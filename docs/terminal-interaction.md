# Terminal interaction

How a surface of `ltl` that presents something or asks something behaves: the
components, the keys, how input is taken, how a pop-up is sized, placed, padded
and erased, and how a surface is captured when nobody is at the keyboard. One
section per pattern, so that a new surface is built from this document and an
existing one is changed against it. `docs/design-language.md` is its companion
for how a surface looks; `docs/terminal-output.md` holds what output does per
platform (encoding, escape sequences, terminal commands). This is a developer
document and is not part of the wiki.

**Status.** Settled by the architect in the prototyping of #412 (notice
surfaces: presenting notices and capturing the analyst's choices), 2026-10-19,
after seven review rounds on macOS, dark and light, and validated on Linux
and Windows on 2026-10-20. Nothing in `ltl` implements it yet; the first
delivery builds all three components, each reached by a real producer (D16).
The locked decisions (D4, D5, D7, D8, D10 to D16) are in
`features/412-notice-surfaces.md` § Locked decisions, which remains their
authority; answers given ahead are #748 (take the analyst's input at choice
points, with a default and answers given ahead). The data model and the
producer's contract, how code anywhere in the run registers a notice or a
choice, are `docs/notice-surfaces.md`.

---

## Independent of look

These patterns are a layer over whichever look a surface takes
(`docs/design-language.md` § Two looks, one choice per surface). They were
validated on the notice surfaces in the new style, and they apply as they
stand to a surface in the ltl look: scrolling the summary table's message list
with the same keys is the model case, interactivity added on top of the
existing table rather than a new surface for the same data. Each pattern is
implemented once and called by every surface that uses it, so a change to a
key, a countdown or a selection behaviour reaches every consumer and every
future consumer (architect, 2026-10-19).

## Components

Three, and only three. Every moment of the run calls one of them with its own
content; no moment has a presentation of its own (D5). Which component a
moment uses is the choice of the feature that calls it.

| component | for | what the caller passes |
|---|---|---|
| **panel** | presenting the notices known once the data work is done, before the charts, with nothing to answer | the notices |
| **ask** | a question put to the analyst during the run, with a default and a countdown, which may lead on to a list of options (the second stage) | the category; one or more notices; the question; the buttons and which is the default; the seconds to the default; the options list with its headings and default, when the choice has a second stage; the preferred placement (alternate screen or below the cursor) and the compact form; whether to leave a record (D4); any parameter of the defaults table it wants otherwise |
| **browser** | many notices, or notices worth exploring, in a navigable list with a detail pane | the notices; the preferred placement; a detail renderer for a notice that has more to show than its parts (a histogram, a selection). A detail that carries ltl's histograms carries them at ltl's own size, side by side as the tool renders two metrics (the bytes histogram beside the duration one where the messages carry bytes), which needs 160 to 180 columns |

A notice is the same record everywhere, the notice record of
`features/412-notice-surfaces.md` D13: its category; a focus (what it is
about: an API, a time range, a count); a statement; evidence, zero or more; a
remedy; the producer that raised it; its immediacy and visibility; and, when
it carries a choice, the question, the buttons, the headings and the list of
options, with the answer once given (D12). An option carries a key, its parts
under the producer's headings (D8), the command options that apply it, and
its effect in one line. The ask call adds presentation only: placement, the
compact form, the seconds, whether to leave a record (D14).

---

## Keys

One key map on every component, following common terminal practice. Moving and
choosing, wherever the action exists:

| key | in a list (options, notices) | between buttons or tabs |
|---|---|---|
| ↑ ↓ | move the highlight one row | |
| j k | the same, for terminals without arrow keys | |
| PgUp PgDn | move a page | |
| ← → | | move the highlight one button, or one tab |
| Tab | | next button or tab, wrapping round |
| Shift-Tab | | previous button or tab, always Tab's reverse |
| 1 to 9 | choose the n-th row directly | choose the n-th tab directly |
| Enter | activate the highlighted row | activate the highlighted button |
| a choice letter | | the caller passes the key character of each option; that letter is underlined in the option's printed label, marking it as the choice code; accepted in either case, so Shift or Caps Lock does not matter |

Leaving:

| key | does |
|---|---|
| Esc | closes the surface, erasing it, and takes the default: "I am not choosing, get me out of this screen"; in the browser, back from a detail to the list, then from the list to closing. Esc alone: no letter closes, since a letter would collide with a caller's choice letter |
| q, x | synonyms with one explanation, "quit/exit the application": the surface is cleared and the run stops cleanly, where the analyst would otherwise reach for Ctrl-C; a parameter, on by default, with its default per use in the table below |
| any other key | stops the countdown and nothing else (D7) |

### The key bar

Each component shows the rows above that apply to it. Every entry is written
`keys: action`, the same shape throughout, so a pair of keys never reads as a
key and an action.

| component | key bar |
|---|---|
| ask, first stage | `←→ Tab: move · Enter: choose · Esc: continue reading · q/x: quit` where quitting is on; the choice letters underlined in the buttons |
| ask, compact box | each choice letter with its action, then Esc: `s: stop here · c: continue reading · Esc: continue reading`; `· q/x: quit` where quitting is on |
| ask, options list | `↑↓ j k: move · 1-N Enter: choose · Esc: continue as planned · q/x: quit` |
| browser, list | `↑↓ j k: move · ←→ Tab: tabs · 1-N: tab · Enter: options · Esc: close · q/x: quit` |
| layered options list over the browser | as the options list, with `Esc: back` |

---

## Taking input

- **Every choice point has a default.** A run with nobody at the keyboard
  neither hangs nor varies: the default is taken when the countdown ends, when
  Esc is pressed, or at once when there is no terminal to wait on.
- **Answers given ahead** (#748): a choice can be answered on standard input or
  by a hidden option before the choice point comes up; the surface is drawn in
  the state the answer reaches, and the answer is taken.
- **Two stages** (D8): a complex choice first asks whether to look at the
  options or continue as planned, a yes or no defaulting to continuing; only a
  yes leads to the options list. The second stage is measured with the first,
  so the surface does not change size at the transition.
- **Observable**: the `-V notices` section (D15) records each choice point
  in the block of the record that carries it, `choice: yes`, with the answer
  taken and how (a key, the default after the countdown, given ahead, or
  quit), so a harness asserts the outcome without reading the rendering; there
  is no separate section for choices.
- **Quitting** with q or x ends the run cleanly, the surface cleared first.

### Countdown (D7)

The seconds left are shown dim in brackets beside the default button and
redrawn each second, in a fixed-width slot so nothing moves. Any key that is
not a choice stops it; the bracket disappears and nothing is said. It never
resumes, and no surface reports its state: its disappearance is the whole
signal.

### Buttons

The default button is the rightmost and is highlighted when the surface
appears; the countdown sits beside it. The other buttons stand to its left in a
fixed order: the action that stops or leaves (Stop, Cancel) leftmost, the
action that goes further (Look at the options) between. Labels are the
caller's; positions are not. Enter activates the highlighted button; the choice
letter the caller passes is underlined in the label and is a shortcut to it.
The buttons are centred on their labels alone; the countdown stands beside the
default button outside the centred width, so nothing moves when it stops.

### The options list (D8)

One row per option; the highlighted option's parts beside it in columns headed
What? How? Why? by default. The headings are parameters of the consumer, and a
consumer whose options have fewer parts gets two columns or one. The why comes
from the producer as part of the notice, not from the surface. The gap between
the columns grows with the width available, one space at the tightest, up to
five when there is room; the columns are never equally spaced. The columns
before the last take their widest part; the last wraps. An empty row stands
between the list and the highlighted option's effect.

---

## Parameters and their defaults by use

Every parameter has a default per use, so that a caller passes only what it
wants otherwise, and a compact surface is not cluttered with what a full one
shows. The uses are the three components, the ask component in its two forms.

| parameter | ask, modal | ask, compact box | browser | panel |
|---|---|---|---|---|
| placement | alternate screen; below the cursor as fallback | below the cursor | alternate screen; below the cursor as fallback | inline, in the run's output |
| size | smallest fitting tier | to its content, full width | smallest fitting tier; height from the tallest detail | to its content |
| quit with q/x | on | off | on | not applicable |
| key bar | full | the choice letters, each with its action, and Esc | full | none |
| countdown to the default | 10 s | 10 s | 15 s | none |
| choice letters | from the caller, underlined | from the caller, underlined | none in the list itself; a selection on an item may open an ask modal on top of the browser, whose own choice letters then take effect | not applicable |
| headings of the options list | the producer's; What? How? Why? when none are given | as the modal | as the modal | not applicable |
| record left after answering | off | off | not applicable | not applicable |
| top edge | category, count, how to read it | category, count, how to read it | `notices` and the count | `notices` and the count; a single category takes the edge form |

### Layered surfaces

A selection on an item in the browser may open an ask modal on top of the
browser, with its own selection and options. The modal's keys and choice
letters take effect while it is up, Esc goes back one layer, and the browser
is back as it was when the modal closes. A notice answered there is marked `◆`
in the list, and its detail shows what was chosen (round 4). While the modal is up the browser
under it is dimmed with its colours kept, its histograms included (D10). A
layered modal is a pop-up and takes a pop-up's padding and size.

---

## Size, placement and padding

### Pop-up size

| tier | width | height |
|---|---|---|
| small | 50% of the columns, at least 44 | to its content, at most 30% of the rows |
| medium | 70% | to its content, at most 50% |
| large | 90% | to its content, at most 80% |

The surface measures what it has to show and takes the smallest tier in which
its longest unbreakable unit fits and its wrapped content does not exceed the
height; for an options list the unit is the width at which its last column
wraps to no more than two rows, so dense content takes a wider tier. The
measure includes the top edge's text and the key bar. A caller may name a
tier. The browser takes the full width when its widest detail exceeds the
large tier. A surface never changes size while it is shown: the browser's
height is computed from its tallest detail before it is drawn, and the second
stage of a choice is measured with the first; the one exception is a caller
that asks for a fixed height, which then holds blank rows in the first stage.

### Where a component is drawn (D5)

- **Alternate screen**: centred, over a dimmed copy of the rows the run has
  printed, every row kept at the position it had, the live row included, and
  every colour kept, dimmed (D10). The
  copy is placed from the cursor position report (CSI 6n), so the progress row
  does not move.
- **Below the cursor**: drawn into rows reserved under the cursor, the fallback
  when the alternate screen is not wanted or not available; one empty row
  precedes a box that will be erased, and where the row above the cursor is
  already empty the surface starts on the cursor's row and adds none, so two
  empty rows never stand above it (architect, 2026-10-20, from the Windows
  re-check).
- **The compact form** of ask is a box below the cursor whose top edge carries
  the category, the count when there is more than one notice, and how to read
  the category, with the question on its last inside row.
- **Inline**: the panel joins the run's output where it is printed.

### Padding

A pop-up that will be erased (the modal, the compact box, the browser, a
layered modal) has two cells of padding inside its left and right edges and one
empty row above and below the content of each of its panes; the padding is
counted as rendered, two cells, not two added to a space already there. A box
that stays on screen (the panel) has one cell inside each side and no empty
rows. A modal's question has an empty row above and below it; the compact
box has an empty row between its notices and the question (rounds 3 and 4).
The browser's tabs belong to its list pane: an empty row above and below the tabs, then the
list, no rule between. In a detail pane an empty row separates the category
heading from the notice under it (architect, 2026-10-20, from the Windows
round), a notice from a histogram under it, and the chosen or on-offer row
from what is above it.

### Redrawing

A surface that changes while it is shown (a countdown tick, a move in a list,
a stage change) rewrites only the cells that changed, overwriting them in
place; nothing is cleared first and nothing is repainted that did not change,
so what lies behind a pop-up never shows through it (architect, 2026-10-20,
from the Windows round). A surface layered over another draws on the same
alternate screen and leaves entering and leaving it to the outermost surface.

### Erasing and the record (D4)

A component that asks erases itself once answered, leaving the cursor where it
was; on the alternate screen, the screen is given back as it was. With the
record flag, the notice and the answer are left as inline text in the ltl look
in the rows the surface occupied, nothing else.

---

## Unattended runs and how a surface is tested

**One rendering, with or without a terminal.** A surface draws the same rows
whether standard output is a terminal or a file; the only difference is what
every command-line tool has: no alternate screen, no cursor control and no
waiting for a key when there is none, so the surface appears once and the run
goes on with the default or the answer given ahead. There is no second code
path that changes the tool's standard output.

**The test method follows the surface it targets.** A harness or the
screenshot tool uses the cheapest capture that sees what the surface produces;
no method runs for a surface that does not need it, and nothing runs on a
platform that lacks the method's tooling.

| surface | what a run with no terminal holds | capture and check | screenshot |
|---|---|---|---|
| panel (notices inline, the first delivery and the normal use) | the same rows as in a terminal | redirected run, read through the cell decoder (`tests/lib/rendered-output.pl`), as every harness today; outcomes from `-V` | the panel's rows as a section through `-V section-layout`, as `process/capture-screenshots.pl` works today |
| a surface that asks (modal, box, options list) | the same surface drawn once, as it appears, in the state the given answer reaches, the default or that answer taken; nothing but rows and colour codes | the frame's cells and the `-V notices` blocks with `choice: yes` by redirected run; its behaviour (keys, erasing, the run unmoved under it, layering) in a tmux pane with keys sent, only once such a surface is delivered | decided when such a surface is delivered: the frame from a redirected run as a section, or a pane capture for the pop-up over the dimmed run |
| browser (navigation, layered pop-ups) | its first frame drawn once, as it appears | as the asking surfaces: redirected run for outcomes, tmux pane for navigation and layering, only once delivered | as above |

The pane-capture method is demonstrated, with predicates for pane padding, the
run's rows unmoved under a pop-up, no trace after it, and a plain redirected
run, each shown to tell a known-good build from the one that carried the
defect it is for, in `prototype/412-notice-surfaces/findings.md` § Unattended
capture. Its predicates enter `tests/lib/` when the first harness needs them.

**Platforms.** The harnesses run on macOS and Linux, never on Windows
(`docs/toolchain-guidance.md`). A harness that needs tmux is skipped where tmux
is absent and runs elsewhere; the better remedy, equipping the Windows
development host with WSL or Cygwin so interactive surfaces are tested there
too, is an enhancement to the Windows setup, to be filed when the first
interactive surface is scheduled.

---

## Owning records

- `features/412-notice-surfaces.md`: the locked decisions and the prototyping
  record; `prototype/412-notice-surfaces/findings.md`: the rounds that settled
  each line, with the architect's feedback per round.
- #748 (take the analyst's input at choice points, with a default and answers
  given ahead): how answers given ahead are supplied; the `-V` record of
  each choice point is the `-V notices` section (D15).
- `tests/HARNESS-DESIGN.md` § Asserting rendered output: cells, never escape
  sequences; `docs/process/screenshots.md`: how the screenshot tool sees output.
