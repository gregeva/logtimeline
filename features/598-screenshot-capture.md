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

1. **Capture tool.** PowerShell (`pwsh`) on macOS and Windows, one implementation.
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

## Open questions

- Whether crops need a column range (a region on the right of the screen, such as
  the heatmap), or whether terminal width plus section control is enough.

## Definition of done (as filed)

The captured images reproduce the rendering that `tests/validate-histogram-ticks.sh`
(percentile tick marks on the histogram x-axis) and
`tests/validate-heatmap-palette.sh` (heatmap colours) assert character by character
and colour by colour. At least one heatmap and one histogram use case, each with a
crop anchored on its section start line, captured on macOS and on Windows.

## Acceptance criteria

To be derived once the open questions above are settled.
