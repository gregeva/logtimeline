
## Benchmark Comparison

  Baseline:    v0.15.1 (v0.15.1, 35 test cases)
  Current:     v0.16.0 (v0.16.0, 63 test cases)

### Timing Delta

| # | file selection | standard | top25 | top25-cons | heatmap | histogram | hm+hg | hm+hg+cons | sort-p99 | sort-skew |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. | humungous-log-uniqueness | -5.9% | -5.8% | -13.9% | -5.6% | -7.7% | -6.6% | -12.2% | - | - |
| 2. | single-day-application-log | -1.9% | -3.2% | -5.1% | -3.9% | -1.4% | -0.8% | -6.1% | - | - |
| 3. | multi-day-application-logs | -4.6% | -1.9% | -11.4% | -3.3% | -6.2% | -4.5% | -13.4% | - | - |
| 4. | multi-day-custom-logs | -8.1% | -9.5% | -14.3% | -8.0% | -8.7% | -8.5% | -14.1% | - | - |
| 5. | single-day-access-log | +6.1% | +7.4% | -3.8% | +7.0% | +4.0% | +4.9% | -2.6% | - | - |
| 6. | month-single-server-access-logs | - | - | - | - | - | - | - | - | - |
| 7. | month-many-servers-access-logs | - | - | - | - | - | - | - | - | - |

### Memory Delta (RSS Peak)

| # | file selection | standard | top25 | top25-cons | heatmap | histogram | hm+hg | hm+hg+cons | sort-p99 | sort-skew |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. | humungous-log-uniqueness | +0.3% | +1.0% | -0.5% | +0.4% | +0.6% | +0.6% | +0.6% | - | - |
| 2. | single-day-application-log | -0.7% | -0.3% | -0.6% | -0.3% | +0.3% | +0.7% | +1.7% | - | - |
| 3. | multi-day-application-logs | -2.6% | = | -1.6% | -0.6% | -1.5% | -3.2% | -1.4% | - | - |
| 4. | multi-day-custom-logs | -5.7% | -6.5% | -5.3% | -3.3% | -6.4% | +0.8% | -5.1% | - | - |
| 5. | single-day-access-log | -13.2% | -11.5% | -13.2% | -9.2% | -11.7% | -8.9% | -12.4% | - | - |
| 6. | month-single-server-access-logs | - | - | - | - | - | - | - | - | - |
| 7. | month-many-servers-access-logs | - | - | - | - | - | - | - | - | - |

### Summary

| test_name | metric | baseline | current | delta | change% | result |
| --- | --- | --- | --- | --- | --- | --- |
| humungous-log-uniqueness-standard | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/total | 2.9 s | 2.7 s | -170 ms | -5.9% | IMPROVE |
| humungous-log-uniqueness-standard | MEMORY/rss_peak | 204.7 MB | 205.3 MB | +576 KB | 0.3% | REGRESS |
| humungous-log-uniqueness-top25 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/total | 2.9 s | 2.7 s | -166 ms | -5.8% | IMPROVE |
| humungous-log-uniqueness-top25 | MEMORY/rss_peak | 203.5 MB | 205.6 MB | +2.1 MB | 1.0% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/total | 12.0 s | 10.3 s | -1.7 s | -13.9% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/rss_peak | 250.3 MB | 249 MB | -1.3 MB | -0.5% | IMPROVE |
| humungous-log-uniqueness-heatmap | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/total | 2.9 s | 2.7 s | -161 ms | -5.6% | IMPROVE |
| humungous-log-uniqueness-heatmap | MEMORY/rss_peak | 204.1 MB | 205 MB | +912 KB | 0.4% | REGRESS |
| humungous-log-uniqueness-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/total | 2.9 s | 2.7 s | -223 ms | -7.7% | IMPROVE |
| humungous-log-uniqueness-histogram | MEMORY/rss_peak | 204 MB | 205.2 MB | +1.2 MB | 0.6% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/total | 2.8 s | 2.7 s | -187 ms | -6.6% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/rss_peak | 204.3 MB | 205.7 MB | +1.3 MB | 0.6% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/total | 11.6 s | 10.2 s | -1.4 s | -12.2% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/rss_peak | 248.1 MB | 249.7 MB | +1.6 MB | 0.6% | REGRESS |
| single-day-application-log-standard | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | TIMING/total | 3.9 s | 3.8 s | -74 ms | -1.9% | IMPROVE |
| single-day-application-log-standard | MEMORY/rss_peak | 37.6 MB | 37.4 MB | -272 KB | -0.7% | IMPROVE |
| single-day-application-log-top25 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | TIMING/total | 3.9 s | 3.8 s | -124 ms | -3.2% | IMPROVE |
| single-day-application-log-top25 | MEMORY/rss_peak | 37.4 MB | 37.3 MB | -96 KB | -0.3% | IMPROVE |
| single-day-application-log-top25-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/total | 7.0 s | 6.6 s | -359 ms | -5.1% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/rss_peak | 126.4 MB | 125.6 MB | -816 KB | -0.6% | IMPROVE |
| single-day-application-log-heatmap | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | TIMING/total | 3.8 s | 3.7 s | -149 ms | -3.9% | IMPROVE |
| single-day-application-log-heatmap | MEMORY/rss_peak | 37.4 MB | 37.3 MB | -128 KB | -0.3% | IMPROVE |
| single-day-application-log-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | TIMING/total | 3.8 s | 3.8 s | -53 ms | -1.4% | IMPROVE |
| single-day-application-log-histogram | MEMORY/rss_peak | 37.2 MB | 37.3 MB | +128 KB | 0.3% | REGRESS |
| single-day-application-log-heatmap-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/total | 3.8 s | 3.7 s | -32 ms | -0.8% | IMPROVE |
| single-day-application-log-heatmap-histogram | MEMORY/rss_peak | 37.1 MB | 37.3 MB | +256 KB | 0.7% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/total | 7 s | 6.6 s | -431 ms | -6.1% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 124.3 MB | 126.4 MB | +2.1 MB | 1.7% | REGRESS |
| multi-day-application-logs-standard | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-standard | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-standard | TIMING/total | 8.5 s | 8.1 s | -389 ms | -4.6% | IMPROVE |
| multi-day-application-logs-standard | MEMORY/rss_peak | 117.9 MB | 114.8 MB | -3 MB | -2.6% | IMPROVE |
| multi-day-application-logs-top25 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/total | 8.3 s | 8.2 s | -156 ms | -1.9% | IMPROVE |
| multi-day-application-logs-top25 | MEMORY/rss_peak | 115.1 MB | 115.1 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/total | 46.1 s | 40.8 s | -5.3 s | -11.4% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | 229.9 MB | 226.1 MB | -3.8 MB | -1.6% | IMPROVE |
| multi-day-application-logs-heatmap | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/total | 8.4 s | 8.1 s | -275 ms | -3.3% | IMPROVE |
| multi-day-application-logs-heatmap | MEMORY/rss_peak | 115.8 MB | 115.1 MB | -720 KB | -0.6% | IMPROVE |
| multi-day-application-logs-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/total | 8.6 s | 8.1 s | -536 ms | -6.2% | IMPROVE |
| multi-day-application-logs-histogram | MEMORY/rss_peak | 116.7 MB | 114.9 MB | -1.8 MB | -1.5% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/total | 8.5 s | 8.1 s | -384 ms | -4.5% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | MEMORY/rss_peak | 118.9 MB | 115.1 MB | -3.8 MB | -3.2% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | 47.3 s | 41.0 s | -6.3 s | -13.4% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 227.7 MB | 224.4 MB | -3.3 MB | -1.4% | IMPROVE |
| multi-day-custom-logs-standard | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/total | 18.0 s | 16.5 s | -1.5 s | -8.1% | IMPROVE |
| multi-day-custom-logs-standard | MEMORY/rss_peak | 204.7 MB | 192.9 MB | -11.7 MB | -5.7% | IMPROVE |
| multi-day-custom-logs-top25 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/total | 18.1 s | 16.4 s | -1.7 s | -9.5% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/rss_peak | 206.2 MB | 192.8 MB | -13.4 MB | -6.5% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/total | 1 min | 52.6 s | -8.8 s | -14.3% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/rss_peak | 261.3 MB | 247.3 MB | -14.0 MB | -5.3% | IMPROVE |
| multi-day-custom-logs-heatmap | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/total | 18.5 s | 17 s | -1.5 s | -8.0% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/rss_peak | 183.9 MB | 177.8 MB | -6.1 MB | -3.3% | IMPROVE |
| multi-day-custom-logs-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/total | 18.9 s | 17.3 s | -1.6 s | -8.7% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/rss_peak | 205.8 MB | 192.6 MB | -13.2 MB | -6.4% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/total | 19.3 s | 17.6 s | -1.6 s | -8.5% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/rss_peak | 179 MB | 180.4 MB | +1.4 MB | 0.8% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/total | 1 min | 52.9 s | -8.7 s | -14.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 243.9 MB | 231.5 MB | -12.4 MB | -5.1% | IMPROVE |
| single-day-access-log-standard | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | TIMING/total | 10.7 s | 11.3 s | +646 ms | 6.1% | REGRESS |
| single-day-access-log-standard | MEMORY/rss_peak | 165.4 MB | 143.5 MB | -21.8 MB | -13.2% | IMPROVE |
| single-day-access-log-top25 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | TIMING/total | 10.5 s | 11.2 s | +773 ms | 7.4% | REGRESS |
| single-day-access-log-top25 | MEMORY/rss_peak | 163.1 MB | 144.3 MB | -18.8 MB | -11.5% | IMPROVE |
| single-day-access-log-top25-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/total | 17.4 s | 16.7 s | -668 ms | -3.8% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/rss_peak | 207.7 MB | 180.4 MB | -27.3 MB | -13.2% | IMPROVE |
| single-day-access-log-heatmap | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | TIMING/total | 11.1 s | 11.9 s | +774 ms | 7.0% | REGRESS |
| single-day-access-log-heatmap | MEMORY/rss_peak | 128.4 MB | 116.5 MB | -11.8 MB | -9.2% | IMPROVE |
| single-day-access-log-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | TIMING/total | 12.8 s | 13.3 s | +516 ms | 4.0% | REGRESS |
| single-day-access-log-histogram | MEMORY/rss_peak | 165.6 MB | 146.2 MB | -19.4 MB | -11.7% | IMPROVE |
| single-day-access-log-heatmap-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/total | 13 s | 13.6 s | +634 ms | 4.9% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/rss_peak | 129.0 MB | 117.5 MB | -11.5 MB | -8.9% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/total | 18.4 s | 17.9 s | -470 ms | -2.6% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 180.9 MB | 158.4 MB | -22.5 MB | -12.4% | IMPROVE |
| humungous-log-uniqueness-sort-p99 | lines_read | N/A | 288,025 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | lines_included | N/A | 288,025 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | TIMING/total | N/A | 2.8 s | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/rss_peak | N/A | 203.2 MB | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | lines_read | N/A | 288,025 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | lines_included | N/A | 288,025 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | TIMING/total | N/A | 2.9 s | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/rss_peak | N/A | 203.6 MB | N/A | N/A | ? |
| single-day-application-log-sort-p99 | lines_read | N/A | 479,904 | N/A | N/A | ? |
| single-day-application-log-sort-p99 | lines_included | N/A | 479,904 | N/A | N/A | ? |
| single-day-application-log-sort-p99 | TIMING/total | N/A | 3.8 s | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/rss_peak | N/A | 37.0 MB | N/A | N/A | ? |
| single-day-application-log-sort-skewness | lines_read | N/A | 479,904 | N/A | N/A | ? |
| single-day-application-log-sort-skewness | lines_included | N/A | 479,904 | N/A | N/A | ? |
| single-day-application-log-sort-skewness | TIMING/total | N/A | 3.8 s | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/rss_peak | N/A | 37.4 MB | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | lines_read | N/A | 930,031 | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | lines_included | N/A | 930,028 | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | TIMING/total | N/A | 8.1 s | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/rss_peak | N/A | 114.4 MB | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | lines_read | N/A | 930,031 | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | lines_included | N/A | 930,028 | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | TIMING/total | N/A | 8.1 s | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/rss_peak | N/A | 114.3 MB | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | lines_read | N/A | 1,530,399 | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | lines_included | N/A | 1,530,399 | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | TIMING/total | N/A | 16.4 s | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/rss_peak | N/A | 190.2 MB | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | lines_read | N/A | 1,530,399 | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | lines_included | N/A | 1,530,399 | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | TIMING/total | N/A | 16.5 s | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/rss_peak | N/A | 192 MB | N/A | N/A | ? |
| single-day-access-log-sort-p99 | lines_read | N/A | 761,698 | N/A | N/A | ? |
| single-day-access-log-sort-p99 | lines_included | N/A | 761,698 | N/A | N/A | ? |
| single-day-access-log-sort-p99 | TIMING/total | N/A | 11.3 s | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/rss_peak | N/A | 143.3 MB | N/A | N/A | ? |
| single-day-access-log-sort-skewness | lines_read | N/A | 761,698 | N/A | N/A | ? |
| single-day-access-log-sort-skewness | lines_included | N/A | 761,698 | N/A | N/A | ? |
| single-day-access-log-sort-skewness | TIMING/total | N/A | 11.5 s | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/rss_peak | N/A | 149.2 MB | N/A | N/A | ? |
| month-single-server-access-logs-standard | lines_read | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-standard | lines_included | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/total | N/A | 2.1 min | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/rss_peak | N/A | 2.5 GB | N/A | N/A | ? |
| month-single-server-access-logs-top25 | lines_read | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | lines_included | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/total | N/A | 2.1 min | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/rss_peak | N/A | 2.5 GB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | lines_read | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | lines_included | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/total | N/A | 4.4 min | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | N/A | 1.6 GB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | lines_read | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | lines_included | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/total | N/A | 2.3 min | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/rss_peak | N/A | 2.1 GB | N/A | N/A | ? |
| month-single-server-access-logs-histogram | lines_read | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | lines_included | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/total | N/A | 2.5 min | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/rss_peak | N/A | 2.5 GB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | lines_read | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | lines_included | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/total | N/A | 2.6 min | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/rss_peak | N/A | 2 GB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_read | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_included | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | N/A | 4.4 min | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | N/A | 1.3 GB | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | lines_read | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | lines_included | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | TIMING/total | N/A | 2.3 min | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/rss_peak | N/A | 2.6 GB | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | lines_read | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | lines_included | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | TIMING/total | N/A | 2.2 min | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/rss_peak | N/A | 2.5 GB | N/A | N/A | ? |
| month-many-servers-access-logs-standard | lines_read | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | lines_included | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/total | N/A | 10.7 min | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/rss_peak | N/A | 12.1 GB | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | lines_read | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | lines_included | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/total | N/A | 10.6 min | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/rss_peak | N/A | 12.4 GB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | lines_read | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | lines_included | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | N/A | 30.2 min | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | N/A | 6.7 GB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | lines_read | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | lines_included | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/total | N/A | 11.2 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/rss_peak | N/A | 9.9 GB | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | lines_read | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | lines_included | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/total | N/A | 12.5 min | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/rss_peak | N/A | 12.4 GB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | lines_read | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | lines_included | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/total | N/A | 12.8 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/rss_peak | N/A | 9.6 GB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_read | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_included | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | N/A | 27.5 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | N/A | 4.6 GB | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | lines_read | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | lines_included | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | TIMING/total | N/A | 11.3 min | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/rss_peak | N/A | 12.7 GB | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | lines_read | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | lines_included | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | TIMING/total | N/A | 10.9 min | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/rss_peak | N/A | 12.4 GB | N/A | N/A | ? |

### Detailed

| test_name | metric | baseline | current | delta | change% | result |
| --- | --- | --- | --- | --- | --- | --- |
| humungous-log-uniqueness-standard | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/read_files | 2.6 s | 2.5 s | -123 ms | -4.8% | IMPROVE |
| humungous-log-uniqueness-standard | TIMING/calculate_statistics | 321 ms | 274 ms | -47 ms | -14.6% | IMPROVE |
| humungous-log-uniqueness-standard | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/total | 2.9 s | 2.7 s | -170 ms | -5.9% | IMPROVE |
| humungous-log-uniqueness-standard | MEMORY/rss_peak | 204.7 MB | 205.3 MB | +576 KB | 0.3% | REGRESS |
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
| humungous-log-uniqueness-standard | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
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
| humungous-log-uniqueness-top25 | TIMING/read_files | 2.6 s | 2.4 s | -130 ms | -5.1% | IMPROVE |
| humungous-log-uniqueness-top25 | TIMING/calculate_statistics | 305 ms | 269 ms | -36 ms | -11.8% | IMPROVE |
| humungous-log-uniqueness-top25 | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/total | 2.9 s | 2.7 s | -166 ms | -5.8% | IMPROVE |
| humungous-log-uniqueness-top25 | MEMORY/rss_peak | 203.5 MB | 205.6 MB | +2.1 MB | 1.0% | REGRESS |
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
| humungous-log-uniqueness-top25 | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
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
| humungous-log-uniqueness-top25-consolidate | TIMING/read_files | 7.3 s | 6.4 s | -808 ms | -11.1% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | TIMING/group_similar | 4.7 s | 3.9 s | -857 ms | -18.1% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/total | 12.0 s | 10.3 s | -1.7 s | -13.9% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/rss_peak | 250.3 MB | 249 MB | -1.3 MB | -0.5% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_clusters | 196.2 KB | 196.2 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_message | 3.1 MB | 3.1 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_trigrams | 71.7 MB | 71.7 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 64.2 MB | 64.2 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_ngram_index | 66.7 MB | 66.7 MB | -16.6 KB | -0.0% | IMPROVE |
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
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
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
| humungous-log-uniqueness-heatmap | TIMING/read_files | 2.5 s | 2.4 s | -94 ms | -3.7% | IMPROVE |
| humungous-log-uniqueness-heatmap | TIMING/calculate_statistics | 337 ms | 270 ms | -67 ms | -19.9% | IMPROVE |
| humungous-log-uniqueness-heatmap | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/total | 2.9 s | 2.7 s | -161 ms | -5.6% | IMPROVE |
| humungous-log-uniqueness-heatmap | MEMORY/rss_peak | 204.1 MB | 205 MB | +912 KB | 0.4% | REGRESS |
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
| humungous-log-uniqueness-heatmap | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
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
| humungous-log-uniqueness-histogram | TIMING/read_files | 2.6 s | 2.4 s | -153 ms | -6.0% | IMPROVE |
| humungous-log-uniqueness-histogram | TIMING/calculate_statistics | 331 ms | 261 ms | -70 ms | -21.1% | IMPROVE |
| humungous-log-uniqueness-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/total | 2.9 s | 2.7 s | -223 ms | -7.7% | IMPROVE |
| humungous-log-uniqueness-histogram | MEMORY/rss_peak | 204 MB | 205.2 MB | +1.2 MB | 0.6% | REGRESS |
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
| humungous-log-uniqueness-histogram | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
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
| humungous-log-uniqueness-heatmap-histogram | TIMING/read_files | 2.5 s | 2.4 s | -146 ms | -5.7% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | TIMING/calculate_statistics | 301 ms | 259 ms | -42 ms | -14.0% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/total | 2.8 s | 2.7 s | -187 ms | -6.6% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/rss_peak | 204.3 MB | 205.7 MB | +1.3 MB | 0.6% | REGRESS |
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
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
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
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/read_files | 6.9 s | 6.3 s | -602 ms | -8.7% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/group_similar | 4.7 s | 3.9 s | -817 ms | -17.5% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/total | 11.6 s | 10.2 s | -1.4 s | -12.2% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/rss_peak | 248.1 MB | 249.7 MB | +1.6 MB | 0.6% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 196.2 KB | 196.2 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 3.1 MB | 3.1 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 71.7 MB | 71.7 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 64.2 MB | 64.2 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 66.7 MB | 66.7 MB | -3.5 KB | -0.0% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 24.8 KB | 24.8 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 614.1 KB | 614.1 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 1.7 MB | 1.7 MB | +64 B | 0.0% | REGRESS |
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
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
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
| single-day-application-log-standard | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | TIMING/read_files | 3.9 s | 3.8 s | -73 ms | -1.9% | IMPROVE |
| single-day-application-log-standard | TIMING/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-standard | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-standard | TIMING/total | 3.9 s | 3.8 s | -74 ms | -1.9% | IMPROVE |
| single-day-application-log-standard | MEMORY/rss_peak | 37.6 MB | 37.4 MB | -272 KB | -0.7% | IMPROVE |
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
| single-day-application-log-standard | MEMORY/log_occurrences | 21.8 KB | 21.5 KB | -256 B | -1.1% | IMPROVE |
| single-day-application-log-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
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
| single-day-application-log-top25 | TIMING/read_files | 3.9 s | 3.7 s | -122 ms | -3.2% | IMPROVE |
| single-day-application-log-top25 | TIMING/calculate_statistics | 7 ms | 6 ms | -1 ms | -14.3% | IMPROVE |
| single-day-application-log-top25 | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25 | TIMING/total | 3.9 s | 3.8 s | -124 ms | -3.2% | IMPROVE |
| single-day-application-log-top25 | MEMORY/rss_peak | 37.4 MB | 37.3 MB | -96 KB | -0.3% | IMPROVE |
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
| single-day-application-log-top25 | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
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
| single-day-application-log-top25-consolidate | TIMING/read_files | 6.7 s | 6.4 s | -289 ms | -4.3% | IMPROVE |
| single-day-application-log-top25-consolidate | TIMING/group_similar | 323 ms | 254 ms | -69 ms | -21.4% | IMPROVE |
| single-day-application-log-top25-consolidate | TIMING/normalize_data | 2 ms | 1 ms | -1 ms | -50.0% | IMPROVE |
| single-day-application-log-top25-consolidate | TIMING/total | 7.0 s | 6.6 s | -359 ms | -5.1% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/rss_peak | 126.4 MB | 125.6 MB | -816 KB | -0.6% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_clusters | 437.3 KB | 437.5 KB | +256 B | 0.1% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_message | 2.6 MB | 2.6 MB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_trigrams | 29.3 MB | 29.3 MB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 16.4 MB | 16.4 MB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_ngram_index | 29.7 MB | 29.7 MB | -3.4 KB | -0.0% | IMPROVE |
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
| single-day-application-log-top25-consolidate | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/log_messages | 137524 | 137524 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 447749 | 448005 | 256 | 0.1% | REGRESS |
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
| single-day-application-log-heatmap | TIMING/read_files | 3.8 s | 3.7 s | -148 ms | -3.9% | IMPROVE |
| single-day-application-log-heatmap | TIMING/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap | TIMING/total | 3.8 s | 3.7 s | -149 ms | -3.9% | IMPROVE |
| single-day-application-log-heatmap | MEMORY/rss_peak | 37.4 MB | 37.3 MB | -128 KB | -0.3% | IMPROVE |
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
| single-day-application-log-heatmap | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
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
| single-day-application-log-histogram | TIMING/read_files | 3.8 s | 3.8 s | -53 ms | -1.4% | IMPROVE |
| single-day-application-log-histogram | TIMING/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-histogram | TIMING/total | 3.8 s | 3.8 s | -53 ms | -1.4% | IMPROVE |
| single-day-application-log-histogram | MEMORY/rss_peak | 37.2 MB | 37.3 MB | +128 KB | 0.3% | REGRESS |
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
| single-day-application-log-histogram | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
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
| single-day-application-log-heatmap-histogram | TIMING/read_files | 3.8 s | 3.7 s | -30 ms | -0.8% | IMPROVE |
| single-day-application-log-heatmap-histogram | TIMING/calculate_statistics | 7 ms | 6 ms | -1 ms | -14.3% | IMPROVE |
| single-day-application-log-heatmap-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/total | 3.8 s | 3.7 s | -32 ms | -0.8% | IMPROVE |
| single-day-application-log-heatmap-histogram | MEMORY/rss_peak | 37.1 MB | 37.3 MB | +256 KB | 0.7% | REGRESS |
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
| single-day-application-log-heatmap-histogram | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
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
| single-day-application-log-heatmap-histogram-consolidate | TIMING/read_files | 6.7 s | 6.3 s | -351 ms | -5.3% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/group_similar | 343 ms | 264 ms | -79 ms | -23.0% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/normalize_data | 2 ms | 1 ms | -1 ms | -50.0% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/total | 7 s | 6.6 s | -431 ms | -6.1% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 124.3 MB | 126.4 MB | +2.1 MB | 1.7% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 437.5 KB | 437.5 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 2.6 MB | 2.6 MB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 29.3 MB | 29.3 MB | +2 KB | 0.0% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 16.4 MB | 16.4 MB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 29.7 MB | 29.7 MB | -768 B | -0.0% | IMPROVE |
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
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_occurrences | 21.8 KB | 21.5 KB | -256 B | -1.1% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
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
| multi-day-application-logs-standard | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-standard | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-standard | TIMING/read_files | 8.3 s | 7.9 s | -355 ms | -4.3% | IMPROVE |
| multi-day-application-logs-standard | TIMING/calculate_statistics | 197 ms | 164 ms | -33 ms | -16.8% | IMPROVE |
| multi-day-application-logs-standard | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-standard | TIMING/total | 8.5 s | 8.1 s | -389 ms | -4.6% | IMPROVE |
| multi-day-application-logs-standard | MEMORY/rss_peak | 117.9 MB | 114.8 MB | -3 MB | -2.6% | IMPROVE |
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
| multi-day-application-logs-standard | MEMORY/log_occurrences | 56.6 KB | 56.7 KB | +64 B | 0.1% | REGRESS |
| multi-day-application-logs-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
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
| multi-day-application-logs-top25 | TIMING/read_files | 8.1 s | 8.0 s | -128 ms | -1.6% | IMPROVE |
| multi-day-application-logs-top25 | TIMING/calculate_statistics | 193 ms | 165 ms | -28 ms | -14.5% | IMPROVE |
| multi-day-application-logs-top25 | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/total | 8.3 s | 8.2 s | -156 ms | -1.9% | IMPROVE |
| multi-day-application-logs-top25 | MEMORY/rss_peak | 115.1 MB | 115.1 MB | 0 B | 0.0% |  |
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
| multi-day-application-logs-top25 | MEMORY/log_occurrences | 56.7 KB | 56.6 KB | -64 B | -0.1% | IMPROVE |
| multi-day-application-logs-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
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
| multi-day-application-logs-top25-consolidate | TIMING/read_files | 41 s | 36.5 s | -4.5 s | -11.0% | IMPROVE |
| multi-day-application-logs-top25-consolidate | TIMING/group_similar | 5 s | 4.3 s | -750 ms | -15.0% | IMPROVE |
| multi-day-application-logs-top25-consolidate | TIMING/calculate_statistics | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/normalize_data | 3 ms | 2 ms | -1 ms | -33.3% | IMPROVE |
| multi-day-application-logs-top25-consolidate | TIMING/total | 46.1 s | 40.8 s | -5.3 s | -11.4% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | 229.9 MB | 226.1 MB | -3.8 MB | -1.6% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_clusters | 3.6 MB | 3.6 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_message | 3.5 MB | 3.5 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 62.2 MB | 62.2 MB | -1 KB | -0.0% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 10.4 MB | 10.4 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_ngram_index | 60.8 MB | 60.8 MB | +26.2 KB | 0.0% | REGRESS |
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
| multi-day-application-logs-top25-consolidate | MEMORY/log_occurrences | 56.6 KB | 56.6 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
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
| multi-day-application-logs-heatmap | TIMING/read_files | 8.2 s | 7.9 s | -259 ms | -3.2% | IMPROVE |
| multi-day-application-logs-heatmap | TIMING/calculate_statistics | 184 ms | 167 ms | -17 ms | -9.2% | IMPROVE |
| multi-day-application-logs-heatmap | TIMING/normalize_data | 2 ms | 1 ms | -1 ms | -50.0% | IMPROVE |
| multi-day-application-logs-heatmap | TIMING/total | 8.4 s | 8.1 s | -275 ms | -3.3% | IMPROVE |
| multi-day-application-logs-heatmap | MEMORY/rss_peak | 115.8 MB | 115.1 MB | -720 KB | -0.6% | IMPROVE |
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
| multi-day-application-logs-heatmap | MEMORY/log_occurrences | 56.6 KB | 56.6 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
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
| multi-day-application-logs-histogram | TIMING/read_files | 8.4 s | 7.9 s | -498 ms | -5.9% | IMPROVE |
| multi-day-application-logs-histogram | TIMING/calculate_statistics | 201 ms | 163 ms | -38 ms | -18.9% | IMPROVE |
| multi-day-application-logs-histogram | TIMING/normalize_data | 2 ms | 1 ms | -1 ms | -50.0% | IMPROVE |
| multi-day-application-logs-histogram | TIMING/total | 8.6 s | 8.1 s | -536 ms | -6.2% | IMPROVE |
| multi-day-application-logs-histogram | MEMORY/rss_peak | 116.7 MB | 114.9 MB | -1.8 MB | -1.5% | IMPROVE |
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
| multi-day-application-logs-histogram | MEMORY/log_occurrences | 56.7 KB | 56.7 KB | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
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
| multi-day-application-logs-heatmap-histogram | TIMING/read_files | 8.3 s | 7.9 s | -338 ms | -4.1% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | TIMING/calculate_statistics | 211 ms | 166 ms | -45 ms | -21.3% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | TIMING/normalize_data | 2 ms | 1 ms | -1 ms | -50.0% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | TIMING/total | 8.5 s | 8.1 s | -384 ms | -4.5% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | MEMORY/rss_peak | 118.9 MB | 115.1 MB | -3.8 MB | -3.2% | IMPROVE |
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
| multi-day-application-logs-heatmap-histogram | MEMORY/log_occurrences | 56.6 KB | 56.7 KB | +64 B | 0.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
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
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/read_files | 42.0 s | 36.7 s | -5.3 s | -12.6% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/group_similar | 5.3 s | 4.3 s | -1 s | -19.4% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/normalize_data | 4 ms | 3 ms | -1 ms | -25.0% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | 47.3 s | 41.0 s | -6.3 s | -13.4% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 227.7 MB | 224.4 MB | -3.3 MB | -1.4% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 3.6 MB | 3.6 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 3.5 MB | 3.5 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 62.2 MB | 62.2 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 10.4 MB | 10.4 MB | +8 KB | 0.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 60.8 MB | 60.8 MB | -25.6 KB | -0.0% | IMPROVE |
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
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 56.6 KB | 56.7 KB | +64 B | 0.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
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
| multi-day-custom-logs-standard | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/read_files | 17.5 s | 16.2 s | -1.3 s | -7.5% | IMPROVE |
| multi-day-custom-logs-standard | TIMING/calculate_statistics | 498 ms | 351 ms | -147 ms | -29.5% | IMPROVE |
| multi-day-custom-logs-standard | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/total | 18.0 s | 16.5 s | -1.5 s | -8.1% | IMPROVE |
| multi-day-custom-logs-standard | MEMORY/rss_peak | 204.7 MB | 192.9 MB | -11.7 MB | -5.7% | IMPROVE |
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
| multi-day-custom-logs-standard | MEMORY/log_messages | 103.0 MB | 102.5 MB | -496.4 KB | -0.5% | IMPROVE |
| multi-day-custom-logs-standard | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_stats | 72.4 KB | 39.8 KB | -32.6 KB | -45.0% | IMPROVE |
| multi-day-custom-logs-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY_FINAL/log_messages | 107978981 | 107470660 | -508321 | -0.5% | IMPROVE |
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
| multi-day-custom-logs-top25 | TIMING/read_files | 17.6 s | 16 s | -1.6 s | -9.0% | IMPROVE |
| multi-day-custom-logs-top25 | TIMING/calculate_statistics | 481 ms | 355 ms | -126 ms | -26.2% | IMPROVE |
| multi-day-custom-logs-top25 | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/total | 18.1 s | 16.4 s | -1.7 s | -9.5% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/rss_peak | 206.2 MB | 192.8 MB | -13.4 MB | -6.5% | IMPROVE |
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
| multi-day-custom-logs-top25 | MEMORY/log_messages | 103 MB | 102.5 MB | -514.6 KB | -0.5% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_stats | 72.4 KB | 39.8 KB | -32.6 KB | -45.0% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY_FINAL/log_messages | 108009221 | 107482300 | -526921 | -0.5% | IMPROVE |
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
| multi-day-custom-logs-top25-consolidate | TIMING/read_files | 55.0 s | 47.7 s | -7.3 s | -13.2% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/group_similar | 5.8 s | 4.6 s | -1.1 s | -19.3% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/calculate_statistics | 676 ms | 260 ms | -416 ms | -61.5% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/total | 1 min | 52.6 s | -8.8 s | -14.3% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/rss_peak | 261.3 MB | 247.3 MB | -14.0 MB | -5.3% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_clusters | 29.5 MB | 29.5 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_message | 5.8 MB | 5.8 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 62.6 MB | 62.6 MB | -1 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 4.5 MB | 4.5 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_ngram_index | 61.3 MB | 61.3 MB | +6 KB | 0.0% | REGRESS |
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
| multi-day-custom-logs-top25-consolidate | MEMORY/log_messages | 28.6 MB | 28.6 MB | -12.6 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_stats | 72.4 KB | 39.8 KB | -32.6 KB | -45.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/log_messages | 30020363 | 30007466 | -12897 | -0.0% | IMPROVE |
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
| multi-day-custom-logs-heatmap | TIMING/read_files | 18.1 s | 16.7 s | -1.4 s | -7.8% | IMPROVE |
| multi-day-custom-logs-heatmap | TIMING/calculate_statistics | 354 ms | 291 ms | -63 ms | -17.8% | IMPROVE |
| multi-day-custom-logs-heatmap | TIMING/heatmap_statistics | 17 ms | 15 ms | -2 ms | -11.8% | IMPROVE |
| multi-day-custom-logs-heatmap | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/total | 18.5 s | 17 s | -1.5 s | -8.0% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/rss_peak | 183.9 MB | 177.8 MB | -6.1 MB | -3.3% | IMPROVE |
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
| multi-day-custom-logs-heatmap | MEMORY/heatmap_counters | 983.4 KB | 981.9 KB | -1.5 KB | -0.2% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_data | 43.7 KB | 43.8 KB | +64 B | 0.1% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_analysis | 20.9 KB | 20.9 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_messages | 102.5 MB | 102.5 MB | -12.8 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_stats | 58.6 KB | 28.2 KB | -30.4 KB | -51.9% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/log_messages | 107483749 | 107470660 | -13089 | -0.0% | IMPROVE |
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
| multi-day-custom-logs-histogram | TIMING/read_files | 18.4 s | 16.9 s | -1.5 s | -8.1% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/calculate_statistics | 503 ms | 352 ms | -151 ms | -30.0% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/histogram_statistics | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/normalize_data | 2 ms | 1 ms | -1 ms | -50.0% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/total | 18.9 s | 17.3 s | -1.6 s | -8.7% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/rss_peak | 205.8 MB | 192.6 MB | -13.2 MB | -6.4% | IMPROVE |
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
| multi-day-custom-logs-histogram | MEMORY/log_analysis | 28.4 MB | 28.4 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_messages | 102.5 MB | 102.5 MB | -12.4 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_stats | 72.4 KB | 39.8 KB | -32.6 KB | -45.0% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY_FINAL/log_messages | 107483557 | 107470852 | -12705 | -0.0% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY_FINAL/log_analysis | 20342 | 20342 | 0 | 0.0% |  |
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
| multi-day-custom-logs-heatmap-histogram | TIMING/read_files | 18.9 s | 17.3 s | -1.6 s | -8.4% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/calculate_statistics | 351 ms | 287 ms | -64 ms | -18.2% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/heatmap_statistics | 16 ms | 15 ms | -1 ms | -6.3% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/histogram_statistics | 4 ms | 3 ms | -1 ms | -25.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/total | 19.3 s | 17.6 s | -1.6 s | -8.5% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/rss_peak | 179 MB | 180.4 MB | +1.4 MB | 0.8% | REGRESS |
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
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_counters | 983.4 KB | 983.4 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_data | 43.6 KB | 42.6 KB | -1 KB | -2.3% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_counters | 122.1 KB | 122.1 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_analysis | 20.9 KB | 20.9 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_messages | 102.5 MB | 102.5 MB | -12.4 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_stats | 58.6 KB | 28.2 KB | -30.4 KB | -51.9% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 107483557 | 107470852 | -12705 | -0.0% | IMPROVE |
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
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/read_files | 56.1 s | 48.5 s | -7.6 s | -13.6% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/group_similar | 5.2 s | 4.2 s | -967 ms | -18.6% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | 222 ms | 127 ms | -95 ms | -42.8% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/heatmap_statistics | 21 ms | 19 ms | -2 ms | -9.5% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/histogram_statistics | 4 ms | 4 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/total | 1 min | 52.9 s | -8.7 s | -14.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 243.9 MB | 231.5 MB | -12.4 MB | -5.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 29.5 MB | 29.5 MB | +3.2 KB | 0.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 5.8 MB | 5.8 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 62.6 MB | 62.6 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 4.5 MB | 4.5 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 61.3 MB | 61.3 MB | +8.9 KB | 0.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 202.1 KB | 202.1 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 478.1 KB | 478.1 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 3.3 MB | 3.3 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 983.4 KB | 983.4 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 43.8 KB | 40.5 KB | -3.2 KB | -7.4% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | 122.1 KB | 122.1 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 20.9 KB | 20.9 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 28.6 MB | 28.6 MB | -9.1 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 58.6 KB | 28.2 KB | -30.4 KB | -51.9% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 30008267 | 29998970 | -9297 | -0.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 20342 | 20342 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 30966612 | 30969940 | 3328 | 0.0% | REGRESS |
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
| single-day-access-log-standard | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | TIMING/read_files | 10.3 s | 11.1 s | +893 ms | 8.7% | REGRESS |
| single-day-access-log-standard | TIMING/calculate_statistics | 397 ms | 151 ms | -246 ms | -62.0% | IMPROVE |
| single-day-access-log-standard | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-standard | TIMING/total | 10.7 s | 11.3 s | +646 ms | 6.1% | REGRESS |
| single-day-access-log-standard | MEMORY/rss_peak | 165.4 MB | 143.5 MB | -21.8 MB | -13.2% | IMPROVE |
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
| single-day-access-log-standard | MEMORY/log_messages | 55.4 MB | 55.2 MB | -205.4 KB | -0.4% | IMPROVE |
| single-day-access-log-standard | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_stats | 43.1 KB | 22.5 KB | -20.6 KB | -47.8% | IMPROVE |
| single-day-access-log-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY_FINAL/log_messages | 58121809 | 57911448 | -210361 | -0.4% | IMPROVE |
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
| single-day-access-log-top25 | TIMING/read_files | 10 s | 11.1 s | +1 s | 10.4% | REGRESS |
| single-day-access-log-top25 | TIMING/calculate_statistics | 436 ms | 169 ms | -267 ms | -61.2% | IMPROVE |
| single-day-access-log-top25 | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25 | TIMING/total | 10.5 s | 11.2 s | +773 ms | 7.4% | REGRESS |
| single-day-access-log-top25 | MEMORY/rss_peak | 163.1 MB | 144.3 MB | -18.8 MB | -11.5% | IMPROVE |
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
| single-day-access-log-top25 | MEMORY/log_messages | 55.5 MB | 55.4 MB | -34.0 KB | -0.1% | IMPROVE |
| single-day-access-log-top25 | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_stats | 43.1 KB | 22.5 KB | -20.6 KB | -47.8% | IMPROVE |
| single-day-access-log-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY_FINAL/log_messages | 58152289 | 58117504 | -34785 | -0.1% | IMPROVE |
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
| single-day-access-log-top25-consolidate | TIMING/read_files | 12.0 s | 12.6 s | +616 ms | 5.1% | REGRESS |
| single-day-access-log-top25-consolidate | TIMING/group_similar | 4.7 s | 3.8 s | -849 ms | -18.1% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/calculate_statistics | 714 ms | 279 ms | -435 ms | -60.9% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/normalize_data | 2 ms | 1 ms | -1 ms | -50.0% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/total | 17.4 s | 16.7 s | -668 ms | -3.8% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/rss_peak | 207.7 MB | 180.4 MB | -27.3 MB | -13.2% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_clusters | 48.4 MB | 48.4 MB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_message | 883 KB | 883 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_trigrams | 4.1 MB | 4.1 MB | +512 B | 0.0% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_ngram_index | 4.8 MB | 4.8 MB | +3.8 KB | 0.1% | REGRESS |
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
| single-day-access-log-top25-consolidate | MEMORY/log_messages | 55.4 MB | 55.4 MB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_stats | 43.1 KB | 22.5 KB | -20.6 KB | -47.8% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/log_messages | 56113218 | 56078049 | -35169 | -0.1% | IMPROVE |
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
| single-day-access-log-heatmap | TIMING/read_files | 11.0 s | 11.8 s | +833 ms | 7.6% | REGRESS |
| single-day-access-log-heatmap | TIMING/calculate_statistics | 107 ms | 49 ms | -58 ms | -54.2% | IMPROVE |
| single-day-access-log-heatmap | TIMING/heatmap_statistics | 9 ms | 8 ms | -1000 us | -11.1% | IMPROVE |
| single-day-access-log-heatmap | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap | TIMING/total | 11.1 s | 11.9 s | +774 ms | 7.0% | REGRESS |
| single-day-access-log-heatmap | MEMORY/rss_peak | 128.4 MB | 116.5 MB | -11.8 MB | -9.2% | IMPROVE |
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
| single-day-access-log-heatmap | MEMORY/heatmap_counters | 568.8 KB | 569.7 KB | +960 B | 0.2% | REGRESS |
| single-day-access-log-heatmap | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_data | 34 KB | 34 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_analysis | 8.1 KB | 8.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_messages | 55.4 MB | 55.4 MB | -7.2 KB | -0.0% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_stats | 34.5 KB | 15.2 KB | -19.3 KB | -56.0% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY_FINAL/log_messages | 58121809 | 58114456 | -7353 | -0.0% | IMPROVE |
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
| single-day-access-log-histogram | TIMING/read_files | 12.4 s | 13.1 s | +750 ms | 6.1% | REGRESS |
| single-day-access-log-histogram | TIMING/calculate_statistics | 385 ms | 152 ms | -233 ms | -60.5% | IMPROVE |
| single-day-access-log-histogram | TIMING/histogram_statistics | 3 ms | 3 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/total | 12.8 s | 13.3 s | +516 ms | 4.0% | REGRESS |
| single-day-access-log-histogram | MEMORY/rss_peak | 165.6 MB | 146.2 MB | -19.4 MB | -11.7% | IMPROVE |
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
| single-day-access-log-histogram | MEMORY/histogram_counters | 105.6 KB | 105.6 KB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_analysis | 52.7 MB | 52.7 MB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_messages | 55.4 MB | 55.4 MB | -13.9 KB | -0.0% | IMPROVE |
| single-day-access-log-histogram | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_stats | 43.1 KB | 22.5 KB | -20.6 KB | -47.8% | IMPROVE |
| single-day-access-log-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY_FINAL/log_messages | 58128849 | 58114584 | -14265 | -0.0% | IMPROVE |
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
| single-day-access-log-heatmap-histogram | TIMING/read_files | 12.9 s | 13.6 s | +693 ms | 5.4% | REGRESS |
| single-day-access-log-heatmap-histogram | TIMING/calculate_statistics | 108 ms | 50 ms | -58 ms | -53.7% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/heatmap_statistics | 9 ms | 8 ms | -1000 us | -11.1% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/histogram_statistics | 3 ms | 3 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/normalize_data | 2 ms | 1 ms | -1 ms | -50.0% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/total | 13 s | 13.6 s | +634 ms | 4.9% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/rss_peak | 129.0 MB | 117.5 MB | -11.5 MB | -8.9% | IMPROVE |
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
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_counters | 568.8 KB | 569.7 KB | +960 B | 0.2% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_data | 34 KB | 34 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_counters | 105.5 KB | 105.6 KB | +128 B | 0.1% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_analysis | 8.1 KB | 8.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_messages | 55.4 MB | 55.2 MB | -212.3 KB | -0.4% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_stats | 34.5 KB | 15.2 KB | -19.3 KB | -56.0% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/log_messages | 58128849 | 57911448 | -217401 | -0.4% | IMPROVE |
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
| single-day-access-log-heatmap-histogram-consolidate | TIMING/read_files | 14.5 s | 15.0 s | +419 ms | 2.9% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/group_similar | 3.5 s | 2.8 s | -707 ms | -20.2% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/calculate_statistics | 356 ms | 175 ms | -181 ms | -50.8% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/heatmap_statistics | 9 ms | 9 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/histogram_statistics | 3 ms | 3 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/normalize_data | 2 ms | 1 ms | -1 ms | -50.0% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/total | 18.4 s | 17.9 s | -470 ms | -2.6% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 180.9 MB | 158.4 MB | -22.5 MB | -12.4% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 48.4 MB | 48.4 MB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 883 KB | 883 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 4.1 MB | 4.1 MB | +2 KB | 0.0% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 4.8 MB | 4.8 MB | -768 B | -0.0% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 118.1 KB | 118.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 352.5 KB | 352.5 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 565.1 KB | 565.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 569.7 KB | 568.8 KB | -960 B | -0.2% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_data | 34 KB | 34 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_counters | 105.6 KB | 105.5 KB | -128 B | -0.1% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_analysis | 8.1 KB | 8.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_messages | 55.2 MB | 55.4 MB | +192.1 KB | 0.3% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_stats | 34.5 KB | 15.2 KB | -19.3 KB | -56.0% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 56055346 | 56068601 | 13255 | 0.0% | REGRESS |
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
| humungous-log-uniqueness-standard | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY/message_key_order | N/A | 2.9 KB | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY/unattributed | N/A | 78.3 MB | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY/message_key_order | N/A | 7.7 KB | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY/unattributed | N/A | 78.5 MB | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY/message_key_order | N/A | 9.4 KB | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY/unattributed | N/A | 38.2 MB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY/message_key_order | N/A | 2.9 KB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY/unattributed | N/A | 78.0 MB | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY/message_key_order | N/A | 2.9 KB | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY/unattributed | N/A | 78.2 MB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/message_key_order | N/A | 2.9 KB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/unattributed | N/A | 78.6 MB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/message_key_order | N/A | 3.2 KB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/unattributed | N/A | 38.9 MB | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | lines_read | N/A | 288,025 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | lines_included | N/A | 288,025 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | TIMING/read_files | N/A | 2.4 s | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | TIMING/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | TIMING/group_similar | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | TIMING/calculate_statistics | N/A | 449 ms | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | TIMING/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | TIMING/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | TIMING/normalize_data | N/A | 1 ms | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | TIMING/total | N/A | 2.8 s | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/rss_peak | N/A | 203.2 MB | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_analysis | N/A | 232 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_messages | N/A | 127 MB | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_occurrences | N/A | 4.5 KB | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_sessions | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_stats | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/message_key_order | N/A | 2.9 KB | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY/unattributed | N/A | 76.1 MB | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/log_messages | N/A | 133188237 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | COUNTS/log_messages_entries | N/A | 286659 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | COUNTS/log_occurrences_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | COUNTS/log_stats_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-p99 | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | lines_read | N/A | 288,025 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | lines_included | N/A | 288,025 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | TIMING/read_files | N/A | 2.4 s | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | TIMING/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | TIMING/group_similar | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | TIMING/calculate_statistics | N/A | 453 ms | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | TIMING/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | TIMING/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | TIMING/normalize_data | N/A | 1 ms | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | TIMING/total | N/A | 2.9 s | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/rss_peak | N/A | 203.6 MB | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_analysis | N/A | 232 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_messages | N/A | 127 MB | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_occurrences | N/A | 4.5 KB | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_sessions | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_stats | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/message_key_order | N/A | 2.9 KB | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY/unattributed | N/A | 76.6 MB | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/log_messages | N/A | 133188237 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | COUNTS/log_messages_entries | N/A | 286659 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | COUNTS/log_occurrences_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | COUNTS/log_stats_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| humungous-log-uniqueness-sort-skewness | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY/message_key_order | N/A | 2.8 KB | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY/unattributed | N/A | 34.6 MB | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY/message_key_order | N/A | 6.4 KB | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY/unattributed | N/A | 34.5 MB | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY/message_key_order | N/A | 12.6 KB | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY/unattributed | N/A | 42.5 MB | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY/message_key_order | N/A | 2.8 KB | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY/unattributed | N/A | 34.5 MB | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY/message_key_order | N/A | 2.8 KB | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY/unattributed | N/A | 34.6 MB | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY/message_key_order | N/A | 2.8 KB | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY/unattributed | N/A | 34.6 MB | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/message_key_order | N/A | 2.6 KB | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/unattributed | N/A | 43.3 MB | N/A | N/A | ? |
| single-day-application-log-sort-p99 | lines_read | N/A | 479,904 | N/A | N/A | ? |
| single-day-application-log-sort-p99 | lines_included | N/A | 479,904 | N/A | N/A | ? |
| single-day-application-log-sort-p99 | TIMING/read_files | N/A | 3.8 s | N/A | N/A | ? |
| single-day-application-log-sort-p99 | TIMING/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-sort-p99 | TIMING/group_similar | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-sort-p99 | TIMING/calculate_statistics | N/A | 7 ms | N/A | N/A | ? |
| single-day-application-log-sort-p99 | TIMING/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-sort-p99 | TIMING/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-sort-p99 | TIMING/normalize_data | N/A | 1 ms | N/A | N/A | ? |
| single-day-application-log-sort-p99 | TIMING/total | N/A | 3.8 s | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/rss_peak | N/A | 37.0 MB | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/log_analysis | N/A | 232 B | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/log_messages | N/A | 2.7 MB | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/log_occurrences | N/A | 21.8 KB | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/log_sessions | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/log_stats | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/message_key_order | N/A | 2.8 KB | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY/unattributed | N/A | 34.2 MB | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY_FINAL/log_messages | N/A | 2872100 | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-sort-p99 | COUNTS/log_messages_entries | N/A | 6512 | N/A | N/A | ? |
| single-day-application-log-sort-p99 | COUNTS/log_occurrences_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-sort-p99 | COUNTS/log_stats_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-sort-p99 | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-sort-p99 | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-sort-p99 | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-sort-p99 | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-application-log-sort-p99 | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-application-log-sort-skewness | lines_read | N/A | 479,904 | N/A | N/A | ? |
| single-day-application-log-sort-skewness | lines_included | N/A | 479,904 | N/A | N/A | ? |
| single-day-application-log-sort-skewness | TIMING/read_files | N/A | 3.7 s | N/A | N/A | ? |
| single-day-application-log-sort-skewness | TIMING/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-sort-skewness | TIMING/group_similar | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-sort-skewness | TIMING/calculate_statistics | N/A | 7 ms | N/A | N/A | ? |
| single-day-application-log-sort-skewness | TIMING/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-sort-skewness | TIMING/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| single-day-application-log-sort-skewness | TIMING/normalize_data | N/A | 1 ms | N/A | N/A | ? |
| single-day-application-log-sort-skewness | TIMING/total | N/A | 3.8 s | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/rss_peak | N/A | 37.4 MB | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/log_analysis | N/A | 232 B | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/log_messages | N/A | 2.7 MB | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/log_occurrences | N/A | 21.8 KB | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/log_sessions | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/log_stats | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/message_key_order | N/A | 2.8 KB | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY/unattributed | N/A | 34.6 MB | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY_FINAL/log_messages | N/A | 2872100 | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-sort-skewness | COUNTS/log_messages_entries | N/A | 6512 | N/A | N/A | ? |
| single-day-application-log-sort-skewness | COUNTS/log_occurrences_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-sort-skewness | COUNTS/log_stats_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-sort-skewness | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-sort-skewness | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-sort-skewness | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-sort-skewness | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-application-log-sort-skewness | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY/message_key_order | N/A | 3.5 KB | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY/unattributed | N/A | 69.0 MB | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY/message_key_order | N/A | 6.5 KB | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY/unattributed | N/A | 69.2 MB | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/message_key_order | N/A | 5.7 KB | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/unattributed | N/A | 78.1 MB | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY/message_key_order | N/A | 3.5 KB | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY/unattributed | N/A | 69.3 MB | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY/message_key_order | N/A | 3.5 KB | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY/unattributed | N/A | 69 MB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY/message_key_order | N/A | 3.5 KB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY/unattributed | N/A | 69.2 MB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | N/A | 3 KB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/unattributed | N/A | 76.4 MB | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | lines_read | N/A | 930,031 | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | lines_included | N/A | 930,028 | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | TIMING/read_files | N/A | 7.8 s | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | TIMING/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | TIMING/group_similar | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | TIMING/calculate_statistics | N/A | 219 ms | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | TIMING/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | TIMING/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | TIMING/normalize_data | N/A | 1 ms | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | TIMING/total | N/A | 8.1 s | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/rss_peak | N/A | 114.4 MB | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/log_analysis | N/A | 232 B | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/log_messages | N/A | 45.8 MB | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/log_occurrences | N/A | 56.6 KB | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/log_sessions | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/log_stats | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/message_key_order | N/A | 3.5 KB | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY/unattributed | N/A | 68.6 MB | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/log_messages | N/A | 48030790 | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | COUNTS/log_messages_entries | N/A | 105902 | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | COUNTS/log_occurrences_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | COUNTS/log_stats_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | CONFIG/time_bucket_size | N/A | 480 | N/A | N/A | ? |
| multi-day-application-logs-sort-p99 | CONFIG/bucket_size_seconds | N/A | 28800.00 | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | lines_read | N/A | 930,031 | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | lines_included | N/A | 930,028 | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | TIMING/read_files | N/A | 7.9 s | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | TIMING/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | TIMING/group_similar | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | TIMING/calculate_statistics | N/A | 215 ms | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | TIMING/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | TIMING/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | TIMING/normalize_data | N/A | 1 ms | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | TIMING/total | N/A | 8.1 s | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/rss_peak | N/A | 114.3 MB | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/log_analysis | N/A | 232 B | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/log_messages | N/A | 45.8 MB | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/log_occurrences | N/A | 56.7 KB | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/log_sessions | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/log_stats | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/message_key_order | N/A | 3.5 KB | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY/unattributed | N/A | 68.5 MB | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/log_messages | N/A | 48030790 | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | COUNTS/log_messages_entries | N/A | 105902 | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | COUNTS/log_occurrences_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | COUNTS/log_stats_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | CONFIG/time_bucket_size | N/A | 480 | N/A | N/A | ? |
| multi-day-application-logs-sort-skewness | CONFIG/bucket_size_seconds | N/A | 28800.00 | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY/message_key_order | N/A | 19.8 KB | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY/unattributed | N/A | 61.9 MB | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY/message_key_order | N/A | 19.8 KB | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY/unattributed | N/A | 61.8 MB | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY/message_key_order | N/A | 6.1 KB | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY/unattributed | N/A | 22.5 MB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY/message_key_order | N/A | 19.8 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY/unattributed | N/A | 74.2 MB | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY/message_key_order | N/A | 19.8 KB | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY/unattributed | N/A | 61.4 MB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY/message_key_order | N/A | 19.8 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY/unattributed | N/A | 76.7 MB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | N/A | 2.7 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/unattributed | N/A | 34.1 MB | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | lines_read | N/A | 1,530,399 | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | lines_included | N/A | 1,530,399 | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | TIMING/read_files | N/A | 16.1 s | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | TIMING/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | TIMING/group_similar | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | TIMING/calculate_statistics | N/A | 274 ms | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | TIMING/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | TIMING/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | TIMING/normalize_data | N/A | 1 ms | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | TIMING/total | N/A | 16.4 s | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/rss_peak | N/A | 190.2 MB | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/log_analysis | N/A | 28.4 MB | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/log_messages | N/A | 102.5 MB | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/log_occurrences | N/A | 20.3 KB | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/log_sessions | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/log_stats | N/A | 39.8 KB | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/message_key_order | N/A | 2.7 KB | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY/unattributed | N/A | 59.2 MB | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/log_messages | N/A | 107471436 | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/log_analysis | N/A | 20342 | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | COUNTS/log_messages_entries | N/A | 182419 | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | COUNTS/log_occurrences_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | COUNTS/log_stats_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| multi-day-custom-logs-sort-p99 | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | lines_read | N/A | 1,530,399 | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | lines_included | N/A | 1,530,399 | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | TIMING/read_files | N/A | 16.1 s | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | TIMING/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | TIMING/group_similar | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | TIMING/calculate_statistics | N/A | 345 ms | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | TIMING/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | TIMING/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | TIMING/normalize_data | N/A | 1 ms | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | TIMING/total | N/A | 16.5 s | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/rss_peak | N/A | 192 MB | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/log_analysis | N/A | 28.4 MB | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/log_messages | N/A | 102.5 MB | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/log_occurrences | N/A | 20.3 KB | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/log_sessions | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/log_stats | N/A | 39.8 KB | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/message_key_order | N/A | 2.5 KB | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY/unattributed | N/A | 61 MB | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/log_messages | N/A | 107473201 | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/log_analysis | N/A | 20342 | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | COUNTS/log_messages_entries | N/A | 182419 | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | COUNTS/log_occurrences_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | COUNTS/log_stats_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| multi-day-custom-logs-sort-skewness | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY/message_key_order | N/A | 1.8 KB | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY/unattributed | N/A | 35.6 MB | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY/message_key_order | N/A | 3.9 KB | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY/unattributed | N/A | 36.1 MB | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY/message_key_order | N/A | 3.8 KB | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY/unattributed | N/A | 13.0 MB | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY/message_key_order | N/A | 1.8 KB | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY/unattributed | N/A | 60.5 MB | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY/message_key_order | N/A | 1.8 KB | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY/unattributed | N/A | 38.0 MB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY/message_key_order | N/A | 1.8 KB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY/unattributed | N/A | 61.5 MB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/message_key_order | N/A | 1.9 KB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/unattributed | N/A | 43.0 MB | N/A | N/A | ? |
| single-day-access-log-sort-p99 | lines_read | N/A | 761,698 | N/A | N/A | ? |
| single-day-access-log-sort-p99 | lines_included | N/A | 761,698 | N/A | N/A | ? |
| single-day-access-log-sort-p99 | TIMING/read_files | N/A | 11.1 s | N/A | N/A | ? |
| single-day-access-log-sort-p99 | TIMING/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-sort-p99 | TIMING/group_similar | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-sort-p99 | TIMING/calculate_statistics | N/A | 208 ms | N/A | N/A | ? |
| single-day-access-log-sort-p99 | TIMING/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-sort-p99 | TIMING/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-sort-p99 | TIMING/normalize_data | N/A | 1 ms | N/A | N/A | ? |
| single-day-access-log-sort-p99 | TIMING/total | N/A | 11.3 s | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/rss_peak | N/A | 143.3 MB | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/log_analysis | N/A | 52.7 MB | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/log_messages | N/A | 55.4 MB | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/log_occurrences | N/A | 18.4 KB | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/log_sessions | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/log_stats | N/A | 22.5 KB | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/message_key_order | N/A | 2.0 KB | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY/unattributed | N/A | 35.2 MB | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY_FINAL/log_messages | N/A | 58114072 | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY_FINAL/log_analysis | N/A | 6670 | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-sort-p99 | COUNTS/log_messages_entries | N/A | 3184 | N/A | N/A | ? |
| single-day-access-log-sort-p99 | COUNTS/log_occurrences_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-sort-p99 | COUNTS/log_stats_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-sort-p99 | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-sort-p99 | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| single-day-access-log-sort-p99 | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-sort-p99 | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-access-log-sort-p99 | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-access-log-sort-skewness | lines_read | N/A | 761,698 | N/A | N/A | ? |
| single-day-access-log-sort-skewness | lines_included | N/A | 761,698 | N/A | N/A | ? |
| single-day-access-log-sort-skewness | TIMING/read_files | N/A | 11.2 s | N/A | N/A | ? |
| single-day-access-log-sort-skewness | TIMING/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-sort-skewness | TIMING/group_similar | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-sort-skewness | TIMING/calculate_statistics | N/A | 333 ms | N/A | N/A | ? |
| single-day-access-log-sort-skewness | TIMING/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-sort-skewness | TIMING/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| single-day-access-log-sort-skewness | TIMING/normalize_data | N/A | 1 ms | N/A | N/A | ? |
| single-day-access-log-sort-skewness | TIMING/total | N/A | 11.5 s | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/rss_peak | N/A | 149.2 MB | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/log_analysis | N/A | 52.7 MB | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/log_messages | N/A | 55.4 MB | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/log_occurrences | N/A | 18.4 KB | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/log_sessions | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/log_stats | N/A | 22.5 KB | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/message_key_order | N/A | 1.9 KB | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY/unattributed | N/A | 41.1 MB | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY_FINAL/log_messages | N/A | 58116157 | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY_FINAL/log_analysis | N/A | 6670 | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-sort-skewness | COUNTS/log_messages_entries | N/A | 3184 | N/A | N/A | ? |
| single-day-access-log-sort-skewness | COUNTS/log_occurrences_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-sort-skewness | COUNTS/log_stats_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-sort-skewness | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-sort-skewness | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| single-day-access-log-sort-skewness | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-sort-skewness | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-access-log-sort-skewness | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| month-single-server-access-logs-standard | lines_read | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-standard | lines_included | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/read_files | N/A | 2 min | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/group_similar | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/calculate_statistics | N/A | 4.9 s | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/normalize_data | N/A | 2 ms | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/total | N/A | 2.1 min | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/rss_peak | N/A | 2.5 GB | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/log_analysis | N/A | 567.3 MB | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/log_messages | N/A | 1.6 GB | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/log_occurrences | N/A | 36.6 KB | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/log_sessions | N/A | 2.2 MB | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/log_stats | N/A | 43.6 KB | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/message_key_order | N/A | 2.2 KB | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/unattributed | N/A | 403.8 MB | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/log_messages | N/A | 1704450665 | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-standard | COUNTS/log_messages_entries | N/A | 1212275 | N/A | N/A | ? |
| month-single-server-access-logs-standard | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-standard | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-standard | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-standard | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| month-single-server-access-logs-standard | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-standard | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-single-server-access-logs-standard | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | lines_read | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | lines_included | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/read_files | N/A | 2.1 min | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/group_similar | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/calculate_statistics | N/A | 5.1 s | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/normalize_data | N/A | 2 ms | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/total | N/A | 2.1 min | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/rss_peak | N/A | 2.5 GB | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/log_analysis | N/A | 567.3 MB | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/log_messages | N/A | 1.6 GB | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/log_occurrences | N/A | 36.6 KB | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/log_sessions | N/A | 2.2 MB | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/log_stats | N/A | 43.6 KB | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/message_key_order | N/A | 4.7 KB | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/unattributed | N/A | 393.9 MB | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/log_messages | N/A | 1702548425 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | COUNTS/log_messages_entries | N/A | 1212275 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | lines_read | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | lines_included | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/read_files | N/A | 2.6 min | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/group_similar | N/A | 1.7 min | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/calculate_statistics | N/A | 7.1 s | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/normalize_data | N/A | 3 ms | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/total | N/A | 4.4 min | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | N/A | 1.6 GB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_clusters | N/A | 507.2 MB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_message | N/A | 2.5 MB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | N/A | 36.7 MB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | N/A | 29.4 MB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_ngram_index | N/A | 36.0 MB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_patterns | N/A | 283.0 KB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_posting_size | N/A | 973.6 KB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | N/A | 1.6 MB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_analysis | N/A | 567.4 MB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_messages | N/A | 567.0 MB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_occurrences | N/A | 36.6 KB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_sessions | N/A | 2.2 MB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_stats | N/A | 43.6 KB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/message_key_order | N/A | 4.2 KB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/unattributed | N/A | 0 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/log_messages | N/A | 594530097 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 531862951 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 248469 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 131128 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 424 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 65592 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 65592 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_messages_entries | N/A | 1317 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | lines_read | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | lines_included | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/read_files | N/A | 2.2 min | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/group_similar | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/calculate_statistics | N/A | 2.1 s | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/heatmap_statistics | N/A | 60 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/normalize_data | N/A | 2 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/total | N/A | 2.3 min | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/rss_peak | N/A | 2.1 GB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_counters | N/A | 2.4 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_counters_hl | N/A | 232 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_data | N/A | 83.6 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/log_analysis | N/A | 15.3 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/log_messages | N/A | 1.6 GB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/log_occurrences | N/A | 36.6 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/log_sessions | N/A | 2.2 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/log_stats | N/A | 29.6 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/message_key_order | N/A | 2.2 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/unattributed | N/A | 528.2 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/log_messages | N/A | 1704450545 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/log_analysis | N/A | 12594 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | COUNTS/log_messages_entries | N/A | 1212275 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | lines_read | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | lines_included | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/read_files | N/A | 2.4 min | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/group_similar | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/calculate_statistics | N/A | 4.9 s | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/histogram_statistics | N/A | 7 ms | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/normalize_data | N/A | 2 ms | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/total | N/A | 2.5 min | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/rss_peak | N/A | 2.5 GB | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/histogram_counters | N/A | 295.6 KB | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/log_analysis | N/A | 567.3 MB | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/log_messages | N/A | 1.6 GB | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/log_occurrences | N/A | 36.8 KB | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/log_sessions | N/A | 2.2 MB | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/log_stats | N/A | 43.6 KB | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/message_key_order | N/A | 2.2 KB | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/unattributed | N/A | 415.4 MB | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/log_messages | N/A | 1704450409 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | COUNTS/log_messages_entries | N/A | 1212275 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | lines_read | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | lines_included | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/read_files | N/A | 2.5 min | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/group_similar | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/calculate_statistics | N/A | 2 s | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/heatmap_statistics | N/A | 60 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/histogram_statistics | N/A | 7 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/normalize_data | N/A | 2 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/total | N/A | 2.6 min | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/rss_peak | N/A | 2 GB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_counters | N/A | 2.4 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | N/A | 232 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_data | N/A | 80.1 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_counters | N/A | 295.5 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_analysis | N/A | 15.3 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_messages | N/A | 1.5 GB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_occurrences | N/A | 36.6 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_sessions | N/A | 2.2 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_stats | N/A | 29.6 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/message_key_order | N/A | 2.2 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/unattributed | N/A | 532.6 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/log_messages | N/A | 1626865585 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | N/A | 12594 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | COUNTS/log_messages_entries | N/A | 1212275 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_read | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_included | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/read_files | N/A | 3.1 min | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/group_similar | N/A | 1.2 min | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | N/A | 2.8 s | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/heatmap_statistics | N/A | 58 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/histogram_statistics | N/A | 10 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/normalize_data | N/A | 3 ms | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | N/A | 4.4 min | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | N/A | 1.3 GB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | N/A | 507.2 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | N/A | 2.5 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | N/A | 36.7 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | N/A | 25.6 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | N/A | 36.0 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | N/A | 283.0 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | N/A | 973.6 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | N/A | 1.6 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | N/A | 2.4 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | N/A | 232 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | N/A | 80.1 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | N/A | 295.6 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | N/A | 15.3 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages | N/A | 567 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | N/A | 36.6 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | N/A | 2.2 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_stats | N/A | 29.6 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | N/A | 1.9 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/unattributed | N/A | 107.1 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | N/A | 594583729 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | N/A | 12594 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 531863079 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 248469 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 131128 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 424 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 65592 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 65592 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | N/A | 1317 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | lines_read | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | lines_included | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | TIMING/read_files | N/A | 2.1 min | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | TIMING/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | TIMING/group_similar | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | TIMING/calculate_statistics | N/A | 11.7 s | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | TIMING/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | TIMING/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | TIMING/normalize_data | N/A | 2 ms | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | TIMING/total | N/A | 2.3 min | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/rss_peak | N/A | 2.6 GB | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/log_analysis | N/A | 567.3 MB | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/log_messages | N/A | 1.6 GB | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/log_occurrences | N/A | 36.6 KB | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/log_sessions | N/A | 2.2 MB | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/log_stats | N/A | 43.6 KB | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/message_key_order | N/A | 2.2 KB | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY/unattributed | N/A | 448.8 MB | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/log_messages | N/A | 1702548945 | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | COUNTS/log_messages_entries | N/A | 1212275 | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-single-server-access-logs-sort-p99 | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | lines_read | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | lines_included | N/A | 7,749,167 | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | TIMING/read_files | N/A | 2.1 min | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | TIMING/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | TIMING/group_similar | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | TIMING/calculate_statistics | N/A | 7.1 s | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | TIMING/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | TIMING/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | TIMING/normalize_data | N/A | 2 ms | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | TIMING/total | N/A | 2.2 min | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/rss_peak | N/A | 2.5 GB | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/log_analysis | N/A | 567.3 MB | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/log_messages | N/A | 1.6 GB | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/log_occurrences | N/A | 36.6 KB | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/log_sessions | N/A | 2.2 MB | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/log_stats | N/A | 43.6 KB | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/message_key_order | N/A | 2.2 KB | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY/unattributed | N/A | 386.2 MB | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/log_messages | N/A | 1704463286 | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | COUNTS/log_messages_entries | N/A | 1212275 | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-single-server-access-logs-sort-skewness | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | lines_read | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | lines_included | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/read_files | N/A | 10.1 min | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/group_similar | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/calculate_statistics | N/A | 30.2 s | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/normalize_data | N/A | 3 ms | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/total | N/A | 10.7 min | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/rss_peak | N/A | 12.1 GB | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/log_analysis | N/A | 2.9 GB | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/log_messages | N/A | 8.2 GB | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/log_occurrences | N/A | 42.1 KB | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/log_sessions | N/A | 14.9 MB | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/log_stats | N/A | 44.1 KB | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/message_key_order | N/A | 2.2 KB | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/unattributed | N/A | 1.1 GB | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/log_messages | N/A | 8796591492 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | COUNTS/log_messages_entries | N/A | 6187253 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | lines_read | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | lines_included | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/read_files | N/A | 10.1 min | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/group_similar | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/calculate_statistics | N/A | 31.3 s | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/normalize_data | N/A | 3 ms | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/total | N/A | 10.6 min | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/rss_peak | N/A | 12.4 GB | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/log_analysis | N/A | 2.9 GB | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/log_messages | N/A | 8.2 GB | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/log_occurrences | N/A | 43.8 KB | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/log_sessions | N/A | 14.9 MB | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/log_stats | N/A | 44.1 KB | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/message_key_order | N/A | 4.7 KB | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/unattributed | N/A | 1.3 GB | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/log_messages | N/A | 8796602084 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | COUNTS/log_messages_entries | N/A | 6187253 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | lines_read | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | lines_included | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/read_files | N/A | 12.4 min | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/group_similar | N/A | 17.1 min | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/calculate_statistics | N/A | 39.3 s | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/normalize_data | N/A | 3 ms | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | N/A | 30.2 min | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | N/A | 6.7 GB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_clusters | N/A | 2.6 GB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_message | N/A | 2.5 MB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | N/A | 36.8 MB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | N/A | 29.5 MB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_ngram_index | N/A | 36.1 MB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_patterns | N/A | 531.3 KB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_posting_size | N/A | 1.2 MB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | N/A | 1.7 MB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_analysis | N/A | 2.9 GB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_messages | N/A | 2.9 GB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_occurrences | N/A | 43.8 KB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_sessions | N/A | 14.9 MB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_stats | N/A | 44.1 KB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/message_key_order | N/A | 4.2 KB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/unattributed | N/A | 0 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/log_messages | N/A | 3091525898 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 2834456928 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 544033 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 131128 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 424 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 65592 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 65592 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_messages_entries | N/A | 2549 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | lines_read | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | lines_included | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/read_files | N/A | 11.0 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/group_similar | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/calculate_statistics | N/A | 12.2 s | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/heatmap_statistics | N/A | 74 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/normalize_data | N/A | 2 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/total | N/A | 11.2 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/rss_peak | N/A | 9.9 GB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_counters | N/A | 2.7 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_counters_hl | N/A | 232 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_data | N/A | 81.1 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/log_analysis | N/A | 15.3 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/log_messages | N/A | 8.2 GB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/log_occurrences | N/A | 42.1 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/log_sessions | N/A | 14.9 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/log_stats | N/A | 29.6 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/message_key_order | N/A | 2.2 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/unattributed | N/A | 1.7 GB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/log_messages | N/A | 8801379964 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/log_analysis | N/A | 12594 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | COUNTS/log_messages_entries | N/A | 6187253 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | lines_read | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | lines_included | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/read_files | N/A | 12.0 min | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/group_similar | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/calculate_statistics | N/A | 29.2 s | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/histogram_statistics | N/A | 10 ms | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/normalize_data | N/A | 3 ms | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/total | N/A | 12.5 min | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/rss_peak | N/A | 12.4 GB | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/histogram_counters | N/A | 307.4 KB | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/log_analysis | N/A | 2.9 GB | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/log_messages | N/A | 8.2 GB | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/log_occurrences | N/A | 43.8 KB | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/log_sessions | N/A | 14.9 MB | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/log_stats | N/A | 44.1 KB | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/message_key_order | N/A | 2.2 KB | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/unattributed | N/A | 1.3 GB | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/log_messages | N/A | 8806439364 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | COUNTS/log_messages_entries | N/A | 6187253 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | lines_read | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | lines_included | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/read_files | N/A | 12.5 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/group_similar | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/calculate_statistics | N/A | 12.8 s | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/heatmap_statistics | N/A | 75 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/histogram_statistics | N/A | 9 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/normalize_data | N/A | 3 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/total | N/A | 12.8 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/rss_peak | N/A | 9.6 GB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_counters | N/A | 2.7 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | N/A | 232 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_data | N/A | 80.6 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_counters | N/A | 307.4 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_analysis | N/A | 15.3 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_messages | N/A | 7.8 GB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_occurrences | N/A | 42.1 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_sessions | N/A | 14.9 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_stats | N/A | 29.6 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/message_key_order | N/A | 2.2 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/unattributed | N/A | 1.8 GB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/log_messages | N/A | 8405396412 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | N/A | 12594 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/log_messages_entries | N/A | 6187253 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_read | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_included | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/read_files | N/A | 14.7 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/group_similar | N/A | 12.6 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | N/A | 14.8 s | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/heatmap_statistics | N/A | 69 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/histogram_statistics | N/A | 11 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/normalize_data | N/A | 3 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | N/A | 27.5 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | N/A | 4.6 GB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | N/A | 2.6 GB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | N/A | 2.5 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | N/A | 36.8 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | N/A | 29.4 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | N/A | 36.1 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | N/A | 531.2 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | N/A | 1.2 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | N/A | 1.7 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | N/A | 2.7 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | N/A | 232 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | N/A | 80.1 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | N/A | 307.4 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | N/A | 15.3 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages | N/A | 2.9 GB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | N/A | 43.8 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | N/A | 14.9 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_stats | N/A | 29.6 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/message_key_order | N/A | 1.9 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/unattributed | N/A | 0 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | N/A | 3093065866 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | N/A | 12594 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 2834892640 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 543905 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 131128 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 424 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 65592 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 65592 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | N/A | 2549 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | lines_read | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | lines_included | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | TIMING/read_files | N/A | 10.1 min | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | TIMING/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | TIMING/group_similar | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | TIMING/calculate_statistics | N/A | 1.2 min | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | TIMING/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | TIMING/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | TIMING/normalize_data | N/A | 3 ms | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | TIMING/total | N/A | 11.3 min | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/rss_peak | N/A | 12.7 GB | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_analysis | N/A | 2.9 GB | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_messages | N/A | 8.2 GB | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_occurrences | N/A | 42.1 KB | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_sessions | N/A | 14.9 MB | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_stats | N/A | 44.1 KB | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/message_key_order | N/A | 2.5 KB | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY/unattributed | N/A | 1.6 GB | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/log_messages | N/A | 8806472284 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | COUNTS/log_messages_entries | N/A | 6187253 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-p99 | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | lines_read | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | lines_included | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | TIMING/read_files | N/A | 10.1 min | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | TIMING/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | TIMING/group_similar | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | TIMING/calculate_statistics | N/A | 43.4 s | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | TIMING/heatmap_statistics | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | TIMING/histogram_statistics | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | TIMING/normalize_data | N/A | 2 ms | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | TIMING/total | N/A | 10.9 min | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/rss_peak | N/A | 12.4 GB | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_clusters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_key_message | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_patterns | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/consolidation_unmatched | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_data | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_raw | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/histogram_values | N/A | 576 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_analysis | N/A | 2.9 GB | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_messages | N/A | 8.2 GB | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_messages_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_occurrences | N/A | 43.8 KB | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_sessions | N/A | 14.9 MB | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_stats | N/A | 44.1 KB | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/message_key_order | N/A | 2.1 KB | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/udm_distinct | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY/unattributed | N/A | 1.3 GB | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/log_messages | N/A | 8796625985 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | COUNTS/log_messages_entries | N/A | 6187253 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-many-servers-access-logs-sort-skewness | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |

