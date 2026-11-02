# Investigation

How a view is grounded before it is stated: a plan, a design opinion, a
diagnosis, a finding. `CLAUDE.md` points here; this file holds the practice.
It applies to any view, not only to the planning step of an issue
(`docs/process/workflow.md` § 2).

## Finding the owning records

The records that govern a surface are found by search, never taken from an
issue's links: an issue body snapshots what its author knew at writing time.

```bash
./process/find-records.sh --issues <term> [<term> ...]
```

It lists every record under `features/`, `docs/` and `releases/` and, with
`--issues`, every open and closed issue body, that carries a term. An exit
status of 3 means an issue search failed and the list is incomplete; the
search is repeated before the list is relied on.

The terms are the surfaces the work touches:

- every option, short and long form (`-g`, `--group-similar`);
- every sub and every user-visible message the work touches;
- a surface with no option of its own (a file argument, a column) by the subs
  and messages that implement it.

Each record found is read, or dismissed in the feature doc with its reason,
judged by its subject, never by the lines that matched. An entry of
`docs/architecture-patterns.md` the search names is a record of its own.

A decision that adds a surface (a sub, a store, a path run per line or per
value) re-runs the search over that surface's nouns before it is locked.

## What is a record

A feature doc, a design doc under `docs/`, a release note, an issue body in the
architect's words. An audit, an issue body's restatement of a record, or
another record's summary points at a record; it is never the record. Every
feature file and doc an issue references is read; investigation findings live
there, not in the issue thread.

## A divergence is a finding only with its record line

Behaviour that looks wrong is a finding only when the primary record line that
defines the expected behaviour is quoted, after a search for a record that
makes the behaviour deliberate. Without one it is an observation, raised as a
question, never stated as a correction or a defect.

## Measure the premise first

A performance fix measures its premise's constants at development scale before
the prescribed change is made; mandatory when the code has moved since the
issue was written (`docs/process/workflow.md` § 2 step 2).

## Capture once

Any output looked at more than once is captured to the scratchpad once and
read there with grep, sed, diff or python3. Harnesses are not debuggers.

- A prototype, reproduction, profiling or benchmark run of `ltl` passes bare
  `-V` and is captured, so a later question is answered from the file, not a
  re-run. Harness assertions stay shaped to what they read
  (`tests/HARNESS-DESIGN.md` § Invocation coherence).
- A failing child process is invoked directly on minimal input, never through
  the parent harness. A harness under iteration runs only the scenarios the
  change needs, one `--scenario` per name (`.claude/rules/harnesses.md`).

## Citing a finding

A finding is cited by what it measured, against what, on what input; it is
re-read before it is cited, never recalled by its name.
