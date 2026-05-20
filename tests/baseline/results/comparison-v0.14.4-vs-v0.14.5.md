
## Benchmark Comparison

  Baseline:    v0.14.4 (v0.14.4, 49 test cases)
  Current:     v0.14.5 (v0.14.5, 49 test cases)

### Timing Delta

| # | file selection | standard | top25 | top25-cons | heatmap | histogram | hm+hg | hm+hg+cons |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. | humungous-log-uniqueness | -1.1% | +0.0% | -4.5% | -1.2% | -2.3% | +0.2% | -7.2% |
| 2. | single-day-application-log | -0.1% | -1.2% | -3.3% | -0.3% | -2.4% | +0.6% | -2.2% |
| 3. | multi-day-application-logs | -0.4% | -0.3% | -5.6% | -0.2% | +0.7% | -2.9% | -5.6% |
| 4. | multi-day-custom-logs | -3.4% | -4.6% | -6.6% | -1.1% | -0.6% | -2.5% | -8.1% |
| 5. | single-day-access-log | +0.2% | -1.6% | -5.2% | +0.9% | -2.7% | -3.1% | -22.4% |
| 6. | month-single-server-access-logs | +1.7% | +1.4% | +81.6% | -0.7% | +1.4% | -6.1% | +40.6% |
| 7. | month-many-servers-access-logs | +3.2% | +2.6% | +179.0% | +0.5% | -0.0% | -4.7% | +99.4% |

### Memory Delta (RSS Peak)

| # | file selection | standard | top25 | top25-cons | heatmap | histogram | hm+hg | hm+hg+cons |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. | humungous-log-uniqueness | +0.7% | +1.1% | +0.7% | +0.9% | +1.4% | +1.6% | +0.6% |
| 2. | single-day-application-log | +5.8% | +5.2% | +1.5% | +6.2% | +6.6% | +3.6% | +1.4% |
| 3. | multi-day-application-logs | +0.4% | +0.6% | -3.0% | +4.0% | +1.2% | +2.1% | +0.4% |
| 4. | multi-day-custom-logs | -2.2% | -0.1% | +0.8% | -13.0% | -17.7% | -28.6% | -21.0% |
| 5. | single-day-access-log | -0.9% | -0.1% | -0.3% | -25.1% | -46.4% | -58.7% | -49.2% |
| 6. | month-single-server-access-logs | -0.6% | +2.8% | +0.5% | -21.4% | -33.3% | -47.4% | -59.9% |
| 7. | month-many-servers-access-logs | -6.9% | -0.9% | +5.8% | -24.7% | -40.6% | -47.2% | -68.5% |

### Summary

| test_name | metric | baseline | current | delta | change% | result |
| --- | --- | --- | --- | --- | --- | --- |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | 43.4 s | 40.9 s | -2.4 s | -5.6% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 222.4 MB | 223.4 MB | +992 KB | 0.4% | REGRESS |
| multi-day-application-logs-heatmap-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/total | 8.0 s | 7.7 s | -234 ms | -2.9% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | MEMORY/rss_peak | 110.7 MB | 113.1 MB | +2.3 MB | 2.1% | REGRESS |
| multi-day-application-logs-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/total | 7.8 s | 7.8 s | +58 ms | 0.7% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/rss_peak | 110.9 MB | 112.2 MB | +1.3 MB | 1.2% | REGRESS |
| multi-day-application-logs-heatmap | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/total | 7.9 s | 7.9 s | -13 ms | -0.2% | IMPROVE |
| multi-day-application-logs-heatmap | MEMORY/rss_peak | 111.1 MB | 115.5 MB | +4.5 MB | 4.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/total | 57 s | 52.4 s | -4.6 s | -8.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 294.1 MB | 232.4 MB | -61.7 MB | -21.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/total | 17.6 s | 17.1 s | -438 ms | -2.5% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/rss_peak | 248.3 MB | 177.2 MB | -71.1 MB | -28.6% | IMPROVE |
| multi-day-custom-logs-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/total | 16.8 s | 16.7 s | -102 ms | -0.6% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/rss_peak | 242.0 MB | 199.2 MB | -42.8 MB | -17.7% | IMPROVE |
| multi-day-custom-logs-heatmap | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/total | 16.6 s | 16.5 s | -187 ms | -1.1% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/rss_peak | 206.5 MB | 179.6 MB | -26.8 MB | -13.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/total | 55.3 s | 51.7 s | -3.6 s | -6.6% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/rss_peak | 255.0 MB | 257.0 MB | +2 MB | 0.8% | REGRESS |
| multi-day-custom-logs-top25 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/total | 16.7 s | 16.0 s | -766 ms | -4.6% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/rss_peak | 200.5 MB | 200.4 MB | -144 KB | -0.1% | IMPROVE |
| multi-day-custom-logs-standard | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/total | 16.7 s | 16.1 s | -561 ms | -3.4% | IMPROVE |
| multi-day-custom-logs-standard | MEMORY/rss_peak | 203.7 MB | 199.1 MB | -4.6 MB | -2.2% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/total | 20.9 s | 16.2 s | -4.7 s | -22.4% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 329.0 MB | 167.1 MB | -161.8 MB | -49.2% | IMPROVE |
| single-day-access-log-heatmap-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/total | 12.2 s | 11.8 s | -380 ms | -3.1% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/rss_peak | 292.1 MB | 120.8 MB | -171.4 MB | -58.7% | IMPROVE |
| single-day-access-log-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | TIMING/total | 11.6 s | 11.3 s | -311 ms | -2.7% | IMPROVE |
| single-day-access-log-histogram | MEMORY/rss_peak | 288.3 MB | 154.6 MB | -133.7 MB | -46.4% | IMPROVE |
| single-day-access-log-heatmap | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | TIMING/total | 10 s | 10.1 s | +95 ms | 0.9% | REGRESS |
| single-day-access-log-heatmap | MEMORY/rss_peak | 160.4 MB | 120.1 MB | -40.3 MB | -25.1% | IMPROVE |
| single-day-access-log-top25-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/total | 15.8 s | 14.9 s | -826 ms | -5.2% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/rss_peak | 194.0 MB | 193.4 MB | -544 KB | -0.3% | IMPROVE |
| single-day-access-log-top25 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | TIMING/total | 9.6 s | 9.5 s | -154 ms | -1.6% | IMPROVE |
| single-day-access-log-top25 | MEMORY/rss_peak | 156.5 MB | 156.2 MB | -208 KB | -0.1% | IMPROVE |
| single-day-access-log-standard | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | TIMING/total | 9.4 s | 9.5 s | +16 ms | 0.2% | REGRESS |
| single-day-access-log-standard | MEMORY/rss_peak | 157.8 MB | 156.4 MB | -1.4 MB | -0.9% | IMPROVE |
| multi-day-application-logs-top25-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/total | 43.0 s | 40.5 s | -2.4 s | -5.6% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | 230.1 MB | 223.3 MB | -6.8 MB | -3.0% | IMPROVE |
| multi-day-application-logs-top25 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/total | 7.9 s | 7.9 s | -20 ms | -0.3% | IMPROVE |
| multi-day-application-logs-top25 | MEMORY/rss_peak | 113.1 MB | 113.8 MB | +704 KB | 0.6% | REGRESS |
| multi-day-application-logs-standard | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-standard | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-standard | TIMING/total | 7.8 s | 7.8 s | -34 ms | -0.4% | IMPROVE |
| multi-day-application-logs-standard | MEMORY/rss_peak | 112.5 MB | 112.9 MB | +432 KB | 0.4% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/total | 6.5 s | 6.4 s | -142 ms | -2.2% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 122.7 MB | 124.4 MB | +1.8 MB | 1.4% | REGRESS |
| single-day-application-log-heatmap-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/total | 3.5 s | 3.6 s | +23 ms | 0.6% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/rss_peak | 33.5 MB | 34.8 MB | +1.2 MB | 3.6% | REGRESS |
| single-day-application-log-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | TIMING/total | 3.6 s | 3.5 s | -86 ms | -2.4% | IMPROVE |
| single-day-application-log-histogram | MEMORY/rss_peak | 33.2 MB | 35.4 MB | +2.2 MB | 6.6% | REGRESS |
| single-day-application-log-heatmap | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | TIMING/total | 3.6 s | 3.5 s | -12 ms | -0.3% | IMPROVE |
| single-day-application-log-heatmap | MEMORY/rss_peak | 33.3 MB | 35.4 MB | +2.1 MB | 6.2% | REGRESS |
| single-day-application-log-top25-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/total | 6.6 s | 6.4 s | -218 ms | -3.3% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/rss_peak | 120.8 MB | 122.6 MB | +1.8 MB | 1.5% | REGRESS |
| single-day-application-log-top25 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | TIMING/total | 3.6 s | 3.5 s | -44 ms | -1.2% | IMPROVE |
| single-day-application-log-top25 | MEMORY/rss_peak | 33.6 MB | 35.3 MB | +1.7 MB | 5.2% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/total | 11 s | 10.3 s | -792 ms | -7.2% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/rss_peak | 246.9 MB | 248.5 MB | +1.6 MB | 0.6% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/total | 2.5 s | 2.6 s | +4 ms | 0.2% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/rss_peak | 200.3 MB | 203.5 MB | +3.3 MB | 1.6% | REGRESS |
| humungous-log-uniqueness-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/total | 2.6 s | 2.5 s | -59 ms | -2.3% | IMPROVE |
| humungous-log-uniqueness-histogram | MEMORY/rss_peak | 200.8 MB | 203.5 MB | +2.8 MB | 1.4% | REGRESS |
| humungous-log-uniqueness-heatmap | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/total | 2.5 s | 2.5 s | -30 ms | -1.2% | IMPROVE |
| humungous-log-uniqueness-heatmap | MEMORY/rss_peak | 201.4 MB | 203.2 MB | +1.8 MB | 0.9% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/total | 10.8 s | 10.3 s | -488 ms | -4.5% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/rss_peak | 247.4 MB | 249.1 MB | +1.7 MB | 0.7% | REGRESS |
| humungous-log-uniqueness-top25 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/total | 2.6 s | 2.6 s | +1000 us | 0.0% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY/rss_peak | 201.3 MB | 203.5 MB | +2.2 MB | 1.1% | REGRESS |
| humungous-log-uniqueness-standard | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/total | 2.6 s | 2.6 s | -29 ms | -1.1% | IMPROVE |
| humungous-log-uniqueness-standard | MEMORY/rss_peak | 201.3 MB | 202.7 MB | +1.3 MB | 0.7% | REGRESS |
| single-day-application-log-standard | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | TIMING/total | 3.5 s | 3.5 s | -4 ms | -0.1% | IMPROVE |
| single-day-application-log-standard | MEMORY/rss_peak | 33.4 MB | 35.3 MB | +1.9 MB | 5.8% | REGRESS |
| month-single-server-access-logs-standard | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/total | 1.8 min | 1.8 min | +1.9 s | 1.7% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/rss_peak | 2.7 GB | 2.7 GB | -16.7 MB | -0.6% | IMPROVE |
| month-single-server-access-logs-top25 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/total | 1.8 min | 1.9 min | +1.6 s | 1.4% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/rss_peak | 2.6 GB | 2.7 GB | +74.3 MB | 2.8% | REGRESS |
| month-single-server-access-logs-top25-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/total | 2.4 min | 4.3 min | +1.9 min | 81.6% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | 1.7 GB | 1.7 GB | +7.8 MB | 0.5% | REGRESS |
| month-single-server-access-logs-heatmap | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/total | 2 min | 2.0 min | -817 ms | -0.7% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/rss_peak | 2.7 GB | 2.2 GB | -602 MB | -21.4% | IMPROVE |
| month-single-server-access-logs-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/total | 2.3 min | 2.3 min | +1.9 s | 1.4% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/rss_peak | 4 GB | 2.7 GB | -1.3 GB | -33.3% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/total | 2.5 min | 2.3 min | -9 s | -6.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/rss_peak | 4.1 GB | 2.2 GB | -1.9 GB | -47.4% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | 3 min | 4.2 min | +1.2 min | 40.6% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 3.2 GB | 1.3 GB | -1.9 GB | -59.9% | IMPROVE |
| month-many-servers-access-logs-standard | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | TIMING/total | 9.0 min | 9.2 min | +17.0 s | 3.2% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY/rss_peak | 13.2 GB | 12.3 GB | -937.3 MB | -6.9% | IMPROVE |
| month-many-servers-access-logs-top25 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | TIMING/total | 9 min | 9.3 min | +14.3 s | 2.6% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/rss_peak | 13.2 GB | 13 GB | -118.5 MB | -0.9% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | 10.9 min | 30.4 min | +19.5 min | 179.0% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | 6.8 GB | 7.2 GB | +404.8 MB | 5.8% | REGRESS |
| month-many-servers-access-logs-heatmap | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/total | 9.9 min | 10.0 min | +3.0 s | 0.5% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/rss_peak | 13.3 GB | 10 GB | -3.3 GB | -24.7% | IMPROVE |
| month-many-servers-access-logs-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/total | 11.4 min | 11.4 min | -302 ms | -0.0% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/rss_peak | 20.5 GB | 12.2 GB | -8.3 GB | -40.6% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/total | 12.3 min | 11.7 min | -34.9 s | -4.7% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/rss_peak | 19.3 GB | 10.2 GB | -9.1 GB | -47.2% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | 14.3 min | 28.4 min | +14.2 min | 99.4% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 15.6 GB | 4.9 GB | -10.7 GB | -68.5% | IMPROVE |

### Detailed

| test_name | metric | baseline | current | delta | change% | result |
| --- | --- | --- | --- | --- | --- | --- |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/read_files | 38.4 s | 36.6 s | -1.8 s | -4.7% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/group_similar | 4.9 s | 4.3 s | -606 ms | -12.3% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | 43.4 s | 40.9 s | -2.4 s | -5.6% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 222.4 MB | 223.4 MB | +992 KB | 0.4% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 3.6 MB | 3.6 MB | +368 B | 0.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 3.5 MB | 3.5 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 62.2 MB | 62.2 MB | -1 KB | -0.0% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 10.4 MB | 10.4 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 60.8 MB | 60.8 MB | +10 KB | 0.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 485.8 KB | 486.5 KB | +736 B | 0.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 1.6 MB | 1.6 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 2.1 MB | 2.1 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 3.2 MB | 3.2 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 56.7 KB | 56.6 KB | -64 B | -0.1% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 726422 | 726422 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 3738228 | 3738596 | 368 | 0.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 497442 | 498178 | 736 | 0.1% | REGRESS |
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
| multi-day-application-logs-heatmap-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/read_files | 7.8 s | 7.6 s | -226 ms | -2.9% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | TIMING/calculate_statistics | 188 ms | 179 ms | -9 ms | -4.8% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/total | 8.0 s | 7.7 s | -234 ms | -2.9% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | MEMORY/rss_peak | 110.7 MB | 113.1 MB | +2.3 MB | 2.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_messages | 45.8 MB | 45.8 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_occurrences | 56.6 KB | 56.6 KB | 0 B | 0.0% |  |
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
| multi-day-application-logs-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/read_files | 7.6 s | 7.6 s | +69 ms | 0.9% | REGRESS |
| multi-day-application-logs-histogram | TIMING/calculate_statistics | 191 ms | 180 ms | -11 ms | -5.8% | IMPROVE |
| multi-day-application-logs-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/total | 7.8 s | 7.8 s | +58 ms | 0.7% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/rss_peak | 110.9 MB | 112.2 MB | +1.3 MB | 1.2% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
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
| multi-day-application-logs-heatmap | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/read_files | 7.7 s | 7.7 s | -17 ms | -0.2% | IMPROVE |
| multi-day-application-logs-heatmap | TIMING/calculate_statistics | 183 ms | 188 ms | +5 ms | 2.7% | REGRESS |
| multi-day-application-logs-heatmap | TIMING/normalize_data | 2 ms | 1 ms | -1 ms | -50.0% | IMPROVE |
| multi-day-application-logs-heatmap | TIMING/total | 7.9 s | 7.9 s | -13 ms | -0.2% | IMPROVE |
| multi-day-application-logs-heatmap | MEMORY/rss_peak | 111.1 MB | 115.5 MB | +4.5 MB | 4.0% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_messages | 45.8 MB | 45.8 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_occurrences | 56.6 KB | 56.7 KB | +64 B | 0.1% | REGRESS |
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
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/read_files | 50 s | 48.0 s | -2.1 s | -4.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/group_similar | 5.6 s | 4.3 s | -1.3 s | -23.5% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | 181 ms | 138 ms | -43 ms | -23.8% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/heatmap_statistics | 537 ms | 19 ms | -518 ms | -96.5% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/histogram_statistics | 680 ms | 4 ms | -676 ms | -99.4% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/total | 57 s | 52.4 s | -4.6 s | -8.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 294.1 MB | 232.4 MB | -61.7 MB | -21.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 29.5 MB | 29.5 MB | +58 B | 0.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 5.8 MB | 5.8 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 62.6 MB | 62.6 MB | -2 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 4.5 MB | 4.5 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 61.3 MB | 61.2 MB | -15.4 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 202 KB | 202.2 KB | +218 B | 0.1% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 478.1 KB | 478.1 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 3.3 MB | 3.3 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 41.5 KB | 42.3 KB | +784 B | 1.8% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 28.4 MB | 120 B | -28.4 MB | -100.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 29.8 MB | 576 B | -29.8 MB | -100.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 20.7 KB | 20.9 KB | +256 B | 1.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 28.6 MB | 28.6 MB | -4.5 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 20 KB | 20.3 KB | +256 B | 1.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 49.6 KB | 49.8 KB | +256 B | 0.5% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 30006420 | 30001812 | -4608 | -0.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 20086 | 20342 | 256 | 1.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 30969882 | 30969940 | 58 | 0.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 206885 | 207103 | 218 | 0.1% | REGRESS |
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
| multi-day-custom-logs-heatmap-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/read_files | 16.3 s | 16.8 s | +535 ms | 3.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | TIMING/calculate_statistics | 334 ms | 304 ms | -30 ms | -9.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/heatmap_statistics | 419 ms | 15 ms | -404 ms | -96.4% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/histogram_statistics | 543 ms | 3 ms | -540 ms | -99.4% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/total | 17.6 s | 17.1 s | -438 ms | -2.5% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/rss_peak | 248.3 MB | 177.2 MB | -71.1 MB | -28.6% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_data | 43.2 KB | 42.9 KB | -304 B | -0.7% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_raw | 28.4 MB | 120 B | -28.4 MB | -100.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_values | 29.8 MB | 576 B | -29.8 MB | -100.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_analysis | 20.7 KB | 20.9 KB | +256 B | 1.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_messages | 103.1 MB | 103.1 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_occurrences | 20 KB | 20.3 KB | +256 B | 1.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_stats | 49.6 KB | 49.8 KB | +256 B | 0.5% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 108064422 | 108064422 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 20086 | 20342 | 256 | 1.3% | REGRESS |
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
| multi-day-custom-logs-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/read_files | 15.9 s | 16.3 s | +454 ms | 2.9% | REGRESS |
| multi-day-custom-logs-histogram | TIMING/calculate_statistics | 404 ms | 384 ms | -20 ms | -5.0% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/histogram_statistics | 538 ms | 3 ms | -535 ms | -99.4% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/total | 16.8 s | 16.7 s | -102 ms | -0.6% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/rss_peak | 242.0 MB | 199.2 MB | -42.8 MB | -17.7% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/histogram_values | 29.8 MB | 576 B | -29.8 MB | -100.0% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/log_analysis | 28.4 MB | 28.4 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_messages | 103.1 MB | 103.1 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_stats | 54.7 KB | 54.7 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY_FINAL/log_messages | 108064422 | 108064422 | 0 | 0.0% |  |
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
| multi-day-custom-logs-heatmap | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/read_files | 15.9 s | 16.1 s | +238 ms | 1.5% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/calculate_statistics | 330 ms | 301 ms | -29 ms | -8.8% | IMPROVE |
| multi-day-custom-logs-heatmap | TIMING/heatmap_statistics | 411 ms | 15 ms | -396 ms | -96.4% | IMPROVE |
| multi-day-custom-logs-heatmap | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/total | 16.6 s | 16.5 s | -187 ms | -1.1% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/rss_peak | 206.5 MB | 179.6 MB | -26.8 MB | -13.0% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_data | 42.7 KB | 43.5 KB | +848 B | 1.9% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_raw | 28.4 MB | 120 B | -28.4 MB | -100.0% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_analysis | 20.9 KB | 20.9 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_messages | 102.6 MB | 103.1 MB | +481.4 KB | 0.5% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_stats | 49.8 KB | 49.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/log_messages | 107569190 | 108062118 | 492928 | 0.5% | REGRESS |
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
| multi-day-custom-logs-top25-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/read_files | 49.8 s | 46.8 s | -3.0 s | -5.9% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/group_similar | 5.2 s | 4.6 s | -641 ms | -12.2% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/calculate_statistics | 329 ms | 300 ms | -29 ms | -8.8% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/total | 55.3 s | 51.7 s | -3.6 s | -6.6% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/rss_peak | 255.0 MB | 257.0 MB | +2 MB | 0.8% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_clusters | 29.5 MB | 29.5 MB | -40 B | -0.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_message | 5.8 MB | 5.8 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 62.6 MB | 62.6 MB | +10 KB | 0.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 4.5 MB | 4.5 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_ngram_index | 61.3 MB | 61.3 MB | -5.8 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_patterns | 201.9 KB | 201.9 KB | +22 B | 0.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_posting_size | 478.1 KB | 478.1 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_unmatched | 3.3 MB | 3.3 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_analysis | 28.4 MB | 28.4 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_messages | 28.6 MB | 28.6 MB | -3.9 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_stats | 54.7 KB | 54.7 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/log_messages | 30013620 | 30009652 | -3968 | -0.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 20342 | 20342 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 30969856 | 30969816 | -40 | -0.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 206763 | 206785 | 22 | 0.0% | REGRESS |
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
| multi-day-custom-logs-top25 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/read_files | 16.3 s | 15.6 s | -733 ms | -4.5% | IMPROVE |
| multi-day-custom-logs-top25 | TIMING/calculate_statistics | 423 ms | 390 ms | -33 ms | -7.8% | IMPROVE |
| multi-day-custom-logs-top25 | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/total | 16.7 s | 16.0 s | -766 ms | -4.6% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/rss_peak | 200.5 MB | 200.4 MB | -144 KB | -0.1% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_analysis | 28.4 MB | 28.4 MB | +256 B | 0.0% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/log_messages | 103.1 MB | 102.6 MB | -487.8 KB | -0.5% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/log_occurrences | 20 KB | 20.3 KB | +256 B | 1.2% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_stats | 54.4 KB | 54.7 KB | +256 B | 0.5% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY_FINAL/log_messages | 108082422 | 107582966 | -499456 | -0.5% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY_FINAL/log_analysis | 20086 | 20342 | 256 | 1.3% | REGRESS |
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
| multi-day-custom-logs-standard | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/read_files | 16.2 s | 15.7 s | -511 ms | -3.2% | IMPROVE |
| multi-day-custom-logs-standard | TIMING/calculate_statistics | 436 ms | 386 ms | -50 ms | -11.5% | IMPROVE |
| multi-day-custom-logs-standard | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/total | 16.7 s | 16.1 s | -561 ms | -3.4% | IMPROVE |
| multi-day-custom-logs-standard | MEMORY/rss_peak | 203.7 MB | 199.1 MB | -4.6 MB | -2.2% | IMPROVE |
| multi-day-custom-logs-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_analysis | 28.4 MB | 28.4 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_messages | 102.6 MB | 102.6 MB | +192 B | 0.0% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_stats | 54.7 KB | 54.7 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY_FINAL/log_messages | 107568998 | 107569190 | 192 | 0.0% | REGRESS |
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
| single-day-access-log-heatmap-histogram-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/read_files | 12.1 s | 13.2 s | +1.1 s | 9.4% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/group_similar | 6.2 s | 2.8 s | -3.4 s | -55.0% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/calculate_statistics | 319 ms | 196 ms | -123 ms | -38.6% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/heatmap_statistics | 691 ms | 8 ms | -683 ms | -98.8% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/histogram_statistics | 1.6 s | 3 ms | -1.6 s | -99.8% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/normalize_data | 2 ms | 1 ms | -1 ms | -50.0% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/total | 20.9 s | 16.2 s | -4.7 s | -22.4% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 329.0 MB | 167.1 MB | -161.8 MB | -49.2% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 49.8 MB | 48.5 MB | -1.3 MB | -2.5% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 883 KB | 883 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 4.1 MB | 4.1 MB | -2.5 KB | -0.1% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 4.8 MB | 4.8 MB | +2.2 KB | 0.0% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 123.4 KB | 120.4 KB | -3 KB | -2.4% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 352.5 KB | 352.5 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 565.1 KB | 565.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_data | 34 KB | 34 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 39.9 MB | 120 B | -39.9 MB | -100.0% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_values | 90.1 MB | 576 B | -90.1 MB | -100.0% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_analysis | 8.1 KB | 8.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_messages | 55.5 MB | 55.5 MB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_stats | 28.5 KB | 28.5 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 57377795 | 56068831 | -1308964 | -2.3% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 6670 | 6670 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 52209401 | 50888429 | -1320972 | -2.5% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 125445 | 123177 | -2268 | -1.8% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 296 | 296 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 16440 | 16440 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 597 | 596 | -1 | -0.2% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/read_files | 10.0 s | 11.8 s | +1.8 s | 18.2% | REGRESS |
| single-day-access-log-heatmap-histogram | TIMING/calculate_statistics | 71 ms | 55 ms | -16 ms | -22.5% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/heatmap_statistics | 605 ms | 8 ms | -597 ms | -98.7% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/histogram_statistics | 1.6 s | 3 ms | -1.6 s | -99.8% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/total | 12.2 s | 11.8 s | -380 ms | -3.1% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/rss_peak | 292.1 MB | 120.8 MB | -171.4 MB | -58.7% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_data | 34 KB | 34 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_raw | 39.9 MB | 120 B | -39.9 MB | -100.0% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_values | 90.1 MB | 576 B | -90.1 MB | -100.0% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/log_analysis | 8.1 KB | 8.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_messages | 55.5 MB | 55.5 MB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_stats | 28.5 KB | 28.5 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/log_messages | 58191194 | 58191194 | 0 | 0.0% |  |
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
| single-day-access-log-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | TIMING/read_files | 9.8 s | 11.1 s | +1.3 s | 13.3% | REGRESS |
| single-day-access-log-histogram | TIMING/calculate_statistics | 238 ms | 196 ms | -42 ms | -17.6% | IMPROVE |
| single-day-access-log-histogram | TIMING/histogram_statistics | 1.6 s | 3 ms | -1.6 s | -99.8% | IMPROVE |
| single-day-access-log-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/total | 11.6 s | 11.3 s | -311 ms | -2.7% | IMPROVE |
| single-day-access-log-histogram | MEMORY/rss_peak | 288.3 MB | 154.6 MB | -133.7 MB | -46.4% | IMPROVE |
| single-day-access-log-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/histogram_values | 90.1 MB | 576 B | -90.1 MB | -100.0% | IMPROVE |
| single-day-access-log-histogram | MEMORY/log_analysis | 52.7 MB | 52.7 MB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_messages | 55.5 MB | 55.5 MB | -6.9 KB | -0.0% | IMPROVE |
| single-day-access-log-histogram | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_stats | 31.6 KB | 31.6 KB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY_FINAL/log_messages | 58191194 | 58184154 | -7040 | -0.0% | IMPROVE |
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
| single-day-access-log-heatmap | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | TIMING/read_files | 9.4 s | 10 s | +663 ms | 7.1% | REGRESS |
| single-day-access-log-heatmap | TIMING/calculate_statistics | 60 ms | 55 ms | -5 ms | -8.3% | IMPROVE |
| single-day-access-log-heatmap | TIMING/heatmap_statistics | 571 ms | 8 ms | -563 ms | -98.6% | IMPROVE |
| single-day-access-log-heatmap | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap | TIMING/total | 10 s | 10.1 s | +95 ms | 0.9% | REGRESS |
| single-day-access-log-heatmap | MEMORY/rss_peak | 160.4 MB | 120.1 MB | -40.3 MB | -25.1% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_data | 34 KB | 34 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_raw | 39.9 MB | 120 B | -39.9 MB | -100.0% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_analysis | 8.1 KB | 8.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_messages | 55.3 MB | 55.5 MB | +198.4 KB | 0.4% | REGRESS |
| single-day-access-log-heatmap | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_stats | 28.5 KB | 28.5 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY_FINAL/log_messages | 57988058 | 58191194 | 203136 | 0.4% | REGRESS |
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
| single-day-access-log-top25-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/read_files | 11.0 s | 10.7 s | -293 ms | -2.7% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/group_similar | 4.4 s | 3.9 s | -514 ms | -11.7% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/calculate_statistics | 373 ms | 355 ms | -18 ms | -4.8% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/total | 15.8 s | 14.9 s | -826 ms | -5.2% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/rss_peak | 194.0 MB | 193.4 MB | -544 KB | -0.3% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_clusters | 48.5 MB | 48.6 MB | +79.8 KB | 0.2% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_message | 883 KB | 883 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_trigrams | 4.1 MB | 4.1 MB | -8.5 KB | -0.2% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_ngram_index | 4.8 MB | 4.8 MB | -3.2 KB | -0.1% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_patterns | 122.0 KB | 122.5 KB | +572 B | 0.5% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_posting_size | 352.5 KB | 352.5 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_unmatched | 565.1 KB | 565.1 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_analysis | 52.7 MB | 52.7 MB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_messages | 55.5 MB | 55.5 MB | +6.9 KB | 0.0% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_stats | 31.6 KB | 31.6 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/log_messages | 56099052 | 56094345 | -4707 | -0.0% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/log_analysis | 6670 | 6670 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 50832213 | 50913902 | 81689 | 0.2% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 123965 | 125489 | 1524 | 1.2% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 296 | 296 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 16440 | 16440 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/log_messages_entries | 614 | 603 | -11 | -1.8% | IMPROVE |
| single-day-access-log-top25-consolidate | COUNTS/log_occurrences_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/log_stats_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-top25 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | TIMING/read_files | 9.4 s | 9.2 s | -130 ms | -1.4% | IMPROVE |
| single-day-access-log-top25 | TIMING/calculate_statistics | 245 ms | 221 ms | -24 ms | -9.8% | IMPROVE |
| single-day-access-log-top25 | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25 | TIMING/total | 9.6 s | 9.5 s | -154 ms | -1.6% | IMPROVE |
| single-day-access-log-top25 | MEMORY/rss_peak | 156.5 MB | 156.2 MB | -208 KB | -0.1% | IMPROVE |
| single-day-access-log-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_analysis | 52.7 MB | 52.7 MB | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_messages | 55.5 MB | 55.5 MB | +6.9 KB | 0.0% | REGRESS |
| single-day-access-log-top25 | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_stats | 31.6 KB | 31.6 KB | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY_FINAL/log_messages | 58197970 | 58205010 | 7040 | 0.0% | REGRESS |
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
| single-day-access-log-standard | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | TIMING/read_files | 9.2 s | 9.3 s | +28 ms | 0.3% | REGRESS |
| single-day-access-log-standard | TIMING/calculate_statistics | 209 ms | 198 ms | -11 ms | -5.3% | IMPROVE |
| single-day-access-log-standard | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-standard | TIMING/total | 9.4 s | 9.5 s | +16 ms | 0.2% | REGRESS |
| single-day-access-log-standard | MEMORY/rss_peak | 157.8 MB | 156.4 MB | -1.4 MB | -0.9% | IMPROVE |
| single-day-access-log-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_analysis | 52.7 MB | 52.7 MB | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_messages | 55.5 MB | 55.5 MB | +6.9 KB | 0.0% | REGRESS |
| single-day-access-log-standard | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_stats | 31.6 KB | 31.6 KB | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY_FINAL/log_messages | 58184154 | 58191194 | 7040 | 0.0% | REGRESS |
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
| multi-day-application-logs-top25-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/read_files | 38 s | 36.3 s | -1.8 s | -4.6% | IMPROVE |
| multi-day-application-logs-top25-consolidate | TIMING/group_similar | 4.9 s | 4.3 s | -663 ms | -13.4% | IMPROVE |
| multi-day-application-logs-top25-consolidate | TIMING/calculate_statistics | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/total | 43.0 s | 40.5 s | -2.4 s | -5.6% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | 230.1 MB | 223.3 MB | -6.8 MB | -3.0% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_clusters | 3.6 MB | 3.6 MB | -60 B | -0.0% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_message | 3.5 MB | 3.5 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 62.2 MB | 62.2 MB | +4 KB | 0.0% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 10.4 MB | 10.4 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_ngram_index | 60.8 MB | 60.8 MB | +1.4 KB | 0.0% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_patterns | 485.9 KB | 485.8 KB | -120 B | -0.0% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_posting_size | 1.6 MB | 1.6 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_unmatched | 2.1 MB | 2.1 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
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
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 3738296 | 3738236 | -60 | -0.0% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 497578 | 497458 | -120 | -0.0% | IMPROVE |
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
| multi-day-application-logs-top25 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/read_files | 7.7 s | 7.7 s | +4 ms | 0.1% | REGRESS |
| multi-day-application-logs-top25 | TIMING/calculate_statistics | 203 ms | 179 ms | -24 ms | -11.8% | IMPROVE |
| multi-day-application-logs-top25 | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/total | 7.9 s | 7.9 s | -20 ms | -0.3% | IMPROVE |
| multi-day-application-logs-top25 | MEMORY/rss_peak | 113.1 MB | 113.8 MB | +704 KB | 0.6% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_messages | 45.8 MB | 45.8 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_occurrences | 56.6 KB | 56.7 KB | +64 B | 0.1% | REGRESS |
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
| multi-day-application-logs-standard | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-standard | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-standard | TIMING/read_files | 7.6 s | 7.6 s | -45 ms | -0.6% | IMPROVE |
| multi-day-application-logs-standard | TIMING/calculate_statistics | 185 ms | 196 ms | +11 ms | 5.9% | REGRESS |
| multi-day-application-logs-standard | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-standard | TIMING/total | 7.8 s | 7.8 s | -34 ms | -0.4% | IMPROVE |
| multi-day-application-logs-standard | MEMORY/rss_peak | 112.5 MB | 112.9 MB | +432 KB | 0.4% | REGRESS |
| multi-day-application-logs-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_messages | 45.8 MB | 45.8 MB | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_occurrences | 56.7 KB | 56.6 KB | -64 B | -0.1% | IMPROVE |
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
| single-day-application-log-heatmap-histogram-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/read_files | 6.3 s | 6.1 s | -128 ms | -2.0% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/group_similar | 279 ms | 264 ms | -15 ms | -5.4% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/normalize_data | 2 ms | 1 ms | -1 ms | -50.0% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/total | 6.5 s | 6.4 s | -142 ms | -2.2% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 122.7 MB | 124.4 MB | +1.8 MB | 1.4% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 437.5 KB | 437.5 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 2.6 MB | 2.6 MB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 29.3 MB | 29.3 MB | +1 KB | 0.0% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 16.4 MB | 16.4 MB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 29.7 MB | 29.7 MB | -2.6 KB | -0.0% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 54.3 KB | 54.3 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 860.9 KB | 860.9 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 1.5 MB | 1.5 MB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_messages | 2.3 MB | 2.3 MB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 137524 | 137524 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 448005 | 448005 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 55576 | 55576 | 0 | 0.0% |  |
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
| single-day-application-log-heatmap-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/read_files | 3.5 s | 3.6 s | +22 ms | 0.6% | REGRESS |
| single-day-application-log-heatmap-histogram | TIMING/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/total | 3.5 s | 3.6 s | +23 ms | 0.6% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/rss_peak | 33.5 MB | 34.8 MB | +1.2 MB | 3.6% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
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
| single-day-application-log-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | TIMING/read_files | 3.6 s | 3.5 s | -85 ms | -2.4% | IMPROVE |
| single-day-application-log-histogram | TIMING/calculate_statistics | 6 ms | 7 ms | +1 ms | 16.7% | REGRESS |
| single-day-application-log-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-histogram | TIMING/total | 3.6 s | 3.5 s | -86 ms | -2.4% | IMPROVE |
| single-day-application-log-histogram | MEMORY/rss_peak | 33.2 MB | 35.4 MB | +2.2 MB | 6.6% | REGRESS |
| single-day-application-log-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
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
| single-day-application-log-heatmap | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | TIMING/read_files | 3.5 s | 3.5 s | -12 ms | -0.3% | IMPROVE |
| single-day-application-log-heatmap | TIMING/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap | TIMING/total | 3.6 s | 3.5 s | -12 ms | -0.3% | IMPROVE |
| single-day-application-log-heatmap | MEMORY/rss_peak | 33.3 MB | 35.4 MB | +2.1 MB | 6.2% | REGRESS |
| single-day-application-log-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
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
| single-day-application-log-top25-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/read_files | 6.3 s | 6.1 s | -187 ms | -3.0% | IMPROVE |
| single-day-application-log-top25-consolidate | TIMING/group_similar | 288 ms | 257 ms | -31 ms | -10.8% | IMPROVE |
| single-day-application-log-top25-consolidate | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/total | 6.6 s | 6.4 s | -218 ms | -3.3% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/rss_peak | 120.8 MB | 122.6 MB | +1.8 MB | 1.5% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_clusters | 437.5 KB | 437.3 KB | -256 B | -0.1% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_message | 2.6 MB | 2.6 MB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_trigrams | 28.4 MB | 28.4 MB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 15.6 MB | 15.6 MB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_ngram_index | 29.7 MB | 29.7 MB | -2.1 KB | -0.0% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_patterns | 54.4 KB | 54.4 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_posting_size | 860.9 KB | 860.9 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_unmatched | 1.5 MB | 1.5 MB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
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
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 448047 | 447791 | -256 | -0.1% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 55660 | 55660 | 0 | 0.0% |  |
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
| single-day-application-log-top25 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | TIMING/read_files | 3.6 s | 3.5 s | -43 ms | -1.2% | IMPROVE |
| single-day-application-log-top25 | TIMING/calculate_statistics | 7 ms | 6 ms | -1 ms | -14.3% | IMPROVE |
| single-day-application-log-top25 | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25 | TIMING/total | 3.6 s | 3.5 s | -44 ms | -1.2% | IMPROVE |
| single-day-application-log-top25 | MEMORY/rss_peak | 33.6 MB | 35.3 MB | +1.7 MB | 5.2% | REGRESS |
| single-day-application-log-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
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
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/read_files | 6.7 s | 6.4 s | -349 ms | -5.2% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/group_similar | 4.3 s | 3.9 s | -443 ms | -10.2% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/total | 11 s | 10.3 s | -792 ms | -7.2% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/rss_peak | 246.9 MB | 248.5 MB | +1.6 MB | 0.6% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 196.2 KB | 196.2 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 3.1 MB | 3.1 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 71.7 MB | 71.7 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 64.2 MB | 64.2 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 66.7 MB | 66.7 MB | +2.8 KB | 0.0% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 24.9 KB | 24.9 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 614.1 KB | 614.1 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 1.7 MB | 1.7 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
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
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 25503 | 25503 | 0 | 0.0% |  |
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
| humungous-log-uniqueness-heatmap-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/read_files | 2.3 s | 2.3 s | +25 ms | 1.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | TIMING/calculate_statistics | 288 ms | 267 ms | -21 ms | -7.3% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/total | 2.5 s | 2.6 s | +4 ms | 0.2% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/rss_peak | 200.3 MB | 203.5 MB | +3.3 MB | 1.6% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
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
| humungous-log-uniqueness-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/read_files | 2.3 s | 2.3 s | -30 ms | -1.3% | IMPROVE |
| humungous-log-uniqueness-histogram | TIMING/calculate_statistics | 305 ms | 276 ms | -29 ms | -9.5% | IMPROVE |
| humungous-log-uniqueness-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/total | 2.6 s | 2.5 s | -59 ms | -2.3% | IMPROVE |
| humungous-log-uniqueness-histogram | MEMORY/rss_peak | 200.8 MB | 203.5 MB | +2.8 MB | 1.4% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
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
| humungous-log-uniqueness-heatmap | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/read_files | 2.3 s | 2.2 s | -22 ms | -1.0% | IMPROVE |
| humungous-log-uniqueness-heatmap | TIMING/calculate_statistics | 276 ms | 268 ms | -8 ms | -2.9% | IMPROVE |
| humungous-log-uniqueness-heatmap | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/total | 2.5 s | 2.5 s | -30 ms | -1.2% | IMPROVE |
| humungous-log-uniqueness-heatmap | MEMORY/rss_peak | 201.4 MB | 203.2 MB | +1.8 MB | 0.9% | REGRESS |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
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
| humungous-log-uniqueness-top25-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/read_files | 6.5 s | 6.3 s | -213 ms | -3.3% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | TIMING/group_similar | 4.3 s | 4 s | -275 ms | -6.4% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/total | 10.8 s | 10.3 s | -488 ms | -4.5% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/rss_peak | 247.4 MB | 249.1 MB | +1.7 MB | 0.7% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_clusters | 196.2 KB | 196.2 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_message | 3.1 MB | 3.1 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_trigrams | 71.8 MB | 71.8 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 64.3 MB | 64.3 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_ngram_index | 66.7 MB | 66.7 MB | -4.8 KB | -0.0% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_patterns | 24.9 KB | 24.9 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_posting_size | 614.1 KB | 614.1 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_unmatched | 1.7 MB | 1.7 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
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
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 25503 | 25503 | 0 | 0.0% |  |
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
| humungous-log-uniqueness-top25 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/read_files | 2.3 s | 2.3 s | +8 ms | 0.3% | REGRESS |
| humungous-log-uniqueness-top25 | TIMING/calculate_statistics | 281 ms | 273 ms | -8 ms | -2.8% | IMPROVE |
| humungous-log-uniqueness-top25 | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/total | 2.6 s | 2.6 s | +1000 us | 0.0% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY/rss_peak | 201.3 MB | 203.5 MB | +2.2 MB | 1.1% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
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
| humungous-log-uniqueness-standard | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/read_files | 2.3 s | 2.3 s | +9 ms | 0.4% | REGRESS |
| humungous-log-uniqueness-standard | TIMING/calculate_statistics | 313 ms | 275 ms | -38 ms | -12.1% | IMPROVE |
| humungous-log-uniqueness-standard | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/total | 2.6 s | 2.6 s | -29 ms | -1.1% | IMPROVE |
| humungous-log-uniqueness-standard | MEMORY/rss_peak | 201.3 MB | 202.7 MB | +1.3 MB | 0.7% | REGRESS |
| humungous-log-uniqueness-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
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
| single-day-application-log-standard | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | TIMING/read_files | 3.5 s | 3.5 s | -3 ms | -0.1% | IMPROVE |
| single-day-application-log-standard | TIMING/calculate_statistics | 7 ms | 6 ms | -1 ms | -14.3% | IMPROVE |
| single-day-application-log-standard | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-standard | TIMING/total | 3.5 s | 3.5 s | -4 ms | -0.1% | IMPROVE |
| single-day-application-log-standard | MEMORY/rss_peak | 33.4 MB | 35.3 MB | +1.9 MB | 5.8% | REGRESS |
| single-day-application-log-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
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
| month-single-server-access-logs-standard | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/read_files | 1.7 min | 1.7 min | +1.6 s | 1.5% | REGRESS |
| month-single-server-access-logs-standard | TIMING/calculate_statistics | 5.4 s | 5.7 s | +302 ms | 5.6% | REGRESS |
| month-single-server-access-logs-standard | TIMING/normalize_data | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| month-single-server-access-logs-standard | TIMING/total | 1.8 min | 1.8 min | +1.9 s | 1.7% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/rss_peak | 2.7 GB | 2.7 GB | -16.7 MB | -0.6% | IMPROVE |
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
| month-single-server-access-logs-standard | MEMORY/log_messages | 1.6 GB | 1.6 GB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_occurrences | 36.6 KB | 36.8 KB | +192 B | 0.5% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_stats | 60.0 KB | 60.0 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY_FINAL/log_messages | 1730917915 | 1730917915 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | COUNTS/log_messages_entries | 1212275 | 1212275 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| month-single-server-access-logs-standard | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/read_files | 1.7 min | 1.8 min | +1.3 s | 1.2% | REGRESS |
| month-single-server-access-logs-top25 | TIMING/calculate_statistics | 5.6 s | 5.9 s | +271 ms | 4.8% | REGRESS |
| month-single-server-access-logs-top25 | TIMING/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/total | 1.8 min | 1.9 min | +1.6 s | 1.4% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/rss_peak | 2.6 GB | 2.7 GB | +74.3 MB | 2.8% | REGRESS |
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
| month-single-server-access-logs-top25 | MEMORY/log_messages | 1.5 GB | 1.6 GB | +72.2 MB | 4.6% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/log_occurrences | 36.8 KB | 36.6 KB | -192 B | -0.5% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_stats | 60.0 KB | 60.0 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY_FINAL/log_messages | 1655260931 | 1730932163 | 75671232 | 4.6% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | COUNTS/log_messages_entries | 1212275 | 1212275 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| month-single-server-access-logs-top25 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/read_files | 2.1 min | 2.4 min | +13.3 s | 10.3% | REGRESS |
| month-single-server-access-logs-top25-consolidate | TIMING/group_similar | 4.5 s | 1.8 min | +1.7 min | 2260.3% | REGRESS |
| month-single-server-access-logs-top25-consolidate | TIMING/calculate_statistics | 7.8 s | 8.6 s | +864 ms | 11.1% | REGRESS |
| month-single-server-access-logs-top25-consolidate | TIMING/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/total | 2.4 min | 4.3 min | +1.9 min | 81.6% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | 1.7 GB | 1.7 GB | +7.8 MB | 0.5% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_clusters | 507.7 MB | 506.7 MB | -1 MB | -0.2% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_message | 149.4 KB | 2.5 MB | +2.3 MB | 1590.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_patterns | 257.2 KB | 294 KB | +36.8 KB | 14.3% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | 198.5 KB | 1.6 MB | +1.4 MB | 700.3% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_analysis | 567.4 MB | 567.4 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_messages | 568.1 MB | 567.8 MB | -350.1 KB | -0.1% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_occurrences | 36.6 KB | 36.8 KB | +192 B | 0.5% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_stats | 60.0 KB | 60.0 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/log_messages | 595725141 | 595366646 | -358495 | -0.1% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 532412788 | 531314378 | -1098410 | -0.2% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 263383 | 262231 | -1152 | -0.4% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 424 | 424 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_messages_entries | 1306 | 1315 | 9 | 0.7% | REGRESS |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/read_files | 1.8 min | 2.0 min | +11.9 s | 11.3% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/calculate_statistics | 2.1 s | 2.2 s | +112 ms | 5.3% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/heatmap_statistics | 12.9 s | 66 ms | -12.8 s | -99.5% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/normalize_data | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/total | 2 min | 2.0 min | -817 ms | -0.7% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/rss_peak | 2.7 GB | 2.2 GB | -602 MB | -21.4% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_data | 77.9 KB | 80.6 KB | +2.7 KB | 3.5% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_raw | 563.6 MB | 120 B | -563.6 MB | -100.0% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_analysis | 15.7 KB | 15.7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_messages | 1.6 GB | 1.6 GB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_occurrences | 36.8 KB | 36.8 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_stats | 54.1 KB | 54.1 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/log_messages | 1732830635 | 1732830635 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | COUNTS/log_messages_entries | 1212275 | 1212275 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| month-single-server-access-logs-heatmap | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/read_files | 1.8 min | 2.2 min | +25 s | 23.2% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/calculate_statistics | 6 s | 5.8 s | -181 ms | -3.0% | IMPROVE |
| month-single-server-access-logs-histogram | TIMING/histogram_statistics | 22.9 s | 7 ms | -22.9 s | -100.0% | IMPROVE |
| month-single-server-access-logs-histogram | TIMING/normalize_data | 3 ms | 2 ms | -1 ms | -33.3% | IMPROVE |
| month-single-server-access-logs-histogram | TIMING/total | 2.3 min | 2.3 min | +1.9 s | 1.4% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/rss_peak | 4 GB | 2.7 GB | -1.3 GB | -33.3% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/histogram_values | 1.1 GB | 576 B | -1.1 GB | -100.0% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/log_analysis | 567.3 MB | 567.3 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_messages | 1.6 GB | 1.6 GB | +1.8 MB | 0.1% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/log_occurrences | 36.6 KB | 36.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_sessions | 2.2 MB | 2.2 MB | -128 B | -0.0% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/log_stats | 60.0 KB | 60.0 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY_FINAL/log_messages | 1730917915 | 1732830683 | 1912768 | 0.1% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | COUNTS/log_messages_entries | 1212275 | 1212275 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| month-single-server-access-logs-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/read_files | 1.8 min | 2.3 min | +27.1 s | 24.6% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/calculate_statistics | 2.3 s | 2.2 s | -35 ms | -1.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/heatmap_statistics | 13.3 s | 66 ms | -13.3 s | -99.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/histogram_statistics | 22.8 s | 7 ms | -22.8 s | -100.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/normalize_data | 3 ms | 2 ms | -1 ms | -33.3% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/total | 2.5 min | 2.3 min | -9 s | -6.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/rss_peak | 4.1 GB | 2.2 GB | -1.9 GB | -47.4% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_data | 78.4 KB | 81.1 KB | +2.7 KB | 3.5% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_raw | 563.6 MB | 120 B | -563.6 MB | -100.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_values | 1.1 GB | 576 B | -1.1 GB | -100.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_analysis | 15.7 KB | 15.7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_messages | 1.6 GB | 1.6 GB | -1.8 MB | -0.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_occurrences | 36.6 KB | 36.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_stats | 54.1 KB | 54.1 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 1732830635 | 1730917867 | -1912768 | -0.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | COUNTS/log_messages_entries | 1212275 | 1212275 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/read_files | 2.3 min | 2.9 min | +35.5 s | 26.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/group_similar | 4.5 s | 1.3 min | +1.2 min | 1663.9% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | 3.1 s | 3.1 s | -13 ms | -0.4% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/heatmap_statistics | 14.2 s | 63 ms | -14.1 s | -99.6% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/histogram_statistics | 23.0 s | 13 ms | -23.0 s | -99.9% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | 3 min | 4.2 min | +1.2 min | 40.6% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 3.2 GB | 1.3 GB | -1.9 GB | -59.9% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 503.6 MB | 506.9 MB | +3.3 MB | 0.7% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 149.4 KB | 2.5 MB | +2.3 MB | 1588.5% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 252.4 KB | 287.7 KB | +35.3 KB | 14.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 198.5 KB | 1.5 MB | +1.4 MB | 699.6% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 77.9 KB | 82.6 KB | +4.7 KB | 6.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 563.7 MB | 120 B | -563.7 MB | -100.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 1.1 GB | 576 B | -1.1 GB | -100.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 15.7 KB | 15.7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 566.2 MB | 568.6 MB | +2.4 MB | 0.4% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 36.6 KB | 36.8 KB | +192 B | 0.5% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 54.1 KB | 54.1 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 593711105 | 596188946 | 2477841 | 0.4% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 528061739 | 531514381 | 3452642 | 0.7% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 258445 | 257101 | -1344 | -0.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 424 | 424 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 1307 | 1320 | 13 | 1.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | TIMING/read_files | 8.4 min | 8.7 min | +13.6 s | 2.7% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/calculate_statistics | 31.9 s | 35.3 s | +3.4 s | 10.7% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/normalize_data | 3 ms | 4 ms | +1 ms | 33.3% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/total | 9.0 min | 9.2 min | +17.0 s | 3.2% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY/rss_peak | 13.2 GB | 12.3 GB | -937.3 MB | -6.9% | IMPROVE |
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
| month-many-servers-access-logs-standard | MEMORY/log_messages | 8.3 GB | 8.0 GB | -377.6 MB | -4.4% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_stats | 60.1 KB | 60.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY_FINAL/log_messages | 8951243238 | 8555259686 | -395983552 | -4.4% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | COUNTS/log_messages_entries | 6187253 | 6187253 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| month-many-servers-access-logs-standard | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | TIMING/read_files | 8.5 min | 8.7 min | +12 s | 2.4% | REGRESS |
| month-many-servers-access-logs-top25 | TIMING/calculate_statistics | 33.6 s | 35.9 s | +2.3 s | 6.8% | REGRESS |
| month-many-servers-access-logs-top25 | TIMING/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-top25 | TIMING/total | 9 min | 9.3 min | +14.3 s | 2.6% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/rss_peak | 13.2 GB | 13 GB | -118.5 MB | -0.9% | IMPROVE |
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
| month-many-servers-access-logs-top25 | MEMORY/log_messages | 8.3 GB | 8.3 GB | +9.4 MB | 0.1% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/log_occurrences | 43.8 KB | 42.1 KB | -1.8 KB | -4.0% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_stats | 60.1 KB | 60.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/log_messages | 8941409678 | 8951257422 | 9847744 | 0.1% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | COUNTS/log_messages_entries | 6187253 | 6187253 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| month-many-servers-access-logs-top25 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/read_files | 9.8 min | 11.3 min | +1.5 min | 15.1% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | TIMING/group_similar | 24.0 s | 18.4 min | +18.0 min | 4497.6% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | TIMING/calculate_statistics | 41.2 s | 45.0 s | +3.7 s | 9.1% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | TIMING/normalize_data | 3 ms | 4 ms | +1 ms | 33.3% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | 10.9 min | 30.4 min | +19.5 min | 179.0% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | 6.8 GB | 7.2 GB | +404.8 MB | 5.8% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_clusters | 2.7 GB | 2.7 GB | +6.1 MB | 0.2% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_message | 144.1 KB | 2.4 MB | +2.3 MB | 1638.2% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_patterns | 532.8 KB | 528.3 KB | -4.4 KB | -0.8% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | 276.4 KB | 1.7 MB | +1.4 MB | 526.3% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_analysis | 2.9 GB | 2.9 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_messages | 2.9 GB | 2.9 GB | +340.2 KB | 0.0% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_sessions | 14.9 MB | 14.9 MB | +32 KB | 0.2% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_stats | 60.1 KB | 60.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/log_messages | 3095534057 | 3095882470 | 348413 | 0.0% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 2848854331 | 2855254748 | 6400417 | 0.2% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 545553 | 541000 | -4553 | -0.8% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 424 | 424 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_messages_entries | 2560 | 2561 | 1 | 0.0% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/read_files | 8.6 min | 9.7 min | +1.1 min | 12.7% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/calculate_statistics | 12.4 s | 13.3 s | +869 ms | 7.0% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/heatmap_statistics | 1.1 min | 85 ms | -1.1 min | -99.9% | IMPROVE |
| month-many-servers-access-logs-heatmap | TIMING/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/total | 9.9 min | 10.0 min | +3.0 s | 0.5% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/rss_peak | 13.3 GB | 10 GB | -3.3 GB | -24.7% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_data | 76.8 KB | 81.1 KB | +4.3 KB | 5.6% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_raw | 2.9 GB | 120 B | -2.9 GB | -100.0% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_analysis | 15.7 KB | 15.7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_messages | 8.3 GB | 8.3 GB | +4.6 MB | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/log_occurrences | 42.1 KB | 43.8 KB | +1.8 KB | 4.2% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_stats | 54.1 KB | 54.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/log_messages | 8941395470 | 8946183838 | 4788368 | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | COUNTS/log_messages_entries | 6187253 | 6187253 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| month-many-servers-access-logs-heatmap | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/read_files | 8.9 min | 10.8 min | +1.9 min | 21.4% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/calculate_statistics | 35.0 s | 37.2 s | +2.2 s | 6.2% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/histogram_statistics | 1.9 min | 11 ms | -1.9 min | -100.0% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/total | 11.4 min | 11.4 min | -302 ms | -0.0% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/rss_peak | 20.5 GB | 12.2 GB | -8.3 GB | -40.6% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/histogram_values | 5.4 GB | 576 B | -5.4 GB | -100.0% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/log_analysis | 2.9 GB | 2.9 GB | +2.6 MB | 0.1% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/log_messages | 8.3 GB | 8.3 GB | +1.8 MB | 0.0% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -128 B | -0.0% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/log_stats | 60.1 KB | 60.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/log_messages | 8949303382 | 8951243238 | 1939856 | 0.0% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | COUNTS/log_messages_entries | 6187253 | 6187253 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| month-many-servers-access-logs-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/read_files | 9 min | 11.5 min | +2.4 min | 27.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/calculate_statistics | 12.9 s | 14.3 s | +1.3 s | 10.4% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/heatmap_statistics | 1.1 min | 86 ms | -1.1 min | -99.9% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/histogram_statistics | 2.0 min | 11 ms | -2.0 min | -100.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/normalize_data | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/total | 12.3 min | 11.7 min | -34.9 s | -4.7% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/rss_peak | 19.3 GB | 10.2 GB | -9.1 GB | -47.2% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_data | 76.8 KB | 81.1 KB | +4.3 KB | 5.6% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_raw | 2.9 GB | 120 B | -2.9 GB | -100.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_values | 5.4 GB | 576 B | -5.4 GB | -100.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_analysis | 15.7 KB | 15.7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_messages | 8.3 GB | 8.3 GB | -13.5 MB | -0.2% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -32 KB | -0.2% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_stats | 54.1 KB | 54.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 8950522326 | 8936336094 | -14186232 | -0.2% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/log_messages_entries | 6187253 | 6187253 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/read_files | 10.4 min | 14.1 min | +3.7 min | 35.2% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/group_similar | 26.7 s | 14 min | +13.6 min | 3049.7% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | 18.1 s | 17.8 s | -329 ms | -1.8% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/heatmap_statistics | 1.2 min | 78 ms | -1.2 min | -99.9% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/histogram_statistics | 1.9 min | 12 ms | -1.9 min | -100.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/normalize_data | 3 ms | 4 ms | +1 ms | 33.3% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | 14.3 min | 28.4 min | +14.2 min | 99.4% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 15.6 GB | 4.9 GB | -10.7 GB | -68.5% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 2.6 GB | 2.7 GB | +26.7 MB | 1.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 144.1 KB | 2.5 MB | +2.3 MB | 1650.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 518.8 KB | 530.2 KB | +11.4 KB | 2.2% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 276.4 KB | 1.7 MB | +1.4 MB | 530.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 76.3 KB | 80.1 KB | +3.8 KB | 5.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 2.9 GB | 120 B | -2.9 GB | -100.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 5.4 GB | 576 B | -5.4 GB | -100.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 15.7 KB | 15.7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 2.9 GB | 2.9 GB | -12.5 MB | -0.4% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 54.1 KB | 54.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 3102243618 | 3089147575 | -13096043 | -0.4% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 2834607088 | 2862631914 | 28024826 | 1.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 531209 | 542916 | 11707 | 2.2% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 424 | 424 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 2517 | 2542 | 25 | 1.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_counters | N/A | 983.4 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_counters_hl | N/A | 232 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY/histogram_counters | N/A | 121.9 KB | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_counters | N/A | 983.4 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | N/A | 232 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_counters | N/A | 122.1 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | N/A | 983.4 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | N/A | 232 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | N/A | 122.1 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY/heatmap_counters | N/A | 568.8 KB | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY/heatmap_counters_hl | N/A | 232 B | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY/histogram_counters | N/A | 105.6 KB | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_counters | N/A | 569.7 KB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_counters_hl | N/A | 232 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_counters | N/A | 105.6 KB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_counters | N/A | 569.7 KB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | N/A | 232 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_counters | N/A | 105.6 KB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | N/A | 36.8 MB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | N/A | 25.9 MB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_ngram_index | N/A | 36.0 MB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_posting_size | N/A | 973.6 KB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 65592 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 65592 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_counters | N/A | 2.4 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_counters_hl | N/A | 232 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/histogram_counters | N/A | 295.6 KB | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_counters | N/A | 2.4 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | N/A | 232 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_counters | N/A | 295.6 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | N/A | 36.7 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | N/A | 29.4 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | N/A | 36.0 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | N/A | 973.6 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | N/A | 2.4 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | N/A | 232 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | N/A | 295.6 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 65592 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 65592 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | N/A | 36.8 MB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | N/A | 29.2 MB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_ngram_index | N/A | 36.1 MB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_posting_size | N/A | 1.2 MB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 65592 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 65592 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_counters | N/A | 2.7 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_counters_hl | N/A | 232 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/histogram_counters | N/A | 307.4 KB | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_counters | N/A | 2.7 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | N/A | 232 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_counters | N/A | 307.4 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | N/A | 36.8 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | N/A | 25.6 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | N/A | 36.1 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | N/A | 1.2 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | N/A | 2.7 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | N/A | 232 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | N/A | 307.4 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 65592 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 65592 | N/A | N/A | ? |

