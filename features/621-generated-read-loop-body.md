# A switchable generated read-loop body (Issue #621)

## Status

Delivered. Measured (§ 3, § 4), priced by prototype (§ 5), proven in the
packed binaries (§ 8, #720, PR #723), implemented by #721 (§ 9, PR #725). Branch
`621-generated-read-loop-body`, cut from `release/0.19.0` 524a66d, merged with
PR #723. Parent: #622 (the refactoring the
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
no runtime warning (the comparison takes 57 s). The comparison stripped colour
escapes, which hides what a highlight renders as shading, and the 46 shapes
did not switch on every gate: five markers were wrong in a way only that
shading shows (§ 9, drop 3). On the default options the
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
- **D2** (locked by the architect 2026-10-13, under #721). The hidden option
  `--generated-loop-threshold=N` sets the size threshold, in bytes, above
  which a file takes the generated body: 2,097,152 (2 MB) when not given, and
  0 sends every file to it. `-D, --debug` overrides it: every file takes the
  inline loop. The harnesses' fixtures are under the threshold,
  so without it the suite would reach only the inline loop; with it, every
  harness can compare both paths on its own fixtures, and a test can exercise
  the threshold's edge. It takes the shape of the existing hidden
  `--detection-window=N`. Chosen over a switch forcing the generated path, an
  environment variable, and no mechanism (the generated path then tested only
  on corpus files above the threshold).
- **D3** (locked by the architect 2026-10-13, under #721; amended the same day).
  Both paths are covered in two places. A dedicated harness,
  `tests/validate-read-path.sh`, compares the generated body with the inline
  loop byte for byte over an option-shape set in which every marker's gate is
  switched on at least once, and fails when one is not. At the release gate
  the full suite runs a second time on the generated path, so every existing
  assertion is checked against it as well (`docs/process/workflow.md` § 5,
  step 4); each harness lets `LTL` be overridden for that pass (a one-line
  change in each of the 48 that set it). An issue's gate runs the suite once:
  a second pass doubles a gate of about 18 minutes, and development cannot
  wait on it. The suite is the gate's failsafe, never a development tool:
  while the work is under way, the developer runs dedicated tests aimed at what
  is being changed, and at most a single harness scenario. Chosen over every
  `ltl` call in every harness running both paths (342 call sites moved to a
  shared runner, suite time doubled on every run) and the dedicated harness
  alone.
- **D4** (locked by the architect 2026-10-13, under #721). When the generated
  body cannot be prepared for a file (the program's source cannot be read, a
  marker does not match the code under it, or the generated text does not
  compile), that file is read by the inline loop; a notice prints on stderr
  once per run saying the standard path is used, slower on large files, and
  `-V read-path` records the reason. Amended by #412 (2026-10-21): the notice
  is a record of the notice store, `read-path-fallback`, drawn in the notices
  panel on standard output, no longer on stderr
  (`features/412-notice-surfaces.md` § Drop 2). The output stays correct; only speed is
  lost. The identity harness fails on any fallback, since with the threshold
  at 0 every file must take the generated body. Chosen over stopping the run
  with an error.
- **D5** (locked by the architect 2026-10-13, under #721). The release build
  proves each packaged binary prepares the generated body: every binary it
  runs reads a small committed fixture with `--generated-loop-threshold=0
  -V read-path`, and the job fails unless every file reports the generated
  path. A step each in the macOS and Linux jobs of
  `.github/workflows/release-build.yml` and one inside
  `build/windows-package.sh` under Wine; the Linux arm64 binary stays checked
  by file type only, as today. Identity is not re-proven in the binary: the
  suite proves it on the source the binary is packed from. Chosen over handing
  the case to #227 (binary smoke harness) and over #720's one-time proof alone.
- **D6** (locked by the architect 2026-10-13, under #721). The generated body
  is compiled per file, inside the per-file loop after the file's format
  detection, so it closes over that file's variables where they are declared
  and nothing moves; its text is written once per run and cached, since the
  markers resolve only values fixed for the run. A file below the threshold
  compiles nothing. Chosen over one compile per run, which moves 13 per-file
  variables out of the per-file loop for no measured speed gain (§ 5: −12.66 %
  per file, −12.81 % per run, over 41 application-log files).
- **D7** (locked by the architect 2026-10-13, under #721). A marker that does
  not find what it names is a mismatch: a `when`, `true`, `false` or `unless`
  marker with no gate or modifier below it, and an `and` marker whose term is
  not in the condition below it, all stop generation, and the file falls back
  under D4. Marker rot is therefore always visible: a notice for the user, a
  failure of the identity harness. Chosen over the prototype's handling, where
  an `and` marker that missed its term left the term in the condition and
  carried on, correct but silently slower.

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

That comparison, like § 5's, stripped colour escapes, so it could not see the
five wrong markers § 9 records; packaging changes neither the markers nor the
comparison, so the verdict stands.

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
| Hidden threshold option | `--generated-loop-threshold=N`, N in bytes, default 2,097,152; 0 sends every file to the generated body. | § 7 D2 |
| Generated-code pattern | A fifth consumption site, recorded in `docs/architecture-patterns.md` in the same commit; the generated code is validated before use. | `docs/architecture-patterns.md` § Generated code compiled from source strings |
| Harnesses | Every harness that reads the loop's output runs both paths and asserts identity. | § 2 |
| `-mem` and `-V` | `format_scan_subs` stays the memory growth around the format scan-sub compiles only; the generated body's compile does not enter it. | `features/log-format-registry.md` D62 |
| Packaged binary | Works as § 8 proved; a harness that runs `perl ltl` proves nothing about the binary. | § 8; `tests/HARNESS-DESIGN.md` § A harness that runs `perl ltl` proves nothing about the packaged binary |
| Speed | Above the threshold, the measured saving holds: about 19 % on a day of web-server access log, 16 % on a day of application log. | #721 Done when; § 5 |

**Delivery plan, agreed 2026-10-13.** (1) The 77 marker comments placed
above the loop's gates, comment-only. (2) The generated path: generator,
per-file path choice, `--generated-loop-threshold=N`, `-D, --debug` with its
`--help` and `docs/usage.md` rows, the fallback notice, matching exit status,
the timing row, the `-V read-path` section, the architecture-patterns entry.
(3) `tests/validate-read-path.sh`. (4) `LTL` overridable in the 48 harnesses
that set it; `docs/process/workflow.md` § 5, step 4. (5) The release-build step
and its committed fixture. Then the gate: the `after` benchmark, the full
suite. The prototype's premise holds on the base: `ltl` changed by one
line outside the loop since 524a66d, and all 77 markers place.

**Drop 2, path choice (confirmed 2026-10-13).** Per file, after format
detection and before the per-line loop: under `-D` the inline loop, the
threshold not consulted; otherwise the generated body when the file's size is
strictly above the threshold, the inline loop when not. The size is
`$progress_file_size`, already resolved for every file at the top of the
per-file loop (no second stat). A file that is not a regular file never reaches
the read path: `ltl` refuses such an argument before reading ("unable to open
any files"). The body's text is written on the first file that needs it and cached
for the run, so a run of small files only, or under `-D`, never reads its own
source.

**Drop 2, generator (confirmed 2026-10-13).** As § 5 prototyped and § 8
proved in the packed binaries: the source read from `__FILE__`, or from
PAR's extracted copy (`$ENV{PAR_0}`, two lines longer) when `__FILE__` is
not on disk; only `read_and_process_logs` from its `while (1) {` to the loop's
closing brace kept; each `#@<op> <expression>` marker (`when`, `and`,
`unless`, `true`, `false`) evaluated once per run and its gate resolved; a
dropped line left empty so line numbers survive under one `#line N
"<__FILE__>"` directive; a known-true arm kept as `if (1) {` with its own
scope. The generator subs sit together under a `## GENERATED READ LOOP ##`
section marker before `read_and_process_logs`. A marker that misses is a
mismatch (D7).

**Drop 2, fallback and exit status (confirmed 2026-10-13).** The fallback
notice goes through the behavioural-notice mechanism
(`docs/architecture-patterns.md` § Behavioural notices, deferred while
progress owns the terminal): queued with `defer_notice()`, since the decision
is taken while the read pass owns the terminal, printed by
`flush_deferred_notices()`, once per run (amended by #412: raised through
`notice()` as `read-path-fallback` and drawn in the notices panel; the two
subs are gone). Its text, in user terms: "Note: the
faster read path could not be prepared, so large files are read with the
standard path, which is slower". The reason (source unreadable, marker
mismatch, compile failure) is recorded in `-V read-path` only. Generation and
the compile run under `local $!` and `local $@`, so the error state after
them is what it was before: a `die` in the loop exits with the same status on
both paths (§ 5 measured 25 against 1, `$!` left set by the generator's file
reads) and names the same line under the `#line` directive.

**Drop 2, observability.** The section is `-V read-path`, named for the
feature as the user knows it (`-D`'s text says the standard path, the notice
the faster read path), and its harness `tests/validate-read-path.sh`. Section
contract, in the content shape of `tests/HARNESS-DESIGN.md`:

```
=== read-path ===
threshold_bytes: 2097152 (default)      # (option) when --generated-loop-threshold set it
standard_path_forced: no                # yes under -D
generated_text: written                 # written | not_needed | failed
fallback_reason: -                      # - | source_unreadable | marker_mismatch | compile_failure
file: <path>
  size_bytes: <bytes>
  path: generated                       # generated | standard
  reason: above_threshold               # above_threshold | at_or_below_threshold | forced_standard | fallback
marker: <source line> op=<op> kept=yes  # one per marker; kept: the code under it stays in the generated body
=== END read-path ===
```

The marker lines serve criterion 7's coverage check: every marker shows
`kept=yes` in at least one shape, whatever its operation. A marker is named by
its source line, stable within one build; its expression is not printed. A
marker inside a block another marker dropped is never resolved and is not
listed, so the coverage check counts the markers from the source (77), not from
the section. The threshold option is a row of `@quantity_options` (kind
`bytes`, a size with `min => 0`): a bare number is bytes, a byte unit is
accepted (`2MB`), and a fraction, a negative or a non-number stops the run with
"Invalid --generated-loop-threshold '<text>': <problem>" and exit 1. The
text writing and every compile are summed into a `benchmark-data` row, `TIMING
read/path_generation`, in the way `detect/scan_sub_compile` sums the scan-sub
compiles. The section joins the reserved-names list of
`tests/HARNESS-DESIGN.md` in the commit that adds it.

**Drop 3, what the identity harness found.** `tests/validate-read-path.sh`
compares raw output, colour escapes included, over 52 option shapes, and
requires every marker counted from the source to be kept by one of them. Three
things surfaced, none visible to the prototype's comparison:

- **Five wrong markers, inherited from `markers.tsv`.** `#@when
  $highlight_active` stood above five blocks testing `$line_is_highlighted`
  (the highlighted heatmap and histogram values, thread-pool threads, sessions
  and users). `when` unwraps its block when true, so under a highlight the
  generated body counted every line as highlighted; only the highlighted
  shading of those cells showed it. Corrected to `#@false !$highlight_active`,
  which drops the block without a highlight and keeps its per-line test with
  one. The generator now refuses the class (D7): a `when` above a block whose
  condition is not its expression is a mismatch.
- **An `and` term at the end of its line**, its `&&` opening the next line
  (the highlight decision), which the prototype kept silently and D7 then
  refused. The generator removes the term and the `&&` across the two lines;
  a term that is not in its condition stays a mismatch.
- **Six gates no shape switched on**: the index capture and its nanosecond
  arm (the shapes ran with `-ni`), the progress repaint (every run had
  `--disable-progress`), the message-statistics bin arm inside grouping, the
  highlighted raw heatmap values and the highlighted thread-pool threads. Five
  shapes added, an `-idx` shape run without `-ni` and one run with progress on.

Criterion 12 is assertable after all: the harness injects a warning and a
`die` into a copy of `ltl` and asserts both paths report the statement's
source line and exit alike. Proven to fail: a marker naming the wrong flag
(output differs in the highlighted session counts), a misplaced `when` (every
shape falls back), a marker that can never be true (coverage fails).

**Drop 4, the second pass.** Ten harnesses read `ltl`'s source through
`$LTL` (`grep`, `perl -ne`, `perl -`), so `LTL` points at a copy of `ltl` whose
one difference is a default threshold of 0, not at a wrapper adding the
option: the source readers read the same source, every run takes the generated
body, and each harness still changes by one line (`LTL="${LTL:-$REPO_DIR/ltl}"`,
48 of them). The shared CSV cache runs its own `ltl` path, so its line takes
the override too, and it is cleared between the passes because its key does
not record which `ltl` filled it. `tests/validate-read-path.sh` stays on the
script in both passes. Procedure: `docs/process/workflow.md` § 5, step 4.

**Drop 5, the release-build check.** `build/verify-read-path.sh <fixture>
<command>` runs a packaged binary on the committed
`tests/fixtures/access-classification-buckets.txt` (15 lines of web-server
access log) with `--generated-loop-threshold=0 -V read-path` and fails unless
the body was written and every file reports the generated path. Each package
script calls it beside its existing `--version` check, so the release workflow
runs it through the scripts its jobs call (D5 placed it in the jobs; the
scripts are where the binary is already run). That covers the Linux arm64
binary too, which its script already runs under emulation. Shown to reject a
run under `-D`.

**Completion gate (615bd8a, 2026-10-13).** The `after` benchmark against the
`before` of c039396, three runs each, medians with ranges:

| benchmark test | before | after | change |
|---|---|---|---|
| `single-day-access-log-standard` | 6.239 s (6.230 to 6.287) | 5.217 s (5.124 to 5.226) | −16.4 % |
| `single-day-application-log-standard` | 3.126 s (3.104 to 3.173) | 2.684 s (2.657 to 2.689) | −14.1 % |
| `multi-day-application-logs-standard` | 6.965 s (6.928 to 7.094) | 6.143 s (6.084 to 6.287) | −11.8 % |
| `single-day-access-log-heatmap-histogram` | 8.844 s (8.842 to 8.889) | 7.916 s (7.831 to 8.011) | −10.5 % |

Criterion 11 holds. Peak memory rose 0.2 to 0.6 MB (median +0.55 % on the
access log, +1.24 % on the application log, 47.50 to 48.09 MB): the compiled
body held beside the inline loop's code while a file is read, the fixed price
§ 5 measured (0.5 to 2 MB), not a per-line cost. The full suite, 50 harnesses,
exits 0 with assertions run (1,114 s); the second pass on the generated path,
run once for this issue before D3's amendment, also exits 0 on all 50 (1,111 s).

**Observation, pre-existing.** A size row of `@quantity_options` accepts a
negative: `-n -1` exits 0. The threshold refuses one through its own `min`;
the other size options are unchanged. Filed as #726 (-n and -gc accept a
negative value).

**Drop 2, records.** `docs/architecture-patterns.md` § Generated code
compiled from source strings gains the fifth consumption site and its status
line in the commit that adds the generator; `-D, --debug` gains its
`print_help()` row and `docs/usage.md` row in the commit that adds the option.

## Acceptance criteria

Agreed with the architect 2026-10-13, for #721. `-V read-path` is a new
section reporting, per file, its size, the threshold in effect, the path
taken, the fallback reason if any, and each marker's resolution; its harness
is `tests/validate-read-path.sh`.

| # | condition and observable outcome | state | verified by |
|---|---|---|---|
| 1 | With no options, a file above 2,097,152 bytes is read by the generated body; a file at or below it by the inline loop. | assertable | `-V read-path` reports the default threshold; a fixture of N bytes is read inline at threshold N and generated at N−1 |
| 2 | With `--generated-loop-threshold=0`, every file with at least one line is read by the generated body. | assertable | `-V read-path` |
| 3 | Under `-D`, every file is read by the inline loop, including with `--generated-loop-threshold=0`. | assertable | `-V read-path` |
| 4 | In a run over several files of different sizes, each file takes its own path, and the output equals an all-inline run. | assertable | `-V read-path` and the identity comparison |
| 5 | A threshold value that is not a non-negative integer stops the run with an error naming the option. | assertable | exit status and stderr |
| 6 | `-D, --debug` has a `--help` row and a `docs/usage.md` row; `--generated-loop-threshold` appears in neither. | assertable | `tests/validate-help-content.sh` |
| 7 | Over an option-shape set in which every marker's gate is switched on by at least one shape, the output with the threshold at 0 is byte-identical to the `-D` output. | assertable | `validate-read-path.sh`, failing when any marker is never switched on (`-V read-path` marker resolutions). Outputs compared, every one the loop feeds: standard output; the STATS and MESSAGES CSVs; the YAML aggregate export; the run index row (`ltl-index.csv`); every `-V` section; timing and memory rows excepted |
| 8 | No runtime warning on either path, on every identity shape. | assertable | `tests/lib/runtime-warnings.sh` |
| 9 | A run that stops with an error exits with the same status and message on both paths (§ 5 measured 25 on the generated body against 1 on the inline loop). | assertable | an error case run on both paths |
| 10 | The format scan-sub compile count is the same on both paths; the generated body's own cost is reported in its own timing row, not in `format_scan_subs`. | assertable | `-V format-registry`, `-V benchmark-data` |
| 11 | Above the threshold the measured saving holds: the access-log and application-log days are each at least 12 % faster than `before`, median of three. | assertable | the `after` benchmark against the four `before` tests of § 9 |
| 12 | A warning or `die` in the generated body names its source line, as on the inline loop. | assertable | `validate-read-path.sh` injects a warning and a `die` into a copy of `ltl` |
| 13 | No loop block exists twice in the source. | review | the diff |
| 14 | When the generated body cannot be prepared for a file, that file is read by the inline loop, one notice prints on stderr for the run, `-V read-path` records the reason, and the output equals the `-D` output (D4). | assertable | `validate-read-path.sh` on a copy of `ltl` with one marker altered so it no longer matches its code |
| 15 | At the release gate the full suite passes a second time on the generated path, and `docs/process/workflow.md` § 5, step 4, says so (D3). | assertable | the release gate's second pass; each of the 48 harnesses that set `LTL` lets it be overridden |
| 16 | The release build fails when a packaged binary it runs does not report the generated path on the committed fixture (D5). | assertable | the new step, its check shown to reject output reporting the inline path (`-D`) |
