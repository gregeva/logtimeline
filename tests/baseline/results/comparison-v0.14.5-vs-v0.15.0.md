
## Benchmark Comparison

  Baseline:    v0.14.5 (v0.14.5, 49 test cases)
  Current:     v0.15.0 (v0.15.0, 49 test cases)

### Timing Delta

| # | file selection | standard | top25 | top25-cons | heatmap | histogram | hm+hg | hm+hg+cons |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. | humungous-log-uniqueness | +78.2% | +75.8% | +2.2% | +72.7% | +73.4% | +70.2% | +1.8% |
| 2. | single-day-application-log | +3.4% | +4.3% | +3.3% | +6.0% | +5.5% | +2.8% | +3.8% |
| 3. | multi-day-application-logs | +7.1% | +5.4% | +2.6% | +6.6% | +7.4% | +6.4% | +0.6% |
| 4. | multi-day-custom-logs | +7.2% | +7.9% | +4.6% | +7.2% | +8.3% | +6.7% | +3.3% |
| 5. | single-day-access-log | +5.1% | +5.4% | +5.8% | +3.9% | +5.3% | +2.5% | +3.9% |
| 6. | month-single-server-access-logs | +12.0% | +13.1% | -1.4% | +10.1% | +7.5% | +7.3% | -3.5% |
| 7. | month-many-servers-access-logs | +15.2% | +15.4% | -6.6% | +15.9% | +13.7% | +11.8% | -4.5% |

### Memory Delta (RSS Peak)

| # | file selection | standard | top25 | top25-cons | heatmap | histogram | hm+hg | hm+hg+cons |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. | humungous-log-uniqueness | +0.5% | +0.7% | +0.6% | +0.9% | +0.6% | +0.5% | +0.9% |
| 2. | single-day-application-log | +4.3% | +4.2% | +2.9% | +4.1% | +3.9% | +6.0% | +1.2% |
| 3. | multi-day-application-logs | +2.8% | +0.6% | +1.6% | -1.1% | +1.8% | +1.3% | +1.0% |
| 4. | multi-day-custom-logs | +2.0% | +0.8% | +3.5% | +0.1% | +1.6% | +1.9% | +5.5% |
| 5. | single-day-access-log | +5.2% | +4.8% | +8.0% | +4.2% | +6.4% | +5.8% | +7.4% |
| 6. | month-single-server-access-logs | -0.5% | -3.8% | +0.8% | -1.8% | -1.0% | -1.8% | +0.1% |
| 7. | month-many-servers-access-logs | +5.6% | -0.4% | -0.1% | -0.5% | +6.5% | -5.4% | +0.1% |

### Summary

| test_name | metric | baseline | current | delta | change% | result |
| --- | --- | --- | --- | --- | --- | --- |
| humungous-log-uniqueness-standard | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/total | 2.6 s | 4.6 s | +2 s | 78.2% | REGRESS |
| humungous-log-uniqueness-standard | MEMORY/rss_peak | 202.7 MB | 203.6 MB | +944 KB | 0.5% | REGRESS |
| humungous-log-uniqueness-top25 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/total | 2.6 s | 4.6 s | +2.0 s | 75.8% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY/rss_peak | 203.5 MB | 204.9 MB | +1.4 MB | 0.7% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/total | 10.3 s | 10.5 s | +231 ms | 2.2% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/rss_peak | 249.1 MB | 250.7 MB | +1.5 MB | 0.6% | REGRESS |
| humungous-log-uniqueness-heatmap | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/total | 2.5 s | 4.3 s | +1.8 s | 72.7% | REGRESS |
| humungous-log-uniqueness-heatmap | MEMORY/rss_peak | 203.2 MB | 205 MB | +1.8 MB | 0.9% | REGRESS |
| humungous-log-uniqueness-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/total | 2.5 s | 4.4 s | +1.9 s | 73.4% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY/rss_peak | 203.5 MB | 204.7 MB | +1.2 MB | 0.6% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/total | 2.6 s | 4.3 s | +1.8 s | 70.2% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/rss_peak | 203.5 MB | 204.5 MB | +1008 KB | 0.5% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/total | 10.3 s | 10.4 s | +180 ms | 1.8% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/rss_peak | 248.5 MB | 250.7 MB | +2.2 MB | 0.9% | REGRESS |
| single-day-application-log-standard | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | TIMING/total | 3.5 s | 3.6 s | +119 ms | 3.4% | REGRESS |
| single-day-application-log-standard | MEMORY/rss_peak | 35.3 MB | 36.8 MB | +1.5 MB | 4.3% | REGRESS |
| single-day-application-log-top25 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | TIMING/total | 3.5 s | 3.7 s | +153 ms | 4.3% | REGRESS |
| single-day-application-log-top25 | MEMORY/rss_peak | 35.3 MB | 36.8 MB | +1.5 MB | 4.2% | REGRESS |
| single-day-application-log-top25-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/total | 6.4 s | 6.6 s | +208 ms | 3.3% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/rss_peak | 122.6 MB | 126.2 MB | +3.6 MB | 2.9% | REGRESS |
| single-day-application-log-heatmap | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | TIMING/total | 3.5 s | 3.8 s | +214 ms | 6.0% | REGRESS |
| single-day-application-log-heatmap | MEMORY/rss_peak | 35.4 MB | 36.8 MB | +1.4 MB | 4.1% | REGRESS |
| single-day-application-log-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | TIMING/total | 3.5 s | 3.7 s | +192 ms | 5.5% | REGRESS |
| single-day-application-log-histogram | MEMORY/rss_peak | 35.4 MB | 36.8 MB | +1.4 MB | 3.9% | REGRESS |
| single-day-application-log-heatmap-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/total | 3.6 s | 3.7 s | +100 ms | 2.8% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/rss_peak | 34.8 MB | 36.8 MB | +2.1 MB | 6.0% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/total | 6.4 s | 6.6 s | +240 ms | 3.8% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 124.4 MB | 126.0 MB | +1.5 MB | 1.2% | REGRESS |
| multi-day-application-logs-standard | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-standard | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-standard | TIMING/total | 7.8 s | 8.3 s | +551 ms | 7.1% | REGRESS |
| multi-day-application-logs-standard | MEMORY/rss_peak | 112.9 MB | 116.1 MB | +3.2 MB | 2.8% | REGRESS |
| multi-day-application-logs-top25 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/total | 7.9 s | 8.3 s | +425 ms | 5.4% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/rss_peak | 113.8 MB | 114.5 MB | +736 KB | 0.6% | REGRESS |
| multi-day-application-logs-top25-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/total | 40.5 s | 41.6 s | +1 s | 2.6% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | 223.3 MB | 226.9 MB | +3.6 MB | 1.6% | REGRESS |
| multi-day-application-logs-heatmap | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/total | 7.9 s | 8.4 s | +517 ms | 6.6% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY/rss_peak | 115.5 MB | 114.2 MB | -1.3 MB | -1.1% | IMPROVE |
| multi-day-application-logs-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/total | 7.8 s | 8.4 s | +581 ms | 7.4% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/rss_peak | 112.2 MB | 114.3 MB | +2 MB | 1.8% | REGRESS |
| multi-day-application-logs-heatmap-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/total | 7.7 s | 8.2 s | +493 ms | 6.4% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/rss_peak | 113.1 MB | 114.5 MB | +1.5 MB | 1.3% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | 40.9 s | 41.2 s | +241 ms | 0.6% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 223.4 MB | 225.6 MB | +2.2 MB | 1.0% | REGRESS |
| multi-day-custom-logs-standard | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/total | 16.1 s | 17.2 s | +1.2 s | 7.2% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/rss_peak | 199.1 MB | 203.1 MB | +4.0 MB | 2.0% | REGRESS |
| multi-day-custom-logs-top25 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/total | 16.0 s | 17.2 s | +1.3 s | 7.9% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/rss_peak | 200.4 MB | 202.0 MB | +1.6 MB | 0.8% | REGRESS |
| multi-day-custom-logs-top25-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/total | 51.7 s | 54.1 s | +2.4 s | 4.6% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/rss_peak | 257.0 MB | 265.9 MB | +8.9 MB | 3.5% | REGRESS |
| multi-day-custom-logs-heatmap | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/total | 16.5 s | 17.6 s | +1.2 s | 7.2% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/rss_peak | 179.6 MB | 179.9 MB | +272 KB | 0.1% | REGRESS |
| multi-day-custom-logs-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/total | 16.7 s | 18.1 s | +1.4 s | 8.3% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/rss_peak | 199.2 MB | 202.5 MB | +3.3 MB | 1.6% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/total | 17.1 s | 18.3 s | +1.1 s | 6.7% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/rss_peak | 177.2 MB | 180.5 MB | +3.3 MB | 1.9% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/total | 52.4 s | 54.1 s | +1.7 s | 3.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 232.4 MB | 245.2 MB | +12.8 MB | 5.5% | REGRESS |
| single-day-access-log-standard | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | TIMING/total | 9.5 s | 9.9 s | +483 ms | 5.1% | REGRESS |
| single-day-access-log-standard | MEMORY/rss_peak | 156.4 MB | 164.5 MB | +8.1 MB | 5.2% | REGRESS |
| single-day-access-log-top25 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | TIMING/total | 9.5 s | 10.0 s | +513 ms | 5.4% | REGRESS |
| single-day-access-log-top25 | MEMORY/rss_peak | 156.2 MB | 163.8 MB | +7.5 MB | 4.8% | REGRESS |
| single-day-access-log-top25-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/total | 14.9 s | 15.8 s | +866 ms | 5.8% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/rss_peak | 193.4 MB | 208.8 MB | +15.4 MB | 8.0% | REGRESS |
| single-day-access-log-heatmap | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | TIMING/total | 10.1 s | 10.5 s | +390 ms | 3.9% | REGRESS |
| single-day-access-log-heatmap | MEMORY/rss_peak | 120.1 MB | 125.1 MB | +5 MB | 4.2% | REGRESS |
| single-day-access-log-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | TIMING/total | 11.3 s | 11.9 s | +598 ms | 5.3% | REGRESS |
| single-day-access-log-histogram | MEMORY/rss_peak | 154.6 MB | 164.5 MB | +9.9 MB | 6.4% | REGRESS |
| single-day-access-log-heatmap-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/total | 11.8 s | 12.1 s | +297 ms | 2.5% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/rss_peak | 120.8 MB | 127.7 MB | +7.0 MB | 5.8% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/total | 16.2 s | 16.8 s | +637 ms | 3.9% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 167.1 MB | 179.5 MB | +12.4 MB | 7.4% | REGRESS |
| month-single-server-access-logs-standard | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/total | 1.8 min | 2.1 min | +13.3 s | 12.0% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/rss_peak | 2.7 GB | 2.7 GB | -14.5 MB | -0.5% | IMPROVE |
| month-single-server-access-logs-top25 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/total | 1.9 min | 2.1 min | +14.5 s | 13.1% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/rss_peak | 2.7 GB | 2.6 GB | -104.6 MB | -3.8% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/total | 4.3 min | 4.2 min | -3.5 s | -1.4% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | 1.7 GB | 1.7 GB | +13.8 MB | 0.8% | REGRESS |
| month-single-server-access-logs-heatmap | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/total | 2.0 min | 2.2 min | +12.1 s | 10.1% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/rss_peak | 2.2 GB | 2.1 GB | -40.2 MB | -1.8% | IMPROVE |
| month-single-server-access-logs-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/total | 2.3 min | 2.5 min | +10.4 s | 7.5% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/rss_peak | 2.7 GB | 2.7 GB | -28.8 MB | -1.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/total | 2.3 min | 2.5 min | +10.3 s | 7.3% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/rss_peak | 2.2 GB | 2.1 GB | -40.4 MB | -1.8% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | 4.2 min | 4.1 min | -8.9 s | -3.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 1.3 GB | 1.3 GB | +1.2 MB | 0.1% | REGRESS |
| month-many-servers-access-logs-standard | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | TIMING/total | 9.2 min | 10.7 min | +1.4 min | 15.2% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY/rss_peak | 12.3 GB | 13.0 GB | +706.0 MB | 5.6% | REGRESS |
| month-many-servers-access-logs-top25 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | TIMING/total | 9.3 min | 10.7 min | +1.4 min | 15.4% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/rss_peak | 13 GB | 13.0 GB | -54.9 MB | -0.4% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | 30.4 min | 28.4 min | -2 min | -6.6% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | 7.2 GB | 7.2 GB | -7.2 MB | -0.1% | IMPROVE |
| month-many-servers-access-logs-heatmap | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/total | 10.0 min | 11.5 min | +1.6 min | 15.9% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/rss_peak | 10 GB | 10.0 GB | -56.3 MB | -0.5% | IMPROVE |
| month-many-servers-access-logs-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/total | 11.4 min | 13 min | +1.6 min | 13.7% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/rss_peak | 12.2 GB | 13.0 GB | +814.5 MB | 6.5% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/total | 11.7 min | 13.1 min | +1.4 min | 11.8% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/rss_peak | 10.2 GB | 9.6 GB | -564.8 MB | -5.4% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | 28.4 min | 27.1 min | -1.3 min | -4.5% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 4.9 GB | 4.9 GB | +3.8 MB | 0.1% | REGRESS |

### Detailed

| test_name | metric | baseline | current | delta | change% | result |
| --- | --- | --- | --- | --- | --- | --- |
| humungous-log-uniqueness-standard | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/read_files | 2.3 s | 2.5 s | +129 ms | 5.5% | REGRESS |
| humungous-log-uniqueness-standard | TIMING/calculate_statistics | 275 ms | 2.2 s | +1.9 s | 694.5% | REGRESS |
| humungous-log-uniqueness-standard | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/total | 2.6 s | 4.6 s | +2 s | 78.2% | REGRESS |
| humungous-log-uniqueness-standard | MEMORY/rss_peak | 202.7 MB | 203.6 MB | +944 KB | 0.5% | REGRESS |
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
| humungous-log-uniqueness-top25 | TIMING/read_files | 2.3 s | 2.4 s | +98 ms | 4.2% | REGRESS |
| humungous-log-uniqueness-top25 | TIMING/calculate_statistics | 273 ms | 2.1 s | +1.9 s | 682.4% | REGRESS |
| humungous-log-uniqueness-top25 | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/total | 2.6 s | 4.6 s | +2.0 s | 75.8% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY/rss_peak | 203.5 MB | 204.9 MB | +1.4 MB | 0.7% | REGRESS |
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
| humungous-log-uniqueness-top25-consolidate | TIMING/read_files | 6.3 s | 6.6 s | +305 ms | 4.9% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | TIMING/group_similar | 4 s | 4.0 s | -74 ms | -1.8% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/total | 10.3 s | 10.5 s | +231 ms | 2.2% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/rss_peak | 249.1 MB | 250.7 MB | +1.5 MB | 0.6% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_clusters | 196.2 KB | 196.2 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_message | 3.1 MB | 3.1 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_trigrams | 71.8 MB | 71.7 MB | -55.3 KB | -0.1% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 64.3 MB | 64.2 MB | -13.1 KB | -0.0% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_ngram_index | 66.7 MB | 66.7 MB | -3.2 KB | -0.0% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_patterns | 24.9 KB | 24.8 KB | -112 B | -0.4% | IMPROVE |
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
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_messages | 2.5 MB | 2.5 MB | +470 B | 0.0% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_occurrences | 4.5 KB | 4.5 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/log_messages | 100953 | 100953 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 200881 | 200881 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 25503 | 25391 | -112 | -0.4% | IMPROVE |
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
| humungous-log-uniqueness-heatmap | TIMING/read_files | 2.2 s | 2.4 s | +138 ms | 6.2% | REGRESS |
| humungous-log-uniqueness-heatmap | TIMING/calculate_statistics | 268 ms | 2.0 s | +1.7 s | 629.5% | REGRESS |
| humungous-log-uniqueness-heatmap | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/total | 2.5 s | 4.3 s | +1.8 s | 72.7% | REGRESS |
| humungous-log-uniqueness-heatmap | MEMORY/rss_peak | 203.2 MB | 205 MB | +1.8 MB | 0.9% | REGRESS |
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
| humungous-log-uniqueness-histogram | TIMING/read_files | 2.3 s | 2.4 s | +152 ms | 6.7% | REGRESS |
| humungous-log-uniqueness-histogram | TIMING/calculate_statistics | 276 ms | 2.0 s | +1.7 s | 622.1% | REGRESS |
| humungous-log-uniqueness-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/total | 2.5 s | 4.4 s | +1.9 s | 73.4% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY/rss_peak | 203.5 MB | 204.7 MB | +1.2 MB | 0.6% | REGRESS |
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
| humungous-log-uniqueness-heatmap-histogram | TIMING/read_files | 2.3 s | 2.4 s | +102 ms | 4.5% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | TIMING/calculate_statistics | 267 ms | 2.0 s | +1.7 s | 633.3% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/total | 2.6 s | 4.3 s | +1.8 s | 70.2% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/rss_peak | 203.5 MB | 204.5 MB | +1008 KB | 0.5% | REGRESS |
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
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/read_files | 6.4 s | 6.5 s | +122 ms | 1.9% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/group_similar | 3.9 s | 4.0 s | +59 ms | 1.5% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/total | 10.3 s | 10.4 s | +180 ms | 1.8% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/rss_peak | 248.5 MB | 250.7 MB | +2.2 MB | 0.9% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 196.2 KB | 196.2 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 3.1 MB | 3.1 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 71.7 MB | 71.7 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 64.2 MB | 64.2 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 66.7 MB | 66.7 MB | -6.1 KB | -0.0% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 24.9 KB | 24.8 KB | -112 B | -0.4% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 614.1 KB | 614.1 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 1.7 MB | 1.7 MB | 0 B | 0.0% |  |
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
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 25503 | 25391 | -112 | -0.4% | IMPROVE |
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
| single-day-application-log-standard | TIMING/read_files | 3.5 s | 3.6 s | +110 ms | 3.1% | REGRESS |
| single-day-application-log-standard | TIMING/calculate_statistics | 6 ms | 15 ms | +9 ms | 150.0% | REGRESS |
| single-day-application-log-standard | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-standard | TIMING/total | 3.5 s | 3.6 s | +119 ms | 3.4% | REGRESS |
| single-day-application-log-standard | MEMORY/rss_peak | 35.3 MB | 36.8 MB | +1.5 MB | 4.3% | REGRESS |
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
| single-day-application-log-standard | MEMORY/log_occurrences | 21.5 KB | 21.8 KB | +256 B | 1.2% | REGRESS |
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
| single-day-application-log-top25 | TIMING/read_files | 3.5 s | 3.7 s | +144 ms | 4.1% | REGRESS |
| single-day-application-log-top25 | TIMING/calculate_statistics | 6 ms | 15 ms | +9 ms | 150.0% | REGRESS |
| single-day-application-log-top25 | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25 | TIMING/total | 3.5 s | 3.7 s | +153 ms | 4.3% | REGRESS |
| single-day-application-log-top25 | MEMORY/rss_peak | 35.3 MB | 36.8 MB | +1.5 MB | 4.2% | REGRESS |
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
| single-day-application-log-top25 | MEMORY/log_occurrences | 21.8 KB | 21.5 KB | -256 B | -1.1% | IMPROVE |
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
| single-day-application-log-top25-consolidate | TIMING/read_files | 6.1 s | 6.3 s | +193 ms | 3.1% | REGRESS |
| single-day-application-log-top25-consolidate | TIMING/group_similar | 257 ms | 272 ms | +15 ms | 5.8% | REGRESS |
| single-day-application-log-top25-consolidate | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/total | 6.4 s | 6.6 s | +208 ms | 3.3% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/rss_peak | 122.6 MB | 126.2 MB | +3.6 MB | 2.9% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_clusters | 437.3 KB | 437.5 KB | +214 B | 0.0% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_message | 2.6 MB | 2.6 MB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_trigrams | 28.4 MB | 29.3 MB | +945 KB | 3.3% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 15.6 MB | 16.4 MB | +767.6 KB | 4.8% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_ngram_index | 29.7 MB | 29.7 MB | +4.2 KB | 0.0% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_patterns | 54.4 KB | 54.2 KB | -196 B | -0.4% | IMPROVE |
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
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 447791 | 448005 | 214 | 0.0% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 55660 | 55464 | -196 | -0.4% | IMPROVE |
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
| single-day-application-log-heatmap | TIMING/read_files | 3.5 s | 3.7 s | +205 ms | 5.8% | REGRESS |
| single-day-application-log-heatmap | TIMING/calculate_statistics | 6 ms | 15 ms | +9 ms | 150.0% | REGRESS |
| single-day-application-log-heatmap | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap | TIMING/total | 3.5 s | 3.8 s | +214 ms | 6.0% | REGRESS |
| single-day-application-log-heatmap | MEMORY/rss_peak | 35.4 MB | 36.8 MB | +1.4 MB | 4.1% | REGRESS |
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
| single-day-application-log-histogram | TIMING/read_files | 3.5 s | 3.7 s | +183 ms | 5.2% | REGRESS |
| single-day-application-log-histogram | TIMING/calculate_statistics | 7 ms | 15 ms | +8 ms | 114.3% | REGRESS |
| single-day-application-log-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-histogram | TIMING/total | 3.5 s | 3.7 s | +192 ms | 5.5% | REGRESS |
| single-day-application-log-histogram | MEMORY/rss_peak | 35.4 MB | 36.8 MB | +1.4 MB | 3.9% | REGRESS |
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
| single-day-application-log-heatmap-histogram | TIMING/read_files | 3.6 s | 3.7 s | +92 ms | 2.6% | REGRESS |
| single-day-application-log-heatmap-histogram | TIMING/calculate_statistics | 6 ms | 15 ms | +9 ms | 150.0% | REGRESS |
| single-day-application-log-heatmap-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/total | 3.6 s | 3.7 s | +100 ms | 2.8% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/rss_peak | 34.8 MB | 36.8 MB | +2.1 MB | 6.0% | REGRESS |
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
| single-day-application-log-heatmap-histogram-consolidate | TIMING/read_files | 6.1 s | 6.4 s | +246 ms | 4.0% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/group_similar | 264 ms | 258 ms | -6 ms | -2.3% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/total | 6.4 s | 6.6 s | +240 ms | 3.8% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 124.4 MB | 126.0 MB | +1.5 MB | 1.2% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 437.5 KB | 437.5 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 2.6 MB | 2.6 MB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 29.3 MB | 29.3 MB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 16.4 MB | 16.4 MB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 29.7 MB | 29.7 MB | -6.4 KB | -0.0% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 54.3 KB | 54.2 KB | -112 B | -0.2% | IMPROVE |
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
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 137524 | 137524 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 448005 | 448005 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 55576 | 55464 | -112 | -0.2% | IMPROVE |
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
| multi-day-application-logs-standard | TIMING/read_files | 7.6 s | 7.9 s | +288 ms | 3.8% | REGRESS |
| multi-day-application-logs-standard | TIMING/calculate_statistics | 196 ms | 459 ms | +263 ms | 134.2% | REGRESS |
| multi-day-application-logs-standard | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-standard | TIMING/total | 7.8 s | 8.3 s | +551 ms | 7.1% | REGRESS |
| multi-day-application-logs-standard | MEMORY/rss_peak | 112.9 MB | 116.1 MB | +3.2 MB | 2.8% | REGRESS |
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
| multi-day-application-logs-top25 | TIMING/read_files | 7.7 s | 7.8 s | +146 ms | 1.9% | REGRESS |
| multi-day-application-logs-top25 | TIMING/calculate_statistics | 179 ms | 458 ms | +279 ms | 155.9% | REGRESS |
| multi-day-application-logs-top25 | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/total | 7.9 s | 8.3 s | +425 ms | 5.4% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/rss_peak | 113.8 MB | 114.5 MB | +736 KB | 0.6% | REGRESS |
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
| multi-day-application-logs-top25 | MEMORY/log_occurrences | 56.7 KB | 56.7 KB | 0 B | 0.0% |  |
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
| multi-day-application-logs-top25-consolidate | TIMING/read_files | 36.3 s | 37.1 s | +853 ms | 2.4% | REGRESS |
| multi-day-application-logs-top25-consolidate | TIMING/group_similar | 4.3 s | 4.5 s | +186 ms | 4.4% | REGRESS |
| multi-day-application-logs-top25-consolidate | TIMING/calculate_statistics | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/total | 40.5 s | 41.6 s | +1 s | 2.6% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | 223.3 MB | 226.9 MB | +3.6 MB | 1.6% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_clusters | 3.6 MB | 3.6 MB | -8 B | -0.0% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_message | 3.5 MB | 3.5 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 62.2 MB | 62.2 MB | -1 KB | -0.0% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 10.4 MB | 10.4 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_ngram_index | 60.8 MB | 60.8 MB | -384 B | -0.0% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_patterns | 485.8 KB | 485.7 KB | -126 B | -0.0% | IMPROVE |
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
| multi-day-application-logs-top25-consolidate | MEMORY/log_occurrences | 56.6 KB | 56.7 KB | +64 B | 0.1% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/log_messages | 726422 | 726422 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 3738236 | 3738228 | -8 | -0.0% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 497458 | 497330 | -128 | -0.0% | IMPROVE |
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
| multi-day-application-logs-heatmap | TIMING/read_files | 7.7 s | 7.9 s | +245 ms | 3.2% | REGRESS |
| multi-day-application-logs-heatmap | TIMING/calculate_statistics | 188 ms | 459 ms | +271 ms | 144.1% | REGRESS |
| multi-day-application-logs-heatmap | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/total | 7.9 s | 8.4 s | +517 ms | 6.6% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY/rss_peak | 115.5 MB | 114.2 MB | -1.3 MB | -1.1% | IMPROVE |
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
| multi-day-application-logs-heatmap | MEMORY/log_occurrences | 56.7 KB | 56.6 KB | -64 B | -0.1% | IMPROVE |
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
| multi-day-application-logs-histogram | TIMING/read_files | 7.6 s | 7.9 s | +305 ms | 4.0% | REGRESS |
| multi-day-application-logs-histogram | TIMING/calculate_statistics | 180 ms | 456 ms | +276 ms | 153.3% | REGRESS |
| multi-day-application-logs-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/total | 7.8 s | 8.4 s | +581 ms | 7.4% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/rss_peak | 112.2 MB | 114.3 MB | +2 MB | 1.8% | REGRESS |
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
| multi-day-application-logs-heatmap-histogram | TIMING/read_files | 7.6 s | 7.8 s | +220 ms | 2.9% | REGRESS |
| multi-day-application-logs-heatmap-histogram | TIMING/calculate_statistics | 179 ms | 453 ms | +274 ms | 153.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/total | 7.7 s | 8.2 s | +493 ms | 6.4% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/rss_peak | 113.1 MB | 114.5 MB | +1.5 MB | 1.3% | REGRESS |
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
| multi-day-application-logs-heatmap-histogram-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/read_files | 36.6 s | 36.8 s | +234 ms | 0.6% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/group_similar | 4.3 s | 4.3 s | +8 ms | 0.2% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | 40.9 s | 41.2 s | +241 ms | 0.6% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 223.4 MB | 225.6 MB | +2.2 MB | 1.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 3.6 MB | 3.6 MB | -368 B | -0.0% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 3.5 MB | 3.5 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 62.2 MB | 62.2 MB | -1 KB | -0.0% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 10.4 MB | 10.4 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 60.8 MB | 60.8 MB | +5.8 KB | 0.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 486.5 KB | 485.7 KB | -846 B | -0.2% | IMPROVE |
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
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 56.6 KB | 56.6 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 726422 | 726422 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 3738596 | 3738228 | -368 | -0.0% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 498178 | 497330 | -848 | -0.2% | IMPROVE |
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
| multi-day-custom-logs-standard | TIMING/read_files | 15.7 s | 16 s | +302 ms | 1.9% | REGRESS |
| multi-day-custom-logs-standard | TIMING/calculate_statistics | 386 ms | 1.2 s | +854 ms | 221.2% | REGRESS |
| multi-day-custom-logs-standard | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/total | 16.1 s | 17.2 s | +1.2 s | 7.2% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/rss_peak | 199.1 MB | 203.1 MB | +4.0 MB | 2.0% | REGRESS |
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
| multi-day-custom-logs-standard | MEMORY/log_messages | 102.6 MB | 103.0 MB | +400.2 KB | 0.4% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_stats | 54.7 KB | 72.4 KB | +17.8 KB | 32.5% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY_FINAL/log_messages | 107569190 | 107978981 | 409791 | 0.4% | REGRESS |
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
| multi-day-custom-logs-top25 | TIMING/read_files | 15.6 s | 16.0 s | +362 ms | 2.3% | REGRESS |
| multi-day-custom-logs-top25 | TIMING/calculate_statistics | 390 ms | 1.3 s | +907 ms | 232.6% | REGRESS |
| multi-day-custom-logs-top25 | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/total | 16.0 s | 17.2 s | +1.3 s | 7.9% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/rss_peak | 200.4 MB | 202.0 MB | +1.6 MB | 0.8% | REGRESS |
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
| multi-day-custom-logs-top25 | MEMORY/log_messages | 102.6 MB | 102.5 MB | -65.5 KB | -0.1% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_stats | 54.7 KB | 72.4 KB | +17.8 KB | 32.5% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY_FINAL/log_messages | 107582966 | 107515909 | -67057 | -0.1% | IMPROVE |
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
| multi-day-custom-logs-top25-consolidate | TIMING/read_files | 46.8 s | 49.0 s | +2.2 s | 4.6% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/group_similar | 4.6 s | 4.7 s | +87 ms | 1.9% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/calculate_statistics | 300 ms | 437 ms | +137 ms | 45.7% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/total | 51.7 s | 54.1 s | +2.4 s | 4.6% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/rss_peak | 257.0 MB | 265.9 MB | +8.9 MB | 3.5% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_clusters | 29.5 MB | 29.5 MB | +124 B | 0.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_message | 5.8 MB | 5.8 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 62.6 MB | 62.6 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 4.5 MB | 4.5 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_ngram_index | 61.3 MB | 61.2 MB | -25.2 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_patterns | 201.9 KB | 202.1 KB | +118 B | 0.1% | REGRESS |
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
| multi-day-custom-logs-top25-consolidate | MEMORY/log_analysis | 28.4 MB | 28.4 MB | -256 B | -0.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_messages | 28.6 MB | 28.6 MB | +10.5 KB | 0.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_stats | 54.7 KB | 72.2 KB | +17.5 KB | 32.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/log_messages | 30009652 | 30020363 | 10711 | 0.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 20342 | 20086 | -256 | -1.3% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 30969816 | 30969940 | 124 | 0.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 206785 | 206903 | 118 | 0.1% | REGRESS |
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
| multi-day-custom-logs-heatmap | TIMING/read_files | 16.1 s | 16.5 s | +390 ms | 2.4% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/calculate_statistics | 301 ms | 1.1 s | +790 ms | 262.5% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/heatmap_statistics | 15 ms | 15 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/total | 16.5 s | 17.6 s | +1.2 s | 7.2% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/rss_peak | 179.6 MB | 179.9 MB | +272 KB | 0.1% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_counters | 983.4 KB | 983.4 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_data | 43.5 KB | 42.9 KB | -576 B | -1.3% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_analysis | 20.9 KB | 20.9 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_messages | 103.1 MB | 102.5 MB | -565 KB | -0.5% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_stats | 49.8 KB | 58.6 KB | +8.7 KB | 17.6% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/log_messages | 108062118 | 107483557 | -578561 | -0.5% | IMPROVE |
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
| multi-day-custom-logs-histogram | TIMING/read_files | 16.3 s | 16.8 s | +525 ms | 3.2% | REGRESS |
| multi-day-custom-logs-histogram | TIMING/calculate_statistics | 384 ms | 1.2 s | +856 ms | 222.9% | REGRESS |
| multi-day-custom-logs-histogram | TIMING/histogram_statistics | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/total | 16.7 s | 18.1 s | +1.4 s | 8.3% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/rss_peak | 199.2 MB | 202.5 MB | +3.3 MB | 1.6% | REGRESS |
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
| multi-day-custom-logs-histogram | MEMORY/histogram_counters | 121.9 KB | 122.1 KB | +192 B | 0.2% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_analysis | 28.4 MB | 28.4 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_messages | 103.1 MB | 102.5 MB | -567.1 KB | -0.5% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_stats | 54.7 KB | 72.4 KB | +17.8 KB | 32.5% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY_FINAL/log_messages | 108064422 | 107483749 | -580673 | -0.5% | IMPROVE |
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
| multi-day-custom-logs-heatmap-histogram | TIMING/read_files | 16.8 s | 17.1 s | +353 ms | 2.1% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | TIMING/calculate_statistics | 304 ms | 1.1 s | +793 ms | 260.9% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | TIMING/heatmap_statistics | 15 ms | 15 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/histogram_statistics | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/total | 17.1 s | 18.3 s | +1.1 s | 6.7% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/rss_peak | 177.2 MB | 180.5 MB | +3.3 MB | 1.9% | REGRESS |
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
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_data | 42.9 KB | 40.1 KB | -2.8 KB | -6.6% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_counters | 122.1 KB | 122.1 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_analysis | 20.9 KB | 20.9 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_messages | 103.1 MB | 103.0 MB | -83.4 KB | -0.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_stats | 49.8 KB | 58.6 KB | +8.7 KB | 17.6% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 108064422 | 107978981 | -85441 | -0.1% | IMPROVE |
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
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/read_files | 48.0 s | 49.5 s | +1.5 s | 3.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/group_similar | 4.3 s | 4.4 s | +115 ms | 2.7% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | 138 ms | 205 ms | +67 ms | 48.6% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/heatmap_statistics | 19 ms | 19 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/histogram_statistics | 4 ms | 4 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/total | 52.4 s | 54.1 s | +1.7 s | 3.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 232.4 MB | 245.2 MB | +12.8 MB | 5.5% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 29.5 MB | 29.5 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 5.8 MB | 5.8 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 62.6 MB | 62.5 MB | -100 KB | -0.2% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 4.5 MB | 4.5 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 61.2 MB | 61.3 MB | +18.9 KB | 0.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 202.2 KB | 202.1 KB | -200 B | -0.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 478.1 KB | 478.1 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 3.3 MB | 3.3 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 983.4 KB | 983.4 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 42.3 KB | 43.1 KB | +896 B | 2.1% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | 122.1 KB | 122.1 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 20.9 KB | 20.9 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 28.6 MB | 28.6 MB | +6.3 KB | 0.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 49.8 KB | 58.6 KB | +8.7 KB | 17.6% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 30001812 | 30008267 | 6455 | 0.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 20342 | 20342 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 30969940 | 30969940 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 207103 | 206903 | -200 | -0.1% | IMPROVE |
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
| single-day-access-log-standard | TIMING/read_files | 9.3 s | 9.6 s | +316 ms | 3.4% | REGRESS |
| single-day-access-log-standard | TIMING/calculate_statistics | 198 ms | 364 ms | +166 ms | 83.8% | REGRESS |
| single-day-access-log-standard | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-standard | TIMING/total | 9.5 s | 9.9 s | +483 ms | 5.1% | REGRESS |
| single-day-access-log-standard | MEMORY/rss_peak | 156.4 MB | 164.5 MB | +8.1 MB | 5.2% | REGRESS |
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
| single-day-access-log-standard | MEMORY/log_messages | 55.5 MB | 55.4 MB | -60.9 KB | -0.1% | IMPROVE |
| single-day-access-log-standard | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_stats | 31.6 KB | 43.1 KB | +11.6 KB | 36.7% | REGRESS |
| single-day-access-log-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY_FINAL/log_messages | 58191194 | 58128849 | -62345 | -0.1% | IMPROVE |
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
| single-day-access-log-top25 | TIMING/read_files | 9.2 s | 9.6 s | +331 ms | 3.6% | REGRESS |
| single-day-access-log-top25 | TIMING/calculate_statistics | 221 ms | 404 ms | +183 ms | 82.8% | REGRESS |
| single-day-access-log-top25 | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25 | TIMING/total | 9.5 s | 10.0 s | +513 ms | 5.4% | REGRESS |
| single-day-access-log-top25 | MEMORY/rss_peak | 156.2 MB | 163.8 MB | +7.5 MB | 4.8% | REGRESS |
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
| single-day-access-log-top25 | MEMORY/log_messages | 55.5 MB | 55.5 MB | -44.6 KB | -0.1% | IMPROVE |
| single-day-access-log-top25 | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_stats | 31.6 KB | 43.1 KB | +11.6 KB | 36.7% | REGRESS |
| single-day-access-log-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY_FINAL/log_messages | 58205010 | 58159329 | -45681 | -0.1% | IMPROVE |
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
| single-day-access-log-top25-consolidate | TIMING/read_files | 10.7 s | 11.1 s | +449 ms | 4.2% | REGRESS |
| single-day-access-log-top25-consolidate | TIMING/group_similar | 3.9 s | 4.1 s | +182 ms | 4.7% | REGRESS |
| single-day-access-log-top25-consolidate | TIMING/calculate_statistics | 355 ms | 589 ms | +234 ms | 65.9% | REGRESS |
| single-day-access-log-top25-consolidate | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/total | 14.9 s | 15.8 s | +866 ms | 5.8% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/rss_peak | 193.4 MB | 208.8 MB | +15.4 MB | 8.0% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_clusters | 48.6 MB | 48.4 MB | -139.5 KB | -0.3% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_message | 883 KB | 883 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_trigrams | 4.1 MB | 4.1 MB | +11.5 KB | 0.3% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_ngram_index | 4.8 MB | 4.8 MB | -6.6 KB | -0.1% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_patterns | 122.5 KB | 118.1 KB | -4.5 KB | -3.6% | IMPROVE |
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
| single-day-access-log-top25-consolidate | MEMORY/log_messages | 55.5 MB | 55.2 MB | -271 KB | -0.5% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_stats | 31.6 KB | 43.1 KB | +11.6 KB | 36.7% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/log_messages | 56094345 | 56086338 | -8007 | -0.0% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/log_analysis | 6670 | 6670 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 50913902 | 50771065 | -142837 | -0.3% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 125489 | 119797 | -5692 | -4.5% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 296 | 296 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 16440 | 16440 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/log_messages_entries | 603 | 615 | 12 | 2.0% | REGRESS |
| single-day-access-log-top25-consolidate | COUNTS/log_occurrences_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/log_stats_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | TIMING/read_files | 10 s | 10.4 s | +345 ms | 3.4% | REGRESS |
| single-day-access-log-heatmap | TIMING/calculate_statistics | 55 ms | 100 ms | +45 ms | 81.8% | REGRESS |
| single-day-access-log-heatmap | TIMING/heatmap_statistics | 8 ms | 8 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap | TIMING/total | 10.1 s | 10.5 s | +390 ms | 3.9% | REGRESS |
| single-day-access-log-heatmap | MEMORY/rss_peak | 120.1 MB | 125.1 MB | +5 MB | 4.2% | REGRESS |
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
| single-day-access-log-heatmap | MEMORY/log_messages | 55.5 MB | 55.4 MB | -60.9 KB | -0.1% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_stats | 28.5 KB | 34.5 KB | +5.9 KB | 20.8% | REGRESS |
| single-day-access-log-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY_FINAL/log_messages | 58191194 | 58128849 | -62345 | -0.1% | IMPROVE |
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
| single-day-access-log-histogram | TIMING/read_files | 11.1 s | 11.5 s | +388 ms | 3.5% | REGRESS |
| single-day-access-log-histogram | TIMING/calculate_statistics | 196 ms | 405 ms | +209 ms | 106.6% | REGRESS |
| single-day-access-log-histogram | TIMING/histogram_statistics | 3 ms | 3 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/total | 11.3 s | 11.9 s | +598 ms | 5.3% | REGRESS |
| single-day-access-log-histogram | MEMORY/rss_peak | 154.6 MB | 164.5 MB | +9.9 MB | 6.4% | REGRESS |
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
| single-day-access-log-histogram | MEMORY/log_messages | 55.5 MB | 55.4 MB | -60.9 KB | -0.1% | IMPROVE |
| single-day-access-log-histogram | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_stats | 31.6 KB | 43.1 KB | +11.6 KB | 36.7% | REGRESS |
| single-day-access-log-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY_FINAL/log_messages | 58184154 | 58121809 | -62345 | -0.1% | IMPROVE |
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
| single-day-access-log-heatmap-histogram | TIMING/read_files | 11.8 s | 12 s | +251 ms | 2.1% | REGRESS |
| single-day-access-log-heatmap-histogram | TIMING/calculate_statistics | 55 ms | 101 ms | +46 ms | 83.6% | REGRESS |
| single-day-access-log-heatmap-histogram | TIMING/heatmap_statistics | 8 ms | 8 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/histogram_statistics | 3 ms | 3 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/total | 11.8 s | 12.1 s | +297 ms | 2.5% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/rss_peak | 120.8 MB | 127.7 MB | +7.0 MB | 5.8% | REGRESS |
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
| single-day-access-log-heatmap-histogram | MEMORY/log_messages | 55.5 MB | 55.2 MB | -259.3 KB | -0.5% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_stats | 28.5 KB | 34.5 KB | +5.9 KB | 20.8% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/log_messages | 58191194 | 57925713 | -265481 | -0.5% | IMPROVE |
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
| single-day-access-log-heatmap-histogram-consolidate | TIMING/read_files | 13.2 s | 13.5 s | +337 ms | 2.6% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/group_similar | 2.8 s | 3.0 s | +185 ms | 6.7% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/calculate_statistics | 196 ms | 311 ms | +115 ms | 58.7% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/heatmap_statistics | 8 ms | 8 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/histogram_statistics | 3 ms | 3 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/total | 16.2 s | 16.8 s | +637 ms | 3.9% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 167.1 MB | 179.5 MB | +12.4 MB | 7.4% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 48.5 MB | 48.4 MB | -114.6 KB | -0.2% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 883 KB | 883 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 4.1 MB | 4.1 MB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 4.8 MB | 4.8 MB | +512 B | 0.0% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 120.4 KB | 118.1 KB | -2.3 KB | -1.9% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 352.5 KB | 352.5 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 565.1 KB | 565.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 569.7 KB | 569.7 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_data | 34 KB | 34 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_counters | 105.6 KB | 105.6 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_analysis | 8.1 KB | 8.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_messages | 55.5 MB | 55.4 MB | -72 KB | -0.1% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_stats | 28.5 KB | 34.5 KB | +5.9 KB | 20.8% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 56068831 | 56082866 | 14035 | 0.0% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 6670 | 6670 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 50888429 | 50771065 | -117364 | -0.2% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 123177 | 119797 | -3380 | -2.7% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 296 | 296 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 16440 | 16440 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 596 | 615 | 19 | 3.2% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/read_files | 1.7 min | 1.8 min | +1.2 s | 1.1% | REGRESS |
| month-single-server-access-logs-standard | TIMING/calculate_statistics | 5.7 s | 17.8 s | +12.1 s | 211.2% | REGRESS |
| month-single-server-access-logs-standard | TIMING/normalize_data | 3 ms | 2 ms | -1 ms | -33.3% | IMPROVE |
| month-single-server-access-logs-standard | TIMING/total | 1.8 min | 2.1 min | +13.3 s | 12.0% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/rss_peak | 2.7 GB | 2.7 GB | -14.5 MB | -0.5% | IMPROVE |
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
| month-single-server-access-logs-standard | MEMORY/log_analysis | 567.3 MB | 567.3 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_messages | 1.6 GB | 1.6 GB | -25.2 MB | -1.5% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/log_occurrences | 36.8 KB | 36.6 KB | -192 B | -0.5% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_stats | 60.0 KB | 82.4 KB | +22.5 KB | 37.5% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY_FINAL/log_messages | 1730917915 | 1704465650 | -26452265 | -1.5% | IMPROVE |
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
| month-single-server-access-logs-top25 | TIMING/read_files | 1.8 min | 1.8 min | +1.4 s | 1.3% | REGRESS |
| month-single-server-access-logs-top25 | TIMING/calculate_statistics | 5.9 s | 19 s | +13.1 s | 222.8% | REGRESS |
| month-single-server-access-logs-top25 | TIMING/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/total | 1.9 min | 2.1 min | +14.5 s | 13.1% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/rss_peak | 2.7 GB | 2.6 GB | -104.6 MB | -3.8% | IMPROVE |
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
| month-single-server-access-logs-top25 | MEMORY/log_analysis | 567.3 MB | 567.3 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_messages | 1.6 GB | 1.5 GB | -99.2 MB | -6.0% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY/log_occurrences | 36.6 KB | 36.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_stats | 60.0 KB | 82.4 KB | +22.5 KB | 37.5% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY_FINAL/log_messages | 1730932163 | 1626913778 | -104018385 | -6.0% | IMPROVE |
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
| month-single-server-access-logs-top25-consolidate | TIMING/read_files | 2.4 min | 2.4 min | +652 ms | 0.5% | REGRESS |
| month-single-server-access-logs-top25-consolidate | TIMING/group_similar | 1.8 min | 1.7 min | -6.1 s | -5.8% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | TIMING/calculate_statistics | 8.6 s | 10.6 s | +2.0 s | 23.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | TIMING/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/total | 4.3 min | 4.2 min | -3.5 s | -1.4% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | 1.7 GB | 1.7 GB | +13.8 MB | 0.8% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_clusters | 506.7 MB | 507.2 MB | +535.6 KB | 0.1% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_message | 2.5 MB | 2.5 MB | +4.9 KB | 0.2% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 36.8 MB | 36.7 MB | -108.9 KB | -0.3% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 25.9 MB | 29.4 MB | +3.6 MB | 13.8% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_ngram_index | 36.0 MB | 35.9 MB | -15.4 KB | -0.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_patterns | 294 KB | 283.0 KB | -11 KB | -3.8% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_posting_size | 973.6 KB | 973.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | 1.6 MB | 1.6 MB | +2.5 KB | 0.2% | REGRESS |
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
| month-single-server-access-logs-top25-consolidate | MEMORY/log_messages | 567.8 MB | 567 MB | -781.2 KB | -0.1% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_occurrences | 36.8 KB | 36.8 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_stats | 60.0 KB | 82.4 KB | +22.5 KB | 37.5% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/log_messages | 595366646 | 594566682 | -799964 | -0.1% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 531314378 | 531862823 | 548445 | 0.1% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 262231 | 248469 | -13762 | -5.2% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 424 | 424 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 65592 | 65592 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_messages_entries | 1315 | 1317 | 2 | 0.2% | REGRESS |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/read_files | 2.0 min | 2.0 min | +1 s | 0.9% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/calculate_statistics | 2.2 s | 13.3 s | +11.1 s | 495.7% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/heatmap_statistics | 66 ms | 63 ms | -3 ms | -4.5% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/normalize_data | 3 ms | 2 ms | -1 ms | -33.3% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/total | 2.0 min | 2.2 min | +12.1 s | 10.1% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/rss_peak | 2.2 GB | 2.1 GB | -40.2 MB | -1.8% | IMPROVE |
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
| month-single-server-access-logs-heatmap | MEMORY/heatmap_data | 80.6 KB | 83.1 KB | +2.5 KB | 3.1% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_analysis | 15.7 KB | 15.7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_messages | 1.6 GB | 1.6 GB | -27.1 MB | -1.6% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/log_occurrences | 36.8 KB | 36.6 KB | -192 B | -0.5% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_stats | 54.1 KB | 64.9 KB | +10.8 KB | 20.0% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/log_messages | 1732830635 | 1704465314 | -28365321 | -1.6% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
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
| month-single-server-access-logs-histogram | TIMING/read_files | 2.2 min | 2.2 min | -2.6 s | -2.0% | IMPROVE |
| month-single-server-access-logs-histogram | TIMING/calculate_statistics | 5.8 s | 18.9 s | +13.1 s | 224.1% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/histogram_statistics | 7 ms | 7 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/total | 2.3 min | 2.5 min | +10.4 s | 7.5% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/rss_peak | 2.7 GB | 2.7 GB | -28.8 MB | -1.0% | IMPROVE |
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
| month-single-server-access-logs-histogram | MEMORY/histogram_counters | 295.6 KB | 295.5 KB | -128 B | -0.0% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_analysis | 567.3 MB | 567.3 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_messages | 1.6 GB | 1.6 GB | -27.1 MB | -1.6% | IMPROVE |
| month-single-server-access-logs-histogram | MEMORY/log_occurrences | 36.6 KB | 36.8 KB | +192 B | 0.5% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/log_sessions | 2.2 MB | 2.2 MB | +128 B | 0.0% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/log_stats | 60.0 KB | 82.4 KB | +22.5 KB | 37.5% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY_FINAL/log_messages | 1732830683 | 1704465650 | -28365033 | -1.6% | IMPROVE |
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
| month-single-server-access-logs-heatmap-histogram | TIMING/read_files | 2.3 min | 2.3 min | -722 ms | -0.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | TIMING/calculate_statistics | 2.2 s | 13.2 s | +11.0 s | 493.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/heatmap_statistics | 66 ms | 68 ms | +2 ms | 3.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/histogram_statistics | 7 ms | 7 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/total | 2.3 min | 2.5 min | +10.3 s | 7.3% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/rss_peak | 2.2 GB | 2.1 GB | -40.4 MB | -1.8% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_counters | 2.4 MB | 2.4 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_data | 81.1 KB | 83.6 KB | +2.5 KB | 3.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_counters | 295.6 KB | 295.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_analysis | 15.7 KB | 15.7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_messages | 1.6 GB | 1.6 GB | -27.1 MB | -1.6% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_occurrences | 36.6 KB | 36.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_stats | 54.1 KB | 64.9 KB | +10.8 KB | 20.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 1730917867 | 1702552546 | -28365321 | -1.6% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
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
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/read_files | 2.9 min | 2.8 min | -2.3 s | -1.3% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/group_similar | 1.3 min | 1.2 min | -7.5 s | -9.4% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | 3.1 s | 3.9 s | +857 ms | 27.8% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/heatmap_statistics | 63 ms | 64 ms | +1 ms | 1.6% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/histogram_statistics | 13 ms | 10 ms | -3 ms | -23.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | 4.2 min | 4.1 min | -8.9 s | -3.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 1.3 GB | 1.3 GB | +1.2 MB | 0.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 506.9 MB | 507.2 MB | +340.7 KB | 0.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 2.5 MB | 2.5 MB | +7.2 KB | 0.3% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 36.7 MB | 36.7 MB | -1 KB | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 29.4 MB | 26.2 MB | -3.2 MB | -11.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 36.0 MB | 36.0 MB | -1.2 KB | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 287.7 KB | 282.9 KB | -4.8 KB | -1.7% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 973.6 KB | 973.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 1.5 MB | 1.6 MB | +3.8 KB | 0.2% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 2.4 MB | 2.4 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 82.6 KB | 83.1 KB | +512 B | 0.6% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | 295.6 KB | 295.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 15.7 KB | 15.7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 568.6 MB | 567.1 MB | -1.5 MB | -0.3% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 36.8 KB | 36.6 KB | -192 B | -0.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 54.1 KB | 64.9 KB | +10.8 KB | 20.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 596188946 | 594598714 | -1590232 | -0.3% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 531514381 | 531863207 | 348826 | 0.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 257101 | 248469 | -8632 | -3.4% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 424 | 424 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 65592 | 65592 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 1320 | 1317 | -3 | -0.2% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | TIMING/read_files | 8.7 min | 8.7 min | +2.3 s | 0.4% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/calculate_statistics | 35.3 s | 2.0 min | +1.4 min | 232.2% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/normalize_data | 4 ms | 3 ms | -1 ms | -25.0% | IMPROVE |
| month-many-servers-access-logs-standard | TIMING/total | 9.2 min | 10.7 min | +1.4 min | 15.2% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY/rss_peak | 12.3 GB | 13.0 GB | +706.0 MB | 5.6% | REGRESS |
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
| month-many-servers-access-logs-standard | MEMORY/log_messages | 8.0 GB | 8.2 GB | +239.6 MB | 2.9% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -128 B | -0.0% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/log_stats | 60.1 KB | 84 KB | +23.9 KB | 39.8% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY_FINAL/log_messages | 8555259686 | 8806454349 | 251194663 | 2.9% | REGRESS |
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
| month-many-servers-access-logs-top25 | TIMING/read_files | 8.7 min | 8.6 min | -2.6 s | -0.5% | IMPROVE |
| month-many-servers-access-logs-top25 | TIMING/calculate_statistics | 35.9 s | 2.1 min | +1.5 min | 246.1% | REGRESS |
| month-many-servers-access-logs-top25 | TIMING/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-top25 | TIMING/total | 9.3 min | 10.7 min | +1.4 min | 15.4% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/rss_peak | 13 GB | 13.0 GB | -54.9 MB | -0.4% | IMPROVE |
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
| month-many-servers-access-logs-top25 | MEMORY/log_messages | 8.3 GB | 8.2 GB | -147.5 MB | -1.7% | IMPROVE |
| month-many-servers-access-logs-top25 | MEMORY/log_occurrences | 42.1 KB | 43.8 KB | +1.8 KB | 4.2% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_stats | 60.1 KB | 84 KB | +23.9 KB | 39.8% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/log_messages | 8951257422 | 8796638669 | -154618753 | -1.7% | IMPROVE |
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
| month-many-servers-access-logs-top25-consolidate | TIMING/read_files | 11.3 min | 10.9 min | -24.8 s | -3.7% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/group_similar | 18.4 min | 16.6 min | -1.7 min | -9.5% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/calculate_statistics | 45.0 s | 54.0 s | +9 s | 20.1% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | TIMING/normalize_data | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | 30.4 min | 28.4 min | -2 min | -6.6% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | 7.2 GB | 7.2 GB | -7.2 MB | -0.1% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_clusters | 2.7 GB | 2.6 GB | -19.8 MB | -0.7% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_message | 2.4 MB | 2.5 MB | +17.1 KB | 0.7% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 36.8 MB | 36.8 MB | -1 KB | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 29.2 MB | 29.5 MB | +259 KB | 0.9% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_ngram_index | 36.1 MB | 36.1 MB | -64 B | -0.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_patterns | 528.3 KB | 531.2 KB | +2.8 KB | 0.5% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_posting_size | 1.2 MB | 1.2 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | 1.7 MB | 1.7 MB | +10.3 KB | 0.6% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_analysis | 2.9 GB | 2.9 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_messages | 2.9 GB | 2.9 GB | -4.1 MB | -0.1% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_stats | 60.1 KB | 84 KB | +23.9 KB | 39.8% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/log_messages | 3095882470 | 3091563059 | -4319411 | -0.1% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 2855254748 | 2834456800 | -20797948 | -0.7% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 541000 | 543905 | 2905 | 0.5% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 424 | 424 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 65592 | 65592 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_messages_entries | 2561 | 2549 | -12 | -0.5% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/read_files | 9.7 min | 9.9 min | +8.5 s | 1.5% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/calculate_statistics | 13.3 s | 1.7 min | +1.4 min | 650.3% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/heatmap_statistics | 85 ms | 76 ms | -9 ms | -10.6% | IMPROVE |
| month-many-servers-access-logs-heatmap | TIMING/normalize_data | 3 ms | 2 ms | -1 ms | -33.3% | IMPROVE |
| month-many-servers-access-logs-heatmap | TIMING/total | 10.0 min | 11.5 min | +1.6 min | 15.9% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/rss_peak | 10 GB | 10.0 GB | -56.3 MB | -0.5% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_key_trigrams | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_ngram_index | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_posting_size | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_counters | 2.7 MB | 2.7 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_data | 81.1 KB | 78.6 KB | -2.5 KB | -3.1% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_analysis | 15.7 KB | 15.7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_messages | 8.3 GB | 8.2 GB | -138.1 MB | -1.6% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/log_occurrences | 43.8 KB | 43.8 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -128 B | -0.0% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/log_stats | 54.1 KB | 64.9 KB | +10.8 KB | 20.0% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/log_messages | 8946183838 | 8801394925 | -144788913 | -1.6% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
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
| month-many-servers-access-logs-histogram | TIMING/read_files | 10.8 min | 10.9 min | +6 s | 0.9% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/calculate_statistics | 37.2 s | 2.1 min | +1.5 min | 237.2% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/histogram_statistics | 11 ms | 10 ms | -1000 us | -9.1% | IMPROVE |
| month-many-servers-access-logs-histogram | TIMING/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/total | 11.4 min | 13 min | +1.6 min | 13.7% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/rss_peak | 12.2 GB | 13.0 GB | +814.5 MB | 6.5% | REGRESS |
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
| month-many-servers-access-logs-histogram | MEMORY/histogram_counters | 307.4 KB | 307.4 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_analysis | 2.9 GB | 2.9 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_messages | 8.3 GB | 8.2 GB | -138.1 MB | -1.6% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/log_occurrences | 42.1 KB | 43.8 KB | +1.8 KB | 4.2% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/log_sessions | 14.9 MB | 14.9 MB | +128 B | 0.0% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/log_stats | 60.1 KB | 84 KB | +23.9 KB | 39.8% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/log_messages | 8951243238 | 8806454349 | -144788889 | -1.6% | IMPROVE |
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
| month-many-servers-access-logs-heatmap-histogram | TIMING/read_files | 11.5 min | 11.5 min | +719 ms | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/calculate_statistics | 14.3 s | 1.6 min | +1.4 min | 576.5% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/heatmap_statistics | 86 ms | 75 ms | -11 ms | -12.8% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/histogram_statistics | 11 ms | 10 ms | -1000 us | -9.1% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/normalize_data | 4 ms | 3 ms | -1 ms | -25.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/total | 11.7 min | 13.1 min | +1.4 min | 11.8% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/rss_peak | 10.2 GB | 9.6 GB | -564.8 MB | -5.4% | IMPROVE |
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
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_data | 81.1 KB | 76.6 KB | -4.5 KB | -5.6% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_counters | 307.4 KB | 307.4 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_analysis | 15.7 KB | 15.7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_messages | 8.3 GB | 7.8 GB | -506.3 MB | -5.9% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_sessions | 14.9 MB | 14.9 MB | +32 KB | 0.2% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_stats | 54.1 KB | 64.9 KB | +10.8 KB | 20.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 8936336094 | 8405411373 | -530924721 | -5.9% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
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
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/read_files | 14.1 min | 13.7 min | -23.7 s | -2.8% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/group_similar | 14 min | 13.1 min | -54.6 s | -6.5% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | 17.8 s | 20.1 s | +2.3 s | 13.2% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/heatmap_statistics | 78 ms | 70 ms | -8 ms | -10.3% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/histogram_statistics | 12 ms | 11 ms | -1 ms | -8.3% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/normalize_data | 4 ms | 3 ms | -1 ms | -25.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | 28.4 min | 27.1 min | -1.3 min | -4.5% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 4.9 GB | 4.9 GB | +3.8 MB | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 2.7 GB | 2.6 GB | -26.5 MB | -1.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 2.5 MB | 2.5 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 36.8 MB | 36.8 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 25.6 MB | 29.5 MB | +3.9 MB | 15.3% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 36.1 MB | 36.1 MB | +8.2 KB | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 530.2 KB | 531.3 KB | +1.1 KB | 0.2% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 1.2 MB | 1.2 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 1.7 MB | 1.7 MB | -112 B | -0.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 2.7 MB | 2.7 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 80.1 KB | 80.6 KB | +512 B | 0.6% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | 307.4 KB | 307.4 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 15.7 KB | 15.7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 2.9 GB | 2.9 GB | +3.7 MB | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 42.1 KB | 43.8 KB | +1.8 KB | 4.2% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 54.1 KB | 64.9 KB | +10.8 KB | 20.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 3089147575 | 3093069459 | 3921884 | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 13010 | 13010 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 2862631914 | 2834892768 | -27739146 | -1.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 542916 | 544033 | 1117 | 0.2% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 424 | 424 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | 120 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | 65592 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 65592 | 65592 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 2542 | 2549 | 7 | 0.3% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 28 | 28 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | 24 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 1440 | 1440 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 86400.00 | 86400.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | N/A | 120 B | N/A | N/A | ? |

