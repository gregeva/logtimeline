# Feature: programmatic console screenshot capture (#598)

## GitHub Issue

[#598](https://github.com/gregeva/logtimeline/issues/598): Enhancement: programmatic
console screenshot capture for documentation (development tooling).

Blocked by [#597](https://github.com/gregeva/logtimeline/issues/597) (section
visibility and the `-V` section start-line report), specified in
`features/597-section-visibility.md`.

## Motivating consumer

The documentation. It has no screenshots because they are captured by hand. A
screenshot defined in code (command line, input files, terminal geometry, target
region) is regenerated at every release and stays current without manual effort.
This is development and release tooling, not shipped with `ltl`.

## Requirements

As filed on the issue, in three parts:

1. **Capture tool.** Perl (D4, superseding PowerShell as filed), one implementation;
   `ltl` run on macOS and on Windows.
   Takes a full `ltl` command line and produces one or more images from a single
   execution. Terminal width and height default (width around 200 columns) and are
   overridable. Crops are in terminal cells, never pixels: a target section plus
   lines before and after it, positioned relative to the section start lines `ltl`
   reports on `-V`. Two runs: a `-V` probe run for the start lines, then a clean
   render run. Output taller than the terminal is handled by hiding or bounding
   sections, never by scrolling back.
2. **Batch processor.** Reads a manifest, separate from the page map in
   `build/sync-wiki.sh`, listing every screenshot: command line, input files,
   geometry overrides, crops, output image names.
3. **Release step.** Beside `build/sync-wiki.sh`; runs the batch processor, and the
   images are committed before any documentation update that references them.

## What this issue takes from #597

- Line positions come from the `-V` report, computed before render (#597 D3), so
  the probe run and the capture run agree when the rendered output is identical.
- Sections are removed with the `hide` options (#597 D1).
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

## Open questions

None.

## Definition of done (as filed)

The captured images reproduce the rendering that `tests/validate-histogram-ticks.sh`
(percentile tick marks on the histogram x-axis) and
`tests/validate-heatmap-palette.sh` (heatmap colours) assert character by character
and colour by colour. At least one heatmap and one histogram use case, each with a
crop anchored on its section start line, captured on macOS and on Windows.

## Acceptance criteria

To be derived once the open questions above are settled.
