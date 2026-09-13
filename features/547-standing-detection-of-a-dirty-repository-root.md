# 547: Standing detection of a dirty repository root

Issue #547 (BUG: `ltl -o` products left in the repository root are hidden by
`.gitignore` and reported by nothing). Branch off `release/0.18.1`.

## Status

Specification and acceptance criteria agreed. No script and no hook wiring
written yet. This document is the record; the corrections below are applied to
it rather than to the issue body, and the issue comment points here.

## Motivating consumer

The developer who saw the same failure twice in one session before its cause
was visible. During #527 (the export harness asserts against an aggregate
export it did not write, and the doc-examples harness leaves one in the
repository root) `tests/validate-aggregate-export.sh` failed its
`directories-relative` scenario twice, with failure text pointing at
`write_aggregate_export()` in `ltl` and at D9 of
`features/503-yaml-aggregate-export.md` (the working directory is never
recorded; the directory list is the distinct directory parts of the files
read), neither of which was at fault. The actual cause was an aggregate export
sitting in the repository root, left there by an earlier harness in the same
chain. It took a second failure and a direct investigation to see it, because
no surface in the repository shows a file that `.gitignore` covers.

That is what this issue is for: the developer is asking "is my root dirty in a
way I cannot see", and today there is no answer short of knowing to pass a flag
nobody in the repository passes. The consumer is not a user of `ltl` and not a
harness; it is the person starting a session, and the surface that person reads
every session is the outstanding-state sweep printed by
`build/claude-hooks/session-start.sh`.

The backlog is live, not hypothetical. Probed from this worktree on
2026-09-13, `git status --short --ignored=traditional` in the main checkout
lists three entries at depth one that `git status --short` does not show:
`ltl-index.csv` (117,991 bytes, written 12 September), `nytprof.out`
(10,845,993 bytes, from 27 August) and `.DS_Store`. The first run of any
detector reports a backlog, not a clean root.

## Requirement

An artifact left at depth one of a repository root that `.gitignore` hides is
named at session start, with enough detail to decide what it is, and nothing
deletes it. Specifically:

1. The session-start outstanding-state sweep reports every ignored artifact at
   depth one of the session's own root and of the main checkout, with its size
   and its age.
2. Nothing in the mechanism removes, moves or truncates any file.
   `tests/cleanup-test-artifacts.sh` stays the only sanctioned cleanup.
3. A file the developer keeps on purpose can be silenced without editing a
   tracked file and without deleting anything.
4. The report is absent when there is nothing to report, and the hook never
   blocks or delays a session on account of it.

## Corrections to the issue body

1. **`features/527-harness-owns-its-working-directory.md` now exists, on the
   #527 branch, and was read.** When #547 was filed the path was dangling in
   both issue bodies. It is present in the #527 worktree today and contains the
   finding #547 cites, recorded as D8 of that document (standing detection of a
   dirty repository root is out of scope there; the fail-fast guard reports it
   at the point where it matters, and if standing detection is wanted it is a
   small separate issue). The pointer is therefore valid once #527 lands. Until
   it lands, the artifact is on a branch, not on `release/0.18.1`, so this
   document states the finding in its own words rather than relying on the
   cross-reference.

2. **#527 has not landed, and its leak is live.** Its issue status is
   `in progress`. `./tests/validate-doc-examples.sh` run on a verified-clean
   root exits 0 reporting 49 passed, 0 failed, 10 skipped while leaving three
   products in the repository root. A harness reporting total success while
   leaking is the defect this issue exists to make visible, and it is also why
   the tightening recorded as D3 below is deliberately not part of this issue.

3. **"An aggregate export and two CSVs" is six artifact classes, five of them
   hidden.** The six are enumerated in § *The six artifact classes*. The issue's
   three are a subset, and the largest offender actually present in the main
   checkout is not among them.

4. **".gitignore covers all three product classes" is true, but the
   load-bearing rule is not a product rule.** `git check-ignore -v` attributes
   the aggregate export to the `*-LTL-AGGREGATE.yaml` rule, and the STATS CSV,
   the MESSAGES CSV and `ltl-index.csv` all to the blanket `*.csv` rule;
   `nytprof.out` is caught by `*.out`. So a detector keyed on product name
   shapes misses `nytprof.out` entirely, while a detector keyed on what git is
   hiding catches everything including a developer's unrelated scratch CSV.
   That asymmetry is what decides D4 below.

5. **"Reported by nothing" is one flag away inside git.**
   `git status --short --ignored=traditional` reports every one of them as a
   `!!` entry. Nothing in the repository passes that flag. Raw, it is not the
   wanted signal: on the main checkout it returns 38 lines, of which 34 are
   profiling results, editor state, the worktree directory and the logs corpus.
   Three are at depth one. The depth-one filter is what makes the probe usable,
   not the command alone.

6. **No dependency edge exists between #547 and #527, in either direction**,
   and none is created here. See § *Ordering*.

## The mechanism

Three correct facts compose into the defect, and none of them is individually
wrong.

**Every runtime product path in `ltl` is a bare name resolved against the
process working directory.** The aggregate-export writer builds its path as
`run_file_stamp() . "-LTL-AGGREGATE.yaml"` and dumps to it; `build_csv_filename()`
returns a base of the shape `${timestamp}-LTL-${file_type}-${safe_args}`; and
`locate_index_file()` returns `.`-rooted paths. There is no option to redirect
them and no statement of where they went. Run from the repository root, which
is exactly what `docs/usage.md` documents, they land in the repository root.

**Every surface that reports repository state reads git's default non-ignored
view.** `build/claude-hooks/session-start.sh` probes with
`git status --short`, `.githooks/pre-commit` reads
`git diff --cached --name-only`, and `tests/cleanup-test-artifacts.sh` looks
only at its own `.artifacts` directory under `tests/`. None of them passes
`--ignored`.

**The blanket ignore rule does double duty.** Ignoring the products is right,
because they must never be committed. But "ignored" was allowed to mean "not
worth mentioning" as well as "uncommittable", and no surface anywhere in the
repository distinguishes the two. The fix is to add the one surface that does:
a probe that asks git what it is hiding, rather than a fifteenth independent
spelling of the product name shapes.

## The six artifact classes

All six are written relative to the process working directory. Five are hidden.

| Class | Written by | Ignored by | Frequency |
|---|---|---|---|
| Aggregate export `*-LTL-AGGREGATE.yaml` | the `-o` export writer | `*-LTL-AGGREGATE.yaml` | every `-o` run |
| STATS CSV `*-LTL-STATS-*.csv` | `build_csv_filename()` | the blanket `*.csv` | every `-o` run |
| MESSAGES CSV `*-LTL-MESSAGES-*.csv` | `build_csv_filename()` | the blanket `*.csv` | every `-o` run without `-n 0` |
| `ltl-index.csv` | `locate_index_file()` | its own named rule | every run without `-ni`, so the most frequent by far |
| `nytprof.out` | the profiling workflow, whose default output file is `./nytprof.out` | `*.out` | every profiling run; the largest artifact in the main root by two orders of magnitude |
| `.ltl-index.$$.tmp` | `locate_index_file()`, removed by `write_index_file()` only on the failure path | **not ignored** | only after a crash between open and rename |

The sixth is the inverse defect and needs no detector: git already shows it,
because nothing ignores it. It is listed so that a future reader does not add a
rule for it and thereby hide the one member of the family whose signal works.

## Decisions

**D1 (locked, architect): the detector is a script under `build/`, called from
the session-start sweep.** Not a harness assertion, and not a change to `ltl`.
*Rationale:* developer tooling under `build/` sits in the skip row of the scope
table in `docs/process/workflow.md` § 3, where both the full harness suite and
the before/after benchmark are skipped with the skip recorded, while any
`tests/validate-*.sh` change is required/required, the same cost as changing
`ltl`. A harness assertion would additionally fail today on the live #527 leak,
making this issue's own gate hostage to another open issue. Changing `ltl` is not
on the table: writing products to the current working directory is the normal
contract of a command-line tool and is how `ltl` works (architect, 2026-09-13);
the defect is that nothing reports what an earlier run left, not where it went.

**D2 (locked, architect): report only; nothing deletes.**
`tests/cleanup-test-artifacts.sh` stays the only sanctioned cleanup. *Rationale:*
the files may be the developer's own output, and the repository-hygiene rule in
CLAUDE.md makes anything destructive against an untracked project artifact the
architect's call, never a script's.

**D3 (locked, architect): making a leaking harness fail is a follow-up, not
part of this issue.** After #527 lands and removes the live leak, the
tightening is one line: the fail-fast guard that #527's own D4 places in each
harness that runs `ltl -o` is extended to the repository root, or the detector
script is called with a non-zero-is-fatal wrapper from the gate's harness
chain. The line goes in `tests/HARNESS-DESIGN.md` § *A harness owns the
directory it runs `ltl` in*, the section #527 adds, as a fourth paragraph
beside its three. *Rationale:* landing it now turns #527's live leak into an
immediate gate failure for every issue, and the signal is wanted before that
coupling is acceptable.

**D4 (delegated): detection is git-keyed, with a small fixed exclusion list.**
The probe is `git status --short --ignored=traditional`, filtered to entries
with no path separator in them, minus the exclusion list in the script
contract below. *Rationale:* it answers the developer's actual question, it
catches every ignored artifact including `nytprof.out` and a stray scratch CSV
that a shape-keyed probe would miss, and it adds no new spelling of the product
shapes. The `traditional` mode is chosen deliberately over the default
`--ignored`, which collapses an ignored directory to its directory entry;
`traditional` lists the files, and combined with the depth-one filter that is
what keeps `logs/` and the profiling results directory from flooding the output
while still naming loose files in the root.

Nonetheless the product-shape vocabulary (`*-LTL-AGGREGATE.yaml`,
`*-LTL-STATS-*.csv`, `*-LTL-MESSAGES-*.csv`) is centralised in the same script,
as the labelling table that turns a bare filename into a named class in the
output. It is not the matcher. *Rationale:* CLAUDE.md's one-resolution-surface-
per-vocabulary rule wants one home for these shapes, and the fourteen
independent spellings across `tests/*.sh` have nowhere to converge today. Giving
them a home costs nothing here and creates the target. **Recorded as a finding,
not done here:** converging the fourteen harness sites onto that table is not
part of this issue; it touches `tests/validate-*.sh` and would pull the diff
into the required/required row of the scope table for no benefit to the
reported case.

**D5 (delegated): scope is the session's own root plus the main checkout, at
depth one.** The main checkout is determined from
`git rev-parse --git-common-dir`, taking the parent directory of the `.git`
path it returns; when the two resolve to the same directory, only one is
probed. *Rationale for depth one:* it is what the issue asks for, it is the
cheap quiet probe, and on the main checkout it reduces 38 lines to 3. *Rationale
for the main checkout:* a worktree session must see the main checkout's backlog,
which is precisely where the 10.8 MB `nytprof.out` and the 117 KB
`ltl-index.csv` are sitting today; a probe anchored on `CLAUDE_PROJECT_DIR` or
`git rev-parse --show-toplevel` reports a clean worktree while that sits
unreported one directory away. *Rationale for `--git-common-dir` over
`git worktree list`:* `git worktree list` prints the main checkout as its first
line, which is a positional convention rather than a stated guarantee, and
parsing it means splitting a line that contains a path with spaces in it.
`--git-common-dir` returns the shared git directory by definition, in both a
worktree and the main checkout, and its parent is the main checkout root. It is
one command with no parsing.

**D6 (delegated): every ignored artifact at depth one is reported;
`ltl-index.csv` is listed only when it is older than the newest tracked file in
that root, and otherwise counted in a single trailing clause.** *Rationale:* it
is rewritten on every run without `-ni`, so under undifferentiated reporting it
appears at every session start forever and is the entry most likely to train a
developer to skim the whole block. The two candidate reduced forms were
counting it always, and listing it only when stale. Staleness is chosen because
it carries information the count does not: a fresh `ltl-index.csv` is the
expected residue of ordinary development and says nothing, while one older than
every tracked file in the root says the root has been sitting untouched with an
index in it, which is the case worth a line. The comparison is against the
newest tracked file rather than against a fixed age so that the threshold moves
with the developer's own activity instead of needing a tuned constant.

**D7 (delegated): an untracked acknowledgement list at
`.claude/root-clean-ack.txt` silences named files.** One bare filename per
line, blank lines and `#` comments ignored, matched against the entry's
basename, no globs. A listed name produces no output at all, not a muted line.
The file is per checkout, so the main checkout's list applies to the main
checkout's findings and the session root's to its own. *Rationale for the
location:* `.gitignore` already covers it through the existing `.claude/*` rule
with its two tracked negations, verified with `git check-ignore -v`, so no
`.gitignore` change is needed and the file cannot reach the public repository;
it sits beside `settings.local.json`, which is the established home for
machine-local state that Claude never edits. *Rationale for existing at all:*
under report-only with no acknowledgement, a developer who deliberately keeps a
STATS CSV in the root receives the identical line at every session start
forever with no way to answer it, which is exactly how a report-only detector
becomes noise. *Rationale for no globs:* a glob is a second matcher to get
right, and a name-per-line list is auditable by reading it.

**D8 (delegated): output shape.** One line per finding inside the existing
`== Outstanding state` block printed by `build/claude-hooks/session-start.sh`,
then one closing line naming the sanctioned cleanup. Nothing at all on a clean
root, not even a heading. Exact format in § *The script contract*. *Rationale:*
the block is the surface the developer and the session both already read, a
heading printed on a clean root is the thing that trains the eye to skip the
block, and the closing line exists so that the report never leaves the reader
to invent a cleanup of their own.

**D9 (delegated): the acceptance criteria assert the mechanism; the attention
half of the issue's "Done when" is met by construction, not left as a gap.**
The issue's criterion is that the artifact "is reported by at least one of the
surfaces a developer sees routinely". The mechanism half is asserted in full
below. The attention half is satisfied by the choice of surface rather than by
a test: the session-start outstanding-state sweep is printed at startup,
resume, clear and compact, and CLAUDE.md's session-start checkpoint makes
reading it the first action of every session. There is no gap to record,
because the requirement is met by where the output goes, and no assertion about
a developer's attention would add anything to that. *Consequence, stated:* a
product created mid-session is reported at the next session start rather than
at the moment it appears. That is accepted; the issue asks for a dirty root to
be visible without anyone looking for it, not for it to be visible instantly.

**D10 (delegated): gate scope is skip and skip, with the skip recorded, and no
release-notes bullet.** The diff touches `build/` and `features/` only, plus
the hook wiring in `.claude/settings.json` if it changes at all, which places it
squarely in the skip row of the scope table in `docs/process/workflow.md` § 3.
*On the release-notes bullet:* `docs/process/workflow.md` § 4 step 6 states that
work confined to `build/`, `tests/`, `features/`, CLAUDE.md or process gets no
bullet, and this work is confined to `build/`. Two earlier release notes do
carry tooling entries, and D12 of the #544 specification (the profiling
workflow cannot run on the development machine and its setup is not
upgrade-safe) cites two of them in deciding that a profiling workflow which
installs its own toolchain earns a bullet. The two decisions are consistent
rather than in conflict: #544 changes a workflow the developer runs by hand and
whose failure mode they experience directly, whereas this detector changes only
what an existing automated sweep prints. Nothing a reader of the release notes
can run behaves differently. No bullet.

**D11 (delegated): prototype, none.** None of the four triggers in
`prototype/README.md` applies: no new or changed data model, no new per-line
cost, no frequency-times-cost profile, and the verification method is known and
was demonstrated during the investigation, on both roots.

**D12 (delegated): the hook never fails a session.** The script's own exit code
is informative; the call site in `build/claude-hooks/session-start.sh` discards
it. *Rationale:* the sweep exits 0 unconditionally today and a session that
cannot start because the root is dirty would be a far worse defect than the one
being fixed. The non-zero exit exists for the future call sites named in D3 and
for a developer running the script directly.

## The script contract

`build/check-root-clean.sh`

**Inputs.** No required arguments. Two optional ones: a directory path, which
probes that root instead of the default pair, and `--quiet`, which suppresses
output and yields only the exit code. An unknown argument is rejected with a
non-zero exit and a usage line rather than being ignored, per the class of
defect #545 describes (harnesses accept an unknown scenario selector or flag
silently and run every assertion).

**The probe.** For each root, in order, the session's own root first:

- The session's own root: `git rev-parse --show-toplevel`.
- The main checkout: the parent directory of the path
  `git rev-parse --git-common-dir` returns. Skipped when it resolves to the
  same directory as the session's own root, so a session in the main checkout
  reports one root, not two.
- In each root: `git -C "$root" status --short --ignored=traditional`, keeping
  only lines whose status field is `!!`, and of those only entries whose path
  contains no `/`. Depth one, exactly.

**Exclusions.** Applied after the depth-one filter, by exact basename:

- `logs`, the corpus symlink each worktree carries; the one stable entry on a
  clean worktree root, verified on this worktree today.
- `.DS_Store`, editor and finder state, not a project artifact, present in the
  main checkout today.

Nothing else is excluded by default. The list is short and fixed on purpose:
anything else a developer wants silenced goes in the acknowledgement file, where
it is their decision and visible to them, rather than accumulating in a tracked
script.

**The acknowledgement file.** `<root>/.claude/root-clean-ack.txt`, read per
root, absent by default. One basename per line; a line whose first
non-whitespace character is `#` and a blank line are skipped; leading and
trailing whitespace is trimmed. A matching entry produces no output. Already
covered by the existing `.claude/*` rule in `.gitignore`, confirmed with
`git check-ignore -v`; no `.gitignore` change is part of this issue.

**Labelling.** The product-shape table lives here, and only here in this script:
`*-LTL-AGGREGATE.yaml` is labelled `aggregate export`, `*-LTL-STATS-*.csv` is
`STATS CSV`, `*-LTL-MESSAGES-*.csv` is `MESSAGES CSV`, `ltl-index.csv` is
`run index`, `nytprof.out` is `profile output`. Anything else is labelled
`untracked, ignored`. The label is presentation; it never decides whether an
entry is reported.

**Output format.** Written to standard output, inside the caller's existing
block. Sizes in whole KB or MB, ages in whole days, both rounded down. One line
per finding:

```
FINDING: dirty root <root-label>: <filename> (<label>, <size>, <age>)
```

where `<root-label>` is `session` or `main checkout`, and age reads
`today` for under a day and `N days old` otherwise. Against the main checkout as
it stands today the block would read:

```
FINDING: dirty root main checkout: nytprof.out (profile output, 10 MB, 16 days old)
FINDING: dirty root main checkout: ltl-index.csv (run index, 115 KB, today)
nothing is deleted automatically; ./tests/cleanup-test-artifacts.sh is the only sanctioned cleanup
```

The `ltl-index.csv` line appears only under the D6 staleness rule. When the
index is present and not stale, it is folded into the closing line instead, as
`(1 run index not listed, current)`. On a clean root the script prints nothing
and the closing line is not printed either.

**Exit codes.** `0` when every probed root is clean after exclusions and
acknowledgements; `1` when at least one finding was printed; `2` on a usage
error or when a root cannot be probed. The caller in
`build/claude-hooks/session-start.sh` discards all three (D12).

## The hook wiring change

`build/claude-hooks/session-start.sh` gains one call, placed after the
`uncommitted:` and `unpushed on this branch:` probes and before the release
branch comparison, so that git's visible state and git's hidden state are
adjacent in the block. The call is guarded on the script being executable and
its exit status is discarded:

```
[ -x ./build/check-root-clean.sh ] && ./build/check-root-clean.sh || true
```

`.claude/settings.json` does **not** change. The `SessionStart` matcher
`startup|resume|clear|compact` already covers every moment the report is wanted,
and no new hook event is introduced. This is stated explicitly because the issue
and the pre-interview both left the wiring open; the conclusion is that there is
nothing to wire.

`build/setup-hooks.sh` does not change either: it activates the tracked
pre-commit guard and has no relationship to the session-start hook.

## Acceptance criteria

Every criterion below is exercised in a scratch clone or scratch directory under
the scratchpad, never in the worktree root, and no `ltl` run in any of them
omits `--disable-progress`.

- [ ] With an `ltl -o` product planted at depth one of a scratch clone's root,
      the script lists it with its size and its age and exits non-zero.
      **[assertable]** Method: create a scratch clone, run
      `ltl --disable-progress -o -bs 1440 -oe` against the smallest fixture
      carrying the signal inside a scratch directory, move one product to the
      clone's root, run `build/check-root-clean.sh <clone-root>` capturing
      output once to the scratchpad, and read from the file that the line names
      the file with a non-zero size and an age, and that the exit status is 1.
- [ ] With the planted product's name in `.claude/root-clean-ack.txt` in that
      root, the script prints nothing for it. **[assertable]** Method: repeat
      the previous step, write the basename into the acknowledgement file, run
      again, and confirm the output contains no line naming that file. With that
      file the only finding, the exit status is 0 and the closing line is absent.
- [ ] With `ltl-index.csv` the only ignored artifact at depth one and newer than
      the newest tracked file, it is not listed and is reported only in the
      closing clause. **[assertable]** Method: in a scratch clone with a
      freshly written index and no other ignored depth-one entry, confirm no
      `FINDING:` line names it and the trailing clause reports one run index not
      listed. Then set its modification time behind every tracked file and
      confirm it is listed as a finding.
- [ ] On a clean root the script produces no output at all. **[assertable]**
      Method: in a scratch clone with only the excluded entries present, confirm
      the captured output file is empty and the exit status is 0. This is the
      criterion that keeps the block quiet, and it is the one a future exclusion
      change breaks first.
- [ ] Nothing is deleted, moved or modified. **[assertable]** Method: checksum
      every file at depth one of both probed roots before and after a run that
      reports findings, and compare the two listings, including modification
      times. The comparison is a listing, never a deletion. This is the
      sabotage-resistant form of D2: a detector that cleans up would pass every
      other criterion here.
- [ ] Run from a worktree session, the script probes the main checkout and
      reports its findings labelled as such. **[assertable]** Method: run the
      script from a scratch worktree of a scratch clone with a product planted
      in the clone's main root and the worktree root clean, and confirm the
      output carries a `main checkout` line and no `session` line. This is the
      criterion the naive anchoring on the session's own toplevel fails.
- [ ] Run from the main checkout, the script probes one root, not two.
      **[assertable]** Method: the same scratch clone, run from its own root,
      with each finding appearing exactly once.
- [ ] The session-start sweep still exits 0 and prints its existing block when
      the script reports findings, and when the script is absent or not
      executable. **[assertable]** Method: run
      `build/claude-hooks/session-start.sh` in a scratch clone with a planted
      product, confirm exit 0 and the findings inside the existing
      `== Outstanding state` block; then with the script bit cleared, confirm
      exit 0 and an unchanged block.
- [ ] An unknown argument is rejected. **[assertable]** Method: run the script
      with a flag it does not define and confirm a non-zero exit and a usage
      line, rather than a probe of the default roots.

**Unassertable: none.** The attention half of the issue's "Done when" is met by
the surface the output goes to rather than by an assertion; the reasoning is
D9, and it is not recorded as a gap.

**Unknown verification method: none.** Every criterion above was demonstrated
in shape during the investigation, on both this worktree and the main checkout.

## Completion gate

Skip and skip, with the skip recorded in the completion comment (D10). The diff
touches `build/` and `features/` only, which is the skip row of the scope table
in `docs/process/workflow.md` § 3: no full harness suite, no before/after
benchmark. No executable line of `ltl` changes, no `tests/validate-*.sh`
changes, no fixture or expectation a harness reads changes, and no `-V` section
or key changes. `--help` and `docs/usage.md` are untouched, so
`tests/validate-help-content.sh` has nothing new to check. `$version_number` is
restored to `X.Y.Z` before the gate regardless, per the pre-PR checkpoint. No
release-notes bullet (D10). Should the diff acquire a `tests/` file for any
reason, the scope test is re-applied and the row becomes required and required.

## Ordering

**#527 first, and no `blocked_by` edge.** #527 (the export harness asserts
against an aggregate export it did not write, and the doc-examples harness
leaves one in the repository root) should land before the tightening recorded as
D3, because it removes the live leak that would otherwise make a leaking-harness
failure fire on every gate the moment it is introduced. That is the reason for
the sequence, and it applies to the follow-up rather than to this issue: nothing
in this specification waits on #527, and the files the two touch are disjoint
(#527 works in `tests/` and `tests/HARNESS-DESIGN.md`; this issue works in
`build/` and `features/`).

No dependency edge exists between the two today, in either direction, and none
is created here. Should the architect want one recorded, the command is:

```
gh api -X POST repos/{owner}/{repo}/issues/547/dependencies/blocked_by -f issue_id=<527 node id>
```

It is stated rather than run.

Against the other open work: #546 (the histogram bin-counter `-V` emitter
labels a consumer unified when no value was observed, so the no-consumer state
the contract promises is misreported) has no technical overlap, different
surfaces and no shared vocabulary; it competes only on gate cost, since a `-V`
section change is required and required while this issue is skip and skip. #545
(harnesses accept an unknown scenario selector or flag silently and run every
assertion) is the same family of defect, a developer-facing surface reporting
success while something was silently not done, and the script contract adopts
its requirement for unknown-argument rejection by hand; that is a
cross-reference, not an edge.

## Findings forwarded, not filed

Three findings were established during the investigation and are the
architect's to dispose of. None is in scope here.

1. **Two `ltl` runs started in the same second in the same directory overwrite
   each other's products.** `run_file_stamp()` memoises one timestamp per run at
   second resolution, and `build_csv_filename()` builds every product name from
   it, so two runs in the same second with the same options collide on all three
   names and the later one silently wins. This is live on the development
   machine, where several agents run `ltl` concurrently. It matters to this
   issue only in that a reported product may be the overwritten remains of two
   runs. It is a defect in `ltl`'s naming rather than in detection, and folding
   it in would move this issue out of the skip row of the scope table.

2. **The product-shape vocabulary is spelled independently at fourteen sites
   across `tests/*.sh`, plus prose in `docs/usage.md` and
   `features/503-yaml-aggregate-export.md`, and no library under `tests/lib/`
   owns it.** D4 gives it one home in `build/check-root-clean.sh` as a
   labelling table so that a target exists; converging the fourteen sites onto
   it is separate work touching `tests/`. D6 of the #527 specification records
   the adjacent finding from the other direction (eight correct inline
   implementations that give a `-o` run its own directory, deliberately left
   unconverged) and names #342 (audit redundant logic surfaces that must
   converge to single resolution functions) as the natural home, noting that its
   stated scope is `ltl` rather than the harnesses.

## Related records

- `features/527-harness-owns-its-working-directory.md` (on the #527 branch until
  it lands). D8 there records why standing detection was left out of scope and
  that it is a small separate issue, which is this one. Its D4 places the
  fail-fast guard that D3 above extends.
- `features/503-yaml-aggregate-export.md`, the export `-o` writes. D9 there
  (the working directory is never recorded; the directory list is the distinct
  directory parts of the files read) is why `ltl` writing to the current
  directory is a contract rather than an oversight, and is untouched here.
- `build/claude-hooks/session-start.sh`, the outstanding-state sweep: the one
  surface changed.
- `tests/cleanup-test-artifacts.sh`, the only sanctioned cleanup, unchanged.
- `docs/process/workflow.md` § 3 (the scope table) and § 4 step 6 (the
  release-notes rule): the basis for D10.
- CLAUDE.md § Repository hygiene: `logs/` and every untracked project artifact
  are read-only; anything destructive is the architect's call. The basis for D2.
