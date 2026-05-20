
## Benchmark Comparison

  Baseline:    v0.14.4 (v0.14.4, 49 test cases)
  Current:     v0.14.5 (v0.14.5, 35 test cases)

### Timing Delta

| # | file selection | standard | top25 | top25-cons | heatmap | histogram | hm+hg | hm+hg+cons |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. | humungous-log-uniqueness | -1.9% | -2.8% | -0.5% | -7.3% | -3.6% | -5.3% | -1.2% |
| 2. | single-day-application-log | -2.5% | -1.3% | +1.9% | -1.9% | -2.1% | +1.0% | +2.1% |
| 3. | multi-day-application-logs | -2.1% | +0.4% | +2.7% | +1.3% | +2.2% | -0.8% | +9.1% |
| 4. | multi-day-custom-logs | +0.2% | +0.6% | +2.4% | +0.0% | -1.7% | -1.1% | +2.9% |
| 5. | single-day-access-log | +1.5% | +1.9% | +30.3% | +2.2% | -0.6% | -1.5% | +12.2% |
| 6. | month-single-server-access-logs | - | - | - | - | - | - | - |
| 7. | month-many-servers-access-logs | - | - | - | - | - | - | - |

### Memory Delta (RSS Peak)

| # | file selection | standard | top25 | top25-cons | heatmap | histogram | hm+hg | hm+hg+cons |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. | humungous-log-uniqueness | +1.0% | +1.6% | +1.3% | +1.5% | +1.9% | +1.0% | +1.0% |
| 2. | single-day-application-log | +6.4% | +7.7% | +0.2% | +6.9% | +6.9% | +5.1% | +2.5% |
| 3. | multi-day-application-logs | -0.1% | +1.3% | -0.9% | +4.4% | +1.5% | +2.1% | +0.1% |
| 4. | multi-day-custom-logs | +0.2% | +0.8% | +2.9% | -13.2% | -18.0% | -29.0% | -19.7% |
| 5. | single-day-access-log | +1.7% | +0.8% | +1.1% | -24.9% | -46.0% | -58.7% | -49.6% |
| 6. | month-single-server-access-logs | - | - | - | - | - | - | - |
| 7. | month-many-servers-access-logs | - | - | - | - | - | - | - |

### Summary

| test_name | metric | baseline | current | delta | change% | result |
| --- | --- | --- | --- | --- | --- | --- |
| humungous-log-uniqueness-standard | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/total | 2.7 s | 2.6 s | -51 ms | -1.9% | IMPROVE |
| humungous-log-uniqueness-standard | MEMORY/rss_peak | 200.7 MB | 202.7 MB | +2.0 MB | 1.0% | REGRESS |
| humungous-log-uniqueness-top25 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/total | 2.7 s | 2.6 s | -74 ms | -2.8% | IMPROVE |
| humungous-log-uniqueness-top25 | MEMORY/rss_peak | 200.3 MB | 203.5 MB | +3.2 MB | 1.6% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/total | 10.4 s | 10.3 s | -53 ms | -0.5% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/rss_peak | 245.9 MB | 249.1 MB | +3.2 MB | 1.3% | REGRESS |
| humungous-log-uniqueness-heatmap | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/total | 2.7 s | 2.5 s | -199 ms | -7.3% | IMPROVE |
| humungous-log-uniqueness-heatmap | MEMORY/rss_peak | 200.2 MB | 203.2 MB | +3.0 MB | 1.5% | REGRESS |
| humungous-log-uniqueness-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/total | 2.6 s | 2.5 s | -96 ms | -3.6% | IMPROVE |
| humungous-log-uniqueness-histogram | MEMORY/rss_peak | 199.7 MB | 203.5 MB | +3.8 MB | 1.9% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/total | 2.7 s | 2.6 s | -144 ms | -5.3% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/rss_peak | 201.4 MB | 203.5 MB | +2.1 MB | 1.0% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/total | 10.4 s | 10.3 s | -126 ms | -1.2% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/rss_peak | 246.1 MB | 248.5 MB | +2.4 MB | 1.0% | REGRESS |
| single-day-application-log-standard | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | TIMING/total | 3.6 s | 3.5 s | -92 ms | -2.5% | IMPROVE |
| single-day-application-log-standard | MEMORY/rss_peak | 33.2 MB | 35.3 MB | +2.1 MB | 6.4% | REGRESS |
| single-day-application-log-top25 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | TIMING/total | 3.6 s | 3.5 s | -48 ms | -1.3% | IMPROVE |
| single-day-application-log-top25 | MEMORY/rss_peak | 32.8 MB | 35.3 MB | +2.5 MB | 7.7% | REGRESS |
| single-day-application-log-top25-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/total | 6.3 s | 6.4 s | +121 ms | 1.9% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/rss_peak | 122.3 MB | 122.6 MB | +240 KB | 0.2% | REGRESS |
| single-day-application-log-heatmap | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | TIMING/total | 3.6 s | 3.5 s | -68 ms | -1.9% | IMPROVE |
| single-day-application-log-heatmap | MEMORY/rss_peak | 33.1 MB | 35.4 MB | +2.3 MB | 6.9% | REGRESS |
| single-day-application-log-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | TIMING/total | 3.6 s | 3.5 s | -77 ms | -2.1% | IMPROVE |
| single-day-application-log-histogram | MEMORY/rss_peak | 33.1 MB | 35.4 MB | +2.3 MB | 6.9% | REGRESS |
| single-day-application-log-heatmap-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/total | 3.5 s | 3.6 s | +34 ms | 1.0% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/rss_peak | 33.1 MB | 34.8 MB | +1.7 MB | 5.1% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/total | 6.3 s | 6.4 s | +134 ms | 2.1% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 121.4 MB | 124.4 MB | +3.1 MB | 2.5% | REGRESS |
| multi-day-application-logs-standard | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-standard | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-standard | TIMING/total | 8.0 s | 7.8 s | -166 ms | -2.1% | IMPROVE |
| multi-day-application-logs-standard | MEMORY/rss_peak | 113.1 MB | 112.9 MB | -160 KB | -0.1% | IMPROVE |
| multi-day-application-logs-top25 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/total | 7.8 s | 7.9 s | +28 ms | 0.4% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/rss_peak | 112.3 MB | 113.8 MB | +1.5 MB | 1.3% | REGRESS |
| multi-day-application-logs-top25-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/total | 39.5 s | 40.5 s | +1.1 s | 2.7% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | 225.2 MB | 223.3 MB | -2.0 MB | -0.9% | IMPROVE |
| multi-day-application-logs-heatmap | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/total | 7.8 s | 7.9 s | +101 ms | 1.3% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY/rss_peak | 110.7 MB | 115.5 MB | +4.8 MB | 4.4% | REGRESS |
| multi-day-application-logs-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/total | 7.7 s | 7.8 s | +169 ms | 2.2% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/rss_peak | 110.6 MB | 112.2 MB | +1.6 MB | 1.5% | REGRESS |
| multi-day-application-logs-heatmap-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/total | 7.8 s | 7.7 s | -61 ms | -0.8% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | MEMORY/rss_peak | 110.8 MB | 113.1 MB | +2.3 MB | 2.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | 37.5 s | 40.9 s | +3.4 s | 9.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 223.2 MB | 223.4 MB | +160 KB | 0.1% | REGRESS |
| multi-day-custom-logs-standard | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/total | 16.1 s | 16.1 s | +39 ms | 0.2% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/rss_peak | 198.8 MB | 199.1 MB | +352 KB | 0.2% | REGRESS |
| multi-day-custom-logs-top25 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/total | 15.9 s | 16.0 s | +92 ms | 0.6% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/rss_peak | 198.9 MB | 200.4 MB | +1.5 MB | 0.8% | REGRESS |
| multi-day-custom-logs-top25-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/total | 50.5 s | 51.7 s | +1.2 s | 2.4% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/rss_peak | 249.8 MB | 257.0 MB | +7.2 MB | 2.9% | REGRESS |
| multi-day-custom-logs-heatmap | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/total | 16.4 s | 16.5 s | +6 ms | 0.0% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/rss_peak | 206.9 MB | 179.6 MB | -27.3 MB | -13.2% | IMPROVE |
| multi-day-custom-logs-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/total | 17.0 s | 16.7 s | -285 ms | -1.7% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/rss_peak | 243.0 MB | 199.2 MB | -43.8 MB | -18.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/total | 17.3 s | 17.1 s | -198 ms | -1.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/rss_peak | 249.7 MB | 177.2 MB | -72.5 MB | -29.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/total | 50.9 s | 52.4 s | +1.5 s | 2.9% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 289.4 MB | 232.4 MB | -57 MB | -19.7% | IMPROVE |
| single-day-access-log-standard | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | TIMING/total | 9.3 s | 9.5 s | +141 ms | 1.5% | REGRESS |
| single-day-access-log-standard | MEMORY/rss_peak | 153.7 MB | 156.4 MB | +2.7 MB | 1.7% | REGRESS |
| single-day-access-log-top25 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | TIMING/total | 9.3 s | 9.5 s | +178 ms | 1.9% | REGRESS |
| single-day-access-log-top25 | MEMORY/rss_peak | 155.1 MB | 156.2 MB | +1.2 MB | 0.8% | REGRESS |
| single-day-access-log-top25-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/total | 11.5 s | 14.9 s | +3.5 s | 30.3% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/rss_peak | 191.3 MB | 193.4 MB | +2.1 MB | 1.1% | REGRESS |
| single-day-access-log-heatmap | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | TIMING/total | 9.9 s | 10.1 s | +222 ms | 2.2% | REGRESS |
| single-day-access-log-heatmap | MEMORY/rss_peak | 159.8 MB | 120.1 MB | -39.7 MB | -24.9% | IMPROVE |
| single-day-access-log-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | TIMING/total | 11.4 s | 11.3 s | -67 ms | -0.6% | IMPROVE |
| single-day-access-log-histogram | MEMORY/rss_peak | 286.3 MB | 154.6 MB | -131.6 MB | -46.0% | IMPROVE |
| single-day-access-log-heatmap-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/total | 12 s | 11.8 s | -186 ms | -1.5% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/rss_peak | 292.5 MB | 120.8 MB | -171.8 MB | -58.7% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/total | 14.4 s | 16.2 s | +1.8 s | 12.2% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 331.3 MB | 167.1 MB | -164.2 MB | -49.6% | IMPROVE |
| month-single-server-access-logs-standard | lines_read | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | lines_included | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/total | 1.8 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/rss_peak | 2.7 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | lines_read | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | lines_included | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/total | 1.8 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/rss_peak | 2.6 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | lines_read | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | lines_included | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/total | 2.4 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | 1.7 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | lines_read | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | lines_included | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/total | 2 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/rss_peak | 2.7 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | lines_read | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | lines_included | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/total | 2.3 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/rss_peak | 4 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | lines_read | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | lines_included | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/total | 2.5 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/rss_peak | 4.1 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_read | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_included | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | 3 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 3.2 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | lines_included | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/total | 9.0 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/rss_peak | 13.2 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | lines_included | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/total | 9 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/rss_peak | 13.2 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | lines_included | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | 10.9 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | 6.8 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | lines_included | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/total | 9.9 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/rss_peak | 13.3 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | lines_included | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/total | 11.4 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/rss_peak | 20.5 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | lines_included | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/total | 12.3 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/rss_peak | 19.3 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_included | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | 14.3 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 15.6 GB | N/A | N/A | N/A | ? |

### Detailed

| test_name | metric | baseline | current | delta | change% | result |
| --- | --- | --- | --- | --- | --- | --- |
| humungous-log-uniqueness-standard | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/read_files | 2.4 s | 2.3 s | -22 ms | -0.9% | IMPROVE |
| humungous-log-uniqueness-standard | TIMING/calculate_statistics | 303 ms | 275 ms | -28 ms | -9.2% | IMPROVE |
| humungous-log-uniqueness-standard | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/total | 2.7 s | 2.6 s | -51 ms | -1.9% | IMPROVE |
| humungous-log-uniqueness-standard | MEMORY/rss_peak | 200.7 MB | 202.7 MB | +2.0 MB | 1.0% | REGRESS |
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
| humungous-log-uniqueness-standard | COUNTS/log_messages_entries | 286659 | 286659 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | COUNTS/log_occurrences_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | COUNTS/log_stats_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| humungous-log-uniqueness-standard | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/read_files | 2.4 s | 2.3 s | -81 ms | -3.4% | IMPROVE |
| humungous-log-uniqueness-top25 | TIMING/calculate_statistics | 266 ms | 273 ms | +7 ms | 2.6% | REGRESS |
| humungous-log-uniqueness-top25 | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/total | 2.7 s | 2.6 s | -74 ms | -2.8% | IMPROVE |
| humungous-log-uniqueness-top25 | MEMORY/rss_peak | 200.3 MB | 203.5 MB | +3.2 MB | 1.6% | REGRESS |
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
| humungous-log-uniqueness-top25 | COUNTS/log_messages_entries | 286659 | 286659 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | COUNTS/log_occurrences_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | COUNTS/log_stats_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| humungous-log-uniqueness-top25 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/read_files | 6.4 s | 6.3 s | -84 ms | -1.3% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | TIMING/group_similar | 4 s | 4 s | +31 ms | 0.8% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/total | 10.4 s | 10.3 s | -53 ms | -0.5% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/rss_peak | 245.9 MB | 249.1 MB | +3.2 MB | 1.3% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_clusters | 196.2 KB | 196.2 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_message | 129.7 KB | 3.1 MB | +2.9 MB | 2312.0% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_patterns | 24.9 KB | 24.9 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_unmatched | 105.5 KB | 1.7 MB | +1.6 MB | 1579.8% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_messages | 120.7 KB | 2.5 MB | +2.4 MB | 2047.1% | REGRESS |
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
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_messages_entries | 72 | 72 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_occurrences_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_stats_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/read_files | 2.4 s | 2.2 s | -136 ms | -5.7% | IMPROVE |
| humungous-log-uniqueness-heatmap | TIMING/calculate_statistics | 332 ms | 268 ms | -64 ms | -19.3% | IMPROVE |
| humungous-log-uniqueness-heatmap | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/total | 2.7 s | 2.5 s | -199 ms | -7.3% | IMPROVE |
| humungous-log-uniqueness-heatmap | MEMORY/rss_peak | 200.2 MB | 203.2 MB | +3.0 MB | 1.5% | REGRESS |
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
| humungous-log-uniqueness-heatmap | COUNTS/log_messages_entries | 286659 | 286659 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | COUNTS/log_occurrences_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | COUNTS/log_stats_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| humungous-log-uniqueness-heatmap | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/read_files | 2.4 s | 2.3 s | -85 ms | -3.6% | IMPROVE |
| humungous-log-uniqueness-histogram | TIMING/calculate_statistics | 286 ms | 276 ms | -10 ms | -3.5% | IMPROVE |
| humungous-log-uniqueness-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/total | 2.6 s | 2.5 s | -96 ms | -3.6% | IMPROVE |
| humungous-log-uniqueness-histogram | MEMORY/rss_peak | 199.7 MB | 203.5 MB | +3.8 MB | 1.9% | REGRESS |
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
| humungous-log-uniqueness-histogram | COUNTS/log_messages_entries | 286659 | 286659 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | COUNTS/log_occurrences_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | COUNTS/log_stats_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| humungous-log-uniqueness-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/read_files | 2.4 s | 2.3 s | -127 ms | -5.3% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | TIMING/calculate_statistics | 284 ms | 267 ms | -17 ms | -6.0% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/total | 2.7 s | 2.6 s | -144 ms | -5.3% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/rss_peak | 201.4 MB | 203.5 MB | +2.1 MB | 1.0% | REGRESS |
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
| humungous-log-uniqueness-heatmap-histogram | COUNTS/log_messages_entries | 286659 | 286659 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | COUNTS/log_occurrences_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | COUNTS/log_stats_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/read_files | 6.2 s | 6.4 s | +124 ms | 2.0% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/group_similar | 4.1 s | 3.9 s | -251 ms | -6.0% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/total | 10.4 s | 10.3 s | -126 ms | -1.2% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/rss_peak | 246.1 MB | 248.5 MB | +2.4 MB | 1.0% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 196.2 KB | 196.2 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 129.7 KB | 3.1 MB | +2.9 MB | 2312.0% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 24.9 KB | 24.9 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 105.5 KB | 1.7 MB | +1.6 MB | 1579.8% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_messages | 120.7 KB | 2.5 MB | +2.4 MB | 2047.5% | REGRESS |
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
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 72 | 72 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 5 | 5 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-standard | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | TIMING/read_files | 3.6 s | 3.5 s | -92 ms | -2.5% | IMPROVE |
| single-day-application-log-standard | TIMING/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-standard | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-standard | TIMING/total | 3.6 s | 3.5 s | -92 ms | -2.5% | IMPROVE |
| single-day-application-log-standard | MEMORY/rss_peak | 33.2 MB | 35.3 MB | +2.1 MB | 6.4% | REGRESS |
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
| single-day-application-log-standard | COUNTS/log_messages_entries | 6512 | 6512 | 0 | 0.0% |  |
| single-day-application-log-standard | COUNTS/log_occurrences_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-standard | COUNTS/log_stats_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-standard | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-standard | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| single-day-application-log-standard | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-standard | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-standard | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-top25 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | TIMING/read_files | 3.6 s | 3.5 s | -47 ms | -1.3% | IMPROVE |
| single-day-application-log-top25 | TIMING/calculate_statistics | 7 ms | 6 ms | -1 ms | -14.3% | IMPROVE |
| single-day-application-log-top25 | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25 | TIMING/total | 3.6 s | 3.5 s | -48 ms | -1.3% | IMPROVE |
| single-day-application-log-top25 | MEMORY/rss_peak | 32.8 MB | 35.3 MB | +2.5 MB | 7.7% | REGRESS |
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
| single-day-application-log-top25 | COUNTS/log_messages_entries | 6512 | 6512 | 0 | 0.0% |  |
| single-day-application-log-top25 | COUNTS/log_occurrences_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-top25 | COUNTS/log_stats_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-top25 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-top25 | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| single-day-application-log-top25 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-top25 | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-top25 | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/read_files | 6.1 s | 6.1 s | +47 ms | 0.8% | REGRESS |
| single-day-application-log-top25-consolidate | TIMING/group_similar | 182 ms | 257 ms | +75 ms | 41.2% | REGRESS |
| single-day-application-log-top25-consolidate | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/total | 6.3 s | 6.4 s | +121 ms | 1.9% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/rss_peak | 122.3 MB | 122.6 MB | +240 KB | 0.2% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_clusters | 437.5 KB | 437.3 KB | -214 B | -0.0% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_message | 97.5 KB | 2.6 MB | +2.5 MB | 2657.3% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_patterns | 54.3 KB | 54.4 KB | +84 B | 0.2% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_unmatched | 120 KB | 1.5 MB | +1.4 MB | 1201.1% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_messages | 158.4 KB | 2.3 MB | +2.1 MB | 1380.0% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/log_occurrences | 21.8 KB | 21.8 KB | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/log_messages | 137524 | 137524 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 448005 | 447791 | -214 | -0.0% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 55576 | 55660 | 84 | 0.2% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 232 | 232 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | COUNTS/log_messages_entries | 136 | 136 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | COUNTS/log_occurrences_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | COUNTS/log_stats_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| single-day-application-log-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | TIMING/read_files | 3.6 s | 3.5 s | -68 ms | -1.9% | IMPROVE |
| single-day-application-log-heatmap | TIMING/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap | TIMING/total | 3.6 s | 3.5 s | -68 ms | -1.9% | IMPROVE |
| single-day-application-log-heatmap | MEMORY/rss_peak | 33.1 MB | 35.4 MB | +2.3 MB | 6.9% | REGRESS |
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
| single-day-application-log-heatmap | COUNTS/log_messages_entries | 6512 | 6512 | 0 | 0.0% |  |
| single-day-application-log-heatmap | COUNTS/log_occurrences_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-heatmap | COUNTS/log_stats_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-heatmap | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-heatmap | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| single-day-application-log-heatmap | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-heatmap | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-heatmap | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | TIMING/read_files | 3.6 s | 3.5 s | -77 ms | -2.1% | IMPROVE |
| single-day-application-log-histogram | TIMING/calculate_statistics | 6 ms | 7 ms | +1 ms | 16.7% | REGRESS |
| single-day-application-log-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-histogram | TIMING/total | 3.6 s | 3.5 s | -77 ms | -2.1% | IMPROVE |
| single-day-application-log-histogram | MEMORY/rss_peak | 33.1 MB | 35.4 MB | +2.3 MB | 6.9% | REGRESS |
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
| single-day-application-log-histogram | COUNTS/log_messages_entries | 6512 | 6512 | 0 | 0.0% |  |
| single-day-application-log-histogram | COUNTS/log_occurrences_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-histogram | COUNTS/log_stats_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-histogram | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| single-day-application-log-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-histogram | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-histogram | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/read_files | 3.5 s | 3.6 s | +33 ms | 0.9% | REGRESS |
| single-day-application-log-heatmap-histogram | TIMING/calculate_statistics | 6 ms | 6 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/total | 3.5 s | 3.6 s | +34 ms | 1.0% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/rss_peak | 33.1 MB | 34.8 MB | +1.7 MB | 5.1% | REGRESS |
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
| single-day-application-log-heatmap-histogram | COUNTS/log_messages_entries | 6512 | 6512 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | COUNTS/log_occurrences_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | COUNTS/log_stats_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| single-day-application-log-heatmap-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/read_files | 6.1 s | 6.1 s | +38 ms | 0.6% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/group_similar | 167 ms | 264 ms | +97 ms | 58.1% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/normalize_data | 2 ms | 1 ms | -1 ms | -50.0% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/total | 6.3 s | 6.4 s | +134 ms | 2.1% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 121.4 MB | 124.4 MB | +3.1 MB | 2.5% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 437.3 KB | 437.5 KB | +214 B | 0.0% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 97.5 KB | 2.6 MB | +2.5 MB | 2657.3% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 54.4 KB | 54.3 KB | -84 B | -0.2% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 120 KB | 1.5 MB | +1.4 MB | 1201.1% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_messages | 158.4 KB | 2.3 MB | +2.1 MB | 1380.0% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_occurrences | 21.5 KB | 21.8 KB | +256 B | 1.2% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 137524 | 137524 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 447791 | 448005 | 214 | 0.0% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 55660 | 55576 | -84 | -0.2% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 232 | 232 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 136 | 136 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 24 | 24 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-application-logs-standard | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-standard | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-standard | TIMING/read_files | 7.8 s | 7.6 s | -164 ms | -2.1% | IMPROVE |
| multi-day-application-logs-standard | TIMING/calculate_statistics | 199 ms | 196 ms | -3 ms | -1.5% | IMPROVE |
| multi-day-application-logs-standard | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-standard | TIMING/total | 8.0 s | 7.8 s | -166 ms | -2.1% | IMPROVE |
| multi-day-application-logs-standard | MEMORY/rss_peak | 113.1 MB | 112.9 MB | -160 KB | -0.1% | IMPROVE |
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
| multi-day-application-logs-standard | COUNTS/log_messages_entries | 105902 | 105902 | 0 | 0.0% |  |
| multi-day-application-logs-standard | COUNTS/log_occurrences_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-standard | COUNTS/log_stats_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-standard | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-standard | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| multi-day-application-logs-standard | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-standard | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-standard | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/read_files | 7.7 s | 7.7 s | +31 ms | 0.4% | REGRESS |
| multi-day-application-logs-top25 | TIMING/calculate_statistics | 181 ms | 179 ms | -2 ms | -1.1% | IMPROVE |
| multi-day-application-logs-top25 | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/total | 7.8 s | 7.9 s | +28 ms | 0.4% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/rss_peak | 112.3 MB | 113.8 MB | +1.5 MB | 1.3% | REGRESS |
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
| multi-day-application-logs-top25 | COUNTS/log_messages_entries | 105902 | 105902 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | COUNTS/log_occurrences_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | COUNTS/log_stats_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| multi-day-application-logs-top25 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/read_files | 37.2 s | 36.3 s | -928 ms | -2.5% | IMPROVE |
| multi-day-application-logs-top25-consolidate | TIMING/initialize_buckets | 1 ms | 0 us | -1 ms | -100.0% | IMPROVE |
| multi-day-application-logs-top25-consolidate | TIMING/group_similar | 2.3 s | 4.3 s | +2.0 s | 87.9% | REGRESS |
| multi-day-application-logs-top25-consolidate | TIMING/calculate_statistics | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/total | 39.5 s | 40.5 s | +1.1 s | 2.7% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | 225.2 MB | 223.3 MB | -2.0 MB | -0.9% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_clusters | 3.6 MB | 3.6 MB | -40 B | -0.0% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_message | 309.4 KB | 3.5 MB | +3.2 MB | 1073.4% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_patterns | 486.2 KB | 485.8 KB | -363 B | -0.1% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_unmatched | 368.0 KB | 2.1 MB | +1.8 MB | 494.9% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_messages | 709.4 KB | 3.2 MB | +2.5 MB | 359.2% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/log_occurrences | 56.6 KB | 56.6 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/log_messages | 726422 | 726422 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 3738276 | 3738236 | -40 | -0.0% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 497821 | 497458 | -363 | -0.1% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 232 | 232 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | COUNTS/log_messages_entries | 1304 | 1304 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | COUNTS/log_occurrences_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | COUNTS/log_stats_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| multi-day-application-logs-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/read_files | 7.6 s | 7.7 s | +93 ms | 1.2% | REGRESS |
| multi-day-application-logs-heatmap | TIMING/calculate_statistics | 179 ms | 188 ms | +9 ms | 5.0% | REGRESS |
| multi-day-application-logs-heatmap | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/total | 7.8 s | 7.9 s | +101 ms | 1.3% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY/rss_peak | 110.7 MB | 115.5 MB | +4.8 MB | 4.4% | REGRESS |
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
| multi-day-application-logs-heatmap | MEMORY/log_messages | 45.8 MB | 45.8 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_occurrences | 56.7 KB | 56.7 KB | 0 B | 0.0% |  |
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
| multi-day-application-logs-heatmap | COUNTS/log_messages_entries | 105902 | 105902 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | COUNTS/log_occurrences_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | COUNTS/log_stats_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| multi-day-application-logs-heatmap | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/read_files | 7.5 s | 7.6 s | +168 ms | 2.2% | REGRESS |
| multi-day-application-logs-histogram | TIMING/calculate_statistics | 178 ms | 180 ms | +2 ms | 1.1% | REGRESS |
| multi-day-application-logs-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/total | 7.7 s | 7.8 s | +169 ms | 2.2% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/rss_peak | 110.6 MB | 112.2 MB | +1.6 MB | 1.5% | REGRESS |
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
| multi-day-application-logs-histogram | MEMORY/log_messages | 45.8 MB | 45.8 MB | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_occurrences | 56.6 KB | 56.7 KB | +64 B | 0.1% | REGRESS |
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
| multi-day-application-logs-histogram | COUNTS/log_messages_entries | 105902 | 105902 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | COUNTS/log_occurrences_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | COUNTS/log_stats_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| multi-day-application-logs-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/read_files | 7.6 s | 7.6 s | -63 ms | -0.8% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | TIMING/calculate_statistics | 177 ms | 179 ms | +2 ms | 1.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/total | 7.8 s | 7.7 s | -61 ms | -0.8% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | MEMORY/rss_peak | 110.8 MB | 113.1 MB | +2.3 MB | 2.1% | REGRESS |
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
| multi-day-application-logs-heatmap-histogram | COUNTS/log_messages_entries | 105902 | 105902 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | COUNTS/log_occurrences_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | COUNTS/log_stats_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/read_files | 35.5 s | 36.6 s | +1.1 s | 3.2% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/group_similar | 2 s | 4.3 s | +2.3 s | 113.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | 37.5 s | 40.9 s | +3.4 s | 9.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 223.2 MB | 223.4 MB | +160 KB | 0.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 3.6 MB | 3.6 MB | +320 B | 0.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 309.4 KB | 3.5 MB | +3.2 MB | 1073.4% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 486.2 KB | 486.5 KB | +357 B | 0.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 368.0 KB | 2.1 MB | +1.8 MB | 494.9% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 709.4 KB | 3.2 MB | +2.5 MB | 359.2% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 56.7 KB | 56.6 KB | -64 B | -0.1% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 726422 | 726422 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 232 | 232 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 3738276 | 3738596 | 320 | 0.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 497821 | 498178 | 357 | 0.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 232 | 232 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 1304 | 1304 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 53 | 53 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 480 | 480 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 28800.00 | 28800.00 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/read_files | 15.7 s | 15.7 s | +35 ms | 0.2% | REGRESS |
| multi-day-custom-logs-standard | TIMING/calculate_statistics | 383 ms | 386 ms | +3 ms | 0.8% | REGRESS |
| multi-day-custom-logs-standard | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/total | 16.1 s | 16.1 s | +39 ms | 0.2% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/rss_peak | 198.8 MB | 199.1 MB | +352 KB | 0.2% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_analysis | 28.4 MB | 28.4 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_messages | 102.6 MB | 102.6 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_stats | 54.7 KB | 54.7 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY_FINAL/log_messages | 107569190 | 107569190 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY_FINAL/log_analysis | 20342 | 20342 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | COUNTS/log_messages_entries | 182419 | 182419 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | COUNTS/log_occurrences_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | COUNTS/log_stats_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| multi-day-custom-logs-standard | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/read_files | 15.5 s | 15.6 s | +93 ms | 0.6% | REGRESS |
| multi-day-custom-logs-top25 | TIMING/calculate_statistics | 391 ms | 390 ms | -1 ms | -0.3% | IMPROVE |
| multi-day-custom-logs-top25 | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/total | 15.9 s | 16.0 s | +92 ms | 0.6% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/rss_peak | 198.9 MB | 200.4 MB | +1.5 MB | 0.8% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_analysis | 28.4 MB | 28.4 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_messages | 102.6 MB | 102.6 MB | -5.8 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_stats | 54.7 KB | 54.7 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY_FINAL/log_messages | 107588918 | 107582966 | -5952 | -0.0% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY_FINAL/log_analysis | 20342 | 20342 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | COUNTS/log_messages_entries | 182419 | 182419 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | COUNTS/log_occurrences_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | COUNTS/log_stats_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| multi-day-custom-logs-top25 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/read_files | 46.9 s | 46.8 s | -113 ms | -0.2% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/group_similar | 3.3 s | 4.6 s | +1.3 s | 39.3% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/calculate_statistics | 294 ms | 300 ms | +6 ms | 2.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/total | 50.5 s | 51.7 s | +1.2 s | 2.4% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/rss_peak | 249.8 MB | 257.0 MB | +7.2 MB | 2.9% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_clusters | 29.5 MB | 29.5 MB | -40 B | -0.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_message | 197.4 KB | 5.8 MB | +5.6 MB | 2903.8% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_patterns | 201.9 KB | 201.9 KB | +22 B | 0.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_unmatched | 248.8 KB | 3.3 MB | +3 MB | 1244.4% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_analysis | 28.4 MB | 28.4 MB | +256 B | 0.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_messages | 28.6 MB | 28.6 MB | -3.9 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_stats | 54.4 KB | 54.7 KB | +256 B | 0.5% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/log_messages | 30013620 | 30009652 | -3968 | -0.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 20086 | 20342 | 256 | 1.3% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 30969856 | 30969816 | -40 | -0.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 206763 | 206785 | 22 | 0.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 232 | 232 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_messages_entries | 606 | 606 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_occurrences_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_stats_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/read_files | 15.7 s | 16.1 s | +401 ms | 2.5% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/calculate_statistics | 310 ms | 301 ms | -9 ms | -2.9% | IMPROVE |
| multi-day-custom-logs-heatmap | TIMING/heatmap_statistics | 402 ms | 15 ms | -387 ms | -96.3% | IMPROVE |
| multi-day-custom-logs-heatmap | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/total | 16.4 s | 16.5 s | +6 ms | 0.0% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/rss_peak | 206.9 MB | 179.6 MB | -27.3 MB | -13.2% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_data | 43.2 KB | 43.5 KB | +272 B | 0.6% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_raw | 28.4 MB | 120 B | -28.4 MB | -100.0% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_analysis | 20.7 KB | 20.9 KB | +256 B | 1.2% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/log_messages | 103.1 MB | 103.1 MB | -2.2 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_stats | 49.6 KB | 49.8 KB | +256 B | 0.5% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/log_messages | 108064422 | 108062118 | -2304 | -0.0% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/log_analysis | 20086 | 20342 | 256 | 1.3% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | COUNTS/log_messages_entries | 182419 | 182419 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | COUNTS/log_occurrences_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | COUNTS/log_stats_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| multi-day-custom-logs-heatmap | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/read_files | 16.1 s | 16.3 s | +252 ms | 1.6% | REGRESS |
| multi-day-custom-logs-histogram | TIMING/calculate_statistics | 394 ms | 384 ms | -10 ms | -2.5% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/histogram_statistics | 530 ms | 3 ms | -527 ms | -99.4% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/total | 17.0 s | 16.7 s | -285 ms | -1.7% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/rss_peak | 243.0 MB | 199.2 MB | -43.8 MB | -18.0% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
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
| multi-day-custom-logs-histogram | COUNTS/log_messages_entries | 182419 | 182419 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | COUNTS/log_occurrences_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | COUNTS/log_stats_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| multi-day-custom-logs-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/read_files | 16.1 s | 16.8 s | +728 ms | 4.5% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | TIMING/calculate_statistics | 314 ms | 304 ms | -10 ms | -3.2% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/heatmap_statistics | 407 ms | 15 ms | -392 ms | -96.3% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/histogram_statistics | 528 ms | 3 ms | -525 ms | -99.4% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/total | 17.3 s | 17.1 s | -198 ms | -1.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/rss_peak | 249.7 MB | 177.2 MB | -72.5 MB | -29.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_data | 43.0 KB | 42.9 KB | -112 B | -0.3% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_raw | 28.4 MB | 120 B | -28.4 MB | -100.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_values | 29.8 MB | 576 B | -29.8 MB | -100.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_analysis | 20.9 KB | 20.9 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_messages | 103.1 MB | 103.1 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_stats | 49.8 KB | 49.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 108064422 | 108064422 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 20342 | 20342 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | COUNTS/log_messages_entries | 182419 | 182419 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | COUNTS/log_occurrences_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | COUNTS/log_stats_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/read_files | 46.4 s | 48.0 s | +1.5 s | 3.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/group_similar | 3.2 s | 4.3 s | +1.1 s | 35.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | 161 ms | 138 ms | -23 ms | -14.3% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/heatmap_statistics | 483 ms | 19 ms | -464 ms | -96.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/histogram_statistics | 676 ms | 4 ms | -672 ms | -99.4% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/total | 50.9 s | 52.4 s | +1.5 s | 2.9% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 289.4 MB | 232.4 MB | -57 MB | -19.7% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 29.5 MB | 29.5 MB | +84 B | 0.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 197.4 KB | 5.8 MB | +5.6 MB | 2903.8% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 201.9 KB | 202.2 KB | +340 B | 0.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 248.8 KB | 3.3 MB | +3 MB | 1244.4% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 43.6 KB | 42.3 KB | -1.4 KB | -3.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 28.4 MB | 120 B | -28.4 MB | -100.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 29.8 MB | 576 B | -29.8 MB | -100.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 20.9 KB | 20.9 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 28.6 MB | 28.6 MB | -2.8 KB | -0.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 20.3 KB | 20.3 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 49.8 KB | 49.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 30004692 | 30001812 | -2880 | -0.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 20342 | 20342 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 30969856 | 30969940 | 84 | 0.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 206763 | 207103 | 340 | 0.2% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | 131128 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 232 | 232 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 606 | 606 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 25 | 25 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-standard | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | TIMING/read_files | 9.1 s | 9.3 s | +144 ms | 1.6% | REGRESS |
| single-day-access-log-standard | TIMING/calculate_statistics | 201 ms | 198 ms | -3 ms | -1.5% | IMPROVE |
| single-day-access-log-standard | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-standard | TIMING/total | 9.3 s | 9.5 s | +141 ms | 1.5% | REGRESS |
| single-day-access-log-standard | MEMORY/rss_peak | 153.7 MB | 156.4 MB | +2.7 MB | 1.7% | REGRESS |
| single-day-access-log-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
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
| single-day-access-log-standard | COUNTS/log_messages_entries | 3184 | 3184 | 0 | 0.0% |  |
| single-day-access-log-standard | COUNTS/log_occurrences_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-standard | COUNTS/log_stats_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-standard | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-standard | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| single-day-access-log-standard | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-standard | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-standard | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-top25 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | TIMING/read_files | 9.1 s | 9.2 s | +179 ms | 2.0% | REGRESS |
| single-day-access-log-top25 | TIMING/calculate_statistics | 224 ms | 221 ms | -3 ms | -1.3% | IMPROVE |
| single-day-access-log-top25 | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25 | TIMING/total | 9.3 s | 9.5 s | +178 ms | 1.9% | REGRESS |
| single-day-access-log-top25 | MEMORY/rss_peak | 155.1 MB | 156.2 MB | +1.2 MB | 0.8% | REGRESS |
| single-day-access-log-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_analysis | 52.7 MB | 52.7 MB | +128 B | 0.0% | REGRESS |
| single-day-access-log-top25 | MEMORY/log_messages | 55.5 MB | 55.5 MB | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_occurrences | 18.3 KB | 18.4 KB | +128 B | 0.7% | REGRESS |
| single-day-access-log-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_stats | 31.4 KB | 31.6 KB | +128 B | 0.4% | REGRESS |
| single-day-access-log-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY_FINAL/log_messages | 58205010 | 58205010 | 0 | 0.0% |  |
| single-day-access-log-top25 | MEMORY_FINAL/log_analysis | 6542 | 6670 | 128 | 2.0% | REGRESS |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-top25 | COUNTS/log_messages_entries | 3184 | 3184 | 0 | 0.0% |  |
| single-day-access-log-top25 | COUNTS/log_occurrences_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-top25 | COUNTS/log_stats_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-top25 | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-top25 | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| single-day-access-log-top25 | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-top25 | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-top25 | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/read_files | 10.4 s | 10.7 s | +305 ms | 2.9% | REGRESS |
| single-day-access-log-top25-consolidate | TIMING/group_similar | 729 ms | 3.9 s | +3.2 s | 432.6% | REGRESS |
| single-day-access-log-top25-consolidate | TIMING/calculate_statistics | 341 ms | 355 ms | +14 ms | 4.1% | REGRESS |
| single-day-access-log-top25-consolidate | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/total | 11.5 s | 14.9 s | +3.5 s | 30.3% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/rss_peak | 191.3 MB | 193.4 MB | +2.1 MB | 1.1% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_clusters | 48.5 MB | 48.6 MB | +25.1 KB | 0.1% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_message | 465.1 KB | 883 KB | +417.9 KB | 89.9% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_patterns | 121 KB | 122.5 KB | +1.5 KB | 1.3% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_unmatched | 317.6 KB | 565.1 KB | +247.6 KB | 78.0% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_analysis | 52.7 MB | 52.7 MB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_messages | 53.5 MB | 55.5 MB | +2 MB | 3.8% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_stats | 31.6 KB | 31.6 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/log_messages | 56062775 | 56094345 | 31570 | 0.1% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/log_analysis | 6670 | 6670 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 50888153 | 50913902 | 25749 | 0.1% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 123909 | 125489 | 1580 | 1.3% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 296 | 296 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/log_messages_entries | 598 | 603 | 5 | 0.8% | REGRESS |
| single-day-access-log-top25-consolidate | COUNTS/log_occurrences_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | COUNTS/log_stats_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| single-day-access-log-top25-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | TIMING/read_files | 9.3 s | 10 s | +779 ms | 8.4% | REGRESS |
| single-day-access-log-heatmap | TIMING/calculate_statistics | 58 ms | 55 ms | -3 ms | -5.2% | IMPROVE |
| single-day-access-log-heatmap | TIMING/heatmap_statistics | 561 ms | 8 ms | -553 ms | -98.6% | IMPROVE |
| single-day-access-log-heatmap | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap | TIMING/total | 9.9 s | 10.1 s | +222 ms | 2.2% | REGRESS |
| single-day-access-log-heatmap | MEMORY/rss_peak | 159.8 MB | 120.1 MB | -39.7 MB | -24.9% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_data | 34 KB | 34 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_raw | 39.9 MB | 120 B | -39.9 MB | -100.0% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_analysis | 8.1 KB | 8.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_messages | 55.5 MB | 55.5 MB | +6.9 KB | 0.0% | REGRESS |
| single-day-access-log-heatmap | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_stats | 28.5 KB | 28.5 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY_FINAL/log_messages | 58184154 | 58191194 | 7040 | 0.0% | REGRESS |
| single-day-access-log-heatmap | MEMORY_FINAL/log_analysis | 6670 | 6670 | 0 | 0.0% |  |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap | COUNTS/log_messages_entries | 3184 | 3184 | 0 | 0.0% |  |
| single-day-access-log-heatmap | COUNTS/log_occurrences_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap | COUNTS/log_stats_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-heatmap | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| single-day-access-log-heatmap | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-heatmap | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-heatmap | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | TIMING/read_files | 9.6 s | 11.1 s | +1.5 s | 15.6% | REGRESS |
| single-day-access-log-histogram | TIMING/calculate_statistics | 228 ms | 196 ms | -32 ms | -14.0% | IMPROVE |
| single-day-access-log-histogram | TIMING/histogram_statistics | 1.5 s | 3 ms | -1.5 s | -99.8% | IMPROVE |
| single-day-access-log-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/total | 11.4 s | 11.3 s | -67 ms | -0.6% | IMPROVE |
| single-day-access-log-histogram | MEMORY/rss_peak | 286.3 MB | 154.6 MB | -131.6 MB | -46.0% | IMPROVE |
| single-day-access-log-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
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
| single-day-access-log-histogram | COUNTS/log_messages_entries | 3184 | 3184 | 0 | 0.0% |  |
| single-day-access-log-histogram | COUNTS/log_occurrences_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-histogram | COUNTS/log_stats_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-histogram | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| single-day-access-log-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-histogram | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-histogram | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/read_files | 9.8 s | 11.8 s | +1.9 s | 19.5% | REGRESS |
| single-day-access-log-heatmap-histogram | TIMING/calculate_statistics | 64 ms | 55 ms | -9 ms | -14.1% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/heatmap_statistics | 583 ms | 8 ms | -575 ms | -98.6% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/histogram_statistics | 1.5 s | 3 ms | -1.5 s | -99.8% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/total | 12 s | 11.8 s | -186 ms | -1.5% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/rss_peak | 292.5 MB | 120.8 MB | -171.8 MB | -58.7% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_data | 34 KB | 34 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_raw | 39.9 MB | 120 B | -39.9 MB | -100.0% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_values | 90.1 MB | 576 B | -90.1 MB | -100.0% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/log_analysis | 8.1 KB | 8.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_messages | 55.5 MB | 55.5 MB | +6.9 KB | 0.0% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_stats | 28.5 KB | 28.5 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/log_messages | 58184154 | 58191194 | 7040 | 0.0% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/log_analysis | 6670 | 6670 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | 120 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | COUNTS/log_messages_entries | 3184 | 3184 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | COUNTS/log_occurrences_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | COUNTS/log_stats_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| single-day-access-log-heatmap-histogram | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/read_files | 11.2 s | 13.2 s | +2 s | 18.0% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/group_similar | 771 ms | 2.8 s | +2 s | 260.3% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/calculate_statistics | 279 ms | 196 ms | -83 ms | -29.7% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/heatmap_statistics | 652 ms | 8 ms | -644 ms | -98.8% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/histogram_statistics | 1.5 s | 3 ms | -1.5 s | -99.8% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/normalize_data | 2 ms | 1 ms | -1 ms | -50.0% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/total | 14.4 s | 16.2 s | +1.8 s | 12.2% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 331.3 MB | 167.1 MB | -164.2 MB | -49.6% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 49.8 MB | 48.5 MB | -1.2 MB | -2.5% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 465.1 KB | 883 KB | +417.9 KB | 89.9% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 121.2 KB | 120.4 KB | -792 B | -0.6% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 317.6 KB | 565.1 KB | +247.6 KB | 78.0% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_data | 34 KB | 34 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 39.9 MB | 120 B | -39.9 MB | -100.0% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_values | 90.1 MB | 576 B | -90.1 MB | -100.0% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_analysis | 8.1 KB | 8.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_messages | 54.7 MB | 55.5 MB | +774.5 KB | 1.4% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_occurrences | 18.4 KB | 18.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_stats | 28.5 KB | 28.5 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 57381194 | 56068831 | -1312363 | -2.3% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 6670 | 6670 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 52193514 | 50888429 | -1305085 | -2.5% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 124101 | 123177 | -924 | -0.7% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 65592 | 65592 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 296 | 296 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 599 | 596 | -3 | -0.5% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 15 | 15 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/terminal_height | 52 | 24 | -28 | -53.8% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | 200 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 60 | 60 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 3600.00 | 3600.00 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | lines_read | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | lines_included | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/read_files | 1.7 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/group_similar | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/calculate_statistics | 5.4 s | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/heatmap_statistics | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/histogram_statistics | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/normalize_data | 2 ms | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | TIMING/total | 1.8 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/rss_peak | 2.7 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/consolidation_clusters | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/consolidation_key_message | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/consolidation_patterns | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/consolidation_unmatched | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/heatmap_data | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/heatmap_raw | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/histogram_values | 576 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/log_analysis | 567.3 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/log_messages | 1.6 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/log_occurrences | 36.6 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/log_sessions | 2.2 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/log_stats | 60.0 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/log_threadpools | 232 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/threadpool_activity | 762 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/log_messages | 1730917915 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/log_analysis | 13010 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_clusters | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_patterns | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_key_message | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/consolidation_unmatched | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | COUNTS/log_messages_entries | 1212275 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | COUNTS/log_occurrences_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | COUNTS/log_stats_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | CONFIG/terminal_height | 52 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | CONFIG/time_bucket_size | 1440 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-standard | CONFIG/bucket_size_seconds | 86400.00 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | lines_read | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | lines_included | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/read_files | 1.7 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/group_similar | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/calculate_statistics | 5.6 s | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/heatmap_statistics | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/histogram_statistics | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/normalize_data | 2 ms | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | TIMING/total | 1.8 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/rss_peak | 2.6 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/consolidation_clusters | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/consolidation_key_message | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/consolidation_patterns | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/consolidation_unmatched | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/heatmap_data | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/heatmap_raw | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/histogram_values | 576 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/log_analysis | 567.3 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/log_messages | 1.5 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/log_occurrences | 36.8 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/log_sessions | 2.2 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/log_stats | 60.0 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/log_threadpools | 232 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/threadpool_activity | 762 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/log_messages | 1655260931 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/log_analysis | 13010 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_clusters | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_patterns | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_key_message | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/consolidation_unmatched | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | COUNTS/log_messages_entries | 1212275 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | COUNTS/log_occurrences_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | COUNTS/log_stats_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | CONFIG/terminal_height | 52 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | CONFIG/time_bucket_size | 1440 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25 | CONFIG/bucket_size_seconds | 86400.00 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | lines_read | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | lines_included | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/read_files | 2.1 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/group_similar | 4.5 s | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/calculate_statistics | 7.8 s | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/heatmap_statistics | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/histogram_statistics | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/normalize_data | 3 ms | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | TIMING/total | 2.4 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | 1.7 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_clusters | 507.7 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_message | 149.4 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_patterns | 257.2 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | 198.5 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_values | 576 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_analysis | 567.4 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_messages | 568.1 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_occurrences | 36.6 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_sessions | 2.2 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_stats | 60.0 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/log_messages | 595725141 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 13010 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 532412788 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 263383 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 424 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_messages_entries | 1306 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_occurrences_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_stats_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/terminal_height | 52 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/time_bucket_size | 1440 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/bucket_size_seconds | 86400.00 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | lines_read | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | lines_included | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/read_files | 1.8 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/group_similar | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/calculate_statistics | 2.1 s | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/heatmap_statistics | 12.9 s | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/histogram_statistics | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/normalize_data | 2 ms | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | TIMING/total | 2 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/rss_peak | 2.7 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_clusters | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_key_message | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_patterns | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_data | 77.9 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_raw | 563.6 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/histogram_values | 576 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/log_analysis | 15.7 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/log_messages | 1.6 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/log_occurrences | 36.8 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/log_sessions | 2.2 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/log_stats | 54.1 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/log_threadpools | 232 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/threadpool_activity | 762 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/log_messages | 1732830635 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/log_analysis | 13010 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_clusters | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_patterns | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_key_message | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/consolidation_unmatched | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | COUNTS/log_messages_entries | 1212275 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | COUNTS/log_occurrences_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | COUNTS/log_stats_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | CONFIG/terminal_height | 52 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | CONFIG/time_bucket_size | 1440 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | CONFIG/bucket_size_seconds | 86400.00 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | lines_read | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | lines_included | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/read_files | 1.8 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/group_similar | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/calculate_statistics | 6 s | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/heatmap_statistics | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/histogram_statistics | 22.9 s | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/normalize_data | 3 ms | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | TIMING/total | 2.3 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/rss_peak | 4 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/consolidation_clusters | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/consolidation_key_message | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/consolidation_patterns | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/consolidation_unmatched | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/heatmap_data | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/heatmap_raw | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/histogram_values | 1.1 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/log_analysis | 567.3 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/log_messages | 1.6 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/log_occurrences | 36.6 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/log_sessions | 2.2 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/log_stats | 60.0 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/log_threadpools | 232 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/threadpool_activity | 762 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/log_messages | 1730917915 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/log_analysis | 13010 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_clusters | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_patterns | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_key_message | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | COUNTS/log_messages_entries | 1212275 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | COUNTS/log_occurrences_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | COUNTS/log_stats_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | CONFIG/terminal_height | 52 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | CONFIG/time_bucket_size | 1440 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-histogram | CONFIG/bucket_size_seconds | 86400.00 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | lines_read | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | lines_included | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/read_files | 1.8 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/group_similar | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/calculate_statistics | 2.3 s | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/heatmap_statistics | 13.3 s | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/histogram_statistics | 22.8 s | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/normalize_data | 3 ms | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | TIMING/total | 2.5 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/rss_peak | 4.1 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_data | 78.4 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_raw | 563.6 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_values | 1.1 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_analysis | 15.7 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_messages | 1.6 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_occurrences | 36.6 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_sessions | 2.2 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_stats | 54.1 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 1732830635 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 13010 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | COUNTS/log_messages_entries | 1212275 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | COUNTS/log_occurrences_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | COUNTS/log_stats_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | CONFIG/terminal_height | 52 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | CONFIG/time_bucket_size | 1440 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | CONFIG/bucket_size_seconds | 86400.00 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_read | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_included | 7,749,167 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/read_files | 2.3 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/group_similar | 4.5 s | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | 3.1 s | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/heatmap_statistics | 14.2 s | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/histogram_statistics | 23.0 s | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/normalize_data | 3 ms | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | 3 min | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 3.2 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 503.6 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 149.4 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 252.4 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 198.5 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 77.9 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 563.7 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 1.1 GB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 15.7 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 566.2 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 36.6 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 2.2 MB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 54.1 KB | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 593711105 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 13010 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 528061739 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 258445 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 424 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 1307 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 28 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 52 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 1440 | N/A | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 86400.00 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | lines_included | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/read_files | 8.4 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/group_similar | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/calculate_statistics | 31.9 s | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/heatmap_statistics | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/histogram_statistics | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/normalize_data | 3 ms | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | TIMING/total | 9.0 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/rss_peak | 13.2 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/consolidation_clusters | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/consolidation_key_message | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/consolidation_patterns | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/consolidation_unmatched | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/heatmap_data | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/heatmap_raw | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/histogram_values | 576 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/log_analysis | 2.9 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/log_messages | 8.3 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/log_occurrences | 42.1 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/log_sessions | 14.9 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/log_stats | 60.1 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/log_threadpools | 232 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/threadpool_activity | 762 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/log_messages | 8951243238 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/log_analysis | 13010 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_clusters | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_patterns | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_key_message | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/consolidation_unmatched | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | COUNTS/log_messages_entries | 6187253 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | COUNTS/log_occurrences_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | COUNTS/log_stats_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | CONFIG/terminal_height | 52 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | CONFIG/time_bucket_size | 1440 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-standard | CONFIG/bucket_size_seconds | 86400.00 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | lines_included | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/read_files | 8.5 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/group_similar | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/calculate_statistics | 33.6 s | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/heatmap_statistics | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/histogram_statistics | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/normalize_data | 3 ms | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | TIMING/total | 9 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/rss_peak | 13.2 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_clusters | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_key_message | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_patterns | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_unmatched | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_data | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_raw | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/histogram_values | 576 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/log_analysis | 2.9 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/log_messages | 8.3 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/log_occurrences | 43.8 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/log_sessions | 14.9 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/log_stats | 60.1 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/log_threadpools | 232 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/threadpool_activity | 762 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/log_messages | 8941409678 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/log_analysis | 13010 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_clusters | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_patterns | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_key_message | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/consolidation_unmatched | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | COUNTS/log_messages_entries | 6187253 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | COUNTS/log_occurrences_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | COUNTS/log_stats_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | CONFIG/terminal_height | 52 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | CONFIG/time_bucket_size | 1440 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | CONFIG/bucket_size_seconds | 86400.00 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | lines_included | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/read_files | 9.8 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/group_similar | 24.0 s | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/calculate_statistics | 41.2 s | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/heatmap_statistics | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/histogram_statistics | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/normalize_data | 3 ms | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | 10.9 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | 6.8 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_clusters | 2.7 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_message | 144.1 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_patterns | 532.8 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | 276.4 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_values | 576 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_analysis | 2.9 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_messages | 2.9 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_occurrences | 42.1 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_sessions | 14.9 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_stats | 60.1 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/log_messages | 3095534057 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/log_analysis | 13010 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | 2848854331 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | 545553 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | 424 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_messages_entries | 2560 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_occurrences_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_stats_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/terminal_height | 52 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/time_bucket_size | 1440 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/bucket_size_seconds | 86400.00 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | lines_included | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/read_files | 8.6 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/group_similar | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/calculate_statistics | 12.4 s | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/heatmap_statistics | 1.1 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/histogram_statistics | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/normalize_data | 3 ms | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | TIMING/total | 9.9 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/rss_peak | 13.3 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_clusters | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_key_message | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_patterns | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_data | 76.8 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_raw | 2.9 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_values | 576 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/log_analysis | 15.7 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/log_messages | 8.3 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/log_occurrences | 42.1 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/log_sessions | 14.9 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/log_stats | 54.1 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/log_threadpools | 232 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/threadpool_activity | 762 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/log_messages | 8941395470 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/log_analysis | 13010 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_clusters | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_patterns | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_key_message | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/consolidation_unmatched | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | COUNTS/log_messages_entries | 6187253 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | COUNTS/log_occurrences_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | COUNTS/log_stats_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | CONFIG/terminal_height | 52 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | CONFIG/time_bucket_size | 1440 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | CONFIG/bucket_size_seconds | 86400.00 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | lines_included | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/read_files | 8.9 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/group_similar | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/calculate_statistics | 35.0 s | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/heatmap_statistics | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/histogram_statistics | 1.9 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/normalize_data | 3 ms | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | TIMING/total | 11.4 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/rss_peak | 20.5 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_clusters | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_key_message | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_patterns | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_unmatched | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_data | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_raw | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/histogram_values | 5.4 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/log_analysis | 2.9 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/log_messages | 8.3 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/log_occurrences | 42.1 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/log_sessions | 14.9 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/log_stats | 60.1 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/log_threadpools | 232 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/threadpool_activity | 762 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/log_messages | 8949303382 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/log_analysis | 13010 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_clusters | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_patterns | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_key_message | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | COUNTS/log_messages_entries | 6187253 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | COUNTS/log_occurrences_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | COUNTS/log_stats_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | CONFIG/terminal_height | 52 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | CONFIG/time_bucket_size | 1440 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | CONFIG/bucket_size_seconds | 86400.00 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | lines_included | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/read_files | 9 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/group_similar | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/calculate_statistics | 12.9 s | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/heatmap_statistics | 1.1 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/histogram_statistics | 2.0 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/normalize_data | 4 ms | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | TIMING/total | 12.3 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/rss_peak | 19.3 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_data | 76.8 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_raw | 2.9 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_values | 5.4 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_analysis | 15.7 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_messages | 8.3 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_occurrences | 42.1 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_sessions | 14.9 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_stats | 54.1 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/log_messages | 8950522326 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | 13010 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | 120 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/log_messages_entries | 6187253 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/log_occurrences_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | COUNTS/log_stats_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/terminal_height | 52 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/time_bucket_size | 1440 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | CONFIG/bucket_size_seconds | 86400.00 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_included | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/read_files | 10.4 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/group_similar | 26.7 s | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | 18.1 s | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/heatmap_statistics | 1.2 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/histogram_statistics | 1.9 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/normalize_data | 3 ms | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | 14.3 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 15.6 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 2.6 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 144.1 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 518.8 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 276.4 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 76.3 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 2.9 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 5.4 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 15.7 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 2.9 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 42.1 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 14.9 MB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 54.1 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | 3102243618 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | 13010 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | 2834607088 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | 531209 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | 131128 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | 424 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | 2517 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | 28 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | 200 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | 52 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | 200 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | 1440 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | 86400.00 | N/A | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_trigrams | N/A | 71.8 MB | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | N/A | 64.3 MB | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_ngram_index | N/A | 66.7 MB | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_posting_size | N/A | 614.1 KB | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 65592 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 65592 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | N/A | 71.7 MB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | N/A | 64.2 MB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | N/A | 66.7 MB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | N/A | 614.1 KB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 65592 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 65592 | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_trigrams | N/A | 28.4 MB | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | N/A | 15.6 MB | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_ngram_index | N/A | 29.7 MB | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_posting_size | N/A | 860.9 KB | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 32824 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 32824 | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | N/A | 29.3 MB | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | N/A | 16.4 MB | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | N/A | 29.7 MB | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | N/A | 860.9 KB | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 32824 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 32824 | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | N/A | 62.2 MB | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | N/A | 10.4 MB | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_ngram_index | N/A | 60.8 MB | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_posting_size | N/A | 1.6 MB | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 65592 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 8248 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | N/A | 62.2 MB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | N/A | 10.4 MB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | N/A | 60.8 MB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | N/A | 1.6 MB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 65592 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 8248 | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | N/A | 62.6 MB | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | N/A | 4.5 MB | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_ngram_index | N/A | 61.3 MB | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_posting_size | N/A | 478.1 KB | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 65592 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 4152 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_counters | N/A | 983.4 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_counters_hl | N/A | 232 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY/histogram_counters | N/A | 121.9 KB | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_counters | N/A | 983.4 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_counters_hl | N/A | 232 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_counters | N/A | 122.1 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | N/A | 62.6 MB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | N/A | 4.5 MB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | N/A | 61.2 MB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | N/A | 478.1 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters | N/A | 983.4 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | N/A | 232 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters | N/A | 122.1 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 65592 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 4152 | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_trigrams | N/A | 4.1 MB | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_ngram_index | N/A | 4.8 MB | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_posting_size | N/A | 352.5 KB | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 16440 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY/heatmap_counters | N/A | 568.8 KB | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY/heatmap_counters_hl | N/A | 232 B | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY/histogram_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY/heatmap_counters | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY/heatmap_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY/histogram_counters | N/A | 105.6 KB | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_counters | N/A | 569.7 KB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_counters_hl | N/A | 232 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_counters | N/A | 105.6 KB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | N/A | 4.1 MB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | N/A | 4.8 MB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | N/A | 352.5 KB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_counters | N/A | 569.7 KB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_counters_hl | N/A | 232 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_counters | N/A | 105.6 KB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_counters_hl | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 16440 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |

