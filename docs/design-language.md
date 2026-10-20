# Design language

How `ltl` looks: the glyphs, colours, emphasis and wording every surface is
drawn with, so that a new surface is drawn from this document and an existing
one is changed against it. Two looks exist, and a rule says which applies
where. This is a developer document: it names Perl identifiers and is not part
of the wiki. `docs/terminal-interaction.md` is its companion for how a surface
behaves; `docs/architecture-patterns.md` holds the mechanisms in code;
`docs/terminal-output.md` holds what output does per platform, including which
glyphs are one cell wide on Windows.

**Status.** The ltl look is what the tool draws today, read from the code
named in each section. The new style and the shared conventions were settled
by the architect in the prototyping of #412 (notice surfaces: presenting
notices and capturing the analyst's choices), 2026-10-19; nothing in `ltl`
draws them yet. The locked decisions behind them (D2 to D9) are in
`features/412-notice-surfaces.md` § Locked decisions, which remains their
authority; this document carries the settled form.

---

## Two looks, one choice per surface

The two looks coexist, and neither replaces the other. The ltl look is the
tool's output as it stands; the new style was validated for the notice
surfaces of #412 (notice surfaces: presenting notices and capturing the
analyst's choices) and is settled for them (D6). Whether a future surface
takes one or the other is a deliberate choice made when that surface is
designed, never a default drawn from the kind of thing it is.

Three rules (architect, 2026-10-19):

1. **Choose one, on purpose.** A new surface, or a change to one, names the
   look it takes and the reason, in its feature doc and in the table below, so
   the project's surfaces stay few in look and the choice is readable later.
2. **Interactivity is independent of look.** The interaction patterns of
   `docs/terminal-interaction.md` (keys, navigation, selection, the countdown)
   lay over either look. Scrolling the summary table's message list is the
   model case: the interactivity validated for the notice surfaces is added on
   top of the existing ltl-look table, not by proposing another surface that
   presents the same data in the new style.
3. **One implementation per look, so change cascades.** Each look is drawn by
   one set of routines that every surface in that look calls; a change or an
   evolution of the look is made there once and reaches every consumer and
   every future consumer, never re-styled per surface.

| surface | look | chosen where |
|---|---|---|
| the run's output: title, timeline, summary table, heatmap, histograms, help and explain text | ltl look | the tool as it stands |
| the notices panel, the ask modal, the compact box, the notice browser, a modal layered over the browser | new style | `features/412-notice-surfaces.md` D6, 2026-10-19 |
| the record a question leaves behind once answered, inline in the output | ltl look | the same, D4 |
| interactivity added to an existing surface, such as scrolling the message list | the surface's own look, the interaction patterns laid over it | rule 2, architect 2026-10-19; no such surface is scheduled yet |

## The ltl look

### Rules, frames and section spacing

- Rules and frames are drawn with the **light box set** of `%histogram_box_sets`
  (`─ │ ┌ ┐ └ ┘ ├ ┤ ┬ ┴ ┼`), in grey (`$colors{'bright-black'}`, SGR 90). The
  timeline's header is closed by a full-width grey rule; the heatmap's scale row
  hangs from the header rule with `┴` at the column separator; the summary
  table is ruled above and below its header with `─`.
- Histogram axes use the **heavy box set** (`━ ┃ ┏ ┓ ┗ ┛ ┣ ┫ ┳ ┻ ╋`) by default
  (`$histogram_box_weight`), with `┬` ticks pointing down to value labels and
  `┴` ticks pointing up at the percentile positions (`render_histogram_x_axis`).
- Bars are drawn with the eight block characters `▁ ▂ ▃ ▄ ▅ ▆ ▇ █`
  (`@histogram_block_chars`) for sub-cell resolution.
- The **title banner** (`get_title_string`) is grey: a full-width light rule, one
  row naming the tool and its version, a full-width light rule.
- **Exactly one blank row** separates two rendered sections, printed by
  `open_section()` before every section but the first; no section owns the
  spacing around it.

### The colour table

`@column_colors` holds ten named colours, each with a foreground, a plain and a
highlighted background, and two eight-step 256-colour gradients, one per
background:

| name | foreground | use |
|---|---|---|
| yellow | SGR 93 | duration |
| green | SGR 32 | bytes |
| cyan | SGR 36 | count |
| blue, magenta, red, orange, pink, teal, purple | SGR 34, 35, 31, 256-colour 208, 213, 43, 93 | the next user-defined metric columns, by position among them |

Colour identity is a property of the column definition in `@column_layout`,
never looked up by position at render time; a heatmap and a histogram take the
colour and gradient of the metric they draw (`features/column-layout-refactor.md`
§ Color Scheme Requirements). A heatmap of a metric with no column colour uses
the white gradient of `%heatmap_special_gradients`.

### Classification and identity shades

Named for the colour they are, shared by every surface that shows the outcome,
so one outcome reads in one colour wherever it appears (`%colors`):

| name | 256-colour | means |
|---|---|---|
| kelly-green | 34 | success |
| rosso-corsa | 160 | failure |
| gold | 178 | unclassified: neither outcome |
| amethyst | 135 | classification conflict: both criteria fired |
| periwinkle | 111 | log-format identity: the legend's format numbers |

The consolidation marker on a summary row (`~`, or a bullet on an
unconsolidated row) carries the row's classification as a colour: green when
every line is a success, red when every line is a failure, violet for a
conflict, terracotta when mixed, and no mark when unclassified.

### Emphasis

- **Bold** and **underline** appear only in help and explain text, through
  `bs_bold()` and `bs_underline()`, which emit SGR 1/22 and SGR 4/24 when
  `help_ansi_enabled()` says so: `FORCE_COLOR` on, else `NO_COLOR` off, else
  only when standard output is a terminal.
- **Dim** (SGR 2) is not used in the ltl look.
- Headers in the timeline are grey; a week or workweek fold is bold and
  upper-cased.

### Backgrounds

The dark background is the default. A light background is set by `-lbg`, or
detected on an interactive Unix terminal by an OSC 11 query of the terminal's
background colour (`detect_light_terminal_background`); `-dbg` forces dark and wins
over `-lbg`. On a light background every colour takes its `gradient_light`
steps. Windows has no detection: `-lbg` is given explicitly.

### Numbers

Every number in output passes through the one dispatch per metric kind,
with a budget row per surface (`docs/architecture-patterns.md` § Width-to-format
rule). A notice names the `notice` row for a scale in prose, `notice exact`
for a count a list beside it must agree with, and `notice share` for a
percentage.

---

## The new style

Settled for the notice surfaces' boxes and pop-ups (D6), available to a
future surface that chooses it. It differs from the ltl look in the elements
below and shares everything else.

| element | the new style |
|---|---|
| corners | rounded: `╭ ╮ ╰ ╯` on light lines `─ │` |
| frame colour | the colour of the category the box carries; grey (SGR 90 dark, 256-colour 244 light) for a box with no category, such as the browser's outer frame |
| headings | bold (SGR 1) |
| secondary text | dim (SGR 2): evidence inside a notice, the countdown's bracket |
| highlight | reverse video for the selected row, button or tab; a coloured block marks only the selected tab, elsewhere a category is in its foreground colour |
| the chosen thing | what the analyst picks (a choice, a key) stands out from the text: bold bright white on dark, bold black on light |

---

## Shared conventions

### The category sheet (D1, D2)

A notice's category is marked by a text glyph and a colour (D2); emoji and
ASCII marks are rejected. The colours are the `fg` of `@column_colors` on a
dark background and the darkest step of the colour's `gradient_light` on a
light one.

| order | category | glyph | on Windows | colour | how to read it |
|---|---|---|---|---|---|
| 1 | data anomaly | ⚠ | ▲ | orange | check the source data or the options before trusting the figures |
| 2 | figure caveat | ≈ | ≈ | magenta | the figures cover less than they appear to |
| 3 | your options | ⚙ | ⛭ | cyan | command usage warnings |
| 4 | decision taken for you | ↻ | ↻ | blue | what the run did instead of what was asked |
| 5 | runtime condition | ⏱ | ⧖ | teal | a condition of the run's environment |
| 6 | guidance | ➤ | ► | green | a next step worth trying |

Windows Terminal draws `⚠`, `⚙` and `⏱` as colour emoji, in their own colours
and covering the next cell, and draws `➤` reaching into the next cell, so
Windows takes the glyph of the fourth column,
seen one cell wide and in the category's colour there
(`docs/terminal-output.md` § Glyphs and width).

The order puts what bears on trusting the figures first and the next step
last. The how-to-read text of *your options* says the tool is warning, never
that the analyst erred.

### The notice (D3)

Notices are grouped by category and compact. The category is named once, in
upper case, with its how-to-read text on the heading row; categories are
divided by one blank row. A notice is one row with no row break inside it: its
statement, evidence and remedy are told apart by colour and by a marker before
the evidence and before the remedy. In a list each notice is preceded by the
bullet `╶` (U+2576, box drawings light right) in the category's colour, so the
one character carries the classification. Continuation rows of a wrapped
notice carry no hanging indent inside a box.

### Wording

- A count is written in parentheses everywhere, `(N)`: after a category name,
  in a tab, in a title; never a bare number.
- The notices panel is titled with the word `notices` in lower case and its
  count; a panel with one category takes the **edge form**: the category's
  glyph, name, count and how-to-read text in the top edge, in the category
  colour, the notices alone inside.
- A key bar entry is `keys: action` (`q/x: quit`), the same shape throughout,
  so a pair of keys never reads as a key and an action.
- The chosen option is reported on a row beginning `chosen:`.

### Light background

On a light background: each category's colour is the darkest step of its light
gradient, frames are 256-colour grey 244, text is black, the highlight is
black bold in reverse video. Every component was reviewed once per form on a
light terminal and accepted (architect, 2026-10-19).

---

## Owning records

- `features/412-notice-surfaces.md`: the locked decisions D1 to D9 and the
  prototyping record; `prototype/412-notice-surfaces/findings.md` the rounds
  that settled the new style and the shared conventions.
- `features/column-layout-refactor.md`: colour identity as a column property.
- `features/452-success-failure-percentage-columns.md`: the classification
  shades (its D14: named definitions, no column-colour index).
- `features/heatmap.md`, `features/histogram-charts.md`: gradients, box sets
  and block characters as used by the charts.
