# #598 rendering prototype: findings

The question (`features/598-screenshot-capture.md` D6): does `ltl`'s ANSI output
render faithfully to SVG, with block and box-drawing characters aligned cell to
cell (criterion 11) and a look that matches the terminal (criterion 12)?

## What was built

- `render.pl`: parses captured standard output into a grid of cells (character,
  foreground, background, bold, underline, reverse) and draws it as SVG. Colours:
  the 16 ANSI colours, text colour and background from the Terminal.app profiles
  "Clear Dark" and "Clear Light"; 256-colour indices 16 to 255 by the xterm formula.
  Two renderers:
  - **text**: every glyph is a `<text>` run in a monospace font stack
    (`ui-monospace`, SF Mono, Menlo, Consolas, DejaVu Sans Mono);
  - **geometry**: the same, except full, partial and eighth blocks and light and
    heavy box-drawing lines are drawn as rectangles at cell coordinates, and
    underlines as a line across the underlined cells.
  `--crisp` sets `shape-rendering="crispEdges"` on the rectangles; `--rows` and
  `--cols` crop in cells.
- `check-alignment.pl`: rasterises an SVG with Quick Look (WebKit, Safari's
  engine) and `sips`, both part of macOS, with nothing to install, and samples every
  full-block cell at its centre, 1.5 device pixels inside each edge, and on the
  edge it shares with a same-coloured full block below or to its right.

## Inputs

`inputs/spread-dbg.ansi.txt` and `inputs/spread-lbg.ansi.txt`: standard output of

    ltl --disable-progress -ni --terminal-width 211 --terminal-height 53 -dbg|-lbg \
        -hm duration -hg duration tests/fixtures/tomcat-access-duration-spread.txt

(the synthetic Tomcat fixture with a spread of durations): 69 rows, title,
timeline with heatmap, histogram, options, messages and summary. A full-day Tomcat
access log from the corpus (761,698 lines) was rendered the same way for viewing,
not committed.

## Observed

**The parser.** On both inputs: 69 rows, none wider than 211 cells, no escape
sequence other than colour codes. One code, `109`, is not a standard SGR code (118
times on the fixture, 122 on the full day); it is ignored, as terminals ignore it.
17 distinct non-ASCII characters, all single-width.

**Alignment, measured.** Rows 0 to 39 (title, timeline with heatmap, histogram)
of the fixture's render, 1,129 full-block cells, 7,276 samples, rasterised at 2.106
device pixels per unit:

| Render | Dark: failed samples | Light: failed samples | Where |
|---|---|---|---|
| geometry, crisp edges | 0 | 0 | |
| geometry, anti-aliased edges | 331 | 331 | all on the edge between two rows |
| text | 2,449 | 2,416 | 869 at the top of the cell, 836 to 869 at the bottom, 707 on the edge between rows |

The font's full block does not fill the cell's height, so as text the timeline
bars, the heatmap and the histogram show a background stripe between every row.
Drawn as rectangles, they fill the cell; without crisp edges, anti-aliasing leaves
a lighter line where two rows meet (samples `#57865e` against `#6caa71` on dark).
The check distinguishes the known-good render from both known-bad ones, on both
backgrounds.

**Look, by eye (Quick Look).** On the fixture and the full day, geometry with
crisp edges shows contiguous heatmap cells, histogram bars and ticks on their
axis, text on its cell grid, and the profile's colours. Two defects found and
fixed along the way: runs of text including spaces were stretched when the viewer
collapsed the spaces (text runs now break at blanks and adjust letter spacing
only), and underlines broke at spaces (now drawn as geometry across the cells).

**Size.** The full 211 x 69 render: 94 KB, 7.7 KB compressed. Text only: 85 KB.

**Quick Look lays an SVG out 768 units wide** and cuts off the rest; the check
scales a copy to that width and confirms the scale against the raster (on a white
background it cannot, and says so).

## Not yet known

1. **Criterion 12**: whether the render matches Terminal.app, side by side on the
   same command at the same size. Judged by the architect.
2. **Display on GitHub**, where the README and the wiki are read: needs the SVGs
   pushed on the issue branch. The alignment check covers WebKit only; Chrome and
   Firefox are not measured on this machine.
3. **Font**: the text uses the viewer's monospace font (SF Mono on macOS, Consolas
   on Windows, DejaVu Sans Mono on Linux). Letter spacing is adjusted to the cell
   grid, so text stays in its cells whichever font is used; the glyph shapes differ.

## Outcome

Viewed on GitHub in Safari by the architect: text renders well in both renderers;
the timeline bars and the heatmap are wrong in the geometry renderer and acceptable
as text glyphs. Terminal.app does not draw a full block over the whole line height,
so the gap between rows that the alignment check counted as a failure is the
terminal's own look. The check measured against a full cell, the wrong reference.

Decision: `features/598-screenshot-capture.md` D14, every character is drawn as
font text.
