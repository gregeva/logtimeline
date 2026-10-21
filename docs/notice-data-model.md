# Notice data model

The mechanism behind `ltl`'s notices: what a notice is as data, how code
registers one or asks a question through it, what an answer is, and what a
producer is responsible for. The surfaces that present notices are specified
in `docs/design-language.md` (how they look) and `docs/terminal-interaction.md`
(how input is taken); the pattern's index entry is
`docs/architecture-patterns.md` § Notice surfaces. The locked decisions
behind every line here are in `features/412-notice-surfaces.md` (D1 to D15),
which remains their authority; nothing in `ltl` implements this yet.

## The store (D11)

One array of notice records, one record per raising, never merged. Every
record gets a unique id, returned to the caller, which gets the record back.
Order is by raising; the surfaces group by category. Two entry calls over
one backend, `notice` and `ask`. The caller says at call time whether the
notice appears on the surfaces, visible by default; an invisible one stays on
the stack, unseen by every surface, read by `-V`.

## The record (D13)

| field | holds | set by |
|---|---|---|
| id | unique per raising | the store |
| kind | a stable name for the notice's type (`read-path-fallback`), the same in every run; what a harness asserts by and what an answer given ahead names | the producer |
| category | one of six (D1): data anomaly, figure caveat, your options, decision taken for you, runtime condition, guidance | the producer |
| focus, statement, evidence, remedy | the notice's parts; evidence is zero or more | the producer |
| producer | the sub that raised it | the producer |
| stage | the pipeline stage it was raised in | the store |
| immediacy | now or deferred | the producer |
| visible | shown on the surfaces or not, default yes | the producer |
| question, buttons, default button, countdown, headings, options | the choice's definition when it has one; the headings name the options' parts, What? How? Why? when none are given; each option carries a key, its parts, the command options that apply it and its effect in one line | the producer |
| answer | see below; present means locked | the surface |

The choice's definition lives on the record, so a deferred notice carries its
choice and the browser layers the ask on it from the record alone.

## The two entry calls (D14)

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

## The answer (D12)

One structure on the record, created when the choice is answered, the same
one the blocking call returns by reference: the caller's choice letter of the
button taken; the key of the option chosen, when the second stage was
reached; how it was answered (a key, the default after the countdown, given
ahead, or quit). The browser sets it through the layered ask. A record with
an answer is locked: seen later it shows what was chosen and cannot be taken
again. The option's command options stay on the option, reached through the
record by the chosen key.

## The `-V notices` section (D15)

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
