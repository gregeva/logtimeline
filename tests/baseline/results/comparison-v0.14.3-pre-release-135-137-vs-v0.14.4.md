
## Benchmark Comparison

  Baseline:    v0.14.3-pre-release-135-137 (v0.14.3, 48 test cases)
  Current:     v0.14.4 (v0.14.3, 49 test cases)

### Timing Delta

| # | file selection | standard | top25 | top25-cons | heatmap | histogram | hm+hg | hm+hg+cons |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. | humungous-log-uniqueness | -3.7% | -3.9% | +158.9% | -4.8% | -4.3% | -5.5% | +165.7% |
| 2. | single-day-application-log | -2.9% | -1.2% | -72.8% | -8.3% | -4.3% | -6.7% | -72.4% |
| 3. | multi-day-application-logs | -1.2% | -2.6% | +149.7% | -4.3% | -2.7% | -2.7% | +156.6% |
| 4. | multi-day-custom-logs | -8.9% | -8.0% | +57.4% | -7.7% | -8.3% | -7.9% | +56.3% |
| 5. | single-day-access-log | -5.6% | -5.2% | -7.6% | -2.4% | -3.6% | -2.8% | -3.2% |
| 6. | month-single-server-access-logs | -3.8% | -5.0% | -96.6% | -4.1% | -4.2% | -4.3% | -95.7% |
| 7. | month-many-servers-access-logs | -7.1% | -6.3% | -97.9% | -7.1% | -12.3% | -11.0% | - |

### Memory Delta (RSS Peak)

| # | file selection | standard | top25 | top25-cons | heatmap | histogram | hm+hg | hm+hg+cons |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. | humungous-log-uniqueness | +10.4% | +9.6% | +93.5% | +11.0% | +10.3% | +10.4% | +95.1% |
| 2. | single-day-application-log | +8.4% | +6.9% | +96.6% | +8.4% | +6.9% | +8.5% | +97.0% |
| 3. | multi-day-application-logs | +72.9% | +74.1% | +83.1% | +73.5% | +73.5% | +70.4% | +83.2% |
| 4. | multi-day-custom-logs | +3.4% | +5.0% | +46.9% | +6.2% | +4.3% | +4.3% | +46.6% |
| 5. | single-day-access-log | -3.2% | -3.6% | -0.1% | -1.2% | -3.2% | -0.3% | +0.2% |
| 6. | month-single-server-access-logs | +23.0% | +23.1% | -46.3% | +23.9% | +12.9% | +13.6% | -28.0% |
| 7. | month-many-servers-access-logs | +31.5% | +25.4% | -38.9% | +26.5% | +62.1% | +58.7% | - |

### Summary

| test_name | metric | baseline | current | delta | change% | result |
| --- | --- | --- | --- | --- | --- | --- |
| humungous-log-uniqueness-standard | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/total | 2.8 s | 2.7 s | -103 ms | -3.7% | IMPROVE |
| humungous-log-uniqueness-standard | MEMORY/rss_peak | 173.6 MB | 191.7 MB | +18.1 MB | 10.4% | REGRESS |
| humungous-log-uniqueness-top25 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/total | 2.7 s | 2.6 s | -105 ms | -3.9% | IMPROVE |
| humungous-log-uniqueness-top25 | MEMORY/rss_peak | 175.2 MB | 192 MB | +16.9 MB | 9.6% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/total | 3.7 s | 9.7 s | +5.9 s | 158.9% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/rss_peak | 127 MB | 245.7 MB | +118.7 MB | 93.5% | REGRESS |
| humungous-log-uniqueness-heatmap | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/total | 2.7 s | 2.5 s | -127 ms | -4.8% | IMPROVE |
| humungous-log-uniqueness-heatmap | MEMORY/rss_peak | 173.3 MB | 192.3 MB | +19 MB | 11.0% | REGRESS |
| humungous-log-uniqueness-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/total | 2.6 s | 2.5 s | -112 ms | -4.3% | IMPROVE |
| humungous-log-uniqueness-histogram | MEMORY/rss_peak | 174.5 MB | 192.5 MB | +18 MB | 10.3% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/total | 2.7 s | 2.5 s | -148 ms | -5.5% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/rss_peak | 173.9 MB | 192.0 MB | +18 MB | 10.4% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/total | 3.7 s | 9.7 s | +6.1 s | 165.7% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/rss_peak | 126.2 MB | 246.3 MB | +120.1 MB | 95.1% | REGRESS |
| single-day-application-log-standard | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | TIMING/total | 3.6 s | 3.5 s | -107 ms | -2.9% | IMPROVE |
| single-day-application-log-standard | MEMORY/rss_peak | 30.2 MB | 32.7 MB | +2.5 MB | 8.4% | REGRESS |
| single-day-application-log-top25 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | TIMING/total | 3.6 s | 3.5 s | -43 ms | -1.2% | IMPROVE |
| single-day-application-log-top25 | MEMORY/rss_peak | 30.6 MB | 32.8 MB | +2.1 MB | 6.9% | REGRESS |
| single-day-application-log-top25-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/total | 22.4 s | 6.1 s | -16.3 s | -72.8% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/rss_peak | 61.6 MB | 121.1 MB | +59.5 MB | 96.6% | REGRESS |
| single-day-application-log-heatmap | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | TIMING/total | 3.8 s | 3.5 s | -316 ms | -8.3% | IMPROVE |
| single-day-application-log-heatmap | MEMORY/rss_peak | 30.2 MB | 32.7 MB | +2.5 MB | 8.4% | REGRESS |
| single-day-application-log-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | TIMING/total | 3.7 s | 3.5 s | -157 ms | -4.3% | IMPROVE |
| single-day-application-log-histogram | MEMORY/rss_peak | 30.6 MB | 32.7 MB | +2.1 MB | 6.9% | REGRESS |
| single-day-application-log-heatmap-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/total | 3.7 s | 3.5 s | -249 ms | -6.7% | IMPROVE |
| single-day-application-log-heatmap-histogram | MEMORY/rss_peak | 30.1 MB | 32.7 MB | +2.6 MB | 8.5% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/total | 22.8 s | 6.3 s | -16.5 s | -72.4% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 61.5 MB | 121.2 MB | +59.7 MB | 97.0% | REGRESS |
| multi-day-application-logs-standard | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-standard | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-standard | TIMING/total | 8 s | 7.9 s | -93 ms | -1.2% | IMPROVE |
| multi-day-application-logs-standard | MEMORY/rss_peak | 63.7 MB | 110.2 MB | +46.5 MB | 72.9% | REGRESS |
| multi-day-application-logs-top25 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/total | 8.0 s | 7.8 s | -211 ms | -2.6% | IMPROVE |
| multi-day-application-logs-top25 | MEMORY/rss_peak | 62.8 MB | 109.3 MB | +46.5 MB | 74.1% | REGRESS |
| multi-day-application-logs-top25-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/total | 15.6 s | 38.9 s | +23.3 s | 149.7% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | 121.8 MB | 222.9 MB | +101.2 MB | 83.1% | REGRESS |
| multi-day-application-logs-heatmap | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/total | 8.1 s | 7.7 s | -350 ms | -4.3% | IMPROVE |
| multi-day-application-logs-heatmap | MEMORY/rss_peak | 62.1 MB | 107.7 MB | +45.6 MB | 73.5% | REGRESS |
| multi-day-application-logs-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/total | 7.9 s | 7.7 s | -214 ms | -2.7% | IMPROVE |
| multi-day-application-logs-histogram | MEMORY/rss_peak | 62.2 MB | 108.0 MB | +45.7 MB | 73.5% | REGRESS |
| multi-day-application-logs-heatmap-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/total | 7.9 s | 7.7 s | -213 ms | -2.7% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | MEMORY/rss_peak | 63.3 MB | 107.8 MB | +44.5 MB | 70.4% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | 15.6 s | 39.9 s | +24.4 s | 156.6% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 122.4 MB | 224.2 MB | +101.8 MB | 83.2% | REGRESS |
| multi-day-custom-logs-standard | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/total | 17.3 s | 15.7 s | -1.5 s | -8.9% | IMPROVE |
| multi-day-custom-logs-standard | MEMORY/rss_peak | 191.2 MB | 197.6 MB | +6.4 MB | 3.4% | REGRESS |
| multi-day-custom-logs-top25 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/total | 17.2 s | 15.8 s | -1.4 s | -8.0% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/rss_peak | 188.2 MB | 197.6 MB | +9.5 MB | 5.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/total | 33.8 s | 53.2 s | +19.4 s | 57.4% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/rss_peak | 189.7 MB | 278.7 MB | +89.0 MB | 46.9% | REGRESS |
| multi-day-custom-logs-heatmap | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/total | 17.7 s | 16.4 s | -1.4 s | -7.7% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/rss_peak | 195.4 MB | 207.5 MB | +12.1 MB | 6.2% | REGRESS |
| multi-day-custom-logs-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/total | 18.4 s | 16.9 s | -1.5 s | -8.3% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/rss_peak | 230.9 MB | 240.9 MB | +10 MB | 4.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/total | 18.5 s | 17 s | -1.5 s | -7.9% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/rss_peak | 238.0 MB | 248.2 MB | +10.2 MB | 4.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/total | 35 s | 54.8 s | +19.7 s | 56.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 228 MB | 334.2 MB | +106.2 MB | 46.6% | REGRESS |
| single-day-access-log-standard | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | TIMING/total | 9.9 s | 9.3 s | -555 ms | -5.6% | IMPROVE |
| single-day-access-log-standard | MEMORY/rss_peak | 159.9 MB | 154.8 MB | -5.2 MB | -3.2% | IMPROVE |
| single-day-access-log-top25 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | TIMING/total | 9.9 s | 9.4 s | -515 ms | -5.2% | IMPROVE |
| single-day-access-log-top25 | MEMORY/rss_peak | 163.4 MB | 157.5 MB | -5.8 MB | -3.6% | IMPROVE |
| single-day-access-log-top25-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/total | 13.6 s | 12.6 s | -1 s | -7.6% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/rss_peak | 233 MB | 232.7 MB | -288 KB | -0.1% | IMPROVE |
| single-day-access-log-heatmap | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | TIMING/total | 10.5 s | 10.3 s | -252 ms | -2.4% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/rss_peak | 161.2 MB | 159.2 MB | -2.0 MB | -1.2% | IMPROVE |
| single-day-access-log-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | TIMING/total | 12.1 s | 11.6 s | -438 ms | -3.6% | IMPROVE |
| single-day-access-log-histogram | MEMORY/rss_peak | 296.3 MB | 286.9 MB | -9.4 MB | -3.2% | IMPROVE |
| single-day-access-log-heatmap-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/total | 12.7 s | 12.4 s | -356 ms | -2.8% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/rss_peak | 292.9 MB | 292.1 MB | -848 KB | -0.3% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/total | 16.6 s | 16.1 s | -540 ms | -3.2% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 337.4 MB | 338.0 MB | +592 KB | 0.2% | REGRESS |
| month-single-server-access-logs-standard | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/total | 1.9 min | 1.8 min | -4.4 s | -3.8% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/rss_peak | 2.2 GB | 2.7 GB | +516.7 MB | 23.0% | REGRESS |
| month-single-server-access-logs-top25 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/total | 1.9 min | 1.8 min | -5.8 s | -5.0% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY/rss_peak | 2.2 GB | 2.7 GB | +518.5 MB | 23.1% | REGRESS |
| month-single-server-access-logs-top25-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/total | 67.4 min | 2.3 min | -65.1 min | -96.6% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | 3.0 GB | 1.6 GB | -1.4 GB | -46.3% | IMPROVE |
| month-single-server-access-logs-heatmap | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/total | 2.1 min | 2 min | -5.2 s | -4.1% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/rss_peak | 2.2 GB | 2.8 GB | +542.9 MB | 23.9% | REGRESS |
| month-single-server-access-logs-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/total | 2.4 min | 2.3 min | -6.1 s | -4.2% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/rss_peak | 3.6 GB | 4 GB | +472.7 MB | 12.9% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/total | 2.6 min | 2.5 min | -6.7 s | -4.3% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/rss_peak | 3.6 GB | 4.1 GB | +503.3 MB | 13.6% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | 68 min | 2.9 min | -65.1 min | -95.7% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 4.4 GB | 3.1 GB | -1.2 GB | -28.0% | IMPROVE |
| month-many-servers-access-logs-standard | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | TIMING/total | 9.5 min | 8.9 min | -40.5 s | -7.1% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/rss_peak | 10 GB | 13.2 GB | +3.2 GB | 31.5% | REGRESS |
| month-many-servers-access-logs-top25 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | TIMING/total | 9.6 min | 8.9 min | -36.2 s | -6.3% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY/rss_peak | 10.2 GB | 12.8 GB | +2.6 GB | 25.4% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | 477.7 min | 10.3 min | -467.4 min | -97.9% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | 11.6 GB | 7.1 GB | -4.5 GB | -38.9% | IMPROVE |
| month-many-servers-access-logs-heatmap | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/total | 10.5 min | 9.8 min | -44.5 s | -7.1% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/rss_peak | 10.6 GB | 13.4 GB | +2.8 GB | 26.5% | REGRESS |
| month-many-servers-access-logs-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/total | 13.0 min | 11.4 min | -1.6 min | -12.3% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/rss_peak | 12 GB | 19.5 GB | +7.5 GB | 62.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/total | 13.8 min | 12.3 min | -1.5 min | -11.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/rss_peak | 13 GB | 20.7 GB | +7.7 GB | 58.7% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_read | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_included | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | N/A | 13.6 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | N/A | 15.3 GB | N/A | N/A | ? |

### Detailed

| test_name | metric | baseline | current | delta | change% | result |
| --- | --- | --- | --- | --- | --- | --- |
| humungous-log-uniqueness-standard | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/read_files | 2.4 s | 2.4 s | -46 ms | -1.9% | IMPROVE |
| humungous-log-uniqueness-standard | TIMING/calculate_statistics | 330 ms | 273 ms | -57 ms | -17.3% | IMPROVE |
| humungous-log-uniqueness-standard | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| humungous-log-uniqueness-standard | TIMING/total | 2.8 s | 2.7 s | -103 ms | -3.7% | IMPROVE |
| humungous-log-uniqueness-standard | MEMORY/rss_peak | 173.6 MB | 191.7 MB | +18.1 MB | 10.4% | REGRESS |
| humungous-log-uniqueness-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_messages | 105.1 MB | 123.2 MB | +18.1 MB | 17.2% | REGRESS |
| humungous-log-uniqueness-standard | MEMORY/log_occurrences | 2.8 KB | 4.5 KB | +1.7 KB | 59.3% | REGRESS |
| humungous-log-uniqueness-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/read_files | 2.4 s | 2.3 s | -79 ms | -3.3% | IMPROVE |
| humungous-log-uniqueness-top25 | TIMING/calculate_statistics | 301 ms | 275 ms | -26 ms | -8.6% | IMPROVE |
| humungous-log-uniqueness-top25 | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| humungous-log-uniqueness-top25 | TIMING/total | 2.7 s | 2.6 s | -105 ms | -3.9% | IMPROVE |
| humungous-log-uniqueness-top25 | MEMORY/rss_peak | 175.2 MB | 192 MB | +16.9 MB | 9.6% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_messages | 105.1 MB | 123.2 MB | +18.1 MB | 17.2% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY/log_occurrences | 2.8 KB | 4.5 KB | +1.7 KB | 59.3% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/read_files | 3.5 s | 6.0 s | +2.4 s | 69.2% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | TIMING/group_similar | 217 ms | 3.7 s | +3.5 s | 1615.7% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| humungous-log-uniqueness-top25-consolidate | TIMING/total | 3.7 s | 9.7 s | +5.9 s | 158.9% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/rss_peak | 127 MB | 245.7 MB | +118.7 MB | 93.5% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_clusters | 97.9 KB | 196.2 KB | +98.3 KB | 100.4% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_message | 86.6 KB | 129.7 KB | +43 KB | 49.7% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_patterns | 18.8 KB | 24.9 KB | +6.1 KB | 32.6% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_unmatched | 72.1 KB | 105.5 KB | +33.4 KB | 46.3% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_messages | 121.1 KB | 120.7 KB | -411 B | -0.3% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_occurrences | 2.8 KB | 4.5 KB | +1.7 KB | 59.3% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/read_files | 2.4 s | 2.3 s | -118 ms | -5.0% | IMPROVE |
| humungous-log-uniqueness-heatmap | TIMING/calculate_statistics | 283 ms | 273 ms | -10 ms | -3.5% | IMPROVE |
| humungous-log-uniqueness-heatmap | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| humungous-log-uniqueness-heatmap | TIMING/total | 2.7 s | 2.5 s | -127 ms | -4.8% | IMPROVE |
| humungous-log-uniqueness-heatmap | MEMORY/rss_peak | 173.3 MB | 192.3 MB | +19 MB | 11.0% | REGRESS |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_messages | 105.1 MB | 123.2 MB | +18.1 MB | 17.2% | REGRESS |
| humungous-log-uniqueness-heatmap | MEMORY/log_occurrences | 2.8 KB | 4.5 KB | +1.7 KB | 59.3% | REGRESS |
| humungous-log-uniqueness-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/read_files | 2.3 s | 2.2 s | -107 ms | -4.6% | IMPROVE |
| humungous-log-uniqueness-histogram | TIMING/calculate_statistics | 288 ms | 283 ms | -5 ms | -1.7% | IMPROVE |
| humungous-log-uniqueness-histogram | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| humungous-log-uniqueness-histogram | TIMING/total | 2.6 s | 2.5 s | -112 ms | -4.3% | IMPROVE |
| humungous-log-uniqueness-histogram | MEMORY/rss_peak | 174.5 MB | 192.5 MB | +18 MB | 10.3% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_messages | 105.1 MB | 123.2 MB | +18.1 MB | 17.2% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY/log_occurrences | 2.8 KB | 4.5 KB | +1.7 KB | 59.3% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/read_files | 2.4 s | 2.2 s | -138 ms | -5.8% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | TIMING/calculate_statistics | 282 ms | 273 ms | -9 ms | -3.2% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | TIMING/total | 2.7 s | 2.5 s | -148 ms | -5.5% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/rss_peak | 173.9 MB | 192.0 MB | +18 MB | 10.4% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_messages | 105.1 MB | 123.2 MB | +18.1 MB | 17.2% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_occurrences | 2.8 KB | 4.5 KB | +1.7 KB | 59.3% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/read_files | 3.5 s | 6 s | +2.6 s | 73.9% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/group_similar | 208 ms | 3.7 s | +3.5 s | 1693.3% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/total | 3.7 s | 9.7 s | +6.1 s | 165.7% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/rss_peak | 126.2 MB | 246.3 MB | +120.1 MB | 95.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 97.9 KB | 196.2 KB | +98.3 KB | 100.4% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 86.6 KB | 129.7 KB | +43 KB | 49.7% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 18.8 KB | 24.9 KB | +6.1 KB | 32.6% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 72 KB | 105.5 KB | +33.5 KB | 46.5% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_messages | 121.1 KB | 120.7 KB | -411 B | -0.3% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_occurrences | 2.8 KB | 4.5 KB | +1.7 KB | 59.3% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | TIMING/read_files | 3.6 s | 3.5 s | -112 ms | -3.1% | IMPROVE |
| single-day-application-log-standard | TIMING/calculate_statistics | 2 ms | 6 ms | +4 ms | 200.0% | REGRESS |
| single-day-application-log-standard | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| single-day-application-log-standard | TIMING/total | 3.6 s | 3.5 s | -107 ms | -2.9% | IMPROVE |
| single-day-application-log-standard | MEMORY/rss_peak | 30.2 MB | 32.7 MB | +2.5 MB | 8.4% | REGRESS |
| single-day-application-log-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_messages | 799.3 KB | 2.7 MB | +1.9 MB | 243.3% | REGRESS |
| single-day-application-log-standard | MEMORY/log_occurrences | 11.3 KB | 21.5 KB | +10.2 KB | 90.0% | REGRESS |
| single-day-application-log-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | TIMING/read_files | 3.6 s | 3.5 s | -47 ms | -1.3% | IMPROVE |
| single-day-application-log-top25 | TIMING/calculate_statistics | 2 ms | 6 ms | +4 ms | 200.0% | REGRESS |
| single-day-application-log-top25 | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| single-day-application-log-top25 | TIMING/total | 3.6 s | 3.5 s | -43 ms | -1.2% | IMPROVE |
| single-day-application-log-top25 | MEMORY/rss_peak | 30.6 MB | 32.8 MB | +2.1 MB | 6.9% | REGRESS |
| single-day-application-log-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_messages | 799.3 KB | 2.7 MB | +1.9 MB | 243.3% | REGRESS |
| single-day-application-log-top25 | MEMORY/log_occurrences | 11.5 KB | 21.8 KB | +10.3 KB | 90.1% | REGRESS |
| single-day-application-log-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/read_files | 12.7 s | 5.9 s | -6.8 s | -53.5% | IMPROVE |
| single-day-application-log-top25-consolidate | TIMING/group_similar | 9.7 s | 161 ms | -9.5 s | -98.3% | IMPROVE |
| single-day-application-log-top25-consolidate | TIMING/calculate_statistics | 1 ms | 0 us | -1 ms | -100.0% | IMPROVE |
| single-day-application-log-top25-consolidate | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/total | 22.4 s | 6.1 s | -16.3 s | -72.8% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/rss_peak | 61.6 MB | 121.1 MB | +59.5 MB | 96.6% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_clusters | 69.9 KB | 437.5 KB | +367.7 KB | 526.3% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_message | 607.5 KB | 117.8 KB | -489.6 KB | -80.6% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_patterns | 13.5 KB | 54.3 KB | +40.8 KB | 301.7% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_unmatched | 384.5 KB | 120 KB | -264.4 KB | -68.8% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_messages | 680.1 KB | 158.4 KB | -521.7 KB | -76.7% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/log_occurrences | 11.5 KB | 21.8 KB | +10.3 KB | 90.1% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | TIMING/read_files | 3.8 s | 3.5 s | -321 ms | -8.4% | IMPROVE |
| single-day-application-log-heatmap | TIMING/calculate_statistics | 2 ms | 6 ms | +4 ms | 200.0% | REGRESS |
| single-day-application-log-heatmap | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| single-day-application-log-heatmap | TIMING/total | 3.8 s | 3.5 s | -316 ms | -8.3% | IMPROVE |
| single-day-application-log-heatmap | MEMORY/rss_peak | 30.2 MB | 32.7 MB | +2.5 MB | 8.4% | REGRESS |
| single-day-application-log-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_messages | 799.3 KB | 2.7 MB | +1.9 MB | 243.3% | REGRESS |
| single-day-application-log-heatmap | MEMORY/log_occurrences | 11.3 KB | 21.8 KB | +10.5 KB | 92.2% | REGRESS |
| single-day-application-log-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | TIMING/read_files | 3.7 s | 3.5 s | -162 ms | -4.4% | IMPROVE |
| single-day-application-log-histogram | TIMING/calculate_statistics | 2 ms | 6 ms | +4 ms | 200.0% | REGRESS |
| single-day-application-log-histogram | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| single-day-application-log-histogram | TIMING/total | 3.7 s | 3.5 s | -157 ms | -4.3% | IMPROVE |
| single-day-application-log-histogram | MEMORY/rss_peak | 30.6 MB | 32.7 MB | +2.1 MB | 6.9% | REGRESS |
| single-day-application-log-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_messages | 799.3 KB | 2.7 MB | +1.9 MB | 243.3% | REGRESS |
| single-day-application-log-histogram | MEMORY/log_occurrences | 11.3 KB | 21.8 KB | +10.5 KB | 92.2% | REGRESS |
| single-day-application-log-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/read_files | 3.7 s | 3.5 s | -253 ms | -6.8% | IMPROVE |
| single-day-application-log-heatmap-histogram | TIMING/calculate_statistics | 2 ms | 6 ms | +4 ms | 200.0% | REGRESS |
| single-day-application-log-heatmap-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/total | 3.7 s | 3.5 s | -249 ms | -6.7% | IMPROVE |
| single-day-application-log-heatmap-histogram | MEMORY/rss_peak | 30.1 MB | 32.7 MB | +2.6 MB | 8.5% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_messages | 799.3 KB | 2.7 MB | +1.9 MB | 243.3% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/log_occurrences | 11.5 KB | 21.8 KB | +10.3 KB | 90.1% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/read_files | 12.9 s | 6.1 s | -6.8 s | -53.0% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/group_similar | 9.8 s | 196 ms | -9.7 s | -98.0% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/calculate_statistics | 1 ms | 0 us | -1 ms | -100.0% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/histogram_statistics | 2 ms | 0 us | -2 ms | -100.0% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/total | 22.8 s | 6.3 s | -16.5 s | -72.4% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 61.5 MB | 121.2 MB | +59.7 MB | 97.0% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 69.9 KB | 437.5 KB | +367.7 KB | 526.3% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 607.5 KB | 117.8 KB | -489.6 KB | -80.6% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 13.5 KB | 54.3 KB | +40.8 KB | 301.7% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 384.5 KB | 120 KB | -264.4 KB | -68.8% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_messages | 680.1 KB | 158.4 KB | -521.7 KB | -76.7% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_occurrences | 11.5 KB | 21.8 KB | +10.3 KB | 90.1% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-standard | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-standard | TIMING/read_files | 8.0 s | 7.8 s | -225 ms | -2.8% | IMPROVE |
| multi-day-application-logs-standard | TIMING/calculate_statistics | 38 ms | 169 ms | +131 ms | 344.7% | REGRESS |
| multi-day-application-logs-standard | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-standard | TIMING/total | 8 s | 7.9 s | -93 ms | -1.2% | IMPROVE |
| multi-day-application-logs-standard | MEMORY/rss_peak | 63.7 MB | 110.2 MB | +46.5 MB | 72.9% | REGRESS |
| multi-day-application-logs-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_messages | 8.8 MB | 44.5 MB | +35.7 MB | 407.3% | REGRESS |
| multi-day-application-logs-standard | MEMORY/log_occurrences | 56.6 KB | 56.6 KB | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/read_files | 8.0 s | 7.6 s | -340 ms | -4.3% | IMPROVE |
| multi-day-application-logs-top25 | TIMING/calculate_statistics | 35 ms | 164 ms | +129 ms | 368.6% | REGRESS |
| multi-day-application-logs-top25 | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/total | 8.0 s | 7.8 s | -211 ms | -2.6% | IMPROVE |
| multi-day-application-logs-top25 | MEMORY/rss_peak | 62.8 MB | 109.3 MB | +46.5 MB | 74.1% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_messages | 8.8 MB | 44.5 MB | +35.7 MB | 407.3% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/log_occurrences | 56.7 KB | 56.7 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/read_files | 14.1 s | 36.6 s | +22.5 s | 159.1% | REGRESS |
| multi-day-application-logs-top25-consolidate | TIMING/group_similar | 1.4 s | 2.3 s | +848 ms | 58.9% | REGRESS |
| multi-day-application-logs-top25-consolidate | TIMING/calculate_statistics | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/total | 15.6 s | 38.9 s | +23.3 s | 149.7% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | 121.8 MB | 222.9 MB | +101.2 MB | 83.1% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_clusters | 1.5 MB | 3.7 MB | +2.2 MB | 144.8% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_message | 406.6 KB | 466.3 KB | +59.7 KB | 14.7% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_patterns | 296 KB | 510.4 KB | +214.4 KB | 72.4% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_unmatched | 319.4 KB | 368.0 KB | +48.6 KB | 15.2% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_messages | 701.4 KB | 691.5 KB | -9.9 KB | -1.4% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/log_occurrences | 56.6 KB | 56.6 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/read_files | 8.1 s | 7.6 s | -486 ms | -6.0% | IMPROVE |
| multi-day-application-logs-heatmap | TIMING/calculate_statistics | 34 ms | 170 ms | +136 ms | 400.0% | REGRESS |
| multi-day-application-logs-heatmap | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/total | 8.1 s | 7.7 s | -350 ms | -4.3% | IMPROVE |
| multi-day-application-logs-heatmap | MEMORY/rss_peak | 62.1 MB | 107.7 MB | +45.6 MB | 73.5% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_messages | 8.8 MB | 44.5 MB | +35.7 MB | 407.3% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY/log_occurrences | 56.6 KB | 56.6 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/read_files | 7.9 s | 7.6 s | -350 ms | -4.4% | IMPROVE |
| multi-day-application-logs-histogram | TIMING/calculate_statistics | 34 ms | 169 ms | +135 ms | 397.1% | REGRESS |
| multi-day-application-logs-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/total | 7.9 s | 7.7 s | -214 ms | -2.7% | IMPROVE |
| multi-day-application-logs-histogram | MEMORY/rss_peak | 62.2 MB | 108.0 MB | +45.7 MB | 73.5% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_messages | 8.8 MB | 44.5 MB | +35.7 MB | 407.3% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/log_occurrences | 56.7 KB | 56.6 KB | -64 B | -0.1% | IMPROVE |
| multi-day-application-logs-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/read_files | 7.9 s | 7.5 s | -350 ms | -4.4% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | TIMING/calculate_statistics | 36 ms | 172 ms | +136 ms | 377.8% | REGRESS |
| multi-day-application-logs-heatmap-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/total | 7.9 s | 7.7 s | -213 ms | -2.7% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | MEMORY/rss_peak | 63.3 MB | 107.8 MB | +44.5 MB | 70.4% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_messages | 8.8 MB | 44.5 MB | +35.7 MB | 407.3% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_occurrences | 56.6 KB | 56.7 KB | +64 B | 0.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/read_files | 14.2 s | 37.6 s | +23.4 s | 165.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/group_similar | 1.4 s | 2.3 s | +966 ms | 69.9% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | 15.6 s | 39.9 s | +24.4 s | 156.6% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 122.4 MB | 224.2 MB | +101.8 MB | 83.2% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 1.5 MB | 3.7 MB | +2.2 MB | 144.8% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 406.6 KB | 466.3 KB | +59.7 KB | 14.7% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 296 KB | 510.4 KB | +214.4 KB | 72.4% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 319.4 KB | 368.0 KB | +48.6 KB | 15.2% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 701.4 KB | 691.5 KB | -9.9 KB | -1.4% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 56.6 KB | 56.6 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/read_files | 16.9 s | 15.4 s | -1.5 s | -9.1% | IMPROVE |
| multi-day-custom-logs-standard | TIMING/calculate_statistics | 391 ms | 390 ms | -1 ms | -0.3% | IMPROVE |
| multi-day-custom-logs-standard | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/total | 17.3 s | 15.7 s | -1.5 s | -8.9% | IMPROVE |
| multi-day-custom-logs-standard | MEMORY/rss_peak | 191.2 MB | 197.6 MB | +6.4 MB | 3.4% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_analysis | 28.2 MB | 28.4 MB | +240.1 KB | 0.8% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/log_messages | 91.9 MB | 103.3 MB | +11.4 MB | 12.4% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/log_occurrences | 10.8 KB | 20.3 KB | +9.5 KB | 87.9% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_stats | 30.1 KB | 54.7 KB | +24.6 KB | 81.9% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/read_files | 16.8 s | 15.4 s | -1.4 s | -8.3% | IMPROVE |
| multi-day-custom-logs-top25 | TIMING/calculate_statistics | 401 ms | 405 ms | +4 ms | 1.0% | REGRESS |
| multi-day-custom-logs-top25 | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/total | 17.2 s | 15.8 s | -1.4 s | -8.0% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/rss_peak | 188.2 MB | 197.6 MB | +9.5 MB | 5.0% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_analysis | 28.2 MB | 28.4 MB | +240.1 KB | 0.8% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/log_messages | 91.9 MB | 103.3 MB | +11.4 MB | 12.4% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/log_occurrences | 10.8 KB | 20.3 KB | +9.5 KB | 87.9% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_stats | 30.1 KB | 54.7 KB | +24.6 KB | 81.9% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/read_files | 29.3 s | 46.4 s | +17.2 s | 58.7% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/group_similar | 4.1 s | 6.5 s | +2.3 s | 56.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/calculate_statistics | 370 ms | 278 ms | -92 ms | -24.9% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/total | 33.8 s | 53.2 s | +19.4 s | 57.4% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/rss_peak | 189.7 MB | 278.7 MB | +89.0 MB | 46.9% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_clusters | 29 MB | 29.6 MB | +648.8 KB | 2.2% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_message | 172.7 KB | 386.1 KB | +213.4 KB | 123.5% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_patterns | 193.8 KB | 209.6 KB | +15.8 KB | 8.2% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_unmatched | 229.2 KB | 248.8 KB | +19.7 KB | 8.6% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_analysis | 28.2 MB | 28.4 MB | +240.1 KB | 0.8% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_messages | 28.7 MB | 28.6 MB | -65.6 KB | -0.2% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_occurrences | 10.8 KB | 20.3 KB | +9.5 KB | 87.9% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_stats | 30.1 KB | 54.7 KB | +24.6 KB | 81.9% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/read_files | 17 s | 15.7 s | -1.4 s | -8.1% | IMPROVE |
| multi-day-custom-logs-heatmap | TIMING/calculate_statistics | 293 ms | 313 ms | +20 ms | 6.8% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/heatmap_statistics | 418 ms | 401 ms | -17 ms | -4.1% | IMPROVE |
| multi-day-custom-logs-heatmap | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/total | 17.7 s | 16.4 s | -1.4 s | -7.7% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/rss_peak | 195.4 MB | 207.5 MB | +12.1 MB | 6.2% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_data | 26.4 KB | 43.6 KB | +17.2 KB | 65.4% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_raw | 28.2 MB | 28.4 MB | +233.2 KB | 0.8% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_analysis | 11.5 KB | 20.9 KB | +9.4 KB | 81.6% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/log_messages | 92.4 MB | 103.3 MB | +10.9 MB | 11.8% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/log_occurrences | 10.8 KB | 20.3 KB | +9.5 KB | 87.9% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_stats | 27.4 KB | 49.8 KB | +22.4 KB | 81.6% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/read_files | 17.4 s | 15.9 s | -1.5 s | -8.5% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/calculate_statistics | 430 ms | 404 ms | -26 ms | -6.0% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/histogram_statistics | 548 ms | 534 ms | -14 ms | -2.6% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/total | 18.4 s | 16.9 s | -1.5 s | -8.3% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/rss_peak | 230.9 MB | 240.9 MB | +10 MB | 4.3% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/histogram_values | 29.8 MB | 29.8 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_analysis | 28.2 MB | 28.4 MB | +240.1 KB | 0.8% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/log_messages | 91.9 MB | 103.8 MB | +11.9 MB | 12.9% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/log_occurrences | 10.8 KB | 20.3 KB | +9.5 KB | 87.9% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_stats | 30.1 KB | 54.7 KB | +24.6 KB | 81.9% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/read_files | 17.1 s | 15.8 s | -1.4 s | -8.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/calculate_statistics | 299 ms | 307 ms | +8 ms | 2.7% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | TIMING/heatmap_statistics | 435 ms | 406 ms | -29 ms | -6.7% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/histogram_statistics | 593 ms | 529 ms | -64 ms | -10.8% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/total | 18.5 s | 17 s | -1.5 s | -7.9% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/rss_peak | 238.0 MB | 248.2 MB | +10.2 MB | 4.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_data | 27.5 KB | 42.7 KB | +15.2 KB | 55.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_raw | 28.2 MB | 28.4 MB | +233.2 KB | 0.8% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_values | 29.8 MB | 29.8 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_analysis | 11.5 KB | 20.9 KB | +9.4 KB | 81.6% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_messages | 91.9 MB | 103.3 MB | +11.4 MB | 12.4% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_occurrences | 10.8 KB | 20.3 KB | +9.5 KB | 87.9% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_stats | 27.4 KB | 49.8 KB | +22.4 KB | 81.6% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/read_files | 29.4 s | 47.1 s | +17.6 s | 59.9% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/group_similar | 4.2 s | 6.4 s | +2.2 s | 52.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | 163 ms | 159 ms | -4 ms | -2.5% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/heatmap_statistics | 565 ms | 483 ms | -82 ms | -14.5% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/histogram_statistics | 687 ms | 666 ms | -21 ms | -3.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/total | 35 s | 54.8 s | +19.7 s | 56.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 228 MB | 334.2 MB | +106.2 MB | 46.6% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 29 MB | 29.6 MB | +648.7 KB | 2.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 172.7 KB | 386.1 KB | +213.4 KB | 123.5% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 193.8 KB | 209.5 KB | +15.8 KB | 8.1% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 229.2 KB | 248.8 KB | +19.7 KB | 8.6% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 27.4 KB | 40.0 KB | +12.6 KB | 46.1% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 28.2 MB | 28.4 MB | +233.3 KB | 0.8% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 29.8 MB | 29.8 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 11.4 KB | 20.9 KB | +9.5 KB | 83.6% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 28.7 MB | 28.6 MB | -63.5 KB | -0.2% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 10.7 KB | 20.3 KB | +9.6 KB | 90.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 27.3 KB | 49.8 KB | +22.5 KB | 82.4% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | TIMING/read_files | 9.6 s | 9.1 s | -534 ms | -5.5% | IMPROVE |
| single-day-access-log-standard | TIMING/calculate_statistics | 233 ms | 212 ms | -21 ms | -9.0% | IMPROVE |
| single-day-access-log-standard | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| single-day-access-log-standard | TIMING/total | 9.9 s | 9.3 s | -555 ms | -5.6% | IMPROVE |
| single-day-access-log-standard | MEMORY/rss_peak | 159.9 MB | 154.8 MB | -5.2 MB | -3.2% | IMPROVE |
| single-day-access-log-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_analysis | 53.2 MB | 52.7 MB | -562.7 KB | -1.0% | IMPROVE |
| single-day-access-log-standard | MEMORY/log_messages | 55.3 MB | 55.5 MB | +198.6 KB | 0.4% | REGRESS |
| single-day-access-log-standard | MEMORY/log_occurrences | 10.1 KB | 18.4 KB | +8.3 KB | 82.6% | REGRESS |
| single-day-access-log-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_stats | 17.3 KB | 31.6 KB | +14.3 KB | 82.5% | REGRESS |
| single-day-access-log-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | TIMING/read_files | 9.7 s | 9.2 s | -475 ms | -4.9% | IMPROVE |
| single-day-access-log-top25 | TIMING/calculate_statistics | 263 ms | 223 ms | -40 ms | -15.2% | IMPROVE |
| single-day-access-log-top25 | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| single-day-access-log-top25 | TIMING/total | 9.9 s | 9.4 s | -515 ms | -5.2% | IMPROVE |
| single-day-access-log-top25 | MEMORY/rss_peak | 163.4 MB | 157.5 MB | -5.8 MB | -3.6% | IMPROVE |
| single-day-access-log-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_analysis | 53.2 MB | 52.7 MB | -562.7 KB | -1.0% | IMPROVE |
| single-day-access-log-top25 | MEMORY/log_messages | 55.5 MB | 55.5 MB | +191 B | 0.0% | REGRESS |
| single-day-access-log-top25 | MEMORY/log_occurrences | 10.1 KB | 18.4 KB | +8.3 KB | 82.6% | REGRESS |
| single-day-access-log-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_stats | 17.3 KB | 31.6 KB | +14.3 KB | 82.5% | REGRESS |
| single-day-access-log-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/read_files | 11.3 s | 10.5 s | -772 ms | -6.8% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/group_similar | 1.9 s | 1.8 s | -164 ms | -8.5% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/calculate_statistics | 431 ms | 328 ms | -103 ms | -23.9% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/total | 13.6 s | 12.6 s | -1 s | -7.6% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/rss_peak | 233 MB | 232.7 MB | -288 KB | -0.1% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_clusters | 48.7 MB | 48.7 MB | -268 B | -0.0% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_message | 464 KB | 465.1 KB | +1.1 KB | 0.2% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_patterns | 132.2 KB | 131.5 KB | -621 B | -0.5% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_unmatched | 316.9 KB | 317.6 KB | +647 B | 0.2% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_analysis | 53.2 MB | 52.7 MB | -562.7 KB | -1.0% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/log_messages | 53.5 MB | 53.5 MB | +3.6 KB | 0.0% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/log_occurrences | 10.1 KB | 18.4 KB | +8.3 KB | 82.6% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_stats | 17.3 KB | 31.6 KB | +14.3 KB | 82.5% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | TIMING/read_files | 9.9 s | 9.6 s | -242 ms | -2.5% | IMPROVE |
| single-day-access-log-heatmap | TIMING/calculate_statistics | 65 ms | 62 ms | -3 ms | -4.6% | IMPROVE |
| single-day-access-log-heatmap | TIMING/heatmap_statistics | 584 ms | 577 ms | -7 ms | -1.2% | IMPROVE |
| single-day-access-log-heatmap | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap | TIMING/total | 10.5 s | 10.3 s | -252 ms | -2.4% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/rss_peak | 161.2 MB | 159.2 MB | -2.0 MB | -1.2% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_data | 19.6 KB | 34 KB | +14.4 KB | 73.6% | REGRESS |
| single-day-access-log-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_raw | 39.8 MB | 39.9 MB | +97.3 KB | 0.2% | REGRESS |
| single-day-access-log-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_analysis | 4.4 KB | 8.1 KB | +3.7 KB | 85.0% | REGRESS |
| single-day-access-log-heatmap | MEMORY/log_messages | 55.5 MB | 55.5 MB | -6.7 KB | -0.0% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/log_occurrences | 10 KB | 18.4 KB | +8.4 KB | 83.7% | REGRESS |
| single-day-access-log-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_stats | 15.6 KB | 28.5 KB | +12.9 KB | 82.5% | REGRESS |
| single-day-access-log-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | TIMING/read_files | 10.2 s | 9.8 s | -370 ms | -3.6% | IMPROVE |
| single-day-access-log-histogram | TIMING/calculate_statistics | 273 ms | 235 ms | -38 ms | -13.9% | IMPROVE |
| single-day-access-log-histogram | TIMING/histogram_statistics | 1.6 s | 1.6 s | -31 ms | -2.0% | IMPROVE |
| single-day-access-log-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/total | 12.1 s | 11.6 s | -438 ms | -3.6% | IMPROVE |
| single-day-access-log-histogram | MEMORY/rss_peak | 296.3 MB | 286.9 MB | -9.4 MB | -3.2% | IMPROVE |
| single-day-access-log-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/histogram_values | 90.1 MB | 90.1 MB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_analysis | 53.2 MB | 52.7 MB | -562.7 KB | -1.0% | IMPROVE |
| single-day-access-log-histogram | MEMORY/log_messages | 55.5 MB | 55.5 MB | +7.1 KB | 0.0% | REGRESS |
| single-day-access-log-histogram | MEMORY/log_occurrences | 10.1 KB | 18.4 KB | +8.3 KB | 82.6% | REGRESS |
| single-day-access-log-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_stats | 17.3 KB | 31.6 KB | +14.3 KB | 82.5% | REGRESS |
| single-day-access-log-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/read_files | 10.4 s | 10.1 s | -307 ms | -2.9% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/calculate_statistics | 71 ms | 65 ms | -6 ms | -8.5% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/heatmap_statistics | 620 ms | 601 ms | -19 ms | -3.1% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/histogram_statistics | 1.6 s | 1.6 s | -24 ms | -1.5% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| single-day-access-log-heatmap-histogram | TIMING/total | 12.7 s | 12.4 s | -356 ms | -2.8% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/rss_peak | 292.9 MB | 292.1 MB | -848 KB | -0.3% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_data | 19.6 KB | 34 KB | +14.4 KB | 73.6% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_raw | 39.8 MB | 39.9 MB | +97.2 KB | 0.2% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_values | 90.1 MB | 90.1 MB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_analysis | 4.4 KB | 8.1 KB | +3.7 KB | 82.4% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/log_messages | 55.5 MB | 55.3 MB | -198.2 KB | -0.3% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/log_occurrences | 10.1 KB | 18.4 KB | +8.3 KB | 82.6% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_stats | 15.7 KB | 28.5 KB | +12.8 KB | 81.8% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/read_files | 11.9 s | 11.5 s | -410 ms | -3.4% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/group_similar | 2.0 s | 1.9 s | -36 ms | -1.8% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/calculate_statistics | 377 ms | 355 ms | -22 ms | -5.8% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/heatmap_statistics | 731 ms | 677 ms | -54 ms | -7.4% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/histogram_statistics | 1.6 s | 1.6 s | -20 ms | -1.2% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/total | 16.6 s | 16.1 s | -540 ms | -3.2% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 337.4 MB | 338.0 MB | +592 KB | 0.2% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 49.9 MB | 49.9 MB | -268 B | -0.0% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 464 KB | 465.1 KB | +1.1 KB | 0.2% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 132.2 KB | 131.5 KB | -621 B | -0.5% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 316.9 KB | 317.5 KB | +583 B | 0.2% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_data | 19.6 KB | 34 KB | +14.4 KB | 73.6% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 39.8 MB | 39.9 MB | +97.2 KB | 0.2% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_values | 90.1 MB | 90.1 MB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_analysis | 4.4 KB | 8.1 KB | +3.7 KB | 82.4% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_messages | 54.7 MB | 54.7 MB | -5.4 KB | -0.0% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_occurrences | 10.1 KB | 18.4 KB | +8.3 KB | 82.6% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_stats | 15.7 KB | 28.5 KB | +12.8 KB | 81.8% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/read_files | 1.8 min | 1.7 min | -4.5 s | -4.1% | IMPROVE |
| month-single-server-access-logs-standard | TIMING/calculate_statistics | 5.5 s | 5.6 s | +91 ms | 1.7% | REGRESS |
| month-single-server-access-logs-standard | TIMING/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/total | 1.9 min | 1.8 min | -4.4 s | -3.8% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/rss_peak | 2.2 GB | 2.7 GB | +516.7 MB | 23.0% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_analysis | 567.3 MB | 567.3 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_messages | 1.2 GB | 1.6 GB | +439.1 MB | 36.2% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/log_occurrences | 36.8 KB | 36.8 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_stats | 60.0 KB | 60.0 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/read_files | 1.8 min | 1.7 min | -5.6 s | -5.1% | IMPROVE |
| month-single-server-access-logs-top25 | TIMING/calculate_statistics | 5.8 s | 5.7 s | -183 ms | -3.1% | IMPROVE |
| month-single-server-access-logs-top25 | TIMING/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/total | 1.9 min | 1.8 min | -5.8 s | -5.0% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY/rss_peak | 2.2 GB | 2.7 GB | +518.5 MB | 23.1% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_analysis | 567.3 MB | 567.3 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_messages | 1.2 GB | 1.6 GB | +439.1 MB | 36.2% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/log_occurrences | 36.8 KB | 36.6 KB | -192 B | -0.5% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_stats | 60.0 KB | 60.0 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/read_files | 2.8 min | 2.2 min | -35.4 s | -21.4% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | TIMING/group_similar | 64.5 min | 4 ms | -64.5 min | -100.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | TIMING/calculate_statistics | 6.7 s | 5.8 s | -919 ms | -13.7% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | TIMING/normalize_data | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | TIMING/total | 67.4 min | 2.3 min | -65.1 min | -96.6% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | 3.0 GB | 1.6 GB | -1.4 GB | -46.3% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_clusters | 5.6 MB | 250.8 MB | +245.2 MB | 4390.6% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_message | 236.4 MB | 149.4 KB | -236.3 MB | -99.9% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_patterns | 71.6 KB | 225.8 KB | +154.2 KB | 215.4% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | 150.6 MB | 198.5 KB | -150.4 MB | -99.9% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_analysis | 567.3 MB | 567.4 MB | +121.6 KB | 0.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_messages | 1.2 GB | 573.9 MB | -637.7 MB | -52.6% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_occurrences | 36.6 KB | 36.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_stats | 60.0 KB | 60.0 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/read_files | 1.9 min | 1.8 min | -5.0 s | -4.4% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/calculate_statistics | 2.1 s | 2.1 s | -20 ms | -0.9% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/heatmap_statistics | 13.3 s | 13.1 s | -209 ms | -1.6% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/normalize_data | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/total | 2.1 min | 2 min | -5.2 s | -4.1% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/rss_peak | 2.2 GB | 2.8 GB | +542.9 MB | 23.9% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_data | 78.4 KB | 77.4 KB | -1 KB | -1.3% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_raw | 563.6 MB | 563.6 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_analysis | 15.7 KB | 15.7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_messages | 1.2 GB | 1.6 GB | +440.9 MB | 36.4% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/log_occurrences | 36.6 KB | 36.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_stats | 54.1 KB | 54.1 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/read_files | 1.9 min | 1.8 min | -5.7 s | -4.9% | IMPROVE |
| month-single-server-access-logs-histogram | TIMING/calculate_statistics | 6.1 s | 6.1 s | +56 ms | 0.9% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/histogram_statistics | 23.6 s | 23.2 s | -421 ms | -1.8% | IMPROVE |
| month-single-server-access-logs-histogram | TIMING/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/total | 2.4 min | 2.3 min | -6.1 s | -4.2% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/rss_peak | 3.6 GB | 4 GB | +472.7 MB | 12.9% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/histogram_values | 1.1 GB | 1.1 GB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_analysis | 567.3 MB | 567.3 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_messages | 1.2 GB | 1.6 GB | +439.1 MB | 36.2% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/log_occurrences | 36.6 KB | 36.8 KB | +192 B | 0.5% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_stats | 60.0 KB | 60.0 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/read_files | 2.0 min | 1.9 min | -5.7 s | -4.9% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/calculate_statistics | 2.1 s | 2.2 s | +114 ms | 5.4% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/heatmap_statistics | 13.8 s | 13.4 s | -402 ms | -2.9% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/histogram_statistics | 23.6 s | 22.9 s | -698 ms | -3.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/normalize_data | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/total | 2.6 min | 2.5 min | -6.7 s | -4.3% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/rss_peak | 3.6 GB | 4.1 GB | +503.3 MB | 13.6% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_data | 75.4 KB | 76.4 KB | +1 KB | 1.3% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_raw | 563.6 MB | 563.6 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_values | 1.1 GB | 1.1 GB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_analysis | 15.7 KB | 15.7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_messages | 1.2 GB | 1.6 GB | +440.9 MB | 36.4% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_occurrences | 36.6 KB | 36.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_stats | 54.1 KB | 54.1 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/read_files | 2.9 min | 2.3 min | -37.8 s | -21.7% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/group_similar | 64.4 min | 5 ms | -64.4 min | -100.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | 2.5 s | 1.6 s | -820 ms | -33.2% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/heatmap_statistics | 14.6 s | 13.6 s | -1 s | -6.9% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/histogram_statistics | 24.5 s | 23.1 s | -1.3 s | -5.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/normalize_data | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | 68 min | 2.9 min | -65.1 min | -95.7% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 4.4 GB | 3.1 GB | -1.2 GB | -28.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 5.6 MB | 251.2 MB | +245.7 MB | 4399.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 236.4 MB | 149.4 KB | -236.3 MB | -99.9% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 71.6 KB | 225.8 KB | +154.2 KB | 215.4% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 150.6 MB | 198.3 KB | -150.4 MB | -99.9% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 77.9 KB | 77.9 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 563.6 MB | 563.7 MB | +121.6 KB | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 1.1 GB | 1.1 GB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 15.7 KB | 15.7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 1.2 GB | 574.3 MB | -637.3 MB | -52.6% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 36.8 KB | 36.6 KB | -192 B | -0.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 2.2 MB | 2.2 MB | -128 B | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 54.1 KB | 54.1 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | TIMING/read_files | 9.1 min | 8.3 min | -43.6 s | -8.0% | IMPROVE |
| month-many-servers-access-logs-standard | TIMING/calculate_statistics | 29 s | 32.1 s | +3.1 s | 10.6% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/normalize_data | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/total | 9.5 min | 8.9 min | -40.5 s | -7.1% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/rss_peak | 10 GB | 13.2 GB | +3.2 GB | 31.5% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_analysis | 2.9 GB | 2.9 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_messages | 6 GB | 8.3 GB | +2.3 GB | 38.5% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY/log_occurrences | 43.8 KB | 43.8 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_sessions | 14.9 MB | 14.9 MB | +128 B | 0.0% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY/log_stats | 60.1 KB | 60.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | TIMING/read_files | 9.0 min | 8.4 min | -34.0 s | -6.3% | IMPROVE |
| month-many-servers-access-logs-top25 | TIMING/calculate_statistics | 35.6 s | 33.3 s | -2.2 s | -6.2% | IMPROVE |
| month-many-servers-access-logs-top25 | TIMING/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-top25 | TIMING/total | 9.6 min | 8.9 min | -36.2 s | -6.3% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY/rss_peak | 10.2 GB | 12.8 GB | +2.6 GB | 25.4% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_analysis | 2.9 GB | 2.9 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_messages | 6 GB | 8.0 GB | +2.0 GB | 32.6% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_stats | 60.1 KB | 60.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/read_files | 10.7 min | 9.8 min | -55.1 s | -8.6% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/group_similar | 466.3 min | 7 ms | -466.3 min | -100.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/calculate_statistics | 37 s | 28.4 s | -8.6 s | -23.2% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | 477.7 min | 10.3 min | -467.4 min | -97.9% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | 11.6 GB | 7.1 GB | -4.5 GB | -38.9% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_clusters | 31.0 MB | 1.2 GB | +1.1 GB | 3737.3% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_message | 1.1 GB | 144.1 KB | -1.1 GB | -100.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_patterns | 133.8 KB | 373.8 KB | +240.0 KB | 179.4% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | 735.8 MB | 276.4 KB | -735.5 MB | -100.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_analysis | 2.9 GB | 2.9 GB | +7.4 MB | 0.3% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_messages | 6 GB | 2.9 GB | -3.1 GB | -51.6% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_occurrences | 42.1 KB | 43.8 KB | +1.8 KB | 4.2% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -32 KB | -0.2% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_stats | 60.1 KB | 60.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/read_files | 9.3 min | 8.5 min | -45.2 s | -8.1% | IMPROVE |
| month-many-servers-access-logs-heatmap | TIMING/calculate_statistics | 10.4 s | 12.6 s | +2.1 s | 20.6% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/heatmap_statistics | 1.1 min | 1.1 min | -1.4 s | -2.2% | IMPROVE |
| month-many-servers-access-logs-heatmap | TIMING/normalize_data | 2 ms | 5 ms | +3 ms | 150.0% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/total | 10.5 min | 9.8 min | -44.5 s | -7.1% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/rss_peak | 10.6 GB | 13.4 GB | +2.8 GB | 26.5% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_data | 76.8 KB | 75.3 KB | -1.5 KB | -2.0% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_raw | 2.9 GB | 2.9 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_analysis | 15.7 KB | 15.7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_messages | 6 GB | 8.3 GB | +2.3 GB | 38.7% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/log_occurrences | 43.8 KB | 42.1 KB | -1.8 KB | -4.0% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_stats | 54.1 KB | 54.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/read_files | 9.5 min | 8.8 min | -39.1 s | -6.9% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/calculate_statistics | 42.3 s | 35.9 s | -6.4 s | -15.2% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/histogram_statistics | 2.8 min | 2.0 min | -50.4 s | -30.1% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/normalize_data | 4 ms | 3 ms | -1 ms | -25.0% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/total | 13.0 min | 11.4 min | -1.6 min | -12.3% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/rss_peak | 12 GB | 19.5 GB | +7.5 GB | 62.1% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/histogram_values | 5.4 GB | 5.4 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_analysis | 2.9 GB | 2.9 GB | +1.6 MB | 0.1% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/log_messages | 6 GB | 8.3 GB | +2.3 GB | 38.7% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_stats | 60.1 KB | 60.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/read_files | 9.6 min | 9 min | -37.9 s | -6.6% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/calculate_statistics | 14.1 s | 12.5 s | -1.5 s | -10.8% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/heatmap_statistics | 1.2 min | 1.1 min | -4.3 s | -6.1% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/histogram_statistics | 2.7 min | 1.9 min | -47.7 s | -29.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/normalize_data | 4 ms | 3 ms | -1 ms | -25.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/total | 13.8 min | 12.3 min | -1.5 min | -11.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/rss_peak | 13 GB | 20.7 GB | +7.7 GB | 58.7% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_data | 75.3 KB | 75.3 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_raw | 2.9 GB | 2.9 GB | +1.6 MB | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_values | 5.4 GB | 5.4 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_analysis | 15.7 KB | 15.7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_messages | 6 GB | 8.0 GB | +1.9 GB | 32.4% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_occurrences | 43.8 KB | 42.1 KB | -1.8 KB | -4.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_stats | 54.1 KB | 54.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_read | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_included | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/read_files | N/A | 10.4 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/group_similar | N/A | 8 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | N/A | 7.7 s | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/heatmap_statistics | N/A | 1.1 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/histogram_statistics | N/A | 1.9 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/normalize_data | N/A | 3 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | N/A | 13.6 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | N/A | 15.3 GB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | N/A | 1.2 GB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | N/A | 144.1 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | N/A | 373.8 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | N/A | 276.4 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | N/A | 76.3 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | N/A | 2.9 GB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | N/A | 5.4 GB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | N/A | 15.7 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages | N/A | 2.9 GB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | N/A | 42.1 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | N/A | 14.9 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_stats | N/A | 54.1 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | N/A | 232 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | N/A | 762 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | N/A | 120 B | N/A | N/A | ? |

