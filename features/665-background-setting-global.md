# The background setting is global, not the heatmap's (Issue #665)

## Status

**Implemented, 2026-10-13** (branch `665-dark-background-override`, off
`release/0.19.0` at f98a9c9). The contracts in § 2 were confirmed by the
architect on 2026-10-13 and are the acceptance criteria, applied to every run;
all six pass. The completion gate has not run.

- **Issue:** #665 (`-dbg` does not override `-lbg` unless a heatmap is
  requested).
- **Parent:** #622 (the refactoring the redundant-logic audit dispatched).
- **Found during:** #653 (make a highlighted histogram's percentile row
  readable on a light background), `features/653-histogram-highlight-row-light-background.md`
  § Pre-existing, outside this issue.

---

## 1. Requirement

`-lbg` / `--light-background` and `-dbg` / `--dark-background` are one global
style setting: the background the output is drawn for. They "change no part of
`ltl`'s operation, only its colours" (`features/598-screenshot-capture.md` D7,
D17). The setting was born with the heatmap and is still resolved inside the
heatmap's option block, so its documented precedence holds only when `-hm` is
given. The heatmap-specific code is taken out, and the setting is resolved once
for the run whatever other options are given (architect, 2026-10-13).

## 2. Contracts (confirmed by the architect, 2026-10-13)

| Surface | Contract | Record |
|---|---|---|
| `-dbg` over `-lbg` | `-dbg` wins whenever both are given, in either order | `--help`: "Force dark-background color gradients (disables auto-detect; wins over -lbg if both given)"; `docs/usage.md`: "overrides `-lbg` and disables auto-detect" and "forces the dark gradients and overrides `-lbg` if both are passed" |
| Terminal auto-detection | The terminal is queried only when something will read the result (today the heatmap gradient alone) and neither `-lbg` nor `-dbg` was given | `features/heatmap.md`: "Auto-detection runs only when heatmap is enabled and `-lbg` wasn't explicitly set"; the scope locked on #665: the query "runs only when something will read the result" |
| `-V heatmap-palette` | Always emitted when requested; with or without `-hm` it reports `light_bg` and `light_bg_source`, whose four values rank `-dbg` > `-lbg` > `auto-detect` > `default` | `emit_heatmap_palette_verbose()` header comment; the `light_bg_source` assertion of `tests/validate-heatmap-palette.sh` |
| Flag resolution | Option-shaped behaviour is reduced at option settlement to a flag resolved once, independent of other options | `docs/architecture-patterns.md` § Run-scoped activation flags resolved once |
| Command echo | `-lbg` and `-dbg` stand in for the terminal and are left out of the echoed command (unchanged here) | `%options_standing_in_for_terminal`; `features/598-screenshot-capture.md` D17 |

## 3. Current state (read 2026-10-13, `release/0.19.0` at f98a9c9)

**Reproduction** on `tests/fixtures/http-status-families.txt`, `-bs 1440 -oe
-n 1`, each run captured with `-V`:

| Options | `light_bg` | `light_bg_source` |
|---|---|---|
| `-lbg -dbg -hg duration -h /store/orders` (either order) | yes | `-lbg` |
| `-lbg -dbg -hm duration` (either order) | no | `-dbg` |
| `-dbg -hg duration -h /store/orders` | no | `default` |
| `-dbg -hm duration` | no | `-dbg` |
| no background option, `-hm duration` | no | `auto-detect` |
| no background option, `-udm 'meth::distinct:/"(GET\|POST)/' -hm meth` | no | `auto-detect`, with `heatmap_active: no` |

The last row: a heatmap over a counting user-defined metric is switched off
after the terminal has been queried, so the query runs for a heatmap that is
never drawn.

**The cause.** The option callbacks record `-lbg` as the setting and `-dbg`
only as a flag; the `-dbg` precedence and the auto-detection both sit inside
the `-hm` block of `adapt_to_command_line_options()`:

```perl
if (defined $heatmap_metric) {
    $heatmap_enabled = 1;
    ...
    if ($heatmap_dark_bg_explicit) {
        $heatmap_light_bg = 0;
```

**Readers of the setting** (grep of `ltl`): `print_heatmap_row()` chooses the
dark or light gradient; `emit_heatmap_palette_verbose()` reports it. Since
#653 the histogram's highlighted percentile row is black on every background
and no longer reads it. The issue body's symptom (that row drawn in the
light-background text colour) is therefore stale: the defect is visible today
in `-V heatmap-palette`, and in any reader added outside the heatmap, such as
the light-background highlight palette `features/histogram-charts.md` defers
until after #665.

## 4. Design

- The setting takes global names (`$light_background`,
  `$light_background_source`); the option callbacks record only which of
  `-lbg` and `-dbg` was given.
- One settlement in `adapt_to_command_line_options()`, outside any feature's
  block: `-dbg` given → dark, source `-dbg`; else `-lbg` → light, source
  `-lbg`; else dark, source `default`.
- The terminal query is a demand gate (`docs/architecture-patterns.md`
  § Demand gates): it runs when neither option was given and a reader of the
  setting is active, decided after the heatmap's on/off is final (after a
  counting user-defined metric switches it off). Today the heatmap is the one
  reader.
- `-V heatmap-palette` keeps its keys and values; only what it reports
  changes, to the contract of § 2.

## Acceptance criteria

Derived from § 2, applied to every run. All six are assertable. Each new
scenario is in `tests/validate-heatmap-palette.sh` and is shown to fail on the
base where the base breaks the contract.

- [x] **AC1 — `-dbg` wins without a heatmap, in either order.** `-lbg -dbg`
      and `-dbg -lbg`, no `-hm`: `light_bg: no`, `light_bg_source: -dbg`.
      Scenarios `no-heatmap-lbg-then-dbg`, `no-heatmap-dbg-then-lbg`.
- [x] **AC2 — `-dbg` alone is reported without a heatmap.** `-dbg`, no `-hm`:
      `light_bg_source: -dbg`. Scenario `no-heatmap-dbg`.
- [x] **AC3 — `-lbg` alone holds without a heatmap.** `-lbg`, no `-hm`:
      `light_bg: yes`, `light_bg_source: -lbg`. Scenario `no-heatmap-lbg`
      (passes on the base; guards the move).
- [x] **AC4 — No terminal query for a heatmap that is not drawn.** No
      background option, `-hm` on a counting user-defined metric:
      `heatmap_active: no`, `light_bg_source: default`. Scenario
      `no-query-heatmap-off`.
- [x] **AC5 — Heatmap runs keep their contract.** The existing `dbg-*`,
      `lbg-*` and `precedence-*` scenarios pass unchanged; with `-hm` and no
      option, `light_bg_source: auto-detect`.
- [x] **AC6 — Nothing rendered changes.** Every run of § 3's reproduction,
      captured before and after, is identical outside `-V heatmap-palette`
      and the timings. The readers are the two in § 3; both are covered.
      One-off comparison, not a harness scenario.

## Implementation record

- **The scenarios, before the fix.** Five scenarios in
  `tests/validate-heatmap-palette.sh` (`no-heatmap-lbg-then-dbg`,
  `no-heatmap-dbg-then-lbg`, `no-heatmap-dbg`, `no-heatmap-lbg`,
  `no-query-heatmap-off`), run on the base: AC1's two fail on `light_bg: no`
  and `light_bg_source: -dbg` (the base reports `yes` and `-lbg`), AC2's fails
  on `light_bg_source: -dbg` (base `default`), AC4's fails on
  `light_bg_source: default` (base `auto-detect`); AC3's passes, as it guards
  behaviour the base already has.
- **The fix.** The option callbacks record only which of `-lbg` and `-dbg` was
  given (`$light_background_given`, `$dark_background_given`). One block in
  `adapt_to_command_line_options()`, ahead of and outside the heatmap's,
  settles `$light_background` and `$light_background_source`; the heatmap
  block holds no background code. The terminal query runs after the
  user-defined heatmap binding, where a counting metric switches the heatmap
  off, when the source is still `default` and the heatmap is on.
  `print_heatmap_row()` and `emit_heatmap_palette_verbose()` read the global
  names; the `-V heatmap-palette` keys and values are unchanged.
- **AC5.** The whole harness passes, 120 assertions.
- **AC6.** The § 3 runs, captured before and after with `-V`: the `-hm` runs
  are identical outside the total time and memory lines; the `-hg` runs differ
  in `light_bg` and `light_bg_source` as the contract requires, and in the
  timeline row, which is one of the two forms the base itself produces
  (below).

### Finding outside this issue

**The timeline row's status bar splits a tie differently from run to run.** On
`tests/fixtures/http-status-families.txt` with `-hg duration -h /store/orders
-bs 1440 -oe -n 1`, the base code (`release/0.19.0` at f98a9c9) run six times
on the same input renders the bucket's row two ways, three runs each: the 3xx
segment three blocks and the 1xx segment four, or the reverse. The two families
carry two lines each. Every before and after capture of § 3 shows one of the
two forms. Filed as #717 (the timeline's category bar splits a tie between two
categories differently from run to run).
