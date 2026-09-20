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
