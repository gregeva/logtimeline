# Analysis — #621, the read loop's remaining run-constant bound

Runs 2026-10-13 14:56Z to about 15:08Z, one host (Apple M1 Pro, Homebrew Perl
5.44.0), on `621-generated-read-loop-body` at ff14d63 (`release/0.19.0` 524a66d
plus the version stamp). The hypothesis is `hypothesis.md` beside this file,
written before the first timing run; the raw rounds are `curve.tsv`. Probes
from `prototype/621-remaining-loop-bound/make-probes.pl`, timed by
`prototype/342-read-loop-cost-curve/run-curve.sh`, summarised by
`prototype/342-read-loop-cost-curve/summarise.pl`, both unchanged from the
audit. Every probe's rendered output and bare `-V` on the two 100,000-line
slices matched the base except the total-time line and the no-match sampling
time.

## The count

NYTProf line counts over the loop on the first 100,000 lines of each file,
under the benchmark runner's invocation
(`--disable-progress -V benchmark-data -mem --terminal-width 200 -bs 60`);
every line read is included on both slices. `loop-line-counts.pl` dumps the
count of every loop line, `sites.tsv` classifies each executed line carrying a
test, `tally.pl` sums the tests per included line.

| class | access log | application log |
|---|---|---|
| **fixed for the run**: removable by a body generated for the default options | **51** | **35** |
| fixed for a file or a format: removable only by a body per file or per format | 12 | 12 |
| first-observation latches over data: not removable by generation | 6 | 4 |

The 51 on the access log: 37 boolean scalars, 4 `defined` tests on undefined
option scalars, 4 list truth tests on the empty user-defined-metric list, 4
numeric compares (the progress stride, the bucket-key scale and the two
absolute time-window bounds, which are infinite on a run with no `-st`/`-et`),
2 hash truth tests, the `-HL` suffix substitution on every retained message
and the per-line `%udm_values` declaration. The application log's lines carry
no duration or bytes, so they skip the per-message and per-bucket metric
blocks and the 16 tests inside them. The thread-pool block's two option tests,
reached only on a line whose thread name yields a pool, are not counted (at
most 2 more on the application log, none on the access log).

The audit's figure of about 64 was a count of sites read from the code, mixing
these three classes; the 51 is a count of executions and holds only the first.

## The cost of one test and the time per line

Ten order-balanced rounds of the base and the gate series, the tool's own
`TIMING total`, medians of ten with ranges:

| file (lines) | base | gate-10 | gate-20 | gate-40 |
|---|---|---|---|---|
| access log (761,698) | 6.271 s (6.148 to 6.787) | +3.28 % | +6.01 % | +11.20 % (6.973 s, 6.886 to 7.412) |
| application log (479,904) | 3.163 s (3.081 to 3.204) | +2.61 % | +3.56 % | +12.08 % (3.546 s, 3.491 to 3.603) |

Least-squares slopes over N in {0, 10, 20, 40}:

| | access log | application log | audit, 2026-09-26 |
|---|---|---|---|
| per test, per run | 0.01738 s (0.277 % of base) | 0.00944 s (0.298 % of base) | 0.0175 s / 0.0109 s |
| **per test, per line** | **22.8 ns** | **19.7 ns** | 23.0 ns / 22.8 ns |
| **time per line (base)** | **8.23 µs** | **6.59 µs** | 11.6 µs / 7.6 µs |

The access log's slope residuals are within ±0.017 s; the application log's
N = 20 point sits 0.055 s under its line, inside the round-to-round spread of
that file's gate-10 (0.028 to 0.301 s). The gate-10 per-round delta is
positive in ten of ten rounds on both files.

## Against the hypotheses

- **H1 (the per-test cost has not moved): holds on the access log** (22.8 ns
  against 23.0); the application log reads 19.7 ns against 22.8, 3 ns under
  the predicted band, driven by the flat N = 20 step.
- **H2 (the time per line has fallen): holds**, by more than predicted on the
  access log: 11.6 µs to 8.23 µs (−29 %), the application log 7.6 µs to
  6.59 µs (−14 %). The fall is the whole release's work on the loop, not the
  hoisting alone.
- **H3 (the remaining bound is about 10 % and 11 %): partly.** Because the
  access log's time per line fell further than its test count, the bound's
  share of its time did not fall:

| | access log | application log |
|---|---|---|
| tests fixed for the run × cost per test / time per line | 51 × 22.8 ns / 8.23 µs = **14.1 %** | 35 × 19.7 ns / 6.59 µs = **10.4 %** |
| adding the tests fixed for a file or a format | +3.3 % | +3.6 % |
| audit's bound, 2026-09-26 | about 13 % | about 19 % |

## What the bound is and is not

It is an upper bound in the audit's sense: every removed test is assumed to
cost a full slope, measured on a test inserted at one point, and removing it
is assumed to cost nothing. Tests in the loop's real sites may cost less than
an inserted one (several share a line with work that stays), and the
substitution and the declaration are counted as one test each although their
cost is not a test's. It says nothing about runs with options switched on,
where the branches those tests guard are needed and fewer tests can go.

Both files remain well above the 3 % threshold agreed for proceeding to a
direct measurement: a copy of the loop with the 51 tests removed for the
default options, proven identical in output and timed against the base,
which would replace this bound with the saving a generated body would
actually deliver on the default scenario.
