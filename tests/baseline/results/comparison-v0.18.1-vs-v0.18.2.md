
## Benchmark Comparison

  Baseline:    v0.18.1 (v0.18.1, 77 test cases)
  Current:     v0.18.2 (v0.18.2, 77 test cases)

### Timing Delta

| # | file selection | standard | no-msgs | top25 | top25-cons | heatmap | histogram | hm+hg | hm+hg+cons | sort-p99 | sort-skew | hm+hg+export |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. | humungous-log-uniqueness | -1.8% | +0.8% | +3.2% | -60.1% | -2.8% | -1.4% | -0.4% | -59.6% | +2.3% | +0.5% | +3.2% |
| 2. | single-day-application-log | -1.4% | -3.5% | -3.5% | -17.5% | -1.9% | -3.1% | -4.3% | -18.6% | -2.7% | -2.3% | -2.7% |
| 3. | multi-day-application-logs | -3.2% | -3.0% | -1.1% | -15.2% | +0.3% | -2.6% | -2.3% | -15.8% | -2.8% | -1.9% | -1.1% |
| 4. | multi-day-custom-logs | -0.5% | -0.8% | -0.1% | -25.2% | +2.6% | +1.3% | -0.8% | -25.1% | -0.7% | -0.1% | -2.2% |
| 5. | single-day-access-log | -1.5% | -1.0% | -0.6% | -5.6% | -0.7% | -0.2% | +0.0% | -3.8% | -2.7% | -1.9% | -0.4% |
| 6. | month-single-server-access-logs | -0.3% | -1.5% | -0.3% | -10.9% | -1.3% | -0.1% | +0.3% | -9.6% | -0.5% | -1.1% | +0.1% |
| 7. | month-many-servers-access-logs | -0.4% | +1.0% | -1.3% | -12.8% | -0.6% | -0.6% | +0.7% | -10.4% | -0.4% | -0.1% | -1.1% |

### Memory Delta (RSS Peak)

| # | file selection | standard | no-msgs | top25 | top25-cons | heatmap | histogram | hm+hg | hm+hg+cons | sort-p99 | sort-skew | hm+hg+export |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. | humungous-log-uniqueness | -0.5% | +2.0% | -0.4% | -81.2% | +0.0% | +0.2% | +0.2% | -81.2% | +0.4% | +0.3% | +0.2% |
| 2. | single-day-application-log | +0.4% | +0.2% | +0.9% | -14.6% | +1.9% | +0.5% | +0.9% | -15.2% | +0.8% | +0.2% | +1.6% |
| 3. | multi-day-application-logs | +0.5% | -0.2% | +0.6% | +6.6% | +0.4% | +0.6% | -0.3% | +6.1% | +0.4% | +0.2% | +1.8% |
| 4. | multi-day-custom-logs | +0.2% | +0.9% | +0.0% | +3.1% | +2.3% | +1.2% | +0.3% | +5.2% | -0.3% | +2.0% | +0.0% |
| 5. | single-day-access-log | -1.6% | +0.6% | +1.6% | +1.3% | -0.9% | +1.9% | +0.4% | +0.3% | +2.0% | +1.5% | -0.6% |
| 6. | month-single-server-access-logs | -0.0% | -0.4% | -0.0% | +1.0% | -0.2% | -4.0% | +0.1% | -11.1% | -0.4% | +0.1% | -0.3% |
| 7. | month-many-servers-access-logs | -0.1% | -1.6% | -0.0% | -4.8% | +4.6% | +0.1% | +0.1% | -6.0% | -0.0% | +0.0% | -0.3% |

### Stage Rollup (timing)

| metric | baseline | current | delta | change% | cases +/- | result |
| --- | --- | --- | --- | --- | --- | --- |

### Category Rollup (memory)

| metric | baseline | current | delta | change% | cases +/- | result |
| --- | --- | --- | --- | --- | --- | --- |

### New In This Version

| metric | test cases | per-test range | aggregate |
| --- | --- | --- | --- |
| (none) | - | - | - |

### Summary

| test_name | metric | baseline | current | delta | change% | result |
| --- | --- | --- | --- | --- | --- | --- |
| humungous-log-uniqueness-standard | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/total | 2.8 s | 2.8 s | -52 ms | -1.8% | IMPROVE |
| humungous-log-uniqueness-standard | MEMORY/rss_peak | 265.2 MB | 263.9 MB | -1.3 MB | -0.5% | IMPROVE |
| humungous-log-uniqueness-no-messages | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | TIMING/total | 2.0 s | 2.0 s | +15 ms | 0.8% | REGRESS |
| humungous-log-uniqueness-no-messages | MEMORY/rss_peak | 37.7 MB | 38.5 MB | +784 KB | 2.0% | REGRESS |
| humungous-log-uniqueness-top25 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/total | 2.7 s | 2.8 s | +88 ms | 3.2% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY/rss_peak | 265.2 MB | 264.1 MB | -1 MB | -0.4% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/total | 10.2 s | 4.1 s | -6.1 s | -60.1% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/rss_peak | 265.3 MB | 50.0 MB | -215.3 MB | -81.2% | IMPROVE |
| humungous-log-uniqueness-heatmap | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/total | 2.8 s | 2.7 s | -77 ms | -2.8% | IMPROVE |
| humungous-log-uniqueness-heatmap | MEMORY/rss_peak | 265.2 MB | 265.2 MB | +80 KB | 0.0% | REGRESS |
| humungous-log-uniqueness-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/total | 2.8 s | 2.7 s | -39 ms | -1.4% | IMPROVE |
| humungous-log-uniqueness-histogram | MEMORY/rss_peak | 264.9 MB | 265.4 MB | +512 KB | 0.2% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/total | 2.8 s | 2.8 s | -12 ms | -0.4% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/rss_peak | 264.8 MB | 265.2 MB | +416 KB | 0.2% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-export | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/total | 2.0 s | 2.1 s | +64 ms | 3.2% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/rss_peak | 38.1 MB | 38.2 MB | +96 KB | 0.2% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/total | 10.2 s | 4.1 s | -6.1 s | -59.6% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/rss_peak | 264.2 MB | 49.7 MB | -214.6 MB | -81.2% | IMPROVE |
| humungous-log-uniqueness-sort-p99 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | TIMING/total | 2.7 s | 2.8 s | +64 ms | 2.3% | REGRESS |
| humungous-log-uniqueness-sort-p99 | MEMORY/rss_peak | 264.8 MB | 265.7 MB | +960 KB | 0.4% | REGRESS |
| humungous-log-uniqueness-sort-skewness | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | TIMING/total | 2.7 s | 2.8 s | +14 ms | 0.5% | REGRESS |
| humungous-log-uniqueness-sort-skewness | MEMORY/rss_peak | 264.6 MB | 265.4 MB | +832 KB | 0.3% | REGRESS |
| single-day-application-log-standard | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | TIMING/total | 3.7 s | 3.7 s | -52 ms | -1.4% | IMPROVE |
| single-day-application-log-standard | MEMORY/rss_peak | 42.1 MB | 42.2 MB | +176 KB | 0.4% | REGRESS |
| single-day-application-log-no-messages | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-no-messages | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-no-messages | TIMING/total | 3.2 s | 3.1 s | -113 ms | -3.5% | IMPROVE |
| single-day-application-log-no-messages | MEMORY/rss_peak | 38.2 MB | 38.3 MB | +96 KB | 0.2% | REGRESS |
| single-day-application-log-top25 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | TIMING/total | 3.7 s | 3.6 s | -129 ms | -3.5% | IMPROVE |
| single-day-application-log-top25 | MEMORY/rss_peak | 41.9 MB | 42.2 MB | +368 KB | 0.9% | REGRESS |
| single-day-application-log-top25-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/total | 6.5 s | 5.4 s | -1.1 s | -17.5% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/rss_peak | 131.1 MB | 112 MB | -19.1 MB | -14.6% | IMPROVE |
| single-day-application-log-heatmap | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | TIMING/total | 3.7 s | 3.7 s | -69 ms | -1.9% | IMPROVE |
| single-day-application-log-heatmap | MEMORY/rss_peak | 41.7 MB | 42.5 MB | +800 KB | 1.9% | REGRESS |
| single-day-application-log-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | TIMING/total | 3.7 s | 3.6 s | -115 ms | -3.1% | IMPROVE |
| single-day-application-log-histogram | MEMORY/rss_peak | 41.9 MB | 42.1 MB | +208 KB | 0.5% | REGRESS |
| single-day-application-log-heatmap-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/total | 3.8 s | 3.6 s | -161 ms | -4.3% | IMPROVE |
| single-day-application-log-heatmap-histogram | MEMORY/rss_peak | 41.8 MB | 42.1 MB | +368 KB | 0.9% | REGRESS |
| single-day-application-log-heatmap-histogram-export | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | TIMING/total | 3.2 s | 3.1 s | -88 ms | -2.7% | IMPROVE |
| single-day-application-log-heatmap-histogram-export | MEMORY/rss_peak | 37.8 MB | 38.4 MB | +624 KB | 1.6% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/total | 6.5 s | 5.3 s | -1.2 s | -18.6% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 132.2 MB | 112 MB | -20.1 MB | -15.2% | IMPROVE |
| single-day-application-log-sort-p99 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | TIMING/total | 3.7 s | 3.6 s | -101 ms | -2.7% | IMPROVE |
| single-day-application-log-sort-p99 | MEMORY/rss_peak | 41.7 MB | 42 MB | +336 KB | 0.8% | REGRESS |
| single-day-application-log-sort-skewness | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | TIMING/total | 3.7 s | 3.6 s | -85 ms | -2.3% | IMPROVE |
| single-day-application-log-sort-skewness | MEMORY/rss_peak | 42.0 MB | 42 MB | +80 KB | 0.2% | REGRESS |
| multi-day-application-logs-standard | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-standard | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-standard | TIMING/total | 8 s | 7.8 s | -253 ms | -3.2% | IMPROVE |
| multi-day-application-logs-standard | MEMORY/rss_peak | 106.7 MB | 107.2 MB | +496 KB | 0.5% | REGRESS |
| multi-day-application-logs-no-messages | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | TIMING/total | 6.7 s | 6.5 s | -200 ms | -3.0% | IMPROVE |
| multi-day-application-logs-no-messages | MEMORY/rss_peak | 39.4 MB | 39.4 MB | -64 KB | -0.2% | IMPROVE |
| multi-day-application-logs-top25 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/total | 7.9 s | 7.8 s | -90 ms | -1.1% | IMPROVE |
| multi-day-application-logs-top25 | MEMORY/rss_peak | 106.7 MB | 107.3 MB | +656 KB | 0.6% | REGRESS |
| multi-day-application-logs-top25-consolidate | lines_read | 930,031 | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | lines_included | 930,028 | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/total | 39.9 s | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | 216 MB | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/total | 7.9 s | 7.9 s | +22 ms | 0.3% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY/rss_peak | 107 MB | 107.5 MB | +432 KB | 0.4% | REGRESS |
| multi-day-application-logs-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/total | 8 s | 7.8 s | -208 ms | -2.6% | IMPROVE |
| multi-day-application-logs-histogram | MEMORY/rss_peak | 106.6 MB | 107.2 MB | +624 KB | 0.6% | REGRESS |
| multi-day-application-logs-heatmap-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/total | 8 s | 7.8 s | -181 ms | -2.3% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | MEMORY/rss_peak | 107.1 MB | 106.8 MB | -304 KB | -0.3% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-export | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | TIMING/total | 6.6 s | 6.5 s | -76 ms | -1.1% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/rss_peak | 39.0 MB | 39.7 MB | +720 KB | 1.8% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_read | 930,031 | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_included | 930,028 | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | 40.1 s | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 216.1 MB | N/A | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | TIMING/total | 8 s | 7.8 s | -225 ms | -2.8% | IMPROVE |
| multi-day-application-logs-sort-p99 | MEMORY/rss_peak | 106.7 MB | 107.2 MB | +464 KB | 0.4% | REGRESS |
| multi-day-application-logs-sort-skewness | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | TIMING/total | 7.9 s | 7.8 s | -147 ms | -1.9% | IMPROVE |
| multi-day-application-logs-sort-skewness | MEMORY/rss_peak | 107 MB | 107.2 MB | +224 KB | 0.2% | REGRESS |
| multi-day-custom-logs-standard | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/total | 16.5 s | 16.4 s | -87 ms | -0.5% | IMPROVE |
| multi-day-custom-logs-standard | MEMORY/rss_peak | 175.1 MB | 175.5 MB | +400 KB | 0.2% | REGRESS |
| multi-day-custom-logs-no-messages | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | TIMING/total | 13.2 s | 13.1 s | -111 ms | -0.8% | IMPROVE |
| multi-day-custom-logs-no-messages | MEMORY/rss_peak | 53.9 MB | 54.4 MB | +512 KB | 0.9% | REGRESS |
| multi-day-custom-logs-top25 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/total | 16.4 s | 16.4 s | -23 ms | -0.1% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/rss_peak | 176.2 MB | 176.3 MB | +80 KB | 0.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/total | 51.4 s | 38.5 s | -13.0 s | -25.2% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/rss_peak | 222.1 MB | 229.0 MB | +6.9 MB | 3.1% | REGRESS |
| multi-day-custom-logs-heatmap | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/total | 17.0 s | 17.4 s | +438 ms | 2.6% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/rss_peak | 172.4 MB | 176.4 MB | +4.0 MB | 2.3% | REGRESS |
| multi-day-custom-logs-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/total | 17.2 s | 17.4 s | +221 ms | 1.3% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/rss_peak | 176.3 MB | 178.4 MB | +2.1 MB | 1.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/total | 17.6 s | 17.4 s | -146 ms | -0.8% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/rss_peak | 172.9 MB | 173.4 MB | +512 KB | 0.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/total | 14.8 s | 14.5 s | -324 ms | -2.2% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/rss_peak | 57.6 MB | 57.6 MB | +16 KB | 0.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/total | 52.7 s | 39.5 s | -13.2 s | -25.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 215.8 MB | 227.0 MB | +11.1 MB | 5.2% | REGRESS |
| multi-day-custom-logs-sort-p99 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | TIMING/total | 16.3 s | 16.2 s | -110 ms | -0.7% | IMPROVE |
| multi-day-custom-logs-sort-p99 | MEMORY/rss_peak | 173.4 MB | 172.9 MB | -464 KB | -0.3% | IMPROVE |
| multi-day-custom-logs-sort-skewness | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | TIMING/total | 16.3 s | 16.3 s | -9 ms | -0.1% | IMPROVE |
| multi-day-custom-logs-sort-skewness | MEMORY/rss_peak | 172.0 MB | 175.3 MB | +3.4 MB | 2.0% | REGRESS |
| single-day-access-log-standard | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | TIMING/total | 8.8 s | 8.7 s | -132 ms | -1.5% | IMPROVE |
| single-day-access-log-standard | MEMORY/rss_peak | 101.2 MB | 99.6 MB | -1.6 MB | -1.6% | IMPROVE |
| single-day-access-log-no-messages | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-no-messages | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-no-messages | TIMING/total | 6.7 s | 6.6 s | -68 ms | -1.0% | IMPROVE |
| single-day-access-log-no-messages | MEMORY/rss_peak | 64.3 MB | 64.7 MB | +400 KB | 0.6% | REGRESS |
| single-day-access-log-top25 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | TIMING/total | 8.7 s | 8.6 s | -48 ms | -0.6% | IMPROVE |
| single-day-access-log-top25 | MEMORY/rss_peak | 98.2 MB | 99.8 MB | +1.6 MB | 1.6% | REGRESS |
| single-day-access-log-top25-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/total | 12.5 s | 11.8 s | -698 ms | -5.6% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/rss_peak | 131.2 MB | 132.8 MB | +1.7 MB | 1.3% | REGRESS |
| single-day-access-log-heatmap | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | TIMING/total | 9.4 s | 9.3 s | -62 ms | -0.7% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/rss_peak | 83.7 MB | 82.9 MB | -752 KB | -0.9% | IMPROVE |
| single-day-access-log-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | TIMING/total | 10.6 s | 10.6 s | -18 ms | -0.2% | IMPROVE |
| single-day-access-log-histogram | MEMORY/rss_peak | 97.5 MB | 99.4 MB | +1.9 MB | 1.9% | REGRESS |
| single-day-access-log-heatmap-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/total | 11.1 s | 11.1 s | +3 ms | 0.0% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/rss_peak | 83.6 MB | 83.9 MB | +304 KB | 0.4% | REGRESS |
| single-day-access-log-heatmap-histogram-export | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | TIMING/total | 9.8 s | 9.8 s | -41 ms | -0.4% | IMPROVE |
| single-day-access-log-heatmap-histogram-export | MEMORY/rss_peak | 68.4 MB | 68 MB | -416 KB | -0.6% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/total | 14.3 s | 13.8 s | -540 ms | -3.8% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 112.9 MB | 113.3 MB | +352 KB | 0.3% | REGRESS |
| single-day-access-log-sort-p99 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/total | 8.9 s | 8.7 s | -236 ms | -2.7% | IMPROVE |
| single-day-access-log-sort-p99 | MEMORY/rss_peak | 97.0 MB | 98.9 MB | +1.9 MB | 2.0% | REGRESS |
| single-day-access-log-sort-skewness | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | TIMING/total | 9.0 s | 8.8 s | -167 ms | -1.9% | IMPROVE |
| single-day-access-log-sort-skewness | MEMORY/rss_peak | 102.4 MB | 103.9 MB | +1.5 MB | 1.5% | REGRESS |
| month-single-server-access-logs-standard | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/total | 1.7 min | 1.6 min | -334 ms | -0.3% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/rss_peak | 2 GB | 2 GB | -688 KB | -0.0% | IMPROVE |
| month-single-server-access-logs-no-messages | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | TIMING/total | 1.2 min | 1.2 min | -1.1 s | -1.5% | IMPROVE |
| month-single-server-access-logs-no-messages | MEMORY/rss_peak | 371.9 MB | 370.2 MB | -1.7 MB | -0.4% | IMPROVE |
| month-single-server-access-logs-top25 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/total | 1.7 min | 1.7 min | -337 ms | -0.3% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY/rss_peak | 2 GB | 2 GB | -576 KB | -0.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | lines_read | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | lines_included | 7,749,159 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/total | 3.1 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | 919.3 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/total | 1.8 min | 1.8 min | -1.4 s | -1.3% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/rss_peak | 1.8 GB | 1.8 GB | -2.8 MB | -0.2% | IMPROVE |
| month-single-server-access-logs-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/total | 2 min | 2 min | -75 ms | -0.1% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/rss_peak | 2 GB | 1.9 GB | -81.8 MB | -4.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/total | 2.1 min | 2.1 min | +396 ms | 0.3% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/rss_peak | 1.8 GB | 1.8 GB | +1.1 MB | 0.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/total | 1.8 min | 1.8 min | +85 ms | 0.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/rss_peak | 372.8 MB | 371.5 MB | -1.3 MB | -0.3% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_read | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_included | 7,749,159 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | 3.3 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 720 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | TIMING/total | 1.8 min | 1.7 min | -547 ms | -0.5% | IMPROVE |
| month-single-server-access-logs-sort-p99 | MEMORY/rss_peak | 2.2 GB | 2.2 GB | -8.2 MB | -0.4% | IMPROVE |
| month-single-server-access-logs-sort-skewness | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | TIMING/total | 1.7 min | 1.7 min | -1.1 s | -1.1% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY/rss_peak | 2.1 GB | 2.1 GB | +1.1 MB | 0.1% | REGRESS |
| month-many-servers-access-logs-standard | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | TIMING/total | 8.3 min | 8.3 min | -1.9 s | -0.4% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/rss_peak | 10.1 GB | 10.1 GB | -5.6 MB | -0.1% | IMPROVE |
| month-many-servers-access-logs-no-messages | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | TIMING/total | 6.1 min | 6.1 min | +3.7 s | 1.0% | REGRESS |
| month-many-servers-access-logs-no-messages | MEMORY/rss_peak | 1.6 GB | 1.6 GB | -27.0 MB | -1.6% | IMPROVE |
| month-many-servers-access-logs-top25 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | TIMING/total | 8.4 min | 8.3 min | -6.3 s | -1.3% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY/rss_peak | 10.1 GB | 10.1 GB | -3 MB | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | lines_included | 38,672,411 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | 18.7 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | 3.6 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/total | 8.9 min | 8.9 min | -3.1 s | -0.6% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/rss_peak | 8.5 GB | 8.9 GB | +395.0 MB | 4.6% | REGRESS |
| month-many-servers-access-logs-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/total | 10.2 min | 10.1 min | -3.9 s | -0.6% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/rss_peak | 10.1 GB | 10.1 GB | +14.4 MB | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/total | 10.5 min | 10.6 min | +4.4 s | 0.7% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/rss_peak | 8.8 GB | 8.8 GB | +8.1 MB | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-export | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/total | 9.1 min | 9.0 min | -6.2 s | -1.1% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/rss_peak | 1.7 GB | 1.7 GB | -5.8 MB | -0.3% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_included | 38,672,411 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | 18.4 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 2.6 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | TIMING/total | 9 min | 9.0 min | -2.2 s | -0.4% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY/rss_peak | 11.0 GB | 10.9 GB | -2.1 MB | -0.0% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | TIMING/total | 8.5 min | 8.5 min | -690 ms | -0.1% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | MEMORY/rss_peak | 10.4 GB | 10.4 GB | +4.1 MB | 0.0% | REGRESS |
| multi-day-application-logs-top25-consolidate | lines_read | N/A | 930,031 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | lines_included | N/A | 930,028 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/total | N/A | 33.9 s | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | N/A | 230.2 MB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_read | N/A | 930,031 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_included | N/A | 930,028 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | N/A | 33.8 s | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | N/A | 229.4 MB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | lines_read | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | lines_included | N/A | 7,749,159 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/total | N/A | 2.8 min | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | N/A | 928.7 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_read | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_included | N/A | 7,749,159 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | N/A | 2.9 min | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | N/A | 640.1 MB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | lines_read | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | lines_included | N/A | 38,672,411 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | N/A | 16.3 min | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | N/A | 3.4 GB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_read | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_included | N/A | 38,672,411 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | N/A | 16.5 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | N/A | 2.5 GB | N/A | N/A | ? |

### Detailed

| test_name | metric | baseline | current | delta | change% | result |
| --- | --- | --- | --- | --- | --- | --- |
| humungous-log-uniqueness-standard | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/parse/read_files | 2.5 s | 2.5 s | -46 ms | -1.8% | IMPROVE |
| humungous-log-uniqueness-standard | TIMING/finalize/calculate_statistics | 319 ms | 312 ms | -7 ms | -2.2% | IMPROVE |
| humungous-log-uniqueness-standard | TIMING/finalize/calculate_statistics/sort_selection | 306 ms | 300 ms | -6 ms | -2.0% | IMPROVE |
| humungous-log-uniqueness-standard | TIMING/finalize/calculate_statistics/untimed | 13 ms | 13 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/total | 2.8 s | 2.8 s | -52 ms | -1.8% | IMPROVE |
| humungous-log-uniqueness-standard | MEMORY/rss_peak | 265.2 MB | 263.9 MB | -1.3 MB | -0.5% | IMPROVE |
| humungous-log-uniqueness-standard | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/format_scan_subs | 1.2 MB | 1.1 MB | -96 KB | -8.1% | IMPROVE |
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
| humungous-log-uniqueness-standard | MEMORY/unattributed | 91.1 MB | 89.9 MB | -1.2 MB | -1.3% | IMPROVE |
| humungous-log-uniqueness-standard | MEMORY_FINAL/log_messages | 181317607 | 181317607 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| humungous-log-uniqueness-no-messages | TIMING/parse/read_files | 2.0 s | 2.0 s | +15 ms | 0.8% | REGRESS |
| humungous-log-uniqueness-no-messages | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-no-messages | TIMING/total | 2.0 s | 2.0 s | +15 ms | 0.8% | REGRESS |
| humungous-log-uniqueness-no-messages | MEMORY/rss_peak | 37.7 MB | 38.5 MB | +784 KB | 2.0% | REGRESS |
| humungous-log-uniqueness-no-messages | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
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
| humungous-log-uniqueness-no-messages | MEMORY/unattributed | 36.6 MB | 37.4 MB | +784.2 KB | 2.1% | REGRESS |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| humungous-log-uniqueness-top25 | TIMING/parse/read_files | 2.4 s | 2.5 s | +92 ms | 3.8% | REGRESS |
| humungous-log-uniqueness-top25 | TIMING/finalize/calculate_statistics | 312 ms | 308 ms | -4 ms | -1.3% | IMPROVE |
| humungous-log-uniqueness-top25 | TIMING/finalize/calculate_statistics/sort_selection | 300 ms | 295 ms | -5 ms | -1.7% | IMPROVE |
| humungous-log-uniqueness-top25 | TIMING/finalize/calculate_statistics/untimed | 13 ms | 13 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/total | 2.7 s | 2.8 s | +88 ms | 3.2% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY/rss_peak | 265.2 MB | 264.1 MB | -1 MB | -0.4% | IMPROVE |
| humungous-log-uniqueness-top25 | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | -32 KB | -2.9% | IMPROVE |
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
| humungous-log-uniqueness-top25 | MEMORY/unattributed | 91.1 MB | 90.1 MB | -1023.8 KB | -1.1% | IMPROVE |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/log_messages | 181317607 | 181317607 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| humungous-log-uniqueness-top25-consolidate | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/parse/read_files | 6.4 s | 3.3 s | -3.1 s | -48.5% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | TIMING/finalize/group_similar | 3.8 s | 768 ms | -3 s | -79.8% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/total | 10.2 s | 4.1 s | -6.1 s | -60.1% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/rss_peak | 265.3 MB | 50.0 MB | -215.3 MB | -81.2% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_clusters | 196.6 KB | 187.8 KB | -8.8 KB | -4.5% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_message | 3.1 MB | 231.5 KB | -2.8 MB | -92.6% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_trigrams | 71.7 MB | 2.8 MB | -68.9 MB | -96.1% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 64.3 MB | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_ngram_index | 66.7 MB | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_patterns | 24.6 KB | 23.8 KB | -811 B | -3.2% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_posting_size | 614.1 KB | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_unmatched | 1.7 MB | 129.8 KB | -1.6 MB | -92.7% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/format_scan_subs | 1.2 MB | 1.1 MB | -128 KB | -10.3% | IMPROVE |
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
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_messages | 3.3 MB | 190.1 KB | -3.1 MB | -94.4% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_stats | 1.7 KB | 1.7 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_users | 8.5 KB | 8.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/message_key_order | 9.4 KB | 10.2 KB | +825 B | 8.5% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/unattributed | 52.4 MB | 39.6 MB | -12.7 MB | -24.3% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/log_messages | 104707 | 45600 | -59107 | -56.4% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 201314 | 192313 | -9001 | -4.5% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 25181 | 24370 | -811 | -3.2% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 4152 | -61440 | -93.7% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 4152 | -61440 | -93.7% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 65592 | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_messages_entries | 72 | 76 | 4 | 5.6% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_occurrences_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_stats_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_messages_population | 72 | 76 | 4 | 5.6% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/parse/read_files | 2.5 s | 2.4 s | -92 ms | -3.7% | IMPROVE |
| humungous-log-uniqueness-heatmap | TIMING/finalize/calculate_statistics | 294 ms | 309 ms | +15 ms | 5.1% | REGRESS |
| humungous-log-uniqueness-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 281 ms | 296 ms | +15 ms | 5.3% | REGRESS |
| humungous-log-uniqueness-heatmap | TIMING/finalize/calculate_statistics/untimed | 13 ms | 13 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/total | 2.8 s | 2.7 s | -77 ms | -2.8% | IMPROVE |
| humungous-log-uniqueness-heatmap | MEMORY/rss_peak | 265.2 MB | 265.2 MB | +80 KB | 0.0% | REGRESS |
| humungous-log-uniqueness-heatmap | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/format_scan_subs | 1.2 MB | 1.1 MB | -160 KB | -12.8% | IMPROVE |
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
| humungous-log-uniqueness-heatmap | MEMORY/unattributed | 91 MB | 91.2 MB | +240.2 KB | 0.3% | REGRESS |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/log_messages | 181317607 | 181317607 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| humungous-log-uniqueness-histogram | TIMING/parse/read_files | 2.5 s | 2.4 s | -47 ms | -1.9% | IMPROVE |
| humungous-log-uniqueness-histogram | TIMING/finalize/calculate_statistics | 299 ms | 307 ms | +8 ms | 2.7% | REGRESS |
| humungous-log-uniqueness-histogram | TIMING/finalize/calculate_statistics/sort_selection | 287 ms | 295 ms | +8 ms | 2.8% | REGRESS |
| humungous-log-uniqueness-histogram | TIMING/finalize/calculate_statistics/untimed | 13 ms | 12 ms | -1000 us | -7.7% | IMPROVE |
| humungous-log-uniqueness-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/total | 2.8 s | 2.7 s | -39 ms | -1.4% | IMPROVE |
| humungous-log-uniqueness-histogram | MEMORY/rss_peak | 264.9 MB | 265.4 MB | +512 KB | 0.2% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | +32 KB | 2.9% | REGRESS |
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
| humungous-log-uniqueness-histogram | MEMORY/unattributed | 90.9 MB | 91.3 MB | +480.2 KB | 0.5% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/log_messages | 181317607 | 181317607 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| humungous-log-uniqueness-heatmap-histogram | TIMING/parse/read_files | 2.5 s | 2.4 s | -36 ms | -1.5% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | TIMING/finalize/calculate_statistics | 296 ms | 320 ms | +24 ms | 8.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 284 ms | 306 ms | +22 ms | 7.7% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | 13 ms | 13 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/total | 2.8 s | 2.8 s | -12 ms | -0.4% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/rss_peak | 264.8 MB | 265.2 MB | +416 KB | 0.2% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
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
| humungous-log-uniqueness-heatmap-histogram | MEMORY/unattributed | 90.8 MB | 91.2 MB | +416.2 KB | 0.4% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/log_messages | 181317607 | 181317607 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/parse/read_files | 2.0 s | 2 s | +64 ms | 3.2% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | TIMING/total | 2.0 s | 2.1 s | +64 ms | 3.2% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/rss_peak | 38.1 MB | 38.2 MB | +96 KB | 0.2% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/format_scan_subs | 1.2 MB | 1.1 MB | -128 KB | -10.5% | IMPROVE |
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
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/unattributed | 36.9 MB | 37.1 MB | +224.2 KB | 0.6% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/parse/read_files | 6.4 s | 3.3 s | -3.1 s | -47.9% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 3.8 s | 777 ms | -3 s | -79.5% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/total | 10.2 s | 4.1 s | -6.1 s | -59.6% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/rss_peak | 264.2 MB | 49.7 MB | -214.6 MB | -81.2% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 196.5 KB | 187.8 KB | -8.7 KB | -4.4% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 3.1 MB | 231.5 KB | -2.8 MB | -92.6% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 71.7 MB | 2.8 MB | -69.0 MB | -96.1% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 64.3 MB | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 66.7 MB | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 24.6 KB | 23.8 KB | -811 B | -3.2% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 614.1 KB | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 1.7 MB | 129.8 KB | -1.6 MB | -92.7% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | -64 KB | -5.5% | IMPROVE |
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
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_messages | 3.3 MB | 190.1 KB | -3.1 MB | -94.4% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_stats | 1.7 KB | 1.7 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_users | 8.5 KB | 8.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/message_key_order | 3.2 KB | 3.3 KB | +55 B | 1.7% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/unattributed | 51.4 MB | 39.4 MB | -12 MB | -23.4% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 104707 | 45600 | -59107 | -56.4% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 201186 | 192313 | -8873 | -4.4% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 25181 | 24370 | -811 | -3.2% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 4152 | -61440 | -93.7% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 4152 | -61440 | -93.7% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 65592 | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 72 | 76 | 4 | 5.6% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_messages_population | 72 | 76 | 4 | 5.6% | REGRESS |
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
| humungous-log-uniqueness-sort-p99 | TIMING/parse/read_files | 2.4 s | 2.5 s | +42 ms | 1.7% | REGRESS |
| humungous-log-uniqueness-sort-p99 | TIMING/finalize/calculate_statistics | 297 ms | 320 ms | +23 ms | 7.7% | REGRESS |
| humungous-log-uniqueness-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 285 ms | 307 ms | +22 ms | 7.7% | REGRESS |
| humungous-log-uniqueness-sort-p99 | TIMING/finalize/calculate_statistics/untimed | 13 ms | 13 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | TIMING/total | 2.7 s | 2.8 s | +64 ms | 2.3% | REGRESS |
| humungous-log-uniqueness-sort-p99 | MEMORY/rss_peak | 264.8 MB | 265.7 MB | +960 KB | 0.4% | REGRESS |
| humungous-log-uniqueness-sort-p99 | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | +48 KB | 4.4% | REGRESS |
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
| humungous-log-uniqueness-sort-p99 | MEMORY/unattributed | 90.7 MB | 91.6 MB | +912.2 KB | 1.0% | REGRESS |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/log_messages | 181317607 | 181317607 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| humungous-log-uniqueness-sort-skewness | TIMING/parse/read_files | 2.4 s | 2.4 s | -2 ms | -0.1% | IMPROVE |
| humungous-log-uniqueness-sort-skewness | TIMING/finalize/calculate_statistics | 296 ms | 312 ms | +16 ms | 5.4% | REGRESS |
| humungous-log-uniqueness-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 284 ms | 300 ms | +16 ms | 5.6% | REGRESS |
| humungous-log-uniqueness-sort-skewness | TIMING/finalize/calculate_statistics/untimed | 13 ms | 13 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | TIMING/total | 2.7 s | 2.8 s | +14 ms | 0.5% | REGRESS |
| humungous-log-uniqueness-sort-skewness | MEMORY/rss_peak | 264.6 MB | 265.4 MB | +832 KB | 0.3% | REGRESS |
| humungous-log-uniqueness-sort-skewness | MEMORY/bucket_outcomes | 1.3 KB | 1.3 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | -16 KB | -1.4% | IMPROVE |
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
| humungous-log-uniqueness-sort-skewness | MEMORY/unattributed | 90.5 MB | 91.4 MB | +848.2 KB | 0.9% | REGRESS |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/log_messages | 181317607 | 181317607 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| single-day-application-log-standard | TIMING/parse/read_files | 3.7 s | 3.6 s | -53 ms | -1.4% | IMPROVE |
| single-day-application-log-standard | TIMING/finalize/calculate_statistics | 6 ms | 7 ms | +1 ms | 16.7% | REGRESS |
| single-day-application-log-standard | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-standard | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-standard | TIMING/total | 3.7 s | 3.7 s | -52 ms | -1.4% | IMPROVE |
| single-day-application-log-standard | MEMORY/rss_peak | 42.1 MB | 42.2 MB | +176 KB | 0.4% | REGRESS |
| single-day-application-log-standard | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/format_scan_subs | 1.2 MB | 1.1 MB | -144 KB | -11.5% | IMPROVE |
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
| single-day-application-log-standard | MEMORY/log_users | 85.2 KB | 85.2 KB | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/unattributed | 37.9 MB | 38.3 MB | +320.2 KB | 0.8% | REGRESS |
| single-day-application-log-standard | MEMORY_FINAL/log_messages | 2914830 | 2914830 | 0 | 0.0% |  |
| single-day-application-log-standard | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| single-day-application-log-no-messages | TIMING/parse/read_files | 3.2 s | 3.1 s | -112 ms | -3.5% | IMPROVE |
| single-day-application-log-no-messages | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-no-messages | TIMING/total | 3.2 s | 3.1 s | -113 ms | -3.5% | IMPROVE |
| single-day-application-log-no-messages | MEMORY/rss_peak | 38.2 MB | 38.3 MB | +96 KB | 0.2% | REGRESS |
| single-day-application-log-no-messages | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/format_scan_subs | 1.2 MB | 1.1 MB | -192 KB | -15.0% | IMPROVE |
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
| single-day-application-log-no-messages | MEMORY/log_users | 85.2 KB | 85.2 KB | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-no-messages | MEMORY/unattributed | 36.8 MB | 37.1 MB | +288.2 KB | 0.8% | REGRESS |
| single-day-application-log-no-messages | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| single-day-application-log-no-messages | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| single-day-application-log-no-messages | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-no-messages | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-no-messages | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-no-messages | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-no-messages | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-no-messages | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| single-day-application-log-top25 | TIMING/detect/scan_sub_compile | 7 ms | 6 ms | -1 ms | -14.3% | IMPROVE |
| single-day-application-log-top25 | TIMING/parse/read_files | 3.7 s | 3.6 s | -130 ms | -3.5% | IMPROVE |
| single-day-application-log-top25 | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25 | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25 | TIMING/total | 3.7 s | 3.6 s | -129 ms | -3.5% | IMPROVE |
| single-day-application-log-top25 | MEMORY/rss_peak | 41.9 MB | 42.2 MB | +368 KB | 0.9% | REGRESS |
| single-day-application-log-top25 | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/format_scan_subs | 1.3 MB | 1.1 MB | -176 KB | -13.3% | IMPROVE |
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
| single-day-application-log-top25 | MEMORY/log_users | 85.0 KB | 85.0 KB | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/message_key_order | 6.4 KB | 6.4 KB | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/unattributed | 37.7 MB | 38.2 MB | +544.2 KB | 1.4% | REGRESS |
| single-day-application-log-top25 | MEMORY_FINAL/log_messages | 2914830 | 2914830 | 0 | 0.0% |  |
| single-day-application-log-top25 | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| single-day-application-log-top25-consolidate | TIMING/detect/scan_sub_compile | 6 ms | 7 ms | +1 ms | 16.7% | REGRESS |
| single-day-application-log-top25-consolidate | TIMING/parse/read_files | 6.2 s | 5.1 s | -1.2 s | -19.1% | IMPROVE |
| single-day-application-log-top25-consolidate | TIMING/finalize/group_similar | 255 ms | 305 ms | +50 ms | 19.6% | REGRESS |
| single-day-application-log-top25-consolidate | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/total | 6.5 s | 5.4 s | -1.1 s | -17.5% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/rss_peak | 131.1 MB | 112 MB | -19.1 MB | -14.6% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_clusters | 440.7 KB | 346.7 KB | -94 KB | -21.3% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_message | 2.6 MB | 1.4 MB | -1.3 MB | -48.4% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_trigrams | 29.3 MB | 28.0 MB | -1.3 MB | -4.5% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 16.4 MB | N/A | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_ngram_index | 29.7 MB | N/A | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_patterns | 54.3 KB | 42.8 KB | -11.6 KB | -21.3% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_posting_size | 860.9 KB | N/A | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_unmatched | 1.5 MB | 800.7 KB | -760.9 KB | -48.7% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | +48 KB | 4.4% | REGRESS |
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
| single-day-application-log-top25-consolidate | MEMORY/log_messages | 2.3 MB | 1.2 MB | -1.1 MB | -47.3% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_stats | 7.9 KB | 7.9 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_users | 85.2 KB | 85.2 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/message_key_order | 12.6 KB | 6.8 KB | -5.8 KB | -46.2% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/unattributed | 46.7 MB | 23.4 MB | -23.3 MB | -49.9% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/log_messages | 151190 | 91437 | -59753 | -39.5% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 451273 | 354999 | -96274 | -21.3% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 55644 | 43807 | -11837 | -21.3% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 32824 | -32768 | -50.0% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 240 | 240 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 32824 | 32824 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 32824 | N/A | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | COUNTS/log_messages_entries | 136 | 103 | -33 | -24.3% | IMPROVE |
| single-day-application-log-top25-consolidate | COUNTS/log_occurrences_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | COUNTS/log_stats_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | COUNTS/log_messages_population | 136 | 103 | -33 | -24.3% | IMPROVE |
| single-day-application-log-top25-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | TIMING/detect/registry_build | 12 ms | 13 ms | +1000 us | 8.3% | REGRESS |
| single-day-application-log-heatmap | TIMING/detect/scan_sub_compile | 6 ms | 7 ms | +1 ms | 16.7% | REGRESS |
| single-day-application-log-heatmap | TIMING/parse/read_files | 3.7 s | 3.6 s | -71 ms | -1.9% | IMPROVE |
| single-day-application-log-heatmap | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 6 ms | +1 ms | 20.0% | REGRESS |
| single-day-application-log-heatmap | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap | TIMING/total | 3.7 s | 3.7 s | -69 ms | -1.9% | IMPROVE |
| single-day-application-log-heatmap | MEMORY/rss_peak | 41.7 MB | 42.5 MB | +800 KB | 1.9% | REGRESS |
| single-day-application-log-heatmap | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | 0 B | 0.0% |  |
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
| single-day-application-log-heatmap | MEMORY/unattributed | 37.7 MB | 38.5 MB | +800.5 KB | 2.1% | REGRESS |
| single-day-application-log-heatmap | MEMORY_FINAL/log_messages | 2914830 | 2914830 | 0 | 0.0% |  |
| single-day-application-log-heatmap | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| single-day-application-log-histogram | TIMING/parse/read_files | 3.7 s | 3.6 s | -116 ms | -3.1% | IMPROVE |
| single-day-application-log-histogram | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-histogram | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 6 ms | +1 ms | 20.0% | REGRESS |
| single-day-application-log-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-histogram | TIMING/total | 3.7 s | 3.6 s | -115 ms | -3.1% | IMPROVE |
| single-day-application-log-histogram | MEMORY/rss_peak | 41.9 MB | 42.1 MB | +208 KB | 0.5% | REGRESS |
| single-day-application-log-histogram | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/format_scan_subs | 1.2 MB | 1.1 MB | -176 KB | -13.9% | IMPROVE |
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
| single-day-application-log-histogram | MEMORY/unattributed | 37.8 MB | 38.2 MB | +384.5 KB | 1.0% | REGRESS |
| single-day-application-log-histogram | MEMORY_FINAL/log_messages | 2914830 | 2914830 | 0 | 0.0% |  |
| single-day-application-log-histogram | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| single-day-application-log-heatmap-histogram | TIMING/detect/registry_build | 12 ms | 13 ms | +1000 us | 8.3% | REGRESS |
| single-day-application-log-heatmap-histogram | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/parse/read_files | 3.7 s | 3.6 s | -162 ms | -4.3% | IMPROVE |
| single-day-application-log-heatmap-histogram | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 5 ms | -1 ms | -16.7% | IMPROVE |
| single-day-application-log-heatmap-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/total | 3.8 s | 3.6 s | -161 ms | -4.3% | IMPROVE |
| single-day-application-log-heatmap-histogram | MEMORY/rss_peak | 41.8 MB | 42.1 MB | +368 KB | 0.9% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/bucket_outcomes | 6 KB | 5.8 KB | -256 B | -4.2% | IMPROVE |
| single-day-application-log-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/format_scan_subs | 1.1 MB | 1 MB | -48 KB | -4.3% | IMPROVE |
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
| single-day-application-log-heatmap-histogram | MEMORY/log_occurrences | 21.8 KB | 21.5 KB | -256 B | -1.1% | IMPROVE |
| single-day-application-log-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_stats | 7.9 KB | 7.9 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_users | 85.5 KB | 85.2 KB | -256 B | -0.3% | IMPROVE |
| single-day-application-log-heatmap-histogram | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/unattributed | 37.8 MB | 38.2 MB | +417.0 KB | 1.1% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/log_messages | 2914830 | 2914830 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| single-day-application-log-heatmap-histogram-export | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | TIMING/parse/read_files | 3.2 s | 3.1 s | -87 ms | -2.7% | IMPROVE |
| single-day-application-log-heatmap-histogram-export | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | TIMING/total | 3.2 s | 3.1 s | -88 ms | -2.7% | IMPROVE |
| single-day-application-log-heatmap-histogram-export | MEMORY/rss_peak | 37.8 MB | 38.4 MB | +624 KB | 1.6% | REGRESS |
| single-day-application-log-heatmap-histogram-export | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | +48 KB | 4.4% | REGRESS |
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
| single-day-application-log-heatmap-histogram-export | MEMORY/log_stats | 7.9 KB | 7.9 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/log_users | 85.5 KB | 85.5 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY/unattributed | 36.6 MB | 37.2 MB | +576.2 KB | 1.5% | REGRESS |
| single-day-application-log-heatmap-histogram-export | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| single-day-application-log-heatmap-histogram-consolidate | TIMING/parse/read_files | 6.2 s | 5.0 s | -1.2 s | -20.0% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 254 ms | 293 ms | +39 ms | 15.4% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/total | 6.5 s | 5.3 s | -1.2 s | -18.6% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 132.2 MB | 112 MB | -20.1 MB | -15.2% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 441.9 KB | 346.2 KB | -95.8 KB | -21.7% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 2.6 MB | 1.4 MB | -1.3 MB | -48.4% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 29.3 MB | 28.0 MB | -1.3 MB | -4.5% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 16.4 MB | N/A | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 29.7 MB | N/A | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 54.3 KB | 42.8 KB | -11.6 KB | -21.3% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 860.9 KB | N/A | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 1.5 MB | 800.7 KB | -760.9 KB | -48.7% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 1.2 MB | 1.1 MB | -96 KB | -8.1% | IMPROVE |
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
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_messages | 2.3 MB | 1.2 MB | -1.1 MB | -47.3% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_stats | 7.9 KB | 7.9 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_users | 85.2 KB | 85.5 KB | +256 B | 0.3% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/message_key_order | 2.6 KB | 2.8 KB | +208 B | 7.8% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/unattributed | 47.7 MB | 23.5 MB | -24.2 MB | -50.8% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 151190 | 91437 | -59753 | -39.5% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 452553 | 354487 | -98066 | -21.7% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 55644 | 43807 | -11837 | -21.3% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 32824 | -32768 | -50.0% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 240 | 240 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 32824 | 32824 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 32824 | N/A | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 136 | 103 | -33 | -24.3% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | COUNTS/log_messages_population | 136 | 103 | -33 | -24.3% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-p99 | TIMING/detect/scan_sub_compile | 7 ms | 6 ms | -1 ms | -14.3% | IMPROVE |
| single-day-application-log-sort-p99 | TIMING/parse/read_files | 3.7 s | 3.6 s | -101 ms | -2.8% | IMPROVE |
| single-day-application-log-sort-p99 | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 5 ms | -1 ms | -16.7% | IMPROVE |
| single-day-application-log-sort-p99 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-p99 | TIMING/total | 3.7 s | 3.6 s | -101 ms | -2.7% | IMPROVE |
| single-day-application-log-sort-p99 | MEMORY/rss_peak | 41.7 MB | 42 MB | +336 KB | 0.8% | REGRESS |
| single-day-application-log-sort-p99 | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/format_scan_subs | 1.2 MB | 1.1 MB | -80 KB | -6.8% | IMPROVE |
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
| single-day-application-log-sort-p99 | MEMORY/log_stats | 7.9 KB | 7.6 KB | -256 B | -3.2% | IMPROVE |
| single-day-application-log-sort-p99 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/log_users | 85.5 KB | 85.2 KB | -256 B | -0.3% | IMPROVE |
| single-day-application-log-sort-p99 | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY/unattributed | 37.6 MB | 38 MB | +416.7 KB | 1.1% | REGRESS |
| single-day-application-log-sort-p99 | MEMORY_FINAL/log_messages | 2914830 | 2914830 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| single-day-application-log-sort-skewness | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-skewness | TIMING/parse/read_files | 3.7 s | 3.6 s | -86 ms | -2.3% | IMPROVE |
| single-day-application-log-sort-skewness | TIMING/finalize/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 6 ms | +1 ms | 20.0% | REGRESS |
| single-day-application-log-sort-skewness | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-sort-skewness | TIMING/total | 3.7 s | 3.6 s | -85 ms | -2.3% | IMPROVE |
| single-day-application-log-sort-skewness | MEMORY/rss_peak | 42.0 MB | 42 MB | +80 KB | 0.2% | REGRESS |
| single-day-application-log-sort-skewness | MEMORY/bucket_outcomes | 6 KB | 6 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/format_scan_subs | 1.2 MB | 1.1 MB | -96 KB | -8.0% | IMPROVE |
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
| single-day-application-log-sort-skewness | MEMORY/log_users | 85.5 KB | 85.2 KB | -256 B | -0.3% | IMPROVE |
| single-day-application-log-sort-skewness | MEMORY/message_key_order | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY/unattributed | 37.9 MB | 38.1 MB | +176.5 KB | 0.5% | REGRESS |
| single-day-application-log-sort-skewness | MEMORY_FINAL/log_messages | 2914830 | 2914830 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-application-log-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| multi-day-application-logs-standard | TIMING/parse/read_files | 7.8 s | 7.6 s | -254 ms | -3.2% | IMPROVE |
| multi-day-application-logs-standard | TIMING/finalize/calculate_statistics | 173 ms | 174 ms | +1 ms | 0.6% | REGRESS |
| multi-day-application-logs-standard | TIMING/finalize/calculate_statistics/sort_selection | 171 ms | 171 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-standard | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-standard | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-standard | TIMING/total | 8 s | 7.8 s | -253 ms | -3.2% | IMPROVE |
| multi-day-application-logs-standard | MEMORY/rss_peak | 106.7 MB | 107.2 MB | +496 KB | 0.5% | REGRESS |
| multi-day-application-logs-standard | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | +16 KB | 1.5% | REGRESS |
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
| multi-day-application-logs-standard | MEMORY/log_users | 40.6 KB | 40.9 KB | +320 B | 0.8% | REGRESS |
| multi-day-application-logs-standard | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/unattributed | 56.6 MB | 57 MB | +479.9 KB | 0.8% | REGRESS |
| multi-day-application-logs-standard | MEMORY_FINAL/log_messages | 51302480 | 51302480 | 0 | 0.0% |  |
| multi-day-application-logs-standard | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| multi-day-application-logs-no-messages | TIMING/parse/read_files | 6.7 s | 6.5 s | -201 ms | -3.0% | IMPROVE |
| multi-day-application-logs-no-messages | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-no-messages | TIMING/total | 6.7 s | 6.5 s | -200 ms | -3.0% | IMPROVE |
| multi-day-application-logs-no-messages | MEMORY/rss_peak | 39.4 MB | 39.4 MB | -64 KB | -0.2% | IMPROVE |
| multi-day-application-logs-no-messages | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/format_scan_subs | 1.2 MB | 1.1 MB | -112 KB | -9.1% | IMPROVE |
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
| multi-day-application-logs-no-messages | MEMORY/log_users | 40.6 KB | 40.7 KB | +64 B | 0.2% | REGRESS |
| multi-day-application-logs-no-messages | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY/unattributed | 38.1 MB | 38.1 MB | +48.2 KB | 0.1% | REGRESS |
| multi-day-application-logs-no-messages | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-no-messages | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| multi-day-application-logs-top25 | TIMING/parse/read_files | 7.7 s | 7.6 s | -96 ms | -1.2% | IMPROVE |
| multi-day-application-logs-top25 | TIMING/finalize/calculate_statistics | 174 ms | 179 ms | +5 ms | 2.9% | REGRESS |
| multi-day-application-logs-top25 | TIMING/finalize/calculate_statistics/sort_selection | 172 ms | 176 ms | +4 ms | 2.3% | REGRESS |
| multi-day-application-logs-top25 | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/total | 7.9 s | 7.8 s | -90 ms | -1.1% | IMPROVE |
| multi-day-application-logs-top25 | MEMORY/rss_peak | 106.7 MB | 107.3 MB | +656 KB | 0.6% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | -32 KB | -2.7% | IMPROVE |
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
| multi-day-application-logs-top25 | MEMORY/log_users | 40.3 KB | 40.5 KB | +128 B | 0.3% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/message_key_order | 6.5 KB | 6.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/unattributed | 56.5 MB | 57.1 MB | +688.1 KB | 1.2% | REGRESS |
| multi-day-application-logs-top25 | MEMORY_FINAL/log_messages | 51302480 | 51302480 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| multi-day-application-logs-top25-consolidate | lines_read | 930,031 | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | lines_excluded | 0 | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | lines_included | 930,028 | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/detect/registry_build | 12 ms | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/detect/scan_sub_compile | 6 ms | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/parse/read_files | 35.8 s | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/accumulate/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/group_similar | 4.1 s | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/calculate_statistics | 3 ms | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | 0 us | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/calculate_statistics/population_walk | 0 us | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 2 ms | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | 0 us | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/calculate_statistics/threadpool_stats | 0 us | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/calculate_statistics/untimed | 0 us | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/heatmap_statistics | 0 us | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/histogram_statistics | 0 us | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/render/normalize_data | 3 ms | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/total | 39.9 s | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | 216 MB | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/bucket_outcomes | 13.3 KB | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_clusters | 3.6 MB | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_message | 3.5 MB | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 62.1 MB | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 10.4 MB | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_ngram_index | 60.6 MB | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_patterns | 485.8 KB | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_posting_size | 1.6 MB | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_unmatched | 2.1 MB | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/format_scan_subs | 1.1 MB | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_counters | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/histogram_counters | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/histogram_values | 576 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/log_analysis | 240 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/log_messages | 3.3 MB | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/log_messages_counters | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/log_occurrences | 56.6 KB | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/log_sessions | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/log_stats | 17.1 KB | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/log_threadpools | 240 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/log_users | 41 KB | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/message_key_order | 5.7 KB | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/threadpool_activity | 778 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/udm_distinct | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/unattributed | 67 MB | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/log_messages | 758060 | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 240 | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 3726518 | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 497416 | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 240 | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 8248 | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | COUNTS/log_messages_entries | 1303 | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | COUNTS/log_occurrences_entries | 53 | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | COUNTS/log_stats_entries | 53 | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | COUNTS/log_analysis_entries | 0 | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | COUNTS/log_messages_population | 1303 | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | COUNTS/threadpool_entries | 0 | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | COUNTS/format_scan_subs_compiled | 1 | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | COUNTS/format_scan_sub_cache_hits | 40 | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | CONFIG/terminal_height | 24 | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | CONFIG/time_bucket_size | 480 | N/A | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | CONFIG/bucket_size_seconds | 28800.00 | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/parse/read_files | 7.7 s | 7.7 s | +17 ms | 0.2% | REGRESS |
| multi-day-application-logs-heatmap | TIMING/finalize/calculate_statistics | 171 ms | 177 ms | +6 ms | 3.5% | REGRESS |
| multi-day-application-logs-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 168 ms | 174 ms | +6 ms | 3.6% | REGRESS |
| multi-day-application-logs-heatmap | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/total | 7.9 s | 7.9 s | +22 ms | 0.3% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY/rss_peak | 107 MB | 107.5 MB | +432 KB | 0.4% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | 0 B | 0.0% |  |
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
| multi-day-application-logs-heatmap | MEMORY/log_users | 40.9 KB | 40.6 KB | -256 B | -0.6% | IMPROVE |
| multi-day-application-logs-heatmap | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/unattributed | 56.8 MB | 57.3 MB | +432.5 KB | 0.7% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY_FINAL/log_messages | 51302480 | 51302480 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| multi-day-application-logs-histogram | TIMING/parse/read_files | 7.8 s | 7.6 s | -210 ms | -2.7% | IMPROVE |
| multi-day-application-logs-histogram | TIMING/finalize/calculate_statistics | 178 ms | 180 ms | +2 ms | 1.1% | REGRESS |
| multi-day-application-logs-histogram | TIMING/finalize/calculate_statistics/sort_selection | 175 ms | 177 ms | +2 ms | 1.1% | REGRESS |
| multi-day-application-logs-histogram | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/total | 8 s | 7.8 s | -208 ms | -2.6% | IMPROVE |
| multi-day-application-logs-histogram | MEMORY/rss_peak | 106.6 MB | 107.2 MB | +624 KB | 0.6% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | 0 B | 0.0% |  |
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
| multi-day-application-logs-histogram | MEMORY/log_occurrences | 56.7 KB | 56.6 KB | -64 B | -0.1% | IMPROVE |
| multi-day-application-logs-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_users | 40.4 KB | 40.6 KB | +192 B | 0.5% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/unattributed | 56.5 MB | 57.1 MB | +624.1 KB | 1.1% | REGRESS |
| multi-day-application-logs-histogram | MEMORY_FINAL/log_messages | 51302480 | 51302480 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| multi-day-application-logs-heatmap-histogram | TIMING/parse/read_files | 7.8 s | 7.6 s | -190 ms | -2.4% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | TIMING/finalize/calculate_statistics | 173 ms | 183 ms | +10 ms | 5.8% | REGRESS |
| multi-day-application-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 171 ms | 180 ms | +9 ms | 5.3% | REGRESS |
| multi-day-application-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/total | 8 s | 7.8 s | -181 ms | -2.3% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | MEMORY/rss_peak | 107.1 MB | 106.8 MB | -304 KB | -0.3% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/format_scan_subs | 1.2 MB | 1.1 MB | -128 KB | -10.3% | IMPROVE |
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
| multi-day-application-logs-heatmap-histogram | MEMORY/log_occurrences | 56.7 KB | 56.6 KB | -64 B | -0.1% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_users | 40.8 KB | 40.7 KB | -128 B | -0.3% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/unattributed | 56.8 MB | 56.7 MB | -175.6 KB | -0.3% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 51302480 | 51302480 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| multi-day-application-logs-heatmap-histogram-export | TIMING/parse/read_files | 6.6 s | 6.5 s | -77 ms | -1.2% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-export | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | TIMING/total | 6.6 s | 6.5 s | -76 ms | -1.1% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/rss_peak | 39.0 MB | 39.7 MB | +720 KB | 1.8% | REGRESS |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | -32 KB | -2.7% | IMPROVE |
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
| multi-day-application-logs-heatmap-histogram-export | MEMORY/log_users | 40.6 KB | 40.8 KB | +192 B | 0.5% | REGRESS |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/unattributed | 37.7 MB | 38.4 MB | +752.1 KB | 1.9% | REGRESS |
| multi-day-application-logs-heatmap-histogram-export | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | COUNTS/log_occurrences_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | COUNTS/log_stats_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | COUNTS/format_scan_sub_cache_hits | 40 | 40 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-export | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_read | 930,031 | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_excluded | 0 | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_included | 930,028 | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/detect/registry_build | 12 ms | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 6 ms | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/parse/read_files | 35.9 s | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/accumulate/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 4.2 s | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 3 ms | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | 0 us | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/population_walk | 0 us | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 3 ms | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | 0 us | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/threadpool_stats | 0 us | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/untimed | 0 us | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/heatmap_statistics | 0 us | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/histogram_statistics | 0 us | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/render/normalize_data | 3 ms | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | 40.1 s | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 216.1 MB | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 13.3 KB | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 3.6 MB | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 3.5 MB | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 62.1 MB | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 10.4 MB | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 60.6 MB | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 485.8 KB | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 1.6 MB | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 2.1 MB | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 1.1 MB | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 240 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 3.3 MB | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 56.6 KB | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 17.1 KB | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 240 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_users | 40.8 KB | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | 3 KB | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 778 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/unattributed | 67.1 MB | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 758060 | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 240 | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 3726518 | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 497416 | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 240 | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 8248 | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 1303 | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 53 | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 53 | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_analysis_entries | 0 | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_messages_population | 1303 | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/threadpool_entries | 0 | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 1 | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/format_scan_sub_cache_hits | 40 | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 480 | N/A | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 28800.00 | N/A | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-p99 | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-p99 | TIMING/parse/read_files | 7.8 s | 7.6 s | -223 ms | -2.9% | IMPROVE |
| multi-day-application-logs-sort-p99 | TIMING/finalize/calculate_statistics | 179 ms | 177 ms | -2 ms | -1.1% | IMPROVE |
| multi-day-application-logs-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 176 ms | 174 ms | -2 ms | -1.1% | IMPROVE |
| multi-day-application-logs-sort-p99 | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-p99 | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-p99 | TIMING/total | 8 s | 7.8 s | -225 ms | -2.8% | IMPROVE |
| multi-day-application-logs-sort-p99 | MEMORY/rss_peak | 106.7 MB | 107.2 MB | +464 KB | 0.4% | REGRESS |
| multi-day-application-logs-sort-p99 | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/format_scan_subs | 1 MB | 1.1 MB | +32 KB | 3.0% | REGRESS |
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
| multi-day-application-logs-sort-p99 | MEMORY/log_users | 40.7 KB | 40.6 KB | -64 B | -0.2% | IMPROVE |
| multi-day-application-logs-sort-p99 | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY/unattributed | 56.6 MB | 57 MB | +432.3 KB | 0.7% | REGRESS |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/log_messages | 51302480 | 51302480 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| multi-day-application-logs-sort-skewness | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-skewness | TIMING/parse/read_files | 7.7 s | 7.6 s | -152 ms | -2.0% | IMPROVE |
| multi-day-application-logs-sort-skewness | TIMING/finalize/calculate_statistics | 174 ms | 178 ms | +4 ms | 2.3% | REGRESS |
| multi-day-application-logs-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 171 ms | 176 ms | +5 ms | 2.9% | REGRESS |
| multi-day-application-logs-sort-skewness | TIMING/finalize/calculate_statistics/untimed | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-skewness | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-sort-skewness | TIMING/total | 7.9 s | 7.8 s | -147 ms | -1.9% | IMPROVE |
| multi-day-application-logs-sort-skewness | MEMORY/rss_peak | 107 MB | 107.2 MB | +224 KB | 0.2% | REGRESS |
| multi-day-application-logs-sort-skewness | MEMORY/bucket_outcomes | 13.3 KB | 13.3 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/format_scan_subs | 1.2 MB | 1.1 MB | -64 KB | -5.3% | IMPROVE |
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
| multi-day-application-logs-sort-skewness | MEMORY/log_occurrences | 56.7 KB | 56.7 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/log_stats | 17.1 KB | 17.1 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/log_users | 40.6 KB | 40.2 KB | -448 B | -1.1% | IMPROVE |
| multi-day-application-logs-sort-skewness | MEMORY/message_key_order | 3.5 KB | 3.5 KB | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY/unattributed | 56.8 MB | 57.1 MB | +288.7 KB | 0.5% | REGRESS |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/log_messages | 51302480 | 51302480 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/log_analysis | 240 | 240 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| multi-day-custom-logs-standard | TIMING/parse/read_files | 16.2 s | 16.1 s | -87 ms | -0.5% | IMPROVE |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics | 352 ms | 351 ms | -1 ms | -0.3% | IMPROVE |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics/bucket_stats | 39 ms | 38 ms | -1 ms | -2.6% | IMPROVE |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics/sort_selection | 304 ms | 304 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics/group_calc | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/finalize/calculate_statistics/untimed | 7 ms | 7 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/total | 16.5 s | 16.4 s | -87 ms | -0.5% | IMPROVE |
| multi-day-custom-logs-standard | MEMORY/rss_peak | 175.1 MB | 175.5 MB | +400 KB | 0.2% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | 0 B | 0.0% |  |
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
| multi-day-custom-logs-standard | MEMORY/log_messages | 89.9 MB | 89.4 MB | -539.2 KB | -0.6% | IMPROVE |
| multi-day-custom-logs-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_stats | 50.3 KB | 50.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_users | 12.7 KB | 12.7 KB | -64 B | -0.5% | IMPROVE |
| multi-day-custom-logs-standard | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/unattributed | 71.1 MB | 72.0 MB | +939.5 KB | 1.3% | REGRESS |
| multi-day-custom-logs-standard | MEMORY_FINAL/log_messages | 94279142 | 93727014 | -552128 | -0.6% | IMPROVE |
| multi-day-custom-logs-standard | MEMORY_FINAL/log_analysis | 20350 | 20350 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| multi-day-custom-logs-no-messages | TIMING/detect/registry_build | 11 ms | 12 ms | +1 ms | 9.1% | REGRESS |
| multi-day-custom-logs-no-messages | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-no-messages | TIMING/parse/read_files | 13.1 s | 13 s | -112 ms | -0.9% | IMPROVE |
| multi-day-custom-logs-no-messages | TIMING/finalize/calculate_statistics | 33 ms | 34 ms | +1 ms | 3.0% | REGRESS |
| multi-day-custom-logs-no-messages | TIMING/finalize/calculate_statistics/bucket_stats | 33 ms | 34 ms | +1 ms | 3.0% | REGRESS |
| multi-day-custom-logs-no-messages | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-no-messages | TIMING/total | 13.2 s | 13.1 s | -111 ms | -0.8% | IMPROVE |
| multi-day-custom-logs-no-messages | MEMORY/rss_peak | 53.9 MB | 54.4 MB | +512 KB | 0.9% | REGRESS |
| multi-day-custom-logs-no-messages | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | +16 KB | 1.4% | REGRESS |
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
| multi-day-custom-logs-no-messages | MEMORY/log_users | 12.7 KB | 12.7 KB | -64 B | -0.5% | IMPROVE |
| multi-day-custom-logs-no-messages | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY/unattributed | 39.8 MB | 40.3 MB | +496.3 KB | 1.2% | REGRESS |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/log_analysis | 20350 | 20350 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| multi-day-custom-logs-top25 | TIMING/parse/read_files | 16.1 s | 16.1 s | -28 ms | -0.2% | IMPROVE |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics | 353 ms | 357 ms | +4 ms | 1.1% | REGRESS |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics/bucket_stats | 40 ms | 39 ms | -1 ms | -2.5% | IMPROVE |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics/sort_selection | 301 ms | 306 ms | +5 ms | 1.7% | REGRESS |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics/group_calc | 5 ms | 5 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/finalize/calculate_statistics/untimed | 7 ms | 7 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/total | 16.4 s | 16.4 s | -23 ms | -0.1% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/rss_peak | 176.2 MB | 176.3 MB | +80 KB | 0.0% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/format_scan_subs | 1.2 MB | 1.1 MB | -32 KB | -2.7% | IMPROVE |
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
| multi-day-custom-logs-top25 | MEMORY/log_messages | 89.5 MB | 89.4 MB | -124.8 KB | -0.1% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_stats | 50.3 KB | 50.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_users | 12.7 KB | 12.7 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/unattributed | 72.5 MB | 72.7 MB | +237.0 KB | 0.3% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY_FINAL/log_messages | 93864790 | 93737046 | -127744 | -0.1% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY_FINAL/log_analysis | 20350 | 20350 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| multi-day-custom-logs-top25-consolidate | TIMING/parse/read_files | 46.9 s | 33.6 s | -13.3 s | -28.4% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/group_similar | 4.3 s | 4.7 s | +389 ms | 9.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/calculate_statistics | 173 ms | 148 ms | -25 ms | -14.5% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | 75 ms | 64 ms | -11 ms | -14.7% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | 97 ms | 83 ms | -14 ms | -14.4% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/total | 51.4 s | 38.5 s | -13.0 s | -25.2% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/rss_peak | 222.1 MB | 229.0 MB | +6.9 MB | 3.1% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_clusters | 14.1 MB | 14.1 MB | +7.3 KB | 0.1% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_message | 5.8 MB | 5.8 MB | -3.9 KB | -0.1% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 62.6 MB | 62.7 MB | +37.2 KB | 0.1% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 4.5 MB | N/A | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_ngram_index | 61.3 MB | N/A | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_patterns | 202.8 KB | 193.0 KB | -9.9 KB | -4.9% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_posting_size | 478.1 KB | N/A | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_unmatched | 3.3 MB | 3.3 MB | -1.9 KB | -0.1% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/format_scan_subs | 1.2 MB | 1.1 MB | -16 KB | -1.4% | IMPROVE |
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
| multi-day-custom-logs-top25-consolidate | MEMORY/log_messages | 13.1 MB | 13.2 MB | +72.2 KB | 0.5% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_stats | 50.3 KB | 50.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_users | 12.7 KB | 12.7 KB | -64 B | -0.5% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/message_key_order | 6.1 KB | 6.1 KB | -9 B | -0.1% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/unattributed | 42.6 MB | 0 B | -42.6 MB | -100.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/log_messages | 13742476 | 13816460 | 73984 | 0.5% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 20350 | 20350 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 14746022 | 14753524 | 7502 | 0.1% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 207697 | 197600 | -10097 | -4.9% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 240 | 240 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 4152 | N/A | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_messages_entries | 606 | 363 | -243 | -40.1% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_occurrences_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_stats_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_analysis_entries | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_messages_population | 606 | 363 | -243 | -40.1% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/format_scan_sub_cache_hits | 4 | 4 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/parse/read_files | 16.6 s | 17 s | +400 ms | 2.4% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/finalize/calculate_statistics | 312 ms | 346 ms | +34 ms | 10.9% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 304 ms | 337 ms | +33 ms | 10.9% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/finalize/calculate_statistics/group_calc | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/finalize/calculate_statistics/untimed | 6 ms | 8 ms | +2 ms | 33.3% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/finalize/heatmap_statistics | 49 ms | 54 ms | +5 ms | 10.2% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/total | 17.0 s | 17.4 s | +438 ms | 2.6% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/rss_peak | 172.4 MB | 176.4 MB | +4.0 MB | 2.3% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | +16 KB | 1.4% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_counters | 985.8 KB | 987.2 KB | +1.5 KB | 0.2% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_data | 42.8 KB | 43.6 KB | +896 B | 2.0% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_analysis | 20.9 KB | 20.9 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_messages | 89.5 MB | 89.9 MB | +414.1 KB | 0.5% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_stats | 35.5 KB | 35.5 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_users | 12.7 KB | 12.7 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/unattributed | 80.7 MB | 84.3 MB | +3.5 MB | 4.4% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/log_messages | 93854950 | 94278950 | 424000 | 0.5% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/log_analysis | 20350 | 20350 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| multi-day-custom-logs-histogram | TIMING/detect/registry_build | 12 ms | 13 ms | +1000 us | 8.3% | REGRESS |
| multi-day-custom-logs-histogram | TIMING/detect/scan_sub_compile | 6 ms | 7 ms | +1 ms | 16.7% | REGRESS |
| multi-day-custom-logs-histogram | TIMING/parse/read_files | 16.8 s | 17 s | +214 ms | 1.3% | REGRESS |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics | 354 ms | 361 ms | +7 ms | 2.0% | REGRESS |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics/bucket_stats | 40 ms | 39 ms | -1 ms | -2.5% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics/sort_selection | 305 ms | 313 ms | +8 ms | 2.6% | REGRESS |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics/group_calc | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/finalize/calculate_statistics/untimed | 7 ms | 8 ms | +1 ms | 14.3% | REGRESS |
| multi-day-custom-logs-histogram | TIMING/finalize/histogram_statistics | 16 ms | 14 ms | -2 ms | -12.5% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/total | 17.2 s | 17.4 s | +221 ms | 1.3% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/rss_peak | 176.3 MB | 178.4 MB | +2.1 MB | 1.2% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/format_scan_subs | 1.2 MB | 1.1 MB | -32 KB | -2.7% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/histogram_counters | 122.5 KB | 122.5 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_analysis | 12.9 MB | 12.9 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_messages | 89.5 MB | 89.4 MB | -124.6 KB | -0.1% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_stats | 50.3 KB | 50.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_users | 12.7 KB | 12.7 KB | -64 B | -0.5% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/unattributed | 72.5 MB | 74.7 MB | +2.3 MB | 3.1% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY_FINAL/log_messages | 93854758 | 93727206 | -127552 | -0.1% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY_FINAL/log_analysis | 20350 | 20350 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| multi-day-custom-logs-heatmap-histogram | TIMING/parse/read_files | 17.2 s | 17.1 s | -146 ms | -0.8% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/calculate_statistics | 315 ms | 315 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 307 ms | 306 ms | -1 ms | -0.3% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/group_calc | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | 6 ms | 6 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/heatmap_statistics | 50 ms | 49 ms | -1 ms | -2.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/finalize/histogram_statistics | 14 ms | 14 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/total | 17.6 s | 17.4 s | -146 ms | -0.8% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/rss_peak | 172.9 MB | 173.4 MB | +512 KB | 0.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | +16 KB | 1.4% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_counters | 985.8 KB | 985.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_data | 43.1 KB | 43.2 KB | +128 B | 0.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_counters | 122.5 KB | 122.5 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_analysis | 20.9 KB | 20.9 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_messages | 89.9 MB | 89.9 MB | -55.4 KB | -0.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_stats | 35.5 KB | 35.5 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_users | 12.7 KB | 12.7 KB | -64 B | -0.5% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/message_key_order | 19.8 KB | 19.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/unattributed | 80.6 MB | 81.2 MB | +551.5 KB | 0.7% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 94279142 | 94222438 | -56704 | -0.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 20350 | 20350 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| multi-day-custom-logs-heatmap-histogram-export | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/parse/read_files | 14.5 s | 14.2 s | -346 ms | -2.4% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics | 96 ms | 97 ms | +1 ms | 1.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/bucket_stats | 96 ms | 97 ms | +1 ms | 1.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/heatmap_statistics | 153 ms | 174 ms | +21 ms | 13.7% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/finalize/histogram_statistics | 14 ms | 15 ms | +1000 us | 7.1% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | TIMING/total | 14.8 s | 14.5 s | -324 ms | -2.2% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/rss_peak | 57.6 MB | 57.6 MB | +16 KB | 0.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/format_scan_subs | 1.2 MB | 1.1 MB | -112 KB | -9.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/heatmap_counters | 987.2 KB | 985.8 KB | -1.5 KB | -0.2% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/heatmap_data | 43.3 KB | 42.8 KB | -448 B | -1.0% | IMPROVE |
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
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_stats | 70.0 KB | 70.0 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/log_users | 12.7 KB | 12.7 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/unattributed | 42.2 MB | 42.4 MB | +130.4 KB | 0.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY_FINAL/log_analysis | 24647 | 24647 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/parse/read_files | 48.4 s | 34.9 s | -13.5 s | -27.9% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 4.1 s | 4.5 s | +338 ms | 8.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 89 ms | 63 ms | -26 ms | -29.2% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | 87 ms | 62 ms | -25 ms | -28.7% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/heatmap_statistics | 54 ms | 52 ms | -2 ms | -3.7% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/finalize/histogram_statistics | 15 ms | 15 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/render/normalize_data | 3 ms | 2 ms | -1 ms | -33.3% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/total | 52.7 s | 39.5 s | -13.2 s | -25.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 215.8 MB | 227.0 MB | +11.1 MB | 5.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 14.1 MB | 14.1 MB | +14.7 KB | 0.1% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 5.8 MB | 5.8 MB | -3.9 KB | -0.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 62.6 MB | 62.7 MB | +47.2 KB | 0.1% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 4.5 MB | N/A | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 61.3 MB | N/A | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 202.8 KB | 193.0 KB | -9.9 KB | -4.9% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 478.1 KB | N/A | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 3.3 MB | 3.3 MB | -1.9 KB | -0.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | -32 KB | -2.9% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 985.5 KB | 985.5 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 40.3 KB | 43.6 KB | +3.4 KB | 8.4% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | 122.5 KB | 122.5 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 20.7 KB | 20.7 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 13.1 MB | 13.2 MB | +73 KB | 0.5% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 35.5 KB | 35.2 KB | -256 B | -0.7% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_users | 12.7 KB | 12.7 KB | -64 B | -0.5% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | 2.7 KB | 2.6 KB | -15 B | -0.5% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/unattributed | 48.1 MB | 2.6 MB | -45.5 MB | -94.6% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 13736620 | 13811372 | 74752 | 0.5% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 20094 | 20094 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 14746022 | 14761076 | 15054 | 0.1% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 207697 | 197600 | -10097 | -4.9% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 240 | 240 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 4152 | N/A | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 606 | 363 | -243 | -40.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_analysis_entries | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_messages_population | 606 | 363 | -243 | -40.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/format_scan_sub_cache_hits | 4 | 4 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | TIMING/detect/registry_build | 13 ms | 12 ms | -1000 us | -7.7% | IMPROVE |
| multi-day-custom-logs-sort-p99 | TIMING/detect/scan_sub_compile | 8 ms | 6 ms | -2 ms | -25.0% | IMPROVE |
| multi-day-custom-logs-sort-p99 | TIMING/parse/read_files | 16.1 s | 16.0 s | -122 ms | -0.8% | IMPROVE |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics | 231 ms | 246 ms | +15 ms | 6.5% | REGRESS |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics/bucket_stats | 39 ms | 39 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | 181 ms | 195 ms | +14 ms | 7.7% | REGRESS |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-p99 | TIMING/finalize/calculate_statistics/untimed | 7 ms | 8 ms | +1 ms | 14.3% | REGRESS |
| multi-day-custom-logs-sort-p99 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-p99 | TIMING/total | 16.3 s | 16.2 s | -110 ms | -0.7% | IMPROVE |
| multi-day-custom-logs-sort-p99 | MEMORY/rss_peak | 173.4 MB | 172.9 MB | -464 KB | -0.3% | IMPROVE |
| multi-day-custom-logs-sort-p99 | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/format_scan_subs | 1.2 MB | 1.1 MB | -112 KB | -9.1% | IMPROVE |
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
| multi-day-custom-logs-sort-p99 | MEMORY/log_messages | 89.5 MB | 89.9 MB | +414.9 KB | 0.5% | REGRESS |
| multi-day-custom-logs-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_stats | 50.3 KB | 50.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/log_users | 12.7 KB | 12.7 KB | -64 B | -0.5% | IMPROVE |
| multi-day-custom-logs-sort-p99 | MEMORY/message_key_order | 2.7 KB | 2.7 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY/unattributed | 69.7 MB | 68.9 MB | -766.6 KB | -1.1% | IMPROVE |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/log_messages | 93854838 | 94279670 | 424832 | 0.5% | REGRESS |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/log_analysis | 20350 | 20350 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| multi-day-custom-logs-sort-skewness | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-skewness | TIMING/parse/read_files | 16 s | 16 s | -22 ms | -0.1% | IMPROVE |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics | 303 ms | 316 ms | +13 ms | 4.3% | REGRESS |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/bucket_stats | 39 ms | 39 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | 248 ms | 261 ms | +13 ms | 5.2% | REGRESS |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/group_calc | 5 ms | 5 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-skewness | TIMING/finalize/calculate_statistics/untimed | 8 ms | 8 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-skewness | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-sort-skewness | TIMING/total | 16.3 s | 16.3 s | -9 ms | -0.1% | IMPROVE |
| multi-day-custom-logs-sort-skewness | MEMORY/rss_peak | 172.0 MB | 175.3 MB | +3.4 MB | 2.0% | REGRESS |
| multi-day-custom-logs-sort-skewness | MEMORY/bucket_outcomes | 6.3 KB | 6.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | -32 KB | -2.8% | IMPROVE |
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
| multi-day-custom-logs-sort-skewness | MEMORY/log_messages | 89.5 MB | 89.5 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_stats | 50.3 KB | 50.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/log_users | 12.7 KB | 12.7 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/message_key_order | 2.5 KB | 2.5 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY/unattributed | 68.3 MB | 71.7 MB | +3.4 MB | 5.0% | REGRESS |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/log_messages | 93859739 | 93859739 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/log_analysis | 20350 | 20350 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| single-day-access-log-standard | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-access-log-standard | TIMING/parse/read_files | 8.7 s | 8.5 s | -133 ms | -1.5% | IMPROVE |
| single-day-access-log-standard | TIMING/finalize/calculate_statistics | 96 ms | 97 ms | +1 ms | 1.0% | REGRESS |
| single-day-access-log-standard | TIMING/finalize/calculate_statistics/bucket_stats | 68 ms | 68 ms | 0 ms | 0.0% |  |
| single-day-access-log-standard | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 6 ms | +1 ms | 20.0% | REGRESS |
| single-day-access-log-standard | TIMING/finalize/calculate_statistics/group_calc | 23 ms | 23 ms | 0 ms | 0.0% |  |
| single-day-access-log-standard | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-standard | TIMING/total | 8.8 s | 8.7 s | -132 ms | -1.5% | IMPROVE |
| single-day-access-log-standard | MEMORY/rss_peak | 101.2 MB | 99.6 MB | -1.6 MB | -1.6% | IMPROVE |
| single-day-access-log-standard | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/format_scan_subs | 1.2 MB | 1.1 MB | -144 KB | -11.5% | IMPROVE |
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
| single-day-access-log-standard | MEMORY/log_messages | 26.9 MB | 26.9 MB | 0 B | 0.0% |  |
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
| single-day-access-log-standard | MEMORY/unattributed | 49.4 MB | 47.9 MB | -1.5 MB | -3.0% | IMPROVE |
| single-day-access-log-standard | MEMORY_FINAL/log_messages | 28180482 | 28180482 | 0 | 0.0% |  |
| single-day-access-log-standard | MEMORY_FINAL/log_analysis | 6678 | 6678 | 0 | 0.0% |  |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| single-day-access-log-no-messages | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| single-day-access-log-no-messages | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-access-log-no-messages | TIMING/parse/read_files | 6.6 s | 6.5 s | -70 ms | -1.1% | IMPROVE |
| single-day-access-log-no-messages | TIMING/finalize/calculate_statistics | 65 ms | 66 ms | +1 ms | 1.5% | REGRESS |
| single-day-access-log-no-messages | TIMING/finalize/calculate_statistics/bucket_stats | 65 ms | 66 ms | +1 ms | 1.5% | REGRESS |
| single-day-access-log-no-messages | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-no-messages | TIMING/total | 6.7 s | 6.6 s | -68 ms | -1.0% | IMPROVE |
| single-day-access-log-no-messages | MEMORY/rss_peak | 64.3 MB | 64.7 MB | +400 KB | 0.6% | REGRESS |
| single-day-access-log-no-messages | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-no-messages | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | -16 KB | -1.4% | IMPROVE |
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
| single-day-access-log-no-messages | MEMORY/unattributed | 39.5 MB | 39.9 MB | +416.2 KB | 1.0% | REGRESS |
| single-day-access-log-no-messages | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| single-day-access-log-no-messages | MEMORY_FINAL/log_analysis | 6678 | 6678 | 0 | 0.0% |  |
| single-day-access-log-no-messages | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-no-messages | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-no-messages | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-no-messages | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-no-messages | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-no-messages | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| single-day-access-log-top25 | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25 | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25 | TIMING/parse/read_files | 8.6 s | 8.5 s | -49 ms | -0.6% | IMPROVE |
| single-day-access-log-top25 | TIMING/finalize/calculate_statistics | 105 ms | 105 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25 | TIMING/finalize/calculate_statistics/bucket_stats | 69 ms | 69 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25 | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25 | TIMING/finalize/calculate_statistics/group_calc | 30 ms | 31 ms | +1 ms | 3.3% | REGRESS |
| single-day-access-log-top25 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25 | TIMING/total | 8.7 s | 8.6 s | -48 ms | -0.6% | IMPROVE |
| single-day-access-log-top25 | MEMORY/rss_peak | 98.2 MB | 99.8 MB | +1.6 MB | 1.6% | REGRESS |
| single-day-access-log-top25 | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | -16 KB | -1.4% | IMPROVE |
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
| single-day-access-log-top25 | MEMORY/unattributed | 46.5 MB | 48.1 MB | +1.6 MB | 3.4% | REGRESS |
| single-day-access-log-top25 | MEMORY_FINAL/log_messages | 28188642 | 28188642 | 0 | 0.0% |  |
| single-day-access-log-top25 | MEMORY_FINAL/log_analysis | 6678 | 6678 | 0 | 0.0% |  |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| single-day-access-log-top25-consolidate | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/parse/read_files | 10.0 s | 9.5 s | -511 ms | -5.1% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/finalize/group_similar | 2.4 s | 2.2 s | -184 ms | -7.7% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/finalize/calculate_statistics | 144 ms | 142 ms | -2 ms | -1.4% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | 79 ms | 79 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | 64 ms | 62 ms | -2 ms | -3.1% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/total | 12.5 s | 11.8 s | -698 ms | -5.6% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/rss_peak | 131.2 MB | 132.8 MB | +1.7 MB | 1.3% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_clusters | 22.2 MB | 22 MB | -148.9 KB | -0.7% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_message | 888 KB | 888 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_trigrams | 4.1 MB | 4.1 MB | +6 KB | 0.1% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_ngram_index | 4.8 MB | N/A | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_patterns | 118.1 KB | 119.4 KB | +1.3 KB | 1.1% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_posting_size | 352.5 KB | N/A | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_unmatched | 565.2 KB | 565.2 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/format_scan_subs | 1.2 MB | 1.1 MB | -112 KB | -9.2% | IMPROVE |
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
| single-day-access-log-top25-consolidate | MEMORY/message_key_order | 3.8 KB | 3.8 KB | +41 B | 1.1% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/unattributed | 46.4 MB | 45 MB | -1.4 MB | -3.0% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/log_messages | 25712795 | 25749074 | 36279 | 0.1% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/log_analysis | 6678 | 6678 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 23239886 | 23087425 | -152461 | -0.7% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 119803 | 122293 | 2490 | 2.1% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 304 | 304 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 16440 | 16440 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | COUNTS/log_messages_entries | 615 | 656 | 41 | 6.7% | REGRESS |
| single-day-access-log-top25-consolidate | COUNTS/log_occurrences_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/log_stats_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/log_analysis_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/log_messages_population | 615 | 656 | 41 | 6.7% | REGRESS |
| single-day-access-log-top25-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap | TIMING/parse/read_files | 9.3 s | 9.3 s | -62 ms | -0.7% | IMPROVE |
| single-day-access-log-heatmap | TIMING/finalize/calculate_statistics | 28 ms | 28 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 5 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap | TIMING/finalize/calculate_statistics/group_calc | 23 ms | 23 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap | TIMING/finalize/heatmap_statistics | 30 ms | 30 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap | TIMING/total | 9.4 s | 9.3 s | -62 ms | -0.7% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/rss_peak | 83.7 MB | 82.9 MB | -752 KB | -0.9% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/format_scan_subs | 1.2 MB | 1.1 MB | -112 KB | -9.1% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/heatmap_counters | 570.3 KB | 572.2 KB | +1.9 KB | 0.3% | REGRESS |
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
| single-day-access-log-heatmap | MEMORY/unattributed | 55.0 MB | 54.3 MB | -641.6 KB | -1.1% | IMPROVE |
| single-day-access-log-heatmap | MEMORY_FINAL/log_messages | 28180482 | 28180482 | 0 | 0.0% |  |
| single-day-access-log-heatmap | MEMORY_FINAL/log_analysis | 6678 | 6678 | 0 | 0.0% |  |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| single-day-access-log-histogram | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/parse/read_files | 10.5 s | 10.5 s | -18 ms | -0.2% | IMPROVE |
| single-day-access-log-histogram | TIMING/finalize/calculate_statistics | 97 ms | 97 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/finalize/calculate_statistics/bucket_stats | 69 ms | 69 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 5 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/finalize/calculate_statistics/group_calc | 23 ms | 23 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/finalize/histogram_statistics | 11 ms | 11 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/total | 10.6 s | 10.6 s | -18 ms | -0.2% | IMPROVE |
| single-day-access-log-histogram | MEMORY/rss_peak | 97.5 MB | 99.4 MB | +1.9 MB | 1.9% | REGRESS |
| single-day-access-log-histogram | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | -64 KB | -5.5% | IMPROVE |
| single-day-access-log-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/histogram_counters | 106 KB | 105.8 KB | -256 B | -0.2% | IMPROVE |
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
| single-day-access-log-histogram | MEMORY/unattributed | 45.7 MB | 47.7 MB | +2.0 MB | 4.3% | REGRESS |
| single-day-access-log-histogram | MEMORY_FINAL/log_messages | 28180482 | 28180482 | 0 | 0.0% |  |
| single-day-access-log-histogram | MEMORY_FINAL/log_analysis | 6678 | 6678 | 0 | 0.0% |  |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| single-day-access-log-heatmap-histogram | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/parse/read_files | 11 s | 11 s | +3 ms | 0.0% | REGRESS |
| single-day-access-log-heatmap-histogram | TIMING/finalize/calculate_statistics | 28 ms | 28 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 5 ms | 5 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/finalize/calculate_statistics/group_calc | 23 ms | 23 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/finalize/heatmap_statistics | 30 ms | 30 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/finalize/histogram_statistics | 11 ms | 11 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/total | 11.1 s | 11.1 s | +3 ms | 0.0% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/rss_peak | 83.6 MB | 83.9 MB | +304 KB | 0.4% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/format_scan_subs | 1.2 MB | 1.1 MB | -112 KB | -9.0% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_counters | 571.2 KB | 571.2 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_data | 34 KB | 34 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_counters | 105.9 KB | 105.9 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_analysis | 8.1 KB | 8.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_messages | 26.7 MB | 26.9 MB | +191.5 KB | 0.7% | REGRESS |
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
| single-day-access-log-heatmap-histogram | MEMORY/unattributed | 55.0 MB | 55.2 MB | +224.7 KB | 0.4% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/log_messages | 27977346 | 28173442 | 196096 | 0.7% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/log_analysis | 6678 | 6678 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| single-day-access-log-heatmap-histogram-export | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | TIMING/parse/read_files | 9.5 s | 9.5 s | -40 ms | -0.4% | IMPROVE |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/calculate_statistics | 183 ms | 182 ms | -1 ms | -0.5% | IMPROVE |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/calculate_statistics/bucket_stats | 183 ms | 182 ms | -1 ms | -0.5% | IMPROVE |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/heatmap_statistics | 97 ms | 97 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | TIMING/finalize/histogram_statistics | 11 ms | 11 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | TIMING/total | 9.8 s | 9.8 s | -41 ms | -0.4% | IMPROVE |
| single-day-access-log-heatmap-histogram-export | MEMORY/rss_peak | 68.4 MB | 68 MB | -416 KB | -0.6% | IMPROVE |
| single-day-access-log-heatmap-histogram-export | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/format_scan_subs | 1.2 MB | 1.1 MB | -112 KB | -9.1% | IMPROVE |
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
| single-day-access-log-heatmap-histogram-export | MEMORY/log_stats | 41.3 KB | 41.3 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY/unattributed | 42.8 MB | 42.5 MB | -304 KB | -0.7% | IMPROVE |
| single-day-access-log-heatmap-histogram-export | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY_FINAL/log_analysis | 12095 | 12095 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| single-day-access-log-heatmap-histogram-consolidate | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/parse/read_files | 12.4 s | 12.0 s | -389 ms | -3.1% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 1.8 s | 1.7 s | -150 ms | -8.2% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 74 ms | 74 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | 73 ms | 72 ms | -1 ms | -1.4% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/heatmap_statistics | 30 ms | 30 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/finalize/histogram_statistics | 11 ms | 11 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/total | 14.3 s | 13.8 s | -540 ms | -3.8% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 112.9 MB | 113.3 MB | +352 KB | 0.3% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 22.2 MB | 22 MB | -148.9 KB | -0.7% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 888 KB | 888 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 4.1 MB | 4.1 MB | +5 KB | 0.1% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 4.8 MB | N/A | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 118.1 KB | 119.4 KB | +1.3 KB | 1.1% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 352.5 KB | N/A | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 565.2 KB | 565.2 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | +16 KB | 1.4% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 572.2 KB | 572.2 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_data | 34 KB | 34 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_counters | 106 KB | 106 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_analysis | 8.1 KB | 8.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_messages | 26.9 MB | 26.9 MB | +6.9 KB | 0.0% | REGRESS |
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
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/unattributed | 51.2 MB | 48.4 MB | -2.8 MB | -5.5% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 25702907 | 25740914 | 38007 | 0.1% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 6678 | 6678 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 23239886 | 23087425 | -152461 | -0.7% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 119803 | 122293 | 2490 | 2.1% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 304 | 304 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 16440 | 16440 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 615 | 656 | 41 | 6.7% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_analysis_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_messages_population | 615 | 656 | 41 | 6.7% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 1 | 1 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/parse/read_files | 8.8 s | 8.5 s | -236 ms | -2.7% | IMPROVE |
| single-day-access-log-sort-p99 | TIMING/finalize/calculate_statistics | 129 ms | 129 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/finalize/calculate_statistics/bucket_stats | 68 ms | 68 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | 59 ms | 59 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-p99 | TIMING/total | 8.9 s | 8.7 s | -236 ms | -2.7% | IMPROVE |
| single-day-access-log-sort-p99 | MEMORY/rss_peak | 97.0 MB | 98.9 MB | +1.9 MB | 2.0% | REGRESS |
| single-day-access-log-sort-p99 | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY/format_scan_subs | 1.2 MB | 1.1 MB | -80 KB | -6.6% | IMPROVE |
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
| single-day-access-log-sort-p99 | MEMORY/unattributed | 45.2 MB | 47.2 MB | +2 MB | 4.4% | REGRESS |
| single-day-access-log-sort-p99 | MEMORY_FINAL/log_messages | 28180482 | 28180482 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY_FINAL/log_analysis | 6678 | 6678 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| single-day-access-log-sort-skewness | TIMING/detect/scan_sub_compile | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-skewness | TIMING/parse/read_files | 8.7 s | 8.5 s | -163 ms | -1.9% | IMPROVE |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics | 254 ms | 250 ms | -4 ms | -1.6% | IMPROVE |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics/bucket_stats | 69 ms | 68 ms | -1 ms | -1.4% | IMPROVE |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | 180 ms | 178 ms | -2 ms | -1.1% | IMPROVE |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-skewness | TIMING/finalize/calculate_statistics/group_calc | 4 ms | 4 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-skewness | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-sort-skewness | TIMING/total | 9.0 s | 8.8 s | -167 ms | -1.9% | IMPROVE |
| single-day-access-log-sort-skewness | MEMORY/rss_peak | 102.4 MB | 103.9 MB | +1.5 MB | 1.5% | REGRESS |
| single-day-access-log-sort-skewness | MEMORY/bucket_outcomes | 3.8 KB | 3.8 KB | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY/format_scan_subs | 1.1 MB | 1.1 MB | -48 KB | -4.2% | IMPROVE |
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
| single-day-access-log-sort-skewness | MEMORY/unattributed | 50.7 MB | 52.3 MB | +1.5 MB | 3.0% | REGRESS |
| single-day-access-log-sort-skewness | MEMORY_FINAL/log_messages | 28182055 | 28182055 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY_FINAL/log_analysis | 6678 | 6678 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| month-single-server-access-logs-standard | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/detect/scan_sub_compile | 13 ms | 13 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/parse/read_files | 1.6 min | 1.6 min | -457 ms | -0.5% | IMPROVE |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics | 4.1 s | 4.2 s | +123 ms | 3.0% | REGRESS |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics/bucket_stats | 2.2 s | 2.2 s | +4 ms | 0.2% | REGRESS |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics/sort_selection | 1.5 s | 1.6 s | +120 ms | 8.1% | REGRESS |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics/group_calc | 324 ms | 324 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/finalize/calculate_statistics/untimed | 63 ms | 61 ms | -2 ms | -3.2% | IMPROVE |
| month-single-server-access-logs-standard | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/total | 1.7 min | 1.6 min | -334 ms | -0.3% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/rss_peak | 2 GB | 2 GB | -688 KB | -0.0% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/format_scan_subs | 1.9 MB | 1.8 MB | -64 KB | -3.3% | IMPROVE |
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
| month-single-server-access-logs-standard | MEMORY/log_messages | 1.5 GB | 1.5 GB | +1.8 MB | 0.1% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_occurrences | 36.8 KB | 36.8 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_sessions | 2.2 MB | 2.2 MB | -128 B | -0.0% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/unattributed | 314.7 MB | 312.3 MB | -2.4 MB | -0.8% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY_FINAL/log_messages | 1565922867 | 1567835635 | 1912768 | 0.1% | REGRESS |
| month-single-server-access-logs-standard | MEMORY_FINAL/log_analysis | 13018 | 13018 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| month-single-server-access-logs-no-messages | TIMING/parse/read_files | 1.2 min | 1.2 min | -1 s | -1.5% | IMPROVE |
| month-single-server-access-logs-no-messages | TIMING/finalize/calculate_statistics | 1.6 s | 1.5 s | -15 ms | -1.0% | IMPROVE |
| month-single-server-access-logs-no-messages | TIMING/finalize/calculate_statistics/bucket_stats | 1.6 s | 1.5 s | -15 ms | -1.0% | IMPROVE |
| month-single-server-access-logs-no-messages | TIMING/finalize/calculate_statistics/untimed | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-no-messages | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-no-messages | TIMING/total | 1.2 min | 1.2 min | -1.1 s | -1.5% | IMPROVE |
| month-single-server-access-logs-no-messages | MEMORY/rss_peak | 371.9 MB | 370.2 MB | -1.7 MB | -0.4% | IMPROVE |
| month-single-server-access-logs-no-messages | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/format_scan_subs | 2.0 MB | 2.0 MB | +16 KB | 0.8% | REGRESS |
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
| month-single-server-access-logs-no-messages | MEMORY/log_occurrences | 36.8 KB | 36.6 KB | -192 B | -0.5% | IMPROVE |
| month-single-server-access-logs-no-messages | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY/unattributed | 126.1 MB | 124.4 MB | -1.7 MB | -1.3% | IMPROVE |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/log_analysis | 13018 | 13018 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| month-single-server-access-logs-top25 | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/detect/scan_sub_compile | 13 ms | 13 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/parse/read_files | 1.6 min | 1.6 min | -334 ms | -0.4% | IMPROVE |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics | 4.3 s | 4.3 s | -4 ms | -0.1% | IMPROVE |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics/bucket_stats | 2.2 s | 2.2 s | -25 ms | -1.1% | IMPROVE |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics/sort_selection | 1.5 s | 1.6 s | +27 ms | 1.8% | REGRESS |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics/group_calc | 478 ms | 476 ms | -2 ms | -0.4% | IMPROVE |
| month-single-server-access-logs-top25 | TIMING/finalize/calculate_statistics/untimed | 65 ms | 61 ms | -4 ms | -6.2% | IMPROVE |
| month-single-server-access-logs-top25 | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/total | 1.7 min | 1.7 min | -337 ms | -0.3% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY/rss_peak | 2 GB | 2 GB | -576 KB | -0.0% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/format_scan_subs | 1.9 MB | 1.9 MB | -32 KB | -1.6% | IMPROVE |
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
| month-single-server-access-logs-top25 | MEMORY/log_messages | 1.5 GB | 1.5 GB | +1.8 MB | 0.1% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_occurrences | 36.6 KB | 36.8 KB | +192 B | 0.5% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/message_key_order | 4.7 KB | 4.7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/unattributed | 314.6 MB | 312.2 MB | -2.4 MB | -0.7% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY_FINAL/log_messages | 1565933395 | 1567846163 | 1912768 | 0.1% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY_FINAL/log_analysis | 13018 | 13018 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| month-single-server-access-logs-top25-consolidate | lines_read | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | lines_excluded | 0 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | lines_included | 7,749,159 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/detect/registry_build | 12 ms | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/detect/scan_sub_compile | 13 ms | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/parse/read_files | 2.1 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/accumulate/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/group_similar | 55.2 s | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics | 4.9 s | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | 2.7 s | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/population_walk | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 3 ms | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | 2.2 s | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/threadpool_stats | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/untimed | 3 ms | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/heatmap_statistics | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/histogram_statistics | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/render/normalize_data | 3 ms | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/total | 3.1 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | 919.3 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/bucket_outcomes | 7 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_clusters | 215.3 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_message | 2.5 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 36.7 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 29.4 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_ngram_index | 36.0 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_patterns | 283.2 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_posting_size | 973.6 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | 1.6 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/format_scan_subs | 1.8 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_counters | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_counters | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_values | 576 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_analysis | 242.9 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_messages | 242.2 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_messages_counters | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_occurrences | 36.6 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_sessions | 2.2 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_stats | 54.2 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_threadpools | 240 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_users | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/message_key_order | 4.2 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/threadpool_activity | 778 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/udm_distinct | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/unattributed | 107.4 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/log_messages | 253998411 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 13018 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 225755145 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 248613 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 432 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 65592 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_messages_entries | 1313 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_occurrences_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_stats_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_analysis_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_messages_population | 1313 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/threadpool_entries | 0 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/format_scan_subs_compiled | 2 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/format_scan_sub_cache_hits | 27 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/terminal_height | 24 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/time_bucket_size | 1440 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/bucket_size_seconds | 86400.00 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/detect/scan_sub_compile | 13 ms | 13 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/parse/read_files | 1.8 min | 1.7 min | -1.3 s | -1.2% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/finalize/calculate_statistics | 1.9 s | 1.8 s | -136 ms | -7.2% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 1.5 s | 1.4 s | -136 ms | -8.8% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/finalize/calculate_statistics/group_calc | 285 ms | 283 ms | -2 ms | -0.7% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/finalize/calculate_statistics/untimed | 72 ms | 73 ms | +1 ms | 1.4% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/finalize/heatmap_statistics | 107 ms | 107 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/total | 1.8 min | 1.8 min | -1.4 s | -1.3% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/rss_peak | 1.8 GB | 1.8 GB | -2.8 MB | -0.2% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/format_scan_subs | 1.9 MB | 2.0 MB | +80 KB | 4.1% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_counters | 2.4 MB | 2.4 MB | -1.8 KB | -0.1% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_data | 75.4 KB | 77.4 KB | +2 KB | 2.7% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_analysis | 15.3 KB | 15.3 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_messages | 1.5 GB | 1.5 GB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_occurrences | 36.8 KB | 36.8 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_stats | 35.0 KB | 35.0 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/unattributed | 320.6 MB | 317.7 MB | -2.9 MB | -0.9% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/log_messages | 1567835155 | 1567835155 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/log_analysis | 12602 | 12602 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| month-single-server-access-logs-histogram | TIMING/detect/scan_sub_compile | 13 ms | 13 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/parse/read_files | 2.0 min | 2.0 min | -177 ms | -0.2% | IMPROVE |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics | 4.1 s | 4.2 s | +101 ms | 2.5% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics/bucket_stats | 2.2 s | 2.2 s | +47 ms | 2.1% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics/sort_selection | 1.5 s | 1.5 s | +50 ms | 3.3% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics/group_calc | 325 ms | 328 ms | +3 ms | 0.9% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/finalize/calculate_statistics/untimed | 64 ms | 65 ms | +1 ms | 1.6% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/finalize/histogram_statistics | 19 ms | 19 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/total | 2 min | 2 min | -75 ms | -0.1% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/rss_peak | 2 GB | 1.9 GB | -81.8 MB | -4.0% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/format_scan_subs | 1.9 MB | 1.9 MB | +32 KB | 1.7% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/histogram_counters | 296 KB | 295.9 KB | -128 B | -0.0% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_analysis | 244 MB | 244 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_messages | 1.5 GB | 1.4 GB | -74.0 MB | -4.9% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_occurrences | 36.6 KB | 36.8 KB | +192 B | 0.5% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/log_sessions | 2.2 MB | 2.2 MB | -128 B | -0.0% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/unattributed | 317.6 MB | 309.7 MB | -7.9 MB | -2.5% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY_FINAL/log_messages | 1567835635 | 1490250931 | -77584704 | -4.9% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY_FINAL/log_analysis | 13018 | 13018 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| month-single-server-access-logs-heatmap-histogram | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/detect/scan_sub_compile | 13 ms | 13 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/parse/read_files | 2.1 min | 2.1 min | +231 ms | 0.2% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics | 1.8 s | 1.9 s | +160 ms | 8.9% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 1.4 s | 1.6 s | +160 ms | 11.2% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/group_calc | 283 ms | 281 ms | -2 ms | -0.7% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | 72 ms | 74 ms | +2 ms | 2.8% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/heatmap_statistics | 103 ms | 108 ms | +5 ms | 4.9% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/finalize/histogram_statistics | 19 ms | 19 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/total | 2.1 min | 2.1 min | +396 ms | 0.3% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/rss_peak | 1.8 GB | 1.8 GB | +1.1 MB | 0.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/format_scan_subs | 1.9 MB | 1.9 MB | +80 KB | 4.2% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_counters | 2.4 MB | 2.4 MB | -1.8 KB | -0.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_data | 77.9 KB | 75.9 KB | -2 KB | -2.6% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_counters | 296 KB | 295.9 KB | -128 B | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_analysis | 15.3 KB | 15.3 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_messages | 1.5 GB | 1.5 GB | +128 B | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_occurrences | 36.8 KB | 36.6 KB | -192 B | -0.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_sessions | 2.2 MB | 2.2 MB | -128 B | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_stats | 35.0 KB | 35.0 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/unattributed | 318.7 MB | 319.8 MB | +1 MB | 0.3% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 1567835027 | 1567835155 | 128 | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 12602 | 12602 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| month-single-server-access-logs-heatmap-histogram-export | TIMING/detect/scan_sub_compile | 13 ms | 13 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/parse/read_files | 1.8 min | 1.8 min | +111 ms | 0.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics | 2.7 s | 2.7 s | -26 ms | -1.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/bucket_stats | 2.7 s | 2.7 s | -26 ms | -1.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/untimed | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/heatmap_statistics | 222 ms | 223 ms | +1 ms | 0.5% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/finalize/histogram_statistics | 18 ms | 18 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/render/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | TIMING/total | 1.8 min | 1.8 min | +85 ms | 0.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/rss_peak | 372.8 MB | 371.5 MB | -1.3 MB | -0.3% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/format_scan_subs | 2 MB | 2.0 MB | -64 KB | -3.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_counters | 2.4 MB | 2.4 MB | -1.8 KB | -0.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_data | 77.4 KB | 78.4 KB | +1 KB | 1.3% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/histogram_counters | 296 KB | 295.9 KB | -128 B | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_analysis | 241.6 MB | 241.6 MB | -1.8 KB | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_messages | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_occurrences | 36.6 KB | 36.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_stats | 82.5 KB | 82.5 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/unattributed | 124.1 MB | 122.9 MB | -1.2 MB | -1.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY_FINAL/log_analysis | 23011 | 21219 | -1792 | -7.8% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_read | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_excluded | 0 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_included | 7,749,159 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/detect/registry_build | 12 ms | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 13 ms | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/parse/read_files | 2.6 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/accumulate/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 38 s | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 2.0 s | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/population_walk | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 3 ms | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | 2.0 s | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/threadpool_stats | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/untimed | 3 ms | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/heatmap_statistics | 99 ms | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/histogram_statistics | 22 ms | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/render/normalize_data | 3 ms | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | 3.3 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 720 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 7 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 215.3 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 2.5 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 36.7 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 29.4 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 36.0 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 283.2 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 973.6 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 1.6 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 1.8 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 2.4 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 240 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 76.4 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | 296 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 240 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 15.3 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 242.2 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 36.6 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 2.2 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 35.0 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 240 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_users | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | 1.9 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 778 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/unattributed | 148.3 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 253987723 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 12602 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 225754889 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 248613 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 432 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 65592 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 1313 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_analysis_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_population | 1313 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/threadpool_entries | 0 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 2 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/format_scan_sub_cache_hits | 27 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 1440 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 86400.00 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | lines_included | 7,749,159 | 7,749,159 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-sort-p99 | TIMING/detect/scan_sub_compile | 13 ms | 13 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-sort-p99 | TIMING/parse/read_files | 1.6 min | 1.6 min | -590 ms | -0.6% | IMPROVE |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics | 10 s | 10.1 s | +43 ms | 0.4% | REGRESS |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/bucket_stats | 2.2 s | 2.3 s | +22 ms | 1.0% | REGRESS |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | 4.7 s | 4.7 s | -12 ms | -0.3% | IMPROVE |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 3 s | 3 s | +35 ms | 1.2% | REGRESS |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/group_calc | 10 ms | 9 ms | -1 ms | -10.0% | IMPROVE |
| month-single-server-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/untimed | 119 ms | 116 ms | -3 ms | -2.5% | IMPROVE |
| month-single-server-access-logs-sort-p99 | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-sort-p99 | TIMING/total | 1.8 min | 1.7 min | -547 ms | -0.5% | IMPROVE |
| month-single-server-access-logs-sort-p99 | MEMORY/rss_peak | 2.2 GB | 2.2 GB | -8.2 MB | -0.4% | IMPROVE |
| month-single-server-access-logs-sort-p99 | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/format_scan_subs | 1.9 MB | 1.9 MB | -32 KB | -1.6% | IMPROVE |
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
| month-single-server-access-logs-sort-p99 | MEMORY/log_occurrences | 36.6 KB | 36.8 KB | +192 B | 0.5% | REGRESS |
| month-single-server-access-logs-sort-p99 | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY/unattributed | 388.1 MB | 380.0 MB | -8.1 MB | -2.1% | IMPROVE |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/log_messages | 1672623763 | 1672623763 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/log_analysis | 13018 | 13018 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| month-single-server-access-logs-sort-skewness | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-sort-skewness | TIMING/detect/scan_sub_compile | 13 ms | 13 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-sort-skewness | TIMING/parse/read_files | 1.6 min | 1.6 min | -1.1 s | -1.2% | IMPROVE |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics | 5.9 s | 5.9 s | -36 ms | -0.6% | IMPROVE |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/bucket_stats | 2.2 s | 2.2 s | -29 ms | -1.3% | IMPROVE |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | 3.4 s | 3.4 s | -3 ms | -0.1% | IMPROVE |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 13 ms | 13 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/group_calc | 212 ms | 212 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/untimed | 69 ms | 65 ms | -4 ms | -5.8% | IMPROVE |
| month-single-server-access-logs-sort-skewness | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-sort-skewness | TIMING/total | 1.7 min | 1.7 min | -1.1 s | -1.1% | IMPROVE |
| month-single-server-access-logs-sort-skewness | MEMORY/rss_peak | 2.1 GB | 2.1 GB | +1.1 MB | 0.1% | REGRESS |
| month-single-server-access-logs-sort-skewness | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/format_scan_subs | 1.9 MB | 2.0 MB | +32 KB | 1.6% | REGRESS |
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
| month-single-server-access-logs-sort-skewness | MEMORY/log_occurrences | 36.6 KB | 36.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY/unattributed | 287.8 MB | 288.8 MB | +1.1 MB | 0.4% | REGRESS |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/log_messages | 1670604024 | 1670604024 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/log_analysis | 13018 | 13018 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| month-many-servers-access-logs-standard | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-standard | TIMING/detect/scan_sub_compile | 20 ms | 20 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-standard | TIMING/parse/read_files | 7.9 min | 7.9 min | -2.2 s | -0.5% | IMPROVE |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics | 24.2 s | 24.5 s | +291 ms | 1.2% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics/bucket_stats | 13.1 s | 13.1 s | +41 ms | 0.3% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics/sort_selection | 8.7 s | 8.9 s | +258 ms | 3.0% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics/group_calc | 2.1 s | 2.1 s | -5 ms | -0.2% | IMPROVE |
| month-many-servers-access-logs-standard | TIMING/finalize/calculate_statistics/untimed | 396 ms | 392 ms | -4 ms | -1.0% | IMPROVE |
| month-many-servers-access-logs-standard | TIMING/render/normalize_data | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-standard | TIMING/total | 8.3 min | 8.3 min | -1.9 s | -0.4% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/rss_peak | 10.1 GB | 10.1 GB | -5.6 MB | -0.1% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/format_scan_subs | 2.4 MB | 2.8 MB | +416 KB | 17.2% | REGRESS |
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
| month-many-servers-access-logs-standard | MEMORY/log_occurrences | 42.1 KB | 43.8 KB | +1.8 KB | 4.2% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -128 B | -0.0% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/unattributed | 1.4 GB | 1.4 GB | -6.0 MB | -0.4% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY_FINAL/log_messages | 8019141603 | 8019141603 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY_FINAL/log_analysis | 13018 | 13018 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| month-many-servers-access-logs-no-messages | TIMING/detect/scan_sub_compile | 20 ms | 20 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-no-messages | TIMING/parse/read_files | 5.9 min | 6.0 min | +3.7 s | 1.0% | REGRESS |
| month-many-servers-access-logs-no-messages | TIMING/finalize/calculate_statistics | 9.6 s | 9.7 s | +28 ms | 0.3% | REGRESS |
| month-many-servers-access-logs-no-messages | TIMING/finalize/calculate_statistics/bucket_stats | 9.6 s | 9.6 s | +28 ms | 0.3% | REGRESS |
| month-many-servers-access-logs-no-messages | TIMING/finalize/calculate_statistics/untimed | 12 ms | 12 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-no-messages | TIMING/render/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-no-messages | TIMING/total | 6.1 min | 6.1 min | +3.7 s | 1.0% | REGRESS |
| month-many-servers-access-logs-no-messages | MEMORY/rss_peak | 1.6 GB | 1.6 GB | -27.0 MB | -1.6% | IMPROVE |
| month-many-servers-access-logs-no-messages | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/format_scan_subs | 2.9 MB | 2.8 MB | -96 KB | -3.3% | IMPROVE |
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
| month-many-servers-access-logs-no-messages | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/message_key_order | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY/unattributed | 443.4 MB | 416.5 MB | -26.9 MB | -6.1% | IMPROVE |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/log_analysis | 13018 | 13018 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| month-many-servers-access-logs-top25 | TIMING/detect/scan_sub_compile | 20 ms | 20 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-top25 | TIMING/parse/read_files | 8.0 min | 7.9 min | -5.8 s | -1.2% | IMPROVE |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics | 25.8 s | 25.2 s | -542 ms | -2.1% | IMPROVE |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics/bucket_stats | 12.8 s | 13.1 s | +307 ms | 2.4% | REGRESS |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics/sort_selection | 9.5 s | 8.6 s | -962 ms | -10.1% | IMPROVE |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics/group_calc | 3.1 s | 3.1 s | +63 ms | 2.1% | REGRESS |
| month-many-servers-access-logs-top25 | TIMING/finalize/calculate_statistics/untimed | 346 ms | 394 ms | +48 ms | 13.9% | REGRESS |
| month-many-servers-access-logs-top25 | TIMING/render/normalize_data | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-top25 | TIMING/total | 8.4 min | 8.3 min | -6.3 s | -1.3% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY/rss_peak | 10.1 GB | 10.1 GB | -3 MB | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/format_scan_subs | 2.3 MB | 2.7 MB | +464 KB | 19.9% | REGRESS |
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
| month-many-servers-access-logs-top25 | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/message_key_order | 4.7 KB | 4.7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/unattributed | 1.4 GB | 1.4 GB | -3.5 MB | -0.2% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/log_messages | 8019152067 | 8019152067 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/log_analysis | 13018 | 13018 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| month-many-servers-access-logs-top25-consolidate | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | lines_excluded | 0 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | lines_included | 38,672,411 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/detect/registry_build | 12 ms | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/detect/scan_sub_compile | 20 ms | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/parse/read_files | 9.8 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/accumulate/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/group_similar | 8.5 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics | 26.6 s | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | 14.7 s | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/population_walk | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | 11.9 s | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/threadpool_stats | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/untimed | 18 ms | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/heatmap_statistics | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/histogram_statistics | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/render/normalize_data | 6 ms | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | 18.7 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | 3.6 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/bucket_outcomes | 7 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_clusters | 1.1 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_message | 2.5 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 36.9 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 29.2 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_ngram_index | 36.2 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_patterns | 523.2 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_posting_size | 1.2 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | 1.7 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/format_scan_subs | 1.9 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_counters | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_counters | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_values | 576 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_analysis | 1.2 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_messages | 1.2 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_messages_counters | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_occurrences | 43.8 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_sessions | 14.9 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_stats | 54.2 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_threadpools | 240 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_users | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/message_key_order | 4.2 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/threadpool_activity | 778 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/udm_distinct | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/unattributed | 0 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/log_messages | 1276491163 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 13018 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 1169250064 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 535708 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 432 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 65592 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_messages_entries | 2537 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_occurrences_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_stats_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_analysis_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_messages_population | 2537 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/threadpool_entries | 0 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/format_scan_subs_compiled | 3 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/format_scan_sub_cache_hits | 142 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/terminal_height | 24 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/time_bucket_size | 1440 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/bucket_size_seconds | 86400.00 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/detect/scan_sub_compile | 20 ms | 20 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/parse/read_files | 8.8 min | 8.7 min | -4.0 s | -0.8% | IMPROVE |
| month-many-servers-access-logs-heatmap | TIMING/finalize/calculate_statistics | 10.4 s | 11.3 s | +926 ms | 8.9% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/finalize/calculate_statistics/sort_selection | 8.3 s | 9.3 s | +935 ms | 11.2% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/finalize/calculate_statistics/group_calc | 1.6 s | 1.6 s | -25 ms | -1.5% | IMPROVE |
| month-many-servers-access-logs-heatmap | TIMING/finalize/calculate_statistics/untimed | 408 ms | 424 ms | +16 ms | 3.9% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/finalize/heatmap_statistics | 115 ms | 120 ms | +5 ms | 4.3% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/total | 8.9 min | 8.9 min | -3.1 s | -0.6% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/rss_peak | 8.5 GB | 8.9 GB | +395.0 MB | 4.6% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/format_scan_subs | 2.2 MB | 2.8 MB | +608 KB | 27.3% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_counters | 2.7 MB | 2.7 MB | +1.8 KB | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_data | 76.8 KB | 76.3 KB | -512 B | -0.7% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_analysis | 15.3 KB | 15.3 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_messages | 7.1 GB | 7.5 GB | +377.6 MB | 5.2% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_occurrences | 43.8 KB | 43.8 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -32 KB | -0.2% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/log_stats | 35.0 KB | 35.0 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/unattributed | 1.4 GB | 1.4 GB | +16.8 MB | 1.2% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/log_messages | 7618099027 | 8014081747 | 395982720 | 5.2% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/log_analysis | 12602 | 12602 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| month-many-servers-access-logs-histogram | TIMING/parse/read_files | 9.8 min | 9.7 min | -3.9 s | -0.7% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics | 24.1 s | 24.1 s | -54 ms | -0.2% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics/bucket_stats | 13.1 s | 12.6 s | -444 ms | -3.4% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics/sort_selection | 8.6 s | 9.1 s | +467 ms | 5.4% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics/group_calc | 2.1 s | 2 s | -38 ms | -1.8% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/finalize/calculate_statistics/untimed | 393 ms | 354 ms | -39 ms | -9.9% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/finalize/histogram_statistics | 20 ms | 20 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/render/normalize_data | 4 ms | 2 ms | -2 ms | -50.0% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/total | 10.2 min | 10.1 min | -3.9 s | -0.6% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/rss_peak | 10.1 GB | 10.1 GB | +14.4 MB | 0.1% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/format_scan_subs | 2.3 MB | 2.7 MB | +432 KB | 18.5% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/histogram_counters | 307.7 KB | 307.8 KB | +128 B | 0.0% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_analysis | 1.2 GB | 1.2 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_messages | 7.5 GB | 7.5 GB | +9.4 MB | 0.1% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_occurrences | 43.8 KB | 42.1 KB | -1.8 KB | -4.0% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -31.9 KB | -0.2% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/unattributed | 1.4 GB | 1.4 GB | +4.6 MB | 0.3% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/log_messages | 8009293859 | 8019141603 | 9847744 | 0.1% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/log_analysis | 13018 | 13018 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| month-many-servers-access-logs-heatmap-histogram | TIMING/parse/read_files | 10.3 min | 10.4 min | +3.6 s | 0.6% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics | 10.4 s | 11.2 s | +830 ms | 8.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/sort_selection | 8.3 s | 9.1 s | +821 ms | 9.9% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/group_calc | 1.6 s | 1.6 s | -32 ms | -1.9% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/calculate_statistics/untimed | 407 ms | 447 ms | +40 ms | 9.8% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/heatmap_statistics | 120 ms | 118 ms | -2 ms | -1.7% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/finalize/histogram_statistics | 20 ms | 20 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/render/normalize_data | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/total | 10.5 min | 10.6 min | +4.4 s | 0.7% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/rss_peak | 8.8 GB | 8.8 GB | +8.1 MB | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/format_scan_subs | 2.2 MB | 2.6 MB | +464 KB | 20.7% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_counters | 2.7 MB | 2.7 MB | -1.8 KB | -0.1% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_data | 76.8 KB | 74.8 KB | -2 KB | -2.6% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_counters | 307.8 KB | 307.7 KB | -128 B | -0.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_analysis | 15.3 KB | 15.3 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_messages | 7.5 GB | 7.5 GB | +9.4 MB | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_occurrences | 43.8 KB | 42.1 KB | -1.8 KB | -4.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -32 KB | -0.2% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_stats | 35.0 KB | 35.0 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/message_key_order | 2.2 KB | 2.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/unattributed | 1.4 GB | 1.4 GB | -1.7 MB | -0.1% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 8004234003 | 8014081747 | 9847744 | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 12602 | 12602 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/detect/scan_sub_compile | 19 ms | 20 ms | +1 ms | 5.3% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/parse/read_files | 8.8 min | 8.7 min | -6.1 s | -1.2% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics | 15.3 s | 15.2 s | -49 ms | -0.3% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/bucket_stats | 15.3 s | 15.2 s | -49 ms | -0.3% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/calculate_statistics/untimed | 12 ms | 12 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/heatmap_statistics | 235 ms | 235 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/finalize/histogram_statistics | 19 ms | 19 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/render/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | TIMING/total | 9.1 min | 9.0 min | -6.2 s | -1.1% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/rss_peak | 1.7 GB | 1.7 GB | -5.8 MB | -0.3% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/format_scan_subs | 2.9 MB | 2.8 MB | -128 KB | -4.3% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_counters | 2.7 MB | 2.7 MB | -1.8 KB | -0.1% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_counters_hl | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_data | 76.8 KB | 76.8 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/histogram_counters | 307.8 KB | 307.7 KB | -128 B | -0.0% | IMPROVE |
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
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/unattributed | 481.3 MB | 475.6 MB | -5.7 MB | -1.2% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY_FINAL/log_messages | 240 | 240 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY_FINAL/log_analysis | 23011 | 23011 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_excluded | 0 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_included | 38,672,411 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/detect/registry_build | 12 ms | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | 20 ms | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/parse/read_files | 12.1 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/accumulate/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/group_similar | 6.1 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | 10.5 s | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/population_walk | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | 6 ms | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | 10.5 s | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/threadpool_stats | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/untimed | 18 ms | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/heatmap_statistics | 113 ms | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/histogram_statistics | 22 ms | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/render/normalize_data | 4 ms | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | 18.4 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 2.6 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | 7 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 1.1 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 2.5 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 36.9 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 25.4 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 36.2 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 523.2 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 1.2 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 1.7 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/format_scan_subs | 2.0 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 2.7 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 240 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 75.8 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | 307.8 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 240 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 15.3 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 1.2 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 42.1 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 14.9 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 35.0 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 240 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_users | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | 1.9 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 778 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/unattributed | 246.8 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 1276072531 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 12602 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 1168766984 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 535708 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 432 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 65592 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 2537 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_analysis_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_population | 2537 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/threadpool_entries | 0 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | 3 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/format_scan_sub_cache_hits | 142 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 1440 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 86400.00 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | lines_included | 38,672,411 | 38,672,411 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | TIMING/detect/registry_build | 12 ms | 12 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | TIMING/detect/scan_sub_compile | 20 ms | 20 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | TIMING/parse/read_files | 8.0 min | 8.0 min | -44 ms | -0.0% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics | 1.1 min | 1 min | -2.1 s | -3.4% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/bucket_stats | 12.9 s | 12.5 s | -385 ms | -3.0% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/population_walk | 28.8 s | 28.2 s | -612 ms | -2.1% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/sort_selection | 21 s | 19.9 s | -1.1 s | -5.1% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | TIMING/finalize/calculate_statistics/untimed | 791 ms | 708 ms | -83 ms | -10.5% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | TIMING/render/normalize_data | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | TIMING/total | 9 min | 9.0 min | -2.2 s | -0.4% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY/rss_peak | 11.0 GB | 10.9 GB | -2.1 MB | -0.0% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/format_scan_subs | 2.1 MB | 2.7 MB | +608 KB | 28.6% | REGRESS |
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
| month-many-servers-access-logs-sort-p99 | MEMORY/log_messages | 7.9 GB | 7.9 GB | +9.4 MB | 0.1% | REGRESS |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_occurrences | 43.8 KB | 42.1 KB | -1.8 KB | -4.0% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_sessions | 14.9 MB | 14.9 MB | +31.9 KB | 0.2% | REGRESS |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/message_key_order | 2.5 KB | 2.5 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY/unattributed | 1.8 GB | 1.8 GB | -12.1 MB | -0.6% | IMPROVE |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/log_messages | 8518784963 | 8528632963 | 9848000 | 0.1% | REGRESS |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/log_analysis | 13018 | 13018 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| month-many-servers-access-logs-sort-skewness | TIMING/parse/read_files | 7.9 min | 8.0 min | +101 ms | 0.0% | REGRESS |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics | 34.8 s | 34 s | -791 ms | -2.3% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/bucket_stats | 12.9 s | 12.8 s | -73 ms | -0.6% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/population_walk | 20.7 s | 20 s | -668 ms | -3.2% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/sort_selection | 71 ms | 66 ms | -5 ms | -7.0% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/group_calc | 713 ms | 715 ms | +2 ms | 0.3% | REGRESS |
| month-many-servers-access-logs-sort-skewness | TIMING/finalize/calculate_statistics/untimed | 406 ms | 359 ms | -47 ms | -11.6% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | TIMING/render/normalize_data | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | TIMING/total | 8.5 min | 8.5 min | -690 ms | -0.1% | IMPROVE |
| month-many-servers-access-logs-sort-skewness | MEMORY/rss_peak | 10.4 GB | 10.4 GB | +4.1 MB | 0.0% | REGRESS |
| month-many-servers-access-logs-sort-skewness | MEMORY/bucket_outcomes | 7 KB | 7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/format_scan_subs | 2.2 MB | 2.6 MB | +480 KB | 21.7% | REGRESS |
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
| month-many-servers-access-logs-sort-skewness | MEMORY/log_messages | 7.9 GB | 7.9 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_messages_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_sessions | 14.9 MB | 14.9 MB | +32 KB | 0.2% | REGRESS |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_stats | 54.2 KB | 54.2 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_threadpools | 240 B | 240 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_users | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/message_key_order | 2.1 KB | 2.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/threadpool_activity | 778 B | 778 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/udm_distinct | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY/unattributed | 1.2 GB | 1.2 GB | +3.6 MB | 0.3% | REGRESS |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/log_messages | 8528067400 | 8528067400 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/log_analysis | 13018 | 13018 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
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
| humungous-log-uniqueness-standard | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-no-messages | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_id_index | N/A | 5.7 MB | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-export | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_id_index | N/A | 5.7 MB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-no-messages | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_id_index | N/A | 55.7 MB | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_id_index | N/A | 55.7 MB | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-no-messages | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | lines_read | N/A | 930,031 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | lines_included | N/A | 930,028 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/detect/registry_build | N/A | 12 ms | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/detect/scan_sub_compile | N/A | 6 ms | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/parse/read_files | N/A | 29.7 s | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/accumulate/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/group_similar | N/A | 4.2 s | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/calculate_statistics | N/A | 3 ms | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | N/A | 2 ms | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/finalize/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/render/normalize_data | N/A | 3 ms | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | TIMING/total | N/A | 33.9 s | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | N/A | 230.2 MB | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/bucket_outcomes | N/A | 13.3 KB | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_clusters | N/A | 3 MB | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_id_index | N/A | 127.2 MB | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_message | N/A | 3.8 MB | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | N/A | 65.7 MB | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_patterns | N/A | 427.2 KB | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_unmatched | N/A | 2.2 MB | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/format_scan_subs | N/A | 1.1 MB | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/log_analysis | N/A | 240 B | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/log_messages | N/A | 3.4 MB | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/log_occurrences | N/A | 56.6 KB | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/log_sessions | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/log_stats | N/A | 17.1 KB | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/log_threadpools | N/A | 240 B | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/log_users | N/A | 40.5 KB | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/message_key_order | N/A | 5.7 KB | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/threadpool_activity | N/A | 778 B | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/unattributed | N/A | 23.3 MB | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/log_messages | N/A | 659452 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/log_analysis | N/A | 240 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 3182226 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 437484 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 131128 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 240 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 65592 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | COUNTS/log_messages_entries | N/A | 1127 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | COUNTS/log_occurrences_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | COUNTS/log_stats_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | COUNTS/log_messages_population | N/A | 1127 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | COUNTS/format_scan_sub_cache_hits | N/A | 40 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | CONFIG/time_bucket_size | N/A | 480 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | CONFIG/bucket_size_seconds | N/A | 28800.00 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_read | N/A | 930,031 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_excluded | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_included | N/A | 930,028 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/detect/registry_build | N/A | 12 ms | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | N/A | 6 ms | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/parse/read_files | N/A | 29.6 s | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/accumulate/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/group_similar | N/A | 4.2 s | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | N/A | 2 ms | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | N/A | 2 ms | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/untimed | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/finalize/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/render/normalize_data | N/A | 3 ms | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | N/A | 33.8 s | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | N/A | 229.4 MB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | N/A | 13.3 KB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | N/A | 3 MB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_id_index | N/A | 127.2 MB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | N/A | 3.8 MB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | N/A | 65.7 MB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | N/A | 427.2 KB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | N/A | 2.2 MB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/format_scan_subs | N/A | 1.1 MB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | N/A | 240 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_messages | N/A | 3.4 MB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | N/A | 56.7 KB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_stats | N/A | 17.1 KB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | N/A | 240 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_users | N/A | 39.8 KB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | N/A | 2.9 KB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | N/A | 778 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/unattributed | N/A | 22.5 MB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | N/A | 659452 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | N/A | 240 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 3178834 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 437484 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 131128 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 240 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 65592 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | N/A | 1127 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_analysis_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_messages_population | N/A | 1127 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | N/A | 1 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/format_scan_sub_cache_hits | N/A | 40 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | N/A | 480 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | N/A | 28800.00 | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-no-messages | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_id_index | N/A | 122.9 MB | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_id_index | N/A | 122.9 MB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-no-messages | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_id_index | N/A | 8.5 MB | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-export | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_id_index | N/A | 8.5 MB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-no-messages | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | lines_read | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | lines_included | N/A | 7,749,159 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/detect/registry_build | N/A | 13 ms | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/detect/scan_sub_compile | N/A | 14 ms | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/parse/read_files | N/A | 2.0 min | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/accumulate/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/group_similar | N/A | 45.0 s | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics | N/A | 4.6 s | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 2.6 s | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | N/A | 2 ms | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | N/A | 2.0 s | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/untimed | N/A | 2 ms | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/finalize/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/render/normalize_data | N/A | 3 ms | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/total | N/A | 2.8 min | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | N/A | 928.7 MB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/bucket_outcomes | N/A | 7 KB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_clusters | N/A | 211.8 MB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_id_index | N/A | 46.3 MB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_message | N/A | 2.1 MB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | N/A | 23.6 MB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_patterns | N/A | 259 KB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | N/A | 1.4 MB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/format_scan_subs | N/A | 1.8 MB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_analysis | N/A | 242.2 MB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_messages | N/A | 242.2 MB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_occurrences | N/A | 36.8 KB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_sessions | N/A | 2.2 MB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_stats | N/A | 54.2 KB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_threadpools | N/A | 240 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/message_key_order | N/A | 4.2 KB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/threadpool_activity | N/A | 778 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/unattributed | N/A | 154.8 MB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/log_messages | N/A | 253943067 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/log_analysis | N/A | 13018 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 222042053 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 231512 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 131128 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 432 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 65592 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_messages_entries | N/A | 1184 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_analysis_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_messages_population | N/A | 1184 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/format_scan_subs_compiled | N/A | 2 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/format_scan_sub_cache_hits | N/A | 27 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_read | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_included | N/A | 7,749,159 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/detect/registry_build | N/A | 12 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | N/A | 13 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/parse/read_files | N/A | 2.4 min | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/accumulate/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/group_similar | N/A | 31.2 s | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | N/A | 1.9 s | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | N/A | 2 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | N/A | 1.9 s | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/untimed | N/A | 4 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/heatmap_statistics | N/A | 96 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/finalize/histogram_statistics | N/A | 19 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/render/normalize_data | N/A | 2 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | N/A | 2.9 min | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | N/A | 640.1 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | N/A | 7 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | N/A | 211.7 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_id_index | N/A | 49.6 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | N/A | 2.1 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | N/A | 26.3 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | N/A | 259 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | N/A | 1.4 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/format_scan_subs | N/A | 1.8 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | N/A | 2.4 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | N/A | 240 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | N/A | 77.9 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | N/A | 295.9 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | N/A | 240 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | N/A | 15.3 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages | N/A | 242.2 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | N/A | 36.6 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | N/A | 2.2 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_stats | N/A | 35.0 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | N/A | 240 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | N/A | 1.9 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | N/A | 778 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/unattributed | N/A | 99.7 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | N/A | 253921339 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | N/A | 12602 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 222005253 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 231512 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 131128 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 432 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 65592 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | N/A | 1184 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_analysis_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_population | N/A | 1184 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | N/A | 2 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/format_scan_sub_cache_hits | N/A | 27 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-no-messages | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | lines_read | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | lines_included | N/A | 38,672,411 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/detect/registry_build | N/A | 12 ms | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/detect/scan_sub_compile | N/A | 20 ms | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/parse/read_files | N/A | 9.8 min | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/accumulate/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/group_similar | N/A | 6 min | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics | N/A | 26.8 s | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 14.6 s | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/sort_selection | N/A | 5 ms | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/group_calc | N/A | 12.2 s | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/calculate_statistics/untimed | N/A | 15 ms | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/finalize/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/render/normalize_data | N/A | 4 ms | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | N/A | 16.3 min | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | N/A | 3.4 GB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/bucket_outcomes | N/A | 7 KB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_clusters | N/A | 1.1 GB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_id_index | N/A | 50.6 MB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_message | N/A | 2.0 MB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | N/A | 26.7 MB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_patterns | N/A | 482.4 KB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | N/A | 1.3 MB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/format_scan_subs | N/A | 2.5 MB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_analysis | N/A | 1.2 GB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_messages | N/A | 1.2 GB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_occurrences | N/A | 43.8 KB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_sessions | N/A | 14.9 MB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_stats | N/A | 54.2 KB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_threadpools | N/A | 240 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/message_key_order | N/A | 4.2 KB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/threadpool_activity | N/A | 778 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/unattributed | N/A | 0 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/log_messages | N/A | 1274163633 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/log_analysis | N/A | 13018 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 1155256263 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 493990 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 131128 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 432 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 65592 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_messages_entries | N/A | 2443 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_analysis_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_messages_population | N/A | 2443 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/format_scan_subs_compiled | N/A | 3 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/format_scan_sub_cache_hits | N/A | 142 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-export | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_read | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_excluded | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_included | N/A | 38,672,411 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/detect/registry_build | N/A | 12 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/detect/scan_sub_compile | N/A | 20 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/parse/read_files | N/A | 12.2 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/accumulate/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/group_similar | N/A | 4.1 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics | N/A | 10.3 s | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/bucket_stats | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/population_walk | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/sort_selection | N/A | 5 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/group_calc | N/A | 10.3 s | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/threadpool_stats | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/calculate_statistics/untimed | N/A | 15 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/heatmap_statistics | N/A | 108 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/finalize/histogram_statistics | N/A | 20 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/render/normalize_data | N/A | 3 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | N/A | 16.5 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | N/A | 2.5 GB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_outcomes | N/A | 7 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | N/A | 1.1 GB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_id_index | N/A | 47.5 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | N/A | 2.0 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | N/A | 23.6 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | N/A | 482.4 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | N/A | 1.3 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/format_scan_subs | N/A | 2.5 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | N/A | 2.7 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | N/A | 240 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | N/A | 76.8 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | N/A | 307.7 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | N/A | 240 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | N/A | 15.3 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages | N/A | 1.2 GB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | N/A | 43.8 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | N/A | 14.9 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_stats | N/A | 35.0 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | N/A | 240 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_users | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | N/A | 1.9 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | N/A | 778 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/unattributed | N/A | 135.1 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | N/A | 1270323921 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | N/A | 12602 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 1150404175 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 493990 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 131128 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 432 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 65592 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | N/A | 2443 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_analysis_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_population | N/A | 2443 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/threadpool_entries | N/A | 0 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/format_scan_subs_compiled | N/A | 3 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/format_scan_sub_cache_hits | N/A | 142 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_id_index | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_id_index | N/A | 120 | N/A | N/A | ? |

