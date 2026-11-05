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
notices and capturing the analyst's choices), 2026-10-19, and validated on
Linux and Windows on 2026-10-20; the notices panel draws them in `ltl`. The locked
decisions behind them (D2 to D10, and D13 for the options list's headings) are in
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
  (`─ │ ┌ ┐ └ ┘ ├ ┤ ┬ ┴ ┼`), in grey (`$colors{'bright-black'}`: the colour
  set's grey once the background is known, § Backgrounds; SGR 90 while it is
  not). The
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
highlighted fill, and an eight-step gradient. Each is drawn in one of the three
conditions of § Backgrounds: while the background is not known, in `ltl`'s own
codes; once it is known, from the colour set for it (`%colour_sets`), 24-bit
where the set moves a colour. The sets are the architect's, validated on
2026-11-03 and 2026-11-04 (`features/749-terminal-colour-codes.md` § 12).

Duration, bytes and count take the first three. The other seven go, in order,
to the columns added after them: sessions, users, each thread pool, then each
user-defined metric. Colour identity is a property of the column definition in
`@column_layout`, never looked up by position at render time; a heatmap and a
histogram take the colour and gradient of the metric they draw
(`features/column-layout-refactor.md` § Color Scheme Requirements).

**Foregrounds**, the column's values and headings:

| name | use | not known | dark | light |
|---|---|---|---|---|
| yellow | duration | SGR 93 | #e5c872 | #c8ab55 |
| green | bytes | SGR 32 | #6caa71 | #5a9860 |
| cyan | count | SGR 36 | #7ccbcd | #4fadb0 |
| blue | | SGR 34 | #719bb9 | #4a799c |
| magenta | | SGR 35 | #bf7dcf | #a057b1 |
| red | | SGR 31 | #d57464 | #b45648 |
| orange | | 256-colour 208 | 208 | #db7302 |
| pink | | 256-colour 213 | 213 | #e36de4 |
| teal | | 256-colour 43 | 43 | #05ba97 |
| purple | | 256-colour 93 | #9758fe | 93 |

**Fills**, the bars: 256-colour codes in every condition, but blue's
highlighted fill, which is 27 once the background is known, so that it stands
apart from its plain fill. The text over every fill is black or white
(256-colour 16 or 231), whichever reads on it, in every condition.

| name | plain fill | highlighted fill |
|---|---|---|
| yellow | 184 | 226 |
| green | 34 | 46 |
| cyan | 30 | 36 |
| blue | 20 | 21; 27 once the background is known |
| magenta | 127 | 201 |
| red | 124 | 196 |
| orange | 166 | 208 |
| pink | 169 | 213 |
| teal | 29 | 43 |
| purple | 55 | 93 |

The histogram's highlighted part does not follow this table for three colours:
it reads a second number of the colour's entry (`highlighted_bg_num`), 51 for
cyan, 27 for blue in every condition and 207 for magenta (#666, the
histogram's count highlight differs from the timeline's).

**Gradients**, the heatmap's eight steps, faintest first. While the background
is not known, the 256-colour steps; once it is known, the set's, each step in
the column's own hue:

| name | not known | dark | light |
|---|---|---|---|
| yellow | 58, 94, 136, 142, 178, 184, 220, 226 | #785502, #926701, #ac7b08, #c19202, #ceae05, #d6cc0e, #e7e70e, #ffff00 | #edee21, #e1e10e, #d7d501, #d5c506, #d0b609, #cba701, #c49909, #bd8b06 |
| green | 22, 28, 34, 40, 46, 82, 118, 154 | #026401, #047b03, #059204, #06aa05, #06c305, #05dd04, #01f701, #9aff93 | #8cfe84, #1eff1a, #05f204, #03e402, #0bd609, #07c906, #06bc05, #01af00 |
| cyan | 23, 30, 37, 44, 51, 80, 86, 123 | #037171, #098585, #009a9a, #02afaf, #0fc5c4, #5cd6d5, #16f1f1, #8afffe | #11e4e4, #05d7d7, #0ec9c9, #0dbbbb, #0daeae, #0ca1a1, #0b9494, #008787 |
| blue | 17, 18, 19, 20, 21, 27, 33, 39 | #0003bc, #0029cc, #0032ee, #0d49fe, #2964fe, #437bfe, #5c8ffe, #76a1fe | #a0bffe, #8eb3fe, #7ca6ff, #6b99fe, #588cfe, #467dfe, #346efe, #215dfe |
| magenta | 53, 89, 125, 127, 163, 165, 201, 207 | #7b027b, #8f048f, #a500a5, #ba04ba, #d005d0, #e706e7, #fe08fe, #ff61fc | #ffa7fb, #ff89fb, #ff65fc, #ff2afe, #ee07ee, #da05da, #c700c7, #b300b3 |
| red | 52, 88, 124, 160, 196, 197, 203, 209 | #8e0302, #a60201, #be0503, #d70503, #f10302, #ff382a, #ff6554, #ff8574 | #fda799, #ff8c7c, #ff6e5d, #ff4838, #f90101, #df0603, #c70100, #af0000 |
| orange | 94, 130, 166, 172, 208, 209, 214, 215 | #a44804, #b75105, #cb5a04, #df6301, #f36d04, #ff7d2f, #fe9660, #ffac82 | #feab81, #fe9964, #fe8642, #fc7103, #ec6900, #db6100, #cb5900, #ba5204 |
| pink | 132, 133, 169, 170, 206, 207, 213, 219 | #ac5f90, #c162a0, #da61b2, #e371bc, #ff6ccf, #ff88d5, #fea0db, #feb6e2 | #ffa2dc, #ff8cd6, #fe75d0, #fe57ca, #ff24c6, #f106ba, #e002ac, #b24e90 |
| teal | 23, 29, 30, 36, 37, 43, 44, 50 | #06704f, #00845d, #01986b, #00ac7a, #03c189, #08d699, #08eca9, #46ffbc | #2ffeb9, #12edab, #03dc9d, #0eca91, #09b984, #0aa877, #08976b, #00875f |
| purple | 54, 55, 56, 92, 93, 129, 134, 171 | #5801a2, #6602bb, #7500d6, #8502f0, #912aff, #9a4fff, #9c7bda, #ae80ff | #c9b2fd, #bb99fe, #ad7ffe, #a061fe, #943bfe, #7a49c4, #7201d0, #5f00af |

A heatmap of a metric with no column colour uses the white gradient of
`%heatmap_special_gradients`, which has no set and keeps its own codes.

### The colour sets beyond the columns

Every other colour `ltl` writes is drawn from the same sets once the
background is known.

**The sixteen scheme colours**, which `ltl` writes as basic and bright codes
(`30` to `37`, `90` to `97`, and `38;5;0` to `38;5;15`): the categories of
`%colors`, the rules and headings, the legend. Black is the scheme's own in
every condition; bright black is the one grey that draws every line and all
secondary text.

| index | colour | dark | light |
|---|---|---|---|
| 0 | black | the scheme's | the scheme's |
| 1 | red | #d57464 | #b45648 |
| 2 | green | #6caa71 | #5a9860 |
| 3 | yellow | #c4ac62 | #a89046 |
| 4 | blue | #719bb9 | #4a799c |
| 5 | magenta | #bf7dcf | #a057b1 |
| 6 | cyan | #7ccbcd | #4fadb0 |
| 7 | white | #dee5eb | #3a4851 |
| 8 | bright black, the grey | #797c81 | #747474 |
| 9 | bright red | #e87461 | #c05140 |
| 10 | bright green | #79be7e | #67ab6d |
| 11 | bright yellow | #e5c872 | #c8ab55 |
| 12 | bright blue | #67b5ed | #2986c4 |
| 13 | bright magenta | #d389e5 | #ac65be |
| 14 | bright cyan | #84dde0 | #5cc8cc |
| 15 | bright white | #e5eff5 | #313c44 |

**`ltl`'s fixed 256-colour text codes**: the code is kept where it reads at
4.5:1 on that background, moved in lightness only where it does not. The
column foregrounds above and the shades below are drawn from this table; 33
and 170 are two notice categories' colours on dark (§ The new style), on light
the darkest step of their column's light gradient.

| 256-colour | dark | light |
|---|---|---|
| 29 | #31a076 | #02845d |
| 30 | #32a09f | #078181 |
| 33 | #3d97fe | 33 |
| 34 | 34 | #029202 |
| 35 | 35 | #07934f |
| 43 | 43 | #05ba97 |
| 44 | 44 | #03bbbb |
| 93 | #9758fe | 93 |
| 111 | 111 | #6f96e4 |
| 135 | #b776ff | #9b48e8 |
| 160 | #f53629 | 160 |
| 166 | #ed7327 | #c05400 |
| 170 | #de66de | 170 |
| 178 | 178 | #b99709 |
| 208 | 208 | #db7302 |
| 213 | 213 | #e36de4 |

Bold over the default foreground takes the set's emphasis colour (§ Emphasis).

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

Once the background is known, each is the colour set's for it: the codes that
read at 4.5:1 on that background are kept, the others moved in lightness only
(on dark, rosso-corsa #f53629 and amethyst #b776ff; on light, kelly-green
#029202, periwinkle #6f96e4, gold #b99709 and amethyst #9b48e8).

The consolidation marker on a summary row (`~`, or a bullet on an
unconsolidated row) carries the row's classification as a colour: green when
every line is a success, red when every line is a failure, violet for a
conflict, terracotta when mixed, and no mark when unclassified.

### Emphasis

- **Bold** and **underline** appear only in help and explain text, through
  `bs_bold()` and `bs_underline()`, which emit SGR 1/22 and SGR 4/24 when
  `help_ansi_enabled()` says so: `FORCE_COLOR` on, else `NO_COLOR` off, else
  only when standard output is a terminal. Bold over the default foreground
  takes the colour set's emphasis colour once the background is known
  (#f0f0f0 on dark, #313c44 on light), the week fold's and an error line's
  too.
- **Dim** (SGR 2) is not used in the ltl look.
- Headers in the timeline are grey; a week or workweek fold is bold and
  upper-cased.

### Backgrounds

The background is settled once for the run (`settle_background`), in three
conditions:

- **Dark**, by `-dbg`, or by the terminal's answer to an OSC 11 query of its
  background colour: the dark colour set.
- **Light**, by `-lbg`, or by that answer: the light colour set. `-dbg` wins
  over `-lbg`.
- **Not known**, when neither option is given and no terminal answers (a
  redirected run, a terminal that does not reply): `ltl`'s standard colours,
  the codes of this page, drawn for dark, which read on either background.

The terminal is asked on every run in a terminal, on Windows as on macOS and
Linux (`docs/terminal-output.md` § The terminals). The two colour sets were
validated by the architect on Terminal.app's Clear Dark and Clear Light
(`features/749-terminal-colour-codes.md` § 12).

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
| frame colour | the colour of the category the box carries; grey for a box with no category, such as the browser's outer frame: the colour set's grey (#797c81 dark, #747474 light) once the background is known, SGR 90 while it is not |
| headings | bold (SGR 1) |
| secondary text | in the colour set's grey once the background is known (#797c81 dark, #747474 light; D10); dim (SGR 2) while it is not: evidence inside a notice, the countdown's bracket |
| highlight | reverse video for the selected row, button or tab; a coloured block marks only the selected tab, elsewhere a category is in its foreground colour |
| the chosen thing | what the analyst picks (a choice, a key) stands out from the text: bold bright white on dark (the set's #e5eff5 once the background is known), bold black on light |

---

## Shared conventions

### The category sheet (D1, D2)

A notice's category is marked by a text glyph and a colour (D2); emoji and
ASCII marks are rejected. On a dark background each colour is a 256-colour
code, the same on every terminal and scheme: orange and teal are the `fg` of
`@column_colors`, the other four were chosen by the architect in the Windows
round in place of the basic codes they had (`docs/terminal-output.md`
§ Colour and emphasis). With the dark colour set, figure caveat is #de66de and
decision taken for you #3d97fe, moved in lightness toward 4.5:1
(`features/749-terminal-colour-codes.md` § 12.9). On a light background each
is the darkest step of the column's light gradient in the light colour set.

| order | category | glyph | on Windows | colour | dark, 256-colour | how to read it |
|---|---|---|---|---|---|---|
| 1 | data anomaly | ⚠ | △ | orange | 208 | check the source data or the options before trusting the figures |
| 2 | figure caveat | ≈ | ≈ | magenta | 170 | the figures cover less than they appear to |
| 3 | your options | ⚙ | ⛭ | cyan | 44 | command usage warnings |
| 4 | decision taken for you | ↻ | ↻ | blue | 33 | what the run did instead of what was asked |
| 5 | runtime condition | ⏱ | ⧖ | teal | 43 | a condition of the run's environment |
| 6 | guidance | ➤ | ► | green | 40 | a next step worth trying |

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
bullet `—` (U+2014, em dash, the architect's choice on every platform after
the Windows and Linux rounds), in the
category's colour, so the one character carries the classification. Continuation rows of a wrapped
notice carry no hanging indent inside a box.

### Wording

- A surface presents information simply, with the least explanation and
  detail the analyst needs to understand it and know what to do (architect,
  2026-10-18, round 1).
- A count is written in parentheses everywhere, `(N)`: after a category name,
  in a tab, in a title; never a bare number.
- The notices panel is titled with the word `notices` in lower case and its
  count, the title in the secondary text's colour, as its count is, never
  bright (rounds 2 and 3); a panel with one category takes the **edge form**: the category's
  glyph, name, count and how-to-read text in the top edge, in the category
  colour, the notices alone inside.
- A key bar entry is `keys: action` (`q/x: quit`), the same shape throughout,
  so a pair of keys never reads as a key and an action.
- The chosen option is reported on a row beginning `chosen:`.
- Every tab of the browser shows its category's name and count, always; tabs
  that do not fit on one row continue on a second (rounds 2 and 3).

### Light background

On a light background, which is always a known one: each category's colour is
the darkest step of its column's light gradient in the light colour set,
frames and secondary text are the set's grey #747474, text is 256-colour black
(16), the highlight is that black, bold, in reverse video.
Every component was reviewed once per form on a light terminal and accepted
(architect, 2026-10-19); the black is a 256-colour code since the Windows
round, where the basic black lost its emphasis and faint darkened (D10,
`docs/terminal-output.md` § Colour and emphasis); the grey and the category
colours are the light colour set's, validated by the architect on 2026-11-04
(`features/749-terminal-colour-codes.md` § 12.9).

---

## Owning records

- `features/412-notice-surfaces.md`: the locked decisions D1 to D16 and the
  prototyping record; `prototype/412-notice-surfaces/findings.md` the rounds
  that settled the new style and the shared conventions.
- `features/column-layout-refactor.md`: colour identity as a column property.
- `features/749-terminal-colour-codes.md`: the two colour sets for a dark and a
  light background, the three conditions, and the architect's validation of
  each colour (§ 12).
- `features/452-success-failure-percentage-columns.md`: the classification
  shades (its D14: named definitions, no column-colour index).
- `features/heatmap.md`, `features/histogram-charts.md`: gradients, box sets
  and block characters as used by the charts.
