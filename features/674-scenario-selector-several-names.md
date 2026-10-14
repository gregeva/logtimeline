# #674 — The scenario selector accepts several scenarios

Issue #674 (validate-classification-states.sh scenario line-states/no-rows fails
when selected alone), under umbrella #729 (process, tests and build). Owning
records for the surface: `tests/HARNESS-DESIGN.md` § The scenario selector (the
contract every harness honours), `features/545-harness-scenario-selector.md`
(the library and its sweep). The harness in the reported case is owned by
`features/453-success-failure-classification-event-ledger.md`; the defect was
first recorded in `features/655-apache-mod-jk-connector-format.md` § Found on the
way, not changed here.

## What this is for

Whoever iterates on a harness — the architect or Claude — runs exactly the
scenarios the change in hand needs, and no more. Some scenarios read a capture
another scenario writes; running such a scenario means running its producer too.
Today the selector takes one name, so the only way to run the pair is the whole
harness, which is the run the selector exists to avoid.

## Requirement

From the architect (2026-10-14): the scenario selector accepts several scenarios.
The purpose of the selector rule, in his words: it exists "to ensure that you
DON'T just execute the entire harness. You are allowed to run multiple tests /
scenarios, etc. - no issue. You cannot however lean on ALL TESTS as you then waste
our time and don't exercise the required reflection on what needs to be tested
and how that gets tested."

And (2026-10-14): the harness design documentation and the process guidance
ensure the pattern is applied across all harnesses.

## Findings

Measured on release/0.20.0 (`a519409`).

- `line-states/no-rows` runs no `ltl` of its own. It reads `$TMP_DIR/pinned.out`,
  which only `producer/contained` writes (the 16-line fixture pinned with `-lf`,
  `-n 0`). Selected alone, the file does not exist and its 7 lookups fail
  (0 of 7); the whole harness passes 56 of 56.
- Two separate invocations cannot share the capture: each harness run makes its
  own `mktemp -d` and removes it on exit.
- `scenario_parse_args()` in `tests/lib/scenario-select.sh` keeps one name in
  `SCENARIO_ONLY`; a second `--scenario` overwrites the first, silently. Asked
  for two, a harness runs the last one and says nothing.

- `validate-filter-summary.sh` kept its own selection beside the library's: it
  read `--scenario` into `ONLY_SCENARIO` itself, ran its first eight scenarios
  before calling `scenario_parse_args`, and registered only four of its fourteen.
  Measured: `--list` ran 60 assertions before listing; `--scenario unmatched`
  ran 9 assertions and was then refused as an unknown scenario. `highlight` and
  `combined-causes` sat inside the `csv-unparseable-row` block, so they ran only
  when that scenario did. The suite-wide sweep did not see it: it read exit codes
  and the listing header, not whether anything ran first.
- `validate-statistics.sh` read the library's `SCENARIO_ONLY` directly for the
  scope line of its `--capture-baselines` confirmation.

The statement in `features/545-harness-scenario-selector.md` that "a scenario that
only passes when a neighbour ran first is not selectable" is superseded by the
requirement above: such a scenario is selected together with its producer.

## Decisions

- **D1 — `--scenario` is repeatable** (architect, 2026-10-14). Each name given
  runs; nothing else does.
- **D2 — Selected scenarios run in registration order**, whatever order they
  were named in. A harness that gates blocks inline can only run them in file
  order, so registration order is the one order every harness can honour; it is
  also the order in which a producer precedes its consumer.
- **D3 — A name given twice runs once.**
- **D4 — One unknown name refuses the whole selection**: diagnostic naming it,
  the scenario list, exit 2, no scenario run — the existing refusal, applied to
  each name.
- **D5 — The selection has one owner** (from the architect's direction that the
  pattern hold across all harnesses). A harness reads it only through
  `scenario_wanted`, `scenario_selected` and `scenario_restricted`, never parses
  `--scenario` itself, and calls `scenario_parse_args` before its first scenario
  runs. `validate-filter-summary.sh` is converted: all fourteen scenarios
  registered in file order, one gate each.
- **D6 — Iteration names the scenarios the change needs, never the whole
  harness**, recorded where the direction is read: `tests/HARNESS-DESIGN.md`
  § The scenario selector (Running what the change needs), `CLAUDE.md` § Before
  running a command, `.claude/rules/harnesses.md`.

## Contracts

`tests/HARNESS-DESIGN.md` § The scenario selector, first bullet, becomes:

- `--scenario NAME` runs that scenario and no other; given more than once, it
  runs each named scenario, in registration order, and no other.

`scenario_usage()` prints `Usage: <harness> [--scenario NAME]... [--list]`.
The same section gains the one-owner rule (D5) and *Running what the change
needs* (D6); its closing paragraph lists the sweep's added checks.

## Surfaces touched

Every reader of the selection, enumerated from the code:

| Reader | Where | Effect of the change |
|---|---|---|
| `scenario_wanted NAME` | the inline gates of 32 harnesses (e.g. `validate-classification-states.sh`) | true for each selected name |
| `scenario_selected` | the dispatch loop of 19 harnesses, and the scenario list three of them print in their summary | echoes every selected name, in registration order |
| `$SCENARIO_ONLY` read directly | `validate-statistics.sh`, the `--capture-baselines` confirmation's scope line | reads `scenario_restricted` and `scenario_selected`; names every selected scenario |
| its own `ONLY_SCENARIO` | `validate-filter-summary.sh` | removed; the library's gates only (D5) |
| `scenario_usage` | every harness's `--list`, `--help`, and refusal diagnostic | the usage line shows the repeatable form |

## Acceptance criteria

All assertable. The library criteria are asserted in
`tests/validate-scenario-selector.sh` through its probe harnesses.

- [x] AC1 — `--scenario alpha --scenario gamma` on a three-scenario probe runs
      alpha and gamma, and not beta. (D1)
- [x] AC2 — `--scenario gamma --scenario alpha` runs alpha, then gamma. (D2)
- [x] AC3 — `--scenario beta --scenario beta` runs beta once. (D3)
- [x] AC4 — `--scenario alpha --scenario no-such-scenario` exits 2, names
      `no-such-scenario`, lists the scenarios, and runs none. (D4)
- [x] AC5 — `--scenario=alpha --scenario gamma` mixes the two spellings. (D1)
- [x] AC6 — An inline-gated probe whose second block reads a file the first
      block writes passes with both named, through `scenario_wanted`. (D1, the
      shape of the reported case)
- [x] AC7 — The reported case: `validate-classification-states.sh --scenario
      producer/contained --scenario line-states/no-rows` runs those two
      scenarios and passes the 7 assertions of `line-states/no-rows`.
- [x] AC8 — The existing selector scenarios (one name, bare run, unknown name,
      unknown flag, a harness's own flags, duplicate registration) pass
      unchanged; the suite-wide sweep still finds every harness refusing an
      unknown name and flag.
- [x] AC9 — `validate-statistics.sh --capture-baselines` with two scenarios
      named states both in its scope line, and capturing nothing when the
      confirmation is declined. Verified by a run, not a harness scenario: the
      path writes released baselines when confirmed.
- [x] AC10 — Every harness refuses an unknown name given beside a known one, in
      both orders (suite-wide sweep). (D1, D4)
- [x] AC11 — No harness reports an assertion on a refusal or a `--list`
      (suite-wide sweep), shown to fail on `validate-filter-summary.sh` as it
      was. (D5)
- [x] AC12 — No harness parses `--scenario` or reads the library's variables
      (static check), shown to fail on `validate-filter-summary.sh` as it was. (D5)
- [x] AC13 — `validate-filter-summary.sh` converted reports the same 146
      assertion lines as before on a bare run, and runs exactly the named
      scenarios under selection. (D5)

## Gate

No `ltl` change, so no benchmark. The change alters what every harness selects,
so the full suite runs as the completion gate (`docs/process/workflow.md` § 3).

## Implementation

- **Library** (`tests/lib/scenario-select.sh`): `SCENARIO_SELECTED` holds every
  name given; `scenario_selected` walks the registry and echoes the selected
  names in its order; `scenario_wanted` tests membership; `scenario_restricted`
  is new. Each name is checked against the registry before anything runs.
- **Probe run, before any assertion was written**: two names, reversed order,
  a repeat, the `=` spelling, an unknown among known, one name, a bare run and
  an empty `--scenario` each behaved as D1–D4 state.
- **The reported case**: `validate-classification-states.sh --scenario
  producer/contained --scenario line-states/no-rows` passes 11 of 11 (4 and 7).
- **`validate-filter-summary.sh`**: bare run 146 of 146 before and after, the
  same assertion lines; `--list` runs nothing and lists 14 scenarios; an unknown
  name runs nothing; `--scenario highlight` runs its 8 assertions only.
- **`validate-statistics.sh --capture-baselines`** with two names, declined:
  "scenarios apache-default apache-consolidated only", "Aborted. No baselines
  were modified", tree unchanged.
- **`validate-scenario-selector.sh`**: new scenarios `selects-several`,
  `inline-gated-pair`, `no-harness-parses-the-selector`; the suite-wide sweep
  gains the unknown-beside-known check in both orders and the no-assertion check
  on a refusal and a listing. 36 of 36 over the ten scenarios this change
  touches; the sweep covers 49 harnesses.
- **Sabotage proof**: over a test tree holding the pre-change
  `validate-filter-summary.sh`, the static check names it, and the sweep names
  it for the unknown-flag run and for `--list`. The static check first passed
  against it: `grep | grep -q` under `pipefail` read the first grep's SIGPIPE as
  no match (`tests/HARNESS-DESIGN.md` Trap 1). It now captures before matching,
  and the sweep's new checks read their whole input.
- **Guidance**: `tests/HARNESS-DESIGN.md` § The scenario selector, `CLAUDE.md`
  § Before running a command and its test block, `.claude/rules/harnesses.md`,
  and the usage comment of 17 harnesses.
