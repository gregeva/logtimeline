---
paths:
  - "releases/**"
---
# Release notes

A release note is an index, not documentation. It tells a user that a
capability exists and gives them the flag and the issue to look it up by;
`docs/usage.md` and `--help` carry the detail, and the feature doc carries the
reasoning. A bullet that a user could read *instead of* the usage row has
already failed.

- **One line per issue, 25 words at the outside.** One line means one line: it
  is read in a list, not a paragraph. Over 25 words, cut — do not wrap.
- Verb first, present tense, no lead-in label: `Add -d/--discard <name> to ...`,
  `Fix ...`. Never `New:`, `Deprecated:`, `Enhancement:`.
- **Name the change once.** No second clause restating the first in other
  words, no "so that" chain, no enumerated cases, no list of accepted values,
  no worked example, no remedy advice, no before/after contrast.
- Never describe pre-existing behaviour, what the bug was, or why it happened.
  The fix is the bullet; the cause belongs on the issue.
- One `(#NNN)` at the end. A second user-observable change in the same issue is
  its own bullet with the same number, not a clause on the first.
- No bullet for work confined to `build/`, `tests/`, `features/`, CLAUDE.md or
  process; the completion comment on the issue says so.
- No usage examples, file lists, "Breaking Changes: None", "Known Issues" or
  root-cause analysis. Shape: `releases/TEMPLATE.md`; register: `releases/v0.14.0.md`.
- The `bug` / `enhancement` label on the issue decides the section.
- Edited directly on the release branch, committed and pushed without a PR.

## The Performance section

The benchmark always runs and its TSV and comparison report are always
committed under `tests/baseline/results/` — that record is what the next
release is judged against, and it is never abridged. The **section in the
release notes** is a pointer to it, not a reproduction of it.

- **Nothing moved: one or two sentences, and the comparison file's path.** Say
  the benchmark ran, say no improvement or regression was observed, cite the
  file. No tables, no percentages, no per-case figures. Register:
  `releases/v0.15.1.md`.
- **The hot path was untouched:** say that, and that no comparison is included.
  Register: `releases/v0.15.2.md`.
- **Performance was the point of the release:** tables earn their place, for the
  cases the work targeted. Only then.
- **A regression that ships is explained, not just disclosed.** Say what was
  measured and how, what a user can expect to feel and where, and what the cause
  turned out to be — including the counter-intuitive part, which is usually the
  whole reason the investigation was worth doing. "Some cases are slower" with no
  mechanism is a disclosure, not an explanation.
- The no-internals rule bans a vocabulary, not an explanation: no Perl
  identifiers, issue numbers or decision labels, and no sub names. The mechanism
  behind them is said in plain words.
- A number in this section is a claim about a measurement, so it is read from
  `compare-results.sh` output, never derived from the input TSVs.
