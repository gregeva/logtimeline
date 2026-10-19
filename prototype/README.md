# Prototyping

Work that answers a question **before** implementation commits to an answer.

A prototype is not a draft of the feature. It is an experiment with a question,
a method and a recorded result, and its output is a decision in the owning
feature doc — not code that later becomes the implementation.

## When a prototype is required

Every change to the hot path is taken carefully and proven not to regress: a
before/after benchmark on this machine is required whenever the work adds cost
per line or per key (`docs/process/workflow.md` § 3 (a)). For a small change to
an existing path, such as a test, a cleared value or a substitution, that
comparison is the evidence, and no prototype is needed.

A prototype is required when the work introduces:

- **(a)** a new or changed data model
- **(b)** a new code path, feature or capability in the hot path, where the best
  and most performant way to build it has to be found
- **(c)** any feature or fix impactful by its cost profile — execution frequency
  × per-execution cost (a cheap operation run tens of millions of times, or an
  expensive one run per key at high cardinality)
- **(d)** a key requirement whose **verification method is not yet known**
- **(e)** a **new surface the analyst sees or answers**, whose form, wording,
  keys and behaviour are not settled by `docs/design-language.md` and
  `docs/terminal-interaction.md`

(a)–(c) are cost questions: *will this be fast enough, and is this the right
shape to store?* (d) is a measurement question: *how would we know whether we
built what was asked for?* (e) is a form question: *what does the analyst see,
and how do they answer?* All are cheaper to answer before implementation than
after, and for the same reason — afterwards, the answer is constrained by what
has already been built.

## (d): the verification-method prototype

This trigger exists because of a specific, repeated failure: a requirement whose
check is unclear gets implemented anyway, and the check is then written to fit
the code. The assertions pass. They confirm the implementation's reading of the
requirement rather than the requirement, so a feature can ship with a full suite
of green tests and still be wrong.

A criterion arrives here from the triage in `docs/test-driven-development.md`
in the **unknown** state. The prototype's job is to determine how — or whether —
that criterion can be asserted.

**Exit conditions.** A (d) prototype exits with one of:

- a **demonstrated assertion method**: a working check, run against known-good
  and known-bad input, shown to distinguish them; or
- a **recorded decision that the requirement cannot be asserted**, with the
  reason and what is done instead (accepted as a gap, verified by eye at a
  stated point, or the requirement itself revised).

Either way it is settled in the feature doc before implementation starts, and
the criteria are updated to match.

**Validate against known failures where they exist.** A method that cannot detect
a defect the project has already seen has not earned its cost. Where real
specimens are available — defects that escaped a previous drop — they are the
test set: run the proposed method against them and report which it catches. A
proposed method that catches none of them is the existing approach with extra
steps.

**The cost is reported, and the architect decides.** Some checks are worth real
infrastructure; some requirements are obvious to any tester on a single run and
are not worth a suite at all. That call is the architect's. The prototype
supplies options, costs and a recommendation — not a built solution.

## (e): the design prototype

A surface is designed by iteration: something is drawn, the architect judges
it in a terminal, and the next round narrows it. The method is right and it is
expensive; the rules below are what made the first use of it (#412, notice
surfaces: seven review rounds, 2026-10-17 to 2026-10-19) converge after three
rounds had not. Each was learned by failing at it; the record is
`prototype/412-notice-surfaces/findings.md`.

**The review object is the framework, not its instances.** Example use cases
(a deprecation notice, a yes-or-no during the read, a choice once a pattern is
found) are inputs the components are exercised with, never scripts of their
own. Reviewing twelve renderings of the same mechanism costs twelve
corrections of one defect and converges on nothing; reviewing a few components
with parameters, and a contract of the conventions they share, converges on a
framework the next feature can call. The contract (components, parameters and
their defaults by use, keys, sizing, placement, padding, erasing, wording,
glyphs and colours) is written **before** the instances that follow it, and is
itself the first thing reviewed, as a document.

**Every round runs the same five steps**, and nothing is built between them:

1. The round's feedback is recorded in the findings, each remark with the
   exact command that drew the view it is about (the review runner saves both).
2. A read-back goes to the architect before anything is built: what was
   heard, what changes, what is not changing and why. Building waits for his
   confirmation of that reading.
3. The round's settled lines are proposed for lock and moved into the record
   in the same step: a locked decision in the feature doc, or a line of the
   project's design and interaction documents, which the contract becomes once
   settled. Only what still needs iteration stays open in the findings.
4. The next round is built against the contract. Claude's own check before
   review observes what the architect will observe, a terminal pane captured
   as it is seen, alternate screen included, or says that it cannot. A check
   that reads the escape stream, or a replay through an emulator without the
   feature under test, has not observed the surface.
5. The round shows only the views a change touched, or something new. A view
   the architect has validated is not shown again, and a mechanism validated
   on one surface (a key, a placement, the padding) is not re-shown on every
   surface that shares it. **The review list is the measure of convergence**:
   it gets shorter every round, towards sign-off, and a list that does not
   shrink is a round that did not converge.

**What was asked is what is rendered, counted.** A padding of two is two
cells measured in the capture, not two added to what was there; a pane's
empty rows are counted in the capture, each pane, each edge, never inferred
from the code meant to produce them. One missing row survived three rounds
with the capture that showed it in hand and uncounted.

**A locked form is swept across every surface when it is locked**, in the
same change, and the sweep is checked by reading each surface's rendering.
A form settled on one surface and left unapplied on another is a defect the
architect finds again.

**Inputs are the tool's own, at the tool's size.** A surface that carries a
chart carries the chart as `ltl` renders it, generated from a real run, at the
width the tool needs for it; a generic stand-in misleads the review of the
surface's size and padding.

**Both backgrounds are reviewed.** Every component is judged once per form on
a dark and on a light terminal before the stage closes; the colours that
survive one do not all survive the other.

**The verification method is chosen per surface, against what the first
delivery uses.** The method follows the surface it targets: the cheapest
capture that sees what the surface produces, and nothing runs on a platform
without its tooling. A surface printed inline is tested by a redirected run as
every harness is; a surface that must be driven (keys, layered pop-ups,
erasing) waits for the terminal-driving method until it is scheduled. A choice
among tools for every surface at once is the wrong question.

**Tension is found, not manufactured.** A decision goes to the architect when
two options are viable or a tension is unsettled, laid out with the situation,
the options and what each does and does not do. When the records settle it,
the step is recorded and taken, and saying so is the answer; alternatives
invented to show a choice where none exists cost the architect's time twice.

**Exit.** A design prototype exits when the architect has judged each
selected surface in a terminal; each surface has a demonstrated way to be
captured and checked unattended, chosen per surface; the contract has moved
out of the issue's record into the project's design and interaction
documents, with a locked decision behind every line; and the findings record
what was chosen, what was learned, and why. Prototype code is not promoted:
what `ltl` builds, and how, is scoped after the exit.

## (a)–(c): the cost prototype

The established workflow: **research → prototype → validate → refine design →
record decisions (as Dxx in the owning feature doc) → implement.**

Research precedes and grounds the prototype — candidate representations,
applicable measured constants, prior findings. The prototype compares
implementation candidates at staged scale (1k → 10k → 100k → millions) against
the current code as the baseline. Exit requires **measured justification**
(medians with ranges) and lessons learned recorded *before* implementation
begins.

Code can be logically correct and still work against the structures it runs
on. A prototype establishes how the structures the design relies on behave in
Perl, and checks that the design uses them the way its intent expects:

- how a scalar is stored and what an operation does to it: stored integers
  read by floating-point arithmetic cache the float and double in size;
- how memory is laid out and reused: sorting in place saves a copy but
  scatters the values, so later passes miss the CPU cache.

Where intent and mechanism diverge, the cost lands silently in the back end and
nothing in the source shows it. The findings report records these mechanisms,
observed with `Devel::Peek` and `Devel::Size` and by measuring each store's
size and each pass's time, not only the process peak.

Two rules that have cost time here when broken:

- **The baseline arm reproduces the production call structure, not just its
  logic.** A baseline wrapped in a convenience sub measures the wrapper. Extract
  the production code path verbatim — call shape, variable scoping, data movement
  included.
- **Constants come from the source, not from memory.** Slice them out of `ltl`
  (see `prototype/459-order-independence/extract-subs.sh` for the pattern); where
  a value must be restated, name the source symbol in a comment beside it so a
  reader can check it in one grep. Every constant restated from memory is an
  opportunity for the prototype to predict something the production code does not
  do.

## What lives here

Prototype scripts, their fixtures, and their findings reports. A findings report
is a deliverable: it records what was compared, against what, on what input, and
what was observed — in the units a reader sees. A prior finding is relayed by
what it measured, never by its name or headline phrase.

Prototype code is not production code and is not promoted into `ltl`. Its output
is the decision.

## See also

- `docs/test-driven-development.md` — where the (d) trigger comes from
- `tests/HARNESS-DESIGN.md` — building the harness once the method is known
- `docs/design-language.md`, `docs/terminal-interaction.md` — what a design
  prototype's contract becomes, and what a new surface is designed against
- `docs/process/workflow.md` § Feature lifecycle — where prototyping sits in the workflow
