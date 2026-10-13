# A switchable generated read-loop body (Issue #621)

## Status

Measuring, not planned for implementation. Branch `621-generated-read-loop-body`,
cut from `release/0.19.0` 524a66d. Parent: #622 (the refactoring the
redundant-logic-surfaces audit dispatched). The hoisting it followed (#620)
is done (`features/620-read-loop-run-constant-hoisting.md`).

## 1. The motivating consumer

Every run of `ltl` on the default options. The read loop
(`read_and_process_logs` :: `while (1) {`) asks, on every line, questions
whose answers are fixed for the run. A body generated per run from only the
blocks its options need would ask none of them; the format registry already
generates and compiles its scan sub per run from declarative specs
(`features/log-format-registry.md`; `docs/architecture-patterns.md`
§ Generated code compiled from source strings).

## 2. Requirement (the issue, 2026-09-27)

A run can switch to a read loop whose body is generated from only the blocks
its options need, compiled once per run. The inline loop stays as the
reference and the debugging path; the generated body is a switch for speed.
The two are kept in sync and proven comparable: every harness that reads the
loop's output runs both paths and asserts identity, and a defect is
reproduced on the inline loop.

The costs recorded against it by the audit
(`features/342-redundant-logic-surfaces-audit-report.md` § Item 8, part 3):
the loop body becomes text assembled from pieces; a defect in the generated
body reports inside evaluated text; the loop's lexical state moves to where
generated code can reach it; every feature block becomes an includable piece.

## 3. The remaining bound (measured 2026-10-13)

Record: `tests/profile/results/621-remaining-loop-bound/` (`hypothesis.md`
written before the timing runs, `analysis.md`, the raw rounds `curve.tsv`);
tooling under `prototype/621-remaining-loop-bound/`. Measured the way the
audit measured its bound: the run-constant tests an included line evaluates,
times the cost of one test, over the time per line, on `release/0.19.0`
524a66d, default options (the benchmark runner's invocation).

| | access log, a day of web-server access log (761,698 lines) | application log, a day of application server log (479,904 lines) |
|---|---|---|
| tests fixed for the run, per included line (NYTProf execution counts, 100,000-line slices) | 51 | 35 |
| tests fixed for a file or a format | 12 | 12 |
| cost of one always-false boolean test (ten order-balanced rounds, slope over 0/10/20/40 tests) | 22.8 ns | 19.7 ns |
| time per line, base median | 8.23 µs (6.271 s, 6.148 to 6.787) | 6.59 µs (3.163 s, 3.081 to 3.204) |
| **bound: tests fixed for the run** | **14.1 %** | **10.4 %** |
| with the tests fixed for a file or a format | 17.4 % | 14.0 % |
| the audit's bound, 2026-09-26 | about 13 % | about 19 % |

The access log's share did not fall: its time per line fell 29 % since the
audit (11.6 to 8.23 µs) while the tests left fell from the audit's site count
of about 64 to 51 executed. The application log's lines carry no duration or
bytes, so they skip the metric blocks and most of the tests; its share fell
from about 19 % to 10.4 %.

The bound is an upper bound: every removed test is assumed to cost a full
slope and its removal nothing, and it covers the default options only.
