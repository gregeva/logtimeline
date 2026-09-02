# Hypothesis: v0.18.0-first parse/read_files regression vs v0.17.0

Benchmark comparison (v0.17.0-release vs v0.18.0-first, all tier) shows
parse/read_files +15.9% suite-wide; per-line normalization puts access-log
cases at +1.1-1.7 s/Mline, application logs +0.3-0.5, custom logs ~0.

A/B on single-day-access-log-standard (148 MB, 0.76M lines, same machine,
interleaved 3x): HEAD 9.62s vs v0.17.0 8.67s read_files -> +0.95s reproducible.

Isolation variants (classification/outcome work #453/#452/#455):
- V1 (per-message outcomes writes removed):        9.51s  (-0.11)
- V2 (V1 + per-bucket outcome accounting removed): 9.46s  (-0.05)
- V3 (V2 + classifier statement nulled):           9.36s  (-0.10)

So classification + outcome accounting ~= 0.26s of the 0.95s. Hypothesis for
the remaining ~0.7s: an additional per-line cost in the include path or the
generated scan block that is NOT part of classification — candidate suspects:
bucket_epoch indirection (#451 profile modes), highlight/filter gate
restructuring (#455), or scan-block changes. Expect read_and_process_logs
line-level profile to show the delta concentrated on specific new lines in
the include loop.

Expected call counts: read_and_process_logs called once; scan sub once per
line (100k sample); classification inline (no sub calls).
