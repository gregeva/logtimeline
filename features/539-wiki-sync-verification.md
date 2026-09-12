# Feature: wiki sync as a script the release verifies

## Overview

The wiki is generated from `docs/`: at every release each page is overwritten
with a byte-for-byte copy of its source. That made the two surfaces consistent
by construction — as long as the copy ran. It was a shell one-liner written out
in the release procedure for a person to paste, and it left no trace in the
repository, so a release that ended without it looked exactly like a release
that included it. Some releases ended without it, and the published wiki fell
behind.

This work turns the copy into `build/sync-wiki.sh`, which carries the
source-to-page map, publishes from it, and verifies what is published against
`docs/`. The release is not finished while that verification fails.

## GitHub Issue

- #539 (BUG: published wiki pages are behind the `docs/` sources they are
  copied from) — the three observed symptoms, and the open question of where
  the check belongs.

## Findings

### F1 — the reported symptoms were repaired by the v0.18.0 sync, before this work began

The issue records three symptoms observed on the live wiki on 2026-09-05:
`Statistics-Reference` behind `docs/explain/statistics.md` by two content
changes, `Home` behind `docs/usage.md` by roughly 150 lines, and
`Classification-Reference` absent altogether.

Cloning `logtimeline.wiki` on 2026-09-12 and diffing each of the seven mapped
pages against its source: all seven are byte-for-byte identical, and
`Classification-Reference.md` is present. The wiki's most recent commit is
`Sync wiki docs from v0.18.0`. No `docs/` file has changed between the `v0.18.0`
tag and `release/0.18.1`, so nothing has fallen behind since.

The symptoms are therefore gone and the defect is not. What the issue asks for
is the second half of its own *what done looks like*: a mechanism that survives
a release in which someone forgets.

### F2 — content equality cannot detect a skipped sync

The obvious check — clone the wiki, diff each page against its source — passes
whenever `docs/` has not moved since the last publish, whether or not this
release's publish ran. A release that changes no documentation leaves every page
matching its source while the sync is skipped, which is the state
`release/0.18.1` is in today: seven pages current, no v0.18.1 sync.

Verification therefore also reads the wiki's most recent commit subject and
asserts it names the version being released. Demonstrated against the live wiki:
`./build/sync-wiki.sh verify` exits 0, and `./build/sync-wiki.sh verify
--version 0.18.1` exits 1 reporting the last commit is `Sync wiki docs from
v0.18.0`.

### F3 — the map existed in three places, none of them authoritative

Before this work the pairing of source to page was written in the `cp` lines of
the procedure's one-liner, parsed back out of that prose by
`tests/validate-explain.sh`, and retyped by whoever ran the release. A harness
assertion existed only because the map lived in a document: it checked that each
copied page was also named in the `git add`, a defect possible only in a
hand-written command line.

## Decisions

### D1 — the sync runs from the release procedure, not CI

CI was considered first and rejected on a concrete constraint: GitHub's wiki is
a separate repository that the Actions `GITHUB_TOKEN` cannot push to, so a CI
job would need a Personal Access Token held as a repository secret. The
architect has no secure secret store, so the sync stays a mechanical step in the
release procedure and the work goes into making that step impossible to skip
silently.

### D2 — the check does not run at session start

Surfacing a stale wiki through the session-start hook was considered and
rejected: it would clone a remote on every session start, resume, clear and
compaction, to guard a step that runs a few times a year. This is release
mechanics and it belongs in the release procedure alone.

### D3 — `build/sync-wiki.sh` is the single source of the map

The map is written in the script and nowhere else. The release procedure runs
the script instead of restating the map; `tests/validate-explain.sh` reads the
map by running `./build/sync-wiki.sh map` instead of parsing it out of the
procedure. A `docs/` file the wiki should carry gets a line in that map and no
other edit.

### D4 — publish is separate from verify

`publish` writes and pushes; `verify` is read-only and needs no write access.
They are separate commands so the verification can be re-run by anyone, at any
time, without the risk of publishing something unintended.

## Acceptance criteria

- **AC1** — every page the map names carries the byte-for-byte content of its
  source, checkable by a command that exits non-zero when one does not.
  *Assertable*: `./build/sync-wiki.sh verify`, probed by appending a line to
  `docs/explain/heatmap.md` and observing `[behind] Heatmap-Reference.md differs
  ... (2 changed line(s))` with exit 1.
- **AC2** — a release whose publish never ran fails verification even when every
  page matches its source. *Assertable*: `./build/sync-wiki.sh verify --version
  0.18.1` against the live wiki reports the last commit is the v0.18.0 sync and
  exits 1.
- **AC3** — a map line naming a file that does not exist is reported before any
  network access, so the failure is not mistaken for a network fault.
  *Assertable*: probed by pointing a map line at `docs/nonexistent.md`; the
  script reports the missing source and exits 1 without cloning.
- **AC4** — every `docs/explain` mirror is carried by the map. *Assertable*:
  scenario `wiki-sync-map` in `tests/validate-explain.sh`, probed by deleting
  the histogram line from the map.
- **AC5** — the release procedure both publishes from the map and verifies the
  result. *Assertable*: scenario `wiki-sync-map`, probed by removing the verify
  invocation from `docs/process/workflow.md`.

## Implementation

`build/sync-wiki.sh` with three commands: `publish --version X.Y.Z` (copy, stage,
commit as `Sync wiki docs from vX.Y.Z`, push; pushes nothing when no page
changed), `verify [--version X.Y.Z]` (read-only diff of every page against its
source, plus the last-commit assertion when a version is named), and `map`
(print the source-to-page pairs, which is how consumers read it).

`docs/process/workflow.md` step 14 becomes the two script invocations, and step
13's definition of a finished release now names an unrun wiki sync alongside an
open release PR.

`tests/validate-explain.sh` scenario `wiki-sync-map` reads the map from the
script. Its three assertions are that every mapped source exists, that every
`docs/explain` mirror is carried by the map, and that the release procedure runs
both `publish` and `verify`. The staged-page assertion is dropped: the script
stages what it copies, so the defect it guarded cannot occur. Scenario
`wiki-link-form` is unchanged.

## Completion gate

Recorded at close-out.
