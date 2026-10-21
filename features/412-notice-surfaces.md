# Notice surfaces: how the run tells the analyst what to know, and asks (#412)

## Overview

The analyst is told what they need to know about their run before they draw
conclusions from its figures, and is asked for a choice where the run can act
on one. This issue designs the notice surfaces that do this: interfaces that
present information and may capture the analyst's input or choice, adapted to
different situations and to different moments of the run. The deferred notices
shown before the timeline, the tables and the charts are one of them, presented
by category, the category telling the analyst how to read each notice.

Today each producer prints its own finished text to standard error at the
moment its condition is detected. The surfaces replace that with one producer
interface and a coherent presentation.

## GitHub Issue

https://github.com/gregeva/logtimeline/issues/412

Requirements are the issue body's eight: the producer/consumer mechanism,
categories, one standardised interface, relevance and restraint, visual design,
a `-V` section, the contract defined as an official pattern in
`docs/architecture-patterns.md`, and user input.

## Framing (architect, 2026-10-17)

- **The category is how the analyst is told to read the notice.** Every notice
  the tool can produce, now and in planned work, is placed in a category
  grouping, and the surfaces present them by category.
- **A data anomaly** is something unexpected in how the data was encountered.
  The analyst judges whether it is expected: if so it is ignored; if not, they
  check the source data or the options given. It comes before the figures so
  that no false conclusion is drawn from them.
- **A detected pattern** comes from the statistics computed over the whole data
  set (for example a high bimodality coefficient on one API, or on the whole
  system). It sets up the analyst's next step: the sort or filter that isolates
  the behaviour, including behaviour the screen cannot show, such as a key
  outside the top N messages.
- **Decisions taken on the analyst's behalf** (fallbacks, metrics not found)
  read as informational.
- **The categories are not fixed at these.** Claude determines the full set
  from the inventory of current and planned notices, and the best way to
  display and communicate each.
- **Placement of the deferred notices.** All data work finishes before any
  section is drawn, so every deferred notice is known before rendering starts.
  They are shown at that point, before the timeline, or afterwards in some form
  of modal presentation; which is a design question.
- **Notice surfaces, adapted to the situation and the moment.** What is
  designed is not one pane at one point of the run but notice surfaces, partly
  presenting information and potentially capturing the analyst's input or
  choice, which are adapted into different situations. Prototyping explores
  them to arrive at patterns to standardise on, and determines how, and if,
  each is implemented in `ltl`. Examples:
  - a single-line deprecation: a couple of lines on standard output, decorated
    a little;
  - early in processing, memory use is growing high: a yes or no on whether to
    continue (#44);
  - later, once statistical analysis has detected a pattern: a choice such as
    changing the sort order, which needs much more of the run to have happened
    before it can even be asked.
- **Input is captured coherently with the notice surfaces.** The choice points
  differ in moment and in what precedes them; how each is presented is
  coherent with the notice surfaces, so the analyst's input is captured and
  collected within them. Deferring notices is one pattern; capturing a choice
  at a given point of the run builds on the same surfaces and is a separate
  pattern, designed and prototyped here.
- **Restraint is choosing the surface, not merging notices.** The surface
  chosen is the one best adapted to the situation and the actual conditions;
  what happens in moving from one surface to another is determined once the
  surfaces themselves are understood. One such surface is a navigable list,
  scrolled up and down, in which a notice is selected to see more detail about
  it: more complicated, and powerful for many notices, where it is overkill
  for a simple informational message.
- **Presentation of information and choices is separate from the charts.**
  As what `ltl` can detect and present grows more complex, the rendering of
  the charts, the statistical information and the metadata describing them is
  separated from the notices and choice patterns. The issue was first framed
  as a structured area before the chart; that framing is too constrained.
  This concerns only the surfaces for the user, how the rendering and the
  user input occur; it has nothing to do with how the data is structured or
  processed.
- **The progress indicator is in scope.** A choice raised while the progress
  indication is displayed is one of the scenarios prototyped. If a modal
  dialogue proves the best way, that is the more straightforward to handle;
  if not, the part of the progress indication on screen is erased, a message
  is displayed followed by an input point (perhaps accepting a single
  character rather than waiting for enter), and the progress printing resumes
  cleanly.
- **A choice point with nobody at the keyboard follows industry practice.**
  The harnesses, Claude during development and the screenshot tool run `ltl`
  unattended, and a run must neither hang nor vary. Ways to handle it include
  taking the choices on standard input, so that they can be redirected, and a
  hidden option, along the lines of an always-yes, that tells `ltl` before a
  choice point comes up how to answer it. Every choice point has a default:
  the analyst is given a certain amount of time to intervene, and if they do
  not, the run goes on with the default. `ltl` has none of these today; how
  user input is supplied and handled is #748 (take the analyst's input at
  choice points, with a default and answers given ahead of time), and the
  surfaces are designed with it in mind.
- **A timed default shows a visible countdown.** The message and its
  question are printed with the yes/no block, followed in brackets by the
  seconds remaining until the default is taken; the line is redrawn every
  second as it counts down, while a single-character read (`Term::ReadKey`)
  accepts Y or N.
- **Glyphs and emoji are covered in a prototype.** Agreed in principle; how
  they render across terminals and fonts is tested before anything is decided.
- **A choice can be multi-stage.** A more complex choice is raised in stages:
  first the analyst is told there are options worth looking at that might
  change the output, and asked whether to look at them or continue as
  planned, a yes or no that defaults after a few seconds to continuing; only a
  yes leads on to the options themselves.
- **Notices found before the read are an example of the framing.** The
  notices raised at option parsing (inventory rows 1 to 11) are known before
  processing starts and before the progress line appears. A small slice could
  expose them at that point with an input asking whether the analyst wants to
  continue, or stop and correct them. Not a decision taken now; a use case
  for the surfaces and choice points the prototypes explore.
- **Out of scope: a notice surface displayed while the read and processing
  occur.** It could be interesting, but it would change how the current
  progress indication works and make the scope too large to manage. (A choice
  raised during the progress line, above, stays a prototyped scenario.)
- **Not part of this stage:** which questions are asked, and identifying every
  place they could be asked. There are a couple of key places where it is
  possible.
- **A surface's form follows what it carries.** A long list of guidance
  needs much of the terminal to show it; a single deprecation notice is a
  couple of lines and calls for no large surface. The design and the
  prototypes look at several forms to choose from, and decide which applies to
  which case. The same holds for the input display.
- **Where the output is read.** An analyst always reads `ltl` in a terminal;
  that is its intended and principal use. Piping is not a design goal: `ltl`
  accepts no piped input and does not intend its output to be piped. Data for
  other consumers goes through `-o` (two CSV files and one YAML file), and
  pictures for documents through the screenshot capability (an SVG and a PNG
  of a targeted section, `docs/process/screenshots.md`). The other readers of
  the terminal surface are the test harnesses, and Claude during development,
  which redirects the output to see how it rendered, stripping ANSI sequences
  where needed.
- **Standard error is temporary; the designed surface is on standard output.**
  The notices print to standard error today so that they stay out of standard
  output and the harnesses can capture and check them. Any designed terminal
  interface is on standard output, so this issue's `-V` section exposes the
  deferred notices, giving the harnesses a way to read them other than
  capturing standard error.
- **The surface works within the screenshot capability**, so the documentation
  can target it. What the screenshot tool handles today (standard output only,
  rows chosen by section through `-V section-layout`, no escape sequence other
  than a colour code) is a constraint of the tool as it is, not a boundary of
  the design: the design determined here feeds back into the screenshot tool,
  which adapts to it, with the balance between them found as part of the work.
- **A modal or pop-up must be introspectable by Claude's development tools**;
  for the analyst it raises no problem. `ltl` has no library for one today:
  what is relevant and possible is found in prototyping, and what is
  integrated into `ltl`, and how, is decided after it.
- **The existing behavioural-notices pattern is one kind of notice** within
  this surface, not the surface.

## Locked decisions

### D1 — Categories split by what the analyst does with the notice (architect, 2026-10-17; runtime condition added the same day)

| category | what the analyst does |
|---|---|
| data anomaly | checks the source data or the options before trusting the figures |
| your options | corrects the command |
| decision taken for you | knows what the run did instead of what was asked |
| figure caveat | reads the figures as covering less than they appear to |
| guidance | applies the suggested sort or filter next |
| runtime condition | is informed of a condition of the run's environment; what, if anything, they do depends on the message |

The test for a notice's category is the analyst's action, so the category
heading tells them how to read every notice under it. The inventory's
*informational* placements divide between *your options* and *decision taken
for you*; each notice is placed under D1 in the inventory below.

### D2 — Categories are marked by a text glyph and a colour (architect, 2026-10-19, from round 1)

Emoji are rejected (inconsistent spacing after them, not apt to the
categories); ASCII marks are rejected (they add nothing beyond the category
name).

### D3 — Notices are grouped by category and compact (architect, 2026-10-19, from rounds 1 and 2)

The category is named once, in upper case, with its how-to-read text on the
heading row; categories are divided by a blank row. A single notice is one row
with no row break inside it: colour and the part markers separate its
statement, evidence and remedy.

### D4 — A surface that asks erases itself; a record is the caller's boolean (architect, 2026-10-19, from round 2)

Once answered the surface is erased and nothing is printed in its place.
Whether it leaves a record of the notice and the answer is a boolean the
caller passes, off by default.

### D5 — Asking during a run is one surface; the modal leads (architect, 2026-10-19, from rounds 1 and 2)

One surface is called at every moment with that moment's notices and choices.
The modal on the alternate screen leads; the box below the cursor is the
compact form; the modal below the cursor is the fallback; the caller passes the
preference. The one-row form (the question and the notice's parts on one line)
is rejected: it cannot be read.

### D6 — Boxes and pop-ups take the new style; inline text keeps the ltl look (architect, 2026-10-19, from round 2)

Rounded corners, the frame in the category colour. A category name set as a
coloured block marks only the selected tab; elsewhere a category is in its
foreground colour.

### D7 — Any key stops a countdown, and nothing says so (architect, 2026-10-19, from rounds 1 and 3)

A key that is not a choice stops the countdown, leaving time to read. No
surface reports the countdown's state: its disappearance is the whole signal,
and it never resumes.

### D8 — The list view of a choice's second stage shows each option in three parts (architect, 2026-10-19, from rounds 2 and 3)

When a choice leads on to its options, they are shown as a selectable list, one
row per option, with the highlighted option's parts beside it in columns headed
What? How? Why? by default. The headings are parameters of the consumer, and a
consumer whose options have fewer parts gets two columns or one. The why comes
from the producer as part of the notice, not from the surface.

### D9 — withdrawn (2026-10-21)

Claude had written here "many notices go to the browser, never to a panel",
from the architect's round 2 remark that the 25-notice panel was a lot of
information. No rule or expectation was stated: which surface a moment of the
run uses is the implementer's choice for that feature, never a rule of the
framework or the engine. The number is left so that the others keep theirs.

### D10 — On a light background, secondary text is an explicit grey, not faint (architect, 2026-10-20, from the Windows round)

On a light background the secondary text of every surface (evidence, the
countdown, the dimmed copy of what lies under a pop-up) is drawn in an
explicit grey on every platform, never with faint (SGR 2): Windows Terminal
draws faint darker, so on a light scheme secondary text stood out from the
text it is secondary to. A layer under a pop-up keeps its colours, dimmed,
on either background (architect, the same day: the histograms under a
layered modal must not lose their colour). Measurements:
`docs/terminal-output.md` § Colour and emphasis.

### D11 — One store, two entry calls (architect, 2026-10-21, from the notice data model walkthrough)

One store of notice records, each with a unique identifier returned at
registration. Two entry calls, `notice` and `ask`, over one backend. The
caller says at call time whether the notice appears on the surfaces, visible
by default; an invisible one stays on the stack, unseen by every surface. A
choice taken at runtime is locked and shows what was chosen. The `-V`
observability section exposes the data model. What `visible` is for
(architect, 2026-10-21, correcting Claude's reading of it as a producer's
switch for a notice nobody should see): its primary use is a notice already
put to the analyst at its moment, such as a choice asked and answered, which
has no relevance later and so is kept off the deferred surfaces (the panel
and the browser); a notice drawn at its call is drawn whatever its
visibility, and `visible: no` keeps it off every surface after. Other uses
exist; the harness scenarios exercise every path of the gate. Trade-offs
weighed before the
lock: two stores (a deferred queue and an ask log) make the panel's record of
an asked choice, the browser's layered ask and `-V` each read two places; no
store for immediate notices leaves nothing to answer on and nothing for the
apply step to read.

### D12 — One answer structure, two routes (architect, 2026-10-21, from the notice data model walkthrough)

The answer is a structure on the record, created when the choice is
answered: the caller's choice letter of the button taken; the key of the
option chosen, when the second stage was reached; how it was answered,
one of six values (amended 2026-10-21, from the prototype's own record of
the answer): `key` (a choice key or Enter), `default` (the countdown ran
out), `esc`, `no_terminal` (the default, nothing to wait on), `ahead`,
`quit`, the last so the `-V` section is written before the run ends. The blocking call returns a
reference to that same structure; the browser sets it through the layered
ask. A record with an answer is locked. The option's command options stay on
the option, reached through the record by the chosen key, one copy. Weighed:
an option named by index is positional and breaks on reordering, so each
option carries a key, one name the producer gives; the prototype's four-value
return list is replaced by the reference.

### D13 — The notice record (architect, 2026-10-21, from the notice data model walkthrough)

What a notice is in the store, one record per raising, never merged:

| field | holds | set by |
|---|---|---|
| id | unique per raising, returned to the caller (D11) | the store |
| kind | a stable name for the notice's type (`read-path-fallback`), the same in every run; what a harness asserts by and what an answer given ahead (#748) names | the producer |
| category | one of the six (D1) | the producer |
| focus, statement, evidence, remedy | the notice's parts (surface contract); evidence is zero or more | the producer |
| producer | the sub that raised it | the producer |
| stage | the pipeline stage it was raised in | the store |
| immediacy | now or deferred | the producer |
| visible | whether it appears on the deferred surfaces, default yes; primarily off for a notice already put to the analyst at its moment (D11) | the producer |
| question, buttons, default button, countdown, headings, options | the choice's definition when it has one; the headings name the options' parts, What? How? Why? when none are given (amended 2026-10-21: the producer owns the options, so it owns what their parts are called); each option carries a key, its parts (D8), its command options and its effect | the producer |
| answer | button letter, option key, how (D12); present means locked | the surface |

The choice's definition lives on the record, not on the ask call, so a
deferred notice carries its choice and the browser layers the ask on it from
the record alone; the ask call carries presentation only (placement, the
compact form, the seconds, whether to leave a record, D4). Not on the record:
how often a producer raises, and any merging.

### D14 — The two entry calls (architect, 2026-10-21, from the notice data model walkthrough)

`notice` takes the record's producer fields (D13) and returns the id; it
draws nothing when deferred, and when immediate draws the panel with that one
notice at the call, in the inline form the prototype draws for the
deprecation. `ask` takes the same with the choice's definition, plus
presentation only (placement, the compact form, the seconds, whether to leave
a record, D4), draws the ask surface now, blocks, and returns a reference to
the answer (D12). An immediate call made while the progress line owns the
terminal is a development mistake, not a case the backend handles; the ask
during the read is a designed scenario of the framing.

### D15 — The `-V notices` section (architect, 2026-10-21, from the notice data model walkthrough)

One section, `notices`, exposes every record of the store as an entity block,
in raising order, in the harness content shape (`tests/HARNESS-DESIGN.md`
§ Content shape): `count`, then per record `notice: <id>` with `kind`,
`category`, `stage`, `producer`, `immediacy`, `visible`, `shown` (the
surface that drew it: `panel`, `ask`, `browser`, or `none`), `focus`,
`statement`, `evidence` (one line per piece, in order, `-` when none;
amended 2026-10-21), `remedy`, `choice` (`yes`/`no`), and when the
record carries a choice (amended 2026-10-21) `headings` (`What? | How? |
Why?`) and one nested block per option offered, `option: <key>` with
`parts` (the parts separated by ` | `), `args` and `effect`; then `answer`
(`button=<letter> option=<key> how=<key|default|esc|no_terminal|ahead|quit>`, or `-`; the six values amended 2026-10-21, D12).
`visible` with `shown` gives requirement 6 its produced, gated and shown. No
separate section for choices: #748's record of each choice point (offered,
the answer, how) is the block of the record that carries the choice, selected
by `choice: yes`. Text is ASCII; the glyphs and bullets belong to the
surfaces. This is the section contract; the harness that validates it is
named for it when the first delivery lands.

### D16 — The first delivery builds the whole framework, each component reached by a real producer (architect, 2026-10-21)

This issue builds into `ltl` the whole framework: the store, the record with
every field (D13), the `notice` and `ask` entry calls (D14), the `-V notices`
section (D15), the rendering layer the components share, and terminal
ownership designed once for all three (the progress line, standard output's
row counting and the sections the screenshot tool reads, the alternate
screen, restoring the terminal on exit or interrupt); the three components,
panel, ask and browser; and the migration of the inventory. Each component
is reached by a real producer, in effect a test surface built to validate the
framework (architect): the panel by the deferred notices; `ask` by the
notices raised at option parsing (rows 1 to 11), drawn before the read with a
choice to continue or stop and correct the command; the browser by the
deferred notices when they do not fit the terminal's height. Weighed: the
panel alone, with `ask` and the browser built later on the record and the
shared layer, leaves terminal ownership designed but proven only for the
panel, the part a later piecemeal build is most likely to get wrong; all
three built without producers ships code no real run reaches. For #748: the
default taken when there is no terminal to wait on, the countdown and the two
stages are built here, and the `-V` record of each choice point is D15;
answers given ahead stay with #748.

### Delivery plan (architect, 2026-10-21)

The drops of D16, in order, each committed and pushed on the issue branch as
it is proven:

1. **Store and record**: every field of the record, the `notice` entry call
   (deferred), the `-V notices` section and its harness, proven on the
   read-path fallback (row 12); until drop 2 the deferred notices still print
   through the stderr flush.
2. **Shared layer and the panel**: the category sheet, the notice row, the
   frame, glyph widths and terminal detection on `ltl`'s
   `detect_light_terminal_background()`; terminal ownership designed for all
   three components; the panel on standard output before the charts, deferred
   and immediate inline.
3. **Migration after the read and at finalize**: rows 13 to 31 to the store
   and the panel, their harness assertions moved from standard error to
   `-V notices`.
4. **`ask`**: raw mode, the key map, buttons, countdown, the compact box, the
   modal on the alternate screen and below the cursor, the options list, the
   default when there is no terminal, the terminal restored on exit or
   interrupt; reached by rows 1 to 11 before the read.
5. **Browser**: the list and detail pane, the ask layered on an item; reached
   by the deferred notices when they do not fit the terminal's height.
6. **Close of the migration**: rows 32 to 35; `defer_notice()` and
   `flush_deferred_notices()` removed; `docs/notice-surfaces.md` and the
   pattern entry trued to what is built; a screenshot entry per surface.

The per-line read loop is not touched, so no before/after benchmark is
planned.

### D17 — Every option of the framework is exercised, by fixtures and by tmux (architect, 2026-10-21)

The acceptance criteria and their scenarios exercise every option of the
framework, as the prototype's testing did (`show.pl`'s options,
`check-tmux.sh`'s scenarios, `capture/specimens.sh`'s predicates, the
review rounds' views): every component and form, placement, size, the
presentation parameters, every way of answering, every key, the content
shapes, and the terminal's widths and backgrounds. Two means, both required:

- **Hidden developer options in `ltl`**: one raises a named set of fixture
  notices through the real `notice` and `ask` calls with the presentation
  parameters given, so a scenario reaches the cells the real producers do not
  choose, through the same progress line and section accounting as any
  producer; one gives answers ahead, which brings #748's requirement 3
  (answers supplied ahead of time) into this issue.
- **tmux-driven scenarios** for navigation and input on the alternate screen
  and below the cursor: keys sent, the pane captured as it is seen. A
  redirected run cannot observe them; the tmux scenarios are required even
  though most cases are redirected runs (architect). They run on macOS and
  Linux only, skipped where tmux is absent, never on Windows, as settled in
  prototyping (`docs/terminal-interaction.md` § Unattended runs and how a
  surface is tested).

Weighed: real producers alone reach only their own cells; a harness-side
driver over subs sliced out of `ltl` never runs them in a real run, so
terminal ownership, the part D16 exists to prove, would go untested.

## Implementation progress

### Drop 1: store and record (2026-10-21)

Built: the store (`@notice_records`), `notice()` with every field of the
record (D13), the stage set by `enter_notice_stage()` as each pipeline stage
begins (`options`, `detect`, `parse`, `accumulate`, `finalize`, `render`),
`-V notices` printed by `emit_notices_verbose()` at the end of
`pipeline_render()`, after the run's last notice, and `tests/validate-notices.sh`.
The first producer is the read-path fallback (row 12, `read-path-fallback`,
*decision taken for you*); its text still prints on standard error through
`flush_deferred_notices()` until drop 2.

How the record is written, within D13 and D15:

- `producer` is the sub that called `notice()`, read from the call stack, so
  it cannot drift from the code.
- `immediacy` is `deferred` (the default) or `now`.
- A button carries its label, its choice letter and its role (`stop`,
  `more`, `default`), as in the prototype; the default button is the one whose
  role is `default`, and the role fixes its position (`docs/terminal-interaction.md`
  § Buttons).
- `headings` is written only when the choice has options; given none, the
  options are headed What? How? Why?, as many as their parts.
- A value is written on one line: tabs and line breaks become a space.
- An unknown field, a missing kind or statement, or a category outside the
  six stops the run: a development mistake, never a run condition.

The hidden developer option of D17 that raises fixture notices is
`--notice-fixture NAME`; its one set so far, `record-fields`, raises nine
records across the six stages that between them carry every field and value
of the record. An unknown set is refused as a usage error naming the sets.

Proven: the fixture run and the fallback, injected into a copy of `ltl`, read
from `-V notices`; a clean run writes `count: 0`; the run's output unchanged
against the base on five option shapes over two inputs, bare `-V` differing
only in timings and memory; four sabotaged copies of `ltl` (the stage never
set, the evidence joined, headings on a choice without options, the fixture
never raised) each fail the assertions written for them. Harnesses run:
`validate-notices.sh` (36 passed), `validate-verbose-content-shape.sh`,
`validate-help-content.sh`, `validate-scenario-selector.sh`, and the
`fallback` scenario of `validate-read-path.sh`.

### Drop 2: shared layer and the panel (2026-10-21)

Built: the category sheet (`@notice_category_sheet`), the new style's codes
per background (`notice_style()`), the cell count and cut (`notice_cells()`,
`notice_fit()`), the notice row, the heading and the frame (`notice_rows()`,
`notice_heading()`, `notice_frame()`), and the panel (`notice_panel_rows()`),
drawn by `draw_deferred_notices()` on standard output after the progress rows
and before the timeline, as the `notices` section of `-V section-layout`; an
immediate `notice()` draws the panel with its one notice at the call, in an
unnamed section so the one blank row between sections holds. The read-path
fallback is drawn in the panel and no longer printed on standard error.

- **Terminal detection** is one sub, `detect_terminal()`, found once on first
  use: the name from `WT_SESSION`, Windows, `TERM_PROGRAM`, then the
  name-and-version and identity replies; the background from the colour
  reply; each query followed by the primary device attributes request, the
  queries written to `/dev/tty` so they never reach the row counter.
  `detect_light_terminal_background()`, the heatmap's, now reads it.
  Hand-forward to drop 4: on Windows `ltl` puts no console in raw mode yet,
  so nothing is asked there and the background is dark; the Windows Terminal
  reply (`docs/terminal-output.md` § The terminals) is read once drop 4
  builds raw mode with the console's input mode.
- **The panel is not a value of `--hide` or `--show`**: behavioural notices
  always print (`CLAUDE.md` § Before writing or changing code). `-V
  section-layout` reports it after `progress` through `@section_layout_order`.
- **Width** is a character a cell, after UTF-8 decoding: every glyph the
  surfaces draw is one cell (`docs/terminal-output.md` § Glyphs and width),
  and `ltl` measures text this way elsewhere.
- **Finding, the bold of two headings.** `@column_colors` writes the orange
  and teal foregrounds with a leading reset (`\e[0m\e[38;5;208m`). The
  prototype's `style_for()` used those codes as they are, so the reset
  cancelled the bold before them: in every prototype view the *data
  anomaly* and *runtime condition* headings drew in the normal weight while
  the other four were bold (`prototype/412-notice-surfaces/lib/NoticeProto.pm`
  `style_for`, `lib/NoticeSurfaces.pm` `label`). The contract says headings are
  bold (`docs/design-language.md` § The new style); `notice_style()` takes
  those two codes without the reset, so all six are bold. To be seen by the
  architect in the terminal review.

The cell decoder (`tests/lib/rendered-output.pl`) records bold and faint per
cell, the attributes a panel row is told apart by; `tests/notices/panel-report.pl`
reports each panel's frame, title and rows from it. Proven: nine panel
scenarios in `tests/validate-notices.sh` (placement and section accounting,
no panel, an invisible notice kept off, the headed form at 80, 120 and 160
columns, the parts of a notice, the edge form and one notice, wrapping at 80
columns, the light background, the Windows glyphs, an immediate notice);
six sabotaged copies of `ltl` each fail the assertion written for them (the
box as wide as the terminal, the bold lost, faint on light, an immediate
notice drawn twice, the Windows glyphs never taken); the run's output
unchanged against drop 1 on six option shapes over two inputs but for the
new `notices absent` row; an interactive run in a tmux pane drew the panel
with no query reply on screen, 0.22 s in all.

## Inventory of current notices

Every stderr emission in `ltl` (169 sites, from a scan of `print STDERR`,
`printf STDERR`, `warn`, `die` and `defer_notice`), on `release/0.20.0` at
`48278bf`. The categories are settled (2026-10-21): the ten notices that fit
two categories were chosen by the architect from their messages, the rest are
placed by D1's test of what the analyst does. The ten, by the `kind` each
carries: `sort-gated-by-omit` (row 8), `discard-switches-off-metric` (9),
`heatmap-counting-metric` (6), `invalid-chart-value` (4) and `du-not-applied`
(16), each *your options*, since the analyst's action is to change the command;
`bound-finer-than-log` (24) and `udm-csv-column-absent` (18) *your options*;
`filter-excluded-no-value` (20) *figure caveat*; `udm-capture-not-number` (29)
*data anomaly*; `final-pass-skipped` (25) *decision taken for you*, its
`--group-similar` reference point the remedy.

Phases: **options** = option settlement in `adapt_to_command_line_options()`
and its callees, printed before the read starts; **read** = inside
`read_and_process_logs()`'s read pass; **after read** = the end of
`read_and_process_logs()` and the tail of `pipeline_parse()`; **finalize** =
`pipeline_finalize()`.

### Notice candidates

| # | producer | phase | prefix today | says | category (D1) | remedy it carries |
|---|---|---|---|---|---|---|
| 1 | `parse_udm_configs` (9 sites) | options | `Warning:` | a `-udm` spec is malformed (bad regex, no name, key and pattern both given, function in the unit slot, counting with a transform, unknown function, fixed-string pattern under a counting aggregation) and is skipped, or a unit is ignored or unknown | your options | the corrected spelling, where one is evident |
| 2 | `parse_udm_configs` (2 sites) | options | `Note:` / `Warning:` | a repeated `-udm` is dropped; two specs resolve to one metric name and the later is skipped | your options | give them different names |
| 3 | `read_pattern_file`, `build_merged_regex` (8 sites) | options | `Warning:` | a pattern file is missing, unreadable, binary, empty, over 10 KB or over the pattern count; the merged regex is over its length limit | your options | none |
| 4 | `adapt_to_command_line_options` (4 sites) | options | none (bare `warn`) | a histogram or precision value is invalid and the default is used | your options | none |
| 5 | `adapt_to_command_line_options` | options | `Warning:` | a minimum bound exceeds its maximum: no entries can match, or be highlighted | your options | none |
| 6 | `adapt_to_command_line_options` (2 sites) | options | `Warning:` | the heatmap is disabled, or a histogram metric skipped, because the metric uses a counting aggregation | your options | none |
| 7 | `adapt_to_command_line_options` (2 sites) | options | `Note:` | `-n 0` leaves the listed options without effect; `-o` writes the stats CSV only | your options | none |
| 8 | `apply_parse_time_sort_gate` | options | `Note:` | `-so` cannot apply because an `--omit-*` option discards its metric; ordered by occurrences | your options | none |
| 9 | `resolve_discard_names` (2 sites) | options | `Note:` | `-d` removes a key a metric reads; the metric is switched off | your options | none |
| 10 | `apply_discard_precedence` (2 sites) | options | `Note:` | a key given to both `-x`/`-m` and `-d` is discarded | your options | none |
| 11 | `print_deprecation_notices` | options | `Warning:` | a deprecated option or spelling was used | your options | the replacement |
| 12 | `read_path_fall_back` | read (deferred) | `Note:` | the faster read path could not be prepared; large files read with the slower standard path | decision taken for you | none |
| 13 | `format_classification_rule_change` | read (deferred) | `Note:` | a file's classification rules changed at line N because the detected format changed | data anomaly | none |
| 14 | `defer_timestamp_impossible_notes` | read (deferred) | `Note:` | N of M lines of a format were not matched because their date cannot exist | data anomaly | `-lf <other variant>` if day and month are swapped |
| 15 | `defer_format_unit_notes` | read (deferred) | `Note:` | a detected format is written by more than one producer, which differ in date layout or duration unit, and nothing decided which | data anomaly | `-lf <variant>` or `-du <unit>` |
| 16 | `defer_format_unit_notes` | read (deferred) | `Note:` | `-du` is not applied to files whose format names the unit on each line | your options | none |
| 17 | `detect_and_parse_csv_header` | read (printed, not deferred) | `Warning:` | the CSV message column is not in the header | data anomaly | none |
| 18 | `emit_udm_csv_unbound_notices` | read (printed, not deferred) and finalize | `Note:` | a `-udm` names a column absent from N CSV headers | your options | none |
| 19 | `read_and_process_logs` | after read | `Note:` | a format's lines carried levels `ltl` does not recognise; those lines were not counted | data anomaly | none |
| 20 | `read_and_process_logs` | after read | `Note:` | N lines carried no value for a numerically filtered metric and were excluded | figure caveat | none |
| 21 | `read_and_process_logs` | after read | `Note:` | directories could not be read and were skipped in recursive selection | data anomaly | none |
| 22 | `resolve_byte_notation` | after read | `Note:` | the run's formats declare different byte notations; SI is used | decision taken for you | `-bn si` or `-bn iec` |
| 23 | `resolve_timestamp_precision` | after read | `Note:` | timestamps are shown to a coarser precision than asked, because the logs carry no finer | decision taken for you | none |
| 24 | `note_finer_duration_bounds` | after read | `Note:` | a duration bound is finer than the log's recorded unit | your options | none |
| 25 | `report_skipped_final_pass` | finalize | `Note:` | the final consolidation pass was skipped over N messages; the similarity at which the data clusters | decision taken for you | a reference point for `--group-similar`; `--mask` for identifiers |
| 26 | `sort_fallback_to_occurrences` (2 texts) | finalize | `Note:` | the `-so` ranking could not be produced (no values observed, or none eligible); ordered by occurrences | decision taken for you | none |
| 27 | `bin_consolidation_notice` | finalize | `Note:` | consolidated rows' percentiles are approximate under the bin data model | figure caveat | `-mdm raw` |
| 28 | `emit_udm_zero_match_notices` | finalize | `Note:` plus indented `read as:`, `pattern:`, `hint:` lines | a `-udm` produced no metrics, with the interpretation acted on | your options | wrap a regex token key in slashes |
| 29 | `emit_udm_skipped_capture_notices` | finalize | `Note:` | N captured values were not numbers and were skipped | data anomaly | none |
| 30 | `emit_classification_percentage_notices` (3 texts) | finalize | `Note:` | the percentage columns are not shown; the shares are omitted; the percentages cover only operations the log records | figure caveat (all three texts; architect, 2026-10-17) | `--help formats` |
| 31 | `emit_classification_percentage_notices` | finalize | `Warning:` | N included lines matched neither classification | data anomaly | none |
| 32 | `read_index_file` | detect (`pipeline_detect()`) | none (bare `warn`) | the run index file exists but cannot be read; read-back skipped | runtime condition | none |
| 33 | `read_index_file` | detect (`pipeline_detect()`) | none (bare `warn`) | the run index file is malformed; read-back skipped | runtime condition | none |
| 34 | `write_index_file` | render (`pipeline_render()`) | none (bare `warn`) | the run index file could not be renamed into place after writing | runtime condition | none |
| 35 | `get_memory_usage` | read and after (registry and CSV compilation, memory measurement) | none (bare `warn`) | on Windows, process memory usage could not be read | runtime condition | none |

### Not notices

| emission | sites | reason |
|---|---|---|
| `print_usage` and the run-stopping errors (`_validate_dm`, `_validate_profile`, a file that cannot be opened, the CSV output that cannot be written, no file to read, with the `-r` quoting hint) | ~15 | the run stops at the error, before any notice is deferred |
| format-registry self-validation (`build_format_registry`, `compile_format_*`, `format_*_src`, `format_classification_resolve`, `derive_format_constraints`, `csv_block_for_file`) | ~50 | internal invariant failures: a defect in `ltl`, never a condition of the run |
| generated read loop (`generated_loop_*`, `read_path_text`) | ~12 | internal invariant failures, caught and turned into row 12 |
| `value_text`, `value_column`, `stat_consumer_active`, `index_row` | 4 | internal invariant failures |
| `--debug-layout`, `--validate-layout`, `merge_consolidation_overlapping_patterns` debug print | 9 | developer diagnostics behind hidden options |
| the filters note in `--help` | 1 | help text on standard output, not a notice |
| `detect_light_terminal_background` | 1 | its `stty` failure is raised inside an `eval` and never printed |

### Observations from the inventory

- **A notice has parts.** Eight of the 35 carry a remedy beside the statement
  (rows 1, 11, 14, 15, 22, 25, 27, 28), and several carry evidence: counts,
  files, lines, the interpretation acted on (row 28's indented lines). A
  producer contract that takes the statement, the evidence and the remedy
  separately would let a surface present each the same way.
- **No guidance producer exists today.** Guidance appears only as remedies
  inside other notices, and row 25 is the one notice whose remedy points at an
  analysis choice rather than a correction.
- **Five prefixes.** `Note:`, `Warning:`, no prefix, `Hint:` (on a run-stopping
  error), and six-space continuation lines. `Warning:` is used both for the
  analyst's own malformed input (row 1) and for a data anomaly (row 31).
- **Timing moves.** Rows 1 to 11 print today before the read starts, so an
  analyst who mistyped a pattern file or a `-udm` sees it at once and can stop
  a long run. Deferred to the end of the data work, they appear only after the read.
- **Two producers print during the read without deferral** (rows 17 and 18,
  via `detect_and_parse_csv_header`), while the read pass may own the terminal.
- **Granularity differs.** Some notices aggregate one line per run across
  files (rows 15, 21), some fire once per file (row 13), some once per metric
  (rows 26, 28).

## Planned producers

Notices specified in open issues and not yet built: a sweep of the 90 open
issues on 2026-10-17 (body, every comment, and the feature docs they own).
Every producer already registered on this issue's thread is shipped and sits in
the inventory above. The categories are Claude's placements, not confirmed by the architect; they
are settled in the planning that precedes implementation, not now.

| issue | fires when | knowable | category (D1) |
|---|---|---|---|
| #454 statistics describe a filtered subset | any line-discarding filter is active (`-i`/`-e`, `-if`/`-ef`, the numeric `min`/`max` filters; not highlights, not `-st`/`-et`) | options; after read for discard counts | figure caveat |
| #401 implied durations, warning A | implied durations are in use; states the maximum-gap ceiling in force | options; after read | figure caveat |
| #401 implied durations, warning B | logged and implied durations are mixed in one run | after read | figure caveat |
| #401 implied durations, suppressed gaps | gaps over the ceiling were suppressed (counted, never silently dropped) | after read | data anomaly, with a remedy (adjust the ceiling) |
| #61 derived metrics, disclosure | a canonical field (`duration`, `bytes`, `count`) carries derived values; derived and real mixed | after read | figure caveat |
| #61 derived metrics, gap in force | an inter-line function runs under a maximum-gap value the analyst did not give | options | decision taken for you |
| #372 paired start/end events | starts with no end, ends with no start, starts evicted (specified for `-V` only so far) | read; after read | data anomaly |
| #2 memory ceiling, engagement | memory pressure engages the adaptive path, with its fidelity trade-off | read | decision taken for you |
| #2 memory ceiling, insufficient | the budget cannot hold the request even after adapting; reduce scope or use `-g` | read; after read | decision taken for you, with a remedy |
| #44 source file heuristics, auto-applied | the heuristics change a setting (empty buckets omitted, bucket size, two passes) | before the read | decision taken for you |
| #17 duration unit auto-detection | the values contradict the detected or assumed unit; suggests `-du` | read, or the detection sample | data anomaly, with a remedy |
| #658 request start or end timestamp | start-or-end stamping is ambiguous, so the format's default is used | detection; after read | decision taken for you |
| #664 stall detection | held requests grow across buckets and release together; also marked in the timeline | after statistics | guidance |
| #193 timeout clusters | error entries cluster near a round timeout boundary | after statistics | guidance |
| #258 scenario knowledge set | the kind of input (GC log, access log) suggests related techniques | after detection | guidance, driven by the input's kind rather than a statistic |
| #535 rates at fine bucket widths | a bucket too narrow for its rates to carry meaning (open: notice, figure change or documentation) | options; after read | figure caveat, with a remedy (widen the bucket) |
| #582 regex specs for message options, misplaced pattern | a slash-delimited pattern given in the replacement slot is read as the pattern (its D9: "an informational message states the mistake and the run continues") | options | your options |
| #582 regex specs for message options, zero match | an `-x`/`-d`/`-m` spec matched nothing (its D10, D12) | after read | your options, with a remedy (wrap a regex in slashes) |
| #642 `-udm` default extraction | a value such as `1,000`, `0x10`, `Inf` (open: skip and report, or leave unmatched) | after read | data anomaly |
| #685 unreadable durations | a line's duration cannot be read; the lines skipped are reported | after read | data anomaly |
| #682 lines no format matched | lines read but matched by no format are reported | after read | data anomaly |
| #686 long forms of `-st`/`-et` | `--start` or `--end` is used: deprecated | options | your options |
| #581, #601 duplicated options | a deprecated duplicate option is used (open: whether a notice is the way) | options | your options |

Open issues that change a shipped notice: #630 removes the deprecated options
and with them their deprecation notices; #483 would end the "no classification
configured" notice (row 30) for GC logs; #697 and #681 change when a shipped
`-udm` notice fires (rows 18, 28); #469 replaces the mechanism behind row 27
without saying whether the notice still applies.

## Prototyping

Prototyping here is iterative design (architect, 2026-10-17, restated
2026-10-19). It began as many separate prototype scripts, one per example
surface and choice point, built to be compared against each other: enough to
establish something quickly, look at the options, pick one, and tighten the
direction. Each review round narrows them, and what they converge on is one
framework for notices, user input, choices and navigation: a few components
with parameters, a conventions contract (keys, buttons, sizing, countdown,
erase or record, headings, glyphs and colours) and the decisions behind them,
fitting the cases known today and cases not yet known. The deliverable of the
stage is that framework's specification and its locked decisions, not a set of
validated renderings; nothing about what is built into `ltl` is scoped until
the prototypes are delivered and validated.

The prototypes cover every example surface and choice point: the decorated
deprecation of a couple of lines, the yes or no while processing, the choice
offered once a pattern is detected, and the long list of guidance. The
examples are the inputs the components are exercised with, never scripts of
their own; once validated the components become patterns to draw on for future
enhancements, even where they are not implemented in `ltl` at first.

Prototypes are reviewed live. The architect works with Claude in one session
while running the prototypes in another, through a review runner that shows
one view at a time and saves the feedback with the exact command that drew it.
Each round then runs the same way (agreed 2026-10-19, after three rounds had
carried the same correction):

1. Claude records the round's feedback in the prototype findings.
2. Claude sends a read-back before building anything: what was heard, what
   changes, what is not changing and why. Building waits for the architect's
   confirmation of that reading.
3. The round's settled lines are proposed for lock and moved into the record,
   each as a locked decision here or a line of the contract (now
   `docs/design-language.md` and `docs/terminal-interaction.md`), in the same
   step; only what still needs iteration stays open in the findings.
4. The next round is built against the contract, and Claude's own check before
   review observes what the architect will observe (a terminal pane captured
   as it is seen, alternate screen included), or says that it cannot.
5. The round shows only the views a change touched or something new. A view
   the architect validated is not shown again; a mechanism validated on one
   surface is not re-shown on every surface that shares it. The list gets
   shorter every round, towards sign-off; a list that does not shrink is a
   round that did not converge (architect, 2026-10-19, after round 5).

The review unit is the contract once, as a document, then each component with
a few inputs; cross-cutting feedback is given against the contract's lines,
not against renderings.

The surfaces are prototyped first: what the analyst sees and how they answer.
The producer interface (how code anywhere in the run registers a notice or a
choice, with a choice's options, default, timeout and what happens when it is
accepted), on which the requirement 7 pattern rests, is designed once the
surfaces are chosen.

The prototypes explore two visual languages: one matching `ltl`'s existing
look (the title banner, the box-drawing rules of the timeline and tables, the
colour table per column and background), and a new style, which the rest of
the output might later adopt.

Prototyping runs in stages, simplest first, each stage directing the next.
The early stages render from fixed sets of example notices, enough to choose a
direction; later stages are fed what real `ltl` runs produce, so that the
chosen surfaces become credible and relevant to `ltl`.

Prototyping runs in stages across platforms. macOS is the primary
development platform, so the prototypes start there; a round of decisions
selects the patterns to take forward, and only those are validated on Linux
and Windows, so that the work falls on the selected patterns alone. The
components rely on standard terminal behaviour (raw key reading through
Term::ReadKey, escape sequences for keys, the alternate screen, the cursor
position report and colour), so the validation is the architect judging each
component once per form in a Linux terminal and in Windows Terminal, as on
macOS, and noting any key that does not decode, any sequence that does not
take, and any glyph missing or two cells wide. Its outcome is acceptance or a
short list of adaptations, each a branch of the kind `ltl` already carries
for Windows (the code page, the bar character); it is not a port (architect,
2026-10-19). Final decisions are not made before it is known what is possible
on the other platforms: a pattern found infeasible or overly complicated on
Windows is found before implementation in `ltl`, not during it. The packaged
binaries carry every library the chosen patterns need.

The research the prototypes start from (what `ltl` has today, the kinds of
terminal surface, prompt practice, Perl libraries, unattended capture) is
`features/412-notice-surfaces-research.md`.

Prototyping is required on two counts of `prototype/README.md`: a new
capability whose shape has to be found, and (d) a verification method not yet
known, since asserting a rendered terminal surface is an open question in this
repository (`docs/test-driven-development.md` § Visual surfaces). The lessons
of this stage's process are worked into `prototype/README.md` when the
prototypes are done, as the rules of a design prototype, a kind that document
does not yet describe.

### Prototyping closed (architect, 2026-10-21)

The prototyping stage is closed; its deliverable, the framework's
specification and its locked decisions, is delivered:

- **What was built**: three components (panel, ask in its modal and compact
  box forms with the options list as its second stage, browser with a
  layered ask) in `prototype/412-notice-surfaces/lib/NoticeSurfaces.pm`,
  exercised with the use cases as data (`notices/inputs.pl`), reviewed
  through `review.pl` over seven rounds on macOS, the light background, the
  Windows and Linux rounds and their re-checks, and terminal detection
  (`lib/NoticeProto.pm`, `probe-terminal.pl`), between 2026-10-17 and
  2026-10-21.
- **What was chosen**: D2 to D8 and D10 (the surfaces), D11 to D15 (the data
  model); the contract in `docs/design-language.md`,
  `docs/terminal-interaction.md` and `docs/terminal-output.md`; the complete
  pattern in `docs/notice-surfaces.md` with its index entry in
  `docs/architecture-patterns.md`. D9 was withdrawn.
- **What was learned**: the rules of the design prototype,
  `prototype/README.md` § (e); the unattended capture method and the
  decision that the test method follows the surface
  (`prototype/412-notice-surfaces/findings.md` § Unattended capture); the
  terminal findings per platform (§ Windows validation round, § Terminal
  detection).
- **Not held as a stage**: the later stage fed by real `ltl` runs, planned
  above. The one real-run input used was the histogram detail of the
  browser, captured from a run; the rest of that intent is met by the
  migration of real producers, which is implementation.

The prototype scripts stay as the reference the first delivery is built
from; nothing in them is production code.

**Findings checked against the specification (2026-10-21, at the
architect's request, before the acceptance criteria).** Every settled line of
`prototype/412-notice-surfaces/findings.md` and of the feedback logs was
matched to where the specification carries it. Transcribed then, being
settled in the rounds but absent: the browser's tabs always named, on a
second row when they do not fit; the panel's title in the secondary colour of
its count; the compact box's empty row before its question; the `◆` marker of
a notice answered in the browser; the bytes histogram beside the duration one
where the messages carry bytes; no second empty row above a surface below the
cursor; the principle that a surface presents information simply; the
background read on Windows and dark when no reply comes; the cost of terminal
detection; the glyph widths measured on macOS and Linux; the width lookup done
once per code point. Trued up: the status lines of the three contract
documents (Linux validated, D16's first delivery, the data model designed) and
the `-V` choice section, which D15 folds into `-V notices`.

### Closing out prototyping (architect, 2026-10-17)

Individual prototypes need not meet these; the selected options must, before
the prototyping stage is closed:

- [x] Each selected surface is judged by the architect in the terminal (macOS,
      dark and light, rounds 4 to 7 and the light evaluation, 2026-10-19).
- [x] Each selected surface has a demonstrated way to be captured and checked
      unattended, for the harnesses and for the screenshot tool
      (`prototype/412-notice-surfaces/findings.md` § Unattended capture, 2026-10-19;
      the method follows the surface, `docs/terminal-interaction.md` § Unattended runs).
- [x] The prototype findings record what was chosen, what was learned along
      the way, and why each decision was made (the findings' round sections
      and § Lessons learned; the lessons are the rules of the design prototype
      in `prototype/README.md` § (e), 2026-10-19).

## Surface framework contract

The framework the prototypes converged on was written here as one document,
each line settled by a locked decision or confirmed by the architect round by
round, and reviewed before code. Once settled it was moved out of this issue's
record into two project documents, so that every surface of `ltl` is drawn and
built from them and nothing drifts between two copies (architect, 2026-10-19:
the contract's patterns are first-class patterns of the project, each with its
own section):

- `docs/design-language.md`: the two looks, coexisting, with one deliberate
  choice per surface and one implementation per look so change cascades
  (architect, 2026-10-19); the ltl look as the tool draws it today, the new
  style as settled for these surfaces (D6), the category sheet, the notice's
  anatomy, wording and the light background.
- `docs/terminal-interaction.md`: the three components and the notice record,
  the key map and key bars, taking input (default, countdown, answers given
  ahead, two stages, quitting), buttons, the options list, the defaults by use,
  layered surfaces, pop-up size, placement, padding, erasing and the record,
  unattended runs and the test method per surface.

The locked decisions above remain the authority behind every line; the
documents carry the settled form and cite the round that settled it. The
one line left open there, the headings of the options list in the modal and
box, closed on 2026-10-21 with D13: every surface takes the producer's
headings, What? How? Why? when none are given.

## Notice data model

The notice data model is what every part of the mechanism shares: the store
of notices, the record a notice is, the answer a choice leaves on it, the step
that applies the choices taken, and the consumers that read them. The
producer interface (how code anywhere in the run hands a notice or a question
to the one surface called at that moment) is the entry side of that model,
and the surfaces are its presentation side; the requirement 7 pattern rests
on the model as a whole (architect, 2026-10-21: what is designed here is a
common and shared data model, not a new producer interface). It is designed
once the surfaces are chosen and validated (they are, on macOS, Linux and
Windows, 2026-10-21), as a walkthrough of seven sections, each confirmed by
the architect before the next: the record; the two entry calls and the
answer; observability (the `-V` sections for notices and for choices, #748);
the pattern entry; the options list's headings. (A section on the moment
each inventory row registers in, and one on restraint, were Claude's and were
dropped on 2026-10-21: when a producer registers, with what immediacy, and
whether it is relevant, is each producer's decision at its migration.) What is
settled is written here, then moved to the project documents as the surface
contract was.

### The situation the model fits

```
phase        options            detect     read (progress owns     after read       finalize         render
                                           the terminal)
producers    udm specs, pattern  run index  read-path fallback,     unknown levels,  skipped pass,    index write
today        files, bounds,      read-back  classification change,  filtered-out     sort fallback,   failure
             deprecations        failures   impossible dates,       lines, byte      bin caveat,
             (rows 1-11)         (32-33)    unit notes, CSV header  notation,        udm zero match,
                                            (12-18)                 precision (19-24) classification (25-31)
printed      at once, stderr     warn       deferred, or printed    at once, stderr  at once, stderr  warn
             before the read                over the progress line
surface      ask before the read            ask during the read     panel before the charts, or the browser when many
(contract)   (a use case, not decided)      (memory growing)        guidance ask after statistics (the detected pattern)
```

### The architect's framing (2026-10-21)

- **Deferral is the primary mode.** The deferred-notices array of `ltl` was a
  placeholder, but its idea stands: every notice is caught and collected, and
  presented together on one surface. An ask (interrupting the run, a modal, a
  question before continuing) is immediate and cannot defer. The producer says
  which it wants: one call with a mode, or a second entry point that
  orchestrates the same backend.
- **A blocking ask returns its answer directly to the caller**, which is what
  is waiting, as a structure (a reference will do), not a bare key.
- **In the browser a choice is recorded on the notice it answers**, so the
  notice's structure holds its response. A recorded choice has an effect
  afterwards, through consumers that look for the choices made; they belong to
  the data model.
- **Applying a choice is the producer's code, not the model's.** Before
  execution continues, the producer's own code goes through the notices for
  runtime-changing choices taken and applies them. A choice affects only the
  stages that come after it, never what was processed before it: the
  coherence of the output on any one dimension is paramount. Which settings a
  choice changes and how (the sort order, the number of messages shown, as
  examples) is the producer's responsibility, decided per choice point, and
  no concern of the notice, selection and input surfaces (architect,
  2026-10-21, restated after Claude twice drew an apply step into the model).
  The model's whole part is the answer on the record (D12) and the identifier
  that gets the record back (D11).
- **An immediate notice raised while the progress line owns the terminal is
  a development mistake** (architect, 2026-10-21): the backend does nothing
  for it; the developer fixes the call. The ask during the read (memory
  growing) is a designed scenario of the framing and is not this case.

### Where the data model stands (2026-10-21)

The walkthrough is complete: D11 (one store, two entry calls), D12 (one
answer structure, two routes), D13 (the notice record), D14 (the two entry
calls), D15 (the `-V notices` section), and the options list's headings closed
in the surface contract. Requirement 7 is met by the pattern entry
`docs/architecture-patterns.md` § Notice surfaces, a short index entry in
the shape of every other (architect, 2026-10-21: the patterns file holds the
reference and points at a complete document per pattern), which replaces the
behavioural-notices entry and names today's producers as placeholders to
migrate; the complete pattern is `docs/notice-surfaces.md` (the surfaces,
taking input, the data model, observability, the producer's contract),
written from the locks before any code. What is built into `ltl`, and the
migration, are D16.
- **These are foundations.** The use cases that make choices are not yet on
  the roadmap; they will come, and this issue lays what they build on.
- **Two parameters shape every notice: immediacy and choice** (architect,
  2026-10-21, correcting Claude's reading that immediate always means asked).
  Immediacy is now or deferred; choice is none or a set of options. This is a
  notices surface, so a message printed at once with nothing to answer is a
  normal use of it. Two entry calls, possibly three.
- **A producer may fire many times per file** (architect, 2026-10-21,
  correcting Claude's claim that the most frequent producer fires once per
  file). A finding on an API is raised once per API found, five in one file as
  easily as one. How often a producer raises is the producer's own practice,
  outside the model.
- **Migrating the current producers is part of the issue**, planned, the cost
  of bringing on a structured pattern that can grow; never a caveat against
  the model.
- **One store, entered by `notice` and `ask`** (architect, 2026-10-21, after
  the trade-offs of one store against two, or none for immediate notices).
  Order is not an issue: notices are organised by category.
- **A choice taken at runtime is locked.** Seen later in the browser it shows
  what was chosen and cannot be taken again.
- **Visibility is the caller's, at call time** (architect, 2026-10-21,
  simplifying an earlier delete entry). The caller says whether the notice
  appears in the notices list, the default, or not; one that does not is
  invisible on every downstream surface and stays on the stack. The `-V`
  section exposes a fair amount, or all, of the data model. Every record has
  a unique identifier, returned when it is put on the stack, to get it back.

Confirmed by the architect from Claude's read-back (2026-10-21): one store,
two entry points, so every notice, asked or not, is in the store with its
answer beside it (the read-back's further clause, that "immediate" always
means asked, is superseded by immediacy and choice as two parameters, above,
and D14); one answer structure,
set on the notice and returned by reference from the blocking call, the
browser setting it through the layered ask.

## Open items

- None. Each producer's immediacy and visibility are set at its migration.

## Acceptance criteria

Derived from the requirements and D11 to D17 (`docs/test-driven-development.md`),
agreed group by group. Each is a coverage matrix: every value of every
dimension is exercised by a scenario (D17), driven by the fixture option
unless a real producer reaches it, and asserted as stated. Every criterion is
assertable unless marked otherwise.

### Store and record (requirements 1 and 3; D11 to D14; agreed 2026-10-21)

| dimension | values exercised | asserted from `-V notices` |
|---|---|---|
| entry call | `notice` deferred; `notice` immediate; `ask` | `immediacy`; `shown` is `panel`, `ask`, `browser` or `none` |
| visible | yes and no, for each entry call | a record with `visible: no` drawn at its call is in neither the panel nor the browser; `shown` names only the surface at the call |
| raisings | one; the same producer several times in a run | one block per raising, distinct ids, never merged |
| stage | every stage a notice can be raised in: options, detect, parse, finalize, render | `stage` set by the store, matching where the call ran |
| category | all six | `category` |
| parts | focus present and absent; evidence none, one, several; remedy present and absent | `focus`, `evidence`, `remedy`; `-` where absent |
| choice | none; buttons only; buttons and an options list, with the producer's headings and with the default What? How? Why?; options of three, two and one parts | `choice`, `headings`, one `option:` block per option with `parts`, `args`, `effect` |
| answer | by a key; the default after the countdown; Esc; given ahead (a letter; a letter with an option); quit; no terminal | `answer`; on quit the run stops with the section written first |
| locked | a record answered at its call, later shown in the browser | the answer unchanged; the browser offers no second ask on it |
| order | records from several stages | blocks in raising order; `count` equals the blocks |

Across the group: `kind` is the same in every run of the same condition; a
harness lookup that matches nothing is a failure.

### `-V notices` (requirement 6; D15; agreed 2026-10-21)

| dimension | values exercised | asserted |
|---|---|---|
| requesting it | `-V notices`; a bare `-V`; `-V list` | the section present and registered; listed among the reserved names of `tests/HARNESS-DESIGN.md` |
| shape | a run whose records between them carry every field, the nested `option:` blocks and several `evidence:` lines included | `tests/validate-verbose-content-shape.sh` passes; absent values `-`, booleans `yes`/`no` |
| when it is written | a record raised at render (row 34); a run ended by quit | the render record is in the section; on quit the section is written before the run stops |
| `shown` | `panel`, `ask`, `browser`, `none` | each on the record drawn so |
| `how` | `key`, `default`, `esc`, `no_terminal`, `ahead`, `quit` | each on the answer reached that way |
| produced, gated, shown | `count`, `visible`, `shown` | requirement 6 read from these alone |
| text | glyphs and bullets on the surfaces | the section is ASCII only |
| no effect on output | the same run with and without `-V notices` | `-V section-layout` rows identical |
| the harness | named for the section, `tests/validate-notices.sh` | `--list` and `--scenario`; every assertion declares `asserts`, `produced_by`, `contract`; the runtime-warning check |

### Migration (requirements 1 to 4; agreed 2026-10-21)

Driven by the real producers, not the fixture option; every run carries
`--disable-progress`, as every test run does.

| dimension | values exercised | asserted |
|---|---|---|
| every notice of the inventory | rows 1 to 35, each raised under its condition on the smallest input carrying it | one record with its `kind`, `category` (as settled in the inventory), `producer`, `stage`; drawn by the panel or `ask` |
| relevance (requirement 4) | each row's condition absent | no record of that `kind`; a clean run has `count: 0` and no panel |
| nothing on standard error | every scenario | standard error holds only what § Not notices lists; a scan of `ltl`'s source finds every remaining `print STDERR`, `warn` and `die` site in a sub that table names |
| raised during the read | rows 12 to 18, while the progress line owns the terminal | all deferred, `immediacy: deferred`, never drawn at the call |
| numbers in notices | each row whose parts carry a count, a size or a share, at 1,000 or more | rendered through the width-to-format rule's notice budgets (`notice`, `notice exact`, `notice share`) |
| the harnesses | the 19 harnesses whose 93 assertion lines read `Note:`/`Warning:` text | each reads `-V notices` by `kind`; no harness reads notice text from standard error; each moved assertion still asserts |
| the old mechanism | `defer_notice()`, `flush_deferred_notices()`, `@deferred_notices` | gone from `ltl`; the pattern entry names no placeholders |

### Panel (requirements 3 to 5; D2, D3, D6, D10; agreed 2026-10-21)

Redirected runs read through the cell decoder (`tests/lib/rendered-output.pl`),
content from the fixture option, and from real producers where one reaches
the case.

| dimension | values exercised | asserted on the rendered cells |
|---|---|---|
| where | deferred notices present | drawn on standard output after the progress line and before the timeline, as its own section (`notices`) in `-V section-layout`, so the screenshot tool can target it |
| none to show | no visible deferred notice | no panel, no empty section |
| how many | one; seven across several categories; as many as fit the terminal's height | one box round them all; beyond the height the browser takes over (the browser group) |
| form | several categories (headed form); one category (edge form) | headed: each heading carries the glyph, the name in upper case, `(N)` and the how-to-read text, in category order, one blank row between categories; edge: glyph, name, count and how-to-read text in the top edge, the frame in the category colour, the notices alone inside |
| the notice | focus present and absent; evidence none, one, several; remedy present and absent | one row each: the em dash bullet in the category colour, the focus bold, the evidence after `·` in secondary text, the remedy after the arrow in the category colour; a notice wider than the box wraps by words with no hanging indent |
| all six categories | one notice each | glyph and colour of the category sheet in `docs/design-language.md` |
| title and frame | any panel | rounded corners; the title `notices (N)` in the secondary colour, as its count; one cell of padding each side, no empty rows |
| width | 80, 120, 160 columns | the box spans the width, nothing overflows it |
| background | dark; light (`-lbg`, and detected from the terminal) | on light, secondary text is grey 244, never faint, and each category's colour is the darkest step of its light gradient (D10) |
| immediate | `notice` called immediately before the read | the inline form drawn at the call with that one notice, not drawn again in the deferred panel |
| unattended | redirected run | the same rows as in a terminal, drawn once |

Unassertable by a harness: how the panel looks on real data on macOS dark and
light, Linux and Windows Terminal, the Windows glyph column included, judged
by the architect in the terminal before the work is called done.

The groups below are derived from the prototype and its tests, which are the
guide (architect, 2026-10-21): every option `show.pl` exposes, every scenario
of `check-tmux.sh`, every predicate of `capture/assert-surface.pl` and every
view of the review rounds becomes a scenario, against the contract in
`docs/terminal-interaction.md` and `docs/design-language.md`. Redirected runs
are read through the cell decoder and `-V notices`; the tmux scenarios run on
macOS and Linux only, skipped where tmux is absent. Unassertable throughout:
the look on real data on macOS dark and light, Linux and Windows Terminal,
judged by the architect in the terminal before the work is called done.

### ask (requirements 2 and 5; D4, D5, D7, D8, D12, D14)

- Real producer: rows 1 to 11, drawn before the read as the prototype's
  preread choice, "Continue with these options?", **Stop and correct them**
  (`s`) and **Continue** (`c`, the default); Stop ends the run before the read
  with `-V notices` written.
- Redirected: the modal and the compact box, each with one stage and with the
  options list; two and three buttons; the countdown's default and a caller's
  seconds; headings given and the default What? How? Why?, options of three,
  two and one parts; each size tier and a fixed height; 80, 120, 160 columns;
  dark and light; the record flag off and on; no terminal (`how=no_terminal`)
  and answers given ahead, a letter, a letter with an option, upper case
  (`how=ahead`). Asserted against § Buttons, § Countdown, § The options list,
  § Pop-up size, § Padding, § Erasing and the record.
- tmux, the prototype's scenarios carried over (`modal-read`, `modal-stopcd`,
  `modal-quit`, `modal-pattern`, `modal-fixed`, `modal-preread`,
  `modal-inline`, `box-read`, `box-pattern`): every key of § Keys on the
  buttons and the list, the countdown run out (`how=default`) and stopped,
  Esc (`how=esc`), q and x (`how=quit`, ignored on the compact box), the
  stage change, both placements; with the predicates for padding, the run's
  rows unmoved under the surface and no trace after it.

### Browser (requirement 5; D5, D10)

- Real producer: the deferred notices when they do not fit the terminal's
  height, in place of the panel.
- Redirected: the first frame drawn once, as it appears; tabs named with
  their counts, wrapping to a second row; `◇` on a notice that carries a
  choice; a detail with histograms at ltl's size, the bytes one only where
  the messages carry bytes; the full width when the widest detail exceeds
  the large tier; height from the tallest detail.
- tmux, the prototype's `browser`, `browser-cd` and `browser-inline`: list
  and tab keys, a tab chosen by number, Enter opening the layered ask over the
  dimmed browser, its answer marking the notice `◆` and its detail showing what
  was chosen, Esc back one layer, Esc and c closing, q and x quitting, the
  15 s countdown closing it, both placements; the size never changing while
  navigated; the same predicates as ask.

### Terminal ownership (requirements 2 and 5; D16)

- One rendering with or without a terminal: the redirected output of every
  surface holds the same rows as the pane, with no cursor control, alternate
  screen or wait (the prototype's `plain` predicate).
- No run hangs: every redirected scenario ends with the default or the answer
  given ahead.
- The terminal restored on every exit: an answer, quit, the end of the run and
  Ctrl-C during an ask leave the pane in its normal mode, the cursor shown and
  the alternate screen left (tmux).
- The progress line is not disturbed: a surface drawn before the read, and the
  panel after it, leave the progress line's rows as `ltl` draws them today.
- `-V section-layout` names the panel's section, and the run's other sections
  keep their rows.
- Standard error carries no ` at <file> line <N>` in any scenario (the
  runtime-warning check).

### Pattern, documentation and screenshots (requirement 7)

- `docs/notice-surfaces.md`, `docs/architecture-patterns.md` § Notice
  surfaces, `docs/terminal-interaction.md` and `docs/design-language.md`
  describe what is built, with no "nothing in `ltl` implements this".
- The hidden developer options of D17 sit in `ltl`'s list of hidden options,
  outside `--help` and `docs/usage.md`.
- One entry per surface in `process/screenshots.yaml`, generated by
  `process/capture-screenshots.pl`.
