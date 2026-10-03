# #653 — A highlighted histogram's percentile row is unreadable on a light background

Issue #653 (Make a highlighted histogram's percentile row readable on a light
background). Owning record for the surface: `features/histogram-charts.md`
(Decisions Log rows *Two legend lines when highlight exists* and *Highlight colors
match bar graph highlight_bg*, Acceptance Criterion 21). Target: the 0.18.6 patch
release, forward-ported to release/0.19.0, where the code involved is identical.

## What it is for

A highlighted histogram shows where a subset of requests sits in the whole
distribution: whether a liveness probe is fast or slow against all traffic, where
one API family's durations fall. The reader compares the population's percentile
row with the subset's row printed beneath it, column for column, and reads the
highlighted part of each bar against the population part. The readers are analysts
at light-background terminals and anyone reading a screenshot on a white page (a
guidebook chapter, a ticket, a slide); the capture tool passes `-lbg` for
`background: light`. When the subset's row cannot be read, the comparison cannot
be made and the picture is dropped, which is what happened in the chapter that
found this.

## Requirement

From the issue, in its terms: the highlight's percentile row readable on a light
background (dark text, or the band in a darker highlight colour), and the
highlighted bars distinguishable from the population's.

## Findings

Measured on release/0.18.6 (`c56ae7b`).

- **Reproduction.** One day of an Apache HTTP Server access log with microsecond
  durations (read with `-du us`), a liveness probe on 7.6% of its lines:
  `-n 0 -bs 1h -du us -hg duration -hgh 10 -h ping` at `--terminal-width 160`,
  once with `-lbg` and once with `-dbg`, each with bare `-V`. 84,876 lines read,
  6,458 highlighted. The population row is `ESC[38;5;184m` (text in xterm colour
  184). The highlighted row is `ESC[48;5;226m ESC[38;5;15m` under `-lbg` and
  `ESC[48;5;226m ESC[38;5;0m` under `-dbg`. Across the whole capture, `-V`
  sections aside, that one escape is the only rendered difference between the two
  runs: every bar cell is the same under both.
- **Rendered.** Through `build/capture-screenshots.pl` with `background: light` and
  crop `sections: histogram`, the highlighted row is a solid yellow band with no
  legible text and the highlighted bars are pale yellow beside the population's
  darker yellow. With `background: dark` both read clearly.
- **All metrics.** A three-metric run (`-hg` with `-hdmin 1000`, `-lbg`) prints the
  highlighted row of each as `48;5;226` / `48;5;46` / `48;5;51` with `38;5;15`
  text. The committed synthetic status-family fixture
  (`tests/fixtures/http-status-families.txt`) reproduces it with
  `-bs 1440 -oe -n 1 -lbg -hg duration -h /store/orders`.
- **Mechanism, text.** `render_histogram_legend()` chooses the text colour of the
  highlighted row from the light-background flag:

  ```perl
  my $fg_color = $heatmap_light_bg ? 15 : 0;  # 15 = white, 0 = black
  ```

  Index 15 is bright white. The band colour never changes with the background, so
  on a light background white text sits on the same bright band.
- **Mechanism, bars.** `render_histogram_row()` draws the population portion in
  `%histogram_base_colors` and the highlighted portion in
  `%histogram_highlight_colors`, both resolved in `normalize_data_for_output()`
  from the metric's `@column_colors` entry (`plain_bg_num`, `highlighted_bg_num`):
  duration 184 / 226, bytes 34 / 46, count 30 / 51. Neither depends on the
  light-background flag. The histogram reads neither `%colors` nor its `-HL` keys;
  those carry the category rows. `gradient_light` is read only by the heatmap.
- **The timeline does it differently.** Its highlighted metric fills use the
  entry's `highlighted_bg` string, which always carries black text, `ESC[38;5;0m`,
  whatever the background.
- **Contrast, measured** (WCAG 2, through the capture tool's colour table: indices
  0 to 15 from its light and dark profiles, 16 to 255 by the xterm formula; page
  white on light, `#191d27` on dark):

  | Pair | Light | Dark |
  |---|---|---|
  | Highlighted row today: text 15 on band 226 / 46 / 51 | 1.23 / 1.04 / 1.06 | not used |
  | Text 0 (the timeline's black) on band 226 / 46 / 51 | 11.17 / 8.74 / 9.56 | 9.61 / 7.52 / 8.23 |
  | Population row: text 184 on the page | 1.54 | 10.92 |
  | Highlighted bar 226 against the page | 1.07 | 15.69 |
  | Population bar 184 against the page | 1.54 | 10.92 |
  | Highlighted bar against population bar: 226/184, 46/34, 51/30 | 1.44 / 2.15 / 3.48 | same |

  On a dark page the highlighted portion is the most visible part of a bar; on a
  white page the order inverts and it is the least visible.
- **No single cube colour fixes the bars for every metric.** Darker candidates for
  a light-background highlight: for duration, 130 reaches 3.05 against the
  population and 4.71 against the page but carries black text at only 2.55; 94 and
  58 go further and need white text. The same trade-off holds for bytes (28, 22)
  and count (25, 24, 23). A darker band readable with black text is not available;
  one readable with white text is.

### Pre-existing, outside this issue

- **`-dbg` overrides `-lbg` only when a heatmap is requested.** The precedence and
  the auto-detection both sit inside the heatmap block of
  `adapt_to_command_line_options()`. Filed as #665.
- **Count's highlight does not match the timeline.** The cyan column entry declares
  a highlighted fill of 36 and a highlighted number of 51; the histogram uses 51,
  the timeline 36. Filed as #666.
- **Records that disagreed with the code.** The Decisions Log row *Two legend lines
  when highlight exists* and Acceptance Criterion 21 said the second row is in
  "highlight text color"; the code draws a band of the highlight colour with text
  on it. Trued up under D6 below. Criterion 16 (light-background gradient
  switching) is ticked, but the histogram never reads `gradient_light`; recorded,
  not changed.

### Citation corrections

- The capture tool does not "always set" `-lbg`: it passes `-lbg` for
  `background: light` and `-dbg` otherwise, and the default is dark. The defect
  appears only in light images.
- The text is bright white (index 15), chosen deliberately when the flag is set,
  not "near-white".
- The highlighted bars are the same under `-lbg` and `-dbg`; their low contrast
  against the population is not a light-background effect.
- The population row's text (184) measures 1.54:1 on white, below the 3:1 minimum
  for large text, though legible in the rendered image.

## Locked decisions

Standing decisions of the histogram record that govern this surface: *Highlight
colors match bar graph highlight_bg* (duration 226, bytes 46, count 51) and *Colors
match bar graph columns*; D7 of the screenshot-capture record (the capture
background defaults to dark).

Decisions locked for this issue (architect, 2026-10-03):

### D1 — 0.18.6 fixes the percentile row only

The highlighted percentile row's text becomes black on every background. The
highlighted bars keep their colours. The bar finding, with its options, is recorded
in `features/histogram-charts.md` as a decision of its own, to be taken separately:
a light-background highlight colour for the histogram alone would break the
matching rule; for the timeline too, it recolours the timeline; either way the
palette has to be chosen from rendered candidates, and #665 has to be fixed first.

### D2 — the text is index 0, the black every highlighted timeline fill uses

Not the fixed cube black (16). The row then reads like every other highlighted
fill, and the harness can assert that the row's text matches the timeline's.

### D3 — the population row's text is out of scope

Its 1.54:1 on white is recorded here and in the histogram record; the issue calls
the row readable, and changing it would run into *Colors match bar graph columns*.

### D4 — the colour assertions live in a new harness

No harness asserts histogram colours today, and `tests/validate-histogram-ticks.sh`
is chartered on the percentile tick marks. The new harness's name and shape follow
`tests/HARNESS-DESIGN.md`, read before it is created.

### D5 — the rendered contrast is checked once, not by a harness

The harness guards the cause (the text code); the contrast is that code combined
with the capture tool's palette, and is measured once at implementation and
recorded here.

### D6 — the histogram record is trued up in the same change

The two Decisions Log rows and Criterion 21 describe the band and its black text;
a new row records this issue and the bar finding.

## Contracts

- **C1.** The highlighted percentile row's text is `38;5;0` under `-lbg`, under
  `-dbg`, under auto-detection and with no background option.
- **C2.** The band keeps the metric's highlight colour (`highlighted_bg_num`) and
  the two rows stay aligned column for column.
- **C3.** Bar colours are unchanged.
- **C4.** Nothing else changes: output under `-dbg` or with no background option is
  byte-identical, escapes included; ANSI-stripped output is identical under every
  option.

## Acceptance criteria

- [ ] **AC1 (C1).** With a highlight active and `-hg duration`, every non-blank
      cell of the highlighted row has text `38;5;0` under `-lbg`, under `-dbg` and
      with neither. *Assertable:* new harness (D4), scenarios for light, dark and
      default; the row located as the histogram section's last row from
      `-V section-layout`, cells decoded with `tests/lib/rendered-output.pl`;
      fixture `tests/fixtures/http-status-families.txt` with `-h /store/orders`,
      shaped `-bs 1440 -oe -n 1`.
- [ ] **AC2 (C1, D2).** The row's text code equals the text code on the timeline's
      highlighted fill of the same metric in the same run. *Assertable:* the same
      harness, against a `--debug-layout` capture.
- [ ] **AC3 (C1, C2).** C1 and C2 hold for each metric in one run of
      `-hg duration,bytes`, each band in its own metric's highlight colour.
      *Assertable:* the same harness.
- [ ] **AC4 (D5).** In the capture tool's light image the row's text measures at
      least 4.5:1 against its band for duration, bytes and count. *Unassertable,
      visual:* measured once at implementation and recorded under
      *Implementation*; expected 11.17 / 8.74 / 9.56 against 1.23 / 1.04 / 1.06
      today.
- [ ] **AC5 (C3, C4).** `tests/validate-regression.sh` passes with no reference
      rebaselined; on the reproduction, the `-dbg` capture is byte-identical before
      and after, and the `-lbg` capture differs only in the highlighted row's text
      escape. *Assertable:* the regression harness plus a diff of the captures.
- [ ] **AC6.** The picture the issue dropped is usable: the capture tool with
      `background: light` and `sections: histogram` on the reproduction shows a
      legible row. *Unassertable, visual:* the rendered PNG on real data.

## Gate

Not the hot path: `render_histogram_legend()` runs once per histogram. The diff
touches an executable line of `ltl`, so the full harness suite and a before/after
benchmark (`single-day-access-log-standard`, labels `653-before` and `653-after`)
are required; the benchmark is expected to be neutral. Harnesses on the surface:
`validate-regression.sh` (the highlighted and `hg-*` scenarios),
`validate-histogram-ticks.sh`, `validate-screenshot-capture.sh`,
`validate-section-layout.sh`, and the new harness. No `-V` section or key changes.
No change to `--help` or `docs/usage.md`. Release note under Bug Fixes: *Fix the
highlighted histogram percentile row, unreadable on a light background (`-lbg`).*

## Implementation

Not started.
