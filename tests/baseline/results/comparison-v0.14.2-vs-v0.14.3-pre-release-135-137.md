
## Benchmark Comparison

  Baseline:    v0.14.2 (v0.14.2, 49 test cases)
  Current:     v0.14.3 (v0.14.3, 48 test cases)

### Timing Delta

| # | file selection | standard | top25 | top25-cons | heatmap | histogram | hm+hg | hm+hg+cons |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. | humungous-log-uniqueness | +2.7% | +5.4% | +15.4% | +8.1% | +1.7% | +5.6% | +12.1% |
| 2. | single-day-application-log | +2.2% | -0.5% | +484.5% | +10.1% | +2.5% | +4.1% | +502.5% |
| 3. | multi-day-application-logs | +5.2% | +4.8% | +37.0% | +6.6% | +8.4% | +4.3% | +37.2% |
| 4. | multi-day-custom-logs | +10.0% | +6.3% | +17.9% | +6.1% | +10.8% | +7.6% | +13.7% |
| 5. | single-day-access-log | +4.5% | +6.1% | +21.9% | +4.7% | +7.5% | +6.0% | +19.2% |
| 6. | month-single-server-access-logs | +7.3% | +7.8% | +2874.7% | +7.6% | +7.4% | +6.6% | +2206.8% |
| 7. | month-many-servers-access-logs | +8.2% | +8.1% | +4594.1% | +8.6% | +10.4% | -3.9% | - |

### Memory Delta (RSS Peak)

| # | file selection | standard | top25 | top25-cons | heatmap | histogram | hm+hg | hm+hg+cons |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. | humungous-log-uniqueness | +0.2% | +0.5% | +1.8% | -0.6% | +0.8% | -0.2% | +1.1% |
| 2. | single-day-application-log | +0.9% | +0.6% | +0.7% | +0.8% | +1.3% | -0.6% | +0.4% |
| 3. | multi-day-application-logs | -0.4% | -1.4% | +1.7% | -2.4% | -2.6% | -0.5% | +2.2% |
| 4. | multi-day-custom-logs | +2.2% | -0.9% | +2.2% | -0.3% | +0.9% | +2.1% | +0.1% |
| 5. | single-day-access-log | +2.0% | +0.9% | +10.1% | +0.1% | +0.7% | +0.6% | +3.1% |
| 6. | month-single-server-access-logs | +2.4% | +2.1% | +72.0% | +0.1% | +2.1% | +1.7% | +28.6% |
| 7. | month-many-servers-access-logs | +3.0% | +4.3% | +47.4% | -0.1% | -10.7% | -5.6% | - |

### Summary

| test_name | metric | baseline | current | delta | change% | result |
| --- | --- | --- | --- | --- | --- | --- |
| humungous-log-uniqueness-standard | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/total | 2.7 s | 2.8 s | +73 ms | 2.7% | REGRESS |
| humungous-log-uniqueness-standard | MEMORY/rss_peak | 173.2 MB | 173.6 MB | +400 KB | 0.2% | REGRESS |
| humungous-log-uniqueness-top25 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/total | 2.5 s | 2.7 s | +138 ms | 5.4% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY/rss_peak | 174.2 MB | 175.2 MB | +960 KB | 0.5% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/total | 3.2 s | 3.7 s | +499 ms | 15.4% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/rss_peak | 124.8 MB | 127 MB | +2.3 MB | 1.8% | REGRESS |
| humungous-log-uniqueness-heatmap | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/total | 2.5 s | 2.7 s | +200 ms | 8.1% | REGRESS |
| humungous-log-uniqueness-heatmap | MEMORY/rss_peak | 174.3 MB | 173.3 MB | -1 MB | -0.6% | IMPROVE |
| humungous-log-uniqueness-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/total | 2.6 s | 2.6 s | +44 ms | 1.7% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY/rss_peak | 173.2 MB | 174.5 MB | +1.3 MB | 0.8% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/total | 2.5 s | 2.7 s | +141 ms | 5.6% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/rss_peak | 174.2 MB | 173.9 MB | -320 KB | -0.2% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/total | 3.3 s | 3.7 s | +396 ms | 12.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/rss_peak | 124.9 MB | 126.2 MB | +1.3 MB | 1.1% | REGRESS |
| single-day-application-log-standard | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | TIMING/total | 3.6 s | 3.6 s | +78 ms | 2.2% | REGRESS |
| single-day-application-log-standard | MEMORY/rss_peak | 29.9 MB | 30.2 MB | +288 KB | 0.9% | REGRESS |
| single-day-application-log-top25 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | TIMING/total | 3.6 s | 3.6 s | -19 ms | -0.5% | IMPROVE |
| single-day-application-log-top25 | MEMORY/rss_peak | 30.4 MB | 30.6 MB | +192 KB | 0.6% | REGRESS |
| single-day-application-log-top25-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/total | 3.8 s | 22.4 s | +18.6 s | 484.5% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/rss_peak | 61.2 MB | 61.6 MB | +448 KB | 0.7% | REGRESS |
| single-day-application-log-heatmap | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | TIMING/total | 3.5 s | 3.8 s | +350 ms | 10.1% | REGRESS |
| single-day-application-log-heatmap | MEMORY/rss_peak | 30.0 MB | 30.2 MB | +240 KB | 0.8% | REGRESS |
| single-day-application-log-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | TIMING/total | 3.6 s | 3.7 s | +90 ms | 2.5% | REGRESS |
| single-day-application-log-histogram | MEMORY/rss_peak | 30.2 MB | 30.6 MB | +400 KB | 1.3% | REGRESS |
| single-day-application-log-heatmap-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/total | 3.6 s | 3.7 s | +147 ms | 4.1% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/rss_peak | 30.3 MB | 30.1 MB | -192 KB | -0.6% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/total | 3.8 s | 22.8 s | +19.0 s | 502.5% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 61.3 MB | 61.5 MB | +272 KB | 0.4% | REGRESS |
| multi-day-application-logs-standard | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-standard | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-standard | TIMING/total | 7.6 s | 8 s | +399 ms | 5.2% | REGRESS |
| multi-day-application-logs-standard | MEMORY/rss_peak | 64 MB | 63.7 MB | -272 KB | -0.4% | IMPROVE |
| multi-day-application-logs-top25 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/total | 7.6 s | 8.0 s | +368 ms | 4.8% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/rss_peak | 63.6 MB | 62.8 MB | -880 KB | -1.4% | IMPROVE |
| multi-day-application-logs-top25-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/total | 11.4 s | 15.6 s | +4.2 s | 37.0% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | 119.7 MB | 121.8 MB | +2.1 MB | 1.7% | REGRESS |
| multi-day-application-logs-heatmap | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/total | 7.6 s | 8.1 s | +501 ms | 6.6% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY/rss_peak | 63.6 MB | 62.1 MB | -1.5 MB | -2.4% | IMPROVE |
| multi-day-application-logs-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/total | 7.3 s | 7.9 s | +616 ms | 8.4% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/rss_peak | 63.9 MB | 62.2 MB | -1.7 MB | -2.6% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/total | 7.6 s | 7.9 s | +328 ms | 4.3% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/rss_peak | 63.6 MB | 63.3 MB | -336 KB | -0.5% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | 11.3 s | 15.6 s | +4.2 s | 37.2% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 119.7 MB | 122.4 MB | +2.7 MB | 2.2% | REGRESS |
| multi-day-custom-logs-standard | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/total | 15.7 s | 17.3 s | +1.6 s | 10.0% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/rss_peak | 187.1 MB | 191.2 MB | +4.1 MB | 2.2% | REGRESS |
| multi-day-custom-logs-top25 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/total | 16.1 s | 17.2 s | +1 s | 6.3% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/rss_peak | 189.8 MB | 188.2 MB | -1.7 MB | -0.9% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/total | 28.7 s | 33.8 s | +5.1 s | 17.9% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/rss_peak | 185.5 MB | 189.7 MB | +4.2 MB | 2.2% | REGRESS |
| multi-day-custom-logs-heatmap | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/total | 16.7 s | 17.7 s | +1 s | 6.1% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/rss_peak | 196 MB | 195.4 MB | -656 KB | -0.3% | IMPROVE |
| multi-day-custom-logs-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/total | 16.6 s | 18.4 s | +1.8 s | 10.8% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/rss_peak | 228.7 MB | 230.9 MB | +2.2 MB | 0.9% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/total | 17.2 s | 18.5 s | +1.3 s | 7.6% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/rss_peak | 233.1 MB | 238.0 MB | +4.8 MB | 2.1% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/total | 30.8 s | 35 s | +4.2 s | 13.7% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 227.8 MB | 228 MB | +256 KB | 0.1% | REGRESS |
| single-day-access-log-standard | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | TIMING/total | 9.4 s | 9.9 s | +426 ms | 4.5% | REGRESS |
| single-day-access-log-standard | MEMORY/rss_peak | 156.8 MB | 159.9 MB | +3.2 MB | 2.0% | REGRESS |
| single-day-access-log-top25 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | TIMING/total | 9.4 s | 9.9 s | +568 ms | 6.1% | REGRESS |
| single-day-access-log-top25 | MEMORY/rss_peak | 161.8 MB | 163.4 MB | +1.5 MB | 0.9% | REGRESS |
| single-day-access-log-top25-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/total | 11.2 s | 13.6 s | +2.4 s | 21.9% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/rss_peak | 211.7 MB | 233 MB | +21.3 MB | 10.1% | REGRESS |
| single-day-access-log-heatmap | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | TIMING/total | 10 s | 10.5 s | +474 ms | 4.7% | REGRESS |
| single-day-access-log-heatmap | MEMORY/rss_peak | 161.1 MB | 161.2 MB | +144 KB | 0.1% | REGRESS |
| single-day-access-log-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | TIMING/total | 11.2 s | 12.1 s | +846 ms | 7.5% | REGRESS |
| single-day-access-log-histogram | MEMORY/rss_peak | 294.2 MB | 296.3 MB | +2.1 MB | 0.7% | REGRESS |
| single-day-access-log-heatmap-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/total | 12.0 s | 12.7 s | +714 ms | 6.0% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/rss_peak | 291.3 MB | 292.9 MB | +1.6 MB | 0.6% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/total | 13.9 s | 16.6 s | +2.7 s | 19.2% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 327.3 MB | 337.4 MB | +10.1 MB | 3.1% | REGRESS |
| month-single-server-access-logs-standard | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/total | 1.8 min | 1.9 min | +7.9 s | 7.3% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/rss_peak | 2.1 GB | 2.2 GB | +52.3 MB | 2.4% | REGRESS |
| month-single-server-access-logs-top25 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/total | 1.8 min | 1.9 min | +8.3 s | 7.8% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/rss_peak | 2.1 GB | 2.2 GB | +46.0 MB | 2.1% | REGRESS |
| month-single-server-access-logs-top25-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/total | 2.3 min | 67.4 min | +65.1 min | 2874.7% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | 1.7 GB | 3.0 GB | +1.3 GB | 72.0% | REGRESS |
| month-single-server-access-logs-heatmap | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/total | 2.0 min | 2.1 min | +9 s | 7.6% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/rss_peak | 2.2 GB | 2.2 GB | +2.7 MB | 0.1% | REGRESS |
| month-single-server-access-logs-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/total | 2.3 min | 2.4 min | +10 s | 7.4% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/rss_peak | 3.5 GB | 3.6 GB | +75.2 MB | 2.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/total | 2.5 min | 2.6 min | +9.8 s | 6.6% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/rss_peak | 3.5 GB | 3.6 GB | +62.7 MB | 1.7% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | 2.9 min | 68 min | +65.1 min | 2206.8% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 3.4 GB | 4.4 GB | +992 MB | 28.6% | REGRESS |
| month-many-servers-access-logs-standard | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | TIMING/total | 8.8 min | 9.5 min | +43.2 s | 8.2% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY/rss_peak | 9.7 GB | 10 GB | +299.2 MB | 3.0% | REGRESS |
| month-many-servers-access-logs-top25 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | TIMING/total | 8.8 min | 9.6 min | +43.0 s | 8.1% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/rss_peak | 9.8 GB | 10.2 GB | +431.1 MB | 4.3% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | 10.2 min | 477.7 min | +467.5 min | 4594.1% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | 7.9 GB | 11.6 GB | +3.7 GB | 47.4% | REGRESS |
| month-many-servers-access-logs-heatmap | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/total | 9.7 min | 10.5 min | +49.9 s | 8.6% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/rss_peak | 10.6 GB | 10.6 GB | -13.4 MB | -0.1% | IMPROVE |
| month-many-servers-access-logs-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/total | 11.7 min | 13.0 min | +1.2 min | 10.4% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/rss_peak | 13.5 GB | 12 GB | -1.4 GB | -10.7% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/total | 14.4 min | 13.8 min | -33.7 s | -3.9% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/rss_peak | 13.8 GB | 13 GB | -799.5 MB | -5.6% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_included | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | 13.8 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 14.4 GB | N/A | N/A | N/A | ? |

### Detailed

| test_name | metric | baseline | current | delta | change% | result |
| --- | --- | --- | --- | --- | --- | --- |
| humungous-log-uniqueness-standard | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/read_files | 2.4 s | 2.4 s | +10 ms | 0.4% | REGRESS |
| humungous-log-uniqueness-standard | TIMING/calculate_statistics | 267 ms | 330 ms | +63 ms | 23.6% | REGRESS |
| humungous-log-uniqueness-standard | TIMING/normalize_data | 1 ms | 0 us | -1 ms | -100.0% | IMPROVE |
| humungous-log-uniqueness-standard | TIMING/total | 2.7 s | 2.8 s | +73 ms | 2.7% | REGRESS |
| humungous-log-uniqueness-standard | MEMORY/rss_peak | 173.2 MB | 173.6 MB | +400 KB | 0.2% | REGRESS |
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
| humungous-log-uniqueness-standard | MEMORY/log_messages | 105.1 MB | 105.1 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_occurrences | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/read_files | 2.3 s | 2.4 s | +99 ms | 4.3% | REGRESS |
| humungous-log-uniqueness-top25 | TIMING/calculate_statistics | 261 ms | 301 ms | +40 ms | 15.3% | REGRESS |
| humungous-log-uniqueness-top25 | TIMING/normalize_data | 1 ms | 0 us | -1 ms | -100.0% | IMPROVE |
| humungous-log-uniqueness-top25 | TIMING/total | 2.5 s | 2.7 s | +138 ms | 5.4% | REGRESS |
| humungous-log-uniqueness-top25 | MEMORY/rss_peak | 174.2 MB | 175.2 MB | +960 KB | 0.5% | REGRESS |
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
| humungous-log-uniqueness-top25 | MEMORY/log_messages | 105.1 MB | 105.1 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_occurrences | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/read_files | 3.0 s | 3.5 s | +560 ms | 18.9% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | TIMING/group_similar | 278 ms | 217 ms | -61 ms | -21.9% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | TIMING/normalize_data | 1 ms | 0 us | -1 ms | -100.0% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | TIMING/total | 3.2 s | 3.7 s | +499 ms | 15.4% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/rss_peak | 124.8 MB | 127 MB | +2.3 MB | 1.8% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_clusters | 87.7 KB | 97.9 KB | +10.2 KB | 11.6% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_message | 114.4 KB | 86.6 KB | -27.8 KB | -24.3% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_patterns | 16.9 KB | 18.8 KB | +1.9 KB | 11.4% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_unmatched | 97.9 KB | 72.1 KB | -25.8 KB | -26.4% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_messages | 121.2 KB | 121.1 KB | -112 B | -0.1% | IMPROVE |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_occurrences | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/read_files | 2.2 s | 2.4 s | +181 ms | 8.2% | REGRESS |
| humungous-log-uniqueness-heatmap | TIMING/calculate_statistics | 264 ms | 283 ms | +19 ms | 7.2% | REGRESS |
| humungous-log-uniqueness-heatmap | TIMING/normalize_data | 1 ms | 0 us | -1 ms | -100.0% | IMPROVE |
| humungous-log-uniqueness-heatmap | TIMING/total | 2.5 s | 2.7 s | +200 ms | 8.1% | REGRESS |
| humungous-log-uniqueness-heatmap | MEMORY/rss_peak | 174.3 MB | 173.3 MB | -1 MB | -0.6% | IMPROVE |
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
| humungous-log-uniqueness-heatmap | MEMORY/log_messages | 105.1 MB | 105.1 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_occurrences | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/read_files | 2.3 s | 2.3 s | +14 ms | 0.6% | REGRESS |
| humungous-log-uniqueness-histogram | TIMING/calculate_statistics | 258 ms | 288 ms | +30 ms | 11.6% | REGRESS |
| humungous-log-uniqueness-histogram | TIMING/normalize_data | 1 ms | 0 us | -1 ms | -100.0% | IMPROVE |
| humungous-log-uniqueness-histogram | TIMING/total | 2.6 s | 2.6 s | +44 ms | 1.7% | REGRESS |
| humungous-log-uniqueness-histogram | MEMORY/rss_peak | 173.2 MB | 174.5 MB | +1.3 MB | 0.8% | REGRESS |
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
| humungous-log-uniqueness-histogram | MEMORY/log_messages | 105.1 MB | 105.1 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_occurrences | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/read_files | 2.3 s | 2.4 s | +127 ms | 5.6% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | TIMING/calculate_statistics | 268 ms | 282 ms | +14 ms | 5.2% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | TIMING/normalize_data | 1 ms | 0 us | -1 ms | -100.0% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | TIMING/total | 2.5 s | 2.7 s | +141 ms | 5.6% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/rss_peak | 174.2 MB | 173.9 MB | -320 KB | -0.2% | IMPROVE |
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
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_messages | 105.1 MB | 105.1 MB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_occurrences | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/read_files | 3.0 s | 3.5 s | +464 ms | 15.5% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/group_similar | 276 ms | 208 ms | -68 ms | -24.6% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/total | 3.3 s | 3.7 s | +396 ms | 12.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/rss_peak | 124.9 MB | 126.2 MB | +1.3 MB | 1.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 87.7 KB | 97.9 KB | +10.2 KB | 11.6% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 114.4 KB | 86.6 KB | -27.8 KB | -24.3% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 16.9 KB | 18.8 KB | +1.9 KB | 11.4% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 97.9 KB | 72 KB | -25.9 KB | -26.4% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_messages | 121.2 KB | 121.1 KB | -112 B | -0.1% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_occurrences | 2.8 KB | 2.8 KB | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | TIMING/read_files | 3.6 s | 3.6 s | +78 ms | 2.2% | REGRESS |
| single-day-application-log-standard | TIMING/calculate_statistics | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-application-log-standard | TIMING/normalize_data | 1 ms | 0 us | -1 ms | -100.0% | IMPROVE |
| single-day-application-log-standard | TIMING/total | 3.6 s | 3.6 s | +78 ms | 2.2% | REGRESS |
| single-day-application-log-standard | MEMORY/rss_peak | 29.9 MB | 30.2 MB | +288 KB | 0.9% | REGRESS |
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
| single-day-application-log-standard | MEMORY/log_messages | 799.3 KB | 799.3 KB | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_occurrences | 11.5 KB | 11.3 KB | -128 B | -1.1% | IMPROVE |
| single-day-application-log-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | TIMING/read_files | 3.6 s | 3.6 s | -18 ms | -0.5% | IMPROVE |
| single-day-application-log-top25 | TIMING/calculate_statistics | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25 | TIMING/normalize_data | 1 ms | 0 us | -1 ms | -100.0% | IMPROVE |
| single-day-application-log-top25 | TIMING/total | 3.6 s | 3.6 s | -19 ms | -0.5% | IMPROVE |
| single-day-application-log-top25 | MEMORY/rss_peak | 30.4 MB | 30.6 MB | +192 KB | 0.6% | REGRESS |
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
| single-day-application-log-top25 | MEMORY/log_messages | 799.3 KB | 799.3 KB | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_occurrences | 11.5 KB | 11.5 KB | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/read_files | 3.8 s | 12.7 s | +8.9 s | 234.0% | REGRESS |
| single-day-application-log-top25-consolidate | TIMING/group_similar | 18 ms | 9.7 s | +9.6 s | 53566.7% | REGRESS |
| single-day-application-log-top25-consolidate | TIMING/calculate_statistics | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| single-day-application-log-top25-consolidate | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/total | 3.8 s | 22.4 s | +18.6 s | 484.5% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/rss_peak | 61.2 MB | 61.6 MB | +448 KB | 0.7% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_clusters | 83.1 KB | 69.9 KB | -13.2 KB | -15.9% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_message | 57.6 KB | 607.5 KB | +549.9 KB | 954.0% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_patterns | 16.1 KB | 13.5 KB | -2.6 KB | -16.0% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_unmatched | 54.6 KB | 384.5 KB | +329.8 KB | 603.9% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_messages | 61.9 KB | 680.1 KB | +618.2 KB | 998.4% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/log_occurrences | 11.3 KB | 11.5 KB | +128 B | 1.1% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | TIMING/read_files | 3.5 s | 3.8 s | +350 ms | 10.1% | REGRESS |
| single-day-application-log-heatmap | TIMING/calculate_statistics | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap | TIMING/normalize_data | 1 ms | 0 us | -1 ms | -100.0% | IMPROVE |
| single-day-application-log-heatmap | TIMING/total | 3.5 s | 3.8 s | +350 ms | 10.1% | REGRESS |
| single-day-application-log-heatmap | MEMORY/rss_peak | 30.0 MB | 30.2 MB | +240 KB | 0.8% | REGRESS |
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
| single-day-application-log-heatmap | MEMORY/log_messages | 799.3 KB | 799.3 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_occurrences | 11.3 KB | 11.3 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | TIMING/read_files | 3.6 s | 3.7 s | +90 ms | 2.5% | REGRESS |
| single-day-application-log-histogram | TIMING/calculate_statistics | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-application-log-histogram | TIMING/normalize_data | 1 ms | 0 us | -1 ms | -100.0% | IMPROVE |
| single-day-application-log-histogram | TIMING/total | 3.6 s | 3.7 s | +90 ms | 2.5% | REGRESS |
| single-day-application-log-histogram | MEMORY/rss_peak | 30.2 MB | 30.6 MB | +400 KB | 1.3% | REGRESS |
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
| single-day-application-log-histogram | MEMORY/log_messages | 799.3 KB | 799.3 KB | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_occurrences | 11.5 KB | 11.3 KB | -128 B | -1.1% | IMPROVE |
| single-day-application-log-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/read_files | 3.6 s | 3.7 s | +146 ms | 4.1% | REGRESS |
| single-day-application-log-heatmap-histogram | TIMING/calculate_statistics | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/total | 3.6 s | 3.7 s | +147 ms | 4.1% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/rss_peak | 30.3 MB | 30.1 MB | -192 KB | -0.6% | IMPROVE |
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
| single-day-application-log-heatmap-histogram | MEMORY/log_messages | 799.3 KB | 799.3 KB | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_occurrences | 11.3 KB | 11.5 KB | +128 B | 1.1% | REGRESS |
| single-day-application-log-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/read_files | 3.8 s | 12.9 s | +9.2 s | 243.6% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/group_similar | 18 ms | 9.8 s | +9.8 s | 54605.6% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/calculate_statistics | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/histogram_statistics | 0 us | 2 ms | +2 ms | NEW | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/total | 3.8 s | 22.8 s | +19.0 s | 502.5% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 61.3 MB | 61.5 MB | +272 KB | 0.4% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 83.1 KB | 69.9 KB | -13.2 KB | -15.9% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 57.6 KB | 607.5 KB | +549.9 KB | 954.0% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 16.1 KB | 13.5 KB | -2.6 KB | -16.0% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 54.6 KB | 384.5 KB | +329.8 KB | 603.9% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_messages | 61.9 KB | 680.1 KB | +618.2 KB | 998.4% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_occurrences | 11.3 KB | 11.5 KB | +128 B | 1.1% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-standard | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-standard | TIMING/read_files | 7.6 s | 8.0 s | +392 ms | 5.2% | REGRESS |
| multi-day-application-logs-standard | TIMING/calculate_statistics | 32 ms | 38 ms | +6 ms | 18.7% | REGRESS |
| multi-day-application-logs-standard | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-standard | TIMING/total | 7.6 s | 8 s | +399 ms | 5.2% | REGRESS |
| multi-day-application-logs-standard | MEMORY/rss_peak | 64 MB | 63.7 MB | -272 KB | -0.4% | IMPROVE |
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
| multi-day-application-logs-standard | MEMORY/log_messages | 8.8 MB | 8.8 MB | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_occurrences | 56.7 KB | 56.6 KB | -64 B | -0.1% | IMPROVE |
| multi-day-application-logs-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/read_files | 7.6 s | 8.0 s | +363 ms | 4.8% | REGRESS |
| multi-day-application-logs-top25 | TIMING/calculate_statistics | 31 ms | 35 ms | +4 ms | 12.9% | REGRESS |
| multi-day-application-logs-top25 | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/total | 7.6 s | 8.0 s | +368 ms | 4.8% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/rss_peak | 63.6 MB | 62.8 MB | -880 KB | -1.4% | IMPROVE |
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
| multi-day-application-logs-top25 | MEMORY/log_messages | 8.8 MB | 8.8 MB | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_occurrences | 56.6 KB | 56.7 KB | +64 B | 0.1% | REGRESS |
| multi-day-application-logs-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/read_files | 10.9 s | 14.1 s | +3.2 s | 29.2% | REGRESS |
| multi-day-application-logs-top25-consolidate | TIMING/group_similar | 432 ms | 1.4 s | +1 s | 233.3% | REGRESS |
| multi-day-application-logs-top25-consolidate | TIMING/calculate_statistics | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| multi-day-application-logs-top25-consolidate | TIMING/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/total | 11.4 s | 15.6 s | +4.2 s | 37.0% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | 119.7 MB | 121.8 MB | +2.1 MB | 1.7% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_clusters | 1.1 MB | 1.5 MB | +470.4 KB | 43.4% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_message | 525.6 KB | 406.6 KB | -119.0 KB | -22.6% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_patterns | 210.1 KB | 296 KB | +85.9 KB | 40.9% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_unmatched | 428.4 KB | 319.4 KB | -109 KB | -25.5% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_messages | 585.5 KB | 701.4 KB | +115.9 KB | 19.8% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/log_occurrences | 56.7 KB | 56.6 KB | -64 B | -0.1% | IMPROVE |
| multi-day-application-logs-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/read_files | 7.6 s | 8.1 s | +498 ms | 6.6% | REGRESS |
| multi-day-application-logs-heatmap | TIMING/calculate_statistics | 30 ms | 34 ms | +4 ms | 13.3% | REGRESS |
| multi-day-application-logs-heatmap | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/total | 7.6 s | 8.1 s | +501 ms | 6.6% | REGRESS |
| multi-day-application-logs-heatmap | MEMORY/rss_peak | 63.6 MB | 62.1 MB | -1.5 MB | -2.4% | IMPROVE |
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
| multi-day-application-logs-heatmap | MEMORY/log_messages | 8.8 MB | 8.8 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_occurrences | 56.7 KB | 56.6 KB | -64 B | -0.1% | IMPROVE |
| multi-day-application-logs-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/read_files | 7.3 s | 7.9 s | +615 ms | 8.4% | REGRESS |
| multi-day-application-logs-histogram | TIMING/calculate_statistics | 32 ms | 34 ms | +2 ms | 6.3% | REGRESS |
| multi-day-application-logs-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/total | 7.3 s | 7.9 s | +616 ms | 8.4% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/rss_peak | 63.9 MB | 62.2 MB | -1.7 MB | -2.6% | IMPROVE |
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
| multi-day-application-logs-histogram | MEMORY/log_messages | 8.8 MB | 8.8 MB | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_occurrences | 56.6 KB | 56.7 KB | +64 B | 0.1% | REGRESS |
| multi-day-application-logs-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/read_files | 7.6 s | 7.9 s | +324 ms | 4.3% | REGRESS |
| multi-day-application-logs-heatmap-histogram | TIMING/calculate_statistics | 32 ms | 36 ms | +4 ms | 12.5% | REGRESS |
| multi-day-application-logs-heatmap-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/total | 7.6 s | 7.9 s | +328 ms | 4.3% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/rss_peak | 63.6 MB | 63.3 MB | -336 KB | -0.5% | IMPROVE |
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
| multi-day-application-logs-heatmap-histogram | MEMORY/log_messages | 8.8 MB | 8.8 MB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_occurrences | 56.6 KB | 56.6 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/read_files | 10.9 s | 14.2 s | +3.3 s | 30.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/group_similar | 434 ms | 1.4 s | +948 ms | 218.4% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/normalize_data | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | 11.3 s | 15.6 s | +4.2 s | 37.2% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 119.7 MB | 122.4 MB | +2.7 MB | 2.2% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 1.1 MB | 1.5 MB | +470.4 KB | 43.4% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 525.6 KB | 406.6 KB | -119.0 KB | -22.6% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 210.1 KB | 296 KB | +85.9 KB | 40.9% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 428.4 KB | 319.4 KB | -109 KB | -25.5% | IMPROVE |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 585.5 KB | 701.4 KB | +115.9 KB | 19.8% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 56.6 KB | 56.6 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/read_files | 15.4 s | 16.9 s | +1.5 s | 10.0% | REGRESS |
| multi-day-custom-logs-standard | TIMING/calculate_statistics | 353 ms | 391 ms | +38 ms | 10.8% | REGRESS |
| multi-day-custom-logs-standard | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/total | 15.7 s | 17.3 s | +1.6 s | 10.0% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/rss_peak | 187.1 MB | 191.2 MB | +4.1 MB | 2.2% | REGRESS |
| multi-day-custom-logs-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_analysis | 28.2 MB | 28.2 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_messages | 91.9 MB | 91.9 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_occurrences | 10.8 KB | 10.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_stats | 30.1 KB | 30.1 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/read_files | 15.8 s | 16.8 s | +988 ms | 6.3% | REGRESS |
| multi-day-custom-logs-top25 | TIMING/calculate_statistics | 371 ms | 401 ms | +30 ms | 8.1% | REGRESS |
| multi-day-custom-logs-top25 | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/total | 16.1 s | 17.2 s | +1 s | 6.3% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/rss_peak | 189.8 MB | 188.2 MB | -1.7 MB | -0.9% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_analysis | 28.2 MB | 28.2 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_messages | 91.9 MB | 91.9 MB | +5.8 KB | 0.0% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/log_occurrences | 10.8 KB | 10.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_stats | 30.1 KB | 30.1 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/read_files | 25.3 s | 29.3 s | +4.0 s | 15.8% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/group_similar | 3 s | 4.1 s | +1.1 s | 36.2% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/calculate_statistics | 338 ms | 370 ms | +32 ms | 9.5% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/normalize_data | 2 ms | 1 ms | -1 ms | -50.0% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/total | 28.7 s | 33.8 s | +5.1 s | 17.9% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/rss_peak | 185.5 MB | 189.7 MB | +4.2 MB | 2.2% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_clusters | 28.9 MB | 29 MB | +122.6 KB | 0.4% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_message | 1.9 MB | 172.7 KB | -1.7 MB | -90.9% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_patterns | 174 KB | 193.8 KB | +19.8 KB | 11.4% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_unmatched | 1.3 MB | 229.2 KB | -1.1 MB | -82.4% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_analysis | 28.2 MB | 28.2 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_messages | 28.7 MB | 28.7 MB | +10.3 KB | 0.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_occurrences | 10.8 KB | 10.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_stats | 30.1 KB | 30.1 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/read_files | 16 s | 17 s | +1 s | 6.3% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/calculate_statistics | 292 ms | 293 ms | +1 ms | 0.3% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/heatmap_statistics | 411 ms | 418 ms | +7 ms | 1.7% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/total | 16.7 s | 17.7 s | +1 s | 6.1% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/rss_peak | 196 MB | 195.4 MB | -656 KB | -0.3% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_data | 27.4 KB | 26.4 KB | -1 KB | -3.7% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_raw | 28.2 MB | 28.2 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_analysis | 11.5 KB | 11.5 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_messages | 91.9 MB | 92.4 MB | +483.4 KB | 0.5% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/log_occurrences | 10.8 KB | 10.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_stats | 27.4 KB | 27.4 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/read_files | 15.7 s | 17.4 s | +1.7 s | 11.1% | REGRESS |
| multi-day-custom-logs-histogram | TIMING/calculate_statistics | 384 ms | 430 ms | +46 ms | 12.0% | REGRESS |
| multi-day-custom-logs-histogram | TIMING/histogram_statistics | 533 ms | 548 ms | +15 ms | 2.8% | REGRESS |
| multi-day-custom-logs-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/total | 16.6 s | 18.4 s | +1.8 s | 10.8% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/rss_peak | 228.7 MB | 230.9 MB | +2.2 MB | 0.9% | REGRESS |
| multi-day-custom-logs-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/histogram_values | 29.8 MB | 29.8 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_analysis | 28.2 MB | 28.2 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_messages | 91.9 MB | 91.9 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_occurrences | 10.8 KB | 10.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_stats | 30.1 KB | 30.1 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/read_files | 16.0 s | 17.1 s | +1.2 s | 7.4% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | TIMING/calculate_statistics | 264 ms | 299 ms | +35 ms | 13.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | TIMING/heatmap_statistics | 417 ms | 435 ms | +18 ms | 4.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | TIMING/histogram_statistics | 530 ms | 593 ms | +63 ms | 11.9% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/total | 17.2 s | 18.5 s | +1.3 s | 7.6% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/rss_peak | 233.1 MB | 238.0 MB | +4.8 MB | 2.1% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_data | 26.4 KB | 27.5 KB | +1.1 KB | 4.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_raw | 28.2 MB | 28.2 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_values | 29.8 MB | 29.8 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_analysis | 11.5 KB | 11.5 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_messages | 92.4 MB | 91.9 MB | -481.4 KB | -0.5% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_occurrences | 10.8 KB | 10.8 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_stats | 27.4 KB | 27.4 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/read_files | 26.3 s | 29.4 s | +3.1 s | 11.9% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/group_similar | 3.2 s | 4.2 s | +989 ms | 30.8% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | 133 ms | 163 ms | +30 ms | 22.6% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/heatmap_statistics | 526 ms | 565 ms | +39 ms | 7.4% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/histogram_statistics | 649 ms | 687 ms | +38 ms | 5.9% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/normalize_data | 2 ms | 1 ms | -1 ms | -50.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/total | 30.8 s | 35 s | +4.2 s | 13.7% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 227.8 MB | 228 MB | +256 KB | 0.1% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 28.9 MB | 29 MB | +122.7 KB | 0.4% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 1.9 MB | 172.7 KB | -1.7 MB | -90.9% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 173.9 KB | 193.8 KB | +19.9 KB | 11.5% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 1.3 MB | 229.2 KB | -1.1 MB | -82.4% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 27.4 KB | 27.4 KB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 28.2 MB | 28.2 MB | -128 B | -0.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 29.8 MB | 29.8 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 11.5 KB | 11.4 KB | -128 B | -1.1% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 28.7 MB | 28.7 MB | +7.8 KB | 0.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 10.8 KB | 10.7 KB | -128 B | -1.2% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 27.4 KB | 27.3 KB | -128 B | -0.5% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | TIMING/read_files | 9.2 s | 9.6 s | +403 ms | 4.4% | REGRESS |
| single-day-access-log-standard | TIMING/calculate_statistics | 210 ms | 233 ms | +23 ms | 11.0% | REGRESS |
| single-day-access-log-standard | TIMING/normalize_data | 1 ms | 0 us | -1 ms | -100.0% | IMPROVE |
| single-day-access-log-standard | TIMING/total | 9.4 s | 9.9 s | +426 ms | 4.5% | REGRESS |
| single-day-access-log-standard | MEMORY/rss_peak | 156.8 MB | 159.9 MB | +3.2 MB | 2.0% | REGRESS |
| single-day-access-log-standard | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_analysis | 53.2 MB | 53.2 MB | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_messages | 55.3 MB | 55.3 MB | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_occurrences | 10.1 KB | 10.1 KB | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_stats | 17.3 KB | 17.3 KB | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | TIMING/read_files | 9.1 s | 9.7 s | +548 ms | 6.0% | REGRESS |
| single-day-access-log-top25 | TIMING/calculate_statistics | 243 ms | 263 ms | +20 ms | 8.2% | REGRESS |
| single-day-access-log-top25 | TIMING/normalize_data | 1 ms | 0 us | -1 ms | -100.0% | IMPROVE |
| single-day-access-log-top25 | TIMING/total | 9.4 s | 9.9 s | +568 ms | 6.1% | REGRESS |
| single-day-access-log-top25 | MEMORY/rss_peak | 161.8 MB | 163.4 MB | +1.5 MB | 0.9% | REGRESS |
| single-day-access-log-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_analysis | 53.2 MB | 53.2 MB | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_messages | 55.3 MB | 55.5 MB | +190.6 KB | 0.3% | REGRESS |
| single-day-access-log-top25 | MEMORY/log_occurrences | 10.1 KB | 10.1 KB | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_stats | 17.3 KB | 17.3 KB | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/read_files | 10.4 s | 11.3 s | +841 ms | 8.1% | REGRESS |
| single-day-access-log-top25-consolidate | TIMING/group_similar | 399 ms | 1.9 s | +1.5 s | 385.0% | REGRESS |
| single-day-access-log-top25-consolidate | TIMING/calculate_statistics | 358 ms | 431 ms | +73 ms | 20.4% | REGRESS |
| single-day-access-log-top25-consolidate | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/total | 11.2 s | 13.6 s | +2.4 s | 21.9% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/rss_peak | 211.7 MB | 233 MB | +21.3 MB | 10.1% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_clusters | 51.5 MB | 48.7 MB | -2.8 MB | -5.5% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_message | 343.2 KB | 464 KB | +120.8 KB | 35.2% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_patterns | 104.9 KB | 132.2 KB | +27.3 KB | 26.0% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_unmatched | 242.5 KB | 316.9 KB | +74.4 KB | 30.7% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_analysis | 53.2 MB | 53.2 MB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_messages | 53.2 MB | 53.5 MB | +322.8 KB | 0.6% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/log_occurrences | 10.1 KB | 10.1 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_stats | 17.3 KB | 17.3 KB | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | TIMING/read_files | 9.4 s | 9.9 s | +457 ms | 4.9% | REGRESS |
| single-day-access-log-heatmap | TIMING/calculate_statistics | 60 ms | 65 ms | +5 ms | 8.3% | REGRESS |
| single-day-access-log-heatmap | TIMING/heatmap_statistics | 572 ms | 584 ms | +12 ms | 2.1% | REGRESS |
| single-day-access-log-heatmap | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap | TIMING/total | 10 s | 10.5 s | +474 ms | 4.7% | REGRESS |
| single-day-access-log-heatmap | MEMORY/rss_peak | 161.1 MB | 161.2 MB | +144 KB | 0.1% | REGRESS |
| single-day-access-log-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_data | 19.6 KB | 19.6 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/heatmap_raw | 39.8 MB | 39.8 MB | -64 B | -0.0% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_analysis | 4.4 KB | 4.4 KB | -64 B | -1.4% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/log_messages | 55.5 MB | 55.5 MB | +6.9 KB | 0.0% | REGRESS |
| single-day-access-log-heatmap | MEMORY/log_occurrences | 10.1 KB | 10 KB | -64 B | -0.6% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_stats | 15.7 KB | 15.6 KB | -64 B | -0.4% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | TIMING/read_files | 9.5 s | 10.2 s | +765 ms | 8.1% | REGRESS |
| single-day-access-log-histogram | TIMING/calculate_statistics | 244 ms | 273 ms | +29 ms | 11.9% | REGRESS |
| single-day-access-log-histogram | TIMING/histogram_statistics | 1.5 s | 1.6 s | +52 ms | 3.4% | REGRESS |
| single-day-access-log-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/total | 11.2 s | 12.1 s | +846 ms | 7.5% | REGRESS |
| single-day-access-log-histogram | MEMORY/rss_peak | 294.2 MB | 296.3 MB | +2.1 MB | 0.7% | REGRESS |
| single-day-access-log-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/histogram_values | 90.1 MB | 90.1 MB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_analysis | 53.2 MB | 53.2 MB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_messages | 55.5 MB | 55.5 MB | -6.9 KB | -0.0% | IMPROVE |
| single-day-access-log-histogram | MEMORY/log_occurrences | 10.1 KB | 10.1 KB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_stats | 17.3 KB | 17.3 KB | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/read_files | 9.8 s | 10.4 s | +638 ms | 6.5% | REGRESS |
| single-day-access-log-heatmap-histogram | TIMING/calculate_statistics | 64 ms | 71 ms | +7 ms | 10.9% | REGRESS |
| single-day-access-log-heatmap-histogram | TIMING/heatmap_statistics | 599 ms | 620 ms | +21 ms | 3.5% | REGRESS |
| single-day-access-log-heatmap-histogram | TIMING/histogram_statistics | 1.5 s | 1.6 s | +49 ms | 3.2% | REGRESS |
| single-day-access-log-heatmap-histogram | TIMING/normalize_data | 1 ms | 0 us | -1 ms | -100.0% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/total | 12.0 s | 12.7 s | +714 ms | 6.0% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/rss_peak | 291.3 MB | 292.9 MB | +1.6 MB | 0.6% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_data | 19.6 KB | 19.6 KB | +64 B | 0.3% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_raw | 39.8 MB | 39.8 MB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/histogram_values | 90.1 MB | 90.1 MB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_analysis | 4.4 KB | 4.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_messages | 55.3 MB | 55.5 MB | +198.4 KB | 0.4% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/log_occurrences | 10.1 KB | 10.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_stats | 15.7 KB | 15.7 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/read_files | 10.9 s | 11.9 s | +1 s | 9.2% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/group_similar | 414 ms | 2.0 s | +1.5 s | 372.9% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/calculate_statistics | 353 ms | 377 ms | +24 ms | 6.8% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/heatmap_statistics | 665 ms | 731 ms | +66 ms | 9.9% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/histogram_statistics | 1.6 s | 1.6 s | +42 ms | 2.7% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/total | 13.9 s | 16.6 s | +2.7 s | 19.2% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 327.3 MB | 337.4 MB | +10.1 MB | 3.1% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 52.7 MB | 49.9 MB | -2.8 MB | -5.3% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 343.2 KB | 464 KB | +120.8 KB | 35.2% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 104.9 KB | 132.2 KB | +27.3 KB | 26.0% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 242.5 KB | 316.9 KB | +74.4 KB | 30.7% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_data | 19.6 KB | 19.6 KB | +64 B | 0.3% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 39.8 MB | 39.8 MB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_values | 90.1 MB | 90.1 MB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_analysis | 4.4 KB | 4.4 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_messages | 54.5 MB | 54.7 MB | +287.1 KB | 0.5% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_occurrences | 10.1 KB | 10.1 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_stats | 15.7 KB | 15.7 KB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/read_files | 1.7 min | 1.8 min | +7.3 s | 7.2% | REGRESS |
| month-single-server-access-logs-standard | TIMING/calculate_statistics | 4.9 s | 5.5 s | +543 ms | 11.0% | REGRESS |
| month-single-server-access-logs-standard | TIMING/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/total | 1.8 min | 1.9 min | +7.9 s | 7.3% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/rss_peak | 2.1 GB | 2.2 GB | +52.3 MB | 2.4% | REGRESS |
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
| month-single-server-access-logs-standard | MEMORY/log_messages | 1.1 GB | 1.2 GB | +45.6 MB | 3.9% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/log_occurrences | 36.6 KB | 36.8 KB | +192 B | 0.5% | REGRESS |
| month-single-server-access-logs-standard | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_stats | 60.0 KB | 60.0 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/read_files | 1.7 min | 1.8 min | +7.7 s | 7.5% | REGRESS |
| month-single-server-access-logs-top25 | TIMING/calculate_statistics | 5.2 s | 5.8 s | +624 ms | 12.0% | REGRESS |
| month-single-server-access-logs-top25 | TIMING/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/total | 1.8 min | 1.9 min | +8.3 s | 7.8% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/rss_peak | 2.1 GB | 2.2 GB | +46.0 MB | 2.1% | REGRESS |
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
| month-single-server-access-logs-top25 | MEMORY/log_messages | 1.1 GB | 1.2 GB | +45.6 MB | 3.9% | REGRESS |
| month-single-server-access-logs-top25 | MEMORY/log_occurrences | 36.8 KB | 36.8 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_stats | 60.0 KB | 60.0 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/read_files | 2.1 min | 2.8 min | +37.9 s | 29.7% | REGRESS |
| month-single-server-access-logs-top25-consolidate | TIMING/group_similar | 484 ms | 64.5 min | +64.5 min | 799371.3% | REGRESS |
| month-single-server-access-logs-top25-consolidate | TIMING/calculate_statistics | 7.9 s | 6.7 s | -1.2 s | -14.7% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | TIMING/normalize_data | 3 ms | 2 ms | -1 ms | -33.3% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | TIMING/total | 2.3 min | 67.4 min | +65.1 min | 2874.7% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | 1.7 GB | 3.0 GB | +1.3 GB | 72.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_clusters | 544.9 MB | 5.6 MB | -539.3 MB | -99.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_message | 390.5 KB | 236.4 MB | +236 MB | 61892.4% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_patterns | 141.4 KB | 71.6 KB | -69.8 KB | -49.4% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | 306.7 KB | 150.6 MB | +150.3 MB | 50181.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_analysis | 566.7 MB | 567.3 MB | +576 KB | 0.1% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_messages | 569.4 MB | 1.2 GB | +642.2 MB | 112.8% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_occurrences | 36.6 KB | 36.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_sessions | 2.2 MB | 2.2 MB | +128 B | 0.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_stats | 60.0 KB | 60.0 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/read_files | 1.7 min | 1.9 min | +8.1 s | 7.8% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/calculate_statistics | 1.9 s | 2.1 s | +226 ms | 12.0% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/heatmap_statistics | 12.6 s | 13.3 s | +670 ms | 5.3% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/total | 2.0 min | 2.1 min | +9 s | 7.6% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/rss_peak | 2.2 GB | 2.2 GB | +2.7 MB | 0.1% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_data | 78.4 KB | 78.4 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_raw | 563.6 MB | 563.6 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_analysis | 15.7 KB | 15.7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_messages | 1.2 GB | 1.2 GB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_occurrences | 36.6 KB | 36.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_stats | 54.1 KB | 54.1 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/read_files | 1.8 min | 1.9 min | +8.5 s | 7.9% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/calculate_statistics | 5.6 s | 6.1 s | +490 ms | 8.8% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/histogram_statistics | 22.5 s | 23.6 s | +1.1 s | 4.8% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/total | 2.3 min | 2.4 min | +10 s | 7.4% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/rss_peak | 3.5 GB | 3.6 GB | +75.2 MB | 2.1% | REGRESS |
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
| month-single-server-access-logs-histogram | MEMORY/log_messages | 1.1 GB | 1.2 GB | +43.7 MB | 3.7% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/log_occurrences | 36.6 KB | 36.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_stats | 60.0 KB | 60.0 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/read_files | 1.8 min | 2.0 min | +7.8 s | 7.2% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/calculate_statistics | 1.9 s | 2.1 s | +244 ms | 13.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/heatmap_statistics | 13.2 s | 13.8 s | +643 ms | 4.9% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/histogram_statistics | 22.5 s | 23.6 s | +1.1 s | 4.7% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/total | 2.5 min | 2.6 min | +9.8 s | 6.6% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/rss_peak | 3.5 GB | 3.6 GB | +62.7 MB | 1.7% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_data | 77.9 KB | 75.4 KB | -2.5 KB | -3.2% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_raw | 563.6 MB | 563.6 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_values | 1.1 GB | 1.1 GB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_analysis | 15.7 KB | 15.7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_messages | 1.1 GB | 1.2 GB | +43.7 MB | 3.7% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_occurrences | 36.6 KB | 36.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_stats | 54.1 KB | 54.1 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/read_files | 2.2 min | 2.9 min | +39.3 s | 29.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/group_similar | 523 ms | 64.4 min | +64.4 min | 738924.9% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | 4.1 s | 2.5 s | -1.7 s | -40.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/heatmap_statistics | 14.1 s | 14.6 s | +489 ms | 3.5% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/histogram_statistics | 23.3 s | 24.5 s | +1.2 s | 5.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | 2.9 min | 68 min | +65.1 min | 2206.8% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 3.4 GB | 4.4 GB | +992 MB | 28.6% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 547.3 MB | 5.6 MB | -541.7 MB | -99.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 390.5 KB | 236.4 MB | +236 MB | 61892.4% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 141.3 KB | 71.6 KB | -69.7 KB | -49.3% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 306.7 KB | 150.6 MB | +150.3 MB | 50181.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 77.9 KB | 77.9 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 563.1 MB | 563.6 MB | +576 KB | 0.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 1.1 GB | 1.1 GB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 15.7 KB | 15.7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 571.8 MB | 1.2 GB | +639.8 MB | 111.9% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 36.8 KB | 36.8 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 54.1 KB | 54.1 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | TIMING/read_files | 8.4 min | 9.1 min | +41.8 s | 8.3% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/calculate_statistics | 27.6 s | 29 s | +1.4 s | 5.1% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/normalize_data | 3 ms | 2 ms | -1 ms | -33.3% | IMPROVE |
| month-many-servers-access-logs-standard | TIMING/total | 8.8 min | 9.5 min | +43.2 s | 8.2% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY/rss_peak | 9.7 GB | 10 GB | +299.2 MB | 3.0% | REGRESS |
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
| month-many-servers-access-logs-standard | MEMORY/log_messages | 5.8 GB | 6 GB | +227.6 MB | 3.8% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY/log_occurrences | 43.8 KB | 43.8 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -128 B | -0.0% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/log_stats | 60.1 KB | 60.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | TIMING/read_files | 8.4 min | 9.0 min | +35.7 s | 7.1% | REGRESS |
| month-many-servers-access-logs-top25 | TIMING/calculate_statistics | 28.3 s | 35.6 s | +7.3 s | 25.8% | REGRESS |
| month-many-servers-access-logs-top25 | TIMING/normalize_data | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| month-many-servers-access-logs-top25 | TIMING/total | 8.8 min | 9.6 min | +43.0 s | 8.1% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/rss_peak | 9.8 GB | 10.2 GB | +431.1 MB | 4.3% | REGRESS |
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
| month-many-servers-access-logs-top25 | MEMORY/log_messages | 5.8 GB | 6 GB | +218.2 MB | 3.7% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_stats | 60.1 KB | 60.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/read_files | 9.4 min | 10.7 min | +1.3 min | 14.0% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | TIMING/group_similar | 2.2 s | 466.3 min | +466.3 min | 1252351.0% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | TIMING/calculate_statistics | 44.8 s | 37 s | -7.8 s | -17.4% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | 10.2 min | 477.7 min | +467.5 min | 4594.1% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | 7.9 GB | 11.6 GB | +3.7 GB | 47.4% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_clusters | 2.8 GB | 31.0 MB | -2.8 GB | -98.9% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_message | 560.5 KB | 1.1 GB | +1.1 GB | 212821.6% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_patterns | 157.1 KB | 133.8 KB | -23.4 KB | -14.9% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | 607.4 KB | 735.8 MB | +735.2 MB | 123944.7% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_analysis | 2.9 GB | 2.9 GB | -37.9 MB | -1.3% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_messages | 2.9 GB | 6 GB | +3.1 GB | 107.8% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_stats | 60.1 KB | 60.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/read_files | 8.5 min | 9.3 min | +46.2 s | 9.1% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/calculate_statistics | 9.1 s | 10.4 s | +1.3 s | 14.7% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/heatmap_statistics | 1 min | 1.1 min | +2.3 s | 3.7% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/total | 9.7 min | 10.5 min | +49.9 s | 8.6% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/rss_peak | 10.6 GB | 10.6 GB | -13.4 MB | -0.1% | IMPROVE |
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
| month-many-servers-access-logs-heatmap | MEMORY/log_messages | 6 GB | 6 GB | -9.4 MB | -0.2% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/log_occurrences | 43.8 KB | 43.8 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_sessions | 14.9 MB | 14.9 MB | +32 KB | 0.2% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/log_stats | 54.1 KB | 54.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/read_files | 8.8 min | 9.5 min | +37.6 s | 7.1% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/calculate_statistics | 35.7 s | 42.3 s | +6.6 s | 18.3% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/histogram_statistics | 2.3 min | 2.8 min | +29.3 s | 21.2% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/normalize_data | 3 ms | 4 ms | +1 ms | 33.3% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/total | 11.7 min | 13.0 min | +1.2 min | 10.4% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/rss_peak | 13.5 GB | 12 GB | -1.4 GB | -10.7% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/histogram_values | 5.4 GB | 5.4 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_analysis | 2.9 GB | 2.9 GB | +6.4 KB | 0.0% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/log_messages | 6 GB | 6 GB | +3.4 MB | 0.1% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/log_occurrences | 43.8 KB | 42.1 KB | -1.8 KB | -4.0% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/log_sessions | 14.9 MB | 14.9 MB | +32 KB | 0.2% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/log_stats | 60.1 KB | 60.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/read_files | 10.5 min | 9.6 min | -48.7 s | -7.8% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/initialize_buckets | 1 ms | 0 us | -1 ms | -100.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/calculate_statistics | 14.5 s | 14.1 s | -399 ms | -2.8% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/heatmap_statistics | 1.3 min | 1.2 min | -9.6 s | -12.1% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/histogram_statistics | 2.3 min | 2.7 min | +25.1 s | 18.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/normalize_data | 3 ms | 4 ms | +1 ms | 33.3% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/total | 14.4 min | 13.8 min | -33.7 s | -3.9% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/rss_peak | 13.8 GB | 13 GB | -799.5 MB | -5.6% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_data | 76.8 KB | 75.3 KB | -1.5 KB | -2.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_raw | 2.9 GB | 2.9 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_values | 5.4 GB | 5.4 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_analysis | 15.7 KB | 15.7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_messages | 6 GB | 6 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_occurrences | 43.8 KB | 43.8 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -128 B | -0.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_stats | 54.1 KB | 54.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_read | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_included | 38,672,504 | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/read_files | 10.2 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/initialize_buckets | 0 us | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/group_similar | 2.7 s | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | 28.7 s | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/heatmap_statistics | 1.2 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/histogram_statistics | 2.0 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/normalize_data | 3 ms | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | 13.8 min | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 14.4 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 2.8 GB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 560.5 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 157.3 KB | N/A | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 607.4 KB | N/A | N/A | N/A | ? |
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

