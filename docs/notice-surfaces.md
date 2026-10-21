# Notice surfaces

The pattern by which `ltl` tells the analyst about their run and takes their
choices: what a notice is, the surfaces that present notices and ask
questions, how input is taken, the data model every part shares, how it is
observed, and what a producer is responsible for. The index entry is
`docs/architecture-patterns.md` § Notice surfaces; the locked decisions
behind every line are in `features/412-notice-surfaces.md` (D1 to D15),
which remains their authority. Nothing in `ltl` implements this yet; the
surfaces and the record are prototyped in `prototype/412-notice-surfaces/`.

## What a notice is

A message to the analyst about this run: a decision taken on their behalf, a
condition detected in the input, a consequence of the options they gave, or
guidance on a next step. It may carry a choice. Every notice belongs to one
of six categories, defined by what the analyst does with it (D1): data
anomaly, figure caveat, your options, decision taken for you, runtime
condition, guidance. The category is how the analyst is told to read the
notice, and the surfaces present notices by category.

## The surfaces

Three components, and only three (D5): every moment of the run calls one of
them with its own content.

| component | for |
|---|---|
| panel | the notices known once the data work is done, before the charts, with nothing to answer; also one immediate notice drawn at the call, inline |
| ask | a question put to the analyst during the run, with a default and a countdown, as a modal on the alternate screen, a modal below the cursor, or a compact box; it may lead on to a list of options (the second stage, D8) |
| browser | many notices, or notices worth exploring, in a navigable list with a detail pane; an ask may be layered on an item |

Which component a moment uses is the choice of the feature that calls it.
How a surface looks (the two coexisting looks, the category sheet of glyphs
and colours, the notice's anatomy, wording, the light background) is
`docs/design-language.md`. How a surface behaves (keys and key bars, taking
input, countdown, buttons, the options list, size, placement, padding,
erasing and the record, unattended runs and the test method per surface) is
`docs/terminal-interaction.md`.

## The terminal

Terminal detection (identity and background, found once, over SSH too),
encoding, escape sequences, colour and emphasis, the glyphs and their width
per platform, input, and checking output on Windows: `docs/terminal-output.md`.

## Verifying a surface

The test method per surface (the redirected run through the cell decoder,
the tmux pane capture, `-V` for outcomes) and the screenshot path:
`docs/terminal-interaction.md` § Unattended runs and how a surface is tested;
`docs/process/screenshots.md`.

## Taking input

Every choice has a default, taken when the countdown ends, when Esc is
pressed, when there is no terminal to wait on, or from an answer given ahead
on standard input or by a hidden option (#748). Any key that is not a choice
stops the countdown, and nothing says so (D7). A surface that asks erases
itself once answered; whether it leaves a record is the caller's boolean
(D4). A complex choice is raised in two stages: first whether to look at the
options or continue as planned, then the options themselves (D8). The full
contract is `docs/terminal-interaction.md` § Taking input.

## The data model

### The store (D11)

One array of notice records, one record per raising, never merged. Every
record gets a unique id, returned to the caller, which gets the record back.
Order is by raising; the surfaces group by category. Two entry calls over
one backend, `notice` and `ask`. The caller says at call time whether the
notice appears on the deferred surfaces (the panel, the browser), visible by
default; an invisible one stays on the stack, read by `-V`. Its primary use is
a notice already put to the analyst at its moment, a choice asked and
answered, which has no relevance later: drawn at its call, it is kept out of
the deferred list.

### The record (D13)

| field | holds | set by |
|---|---|---|
| id | unique per raising | the store |
| kind | a stable name for the notice's type (`read-path-fallback`), the same in every run; what a harness asserts by and what an answer given ahead names | the producer |
| category | one of six (D1): data anomaly, figure caveat, your options, decision taken for you, runtime condition, guidance | the producer |
| focus, statement, evidence, remedy | the notice's parts; evidence is zero or more | the producer |
| producer | the sub that raised it | the producer |
| stage | the pipeline stage it was raised in | the store |
| immediacy | now or deferred | the producer |
| visible | whether it appears on the deferred surfaces, default yes; primarily off for a notice already put to the analyst at its moment | the producer |
| question, buttons, default button, countdown, headings, options | the choice's definition when it has one; the headings name the options' parts, What? How? Why? when none are given; each option carries a key, its parts, the command options that apply it and its effect in one line | the producer |
| answer | see below; present means locked | the surface |

The choice's definition lives on the record, so a deferred notice carries its
choice and the browser layers the ask on it from the record alone.

### The two entry calls (D14)

- **`notice`** takes the record's producer fields and returns the id.
  Deferred, it draws nothing: the panel presents every deferred, visible
  notice once the data work is done, or the browser when the feature that
  calls it chooses so. Immediate, it draws the panel with that one notice at
  the call, inline.
- **`ask`** takes the same with the choice's definition, plus presentation
  only (placement, the compact form, the seconds to the default, whether to
  leave a record), draws the ask surface now, blocks, and returns a reference
  to the answer. Every choice has a default, taken when the countdown ends,
  when Esc is pressed, when there is no terminal to wait on, or from an
  answer given ahead (#748).

### The answer (D12)

One structure on the record, created when the choice is answered, the same
one the blocking call returns by reference: the caller's choice letter of the
button taken; the key of the option chosen, when the second stage was
reached; how it was answered (a key, the default after the countdown, given
ahead, or quit). The browser sets it through the layered ask. A record with
an answer is locked: seen later it shows what was chosen and cannot be taken
again. The option's command options stay on the option, reached through the
record by the chosen key.

## Observability: the `-V notices` section (D15)

One section exposes every record as an entity block, in raising order, in
the harness content shape (`tests/HARNESS-DESIGN.md` § Content shape):

```
=== notices ===
count: 2
notice: 1
  kind: read-path-fallback
  category: decision_taken_for_you
  stage: parse
  producer: read_path_fall_back
  immediacy: deferred
  visible: yes
  shown: panel
  focus: -
  statement: the faster read path could not be prepared, so large files are read with the standard path
  evidence: -
  remedy: -
  choice: no
  answer: -
notice: 2
  kind: bimodal-api
  category: guidance
  ...
  choice: yes
  shown: ask
  headings: What? | How? | Why?
  option: bimodality
    parts: Sort the messages by bimodality | -so bimodality_coef | other APIs whose durations split the same way show up beside it
    args: -so bimodality_coef
    effect: this API comes first in the messages table, with any other whose durations split the same way
  answer: button=l option=bimodality how=key
=== END notices ===
```

`shown` names the surface that drew the record (`panel`, `ask`, `browser`)
or `none`; with `visible` it gives what was produced, gated and shown. No
separate section for choices: a harness selects the blocks with
`choice: yes`. Text is ASCII; glyphs and bullets belong to the surfaces.

## The producer's contract

- The producer decides the category, the immediacy, the visibility, how often
  it raises (once per API found is as valid as once per run), and whether its
  notice is relevant to this run.
- A producer that offers a choice applies the answer itself, in its own code,
  before execution continues, and only to the stages that follow; what it may
  change and how is its responsibility, never the surfaces'.
- An immediate call made while the progress line owns the terminal is a
  development mistake; the backend does nothing for it. The ask during the
  read is a designed scenario.
- A notice always prints: `--disable-progress` suppresses progress indicators
  only.
- The producer passes what the notice says, never a formatted line; numbers
  in its parts render through the width-to-format dispatch's notice budgets.
