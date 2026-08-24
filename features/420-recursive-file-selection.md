# #420 — Recursive file selection with `-r`/`--recursive`

Owning doc for the `-r`/`--recursive` file-argument expansion contract: how a
file pattern splits into a root set and a filename filter, the traversal order
beneath each root, and what the sweep does with things it cannot read.

## Goal

Express an analysis over a directory tree of logs in one invocation, with
identical semantics on macOS, Linux, and Windows.

`ltl` globs its file arguments in-process (`adapt_to_command_line_options()`,
the `push @in_files, bsd_glob($pattern)` loop) and drops non-files with
`grep { -f $_ }`, so each `*` matches exactly one directory level and
directories are silently discarded. The shell-side workarounds — `**`
globstar, `find` + substitution — are platform-dependent, which defeats the
reason in-process globbing exists.

## Governing statement

**`-r` replaces one-level matching with all-depth matching of the same
filename pattern against the same root set. Nothing else changes.**

Every decision below is a consequence of that sentence. When a case is
ambiguous, this is the tiebreaker.

## Locked decisions (planning walkthrough, 2026-08-24)

- **D1 — Pattern splits at the last `/`.** The directory part is globbed
  exactly as today with `bsd_glob()`, yielding the roots; the final component
  is a filename filter applied to basenames at every depth beneath each root.
  Wildcards in the directory part need no special handling —
  `logs/*/access/*.888` globs `logs/*/access` to a set of roots. An empty
  directory part makes the root `.`, so `-r *.888` recurses from the current
  directory.

  Rejected: treating the whole pattern as the root source. The final component
  is by definition a *file* filter, so globbing the full pattern to find
  directories to descend would find nothing for `logs/access/*.888` and
  recursion would silently do nothing.

- **D2 — A bare directory argument matches nothing, with or without `-r`.**
  `logs/access` names only directories and carries no filename component, so
  there is nothing to match. Unchanged from today. This is why D1's split is
  unambiguous rather than a heuristic: a valid pattern always has a filename
  component.

- **D3 — Without `-r`, behavior is exactly what ships today.** `-r` is purely
  additive. The non-recursive path is not refactored through the new
  expansion.

- **D4 — Directories are descended regardless of their own name.** The
  filename filter gates files only: a directory named `2026-08` is entered
  under a `*.888` filter. Same shape as `grep` with `--include='*.888'`.

- **D5 — Breadth-first traversal, alphanumeric within each level.** Every
  match at the root level is collected before any match one level down, and so
  on; shallower always precedes deeper regardless of name. Within a level,
  matching files are emitted in alphanumeric order, then subdirectories are
  queued for the next level in alphanumeric order.

  Rationale (architect): log trees put current or general files at the top and
  archives nested below, so breadth-first leads with the most relevant files.
  A plain alphanumeric sort of full path strings does not do this — `/` sorts
  before `-` in ASCII, so `access/2026-08/a.888` would land between
  `access/2026-08-15.888` and `access/b.888`, interleaving depths. Sorting
  directories as well as files at each level makes the whole traversal
  deterministic and identical across platforms, which `File::Find`'s default
  (depth-first, filesystem-read order) is not.

- **D6 — Multiple patterns expand independently; results deduplicated when
  `-r` is given.** Patterns concatenate in command-line order as today. A
  recursive sweep can reach one file from two patterns whose roots nest
  (`ltl -r logs/*.888 logs/access/*.888`), and reading a file twice doubles
  its lines into the analysis. Deduplication is `-r`-only: changing the
  existing non-recursive behavior (`ltl f.888 f.888` reads it twice) is out of
  scope for this issue.

- **D7 — Directory symlinks are not followed.** This avoids traversal loops (a
  symlink to an ancestor) and duplicate collection via distinct paths to the
  same tree — neither of which path-based dedup can catch. Symlinks *to files*
  are still collected, since `-f` follows the link.

  This is the conservative reading of both `grep` implementations: BSD
  `grep -R` does not follow unless `-S` is given; GNU `grep -r` follows only
  links named on the command line, reserving follow-everything for `-R`. Since
  `ltl` defines no `-R`, no-follow is the single behavior.

- **D8 — Unreadable directories: collect, continue, report once at the end.**
  Directories that cannot be opened are accumulated during the sweep and
  reported as a single `Note:` to STDERR at the tail of
  `read_and_process_logs()`, following the deferred-note precedent already
  there (the numeric-filter no-metric note). The sweep continues past them: a
  permission-denied directory partway through a large legitimate tree must not
  abort the run, but the gap must not be silent either. STDERR keeps it clear
  of `-o` CSV and piped output.

  No truncation rule and no `-V` listing (architect): the names are enough, and
  a user who cannot read a directory through `ltl` cannot read it through
  Finder or Explorer either.

- **D9 — In-process implementation.** Core Perl (e.g. `File::Find`), so
  semantics are identical across platforms — the same reason `bsd_glob()` is
  used today rather than deferring to the shell.

- **D10 — Option naming.** `-r` / `--recursive`, both forms. `r` is unclaimed
  in the GetOptions block and `-r` is currently rejected as an unknown option,
  so no abbreviation collides (`-or`, `-ru` are distinct). The naming follows
  BSD and GNU `grep`, which both document `-r` alongside `--recursive`; POSIX
  specifies no recursion option for `grep` at all, so this is a de-facto
  convention the two major implementations agree on rather than a standard.
  Only `-r` is defined — no `-R` variant (see D7).

- **D11 — No prototype required.** The mandatory-prototype triggers do not
  apply: no new or changed data model, no per-line hot-path cost, no impactful
  cost profile. `-r` is one-time argument expansion completing before any line
  is read, and `@in_files` is unchanged in shape.

## Verification

New harness `tests/validate-recursive-file-selection.sh`.

**Assertion surface — no new `-V` section required.** `-V format-detection`
already emits `files: N` followed by one `file: <path>` line per entry in
`@in_files` order (`emit_format_detection_verbose()`, whose comment states
this is the canonical order). That carries everything the contract needs:
which files matched, how many, in what order, and whether any appears twice.

It is more reliable than scanning summary output, not less: the summary
aggregates across files, so with empty fixture files no file contributes
lines and none would be distinguishable there — but each still appears as a
`file:` entry here.

**Fixture tree** — committed under `tests/fixtures/`, several levels deep,
built from empty files with numeric extensions: `.888` (matching), `.123` and
`.000` (non-matching siblings at each level). Numeric extensions cannot
collide with code or tooling extensions and are untouched by `.gitignore`,
unlike `*.log` and `*.csv` (both blanket-ignored, which is why the motivating
`*.log` example cannot be a fixture). Non-matching siblings make filtering
assertable positively and negatively, and a wrong `file:` line is self-evident
on failure. Enough breadth per level for alphanumeric ordering to be
meaningful.

Note: git does not track empty directories, so a directory intended to hold no
matches is expressed as one containing only non-matching files — a better test
in any case.

**Properties asserted**: depth-widening (`-r` collects what non-`-r` does not),
non-`-r` behavior unchanged (D3), filename filtering at depth (D1),
directories descended regardless of name (D4), breadth-first ordering (D5),
alphanumeric ordering within a level (D5), dedup across nesting patterns (D6),
and the empty-directory-part `.` root case (D1).

**Constructed at run time**: the unreadable-directory note (D8), via `chmod`
under the scratch directory — it cannot be committed and does not apply on
Windows.

**Not asserted**: symlink no-follow (D7). Committed symlinks behave
inconsistently across platforms and this tool ships on Windows. The contract
stands; it carries no harness assertion.

**Invocation shape**: per `tests/HARNESS-DESIGN.md` § "Invocation coherence",
the harness reads file selection and never a bucket, so it runs `-bs 1440 -oe`
against the tiny fixture tree.

## Documentation obligations

`print_help()` and the options reference in `docs/usage.md` updated in the
same commit — parity enforced by `tests/validate-help-content.sh`.

## Implementation notes

- **N1 — The sweep is an explicit breadth-first queue, not `File::Find`.**
  D5 requires shallower-before-deeper with alphanumeric ordering within each
  level; `File::Find` is depth-first in filesystem-read order and offers no
  option that produces D5's order. `expand_recursive_pattern()` therefore
  walks the tree itself with `opendir`/`readdir`, sorting each directory's
  entries once and making two passes over them — matching files first, then
  subdirectories queued for the next level. The two passes are what keep the
  traversal breadth-first rather than interleaving a directory's own matches
  with its children's.

  `opendir` is also what makes D8 implementable: a directory that cannot be
  opened reports the error, whereas `bsd_glob` on an unreadable directory
  returns an empty list indistinguishable from one that legitimately holds no
  matches.

- **N2 — The filename filter is a compiled regex that agrees with `bsd_glob`.**
  `bsd_glob` cannot be asked to match a basename in a directory other than the
  one its pattern names, so `basename_matches_glob()` compiles the filename
  component to an equivalent regular expression, cached per pattern. Agreement
  with `bsd_glob` is the contract — "the same filename pattern" means the
  pattern a user writes selects the same names at depth that it selects at the
  top level — and was verified against `bsd_glob` itself over `*`, `?`,
  `[...]`, `[!...]`, `{a,b}`, escapes, and literal names.

- **N3 — A leading dot is only matched by a pattern that spells it out.**
  Not specified in the contract; resolved by N2's agreement rule. `bsd_glob`
  excludes dotfiles from `*` by default, so `-r *.888` does not select
  `.hidden.888` while `-r .*.888` does — the same as the non-recursive path.

- **N4 — Root globbing and root-set nesting.** The directory part is globbed
  with the same `bsd_glob` call the non-recursive path uses, then filtered to
  directories that are not symlinks (D7 applies to roots as well as to
  descended directories). The queue carries a seen-set from the start, so a
  root set that nests (`logs` and `logs/access` both matching the directory
  part) descends the shared subtree once.

- **N5 — Deduplication is a separate pass over `@in_files`, not per-pattern.**
  D6 dedups across the whole run, so the pass runs after the argument loop and
  after the `-f` filter, and only when `-r` is given.

## Verification record

Harness `tests/validate-recursive-file-selection.sh`: 17 assertions, all
passing, over the committed fixture tree at
`tests/fixtures/recursive-file-selection/` (eight `.888` files across four
levels, with `.123`/`.000` siblings at each level, numerically-named archive
directories for D4, and a directory holding only non-matching files).

Each asserted property was proved able to fail by sabotaging the code it
covers (HARNESS-DESIGN.md § "Proving a new assertion can fail"):

| Sabotage | Assertions that failed |
|---|---|
| Reverse the within-level sort | breadth-first/alphanumeric ordering (1) |
| Remove the `-r` deduplication pass | both dedup assertions (2) |
| Gate directory descent on the filename filter | depth, D4, ordering, `.` root, dedup, unreadable-note (9) |

**Completion gate** (both run on the merged commit's content): the complete
`tests/validate-*.sh` suite exits 0 — 22 harnesses — and
`single-day-access-log-standard` against the `v0.16.0` baseline shows no
metric worse by more than 5% (`TIMING/total` -20.1%, `MEMORY/rss_peak` +2.6%;
both reflect the release span rather than this change, which does no work when
`-r` is unset).

Note for anyone re-running the suite from a git worktree:
`validate-regression.sh` compares rendered output byte-for-byte, and the
rendered file legend embeds the absolute path of the input file, so all eight
`hl-*` scenarios fail on the checkout path alone. They pass when the same
modified `ltl` runs from the main checkout, where the reference outputs were
captured.
