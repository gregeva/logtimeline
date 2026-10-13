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
direct measurement, which follows.

## The specialised loop: the saving measured directly

`prototype/621-remaining-loop-bound/make-specialised.pl` writes the body a
generator would emit for the default options: the base `ltl` with every test of
a value fixed for the run taken out (56 asserted edits: a block whose condition
is false deleted, a block whose condition is true unwrapped, an if/else reduced
to the arm that runs, a fixed term dropped from a condition), and the
declarations only those blocks used. Tests fixed for a file or a format and the
first-observation latches stay. The loop goes from 1,311 lines to 659. A guard
before the loop stops the probe on any run whose options differ from the values
it was specialised for, which were read from the benchmark runner's invocation
and are the same on both files; bare `-V` trips it, because full verbose output
switches on demand the default run does not have.

**Identity.** Under the benchmark runner's invocation on both full files, with
the hash seed fixed (`PERL_HASH_SEED=0 PERL_PERTURB_KEYS=0`), the rendered
output and every `-V benchmark-data` row match the base except the timing rows,
the peak resident size, the unattributed memory and the compiled scan sub's
size. Without the fixed seed the bucket store's measured size differs by 192
bytes on the access log slice; the base alone reads 2,023 or 2,215 bytes from
one run to the next, and the two agree with the seed fixed, so the difference
is the hash table's sizing under the per-process seed, not the store's
content (its keys, values and scalar types are identical).

**Timing.** Ten order-balanced rounds of the base and the specialised loop,
`specialised.tsv`:

| file | base median | specialised median | per-round delta, median (range) | faster in |
|---|---|---|---|---|
| access log | 6.344 s (6.111 to 6.428) | 4.989 s (4.967 to 5.138) | **−20.50 %**, −1.313 s (−1.461 to −1.129 s) | 10 of 10 |
| application log | 3.139 s (3.081 to 3.303) | 2.663 s (2.582 to 4.176) | **−15.17 %**, −0.480 s (−0.615 to +0.873 s) | 9 of 10 |

The application log's one slower round (round 4, 3.303 s against 4.176 s) is
the specialised run's maximum and 1.5 s above its next-slowest run; the other
nine rounds read −11.4 % to −18.9 %.

**Attribution.** The direct saving exceeds the bound (14.1 % and 10.4 %).
NYTProf statement counts of the specialised loop on the same 100,000-line
slices: 84.0 statements per line against the base's 131.0 on the access log
(47 fewer), 66.0 against 101.0 on the application log (35 fewer), matching the
counted tests (several tests share a statement). The saving per line, 1.72 µs
and 1.00 µs, is 36.7 ns and 28.6 ns per removed statement, against 22.8 ns and
19.7 ns for the inserted always-false test: a test in its real site costs about
1.5 times the probe's, because the sites are compound conditions, `defined` and
list tests, and blocks with their own declarations rather than the probe's one
scalar read. The `-HL` suffix substitution, the one removed statement that is
not a test, was timed on its own (`nohl.tsv`, the base without it, proven
identical the same way): +0.40 % (−8.42 to +2.67 %) on the access log and
−0.05 % (−8.02 to +3.33 %) on the application log, faster in 5 of 10 on each,
nothing resolvable.

The gate-series bound therefore under-reads what removing the tests recovers;
the measured saving on the default options is about 20 % on the access log and
15 % on the application log.
