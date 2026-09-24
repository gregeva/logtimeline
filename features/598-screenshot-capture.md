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
   `ltl` run on macOS and on Windows.
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
| sections | one section, or several in print order; the crop spans from the first one's start row to the last one's last row, including the blank rows between | `timeline,histogram` |
| start offset | rows relative to the first section's start row; negative reaches above it, positive skips into it | `+15` skips the first 15 timeline rows; `-5` starts 5 rows above the timeline |
| end offset | rows relative to the last section's last row, same sign convention; default `0` | `-2` stops 2 rows before the histogram ends |

Start rows and row counts are read from `-V section-layout` (#597 D13). Anything
printed between the named sections is part of the crop; leaving it out means hiding
it with `--hide`. A crop naming a section the report gives as `hidden` or `absent`
is an error, not an empty image.

**D3: columns are absolute, measured from the edges** (architect, 2026-09-24). A
crop may give a left and a right position. Left counts from the left edge, which is
0; right counts from the right edge, which is the terminal width, so a negative
value reaches inward. Anything not given means the full width. At
`--terminal-width 200`, `100, -25` captures 75 cells starting at the middle
(cells 100 to 175). Column positions hold only while the terminal width is fixed,
which every screenshot definition sets. Columns anchored to positions `ltl` reports,
as rows are, are [#599](https://github.com/gregeva/logtimeline/issues/599), filed as not planned.

**D4: the tool is written in Perl, not PowerShell** (architect, 2026-09-24),
superseding the platform line as filed. PowerShell was chosen to capture the
console window; with D1 nothing is captured from a window, and .NET's bundled
imaging (`System.Drawing`) is supported only on Windows. Perl is `ltl`'s own
language and toolchain; one implementation runs wherever `ltl` is developed. The
macOS and Windows requirement stands as: `ltl` is run, and its output captured, on
both.

**D5: screenshots are SVG** (architect, 2026-09-24). Written as text, so no imaging
module is needed, and a release's screenshot changes are readable in its diff.

**D6: prototype the rendering first** (architect, 2026-09-24). Before anything is
built on it, a prototype under `prototype/` proves that `ltl`'s ANSI output renders
faithfully to SVG: the block and box-drawing characters align cell to cell, the
colours match, and the result displays correctly where the documentation is read.

**D7: the background is an input** (architect, 2026-09-24). `ltl` detects a light or
dark terminal background and chooses its colours from it (`-lbg, --light-background`,
`-dbg, --dark-background` force either). Each screenshot states `dark` or `light`;
the tool forces that choice on `ltl` rather than letting it detect, and draws the
image on the matching background.

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

## Open questions

None.

## Definition of done (as filed)

The captured images reproduce the rendering that `tests/validate-histogram-ticks.sh`
(percentile tick marks on the histogram x-axis) and
`tests/validate-heatmap-palette.sh` (heatmap colours) assert character by character
and colour by colour. At least one heatmap and one histogram use case, each with a
crop anchored on its section start line, captured on macOS and on Windows.

## Acceptance criteria

Criteria 1 to 10 are assertable; 11 and 12 are unknown and are the prototype's
scope (D6).

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
- [ ] 9. The same recipe on macOS and on Windows yields the same crop cells.
- [ ] 10. `docs/process/screenshots.md` exists, the `CLAUDE.md` row points at it, and
      the path rule covers `images/screenshots/**` and `build/screenshots.yaml` (D12).
- [ ] 11. *(unknown: prototype)* Block and box-drawing characters align cell to cell
      in the SVG as displayed where the documentation is read.
- [ ] 12. *(unknown: prototype)* The rendered image matches the terminal's look,
      verified by viewing it on real data.
