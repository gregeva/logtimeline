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

## Open questions

- How a cell region becomes an image: capturing the terminal window, or rendering
  the captured ANSI output for that cell range to an image.
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
