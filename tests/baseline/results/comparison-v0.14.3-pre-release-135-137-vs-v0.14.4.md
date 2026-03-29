
## Benchmark Comparison

  Baseline:    v0.14.3-pre-release-135-137 (v0.14.3, 48 test cases)
  Current:     v0.14.4 (v0.14.4, 49 test cases)

### Timing Delta

| # | file selection | standard | top25 | top25-cons | heatmap | histogram | hm+hg | hm+hg+cons |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. | humungous-log-uniqueness | -3.4% | -0.9% | +177.0% | +1.7% | +0.9% | +1.1% | +182.9% |
| 2. | single-day-application-log | -0.5% | -0.2% | -72.0% | -5.0% | -1.6% | -5.4% | -72.5% |
| 3. | multi-day-application-logs | -0.8% | -2.0% | +153.6% | -3.9% | -3.7% | -1.6% | +141.2% |
| 4. | multi-day-custom-logs | -7.1% | -7.4% | +49.5% | -7.3% | -7.6% | -6.3% | +45.3% |
| 5. | single-day-access-log | -5.6% | -6.4% | -15.9% | -6.0% | -5.9% | -5.4% | -13.1% |
| 6. | month-single-server-access-logs | -5.3% | -5.2% | -96.5% | -6.0% | -5.5% | -5.3% | -95.6% |
| 7. | month-many-servers-access-logs | -6.0% | -5.5% | -97.7% | -5.7% | -11.7% | -10.9% | - |

### Memory Delta (RSS Peak)

| # | file selection | standard | top25 | top25-cons | heatmap | histogram | hm+hg | hm+hg+cons |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. | humungous-log-uniqueness | +15.6% | +14.3% | +93.6% | +15.5% | +14.4% | +15.8% | +94.9% |
| 2. | single-day-application-log | +9.9% | +7.0% | +98.5% | +9.5% | +8.1% | +9.9% | +97.2% |
| 3. | multi-day-application-logs | +77.4% | +78.9% | +84.9% | +78.2% | +77.8% | +75.1% | +82.4% |
| 4. | multi-day-custom-logs | +4.0% | +5.7% | +31.7% | +5.9% | +5.2% | +4.9% | +26.9% |
| 5. | single-day-access-log | -3.9% | -5.1% | -17.9% | -0.9% | -3.4% | -0.1% | -1.8% |
| 6. | month-single-server-access-logs | +22.8% | +19.8% | -44.6% | +23.7% | +13.2% | +13.6% | -25.4% |
| 7. | month-many-servers-access-logs | +31.8% | +28.6% | -40.9% | +26.0% | +71.0% | +47.9% | - |

### Summary

| test_name | metric | baseline | current | delta | change% | result |
| --- | --- | --- | --- | --- | --- | --- |
| humungous-log-uniqueness-standard | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/total | 2.8 s | 2.7 s | -94 ms | -3.4% | IMPROVE |
| humungous-log-uniqueness-standard | MEMORY/rss_peak | 173.6 MB | 200.7 MB | +27.1 MB | 15.6% | REGRESS |
| humungous-log-uniqueness-top25 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/total | 2.7 s | 2.7 s | -24 ms | -0.9% | IMPROVE |
| humungous-log-uniqueness-top25 | MEMORY/rss_peak | 175.2 MB | 200.3 MB | +25.1 MB | 14.3% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/total | 3.7 s | 10.4 s | +6.6 s | 177.0% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/rss_peak | 127 MB | 245.9 MB | +118.9 MB | 93.6% | REGRESS |
| humungous-log-uniqueness-heatmap | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/total | 2.7 s | 2.7 s | +46 ms | 1.7% | REGRESS |
| humungous-log-uniqueness-heatmap | MEMORY/rss_peak | 173.3 MB | 200.2 MB | +26.9 MB | 15.5% | REGRESS |
| humungous-log-uniqueness-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/total | 2.6 s | 2.6 s | +24 ms | 0.9% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY/rss_peak | 174.5 MB | 199.7 MB | +25.2 MB | 14.4% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/total | 2.7 s | 2.7 s | +30 ms | 1.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/rss_peak | 173.9 MB | 201.4 MB | +27.5 MB | 15.8% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/total | 3.7 s | 10.4 s | +6.7 s | 182.9% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/rss_peak | 126.2 MB | 246.1 MB | +119.8 MB | 94.9% | REGRESS |
| single-day-application-log-standard | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | TIMING/total | 3.6 s | 3.6 s | -17 ms | -0.5% | IMPROVE |
| single-day-application-log-standard | MEMORY/rss_peak | 30.2 MB | 33.2 MB | +3 MB | 9.9% | REGRESS |
| single-day-application-log-top25 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | TIMING/total | 3.6 s | 3.6 s | -7 ms | -0.2% | IMPROVE |
| single-day-application-log-top25 | MEMORY/rss_peak | 30.6 MB | 32.8 MB | +2.2 MB | 7.0% | REGRESS |
| single-day-application-log-top25-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/total | 22.4 s | 6.3 s | -16.1 s | -72.0% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/rss_peak | 61.6 MB | 122.3 MB | +60.7 MB | 98.5% | REGRESS |
| single-day-application-log-heatmap | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | TIMING/total | 3.8 s | 3.6 s | -192 ms | -5.0% | IMPROVE |
| single-day-application-log-heatmap | MEMORY/rss_peak | 30.2 MB | 33.1 MB | +2.9 MB | 9.5% | REGRESS |
| single-day-application-log-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | TIMING/total | 3.7 s | 3.6 s | -59 ms | -1.6% | IMPROVE |
| single-day-application-log-histogram | MEMORY/rss_peak | 30.6 MB | 33.1 MB | +2.5 MB | 8.1% | REGRESS |
| single-day-application-log-heatmap-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/total | 3.7 s | 3.5 s | -201 ms | -5.4% | IMPROVE |
| single-day-application-log-heatmap-histogram | MEMORY/rss_peak | 30.1 MB | 33.1 MB | +3.0 MB | 9.9% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/total | 22.8 s | 6.3 s | -16.5 s | -72.5% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 61.5 MB | 121.4 MB | +59.8 MB | 97.2% | REGRESS |
| multi-day-application-logs-standard | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-standard | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-standard | TIMING/total | 8 s | 8.0 s | -65 ms | -0.8% | IMPROVE |
| multi-day-application-logs-standard | MEMORY/rss_peak | 63.7 MB | 113.1 MB | +49.3 MB | 77.4% | REGRESS |
| multi-day-application-logs-top25 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/total | 8.0 s | 7.8 s | -159 ms | -2.0% | IMPROVE |
| multi-day-application-logs-top25 | MEMORY/rss_peak | 62.8 MB | 112.3 MB | +49.6 MB | 78.9% | REGRESS |
| multi-day-application-logs-top25-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/total | 15.6 s | 39.5 s | +23.9 s | 153.6% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | 121.8 MB | 225.2 MB | +103.4 MB | 84.9% | REGRESS |
| multi-day-application-logs-heatmap | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/total | 8.1 s | 7.8 s | -313 ms | -3.9% | IMPROVE |
| multi-day-application-logs-heatmap | MEMORY/rss_peak | 62.1 MB | 110.7 MB | +48.6 MB | 78.2% | REGRESS |
| multi-day-application-logs-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/total | 7.9 s | 7.7 s | -292 ms | -3.7% | IMPROVE |
| multi-day-application-logs-histogram | MEMORY/rss_peak | 62.2 MB | 110.6 MB | +48.4 MB | 77.8% | REGRESS |
| multi-day-application-logs-heatmap-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/total | 7.9 s | 7.8 s | -130 ms | -1.6% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | MEMORY/rss_peak | 63.3 MB | 110.8 MB | +47.5 MB | 75.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | 15.6 s | 37.5 s | +22.0 s | 141.2% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 122.4 MB | 223.2 MB | +100.9 MB | 82.4% | REGRESS |
| multi-day-custom-logs-standard | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/total | 17.3 s | 16.1 s | -1.2 s | -7.1% | IMPROVE |
| multi-day-custom-logs-standard | MEMORY/rss_peak | 191.2 MB | 198.8 MB | +7.6 MB | 4.0% | REGRESS |
| multi-day-custom-logs-top25 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/total | 17.2 s | 15.9 s | -1.3 s | -7.4% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/rss_peak | 188.2 MB | 198.9 MB | +10.7 MB | 5.7% | REGRESS |
| multi-day-custom-logs-top25-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/total | 33.8 s | 50.5 s | +16.7 s | 49.5% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/rss_peak | 189.7 MB | 249.8 MB | +60.1 MB | 31.7% | REGRESS |
| multi-day-custom-logs-heatmap | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/total | 17.7 s | 16.4 s | -1.3 s | -7.3% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/rss_peak | 195.4 MB | 206.9 MB | +11.5 MB | 5.9% | REGRESS |
| multi-day-custom-logs-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/total | 18.4 s | 17.0 s | -1.4 s | -7.6% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/rss_peak | 230.9 MB | 243.0 MB | +12.1 MB | 5.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/total | 18.5 s | 17.3 s | -1.2 s | -6.3% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/rss_peak | 238.0 MB | 249.7 MB | +11.7 MB | 4.9% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/total | 35 s | 50.9 s | +15.9 s | 45.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 228 MB | 289.4 MB | +61.4 MB | 26.9% | REGRESS |
| single-day-access-log-standard | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | TIMING/total | 9.9 s | 9.3 s | -554 ms | -5.6% | IMPROVE |
| single-day-access-log-standard | MEMORY/rss_peak | 159.9 MB | 153.7 MB | -6.2 MB | -3.9% | IMPROVE |
| single-day-access-log-top25 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | TIMING/total | 9.9 s | 9.3 s | -637 ms | -6.4% | IMPROVE |
| single-day-access-log-top25 | MEMORY/rss_peak | 163.4 MB | 155.1 MB | -8.3 MB | -5.1% | IMPROVE |
| single-day-access-log-top25-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/total | 13.6 s | 11.5 s | -2.2 s | -15.9% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/rss_peak | 233 MB | 191.3 MB | -41.7 MB | -17.9% | IMPROVE |
| single-day-access-log-heatmap | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | TIMING/total | 10.5 s | 9.9 s | -636 ms | -6.0% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/rss_peak | 161.2 MB | 159.8 MB | -1.4 MB | -0.9% | IMPROVE |
| single-day-access-log-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | TIMING/total | 12.1 s | 11.4 s | -713 ms | -5.9% | IMPROVE |
| single-day-access-log-histogram | MEMORY/rss_peak | 296.3 MB | 286.3 MB | -10 MB | -3.4% | IMPROVE |
| single-day-access-log-heatmap-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/total | 12.7 s | 12 s | -684 ms | -5.4% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/rss_peak | 292.9 MB | 292.5 MB | -384 KB | -0.1% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/total | 16.6 s | 14.4 s | -2.2 s | -13.1% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 337.4 MB | 331.3 MB | -6.1 MB | -1.8% | IMPROVE |
| month-single-server-access-logs-standard | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/total | 1.9 min | 1.8 min | -6.1 s | -5.3% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/rss_peak | 2.2 GB | 2.7 GB | +513.2 MB | 22.8% | REGRESS |
| month-single-server-access-logs-top25 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/total | 1.9 min | 1.8 min | -6.0 s | -5.2% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY/rss_peak | 2.2 GB | 2.6 GB | +444.4 MB | 19.8% | REGRESS |
| month-single-server-access-logs-top25-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/total | 67.4 min | 2.4 min | -65 min | -96.5% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | 3.0 GB | 1.7 GB | -1.3 GB | -44.6% | IMPROVE |
| month-single-server-access-logs-heatmap | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/total | 2.1 min | 2 min | -7.6 s | -6.0% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/rss_peak | 2.2 GB | 2.7 GB | +538.1 MB | 23.7% | REGRESS |
| month-single-server-access-logs-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/total | 2.4 min | 2.3 min | -7.9 s | -5.5% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/rss_peak | 3.6 GB | 4 GB | +482.4 MB | 13.2% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/total | 2.6 min | 2.5 min | -8.3 s | -5.3% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/rss_peak | 3.6 GB | 4.1 GB | +502.7 MB | 13.6% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | 68 min | 3 min | -65 min | -95.6% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 4.4 GB | 3.2 GB | -1.1 GB | -25.4% | IMPROVE |
| month-many-servers-access-logs-standard | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | TIMING/total | 9.5 min | 9.0 min | -34.3 s | -6.0% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/rss_peak | 10 GB | 13.2 GB | +3.2 GB | 31.8% | REGRESS |
| month-many-servers-access-logs-top25 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | TIMING/total | 9.6 min | 9 min | -31.4 s | -5.5% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY/rss_peak | 10.2 GB | 13.2 GB | +2.9 GB | 28.6% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | 477.7 min | 10.9 min | -466.7 min | -97.7% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | 11.6 GB | 6.8 GB | -4.7 GB | -40.9% | IMPROVE |
| month-many-servers-access-logs-heatmap | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/total | 10.5 min | 9.9 min | -36.2 s | -5.7% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/rss_peak | 10.6 GB | 13.3 GB | +2.8 GB | 26.0% | REGRESS |
| month-many-servers-access-logs-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/total | 13.0 min | 11.4 min | -1.5 min | -11.7% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/rss_peak | 12 GB | 20.5 GB | +8.5 GB | 71.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/total | 13.8 min | 12.3 min | -1.5 min | -10.9% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/rss_peak | 13 GB | 19.3 GB | +6.2 GB | 47.9% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_read | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_included | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | N/A | 14.3 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | N/A | 15.6 GB | N/A | N/A | ? |

### Detailed

| test_name | metric | baseline | current | delta | change% | result |
| --- | --- | --- | --- | --- | --- | --- |
| humungous-log-uniqueness-standard | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/read_files | 2.4 s | 2.4 s | -68 ms | -2.8% | IMPROVE |
| humungous-log-uniqueness-standard | TIMING/calculate_statistics | 330 ms | 303 ms | -27 ms | -8.2% | IMPROVE |
| humungous-log-uniqueness-standard | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| humungous-log-uniqueness-standard | TIMING/total | 2.8 s | 2.7 s | -94 ms | -3.4% | IMPROVE |
| humungous-log-uniqueness-standard | MEMORY/rss_peak | 173.6 MB | 200.7 MB | +27.1 MB | 15.6% | REGRESS |
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
| humungous-log-uniqueness-standard | MEMORY/log_messages | 105.1 MB | 127 MB | +21.9 MB | 20.8% | REGRESS |
| humungous-log-uniqueness-standard | MEMORY/log_occurrences | 2.8 KB | 4.5 KB | +1.7 KB | 59.3% | REGRESS |
| humungous-log-uniqueness-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/read_files | 2.4 s | 2.4 s | +10 ms | 0.4% | REGRESS |
| humungous-log-uniqueness-top25 | TIMING/calculate_statistics | 301 ms | 266 ms | -35 ms | -11.6% | IMPROVE |
| humungous-log-uniqueness-top25 | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| humungous-log-uniqueness-top25 | TIMING/total | 2.7 s | 2.7 s | -24 ms | -0.9% | IMPROVE |
| humungous-log-uniqueness-top25 | MEMORY/rss_peak | 175.2 MB | 200.3 MB | +25.1 MB | 14.3% | REGRESS |
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
| humungous-log-uniqueness-top25 | MEMORY/log_messages | 105.1 MB | 127 MB | +21.9 MB | 20.8% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY/log_occurrences | 2.8 KB | 4.5 KB | +1.7 KB | 59.3% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/read_files | 3.5 s | 6.4 s | +2.8 s | 80.6% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | TIMING/group_similar | 217 ms | 4 s | +3.8 s | 1743.3% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| humungous-log-uniqueness-top25-consolidate | TIMING/total | 3.7 s | 10.4 s | +6.6 s | 177.0% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/rss_peak | 127 MB | 245.9 MB | +118.9 MB | 93.6% | REGRESS |
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
| humungous-log-uniqueness-heatmap | TIMING/read_files | 2.4 s | 2.4 s | -3 ms | -0.1% | IMPROVE |
| humungous-log-uniqueness-heatmap | TIMING/calculate_statistics | 283 ms | 332 ms | +49 ms | 17.3% | REGRESS |
| humungous-log-uniqueness-heatmap | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| humungous-log-uniqueness-heatmap | TIMING/total | 2.7 s | 2.7 s | +46 ms | 1.7% | REGRESS |
| humungous-log-uniqueness-heatmap | MEMORY/rss_peak | 173.3 MB | 200.2 MB | +26.9 MB | 15.5% | REGRESS |
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
| humungous-log-uniqueness-heatmap | MEMORY/log_messages | 105.1 MB | 127 MB | +21.9 MB | 20.8% | REGRESS |
| humungous-log-uniqueness-heatmap | MEMORY/log_occurrences | 2.8 KB | 4.5 KB | +1.7 KB | 59.3% | REGRESS |
| humungous-log-uniqueness-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/read_files | 2.3 s | 2.4 s | +25 ms | 1.1% | REGRESS |
| humungous-log-uniqueness-histogram | TIMING/calculate_statistics | 288 ms | 286 ms | -2 ms | -0.7% | IMPROVE |
| humungous-log-uniqueness-histogram | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| humungous-log-uniqueness-histogram | TIMING/total | 2.6 s | 2.6 s | +24 ms | 0.9% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY/rss_peak | 174.5 MB | 199.7 MB | +25.2 MB | 14.4% | REGRESS |
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
| humungous-log-uniqueness-histogram | MEMORY/log_messages | 105.1 MB | 127 MB | +21.9 MB | 20.8% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY/log_occurrences | 2.8 KB | 4.5 KB | +1.7 KB | 59.3% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/read_files | 2.4 s | 2.4 s | +28 ms | 1.2% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | TIMING/calculate_statistics | 282 ms | 284 ms | +2 ms | 0.7% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | TIMING/total | 2.7 s | 2.7 s | +30 ms | 1.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/rss_peak | 173.9 MB | 201.4 MB | +27.5 MB | 15.8% | REGRESS |
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
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_messages | 105.1 MB | 127 MB | +21.9 MB | 20.8% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_occurrences | 2.8 KB | 4.5 KB | +1.7 KB | 59.3% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/read_files | 3.5 s | 6.2 s | +2.8 s | 80.0% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/group_similar | 208 ms | 4.1 s | +3.9 s | 1894.7% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/total | 3.7 s | 10.4 s | +6.7 s | 182.9% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/rss_peak | 126.2 MB | 246.1 MB | +119.8 MB | 94.9% | REGRESS |
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
| single-day-application-log-standard | TIMING/read_files | 3.6 s | 3.6 s | -22 ms | -0.6% | IMPROVE |
| single-day-application-log-standard | TIMING/calculate_statistics | 2 ms | 6 ms | +4 ms | 200.0% | REGRESS |
| single-day-application-log-standard | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| single-day-application-log-standard | TIMING/total | 3.6 s | 3.6 s | -17 ms | -0.5% | IMPROVE |
| single-day-application-log-standard | MEMORY/rss_peak | 30.2 MB | 33.2 MB | +3 MB | 9.9% | REGRESS |
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
| single-day-application-log-standard | MEMORY/log_messages | 799.3 KB | 2.7 MB | +2.0 MB | 250.9% | REGRESS |
| single-day-application-log-standard | MEMORY/log_occurrences | 11.3 KB | 21.8 KB | +10.5 KB | 92.2% | REGRESS |
| single-day-application-log-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | TIMING/read_files | 3.6 s | 3.6 s | -13 ms | -0.4% | IMPROVE |
| single-day-application-log-top25 | TIMING/calculate_statistics | 2 ms | 7 ms | +5 ms | 250.0% | REGRESS |
| single-day-application-log-top25 | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| single-day-application-log-top25 | TIMING/total | 3.6 s | 3.6 s | -7 ms | -0.2% | IMPROVE |
| single-day-application-log-top25 | MEMORY/rss_peak | 30.6 MB | 32.8 MB | +2.2 MB | 7.0% | REGRESS |
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
| single-day-application-log-top25 | MEMORY/log_messages | 799.3 KB | 2.7 MB | +2.0 MB | 250.9% | REGRESS |
| single-day-application-log-top25 | MEMORY/log_occurrences | 11.5 KB | 21.8 KB | +10.3 KB | 90.1% | REGRESS |
| single-day-application-log-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/read_files | 12.7 s | 6.1 s | -6.7 s | -52.2% | IMPROVE |
| single-day-application-log-top25-consolidate | TIMING/group_similar | 9.7 s | 182 ms | -9.5 s | -98.1% | IMPROVE |
| single-day-application-log-top25-consolidate | TIMING/calculate_statistics | 1 ms | 0 us | -1 ms | -100.0% | IMPROVE |
| single-day-application-log-top25-consolidate | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/total | 22.4 s | 6.3 s | -16.1 s | -72.0% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/rss_peak | 61.6 MB | 122.3 MB | +60.7 MB | 98.5% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_clusters | 69.9 KB | 437.5 KB | +367.6 KB | 526.2% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_message | 607.5 KB | 97.5 KB | -510 KB | -84.0% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_patterns | 13.5 KB | 54.3 KB | +40.8 KB | 301.4% | REGRESS |
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
| single-day-application-log-heatmap | TIMING/read_files | 3.8 s | 3.6 s | -197 ms | -5.2% | IMPROVE |
| single-day-application-log-heatmap | TIMING/calculate_statistics | 2 ms | 6 ms | +4 ms | 200.0% | REGRESS |
| single-day-application-log-heatmap | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| single-day-application-log-heatmap | TIMING/total | 3.8 s | 3.6 s | -192 ms | -5.0% | IMPROVE |
| single-day-application-log-heatmap | MEMORY/rss_peak | 30.2 MB | 33.1 MB | +2.9 MB | 9.5% | REGRESS |
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
| single-day-application-log-heatmap | MEMORY/log_messages | 799.3 KB | 2.7 MB | +2.0 MB | 250.9% | REGRESS |
| single-day-application-log-heatmap | MEMORY/log_occurrences | 11.3 KB | 21.8 KB | +10.5 KB | 92.2% | REGRESS |
| single-day-application-log-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | TIMING/read_files | 3.7 s | 3.6 s | -64 ms | -1.8% | IMPROVE |
| single-day-application-log-histogram | TIMING/calculate_statistics | 2 ms | 6 ms | +4 ms | 200.0% | REGRESS |
| single-day-application-log-histogram | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| single-day-application-log-histogram | TIMING/total | 3.7 s | 3.6 s | -59 ms | -1.6% | IMPROVE |
| single-day-application-log-histogram | MEMORY/rss_peak | 30.6 MB | 33.1 MB | +2.5 MB | 8.1% | REGRESS |
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
| single-day-application-log-histogram | MEMORY/log_messages | 799.3 KB | 2.7 MB | +2.0 MB | 250.9% | REGRESS |
| single-day-application-log-histogram | MEMORY/log_occurrences | 11.3 KB | 21.8 KB | +10.5 KB | 92.2% | REGRESS |
| single-day-application-log-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/read_files | 3.7 s | 3.5 s | -205 ms | -5.5% | IMPROVE |
| single-day-application-log-heatmap-histogram | TIMING/calculate_statistics | 2 ms | 6 ms | +4 ms | 200.0% | REGRESS |
| single-day-application-log-heatmap-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/total | 3.7 s | 3.5 s | -201 ms | -5.4% | IMPROVE |
| single-day-application-log-heatmap-histogram | MEMORY/rss_peak | 30.1 MB | 33.1 MB | +3.0 MB | 9.9% | REGRESS |
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
| single-day-application-log-heatmap-histogram | MEMORY/log_messages | 799.3 KB | 2.7 MB | +2.0 MB | 250.9% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/log_occurrences | 11.5 KB | 21.8 KB | +10.3 KB | 90.1% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/read_files | 12.9 s | 6.1 s | -6.8 s | -52.8% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/group_similar | 9.8 s | 167 ms | -9.7 s | -98.3% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/calculate_statistics | 1 ms | 0 us | -1 ms | -100.0% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/histogram_statistics | 2 ms | 0 us | -2 ms | -100.0% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/total | 22.8 s | 6.3 s | -16.5 s | -72.5% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 61.5 MB | 121.4 MB | +59.8 MB | 97.2% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 69.9 KB | 437.3 KB | +367.4 KB | 525.9% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 607.5 KB | 97.5 KB | -510 KB | -84.0% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 13.5 KB | 54.4 KB | +40.8 KB | 302.0% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 384.5 KB | 120 KB | -264.4 KB | -68.8% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_messages | 680.1 KB | 158.4 KB | -521.7 KB | -76.7% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_occurrences | 11.5 KB | 21.5 KB | +10.1 KB | 87.9% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-standard | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-standard | TIMING/read_files | 8.0 s | 7.8 s | -226 ms | -2.8% | IMPROVE |
| multi-day-application-logs-standard | TIMING/calculate_statistics | 38 ms | 199 ms | +161 ms | 423.7% | REGRESS |
| multi-day-application-logs-standard | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-standard | TIMING/total | 8 s | 8.0 s | -65 ms | -0.8% | IMPROVE |
| multi-day-application-logs-standard | MEMORY/rss_peak | 63.7 MB | 113.1 MB | +49.3 MB | 77.4% | REGRESS |
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
| multi-day-application-logs-standard | MEMORY/log_messages | 8.8 MB | 45.8 MB | +37 MB | 422.0% | REGRESS |
| multi-day-application-logs-standard | MEMORY/log_occurrences | 56.6 KB | 56.7 KB | +64 B | 0.1% | REGRESS |
| multi-day-application-logs-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/read_files | 8.0 s | 7.7 s | -305 ms | -3.8% | IMPROVE |
| multi-day-application-logs-top25 | TIMING/calculate_statistics | 35 ms | 181 ms | +146 ms | 417.1% | REGRESS |
| multi-day-application-logs-top25 | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/total | 8.0 s | 7.8 s | -159 ms | -2.0% | IMPROVE |
| multi-day-application-logs-top25 | MEMORY/rss_peak | 62.8 MB | 112.3 MB | +49.6 MB | 78.9% | REGRESS |
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
| multi-day-application-logs-top25 | MEMORY/log_messages | 8.8 MB | 45.8 MB | +37 MB | 422.0% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/log_occurrences | 56.7 KB | 56.7 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/read_files | 14.1 s | 37.2 s | +23.1 s | 163.4% | REGRESS |
| multi-day-application-logs-top25-consolidate | TIMING/initialize_buckets | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| multi-day-application-logs-top25-consolidate | TIMING/group_similar | 1.4 s | 2.3 s | +833 ms | 57.8% | REGRESS |
| multi-day-application-logs-top25-consolidate | TIMING/calculate_statistics | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| multi-day-application-logs-top25-consolidate | TIMING/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/total | 15.6 s | 39.5 s | +23.9 s | 153.6% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | 121.8 MB | 225.2 MB | +103.4 MB | 84.9% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_clusters | 1.5 MB | 3.6 MB | +2 MB | 134.7% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_message | 406.6 KB | 309.4 KB | -97.2 KB | -23.9% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_patterns | 296 KB | 486.2 KB | +190.1 KB | 64.2% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_unmatched | 319.4 KB | 368.0 KB | +48.6 KB | 15.2% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_messages | 701.4 KB | 709.4 KB | +8 KB | 1.1% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/log_occurrences | 56.6 KB | 56.6 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/read_files | 8.1 s | 7.6 s | -459 ms | -5.7% | IMPROVE |
| multi-day-application-logs-heatmap | TIMING/calculate_statistics | 34 ms | 179 ms | +145 ms | 426.5% | REGRESS |
| multi-day-application-logs-heatmap | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/total | 8.1 s | 7.8 s | -313 ms | -3.9% | IMPROVE |
| multi-day-application-logs-heatmap | MEMORY/rss_peak | 62.1 MB | 110.7 MB | +48.6 MB | 78.2% | REGRESS |
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
| multi-day-application-logs-heatmap | MEMORY/log_messages | 8.8 MB | 45.8 MB | +37 MB | 422.0% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY/log_occurrences | 56.6 KB | 56.7 KB | +64 B | 0.1% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/read_files | 7.9 s | 7.5 s | -437 ms | -5.5% | IMPROVE |
| multi-day-application-logs-histogram | TIMING/calculate_statistics | 34 ms | 178 ms | +144 ms | 423.5% | REGRESS |
| multi-day-application-logs-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/total | 7.9 s | 7.7 s | -292 ms | -3.7% | IMPROVE |
| multi-day-application-logs-histogram | MEMORY/rss_peak | 62.2 MB | 110.6 MB | +48.4 MB | 77.8% | REGRESS |
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
| multi-day-application-logs-histogram | MEMORY/log_messages | 8.8 MB | 45.8 MB | +37 MB | 422.0% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/log_occurrences | 56.7 KB | 56.6 KB | -64 B | -0.1% | IMPROVE |
| multi-day-application-logs-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/read_files | 7.9 s | 7.6 s | -272 ms | -3.4% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | TIMING/calculate_statistics | 36 ms | 177 ms | +141 ms | 391.7% | REGRESS |
| multi-day-application-logs-heatmap-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/total | 7.9 s | 7.8 s | -130 ms | -1.6% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | MEMORY/rss_peak | 63.3 MB | 110.8 MB | +47.5 MB | 75.1% | REGRESS |
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
| multi-day-application-logs-heatmap-histogram | MEMORY/log_messages | 8.8 MB | 45.8 MB | +37 MB | 422.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_occurrences | 56.6 KB | 56.7 KB | +64 B | 0.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/read_files | 14.2 s | 35.5 s | +21.3 s | 150.5% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/group_similar | 1.4 s | 2 s | +648 ms | 46.9% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | 15.6 s | 37.5 s | +22.0 s | 141.2% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 122.4 MB | 223.2 MB | +100.9 MB | 82.4% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 1.5 MB | 3.6 MB | +2 MB | 134.7% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 406.6 KB | 309.4 KB | -97.2 KB | -23.9% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 296 KB | 486.2 KB | +190.1 KB | 64.2% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 319.4 KB | 368.0 KB | +48.6 KB | 15.2% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 701.4 KB | 709.4 KB | +8 KB | 1.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 56.6 KB | 56.7 KB | +64 B | 0.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/read_files | 16.9 s | 15.7 s | -1.2 s | -7.3% | IMPROVE |
| multi-day-custom-logs-standard | TIMING/calculate_statistics | 391 ms | 383 ms | -8 ms | -2.0% | IMPROVE |
| multi-day-custom-logs-standard | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/total | 17.3 s | 16.1 s | -1.2 s | -7.1% | IMPROVE |
| multi-day-custom-logs-standard | MEMORY/rss_peak | 191.2 MB | 198.8 MB | +7.6 MB | 4.0% | REGRESS |
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
| multi-day-custom-logs-standard | MEMORY/log_messages | 91.9 MB | 102.6 MB | +10.7 MB | 11.6% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/log_occurrences | 10.8 KB | 20.3 KB | +9.5 KB | 87.9% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_stats | 30.1 KB | 54.7 KB | +24.6 KB | 81.9% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/read_files | 16.8 s | 15.5 s | -1.3 s | -7.5% | IMPROVE |
| multi-day-custom-logs-top25 | TIMING/calculate_statistics | 401 ms | 391 ms | -10 ms | -2.5% | IMPROVE |
| multi-day-custom-logs-top25 | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/total | 17.2 s | 15.9 s | -1.3 s | -7.4% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/rss_peak | 188.2 MB | 198.9 MB | +10.7 MB | 5.7% | REGRESS |
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
| multi-day-custom-logs-top25 | MEMORY/log_messages | 91.9 MB | 102.6 MB | +10.7 MB | 11.6% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/log_occurrences | 10.8 KB | 20.3 KB | +9.5 KB | 87.9% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_stats | 30.1 KB | 54.7 KB | +24.6 KB | 81.9% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/read_files | 29.3 s | 46.9 s | +17.7 s | 60.3% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/group_similar | 4.1 s | 3.3 s | -846 ms | -20.4% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/calculate_statistics | 370 ms | 294 ms | -76 ms | -20.5% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/total | 33.8 s | 50.5 s | +16.7 s | 49.5% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/rss_peak | 189.7 MB | 249.8 MB | +60.1 MB | 31.7% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_clusters | 29 MB | 29.5 MB | +543.9 KB | 1.8% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_message | 172.7 KB | 197.4 KB | +24.7 KB | 14.3% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_patterns | 193.8 KB | 201.9 KB | +8.1 KB | 4.2% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_unmatched | 229.2 KB | 248.8 KB | +19.7 KB | 8.6% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_analysis | 28.2 MB | 28.4 MB | +239.8 KB | 0.8% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_messages | 28.7 MB | 28.6 MB | -52.2 KB | -0.2% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_occurrences | 10.8 KB | 20.3 KB | +9.5 KB | 87.9% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_stats | 30.1 KB | 54.4 KB | +24.4 KB | 81.1% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/read_files | 17 s | 15.7 s | -1.3 s | -7.6% | IMPROVE |
| multi-day-custom-logs-heatmap | TIMING/calculate_statistics | 293 ms | 310 ms | +17 ms | 5.8% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/heatmap_statistics | 418 ms | 402 ms | -16 ms | -3.8% | IMPROVE |
| multi-day-custom-logs-heatmap | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/total | 17.7 s | 16.4 s | -1.3 s | -7.3% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/rss_peak | 195.4 MB | 206.9 MB | +11.5 MB | 5.9% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_data | 26.4 KB | 43.2 KB | +16.9 KB | 64.0% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_raw | 28.2 MB | 28.4 MB | +233.0 KB | 0.8% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_analysis | 11.5 KB | 20.7 KB | +9.2 KB | 79.4% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/log_messages | 92.4 MB | 103.1 MB | +10.7 MB | 11.6% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/log_occurrences | 10.8 KB | 20.3 KB | +9.5 KB | 87.9% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_stats | 27.4 KB | 49.6 KB | +22.1 KB | 80.6% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/read_files | 17.4 s | 16.1 s | -1.4 s | -7.8% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/calculate_statistics | 430 ms | 394 ms | -36 ms | -8.4% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/histogram_statistics | 548 ms | 530 ms | -18 ms | -3.3% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/total | 18.4 s | 17.0 s | -1.4 s | -7.6% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/rss_peak | 230.9 MB | 243.0 MB | +12.1 MB | 5.2% | REGRESS |
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
| multi-day-custom-logs-histogram | MEMORY/log_messages | 91.9 MB | 103.1 MB | +11.1 MB | 12.1% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/log_occurrences | 10.8 KB | 20.3 KB | +9.5 KB | 87.9% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_stats | 30.1 KB | 54.7 KB | +24.6 KB | 81.9% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/read_files | 17.1 s | 16.1 s | -1.1 s | -6.3% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/calculate_statistics | 299 ms | 314 ms | +15 ms | 5.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | TIMING/heatmap_statistics | 435 ms | 407 ms | -28 ms | -6.4% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/histogram_statistics | 593 ms | 528 ms | -65 ms | -11.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/total | 18.5 s | 17.3 s | -1.2 s | -6.3% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/rss_peak | 238.0 MB | 249.7 MB | +11.7 MB | 4.9% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_data | 27.5 KB | 43.0 KB | +15.5 KB | 56.4% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_raw | 28.2 MB | 28.4 MB | +233.2 KB | 0.8% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_values | 29.8 MB | 29.8 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_analysis | 11.5 KB | 20.9 KB | +9.4 KB | 81.6% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_messages | 91.9 MB | 103.1 MB | +11.1 MB | 12.1% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_occurrences | 10.8 KB | 20.3 KB | +9.5 KB | 87.9% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_stats | 27.4 KB | 49.8 KB | +22.4 KB | 81.6% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/read_files | 29.4 s | 46.4 s | +17.0 s | 57.8% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/group_similar | 4.2 s | 3.2 s | -1 s | -24.4% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | 163 ms | 161 ms | -2 ms | -1.2% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/heatmap_statistics | 565 ms | 483 ms | -82 ms | -14.5% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/histogram_statistics | 687 ms | 676 ms | -11 ms | -1.6% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/total | 35 s | 50.9 s | +15.9 s | 45.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 228 MB | 289.4 MB | +61.4 MB | 26.9% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 29 MB | 29.5 MB | +543.9 KB | 1.8% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 172.7 KB | 197.4 KB | +24.7 KB | 14.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 193.8 KB | 201.9 KB | +8.1 KB | 4.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 229.2 KB | 248.8 KB | +19.7 KB | 8.6% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 27.4 KB | 43.6 KB | +16.2 KB | 59.4% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 28.2 MB | 28.4 MB | +233.3 KB | 0.8% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 29.8 MB | 29.8 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 11.4 KB | 20.9 KB | +9.5 KB | 83.6% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 28.7 MB | 28.6 MB | -47.9 KB | -0.2% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 10.7 KB | 20.3 KB | +9.6 KB | 90.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 27.3 KB | 49.8 KB | +22.5 KB | 82.4% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | TIMING/read_files | 9.6 s | 9.1 s | -522 ms | -5.4% | IMPROVE |
| single-day-access-log-standard | TIMING/calculate_statistics | 233 ms | 201 ms | -32 ms | -13.7% | IMPROVE |
| single-day-access-log-standard | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| single-day-access-log-standard | TIMING/total | 9.9 s | 9.3 s | -554 ms | -5.6% | IMPROVE |
| single-day-access-log-standard | MEMORY/rss_peak | 159.9 MB | 153.7 MB | -6.2 MB | -3.9% | IMPROVE |
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
| single-day-access-log-standard | MEMORY/log_messages | 55.3 MB | 55.5 MB | +191.7 KB | 0.3% | REGRESS |
| single-day-access-log-standard | MEMORY/log_occurrences | 10.1 KB | 18.4 KB | +8.3 KB | 82.6% | REGRESS |
| single-day-access-log-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_stats | 17.3 KB | 31.6 KB | +14.3 KB | 82.5% | REGRESS |
| single-day-access-log-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | TIMING/read_files | 9.7 s | 9.1 s | -597 ms | -6.2% | IMPROVE |
| single-day-access-log-top25 | TIMING/calculate_statistics | 263 ms | 224 ms | -39 ms | -14.8% | IMPROVE |
| single-day-access-log-top25 | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| single-day-access-log-top25 | TIMING/total | 9.9 s | 9.3 s | -637 ms | -6.4% | IMPROVE |
| single-day-access-log-top25 | MEMORY/rss_peak | 163.4 MB | 155.1 MB | -8.3 MB | -5.1% | IMPROVE |
| single-day-access-log-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_analysis | 53.2 MB | 52.7 MB | -562.8 KB | -1.0% | IMPROVE |
| single-day-access-log-top25 | MEMORY/log_messages | 55.5 MB | 55.5 MB | +7.1 KB | 0.0% | REGRESS |
| single-day-access-log-top25 | MEMORY/log_occurrences | 10.1 KB | 18.3 KB | +8.2 KB | 81.4% | REGRESS |
| single-day-access-log-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_stats | 17.3 KB | 31.4 KB | +14.1 KB | 81.7% | REGRESS |
| single-day-access-log-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/read_files | 11.3 s | 10.4 s | -878 ms | -7.8% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/group_similar | 1.9 s | 729 ms | -1.2 s | -62.3% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/calculate_statistics | 431 ms | 341 ms | -90 ms | -20.9% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/total | 13.6 s | 11.5 s | -2.2 s | -15.9% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/rss_peak | 233 MB | 191.3 MB | -41.7 MB | -17.9% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_clusters | 48.7 MB | 48.5 MB | -161.7 KB | -0.3% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_message | 464 KB | 465.1 KB | +1.1 KB | 0.2% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_patterns | 132.2 KB | 121 KB | -11.1 KB | -8.4% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_unmatched | 316.9 KB | 317.6 KB | +647 B | 0.2% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_analysis | 53.2 MB | 52.7 MB | -562.7 KB | -1.0% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/log_messages | 53.5 MB | 53.5 MB | -74.2 KB | -0.1% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/log_occurrences | 10.1 KB | 18.4 KB | +8.3 KB | 82.6% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_stats | 17.3 KB | 31.6 KB | +14.3 KB | 82.5% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | TIMING/read_files | 9.9 s | 9.3 s | -607 ms | -6.2% | IMPROVE |
| single-day-access-log-heatmap | TIMING/calculate_statistics | 65 ms | 58 ms | -7 ms | -10.8% | IMPROVE |
| single-day-access-log-heatmap | TIMING/heatmap_statistics | 584 ms | 561 ms | -23 ms | -3.9% | IMPROVE |
| single-day-access-log-heatmap | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap | TIMING/total | 10.5 s | 9.9 s | -636 ms | -6.0% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/rss_peak | 161.2 MB | 159.8 MB | -1.4 MB | -0.9% | IMPROVE |
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
| single-day-access-log-histogram | TIMING/read_files | 10.2 s | 9.6 s | -614 ms | -6.0% | IMPROVE |
| single-day-access-log-histogram | TIMING/calculate_statistics | 273 ms | 228 ms | -45 ms | -16.5% | IMPROVE |
| single-day-access-log-histogram | TIMING/histogram_statistics | 1.6 s | 1.5 s | -53 ms | -3.3% | IMPROVE |
| single-day-access-log-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/total | 12.1 s | 11.4 s | -713 ms | -5.9% | IMPROVE |
| single-day-access-log-histogram | MEMORY/rss_peak | 296.3 MB | 286.3 MB | -10 MB | -3.4% | IMPROVE |
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
| single-day-access-log-heatmap-histogram | TIMING/read_files | 10.4 s | 9.8 s | -580 ms | -5.6% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/calculate_statistics | 71 ms | 64 ms | -7 ms | -9.9% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/heatmap_statistics | 620 ms | 583 ms | -37 ms | -6.0% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/histogram_statistics | 1.6 s | 1.5 s | -62 ms | -3.9% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| single-day-access-log-heatmap-histogram | TIMING/total | 12.7 s | 12 s | -684 ms | -5.4% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/rss_peak | 292.9 MB | 292.5 MB | -384 KB | -0.1% | IMPROVE |
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
| single-day-access-log-heatmap-histogram | MEMORY/log_messages | 55.5 MB | 55.5 MB | -6.7 KB | -0.0% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/log_occurrences | 10.1 KB | 18.4 KB | +8.3 KB | 82.6% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_stats | 15.7 KB | 28.5 KB | +12.8 KB | 81.8% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/read_files | 11.9 s | 11.2 s | -746 ms | -6.2% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/group_similar | 2.0 s | 771 ms | -1.2 s | -60.6% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/calculate_statistics | 377 ms | 279 ms | -98 ms | -26.0% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/heatmap_statistics | 731 ms | 652 ms | -79 ms | -10.8% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/histogram_statistics | 1.6 s | 1.5 s | -67 ms | -4.2% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/total | 16.6 s | 14.4 s | -2.2 s | -13.1% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 337.4 MB | 331.3 MB | -6.1 MB | -1.8% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 49.9 MB | 49.8 MB | -160.6 KB | -0.3% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 464 KB | 465.1 KB | +1.1 KB | 0.2% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 132.2 KB | 121.2 KB | -11.0 KB | -8.3% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 316.9 KB | 317.6 KB | +647 B | 0.2% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_data | 19.6 KB | 34 KB | +14.4 KB | 73.6% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 39.8 MB | 39.9 MB | +97.2 KB | 0.2% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_values | 90.1 MB | 90.1 MB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_analysis | 4.4 KB | 8.1 KB | +3.7 KB | 82.4% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_messages | 54.7 MB | 54.7 MB | -10.9 KB | -0.0% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_occurrences | 10.1 KB | 18.4 KB | +8.3 KB | 82.6% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_stats | 15.7 KB | 28.5 KB | +12.8 KB | 81.8% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/read_files | 1.8 min | 1.7 min | -6 s | -5.5% | IMPROVE |
| month-single-server-access-logs-standard | TIMING/calculate_statistics | 5.5 s | 5.4 s | -51 ms | -0.9% | IMPROVE |
| month-single-server-access-logs-standard | TIMING/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/total | 1.9 min | 1.8 min | -6.1 s | -5.3% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/rss_peak | 2.2 GB | 2.7 GB | +513.2 MB | 22.8% | REGRESS |
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
| month-single-server-access-logs-standard | MEMORY/log_messages | 1.2 GB | 1.6 GB | +437.2 MB | 36.0% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/log_occurrences | 36.8 KB | 36.6 KB | -192 B | -0.5% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_stats | 60.0 KB | 60.0 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/read_files | 1.8 min | 1.7 min | -5.7 s | -5.2% | IMPROVE |
| month-single-server-access-logs-top25 | TIMING/calculate_statistics | 5.8 s | 5.6 s | -211 ms | -3.6% | IMPROVE |
| month-single-server-access-logs-top25 | TIMING/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/total | 1.9 min | 1.8 min | -6.0 s | -5.2% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY/rss_peak | 2.2 GB | 2.6 GB | +444.4 MB | 19.8% | REGRESS |
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
| month-single-server-access-logs-top25 | MEMORY/log_messages | 1.2 GB | 1.5 GB | +365.1 MB | 30.1% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/log_occurrences | 36.8 KB | 36.8 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_stats | 60.0 KB | 60.0 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/read_files | 2.8 min | 2.1 min | -36.4 s | -22.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | TIMING/group_similar | 64.5 min | 4.5 s | -64.4 min | -99.9% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | TIMING/calculate_statistics | 6.7 s | 7.8 s | +1 s | 15.4% | REGRESS |
| month-single-server-access-logs-top25-consolidate | TIMING/normalize_data | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | TIMING/total | 67.4 min | 2.4 min | -65 min | -96.5% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | 3.0 GB | 1.7 GB | -1.3 GB | -44.6% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_clusters | 5.6 MB | 507.7 MB | +502.2 MB | 8992.5% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_message | 236.4 MB | 149.4 KB | -236.3 MB | -99.9% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_patterns | 71.6 KB | 257.2 KB | +185.6 KB | 259.3% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | 150.6 MB | 198.5 KB | -150.4 MB | -99.9% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_analysis | 567.3 MB | 567.4 MB | +121.6 KB | 0.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_messages | 1.2 GB | 568.1 MB | -643.4 MB | -53.1% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_occurrences | 36.6 KB | 36.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_stats | 60.0 KB | 60.0 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/read_files | 1.9 min | 1.8 min | -7.2 s | -6.4% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/calculate_statistics | 2.1 s | 2.1 s | +2 ms | 0.1% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/heatmap_statistics | 13.3 s | 12.9 s | -417 ms | -3.1% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/total | 2.1 min | 2 min | -7.6 s | -6.0% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/rss_peak | 2.2 GB | 2.7 GB | +538.1 MB | 23.7% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_data | 78.4 KB | 77.9 KB | -512 B | -0.6% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_raw | 563.6 MB | 563.6 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_analysis | 15.7 KB | 15.7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_messages | 1.2 GB | 1.6 GB | +440.9 MB | 36.4% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/log_occurrences | 36.6 KB | 36.8 KB | +192 B | 0.5% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_stats | 54.1 KB | 54.1 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/read_files | 1.9 min | 1.8 min | -7.2 s | -6.2% | IMPROVE |
| month-single-server-access-logs-histogram | TIMING/calculate_statistics | 6.1 s | 6 s | -62 ms | -1.0% | IMPROVE |
| month-single-server-access-logs-histogram | TIMING/histogram_statistics | 23.6 s | 22.9 s | -666 ms | -2.8% | IMPROVE |
| month-single-server-access-logs-histogram | TIMING/normalize_data | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/total | 2.4 min | 2.3 min | -7.9 s | -5.5% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/rss_peak | 3.6 GB | 4 GB | +482.4 MB | 13.2% | REGRESS |
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
| month-single-server-access-logs-histogram | MEMORY/log_occurrences | 36.6 KB | 36.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_stats | 60.0 KB | 60.0 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/read_files | 2.0 min | 1.8 min | -7.2 s | -6.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/calculate_statistics | 2.1 s | 2.3 s | +144 ms | 6.8% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/heatmap_statistics | 13.8 s | 13.3 s | -484 ms | -3.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/histogram_statistics | 23.6 s | 22.8 s | -752 ms | -3.2% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/normalize_data | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/total | 2.6 min | 2.5 min | -8.3 s | -5.3% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/rss_peak | 3.6 GB | 4.1 GB | +502.7 MB | 13.6% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_data | 75.4 KB | 78.4 KB | +3 KB | 4.0% | REGRESS |
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
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/read_files | 2.9 min | 2.3 min | -38.2 s | -22.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/group_similar | 64.4 min | 4.5 s | -64.3 min | -99.9% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | 2.5 s | 3.1 s | +631 ms | 25.5% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/heatmap_statistics | 14.6 s | 14.2 s | -412 ms | -2.8% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/histogram_statistics | 24.5 s | 23.0 s | -1.5 s | -6.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/normalize_data | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | 68 min | 3 min | -65 min | -95.6% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 4.4 GB | 3.2 GB | -1.1 GB | -25.4% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 5.6 MB | 503.6 MB | +498 MB | 8918.2% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 236.4 MB | 149.4 KB | -236.3 MB | -99.9% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 71.6 KB | 252.4 KB | +180.8 KB | 252.6% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 150.6 MB | 198.5 KB | -150.4 MB | -99.9% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 77.9 KB | 77.9 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 563.6 MB | 563.7 MB | +121.6 KB | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 1.1 GB | 1.1 GB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 15.7 KB | 15.7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 1.2 GB | 566.2 MB | -645.4 MB | -53.3% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 36.8 KB | 36.6 KB | -192 B | -0.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 54.1 KB | 54.1 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | TIMING/read_files | 9.1 min | 8.4 min | -37.2 s | -6.8% | IMPROVE |
| month-many-servers-access-logs-standard | TIMING/calculate_statistics | 29 s | 31.9 s | +2.9 s | 10.0% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/normalize_data | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/total | 9.5 min | 9.0 min | -34.3 s | -6.0% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/rss_peak | 10 GB | 13.2 GB | +3.2 GB | 31.8% | REGRESS |
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
| month-many-servers-access-logs-standard | MEMORY/log_occurrences | 43.8 KB | 42.1 KB | -1.8 KB | -4.0% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/log_sessions | 14.9 MB | 14.9 MB | +128 B | 0.0% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY/log_stats | 60.1 KB | 60.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | TIMING/read_files | 9.0 min | 8.5 min | -29.5 s | -5.5% | IMPROVE |
| month-many-servers-access-logs-top25 | TIMING/calculate_statistics | 35.6 s | 33.6 s | -1.9 s | -5.4% | IMPROVE |
| month-many-servers-access-logs-top25 | TIMING/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-top25 | TIMING/total | 9.6 min | 9 min | -31.4 s | -5.5% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY/rss_peak | 10.2 GB | 13.2 GB | +2.9 GB | 28.6% | REGRESS |
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
| month-many-servers-access-logs-top25 | MEMORY/log_messages | 6 GB | 8.3 GB | +2.3 GB | 38.5% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/log_occurrences | 42.1 KB | 43.8 KB | +1.8 KB | 4.2% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/log_sessions | 14.9 MB | 14.9 MB | +32 KB | 0.2% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/log_stats | 60.1 KB | 60.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/read_files | 10.7 min | 9.8 min | -53.4 s | -8.3% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/group_similar | 466.3 min | 24.0 s | -465.9 min | -99.9% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/calculate_statistics | 37 s | 41.2 s | +4.2 s | 11.3% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | TIMING/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | 477.7 min | 10.9 min | -466.7 min | -97.7% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | 11.6 GB | 6.8 GB | -4.7 GB | -40.9% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_clusters | 31.0 MB | 2.7 GB | +2.6 GB | 8675.1% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_message | 1.1 GB | 144.1 KB | -1.1 GB | -100.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_patterns | 133.8 KB | 532.8 KB | +399.0 KB | 298.2% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | 735.8 MB | 276.4 KB | -735.5 MB | -100.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_analysis | 2.9 GB | 2.9 GB | +7.4 MB | 0.3% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_messages | 6 GB | 2.9 GB | -3.1 GB | -52.1% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -32 KB | -0.2% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_stats | 60.1 KB | 60.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/read_files | 9.3 min | 8.6 min | -36.8 s | -6.6% | IMPROVE |
| month-many-servers-access-logs-heatmap | TIMING/calculate_statistics | 10.4 s | 12.4 s | +2 s | 19.3% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/heatmap_statistics | 1.1 min | 1.1 min | -1.4 s | -2.2% | IMPROVE |
| month-many-servers-access-logs-heatmap | TIMING/normalize_data | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/total | 10.5 min | 9.9 min | -36.2 s | -5.7% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/rss_peak | 10.6 GB | 13.3 GB | +2.8 GB | 26.0% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_data | 76.8 KB | 76.8 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_raw | 2.9 GB | 2.9 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_analysis | 15.7 KB | 15.7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_messages | 6 GB | 8.3 GB | +2.3 GB | 38.5% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/log_occurrences | 43.8 KB | 42.1 KB | -1.8 KB | -4.0% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_stats | 54.1 KB | 54.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/read_files | 9.5 min | 8.9 min | -32.6 s | -5.8% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/calculate_statistics | 42.3 s | 35.0 s | -7.3 s | -17.3% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/histogram_statistics | 2.8 min | 1.9 min | -50.8 s | -30.3% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/normalize_data | 4 ms | 3 ms | -1 ms | -25.0% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/total | 13.0 min | 11.4 min | -1.5 min | -11.7% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/rss_peak | 12 GB | 20.5 GB | +8.5 GB | 71.0% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/histogram_values | 5.4 GB | 5.4 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_analysis | 2.9 GB | 2.9 GB | +236.8 KB | 0.0% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/log_messages | 6 GB | 8.3 GB | +2.3 GB | 38.7% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_stats | 60.1 KB | 60.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/read_files | 9.6 min | 9 min | -36.9 s | -6.4% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/calculate_statistics | 14.1 s | 12.9 s | -1.2 s | -8.2% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/heatmap_statistics | 1.2 min | 1.1 min | -4.5 s | -6.4% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/histogram_statistics | 2.7 min | 2.0 min | -47.2 s | -28.7% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/normalize_data | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/total | 13.8 min | 12.3 min | -1.5 min | -10.9% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/rss_peak | 13 GB | 19.3 GB | +6.2 GB | 47.9% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_data | 75.3 KB | 76.8 KB | +1.5 KB | 2.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_raw | 2.9 GB | 2.9 GB | -19.2 KB | -0.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_values | 5.4 GB | 5.4 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_analysis | 15.7 KB | 15.7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_messages | 6 GB | 8.3 GB | +2.3 GB | 38.5% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_occurrences | 43.8 KB | 42.1 KB | -1.8 KB | -4.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_sessions | 14.9 MB | 14.9 MB | +128 B | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_stats | 54.1 KB | 54.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY_FINAL/log_messages | N/A | 133188237 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | COUNTS/log_messages_entries | N/A | 286659 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | COUNTS/log_occurrences_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | COUNTS/log_stats_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/log_messages | N/A | 133188237 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | COUNTS/log_messages_entries | N/A | 286659 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | COUNTS/log_occurrences_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | COUNTS/log_stats_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/log_messages | N/A | 100953 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 200881 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 25503 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 65592 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 232 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_messages_entries | N/A | 72 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_occurrences_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_stats_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/log_messages | N/A | 133188237 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | COUNTS/log_messages_entries | N/A | 286659 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | COUNTS/log_occurrences_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | COUNTS/log_stats_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/log_messages | N/A | 133188237 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | COUNTS/log_messages_entries | N/A | 286659 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | COUNTS/log_occurrences_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | COUNTS/log_stats_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/log_messages | N/A | 133188237 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | COUNTS/log_messages_entries | N/A | 286659 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | COUNTS/log_occurrences_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | COUNTS/log_stats_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | N/A | 100953 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 200881 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 25503 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 65592 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 232 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_messages_entries | N/A | 72 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_stats_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY_FINAL/log_messages | N/A | 2872100 | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-standard | COUNTS/log_messages_entries | N/A | 6512 | N/A | N/A | ? |
| single-day-application-log-standard | COUNTS/log_occurrences_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-standard | COUNTS/log_stats_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-standard | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-standard | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| single-day-application-log-standard | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-standard | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-application-log-standard | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY_FINAL/log_messages | N/A | 2872100 | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-top25 | COUNTS/log_messages_entries | N/A | 6512 | N/A | N/A | ? |
| single-day-application-log-top25 | COUNTS/log_occurrences_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-top25 | COUNTS/log_stats_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-top25 | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-top25 | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| single-day-application-log-top25 | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-top25 | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-application-log-top25 | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/log_messages | N/A | 137524 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 448005 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 55576 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 65592 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 232 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | COUNTS/log_messages_entries | N/A | 136 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | COUNTS/log_occurrences_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | COUNTS/log_stats_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY_FINAL/log_messages | N/A | 2872100 | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap | COUNTS/log_messages_entries | N/A | 6512 | N/A | N/A | ? |
| single-day-application-log-heatmap | COUNTS/log_occurrences_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-heatmap | COUNTS/log_stats_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-heatmap | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-heatmap | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| single-day-application-log-heatmap | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-heatmap | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-application-log-heatmap | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY_FINAL/log_messages | N/A | 2872100 | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-histogram | COUNTS/log_messages_entries | N/A | 6512 | N/A | N/A | ? |
| single-day-application-log-histogram | COUNTS/log_occurrences_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-histogram | COUNTS/log_stats_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-histogram | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-histogram | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| single-day-application-log-histogram | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-histogram | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-application-log-histogram | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/log_messages | N/A | 2872100 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | COUNTS/log_messages_entries | N/A | 6512 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | COUNTS/log_occurrences_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | COUNTS/log_stats_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | N/A | 137524 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 447791 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 55660 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 65592 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 232 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | COUNTS/log_messages_entries | N/A | 136 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | COUNTS/log_stats_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY_FINAL/log_messages | N/A | 48030790 | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-standard | COUNTS/log_messages_entries | N/A | 105902 | N/A | N/A | ? |
| multi-day-application-logs-standard | COUNTS/log_occurrences_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-standard | COUNTS/log_stats_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-standard | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-standard | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| multi-day-application-logs-standard | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-standard | CONFIG/time_bucket_size | N/A | 480 | N/A | N/A | ? |
| multi-day-application-logs-standard | CONFIG/bucket_size_seconds | N/A | 28800.00 | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY_FINAL/log_messages | N/A | 48030790 | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-top25 | COUNTS/log_messages_entries | N/A | 105902 | N/A | N/A | ? |
| multi-day-application-logs-top25 | COUNTS/log_occurrences_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-top25 | COUNTS/log_stats_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-top25 | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-top25 | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| multi-day-application-logs-top25 | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-top25 | CONFIG/time_bucket_size | N/A | 480 | N/A | N/A | ? |
| multi-day-application-logs-top25 | CONFIG/bucket_size_seconds | N/A | 28800.00 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/log_messages | N/A | 726422 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 3738276 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 497821 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 131128 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 232 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | COUNTS/log_messages_entries | N/A | 1304 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | COUNTS/log_occurrences_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | COUNTS/log_stats_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | CONFIG/time_bucket_size | N/A | 480 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | CONFIG/bucket_size_seconds | N/A | 28800.00 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY_FINAL/log_messages | N/A | 48030790 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | COUNTS/log_messages_entries | N/A | 105902 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | COUNTS/log_occurrences_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | COUNTS/log_stats_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | CONFIG/time_bucket_size | N/A | 480 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | CONFIG/bucket_size_seconds | N/A | 28800.00 | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY_FINAL/log_messages | N/A | 48030790 | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-histogram | COUNTS/log_messages_entries | N/A | 105902 | N/A | N/A | ? |
| multi-day-application-logs-histogram | COUNTS/log_occurrences_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-histogram | COUNTS/log_stats_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-histogram | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-histogram | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| multi-day-application-logs-histogram | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-histogram | CONFIG/time_bucket_size | N/A | 480 | N/A | N/A | ? |
| multi-day-application-logs-histogram | CONFIG/bucket_size_seconds | N/A | 28800.00 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/log_messages | N/A | 48030790 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | COUNTS/log_messages_entries | N/A | 105902 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | COUNTS/log_occurrences_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | COUNTS/log_stats_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | CONFIG/time_bucket_size | N/A | 480 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | CONFIG/bucket_size_seconds | N/A | 28800.00 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | N/A | 726422 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 3738276 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 497821 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 131128 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 232 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | N/A | 1304 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | N/A | 480 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | N/A | 28800.00 | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY_FINAL/log_messages | N/A | 107569190 | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY_FINAL/log_analysis | N/A | 20342 | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-standard | COUNTS/log_messages_entries | N/A | 182419 | N/A | N/A | ? |
| multi-day-custom-logs-standard | COUNTS/log_occurrences_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-standard | COUNTS/log_stats_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-standard | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-standard | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| multi-day-custom-logs-standard | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-standard | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| multi-day-custom-logs-standard | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY_FINAL/log_messages | N/A | 107588918 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY_FINAL/log_analysis | N/A | 20342 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | COUNTS/log_messages_entries | N/A | 182419 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | COUNTS/log_occurrences_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | COUNTS/log_stats_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/log_messages | N/A | 30013620 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/log_analysis | N/A | 20086 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 30969856 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 206763 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 131128 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 232 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_messages_entries | N/A | 606 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_occurrences_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_stats_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/log_messages | N/A | 108064422 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/log_analysis | N/A | 20086 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | COUNTS/log_messages_entries | N/A | 182419 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | COUNTS/log_occurrences_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | COUNTS/log_stats_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY_FINAL/log_messages | N/A | 108064422 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY_FINAL/log_analysis | N/A | 20342 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | COUNTS/log_messages_entries | N/A | 182419 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | COUNTS/log_occurrences_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | COUNTS/log_stats_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/log_messages | N/A | 108064422 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | N/A | 20342 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | COUNTS/log_messages_entries | N/A | 182419 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | COUNTS/log_occurrences_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | COUNTS/log_stats_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | N/A | 30004692 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | N/A | 20342 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 30969856 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 206763 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 131128 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 232 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | N/A | 606 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY_FINAL/log_messages | N/A | 58184154 | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY_FINAL/log_analysis | N/A | 6670 | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-standard | COUNTS/log_messages_entries | N/A | 3184 | N/A | N/A | ? |
| single-day-access-log-standard | COUNTS/log_occurrences_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-standard | COUNTS/log_stats_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-standard | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-standard | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| single-day-access-log-standard | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-standard | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-access-log-standard | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY_FINAL/log_messages | N/A | 58205010 | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY_FINAL/log_analysis | N/A | 6542 | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-top25 | COUNTS/log_messages_entries | N/A | 3184 | N/A | N/A | ? |
| single-day-access-log-top25 | COUNTS/log_occurrences_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-top25 | COUNTS/log_stats_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-top25 | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-top25 | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| single-day-access-log-top25 | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-top25 | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-access-log-top25 | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/log_messages | N/A | 56062775 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/log_analysis | N/A | 6670 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 50888153 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 123909 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 65592 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 296 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | COUNTS/log_messages_entries | N/A | 598 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | COUNTS/log_occurrences_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | COUNTS/log_stats_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY_FINAL/log_messages | N/A | 58184154 | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY_FINAL/log_analysis | N/A | 6670 | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap | COUNTS/log_messages_entries | N/A | 3184 | N/A | N/A | ? |
| single-day-access-log-heatmap | COUNTS/log_occurrences_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-heatmap | COUNTS/log_stats_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-heatmap | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-heatmap | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| single-day-access-log-heatmap | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-heatmap | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-access-log-heatmap | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY_FINAL/log_messages | N/A | 58191194 | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY_FINAL/log_analysis | N/A | 6670 | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-histogram | COUNTS/log_messages_entries | N/A | 3184 | N/A | N/A | ? |
| single-day-access-log-histogram | COUNTS/log_occurrences_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-histogram | COUNTS/log_stats_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-histogram | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-histogram | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| single-day-access-log-histogram | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-histogram | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-access-log-histogram | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/log_messages | N/A | 58184154 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/log_analysis | N/A | 6670 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | COUNTS/log_messages_entries | N/A | 3184 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | COUNTS/log_occurrences_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | COUNTS/log_stats_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | N/A | 57381194 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | N/A | 6670 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 52193514 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 124101 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 65592 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 296 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_messages_entries | N/A | 599 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_stats_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/log_messages | N/A | 1730917915 | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-standard | COUNTS/log_messages_entries | N/A | 1212275 | N/A | N/A | ? |
| month-single-server-access-logs-standard | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-standard | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-standard | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-standard | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| month-single-server-access-logs-standard | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-standard | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-single-server-access-logs-standard | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/log_messages | N/A | 1655260931 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | COUNTS/log_messages_entries | N/A | 1212275 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/log_messages | N/A | 595725141 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 532412788 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 263383 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 131128 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 424 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_messages_entries | N/A | 1306 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/log_messages | N/A | 1732830635 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | COUNTS/log_messages_entries | N/A | 1212275 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/log_messages | N/A | 1730917915 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | COUNTS/log_messages_entries | N/A | 1212275 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/log_messages | N/A | 1732830635 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | COUNTS/log_messages_entries | N/A | 1212275 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | N/A | 593711105 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 528061739 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 258445 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 131128 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 424 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | N/A | 1307 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/log_messages | N/A | 8951243238 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | COUNTS/log_messages_entries | N/A | 6187253 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/log_messages | N/A | 8941409678 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | COUNTS/log_messages_entries | N/A | 6187253 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/log_messages | N/A | 3095534057 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 2848854331 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 545553 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 131128 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 424 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_messages_entries | N/A | 2560 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/log_messages | N/A | 8941395470 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | COUNTS/log_messages_entries | N/A | 6187253 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/log_messages | N/A | 8949303382 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | COUNTS/log_messages_entries | N/A | 6187253 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/log_messages | N/A | 8950522326 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/log_messages_entries | N/A | 6187253 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_read | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_included | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/read_files | N/A | 10.4 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/group_similar | N/A | 26.7 s | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | N/A | 18.1 s | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/heatmap_statistics | N/A | 1.2 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/histogram_statistics | N/A | 1.9 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/normalize_data | N/A | 3 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | N/A | 14.3 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | N/A | 15.6 GB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | N/A | 2.6 GB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | N/A | 144.1 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | N/A | 518.8 KB | N/A | N/A | ? |
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
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | N/A | 3102243618 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 2834607088 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 531209 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 131128 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 424 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | N/A | 2517 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | N/A | 52 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |

