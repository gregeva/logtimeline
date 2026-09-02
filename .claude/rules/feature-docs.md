---
paths:
  - "features/**"
---
# Feature docs

The feature doc is the primary planning artifact and the record of everything
found while executing the work. Issue comments only point here.

- Requirements, locked decisions (Dxx with rationale), open items, `-V`
  section contracts, merge gate, and an `## Acceptance criteria` section agreed
  before code, each criterion triaged assertable / unassertable / unknown.
- A finding, contract, constraint or hand-forward produced during the work is
  written here in the same action as any issue comment about it.
- A locked decision stands until the architect changes it; a line Claude wrote
  here carries no authority Claude did not already have.
- A finding is cited by what it measured, against what, on what input, and
  what the reader would observe; never by its tag or headline.
- Public repository: no customer names, case numbers, incident descriptions,
  hostnames or provenance. Contributed logs are described by what they are.
- Feature docs are committed and pushed directly to the release branch; they
  do not need a PR unless the architect asks for one.
