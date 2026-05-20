
> **⚠️ Cross-machine baseline caveat.** The two TSVs compared here were captured on
> different machines:
>
> - `v0.14.3-pre-release-135-137.tsv` — all 48 rows, both std-tier and XL-tier, were
>   captured on `/Users/gregeva/...` (the original baseline machine).
> - `v0.14.4.tsv` — all 49 rows are captured on `/Users/geva/...` (the current
>   machine). The 35 std-tier rows were re-captured in `efa5ea1` (PR #210); the 14
>   XL rows were re-captured per issue #213 to remove a previously-preserved
>   cross-machine contamination.
>
> The current machine is substantially slower than the original on the
> consolidation hot path (~25× on `month-single-server` top25-consolidate, observed
> against v0.14.4 source running on both). That hardware gap dominates many of the
> deltas in this report and is **not** a v0.14.3 → v0.14.4 code change.
>
> Trust this report for:
> - Direction of relative change *within* same-machine pairs of rows (e.g. the
>   std-tier comparison reflects only #142's `find_candidates` regression fix in
>   v0.14.4 plus normal variance, modulo whatever cross-machine hardware variance
>   applies symmetrically to both consolidate and non-consolidate rows).
> - The qualitative call-out that consolidation timing improved in v0.14.4
>   relative to the v0.14.3 regression introduced by #137.
>
> Don't trust the absolute timing magnitudes — particularly the large negative
> consolidate-scenario deltas, which reflect a mixture of the real #142 fix and
> the hardware-speed gap between the two baseline machines.
>
> Issue #213 has the full investigation. A clean same-machine v0.14.3 → v0.14.4
> comparison would require re-capturing v0.14.3 on the current machine, which is
> not done here. Tracked separately if it becomes valuable.

## Benchmark Comparison

  Baseline:    v0.14.3-pre-release-135-137 (v0.14.3, 48 test cases)
  Current:     v0.14.4 (v0.14.4, 49 test cases)

### Timing Delta

| # | file selection | standard | top25 | top25-cons | heatmap | histogram | hm+hg | hm+hg+cons |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. | humungous-log-uniqueness | -4.2% | -3.7% | +188.7% | -4.6% | -0.5% | -4.4% | +201.1% |
| 2. | single-day-application-log | -2.9% | -0.3% | -70.5% | -6.5% | -1.4% | -5.1% | -71.3% |
| 3. | multi-day-application-logs | -2.5% | -1.4% | +176.0% | -2.5% | -2.3% | +0.5% | +178.8% |
| 4. | multi-day-custom-logs | -3.7% | -2.4% | +63.8% | -6.2% | -8.6% | -5.0% | +62.7% |
| 5. | single-day-access-log | -4.3% | -3.1% | +15.6% | -4.8% | -3.9% | -3.9% | +25.6% |
| 6. | month-single-server-access-logs | -3.0% | -3.5% | -93.3% | +0.8% | +1.6% | +3.6% | -90.5% |
| 7. | month-many-servers-access-logs | +0.2% | +2.9% | -93.5% | +0.1% | +24.8% | +0.6% | - |

### Memory Delta (RSS Peak)

| # | file selection | standard | top25 | top25-cons | heatmap | histogram | hm+hg | hm+hg+cons |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1. | humungous-log-uniqueness | +16.0% | +14.9% | +94.8% | +16.2% | +15.0% | +15.1% | +95.5% |
| 2. | single-day-application-log | +10.6% | +9.6% | +96.0% | +10.2% | +8.4% | +11.4% | +99.3% |
| 3. | multi-day-application-logs | +76.5% | +80.2% | +88.9% | +78.8% | +78.3% | +75.0% | +81.8% |
| 4. | multi-day-custom-logs | +6.6% | +6.6% | +34.4% | +5.7% | +4.8% | +4.3% | +29.0% |
| 5. | single-day-access-log | -1.3% | -4.2% | -16.8% | -0.5% | -2.7% | -0.3% | -2.5% |
| 6. | month-single-server-access-logs | +22.9% | +23.1% | -43.8% | +23.8% | +16.2% | +16.2% | -25.1% |
| 7. | month-many-servers-access-logs | +22.7% | +8.0% | -37.1% | +21.7% | -0.1% | +11.5% | - |

### Summary

| test_name | metric | baseline | current | delta | change% | result |
| --- | --- | --- | --- | --- | --- | --- |
| humungous-log-uniqueness-standard | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/total | 2.8 s | 2.6 s | -116 ms | -4.2% | IMPROVE |
| humungous-log-uniqueness-standard | MEMORY/rss_peak | 173.6 MB | 201.3 MB | +27.7 MB | 16.0% | REGRESS |
| humungous-log-uniqueness-top25 | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25 | TIMING/total | 2.7 s | 2.6 s | -99 ms | -3.7% | IMPROVE |
| humungous-log-uniqueness-top25 | MEMORY/rss_peak | 175.2 MB | 201.3 MB | +26.2 MB | 14.9% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | TIMING/total | 3.7 s | 10.8 s | +7.1 s | 188.7% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/rss_peak | 127 MB | 247.4 MB | +120.4 MB | 94.8% | REGRESS |
| humungous-log-uniqueness-heatmap | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/total | 2.7 s | 2.5 s | -123 ms | -4.6% | IMPROVE |
| humungous-log-uniqueness-heatmap | MEMORY/rss_peak | 173.3 MB | 201.4 MB | +28.1 MB | 16.2% | REGRESS |
| humungous-log-uniqueness-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-histogram | TIMING/total | 2.6 s | 2.6 s | -13 ms | -0.5% | IMPROVE |
| humungous-log-uniqueness-histogram | MEMORY/rss_peak | 174.5 MB | 200.8 MB | +26.2 MB | 15.0% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram | TIMING/total | 2.7 s | 2.5 s | -118 ms | -4.4% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/rss_peak | 173.9 MB | 200.3 MB | +26.3 MB | 15.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/total | 3.7 s | 11 s | +7.4 s | 201.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/rss_peak | 126.2 MB | 246.9 MB | +120.6 MB | 95.5% | REGRESS |
| single-day-application-log-standard | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | TIMING/total | 3.6 s | 3.5 s | -105 ms | -2.9% | IMPROVE |
| single-day-application-log-standard | MEMORY/rss_peak | 30.2 MB | 33.4 MB | +3.2 MB | 10.6% | REGRESS |
| single-day-application-log-top25 | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25 | TIMING/total | 3.6 s | 3.6 s | -11 ms | -0.3% | IMPROVE |
| single-day-application-log-top25 | MEMORY/rss_peak | 30.6 MB | 33.6 MB | +3.0 MB | 9.6% | REGRESS |
| single-day-application-log-top25-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/total | 22.4 s | 6.6 s | -15.8 s | -70.5% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/rss_peak | 61.6 MB | 120.8 MB | +59.2 MB | 96.0% | REGRESS |
| single-day-application-log-heatmap | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | TIMING/total | 3.8 s | 3.6 s | -248 ms | -6.5% | IMPROVE |
| single-day-application-log-heatmap | MEMORY/rss_peak | 30.2 MB | 33.3 MB | +3.1 MB | 10.2% | REGRESS |
| single-day-application-log-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-histogram | TIMING/total | 3.7 s | 3.6 s | -50 ms | -1.4% | IMPROVE |
| single-day-application-log-histogram | MEMORY/rss_peak | 30.6 MB | 33.2 MB | +2.6 MB | 8.4% | REGRESS |
| single-day-application-log-heatmap-histogram | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/total | 3.7 s | 3.5 s | -190 ms | -5.1% | IMPROVE |
| single-day-application-log-heatmap-histogram | MEMORY/rss_peak | 30.1 MB | 33.5 MB | +3.4 MB | 11.4% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/total | 22.8 s | 6.5 s | -16.2 s | -71.3% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 61.5 MB | 122.7 MB | +61.1 MB | 99.3% | REGRESS |
| multi-day-application-logs-standard | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-standard | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-standard | TIMING/total | 8 s | 7.8 s | -197 ms | -2.5% | IMPROVE |
| multi-day-application-logs-standard | MEMORY/rss_peak | 63.7 MB | 112.5 MB | +48.8 MB | 76.5% | REGRESS |
| multi-day-application-logs-top25 | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/total | 8.0 s | 7.9 s | -111 ms | -1.4% | IMPROVE |
| multi-day-application-logs-top25 | MEMORY/rss_peak | 62.8 MB | 113.1 MB | +50.4 MB | 80.2% | REGRESS |
| multi-day-application-logs-top25-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/total | 15.6 s | 43.0 s | +27.4 s | 176.0% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | 121.8 MB | 230.1 MB | +108.3 MB | 88.9% | REGRESS |
| multi-day-application-logs-heatmap | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/total | 8.1 s | 7.9 s | -199 ms | -2.5% | IMPROVE |
| multi-day-application-logs-heatmap | MEMORY/rss_peak | 62.1 MB | 111.1 MB | +49.0 MB | 78.8% | REGRESS |
| multi-day-application-logs-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/total | 7.9 s | 7.8 s | -181 ms | -2.3% | IMPROVE |
| multi-day-application-logs-histogram | MEMORY/rss_peak | 62.2 MB | 110.9 MB | +48.7 MB | 78.3% | REGRESS |
| multi-day-application-logs-heatmap-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/total | 7.9 s | 8.0 s | +43 ms | 0.5% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/rss_peak | 63.3 MB | 110.7 MB | +47.5 MB | 75.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | 15.6 s | 43.4 s | +27.8 s | 178.8% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 122.4 MB | 222.4 MB | +100.1 MB | 81.8% | REGRESS |
| multi-day-custom-logs-standard | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/total | 17.3 s | 16.7 s | -635 ms | -3.7% | IMPROVE |
| multi-day-custom-logs-standard | MEMORY/rss_peak | 191.2 MB | 203.7 MB | +12.6 MB | 6.6% | REGRESS |
| multi-day-custom-logs-top25 | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/total | 17.2 s | 16.7 s | -412 ms | -2.4% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/rss_peak | 188.2 MB | 200.5 MB | +12.4 MB | 6.6% | REGRESS |
| multi-day-custom-logs-top25-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/total | 33.8 s | 55.3 s | +21.6 s | 63.8% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/rss_peak | 189.7 MB | 255.0 MB | +65.3 MB | 34.4% | REGRESS |
| multi-day-custom-logs-heatmap | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/total | 17.7 s | 16.6 s | -1.1 s | -6.2% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/rss_peak | 195.4 MB | 206.5 MB | +11.1 MB | 5.7% | REGRESS |
| multi-day-custom-logs-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/total | 18.4 s | 16.8 s | -1.6 s | -8.6% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/rss_peak | 230.9 MB | 242.0 MB | +11.1 MB | 4.8% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/total | 18.5 s | 17.6 s | -916 ms | -5.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/rss_peak | 238.0 MB | 248.3 MB | +10.3 MB | 4.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/total | 35 s | 57 s | +22.0 s | 62.7% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 228 MB | 294.1 MB | +66.1 MB | 29.0% | REGRESS |
| single-day-access-log-standard | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | TIMING/total | 9.9 s | 9.4 s | -429 ms | -4.3% | IMPROVE |
| single-day-access-log-standard | MEMORY/rss_peak | 159.9 MB | 157.8 MB | -2.1 MB | -1.3% | IMPROVE |
| single-day-access-log-top25 | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25 | TIMING/total | 9.9 s | 9.6 s | -305 ms | -3.1% | IMPROVE |
| single-day-access-log-top25 | MEMORY/rss_peak | 163.4 MB | 156.5 MB | -6.9 MB | -4.2% | IMPROVE |
| single-day-access-log-top25-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/total | 13.6 s | 15.8 s | +2.1 s | 15.6% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/rss_peak | 233 MB | 194.0 MB | -39.1 MB | -16.8% | IMPROVE |
| single-day-access-log-heatmap | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | TIMING/total | 10.5 s | 10 s | -509 ms | -4.8% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/rss_peak | 161.2 MB | 160.4 MB | -784 KB | -0.5% | IMPROVE |
| single-day-access-log-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | TIMING/total | 12.1 s | 11.6 s | -469 ms | -3.9% | IMPROVE |
| single-day-access-log-histogram | MEMORY/rss_peak | 296.3 MB | 288.3 MB | -8.0 MB | -2.7% | IMPROVE |
| single-day-access-log-heatmap-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/total | 12.7 s | 12.2 s | -490 ms | -3.9% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/rss_peak | 292.9 MB | 292.1 MB | -800 KB | -0.3% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/total | 16.6 s | 20.9 s | +4.2 s | 25.6% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 337.4 MB | 329.0 MB | -8.5 MB | -2.5% | IMPROVE |
| month-single-server-access-logs-standard | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/total | 1.9 min | 1.9 min | -3.5 s | -3.0% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/rss_peak | 2.2 GB | 2.7 GB | +516.3 MB | 22.9% | REGRESS |
| month-single-server-access-logs-top25 | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/total | 1.9 min | 1.9 min | -4.1 s | -3.5% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY/rss_peak | 2.2 GB | 2.7 GB | +517.8 MB | 23.1% | REGRESS |
| month-single-server-access-logs-top25-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/total | 67.4 min | 4.5 min | -62.9 min | -93.3% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | 3.0 GB | 1.7 GB | -1.3 GB | -43.8% | IMPROVE |
| month-single-server-access-logs-heatmap | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/total | 2.1 min | 2.1 min | +992 ms | 0.8% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/rss_peak | 2.2 GB | 2.7 GB | +540.4 MB | 23.8% | REGRESS |
| month-single-server-access-logs-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/total | 2.4 min | 2.5 min | +2.3 s | 1.6% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/rss_peak | 3.6 GB | 4.1 GB | +592.1 MB | 16.2% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | TIMING/total | 2.6 min | 2.7 min | +5.6 s | 3.6% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/rss_peak | 3.6 GB | 4.2 GB | +598 MB | 16.2% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | 68 min | 6.5 min | -61.5 min | -90.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 4.4 GB | 3.3 GB | -1.1 GB | -25.1% | IMPROVE |
| month-many-servers-access-logs-standard | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | TIMING/total | 9.5 min | 9.6 min | +1.1 s | 0.2% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY/rss_peak | 10 GB | 12.3 GB | +2.3 GB | 22.7% | REGRESS |
| month-many-servers-access-logs-top25 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | TIMING/total | 9.6 min | 9.8 min | +16.8 s | 2.9% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/rss_peak | 10.2 GB | 11 GB | +834.9 MB | 8.0% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | 477.7 min | 31.2 min | -446.5 min | -93.5% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | 11.6 GB | 7.3 GB | -4.3 GB | -37.1% | IMPROVE |
| month-many-servers-access-logs-heatmap | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/total | 10.5 min | 10.5 min | +573 ms | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/rss_peak | 10.6 GB | 12.9 GB | +2.3 GB | 21.7% | REGRESS |
| month-many-servers-access-logs-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/total | 13.0 min | 16.2 min | +3.2 min | 24.8% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/rss_peak | 12 GB | 12 GB | -7 MB | -0.1% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/total | 13.8 min | 13.9 min | +4.9 s | 0.6% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/rss_peak | 13 GB | 14.6 GB | +1.5 GB | 11.5% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_read | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | lines_included | N/A | 38,672,504 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | N/A | 43.4 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | N/A | 14.3 GB | N/A | N/A | ? |

### Detailed

| test_name | metric | baseline | current | delta | change% | result |
| --- | --- | --- | --- | --- | --- | --- |
| humungous-log-uniqueness-standard | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-standard | TIMING/read_files | 2.4 s | 2.3 s | -99 ms | -4.1% | IMPROVE |
| humungous-log-uniqueness-standard | TIMING/calculate_statistics | 330 ms | 313 ms | -17 ms | -5.2% | IMPROVE |
| humungous-log-uniqueness-standard | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| humungous-log-uniqueness-standard | TIMING/total | 2.8 s | 2.6 s | -116 ms | -4.2% | IMPROVE |
| humungous-log-uniqueness-standard | MEMORY/rss_peak | 173.6 MB | 201.3 MB | +27.7 MB | 16.0% | REGRESS |
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
| humungous-log-uniqueness-top25 | TIMING/read_files | 2.4 s | 2.3 s | -79 ms | -3.3% | IMPROVE |
| humungous-log-uniqueness-top25 | TIMING/calculate_statistics | 301 ms | 281 ms | -20 ms | -6.6% | IMPROVE |
| humungous-log-uniqueness-top25 | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| humungous-log-uniqueness-top25 | TIMING/total | 2.7 s | 2.6 s | -99 ms | -3.7% | IMPROVE |
| humungous-log-uniqueness-top25 | MEMORY/rss_peak | 175.2 MB | 201.3 MB | +26.2 MB | 14.9% | REGRESS |
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
| humungous-log-uniqueness-top25-consolidate | TIMING/read_files | 3.5 s | 6.5 s | +3.0 s | 84.2% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | TIMING/group_similar | 217 ms | 4.3 s | +4.1 s | 1884.3% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| humungous-log-uniqueness-top25-consolidate | TIMING/total | 3.7 s | 10.8 s | +7.1 s | 188.7% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/rss_peak | 127 MB | 247.4 MB | +120.4 MB | 94.8% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_clusters | 97.9 KB | 196.2 KB | +98.3 KB | 100.4% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_message | 86.6 KB | 3.1 MB | +3.0 MB | 3509.9% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_patterns | 18.8 KB | 24.9 KB | +6.1 KB | 32.6% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_unmatched | 72.1 KB | 1.7 MB | +1.7 MB | 2358.2% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_messages | 121.1 KB | 2.5 MB | +2.4 MB | 2040.0% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_occurrences | 2.8 KB | 4.5 KB | +1.7 KB | 59.3% | REGRESS |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_read | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | lines_included | 288,025 | 288,025 | 0 | 0.0% |  |
| humungous-log-uniqueness-heatmap | TIMING/read_files | 2.4 s | 2.3 s | -117 ms | -4.9% | IMPROVE |
| humungous-log-uniqueness-heatmap | TIMING/calculate_statistics | 283 ms | 276 ms | -7 ms | -2.5% | IMPROVE |
| humungous-log-uniqueness-heatmap | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| humungous-log-uniqueness-heatmap | TIMING/total | 2.7 s | 2.5 s | -123 ms | -4.6% | IMPROVE |
| humungous-log-uniqueness-heatmap | MEMORY/rss_peak | 173.3 MB | 201.4 MB | +28.1 MB | 16.2% | REGRESS |
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
| humungous-log-uniqueness-histogram | TIMING/read_files | 2.3 s | 2.3 s | -30 ms | -1.3% | IMPROVE |
| humungous-log-uniqueness-histogram | TIMING/calculate_statistics | 288 ms | 305 ms | +17 ms | 5.9% | REGRESS |
| humungous-log-uniqueness-histogram | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| humungous-log-uniqueness-histogram | TIMING/total | 2.6 s | 2.6 s | -13 ms | -0.5% | IMPROVE |
| humungous-log-uniqueness-histogram | MEMORY/rss_peak | 174.5 MB | 200.8 MB | +26.2 MB | 15.0% | REGRESS |
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
| humungous-log-uniqueness-heatmap-histogram | TIMING/read_files | 2.4 s | 2.3 s | -124 ms | -5.2% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | TIMING/calculate_statistics | 282 ms | 288 ms | +6 ms | 2.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| humungous-log-uniqueness-heatmap-histogram | TIMING/total | 2.7 s | 2.5 s | -118 ms | -4.4% | IMPROVE |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/rss_peak | 173.9 MB | 200.3 MB | +26.3 MB | 15.1% | REGRESS |
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
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/read_files | 3.5 s | 6.7 s | +3.2 s | 93.7% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/group_similar | 208 ms | 4.3 s | +4.1 s | 1987.0% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | TIMING/total | 3.7 s | 11 s | +7.4 s | 201.1% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/rss_peak | 126.2 MB | 246.9 MB | +120.6 MB | 95.5% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 97.9 KB | 196.2 KB | +98.3 KB | 100.4% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 86.6 KB | 3.1 MB | +3.0 MB | 3509.9% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 18.8 KB | 24.9 KB | +6.1 KB | 32.6% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 72 KB | 1.7 MB | +1.7 MB | 2360.4% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_messages | 121.1 KB | 2.5 MB | +2.4 MB | 2040.4% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_occurrences | 2.8 KB | 4.5 KB | +1.7 KB | 59.3% | REGRESS |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-standard | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-standard | TIMING/read_files | 3.6 s | 3.5 s | -111 ms | -3.1% | IMPROVE |
| single-day-application-log-standard | TIMING/calculate_statistics | 2 ms | 7 ms | +5 ms | 250.0% | REGRESS |
| single-day-application-log-standard | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| single-day-application-log-standard | TIMING/total | 3.6 s | 3.5 s | -105 ms | -2.9% | IMPROVE |
| single-day-application-log-standard | MEMORY/rss_peak | 30.2 MB | 33.4 MB | +3.2 MB | 10.6% | REGRESS |
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
| single-day-application-log-top25 | TIMING/read_files | 3.6 s | 3.6 s | -17 ms | -0.5% | IMPROVE |
| single-day-application-log-top25 | TIMING/calculate_statistics | 2 ms | 7 ms | +5 ms | 250.0% | REGRESS |
| single-day-application-log-top25 | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| single-day-application-log-top25 | TIMING/total | 3.6 s | 3.6 s | -11 ms | -0.3% | IMPROVE |
| single-day-application-log-top25 | MEMORY/rss_peak | 30.6 MB | 33.6 MB | +3.0 MB | 9.6% | REGRESS |
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
| single-day-application-log-top25-consolidate | TIMING/read_files | 12.7 s | 6.3 s | -6.4 s | -50.4% | IMPROVE |
| single-day-application-log-top25-consolidate | TIMING/group_similar | 9.7 s | 288 ms | -9.4 s | -97.0% | IMPROVE |
| single-day-application-log-top25-consolidate | TIMING/calculate_statistics | 1 ms | 0 us | -1 ms | -100.0% | IMPROVE |
| single-day-application-log-top25-consolidate | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-top25-consolidate | TIMING/total | 22.4 s | 6.6 s | -15.8 s | -70.5% | IMPROVE |
| single-day-application-log-top25-consolidate | MEMORY/rss_peak | 61.6 MB | 120.8 MB | +59.2 MB | 96.0% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_clusters | 69.9 KB | 437.5 KB | +367.7 KB | 526.3% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_message | 607.5 KB | 2.6 MB | +2 MB | 342.5% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_patterns | 13.5 KB | 54.4 KB | +40.8 KB | 302.0% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_unmatched | 384.5 KB | 1.5 MB | +1.1 MB | 306.2% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_messages | 680.1 KB | 2.3 MB | +1.6 MB | 244.8% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/log_occurrences | 11.5 KB | 21.8 KB | +10.3 KB | 90.1% | REGRESS |
| single-day-application-log-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap | lines_read | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | lines_included | 479,904 | 479,904 | 0 | 0.0% |  |
| single-day-application-log-heatmap | TIMING/read_files | 3.8 s | 3.5 s | -253 ms | -6.7% | IMPROVE |
| single-day-application-log-heatmap | TIMING/calculate_statistics | 2 ms | 6 ms | +4 ms | 200.0% | REGRESS |
| single-day-application-log-heatmap | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| single-day-application-log-heatmap | TIMING/total | 3.8 s | 3.6 s | -248 ms | -6.5% | IMPROVE |
| single-day-application-log-heatmap | MEMORY/rss_peak | 30.2 MB | 33.3 MB | +3.1 MB | 10.2% | REGRESS |
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
| single-day-application-log-histogram | TIMING/read_files | 3.7 s | 3.6 s | -56 ms | -1.5% | IMPROVE |
| single-day-application-log-histogram | TIMING/calculate_statistics | 2 ms | 6 ms | +4 ms | 200.0% | REGRESS |
| single-day-application-log-histogram | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| single-day-application-log-histogram | TIMING/total | 3.7 s | 3.6 s | -50 ms | -1.4% | IMPROVE |
| single-day-application-log-histogram | MEMORY/rss_peak | 30.6 MB | 33.2 MB | +2.6 MB | 8.4% | REGRESS |
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
| single-day-application-log-heatmap-histogram | TIMING/read_files | 3.7 s | 3.5 s | -194 ms | -5.2% | IMPROVE |
| single-day-application-log-heatmap-histogram | TIMING/calculate_statistics | 2 ms | 6 ms | +4 ms | 200.0% | REGRESS |
| single-day-application-log-heatmap-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram | TIMING/total | 3.7 s | 3.5 s | -190 ms | -5.1% | IMPROVE |
| single-day-application-log-heatmap-histogram | MEMORY/rss_peak | 30.1 MB | 33.5 MB | +3.4 MB | 11.4% | REGRESS |
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
| single-day-application-log-heatmap-histogram-consolidate | TIMING/read_files | 12.9 s | 6.3 s | -6.7 s | -51.6% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/group_similar | 9.8 s | 279 ms | -9.6 s | -97.2% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/calculate_statistics | 1 ms | 0 us | -1 ms | -100.0% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/histogram_statistics | 2 ms | 0 us | -2 ms | -100.0% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | TIMING/total | 22.8 s | 6.5 s | -16.2 s | -71.3% | IMPROVE |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 61.5 MB | 122.7 MB | +61.1 MB | 99.3% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 69.9 KB | 437.5 KB | +367.6 KB | 526.2% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 607.5 KB | 2.6 MB | +2 MB | 342.5% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 13.5 KB | 54.3 KB | +40.8 KB | 301.4% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 384.5 KB | 1.5 MB | +1.1 MB | 306.2% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_messages | 680.1 KB | 2.3 MB | +1.6 MB | 244.8% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_occurrences | 11.5 KB | 21.8 KB | +10.3 KB | 90.1% | REGRESS |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-standard | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-standard | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-standard | TIMING/read_files | 8.0 s | 7.6 s | -345 ms | -4.3% | IMPROVE |
| multi-day-application-logs-standard | TIMING/calculate_statistics | 38 ms | 185 ms | +147 ms | 386.8% | REGRESS |
| multi-day-application-logs-standard | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-standard | TIMING/total | 8 s | 7.8 s | -197 ms | -2.5% | IMPROVE |
| multi-day-application-logs-standard | MEMORY/rss_peak | 63.7 MB | 112.5 MB | +48.8 MB | 76.5% | REGRESS |
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
| multi-day-application-logs-top25 | TIMING/read_files | 8.0 s | 7.7 s | -278 ms | -3.5% | IMPROVE |
| multi-day-application-logs-top25 | TIMING/calculate_statistics | 35 ms | 203 ms | +168 ms | 480.0% | REGRESS |
| multi-day-application-logs-top25 | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25 | TIMING/total | 8.0 s | 7.9 s | -111 ms | -1.4% | IMPROVE |
| multi-day-application-logs-top25 | MEMORY/rss_peak | 62.8 MB | 113.1 MB | +50.4 MB | 80.2% | REGRESS |
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
| multi-day-application-logs-top25 | MEMORY/log_occurrences | 56.7 KB | 56.6 KB | -64 B | -0.1% | IMPROVE |
| multi-day-application-logs-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/read_files | 14.1 s | 38 s | +23.9 s | 169.2% | REGRESS |
| multi-day-application-logs-top25-consolidate | TIMING/group_similar | 1.4 s | 4.9 s | +3.5 s | 242.7% | REGRESS |
| multi-day-application-logs-top25-consolidate | TIMING/calculate_statistics | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| multi-day-application-logs-top25-consolidate | TIMING/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-top25-consolidate | TIMING/total | 15.6 s | 43.0 s | +27.4 s | 176.0% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/rss_peak | 121.8 MB | 230.1 MB | +108.3 MB | 88.9% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_clusters | 1.5 MB | 3.6 MB | +2 MB | 134.7% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_message | 406.6 KB | 3.5 MB | +3.1 MB | 792.9% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_patterns | 296 KB | 485.9 KB | +189.9 KB | 64.2% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_unmatched | 319.4 KB | 2.1 MB | +1.8 MB | 585.4% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_messages | 701.4 KB | 3.2 MB | +2.5 MB | 364.4% | REGRESS |
| multi-day-application-logs-top25-consolidate | MEMORY/log_occurrences | 56.6 KB | 56.6 KB | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap | TIMING/read_files | 8.1 s | 7.7 s | -349 ms | -4.3% | IMPROVE |
| multi-day-application-logs-heatmap | TIMING/calculate_statistics | 34 ms | 183 ms | +149 ms | 438.2% | REGRESS |
| multi-day-application-logs-heatmap | TIMING/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| multi-day-application-logs-heatmap | TIMING/total | 8.1 s | 7.9 s | -199 ms | -2.5% | IMPROVE |
| multi-day-application-logs-heatmap | MEMORY/rss_peak | 62.1 MB | 111.1 MB | +49.0 MB | 78.8% | REGRESS |
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
| multi-day-application-logs-heatmap | MEMORY/log_occurrences | 56.6 KB | 56.6 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/read_files | 7.9 s | 7.6 s | -338 ms | -4.3% | IMPROVE |
| multi-day-application-logs-histogram | TIMING/calculate_statistics | 34 ms | 191 ms | +157 ms | 461.8% | REGRESS |
| multi-day-application-logs-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-histogram | TIMING/total | 7.9 s | 7.8 s | -181 ms | -2.3% | IMPROVE |
| multi-day-application-logs-histogram | MEMORY/rss_peak | 62.2 MB | 110.9 MB | +48.7 MB | 78.3% | REGRESS |
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
| multi-day-application-logs-histogram | MEMORY/log_occurrences | 56.7 KB | 56.7 KB | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/read_files | 7.9 s | 7.8 s | -109 ms | -1.4% | IMPROVE |
| multi-day-application-logs-heatmap-histogram | TIMING/calculate_statistics | 36 ms | 188 ms | +152 ms | 422.2% | REGRESS |
| multi-day-application-logs-heatmap-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | TIMING/total | 7.9 s | 8.0 s | +43 ms | 0.5% | REGRESS |
| multi-day-application-logs-heatmap-histogram | MEMORY/rss_peak | 63.3 MB | 110.7 MB | +47.5 MB | 75.0% | REGRESS |
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
| multi-day-application-logs-heatmap-histogram | MEMORY/log_occurrences | 56.6 KB | 56.6 KB | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_read | 930,031 | 930,031 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | lines_included | 930,028 | 930,028 | 0 | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/read_files | 14.2 s | 38.4 s | +24.3 s | 171.2% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/group_similar | 1.4 s | 4.9 s | +3.6 s | 256.9% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/normalize_data | 3 ms | 3 ms | 0 ms | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | TIMING/total | 15.6 s | 43.4 s | +27.8 s | 178.8% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 122.4 MB | 222.4 MB | +100.1 MB | 81.8% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 1.5 MB | 3.6 MB | +2 MB | 134.7% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 406.6 KB | 3.5 MB | +3.1 MB | 792.9% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 296 KB | 485.8 KB | +189.8 KB | 64.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 319.4 KB | 2.1 MB | +1.8 MB | 585.4% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 701.4 KB | 3.2 MB | +2.5 MB | 364.4% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 56.6 KB | 56.7 KB | +64 B | 0.1% | REGRESS |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-standard | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/read_files | 16.9 s | 16.2 s | -679 ms | -4.0% | IMPROVE |
| multi-day-custom-logs-standard | TIMING/calculate_statistics | 391 ms | 436 ms | +45 ms | 11.5% | REGRESS |
| multi-day-custom-logs-standard | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-standard | TIMING/total | 17.3 s | 16.7 s | -635 ms | -3.7% | IMPROVE |
| multi-day-custom-logs-standard | MEMORY/rss_peak | 191.2 MB | 203.7 MB | +12.6 MB | 6.6% | REGRESS |
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
| multi-day-custom-logs-top25 | TIMING/read_files | 16.8 s | 16.3 s | -434 ms | -2.6% | IMPROVE |
| multi-day-custom-logs-top25 | TIMING/calculate_statistics | 401 ms | 423 ms | +22 ms | 5.5% | REGRESS |
| multi-day-custom-logs-top25 | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-top25 | TIMING/total | 17.2 s | 16.7 s | -412 ms | -2.4% | IMPROVE |
| multi-day-custom-logs-top25 | MEMORY/rss_peak | 188.2 MB | 200.5 MB | +12.4 MB | 6.6% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_analysis | 28.2 MB | 28.4 MB | +239.8 KB | 0.8% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/log_messages | 91.9 MB | 103.1 MB | +11.1 MB | 12.1% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/log_occurrences | 10.8 KB | 20 KB | +9.2 KB | 85.6% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/log_stats | 30.1 KB | 54.4 KB | +24.4 KB | 81.1% | REGRESS |
| multi-day-custom-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | TIMING/read_files | 29.3 s | 49.8 s | +20.5 s | 70.1% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/group_similar | 4.1 s | 5.2 s | +1.1 s | 26.3% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/calculate_statistics | 370 ms | 329 ms | -41 ms | -11.1% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | TIMING/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| multi-day-custom-logs-top25-consolidate | TIMING/total | 33.8 s | 55.3 s | +21.6 s | 63.8% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/rss_peak | 189.7 MB | 255.0 MB | +65.3 MB | 34.4% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_clusters | 29 MB | 29.5 MB | +543.9 KB | 1.8% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_message | 172.7 KB | 5.8 MB | +5.6 MB | 3332.6% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_patterns | 193.8 KB | 201.9 KB | +8.1 KB | 4.2% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_unmatched | 229.2 KB | 3.3 MB | +3 MB | 1359.7% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_analysis | 28.2 MB | 28.4 MB | +240.1 KB | 0.8% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_messages | 28.7 MB | 28.6 MB | -52.2 KB | -0.2% | IMPROVE |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_occurrences | 10.8 KB | 20.3 KB | +9.5 KB | 87.9% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_stats | 30.1 KB | 54.7 KB | +24.6 KB | 81.9% | REGRESS |
| multi-day-custom-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/read_files | 17 s | 15.9 s | -1.1 s | -6.7% | IMPROVE |
| multi-day-custom-logs-heatmap | TIMING/calculate_statistics | 293 ms | 330 ms | +37 ms | 12.6% | REGRESS |
| multi-day-custom-logs-heatmap | TIMING/heatmap_statistics | 418 ms | 411 ms | -7 ms | -1.7% | IMPROVE |
| multi-day-custom-logs-heatmap | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap | TIMING/total | 17.7 s | 16.6 s | -1.1 s | -6.2% | IMPROVE |
| multi-day-custom-logs-heatmap | MEMORY/rss_peak | 195.4 MB | 206.5 MB | +11.1 MB | 5.7% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_data | 26.4 KB | 42.7 KB | +16.3 KB | 61.8% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_raw | 28.2 MB | 28.4 MB | +233.2 KB | 0.8% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_analysis | 11.5 KB | 20.9 KB | +9.4 KB | 81.6% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/log_messages | 92.4 MB | 102.6 MB | +10.2 MB | 11.0% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/log_occurrences | 10.8 KB | 20.3 KB | +9.5 KB | 87.9% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/log_stats | 27.4 KB | 49.8 KB | +22.4 KB | 81.6% | REGRESS |
| multi-day-custom-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-histogram | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/read_files | 17.4 s | 15.9 s | -1.6 s | -8.9% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/calculate_statistics | 430 ms | 404 ms | -26 ms | -6.0% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/histogram_statistics | 548 ms | 538 ms | -10 ms | -1.8% | IMPROVE |
| multi-day-custom-logs-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-histogram | TIMING/total | 18.4 s | 16.8 s | -1.6 s | -8.6% | IMPROVE |
| multi-day-custom-logs-histogram | MEMORY/rss_peak | 230.9 MB | 242.0 MB | +11.1 MB | 4.8% | REGRESS |
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
| multi-day-custom-logs-heatmap-histogram | TIMING/read_files | 17.1 s | 16.3 s | -886 ms | -5.2% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/calculate_statistics | 299 ms | 334 ms | +35 ms | 11.7% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | TIMING/heatmap_statistics | 435 ms | 419 ms | -16 ms | -3.7% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/histogram_statistics | 593 ms | 543 ms | -50 ms | -8.4% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | TIMING/total | 18.5 s | 17.6 s | -916 ms | -5.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram | MEMORY/rss_peak | 238.0 MB | 248.3 MB | +10.3 MB | 4.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_data | 27.5 KB | 43.2 KB | +15.7 KB | 57.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_raw | 28.2 MB | 28.4 MB | +233.0 KB | 0.8% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/histogram_values | 29.8 MB | 29.8 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_analysis | 11.5 KB | 20.7 KB | +9.2 KB | 79.4% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_messages | 91.9 MB | 103.1 MB | +11.1 MB | 12.1% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_occurrences | 10.8 KB | 20 KB | +9.2 KB | 85.6% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_stats | 27.4 KB | 49.6 KB | +22.1 KB | 80.6% | REGRESS |
| multi-day-custom-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_read | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | lines_included | 1,530,399 | 1,530,399 | 0 | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/read_files | 29.4 s | 50 s | +20.6 s | 69.9% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/group_similar | 4.2 s | 5.6 s | +1.4 s | 33.5% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | 163 ms | 181 ms | +18 ms | 11.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/heatmap_statistics | 565 ms | 537 ms | -28 ms | -5.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/histogram_statistics | 687 ms | 680 ms | -7 ms | -1.0% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | TIMING/total | 35 s | 57 s | +22.0 s | 62.7% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 228 MB | 294.1 MB | +66.1 MB | 29.0% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 29 MB | 29.5 MB | +543.9 KB | 1.8% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 172.7 KB | 5.8 MB | +5.6 MB | 3332.6% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 193.8 KB | 202 KB | +8.3 KB | 4.3% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 229.2 KB | 3.3 MB | +3 MB | 1359.7% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 27.4 KB | 41.5 KB | +14.1 KB | 51.6% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 28.2 MB | 28.4 MB | +233.1 KB | 0.8% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 29.8 MB | 29.8 MB | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 11.4 KB | 20.7 KB | +9.3 KB | 81.4% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 28.7 MB | 28.6 MB | -46.2 KB | -0.2% | IMPROVE |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 10.7 KB | 20 KB | +9.4 KB | 87.8% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 27.3 KB | 49.6 KB | +22.3 KB | 81.5% | REGRESS |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-standard | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-standard | TIMING/read_files | 9.6 s | 9.2 s | -406 ms | -4.2% | IMPROVE |
| single-day-access-log-standard | TIMING/calculate_statistics | 233 ms | 209 ms | -24 ms | -10.3% | IMPROVE |
| single-day-access-log-standard | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| single-day-access-log-standard | TIMING/total | 9.9 s | 9.4 s | -429 ms | -4.3% | IMPROVE |
| single-day-access-log-standard | MEMORY/rss_peak | 159.9 MB | 157.8 MB | -2.1 MB | -1.3% | IMPROVE |
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
| single-day-access-log-top25 | TIMING/read_files | 9.7 s | 9.4 s | -288 ms | -3.0% | IMPROVE |
| single-day-access-log-top25 | TIMING/calculate_statistics | 263 ms | 245 ms | -18 ms | -6.8% | IMPROVE |
| single-day-access-log-top25 | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| single-day-access-log-top25 | TIMING/total | 9.9 s | 9.6 s | -305 ms | -3.1% | IMPROVE |
| single-day-access-log-top25 | MEMORY/rss_peak | 163.4 MB | 156.5 MB | -6.9 MB | -4.2% | IMPROVE |
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
| single-day-access-log-top25-consolidate | TIMING/read_files | 11.3 s | 11.0 s | -280 ms | -2.5% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/group_similar | 1.9 s | 4.4 s | +2.5 s | 127.2% | REGRESS |
| single-day-access-log-top25-consolidate | TIMING/calculate_statistics | 431 ms | 373 ms | -58 ms | -13.5% | IMPROVE |
| single-day-access-log-top25-consolidate | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-top25-consolidate | TIMING/total | 13.6 s | 15.8 s | +2.1 s | 15.6% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/rss_peak | 233 MB | 194.0 MB | -39.1 MB | -16.8% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_clusters | 48.7 MB | 48.5 MB | -216.4 KB | -0.4% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_message | 464 KB | 883 KB | +419 KB | 90.3% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_patterns | 132.2 KB | 122.0 KB | -10.2 KB | -7.7% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_unmatched | 316.9 KB | 565.1 KB | +248.2 KB | 78.3% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_analysis | 53.2 MB | 52.7 MB | -562.7 KB | -1.0% | IMPROVE |
| single-day-access-log-top25-consolidate | MEMORY/log_messages | 53.5 MB | 55.5 MB | +1.9 MB | 3.6% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/log_occurrences | 10.1 KB | 18.4 KB | +8.3 KB | 82.6% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/log_stats | 17.3 KB | 31.6 KB | +14.3 KB | 82.5% | REGRESS |
| single-day-access-log-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap | TIMING/read_files | 9.9 s | 9.4 s | -491 ms | -5.0% | IMPROVE |
| single-day-access-log-heatmap | TIMING/calculate_statistics | 65 ms | 60 ms | -5 ms | -7.7% | IMPROVE |
| single-day-access-log-heatmap | TIMING/heatmap_statistics | 584 ms | 571 ms | -13 ms | -2.2% | IMPROVE |
| single-day-access-log-heatmap | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap | TIMING/total | 10.5 s | 10 s | -509 ms | -4.8% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/rss_peak | 161.2 MB | 160.4 MB | -784 KB | -0.5% | IMPROVE |
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
| single-day-access-log-heatmap | MEMORY/log_messages | 55.5 MB | 55.3 MB | -198.2 KB | -0.3% | IMPROVE |
| single-day-access-log-heatmap | MEMORY/log_occurrences | 10 KB | 18.4 KB | +8.4 KB | 83.7% | REGRESS |
| single-day-access-log-heatmap | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/log_stats | 15.6 KB | 28.5 KB | +12.9 KB | 82.5% | REGRESS |
| single-day-access-log-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-histogram | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-histogram | TIMING/read_files | 10.2 s | 9.8 s | -425 ms | -4.2% | IMPROVE |
| single-day-access-log-histogram | TIMING/calculate_statistics | 273 ms | 238 ms | -35 ms | -12.8% | IMPROVE |
| single-day-access-log-histogram | TIMING/histogram_statistics | 1.6 s | 1.6 s | -9 ms | -0.6% | IMPROVE |
| single-day-access-log-histogram | TIMING/normalize_data | 1 ms | 1 ms | 0 ms | 0.0% |  |
| single-day-access-log-histogram | TIMING/total | 12.1 s | 11.6 s | -469 ms | -3.9% | IMPROVE |
| single-day-access-log-histogram | MEMORY/rss_peak | 296.3 MB | 288.3 MB | -8.0 MB | -2.7% | IMPROVE |
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
| single-day-access-log-heatmap-histogram | TIMING/read_files | 10.4 s | 10.0 s | -470 ms | -4.5% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/calculate_statistics | 71 ms | 71 ms | 0 ms | 0.0% |  |
| single-day-access-log-heatmap-histogram | TIMING/heatmap_statistics | 620 ms | 605 ms | -15 ms | -2.4% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/histogram_statistics | 1.6 s | 1.6 s | -5 ms | -0.3% | IMPROVE |
| single-day-access-log-heatmap-histogram | TIMING/normalize_data | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| single-day-access-log-heatmap-histogram | TIMING/total | 12.7 s | 12.2 s | -490 ms | -3.9% | IMPROVE |
| single-day-access-log-heatmap-histogram | MEMORY/rss_peak | 292.9 MB | 292.1 MB | -800 KB | -0.3% | IMPROVE |
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
| single-day-access-log-heatmap-histogram | MEMORY/log_messages | 55.5 MB | 55.5 MB | +191 B | 0.0% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/log_occurrences | 10.1 KB | 18.4 KB | +8.3 KB | 82.6% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/log_stats | 15.7 KB | 28.5 KB | +12.8 KB | 81.8% | REGRESS |
| single-day-access-log-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_read | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | lines_included | 761,698 | 761,698 | 0 | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/read_files | 11.9 s | 12.1 s | +136 ms | 1.1% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/group_similar | 2.0 s | 6.2 s | +4.2 s | 215.5% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/calculate_statistics | 377 ms | 319 ms | -58 ms | -15.4% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/heatmap_statistics | 731 ms | 691 ms | -40 ms | -5.5% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/histogram_statistics | 1.6 s | 1.6 s | -15 ms | -0.9% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/normalize_data | 1 ms | 2 ms | +1 ms | 100.0% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | TIMING/total | 16.6 s | 20.9 s | +4.2 s | 25.6% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/rss_peak | 337.4 MB | 329.0 MB | -8.5 MB | -2.5% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 49.9 MB | 49.8 MB | -145 KB | -0.3% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 464 KB | 883 KB | +419 KB | 90.3% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 132.2 KB | 123.4 KB | -8.7 KB | -6.6% | IMPROVE |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 316.9 KB | 565.1 KB | +248.2 KB | 78.3% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_data | 19.6 KB | 34 KB | +14.4 KB | 73.6% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 39.8 MB | 39.9 MB | +97.2 KB | 0.2% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/histogram_values | 90.1 MB | 90.1 MB | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_analysis | 4.4 KB | 8.1 KB | +3.7 KB | 82.4% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_messages | 54.7 MB | 55.5 MB | +763.5 KB | 1.4% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_occurrences | 10.1 KB | 18.4 KB | +8.3 KB | 82.6% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_sessions | 120 B | 120 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_stats | 15.7 KB | 28.5 KB | +12.8 KB | 81.8% | REGRESS |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-standard | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/read_files | 1.8 min | 1.8 min | -3.8 s | -3.5% | IMPROVE |
| month-single-server-access-logs-standard | TIMING/calculate_statistics | 5.5 s | 5.8 s | +347 ms | 6.3% | REGRESS |
| month-single-server-access-logs-standard | TIMING/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-standard | TIMING/total | 1.9 min | 1.9 min | -3.5 s | -3.0% | IMPROVE |
| month-single-server-access-logs-standard | MEMORY/rss_peak | 2.2 GB | 2.7 GB | +516.3 MB | 22.9% | REGRESS |
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
| month-single-server-access-logs-top25 | TIMING/read_files | 1.8 min | 1.7 min | -4.9 s | -4.5% | IMPROVE |
| month-single-server-access-logs-top25 | TIMING/calculate_statistics | 5.8 s | 6.7 s | +858 ms | 14.7% | REGRESS |
| month-single-server-access-logs-top25 | TIMING/normalize_data | 2 ms | 2 ms | 0 ms | 0.0% |  |
| month-single-server-access-logs-top25 | TIMING/total | 1.9 min | 1.9 min | -4.1 s | -3.5% | IMPROVE |
| month-single-server-access-logs-top25 | MEMORY/rss_peak | 2.2 GB | 2.7 GB | +517.8 MB | 23.1% | REGRESS |
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
| month-single-server-access-logs-top25 | MEMORY/log_occurrences | 36.8 KB | 36.8 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_stats | 60.0 KB | 60.0 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | TIMING/read_files | 2.8 min | 2.5 min | -16.8 s | -10.2% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | TIMING/group_similar | 64.5 min | 1.9 min | -62.6 min | -97.1% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | TIMING/calculate_statistics | 6.7 s | 9.3 s | +2.6 s | 38.7% | REGRESS |
| month-single-server-access-logs-top25-consolidate | TIMING/normalize_data | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | TIMING/total | 67.4 min | 4.5 min | -62.9 min | -93.3% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/rss_peak | 3.0 GB | 1.7 GB | -1.3 GB | -43.8% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_clusters | 5.6 MB | 506.6 MB | +501 MB | 8971.7% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_message | 236.4 MB | 2.5 MB | -233.9 MB | -99.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_patterns | 71.6 KB | 289.2 KB | +217.6 KB | 304.1% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | 150.6 MB | 1.6 MB | -149 MB | -99.0% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_analysis | 567.3 MB | 567.4 MB | +121.6 KB | 0.0% | REGRESS |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_messages | 1.2 GB | 565.9 MB | -645.6 MB | -53.3% | IMPROVE |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_occurrences | 36.6 KB | 36.6 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_stats | 60.0 KB | 60.0 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap | TIMING/read_files | 1.9 min | 1.9 min | -621 ms | -0.6% | IMPROVE |
| month-single-server-access-logs-heatmap | TIMING/calculate_statistics | 2.1 s | 3.2 s | +1.1 s | 52.2% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/heatmap_statistics | 13.3 s | 13.8 s | +508 ms | 3.8% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/normalize_data | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| month-single-server-access-logs-heatmap | TIMING/total | 2.1 min | 2.1 min | +992 ms | 0.8% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/rss_peak | 2.2 GB | 2.7 GB | +540.4 MB | 23.8% | REGRESS |
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
| month-single-server-access-logs-heatmap | MEMORY/log_occurrences | 36.6 KB | 36.8 KB | +192 B | 0.5% | REGRESS |
| month-single-server-access-logs-heatmap | MEMORY/log_sessions | 2.2 MB | 2.2 MB | -128 B | -0.0% | IMPROVE |
| month-single-server-access-logs-heatmap | MEMORY/log_stats | 54.1 KB | 54.1 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-histogram | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-histogram | TIMING/read_files | 1.9 min | 1.9 min | +536 ms | 0.5% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/calculate_statistics | 6.1 s | 6.9 s | +776 ms | 12.8% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/histogram_statistics | 23.6 s | 24.5 s | +938 ms | 4.0% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/normalize_data | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| month-single-server-access-logs-histogram | TIMING/total | 2.4 min | 2.5 min | +2.3 s | 1.6% | REGRESS |
| month-single-server-access-logs-histogram | MEMORY/rss_peak | 3.6 GB | 4.1 GB | +592.1 MB | 16.2% | REGRESS |
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
| month-single-server-access-logs-heatmap-histogram | TIMING/read_files | 2.0 min | 2 min | +3.4 s | 2.9% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/calculate_statistics | 2.1 s | 2.6 s | +440 ms | 20.8% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/heatmap_statistics | 13.8 s | 14.5 s | +663 ms | 4.8% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/histogram_statistics | 23.6 s | 24.7 s | +1.1 s | 4.6% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/normalize_data | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | TIMING/total | 2.6 min | 2.7 min | +5.6 s | 3.6% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/rss_peak | 3.6 GB | 4.2 GB | +598 MB | 16.2% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_data | 75.4 KB | 77.9 KB | +2.5 KB | 3.3% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_raw | 563.6 MB | 563.6 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/histogram_values | 1.1 GB | 1.1 GB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_analysis | 15.7 KB | 15.7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_messages | 1.2 GB | 1.6 GB | +439.1 MB | 36.2% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_occurrences | 36.6 KB | 36.8 KB | +192 B | 0.5% | REGRESS |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_stats | 54.1 KB | 54.1 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_read | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | lines_included | 7,749,167 | 7,749,167 | 0 | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/read_files | 2.9 min | 2.8 min | -4.4 s | -2.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/group_similar | 64.4 min | 2.9 min | -61.5 min | -95.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | 2.5 s | 3.6 s | +1.2 s | 47.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/heatmap_statistics | 14.6 s | 15.6 s | +1 s | 7.2% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/histogram_statistics | 24.5 s | 25.5 s | +1 s | 4.1% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/normalize_data | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | TIMING/total | 68 min | 6.5 min | -61.5 min | -90.5% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | 4.4 GB | 3.3 GB | -1.1 GB | -25.1% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | 5.6 MB | 507.7 MB | +502.1 MB | 8991.4% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | 236.4 MB | 2.5 MB | -234.0 MB | -99.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | 71.6 KB | 295 KB | +223.5 KB | 312.2% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | 150.6 MB | 1.6 MB | -149 MB | -99.0% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | 77.9 KB | 76.9 KB | -1 KB | -1.3% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw | 563.6 MB | 563.7 MB | +121.6 KB | 0.0% | REGRESS |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/histogram_values | 1.1 GB | 1.1 GB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_analysis | 15.7 KB | 15.7 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_messages | 1.2 GB | 566.3 MB | -645.3 MB | -53.3% | IMPROVE |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_occurrences | 36.8 KB | 36.8 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_sessions | 2.2 MB | 2.2 MB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_stats | 54.1 KB | 54.1 KB | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-standard | TIMING/read_files | 9.1 min | 9.0 min | -4.7 s | -0.9% | IMPROVE |
| month-many-servers-access-logs-standard | TIMING/calculate_statistics | 29 s | 34.9 s | +5.9 s | 20.2% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/normalize_data | 2 ms | 3 ms | +1 ms | 50.0% | REGRESS |
| month-many-servers-access-logs-standard | TIMING/total | 9.5 min | 9.6 min | +1.1 s | 0.2% | REGRESS |
| month-many-servers-access-logs-standard | MEMORY/rss_peak | 10 GB | 12.3 GB | +2.3 GB | 22.7% | REGRESS |
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
| month-many-servers-access-logs-standard | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -31.9 KB | -0.2% | IMPROVE |
| month-many-servers-access-logs-standard | MEMORY/log_stats | 60.1 KB | 60.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-standard | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25 | TIMING/read_files | 9.0 min | 9.0 min | +1.8 s | 0.3% | REGRESS |
| month-many-servers-access-logs-top25 | TIMING/calculate_statistics | 35.6 s | 50.5 s | +15.0 s | 42.1% | REGRESS |
| month-many-servers-access-logs-top25 | TIMING/normalize_data | 3 ms | 7 ms | +4 ms | 133.3% | REGRESS |
| month-many-servers-access-logs-top25 | TIMING/total | 9.6 min | 9.8 min | +16.8 s | 2.9% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/rss_peak | 10.2 GB | 11 GB | +834.9 MB | 8.0% | REGRESS |
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
| month-many-servers-access-logs-top25 | MEMORY/log_messages | 6 GB | 8.3 GB | +2.3 GB | 38.7% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_sessions | 14.9 MB | 14.9 MB | +32 KB | 0.2% | REGRESS |
| month-many-servers-access-logs-top25 | MEMORY/log_stats | 60.1 KB | 60.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25 | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | TIMING/read_files | 10.7 min | 11.8 min | +1.1 min | 9.9% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | TIMING/group_similar | 466.3 min | 18.6 min | -447.7 min | -96.0% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | TIMING/calculate_statistics | 37 s | 46 s | +9.0 s | 24.3% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | TIMING/normalize_data | 3 ms | 4 ms | +1 ms | 33.3% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | TIMING/total | 477.7 min | 31.2 min | -446.5 min | -93.5% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/rss_peak | 11.6 GB | 7.3 GB | -4.3 GB | -37.1% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_clusters | 31.0 MB | 2.6 GB | +2.6 GB | 8663.5% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_message | 1.1 GB | 2.4 MB | -1.1 GB | -99.8% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_patterns | 133.8 KB | 518.0 KB | +384.2 KB | 287.2% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_unmatched | 735.8 MB | 1.7 MB | -734.1 MB | -99.8% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_analysis | 2.9 GB | 2.9 GB | +7.4 MB | 0.3% | REGRESS |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_messages | 6 GB | 2.9 GB | -3.1 GB | -52.1% | IMPROVE |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_stats | 60.1 KB | 60.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-top25-consolidate | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap | TIMING/read_files | 9.3 min | 9.1 min | -7.2 s | -1.3% | IMPROVE |
| month-many-servers-access-logs-heatmap | TIMING/calculate_statistics | 10.4 s | 14.6 s | +4.1 s | 39.6% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/heatmap_statistics | 1.1 min | 1.1 min | +3.7 s | 5.6% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/normalize_data | 2 ms | 4 ms | +2 ms | 100.0% | REGRESS |
| month-many-servers-access-logs-heatmap | TIMING/total | 10.5 min | 10.5 min | +573 ms | 0.1% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/rss_peak | 10.6 GB | 12.9 GB | +2.3 GB | 21.7% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_data | 76.8 KB | 74.8 KB | -2 KB | -2.6% | IMPROVE |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_raw | 2.9 GB | 2.9 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/histogram_values | 576 B | 576 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_analysis | 15.7 KB | 15.7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_messages | 6 GB | 8.0 GB | +2.0 GB | 32.6% | REGRESS |
| month-many-servers-access-logs-heatmap | MEMORY/log_occurrences | 43.8 KB | 43.8 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_sessions | 14.9 MB | 14.9 MB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_stats | 54.1 KB | 54.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-histogram | TIMING/read_files | 9.5 min | 9.5 min | +1.4 s | 0.3% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/initialize_buckets | 0 us | 1 ms | +1 ms | NEW | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/calculate_statistics | 42.3 s | 1.1 min | +21.1 s | 49.9% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/histogram_statistics | 2.8 min | 5.6 min | +2.8 min | 101.6% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/normalize_data | 4 ms | 6 ms | +2 ms | 50.0% | REGRESS |
| month-many-servers-access-logs-histogram | TIMING/total | 13.0 min | 16.2 min | +3.2 min | 24.8% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/rss_peak | 12 GB | 12 GB | -7 MB | -0.1% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_data | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_raw | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/histogram_values | 5.4 GB | 5.4 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_analysis | 2.9 GB | 2.9 GB | -6.4 KB | -0.0% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/log_messages | 6 GB | 8.3 GB | +2.3 GB | 38.7% | REGRESS |
| month-many-servers-access-logs-histogram | MEMORY/log_occurrences | 42.1 KB | 42.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_sessions | 14.9 MB | 14.9 MB | -32 KB | -0.2% | IMPROVE |
| month-many-servers-access-logs-histogram | MEMORY/log_stats | 60.1 KB | 60.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | lines_read | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | lines_included | 38,672,504 | 38,672,504 | 0 | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/read_files | 9.6 min | 9.6 min | -236 ms | -0.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/calculate_statistics | 14.1 s | 19.9 s | +5.9 s | 41.6% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/heatmap_statistics | 1.2 min | 1.2 min | +1.1 s | 1.6% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | TIMING/histogram_statistics | 2.7 min | 2.7 min | -1.8 s | -1.1% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | TIMING/normalize_data | 4 ms | 4 ms | 0 ms | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | TIMING/total | 13.8 min | 13.9 min | +4.9 s | 0.6% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/rss_peak | 13 GB | 14.6 GB | +1.5 GB | 11.5% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_clusters | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_key_message | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_patterns | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_unmatched | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_data | 75.3 KB | 76.8 KB | +1.5 KB | 2.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_data_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_raw | 2.9 GB | 2.9 GB | -6.4 KB | -0.0% | IMPROVE |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/heatmap_raw_hl | 120 B | 120 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/histogram_values | 5.4 GB | 5.4 GB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_analysis | 15.7 KB | 15.7 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_messages | 6 GB | 8.3 GB | +2.3 GB | 38.5% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_occurrences | 43.8 KB | 43.8 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_sessions | 14.9 MB | 14.9 MB | +128 B | 0.0% | REGRESS |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_stats | 54.1 KB | 54.1 KB | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/log_threadpools | 232 B | 232 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/threadpool_activity | 762 B | 762 B | 0 B | 0.0% |  |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/udm_last_value | 120 B | 120 B | 0 B | 0.0% |  |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | N/A | 62.2 MB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | N/A | 10.4 MB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | N/A | 60.8 MB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | N/A | 1.6 MB | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | N/A | 726422 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 3738228 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 497442 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 131128 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 232 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 65592 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 8248 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | N/A | 1304 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | N/A | 480 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | N/A | 28800.00 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/log_messages | N/A | 48030790 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | COUNTS/log_messages_entries | N/A | 105902 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | COUNTS/log_occurrences_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | COUNTS/log_stats_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | CONFIG/time_bucket_size | N/A | 480 | N/A | N/A | ? |
| multi-day-application-logs-heatmap-histogram | CONFIG/bucket_size_seconds | N/A | 28800.00 | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY_FINAL/log_messages | N/A | 48030790 | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-histogram | COUNTS/log_messages_entries | N/A | 105902 | N/A | N/A | ? |
| multi-day-application-logs-histogram | COUNTS/log_occurrences_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-histogram | COUNTS/log_stats_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-histogram | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-histogram | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| multi-day-application-logs-histogram | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-histogram | CONFIG/time_bucket_size | N/A | 480 | N/A | N/A | ? |
| multi-day-application-logs-histogram | CONFIG/bucket_size_seconds | N/A | 28800.00 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY_FINAL/log_messages | N/A | 48030790 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | COUNTS/log_messages_entries | N/A | 105902 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | COUNTS/log_occurrences_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | COUNTS/log_stats_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | CONFIG/time_bucket_size | N/A | 480 | N/A | N/A | ? |
| multi-day-application-logs-heatmap | CONFIG/bucket_size_seconds | N/A | 28800.00 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | N/A | 62.6 MB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | N/A | 4.5 MB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | N/A | 61.3 MB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | N/A | 478.1 KB | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | N/A | 30006420 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | N/A | 20086 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 30969882 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 206885 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 131128 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 232 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 65592 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 4152 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | N/A | 606 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/log_messages | N/A | 108064422 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | N/A | 20086 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | COUNTS/log_messages_entries | N/A | 182419 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | COUNTS/log_occurrences_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | COUNTS/log_stats_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap-histogram | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY_FINAL/log_messages | N/A | 108064422 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY_FINAL/log_analysis | N/A | 20342 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | COUNTS/log_messages_entries | N/A | 182419 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | COUNTS/log_occurrences_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | COUNTS/log_stats_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| multi-day-custom-logs-histogram | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/log_messages | N/A | 107569190 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/log_analysis | N/A | 20342 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | COUNTS/log_messages_entries | N/A | 182419 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | COUNTS/log_occurrences_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | COUNTS/log_stats_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| multi-day-custom-logs-heatmap | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | N/A | 62.6 MB | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | N/A | 4.5 MB | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_ngram_index | N/A | 61.3 MB | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY/consolidation_posting_size | N/A | 478.1 KB | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/log_messages | N/A | 30013620 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/log_analysis | N/A | 20342 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 30969856 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 206763 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 131128 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 232 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 65592 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 4152 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_messages_entries | N/A | 606 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_occurrences_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | COUNTS/log_stats_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| multi-day-custom-logs-top25-consolidate | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY_FINAL/log_messages | N/A | 108082422 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY_FINAL/log_analysis | N/A | 20086 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | COUNTS/log_messages_entries | N/A | 182419 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | COUNTS/log_occurrences_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | COUNTS/log_stats_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| multi-day-custom-logs-top25 | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY_FINAL/log_messages | N/A | 107568998 | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY_FINAL/log_analysis | N/A | 20342 | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-standard | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| multi-day-custom-logs-standard | COUNTS/log_messages_entries | N/A | 182419 | N/A | N/A | ? |
| multi-day-custom-logs-standard | COUNTS/log_occurrences_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-standard | COUNTS/log_stats_entries | N/A | 25 | N/A | N/A | ? |
| multi-day-custom-logs-standard | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-standard | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| multi-day-custom-logs-standard | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-custom-logs-standard | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| multi-day-custom-logs-standard | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | N/A | 4.1 MB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | N/A | 4.8 MB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | N/A | 352.5 KB | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | N/A | 57377795 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | N/A | 6670 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 52209401 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 125445 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 65592 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 296 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 16440 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_messages_entries | N/A | 597 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | COUNTS/log_stats_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/log_messages | N/A | 58191194 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/log_analysis | N/A | 6670 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | COUNTS/log_messages_entries | N/A | 3184 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | COUNTS/log_occurrences_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | COUNTS/log_stats_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-access-log-heatmap-histogram | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY_FINAL/log_messages | N/A | 58191194 | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY_FINAL/log_analysis | N/A | 6670 | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-histogram | COUNTS/log_messages_entries | N/A | 3184 | N/A | N/A | ? |
| single-day-access-log-histogram | COUNTS/log_occurrences_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-histogram | COUNTS/log_stats_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-histogram | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-histogram | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| single-day-access-log-histogram | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-histogram | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-access-log-histogram | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY_FINAL/log_messages | N/A | 57988058 | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY_FINAL/log_analysis | N/A | 6670 | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-heatmap | COUNTS/log_messages_entries | N/A | 3184 | N/A | N/A | ? |
| single-day-access-log-heatmap | COUNTS/log_occurrences_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-heatmap | COUNTS/log_stats_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-heatmap | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-heatmap | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| single-day-access-log-heatmap | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-heatmap | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-access-log-heatmap | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_trigrams | N/A | 4.1 MB | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_ngram_index | N/A | 4.8 MB | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY/consolidation_posting_size | N/A | 352.5 KB | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/log_messages | N/A | 56099052 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/log_analysis | N/A | 6670 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 50832213 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 123965 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 65592 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 296 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 16440 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | COUNTS/log_messages_entries | N/A | 614 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | COUNTS/log_occurrences_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | COUNTS/log_stats_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-access-log-top25-consolidate | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY_FINAL/log_messages | N/A | 58197970 | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY_FINAL/log_analysis | N/A | 6670 | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-top25 | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-top25 | COUNTS/log_messages_entries | N/A | 3184 | N/A | N/A | ? |
| single-day-access-log-top25 | COUNTS/log_occurrences_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-top25 | COUNTS/log_stats_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-top25 | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-top25 | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| single-day-access-log-top25 | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-top25 | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-access-log-top25 | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY_FINAL/log_messages | N/A | 58184154 | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY_FINAL/log_analysis | N/A | 6670 | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-standard | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| single-day-access-log-standard | COUNTS/log_messages_entries | N/A | 3184 | N/A | N/A | ? |
| single-day-access-log-standard | COUNTS/log_occurrences_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-standard | COUNTS/log_stats_entries | N/A | 15 | N/A | N/A | ? |
| single-day-access-log-standard | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-standard | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| single-day-access-log-standard | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-access-log-standard | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-access-log-standard | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | N/A | 62.2 MB | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | N/A | 10.4 MB | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_ngram_index | N/A | 60.8 MB | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY/consolidation_posting_size | N/A | 1.6 MB | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/log_messages | N/A | 726422 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 3738296 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 497578 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 131128 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 232 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 65592 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 8248 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | COUNTS/log_messages_entries | N/A | 1304 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | COUNTS/log_occurrences_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | COUNTS/log_stats_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | CONFIG/time_bucket_size | N/A | 480 | N/A | N/A | ? |
| multi-day-application-logs-top25-consolidate | CONFIG/bucket_size_seconds | N/A | 28800.00 | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY_FINAL/log_messages | N/A | 48030790 | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-top25 | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-top25 | COUNTS/log_messages_entries | N/A | 105902 | N/A | N/A | ? |
| multi-day-application-logs-top25 | COUNTS/log_occurrences_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-top25 | COUNTS/log_stats_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-top25 | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-top25 | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| multi-day-application-logs-top25 | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-top25 | CONFIG/time_bucket_size | N/A | 480 | N/A | N/A | ? |
| multi-day-application-logs-top25 | CONFIG/bucket_size_seconds | N/A | 28800.00 | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY_FINAL/log_messages | N/A | 48030790 | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-standard | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| multi-day-application-logs-standard | COUNTS/log_messages_entries | N/A | 105902 | N/A | N/A | ? |
| multi-day-application-logs-standard | COUNTS/log_occurrences_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-standard | COUNTS/log_stats_entries | N/A | 53 | N/A | N/A | ? |
| multi-day-application-logs-standard | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-standard | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| multi-day-application-logs-standard | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| multi-day-application-logs-standard | CONFIG/time_bucket_size | N/A | 480 | N/A | N/A | ? |
| multi-day-application-logs-standard | CONFIG/bucket_size_seconds | N/A | 28800.00 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | N/A | 29.3 MB | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | N/A | 16.4 MB | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | N/A | 29.7 MB | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | N/A | 860.9 KB | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | N/A | 137524 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 448005 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 55576 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 65592 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 232 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 32824 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 32824 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | COUNTS/log_messages_entries | N/A | 136 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | COUNTS/log_stats_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/log_messages | N/A | 2872100 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | COUNTS/log_messages_entries | N/A | 6512 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | COUNTS/log_occurrences_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | COUNTS/log_stats_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-application-log-heatmap-histogram | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY_FINAL/log_messages | N/A | 2872100 | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-histogram | COUNTS/log_messages_entries | N/A | 6512 | N/A | N/A | ? |
| single-day-application-log-histogram | COUNTS/log_occurrences_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-histogram | COUNTS/log_stats_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-histogram | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-histogram | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-histogram | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-histogram | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-application-log-histogram | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY_FINAL/log_messages | N/A | 2872100 | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-heatmap | COUNTS/log_messages_entries | N/A | 6512 | N/A | N/A | ? |
| single-day-application-log-heatmap | COUNTS/log_occurrences_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-heatmap | COUNTS/log_stats_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-heatmap | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-heatmap | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-heatmap | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-heatmap | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-application-log-heatmap | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_trigrams | N/A | 28.4 MB | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | N/A | 15.6 MB | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_ngram_index | N/A | 29.7 MB | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY/consolidation_posting_size | N/A | 860.9 KB | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/log_messages | N/A | 137524 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 448047 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 55660 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 65592 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 232 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 32824 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 32824 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | COUNTS/log_messages_entries | N/A | 136 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | COUNTS/log_occurrences_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | COUNTS/log_stats_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-application-log-top25-consolidate | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY_FINAL/log_messages | N/A | 2872100 | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-top25 | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-top25 | COUNTS/log_messages_entries | N/A | 6512 | N/A | N/A | ? |
| single-day-application-log-top25 | COUNTS/log_occurrences_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-top25 | COUNTS/log_stats_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-top25 | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-top25 | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-top25 | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-top25 | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-application-log-top25 | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | N/A | 71.7 MB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | N/A | 64.2 MB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | N/A | 66.7 MB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | N/A | 614.1 KB | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | N/A | 100953 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 200881 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 25503 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 65592 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 232 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 65592 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 65592 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_messages_entries | N/A | 72 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | COUNTS/log_stats_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/log_messages | N/A | 133188237 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | COUNTS/log_messages_entries | N/A | 286659 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | COUNTS/log_occurrences_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | COUNTS/log_stats_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap-histogram | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/log_messages | N/A | 133188237 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | COUNTS/log_messages_entries | N/A | 286659 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | COUNTS/log_occurrences_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | COUNTS/log_stats_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| humungous-log-uniqueness-histogram | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/log_messages | N/A | 133188237 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | COUNTS/log_messages_entries | N/A | 286659 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | COUNTS/log_occurrences_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | COUNTS/log_stats_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| humungous-log-uniqueness-heatmap | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_trigrams | N/A | 71.8 MB | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | N/A | 64.3 MB | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_ngram_index | N/A | 66.7 MB | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY/consolidation_posting_size | N/A | 614.1 KB | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/log_messages | N/A | 100953 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 200881 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 25503 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 65592 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 232 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 65592 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 65592 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_messages_entries | N/A | 72 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_occurrences_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | COUNTS/log_stats_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| humungous-log-uniqueness-top25-consolidate | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/log_messages | N/A | 133188237 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | COUNTS/log_messages_entries | N/A | 286659 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | COUNTS/log_occurrences_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | COUNTS/log_stats_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| humungous-log-uniqueness-top25 | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY_FINAL/log_messages | N/A | 133188237 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | COUNTS/log_messages_entries | N/A | 286659 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | COUNTS/log_occurrences_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | COUNTS/log_stats_entries | N/A | 5 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| humungous-log-uniqueness-standard | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY_FINAL/log_messages | N/A | 2872100 | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY_FINAL/log_analysis | N/A | 232 | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_clusters | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_patterns | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_key_message | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_unmatched | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_key_trigrams | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-standard | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 120 | N/A | N/A | ? |
| single-day-application-log-standard | COUNTS/log_messages_entries | N/A | 6512 | N/A | N/A | ? |
| single-day-application-log-standard | COUNTS/log_occurrences_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-standard | COUNTS/log_stats_entries | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-standard | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-standard | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| single-day-application-log-standard | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| single-day-application-log-standard | CONFIG/time_bucket_size | N/A | 60 | N/A | N/A | ? |
| single-day-application-log-standard | CONFIG/bucket_size_seconds | N/A | 3600.00 | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-standard | MEMORY_FINAL/log_messages | N/A | 1732830683 | N/A | N/A | ? |
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
| month-single-server-access-logs-top25 | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-top25 | MEMORY_FINAL/log_messages | N/A | 1732844931 | N/A | N/A | ? |
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
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | N/A | 36.8 MB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | N/A | 29.4 MB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_ngram_index | N/A | 36.0 MB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY/consolidation_posting_size | N/A | 973.6 KB | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/log_messages | N/A | 593429939 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 531192355 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 257127 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 131128 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 424 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 65592 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 65592 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_messages_entries | N/A | 1319 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-single-server-access-logs-top25-consolidate | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/log_messages | N/A | 1732830635 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
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
| month-single-server-access-logs-histogram | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-histogram | MEMORY_FINAL/log_messages | N/A | 1730917915 | N/A | N/A | ? |
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
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/log_messages | N/A | 1730917867 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
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
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | N/A | 36.7 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | N/A | 29.4 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | N/A | 36.0 MB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | N/A | 973.6 KB | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | N/A | 593801746 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 532348102 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 262226 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 131128 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 296 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 65592 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 65592 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | N/A | 1300 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-single-server-access-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-standard | MEMORY_FINAL/log_messages | N/A | 8951243238 | N/A | N/A | ? |
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
| month-many-servers-access-logs-top25 | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-top25 | MEMORY_FINAL/log_messages | N/A | 8951257422 | N/A | N/A | ? |
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
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams | N/A | 36.8 MB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_key_trigrams_norm | N/A | 25.5 MB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_ngram_index | N/A | 36.1 MB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY/consolidation_posting_size | N/A | 1.2 MB | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/log_messages | N/A | 3097415057 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 2845092503 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 529500 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 131128 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 296 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 65592 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 65592 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_messages_entries | N/A | 2501 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-many-servers-access-logs-top25-consolidate | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/log_messages | N/A | 8555259662 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
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
| month-many-servers-access-logs-histogram | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-histogram | MEMORY_FINAL/log_messages | N/A | 8950522350 | N/A | N/A | ? |
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
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_key_trigrams_norm | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_ngram_index | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY/consolidation_posting_size | N/A | 120 B | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/log_messages | N/A | 8950528878 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
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
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/read_files | N/A | 12.4 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/initialize_buckets | N/A | 0 us | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/group_similar | N/A | 27.4 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/calculate_statistics | N/A | 18.7 s | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/heatmap_statistics | N/A | 1.2 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/histogram_statistics | N/A | 2 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/normalize_data | N/A | 4 ms | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | TIMING/total | N/A | 43.4 min | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/rss_peak | N/A | 14.3 GB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_clusters | N/A | 2.6 GB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_message | N/A | 2.5 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams | N/A | 36.8 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_key_trigrams_norm | N/A | 29.5 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_ngram_index | N/A | 36.1 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_patterns | N/A | 530.6 KB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_posting_size | N/A | 1.2 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/consolidation_unmatched | N/A | 1.7 MB | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY/heatmap_data | N/A | 76.8 KB | N/A | N/A | ? |
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
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_messages | N/A | 3093262484 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/log_analysis | N/A | 13010 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_clusters | N/A | 2833493657 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_patterns | N/A | 543305 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_message | N/A | 131128 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_unmatched | N/A | 424 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_ngram_index | N/A | 120 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams | N/A | 65592 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | MEMORY_FINAL/consolidation_key_trigrams_norm | N/A | 65592 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_messages_entries | N/A | 2547 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_occurrences_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | COUNTS/log_stats_entries | N/A | 28 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_width | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/terminal_height | N/A | 24 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/max_log_message_length | N/A | 200 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/time_bucket_size | N/A | 1440 | N/A | N/A | ? |
| month-many-servers-access-logs-heatmap-histogram-consolidate | CONFIG/bucket_size_seconds | N/A | 86400.00 | N/A | N/A | ? |

