# Hypothesis — #621, pricing the generated read-loop body

Written 2026-10-13T15:27Z, before any of the measurements below.

## What is being investigated

The direct measurement (`analysis.md` § The specialised loop) gives the prize:
a loop specialised for the default options runs 20.5 % faster on the day of
access log and 15.2 % faster on the day of application log. That loop was
written ahead of time by a prototype script for one option set and guarded
against every other. The issue records four costs against producing such a
body at run time, none of them priced yet:

1. **The loop body becomes text assembled from pieces.**
2. **A defect in the generated body reports inside evaluated text.**
3. **The loop's lexical state moves to where generated code can reach it.**
4. **Every feature block becomes an includable piece.**

This prototype builds the mechanism the costs belong to and measures each.

## The candidate mechanism

The inline loop stays the one source and the reference (the architect's
framing on the issue). Each gate in it carries a marker comment on the line
above, naming the run-constant expression that decides it. At run start a
generator reads the loop's text from the program's own source, evaluates each
marker's expression once, and writes the body for that run:

- `#@when EXPR` above an `if` block whose whole condition is `EXPR`: true keeps
  the arm and drops its test and the other arms; false drops the arm and keeps
  the `else` arm, or turns an `elsif` into the `if`.
- `#@when EXPR` above a statement: false drops the statement; true keeps it.
- `#@and TERM` above a block or statement whose condition is `TERM && rest`:
  false is treated as `#@when` false; true removes the term's text.
- `#@unless EXPR` above a statement carrying `unless EXPR`: true drops the
  statement; false removes the modifier.

A dropped line is blanked, not removed, so the generated text keeps the
source's line numbers and one `#line` directive points every line of the
generated body back at the source line it came from. The body is compiled
with a string `eval` as an anonymous sub and called in place of the loop.
The markers are placed by a script for the prototype, at the sites the
direct measurement's 56 edits found; in production they would be written in
`ltl`.

Two placements of the compile, which differ in cost 3:

- **per file**: compiled inside the per-file loop, after the file's own
  variables are declared, so the sub closes over them as they are; nothing
  moves, one compile per file.
- **per run**: compiled once before the per-file loop; the loop's 13 per-file
  variables (the file handle, the file name, the line number, the window
  replay state, the scan telemetry, the classification binding, the CSV
  header state, the index record and the progress size) move out of the
  per-file loop and are reset at the start of each file.

## Hypotheses

**H1 (generated code runs as fast as inline code).** A body compiled from text
by `eval` runs at the speed of the same body compiled inline: the op tree is
the same, and closed-over variables are read from a pad as the inline loop's
are. Predicts: on the full benchmark files under the default options, per-file
and per-run generated bodies each within ±1.5 % of the inline specialised loop,
and so about 20 % and 15 % faster than the base.

**H2 (generation costs milliseconds, once).** Reading the source, applying the
markers and compiling about 1,300 lines costs under 20 ms. Predicts: the
generated body is slower than the base only at the smallest scale: at 1,000
lines (a few tens of milliseconds of run time) the compile is a visible share;
from 10,000 lines on the saving dominates. Per-file compilation adds the
compile once per file, so on a run over 41 files it costs up to 41 × that.

**H3 (error reports).** A warning or `die` raised inside the generated body
without a `#line` directive reports `at (eval N) line M`; with the directive
it reports the source file and the source line, the same text the inline loop
gives. The harnesses' runtime-warning check (` at .+ line [0-9]+`) catches
both forms. NYTProf attributes the generated body's statements to the source
lines only with the directive.

**H4 (the generator handles every option set).** With markers in place the
generated body is byte-identical in output to the base on every option shape
that reaches a marked gate, not only on the default; option shapes that turn
gates on keep those blocks and recover less.

**H5 (the source runs in the packaged binary).** The generator reads the
loop's text from the program's own file. In a PAR-packed binary the script
is not a plain file on disk; the source is reachable through PAR's archive.
Predicts: a packed probe either reads its source by `__FILE__` or needs one
fallback through PAR, and either way generates the same body.

## Measurements

| cost | measured by |
|---|---|
| 1, text from pieces | the generator's size; the time to read and specialise the source per run; the body it writes for the default options compared with the direct measurement's |
| 2, errors in evaluated text | an injected warning and an injected `die` in a kept statement, inline and generated with and without `#line`; the runtime-warning check over each; NYTProf line attribution of the generated body |
| 3, lexical state | the per-file and per-run placements: variables moved, lines changed in `read_and_process_logs`, timing of each |
| 4, includable pieces | markers needed and their kinds; the identity of the generated body's output with the base over option shapes covering every marked gate; a marker deliberately wrong, to see how it fails |
| H1, H2 | ten order-balanced rounds of the base, the inline specialised loop and both generated placements at 1,000, 10,000, 100,000 lines and the full file, on both benchmark files; and over the 41 files of the multi-day application log selection |
| H5 | a packed binary of the generated probe, run on a slice |

The time-window gate's marker compares the bounds with their unbounded
values, the literals of `%filter_range_epoch`'s declaration in `ltl`'s
globals, restated in the marker with that symbol named beside them.
