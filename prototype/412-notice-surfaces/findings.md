# Notice surfaces, prototyping stage 1: findings (#412)

Stage 1 of the prototyping in `features/412-notice-surfaces.md` § Prototyping:
terminal layout design on macOS, from fixed example notices, in both visual
languages. No prototype runs `ltl`; the progress line, completion rows and
notices they show are fixed content. Each prototype is run live by the
architect; his feedback and what Claude's own runs observed are recorded here
as they land, and the stage's findings report is written into the feature doc
from this file.

Run from this directory with Homebrew Perl. Every prototype takes
`--style ltl|new`, `--glyphs symbol|emoji|ascii`, `--bg dark|light` and
`--width N`; every choice point takes `--answer` (answers given ahead, comma
separated, one per choice point) and `--seconds N`.

## Shared pieces

- `lib/NoticeProto.pm`: the two visual languages, built on ltl's box glyphs
  (`%histogram_box_sets`) and colour table (`@column_colors`), read from the
  `ltl` source at run time; the tty guard (mode restored and cursor shown on
  normal exit, `die`, Ctrl-C and TERM); width measured by Unicode's
  properties; a key reader decoding arrows, PgUp/PgDn, Tab, Enter and Esc; the
  timed yes or no with its visible countdown; answers given ahead.
- `lib/NoticeForms.pm`: the three forms a block of notices takes (lines, a box
  per category, headed sections).
- `notices/sets.pl`: the fixed sets, worded after the shipped producers, each
  notice split into statement, evidence and remedy: *minimal* (one
  deprecation), *typical* (7 over five categories), *options* (4 known before
  the read), *heavy* (25 over all six).
- `replay.pl`: Claude's check of a raw capture, replayed through Term::VT102 to
  the screen it leaves.
- Claude's proposals throughout, all open: the category colours (data anomaly
  orange, figure caveat magenta, your options cyan, decision taken for you
  blue, runtime condition teal, guidance green; on a light background the
  darkest step of each `gradient_light`), the glyphs (`⚠ ≈ ⚙ ↻ ⏱ ➤`), the
  order (what bears on trusting the figures first, the next step last), and
  the wording of each category's "how to read it" line.

## The prototypes

| # | surface | moment | variants to compare |
|---|---|---|---|
| P1 | deferred notices by category | data work done, before the charts | `--form lines\|boxes\|sections`; `--set minimal` is the two-line deprecation; `--all` shows all six side by side |
| P2 | option notices with a timed continue / stop | before the read | `--form`; `--frame shared` puts notices and question in one frame |
| P3 | yes or no over the progress line (memory growing) | during the read | `--place above` (notice and answer stay, progress resumes below), `inplace` (one row in place of the progress row, answer recorded under the completion row), `box` (boxed notice, collapses to one row once answered) |
| P4 | two-stage choice once a pattern is detected | after the statistics | stage one is a `[y/N]` defaulting to continue; stage two `--selector list` (arrows, highlighted row, its effect shown beneath) or `keys` (one row, a digit) |
| P5 | navigable list of many notices with detail | data work done | `--mode inline` (a window below the cursor with a detail pane, collapsing to one row of counts) or `fullscreen` (alternate screen, category tabs, list and detail side by side from 120 columns) |
| P6 | modal dialog with buttons and a countdown | `--moment read` or `after` | `--screen inline` (drawn into rows reserved below the cursor) or `alt` (centred on the alternate screen) |

```
perl p1-deferred-notices.pl --all
perl p1-deferred-notices.pl --form boxes --style new
perl p2-preread-choice.pl
perl p2-preread-choice.pl --frame shared --style new
perl p3-progress-choice.pl --place above
perl p3-progress-choice.pl --place inplace
perl p3-progress-choice.pl --place box --style new
perl p4-pattern-choice.pl
perl p4-pattern-choice.pl --selector keys --style new
perl p5-notice-browser.pl
perl p5-notice-browser.pl --mode fullscreen
perl p6-modal-choice.pl --moment read
perl p6-modal-choice.pl --moment after --screen alt --style new
```

## Claude's own runs (2026-10-18)

- **Unattended.** Every prototype with stdout to a file, in both styles, both
  backgrounds, at 80 and 140 columns (44 runs): exit 0, nothing on stderr,
  never waiting. With no terminal each choice point takes its default and its
  row says so (`default, no terminal`); P5 prints its first frame; P6 prints
  the dialog as it first appears.
- **Answers given ahead.** `--answer n` (P2, P6), `--answer y,1` and `y,2`
  (P4, one answer per stage): each row records `given ahead`.
- **Keys under a pty** (`expect`), replayed to the screen they leave: P2 `n`
  during the countdown; P3 `y` in each placement, and the screen at the
  moment of the question; P4 `y` then down and Enter in the list, `y` then `1`
  in the keys row; P5 down, down, `3`, Tab, down, `q` in both modes; P6 Tab and
  Enter on both screens, and the read moment's dialog mid-countdown.
- **Width.** No rendered row wider than the terminal at 80 or 100 columns,
  measured by Unicode width with SGR removed. Rows that did not fit were made
  to: a category heading puts its "how to read it" on the next row, P5's
  counts and tabs drop the category names, its key bar is cut.
- **Term::VT102 as the checking emulator.** It needs the capture decoded as
  UTF-8 and bare line feeds turned into CR LF (`replay.pl` does both). It has
  no alternate screen: a replay of P5 full-screen or P6 `--screen alt` shows
  the last frame overwritten by what was printed after leaving it, so those
  were checked from the frame's own bytes and the `?1049h` / `?1049l` pair.
  This bears on the unattended-capture criterion for selected surfaces.

## Architect's feedback (2026-10-18)

Given through `review.pl`, one entry per option, verbatim in
`feedback/stage1.jsonl`. 29 of 30 options reviewed; the light-background
option (one box per category with `--bg light`) was not, so no light
background has been evaluated.

Across the surfaces:

- **One standard set of patterns.** Each moment does not get its own way of
  presenting and asking; a small set of surface patterns is chosen, committed
  to, and called through shared code wherever it applies.
- **Vertical space is the cost.** No row break inside a notice: the colours
  and the `→` already separate its statement, evidence and remedy. A single
  notice is one row. Mostly empty rows and a right side left blank are waste.
- **Group by category, name it once.** A category's name is not repeated on
  each notice. Upper-case headings, and the "how to read it" text on the
  heading row, are liked.
- **Colours and text glyphs are liked.** Emoji are rejected (inconsistent
  spacing after them in this terminal, and not apt to the categories); ASCII
  marks add nothing beyond the category name.
- **A surface that asks erases itself once answered**, so it costs no screen
  space afterwards; nothing redundant is left (a declined choice leaves no
  row repeating "continue as planned").
- **Countdowns.** Any key other than a choice stops the countdown, leaving
  time to read; the pattern choice's countdown is too short.
- **Navigation.** `j`/`k` alongside the arrows for less capable terminals;
  number keys select a tab.

By surface:

| surface | liked | to change |
|---|---|---|
| deferred notices (P1) | a box marking the notice surface; headed sections, upper case, the how-to-read text | a box per category is busy beyond one or two categories: one box round all the notices, categories divided inside by rows or blank lines; denser rows |
| option notices with a timed continue (P2) | the choice row; bold or bright white choices | the layout of the block; the shared frame left open while asking: draw the bottom edge and come back up for the choice |
| yes or no over the progress line (P3) | in the progress row itself, for the most minimal (with the category colours and parts brought into that one row); the box that collapses once answered, for more detail, with the frame in the category colour | the notice above the progress line wastes width and rows |
| pattern choice in two stages (P4) | the vertical list with its explanation of the highlighted view | the guidance notice lacks the separated parts the others have (the focus, e.g. the API, then the analysis); stage two sits outside stage one's box: the box should grow to hold the list; declining should erase it all; the one-row digit selector is a fallback only (small terminal, no boxes, no arrow keys) |
| notice browser (P5) | the list with a detail pane, for many dense notices; category tabs filtered with left and right | should be a box drawn over the output and erased on closing, reachable again after a two-stage choice; full screen is overkill; the new style shows no difference from the ltl look here |
| modal (P6) | the modal erasing itself after the choice; the alternate screen as primary, drawn below the cursor as fallback, the caller passing which | a different presentation per moment |
