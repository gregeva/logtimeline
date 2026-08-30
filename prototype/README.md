# Prototyping

Work that answers a question **before** implementation commits to an answer.

A prototype is not a draft of the feature. It is an experiment with a question,
a method and a recorded result, and its output is a decision in the owning
feature doc — not code that later becomes the implementation.

## When a prototype is mandatory

Not a judgment call. A prototype is required when the work introduces:

- **(a)** a new or changed data model
- **(b)** a new per-line hot-path cost
- **(c)** any feature or fix impactful by its cost profile — execution frequency
  × per-execution cost (a cheap operation run tens of millions of times, or an
  expensive one run per key at high cardinality)
- **(d)** a key requirement whose **verification method is not yet known**

(a)–(c) are cost questions: *will this be fast enough, and is this the right
shape to store?* (d) is a measurement question: *how would we know whether we
built what was asked for?* Both are cheaper to answer before implementation than
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

## (a)–(c): the cost prototype

The established workflow: **research → prototype → validate → refine design →
record decisions (as Dxx in the owning feature doc) → implement.**

Research precedes and grounds the prototype — candidate representations,
applicable measured constants, prior findings. The prototype compares
implementation candidates at staged scale (1k → 10k → 100k → millions) against
the current code as the baseline. Exit requires **measured justification**
(medians with ranges) and lessons learned recorded *before* implementation
begins.

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
- CLAUDE.md § *Development Phases* — where prototyping sits in the workflow
