
## Benchmark Comparison

  Baseline:    v0.15.0 (v0.15.0, 49 test cases)
  Current:     v0.15.1 (v0.15.1, 35 test cases)

### Timing Delta

| # | file selection | standard | top25 | top25-cons | heatmap | histogram | hm+hg | hm+hg+cons |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. | humungous-log-uniqueness | +9.5% | +3.5% | -14.7% | +6.1% | +3.4% | +5.1% | +7.2% |
| 2. | single-day-application-log | +2.3% | -0.6% | +0.2% | -3.2% | -0.1% | -0.2% | +2.6% |
| 3. | multi-day-application-logs | +0.6% | +2.0% | +5.4% | -2.0% | -0.2% | +4.8% | +1.7% |
| 4. | multi-day-custom-logs | +4.1% | +5.5% | +6.5% | +5.6% | +5.3% | +5.2% | +1.7% |
| 5. | single-day-access-log | +3.4% | +1.7% | +4.9% | +2.2% | +5.1% | +3.3% | +3.2% |
| 6. | month-single-server-access-logs | - | - | - | - | - | - | - |
| 7. | month-many-servers-access-logs | - | - | - | - | - | - | - |

### Memory Delta (RSS Peak)

| # | file selection | standard | top25 | top25-cons | heatmap | histogram | hm+hg | hm+hg+cons |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. | humungous-log-uniqueness | -0.1% | -0.4% | +0.1% | -0.4% | +0.1% | -0.7% | -0.8% |
| 2. | single-day-application-log | +2.5% | +1.7% | +0.3% | +3.9% | +2.1% | +1.2% | -1.6% |
| 3. | multi-day-application-logs | +2.8% | -1.7% | +1.1% | +0.6% | -1.0% | +4.0% | -0.1% |
| 4. | multi-day-custom-logs | +0.9% | +0.5% | -1.0% | +2.2% | +0.9% | -1.5% | -1.4% |
| 5. | single-day-access-log | +0.9% | -0.6% | -1.2% | +0.4% | +0.9% | +2.5% | -1.0% |
| 6. | month-single-server-access-logs | - | - | - | - | - | - | - |
| 7. | month-many-servers-access-logs | - | - | - | - | - | - | - |

### Summary

| test_name | metric | baseline | current | delta | change% | result |
| --- | --- | --- | --- | --- | --- | --- |
| humungous-log-uniqueness-standard | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/total | 2.6 s | 2.9 s | +252 ms | 9.5% | REGRESS |
| humungous-log-uniqueness-standard | MEMORY/rss_peak | 204.9 MB | 204.7 MB | -176 KB | -0.1% | IMPROVE |
| humungous-log-uniqueness-top25 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/total | 2.8 s | 2.9 s | +97 ms | 3.5% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY/rss_peak | 204.3 MB | 203.5 MB | -864 KB | -0.4% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/total | 14.1 s | 12.0 s | -2.1 s | -14.7% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/rss_peak | 250.2 MB | 250.3 MB | +160 KB | 0.1% | REGRESS |
| humungous-log-uniqueness-heatmap | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/total | 2.7 s | 2.9 s | +165 ms | 6.1% | REGRESS |
| humungous-log-uniqueness-heatmap | MEMORY/rss_peak | 204.9 MB | 204.1 MB | -768 KB | -0.4% | IMPROVE |
| humungous-log-uniqueness-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/total | 2.8 s | 2.9 s | +96 ms | 3.4% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY/rss_peak | 203.8 MB | 204 MB | +272 KB | 0.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/total | 2.7 s | 2.8 s | +139 ms | 5.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/rss_peak | 205.7 MB | 204.3 MB | -1.4 MB | -0.7% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/total | 10.8 s | 11.6 s | +776 ms | 7.2% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/rss_peak | 250.0 MB | 248.1 MB | -1.9 MB | -0.8% | IMPROVE |
| single-day-application-log-standard | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | TIMING/total | 3.8 s | 3.9 s | +88 ms | 2.3% | REGRESS |
| single-day-application-log-standard | MEMORY/rss_peak | 36.7 MB | 37.6 MB | +928 KB | 2.5% | REGRESS |
| single-day-application-log-top25 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | TIMING/total | 3.9 s | 3.9 s | -23 ms | -0.6% | IMPROVE |
| single-day-application-log-top25 | MEMORY/rss_peak | 36.8 MB | 37.4 MB | +640 KB | 1.7% | REGRESS |
| single-day-application-log-top25-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/total | 7.0 s | 7.0 s | +15 ms | 0.2% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/rss_peak | 126.1 MB | 126.4 MB | +368 KB | 0.3% | REGRESS |
| single-day-application-log-heatmap | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | TIMING/total | 4.0 s | 3.8 s | -128 ms | -3.2% | IMPROVE |
| single-day-application-log-heatmap | MEMORY/rss_peak | 36 MB | 37.4 MB | +1.4 MB | 3.9% | REGRESS |
| single-day-application-log-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | TIMING/total | 3.8 s | 3.8 s | -3 ms | -0.1% | IMPROVE |
| single-day-application-log-histogram | MEMORY/rss_peak | 36.5 MB | 37.2 MB | +768 KB | 2.1% | REGRESS |
| single-day-application-log-heatmap-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/total | 3.8 s | 3.8 s | -8 ms | -0.2% | IMPROVE |
| single-day-application-log-heatmap-histogram | MEMORY/rss_peak | 36.6 MB | 37.1 MB | +464 KB | 1.2% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/total | 6.8 s | 7 s | +179 ms | 2.6% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 126.3 MB | 124.3 MB | -2 MB | -1.6% | IMPROVE |
| multi-day-application-logs-standard | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-standard | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-standard | TIMING/total | 8.4 s | 8.5 s | +50 ms | 0.6% | REGRESS |
| multi-day-application-logs-standard | MEMORY/rss_peak | 114.7 MB | 117.9 MB | +3.2 MB | 2.8% | REGRESS |
| multi-day-application-logs-top25 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/total | 8.1 s | 8.3 s | +159 ms | 2.0% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/rss_peak | 117.1 MB | 115.1 MB | -2 MB | -1.7% | IMPROVE |
| multi-day-application-logs-top25-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/total | 43.7 s | 46.1 s | +2.3 s | 5.4% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | 227.3 MB | 229.9 MB | +2.6 MB | 1.1% | REGRESS |
| multi-day-application-logs-heatmap | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/total | 8.6 s | 8.4 s | -170 ms | -2.0% | IMPROVE |
| multi-day-application-logs-heatmap | MEMORY/rss_peak | 115.1 MB | 115.8 MB | +720 KB | 0.6% | REGRESS |
| multi-day-application-logs-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/total | 8.6 s | 8.6 s | -19 ms | -0.2% | IMPROVE |
| multi-day-application-logs-histogram | MEMORY/rss_peak | 117.8 MB | 116.7 MB | -1.1 MB | -1.0% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/total | 8.1 s | 8.5 s | +385 ms | 4.8% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/rss_peak | 114.4 MB | 118.9 MB | +4.5 MB | 4.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | 46.5 s | 47.3 s | +809 ms | 1.7% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 227.8 MB | 227.7 MB | -144 KB | -0.1% | IMPROVE |
| multi-day-custom-logs-standard | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/total | 17.3 s | 18.0 s | +716 ms | 4.1% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/rss_peak | 202.8 MB | 204.7 MB | +1.8 MB | 0.9% | REGRESS |
| multi-day-custom-logs-top25 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/total | 17.1 s | 18.1 s | +941 ms | 5.5% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/rss_peak | 205.2 MB | 206.2 MB | +1 MB | 0.5% | REGRESS |
| multi-day-custom-logs-top25-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/total | 57.7 s | 1 min | +3.7 s | 6.5% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/rss_peak | 263.9 MB | 261.3 MB | -2.6 MB | -1.0% | IMPROVE |
| multi-day-custom-logs-heatmap | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/total | 17.5 s | 18.5 s | +974 ms | 5.6% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/rss_peak | 179.9 MB | 183.9 MB | +4 MB | 2.2% | REGRESS |
| multi-day-custom-logs-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/total | 18.0 s | 18.9 s | +944 ms | 5.3% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/rss_peak | 204 MB | 205.8 MB | +1.8 MB | 0.9% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/total | 18.3 s | 19.3 s | +955 ms | 5.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/rss_peak | 181.7 MB | 179 MB | -2.7 MB | -1.5% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/total | 1 min | 1 min | +1 s | 1.7% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 247.3 MB | 243.9 MB | -3.4 MB | -1.4% | IMPROVE |
| single-day-access-log-standard | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | TIMING/total | 10.3 s | 10.7 s | +352 ms | 3.4% | REGRESS |
| single-day-access-log-standard | MEMORY/rss_peak | 163.8 MB | 165.4 MB | +1.5 MB | 0.9% | REGRESS |
| single-day-access-log-top25 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | TIMING/total | 10.3 s | 10.5 s | +174 ms | 1.7% | REGRESS |
| single-day-access-log-top25 | MEMORY/rss_peak | 164 MB | 163.1 MB | -960 KB | -0.6% | IMPROVE |
| single-day-access-log-top25-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/total | 16.6 s | 17.4 s | +820 ms | 4.9% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/rss_peak | 210.3 MB | 207.7 MB | -2.6 MB | -1.2% | IMPROVE |
| single-day-access-log-heatmap | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | TIMING/total | 10.9 s | 11.1 s | +240 ms | 2.2% | REGRESS |
| single-day-access-log-heatmap | MEMORY/rss_peak | 127.8 MB | 128.4 MB | +560 KB | 0.4% | REGRESS |
| single-day-access-log-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | TIMING/total | 12.2 s | 12.8 s | +620 ms | 5.1% | REGRESS |
| single-day-access-log-histogram | MEMORY/rss_peak | 164.1 MB | 165.6 MB | +1.5 MB | 0.9% | REGRESS |
| single-day-access-log-heatmap-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/total | 12.6 s | 13 s | +416 ms | 3.3% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/rss_peak | 125.9 MB | 129.0 MB | +3.1 MB | 2.5% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/total | 17.8 s | 18.4 s | +569 ms | 3.2% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 182.7 MB | 180.9 MB | -1.8 MB | -1.0% | IMPROVE |
| month-single-server-access-logs-standard | lines_read | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | lines_included | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/total | 2.0 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/rss_peak | 2.7 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | lines_read | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | lines_included | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/total | 2.1 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/rss_peak | 2.7 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | lines_read | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | lines_included | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/total | 4.4 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | 1.7 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | lines_read | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | lines_included | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/total | 2 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/rss_peak | 2.1 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | lines_read | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | lines_included | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/total | 2.3 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/rss_peak | 2.7 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | lines_read | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | lines_included | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/total | 2.4 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/rss_peak | 2.1 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_read | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_included | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | 4.3 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 1.3 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | lines_included | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/total | 9.6 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/rss_peak | 12.5 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | lines_included | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/total | 9.5 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/rss_peak | 12.3 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | lines_included | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | 30 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | 7.3 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | lines_included | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/total | 10.1 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/rss_peak | 9.5 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | lines_included | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/total | 11.5 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/rss_peak | 12.2 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | lines_included | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/total | 11.7 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/rss_peak | 9.6 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_included | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | 27.2 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 4.9 GB | N/A | N/A | N/A | ? |

### Detailed

| test_name | metric | baseline | current | delta | change% | result |
| --- | --- | --- | --- | --- | --- | --- |
| humungous-log-uniqueness-standard | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/read_files | 2.4 s | 2.6 s | +202 ms | 8.5% | REGRESS |
| humungous-log-uniqueness-standard | TIMING/calculate_statistics | 272 ms | 321 ms | +49 ms | 18.0% | REGRESS |
| humungous-log-uniqueness-standard | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/total | 2.6 s | 2.9 s | +252 ms | 9.5% | REGRESS |
| humungous-log-uniqueness-standard | MEMORY/rss_peak | 204.9 MB | 204.7 MB | -176 KB | -0.1% | IMPROVE |
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
| humungous-log-uniqueness-top25 | TIMING/read_files | 2.4 s | 2.6 s | +110 ms | 4.5% | REGRESS |
| humungous-log-uniqueness-top25 | TIMING/calculate_statistics | 318 ms | 305 ms | -13 ms | -4.1% | IMPROVE |
| humungous-log-uniqueness-top25 | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/total | 2.8 s | 2.9 s | +97 ms | 3.5% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY/rss_peak | 204.3 MB | 203.5 MB | -864 KB | -0.4% | IMPROVE |
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
| humungous-log-uniqueness-top25-consolidate | TIMING/read_files | 9.8 s | 7.3 s | -2.6 s | -26.2% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | TIMING/group_similar | 4.2 s | 4.7 s | +508 ms | 12.0% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/total | 14.1 s | 12.0 s | -2.1 s | -14.7% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/rss_peak | 250.2 MB | 250.3 MB | +160 KB | 0.1% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_clusters | 196.2 KB | 196.2 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_message | 3.1 MB | 3.1 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_trigrams | 71.7 MB | 71.7 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 64.2 MB | 64.2 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_ngram_index | 66.7 MB | 66.7 MB | +9.3 KB | 0.0% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_patterns | 24.8 KB | 24.8 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_posting_size | 614.1 KB | 614.1 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_unmatched | 1.7 MB | 1.7 MB | +64 B | 0.0% | REGRESS |
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
| humungous-log-uniqueness-heatmap | TIMING/read_files | 2.4 s | 2.5 s | +99 ms | 4.1% | REGRESS |
| humungous-log-uniqueness-heatmap | TIMING/calculate_statistics | 271 ms | 337 ms | +66 ms | 24.4% | REGRESS |
| humungous-log-uniqueness-heatmap | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/total | 2.7 s | 2.9 s | +165 ms | 6.1% | REGRESS |
| humungous-log-uniqueness-heatmap | MEMORY/rss_peak | 204.9 MB | 204.1 MB | -768 KB | -0.4% | IMPROVE |
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
| humungous-log-uniqueness-histogram | TIMING/read_files | 2.5 s | 2.6 s | +68 ms | 2.7% | REGRESS |
| humungous-log-uniqueness-histogram | TIMING/calculate_statistics | 304 ms | 331 ms | +27 ms | 8.9% | REGRESS |
| humungous-log-uniqueness-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/total | 2.8 s | 2.9 s | +96 ms | 3.4% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY/rss_peak | 203.8 MB | 204 MB | +272 KB | 0.1% | REGRESS |
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
| humungous-log-uniqueness-heatmap-histogram | TIMING/read_files | 2.4 s | 2.5 s | +132 ms | 5.5% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | TIMING/calculate_statistics | 293 ms | 301 ms | +8 ms | 2.7% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/total | 2.7 s | 2.8 s | +139 ms | 5.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/rss_peak | 205.7 MB | 204.3 MB | -1.4 MB | -0.7% | IMPROVE |
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
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/read_files | 6.4 s | 6.9 s | +532 ms | 8.3% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/group_similar | 4.4 s | 4.7 s | +244 ms | 5.5% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/total | 10.8 s | 11.6 s | +776 ms | 7.2% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/rss_peak | 250.0 MB | 248.1 MB | -1.9 MB | -0.8% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 196.2 KB | 196.2 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 3.1 MB | 3.1 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 71.7 MB | 71.7 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 64.2 MB | 64.2 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 66.7 MB | 66.7 MB | -4.4 KB | -0.0% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 24.8 KB | 24.8 KB | 0 B | 0.0% |  |
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
| single-day-application-log-standard | TIMING/read_files | 3.8 s | 3.9 s | +87 ms | 2.3% | REGRESS |
| single-day-application-log-standard | TIMING/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-standard | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-standard | TIMING/total | 3.8 s | 3.9 s | +88 ms | 2.3% | REGRESS |
| single-day-application-log-standard | MEMORY/rss_peak | 36.7 MB | 37.6 MB | +928 KB | 2.5% | REGRESS |
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
| single-day-application-log-standard | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
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
| single-day-application-log-top25 | TIMING/read_files | 3.9 s | 3.9 s | -22 ms | -0.6% | IMPROVE |
| single-day-application-log-top25 | TIMING/calculate_statistics | 7 ms | 7 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25 | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25 | TIMING/total | 3.9 s | 3.9 s | -23 ms | -0.6% | IMPROVE |
| single-day-application-log-top25 | MEMORY/rss_peak | 36.8 MB | 37.4 MB | +640 KB | 1.7% | REGRESS |
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
| single-day-application-log-top25-consolidate | TIMING/read_files | 6.7 s | 6.7 s | -25 ms | -0.4% | IMPROVE |
| single-day-application-log-top25-consolidate | TIMING/group_similar | 284 ms | 323 ms | +39 ms | 13.7% | REGRESS |
| single-day-application-log-top25-consolidate | TIMING/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| single-day-application-log-top25-consolidate | TIMING/total | 7.0 s | 7.0 s | +15 ms | 0.2% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/rss_peak | 126.1 MB | 126.4 MB | +368 KB | 0.3% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_clusters | 437.5 KB | 437.3 KB | -256 B | -0.1% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_message | 2.6 MB | 2.6 MB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_trigrams | 29.3 MB | 29.3 MB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 16.4 MB | 16.4 MB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_ngram_index | 29.7 MB | 29.7 MB | +4.1 KB | 0.0% | REGRESS |
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
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 448005 | 447749 | -256 | -0.1% | IMPROVE |
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
| single-day-application-log-heatmap | TIMING/read_files | 3.9 s | 3.8 s | -128 ms | -3.2% | IMPROVE |
| single-day-application-log-heatmap | TIMING/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap | TIMING/total | 4.0 s | 3.8 s | -128 ms | -3.2% | IMPROVE |
| single-day-application-log-heatmap | MEMORY/rss_peak | 36 MB | 37.4 MB | +1.4 MB | 3.9% | REGRESS |
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
| single-day-application-log-histogram | TIMING/read_files | 3.8 s | 3.8 s | -3 ms | -0.1% | IMPROVE |
| single-day-application-log-histogram | TIMING/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-histogram | TIMING/total | 3.8 s | 3.8 s | -3 ms | -0.1% | IMPROVE |
| single-day-application-log-histogram | MEMORY/rss_peak | 36.5 MB | 37.2 MB | +768 KB | 2.1% | REGRESS |
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
| single-day-application-log-histogram | MEMORY/log_occurrences | 21.5 KB | 21.8 KB | +256 B | 1.2% | REGRESS |
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
| single-day-application-log-heatmap-histogram | TIMING/read_files | 3.8 s | 3.8 s | -9 ms | -0.2% | IMPROVE |
| single-day-application-log-heatmap-histogram | TIMING/calculate_statistics | 7 ms | 7 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/total | 3.8 s | 3.8 s | -8 ms | -0.2% | IMPROVE |
| single-day-application-log-heatmap-histogram | MEMORY/rss_peak | 36.6 MB | 37.1 MB | +464 KB | 1.2% | REGRESS |
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
| single-day-application-log-heatmap-histogram-consolidate | TIMING/read_files | 6.6 s | 6.7 s | +127 ms | 1.9% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/group_similar | 291 ms | 343 ms | +52 ms | 17.9% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/total | 6.8 s | 7 s | +179 ms | 2.6% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 126.3 MB | 124.3 MB | -2 MB | -1.6% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 437.5 KB | 437.5 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 2.6 MB | 2.6 MB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 29.3 MB | 29.3 MB | -1 KB | -0.0% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 16.4 MB | 16.4 MB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 29.7 MB | 29.7 MB | +3.6 KB | 0.0% | REGRESS |
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
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_occurrences | 21.5 KB | 21.8 KB | +256 B | 1.2% | REGRESS |
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
| multi-day-application-logs-standard | TIMING/read_files | 8.2 s | 8.3 s | +18 ms | 0.2% | REGRESS |
| multi-day-application-logs-standard | TIMING/calculate_statistics | 166 ms | 197 ms | +31 ms | 18.7% | REGRESS |
| multi-day-application-logs-standard | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-standard | TIMING/total | 8.4 s | 8.5 s | +50 ms | 0.6% | REGRESS |
| multi-day-application-logs-standard | MEMORY/rss_peak | 114.7 MB | 117.9 MB | +3.2 MB | 2.8% | REGRESS |
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
| multi-day-application-logs-top25 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/read_files | 8.0 s | 8.1 s | +162 ms | 2.0% | REGRESS |
| multi-day-application-logs-top25 | TIMING/calculate_statistics | 197 ms | 193 ms | -4 ms | -2.0% | IMPROVE |
| multi-day-application-logs-top25 | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/total | 8.1 s | 8.3 s | +159 ms | 2.0% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/rss_peak | 117.1 MB | 115.1 MB | -2 MB | -1.7% | IMPROVE |
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
| multi-day-application-logs-top25-consolidate | TIMING/read_files | 39.2 s | 41 s | +1.8 s | 4.6% | REGRESS |
| multi-day-application-logs-top25-consolidate | TIMING/group_similar | 4.5 s | 5 s | +551 ms | 12.3% | REGRESS |
| multi-day-application-logs-top25-consolidate | TIMING/calculate_statistics | 4 ms | 3 ms | -1 ms | -25.0% | IMPROVE |
| multi-day-application-logs-top25-consolidate | TIMING/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/total | 43.7 s | 46.1 s | +2.3 s | 5.4% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | 227.3 MB | 229.9 MB | +2.6 MB | 1.1% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_clusters | 3.6 MB | 3.6 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_message | 3.5 MB | 3.5 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 62.2 MB | 62.2 MB | +1 KB | 0.0% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 10.4 MB | 10.4 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_ngram_index | 60.8 MB | 60.8 MB | -32.9 KB | -0.1% | IMPROVE |
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
| multi-day-application-logs-top25-consolidate | MEMORY/log_occurrences | 56.7 KB | 56.6 KB | -64 B | -0.1% | IMPROVE |
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
| multi-day-application-logs-heatmap | TIMING/read_files | 8.4 s | 8.2 s | -160 ms | -1.9% | IMPROVE |
| multi-day-application-logs-heatmap | TIMING/calculate_statistics | 193 ms | 184 ms | -9 ms | -4.7% | IMPROVE |
| multi-day-application-logs-heatmap | TIMING/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| multi-day-application-logs-heatmap | TIMING/total | 8.6 s | 8.4 s | -170 ms | -2.0% | IMPROVE |
| multi-day-application-logs-heatmap | MEMORY/rss_peak | 115.1 MB | 115.8 MB | +720 KB | 0.6% | REGRESS |
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
| multi-day-application-logs-histogram | TIMING/read_files | 8.5 s | 8.4 s | -49 ms | -0.6% | IMPROVE |
| multi-day-application-logs-histogram | TIMING/calculate_statistics | 171 ms | 201 ms | +30 ms | 17.5% | REGRESS |
| multi-day-application-logs-histogram | TIMING/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| multi-day-application-logs-histogram | TIMING/total | 8.6 s | 8.6 s | -19 ms | -0.2% | IMPROVE |
| multi-day-application-logs-histogram | MEMORY/rss_peak | 117.8 MB | 116.7 MB | -1.1 MB | -1.0% | IMPROVE |
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
| multi-day-application-logs-heatmap-histogram | TIMING/read_files | 7.9 s | 8.3 s | +354 ms | 4.5% | REGRESS |
| multi-day-application-logs-heatmap-histogram | TIMING/calculate_statistics | 181 ms | 211 ms | +30 ms | 16.6% | REGRESS |
| multi-day-application-logs-heatmap-histogram | TIMING/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/total | 8.1 s | 8.5 s | +385 ms | 4.8% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/rss_peak | 114.4 MB | 118.9 MB | +4.5 MB | 4.0% | REGRESS |
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
| multi-day-application-logs-heatmap-histogram | MEMORY/log_occurrences | 56.7 KB | 56.6 KB | -64 B | -0.1% | IMPROVE |
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
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/read_files | 41.8 s | 42.0 s | +225 ms | 0.5% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/group_similar | 4.7 s | 5.3 s | +583 ms | 12.3% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/normalize_data | 3 ms | 4 ms | +1 ms | 33.3% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | 46.5 s | 47.3 s | +809 ms | 1.7% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 227.8 MB | 227.7 MB | -144 KB | -0.1% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 3.6 MB | 3.6 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 3.5 MB | 3.5 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 62.2 MB | 62.2 MB | +3 KB | 0.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 10.4 MB | 10.4 MB | -8 KB | -0.1% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 60.8 MB | 60.8 MB | -5.6 KB | -0.0% | IMPROVE |
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
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 56.7 KB | 56.6 KB | -64 B | -0.1% | IMPROVE |
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
| multi-day-custom-logs-standard | TIMING/read_files | 16.8 s | 17.5 s | +667 ms | 4.0% | REGRESS |
| multi-day-custom-logs-standard | TIMING/calculate_statistics | 449 ms | 498 ms | +49 ms | 10.9% | REGRESS |
| multi-day-custom-logs-standard | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/total | 17.3 s | 18.0 s | +716 ms | 4.1% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/rss_peak | 202.8 MB | 204.7 MB | +1.8 MB | 0.9% | REGRESS |
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
| multi-day-custom-logs-standard | MEMORY/log_messages | 103.0 MB | 103.0 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_stats | 72.4 KB | 72.4 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY_FINAL/log_messages | 107978981 | 107978981 | 0 | 0.0% |  |
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
| multi-day-custom-logs-top25 | TIMING/read_files | 16.6 s | 17.6 s | +959 ms | 5.8% | REGRESS |
| multi-day-custom-logs-top25 | TIMING/calculate_statistics | 500 ms | 481 ms | -19 ms | -3.8% | IMPROVE |
| multi-day-custom-logs-top25 | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/total | 17.1 s | 18.1 s | +941 ms | 5.5% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/rss_peak | 205.2 MB | 206.2 MB | +1 MB | 0.5% | REGRESS |
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
| multi-day-custom-logs-top25 | MEMORY/log_messages | 102.5 MB | 103 MB | +481.8 KB | 0.5% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_stats | 72.4 KB | 72.4 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY_FINAL/log_messages | 107515909 | 108009221 | 493312 | 0.5% | REGRESS |
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
| multi-day-custom-logs-top25-consolidate | TIMING/read_files | 52.0 s | 55.0 s | +3.0 s | 5.7% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/group_similar | 5.2 s | 5.8 s | +563 ms | 10.8% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/calculate_statistics | 497 ms | 676 ms | +179 ms | 36.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/total | 57.7 s | 1 min | +3.7 s | 6.5% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/rss_peak | 263.9 MB | 261.3 MB | -2.6 MB | -1.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_clusters | 29.5 MB | 29.5 MB | +3.2 KB | 0.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_message | 5.8 MB | 5.8 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 62.6 MB | 62.6 MB | +1 KB | 0.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 4.5 MB | 4.5 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_ngram_index | 61.3 MB | 61.3 MB | +5.7 KB | 0.0% | REGRESS |
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
| multi-day-custom-logs-top25-consolidate | MEMORY/log_analysis | 28.4 MB | 28.4 MB | +256 B | 0.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_messages | 28.6 MB | 28.6 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_stats | 72.2 KB | 72.4 KB | +256 B | 0.3% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/log_messages | 30020363 | 30020363 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 20086 | 20342 | 256 | 1.3% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 30966612 | 30969940 | 3328 | 0.0% | REGRESS |
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
| multi-day-custom-logs-heatmap | TIMING/read_files | 17.2 s | 18.1 s | +947 ms | 5.5% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/calculate_statistics | 328 ms | 354 ms | +26 ms | 7.9% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/heatmap_statistics | 16 ms | 17 ms | +1 ms | 6.3% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/total | 17.5 s | 18.5 s | +974 ms | 5.6% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/rss_peak | 179.9 MB | 183.9 MB | +4 MB | 2.2% | REGRESS |
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
| multi-day-custom-logs-heatmap | MEMORY/heatmap_counters | 983.2 KB | 983.4 KB | +256 B | 0.0% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_data | 43.2 KB | 43.7 KB | +512 B | 1.2% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_analysis | 20.7 KB | 20.9 KB | +256 B | 1.2% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/log_messages | 103.0 MB | 102.5 MB | -483.6 KB | -0.5% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_stats | 58.3 KB | 58.6 KB | +256 B | 0.4% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/log_messages | 107978981 | 107483749 | -495232 | -0.5% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/log_analysis | 20086 | 20342 | 256 | 1.3% | REGRESS |
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
| multi-day-custom-logs-histogram | TIMING/read_files | 17.5 s | 18.4 s | +894 ms | 5.1% | REGRESS |
| multi-day-custom-logs-histogram | TIMING/calculate_statistics | 453 ms | 503 ms | +50 ms | 11.0% | REGRESS |
| multi-day-custom-logs-histogram | TIMING/histogram_statistics | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| multi-day-custom-logs-histogram | TIMING/total | 18.0 s | 18.9 s | +944 ms | 5.3% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/rss_peak | 204 MB | 205.8 MB | +1.8 MB | 0.9% | REGRESS |
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
| multi-day-custom-logs-histogram | MEMORY/log_messages | 103.0 MB | 102.5 MB | -483.8 KB | -0.5% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_stats | 72.4 KB | 72.4 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY_FINAL/log_messages | 107978981 | 107483557 | -495424 | -0.5% | IMPROVE |
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
| multi-day-custom-logs-heatmap-histogram | TIMING/read_files | 18.0 s | 18.9 s | +936 ms | 5.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | TIMING/calculate_statistics | 333 ms | 351 ms | +18 ms | 5.4% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | TIMING/heatmap_statistics | 15 ms | 16 ms | +1 ms | 6.7% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | TIMING/histogram_statistics | 3 ms | 4 ms | +1 ms | 33.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | TIMING/normalize_data | 2 ms | 1 ms | -1 ms | -50.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/total | 18.3 s | 19.3 s | +955 ms | 5.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/rss_peak | 181.7 MB | 179 MB | -2.7 MB | -1.5% | IMPROVE |
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
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_counters | 981.9 KB | 983.4 KB | +1.5 KB | 0.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_data | 42.4 KB | 43.6 KB | +1.1 KB | 2.7% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_counters | 121.9 KB | 122.1 KB | +192 B | 0.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_analysis | 20.9 KB | 20.9 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_messages | 103.0 MB | 102.5 MB | -483.6 KB | -0.5% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_stats | 58.6 KB | 58.6 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 107978789 | 107483557 | -495232 | -0.5% | IMPROVE |
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
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/read_files | 55.3 s | 56.1 s | +780 ms | 1.4% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/group_similar | 4.9 s | 5.2 s | +275 ms | 5.6% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | 235 ms | 222 ms | -13 ms | -5.5% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/heatmap_statistics | 21 ms | 21 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/histogram_statistics | 4 ms | 4 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/normalize_data | 3 ms | 2 ms | -1 ms | -33.3% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/total | 1 min | 1 min | +1 s | 1.7% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 247.3 MB | 243.9 MB | -3.4 MB | -1.4% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 29.5 MB | 29.5 MB | -3.2 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 5.8 MB | 5.8 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 62.6 MB | 62.6 MB | +4 KB | 0.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 4.5 MB | 4.5 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 61.3 MB | 61.3 MB | -4.6 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 202.1 KB | 202.1 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 478.1 KB | 478.1 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 3.3 MB | 3.3 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 981.9 KB | 983.4 KB | +1.5 KB | 0.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 43.3 KB | 43.8 KB | +512 B | 1.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | 121.9 KB | 122.1 KB | +192 B | 0.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 20.9 KB | 20.9 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 28.6 MB | 28.6 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 58.6 KB | 58.6 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 30008267 | 30008267 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 20342 | 20342 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 30969940 | 30966612 | -3328 | -0.0% | IMPROVE |
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
| single-day-access-log-standard | TIMING/read_files | 9.9 s | 10.3 s | +332 ms | 3.3% | REGRESS |
| single-day-access-log-standard | TIMING/calculate_statistics | 378 ms | 397 ms | +19 ms | 5.0% | REGRESS |
| single-day-access-log-standard | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-standard | TIMING/total | 10.3 s | 10.7 s | +352 ms | 3.4% | REGRESS |
| single-day-access-log-standard | MEMORY/rss_peak | 163.8 MB | 165.4 MB | +1.5 MB | 0.9% | REGRESS |
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
| single-day-access-log-standard | MEMORY/log_messages | 55.4 MB | 55.4 MB | -6.9 KB | -0.0% | IMPROVE |
| single-day-access-log-standard | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_stats | 43.1 KB | 43.1 KB | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY_FINAL/log_messages | 58128849 | 58121809 | -7040 | -0.0% | IMPROVE |
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
| single-day-access-log-top25 | TIMING/read_files | 9.9 s | 10 s | +157 ms | 1.6% | REGRESS |
| single-day-access-log-top25 | TIMING/calculate_statistics | 419 ms | 436 ms | +17 ms | 4.1% | REGRESS |
| single-day-access-log-top25 | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25 | TIMING/total | 10.3 s | 10.5 s | +174 ms | 1.7% | REGRESS |
| single-day-access-log-top25 | MEMORY/rss_peak | 164 MB | 163.1 MB | -960 KB | -0.6% | IMPROVE |
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
| single-day-access-log-top25 | MEMORY/log_messages | 55.5 MB | 55.5 MB | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_stats | 43.1 KB | 43.1 KB | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY_FINAL/log_messages | 58152289 | 58152289 | 0 | 0.0% |  |
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
| single-day-access-log-top25-consolidate | TIMING/read_files | 11.6 s | 12.0 s | +373 ms | 3.2% | REGRESS |
| single-day-access-log-top25-consolidate | TIMING/group_similar | 4.3 s | 4.7 s | +354 ms | 8.2% | REGRESS |
| single-day-access-log-top25-consolidate | TIMING/calculate_statistics | 623 ms | 714 ms | +91 ms | 14.6% | REGRESS |
| single-day-access-log-top25-consolidate | TIMING/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| single-day-access-log-top25-consolidate | TIMING/total | 16.6 s | 17.4 s | +820 ms | 4.9% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/rss_peak | 210.3 MB | 207.7 MB | -2.6 MB | -1.2% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_clusters | 48.4 MB | 48.4 MB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_message | 883 KB | 883 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_trigrams | 4.1 MB | 4.1 MB | +3 KB | 0.1% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_ngram_index | 4.8 MB | 4.8 MB | -7.6 KB | -0.2% | IMPROVE |
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
| single-day-access-log-top25-consolidate | MEMORY/log_messages | 55.4 MB | 55.4 MB | -6.9 KB | -0.0% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_stats | 43.1 KB | 43.1 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/log_messages | 56115074 | 56113218 | -1856 | -0.0% | IMPROVE |
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
| single-day-access-log-heatmap | TIMING/read_files | 10.8 s | 11.0 s | +236 ms | 2.2% | REGRESS |
| single-day-access-log-heatmap | TIMING/calculate_statistics | 104 ms | 107 ms | +3 ms | 2.9% | REGRESS |
| single-day-access-log-heatmap | TIMING/heatmap_statistics | 8 ms | 9 ms | +1000 us | 12.5% | REGRESS |
| single-day-access-log-heatmap | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap | TIMING/total | 10.9 s | 11.1 s | +240 ms | 2.2% | REGRESS |
| single-day-access-log-heatmap | MEMORY/rss_peak | 127.8 MB | 128.4 MB | +560 KB | 0.4% | REGRESS |
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
| single-day-access-log-heatmap | MEMORY/heatmap_counters | 569.7 KB | 568.8 KB | -960 B | -0.2% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_data | 34 KB | 34 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/histogram_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_analysis | 8.1 KB | 8.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_messages | 55.4 MB | 55.4 MB | -6.9 KB | -0.0% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_stats | 34.5 KB | 34.5 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY_FINAL/log_messages | 58128849 | 58121809 | -7040 | -0.0% | IMPROVE |
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
| single-day-access-log-histogram | TIMING/read_files | 11.8 s | 12.4 s | +603 ms | 5.1% | REGRESS |
| single-day-access-log-histogram | TIMING/calculate_statistics | 369 ms | 385 ms | +16 ms | 4.3% | REGRESS |
| single-day-access-log-histogram | TIMING/histogram_statistics | 3 ms | 3 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/total | 12.2 s | 12.8 s | +620 ms | 5.1% | REGRESS |
| single-day-access-log-histogram | MEMORY/rss_peak | 164.1 MB | 165.6 MB | +1.5 MB | 0.9% | REGRESS |
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
| single-day-access-log-histogram | MEMORY/histogram_counters | 105.5 KB | 105.6 KB | +128 B | 0.1% | REGRESS |
| single-day-access-log-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_analysis | 52.7 MB | 52.7 MB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_messages | 55.2 MB | 55.4 MB | +198.4 KB | 0.4% | REGRESS |
| single-day-access-log-histogram | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_stats | 43.1 KB | 43.1 KB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY_FINAL/log_messages | 57925713 | 58128849 | 203136 | 0.4% | REGRESS |
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
| single-day-access-log-heatmap-histogram | TIMING/read_files | 12.5 s | 12.9 s | +409 ms | 3.3% | REGRESS |
| single-day-access-log-heatmap-histogram | TIMING/calculate_statistics | 103 ms | 108 ms | +5 ms | 4.9% | REGRESS |
| single-day-access-log-heatmap-histogram | TIMING/heatmap_statistics | 8 ms | 9 ms | +1000 us | 12.5% | REGRESS |
| single-day-access-log-heatmap-histogram | TIMING/histogram_statistics | 3 ms | 3 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| single-day-access-log-heatmap-histogram | TIMING/total | 12.6 s | 13 s | +416 ms | 3.3% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/rss_peak | 125.9 MB | 129.0 MB | +3.1 MB | 2.5% | REGRESS |
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
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_counters | 569.7 KB | 568.8 KB | -960 B | -0.2% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_counters_hl | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_data | 34 KB | 34 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_counters | 105.6 KB | 105.5 KB | -128 B | -0.1% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_analysis | 8.1 KB | 8.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_messages | 55.4 MB | 55.4 MB | +6.9 KB | 0.0% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_stats | 34.5 KB | 34.5 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/log_messages | 58121809 | 58128849 | 7040 | 0.0% | REGRESS |
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
| single-day-access-log-heatmap-histogram-consolidate | TIMING/read_files | 14.3 s | 14.5 s | +265 ms | 1.9% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/group_similar | 3.2 s | 3.5 s | +288 ms | 9.0% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/calculate_statistics | 340 ms | 356 ms | +16 ms | 4.7% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/heatmap_statistics | 9 ms | 9 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/histogram_statistics | 3 ms | 3 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/total | 17.8 s | 18.4 s | +569 ms | 3.2% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 182.7 MB | 180.9 MB | -1.8 MB | -1.0% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 48.4 MB | 48.4 MB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 883 KB | 883 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 4.1 MB | 4.1 MB | -2 KB | -0.0% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 4.8 MB | 4.8 MB | +640 B | 0.0% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 118.1 KB | 118.1 KB | 0 B | 0.0% |  |
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
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_messages | 55.4 MB | 55.2 MB | -199 KB | -0.4% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_stats | 34.5 KB | 34.5 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 56084594 | 56055346 | -29248 | -0.1% | IMPROVE |
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
| month-single-server-access-logs-standard | lines_read | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | lines_included | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/read_files | 1.8 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/group_similar | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/calculate_statistics | 7.2 s | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/heatmap_statistics | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/histogram_statistics | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/normalize_data | 2 ms | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/total | 2.0 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/rss_peak | 2.7 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/bucket_stats_counters | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/bucket_stats_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/consolidation_clusters | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/consolidation_key_message | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/consolidation_key_trigrams | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/consolidation_patterns | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/consolidation_unmatched | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/heatmap_counters | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/heatmap_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/heatmap_data | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/heatmap_raw | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/histogram_counters | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/histogram_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/histogram_values | 576 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/log_analysis | 567.3 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/log_messages | 1.6 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/log_occurrences | 36.6 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/log_sessions | 2.2 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/log_stats | 82.4 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/log_threadpools | 232 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/threadpool_activity | 762 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/log_messages | 1702552882 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/log_analysis | 13010 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_clusters | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_patterns | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_key_message | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_unmatched | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_key_trigrams | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | COUNTS/log_messages_entries | 1212275 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | COUNTS/log_occurrences_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | COUNTS/log_stats_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | CONFIG/terminal_height | 24 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | CONFIG/time_bucket_size | 1440 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | CONFIG/bucket_size_seconds | 86400.00 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | lines_read | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | lines_included | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/read_files | 1.9 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/group_similar | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/calculate_statistics | 7.4 s | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/heatmap_statistics | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/histogram_statistics | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/normalize_data | 2 ms | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/total | 2.1 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/rss_peak | 2.7 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/bucket_stats_counters | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/bucket_stats_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/consolidation_clusters | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/consolidation_key_message | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/consolidation_key_trigrams | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/consolidation_patterns | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/consolidation_unmatched | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/heatmap_counters | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/heatmap_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/heatmap_data | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/heatmap_raw | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/histogram_counters | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/histogram_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/histogram_values | 576 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/log_analysis | 567.3 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/log_messages | 1.6 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/log_occurrences | 36.6 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/log_sessions | 2.2 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/log_stats | 82.4 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/log_threadpools | 232 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/threadpool_activity | 762 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/log_messages | 1704497778 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/log_analysis | 13010 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_clusters | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_patterns | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_key_message | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_unmatched | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | COUNTS/log_messages_entries | 1212275 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | COUNTS/log_occurrences_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | COUNTS/log_stats_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | CONFIG/terminal_height | 24 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | CONFIG/time_bucket_size | 1440 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | CONFIG/bucket_size_seconds | 86400.00 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | lines_read | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | lines_included | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/read_files | 2.5 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/group_similar | 1.8 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/calculate_statistics | 10.9 s | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/heatmap_statistics | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/histogram_statistics | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/normalize_data | 3 ms | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/total | 4.4 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | 1.7 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_clusters | 507.2 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_message | 2.5 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 36.7 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 29.4 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_ngram_index | 36.0 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_patterns | 283.0 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_posting_size | 973.6 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | 1.6 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_counters | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_counters | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_values | 576 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_analysis | 567.4 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_messages | 567.1 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_occurrences | 36.8 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_sessions | 2.2 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_stats | 82.4 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/log_messages | 594631002 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 13010 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 531862951 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 248469 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 424 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 65592 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_messages_entries | 1317 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_occurrences_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_stats_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/terminal_height | 24 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/time_bucket_size | 1440 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/bucket_size_seconds | 86400.00 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | lines_read | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | lines_included | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/read_files | 2.0 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/group_similar | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/calculate_statistics | 2.2 s | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/heatmap_statistics | 67 ms | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/histogram_statistics | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/normalize_data | 3 ms | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/total | 2 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/rss_peak | 2.1 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/bucket_stats_counters | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/bucket_stats_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_clusters | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_key_message | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_key_trigrams | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_patterns | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_counters | 2.4 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_counters_hl | 232 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_data | 83.1 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_raw | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/histogram_counters | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/histogram_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/histogram_values | 576 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/log_analysis | 15.7 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/log_messages | 1.6 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/log_occurrences | 36.6 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/log_sessions | 2.2 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/log_stats | 64.9 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/log_threadpools | 232 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/threadpool_activity | 762 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/log_messages | 1704465314 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/log_analysis | 13010 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_clusters | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_patterns | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_key_message | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_unmatched | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | COUNTS/log_messages_entries | 1212275 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | COUNTS/log_occurrences_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | COUNTS/log_stats_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | CONFIG/terminal_height | 24 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | CONFIG/time_bucket_size | 1440 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | CONFIG/bucket_size_seconds | 86400.00 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | lines_read | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | lines_included | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/read_files | 2.2 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/group_similar | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/calculate_statistics | 6.9 s | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/heatmap_statistics | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/histogram_statistics | 12 ms | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/normalize_data | 3 ms | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/total | 2.3 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/rss_peak | 2.7 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/bucket_stats_counters | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/bucket_stats_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/consolidation_clusters | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/consolidation_key_message | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/consolidation_key_trigrams | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/consolidation_patterns | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/consolidation_unmatched | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/heatmap_counters | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/heatmap_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/heatmap_data | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/heatmap_raw | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/histogram_counters | 295.5 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/histogram_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/histogram_values | 576 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/log_analysis | 567.3 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/log_messages | 1.6 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/log_occurrences | 36.8 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/log_sessions | 2.2 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/log_stats | 82.4 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/log_threadpools | 232 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/threadpool_activity | 762 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/log_messages | 1704465650 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/log_analysis | 13010 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_clusters | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_patterns | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_key_message | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | COUNTS/log_messages_entries | 1212275 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | COUNTS/log_occurrences_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | COUNTS/log_stats_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | CONFIG/terminal_height | 24 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | CONFIG/time_bucket_size | 1440 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | CONFIG/bucket_size_seconds | 86400.00 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | lines_read | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | lines_included | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/read_files | 2.3 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/group_similar | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/calculate_statistics | 2.3 s | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/heatmap_statistics | 65 ms | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/histogram_statistics | 7 ms | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/normalize_data | 2 ms | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/total | 2.4 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/rss_peak | 2.1 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/bucket_stats_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_counters | 2.4 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | 232 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_data | 83.1 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_raw | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_counters | 295.6 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_values | 576 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_analysis | 15.7 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_messages | 1.6 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_occurrences | 36.8 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_sessions | 2.2 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_stats | 64.9 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 1704465314 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 13010 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | COUNTS/log_messages_entries | 1212275 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | COUNTS/log_occurrences_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | COUNTS/log_stats_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | CONFIG/terminal_height | 24 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | CONFIG/time_bucket_size | 1440 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | CONFIG/bucket_size_seconds | 86400.00 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_read | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_included | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/read_files | 2.9 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/group_similar | 1.3 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | 4.2 s | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/heatmap_statistics | 64 ms | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/histogram_statistics | 11 ms | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/normalize_data | 3 ms | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | 4.3 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 1.3 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 507.2 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 2.5 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 36.7 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 29.2 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 35.9 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 283.0 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 973.6 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 1.6 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 2.4 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 232 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 83.1 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | 295.6 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 15.7 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 567.0 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 36.6 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 2.2 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 64.9 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 594534330 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 13010 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 531863079 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 248469 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 424 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 65592 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 1317 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 1440 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 86400.00 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | lines_included | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/read_files | 8.9 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/group_similar | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/calculate_statistics | 41.5 s | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/heatmap_statistics | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/histogram_statistics | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/normalize_data | 3 ms | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/total | 9.6 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/rss_peak | 12.5 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/bucket_stats_counters | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/bucket_stats_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/consolidation_clusters | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/consolidation_key_message | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/consolidation_key_trigrams | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/consolidation_patterns | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/consolidation_unmatched | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/heatmap_counters | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/heatmap_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/heatmap_data | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/heatmap_raw | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/histogram_counters | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/histogram_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/histogram_values | 576 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/log_analysis | 2.9 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/log_messages | 7.8 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/log_occurrences | 43.8 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/log_sessions | 14.9 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/log_stats | 84 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/log_threadpools | 232 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/threadpool_activity | 762 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/log_messages | 8410470797 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/log_analysis | 13010 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_clusters | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_patterns | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_key_message | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_unmatched | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_key_trigrams | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | COUNTS/log_messages_entries | 6187253 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | COUNTS/log_occurrences_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | COUNTS/log_stats_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | CONFIG/terminal_height | 24 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | CONFIG/time_bucket_size | 1440 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | CONFIG/bucket_size_seconds | 86400.00 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | lines_included | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/read_files | 8.8 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/group_similar | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/calculate_statistics | 42.6 s | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/heatmap_statistics | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/histogram_statistics | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/normalize_data | 3 ms | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/total | 9.5 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/rss_peak | 12.3 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/bucket_stats_counters | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/bucket_stats_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_clusters | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_key_message | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_key_trigrams | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_patterns | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_unmatched | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_counters | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_data | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_raw | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/histogram_counters | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/histogram_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/histogram_values | 576 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/log_analysis | 2.9 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/log_messages | 7.8 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/log_occurrences | 42.1 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/log_sessions | 14.9 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/log_stats | 84 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/log_threadpools | 232 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/threadpool_activity | 762 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/log_messages | 8410503821 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/log_analysis | 13010 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_clusters | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_patterns | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_key_message | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_unmatched | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | COUNTS/log_messages_entries | 6187253 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | COUNTS/log_occurrences_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | COUNTS/log_stats_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | CONFIG/terminal_height | 24 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | CONFIG/time_bucket_size | 1440 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | CONFIG/bucket_size_seconds | 86400.00 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | lines_included | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/read_files | 11.4 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/group_similar | 17.7 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/calculate_statistics | 54.9 s | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/heatmap_statistics | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/histogram_statistics | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/normalize_data | 4 ms | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | 30 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | 7.3 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/bucket_stats_counters | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_clusters | 2.6 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_message | 2.5 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | 36.8 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | 25.9 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_ngram_index | 36.1 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_patterns | 531.2 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_posting_size | 1.2 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | 1.7 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_counters | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_counters | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_values | 576 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_analysis | 2.9 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_messages | 2.9 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_occurrences | 43.8 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_sessions | 14.9 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_stats | 84 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/log_messages | 3091563123 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 13010 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 2834456672 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 543905 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 424 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 65592 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_messages_entries | 2549 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_occurrences_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_stats_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/terminal_height | 24 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/time_bucket_size | 1440 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/bucket_size_seconds | 86400.00 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | lines_included | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/read_files | 9.8 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/group_similar | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/calculate_statistics | 15.4 s | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/heatmap_statistics | 82 ms | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/histogram_statistics | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/normalize_data | 5 ms | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/total | 10.1 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/rss_peak | 9.5 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/bucket_stats_counters | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/bucket_stats_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_clusters | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_key_message | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_key_trigrams | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_patterns | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_counters | 2.7 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_counters_hl | 232 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_data | 80.1 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_raw | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_counters | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_values | 576 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/log_analysis | 15.7 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/log_messages | 7.8 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/log_occurrences | 43.8 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/log_sessions | 14.9 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/log_stats | 64.9 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/log_threadpools | 232 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/threadpool_activity | 762 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/log_messages | 8405411373 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/log_analysis | 13010 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_clusters | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_patterns | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_key_message | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_unmatched | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | COUNTS/log_messages_entries | 6187253 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | COUNTS/log_occurrences_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | COUNTS/log_stats_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | CONFIG/terminal_height | 24 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | CONFIG/time_bucket_size | 1440 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | CONFIG/bucket_size_seconds | 86400.00 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | lines_included | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/read_files | 10.8 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/group_similar | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/calculate_statistics | 41.9 s | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/heatmap_statistics | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/histogram_statistics | 11 ms | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/normalize_data | 3 ms | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/total | 11.5 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/rss_peak | 12.2 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/bucket_stats_counters | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/bucket_stats_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_clusters | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_key_message | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_key_trigrams | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_patterns | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_unmatched | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_counters | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_data | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_raw | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/histogram_counters | 307.4 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/histogram_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/histogram_values | 576 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/log_analysis | 2.9 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/log_messages | 8.2 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/log_occurrences | 43.8 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/log_sessions | 14.9 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/log_stats | 84 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/log_threadpools | 232 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/threadpool_activity | 762 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/log_messages | 8796606605 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/log_analysis | 13010 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_clusters | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_patterns | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_key_message | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | COUNTS/log_messages_entries | 6187253 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | COUNTS/log_occurrences_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | COUNTS/log_stats_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | CONFIG/terminal_height | 24 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | CONFIG/time_bucket_size | 1440 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | CONFIG/bucket_size_seconds | 86400.00 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | lines_included | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/read_files | 11.5 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/group_similar | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/calculate_statistics | 14.1 s | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/heatmap_statistics | 81 ms | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/histogram_statistics | 10 ms | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/normalize_data | 4 ms | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/total | 11.7 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/rss_peak | 9.6 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/bucket_stats_counters | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/bucket_stats_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_ngram_index | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_posting_size | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_counters | 2.7 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | 232 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_data | 81.1 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_raw | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_counters | 307.3 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_values | 576 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_analysis | 15.7 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_messages | 7.8 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_occurrences | 42.1 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_sessions | 14.9 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_stats | 64.9 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 8405411373 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 13010 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/log_messages_entries | 6187253 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/log_occurrences_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/log_stats_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/terminal_height | 24 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/time_bucket_size | 1440 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/bucket_size_seconds | 86400.00 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_included | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/read_files | 13.9 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/group_similar | 13.0 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | 21.3 s | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/heatmap_statistics | 71 ms | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/histogram_statistics | 11 ms | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/normalize_data | 3 ms | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | 27.2 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 4.9 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/bucket_stats_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 2.6 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 2.5 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | 36.8 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | 29.4 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | 36.1 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 531.3 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | 1.2 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 1.7 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | 2.7 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | 232 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 80.1 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | 307.4 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 15.7 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 2.9 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 43.8 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 14.9 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 64.9 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 3093068947 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 13010 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 2834892768 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 544033 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 424 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | 65592 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | 65592 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 2549 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 24 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 1440 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 86400.00 | N/A | N/A | N/A | ? |

