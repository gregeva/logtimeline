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
