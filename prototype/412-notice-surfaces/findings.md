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

## Resuming (2026-10-19)

Where stage 1 stands, for picking the review up in a later session:

- **Round 7 is reviewed and accepted** ("yes, you finally got it",
  `feedback/stage1-round7.jsonl`). Every view of the framework on macOS is now
  validated by the architect: the panel in both forms, the modal at the three
  moments with its options list, the compact box, the inline fallbacks, the
  browser on both screens with the layered list. What remains of stage 1 is
  listed under § Where stage 1 stands below; the next step is the architect's
  to direct.
- **What each round holds:** round 1 (the six first prototypes, `p1-` to
  `p6-*.pl`, feedback `feedback/stage1.jsonl`); round 2 (reviewed at commit
  4d1218c, feedback `feedback/stage1-round2.jsonl`); round 3 (its scripts at
  commit 4bef110, feedback `feedback/stage1-round3.jsonl`); round 4 (the first
  build of `show.pl` with `lib/NoticeSurfaces.pm` and `notices/inputs.pl`,
  feedback `feedback/stage1-round4.jsonl`); round 5 (the same scripts,
  feedback `feedback/stage1-round5.jsonl`); round 6 (feedback
  `feedback/stage1-round6.jsonl`); round 7 (feedback
  `feedback/stage1-round7.jsonl`; the same scripts, the current framework).
- **Not started:** the decision round on which surfaces go forward, the
  light background (no option on it has been evaluated), porting to Linux and
  Windows, the unattended-capture method for the selected surfaces, the
  producer interface.
- `ltl` carries `$version_number = "0.20.0-412"`; it is restored before any
  completion gate.

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

## Round 2: the standard patterns (2026-10-18)

Built from the feedback above, in `lib/NoticeSurfaces.pm` and called by three
scripts under `round2/`: the same patterns at every moment, none of its own.
Reviewed with `perl review.pl` (round 2 is the default; feedback to
`feedback/stage1-round2.jsonl`).

| pattern | what it is | called at |
|---|---|---|
| panel | one notice: one row, no box; more: one box round them all, each category headed once (upper case, count, how to read it), one row per notice, categories divided by a rule or a blank row | end of the run (`round2/panel.pl`), and to carry what each question showed and its answer |
| row | the question on one row in place of what was there, the notice cut to fit beside it; several notices: a row each above it; the views chosen by digit | before the read, during it, once a pattern is found (`round2/ask.pl --surface row`) |
| box | a box below the cursor, frame in the category colour in the new style, the question on its last row inside the frame; grows to hold the views | the same three moments (`--surface box`) |
| modal | a dialog with two buttons, on the alternate screen over a dimmed copy of what the run printed, or below the cursor as the fallback, the caller choosing; grows to hold the views | the same three moments (`--surface modal --screen alt\|inline`) |
| browser | the notices in a box of fixed height: tabs by category (the shown one named), the list, the selected notice's detail; a notice offering views opens them in the detail's place and returns to the list | end of the run (`round2/browser.pl --screen alt\|inline`) |

Every surface that asks erases itself once answered; any key that is not a
choice stops its countdown (10 s); `j`/`k` move wherever the arrows do; a
notice's parts are told apart by colour, `·` before the evidence and `→`
before the remedy. Claude's proposals in this round, all open: carrying the
question's notice and its answer to the end panel as a `↳` row; the
alternate screen drawn over a dimmed copy of the run's own rows (ltl knows
what it printed), so the dialog reads as a window over the run; naming only
the shown tab.

Claude's own runs: every script unattended in both styles at 80 and 140
columns, exit 0, nothing on stderr; under a pty with keys (expect driving
`script -F`), replayed through Term::VT102: the countdown paused by another
key, the box and modal growing to hold the views, declining erasing all of
it, the browser's tabs, views and closing. A width lookup per character
through Unicode::UCD made the browser take seconds per frame; each code
point is now looked up once.

### Architect's feedback on round 2 (2026-10-18)

All 16 options reviewed, verbatim in `feedback/stage1-round2.jsonl`.

- **Questions during a run lead with the modal** on the alternate screen; the
  modal below the cursor is the second choice. The row form is rejected: the
  three parts of a notice and a question jammed into one row cannot be read.
  A one-row form would have to be very concise, which these notices are not.
- **One pattern, different inputs.** The memory question and the pattern
  question are the same surface called with different content; a prototype
  that shows them as different surfaces misreads the work.
- **Nothing is reprinted after the answer.** A surface that asks shows the
  notice mid-run, takes the choice, and leaves no trace. Carrying the notice
  and the answer to the end panel is rejected as the default; whether a
  surface leaves a record is a boolean the caller passes.
- **Style by kind:** boxes and pop-ups in the new style (rounded corners, the
  frame in the category colour); inline text close to the ltl look. Category
  names set as coloured blocks are rejected except to mark the selected tab;
  elsewhere a category is in its foreground colour.
- **Panel:** categories divided by a blank row, not a rule; `NOTICES` in the
  same dim colour as its count, not bright; the box drawn even for a single
  notice; 25 notices belong in the browser, not printed as a panel. The
  compaction, glyphs and colours are kept.
- **Box:** the small box in the category colour is right directionally. Its
  heading carries the category, the count, and how to read the category.
- **Views (the second stage):** each view has a third part, the why, in a
  column on the right beside the what and the how; it comes from the
  producer as part of the notice.
- **Browser:** good in both modes, in the new style with rounded corners;
  every tab always shows its category name.

## Round 3 (2026-10-18)

Built from round 2's feedback; the scripts moved from `round2/` to
`surfaces/`, where the patterns now evolve, and both styles default to the
new one for boxes and dialogs.

- **Asking during the run is one surface**, `ask()` in
  `lib/NoticeSurfaces.pm`, called at each moment with that moment's notices
  and choices: the modal on the alternate screen over the dimmed run leads,
  the modal below the cursor is its fallback (`--screen inline`), and the box
  below the cursor is the compact form (`--surface box`). The row form is
  removed.
- **No trace by default.** Once answered the surface is erased and nothing is
  printed in its place. `record`, a boolean the caller passes (`--record`),
  leaves the notice and the answer as inline text in the ltl look where the
  surface was. The carry to the end panel is removed.
- **The top edge** of the modal and the box carries the category, the count
  when there is more than one notice, and how to read the category.
- **Views** in three columns: what, options, why; the why is part of each
  view as its producer would give it (`notices/round2.pl`), wrapping within
  its column when the terminal is narrow.
- **Panel:** blank rows between categories, `NOTICES` in the dim of its
  count, the box drawn for a single notice too.
- **Browser:** rounded corners; every tab named, on a second row when they do
  not fit on one; a coloured block only on the selected tab, the detail
  heading in its foreground colour; closing leaves no trace.

Claude's own runs: every script unattended in both styles at 80 and 140
columns, on both screens, with and without a record and with answers given
ahead (exit 0, nothing on stderr); under a pty with keys, replayed through
Term::VT102: the views' columns at 100 and 160 columns, the modal growing to
them inline and on the alternate screen (one enter, one leave), the record
left in place of the dialog, nothing left without it, the browser's views and
closing.

### Architect's feedback on round 3 (2026-10-19)

All 12 options reviewed, verbatim in `feedback/stage1-round3.jsonl`. The
patterns are accepted in direction: the panel "looks good", the box during the
read is "perfect", the browser over the dimmed run "I love it", the modal below
the cursor and the browser below the cursor are fine. What follows is what
changes.

**The framework, not the instances.** Said on the compact form before the
read, and bearing on the whole stage: the use cases (the deprecation, the
memory question, the pattern choice, the long list) were given as examples in
order to establish standardised terminal interface scenarios, usage patterns,
layouts and designs; the prototypes still iterate through the same per-use-case
scripts, and the architect fears that after all the prototype work what is to
be built (a standard framework) will still not have been structured. This is
the third round carrying the correction (round 1: one standard set of
patterns; round 2: one pattern, different inputs).

Across the surfaces:

- **Keys follow industry practice and are the same on every surface.** Where
  Tab moves forward, Shift-Tab moves back. A quit key (Esc, and `q`) is
  always available and takes the default; one surface accepted Esc and
  another only Enter, which is the inconsistency to remove. A parameter lets
  a consumer add a key (`q` or `x`) that quits the application outright, so
  the analyst can simply say quit.
- **Nothing ever says "paused".** Any key stops the countdown; stopping is an
  internal state that the countdown's disappearance already shows. A "paused"
  word implies it might resume, which it never does. No surface shows status
  on the countdown.
- **Pop-up size follows the text.** A dialog measures what it has to show and
  takes one of three predefined sizes, ratios of the terminal: small, medium,
  large. The views' third column widened the text without widening the
  modal. Generic to every pop-up.
- **Buttons sit in fixed places.** Continue and Select changed position
  between prototypes; cancel, continue or OK have one consistent placement
  across uses. Custom labels depend on the use, their positions do not.
- **The dimmed run does not move.** The progress line printed at the top right
  of the terminal is drawn at the bottom right of the dimmed copy under the
  modal, and returns to the top when the modal closes. Seen on the modal
  during the read and on the record variant; a bug in the prototypes, since
  dimming must not move the run's rows.
- **Views are headed What? How? Why?** by default, and the headings are
  parameters set by each consumer. A consumer may have fewer than three parts:
  the surface adapts down to two columns or one. (Claude had named the columns
  what, options and why.)
- **The browser is sized for its tallest detail up front.** A selection whose
  detail grows from three or four rows to ten (a guidance notice with a
  selection and a histogram of the API concerned) must not resize or move the
  window while the analyst navigates: the height is computed from the largest
  entry before drawing. Such an entry is added to the examples.

By option:

| option | verdict | to change |
|---|---|---|
| panel, 7 notices | looks good | title is the bare count, not "about this run"; the filled circle bullets are too intense and overshadow the category glyph: something lighter from the dash family (not the plain dash), chosen in a bullet glyph selection prototype next round |
| panel, one notice | | `notices` in lower case beside the upper-case category name; "correct the command" reads as blame: words that say the tool is warning, such as "command usage warnings" |
| modal during the read | otherwise good | the dimmed run moving; Shift-Tab; a quit key; no "paused" |
| modal before the read | as the previous | no "paused" anywhere |
| modal once a pattern is found | the third column is good | What? How? Why? parameterised, adapting down; the modal sized to its text; button placement |
| modal below the cursor | good | |
| modal with a record | validated, works; the architect sees no use case for it | the dimmed run moving |
| box during the read | perfect | keys consistent with the modal (Esc accepted there, only Enter here); the parameterised quit-the-application key |
| box before the read | fine | an empty row between the notices and the question; the framework remark above |
| box once a pattern is found | good; full width keeps the Why from wrapping | the three-column remarks above |
| browser over the dimmed run | I love it, well done | fixed height from the tallest detail; the guidance-with-histogram example |
| browser below the cursor | fine, a variation on the last; erases on closing as it should | |

## The pause after round 3 (2026-10-19)

The architect paused the stage to redesign its process. What was diagnosed,
what was agreed and the round procedure that came of it are recorded in
`features/412-notice-surfaces.md` § Prototyping; the decisions the three
rounds had settled are locked there as D2 to D9, and the framework's
specification is its § Surface framework contract, reviewed by the architect
as a document before round 4 was built. The lessons go into
`prototype/README.md` when the stage closes, as the rules of a design
prototype.

## Round 4: the framework against the contract (2026-10-19)

Built from the contract after the architect confirmed the read-back (one
addition at confirmation: more text on the screen before a modal, so the
dimmed run has something to dim). The round 3 scripts are gone; the use cases
are named inputs (`notices/inputs.pl`) any component takes, and one driver
runs them:

```
perl show.pl panel [--input typical|deprecation|heavy] [--bullet N|glyph]
perl show.pl bullets
perl show.pl ask --input memory|preread|pattern [--form modal|box] [--placement alt|inline]
                 [--size small|medium|large] [--quit on|off] [--keybar full|letters|none]
                 [--record] [--seconds N] [--answer letter|default[,option]] [--fixed-height]
perl show.pl browser [--input heavy] [--placement alt|inline] [--size ...] [--rows N] [--seconds N]
```

What it holds, by the contract's sections:

- **Components:** `panel()`, `ask()` and `browser()` in `lib/NoticeSurfaces.pm`,
  each taking the parameters of the defaults table and only what a caller
  wants otherwise (`with_defaults()`); the table itself is `%DEFAULTS`.
- **Keys:** one map, `action()`, on every component: arrows and j/k, PgUp and
  PgDn, ←→ and Tab with Shift-Tab as its reverse (`\e[Z` decoded in
  `NoticeProto::read_key`), digits, Enter, Esc taking the default, q and x
  quitting where quitting is on (the surface cleared, the run stopped with one
  dim row), any other key stopping the countdown; the key bar text comes from
  `key_bar()` and reads the same everywhere. Choice letters are passed by the
  caller with each button, underlined in the label (`lettered()`), accepted in
  either case.
- **Buttons:** by role, `stop` leftmost, `more` between, `default` rightmost
  and highlighted, the countdown's slot beside it kept at a fixed width so the
  row does not move when the countdown stops.
- **Size tiers:** small, medium, large as 50, 70 and 90 per cent of the
  columns (at least 44) and 30, 50 and 80 per cent of the rows; `choose_tier()`
  takes the smallest in which the content's longest unbreakable unit (the top
  edge, the key bar, the button row, the options list's fixed columns, the
  longest word) fits and the rows do not exceed the height; `--size` names
  one. At 120 by 40 the memory modal takes medium and the pattern modal large.
- **Height across the two stages:** Claude's interpretation of the contract's
  proposed line, to be seen. The width is chosen once for both stages; the
  height is each stage's own, growing when the options list opens, since the
  transition is a decision, not navigation. The literal reading (one height
  for both, the taller's, so stage one carries blank rows between the notice
  and the question) is `--fixed-height`, kept for comparison and not a review
  view. The browser follows the architect's rule literally: its height comes
  from its tallest detail before it is drawn.
- **The dimmed run does not move:** the backdrop is built from the terminal's
  own cursor position report (`query_cursor_position`): the live row at the
  cursor's row, the printed rows ending on the row above it, nothing padded.
  `notices/backdrop.pl` gives the run more to dim: a previous run's summary,
  the prompt, ltl's banner, two scanning rows, the progress line.
- **Compact box:** quitting off and the key bar the choice letters only
  (the defaults table); the choices on the question row with their letters
  underlined, the default bright with the countdown; a blank row before the
  question.
- **Wording:** `notices · N` dim as the panel's title; `command usage
  warnings` for *your options*.
- **Bullet:** an en dash in the dim colour by default; `perl show.pl bullets`
  is the glyph sheet, ten candidates each under a category heading with two
  notices, numbered so the architect can name one; `panel --bullet N` shows it
  in full.
- **Browser:** sized before drawing for its tallest detail: the guidance
  notice on one API carries ltl's own duration histogram with its percentile
  legend (`notices/histogram.pl`, 14 rows captured from a real `-hg duration
  -hgh 8` run at 80 columns, colour codes kept; the architect's correction
  mid-build: an actual ltl histogram, not generic bins). Enter on it opens the
  options list as an ask modal layered over the browser (`stage => 2`): on the
  alternate screen over the dimmed browser, or centred within the browser's
  rows when the browser is below the cursor (`drawer` mode `over`); Esc
  returns to the browser as it was, a choice marks the notice ◆ and shows in
  its detail. A 15 s countdown to closing runs until the first key.
- **Open, carried as placeholders:** the headings What? How? Why? in the modal
  and box (the producers' data model decides later); the light background.

Claude's own runs, before review:

- **Unattended**, every view at 120 by 40 to a file (15 runs: the panel with
  each input and a bullet candidate, the glyph sheet, every ask input in each
  form and placement, with answers given ahead and with a record, the browser
  on both screens): exit 0, nothing on stderr.
- **In a tmux pane** (`check-tmux.sh`, 120 by 40, keys sent, the pane captured
  as seen, alternate screen included), replacing the replay through an
  emulator that had no alternate screen: the backdrop rows at their positions
  under the memory modal with the progress row where it was; Shift-Tab moving
  the focus back; a space stopping the countdown with the slot left blank;
  Esc leaving no trace and the run going on; x stopping the run; the pattern
  modal growing from the question to the three-column list, 1 to 3 and ↓
  moving the highlight; the same with `--fixed-height`; the preread modal's
  `s` stopping before the read; the inline modal; the box with q ignored
  (quitting off) and stopping the countdown, Esc taking the default; the box
  pattern list at full width, `2` and Enter choosing; the browser on tab 7
  showing the histogram detail, Enter opening the layered list over the
  dimmed browser (`\e[2m` on the browser's rows in the capture), a choice
  marked ◆, Esc back to the browser; the inline browser's layered list drawn
  within its rows and the browser repainted after it; the browser closing on
  its own after its countdown.

### Architect's feedback on round 4 (2026-10-19)

All 12 entries, verbatim in `feedback/stage1-round4.jsonl`. The framework
reads as right: the panel "looks good", the single-notice panel "amazing",
the memory modal "looks great", the compact box "beautiful, I love it", the
inline modal "unnoticeably different, so perfect for a fallback", the browser
"really great, and the power is starting to come through". The closing entry
carried no separate remarks against the contract; what follows is what
changes.

Across the surfaces:

- **Padding inside every pop-up that will be erased.** One empty row above
  and below the content and two characters of padding left and right, in each
  pane (the modal, the browser's list and detail, the layered modal), so the
  content is easier to read and separate. The question in a modal has an
  empty row above and below it. Between a notice and its histogram in the
  browser's detail, an empty row.
- **The bullet carries the category colour.** Claude changed the bullet to
  the dim colour without asking; the category colour on the bullet carried
  the classification in a single character and is put back.
- **Buttons are centred on text that does not change.** The countdown's
  removal moved the buttons off centre; the width used for centring must not
  change through the run.
- **The column gap in the options list grows with the width.** One space at
  the tightest, up to about five when there is room; columns are not equally
  spaced, the gap expands with the available width.
- **A dense list gets a wider pop-up.** The pattern modal's list, at about
  two thirds of the terminal, was too dense for its content; dense content
  takes the wider tier.
- **No hanging indent** on a notice's continuation rows inside a modal: never
  requested, removed.

By view:

| view | verdict | to change |
|---|---|---|
| panel, 7 notices | looks good; the dash is liked | the bullet back in the category colour |
| panel, one notice | amazing | add, for comparison, the form where the glyph, category, count and how-to-read sit in the top edge, saving a row on a tight terminal |
| bullet glyph sheet | | first choice candidate 7 (U+2576, box drawings light right: a slight indentation under the category glyph, the dash right-aligned); second choice candidate 2 (U+2012, figure dash) |
| modal during the read | looks great | two characters of inside padding left and right; buttons centred; the hanging indent removed; an empty row below the question |
| modal before the read | missed (the countdown ran out) | reviewed again next round |
| modal once a pattern is found | pretty good; the list all good | the buttons' centring; a wider pop-up for the dense list |
| box during the read | beautiful | |
| box once a pattern is found | looks and works good | the column gap growing with the width |
| modal below the cursor | good, perfect as a fallback | |
| browser over the dimmed run | really great | the padding rule above in the list, the detail and the layered modal; an empty row between the notice and the histogram; the bytes histogram added to the detail where the messages data has bytes |
| browser below the cursor | good, as expected | |

## Round 5: round 4's corrections (2026-10-19)

Built after the architect confirmed the read-back, with one amendment at
confirmation: the two characters of side padding apply to every box, erased
or not; the empty rows above and below apply to the pop-ups that are erased.
The settled lines went into the contract first (§ Padding, § Buttons, § The
options list, § Pop-up size, the bullet in § Category sheet).

- **Padding:** `frame()` leaves three cells inside each side edge (the one
  it had and the two asked for) and every component lays its rows out to
  `inside_width()`. The modal and the compact box have an empty row above and
  below their content; the browser's three panes (tabs, list, detail) each
  have one; the layered modal has the modal's. The modal's question has an
  empty row above and below. An empty row separates a notice from its
  histogram in the detail. A single notice inside a modal or box has no
  hanging indent on its continuation rows; under a bullet the continuation
  stays aligned with the text.
- **Bullet:** `╶` (U+2576) in the category's colour, the sheet's first choice;
  the sheet stays in `show.pl bullets` but is no longer a review view.
- **Buttons:** centred on their labels alone (`centred_buttons()`); the
  countdown's slot follows the default button outside the centred width.
- **Options list:** the gap between columns is one space at the tightest and
  up to five, the spare width shared between the gaps and the last column
  (`option_columns()`); the tier is chosen so the last column wraps to no more
  than two rows (`options_unit()`), which takes the pattern modal from medium
  to large at 120 columns.
- **Single notice:** `panel --edge` is the comparison the architect asked for:
  the category's glyph, name, count and how-to-read text in the top edge in
  the category colour, the notice alone inside, one row shorter than the
  headed form. Both are review views.
- **Browser detail:** ltl's duration and bytes histograms side by side, as ltl
  renders two metrics (`-hg duration,bytes -hgh 8` at 90 columns, 14 rows, 85
  cells wide, `notices/histogram.pl` regenerated from a real run), so the
  detail is no taller than before.

Claude's own runs, before review: every view unattended at 120 by 40 (15
runs, exit 0, nothing on stderr); in a tmux pane (`check-tmux.sh`): the
memory modal with Shift-Tab and a stopped countdown; the pattern modal's list
in the large tier with the gap at five spaces, 1 to 3 and ↓; the box pattern
list at full width; the browser on tab 7 with both histograms in the detail
after an empty row, the layered list padded the same, a choice marked and
shown, Esc back; the inline browser's layered list and repaint.

### Architect's feedback on round 5 (2026-10-19)

All 12 entries, verbatim in `feedback/stage1-round5.jsonl`. Settled: the
memory modal ("perfect, they've nailed it"), the single notice with the
category in the top edge ("this is the one, way cleaner": the same visual
language as the pop-ups, one row fewer), the preread modal ("also great"), the
inline fallback. What changes:

- **Padding, corrected and counted.** Two characters inside the sides of a
  pop-up that will be erased; one character for the inline panel that stays
  on screen (the architect withdrew the two for it: with no empty rows above
  and below, the sides follow suit). Round 5 rendered three where two were
  asked: Claude added two to the one that was there. The padding asked for is
  the padding rendered, counted.
- **Each pane, one empty row above and below its content**, in a pop-up that
  will be erased: the options list pane got none above it in round 5. The
  browser's tabs are part of the list pane, not a pane of their own: the rule
  under them goes, and the tabs have an empty row above and below, then the
  list.
- **The histograms at ltl's own size**, side by side as the tool renders two
  metrics at 160 to 180 columns, not crushed into 85 cells: "you had the
  correct size before, I just asked you to add the bytes next to it". An empty
  row before the `chosen:` row, which bumped into the legend.
- **Counts in parentheses everywhere.** The browser's title and tabs carried
  bare numbers where every other surface writes `(N)`: a locked form is
  carried across every surface when it is locked.
- **One empty row before a box drawn below the cursor that will be erased**,
  as the inline modal did; the compact box and the inline browser drew on the
  next row directly. Standardised on the empty row.
- **The process.** Twelve scenarios again, many already validated (the
  fallback shown for every surface), "an inappropriate waste of my time": the
  list must get shorter every round, towards sign-off.

## Lessons learned (worked into `prototype/README.md` § (e) on 2026-10-19)

1. **The review list shrinks every round.** A round shows only the views a
   change touched or something new; a view the architect has validated is not
   shown again, and a mechanism validated on one surface (the fallback
   placement, a key, the padding) is not re-shown on every surface that
   shares it. The list is the measure of convergence: twelve, then twelve
   again, is a round that did not converge (architect, round 5).
2. **A locked form is swept across every surface when it is locked**, in the
   same change, and the sweep is checked against each surface by reading the
   rendering (counts in parentheses, round 5).
3. **What was asked is what is rendered, counted.** A padding of two is two
   cells, measured in the capture before review, not two added to what was
   there; a pane's empty rows are counted in the capture, each pane, each
   edge, not inferred from the code that was meant to produce them (round 6:
   a row count derived from a Perl expression in scalar context dropped the
   list pane's bottom row while the capture that would have shown it was in
   hand and not counted).
4. The lessons recorded at the pause (feature doc § Prototyping): the review
   object is the framework and its contract, not instances; the contract is
   written before instances; every round is read back before building; every
   round ends with its settled lines in the record; Claude's own check
   observes what the architect observes.
5. **A verification method is chosen per surface, against what the first
   delivery uses.** Asked which capture method the harnesses should adopt, I
   offered a choice of tools for every surface at once, with tmux weighed
   against a redirected run as if one had to win. The architect's rule: the
   method follows the surface it targets, the cheapest capture that sees what
   the surface produces, and nothing runs on a platform without its tooling.
   The first delivery prints notices inline, so the first harness is a
   redirected run; the terminal-driving method waits for the surface that
   needs it (2026-10-19).
6. **Tension is found, not manufactured.** Told that a recommendation hid the
   tension behind a decision, I answered by inventing alternatives (a record
   form for redirected runs) that the records had already ruled out. A
   decision goes to the architect when two options are viable or a tension is
   unsettled; when the records settle it, the step is recorded and taken, and
   saying so is the answer (2026-10-19).

## Round 6: round 5's corrections, three views (2026-10-19)

Built after the architect confirmed the read-back; the settled lines went into
the contract first (§ Padding, § Wording, the browser's detail in
§ Components). Shown for review: the panel, the pattern modal with its list,
the browser; nothing already validated.

- **Padding counted as rendered:** `frame()` takes `side`, two cells for a
  pop-up that is erased, one for the panel that stays; the captures count
  one cell after the panel's edge and two after the modal's.
- **Each pane an empty row above and below:** the modal's list pane now has
  its row above (`RULE`, blank, list); the browser's tabs are in the list pane
  (blank, tabs, blank, list, blank), the rule under the tabs is gone.
- **Histograms at ltl's size:** `notices/histogram.pl` regenerated from the
  same run at 170 columns (14 rows, 161 cells); a detail wider than the
  largest tier takes the whole width rather than being cut. An empty row
  before the options or `chosen:` row.
- **Counts in parentheses** on the browser's title and tabs, and the panel's
  title, `notices (7)`.
- **One empty row before an erased box drawn below the cursor:** the inline
  drawer prints it on its first draw and erases it with the box.
- **The single-category panel takes the edge form** by default; `--headed`
  asks for the headed form.

Claude's own runs: every view unattended at 180 by 50 (12 runs, exit 0,
nothing on stderr); in a tmux pane at 180 by 50: the pattern modal's list
pane padded above and below with two cells at the sides, the compact box
below an empty row, the browser full width with both histograms at their own
size, counts in parentheses, the empty row before `chosen:` after a choice,
the inline browser repainted after its layered list.

### Architect's feedback on round 6 (2026-10-19)

Three entries, verbatim in `feedback/stage1-round6.jsonl`. The panel:
"perfect". The browser: "you've nailed it". The pattern modal: the list pane
still lacked its empty row at the bottom, said for the third time, and an
empty row is wanted between the list and the highlighted option's effect row.

## Round 7: the options list's pane rows (2026-10-19)

One view. The cause of the missing row: the stage's row count took a list
in scalar context (the last element's count, not the list's), one short once
round 6 had added the row above the list, so the frame cut its last row. The
count now comes from the rows themselves. The list pane reads: empty row,
headings, options, empty row, the effect, empty row; the body's pane closes
with an empty row before the rule. Checked in a tmux pane at 180 by 50 in
both forms, each pane's rows counted in the capture; every other view ran
unattended unchanged.

### Architect's feedback on round 7 (2026-10-19)

One entry: the pattern modal's list, "yes, you finally got it". No view of
the framework is left unvalidated on macOS.

## Where stage 1 stands (2026-10-19, after round 7)

| closing criterion or item (feature doc § Closing out prototyping, § Prototyping) | state |
|---|---|
| each selected surface judged by the architect in the terminal | done on macOS: the three components, every form and placement |
| a demonstrated way to capture and check each selected surface unattended, for the harnesses and the screenshot tool | demonstrated against known-good and known-bad input (§ Unattended capture below); the options and their costs are before the architect |
| the findings record what was chosen, what was learned and why | this file; the lessons are `prototype/README.md` § (e), the design prototype (2026-10-19) |
| the light background | evaluated and accepted, every component once per form (`feedback/stage1-light.jsonl`) |
| validating the selected components on Linux and Windows (the architect, from his terminals; standard terminal behaviour, so acceptance or a short list of adaptations, not a port) | Windows: accepted by the architect 2026-10-20 after his round and re-check, with the adaptations listed under § Windows validation round below; macOS: the re-check accepted 2026-10-20, dark and light; Linux: not started |
| the producer interface (how code registers a notice or a choice) | not started; designed once the surfaces are chosen, which they now are |
| the modal's and box's list headings | open until the producers' data model is investigated |

### Architect's feedback on the light background (2026-10-19)

Six entries, verbatim in `feedback/stage1-light.jsonl`: every view accepted
("yes, it works", "all good", the compact box's default "nice, that is black
bold"). The category sheet's light colours (the darkest step of each colour's
light gradient) stand. One remark on the browser: Esc and close should be
synonyms as q and x are; its reading is checked with the architect before
anything changes.

## Unattended capture: the method, demonstrated (2026-10-19)

The stage's second closing criterion, a verification-method prototype under
`prototype/README.md` § (d): how a surface is captured and checked by the
harnesses and by the screenshot tool with nobody at the keyboard. The
consumers and their constraints come from the records: a harness reads a
redirected standard output and asserts on cells through
`tests/lib/rendered-output.pl`, never on escape sequences
(`tests/HARNESS-DESIGN.md` § Asserting rendered output); the screenshot tool
draws standard output, chooses rows by `-V section-layout`, refuses any escape
other than a colour code, and runs `ltl` with `--disable-progress`
(`docs/process/screenshots.md`, `features/598-screenshot-capture.md`).

### Two captures, one decoder

| capture | what it is | sees | does not see |
|---|---|---|---|
| **redirected run** | standard output to a file, no terminal: every component draws itself once, as it would appear, in the state an answer given ahead reaches (the options list with its choice highlighted), takes that answer or the default, and emits nothing but rows and colour codes | the surface's content, colours, padding, size; the answer taken | keys, erasing, layering, the dimmed run |
| **pane capture** | the run in a tmux pane of a set size, keys sent as the analyst would, the pane captured with its attributes (`capture-pane -e -p`), alternate screen included | everything the analyst sees at any moment: the dimmed run under a modal, a focus moved by Shift-Tab, the surface erased, a list layered over the browser | nothing of the surfaces; it needs tmux |

Both are read through the repository's own cell decoder;
`capture/assert-surface.pl` adds four predicates over it: `panes` (each pane's
side padding in cells and its empty rows above and below), `unmoved` (the run's
rows outside a pop-up's rectangle at the same rows as before it opened),
`no-trace` (nothing where the pop-up was once it closed, the run's own rows
continuing), `plain` (a redirected run holds no escape but colour, draws the
surface once, and goes on).

### Validated against this stage's own escaped defects

`capture/specimens.sh` runs each predicate on the current build and on the
build that carried the defect it is for, checked out from its commit, and
reports whether the two are told apart. All eight cases came out as expected:

| predicate | known good | known bad | told apart |
|---|---|---|---|
| panes (2 cells at the sides, an empty row above and below) | round 7, the options list | round 6 (commit e6230dd): the list pane lacked its row below, said three times before it was caught | yes: `no empty row below its content` on both panes of the round 6 capture |
| unmoved | round 7, the memory modal | round 3 (commit 4bef110): the dimmed run drawn at the bottom of the screen | yes: `row 2 moved: before '$ ltl ...' / with the pop-up ''` |
| no-trace | round 7, Esc on the memory modal | the same with `--record`, which leaves the notice and the answer on purpose | yes: `3 rows left where the pop-up was` |
| plain | the redirected run | the raw byte stream a terminal receives (tmux `pipe-pane`) | yes: `74 escape sequences other than colour codes` |

Two things the demonstration changed in the prototypes: a redirected run paints
no progress line and no cursor control (as `ltl` under `--disable-progress`);
and with an answer given ahead and no terminal the surface is still drawn
once, in the state the answer reaches, so a harness or the screenshot tool can
look at it.

### The decision: the method follows the surface (architect, 2026-10-19)

I put this up as a choice among tools (redirected run, a hidden frame option,
tmux) for all surfaces at once. The architect reframed it: the harnesses adapt
to the surface they target, and the surfaces are being designed now so the
language can grow; the first delivery and the normal use is notices printed
inline, with no interactivity. For that, the redirected run and the cell
decoder are the whole method, and tmux would be cost without return. tmux
becomes essential when a surface needs the interface driven: navigation,
layered pop-ups, keys. Settled in `features/412-notice-surfaces.md`
§ Unattended runs as a table of surface against method.

Two corrections to what I wrote above. The "skipped on Windows" cost was moot:
the harnesses do not run on Windows at all, for any surface. And the choice is
not fixed per platform: a tmux harness is skipped where tmux is absent, and
the Windows host can be equipped (WSL, Cygwin) so interactive surfaces are
tested there too, an enhancement to the Windows setup when the first such
surface is scheduled.

I had also put up, as "question 1", whether a redirected run should hold the
dialog's frame once (what the prototypes do), the notice in the record form
instead, or nothing. The architect refused the record form: there is no
purpose in a second code path that changes the tool's standard output
depending on where it goes. The redirected run holds the surface as it
appears, drawn once, with the default or the given answer taken; the only
terminal dependence is the one every command-line tool has (no alternate
screen, no cursor control, no key to wait for). That is what the contract's
proposed line already said; the alternatives were mine, made up to show
tension where the records had settled the matter.

The screenshot question follows the same rule: the panel is a section the
tool already draws; how a pop-up is pictured is decided when a pop-up is
delivered.

## The contract becomes the project's (architect, 2026-10-19)

What the rounds settled goes beyond this issue: how input is taken, how
navigation works, which keys do what, and the design language, are patterns of
the application that every future surface reads from. The architect had them
moved out of the feature doc into `docs/design-language.md` (the looks, with
the existing ltl look written up from the code for the first time, since other
surfaces will reapply it even where the new style does not) and
`docs/terminal-interaction.md` (the behaviour), one section per pattern; the
feature doc keeps the locked decisions and points at them. The references to
"the contract" in the rounds above describe the document as it was while the
rounds ran.

## Windows validation round (2026-10-20)

Run on Windows 11, Strawberry Perl, in a new Windows Terminal window, then a
classic console window (`conhost.exe`); screens captured, not typed into. The
round did not reach the architect's judgement: the review was unreadable from
its first screen, for two faults of these scripts, not of the platform.

- **The code page.** A new Windows Terminal window starts on code page 437.
  `review.pl`, `show.pl` and the prototypes mark their output UTF-8 but never
  set the console to 65001, as `ltl` does at startup. Every non-ASCII
  character arrived as its UTF-8 bytes read under 437 (`│` as `Γöé`, `·` as
  `┬╖`), two or three cells each, so the panel's rule wrapped onto three rows.
  With `chcp 65001` first, `perl show.pl panel` rendered as on macOS: frame,
  rounded corners, colours, dim, bold.
- **`stty`.** `review.pl` calls `system('stty', 'sane')` after each view;
  Windows prints `'stty' is not recognized as an internal or external command`
  into the review.

Both fixed the same day: `lib/NoticeProto.pm`, which every prototype and
`show.pl` load, `review.pl` and `replay.pl` set the code page as `ltl` does,
and `review.pl` resets the terminal with Term::ReadKey's `ReadMode('normal')`.
From a new window on code page 437, the review's first screen and
`perl show.pl panel` then rendered as on macOS.

Seen once the code page was set:

- `⚠`, `⚙` and `⏱` of the category sheet are drawn by Windows Terminal as
  colour emoji two cells wide over a one-cell slot, covering the space after
  them (`⚠DATA ANOMALY`); the text-presentation selector does not change it.
  `≈`, `↻`, `➤`, the bullet `╶`, the arrows and every box and block glyph are
  one cell. In the classic console host the three are monochrome and still
  cover the next cell, and `↻` is a missing-glyph box in the panel's bold,
  coloured heading though it is drawn in plain text.
- Windows Terminal renders every SGR sequence the prototypes use without a
  `SetConsoleMode` call; the classic console host prints them as text.
  `WT_SESSION` is inherited by a classic console window started from inside
  Windows Terminal, so it does not tell the two apart. These answer open
  points 5 and 6 of `features/412-notice-surfaces-research.md` § 6.

`review.pl` now loads `lib/NoticeProto.pm`, which prepares the console as
`ltl` does (`system("chcp 65001 > nul")`, whose `cmd.exe` leaves VT
processing on); `perl show.pl panel` renders in colour in a classic console
window too. An explicit `SetConsoleMode` call through Win32::API was tried
first and removed, since it duplicated what the `chcp` call already does. Replacement glyphs
for the three were tried in both terminals; the results are the glyph table
of `docs/terminal-output.md` § Glyphs and width. On Windows the category
sheet now takes `▲` for data anomaly, `⛭` for your options (the architect's
pick, from the classic console capture) and `⧖` for runtime condition. In
`perl show.pl panel` in Windows Terminal each is one cell in its category's
colour; in the classic console `▲` and `⛭` are, while `⧖` and `↻` are
missing-glyph boxes in the bold headings.

The architect then saw `➤` of guidance reaching into the next cell in
Windows Terminal, which the measurement above had passed as one cell. Of the
right-pointing candidates printed in both terminals, `►` (U+25BA), `▸` and
`›` were one cell in both; the architect chose `►`, and the category sheet
takes it on Windows.

`▲` for data anomaly and `⧖` for runtime condition were Claude's picks, never
the architect's. In his own Windows round the architect chose `△` (U+25B3),
one cell in its colour in both terminals, for data anomaly.

Every non-ASCII character the prototypes and `ltl` draw, 74, was then printed
in both terminals (the table in `docs/terminal-output.md` § Glyphs and width).
In Windows Terminal only the three emoji glyphs fail. In the classic console
`↳ ↻ ⎯ ▶ ⧖` and the blocks `▁ ▂ ▃ ▅ ▆ ▇` were drawn in some windows and
missing-glyph boxes in others; what decides it is not isolated.

`ltl` itself renders its colours in a classic console window: its startup
`system("chcp 65001 > nul")` runs `cmd.exe`, which leaves VT processing on
(console mode 0x0003 before, 0x0007 after, read through `GetConsoleMode`).
An earlier line of `docs/terminal-output.md` said `ltl`'s colours reach a
classic console as text; that was inferred from a script that starts no
subprocess, never from running `ltl`, and it was wrong.

The rules drawn from these are `docs/terminal-output.md`.

### Keys, a first pass by script (2026-10-20)

Each view was started with `perl show.pl` in its own Windows Terminal window
and driven with keystrokes sent to that window only, the screen captured
after each key; the architect's own judgement of the views is still to come.

| view | keys sent | seen |
|---|---|---|
| modal, during the read | → ← Tab Shift-Tab, `z`, Esc, Enter | ← and Tab move to Stop here, → and Shift-Tab back; Tab stops the countdown and its bracket goes; `z` changes nothing; Esc erases the modal and the run carries on; Enter on Continue reading continues |
| modal, countdown left to run out (`--seconds 4`) | none | the default taken, the run completes |
| modal, quitting | `x`, then a typed command | the run stops with `Stopped: the analyst quit (q/x).`; the command typed afterwards echoes and runs |
| modal with its options list | `l`, ↓ j k, `2`, Enter | `l` opens the list on Continue as planned; ↓ wraps to 1, j k move; `2` then Enter chooses Isolate this API (`-i GetDateAndTime -hg`) |
| compact box | `C`; separately Esc | the upper-case letter chooses Continue reading; Esc takes the default; the box is erased either way |
| notice browser | `3`, ↓, `7`, Enter, Esc, Esc | the digits pick the tabs; ↓ moves the highlight; Enter on a guidance item opens the layered options list over the browser; Esc goes back to the browser as it was, then closes it |
| modal and browser below the cursor | Esc; Tab, Esc | drawn below the run and erased on Esc |

Every key decoded. Two things to look at:

- **The dimmed copy of the run under an alternate-screen modal stood 3 to 4
  rows lower than the run itself** (the `Processing 40%` row and the summary
  table above it, in all three modal captures), where
  `docs/terminal-interaction.md` § Where a component is drawn has "every row
  kept at the position it had, the live row included". Cause: the cursor
  position report never arrived. Term::ReadKey read one `00` byte in its
  place, because the console's input handle lacked
  `ENABLE_VIRTUAL_TERMINAL_INPUT`, so `backdrop_layer()` fell back to the
  bottom row. `raw_mode()` now sets the flag on Windows; with it the report
  reads `ESC [ 2 ; 1 R`, and the copy's rows stand where the run's were, in a
  window of 120 by 29 and in a maximized one, with ← Tab Shift-Tab Esc still
  decoding.
- After the browser below the cursor closes, the window shows only the rows
  after it: the run's rows above have scrolled out of view, the browser being
  taller than the space below the cursor. Whether macOS does the same is not
  known.

### Light background, by script (2026-10-20)

Maximized Windows Terminal windows on its built-in "One Half Light" scheme
(`wt --colorScheme`, the architect's settings untouched), each view with
`--bg light`: the panel, the modal (Tab, Esc), the options list (`l`, ↓, Esc)
and the browser with the layered options list (`7`, Enter, Esc, Esc). Every
glyph is one cell in its light colour, the keys decode, and the browser's
histograms show at `ltl`'s size side by side in the maximized window.

One thing does not hold: **the dimmed copy of the run under a modal is not
dimmed.** Its text measures RGB 28,29,33 against the scheme's foreground
#383A42 (56,58,66), about half its brightness: Windows Terminal renders faint
(SGR 2) by darkening the colour, which on a light scheme takes text towards
black instead of towards the background. On the dark scheme the same
sequence greys the copy as designed.

The architect also saw emphasised text in the notices lose its emphasis, and
the histograms under the layered options list lose their colour. Both are
measured in `docs/terminal-output.md` § Colour and emphasis: Windows Terminal draws bold
in a basic colour as its lighter bright variant in the normal weight, and the
prototypes' dimmed layer stripped every colour (`strip_sgr`) before applying
faint. The architect locked D10 (on a light background secondary text is an
explicit grey; a dimmed layer keeps its colours). Since then `style_for()`
gives light text and emphasis as 256-colour black and secondary text as grey
244, and `dim_row()` dims a layer with its colours kept. Measured after the
change, in maximized windows: on light, the focus and statement black
(0,0,0) with the focus bold, evidence and the dimmed backdrop grey (128); the
browser's text under the layered list from black to 127 on light and from 204
to 102 on dark, its histograms in their own colours, dimmed, on both; the
colours back in full when the list closes.

### Architect's feedback on the Windows round (2026-10-20)

From `feedback/stage1-windows.jsonl`, `perl review.pl --round windows` in
Windows Terminal:

| option | feedback |
|---|---|
| panel | "excellent - finally got to compatibility with macOS" |
| panel-one | "not convinced about the bullet glyph in Windows. I don't recall the color being this on on macOS - make sure that they are the same colors across environments. Otherwise all good." |
| modal-read | "whole screen is flickering when the countdown remaining time is updated. Make sure that any refreshes are differential - you cannot update the entire screen just for a single character!" |
| modal-quit | "at the redraw ... you are first drawing the dimmed background, then re-drawing the modal dialogue over top of it, which is causing the modal dialogue to be cleared and redrawn, and we can see what is behind it ... this is not allowed for a TUI" |
| modal-pattern | "Functionally it works as expected, but same issue on the redraw, while navigating the list, I can see the text from the background coming through as the modal window is erased and fully redrawn." |
| modal-inline | "Yes, perfect" |
| box-read | "Perfect" |
| browser | "Escape to close does not erase the dialogue!!!! ... Same issues as seen throughout with the redrawing." |
| browser-inline | "Good. However in the detail pane, there should be an additional vertical space below the category heading and the notices themselves in the dialogue versions which are erased. This is obviously uniform across platforms and virtual screen-based or fallback method." |
| light | "It's not possible to switch to a light profile browser during the same orchestrated run, however I already watched your light background terminal tests, and the current state is excellent." |
| contract | "No comment" |

What the code shows for the redraw: every alternate-screen draw in
`draw_rows()` clears the screen (`\e[H\e[2J`), repaints every dimmed layer
under the surface, then the surface, so a countdown tick or a key in a list
repaints the whole screen. The browser's Esc did not reproduce in a run of
`perl show.pl browser` started on its own: one Esc in the list closed it and
gave the screen back.

### Built from the Windows round's feedback (2026-10-20)

- **Redraw by difference.** The alternate screen is now held as one composed
  row per terminal row (the dimmed layers, the surface over them); a draw
  rewrites only the run of cells from the first to the last changed cell of
  each changed row, in place, with no clear. Measured on two draws a second
  apart, 120 by 30: the first writes 28 rows (the screen opening), a
  countdown tick writes one span of two characters (` 9`), a Tab writes the
  button span alone.
- **Esc in the browser after the layered options list.** The layered list
  opened its own alternate screen and left it on closing, so the browser
  went on drawing on the normal screen and its close had nothing to undo.
  A surface layered over another now shares its parent's alternate screen;
  the parent repaints itself in place when the layer closes. The architect's
  sequence (7, Enter, ↓, ↑, Esc, Esc) now ends with the run's screen back.
- **The detail pane** has an empty row between the category heading and the
  notice.
- **Category colours on a dark background.** Four categories had their ltl
  colour as a basic code (`35`, `36`, `34`, `32`), which Windows Terminal's
  scheme repaints (its "cyan" is a blue). From a sheet of 256-colour
  candidates shown in both Windows terminals the architect chose 170 for
  figure caveat, 44 for your options, 33 for decision taken for you and 40
  for guidance, on every platform.
- **The bullet on Windows** is `—` (U+2014), the architect's choice from the
  bullet sheet drawn in panels in Windows Terminal, after `‒` (U+2012) was
  rejected in context; elsewhere it stays `╶`.

### Architect's re-check on Windows (2026-10-20)

modal-read, modal-quit, modal-pattern: no flicker. browser: "yes, perfect".
modal-inline: "there wasn't previous flicker here - not sure why you are
asking me to redo this test" (the re-check was started with `--from` and so
ran views that had not changed; a re-check names the changed views alone).
box-read: "There are 2 empty lines above the compact box, that is not a part
of what we've agreed to in the requirements." browser-inline: "it too like
compact box has way too many empty lines before it which does not meet
requirements."

Cause: a surface below the cursor always cleared the cursor's row and moved
down, adding an empty row even where the row above was already empty (the
run's blank row before the progress line), and `show.pl` printed a newline of
its own before the browser. Now the surface starts on the cursor's row when
the row above is empty and adds the empty row only otherwise, and the extra
newline is gone; rows are overwritten in place with the line's tail cleared
after them. Measured on screen rows: one empty row above the compact box, the
modal below the cursor and the browser below the cursor; after Esc the
progress row resumes on its own row.

Confirmed by the architect: box-read "Yes, that's correct now"; browser-inline
"yes, good". The Windows round is accepted. Changes that reach macOS and
await a look there: on a light background, text and emphasis as 256-colour
black and secondary text as grey 244 (D10); dimmed layers keeping their
colours; the dark category colours 170, 44, 33, 40; redraw by difference;
the detail pane's empty row under the heading; one empty row above a surface
below the cursor.

### Architect's re-check on macOS (2026-10-20)

The views the Windows round's changes reach, shown alone (`review.pl --round
mac`, feedback in `feedback/stage1-mac.jsonl`): the panel with the dark
category colours 170, 44, 33 and 40, "yes, good"; the modal redrawn by
difference, "good"; the compact box with one empty row above it, "good"; the
browser's detail pane row and the layered list's close, "good"; the browser
below the cursor, "Good". The dark-background changes are accepted on macOS.
From a light profile, later the same day: the panel with text as 256-colour
black and secondary text as grey 244 (D10), "good"; the modal with the dimmed
run keeping its colours, "good". Every change the Windows round made is
accepted on macOS; the framework stands validated on both platforms, dark and
light.

### Claude's runs on Linux, before the architect's round (2026-10-20)

Ubuntu, Perl 5.40.1, Term::ReadKey 2.38, tmux 3.6, `C.UTF-8`; no Homebrew.

- **In a tmux pane** (`check-tmux.sh`, 120 by 40): all 12 scenarios exit 0.
  The modal's rows outside the dialog unmoved; ← → Tab and Shift-Tab move the
  focus; any key stops the countdown; Esc gives the run back; x stops the run
  with `stty -g` identical before and after, the cursor visible, the alternate
  screen off and typing echoed. The options list: ↓ wraps, a digit chooses,
  Enter takes it. The compact box: one empty row above it. The browser at 180
  by 50: tab 7 draws both histograms in full; the sequence 7, Enter, ↓, ↑, Esc,
  Esc ends with the run's screen back.
- **Capture method** (`capture/specimens.sh`): the eight known-good and
  known-bad cases come out as on macOS. `panes` passes on every capture of a
  surface drawn alone.
- **Redirected runs**, every view at 120 by 40: exit 0, nothing on stderr, `plain`
  passes on each.
- **Glyphs**: the 23 non-ASCII characters the views draw, glibc `wcwidth` 1
  for each. The dark category colours are 170, 44, 33 and 40; the basic codes
  left are the backdrop's banner and status lines, copied from `ltl`.

Not of this platform: `check-tmux.sh` and `capture/specimens.sh` call
`brew --prefix` unconditionally and print `brew: command not found` where it
is absent (filed as #750, a workaround of the environment setup to be
addressed across the repository); the `browser-cd` scenario captures at 7 s a browser that opens at
3.5 s and closes on its 3 s countdown, so its `up` capture shows the run
after it. What these runs cannot show is the architect's terminal and font:
`perl review.pl --round linux`.

### Architect's feedback on the Linux round (2026-10-20)

From `feedback/stage1-linux.jsonl`, `perl review.pl --round linux`; light and
the platform remarks not given:

| option | feedback |
|---|---|
| panel | "Mostly OK, however the box drawing is showing here as it was initially with macOS where the lines are not contiguous. During the prototyping on macOS, I am not sure what you did after having starting to look at actually what was rendered, but you changed how the boxes with the rounded corners were drawn and they got a 10X improvement. Here, what is displayed in Linux is very legacy from our prototyping efforts. Otherwise the glyphs, colors, are all good." |
| panel-one | "same comment as last one. the bullet character is a bit small. maybe it should be widened to the em dash?" |
| modal-read | "Fine - smae issues on box drawing" |
| modal-quit | "Fine" |
| modal-pattern | "fine - same comments" |
| modal-inline | "yes, works" |
| box-read | "works, available key list does not include the Esc like the specification mandates" |
| browser | "works" |
| browser-inline | "works" |

What the code shows for the box drawing: the frame is written with the same
characters and codes in round 3 (commit 4bef110) as now: `─ │ ╭ ╮ ╰ ╯`
(U+2500, U+2502, U+256D to U+2570) in colour 90, byte for byte the same in
the two panels' redirected runs. Between round 3 and round 4 nothing in how
the frame is drawn changed; whether its lines join is decided by the terminal
that renders them (its font, and whether it draws box-drawing characters
itself).

The compact box's key bar: `s/c: choose` alone comes from the defaults table's
"the choice letters only", a line Claude wrote (commit 5b3eb47); the Esc row
of the key map (Esc closes the surface and takes the default) applies to every
surface, and the box takes Esc.

### Terminal detection (2026-10-20)

The architect, after the Linux round, from macOS Terminal over SSH: the
prototypes need terminal detection and handling as comprehensive as Windows
forced, done now, within this issue. The prototypes adapt by operating system
(`$^O`), so a Linux host drawn by macOS Terminal gets the Linux choices; over
SSH the host's environment does not carry `TERM_PROGRAM` (this host sees
`TERM=xterm-256color`), while the terminal's answers to queries reach the
program wherever it runs.

`probe-terminal.pl --label NAME` records what the program can learn, into
`terminals/NAME.json`: the environment, the terminal's answers to the device
attributes, name-and-version and colour queries, and the cells it advances
for every glyph the surfaces draw; then it draws the frame and the bullets to
be looked at. Checked in a tmux pane on this host: tmux answers the name query
(`tmux 3.6`), not the colour queries, and every glyph is one cell.

Run by the architect (2026-10-20), files under `terminals/`:

| run | terminal's identity answer | background | `TERM_PROGRAM` | glyphs not one cell | frame lines, as seen |
|---|---|---|---|---|---|
| `mac-pro-ssh`: macOS Terminal, profile Pro, SSH to this Linux host | `1;95;0` | black | absent | none | vertical bars broken between rows; rounded corners about one pixel low |
| `mac-clear-dark-local`: macOS Terminal, profile Clear Dark, on another Mac | `1;95;0` | dark blue-grey | `Apple_Terminal` 470.2 | none | joined, rounded corners in line |
| profile Pro, on the Mac without SSH | | | | | broken, as over SSH (the architect) |

A second run in the Pro window over SSH was the same as the first in
everything but its time and is not kept.

- **The broken lines come from the profile, not from the program or SSH.**
  The same terminal, the same characters and the same widths join in Clear
  Dark and break in Pro, locally and over SSH alike. Breaks between rows of
  vertical bars are a line height taller than the font's `│`; corners off the
  line are drawn from a fallback font. No query reaches a profile's font or
  spacing, so detection cannot see this, and no handling in the program
  corrects it.
- **The terminal is identified by its answer, over SSH too:** macOS Terminal
  answers the secondary device attributes with `1;95;0` and ignores the name
  query; tmux answers both (`84;0;0`, `tmux 3.6`). The environment names the
  terminal only on the machine it runs on.
- **The background is read from the terminal** (the colour query answered in
  every macOS Terminal run), so a dark or light background can be known
  without the analyst saying so.

The fonts (the architect): Clear Dark uses SF Mono Terminal Regular 12, Pro
uses Monaco 10. With the Pro profile switched to SF Mono Terminal the frame's
lines join: the cause is the font, confirmed. SF Mono Terminal needs
anti-aliasing on to read well. Recorded in `docs/terminal-output.md`
§ Glyphs and width.
Monaco stays the architect's terminal font (2026-10-20): a frame drawn in a
font without the box-drawing set is a case the surfaces have to handle, open.

Built (the architect: identity and background only, glyph width settled by
taking no glyph wider than a cell): `terminal()` in `lib/NoticeProto.pm` finds
the terminal and the background once; the Windows category glyphs and the
Windows bullet follow the Windows terminals instead of `$^O`; the background
is the terminal's unless `--bg` is given; `perl show.pl terminal` prints what
was found and from what. Checked: in a tmux pane, `tmux` from `TERM_PROGRAM`
and, with it unset, from the name reply; the measured colour replies (black,
dark blue-grey) read dark, white and cream light; the redirected runs of every
view and the tmux captures of every scenario are unchanged but for the
compact box's key bar. The rule is `docs/terminal-output.md` § The terminals.

In macOS Terminal, profile Pro, over SSH to the Linux host (the architect,
2026-10-20), `perl show.pl terminal`: terminal `Apple_Terminal` from the
identity reply `1;95;0`, background dark from the colour reply (luminance
0.00), the category glyphs ⚠ ≈ ⚙ ↻ ⏱ ➤. The Windows branch awaits a check on
Windows.
