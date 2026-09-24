# Feature: programmatic console screenshot capture (#598)

## GitHub Issue

[#598](https://github.com/gregeva/logtimeline/issues/598): Enhancement: programmatic
console screenshot capture for documentation (development tooling).

Builds on [#597](https://github.com/gregeva/logtimeline/issues/597) (section
visibility and the `-V section-layout` report), shipped in 0.18.4 and specified in
`features/597-section-visibility.md`.

## Motivating consumer

The documentation. Its screenshots are captured by hand (`images/` holds 16 hand-captured PNGs; `README.md` shows two), so there are few of them and they go stale. A
screenshot defined in code (command line, input files, terminal geometry, target
region) is regenerated at every release and stays current without manual effort.
This is development and release tooling, not shipped with `ltl`.

## Requirements

As filed on the issue, in three parts, plus a fourth added in specification:

1. **Capture tool.** Perl (D4, superseding PowerShell as filed), one implementation;
   `ltl` run on Linux and macOS (D15).
   Takes a full `ltl` command line and produces one or more images from a single
   execution. Terminal width and height default to 211 x 53 and are overridable (D11). Crops are in terminal cells, never pixels: a target section plus
   lines before and after it, positioned relative to the section start lines `ltl`
   reports on `-V`. Two runs: a `-V` probe run for the start lines, then a clean
   render run. Output taller than the terminal is handled by hiding or bounding
   sections, never by scrolling back.
2. **Batch processor.** Reads a manifest, separate from the page map in
   `build/sync-wiki.sh`, listing every screenshot: command line, input files,
   geometry overrides, crops, output image names.
3. **Release step.** Beside `build/sync-wiki.sh`; runs the batch processor, and the
   images are committed before any documentation update that references them.
4. **Guidance for agents** (architect, 2026-09-24). Documentation written for
   machine and AI use, not for end users, explaining the intended and appropriate
   use of the tooling to create screenshots across scenarios and use cases, and
   setting the expectation that any screenshot requested for documentation is
   generated this way and added to the manifest and the automated refresh and
   rebuild pipeline.

## What this issue takes from #597

- Line positions come from the `-V section-layout` report, measured as each section
  prints and printed after the run's last row (#597 D3), so the probe run and the
  capture run agree when the rendered output is identical.
- Sections are removed with the `hide` options (#597 D1).
- The recipe's terminal width and height reach `ltl` through `--terminal-width` and
  `--terminal-height` (#597 D15), so defaults `ltl` derives from the terminal size
  (bucket size, histogram height) match a real terminal of that size.
- Rows are counted from the first row the run prints, as the run prints without
  `-V` (#597 D6), so positions read from the probe run apply to the capture run.
- One blank row separates sections and belongs to neither (#597 D5).

## Decisions

**D1: images are rendered from the captured ANSI output** (architect, 2026-09-24),
not captured from a terminal window. The render run's standard output is parsed into
a grid of cells (character, foreground, background, attributes) and the cropped cell
range is drawn to an image. The same input yields the same image on macOS and
Windows, needs no visible window, and a crop in cells is a slice of the grid. The
renderer's font and colour table set the look; the font must carry the block and
box-drawing characters `ltl` prints.

**D2: a crop is sections plus a start and an end offset** (architect, 2026-09-24).

| Part | Meaning | Example |
|---|---|---|
| sections | one section, or several in print order; the crop spans from the first one's start row to the largest last row among them, including the blank rows between. Side-by-side parts share a start row, so for `summary-values,summary-files` the longer of the two sets the end (architect, 2026-09-24) | `timeline,histogram` |
| start offset | rows relative to the first section's start row; negative reaches above it, positive skips into it | `+15` skips the first 15 timeline rows; `-5` starts 5 rows above the timeline |
| end offset | rows relative to that largest last row, same sign convention; default `0` | `-2` stops 2 rows before the histogram ends |

Start rows and row counts are read from `-V section-layout` (#597 D13). Anything
printed between the named sections is part of the crop; leaving it out means hiding
it with `--hide`. A crop naming a section the report gives as `hidden` or `absent`
is an error, not an empty image.

**D3: columns are absolute, measured from the edges** (architect, 2026-09-24). A
crop may give a left and a right position. Left counts from the left edge, which is
0; right counts from the right edge, which is the terminal width, so a negative
value reaches inward. Anything not given means the full width. At
`--terminal-width 200`, `100, -25` captures 75 cells starting at the middle
(cells 100 to 175). A positive right position is instead a width counted from the
left position (architect, 2026-09-24): `50, 25` captures 25 cells starting at cell
50, a bounded size that a position pulled back from the right edge cannot give. The
left position cannot be larger than the terminal width. Column positions hold only while the terminal width is fixed,
which every screenshot definition sets. Columns anchored to positions `ltl` reports,
as rows are, are [#599](https://github.com/gregeva/logtimeline/issues/599), filed as not planned.

**D4: the tool is written in Perl, not PowerShell** (architect, 2026-09-24),
superseding the platform line as filed. PowerShell was chosen to capture the
console window; with D1 nothing is captured from a window, and .NET's bundled
imaging (`System.Drawing`) is supported only on Windows. Perl is `ltl`'s own
language and toolchain; one implementation runs wherever `ltl` is developed. The
platforms are D15.

**D5: screenshots are SVG** (architect, 2026-09-24). Written as text, so no imaging
module is needed, and a release's screenshot changes are readable in its diff.

**D6: prototype the rendering first** (architect, 2026-09-24). Before anything is
built on it, a prototype under `prototype/` proves that `ltl`'s ANSI output renders
faithfully to SVG: the block and box-drawing characters align cell to cell, the
colours match, and the result displays correctly where the documentation is read.

**D7: the background is an input** (architect, 2026-09-24). `ltl` detects a light or
dark terminal background and chooses its colours from it (`-lbg, --light-background`,
`-dbg, --dark-background` force either). A screenshot states `dark` or `light`;
stating it is best practice but not required, and a screenshot that does not state
it is `dark`, in the manifest and on the tool's command line alike (architect,
2026-09-24). The tool forces the background on `ltl` rather than letting it detect,
and draws the image on the matching background.

**D8: the manifest is YAML** (architect, 2026-09-24), read with `YAML::PP`, which
`ltl` already depends on. It is edited by hand, and YAML carries a comment beside
each screenshot saying what it is for.

**D9: screenshots are made from the log files on the development machines**
(architect, 2026-09-24), the `logs/` corpus the release is run from, not only from
committed fixtures. The architect selects the files and the narrative so the
documentation exposes nothing sensitive.

> **Warning: sensitive data in screenshots.** The repository and its documentation
> are public. Everything `ltl` renders is metrics and counters except the
> **messages** section (message text, which can carry host names, user names, paths
> and identifiers) and possibly the **file names** in the summary's file list. A
> screenshot showing either is checked for sensitive content before it is
> committed; hiding the section (`--hide`) or cropping it out removes it.

**D10: locations** (architect, 2026-09-24).

| What | Where |
|---|---|
| the tool | `build/capture-screenshots.pl`, release tooling beside `build/sync-wiki.sh` |
| the manifest | `build/screenshots.yaml`, beside the tool that reads it; hand-edited source is kept apart from generated output |
| the images | `images/screenshots/*.svg`, generated output only, in a subfolder of the repository's existing `images/` so regeneration never touches the hand-captured screenshots there |
| input paths in the manifest | relative to the repository root (`logs/...`), so one recipe resolves on every development machine |

**D11: default terminal size 211 x 53, overridable twice** (architect, 2026-09-24),
superseding the filed default width of about 200 columns. 211 x 53 is the size a
full timeline is read at (see *Terminal sizes in real use*); at 53 rows `ltl`
defaults to 60-minute buckets and a 7-row histogram. A screenshot in the manifest
may set its own size, and the tool's command line may set one for a run; the
command line takes precedence over the manifest, the manifest over the default.
237 x 62 is the override for a picture that needs more detail.

**D12: where the agent guidance lives** (architect, 2026-09-24), for requirement 4:

| Layer | Content |
|---|---|
| `docs/process/screenshots.md` | the guidance: when to use the tool, writing a manifest entry, choosing sections and offsets, the sensitivity warning, the refresh pipeline |
| a row in the `CLAUDE.md` *Where to look* table | creating or changing a documentation screenshot points at `docs/process/screenshots.md` |
| a path-scoped rule in `.claude/rules/` on `images/screenshots/**` and `build/screenshots.yaml` | images are generated, never edited by hand; a new screenshot is a manifest entry plus a regeneration |

**D13: run-varying figures are accepted** (architect, 2026-09-24). The summary's
`TOTAL TIME` and `MAXIMUM MEMORY USED` differ on every run, so an image showing them
changes at every release even when nothing else has. That is accepted; the noise is
confined to the images that show the summary's values.

**D14: every character is drawn as font text** (architect, 2026-09-24). Block and
box-drawing characters included, in the viewer's monospace font, each run of
characters held to its cells' width. Terminal.app does not draw a full block over the
whole line height, so rows keep the gap between them that Terminal.app shows; drawing
blocks as rectangles filling the cell, compared in the rendering prototype, does not
match it. The look on Windows depends on the viewer's font (Consolas).

**D15: the tool runs on Linux and macOS, not Windows** (architect, 2026-09-24),
superseding the macOS and Windows requirement as filed. It is run mostly on Linux
and macOS, in a pipeline. Criterion 9 compares Linux with macOS.

**D16: `ltl` runs in the repository root, and its output files are removed
afterwards** (architect, 2026-09-24). Input paths in a recipe are relative to the
root (D10) and print in the summary's file list as written. After each run the tool
deletes `*.csv` and `*.yaml` at the top level of the repository root, which is
where `-o` writes; both patterns are ignored by git (`*.csv`,
`*-LTL-AGGREGATE.yaml`), so nothing a run writes is committed.

## Capture tool design (agreed with the architect, 2026-09-24)

**Command line.** One ad hoc run mirrors one manifest entry, in the same words:

```
build/capture-screenshots.pl --name BASE [--background dark|light]
                             [--width N] [--height N] [--out-dir DIR]
                             [--crop 'sections=A[,B] start=±N end=±N cols=L,R label=LABEL'] ...
                             -- <ltl options and input files>
```

- Everything after `--` is the `ltl` command line, passed through.
- Each `--crop` is one image; repeated, it yields several from one execution.
  `sections`, `start` and `end` are D2 (`start` and `end` default to 0); `cols` is
  D3 (default: the full width). A crop without `sections` is the whole output.
- No `--crop`: one image of the whole output.
- Names compose in layers (architect, 2026-09-24): the recipe, its sections, a part
  within them. `--name BASE` is required; each image is `BASE[-sections][-label].svg`,
  the sections joined with `+` in print order, `label` optional. The whole output
  is `BASE.svg`; `sections=timeline start=+15 label=peak` is
  `BASE-timeline-peak.svg`. Two crops composing the same file name are an error
  naming both; a label tells them apart. Nothing is numbered, so reordering crops
  renames no file.
- Size: 211 x 53 by default (D11); `--width` and `--height` override it, and the
  manifest in batch mode.
- `--background`: D7, `dark` when not given.
- `--out-dir`: the current directory by default. Ad hoc runs never write to
  `images/screenshots/` (D10).

**Running `ltl`.**

- The checkout's own `ltl`, run by the Perl that runs the tool.
- `LTL_CONFIG`, `FORCE_COLOR` and `NO_COLOR` are removed from its environment.
- Both runs get `--terminal-width W --terminal-height H`, `-dbg` or `-lbg`,
  `--disable-progress` and `-ni` (no index file written into the working
  directory); the probe run also gets `-V section-layout`. They show on the options
  row.
- Refused on the passed command line, an error with nothing run: `-tw`, `-th`,
  `-lbg`, `-dbg` (the tool sets them), `-V` (diagnostic output) and `-p` (waits for
  a key).
- `-o` is allowed: output files are part of what a screenshot may show. The files
  it writes are removed after each run (D16).
- Standard output and standard error are each redirected to a file.
- A non-zero exit, or a Perl warning on standard error (` at <file> line <N>`),
  stops the tool with standard error shown and no image written; other standard
  error output is passed through.
- Rows longer than the width are clipped at the width, not wrapped, so row numbers
  stay the reported positions.

**Resolving a crop.**

- Positions come from the probe run's `-V section-layout` rows (name, state, start,
  row count), rows numbered from 1 at the title (#597 D6).
- A crop names sections and parts as the report lists them, in print order.
- Rows: from the first section's start plus `start`, to the largest last row among
  the named sections plus `end` (D2).
- Columns: `cols=L,R` per D3.
- Errors, each naming the crop and writing no image: an unknown name; a `hidden` or
  `absent` section (criterion 5); names out of print order; a row span outside the
  output or empty after the offsets; `L` negative or larger than the terminal
  width; a positive `R` reaching past the right edge; a negative or zero `R` whose
  end falls at or before `L` (architect, 2026-09-24).
- The capture run must print as many rows as the probe run, or the tool stops: the
  probe's positions would not apply.

**Rendering** (D14), carried from the rendering prototype's text renderer.

- Colour codes build the grid of cells; non-standard codes `ltl` emits (`109`) are
  ignored; any other escape sequence is an error.
- One colour table at the top of the tool: per background, the 16 ANSI colours,
  text, bold and background colours from Terminal.app "Clear Dark" and "Clear
  Light"; indices 16 to 255 by the xterm formula. Different image backgrounds are
  changed there.
- Every character is font text, in runs of one colour and weight broken at blanks,
  each started at its first cell and held to its cells' width by letter spacing.
  Font list `ui-monospace`, SF Mono, Menlo, Consolas, DejaVu Sans Mono; 12 px;
  cells 7.2 x 15.
- Backgrounds are full-cell rectangles with crisp edges, as Terminal.app paints them
  over the full line height; foreground blocks keep the gap between rows.
- Underline is a line across the underlined cells, blanks included.
- The same input yields a byte-identical SVG.

**Output and reporting.**

- Each image is `<out-dir>/BASE[-sections][-label].svg`; `BASE` and labels use
  letters, digits, `.`, `_` and `-` only. An existing file is overwritten.
- Every crop is resolved and checked before any image is written: one bad crop, no
  images from that execution.
- Standard output: the `ltl` command line once, then one line per image with its
  path, rows, columns and sections. `ltl`'s standard error passes through.
- A crop whose rows overlap the messages or the summary's file list gets a notice to
  check it for sensitive content before committing (D9).
- Each SVG carries a comment with its crop and the `ltl` command line, without the
  version, so an image is regenerated from what it says and stays byte-identical
  across releases unless its rendering changes.
- Exit status 0 when every image is written, non-zero on any error.

**Verification** (architect, 2026-09-24). Criteria 1 to 7 are asserted by a suite
harness, `tests/validate-screenshot-capture.sh`, with `--scenario`, on the committed
synthetic fixture: the tool reads `-V section-layout`, so a change to that report
or to `ltl`'s colour output that would break screenshots fails the suite before
merge. Its file name follows the tool, not a `-V` section. A `--trace` option on
the tool prints both `ltl` command lines, the number of runs, and each crop's
resolved rows and columns.

| Criterion | Check |
|---|---|
| 1 | the grid of characters rebuilt from the SVG's text positions equals `ltl`'s output, sliced by the reported positions, offsets and columns |
| 2 | each cell's text and background colour equals `ltl`'s colour code through the colour table; heatmap cells use only the gradient `-V heatmap-palette` reports |
| 3 | tick characters sit at the columns `-V histogram-percentile-ticks` gives |
| 4 | `-dbg` or `-lbg` in the traced command lines, and the matching background fill |
| 5 | non-zero exit naming the section, no file written |
| 6 | `--terminal-width` and `--terminal-height` in the traced command lines, command line over manifest over default |
| 7 | two runs traced, one image per crop |

Criterion 11's pixel check needs Quick Look: it runs on macOS and is skipped on
Linux. With a harness under `tests/`, this issue's completion gate is the full suite
and a before/after benchmark (`docs/process/workflow.md` § 3).

## Finding: what the capture inherits from `ltl`'s output

Measured 2026-09-24 on `release/0.18.4`:

- **The options row echoes the whole command line**, so the probe run's row carries
  `-V section-layout` and the capture run's does not (full-day Tomcat access log, 211
  x 53: row 40 differs in those 19 characters; the only other differences are the
  run-varying `TOTAL TIME` and `MAXIMUM MEMORY USED`, D13). The row is printed
  unwrapped however long it is (`print_run_options()`), and the row count behind
  `-V section-layout` counts it as one row, so a terminal that wraps it shows
  more rows than the report counts.
- **The timeline bars are drawn with a different character on Windows.**
  `$default_chart_block` is the full block (U+2588) elsewhere and the black square
  (U+25A0) on Windows, and no option sets it. A crop showing the timeline bars
  therefore differs between macOS and Windows. The heatmap and histogram draw the
  full block on both. Windows is not a platform of the tool (D15), so no crop is
  compared across it.

## Finding: terminal sizes in real use

Measured by the architect with `tput lines` / `tput cols` in macOS Terminal,
2026-09-24:

| Setting | Columns x rows |
|---|---|
| windowed | 44 rows |
| full screen | 50 to 56 rows |
| zoomed far in | 158 x 40, too small to see a full timeline's detail |
| typical viewing of a full timeline | about 211 x 53 |
| higher resolution and fidelity | about 237 x 62 |

The filed default width of about 200 columns is therefore a starting point only:
the size must be settable per screenshot in the manifest and on the tool's command
line.

## Rendering prototype (D6): reference look

The prototype matches the macOS Terminal.app profiles "Clear Dark" for `dark` and
"Clear Light" for `light` (architect, 2026-09-24): their 16 ANSI colours, default
text colour and background, and font (SF Mono Terminal, 12 pt, line spacing 1.0).
The profiles' backgrounds are translucent (opacity 0.95 dark, 0.93 light) and are
drawn opaque. They are a starting point, not necessarily the right image
backgrounds: a configuration value for the background colour of each of `-dbg` and
`-lbg` is likely to follow (architect, 2026-09-24).

Findings so far (`prototype/598-ansi-svg/findings.md`): drawn as font glyphs, full
blocks do not fill the cell's height, leaving a background stripe between rows in
the timeline bars, the heatmap and the histogram (2,449 of 7,276 edge samples fail
on the dark fixture render). Drawn as rectangles at cell coordinates with crisp
edges, none fail, on dark or light. A pixel check through Quick Look and `sips`
(macOS only, nothing to install) tells the two apart. Pending: the side-by-side
comparison with Terminal.app (criterion 12).

Viewed on GitHub by the architect (2026-09-24): text renders well in both modes; the
timeline bars and the heatmap are poor in geometry mode, while the text-glyph render
is acceptable. The cause (architect, 2026-09-24): Terminal.app does not
draw a full block over the whole line height, so a gap between rows is its expected
rendering; geometry mode fills the line and so does not match it. The pixel check
measured blocks against a full cell, which is the wrong reference for Terminal.app.

## Open questions

None.

## Definition of done (as filed)

The captured images reproduce the rendering that `tests/validate-histogram-ticks.sh`
(percentile tick marks on the histogram x-axis) and
`tests/validate-heatmap-palette.sh` (heatmap colours) assert character by character
and colour by colour. At least one heatmap and one histogram use case, each with a
crop anchored on its section start line, captured on macOS and on Windows.
Changed by D15: captured on Linux and on macOS.

## Acceptance criteria

Criteria 1 to 11 are assertable; 12 is verified by eye. The rendering prototype
(D6) settled 11 and 12, which it held as unknown (`prototype/598-ansi-svg/findings.md`).

- [ ] 1. A crop's cells equal the corresponding rows of `ltl`'s standard output,
      sliced by the reported section positions, the start and end offsets and the
      column positions (for example `+15` / `-2`, and `100, -25` at width 200) (D2, D3).
- [ ] 2. Every cell's foreground and background colour is the one `ltl` printed,
      mapped through the tool's colour table; heatmap cells are checked against the
      gradient `-V heatmap-palette` reports.
- [ ] 3. Histogram tick glyphs sit at the columns `tests/validate-histogram-ticks.sh`
      asserts.
- [ ] 4. `light` runs `ltl` with `-lbg` and draws a light background; `dark` with
      `-dbg` and a dark one (D7).
- [ ] 5. A crop naming a `hidden` or `absent` section fails with an error naming it,
      and writes no image (D2).
- [ ] 6. Size precedence is command line over manifest over the 211 x 53 default,
      observed in the `--terminal-width` and `--terminal-height` passed to `ltl` (D11).
- [ ] 7. One execution yields several crops, with `ltl` run exactly twice per recipe.
- [ ] 8. A batch run regenerates every manifest entry into `images/screenshots/` (D10).
- [ ] 9. The same recipe on Linux and on macOS yields the same crop cells (D15).
- [ ] 10. `docs/process/screenshots.md` exists, the `CLAUDE.md` row points at it, and
      the path rule covers `images/screenshots/**` and `build/screenshots.yaml` (D12).
- [ ] 11. Every character sits within its cell's columns as displayed: the pixel
      check (`prototype/598-ansi-svg/check-alignment.pl`, Quick Look on macOS)
      samples each full block's left and right edges (D14).
- [ ] 12. *(by eye)* The rendered image matches Terminal.app's look on real data,
      block heights and the gap between rows included, which follow the viewer's
      font (D14).
