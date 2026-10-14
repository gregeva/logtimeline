# Analysis — #621, pricing the generated read-loop body

Runs 2026-10-13, one host (Apple M1 Pro, Homebrew Perl 5.44.0), base `ltl` at
`621-generated-read-loop-body` ff14d63 (`release/0.19.0` 524a66d plus the
version stamp). The hypotheses are `hypothesis-generator.md` beside this file,
written before the first measurement. Probes from
`prototype/621-remaining-loop-bound/make-generated.pl` and `markers.tsv`;
timing by `prototype/342-read-loop-cost-curve/run-curve.sh` and, for the run
over many files, `run-files.sh`; summaries by `summarise-pairs.py`; identity
by `prototype/616-observation-count-arms/prove.sh` with the hash seed fixed.
Raw rounds: `generated-staged.tsv`, `generated-files.tsv`.

## What was built

**Markers.** 77 marker comment lines above the loop's gates (`markers.tsv`:
53 `when`, 17 `and`, 4 `unless`, 2 `false`, 1 `true`). Each names the
expression, fixed for the run, that decides its gate. They are comments, so
the inline loop compiles to the base's code.

**Generator.** About 150 lines of Perl added before `read_and_process_logs`:
stream the program's own source, keep the loop's lines, resolve each marker
by evaluating its expression once, and return the text of an anonymous sub
holding the loop. A dropped line is blanked, so the text keeps the source's
line numbers and one `#line` directive maps the body back to the source. An
arm whose condition is known true keeps its scope as `if (1) {`: Perl folds
the constant test away, the arm's declarations stay its own, and unlike a
bare block it is no loop, so `next` and `last` still mean the read loop. The
first build blanked those braces instead; the `-idx` shape then warned that
`my $fd` masked an earlier declaration (two index blocks unwrapped into one
scope), which is what fixed the rule.

**Placements.** *Per file*: the body is compiled inside the per-file loop and
closes over the file's own variables where they are declared; 3 lines of
`read_and_process_logs` change (the compile, and the switch around the inline
loop). *Per run*: compiled once before the per-file loop; the 13 per-file
variables the loop reads are declared before it and reset at each file's
start; 29 lines change. `LTL_GENERATED_LOOP=0` runs the inline loop instead.

On the default options the generated body is code-identical (comments and
blank lines aside) to the hand-specialised loop measured in `analysis.md`
§ The specialised loop; 64 markers resolve (49 dropped, 9 terms removed, 3
modifiers removed, 3 unwrapped), the rest sitting inside dropped blocks.

## Identity over option shapes (H4)

46 option shapes on 20,000-line slices of five families (the day of access
log, the thread-and-session access log, the application log, the script log
carrying counts and durations, a CSV of metrics), chosen so every marked gate
is switched on at least once: no messages, grouping, the grouping section,
heatmap and histogram in both data models, regex, numeric and outcome
highlights, include and exclude, absolute and time-of-day windows, profile,
outcome and numeric filters, `-du`, the bin models, `-o`, the three omits,
millisecond buckets, nanosecond precision, `-idx`, `-mem debug`, mask, expose
and discard, `-so bytes`, hidden session and user columns, thread-pool
activity and summary, user-defined metrics in the loop, the heatmap, grouping
and a CSV. Terminal output, the STATS and MESSAGES CSVs and the aggregate
export, compared byte for byte with timing and memory rows removed:

- both placements identical to the base on all 46 shapes, no runtime warning;
- the one difference seen in some runs is `-mem debug`'s memory attribution
  rows (unattributed 42 against 43 MB): the generated build's peak is higher
  (below), not a content difference.

The comparison of the base and one generated build over the 46 shapes takes
57 s on this machine.

**A pre-existing defect found on the way.** On the script log,
`-udm durationMS::max -hg -h Things` ends the run with "Can't use an undefined
value as an ARRAY reference" in the histogram drawing, on the base as on the
probes: a histogram of a user-defined metric under a highlight. Not caused by
this work; that shape was replaced by two that avoid it.

## Speed (H1, H2)

Ten order-balanced rounds; per-round delta against the base, median (range):

| selection | base median | hand-specialised | generated, per file | generated, per run |
|---|---|---|---|---|
| access, 1,000 lines | 0.052 s | −1.98 % (−7.94 to +3.92) | **+12.88 %** (0.00 to +20.63) | **+7.63 %** (+1.59 to +17.65) |
| access, 10,000 lines | 0.128 s | −15.62 % | −9.40 % (−14.29 to −5.56) | −8.43 % (−12.12 to −4.07) |
| access, 100,000 lines | 0.861 s | −19.12 % | −17.12 % | −16.73 % |
| access, 761,698 lines | 6.260 s | −19.57 % (−21.89 to −18.54) | **−19.02 %** (−22.80 to −16.39) | **−18.03 %** (−21.14 to −14.62) |
| application, 1,000 lines | 0.051 s | −3.85 % | **+9.72 %** (−5.08 to +27.08) | **+11.25 %** (0.00 to +14.58) |
| application, 10,000 lines | 0.107 s | −9.86 % | −3.65 % (−7.14 to +6.42) | −2.82 % (−5.36 to +8.04) |
| application, 100,000 lines | 0.683 s | −15.02 % | −14.43 % | −14.99 % |
| application, 479,904 lines | 3.178 s | −17.23 % (−21.85 to −11.98) | **−16.51 %** (−22.00 to −14.37) | **−16.82 %** (−23.50 to −12.75) |
| application, 41 files, 315 MB | 7.236 s | −14.30 % (−18.23 to −11.88) | **−12.66 %** (−18.92 to −10.95) | **−12.81 %** (−23.99 to −10.91) |

Faster than the base in 10 of 10 rounds at 100,000 lines and above on every
selection, for both placements.

**The fixed cost.** Generation is about 5.3 ms (reading the source to the
loop 2.6 ms, resolving the markers the rest) and the compile 1.5 ms, once per
run; per file, the compile repeats: 41 compiles cost 63 ms in all on the
41-file run. A first build whose brace matcher split every line into
characters for every marker took 15 ms to generate; it was replaced before
these rounds (its rounds are not kept).

**H1 holds within about 1.6 points**: the generated bodies read 0.6 to 1.5
points short of the hand-specialised loop on the full files, inside the
rounds' spread; what the gap consists of was not measured. **H2 holds**: generation costs
about 7 ms, so a generated body is slower than the base only at the smallest
scale; between 1,000 and 10,000 lines it crosses over, and the per-file
compile costs the 41-file run under 2 points against compiling once.

## Memory

Peak resident size, medians: on the full access log 98.2 MB base, 100.0 MB per
file, 99.9 MB per run; on the full application log 44.8, 45.1 and 45.2 MB; on
the 41 files 110.4, 110.1 and 111.2 MB; on a 20,000-line slice, three runs
each with the hash seed fixed, 44.6 to 45.1 MB base against 45.3 to 45.8 MB.
The generated build holds the inline loop's code as well as the generated
body's: about 0.5 to 2 MB more at peak.

## Errors in evaluated text (H3)

A warning and a `die` injected after the every-included-line point, run on a
1,000-line slice:

| build | warning reports | `die` reports | harness check (` at .+ line N`) |
|---|---|---|---|
| inline loop | `at <source> line 17852` | `at <source> line 17853` | caught |
| generated, `#line` directive | `at <source> line 17852` | `at <source> line 17853` | caught |
| generated, no directive | `at (eval 173) line 606` | `at (eval 173) line 607` | caught |

With the directive, a defect in the generated body names the same file and
line as the inline loop. Without it the harnesses still catch it, but the
line points into evaluated text. One difference remains with the directive:
the `die` exits with status 25 against the inline loop's 1; a `die`'s exit
status is whatever `$!` holds when it fires.

NYTProf on a 10,000-line slice attributes the generated body's statements to
the source's lines with the directive (87 statements per line, at the loop's
own line numbers, so `loop-line-counts.pl` reads it unchanged); without it they
land in an `(eval N)` entry of their own.

## A marker that is wrong (cost 4)

Two deliberate errors, run over the shapes that reach them:

- **a declaration marker too narrow** (`my %udm_values` kept only for
  `-udm`): every shape that keeps a block using it, the heatmap and the
  histogram, ends at generation with `Global symbol "%udm_values" requires
  explicit package name`, naming the source line. Loud, at run start.
- **a gate marker naming the wrong flag** (the histogram block marked with the
  heatmap's flag): on a histogram run with no heatmap the histogram is
  silently missing from the output; on a heatmap run with no histogram the
  body fails to compile (a declaration it needs was dropped). The silent case
  is caught only by the identity comparison on a shape that turns the gate on.

So every marker needs a shape in the identity set that switches its gate on,
and a marker's expression has to be kept true to its gate as the code changes.

## The packaged binary (H5)

PAR::Packer could not be installed here: the network proxy returns an HTML
block page in place of the Archive-Zip distribution it depends on. From PAR's
source (`PAR.pm` `_run_member`, the release cpanm fetched): a packed binary
extracts the script to a temporary file, prepends `package main;` and
`#line 1 "script/ltl"`, names that file in `$ENV{PAR_0}`, and runs it. So
`__FILE__` is `script/ltl`, not a file on disk. The generator reads
`$ENV{PAR_0}` when `__FILE__` does not exist and shifts its line numbers by
the two prepended lines. That layout simulated (the probe run by `do` from
such a file, `PAR_0` set): the generator ran, output identical to a direct
run, and an injected warning reported `script/ltl line 17858`, the statement's
line. Not verified in a packed binary.

## The four costs, priced

| cost | price measured |
|---|---|
| 1, the body becomes text assembled from pieces | The source stays one inline loop; the generator (about 150 lines) writes the body from it at each run in about 5.3 ms, plus 1.5 ms to compile. No piece is written twice. |
| 2, a defect reports inside evaluated text | With one `#line` directive and blanked (not removed) lines, warnings, `die` messages and NYTProf all name the source file and line, as the inline loop does; the harnesses' runtime-warning check catches either way. |
| 3, the loop's lexical state moves | Not necessarily: compiled per file, nothing moves (3 lines change) at one 1.5 ms compile per file; compiled per run, 13 per-file variables move out of the per-file loop (29 lines change). Speed is the same within the rounds' spread. |
| 4, every feature block becomes an includable piece | 77 marker lines in the loop; no block is moved or copied. A marker kept true to its gate is the maintenance; a wrong one fails at generation when it breaks a declaration, and silently when it misnames a gate, which only the identity comparison over a shape switching that gate on catches (46 shapes, 57 s). |
| memory | 0.5 to 2 MB more at peak: the inline loop's code is held as well as the generated body's. |
| small inputs | about 7 ms per run: slower than the base at 1,000 lines (+8 to +13 %), faster at 10,000 (−3 to −9 %); the crossing point between them was not measured. |
| packaging | Reading the source needs a branch for PAR's extracted copy; simulated, not run in a packed binary. |
