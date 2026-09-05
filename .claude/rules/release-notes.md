---
paths:
  - "releases/**"
---
# Release notes

- One bullet per issue that changed what a user of `ltl` observes, with a
  `(#NNN)` reference. Concise: the change, not every detail of it, and never
  pre-existing behaviour.
- No bullet for work confined to `build/`, `tests/`, `features/`, CLAUDE.md or
  process; the completion comment on the issue says so.
- No usage examples, file lists, "Breaking Changes: None", "Known Issues" or
  root-cause analysis. Shape: `releases/TEMPLATE.md`.
- The `bug` / `enhancement` label on the issue decides the section.
- Edited directly on the release branch, committed and pushed without a PR.
