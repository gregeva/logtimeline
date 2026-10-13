# A switchable generated read-loop body (Issue #621)

## Status

Measured (§ 3, § 4) and priced by prototype (§ 5), not planned for implementation. Branch `621-generated-read-loop-body`,
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

The bound assumes every removed test costs what one inserted test costs, and
covers the default options only. § 4 measures the saving directly and finds
the bound under-reads it.

## 4. The saving measured directly (2026-10-13)

A prototype, `prototype/621-remaining-loop-bound/make-specialised.pl`, writes
the loop a generator would emit for the default options: every test of a value
fixed for the run taken out by asserted mechanical edits, tests fixed for a
file or a format kept, the loop 1,311 lines to 659, and a guard that stops the
probe on any other option set. Record: `analysis.md` § The specialised loop.

| | access log | application log |
|---|---|---|
| output against the base, full file, hash seed fixed | identical except timing, peak memory and code size | identical except timing, peak memory and code size |
| time, ten rounds, per-round delta median (range) | **−20.50 %** (−22.73 to −18.01 %), faster in 10 of 10; 6.344 s to 4.989 s | **−15.17 %** (−18.91 to +26.43 %), faster in 9 of 10; 3.139 s to 2.663 s |
| statements per line (NYTProf, 100,000-line slice) | 131.0 to 84.0 | 101.0 to 66.0 |
| saving per removed statement | 36.7 ns | 28.6 ns |
| the § 3 bound | 14.1 % | 10.4 % |

A test in its real site costs about 1.5 times the inserted always-false test
the bound was computed from, so the bound under-reads the saving. The one
removed statement that is not a test, the per-message `-HL` suffix
substitution, measured nothing resolvable on its own (+0.40 % and −0.05 %).

The measurement covers the default options only. A run that switches options
on needs the blocks they guard, and its generated body keeps more of the
loop.

## 5. What a generated body costs (prototype, 2026-10-13)

Record: `tests/profile/results/621-remaining-loop-bound/analysis-generator.md`
(hypotheses in `hypothesis-generator.md`, written before the measurements);
tooling `prototype/621-remaining-loop-bound/make-generated.pl` and
`markers.tsv`.

**The mechanism prototyped.** The inline loop stays the one source and the
reference. 77 marker comments above its gates each name the run-constant
expression that decides the gate. At run start a generator of about 150 lines
streams the program's own source, resolves every marker once, blanks what the
run does not need (keeping line numbers), keeps a known-true arm's scope as
`if (1) {`, and compiles the text as an anonymous sub under one `#line`
directive. A switch selects the inline loop instead.

**Identity.** Both placements of the compile produce the base's output on 46
option shapes over five log families that switch every marked gate on, with
no runtime warning (the comparison takes 57 s). On the default options the
generated body is code-identical to the hand-specialised loop of § 4.

**Speed**, ten rounds, per-round delta against the base:

| selection | hand-specialised (§ 4) | generated, compiled per file | generated, compiled per run |
|---|---|---|---|
| access log, full day | −19.57 % | −19.02 % | −18.03 % |
| application log, full day | −17.23 % | −16.51 % | −16.82 % |
| application logs, 41 files | −14.30 % | −12.66 % | −12.81 % |
| access log, 100,000 lines | −19.12 % | −17.12 % | −16.73 % |
| access log, 10,000 lines | −15.62 % | −9.40 % | −8.43 % |
| access log, 1,000 lines | −1.98 % | +12.88 % | +7.63 % |
| application log, 1,000 lines | −3.85 % | +9.72 % | +11.25 % |

**The four recorded costs, priced:**

| cost | price |
|---|---|
| the body becomes text assembled from pieces | none duplicated: the body is written from the inline loop at each run, about 5.3 ms, plus a 1.5 ms compile |
| a defect reports inside evaluated text | with the `#line` directive, warnings, `die` messages and NYTProf name the source file and line exactly as the inline loop does; without it, `(eval N) line M`. The harnesses' runtime-warning check catches both |
| the loop's lexical state moves | compiled per file, nothing moves (3 lines change; one 1.5 ms compile per file, 63 ms over 41 files); compiled per run, 13 per-file variables move out of the per-file loop (29 lines change); same speed |
| every feature block becomes an includable piece | 77 marker lines, no block moved; a marker naming the wrong flag can drop a feature's output silently, caught only by the identity comparison on a shape that switches that gate on; one breaking a declaration fails loudly at run start |

**Also measured:** 0.5 to 2 MB more peak memory (the inline loop's code is
held beside the generated body's); slower than the base on a 1,000-line input
by the 7 ms fixed cost; a `die` in the generated body exits with `$!`'s value
(25 here) where the inline loop exited 1.

**Not verified:** a PAR-packed binary. The generator reads PAR's extracted
copy of the script (named in `PAR_0`, two lines longer) when `__FILE__` is
not on disk; that layout was simulated and works, but the packager could not
be installed on this machine (the network proxy blocks one of its
dependencies).

**Found on the way, pre-existing:** on the script log,
`-udm durationMS::max -hg -h Things` ends the run in the histogram drawing
("Can't use an undefined value as an ARRAY reference"), on the base and on the
released v0.18.6 as well; filed as #719.

## 6. Direction (the architect, 2026-10-13)

- The PAR::Packer angle is tested first, as its own sub-issue: #720 (prove the
  generated read-loop body in the PAR-packed binaries). It blocks the
  implementation.
- The implementation is its own sub-issue: #721 (generate the read loop's body
  per run for large inputs, with an option to force the inline loop).
- The generated path is taken only when a file is above a size threshold, so a
  small file does not pay the fixed cost (§ 5: slower than the base at 1,000
  lines) and does not need the speedup. Threshold chosen from § 5's
  measurements: 2 MB per file. Generation costs about 7 ms; at 10,000 lines
  (about 1.8 to 1.9 MB of the benchmark logs) the generated body measured 3 to
  9 % faster than the base, at 1,000 lines 8 to 13 % slower. The size of a file
  is known before it is read; its line count is not.
- A command-line option shuts the runtime compile off and forces the standard
  inline flow, for development, debugging and profiling; proposed as `--debug`.
