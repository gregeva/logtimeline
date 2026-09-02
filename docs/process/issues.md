# Issues and Records

How GitHub issues are filed, tracked and linked, and where each kind of record
lives. `CLAUDE.md` holds the checkpoints; this file holds the conventions.

## Where things are recorded

| Record | Lives in | Not in |
|---|---|---|
| Requirement (what and why) | issue body, in the architect's own terms | design, line numbers, plans |
| Design, locked decisions (Dxx), acceptance criteria, findings, contracts, hand-forwards | the owning `features/*.md` | issue comments (they only point at the doc) |
| A decision about an issue's disposition | the open issue's own thread, transcribed at the moment it is made | only the closing comment of some other PR or issue |
| A deferral ("restorable from X") | a committed artifact that X actually contains, verified before the deferral is written | branch memory |
| Change history | git: commit messages, PR descriptions, `git blame` | code comments, script headers, doc narratives |
| Internal mechanism (identifiers, issue numbers, jargon) | source comments, feature docs, issue and PR bodies | `--help`, `--explain`, `docs/usage.md`, `docs/explain/`, error messages, the wiki |
| Anything about the tooling used to do the work (problem reports, tool feedback, transcripts, scratch) | the session scratchpad or `/tmp` | anywhere in the repository |

Code is referenced by enclosing function name plus a distinctive snippet to grep
for. Line numbers drift within a day and may appear only as hints.

## Issue conventions

Every issue carries a type prefix in its title and the matching label, applied
when filed:

| Kind | Title prefix | Label |
|---|---|---|
| Defect | `BUG:` | `bug` |
| New capability or improvement | `FEATURE:` or `Enhancement:` | `enhancement` |

The label drives release-notes classification (`What's New` vs `Bug Fixes`).

## Filing a requirement

When the architect asks for an enhancement request or bug report to be filed,
the deliverable is the requirement, and nothing else. File it and stop. Do not
read the implementation first: exposure to the current code pulls the write-up
toward the mechanism that exists rather than the capability that is wanted.

**A requirement body contains:**

- the capability or defect in the architect's own terms, at the level of
  abstraction he used, transcribed and organised, not reinterpreted
- the problem it solves or the wrong behaviour observed; for a bug, the
  reproduction as described
- the user-visible outcome that makes it done
- **links**: the feature docs that govern the area (path and section heading),
  the issues it relates to, extends, supersedes or overlaps (number with
  parenthesised context), the locked decisions that bear on it; and where it
  cannot proceed until another issue lands, a native `blocked_by` recorded at
  filing
- open questions, marked as open, where intent was genuinely not stated

**A requirement body never contains:** line numbers or ranges; an
implementation plan, phases, drops or task list; proposed data structures, sub
names, option names, algorithms or code sketches; effort estimates or
sequencing; acceptance criteria the architect did not state; a framing he did
not use presented as his.

A requirement is short. Past roughly a screen, the excess is specification.
If something is unclear, ask one question before filing.

## Issue updates

Issues are updated when work starts, during investigation, on design decisions,
and at completion. Every comment carrying a finding, contract, constraint or
status change is written into the owning feature doc in the same action; the
comment references the doc. Completion and close follow
`docs/process/workflow.md` § 4.

The **`not planned` label** marks an *open* issue retained as a decision or
spec record (e.g. #370, temporal interpolation). Such issues are not closed:
"label as not planned" and "close as not planned" are different dispositions.

## Issue status

Every open issue carries exactly one `status:` label. Closed issues carry none.

| Label | Meaning |
|---|---|
| `status: backlog` | Accepted and understood; no work underway. Where anything filed lands. |
| `status: in progress` | Branch cut, work underway. Set before the first line of code. |
| `status: in review` | PR open against the release branch. |
| `status: on hold` | Deliberately paused by an explicit decision. Says nothing about whether work has started. |

Status changes at the moment the state changes, never batched. The transitions
are embedded in the steps that cause them (branch verification, PR creation,
close). `build/issue-status.sh` is the only sanctioned writer; `set` swaps
labels atomically.

```bash
./build/issue-status.sh set {number} "in progress"
./build/issue-status.sh show {number}
./build/issue-status.sh list
./build/issue-status.sh sweep      # strips status from closed issues; proposes, never applies, elsewhere
```

Status is a deliberate decision, never a computed value. A recorded status
stands until another decision changes it; `sweep` leaves `on hold` and
`in progress` alone because both record a judgement no signal can second-guess.
When a change is not self-evident from the thread, comment the reasoning and
where the decision lives.

`on hold` records a decision to pause, not an amount of progress. Leaving it
goes to `in progress` when work has started; `backlog` is reachable only by
explicit instruction, and an issue never returns to `backlog` once work has
begun unless the architect says so. A parent issue is `in progress` once work
has started on it or any child, and stays so until closed or deliberately held.

Status is orthogonal to blocking and to `not planned`.

## Blocking relationships

Blocking is tracked only through GitHub's native issue dependencies, never a
label, body line or comment on its own.

- The blocker must be an open issue. Releasing dependents is part of closing
  the blocker (`docs/process/workflow.md` § 4 step 9).
- The native edge is created in the same action that files or re-plans the
  issue. "Native dependency still to be recorded" is a defect, not a TODO.
- The body also carries a human-readable `Blocked by #N (context)` line; both
  must exist and agree.
- One API call maintains both directions.

**Dependency-first test before any cross-issue note:** can this issue proceed
to a clean implementation before the other lands? No → native `blocked_by` plus
agreeing prose, never a comment. Yes → an informational note is acceptable and
states explicitly why it is not a gate.

```bash
# "#DEPENDENT is blocked by #BLOCKER"
BLOCKER_ID=$(gh api repos/{owner}/{repo}/issues/BLOCKER --jq '.id')
gh api --method POST repos/{owner}/{repo}/issues/DEPENDENT/dependencies/blocked_by -F issue_id="$BLOCKER_ID"

# Inspect
gh api repos/{owner}/{repo}/issues/DEPENDENT/dependencies/blocked_by --jq '[.[].number]'
gh api repos/{owner}/{repo}/issues/BLOCKER/dependencies/blocking --jq '[.[].number]'
```

## Reframing

When an issue's framing changes (the architect says "reframe it", or a finding
overturns the title's hypothesis), every artifact carrying the old framing is
trued up in the same action: title, body, branch name (the slug follows the
title), feature doc, analysis records, comments. Nothing is asked per item.
