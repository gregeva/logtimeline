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

## Contracts

`tests/HARNESS-DESIGN.md` § The scenario selector, first bullet, becomes:

- `--scenario NAME` runs that scenario and no other; given more than once, it
  runs each named scenario, in registration order, and no other.

`scenario_usage()` prints `Usage: <harness> [--scenario NAME]... [--list]`.

## Surfaces touched

Every reader of the selection, enumerated from the code:

| Reader | Where | Effect of the change |
|---|---|---|
| `scenario_wanted NAME` | the inline gates of 32 harnesses (e.g. `validate-classification-states.sh`) | true for each selected name |
| `scenario_selected` | the dispatch loop of 19 harnesses, and the scenario list three of them print in their summary | echoes every selected name, in registration order |
| `$SCENARIO_ONLY` read directly | `validate-statistics.sh`, the `--capture-baselines` confirmation's scope line | names every selected scenario |
| `scenario_usage` | every harness's `--list`, `--help`, and refusal diagnostic | the usage line shows the repeatable form |

## Acceptance criteria

All assertable. The library criteria are asserted in
`tests/validate-scenario-selector.sh` through its probe harnesses.

- [ ] AC1 — `--scenario alpha --scenario gamma` on a three-scenario probe runs
      alpha and gamma, and not beta. (D1)
- [ ] AC2 — `--scenario gamma --scenario alpha` runs alpha, then gamma. (D2)
- [ ] AC3 — `--scenario beta --scenario beta` runs beta once. (D3)
- [ ] AC4 — `--scenario alpha --scenario no-such-scenario` exits 2, names
      `no-such-scenario`, lists the scenarios, and runs none. (D4)
- [ ] AC5 — `--scenario=alpha --scenario gamma` mixes the two spellings. (D1)
- [ ] AC6 — An inline-gated probe whose second block reads a file the first
      block writes passes with both named, through `scenario_wanted`. (D1, the
      shape of the reported case)
- [ ] AC7 — The reported case: `validate-classification-states.sh --scenario
      producer/contained --scenario line-states/no-rows` runs those two
      scenarios and passes the 7 assertions of `line-states/no-rows`.
- [ ] AC8 — The existing selector scenarios (one name, bare run, unknown name,
      unknown flag, a harness's own flags, duplicate registration) pass
      unchanged; the suite-wide sweep still finds every harness refusing an
      unknown name and flag.
- [ ] AC9 — `validate-statistics.sh --capture-baselines` with two scenarios
      named states both in its scope line, and capturing nothing when the
      confirmation is declined. Verified by a run, not a harness scenario: the
      path writes released baselines when confirmed.

## Gate

No `ltl` change, so no benchmark. The change alters what every harness selects,
so the full suite runs as the completion gate (`docs/process/workflow.md` § 3).
