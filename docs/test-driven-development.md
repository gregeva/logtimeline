# Test-Driven Development

How a requirement becomes something that can be checked, and when that happens.

This document owns the *process*. `tests/HARNESS-DESIGN.md` owns how a harness is
built once you know what it must assert; `prototype/README.md` owns what happens
when you do not yet know how to assert something.

## The rule

**Test cases are derived from requirements, recorded in the specification, and
agreed before implementation begins.** They are not written after the code to
confirm it works.

The order is not a preference. A test written after the code inherits whatever
the code happens to do, including a misreading of the requirement, and it will
pass while the feature is wrong. A test derived from the requirement cannot pass
against the wrong design, because it was written from the thing the architect
asked for rather than from the thing that got built.

## Acceptance criteria

Every feature doc carries an `## Acceptance criteria` section, written during the
planning walkthrough. Each criterion is a **condition and an observable
outcome** — the shape an assertion takes:

```
- [ ] When two or more files are selected, the progress line shows the overall
      percentage and the file counter; with one file it shows neither.
- [ ] A run whose input includes an unreadable file still reaches 100%.
- [ ] The category bar uses the colour table the timeline's duration and bytes
      columns use, with no per-category fill table.
```

Not every requirement can be expressed this way, and that is allowed — but it is
*discovered here*, during specification, where it is cheap and where the
requirement can still change. It is not discovered during implementation, where
the only remaining move is to write whatever assertion the existing code permits.

Criteria cover the **key** requirements of the feature: the ones that would make
a reviewer say the feature was not delivered if they failed. Exhaustiveness is
not the goal; a criterion per requirement clause, mechanically produced, is
noise. What matters is that the load-bearing requirements each have one.

### Where a requirement names an existing mechanism

When the requirement says to reuse something that already exists — a renderer, a
resolution surface, a colour table — **the criterion names it too**. "The bar
uses the mechanism the timeline's duration and bytes columns use" is checkable:
the same table, the same loop. A criterion written that way cannot pass against a
newly invented substitute, which is the failure it exists to prevent.

## Triage: the three states

Writing a criterion forces the question *how would I observe this?* Each
criterion lands in one of three states, **before implementation**:

| State | Meaning | What happens |
|---|---|---|
| **Assertable** | The verification method is known | It goes into the criteria; a harness scenario follows |
| **Unassertable** | It genuinely cannot be checked | Recorded as a known gap with the reason; the architect decides whether the requirement stands |
| **Unknown** | The method is not yet known | **Determining it becomes prototyping scope** — see `prototype/README.md` |

The third state is the one that gets skipped, and skipping it is expensive. An
unresolved "how do I check this?" does not disappear: it is answered later, during
implementation, by whatever the code already written happens to permit. That is
how a feature acquires assertions that confirm its own misreading of the
requirement.

## Proportionality

**The verification method is proposed with its cost, and where that cost is
non-trivial the architect decides whether it is worth paying.**

Some requirements are obvious to any tester on a single run and do not justify
machinery. Others need real infrastructure. Both failure modes are available and
both are real: skipping verification because it looks hard, and building an
elaborate suite for something a person would spot immediately.

The judgement is the architect's, not an implementation detail to be settled
alone. Bring the options and the cost.

## Implementation is done when the criteria pass

That is what "done" means. It is not "the code works as far as I can tell", and
it is not "the harnesses are green" — harnesses can be green against a feature
that was never built to the requirement.

**If a criterion turns out to be unbuildable during implementation, stop and
raise it.** It means the requirement and the design have diverged, and continuing
means silently choosing the design. That divergence is the most expensive thing
this document exists to catch, because testing cannot catch it: the tests written
after the fact inherit the divergence.

## Visual surfaces

Output that a person reads — colour, fill, alignment, line shape — is asserted by
inspecting **what is rendered**, not by grepping for escape sequences. A test that
confirms a particular escape code is present confirms only that some code was
emitted; it will pass against a fill drawn from the wrong colour table, two rows
that render identically when they must differ, or a bar a character wider than
the data supports.

Where a change touches a visual surface, the rendered output is looked at, on
real data, before the work is called done.

The general method for asserting a rendered terminal surface is an open question
in this repository at the time of writing, and is scoped as prototyping research
under the "unknown" state above.

## See also

- `tests/HARNESS-DESIGN.md` — building the harness once you know what to assert
- `prototype/README.md` — resolving an unknown verification method
- CLAUDE.md § *Development Phases* — where this sits in the workflow
