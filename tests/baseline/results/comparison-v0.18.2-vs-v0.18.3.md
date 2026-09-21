
## Benchmark Comparison

  Baseline:    v0.18.2 (v0.18.2, 77 test cases)
  Current:     v0.18.3 (v0.18.3, 77 test cases)

### Timing Delta

| # | file selection | standard | no-msgs | top25 | top25-cons | heatmap | histogram | hm+hg | hm+hg+cons | sort-p99 | sort-skew | hm+hg+export |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. | humungous-log-uniqueness | +3.3% | -4.5% | +0.2% | +1.1% | +4.5% | +3.1% | +1.1% | -1.4% | +1.1% | -0.4% | -6.1% |
| 2. | single-day-application-log | +0.2% | -0.8% | +0.7% | +1.1% | +0.1% | +1.2% | +2.6% | +1.9% | +2.0% | +1.0% | -1.1% |
| 3. | multi-day-application-logs | +2.2% | +1.9% | +1.1% | +0.4% | +0.1% | +1.4% | +0.3% | +1.6% | +2.2% | +3.5% | -0.7% |
| 4. | multi-day-custom-logs | +1.5% | +1.5% | +1.3% | +5.0% | +5.3% | +7.1% | +9.2% | +12.7% | +9.3% | +9.4% | +4.9% |
| 5. | single-day-access-log | +8.5% | +5.9% | +9.5% | +9.6% | +8.5% | +8.4% | +7.7% | +8.5% | +7.8% | +7.5% | +6.8% |
| 6. | month-single-server-access-logs | +7.5% | +5.2% | +7.7% | +7.3% | +9.3% | +7.9% | +8.1% | +11.8% | +11.9% | +11.1% | +7.5% |
| 7. | month-many-servers-access-logs | +7.6% | +3.5% | +6.5% | +0.0% | +2.0% | +1.8% | +0.9% | +0.6% | +1.0% | +2.0% | +1.4% |

### Memory Delta (RSS Peak)

| # | file selection | standard | no-msgs | top25 | top25-cons | heatmap | histogram | hm+hg | hm+hg+cons | sort-p99 | sort-skew | hm+hg+export |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. | humungous-log-uniqueness | -0.0% | -0.7% | +0.5% | +0.5% | -0.4% | +0.1% | -0.2% | +0.5% | -0.6% | = | +0.9% |
| 2. | single-day-application-log | +0.4% | -0.0% | +0.6% | +0.2% | -0.2% | +0.4% | +0.6% | +0.1% | +0.6% | +0.4% | +1.1% |
| 3. | multi-day-application-logs | +0.2% | +1.1% | +0.0% | -0.3% | -0.1% | +0.1% | +0.5% | +0.0% | +0.3% | +2.7% | +0.4% |
| 4. | multi-day-custom-logs | +1.0% | -0.9% | +0.6% | +0.7% | -1.5% | -0.5% | +1.0% | +1.1% | +1.9% | +1.5% | +0.6% |
| 5. | single-day-access-log | +1.7% | +4.1% | +0.8% | -1.7% | +0.5% | +2.0% | -0.5% | +1.7% | +0.5% | +1.0% | +2.6% |
| 6. | month-single-server-access-logs | +0.2% | +0.5% | +0.2% | -13.0% | +0.5% | +0.3% | +0.2% | +8.9% | +0.1% | +0.0% | +1.2% |
| 7. | month-many-servers-access-logs | +0.0% | +2.6% | +0.1% | -12.6% | -0.1% | +0.0% | +0.0% | -6.7% | +0.0% | -0.1% | +0.0% |

### Stage Rollup (timing)

| metric | baseline | current | delta | change% | cases +/- | result |
| --- | --- | --- | --- | --- | --- | --- |
| parse/read_files | 125.0 min | 129.4 min | +4.4 min | 3.5% | 69/8 | REGRESS |
| finalize/group_similar | 11.8 min | 11.9 min | +2.4 s | 0.3% | 12/2 | REGRESS |
| finalize/calculate_statistics | 5.1 min | 5.2 min | +9.7 s | 3.2% | 46/11 | REGRESS |
| finalize/calculate_statistics/bucket_stats (within parent) | 2 min | 2.1 min | +3.9 s | 3.2% | 27/4 | REGRESS |
| finalize/calculate_statistics/population_walk (within parent) | 57 s | 59.1 s | +2.1 s | 3.7% | 7/1 | REGRESS |
| finalize/calculate_statistics/sort_selection (within parent) | 1.3 min | 1.4 min | +2.5 s | 3.1% | 29/13 | REGRESS |
| finalize/calculate_statistics/group_calc (within parent) | 39.9 s | 40.9 s | +1 s | 2.6% | 23/4 | REGRESS |
| finalize/calculate_statistics/untimed (within parent) | 3.8 s | 3.9 s | +119 ms | 3.1% | 20/3 | REGRESS |
| total | 142.0 min | 146.6 min | +4.6 min | 3.3% | 70/7 | REGRESS |
| (4 below noise floor) | 2.9 s | 3 s | +92 ms | 3.1% | - | REGRESS |
| (1 below noise floor) (within parent) | 697 ms | 733 ms | +36 ms | 5.2% | - | REGRESS |
| sum of stages | 142.0 min | 146.6 min | +4.6 min | 3.3% | - | REGRESS |

### Category Rollup (memory)

| metric | baseline | current | delta | change% | cases +/- | result |
| --- | --- | --- | --- | --- | --- | --- |
| rss_peak | 101.0 GB | 100.4 GB | -575.4 MB | -0.6% | 57/19 | IMPROVE (most cases REGRESS) |
| unattributed | 16.4 GB | 16.3 GB | -90.1 MB | -0.5% | 57/18 | IMPROVE (most cases REGRESS) |
| log_messages | 68.8 GB | 68.8 GB | -23.0 MB | -0.0% | 6/10 | IMPROVE |
| log_analysis | 11.6 GB | 11.6 GB | +7.8 MB | 0.1% | 3/1 | REGRESS |
| consolidation_id_index | 833.7 MB | 837.8 MB | +4.2 MB | 0.5% | 7/4 | REGRESS |
| consolidation_key_trigrams | 426.8 MB | 430.3 MB | +3.6 MB | 0.8% | 8/5 | REGRESS |
| consolidation_clusters | 2.6 GB | 2.6 GB | -3.0 MB | -0.1% | 5/7 | IMPROVE |
| (25 below noise floor) | 391.1 MB | 391.2 MB | +152.7 KB | 0.0% | - | REGRESS |

### New In This Version

| metric | test cases | per-test range | aggregate |
| --- | --- | --- | --- |
| (none) | - | - | - |

### Summary

| test_name | metric | baseline | current | delta | change% | result |
| --- | --- | --- | --- | --- | --- | --- |
| humungous-log-uniqueness-standard | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/total | 2.8 s | 2.9 s | +91 ms | 3.3% | REGRESS |
| humungous-log-uniqueness-standard | MEMORY/rss_peak | 263.9 MB | 263.8 MB | -112 KB | -0.0% | IMPROVE |
| humungous-log-uniqueness-no-messages | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | TIMING/total | 2.0 s | 1.9 s | -89 ms | -4.5% | IMPROVE |
| humungous-log-uniqueness-no-messages | MEMORY/rss_peak | 38.5 MB | 38.2 MB | -288 KB | -0.7% | IMPROVE |
| humungous-log-uniqueness-top25 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/total | 2.8 s | 2.8 s | +7 ms | 0.2% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY/rss_peak | 264.1 MB | 265.5 MB | +1.3 MB | 0.5% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/total | 4.1 s | 4.1 s | +46 ms | 1.1% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/rss_peak | 50.0 MB | 50.2 MB | +240 KB | 0.5% | REGRESS |
| humungous-log-uniqueness-heatmap | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/total | 2.7 s | 2.8 s | +122 ms | 4.5% | REGRESS |
| humungous-log-uniqueness-heatmap | MEMORY/rss_peak | 265.2 MB | 264.3 MB | -976 KB | -0.4% | IMPROVE |
| humungous-log-uniqueness-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/total | 2.7 s | 2.8 s | +86 ms | 3.1% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY/rss_peak | 265.4 MB | 265.6 MB | +256 KB | 0.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/total | 2.8 s | 2.8 s | +31 ms | 1.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/rss_peak | 265.2 MB | 264.6 MB | -640 KB | -0.2% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-export | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/total | 2.1 s | 1.9 s | -125 ms | -6.1% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/rss_peak | 38.2 MB | 38.5 MB | +352 KB | 0.9% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/total | 4.1 s | 4.1 s | -56 ms | -1.4% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/rss_peak | 49.7 MB | 49.9 MB | +240 KB | 0.5% | REGRESS |
| humungous-log-uniqueness-sort-p99 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | TIMING/total | 2.8 s | 2.8 s | +30 ms | 1.1% | REGRESS |
| humungous-log-uniqueness-sort-p99 | MEMORY/rss_peak | 265.7 MB | 264.2 MB | -1.5 MB | -0.6% | IMPROVE |
| humungous-log-uniqueness-sort-skewness | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | TIMING/total | 2.8 s | 2.7 s | -10 ms | -0.4% | IMPROVE |
| humungous-log-uniqueness-sort-skewness | MEMORY/rss_peak | 265.4 MB | 265.4 MB | 0 B | 0.0% |  |
| single-day-application-log-standard | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | TIMING/total | 3.7 s | 3.7 s | +7 ms | 0.2% | REGRESS |
| single-day-application-log-standard | MEMORY/rss_peak | 42.2 MB | 42.4 MB | +192 KB | 0.4% | REGRESS |
| single-day-application-log-no-messages | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-no-messages | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-no-messages | TIMING/total | 3.1 s | 3.1 s | -26 ms | -0.8% | IMPROVE |
| single-day-application-log-no-messages | MEMORY/rss_peak | 38.3 MB | 38.3 MB | -16 KB | -0.0% | IMPROVE |
| single-day-application-log-top25 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | TIMING/total | 3.6 s | 3.6 s | +24 ms | 0.7% | REGRESS |
| single-day-application-log-top25 | MEMORY/rss_peak | 42.2 MB | 42.5 MB | +240 KB | 0.6% | REGRESS |
| single-day-application-log-top25-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/total | 5.4 s | 5.4 s | +60 ms | 1.1% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/rss_peak | 112 MB | 112.2 MB | +224 KB | 0.2% | REGRESS |
| single-day-application-log-heatmap | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | TIMING/total | 3.7 s | 3.7 s | +5 ms | 0.1% | REGRESS |
| single-day-application-log-heatmap | MEMORY/rss_peak | 42.5 MB | 42.4 MB | -96 KB | -0.2% | IMPROVE |
| single-day-application-log-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | TIMING/total | 3.6 s | 3.7 s | +42 ms | 1.2% | REGRESS |
| single-day-application-log-histogram | MEMORY/rss_peak | 42.1 MB | 42.3 MB | +192 KB | 0.4% | REGRESS |
| single-day-application-log-heatmap-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/total | 3.6 s | 3.7 s | +92 ms | 2.6% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/rss_peak | 42.1 MB | 42.4 MB | +240 KB | 0.6% | REGRESS |
| single-day-application-log-heatmap-histogram-export | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | TIMING/total | 3.1 s | 3.1 s | -36 ms | -1.1% | IMPROVE |
| single-day-application-log-heatmap-histogram-export | MEMORY/rss_peak | 38.4 MB | 38.9 MB | +448 KB | 1.1% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/total | 5.3 s | 5.4 s | +103 ms | 1.9% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 112 MB | 112.2 MB | +144 KB | 0.1% | REGRESS |
| single-day-application-log-sort-p99 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | TIMING/total | 3.6 s | 3.7 s | +71 ms | 2.0% | REGRESS |
| single-day-application-log-sort-p99 | MEMORY/rss_peak | 42 MB | 42.3 MB | +256 KB | 0.6% | REGRESS |
| single-day-application-log-sort-skewness | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | TIMING/total | 3.6 s | 3.6 s | +35 ms | 1.0% | REGRESS |
| single-day-application-log-sort-skewness | MEMORY/rss_peak | 42 MB | 42.2 MB | +176 KB | 0.4% | REGRESS |
| multi-day-application-logs-standard | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-standard | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-standard | TIMING/total | 7.8 s | 7.9 s | +169 ms | 2.2% | REGRESS |
| multi-day-application-logs-standard | MEMORY/rss_peak | 107.2 MB | 107.3 MB | +176 KB | 0.2% | REGRESS |
| multi-day-application-logs-no-messages | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | TIMING/total | 6.5 s | 6.6 s | +125 ms | 1.9% | REGRESS |
| multi-day-application-logs-no-messages | MEMORY/rss_peak | 39.4 MB | 39.8 MB | +432 KB | 1.1% | REGRESS |
| multi-day-application-logs-top25 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/total | 7.8 s | 7.9 s | +89 ms | 1.1% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/rss_peak | 107.3 MB | 107.3 MB | +16 KB | 0.0% | REGRESS |
| multi-day-application-logs-top25-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/total | 33.9 s | 34 s | +137 ms | 0.4% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | 230.2 MB | 229.5 MB | -656 KB | -0.3% | IMPROVE |
| multi-day-application-logs-heatmap | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/total | 7.9 s | 7.9 s | +10 ms | 0.1% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY/rss_peak | 107.5 MB | 107.3 MB | -144 KB | -0.1% | IMPROVE |
| multi-day-application-logs-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/total | 7.8 s | 7.9 s | +109 ms | 1.4% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/rss_peak | 107.2 MB | 107.4 MB | +144 KB | 0.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/total | 7.8 s | 7.8 s | +26 ms | 0.3% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/rss_peak | 106.8 MB | 107.4 MB | +576 KB | 0.5% | REGRESS |
| multi-day-application-logs-heatmap-histogram-export | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | TIMING/total | 6.5 s | 6.5 s | -44 ms | -0.7% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/rss_peak | 39.7 MB | 39.8 MB | +144 KB | 0.4% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | 33.8 s | 34.3 s | +557 ms | 1.6% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 229.4 MB | 229.4 MB | +32 KB | 0.0% | REGRESS |
| multi-day-application-logs-sort-p99 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | TIMING/total | 7.8 s | 7.9 s | +171 ms | 2.2% | REGRESS |
| multi-day-application-logs-sort-p99 | MEMORY/rss_peak | 107.2 MB | 107.4 MB | +288 KB | 0.3% | REGRESS |
| multi-day-application-logs-sort-skewness | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | TIMING/total | 7.8 s | 8.1 s | +272 ms | 3.5% | REGRESS |
| multi-day-application-logs-sort-skewness | MEMORY/rss_peak | 107.2 MB | 110.1 MB | +2.9 MB | 2.7% | REGRESS |
| multi-day-custom-logs-standard | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/total | 16.4 s | 16.7 s | +252 ms | 1.5% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/rss_peak | 175.5 MB | 177.3 MB | +1.8 MB | 1.0% | REGRESS |
| multi-day-custom-logs-no-messages | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | TIMING/total | 13.1 s | 13.3 s | +196 ms | 1.5% | REGRESS |
| multi-day-custom-logs-no-messages | MEMORY/rss_peak | 54.4 MB | 53.9 MB | -496 KB | -0.9% | IMPROVE |
| multi-day-custom-logs-top25 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/total | 16.4 s | 16.6 s | +212 ms | 1.3% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/rss_peak | 176.3 MB | 177.4 MB | +1.1 MB | 0.6% | REGRESS |
| multi-day-custom-logs-top25-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/total | 38.5 s | 40.4 s | +1.9 s | 5.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/rss_peak | 229.0 MB | 230.6 MB | +1.6 MB | 0.7% | REGRESS |
| multi-day-custom-logs-heatmap | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/total | 17.4 s | 18.4 s | +932 ms | 5.3% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/rss_peak | 176.4 MB | 173.7 MB | -2.7 MB | -1.5% | IMPROVE |
| multi-day-custom-logs-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/total | 17.4 s | 18.7 s | +1.2 s | 7.1% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/rss_peak | 178.4 MB | 177.4 MB | -976 KB | -0.5% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/total | 17.4 s | 19.1 s | +1.6 s | 9.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/rss_peak | 173.4 MB | 175 MB | +1.7 MB | 1.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/total | 14.5 s | 15.2 s | +715 ms | 4.9% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/rss_peak | 57.6 MB | 57.9 MB | +336 KB | 0.6% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/total | 39.5 s | 44.5 s | +5 s | 12.7% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 227.0 MB | 229.6 MB | +2.6 MB | 1.1% | REGRESS |
| multi-day-custom-logs-sort-p99 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | TIMING/total | 16.2 s | 17.7 s | +1.5 s | 9.3% | REGRESS |
| multi-day-custom-logs-sort-p99 | MEMORY/rss_peak | 172.9 MB | 176.2 MB | +3.3 MB | 1.9% | REGRESS |
| multi-day-custom-logs-sort-skewness | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | TIMING/total | 16.3 s | 17.9 s | +1.5 s | 9.4% | REGRESS |
| multi-day-custom-logs-sort-skewness | MEMORY/rss_peak | 175.3 MB | 177.9 MB | +2.5 MB | 1.5% | REGRESS |
| single-day-access-log-standard | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | TIMING/total | 8.7 s | 9.4 s | +738 ms | 8.5% | REGRESS |
| single-day-access-log-standard | MEMORY/rss_peak | 99.6 MB | 101.2 MB | +1.7 MB | 1.7% | REGRESS |
| single-day-access-log-no-messages | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-no-messages | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-no-messages | TIMING/total | 6.6 s | 7 s | +391 ms | 5.9% | REGRESS |
| single-day-access-log-no-messages | MEMORY/rss_peak | 64.7 MB | 67.3 MB | +2.6 MB | 4.1% | REGRESS |
| single-day-access-log-top25 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | TIMING/total | 8.6 s | 9.5 s | +825 ms | 9.5% | REGRESS |
| single-day-access-log-top25 | MEMORY/rss_peak | 99.8 MB | 100.6 MB | +768 KB | 0.8% | REGRESS |
| single-day-access-log-top25-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/total | 11.8 s | 13.0 s | +1.1 s | 9.6% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/rss_peak | 132.8 MB | 130.5 MB | -2.3 MB | -1.7% | IMPROVE |
| single-day-access-log-heatmap | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | TIMING/total | 9.3 s | 10.1 s | +790 ms | 8.5% | REGRESS |
| single-day-access-log-heatmap | MEMORY/rss_peak | 82.9 MB | 83.3 MB | +384 KB | 0.5% | REGRESS |
| single-day-access-log-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | TIMING/total | 10.6 s | 11.5 s | +893 ms | 8.4% | REGRESS |
| single-day-access-log-histogram | MEMORY/rss_peak | 99.4 MB | 101.5 MB | +2 MB | 2.0% | REGRESS |
| single-day-access-log-heatmap-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/total | 11.1 s | 12.0 s | +857 ms | 7.7% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/rss_peak | 83.9 MB | 83.5 MB | -416 KB | -0.5% | IMPROVE |
| single-day-access-log-heatmap-histogram-export | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | TIMING/total | 9.8 s | 10.4 s | +662 ms | 6.8% | REGRESS |
| single-day-access-log-heatmap-histogram-export | MEMORY/rss_peak | 68 MB | 69.8 MB | +1.8 MB | 2.6% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/total | 13.8 s | 14.9 s | +1.2 s | 8.5% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 113.3 MB | 115.2 MB | +2.0 MB | 1.7% | REGRESS |
| single-day-access-log-sort-p99 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/total | 8.7 s | 9.3 s | +673 ms | 7.8% | REGRESS |
| single-day-access-log-sort-p99 | MEMORY/rss_peak | 98.9 MB | 99.4 MB | +512 KB | 0.5% | REGRESS |
| single-day-access-log-sort-skewness | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | TIMING/total | 8.8 s | 9.5 s | +659 ms | 7.5% | REGRESS |
| single-day-access-log-sort-skewness | MEMORY/rss_peak | 103.9 MB | 104.9 MB | +1 MB | 1.0% | REGRESS |
| month-single-server-access-logs-standard | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/total | 1.6 min | 1.8 min | +7.4 s | 7.5% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/rss_peak | 2 GB | 2 GB | +4.2 MB | 0.2% | REGRESS |
| month-single-server-access-logs-no-messages | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | TIMING/total | 1.2 min | 1.3 min | +3.7 s | 5.2% | REGRESS |
| month-single-server-access-logs-no-messages | MEMORY/rss_peak | 370.2 MB | 372.2 MB | +2.0 MB | 0.5% | REGRESS |
| month-single-server-access-logs-top25 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/total | 1.7 min | 1.8 min | +7.7 s | 7.7% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/rss_peak | 2 GB | 2 GB | +3.5 MB | 0.2% | REGRESS |
| month-single-server-access-logs-top25-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/total | 2.8 min | 3.0 min | +12.2 s | 7.3% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | 928.7 MB | 807.7 MB | -121.0 MB | -13.0% | IMPROVE |
| month-single-server-access-logs-heatmap | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/total | 1.8 min | 1.9 min | +9.9 s | 9.3% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/rss_peak | 1.8 GB | 1.8 GB | +9.5 MB | 0.5% | REGRESS |
| month-single-server-access-logs-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/total | 2 min | 2.2 min | +9.5 s | 7.9% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/rss_peak | 1.9 GB | 1.9 GB | +5.0 MB | 0.3% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/total | 2.1 min | 2.3 min | +10.2 s | 8.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/rss_peak | 1.8 GB | 1.8 GB | +3.6 MB | 0.2% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/total | 1.8 min | 1.9 min | +8.1 s | 7.5% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/rss_peak | 371.5 MB | 375.8 MB | +4.3 MB | 1.2% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | 2.9 min | 3.3 min | +20.9 s | 11.8% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 640.1 MB | 697.1 MB | +56.9 MB | 8.9% | REGRESS |
| month-single-server-access-logs-sort-p99 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | TIMING/total | 1.7 min | 2.0 min | +12.5 s | 11.9% | REGRESS |
| month-single-server-access-logs-sort-p99 | MEMORY/rss_peak | 2.2 GB | 2.2 GB | +2.3 MB | 0.1% | REGRESS |
| month-single-server-access-logs-sort-skewness | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | TIMING/total | 1.7 min | 1.9 min | +11.2 s | 11.1% | REGRESS |
| month-single-server-access-logs-sort-skewness | MEMORY/rss_peak | 2.1 GB | 2.1 GB | +1 MB | 0.0% | REGRESS |
| month-many-servers-access-logs-standard | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | TIMING/total | 8.3 min | 8.9 min | +37.9 s | 7.6% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY/rss_peak | 10.1 GB | 10.1 GB | +5 MB | 0.0% | REGRESS |
| month-many-servers-access-logs-no-messages | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | TIMING/total | 6.1 min | 6.3 min | +12.9 s | 3.5% | REGRESS |
| month-many-servers-access-logs-no-messages | MEMORY/rss_peak | 1.6 GB | 1.6 GB | +43.1 MB | 2.6% | REGRESS |
| month-many-servers-access-logs-top25 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | TIMING/total | 8.3 min | 8.8 min | +32.5 s | 6.5% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/rss_peak | 10.1 GB | 10.1 GB | +5.9 MB | 0.1% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | 16.3 min | 16.3 min | +91 ms | 0.0% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | 3.4 GB | 3.0 GB | -437.2 MB | -12.6% | IMPROVE |
| month-many-servers-access-logs-heatmap | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/total | 8.9 min | 9.1 min | +10.7 s | 2.0% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/rss_peak | 8.9 GB | 8.8 GB | -11.4 MB | -0.1% | IMPROVE |
| month-many-servers-access-logs-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/total | 10.1 min | 10.3 min | +10.7 s | 1.8% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/rss_peak | 10.1 GB | 10.1 GB | +2.2 MB | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/total | 10.6 min | 10.7 min | +5.8 s | 0.9% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/rss_peak | 8.8 GB | 8.8 GB | +2.1 MB | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-export | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/total | 9.0 min | 9.1 min | +7.4 s | 1.4% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/rss_peak | 1.7 GB | 1.7 GB | +240 KB | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | 16.5 min | 16.6 min | +5.5 s | 0.6% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 2.5 GB | 2.3 GB | -170.9 MB | -6.7% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | TIMING/total | 9.0 min | 9.1 min | +5.5 s | 1.0% | REGRESS |
| month-many-servers-access-logs-sort-p99 | MEMORY/rss_peak | 10.9 GB | 11.0 GB | +2.9 MB | 0.0% | REGRESS |
| month-many-servers-access-logs-sort-skewness | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | TIMING/total | 8.5 min | 8.7 min | +10.1 s | 2.0% | REGRESS |
| month-many-servers-access-logs-sort-skewness | MEMORY/rss_peak | 10.4 GB | 10.4 GB | -14.5 MB | -0.1% | IMPROVE |

### Detailed

| test_name | metric | baseline | current | delta | change% | result |
| --- | --- | --- | --- | --- | --- | --- |
| humungous-log-uniqueness-standard | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/detect/scan_sub_compile | 6 ms | 7 ms | +1 ms | 16.7% | REGRESS |
| humungous-log-uniqueness-standard | TIMING/parse/read_files | 2.5 s | 2.5 s | +74 ms | 3.0% | REGRESS |
| humungous-log-uniqueness-standard | TIMING/finalize/calculate_statistics | 312 ms | 329 ms | +17 ms | 5.4% | REGRESS |
| humungous-log-uniqueness-standard | TIMING/finalize/calculate_statistics/sort_selection | 300 ms | 315 ms | +15 ms | 5.0% | REGRESS |
| humungous-log-uniqueness-standard | TIMING/finalize/calculate_statistics/untimed | 13 ms | 14 ms | +1 ms | 7.7% | REGRESS |
| humungous-log-uniqueness-standard | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/total | 2.8 s | 2.9 s | +91 ms | 3.3% | REGRESS |
| humungous-log-uniqueness-standard | MEMORY/rss_peak | 263.9 MB | 263.8 MB | -112 KB | -0.0% | IMPROVE |
| humungous-log-uniqueness-standard | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/format_scan_subs | 1.1 MB | 1 MB | -16 KB | -1.5% | IMPROVE |
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
| humungous-log-uniqueness-standard | MEMORY/unattributed | 89.9 MB | 89.8 MB | -96 KB | -0.1% | IMPROVE |
| humungous-log-uniqueness-standard | MEMORY_FINAL/log_messages | 181317607 | 181317607 | 0 | 0.0% |  |
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
| humungous-log-uniqueness-no-messages | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-no-messages | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-no-messages | TIMING/parse/read_files | 2.0 s | 1.9 s | -89 ms | -4.5% | IMPROVE |
| humungous-log-uniqueness-no-messages | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-no-messages | TIMING/total | 2.0 s | 1.9 s | -89 ms | -4.5% | IMPROVE |
| humungous-log-uniqueness-no-messages | MEMORY/rss_peak | 38.5 MB | 38.2 MB | -288 KB | -0.7% | IMPROVE |
| humungous-log-uniqueness-no-messages | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | 0 B | 0.0% |  |
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
| humungous-log-uniqueness-no-messages | MEMORY/unattributed | 37.4 MB | 37.1 MB | -288 KB | -0.8% | IMPROVE |
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
| humungous-log-uniqueness-top25 | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/parse/read_files | 2.5 s | 2.5 s | -8 ms | -0.3% | IMPROVE |
| humungous-log-uniqueness-top25 | TIMING/finalize/calculate_statistics | 308 ms | 323 ms | +15 ms | 4.9% | REGRESS |
| humungous-log-uniqueness-top25 | TIMING/finalize/calculate_statistics/sort_selection | 295 ms | 309 ms | +14 ms | 4.7% | REGRESS |
| humungous-log-uniqueness-top25 | TIMING/finalize/calculate_statistics/untimed | 13 ms | 14 ms | +1 ms | 7.7% | REGRESS |
| humungous-log-uniqueness-top25 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/total | 2.8 s | 2.8 s | +7 ms | 0.2% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY/rss_peak | 264.1 MB | 265.5 MB | +1.3 MB | 0.5% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | +32 KB | 2.9% | REGRESS |
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
| humungous-log-uniqueness-top25 | MEMORY/unattributed | 90.1 MB | 91.4 MB | +1.3 MB | 1.4% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/log_messages | 181317607 | 181317607 | 0 | 0.0% |  |
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
| humungous-log-uniqueness-top25-consolidate | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/detect/scan_sub_compile | 6 ms | 7 ms | +1 ms | 16.7% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | TIMING/parse/read_files | 3.3 s | 3.3 s | +33 ms | 1.0% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | TIMING/finalize/group_similar | 768 ms | 782 ms | +14 ms | 1.8% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/total | 4.1 s | 4.1 s | +46 ms | 1.1% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/rss_peak | 50.0 MB | 50.2 MB | +240 KB | 0.5% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_clusters | 187.8 KB | 187.9 KB | +64 B | 0.0% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_id_index | 5.7 MB | 5.7 MB | +2 KB | 0.0% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_message | 231.5 KB | 231.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_trigrams | 2.8 MB | 2.8 MB | +2 KB | 0.1% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_patterns | 23.8 KB | 23.8 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_unmatched | 129.8 KB | 129.8 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | -16 KB | -1.4% | IMPROVE |
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
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_messages | 190.1 KB | 190.1 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_stats | 1.7 KB | 1.7 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_users | 8.5 KB | 8.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/message_key_order | 10.2 KB | 10.2 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/unattributed | 39.6 MB | 39.9 MB | +251.9 KB | 0.6% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/log_messages | 45600 | 45600 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 192313 | 192377 | 64 | 0.0% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 24370 | 24370 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 4152 | 4152 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 4152 | 4152 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_messages_entries | 76 | 76 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_occurrences_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_stats_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_messages_population | 76 | 76 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/detect/scan_sub_compile | 6 ms | 7 ms | +1 ms | 16.7% | REGRESS |
| humungous-log-uniqueness-heatmap | TIMING/parse/read_files | 2.4 s | 2.5 s | +116 ms | 4.9% | REGRESS |
| humungous-log-uniqueness-heatmap | TIMING/finalize/calculate_statistics | 309 ms | 314 ms | +5 ms | 1.6% | REGRESS |
| humungous-log-uniqueness-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 296 ms | 301 ms | +5 ms | 1.7% | REGRESS |
| humungous-log-uniqueness-heatmap | TIMING/finalize/calculate_statistics/untimed | 13 ms | 13 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/total | 2.7 s | 2.8 s | +122 ms | 4.5% | REGRESS |
| humungous-log-uniqueness-heatmap | MEMORY/rss_peak | 265.2 MB | 264.3 MB | -976 KB | -0.4% | IMPROVE |
| humungous-log-uniqueness-heatmap | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/format_scan_subs | 1.1 MB | 1.2 MB | +192 KB | 17.6% | REGRESS |
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
| humungous-log-uniqueness-heatmap | MEMORY/unattributed | 91.2 MB | 90.1 MB | -1.1 MB | -1.3% | IMPROVE |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/log_messages | 181317607 | 181317607 | 0 | 0.0% |  |
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
| humungous-log-uniqueness-histogram | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/parse/read_files | 2.4 s | 2.5 s | +78 ms | 3.2% | REGRESS |
| humungous-log-uniqueness-histogram | TIMING/finalize/calculate_statistics | 307 ms | 315 ms | +8 ms | 2.6% | REGRESS |
| humungous-log-uniqueness-histogram | TIMING/finalize/calculate_statistics/sort_selection | 295 ms | 302 ms | +7 ms | 2.4% | REGRESS |
| humungous-log-uniqueness-histogram | TIMING/finalize/calculate_statistics/untimed | 12 ms | 13 ms | +1000 us | 8.3% | REGRESS |
| humungous-log-uniqueness-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/total | 2.7 s | 2.8 s | +86 ms | 3.1% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY/rss_peak | 265.4 MB | 265.6 MB | +256 KB | 0.1% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | -48 KB | -4.2% | IMPROVE |
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
| humungous-log-uniqueness-histogram | MEMORY/unattributed | 91.3 MB | 91.6 MB | +304 KB | 0.3% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/log_messages | 181317607 | 181317607 | 0 | 0.0% |  |
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
| humungous-log-uniqueness-heatmap-histogram | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/parse/read_files | 2.4 s | 2.5 s | +42 ms | 1.7% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | TIMING/finalize/calculate_statistics | 320 ms | 309 ms | -11 ms | -3.4% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 306 ms | 296 ms | -10 ms | -3.3% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | 13 ms | 13 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/total | 2.8 s | 2.8 s | +31 ms | 1.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/rss_peak | 265.2 MB | 264.6 MB | -640 KB | -0.2% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | 0 B | 0.0% |  |
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
| humungous-log-uniqueness-heatmap-histogram | MEMORY/unattributed | 91.2 MB | 90.6 MB | -640 KB | -0.7% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/log_messages | 181317607 | 181317607 | 0 | 0.0% |  |
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
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/detect/scan_sub_compile | 6 ms | 7 ms | +1 ms | 16.7% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/parse/read_files | 2 s | 1.9 s | -125 ms | -6.1% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/total | 2.1 s | 1.9 s | -125 ms | -6.1% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/rss_peak | 38.2 MB | 38.5 MB | +352 KB | 0.9% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | +16 KB | 1.5% | REGRESS |
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
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/unattributed | 37.1 MB | 37.4 MB | +336 KB | 0.9% | REGRESS |
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
| humungous-log-uniqueness-heatmap-histogram-export | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/parse/read_files | 3.3 s | 3.3 s | -54 ms | -1.6% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 777 ms | 775 ms | -2 ms | -0.3% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/total | 4.1 s | 4.1 s | -56 ms | -1.4% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/rss_peak | 49.7 MB | 49.9 MB | +240 KB | 0.5% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 187.8 KB | 187.9 KB | +64 B | 0.0% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_id_index | 5.7 MB | 5.7 MB | +2 KB | 0.0% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 231.5 KB | 231.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 2.8 MB | 2.8 MB | +2 KB | 0.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 23.8 KB | 23.8 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 129.8 KB | 129.7 KB | -128 B | -0.1% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | 0 B | 0.0% |  |
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
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_messages | 190.1 KB | 190.1 KB | 0 B | 0.0% |  |
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
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/unattributed | 39.4 MB | 39.6 MB | +236.1 KB | 0.6% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 45600 | 45600 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 192313 | 192377 | 64 | 0.0% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 24370 | 24370 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 4152 | 4152 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 4152 | 4152 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 76 | 76 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_messages_population | 76 | 76 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | TIMING/parse/read_files | 2.5 s | 2.5 s | +34 ms | 1.4% | REGRESS |
| humungous-log-uniqueness-sort-p99 | TIMING/finalize/calculate_statistics | 320 ms | 314 ms | -6 ms | -1.9% | IMPROVE |
| humungous-log-uniqueness-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 307 ms | 301 ms | -6 ms | -2.0% | IMPROVE |
| humungous-log-uniqueness-sort-p99 | TIMING/finalize/calculate_statistics/untimed | 13 ms | 13 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | TIMING/total | 2.8 s | 2.8 s | +30 ms | 1.1% | REGRESS |
| humungous-log-uniqueness-sort-p99 | MEMORY/rss_peak | 265.7 MB | 264.2 MB | -1.5 MB | -0.6% | IMPROVE |
| humungous-log-uniqueness-sort-p99 | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | -48 KB | -4.2% | IMPROVE |
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
| humungous-log-uniqueness-sort-p99 | MEMORY/unattributed | 91.6 MB | 90.2 MB | -1.4 MB | -1.6% | IMPROVE |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/log_messages | 181317607 | 181317607 | 0 | 0.0% |  |
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
| humungous-log-uniqueness-sort-skewness | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | TIMING/parse/read_files | 2.4 s | 2.4 s | -17 ms | -0.7% | IMPROVE |
| humungous-log-uniqueness-sort-skewness | TIMING/finalize/calculate_statistics | 312 ms | 319 ms | +7 ms | 2.2% | REGRESS |
| humungous-log-uniqueness-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 300 ms | 306 ms | +6 ms | 2.0% | REGRESS |
| humungous-log-uniqueness-sort-skewness | TIMING/finalize/calculate_statistics/untimed | 13 ms | 13 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | TIMING/total | 2.8 s | 2.7 s | -10 ms | -0.4% | IMPROVE |
| humungous-log-uniqueness-sort-skewness | MEMORY/rss_peak | 265.4 MB | 265.4 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | -32 KB | -2.8% | IMPROVE |
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
| humungous-log-uniqueness-sort-skewness | MEMORY/unattributed | 91.4 MB | 91.4 MB | +32 KB | 0.0% | REGRESS |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/log_messages | 181317607 | 181317607 | 0 | 0.0% |  |
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
| single-day-application-log-standard | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| single-day-application-log-standard | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-standard | TIMING/parse/read_files | 3.6 s | 3.6 s | +8 ms | 0.2% | REGRESS |
| single-day-application-log-standard | TIMING/finalize/calculate_statistics | 7 ms | 6 ms | -1 ms | -14.3% | IMPROVE |
| single-day-application-log-standard | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-standard | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-standard | TIMING/total | 3.7 s | 3.7 s | +7 ms | 0.2% | REGRESS |
| single-day-application-log-standard | MEMORY/rss_peak | 42.2 MB | 42.4 MB | +192 KB | 0.4% | REGRESS |
| single-day-application-log-standard | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | 0 B | 0.0% |  |
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
| single-day-application-log-standard | MEMORY/log_stats | 7.9 KB | 7.6 KB | -256 B | -3.2% | IMPROVE |
| single-day-application-log-standard | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_users | 85.2 KB | 85.2 KB | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/unattributed | 38.3 MB | 38.4 MB | +192.2 KB | 0.5% | REGRESS |
| single-day-application-log-standard | MEMORY_FINAL/log_messages | 2914830 | 2914830 | 0 | 0.0% |  |
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
| single-day-application-log-no-messages | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| single-day-application-log-no-messages | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-no-messages | TIMING/parse/read_files | 3.1 s | 3.1 s | -26 ms | -0.8% | IMPROVE |
| single-day-application-log-no-messages | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-no-messages | TIMING/total | 3.1 s | 3.1 s | -26 ms | -0.8% | IMPROVE |
| single-day-application-log-no-messages | MEMORY/rss_peak | 38.3 MB | 38.3 MB | -16 KB | -0.0% | IMPROVE |
| single-day-application-log-no-messages | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | 0 B | 0.0% |  |
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
| single-day-application-log-no-messages | MEMORY/log_stats | 7.9 KB | 7.9 KB | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/log_users | 85.2 KB | 85.5 KB | +256 B | 0.3% | REGRESS |
| single-day-application-log-no-messages | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/unattributed | 37.1 MB | 37.1 MB | -16.2 KB | -0.0% | IMPROVE |
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
| single-day-application-log-top25 | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25 | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25 | TIMING/parse/read_files | 3.6 s | 3.6 s | +24 ms | 0.7% | REGRESS |
| single-day-application-log-top25 | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25 | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25 | TIMING/total | 3.6 s | 3.6 s | +24 ms | 0.7% | REGRESS |
| single-day-application-log-top25 | MEMORY/rss_peak | 42.2 MB | 42.5 MB | +240 KB | 0.6% | REGRESS |
| single-day-application-log-top25 | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | -48 KB | -4.2% | IMPROVE |
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
| single-day-application-log-top25 | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_stats | 7.9 KB | 7.9 KB | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_users | 85.0 KB | 85.5 KB | +512 B | 0.6% | REGRESS |
| single-day-application-log-top25 | MEMORY/message_key_order | 6.4 KB | 6.4 KB | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/unattributed | 38.2 MB | 38.5 MB | +287.5 KB | 0.7% | REGRESS |
| single-day-application-log-top25 | MEMORY_FINAL/log_messages | 2914830 | 2914830 | 0 | 0.0% |  |
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
| single-day-application-log-top25-consolidate | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/detect/scan_sub_compile | 7 ms | 6 ms | -1 ms | -14.3% | IMPROVE |
| single-day-application-log-top25-consolidate | TIMING/parse/read_files | 5.1 s | 5.1 s | +54 ms | 1.1% | REGRESS |
| single-day-application-log-top25-consolidate | TIMING/finalize/group_similar | 305 ms | 311 ms | +6 ms | 2.0% | REGRESS |
| single-day-application-log-top25-consolidate | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/total | 5.4 s | 5.4 s | +60 ms | 1.1% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/rss_peak | 112 MB | 112.2 MB | +224 KB | 0.2% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_clusters | 346.7 KB | 346.2 KB | -512 B | -0.1% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_id_index | 55.7 MB | 55.7 MB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_message | 1.4 MB | 1.4 MB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_trigrams | 28.0 MB | 28.0 MB | -3 KB | -0.0% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_patterns | 42.8 KB | 42.8 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_unmatched | 800.7 KB | 800.7 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | -32 KB | -2.8% | IMPROVE |
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
| single-day-application-log-top25-consolidate | MEMORY/log_messages | 1.2 MB | 1.2 MB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_stats | 7.9 KB | 7.9 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_users | 85.2 KB | 85.0 KB | -256 B | -0.3% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/message_key_order | 6.8 KB | 6.8 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/unattributed | 23.4 MB | 23.7 MB | +259.8 KB | 1.1% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/log_messages | 91437 | 91437 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 354999 | 354487 | -512 | -0.1% | IMPROVE |
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
| single-day-application-log-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | TIMING/detect/registry_build | 13 ms | 12 ms | -1000 us | -7.7% | IMPROVE |
| single-day-application-log-heatmap | TIMING/detect/scan_sub_compile | 7 ms | 6 ms | -1 ms | -14.3% | IMPROVE |
| single-day-application-log-heatmap | TIMING/parse/read_files | 3.6 s | 3.6 s | +6 ms | 0.2% | REGRESS |
| single-day-application-log-heatmap | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 5 ms | -1 ms | -16.7% | IMPROVE |
| single-day-application-log-heatmap | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap | TIMING/total | 3.7 s | 3.7 s | +5 ms | 0.1% | REGRESS |
| single-day-application-log-heatmap | MEMORY/rss_peak | 42.5 MB | 42.4 MB | -96 KB | -0.2% | IMPROVE |
| single-day-application-log-heatmap | MEMORY/bucket_outcomes | 6 KB | 5.8 KB | -256 B | -4.2% | IMPROVE |
| single-day-application-log-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | +32 KB | 2.9% | REGRESS |
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
| single-day-application-log-heatmap | MEMORY/log_occurrences | 21.8 KB | 21.5 KB | -256 B | -1.1% | IMPROVE |
| single-day-application-log-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_stats | 7.9 KB | 7.9 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_users | 85.2 KB | 85.2 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/unattributed | 38.5 MB | 38.4 MB | -127.5 KB | -0.3% | IMPROVE |
| single-day-application-log-heatmap | MEMORY_FINAL/log_messages | 2914830 | 2914830 | 0 | 0.0% |  |
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
| single-day-application-log-histogram | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| single-day-application-log-histogram | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-histogram | TIMING/parse/read_files | 3.6 s | 3.6 s | +42 ms | 1.2% | REGRESS |
| single-day-application-log-histogram | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-histogram | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 5 ms | -1 ms | -16.7% | IMPROVE |
| single-day-application-log-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-histogram | TIMING/total | 3.6 s | 3.7 s | +42 ms | 1.2% | REGRESS |
| single-day-application-log-histogram | MEMORY/rss_peak | 42.1 MB | 42.3 MB | +192 KB | 0.4% | REGRESS |
| single-day-application-log-histogram | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | +32 KB | 2.9% | REGRESS |
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
| single-day-application-log-histogram | MEMORY/log_stats | 7.9 KB | 7.6 KB | -256 B | -3.2% | IMPROVE |
| single-day-application-log-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_users | 85.2 KB | 85.2 KB | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/unattributed | 38.2 MB | 38.3 MB | +160.2 KB | 0.4% | REGRESS |
| single-day-application-log-histogram | MEMORY_FINAL/log_messages | 2914830 | 2914830 | 0 | 0.0% |  |
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
| single-day-application-log-heatmap-histogram | TIMING/detect/registry_build | 13 ms | 12 ms | -1000 us | -7.7% | IMPROVE |
| single-day-application-log-heatmap-histogram | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/parse/read_files | 3.6 s | 3.7 s | +93 ms | 2.6% | REGRESS |
| single-day-application-log-heatmap-histogram | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 6 ms | +1 ms | 20.0% | REGRESS |
| single-day-application-log-heatmap-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/total | 3.6 s | 3.7 s | +92 ms | 2.6% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/rss_peak | 42.1 MB | 42.4 MB | +240 KB | 0.6% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/bucket_outcomes | 5.8 KB | 6 KB | +256 B | 4.3% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/format_scan_subs | 1 MB | 1.1 MB | +64 KB | 6.0% | REGRESS |
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
| single-day-application-log-heatmap-histogram | MEMORY/log_occurrences | 21.5 KB | 21.8 KB | +256 B | 1.2% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_stats | 7.9 KB | 7.9 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_users | 85.2 KB | 85.5 KB | +256 B | 0.3% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/unattributed | 38.2 MB | 38.3 MB | +175.2 KB | 0.4% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/log_messages | 2914830 | 2914830 | 0 | 0.0% |  |
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
| single-day-application-log-heatmap-histogram-export | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | TIMING/detect/scan_sub_compile | 6 ms | 7 ms | +1 ms | 16.7% | REGRESS |
| single-day-application-log-heatmap-histogram-export | TIMING/parse/read_files | 3.1 s | 3.1 s | -37 ms | -1.2% | IMPROVE |
| single-day-application-log-heatmap-histogram-export | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | TIMING/total | 3.1 s | 3.1 s | -36 ms | -1.1% | IMPROVE |
| single-day-application-log-heatmap-histogram-export | MEMORY/rss_peak | 38.4 MB | 38.9 MB | +448 KB | 1.1% | REGRESS |
| single-day-application-log-heatmap-histogram-export | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/format_scan_subs | 1.1 MB | 1 MB | -80 KB | -7.0% | IMPROVE |
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
| single-day-application-log-heatmap-histogram-export | MEMORY/log_users | 85.5 KB | 84.7 KB | -768 B | -0.9% | IMPROVE |
| single-day-application-log-heatmap-histogram-export | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/unattributed | 37.2 MB | 37.7 MB | +529 KB | 1.4% | REGRESS |
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
| single-day-application-log-heatmap-histogram-export | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/parse/read_files | 5.0 s | 5.1 s | +89 ms | 1.8% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 293 ms | 307 ms | +14 ms | 4.8% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/total | 5.3 s | 5.4 s | +103 ms | 1.9% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 112 MB | 112.2 MB | +144 KB | 0.1% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 346.2 KB | 346.8 KB | +640 B | 0.2% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_id_index | 55.7 MB | 55.7 MB | +2 KB | 0.0% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 1.4 MB | 1.4 MB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 28.0 MB | 28.0 MB | +2 KB | 0.0% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 42.8 KB | 42.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 800.7 KB | 800.7 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | +48 KB | 4.4% | REGRESS |
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
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_messages | 1.2 MB | 1.2 MB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_stats | 7.9 KB | 7.9 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_users | 85.5 KB | 85.5 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/unattributed | 23.5 MB | 23.6 MB | +91.4 KB | 0.4% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 91437 | 91437 | 0 | 0.0% |  |
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
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-p99 | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-p99 | TIMING/parse/read_files | 3.6 s | 3.6 s | +70 ms | 2.0% | REGRESS |
| single-day-application-log-sort-p99 | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 6 ms | +1 ms | 20.0% | REGRESS |
| single-day-application-log-sort-p99 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-p99 | TIMING/total | 3.6 s | 3.7 s | +71 ms | 2.0% | REGRESS |
| single-day-application-log-sort-p99 | MEMORY/rss_peak | 42 MB | 42.3 MB | +256 KB | 0.6% | REGRESS |
| single-day-application-log-sort-p99 | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | 0 B | 0.0% |  |
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
| single-day-application-log-sort-p99 | MEMORY/log_stats | 7.6 KB | 7.9 KB | +256 B | 3.3% | REGRESS |
| single-day-application-log-sort-p99 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/log_users | 85.2 KB | 85.5 KB | +256 B | 0.3% | REGRESS |
| single-day-application-log-sort-p99 | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/unattributed | 38 MB | 38.3 MB | +255.5 KB | 0.7% | REGRESS |
| single-day-application-log-sort-p99 | MEMORY_FINAL/log_messages | 2914830 | 2914830 | 0 | 0.0% |  |
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
| single-day-application-log-sort-skewness | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-skewness | TIMING/detect/scan_sub_compile | 6 ms | 7 ms | +1 ms | 16.7% | REGRESS |
| single-day-application-log-sort-skewness | TIMING/parse/read_files | 3.6 s | 3.6 s | +35 ms | 1.0% | REGRESS |
| single-day-application-log-sort-skewness | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 5 ms | -1 ms | -16.7% | IMPROVE |
| single-day-application-log-sort-skewness | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-skewness | TIMING/total | 3.6 s | 3.6 s | +35 ms | 1.0% | REGRESS |
| single-day-application-log-sort-skewness | MEMORY/rss_peak | 42 MB | 42.2 MB | +176 KB | 0.4% | REGRESS |
| single-day-application-log-sort-skewness | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/format_scan_subs | 1.1 MB | 1.2 MB | +128 KB | 11.6% | REGRESS |
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
| single-day-application-log-sort-skewness | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/log_stats | 7.9 KB | 7.9 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/log_users | 85.2 KB | 85.2 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/unattributed | 38.1 MB | 38.1 MB | +48 KB | 0.1% | REGRESS |
| single-day-application-log-sort-skewness | MEMORY_FINAL/log_messages | 2914830 | 2914830 | 0 | 0.0% |  |
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
| multi-day-application-logs-standard | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-standard | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-standard | TIMING/parse/read_files | 7.6 s | 7.7 s | +161 ms | 2.1% | REGRESS |
| multi-day-application-logs-standard | TIMING/finalize/calculate_statistics | 174 ms | 181 ms | +7 ms | 4.0% | REGRESS |
| multi-day-application-logs-standard | TIMING/finalize/calculate_statistics/sort_selection | 171 ms | 178 ms | +7 ms | 4.1% | REGRESS |
| multi-day-application-logs-standard | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-standard | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-standard | TIMING/total | 7.8 s | 7.9 s | +169 ms | 2.2% | REGRESS |
| multi-day-application-logs-standard | MEMORY/rss_peak | 107.2 MB | 107.3 MB | +176 KB | 0.2% | REGRESS |
| multi-day-application-logs-standard | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | +32 KB | 2.9% | REGRESS |
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
| multi-day-application-logs-standard | MEMORY/log_occurrences | 56.7 KB | 56.6 KB | -64 B | -0.1% | IMPROVE |
| multi-day-application-logs-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_users | 40.9 KB | 40.9 KB | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/unattributed | 57 MB | 57.2 MB | +144.1 KB | 0.2% | REGRESS |
| multi-day-application-logs-standard | MEMORY_FINAL/log_messages | 51302480 | 51302480 | 0 | 0.0% |  |
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
| multi-day-application-logs-no-messages | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-no-messages | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-no-messages | TIMING/parse/read_files | 6.5 s | 6.6 s | +125 ms | 1.9% | REGRESS |
| multi-day-application-logs-no-messages | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-no-messages | TIMING/total | 6.5 s | 6.6 s | +125 ms | 1.9% | REGRESS |
| multi-day-application-logs-no-messages | MEMORY/rss_peak | 39.4 MB | 39.8 MB | +432 KB | 1.1% | REGRESS |
| multi-day-application-logs-no-messages | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | -32 KB | -2.9% | IMPROVE |
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
| multi-day-application-logs-no-messages | MEMORY/log_occurrences | 56.6 KB | 56.7 KB | +64 B | 0.1% | REGRESS |
| multi-day-application-logs-no-messages | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/log_users | 40.7 KB | 40.8 KB | +64 B | 0.2% | REGRESS |
| multi-day-application-logs-no-messages | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/unattributed | 38.1 MB | 38.6 MB | +463.9 KB | 1.2% | REGRESS |
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
| multi-day-application-logs-top25 | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/parse/read_files | 7.6 s | 7.7 s | +94 ms | 1.2% | REGRESS |
| multi-day-application-logs-top25 | TIMING/finalize/calculate_statistics | 179 ms | 174 ms | -5 ms | -2.8% | IMPROVE |
| multi-day-application-logs-top25 | TIMING/finalize/calculate_statistics/sort_selection | 176 ms | 172 ms | -4 ms | -2.3% | IMPROVE |
| multi-day-application-logs-top25 | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/total | 7.8 s | 7.9 s | +89 ms | 1.1% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/rss_peak | 107.3 MB | 107.3 MB | +16 KB | 0.0% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | 0 B | 0.0% |  |
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
| multi-day-application-logs-top25 | MEMORY/log_occurrences | 56.6 KB | 56.7 KB | +64 B | 0.1% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_users | 40.5 KB | 40.6 KB | +192 B | 0.5% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/message_key_order | 6.5 KB | 6.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/unattributed | 57.1 MB | 57.1 MB | +15.8 KB | 0.0% | REGRESS |
| multi-day-application-logs-top25 | MEMORY_FINAL/log_messages | 51302480 | 51302480 | 0 | 0.0% |  |
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
| multi-day-application-logs-top25-consolidate | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/parse/read_files | 29.7 s | 29.8 s | +111 ms | 0.4% | REGRESS |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/group_similar | 4.2 s | 4.2 s | +27 ms | 0.6% | REGRESS |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/calculate_statistics | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/total | 33.9 s | 34 s | +137 ms | 0.4% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | 230.2 MB | 229.5 MB | -656 KB | -0.3% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_clusters | 3 MB | 3 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_id_index | 127.2 MB | 127.2 MB | -6 KB | -0.0% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_message | 3.8 MB | 3.8 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 65.7 MB | 65.7 MB | -8 KB | -0.0% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_patterns | 427.2 KB | 427.2 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_unmatched | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | -16 KB | -1.4% | IMPROVE |
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
| multi-day-application-logs-top25-consolidate | MEMORY/log_messages | 3.4 MB | 3.4 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_occurrences | 56.6 KB | 56.7 KB | +64 B | 0.1% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_users | 40.5 KB | 40.3 KB | -192 B | -0.5% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/message_key_order | 5.7 KB | 5.7 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/unattributed | 23.3 MB | 22.6 MB | -625.9 KB | -2.6% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/log_messages | 659452 | 659452 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 3182226 | 3182226 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 437484 | 437484 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | COUNTS/log_messages_entries | 1127 | 1127 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | COUNTS/log_occurrences_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | COUNTS/log_stats_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | COUNTS/log_messages_population | 1127 | 1127 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | COUNTS/format_scan_sub_cache_hits | 40 | 40 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/parse/read_files | 7.7 s | 7.7 s | +8 ms | 0.1% | REGRESS |
| multi-day-application-logs-heatmap | TIMING/finalize/calculate_statistics | 177 ms | 178 ms | +1 ms | 0.6% | REGRESS |
| multi-day-application-logs-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 174 ms | 175 ms | +1 ms | 0.6% | REGRESS |
| multi-day-application-logs-heatmap | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/total | 7.9 s | 7.9 s | +10 ms | 0.1% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY/rss_peak | 107.5 MB | 107.3 MB | -144 KB | -0.1% | IMPROVE |
| multi-day-application-logs-heatmap | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | -32 KB | -2.7% | IMPROVE |
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
| multi-day-application-logs-heatmap | MEMORY/log_occurrences | 56.7 KB | 56.7 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_users | 40.6 KB | 40.5 KB | -192 B | -0.5% | IMPROVE |
| multi-day-application-logs-heatmap | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/unattributed | 57.3 MB | 57.2 MB | -111.8 KB | -0.2% | IMPROVE |
| multi-day-application-logs-heatmap | MEMORY_FINAL/log_messages | 51302480 | 51302480 | 0 | 0.0% |  |
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
| multi-day-application-logs-histogram | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/parse/read_files | 7.6 s | 7.7 s | +112 ms | 1.5% | REGRESS |
| multi-day-application-logs-histogram | TIMING/finalize/calculate_statistics | 180 ms | 176 ms | -4 ms | -2.2% | IMPROVE |
| multi-day-application-logs-histogram | TIMING/finalize/calculate_statistics/sort_selection | 177 ms | 174 ms | -3 ms | -1.7% | IMPROVE |
| multi-day-application-logs-histogram | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/total | 7.8 s | 7.9 s | +109 ms | 1.4% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/rss_peak | 107.2 MB | 107.4 MB | +144 KB | 0.1% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | +32 KB | 2.9% | REGRESS |
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
| multi-day-application-logs-histogram | MEMORY/log_occurrences | 56.6 KB | 56.6 KB | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_users | 40.6 KB | 40.9 KB | +320 B | 0.8% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/unattributed | 57.1 MB | 57.2 MB | +111.7 KB | 0.2% | REGRESS |
| multi-day-application-logs-histogram | MEMORY_FINAL/log_messages | 51302480 | 51302480 | 0 | 0.0% |  |
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
| multi-day-application-logs-heatmap-histogram | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/parse/read_files | 7.6 s | 7.7 s | +34 ms | 0.4% | REGRESS |
| multi-day-application-logs-heatmap-histogram | TIMING/finalize/calculate_statistics | 183 ms | 175 ms | -8 ms | -4.4% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 180 ms | 172 ms | -8 ms | -4.4% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/total | 7.8 s | 7.8 s | +26 ms | 0.3% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/rss_peak | 106.8 MB | 107.4 MB | +576 KB | 0.5% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | +16 KB | 1.4% | REGRESS |
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
| multi-day-application-logs-heatmap-histogram | MEMORY/log_users | 40.7 KB | 40.4 KB | -320 B | -0.8% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/unattributed | 56.7 MB | 57.2 MB | +560.2 KB | 1.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 51302480 | 51302480 | 0 | 0.0% |  |
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
| multi-day-application-logs-heatmap-histogram-export | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | TIMING/parse/read_files | 6.5 s | 6.5 s | -43 ms | -0.7% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-export | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | TIMING/total | 6.5 s | 6.5 s | -44 ms | -0.7% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/rss_peak | 39.7 MB | 39.8 MB | +144 KB | 0.4% | REGRESS |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | +16 KB | 1.4% | REGRESS |
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
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_occurrences | 56.6 KB | 56.6 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_users | 40.8 KB | 40.7 KB | -128 B | -0.3% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/unattributed | 38.4 MB | 38.6 MB | +128.1 KB | 0.3% | REGRESS |
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
| multi-day-application-logs-heatmap-histogram-export | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/parse/read_files | 29.6 s | 30.2 s | +555 ms | 1.9% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 4.2 s | 4.2 s | +2 ms | 0.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | 33.8 s | 34.3 s | +557 ms | 1.6% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 229.4 MB | 229.4 MB | +32 KB | 0.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 3 MB | 3 MB | +3.3 KB | 0.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_id_index | 127.2 MB | 127.2 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 3.8 MB | 3.8 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 65.7 MB | 65.7 MB | +1 KB | 0.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 427.2 KB | 427.2 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | 0 B | 0.0% |  |
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
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 3.4 MB | 3.4 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 56.7 KB | 56.7 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_users | 39.8 KB | 40.5 KB | +704 B | 1.7% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | 2.9 KB | 2.9 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/unattributed | 22.5 MB | 22.5 MB | +27 KB | 0.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 659452 | 659452 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 3178834 | 3182226 | 3392 | 0.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 437484 | 437484 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 1127 | 1127 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_messages_population | 1127 | 1127 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/format_scan_sub_cache_hits | 40 | 40 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-p99 | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-p99 | TIMING/parse/read_files | 7.6 s | 7.8 s | +171 ms | 2.3% | REGRESS |
| multi-day-application-logs-sort-p99 | TIMING/finalize/calculate_statistics | 177 ms | 176 ms | -1 ms | -0.6% | IMPROVE |
| multi-day-application-logs-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 174 ms | 173 ms | -1 ms | -0.6% | IMPROVE |
| multi-day-application-logs-sort-p99 | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-p99 | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-p99 | TIMING/total | 7.8 s | 7.9 s | +171 ms | 2.2% | REGRESS |
| multi-day-application-logs-sort-p99 | MEMORY/rss_peak | 107.2 MB | 107.4 MB | +288 KB | 0.3% | REGRESS |
| multi-day-application-logs-sort-p99 | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | +48 KB | 4.3% | REGRESS |
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
| multi-day-application-logs-sort-p99 | MEMORY/log_occurrences | 56.6 KB | 56.6 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/log_users | 40.6 KB | 40.6 KB | -64 B | -0.2% | IMPROVE |
| multi-day-application-logs-sort-p99 | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/unattributed | 57 MB | 57.3 MB | +240.1 KB | 0.4% | REGRESS |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/log_messages | 51302480 | 51302480 | 0 | 0.0% |  |
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
| multi-day-application-logs-sort-skewness | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-skewness | TIMING/detect/scan_sub_compile | 6 ms | 7 ms | +1 ms | 16.7% | REGRESS |
| multi-day-application-logs-sort-skewness | TIMING/parse/read_files | 7.6 s | 7.9 s | +271 ms | 3.6% | REGRESS |
| multi-day-application-logs-sort-skewness | TIMING/finalize/calculate_statistics | 178 ms | 178 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 176 ms | 175 ms | -1 ms | -0.6% | IMPROVE |
| multi-day-application-logs-sort-skewness | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-skewness | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-skewness | TIMING/total | 7.8 s | 8.1 s | +272 ms | 3.5% | REGRESS |
| multi-day-application-logs-sort-skewness | MEMORY/rss_peak | 107.2 MB | 110.1 MB | +2.9 MB | 2.7% | REGRESS |
| multi-day-application-logs-sort-skewness | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/format_scan_subs | 1.1 MB | 1 MB | -96 KB | -8.3% | IMPROVE |
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
| multi-day-application-logs-sort-skewness | MEMORY/log_users | 40.2 KB | 40.7 KB | +512 B | 1.2% | REGRESS |
| multi-day-application-logs-sort-skewness | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/unattributed | 57.1 MB | 60 MB | +3.0 MB | 5.2% | REGRESS |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/log_messages | 51302480 | 51302480 | 0 | 0.0% |  |
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
| multi-day-custom-logs-standard | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/parse/read_files | 16.1 s | 16.3 s | +250 ms | 1.6% | REGRESS |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics | 351 ms | 353 ms | +2 ms | 0.6% | REGRESS |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics/bucket_stats | 38 ms | 39 ms | +1 ms | 2.6% | REGRESS |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics/sort_selection | 304 ms | 305 ms | +1 ms | 0.3% | REGRESS |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics/group_calc | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics/untimed | 7 ms | 7 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/total | 16.4 s | 16.7 s | +252 ms | 1.5% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/rss_peak | 175.5 MB | 177.3 MB | +1.8 MB | 1.0% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | -48 KB | -4.2% | IMPROVE |
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
| multi-day-custom-logs-standard | MEMORY/log_messages | 89.4 MB | 89.9 MB | +483.8 KB | 0.5% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_stats | 50.3 KB | 50.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_users | 12.7 KB | 12.7 KB | +64 B | 0.5% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/unattributed | 72.0 MB | 73.4 MB | +1.4 MB | 1.9% | REGRESS |
| multi-day-custom-logs-standard | MEMORY_FINAL/log_messages | 93727014 | 94222438 | 495424 | 0.5% | REGRESS |
| multi-day-custom-logs-standard | MEMORY_FINAL/log_analysis | 20350 | 20350 | 0 | 0.0% |  |
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
| multi-day-custom-logs-no-messages | TIMING/detect/registry_build | 12 ms | 13 ms | +1000 us | 8.3% | REGRESS |
| multi-day-custom-logs-no-messages | TIMING/detect/scan_sub_compile | 6 ms | 7 ms | +1 ms | 16.7% | REGRESS |
| multi-day-custom-logs-no-messages | TIMING/parse/read_files | 13 s | 13.2 s | +194 ms | 1.5% | REGRESS |
| multi-day-custom-logs-no-messages | TIMING/finalize/calculate_statistics | 34 ms | 34 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-no-messages | TIMING/finalize/calculate_statistics/bucket_stats | 34 ms | 34 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-no-messages | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-no-messages | TIMING/total | 13.1 s | 13.3 s | +196 ms | 1.5% | REGRESS |
| multi-day-custom-logs-no-messages | MEMORY/rss_peak | 54.4 MB | 53.9 MB | -496 KB | -0.9% | IMPROVE |
| multi-day-custom-logs-no-messages | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | +48 KB | 4.3% | REGRESS |
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
| multi-day-custom-logs-no-messages | MEMORY/log_stats | 50.3 KB | 50.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/log_users | 12.7 KB | 12.7 KB | +64 B | 0.5% | REGRESS |
| multi-day-custom-logs-no-messages | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/unattributed | 40.3 MB | 39.8 MB | -544.1 KB | -1.3% | IMPROVE |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/log_analysis | 20350 | 20350 | 0 | 0.0% |  |
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
| multi-day-custom-logs-top25 | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/parse/read_files | 16.1 s | 16.3 s | +209 ms | 1.3% | REGRESS |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics | 357 ms | 360 ms | +3 ms | 0.8% | REGRESS |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics/bucket_stats | 39 ms | 40 ms | +1 ms | 2.6% | REGRESS |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics/sort_selection | 306 ms | 308 ms | +2 ms | 0.7% | REGRESS |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics/group_calc | 5 ms | 5 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics/untimed | 7 ms | 7 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/total | 16.4 s | 16.6 s | +212 ms | 1.3% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/rss_peak | 176.3 MB | 177.4 MB | +1.1 MB | 0.6% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/format_scan_subs | 1.1 MB | 1 MB | -80 KB | -6.9% | IMPROVE |
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
| multi-day-custom-logs-top25 | MEMORY/log_messages | 89.4 MB | 89.4 MB | -192 B | -0.0% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_stats | 50.3 KB | 50.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_users | 12.7 KB | 12.7 KB | -64 B | -0.5% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/unattributed | 72.7 MB | 73.9 MB | +1.2 MB | 1.6% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY_FINAL/log_messages | 93737046 | 93736854 | -192 | -0.0% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY_FINAL/log_analysis | 20350 | 20350 | 0 | 0.0% |  |
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
| multi-day-custom-logs-top25-consolidate | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/parse/read_files | 33.6 s | 35.3 s | +1.7 s | 5.1% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/group_similar | 4.7 s | 4.9 s | +160 ms | 3.4% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/calculate_statistics | 148 ms | 195 ms | +47 ms | 31.8% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | 64 ms | 85 ms | +21 ms | 32.8% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | 83 ms | 109 ms | +26 ms | 31.3% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/total | 38.5 s | 40.4 s | +1.9 s | 5.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/rss_peak | 229.0 MB | 230.6 MB | +1.6 MB | 0.7% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_clusters | 14.1 MB | 14.1 MB | +7.4 KB | 0.1% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_id_index | 122.9 MB | 122.9 MB | +10 KB | 0.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_message | 5.8 MB | 5.8 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 62.7 MB | 62.7 MB | +10 KB | 0.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_patterns | 193.0 KB | 193.0 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_unmatched | 3.3 MB | 3.3 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | -48 KB | -4.1% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_analysis | 12.9 MB | 12.9 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_messages | 13.2 MB | 13.2 MB | -3.2 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_stats | 50.3 KB | 50.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_users | 12.7 KB | 12.7 KB | +64 B | 0.5% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/message_key_order | 6.1 KB | 6.1 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/log_messages | 13816460 | 13813132 | -3328 | -0.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 20350 | 20350 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 14753524 | 14761076 | 7552 | 0.1% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 197600 | 197600 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 240 | 240 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_messages_entries | 363 | 363 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_occurrences_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_stats_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_analysis_entries | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_messages_population | 363 | 363 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/format_scan_sub_cache_hits | 4 | 4 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/detect/registry_build | 12 ms | 14 ms | +2 ms | 16.7% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/detect/scan_sub_compile | 6 ms | 8 ms | +2 ms | 33.3% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/parse/read_files | 17 s | 17.9 s | +923 ms | 5.4% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/finalize/calculate_statistics | 346 ms | 356 ms | +10 ms | 2.9% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 337 ms | 345 ms | +8 ms | 2.4% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/finalize/calculate_statistics/group_calc | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/finalize/calculate_statistics/untimed | 8 ms | 8 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/finalize/heatmap_statistics | 54 ms | 51 ms | -3 ms | -5.6% | IMPROVE |
| multi-day-custom-logs-heatmap | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/total | 17.4 s | 18.4 s | +932 ms | 5.3% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/rss_peak | 176.4 MB | 173.7 MB | -2.7 MB | -1.5% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | -32 KB | -2.8% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_counters | 987.2 KB | 985.8 KB | -1.5 KB | -0.2% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_data | 43.6 KB | 43.5 KB | -128 B | -0.3% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_analysis | 20.9 KB | 20.9 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_messages | 89.9 MB | 89.9 MB | +192 B | 0.0% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_stats | 35.5 KB | 35.5 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_users | 12.7 KB | 12.7 KB | +64 B | 0.5% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/unattributed | 84.3 MB | 81.6 MB | -2.6 MB | -3.1% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/log_messages | 94278950 | 94279142 | 192 | 0.0% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/log_analysis | 20350 | 20350 | 0 | 0.0% |  |
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
| multi-day-custom-logs-histogram | TIMING/detect/registry_build | 13 ms | 12 ms | -1000 us | -7.7% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/detect/scan_sub_compile | 7 ms | 6 ms | -1 ms | -14.3% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/parse/read_files | 17 s | 18.2 s | +1.2 s | 7.1% | REGRESS |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics | 361 ms | 390 ms | +29 ms | 8.0% | REGRESS |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics/bucket_stats | 39 ms | 40 ms | +1 ms | 2.6% | REGRESS |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics/sort_selection | 313 ms | 340 ms | +27 ms | 8.6% | REGRESS |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics/group_calc | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics/untimed | 8 ms | 8 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/finalize/histogram_statistics | 14 ms | 16 ms | +2 ms | 14.3% | REGRESS |
| multi-day-custom-logs-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/total | 17.4 s | 18.7 s | +1.2 s | 7.1% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/rss_peak | 178.4 MB | 177.4 MB | -976 KB | -0.5% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/bucket_outcomes | 6.3 KB | 6.1 KB | -256 B | -4.0% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | -16 KB | -1.4% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/histogram_counters | 122.5 KB | 122.3 KB | -192 B | -0.2% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_analysis | 12.9 MB | 12.9 MB | -256 B | -0.0% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/log_messages | 89.4 MB | 89.9 MB | +483.6 KB | 0.5% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_occurrences | 20.3 KB | 20 KB | -256 B | -1.2% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_stats | 50.3 KB | 50.1 KB | -256 B | -0.5% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_users | 12.7 KB | 12.5 KB | -192 B | -1.5% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/unattributed | 74.7 MB | 73.3 MB | -1.4 MB | -1.9% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY_FINAL/log_messages | 93727206 | 94222438 | 495232 | 0.5% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY_FINAL/log_analysis | 20350 | 20094 | -256 | -1.3% | IMPROVE |
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
| multi-day-custom-logs-heatmap-histogram | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/parse/read_files | 17.1 s | 18.6 s | +1.6 s | 9.1% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/calculate_statistics | 315 ms | 366 ms | +51 ms | 16.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 306 ms | 356 ms | +50 ms | 16.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/group_calc | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | 6 ms | 8 ms | +2 ms | 33.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/heatmap_statistics | 49 ms | 52 ms | +3 ms | 6.1% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/histogram_statistics | 14 ms | 15 ms | +1000 us | 7.1% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/total | 17.4 s | 19.1 s | +1.6 s | 9.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/rss_peak | 173.4 MB | 175 MB | +1.7 MB | 1.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | -32 KB | -2.9% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_counters | 985.8 KB | 987.2 KB | +1.5 KB | 0.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_data | 43.2 KB | 39.7 KB | -3.5 KB | -8.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_counters | 122.5 KB | 122.6 KB | +192 B | 0.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_analysis | 20.9 KB | 20.9 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_messages | 89.9 MB | 89.5 MB | -358.9 KB | -0.4% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_stats | 35.5 KB | 35.5 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_users | 12.7 KB | 12.7 KB | +64 B | 0.5% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/unattributed | 81.2 MB | 83.2 MB | +2 MB | 2.5% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 94222438 | 93854950 | -367488 | -0.4% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 20350 | 20350 | 0 | 0.0% |  |
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
| multi-day-custom-logs-heatmap-histogram-export | TIMING/detect/registry_build | 12 ms | 13 ms | +1000 us | 8.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/detect/scan_sub_compile | 6 ms | 7 ms | +1 ms | 16.7% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/parse/read_files | 14.2 s | 14.9 s | +702 ms | 4.9% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics | 97 ms | 102 ms | +5 ms | 5.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/bucket_stats | 97 ms | 102 ms | +5 ms | 5.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/heatmap_statistics | 174 ms | 179 ms | +5 ms | 2.9% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/histogram_statistics | 15 ms | 16 ms | +1 ms | 6.7% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/total | 14.5 s | 15.2 s | +715 ms | 4.9% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/rss_peak | 57.6 MB | 57.9 MB | +336 KB | 0.6% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | -32 KB | -2.9% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/heatmap_counters | 985.8 KB | 987.2 KB | +1.5 KB | 0.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/heatmap_data | 42.8 KB | 42.6 KB | -192 B | -0.4% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/histogram_counters | 122.5 KB | 122.6 KB | +192 B | 0.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_analysis | 12.9 MB | 12.9 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_messages | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_stats | 70.0 KB | 70.0 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_users | 12.7 KB | 12.7 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/unattributed | 42.4 MB | 42.7 MB | +366.5 KB | 0.8% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY_FINAL/log_analysis | 24647 | 24647 | 0 | 0.0% |  |
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
| multi-day-custom-logs-heatmap-histogram-export | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/detect/registry_build | 12 ms | 13 ms | +1000 us | 8.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 6 ms | 7 ms | +1 ms | 16.7% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/parse/read_files | 34.9 s | 38.9 s | +4 s | 11.6% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 4.5 s | 5.4 s | +965 ms | 21.5% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 63 ms | 80 ms | +17 ms | 27.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | 62 ms | 79 ms | +17 ms | 27.4% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/heatmap_statistics | 52 ms | 55 ms | +3 ms | 5.8% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/histogram_statistics | 15 ms | 16 ms | +1 ms | 6.7% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/render/normalize_data | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/total | 39.5 s | 44.5 s | +5 s | 12.7% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 227.0 MB | 229.6 MB | +2.6 MB | 1.1% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 14.1 MB | 14.1 MB | -7.4 KB | -0.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_id_index | 122.9 MB | 122.9 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 5.8 MB | 5.8 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 62.7 MB | 62.7 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 193.0 KB | 193.0 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 3.3 MB | 3.3 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | +16 KB | 1.5% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 985.5 KB | 985.8 KB | +256 B | 0.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 43.6 KB | 43.8 KB | +128 B | 0.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | 122.5 KB | 122.5 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 20.7 KB | 20.9 KB | +256 B | 1.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 13.2 MB | 13.2 MB | +1.9 KB | 0.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 35.2 KB | 35.5 KB | +256 B | 0.7% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_users | 12.7 KB | 12.7 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | 2.6 KB | 2.6 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/unattributed | 2.6 MB | 5.2 MB | +2.6 MB | 99.6% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 13811372 | 13813292 | 1920 | 0.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 20094 | 20350 | 256 | 1.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 14761076 | 14753524 | -7552 | -0.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 197600 | 197600 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 240 | 240 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 363 | 363 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_analysis_entries | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_messages_population | 363 | 363 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/format_scan_sub_cache_hits | 4 | 4 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-p99 | TIMING/detect/scan_sub_compile | 6 ms | 7 ms | +1 ms | 16.7% | REGRESS |
| multi-day-custom-logs-sort-p99 | TIMING/parse/read_files | 16.0 s | 17.5 s | +1.5 s | 9.4% | REGRESS |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics | 246 ms | 262 ms | +16 ms | 6.5% | REGRESS |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics/bucket_stats | 39 ms | 42 ms | +3 ms | 7.7% | REGRESS |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | 195 ms | 208 ms | +13 ms | 6.7% | REGRESS |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics/untimed | 8 ms | 8 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-p99 | TIMING/render/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| multi-day-custom-logs-sort-p99 | TIMING/total | 16.2 s | 17.7 s | +1.5 s | 9.3% | REGRESS |
| multi-day-custom-logs-sort-p99 | MEMORY/rss_peak | 172.9 MB | 176.2 MB | +3.3 MB | 1.9% | REGRESS |
| multi-day-custom-logs-sort-p99 | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/format_scan_subs | 1.1 MB | 1 MB | -96 KB | -8.6% | IMPROVE |
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
| multi-day-custom-logs-sort-p99 | MEMORY/log_messages | 89.9 MB | 89.9 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_stats | 50.3 KB | 50.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_users | 12.7 KB | 12.7 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/message_key_order | 2.7 KB | 2.7 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/unattributed | 68.9 MB | 72.3 MB | +3.4 MB | 4.9% | REGRESS |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/log_messages | 94279670 | 94279670 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/log_analysis | 20350 | 20350 | 0 | 0.0% |  |
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
| multi-day-custom-logs-sort-skewness | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-skewness | TIMING/detect/scan_sub_compile | 6 ms | 7 ms | +1 ms | 16.7% | REGRESS |
| multi-day-custom-logs-sort-skewness | TIMING/parse/read_files | 16 s | 17.5 s | +1.5 s | 9.4% | REGRESS |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics | 316 ms | 344 ms | +28 ms | 8.9% | REGRESS |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/bucket_stats | 39 ms | 42 ms | +3 ms | 7.7% | REGRESS |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | 261 ms | 284 ms | +23 ms | 8.8% | REGRESS |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/group_calc | 5 ms | 6 ms | +1 ms | 20.0% | REGRESS |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/untimed | 8 ms | 9 ms | +1000 us | 12.5% | REGRESS |
| multi-day-custom-logs-sort-skewness | TIMING/render/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| multi-day-custom-logs-sort-skewness | TIMING/total | 16.3 s | 17.9 s | +1.5 s | 9.4% | REGRESS |
| multi-day-custom-logs-sort-skewness | MEMORY/rss_peak | 175.3 MB | 177.9 MB | +2.5 MB | 1.5% | REGRESS |
| multi-day-custom-logs-sort-skewness | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/format_scan_subs | 1.1 MB | 1 MB | -80 KB | -7.1% | IMPROVE |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_analysis | 12.9 MB | 12.9 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_messages | 89.5 MB | 89.4 MB | -127.2 KB | -0.1% | IMPROVE |
| multi-day-custom-logs-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_stats | 50.3 KB | 50.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_users | 12.7 KB | 12.7 KB | +64 B | 0.5% | REGRESS |
| multi-day-custom-logs-sort-skewness | MEMORY/message_key_order | 2.5 KB | 2.5 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/unattributed | 71.7 MB | 74.5 MB | +2.7 MB | 3.8% | REGRESS |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/log_messages | 93859739 | 93729435 | -130304 | -0.1% | IMPROVE |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/log_analysis | 20350 | 20350 | 0 | 0.0% |  |
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
| single-day-access-log-standard | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| single-day-access-log-standard | TIMING/detect/scan_sub_compile | 6 ms | 7 ms | +1 ms | 16.7% | REGRESS |
| single-day-access-log-standard | TIMING/parse/read_files | 8.5 s | 9.3 s | +732 ms | 8.6% | REGRESS |
| single-day-access-log-standard | TIMING/finalize/calculate_statistics | 97 ms | 102 ms | +5 ms | 5.2% | REGRESS |
| single-day-access-log-standard | TIMING/finalize/calculate_statistics/bucket_stats | 68 ms | 72 ms | +4 ms | 5.9% | REGRESS |
| single-day-access-log-standard | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-access-log-standard | TIMING/finalize/calculate_statistics/group_calc | 23 ms | 24 ms | +1 ms | 4.3% | REGRESS |
| single-day-access-log-standard | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-standard | TIMING/total | 8.7 s | 9.4 s | +738 ms | 8.5% | REGRESS |
| single-day-access-log-standard | MEMORY/rss_peak | 99.6 MB | 101.2 MB | +1.7 MB | 1.7% | REGRESS |
| single-day-access-log-standard | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | +32 KB | 2.9% | REGRESS |
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
| single-day-access-log-standard | MEMORY/log_messages | 26.9 MB | 26.9 MB | -128 B | -0.0% | IMPROVE |
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
| single-day-access-log-standard | MEMORY/unattributed | 47.9 MB | 49.6 MB | +1.6 MB | 3.4% | REGRESS |
| single-day-access-log-standard | MEMORY_FINAL/log_messages | 28180482 | 28180354 | -128 | -0.0% | IMPROVE |
| single-day-access-log-standard | MEMORY_FINAL/log_analysis | 6678 | 6678 | 0 | 0.0% |  |
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
| single-day-access-log-no-messages | TIMING/detect/registry_build | 12 ms | 13 ms | +1000 us | 8.3% | REGRESS |
| single-day-access-log-no-messages | TIMING/detect/scan_sub_compile | 6 ms | 7 ms | +1 ms | 16.7% | REGRESS |
| single-day-access-log-no-messages | TIMING/parse/read_files | 6.5 s | 6.9 s | +388 ms | 5.9% | REGRESS |
| single-day-access-log-no-messages | TIMING/finalize/calculate_statistics | 66 ms | 69 ms | +3 ms | 4.5% | REGRESS |
| single-day-access-log-no-messages | TIMING/finalize/calculate_statistics/bucket_stats | 66 ms | 69 ms | +3 ms | 4.5% | REGRESS |
| single-day-access-log-no-messages | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-no-messages | TIMING/total | 6.6 s | 7 s | +391 ms | 5.9% | REGRESS |
| single-day-access-log-no-messages | MEMORY/rss_peak | 64.7 MB | 67.3 MB | +2.6 MB | 4.1% | REGRESS |
| single-day-access-log-no-messages | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | 0 B | 0.0% |  |
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
| single-day-access-log-no-messages | MEMORY/unattributed | 39.9 MB | 42.5 MB | +2.6 MB | 6.6% | REGRESS |
| single-day-access-log-no-messages | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| single-day-access-log-no-messages | MEMORY_FINAL/log_analysis | 6678 | 6678 | 0 | 0.0% |  |
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
| single-day-access-log-top25 | TIMING/detect/registry_build | 12 ms | 13 ms | +1000 us | 8.3% | REGRESS |
| single-day-access-log-top25 | TIMING/detect/scan_sub_compile | 6 ms | 7 ms | +1 ms | 16.7% | REGRESS |
| single-day-access-log-top25 | TIMING/parse/read_files | 8.5 s | 9.3 s | +817 ms | 9.6% | REGRESS |
| single-day-access-log-top25 | TIMING/finalize/calculate_statistics | 105 ms | 112 ms | +7 ms | 6.7% | REGRESS |
| single-day-access-log-top25 | TIMING/finalize/calculate_statistics/bucket_stats | 69 ms | 73 ms | +4 ms | 5.8% | REGRESS |
| single-day-access-log-top25 | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25 | TIMING/finalize/calculate_statistics/group_calc | 31 ms | 33 ms | +2 ms | 6.5% | REGRESS |
| single-day-access-log-top25 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25 | TIMING/total | 8.6 s | 9.5 s | +825 ms | 9.5% | REGRESS |
| single-day-access-log-top25 | MEMORY/rss_peak | 99.8 MB | 100.6 MB | +768 KB | 0.8% | REGRESS |
| single-day-access-log-top25 | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | +16 KB | 1.4% | REGRESS |
| single-day-access-log-top25 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_analysis | 23.6 MB | 23.6 MB | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_messages | 26.9 MB | 26.9 MB | 0 B | 0.0% |  |
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
| single-day-access-log-top25 | MEMORY/unattributed | 48.1 MB | 48.9 MB | +752 KB | 1.5% | REGRESS |
| single-day-access-log-top25 | MEMORY_FINAL/log_messages | 28188642 | 28188642 | 0 | 0.0% |  |
| single-day-access-log-top25 | MEMORY_FINAL/log_analysis | 6678 | 6678 | 0 | 0.0% |  |
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
| single-day-access-log-top25-consolidate | TIMING/detect/registry_build | 12 ms | 13 ms | +1000 us | 8.3% | REGRESS |
| single-day-access-log-top25-consolidate | TIMING/detect/scan_sub_compile | 6 ms | 7 ms | +1 ms | 16.7% | REGRESS |
| single-day-access-log-top25-consolidate | TIMING/parse/read_files | 9.5 s | 10.2 s | +751 ms | 7.9% | REGRESS |
| single-day-access-log-top25-consolidate | TIMING/finalize/group_similar | 2.2 s | 2.6 s | +370 ms | 16.9% | REGRESS |
| single-day-access-log-top25-consolidate | TIMING/finalize/calculate_statistics | 142 ms | 161 ms | +19 ms | 13.4% | REGRESS |
| single-day-access-log-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | 79 ms | 88 ms | +9 ms | 11.4% | REGRESS |
| single-day-access-log-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | 62 ms | 71 ms | +9 ms | 14.5% | REGRESS |
| single-day-access-log-top25-consolidate | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/total | 11.8 s | 13.0 s | +1.1 s | 9.6% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/rss_peak | 132.8 MB | 130.5 MB | -2.3 MB | -1.7% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_clusters | 22 MB | 22.0 MB | -19.5 KB | -0.1% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_id_index | 8.5 MB | 8.5 MB | +7 KB | 0.1% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_message | 888 KB | 888 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_trigrams | 4.1 MB | 4.1 MB | +7 KB | 0.2% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_patterns | 119.4 KB | 119.4 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_unmatched | 565.2 KB | 565.2 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | +64 KB | 5.8% | REGRESS |
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
| single-day-access-log-top25-consolidate | MEMORY/log_messages | 26.9 MB | 26.9 MB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_stats | 27.6 KB | 27.6 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/message_key_order | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/unattributed | 45 MB | 42.7 MB | -2.3 MB | -5.2% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/log_messages | 25749074 | 25749074 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/log_analysis | 6678 | 6678 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 23087425 | 23067457 | -19968 | -0.1% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 122293 | 122293 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 304 | 304 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 16440 | 16440 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/log_messages_entries | 656 | 656 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/log_occurrences_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/log_stats_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/log_analysis_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/log_messages_population | 656 | 656 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap | TIMING/detect/scan_sub_compile | 6 ms | 7 ms | +1 ms | 16.7% | REGRESS |
| single-day-access-log-heatmap | TIMING/parse/read_files | 9.3 s | 10.1 s | +785 ms | 8.5% | REGRESS |
| single-day-access-log-heatmap | TIMING/finalize/calculate_statistics | 28 ms | 31 ms | +3 ms | 10.7% | REGRESS |
| single-day-access-log-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 6 ms | +1 ms | 20.0% | REGRESS |
| single-day-access-log-heatmap | TIMING/finalize/calculate_statistics/group_calc | 23 ms | 25 ms | +2 ms | 8.7% | REGRESS |
| single-day-access-log-heatmap | TIMING/finalize/heatmap_statistics | 30 ms | 32 ms | +2 ms | 6.7% | REGRESS |
| single-day-access-log-heatmap | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap | TIMING/total | 9.3 s | 10.1 s | +790 ms | 8.5% | REGRESS |
| single-day-access-log-heatmap | MEMORY/rss_peak | 82.9 MB | 83.3 MB | +384 KB | 0.5% | REGRESS |
| single-day-access-log-heatmap | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/format_scan_subs | 1.1 MB | 1 MB | -80 KB | -7.1% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/heatmap_counters | 572.2 KB | 572.2 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_data | 34 KB | 34 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_analysis | 8.1 KB | 8.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_messages | 26.9 MB | 26.9 MB | 0 B | 0.0% |  |
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
| single-day-access-log-heatmap | MEMORY/unattributed | 54.3 MB | 54.8 MB | +464 KB | 0.8% | REGRESS |
| single-day-access-log-heatmap | MEMORY_FINAL/log_messages | 28180482 | 28180482 | 0 | 0.0% |  |
| single-day-access-log-heatmap | MEMORY_FINAL/log_analysis | 6678 | 6678 | 0 | 0.0% |  |
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
| single-day-access-log-histogram | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/detect/scan_sub_compile | 6 ms | 7 ms | +1 ms | 16.7% | REGRESS |
| single-day-access-log-histogram | TIMING/parse/read_files | 10.5 s | 11.4 s | +885 ms | 8.5% | REGRESS |
| single-day-access-log-histogram | TIMING/finalize/calculate_statistics | 97 ms | 104 ms | +7 ms | 7.2% | REGRESS |
| single-day-access-log-histogram | TIMING/finalize/calculate_statistics/bucket_stats | 69 ms | 73 ms | +4 ms | 5.8% | REGRESS |
| single-day-access-log-histogram | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 6 ms | +1 ms | 20.0% | REGRESS |
| single-day-access-log-histogram | TIMING/finalize/calculate_statistics/group_calc | 23 ms | 25 ms | +2 ms | 8.7% | REGRESS |
| single-day-access-log-histogram | TIMING/finalize/histogram_statistics | 11 ms | 13 ms | +2 ms | 18.2% | REGRESS |
| single-day-access-log-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/total | 10.6 s | 11.5 s | +893 ms | 8.4% | REGRESS |
| single-day-access-log-histogram | MEMORY/rss_peak | 99.4 MB | 101.5 MB | +2 MB | 2.0% | REGRESS |
| single-day-access-log-histogram | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | -16 KB | -1.4% | IMPROVE |
| single-day-access-log-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/histogram_counters | 105.8 KB | 105.9 KB | +128 B | 0.1% | REGRESS |
| single-day-access-log-histogram | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_analysis | 23.6 MB | 23.6 MB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_messages | 26.9 MB | 26.9 MB | 0 B | 0.0% |  |
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
| single-day-access-log-histogram | MEMORY/unattributed | 47.7 MB | 49.7 MB | +2 MB | 4.3% | REGRESS |
| single-day-access-log-histogram | MEMORY_FINAL/log_messages | 28180482 | 28180482 | 0 | 0.0% |  |
| single-day-access-log-histogram | MEMORY_FINAL/log_analysis | 6678 | 6678 | 0 | 0.0% |  |
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
| single-day-access-log-heatmap-histogram | TIMING/detect/registry_build | 12 ms | 13 ms | +1000 us | 8.3% | REGRESS |
| single-day-access-log-heatmap-histogram | TIMING/detect/scan_sub_compile | 6 ms | 7 ms | +1 ms | 16.7% | REGRESS |
| single-day-access-log-heatmap-histogram | TIMING/parse/read_files | 11 s | 11.9 s | +851 ms | 7.7% | REGRESS |
| single-day-access-log-heatmap-histogram | TIMING/finalize/calculate_statistics | 28 ms | 31 ms | +3 ms | 10.7% | REGRESS |
| single-day-access-log-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 5 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/finalize/calculate_statistics/group_calc | 23 ms | 25 ms | +2 ms | 8.7% | REGRESS |
| single-day-access-log-heatmap-histogram | TIMING/finalize/heatmap_statistics | 30 ms | 31 ms | +1 ms | 3.3% | REGRESS |
| single-day-access-log-heatmap-histogram | TIMING/finalize/histogram_statistics | 11 ms | 12 ms | +1 ms | 9.1% | REGRESS |
| single-day-access-log-heatmap-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/total | 11.1 s | 12.0 s | +857 ms | 7.7% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/rss_peak | 83.9 MB | 83.5 MB | -416 KB | -0.5% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/format_scan_subs | 1.1 MB | 1.2 MB | +48 KB | 4.2% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_counters | 571.2 KB | 572.2 KB | +960 B | 0.2% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_data | 34 KB | 34 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_counters | 105.9 KB | 106 KB | +128 B | 0.1% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_analysis | 8.1 KB | 8.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_messages | 26.9 MB | 26.9 MB | +6.9 KB | 0.0% | REGRESS |
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
| single-day-access-log-heatmap-histogram | MEMORY/unattributed | 55.2 MB | 54.7 MB | -471.9 KB | -0.8% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/log_messages | 28173442 | 28180482 | 7040 | 0.0% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/log_analysis | 6678 | 6678 | 0 | 0.0% |  |
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
| single-day-access-log-heatmap-histogram-export | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | TIMING/detect/scan_sub_compile | 6 ms | 7 ms | +1 ms | 16.7% | REGRESS |
| single-day-access-log-heatmap-histogram-export | TIMING/parse/read_files | 9.5 s | 10.1 s | +647 ms | 6.8% | REGRESS |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/calculate_statistics | 182 ms | 191 ms | +9 ms | 4.9% | REGRESS |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/calculate_statistics/bucket_stats | 182 ms | 191 ms | +9 ms | 4.9% | REGRESS |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/heatmap_statistics | 97 ms | 102 ms | +5 ms | 5.2% | REGRESS |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/histogram_statistics | 11 ms | 11 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | TIMING/total | 9.8 s | 10.4 s | +662 ms | 6.8% | REGRESS |
| single-day-access-log-heatmap-histogram-export | MEMORY/rss_peak | 68 MB | 69.8 MB | +1.8 MB | 2.6% | REGRESS |
| single-day-access-log-heatmap-histogram-export | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/format_scan_subs | 1.1 MB | 1 MB | -64 KB | -5.7% | IMPROVE |
| single-day-access-log-heatmap-histogram-export | MEMORY/heatmap_counters | 572.2 KB | 571.2 KB | -960 B | -0.2% | IMPROVE |
| single-day-access-log-heatmap-histogram-export | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/heatmap_data | 34 KB | 34 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/histogram_counters | 106 KB | 105.9 KB | -128 B | -0.1% | IMPROVE |
| single-day-access-log-heatmap-histogram-export | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_analysis | 23.6 MB | 23.6 MB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_messages | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_stats | 41.3 KB | 41.3 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/unattributed | 42.5 MB | 44.3 MB | +1.8 MB | 4.3% | REGRESS |
| single-day-access-log-heatmap-histogram-export | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY_FINAL/log_analysis | 12095 | 12095 | 0 | 0.0% |  |
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
| single-day-access-log-heatmap-histogram-export | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/detect/registry_build | 12 ms | 13 ms | +1000 us | 8.3% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 6 ms | 7 ms | +1 ms | 16.7% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/parse/read_files | 12.0 s | 12.9 s | +871 ms | 7.3% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 1.7 s | 1.9 s | +281 ms | 16.8% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 74 ms | 85 ms | +11 ms | 14.9% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | 72 ms | 84 ms | +12 ms | 16.7% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/heatmap_statistics | 30 ms | 32 ms | +2 ms | 6.7% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/histogram_statistics | 11 ms | 12 ms | +1 ms | 9.1% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/render/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/total | 13.8 s | 14.9 s | +1.2 s | 8.5% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 113.3 MB | 115.2 MB | +2.0 MB | 1.7% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 22 MB | 22 MB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_id_index | 8.5 MB | 8.5 MB | -10.5 KB | -0.1% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 888 KB | 888 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 4.1 MB | 4.1 MB | -10.5 KB | -0.2% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 119.4 KB | 119.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 565.2 KB | 565.2 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 572.2 KB | 570.3 KB | -1.9 KB | -0.3% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_data | 34 KB | 34 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_counters | 106 KB | 105.8 KB | -256 B | -0.2% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_analysis | 8.1 KB | 8.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_messages | 26.9 MB | 26.9 MB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_stats | 18.2 KB | 18.2 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/message_key_order | 1.9 KB | 1.9 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/unattributed | 48.4 MB | 50.4 MB | +2.0 MB | 4.1% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 25740914 | 25740914 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 6678 | 6678 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 23087425 | 23087425 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 122293 | 122293 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 304 | 304 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 16440 | 16440 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 656 | 656 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_analysis_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_messages_population | 656 | 656 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/detect/scan_sub_compile | 6 ms | 7 ms | +1 ms | 16.7% | REGRESS |
| single-day-access-log-sort-p99 | TIMING/parse/read_files | 8.5 s | 9.2 s | +662 ms | 7.8% | REGRESS |
| single-day-access-log-sort-p99 | TIMING/finalize/calculate_statistics | 129 ms | 139 ms | +10 ms | 7.8% | REGRESS |
| single-day-access-log-sort-p99 | TIMING/finalize/calculate_statistics/bucket_stats | 68 ms | 72 ms | +4 ms | 5.9% | REGRESS |
| single-day-access-log-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | 59 ms | 65 ms | +6 ms | 10.2% | REGRESS |
| single-day-access-log-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| single-day-access-log-sort-p99 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/total | 8.7 s | 9.3 s | +673 ms | 7.8% | REGRESS |
| single-day-access-log-sort-p99 | MEMORY/rss_peak | 98.9 MB | 99.4 MB | +512 KB | 0.5% | REGRESS |
| single-day-access-log-sort-p99 | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | +32 KB | 2.8% | REGRESS |
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
| single-day-access-log-sort-p99 | MEMORY/log_messages | 26.9 MB | 26.9 MB | 0 B | 0.0% |  |
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
| single-day-access-log-sort-p99 | MEMORY/unattributed | 47.2 MB | 47.7 MB | +480 KB | 1.0% | REGRESS |
| single-day-access-log-sort-p99 | MEMORY_FINAL/log_messages | 28180482 | 28180482 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY_FINAL/log_analysis | 6678 | 6678 | 0 | 0.0% |  |
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
| single-day-access-log-sort-skewness | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-skewness | TIMING/detect/scan_sub_compile | 6 ms | 7 ms | +1 ms | 16.7% | REGRESS |
| single-day-access-log-sort-skewness | TIMING/parse/read_files | 8.5 s | 9.2 s | +644 ms | 7.5% | REGRESS |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics | 250 ms | 265 ms | +15 ms | 6.0% | REGRESS |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics/bucket_stats | 68 ms | 73 ms | +5 ms | 7.4% | REGRESS |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | 178 ms | 187 ms | +9 ms | 5.1% | REGRESS |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics/group_calc | 4 ms | 4 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-skewness | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-skewness | TIMING/total | 8.8 s | 9.5 s | +659 ms | 7.5% | REGRESS |
| single-day-access-log-sort-skewness | MEMORY/rss_peak | 103.9 MB | 104.9 MB | +1 MB | 1.0% | REGRESS |
| single-day-access-log-sort-skewness | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | +64 KB | 5.8% | REGRESS |
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
| single-day-access-log-sort-skewness | MEMORY/log_messages | 26.9 MB | 26.9 MB | 0 B | 0.0% |  |
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
| single-day-access-log-sort-skewness | MEMORY/unattributed | 52.3 MB | 53.2 MB | +976 KB | 1.8% | REGRESS |
| single-day-access-log-sort-skewness | MEMORY_FINAL/log_messages | 28182055 | 28182055 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY_FINAL/log_analysis | 6678 | 6678 | 0 | 0.0% |  |
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
| month-single-server-access-logs-standard | TIMING/detect/registry_build | 12 ms | 13 ms | +1000 us | 8.3% | REGRESS |
| month-single-server-access-logs-standard | TIMING/detect/scan_sub_compile | 13 ms | 14 ms | +1 ms | 7.7% | REGRESS |
| month-single-server-access-logs-standard | TIMING/parse/read_files | 1.6 min | 1.7 min | +7.2 s | 7.6% | REGRESS |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics | 4.2 s | 4.4 s | +224 ms | 5.3% | REGRESS |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics/bucket_stats | 2.2 s | 2.4 s | +198 ms | 9.0% | REGRESS |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics/sort_selection | 1.6 s | 1.6 s | -6 ms | -0.4% | IMPROVE |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics/group_calc | 324 ms | 352 ms | +28 ms | 8.6% | REGRESS |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics/untimed | 61 ms | 65 ms | +4 ms | 6.6% | REGRESS |
| month-single-server-access-logs-standard | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/total | 1.6 min | 1.8 min | +7.4 s | 7.5% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/rss_peak | 2 GB | 2 GB | +4.2 MB | 0.2% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/format_scan_subs | 1.8 MB | 1.9 MB | +80 KB | 4.2% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_analysis | 244 MB | 244 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_messages | 1.5 GB | 1.5 GB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_occurrences | 36.8 KB | 36.6 KB | -192 B | -0.5% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/log_sessions | 2.2 MB | 2.2 MB | +128 B | 0.0% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/unattributed | 312.3 MB | 316.5 MB | +4.2 MB | 1.3% | REGRESS |
| month-single-server-access-logs-standard | MEMORY_FINAL/log_messages | 1567835635 | 1567835635 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY_FINAL/log_analysis | 13018 | 13018 | 0 | 0.0% |  |
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
| month-single-server-access-logs-no-messages | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-no-messages | TIMING/detect/scan_sub_compile | 13 ms | 13 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-no-messages | TIMING/parse/read_files | 1.2 min | 1.2 min | +3.5 s | 4.9% | REGRESS |
| month-single-server-access-logs-no-messages | TIMING/finalize/calculate_statistics | 1.5 s | 1.8 s | +240 ms | 15.6% | REGRESS |
| month-single-server-access-logs-no-messages | TIMING/finalize/calculate_statistics/bucket_stats | 1.5 s | 1.8 s | +240 ms | 15.6% | REGRESS |
| month-single-server-access-logs-no-messages | TIMING/finalize/calculate_statistics/untimed | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-no-messages | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-no-messages | TIMING/total | 1.2 min | 1.3 min | +3.7 s | 5.2% | REGRESS |
| month-single-server-access-logs-no-messages | MEMORY/rss_peak | 370.2 MB | 372.2 MB | +2.0 MB | 0.5% | REGRESS |
| month-single-server-access-logs-no-messages | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/format_scan_subs | 2.0 MB | 2.0 MB | -32 KB | -1.6% | IMPROVE |
| month-single-server-access-logs-no-messages | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/log_analysis | 241.5 MB | 241.5 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/log_messages | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/log_occurrences | 36.6 KB | 36.8 KB | +192 B | 0.5% | REGRESS |
| month-single-server-access-logs-no-messages | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/unattributed | 124.4 MB | 126.4 MB | +2.0 MB | 1.6% | REGRESS |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/log_analysis | 13018 | 13018 | 0 | 0.0% |  |
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
| month-single-server-access-logs-top25 | TIMING/detect/registry_build | 12 ms | 13 ms | +1000 us | 8.3% | REGRESS |
| month-single-server-access-logs-top25 | TIMING/detect/scan_sub_compile | 13 ms | 14 ms | +1 ms | 7.7% | REGRESS |
| month-single-server-access-logs-top25 | TIMING/parse/read_files | 1.6 min | 1.7 min | +7.4 s | 7.8% | REGRESS |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics | 4.3 s | 4.5 s | +243 ms | 5.6% | REGRESS |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics/bucket_stats | 2.2 s | 2.3 s | +127 ms | 5.7% | REGRESS |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics/sort_selection | 1.6 s | 1.6 s | +70 ms | 4.5% | REGRESS |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics/group_calc | 476 ms | 518 ms | +42 ms | 8.8% | REGRESS |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics/untimed | 61 ms | 65 ms | +4 ms | 6.6% | REGRESS |
| month-single-server-access-logs-top25 | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/total | 1.7 min | 1.8 min | +7.7 s | 7.7% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/rss_peak | 2 GB | 2 GB | +3.5 MB | 0.2% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/format_scan_subs | 1.9 MB | 1.9 MB | +16 KB | 0.8% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_analysis | 244 MB | 244 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_messages | 1.5 GB | 1.5 GB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_occurrences | 36.8 KB | 36.8 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/message_key_order | 4.7 KB | 4.7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/unattributed | 312.2 MB | 315.7 MB | +3.5 MB | 1.1% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY_FINAL/log_messages | 1567846163 | 1567846163 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY_FINAL/log_analysis | 13018 | 13018 | 0 | 0.0% |  |
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
| month-single-server-access-logs-top25-consolidate | TIMING/detect/registry_build | 13 ms | 13 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/detect/scan_sub_compile | 14 ms | 15 ms | +1000 us | 7.1% | REGRESS |
| month-single-server-access-logs-top25-consolidate | TIMING/parse/read_files | 2.0 min | 2.1 min | +7.8 s | 6.7% | REGRESS |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/group_similar | 45.0 s | 48.5 s | +3.5 s | 7.7% | REGRESS |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics | 4.6 s | 5.5 s | +876 ms | 19.1% | REGRESS |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | 2.6 s | 3.2 s | +643 ms | 24.9% | REGRESS |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | 2.0 s | 2.2 s | +229 ms | 11.5% | REGRESS |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/untimed | 2 ms | 6 ms | +4 ms | 200.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/total | 2.8 min | 3.0 min | +12.2 s | 7.3% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | 928.7 MB | 807.7 MB | -121.0 MB | -13.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_clusters | 211.8 MB | 211.7 MB | -35.9 KB | -0.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_id_index | 46.3 MB | 49.6 MB | +3.4 MB | 7.3% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_message | 2.1 MB | 2.1 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 23.6 MB | 26.3 MB | +2.7 MB | 11.6% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_patterns | 259 KB | 259 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | 1.4 MB | 1.4 MB | +128 B | 0.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/format_scan_subs | 1.8 MB | 1.8 MB | +16 KB | 0.9% | REGRESS |
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
| month-single-server-access-logs-top25-consolidate | MEMORY/log_messages | 242.2 MB | 242.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_occurrences | 36.8 KB | 36.6 KB | -192 B | -0.5% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/message_key_order | 4.2 KB | 4.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/unattributed | 154.8 MB | 27.8 MB | -127 MB | -82.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/log_messages | 253943067 | 253943067 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 13018 | 13018 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 222042053 | 222005253 | -36800 | -0.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 231512 | 231512 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 432 | 304 | -128 | -29.6% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_messages_entries | 1184 | 1184 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_messages_population | 1184 | 1184 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/format_scan_subs_compiled | 2 | 2 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/detect/registry_build | 12 ms | 13 ms | +1000 us | 8.3% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/detect/scan_sub_compile | 13 ms | 14 ms | +1 ms | 7.7% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/parse/read_files | 1.7 min | 1.9 min | +9.6 s | 9.2% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/finalize/calculate_statistics | 1.8 s | 2 s | +287 ms | 16.3% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 1.4 s | 1.7 s | +261 ms | 18.6% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/finalize/calculate_statistics/group_calc | 283 ms | 301 ms | +18 ms | 6.4% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/finalize/calculate_statistics/untimed | 73 ms | 81 ms | +8 ms | 11.0% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/finalize/heatmap_statistics | 107 ms | 112 ms | +5 ms | 4.7% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/total | 1.8 min | 1.9 min | +9.9 s | 9.3% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/rss_peak | 1.8 GB | 1.8 GB | +9.5 MB | 0.5% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/format_scan_subs | 2.0 MB | 1.9 MB | -32 KB | -1.6% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_counters | 2.4 MB | 2.4 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_data | 77.4 KB | 78.4 KB | +1 KB | 1.3% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_analysis | 15.3 KB | 15.3 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_messages | 1.5 GB | 1.5 GB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_occurrences | 36.8 KB | 36.6 KB | -192 B | -0.5% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_stats | 35.0 KB | 35.0 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/unattributed | 317.7 MB | 327.2 MB | +9.5 MB | 3.0% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/log_messages | 1567835155 | 1567835155 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/log_analysis | 12602 | 12602 | 0 | 0.0% |  |
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
| month-single-server-access-logs-histogram | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/detect/scan_sub_compile | 13 ms | 14 ms | +1 ms | 7.7% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/parse/read_files | 2.0 min | 2.1 min | +9.3 s | 7.9% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics | 4.2 s | 4.5 s | +270 ms | 6.5% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics/bucket_stats | 2.2 s | 2.4 s | +162 ms | 7.2% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics/sort_selection | 1.5 s | 1.6 s | +84 ms | 5.4% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics/group_calc | 328 ms | 351 ms | +23 ms | 7.0% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics/untimed | 65 ms | 67 ms | +2 ms | 3.1% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/finalize/histogram_statistics | 19 ms | 19 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/total | 2 min | 2.2 min | +9.5 s | 7.9% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/rss_peak | 1.9 GB | 1.9 GB | +5.0 MB | 0.3% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/format_scan_subs | 1.9 MB | 1.9 MB | +16 KB | 0.8% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/histogram_counters | 295.9 KB | 295.9 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_analysis | 244 MB | 244 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_messages | 1.4 GB | 1.4 GB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_occurrences | 36.8 KB | 36.8 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_sessions | 2.2 MB | 2.2 MB | +128 B | 0.0% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/unattributed | 309.7 MB | 314.7 MB | +5.0 MB | 1.6% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY_FINAL/log_messages | 1490250931 | 1490250931 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY_FINAL/log_analysis | 13018 | 13018 | 0 | 0.0% |  |
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
| month-single-server-access-logs-heatmap-histogram | TIMING/detect/registry_build | 12 ms | 14 ms | +2 ms | 16.7% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/detect/scan_sub_compile | 13 ms | 15 ms | +2 ms | 15.4% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/parse/read_files | 2.1 min | 2.2 min | +10.1 s | 8.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics | 1.9 s | 2 s | +74 ms | 3.8% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 1.6 s | 1.6 s | +52 ms | 3.3% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/group_calc | 281 ms | 299 ms | +18 ms | 6.4% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | 74 ms | 78 ms | +4 ms | 5.4% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/heatmap_statistics | 108 ms | 113 ms | +5 ms | 4.6% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/histogram_statistics | 19 ms | 19 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/total | 2.1 min | 2.3 min | +10.2 s | 8.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/rss_peak | 1.8 GB | 1.8 GB | +3.6 MB | 0.2% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/format_scan_subs | 1.9 MB | 1.9 MB | -32 KB | -1.6% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_counters | 2.4 MB | 2.4 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_data | 75.9 KB | 77.4 KB | +1.5 KB | 2.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_counters | 295.9 KB | 295.9 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_analysis | 15.3 KB | 15.3 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_messages | 1.5 GB | 1.5 GB | -1.8 MB | -0.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_occurrences | 36.6 KB | 36.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_sessions | 2.2 MB | 2.2 MB | +128 B | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_stats | 35.0 KB | 35.0 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/unattributed | 319.8 MB | 325.2 MB | +5.4 MB | 1.7% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 1567835155 | 1565922387 | -1912768 | -0.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 12602 | 12602 | 0 | 0.0% |  |
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
| month-single-server-access-logs-heatmap-histogram-export | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/detect/scan_sub_compile | 13 ms | 14 ms | +1 ms | 7.7% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/parse/read_files | 1.8 min | 1.9 min | +7.8 s | 7.5% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics | 2.7 s | 2.9 s | +215 ms | 8.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/bucket_stats | 2.7 s | 2.9 s | +214 ms | 8.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/untimed | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/heatmap_statistics | 223 ms | 234 ms | +11 ms | 4.9% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/histogram_statistics | 18 ms | 19 ms | +1 ms | 5.6% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/render/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/total | 1.8 min | 1.9 min | +8.1 s | 7.5% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/rss_peak | 371.5 MB | 375.8 MB | +4.3 MB | 1.2% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/format_scan_subs | 2.0 MB | 2.0 MB | +16 KB | 0.8% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_counters | 2.4 MB | 2.4 MB | +1.8 KB | 0.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_data | 78.4 KB | 74.9 KB | -3.5 KB | -4.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/histogram_counters | 295.9 KB | 296 KB | +128 B | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_analysis | 241.6 MB | 241.6 MB | +1.8 KB | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_messages | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_occurrences | 36.6 KB | 36.8 KB | +192 B | 0.5% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_stats | 82.5 KB | 82.5 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/unattributed | 122.9 MB | 127.2 MB | +4.3 MB | 3.5% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY_FINAL/log_analysis | 21219 | 23011 | 1792 | 8.4% | REGRESS |
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
| month-single-server-access-logs-heatmap-histogram-export | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 13 ms | 13 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/parse/read_files | 2.4 min | 2.7 min | +16.3 s | 11.4% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 31.2 s | 35.3 s | +4.1 s | 13.2% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 1.9 s | 2.3 s | +431 ms | 22.9% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | 1.9 s | 2.3 s | +431 ms | 23.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/untimed | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/heatmap_statistics | 96 ms | 103 ms | +7 ms | 7.3% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/histogram_statistics | 19 ms | 22 ms | +3 ms | 15.8% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/render/normalize_data | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | 2.9 min | 3.3 min | +20.9 s | 11.8% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 640.1 MB | 697.1 MB | +56.9 MB | 8.9% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 211.7 MB | 211.7 MB | -64 B | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_id_index | 49.6 MB | 49.6 MB | -1 KB | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 2.1 MB | 2.1 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 26.3 MB | 26.3 MB | -1 KB | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 259 KB | 259 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 1.4 MB | 1.4 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 1.8 MB | 1.9 MB | +48 KB | 2.5% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 2.4 MB | 2.4 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 77.9 KB | 78.4 KB | +512 B | 0.6% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | 295.9 KB | 295.9 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 15.3 KB | 15.3 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 242.2 MB | 242.2 MB | +17.3 KB | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 36.6 KB | 36.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 35.0 KB | 35.0 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | 1.9 KB | 1.9 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/unattributed | 99.7 MB | 156.6 MB | +56.9 MB | 57.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 253921339 | 253939067 | 17728 | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 12602 | 12602 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 222005253 | 222005189 | -64 | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 231512 | 231512 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 432 | 432 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 1184 | 1184 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_population | 1184 | 1184 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 2 | 2 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/format_scan_sub_cache_hits | 27 | 27 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | TIMING/detect/registry_build | 12 ms | 14 ms | +2 ms | 16.7% | REGRESS |
| month-single-server-access-logs-sort-p99 | TIMING/detect/scan_sub_compile | 13 ms | 14 ms | +1 ms | 7.7% | REGRESS |
| month-single-server-access-logs-sort-p99 | TIMING/parse/read_files | 1.6 min | 1.7 min | +10.3 s | 10.9% | REGRESS |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics | 10.1 s | 12.2 s | +2.2 s | 21.4% | REGRESS |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/bucket_stats | 2.3 s | 2.9 s | +621 ms | 27.5% | REGRESS |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | 4.7 s | 5.4 s | +739 ms | 15.8% | REGRESS |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 3 s | 3.8 s | +763 ms | 25.1% | REGRESS |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/group_calc | 9 ms | 10 ms | +1 ms | 11.1% | REGRESS |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/untimed | 116 ms | 147 ms | +31 ms | 26.7% | REGRESS |
| month-single-server-access-logs-sort-p99 | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-sort-p99 | TIMING/total | 1.7 min | 2.0 min | +12.5 s | 11.9% | REGRESS |
| month-single-server-access-logs-sort-p99 | MEMORY/rss_peak | 2.2 GB | 2.2 GB | +2.3 MB | 0.1% | REGRESS |
| month-single-server-access-logs-sort-p99 | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/format_scan_subs | 1.9 MB | 1.9 MB | +32 KB | 1.7% | REGRESS |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/log_analysis | 244 MB | 244 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/log_messages | 1.6 GB | 1.6 GB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/log_occurrences | 36.8 KB | 36.6 KB | -192 B | -0.5% | IMPROVE |
| month-single-server-access-logs-sort-p99 | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/unattributed | 380.0 MB | 382.3 MB | +2.3 MB | 0.6% | REGRESS |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/log_messages | 1672623763 | 1672623763 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/log_analysis | 13018 | 13018 | 0 | 0.0% |  |
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
| month-single-server-access-logs-sort-skewness | TIMING/detect/registry_build | 12 ms | 13 ms | +1000 us | 8.3% | REGRESS |
| month-single-server-access-logs-sort-skewness | TIMING/detect/scan_sub_compile | 13 ms | 14 ms | +1 ms | 7.7% | REGRESS |
| month-single-server-access-logs-sort-skewness | TIMING/parse/read_files | 1.6 min | 1.7 min | +9.6 s | 10.1% | REGRESS |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics | 5.9 s | 7.6 s | +1.6 s | 27.9% | REGRESS |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/bucket_stats | 2.2 s | 2.8 s | +576 ms | 26.1% | REGRESS |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | 3.4 s | 4.4 s | +996 ms | 29.2% | REGRESS |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 13 ms | 19 ms | +6 ms | 46.2% | REGRESS |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/group_calc | 212 ms | 269 ms | +57 ms | 26.9% | REGRESS |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/untimed | 65 ms | 79 ms | +14 ms | 21.5% | REGRESS |
| month-single-server-access-logs-sort-skewness | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-sort-skewness | TIMING/total | 1.7 min | 1.9 min | +11.2 s | 11.1% | REGRESS |
| month-single-server-access-logs-sort-skewness | MEMORY/rss_peak | 2.1 GB | 2.1 GB | +1 MB | 0.0% | REGRESS |
| month-single-server-access-logs-sort-skewness | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/format_scan_subs | 2.0 MB | 1.9 MB | -16 KB | -0.8% | IMPROVE |
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
| month-single-server-access-logs-sort-skewness | MEMORY/log_messages | 1.6 GB | 1.6 GB | 0 B | 0.0% |  |
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
| month-single-server-access-logs-sort-skewness | MEMORY/unattributed | 288.8 MB | 289.9 MB | +1.1 MB | 0.4% | REGRESS |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/log_messages | 1670604024 | 1670604024 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/log_analysis | 13018 | 13018 | 0 | 0.0% |  |
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
| month-many-servers-access-logs-standard | TIMING/detect/registry_build | 12 ms | 13 ms | +1000 us | 8.3% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/detect/scan_sub_compile | 20 ms | 22 ms | +2 ms | 10.0% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/parse/read_files | 7.9 min | 8.5 min | +36.0 s | 7.6% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics | 24.5 s | 26.4 s | +1.9 s | 7.8% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics/bucket_stats | 13.1 s | 14.0 s | +808 ms | 6.1% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics/sort_selection | 8.9 s | 9.8 s | +886 ms | 9.9% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics/group_calc | 2.1 s | 2.2 s | +182 ms | 8.8% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics/untimed | 392 ms | 421 ms | +29 ms | 7.4% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/render/normalize_data | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-standard | TIMING/total | 8.3 min | 8.9 min | +37.9 s | 7.6% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY/rss_peak | 10.1 GB | 10.1 GB | +5 MB | 0.0% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/format_scan_subs | 2.8 MB | 2.8 MB | +16 KB | 0.6% | REGRESS |
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
| month-many-servers-access-logs-standard | MEMORY/log_messages | 7.5 GB | 7.5 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_occurrences | 43.8 KB | 42.1 KB | -1.8 KB | -4.0% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/log_sessions | 14.9 MB | 14.9 MB | +128 B | 0.0% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/unattributed | 1.4 GB | 1.4 GB | +5 MB | 0.4% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY_FINAL/log_messages | 8019141603 | 8019141603 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY_FINAL/log_analysis | 13018 | 13018 | 0 | 0.0% |  |
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
| month-many-servers-access-logs-no-messages | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-no-messages | TIMING/detect/scan_sub_compile | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| month-many-servers-access-logs-no-messages | TIMING/parse/read_files | 6.0 min | 6.2 min | +12.3 s | 3.5% | REGRESS |
| month-many-servers-access-logs-no-messages | TIMING/finalize/calculate_statistics | 9.7 s | 10.2 s | +515 ms | 5.3% | REGRESS |
| month-many-servers-access-logs-no-messages | TIMING/finalize/calculate_statistics/bucket_stats | 9.6 s | 10.2 s | +515 ms | 5.3% | REGRESS |
| month-many-servers-access-logs-no-messages | TIMING/finalize/calculate_statistics/untimed | 12 ms | 13 ms | +1000 us | 8.3% | REGRESS |
| month-many-servers-access-logs-no-messages | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-no-messages | TIMING/total | 6.1 min | 6.3 min | +12.9 s | 3.5% | REGRESS |
| month-many-servers-access-logs-no-messages | MEMORY/rss_peak | 1.6 GB | 1.6 GB | +43.1 MB | 2.6% | REGRESS |
| month-many-servers-access-logs-no-messages | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/format_scan_subs | 2.8 MB | 2.7 MB | -48 KB | -1.7% | IMPROVE |
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
| month-many-servers-access-logs-no-messages | MEMORY/log_occurrences | 42.1 KB | 43.8 KB | +1.8 KB | 4.2% | REGRESS |
| month-many-servers-access-logs-no-messages | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -128 B | -0.0% | IMPROVE |
| month-many-servers-access-logs-no-messages | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/unattributed | 416.5 MB | 459.7 MB | +43.2 MB | 10.4% | REGRESS |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/log_analysis | 13018 | 13018 | 0 | 0.0% |  |
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
| month-many-servers-access-logs-top25 | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-top25 | TIMING/detect/scan_sub_compile | 20 ms | 21 ms | +1 ms | 5.0% | REGRESS |
| month-many-servers-access-logs-top25 | TIMING/parse/read_files | 7.9 min | 8.4 min | +31.6 s | 6.7% | REGRESS |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics | 25.2 s | 26.1 s | +854 ms | 3.4% | REGRESS |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics/bucket_stats | 13.1 s | 13 s | -117 ms | -0.9% | IMPROVE |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics/sort_selection | 8.6 s | 9.6 s | +1.1 s | 12.3% | REGRESS |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics/group_calc | 3.1 s | 3.1 s | -42 ms | -1.3% | IMPROVE |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics/untimed | 394 ms | 354 ms | -40 ms | -10.2% | IMPROVE |
| month-many-servers-access-logs-top25 | TIMING/render/normalize_data | 4 ms | 2 ms | -2 ms | -50.0% | IMPROVE |
| month-many-servers-access-logs-top25 | TIMING/total | 8.3 min | 8.8 min | +32.5 s | 6.5% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/rss_peak | 10.1 GB | 10.1 GB | +5.9 MB | 0.1% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/format_scan_subs | 2.7 MB | 2.8 MB | +32 KB | 1.1% | REGRESS |
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
| month-many-servers-access-logs-top25 | MEMORY/log_messages | 7.5 GB | 7.5 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_occurrences | 42.1 KB | 43.8 KB | +1.8 KB | 4.2% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/message_key_order | 4.7 KB | 4.7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/unattributed | 1.4 GB | 1.4 GB | +5.9 MB | 0.4% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/log_messages | 8019152067 | 8019152067 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/log_analysis | 13018 | 13018 | 0 | 0.0% |  |
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
| month-many-servers-access-logs-top25-consolidate | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/detect/scan_sub_compile | 20 ms | 20 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/parse/read_files | 9.8 min | 9.9 min | +7.9 s | 1.3% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/group_similar | 6 min | 5.9 min | -7.7 s | -2.1% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics | 26.8 s | 26.8 s | -31 ms | -0.1% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | 14.6 s | 14.5 s | -37 ms | -0.3% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 5 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | 12.2 s | 12.2 s | -3 ms | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/untimed | 15 ms | 25 ms | +10 ms | 66.7% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | TIMING/render/normalize_data | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | 16.3 min | 16.3 min | +91 ms | 0.0% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | 3.4 GB | 3.0 GB | -437.2 MB | -12.6% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_clusters | 1.1 GB | 1.1 GB | -370.4 KB | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_id_index | 50.6 MB | 48.3 MB | -2.3 MB | -4.6% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_message | 2.0 MB | 2.0 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 26.7 MB | 24.4 MB | -2.3 MB | -8.7% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_patterns | 482.4 KB | 482.4 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | 1.3 MB | 1.3 MB | +256 B | 0.0% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/format_scan_subs | 2.5 MB | 2.7 MB | +160 KB | 6.2% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_analysis | 1.2 GB | 1.2 GB | +7.8 MB | 0.6% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_messages | 1.2 GB | 1.2 GB | -447.9 KB | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_occurrences | 43.8 KB | 43.8 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -32 KB | -0.2% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/message_key_order | 4.2 KB | 4.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/log_messages | 1274163633 | 1273705009 | -458624 | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 13018 | 13018 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 1155256263 | 1154876999 | -379264 | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 493990 | 493990 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 432 | 432 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_messages_entries | 2443 | 2443 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_messages_population | 2443 | 2443 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/format_scan_subs_compiled | 3 | 3 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/format_scan_sub_cache_hits | 142 | 142 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/detect/scan_sub_compile | 20 ms | 20 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/parse/read_files | 8.7 min | 8.9 min | +11.6 s | 2.2% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/finalize/calculate_statistics | 11.3 s | 10.4 s | -893 ms | -7.9% | IMPROVE |
| month-many-servers-access-logs-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 9.3 s | 8.4 s | -902 ms | -9.7% | IMPROVE |
| month-many-servers-access-logs-heatmap | TIMING/finalize/calculate_statistics/group_calc | 1.6 s | 1.6 s | -5 ms | -0.3% | IMPROVE |
| month-many-servers-access-logs-heatmap | TIMING/finalize/calculate_statistics/untimed | 424 ms | 439 ms | +15 ms | 3.5% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/finalize/heatmap_statistics | 120 ms | 118 ms | -2 ms | -1.7% | IMPROVE |
| month-many-servers-access-logs-heatmap | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/total | 8.9 min | 9.1 min | +10.7 s | 2.0% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/rss_peak | 8.9 GB | 8.8 GB | -11.4 MB | -0.1% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/format_scan_subs | 2.8 MB | 2.7 MB | -80 KB | -2.8% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_counters | 2.7 MB | 2.7 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_data | 76.3 KB | 76.8 KB | +512 B | 0.7% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_analysis | 15.3 KB | 15.3 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_messages | 7.5 GB | 7.5 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_occurrences | 43.8 KB | 43.8 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_sessions | 14.9 MB | 14.9 MB | +32.1 KB | 0.2% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/log_stats | 35.0 KB | 35.0 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/unattributed | 1.4 GB | 1.4 GB | -11.4 MB | -0.8% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/log_messages | 8014081747 | 8014081747 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/log_analysis | 12602 | 12602 | 0 | 0.0% |  |
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
| month-many-servers-access-logs-histogram | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/detect/scan_sub_compile | 20 ms | 20 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/parse/read_files | 9.7 min | 9.9 min | +10.6 s | 1.8% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics | 24.1 s | 24.2 s | +139 ms | 0.6% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics/bucket_stats | 12.6 s | 12.6 s | -32 ms | -0.3% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics/sort_selection | 9.1 s | 9.2 s | +168 ms | 1.9% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics/group_calc | 2 s | 2 s | +2 ms | 0.1% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics/untimed | 354 ms | 353 ms | -1 ms | -0.3% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/finalize/histogram_statistics | 20 ms | 20 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/render/normalize_data | 2 ms | 4 ms | +2 ms | 100.0% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/total | 10.1 min | 10.3 min | +10.7 s | 1.8% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/rss_peak | 10.1 GB | 10.1 GB | +2.2 MB | 0.0% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/format_scan_subs | 2.7 MB | 2.7 MB | -32 KB | -1.2% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/histogram_counters | 307.8 KB | 307.8 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_analysis | 1.2 GB | 1.2 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_messages | 7.5 GB | 7.5 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_sessions | 14.9 MB | 14.9 MB | +32 KB | 0.2% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/unattributed | 1.4 GB | 1.4 GB | +2.2 MB | 0.2% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/log_messages | 8019141603 | 8019141603 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/log_analysis | 13018 | 13018 | 0 | 0.0% |  |
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
| month-many-servers-access-logs-heatmap-histogram | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/detect/scan_sub_compile | 20 ms | 20 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/parse/read_files | 10.4 min | 10.5 min | +6.0 s | 1.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics | 11.2 s | 11.0 s | -196 ms | -1.8% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 9.1 s | 9.0 s | -174 ms | -1.9% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/group_calc | 1.6 s | 1.6 s | +6 ms | 0.4% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | 447 ms | 419 ms | -28 ms | -6.3% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/heatmap_statistics | 118 ms | 118 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/histogram_statistics | 20 ms | 20 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/render/normalize_data | 4 ms | 5 ms | +1 ms | 25.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/total | 10.6 min | 10.7 min | +5.8 s | 0.9% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/rss_peak | 8.8 GB | 8.8 GB | +2.1 MB | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/format_scan_subs | 2.6 MB | 2.6 MB | -32 KB | -1.2% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_counters | 2.7 MB | 2.7 MB | +1.8 KB | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_data | 74.8 KB | 75.3 KB | +512 B | 0.7% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_counters | 307.7 KB | 307.8 KB | +128 B | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_analysis | 15.3 KB | 15.3 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_messages | 7.5 GB | 7.5 GB | -9.4 MB | -0.1% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_occurrences | 42.1 KB | 43.8 KB | +1.8 KB | 4.2% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_sessions | 14.9 MB | 14.9 MB | +32 KB | 0.2% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_stats | 35.0 KB | 35.0 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/unattributed | 1.4 GB | 1.4 GB | +11.5 MB | 0.8% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 8014081747 | 8004234003 | -9847744 | -0.1% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 12602 | 12602 | 0 | 0.0% |  |
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
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/detect/scan_sub_compile | 20 ms | 20 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/parse/read_files | 8.7 min | 8.9 min | +7.3 s | 1.4% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics | 15.2 s | 15.3 s | +56 ms | 0.4% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/bucket_stats | 15.2 s | 15.3 s | +55 ms | 0.4% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/untimed | 12 ms | 12 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/heatmap_statistics | 235 ms | 251 ms | +16 ms | 6.8% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/histogram_statistics | 19 ms | 19 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/total | 9.0 min | 9.1 min | +7.4 s | 1.4% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/rss_peak | 1.7 GB | 1.7 GB | +240 KB | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/format_scan_subs | 2.8 MB | 2.7 MB | -16 KB | -0.6% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_counters | 2.7 MB | 2.7 MB | +1.8 KB | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_data | 76.8 KB | 75.3 KB | -1.5 KB | -2.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/histogram_counters | 307.7 KB | 307.8 KB | +128 B | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_analysis | 1.2 GB | 1.2 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_messages | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_stats | 82.7 KB | 82.7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/unattributed | 475.6 MB | 475.8 MB | +255.6 KB | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY_FINAL/log_analysis | 23011 | 23011 | 0 | 0.0% |  |
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
| month-many-servers-access-logs-heatmap-histogram-export | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 20 ms | 20 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/parse/read_files | 12.2 min | 12.3 min | +4.9 s | 0.7% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 4.1 min | 4.1 min | +687 ms | 0.3% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 10.3 s | 10.2 s | -41 ms | -0.4% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 5 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | 10.3 s | 10.2 s | -45 ms | -0.4% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/untimed | 15 ms | 19 ms | +4 ms | 26.7% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/heatmap_statistics | 108 ms | 107 ms | -1 ms | -0.9% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/histogram_statistics | 20 ms | 19 ms | -1 ms | -5.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | 16.5 min | 16.6 min | +5.5 s | 0.6% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 2.5 GB | 2.3 GB | -170.9 MB | -6.7% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 1.1 GB | 1.1 GB | -2.6 MB | -0.2% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_id_index | 47.5 MB | 50.6 MB | +3.1 MB | 6.6% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 2.0 MB | 2.0 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 23.6 MB | 26.7 MB | +3.1 MB | 13.2% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 482.4 KB | 482.5 KB | +128 B | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 1.3 MB | 1.3 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 2.5 MB | 2.6 MB | +48 KB | 1.9% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 2.7 MB | 2.7 MB | +1.8 KB | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 76.8 KB | 76.3 KB | -512 B | -0.7% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | 307.7 KB | 307.8 KB | +128 B | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 15.3 KB | 15.3 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 1.2 GB | 1.2 GB | -2.4 MB | -0.2% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 43.8 KB | 43.8 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 35.0 KB | 35.0 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | 1.9 KB | 1.9 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/unattributed | 135.1 MB | 0 B | -135.1 MB | -100.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 1270323921 | 1267763449 | -2560472 | -0.2% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 12602 | 12602 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 1150404175 | 1147727159 | -2677016 | -0.2% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 493990 | 494118 | 128 | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 432 | 304 | -128 | -29.6% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_id_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 2443 | 2443 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_analysis_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_population | 2443 | 2443 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 3 | 3 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/format_scan_sub_cache_hits | 142 | 142 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | TIMING/detect/scan_sub_compile | 20 ms | 20 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | TIMING/parse/read_files | 8.0 min | 8.1 min | +5.3 s | 1.1% | REGRESS |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics | 1 min | 1 min | +183 ms | 0.3% | REGRESS |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/bucket_stats | 12.5 s | 12.6 s | +64 ms | 0.5% | REGRESS |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | 28.2 s | 28.1 s | -82 ms | -0.3% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 19.9 s | 20.1 s | +160 ms | 0.8% | REGRESS |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/untimed | 708 ms | 750 ms | +42 ms | 5.9% | REGRESS |
| month-many-servers-access-logs-sort-p99 | TIMING/render/normalize_data | 4 ms | 2 ms | -2 ms | -50.0% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | TIMING/total | 9.0 min | 9.1 min | +5.5 s | 1.0% | REGRESS |
| month-many-servers-access-logs-sort-p99 | MEMORY/rss_peak | 10.9 GB | 11.0 GB | +2.9 MB | 0.0% | REGRESS |
| month-many-servers-access-logs-sort-p99 | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/format_scan_subs | 2.7 MB | 2.7 MB | +32 KB | 1.2% | REGRESS |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_analysis | 1.2 GB | 1.2 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_messages | 7.9 GB | 7.9 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_occurrences | 42.1 KB | 43.8 KB | +1.8 KB | 4.2% | REGRESS |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_sessions | 14.9 MB | 14.9 MB | +128 B | 0.0% | REGRESS |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/message_key_order | 2.5 KB | 2.5 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/unattributed | 1.8 GB | 1.8 GB | +2.9 MB | 0.2% | REGRESS |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/log_messages | 8528632963 | 8528632963 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/log_analysis | 13018 | 13018 | 0 | 0.0% |  |
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
| month-many-servers-access-logs-sort-skewness | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | TIMING/detect/scan_sub_compile | 20 ms | 20 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | TIMING/parse/read_files | 8.0 min | 8.1 min | +9.9 s | 2.1% | REGRESS |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics | 34 s | 34.2 s | +210 ms | 0.6% | REGRESS |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/bucket_stats | 12.8 s | 12.6 s | -239 ms | -1.9% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | 20 s | 20.5 s | +430 ms | 2.1% | REGRESS |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 66 ms | 67 ms | +1 ms | 1.5% | REGRESS |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/group_calc | 715 ms | 723 ms | +8 ms | 1.1% | REGRESS |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/untimed | 359 ms | 369 ms | +10 ms | 2.8% | REGRESS |
| month-many-servers-access-logs-sort-skewness | TIMING/render/normalize_data | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | TIMING/total | 8.5 min | 8.7 min | +10.1 s | 2.0% | REGRESS |
| month-many-servers-access-logs-sort-skewness | MEMORY/rss_peak | 10.4 GB | 10.4 GB | -14.5 MB | -0.1% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_id_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/format_scan_subs | 2.6 MB | 2.6 MB | 0 B | 0.0% |  |
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
| month-many-servers-access-logs-sort-skewness | MEMORY/log_messages | 7.9 GB | 7.9 GB | -9.4 MB | -0.1% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/message_key_order | 2.1 KB | 2.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/unattributed | 1.2 GB | 1.2 GB | -5.1 MB | -0.4% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/log_messages | 8528067400 | 8518219656 | -9847744 | -0.1% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/log_analysis | 13018 | 13018 | 0 | 0.0% |  |
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

