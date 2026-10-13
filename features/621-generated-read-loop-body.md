# A switchable generated read-loop body (Issue #621)

## Status

Measured (§ 3, § 4), priced by prototype (§ 5), proven in the packed binaries (§ 8, #720); implementation is #721. Branch `621-generated-read-loop-body`,
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

**The packed binaries:** the generator reads PAR's extracted copy of the
script (named in `PAR_0`, two lines longer) when `__FILE__` is not on disk.
Simulated here; verified in the packed binaries of all four release
packagings by #720, § 8.

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

## 7. Locked decisions

Locked by the architect on 2026-10-13.

- **D1.** `-D, --debug` is a user-facing option: under it every file takes the
  standard (inline) path, whatever its size. It is how a user rules the
  generated body in or out when a result looks wrong (a wrong marker can drop
  output silently, § 5), and the path for debugging and profiling on the
  reference code. Finding the line of a failing statement does not need it:
  with the `#line` directive the generated body reports warnings, `die`
  messages and profiler lines at the same source line (§ 5). Its `--help` and
  `docs/usage.md` text says what the user sees (the standard path, slower on
  large files, for reproducing a problem or profiling), not how it works.
- **D2** (decided by the architect 2026-10-13, under #721). A hidden option
  sets the size threshold above which a file takes the generated body; 0
  sends every file to it. The harnesses' fixtures are under the threshold,
  so without it the suite would reach only the inline loop; with it, every
  harness can compare both paths on its own fixtures, and a test can exercise
  the threshold's edge. It takes the shape of the existing hidden
  `--detection-window=N`. Chosen over a switch forcing the generated path, an
  environment variable, and no mechanism (the generated path then tested only
  on corpus files above the threshold).

## 8. The packed binaries (#720, 2026-10-13)

**Verdict: the generated body works in the PAR-packed binaries of all four
release packagings.** It is taken, gives the inline loop's output, and reports
a warning at its source line.

**What was packed.** Both probes of § 5 (compiled per file, compiled per run),
built by `prototype/621-remaining-loop-bound/make-generated.pl` from `ltl` at
524a66d, and a copy of each with one runtime warning (an undefined value in a
concatenation) injected as the first statement of the per-line loop. Each
script was packed as `ltl`, so its packed member is `script/ltl` as in the
release binaries, with PAR::Packer 1.064 on every platform:

| packaging | how | Perl |
|---|---|---|
| macOS arm64 | `pp`, as `build/macos-package.sh` | Homebrew 5.44.0 |
| Linux arm64, Linux amd64 | the container steps of `build/ubuntu-package.sh` (Ubuntu 20.04), `prototype/720-packed-generated-loop/pack-linux.sh`; tested in a fresh Ubuntu 20.04 container | 5.30.0 |
| Windows amd64 | the container steps of `build/windows-package.sh` (Strawberry Perl under Wine 5.0), `pack-windows.sh`; tested under Wine there | Strawberry 5.42.3 |

Checks per platform: `prototype/720-packed-generated-loop/test-pack.sh`. The
identity comparison is § 5's (`prototype/616-observation-count-arms/prove.sh`,
the 46 shapes of `prototype/621-remaining-loop-bound/shapes.txt` on
20,000-line slices of their five families, hash seed fixed), against the
packed inline loop (`LTL_GENERATED_LOOP=0`) as the reference; on macOS also
against the unpacked base.

| check | macOS arm64 | Linux arm64 | Linux amd64 | Windows amd64 |
|---|---|---|---|---|
| `__FILE__` is `script/<name>`; `PAR_0` names an extracted copy with `package main;` and a `#line 1` directive above the script, on a first and a cached run | yes | yes | yes | yes (a `C:\` path) |
| the generated path is taken: the markers resolved (64 results on the access-log slice at default options, 609 body lines) and the body compiled | yes | yes | yes | yes |
| output identical to the packed inline loop, 46 shapes, no runtime warning | 45; `-mem debug` differs in memory figures | 45; `-mem debug` differs in memory figures | 46 | 46 |
| the injected warning reads `at script/ltl line N`, N the statement's source line, on the inline and the generated path | yes | yes | yes | yes |

**The `-mem debug` differences are memory figures only**, every other line of
that output identical:

- PAR's runtime adds 14 to 15 MB of unattributed memory to every packed run on
  macOS, inline or generated (43 MB unpacked, 57 to 58 MB packed).
- On macOS the per-run placement reports the format scan subs at 1 MB where
  the inline loop reports 2 MB, in three repeats, and the same unpacked: a
  property of the per-run placement, not of packaging. Unattributed memory
  differs by 1 MB between the paths (57 and 58 MB on macOS, 51 and 52 MB on
  Linux arm64).

**Also observed.** For the same options, the generated body is byte-identical
on macOS and Linux arm64. Writing the body's text took 5.4 to 8.1 ms on Linux
and 49 to 77 ms on Windows; the Windows figure is Wine on an emulated amd64
container, not a measurement of Windows.

## 9. Implementation (#721)

Branch `721-generated-read-loop`, cut from `release/0.19.0` c039396. The
`before` benchmark is captured there: three runs each of
`single-day-access-log-standard`, `single-day-application-log-standard`,
`multi-day-application-logs-standard` and
`single-day-access-log-heatmap-histogram`.

**Contracts of the surfaces it touches, confirmed by the architect
2026-10-13:**

| surface | contract | record |
|---|---|---|
| Loop output | Identical on either path, for every option set and input. | § 2 |
| One source | The inline loop stays the only source; the generated body is written from it at run start, and no block is written twice. | #721 body; § 5 |
| Path choice | Made per file, by size: the generated body above 2 MB, the inline loop below. | § 6 |
| `-D, --debug` | Every file takes the inline path, whatever its size; a `--help` row and a `docs/usage.md` row describe what the user sees. | § 7 D1 |
| Hidden threshold option | Sets the size threshold; 0 sends every file to the generated body. | § 7 D2 |
| Generated-code pattern | A fifth consumption site, recorded in `docs/architecture-patterns.md` in the same commit; the generated code is validated before use. | `docs/architecture-patterns.md` § Generated code compiled from source strings |
| Harnesses | Every harness that reads the loop's output runs both paths and asserts identity. | § 2 |
| `-mem` and `-V` | `format_scan_subs` stays the memory growth around the format scan-sub compiles only; the generated body's compile does not enter it. | `features/log-format-registry.md` D62 |
| Packaged binary | Works as § 8 proved; a harness that runs `perl ltl` proves nothing about the binary. | § 8; `tests/HARNESS-DESIGN.md` § A harness that runs `perl ltl` proves nothing about the packaged binary |
| Speed | Above the threshold, the measured saving holds: about 19 % on a day of web-server access log, 16 % on a day of application log. | #721 Done when; § 5 |
