# Feature: a harness honours its scenario selector and rejects what it does not know

Record for issue #545 (BUG: harnesses accept an unknown scenario selector or
flag silently and run every assertion).

Owning contract: `tests/HARNESS-DESIGN.md`. The selector is a property of the
harness contract and has no section there today; this work adds one.

Consumer: the operator iterating on a single harness. `CLAUDE.md` § Before
running a command directs that a harness under iteration uses `--scenario` or a
single-test selector. That checkpoint is unenforceable against a harness that
does not parse the selector, and actively misleading against one that parses it
and ignores an unknown name: the run reports success over the full assertion
set while the operator reads it as the one scenario they named.

---

## What was measured

Measured on `release/0.18.3` at 256768a, 2026-09-20.

### The corpus is larger than the issue records

The issue body states thirty-six harnesses, four of which parse `--scenario`.
`ls tests/validate-*.sh | wc -l` returns **40**, and `grep -l -- '--scenario'`
matches **8**. The four harnesses added since the issue was filed
(`validate-message-discard.sh`, `validate-message-expose.sh`,
`validate-message-mask.sh`, and the count generally) all parse the selector,
so the gap is thirty-two harnesses, not thirty-two of thirty-six.

### Two distinct defects, not one

The issue describes one behaviour. Two were observed, and they need different
fixes.

**A harness that does not parse arguments discards them.** Every argument is
ignored, and the full assertion set runs to a zero exit:

```
./tests/validate-message-grouping-notices.sh --scenario no-such-thing
  ...
  Results: 4 passed, 0 failed
rc=0

./tests/validate-message-grouping-notices.sh --bogus-flag
rc=0
```

**A harness that parses the selector may still not validate the name.** This is
the more dangerous class, because the operator has evidence the harness
understands the option. Behaviour across the eight parsing harnesses on
`--scenario zzz-no-such`:

| Harness | exit | what it does |
|---|---|---|
| `validate-message-discard.sh` | 2 | `ERROR: unknown scenario 'zzz-no-such'` plus the scenario list |
| `validate-message-expose.sh` | 2 | same |
| `validate-message-mask.sh` | 2 | same |
| `validate-udm-specs.sh` | 2 | `ERROR: no scenarios ran (check --scenario 'zzz-no-such')` — detected after the fact, not before |
| `validate-csv-output.sh` | 1 | runs part of the harness, then fails for an unrelated reason |
| `validate-statistics.sh` | 1 | fails with no diagnostic naming the selector |
| `validate-aggregate-export.sh` | 0 | **runs nothing, reports success** |
| `validate-filter-summary.sh` | 0 | **runs nothing, reports success** |

The last two are the exact failure #545 was filed for, in harnesses that already
parse the option. `validate-aggregate-export.sh` gates each scenario on
`want()`, which returns false for every scenario when the name is unknown, and
the harness then certifies itself:

```
./tests/validate-aggregate-export.sh --scenario zzz-no-such
Validating the YAML aggregate export (Issue #503)

Results: 0 passed, 0 failed
ALL AGGREGATE-EXPORT TESTS PASSED
rc=0
```

`validate-filter-summary.sh` prints the same shape
(`Results: 0 passed, 0 failed` / `ALL FILTER-SUMMARY TESTS PASSED`). A zero
assertion count is reported as a pass, which is the worst available outcome:
the operator's evidence that the harness ran is the line that says it did not.

### A reference implementation already exists

`tests/validate-message-discard.sh` (#567, merged in this release) does what the
issue asks: a `SCENARIOS=(...)` array, a `usage()` that prints it, an argument
loop whose `*)` arm is an error, membership validation of the selected name
before any assertion runs, and `exit 2` for both unknown-scenario and
unknown-flag. `validate-message-expose.sh` and `validate-message-mask.sh` carry
the same code. The pattern is proven; it is duplicated three times, with the
scenario-name list written twice in each copy (once in the array, once in the
dispatch `case`), which is a drift surface.

### Four structural groups decide the per-harness cost

Classified by where each harness names its scenarios — inside a function
(selectable by calling or not calling it) or at top level (runs unconditionally
as the file is read). The discriminator is whether the `current_scenario=` /
`current_mode=` / `current_anchor=` assignments are indented into a function
body or sit in column one:

**Group 1 — named functions with a flat dispatch list (16 harnesses).**
`validate-format-detection.sh` is typical: 48 scenario functions, each opening
with `current_scenario="..."`, called from a list at the foot of the file. Also
`validate-explain.sh` (41), `validate-histogram-bin-counters.sh` and
`validate-index-read-back.sh` (20 each), `validate-runtime-config.sh` (19),
`validate-udm-specs.sh` (20), the three message harnesses that already have the
selector, plus `validate-format-registry.sh`, `validate-help-content.sh`,
`validate-udm-counting.sh`, `validate-duration-display.sh`,
`validate-heatmap-palette.sh`, `validate-profile-render.sh` and
`validate-doc-examples.sh`. Adding a selector is mechanical — replace the call
list with a registry and a loop.

**Group 2 — named scenarios inline at top level (16 harnesses).**
`validate-statistics-demand.sh` (17 scenarios), `validate-classification-percentages.sh`
and `validate-message-grouping.sh` (13 each), `validate-classification-states.sh`
and `validate-aggregate-export.sh` (12), `validate-summary-contribution-bar.sh`
(11), `validate-bucket-size-units.sh` and `validate-recursive-file-selection.sh`
(9), `validate-progress-line.sh` (8), `validate-log-level-vocabulary.sh`,
`validate-outcome-criteria.sh` and `validate-numeric-criteria-notices.sh` (6),
`validate-category-names.sh` (5), `validate-message-control-characters.sh` and
`validate-message-grouping-notices.sh` (4), and `validate-filter-summary.sh` (3).
Each block runs as the file is read, so it must be wrapped in a function before
it can be selected. Mechanical but larger, and it touches the whole body of each
file. Two of these — `validate-aggregate-export.sh` and
`validate-filter-summary.sh` — are the pair that today reports success while
running nothing.

**Group 3 — the scenario name is data, not code (2 harnesses).**
`validate-csv-output.sh` and `validate-statistics.sh` read
`tests/*/scenarios.tsv` and loop over its rows; the scenario name is the first
column. The registry already exists — it is the TSV — so the selector only has
to validate the name against that column. This is the cheapest group, and the
`0 passed, 0 failed, exit 0` outcome is closest to the surface here.

**Group 4 — no scenario structure at all (6 harnesses).**
`validate-csv-input.sh`, `validate-help-layout.sh`, `validate-histogram-ticks.sh`,
`validate-regression.sh`, `validate-profile.sh` and
`validate-distribution-shape.sh`. Some name their units differently
(`current_anchor` in distribution-shape, `current_mode` in profile, `run_test`
cases in regression); others are a flat sequence of assertions under an
`echo "[label]"` banner. These need a scenario vocabulary decided before a
selector can exist, and that is a design decision per harness, not a sweep step.

### The suite is not at risk

Release step 11 and `docs/process/workflow.md` § 3(a) both invoke every
`tests/validate-*.sh` with no arguments. Strict argument parsing changes
nothing for a bare invocation, so the sweep cannot break the gate by
construction.

---

## Decisions

**D1 — the scope is all forty harnesses, Groups 1 to 4.** Consistency obliges
it: a selector honoured by some harnesses and ignored by others cannot be
relied on, and an operator cannot tell which is which without reading the
harness. Same reasoning as the colour-environment sweep (#438), where a guard
applied only to the harnesses observed failing was rejected for leaving the
same latent inconsistency everywhere else.

**D2 — the work runs in stages on one branch, not as two issues.** Splitting
Group 4 into a follow-up would guarantee the mixed state D1 exists to prevent,
for as long as the follow-up sat in the backlog.

**D3 — existing scenario names carry over; the term is standardised.** Group 4's
harnesses that already have a unit of work keep those names as their selector
tokens: the distribution-shape anchors (normal, exponential, bimodal, ...), the
profile modes, and the regression cases. Nothing is renamed and no vocabulary is
invented. What is standardised is the *term*: every harness calls its units
scenarios and holds the running one in `current_scenario`, so a selector token
means the same thing suite-wide. `current_anchor` and `current_mode` are
renamed; the names they hold are untouched.

Measured scope of D3: `current_scenario` already has 1225 uses across the suite
against 29 `current_mode` and 12 `current_anchor`, both confined to one harness
each (`validate-profile.sh`, `validate-distribution-shape.sh`). The
standardisation is two files. (`current_year` in `validate-index-read-back.sh`
is a date value, not a unit of work, and is untouched.)

---

## Resolution

**A shared library, on the precedent of `tests/lib/runtime-warnings.sh` (#341)
and `tests/lib/colour-env.sh` (#438).** Both prior cross-harness sweeps landed
as one sourced helper applied to every harness in a single commit, rather than
forty local implementations. `tests/lib/scenario-select.sh` would own the
argument loop, the membership check, the usage/list output and the exit codes,
so the rule is enforced in one place and a new harness inherits it by sourcing
one file.

**One registry per harness, not two lists.** The registry maps a scenario name
to the function that runs it, so the name list and the dispatch cannot drift
apart — the defect the three existing copies of the pattern already carry.

**The contract gains a section.** `tests/HARNESS-DESIGN.md` states that a
harness declares its scenarios, honours `--scenario`, rejects an unknown
scenario name and an unknown flag with a non-zero exit, and runs no assertion
in either case.

**The harness proves itself.** The library is itself under test: an assertion
that an unknown name exits non-zero with no assertion run, and that a known name
runs that scenario and no other.

---

## Implementation record

### The library

`tests/lib/scenario-select.sh`, sourced like `runtime-warnings.sh` and
`colour-env.sh` before it. A harness calls `scenario_register` with its scenario
names in run order and `scenario_parse_args "$@"`; it then dispatches through
`scenario_selected` (a list to loop over) or gates blocks with
`scenario_wanted`. Registering a duplicate name is a harness defect and exits 2.

A harness with flags of its own sets `SCENARIO_EXTRA_ARG_HANDLER` to a function
that claims them, so unknown-argument rejection stays in one place.

**The handler reports through a variable, not stdout.** The first design had it
echo the number of arguments consumed, and `validate-statistics.sh` — the first
consumer, with three flags of its own — exposed the defect: the handler runs
under `$(...)`, a subshell, so `--skip-l3` set `SKIP_L3=1` in the subshell and
the parent never saw it. A probe confirmed the flag reading 0 after being
passed. The handler now sets `SCENARIO_ARGS_CONSUMED` and is called in the
current shell.

### Stage 1 — the library, the contract, and Group 3

`tests/HARNESS-DESIGN.md` § The scenario selector states the contract.
`validate-csv-output.sh` and `validate-statistics.sh` register from the first
column of their `scenarios.tsv`, so the selectable names are the rows that run,
by construction.

Both harnesses now behave:

```
./tests/validate-csv-output.sh --scenario zzz-nope
ERROR: unknown scenario 'zzz-nope'
Usage: ./tests/validate-csv-output.sh [--scenario NAME] [--list]
Scenarios:
  access-bytes-duration
  ...
rc=2
```

and a named scenario runs alone — `CI=1 ./tests/validate-csv-output.sh
--scenario access-bytes-duration` reports `1 scenarios, 6 pass, 0 fail`;
`CI=1 ./tests/validate-statistics.sh --scenario apache-default --skip-l3`
reports `1 scenarios, 1 pass, 0 fail` over 985 checked cells. An unknown flag
exits 2 in both.


### Stage 2 — Groups 1, 2 and 4

The remaining thirty-eight harnesses. Every one declares its scenarios,
honours `--scenario`, rejects an unknown name and an unknown flag with exit 2,
and runs no assertion in either case. Verified mechanically across the whole
suite: forty harnesses checked, zero non-compliant.

**Group 1 (16) — a registry replaces the dispatch list.** The flat call list at
the foot of each file becomes `scenario_register` plus a loop over
`scenario_selected`. The selector token is the scenario's own literal
`current_scenario` where it has exactly one that does not interpolate, and the
function name otherwise: in `validate-explain.sh`, `current_scenario` is a
per-assertion label (`topic:$topic`, `reflow:width-$w`), not a stable name, so
tokens there derive from the function names.

**Group 2 (16) — each top-level block is gated.** The blocks stay where they
are, wrapped in `if scenario_wanted <name>; then`, with the banner comment
pulled inside the block it labels. They are not lifted into functions: several
carry heredocs and shared locals that a wrapper would change.
`validate-aggregate-export.sh` is the exception — it already gated every block
on its own `want "$current_scenario"`, so `want` became a thin alias for
`scenario_wanted` and the harness keeps one selection surface instead of two.

**Group 4 (6) — the vocabulary is standardised (D3).**
`validate-distribution-shape.sh` had a parallel `--anchor` selector over
`current_anchor`; `validate-profile.sh` had `--mode` over `current_mode`. Both
now use `--scenario` and `current_scenario`, and the names they select (normal,
exponential, bimodal; the profile modes) are unchanged. Three harnesses gained
a vocabulary they did not have: `validate-regression.sh` registers one scenario
per reference file on disk (so a case and the reference it is diffed against
cannot drift), `validate-help-layout.sh` one per layout section,
`validate-histogram-ticks.sh` one per rendered width plus the multi-histogram
case, and `validate-csv-input.sh` declares the single scenario it runs.

`validate-regression.sh` takes a documented positional argument naming an
alternative reference directory; it claims that through
`SCENARIO_EXTRA_ARG_HANDLER`, so the positional still works and an unknown flag
is still refused.

**One latent gap closed on the way.** `validate-profile.sh` ran its
profile-off case only when no mode was selected, so selecting any mode silently
skipped it. It is now a registered scenario (`profile-off`) and selectable like
any other.

**Two ordering defects found and fixed.** `validate-index-read-back.sh` ran six
helper self-test assertions before reaching its argument parsing, so a rejected
argument had already run assertions — against the contract's "runs no
assertions in either case". Parsing moved ahead of the self-tests.
`validate-doc-examples.sh` printed its banner before rejecting. Both now refuse
before any output.

### Verification

Every converted harness was run against a worktree of the pre-conversion commit
(`LTL_LOGS_DIR` pointing at the real corpus) and compared on exit code and
assertion count:

| | before | after |
|---|---|---|
| `validate-explain.sh` | 689 | 689 |
| `validate-format-detection.sh` | 272 | 272 |
| `validate-histogram-bin-counters.sh` | 147 | 147 |
| `validate-aggregate-export.sh` | 146 | 146 |
| `validate-udm-specs.sh` | 126 | 126 |
| `validate-profile.sh` | 106 | 106 |
| `validate-statistics-demand.sh` | 102 | 102 |
| `validate-filter-summary.sh` | 87 | 87 |
| `validate-index-read-back.sh` | 59 | 59 |
| `validate-message-discard.sh` | 57 | 57 |
| `validate-classification-states.sh` | 56 | 56 |
| `validate-runtime-config.sh` | 51 | 51 |
| `validate-profile-render.sh` | 50 | 50 |

and the rest likewise, all sixteen of Group 1 and all sixteen of Group 2
matching. For the six largest, the full output was diffed line by line and is
identical apart from the harness path and blank-line spacing.

One run of `validate-aggregate-export.sh` reported `csv_cache_produce rc=1` on
the `oracle-chain` rows, one assertion short. It did not reproduce: the
scenario alone passes 44 assertions and the full harness 146. The baseline
worktree and the converted checkout share one cache directory, and the
comparison ran them back to back — cache contention between two checkouts, not
a defect in either. Worth knowing for the next comparison run of this shape.


### Stage 3 — the selector is itself under test

`tests/validate-scenario-selector.sh`, seven scenarios, 23 assertions. Two
subjects, because the contract has two halves:

- **The library**, through probe harnesses written to a temporary directory.
  A probe registers three scenarios and prints one line per scenario that runs,
  so "ran nothing" and "ran everything" are distinguishable — which is exactly
  what the defect behind this issue could not be.
- **The suite**, swept for the two refusals and the `--list` listing. This is
  the half that regresses: a harness added or rewritten later loses the
  selector silently, and the suite's own green run says nothing about it. Same
  reasoning as the runtime-warning (#341) and colour-environment (#438) sweeps.

**Each assertion was proved able to fail** (HARNESS-DESIGN.md § Proving a new
assertion can fail), by sabotaging the library and running the harness against
it:

| Sabotage | What failed |
|---|---|
| Accept an unknown scenario name (the #545 defect itself) | all four `unknown-name-refused` assertions; the sweep reported 35 of 40 harnesses accepting it |
| Ignore an unknown flag | both `unknown-flag-refused` assertions |
| Selection returns every scenario regardless of the selector | three `selects-one` assertions |
| Run the extra-argument handler under command substitution | two `harness-keeps-its-own-flags` assertions — the stage 1 bug, which this harness would have caught |

The library was restored byte-identical after each (`git diff` empty).

**One defect in the harness's own first draft**, found by running it: the
suite sweep piped `--list` into `grep -q`, which closes the pipe on its first
match and kills the still-writing harness with SIGPIPE, so the pipeline's
status reported the harness's death rather than whether the listing was found.
Thirty harnesses were reported non-compliant when all forty were fine. The
sweep now captures the listing first and matches against the captured text —
HARNESS-DESIGN.md Trap 1 in a new guise: a harness never reads a status that is
not the one it means.

### Records updated

`CLAUDE.md` § Before running a command no longer says "`--scenario` or a
single-test selector" — the selector exists everywhere, so the checkpoint
states what it now guarantees. `.claude/rules/harnesses.md` names the library a
new harness must use. `tests/HARNESS-DESIGN.md` § The scenario selector points
at the harness that enforces it.


## The defect the conversion introduced, and what it changed

Gating a block where it stood, rather than lifting it into a function, has a
failure mode the full pass cannot see. A statement written *between* two
scenarios — a contract string, a fixture path, a shared `produced_by` — ends up
inside whichever block the gate happened to close after. Every scenario still
runs in a bare invocation, so the harness stays green; but selecting the later
scenario alone dies on an unbound variable, which is precisely the run this
issue exists to make trustworthy.

Two shapes, both found by running every registered scenario of every harness
alone:

**A statement swallowed into the preceding block.**
`validate-numeric-criteria-notices.sh` defined `INVERTED_RANGE_CONTRACT`
between two scenarios; the gate closed after it, so
`--scenario inverted-range-warnings` reported
`INVERTED_RANGE_CONTRACT: unbound variable` and asserted nothing. Fixed by
hoisting such statements out of the block. Same for `FAMILY_PRODUCED`
(`validate-category-names.sh`), `NARROW_WIDTH` (`validate-progress-line.sh`)
and `DURATION_SPREAD_FIXTURE` (`validate-statistics-demand.sh`).

**A scenario reading an artifact its neighbour produced.** Not a scoping
accident but a real dependency the selector exposes:
`validate-summary-contribution-bar.sh` § summary-bar-log compared its
logarithmic render against the linear render captured by the default-bar
scenario, and `validate-progress-line.sh` § disable-progress compared its
suppressed run against the multi-file scenario's painting run. Both now capture
what they compare against. A scenario that only passes when a neighbour ran
first is not selectable, and the harness contract now says a named scenario
runs.

**The harness gained the assertion that would have caught it.**
`tests/validate-scenario-selector.sh` § named-scenario-runs. The sweep as first
written asserted only the two refusals — that a harness says no to what it does
not know — and never that it says yes to what it does. Half a contract, and the
half that was missing is where the conversion broke.

Its first draft ran *one* scenario per harness, the first registered, and
passed against a deliberately reintroduced defect: the swallowed statement
belongs to one particular block, and `validate-category-names.sh` breaks in its
second scenario, not its first. Running every scenario instead does catch it —
and takes about ten minutes, because the suite registers **504** scenarios and
each is a live `ltl` run. That is a completion gate of its own, not an
assertion inside one.

The check is therefore split by instrument:

- **Statically**, a Perl pass over the gating reports any variable assigned
  inside one scenario block and read inside another — the defect's actual
  shape, found in milliseconds and named precisely
  (`validate-category-names.sh:$FAMILY_PRODUCED`).
- **Dynamically**, the first scenario of each harness is run, which proves the
  gating executes at all. One run per harness, not one per scenario.

Together, 62 seconds. Verified against the reintroduced defect: the static
check fails and names the harness and the variable; with the defect removed,
all three assertions pass. The dynamic half skips `validate-statistics.sh` and
`validate-csv-output.sh`, which drive the shared capture cache and would race
the gate's own runs of them.


**A third trap of the same family, in the new harness itself.** Each sweep
ended with `[[ -n "$list" ]] && echo "..."` to print the offending harnesses.
Where that was a function's last statement it became the function's return
value, which is 1 when the list is empty — the passing case. Under `set -e` the
dispatch loop then ended silently after `named-scenario-runs`, and the harness
exited 1 having printed only passes and no summary line. The guards are now
`if`/`fi`. Three defects in this issue's own work — the subshell handler, the
SIGPIPE read, this one — were all a status read from something other than what
the author meant to test, which is the rule HARNESS-DESIGN.md Trap 1 already
states.


## Completion gate

Run on 40c65ad, the commit being merged, with `$version_number` at `0.18.3`,
serially and with nothing else touching the repository.

- **The complete harness suite: 41 of 41 exit 0**, 2,807 assertions, no harness
  reporting zero. `CI=1 ./tests/validate-csv-output.sh` then
  `CI=1 ./tests/validate-statistics.sh` first, per the shared cache, then the
  rest. `validate-statistics.sh` reports 22 scenarios, 22 pass, 0 fail, with no
  T4 or T3 on any layer.
- **No Perl runtime warning** on any capture (` at <file> line <N>` absent from
  all 41).
- **Benchmark: skipped, recorded here.** The branch changes no executable line
  of `ltl`. Its only diff against the release branch was the `-545` version
  stamp, restored before the gate. `docs/process/workflow.md` § 3 makes the
  benchmark required for `ltl` changes and for harness changes it does not
  reach; the scope row that applies here is `tests/validate-*.sh` and
  `tests/lib/`, which requires the suite, not the benchmark.

An earlier run of the same gate reported `validate-statistics.sh` at 20 pass,
2 fail and `validate-aggregate-export.sh` one assertion short, both on
`csv_cache_produce rc=1` and a `mv: No such file or directory` into
`tests/.artifacts/`. A concurrent sweep of scenario selectors was running in
the same checkout and its harnesses cleaned up the shared cache mid-run. Both
harnesses pass in the clean gate. The gate is a serial instrument: nothing else
may touch the repository while it runs, and that includes another harness.

## Release notes

No bullet. `CLAUDE.md` § Before writing a file limits release-notes bullets to
user-observable change; this issue changes how harnesses accept arguments and
is invisible to anyone running `ltl`.
