# A heatmap of a user-defined metric that has no timeline column (Issues #678 and #713)

## Status

**Delivered**, both issues closed: PR #716 merged into `release/0.19.0` as 78c0c8f on 2026-10-13, for #678 and #713 together. The record below is the work as it went.

**Gate passed, 2026-10-13** (on ec98119, branch `678-udm-heatmap-colour`). D1 to D4 are locked; the acceptance criteria are agreed and pass. The current state (§ 3) was read on
`release/0.19.0` at b736e7b. No code has changed.

- **Issues:** #678 (a heatmap of a user-defined time metric whose every value
  is zero ends the run) and #713 (a heatmap of a user-defined metric that
  captured no value ends the run), planned together on one branch and one PR
  that closes both (architect, 2026-10-13): one cause, one draw.
- **Parent:** #622 (the refactoring the redundant-logic audit dispatched); both
  are sub-issues.
- **Found during:** #617 (one width-to-format rule,
  `features/617-width-to-format-rule.md` § Delivery progress, findings from
  drop 1) for #678; #614 (operand settlement) for #713.

---

## 1. Requirement (issue bodies)

**#678.** `-hm` on a user-defined time metric whose every captured value is
zero stops the run while the heatmap header is drawn. *Done when:* a run whose
heatmap metric is all zeros completes without a runtime error.

**#713.** `-hm` on a user-defined metric that captures no value at all in the
run stops the run while the heatmap is drawn, exit status 255. *Done when:* a
run whose heatmap metric captured no value completes without a runtime error.

## 2. Locked decisions

- **D1 — A user-defined metric's colour is fixed by its position among the
  `-udm` specs, for its timeline column and its heatmap alike.** The colour no
  longer depends on whether any other user-defined metric captured data, and a
  heatmap has a colour whether or not its metric has a timeline column. This
  keeps the record's rule that a user-defined heatmap "uses color gradient
  matching the metric's bar graph column" (`features/user-defined-metrics.md`,
  heatmap support) and makes it hold when the column is absent. User-observable:
  in a run where an earlier user-defined metric captured nothing, a later
  metric's timeline column keeps its own colour instead of taking the empty
  one's. *Architect, 2026-10-13.*
- **D2 — The user-defined colours start where they start today.** The first
  user-defined slot stays `3`, plus one for each of the sessions and users
  columns when the run adds it, plus the number of thread-pool columns; D1
  fixes only the order from there. A run whose user-defined metrics all
  captured data keeps today's colours exactly, and a heatmap and its column
  read the same slot. The same `-udm` spec can still take a different colour
  on a log with sessions or users than on one without, as it does today.
  *Architect, 2026-10-13.*
- **D3 — A user-defined heatmap of a metric that captured no value renders
  as the built-in duration's does with no durations.** When nothing was
  captured (#713), the heatmap shows its header and footer at 0 in the
  metric's own unit, empty rows, in the colour D1 gives it, and the run
  exits 0. The built-in reference, on two application-log lines carrying no
  duration with `-hm duration`: header `0ms … heatmap [duration] … 0ms`,
  every row empty, footer ticks `0ms`. The column is not dropped. A metric
  whose every captured value is zero (#678) is not this case: values were
  found, and empty rows would be wrong for it. *Architect, 2026-10-13,
  corrected the same day to exclude the all-zero case.*
- **D4 — Drawing observed zeros is #715, not this work.** No heatmap
  receives a zero value (§ 3), so drawing them needs a position for zero on
  a logarithmic axis, for every metric and every run: filed as #715 (a heatmap
  leaves out observed zero values, and draws nothing when every value is
  equal). Here, an all-zero user-defined
  heatmap stops ending the run, takes its D1 colour, and otherwise renders
  as the built-in duration's all-zero heatmap does today, until #715 lands.
  *Architect, 2026-10-13.*

## 3. Current state (read 2026-10-13, `release/0.19.0` at b736e7b)

**Reproduction**, each run captured with `-V`:

| Input | Exit | `-V heatmap-palette` `color_name` |
|---|---|---|
| Two application-log lines in the ThingWorx shape carrying `elapsed=0`; `-ni -bs 1 -n 0 -udm 'elapsed:s:max' -hm elapsed` (#678) | 255, `Can't use an undefined value as an ARRAY reference` in `print_heatmap_row` | `-` |
| The same two lines carrying `elapsed=5` | 0 | `magenta` |
| `tests/fixtures/tomcat-access-single-sample-keys.txt`, which carries no `x`; `-bs 1440 -oe -udm x::max -hm x` (#713) | 255, the same error, after the `no metrics produced from matching lines` notice | — |
| The all-zero lines with `-hg elapsed` | 0 | — |
| The no-value fixture with `-hg x` | 0 | — |
| The `elapsed=0` lines (no durations) with `-hm duration` | 0 | `yellow` |

Both failing runs also print two `Use of uninitialized value $color_key`
warnings, one pair from `emit_heatmap_palette_verbose` under `-V` and one from
`print_heatmap_row`.

**The built-in duration does not draw observed zeros either.** On the first
two lines of `tests/fixtures/tomcat-access-single-sample-keys.txt`, whose
durations are both `0`, `-bs 1440 -n 0 -hm duration` exits 0 with the header
`0ms … heatmap [duration] … 0ms`, footer ticks `0ms` and the bucket's row
empty: two durations were observed and no cell shows them. The render is the
same as for a log carrying no duration at all.

**Why: no heatmap ever receives a zero.** The read loop's heatmap capture
keeps a value only when it is above zero, for every metric, before either
data model (raw or bin) sees it:

```perl
if (defined $heatmap_value && $heatmap_value > 0) {
    $heatmap_min = $heatmap_value if !defined $heatmap_min || $heatmap_value < $heatmap_min;
```

So every observed zero is left out of every heatmap, in a mixed run as in an
all-zero one, and the axis is logarithmic (`boundary[i] = min * (max/min)^(i/N)`
in `calculate_heatmap_buckets_exact`), which has no position for zero. An
all-zero metric therefore leaves `$heatmap_min` and `$heatmap_max` undefined,
exactly as a metric that captured nothing does.

**The cause.** In the layout pass, a user-defined metric's timeline column is
added only when its largest bucket total is above zero:

```perl
for my $config (@udm_configs) {
    my $key = "udm_$config->{name}";
    if (defined $max_total{$key} && $max_total{$key} > 0) {
        add_dynamic_column(\@column_layout, $key, $config->{name}, $udm_color_idx++,
```

An all-zero metric and a metric that captured nothing both fail the test, so
no column is added. The heatmap holds no colour of its own for a user-defined
metric; it copies the column's:

```perl
my ($col_entry) = grep { $_->{id} eq $udm_key } @column_layout;
if ($col_entry && $col_entry->{color}) {
    $heatmap_metric_map{$heatmap_metric}{color} = $col_entry->{color}{name};
```

With no column, `$heatmap_metric_map{...}{color}` stays undefined and
`print_heatmap_row` dereferences the gradient of an undefined entry. The
histogram takes its colours from the column the same way, but its readers fall
back when they are missing, so `-hg` survives both inputs. The built-in
duration's column is always in the layout, so its heatmap always has a colour.

**The colour slots.** `add_dynamic_column` takes
`$column_colors[$color_index % scalar(@column_colors)]`. The user-defined
metrics' first index is `3`, plus one when the sessions column is added, plus
one when the users column is added, plus the number of thread-pool columns;
`$udm_color_idx` then advances only for a metric whose column was added.

## Acceptance criteria

Agreed with the architect 2026-10-13. Every scenario named below is new in
`tests/validate-heatmap-palette.sh` and is shown to fail on the code before
the fix. All six are assertable.

- [x] **AC1 — An all-zero user-defined heatmap completes with its colour.**
      Two application-log lines carrying `elapsed=0`, `-udm 'elapsed:s:max'
      -hm elapsed`: exit 0, no ` at … line N` on stderr, and `-V
      heatmap-palette` names the same `color_name` as a control run on the
      same lines carrying `elapsed=5`. Nothing about the rendered rows is
      asserted: under D4 they render as #715 leaves them.
- [x] **AC2 — A heatmap of a metric that captured nothing completes with its
      colour.** `-udm x::max -hm x` on
      `tests/fixtures/tomcat-access-single-sample-keys.txt`, which carries no
      `x`: exit 0, no runtime warnings, a `color_name` named in `-V
      heatmap-palette`, and the zero-match notice exactly as
      `features/user-defined-metrics.md` D8 and D9 define it, once for the one
      spec.
- [x] **AC3 — The no-value heatmap renders as D3 says.** On the AC2 run, the
      header and footer read `0` in the metric's unit at both ends, and every
      heatmap cell on every row is empty. Checked on the rendered output, the
      heatmap column cut by the layout engine's offsets (`--debug-layout`,
      `timeline_cell_report`).
- [x] **AC4 — A user-defined column's colour does not depend on another
      metric's data (D1).** Two specs, the first capturing nothing and the
      second capturing data: the second's timeline column has the same fill
      colour as in a control run where both capture. Checked on the decoded
      column fill colour, the column cut by the layout offsets.
- [x] **AC5 — A heatmap and its column read one colour (D1).** `-hm` on the
      AC4 run's second metric: `-V heatmap-palette` names the colour of its
      timeline column.
- [x] **AC6 — Runs whose user-defined metrics all captured data keep their
      colours (D2).** With and without sessions and users, the rendered output
      is byte-identical before and after the change. Checked by a one-off
      reference capture on the base commit compared after the fix, not a
      harness scenario.

## Implementation record

Branch `678-udm-heatmap-colour`, version stamped `0.19.0-678` (3b8a5c7).

- **b9cd88c, e894195 — the scenarios, before the fix.** Four scenarios in
  `tests/validate-heatmap-palette.sh` (`udm-all-zero`, `udm-no-value`,
  `udm-colour-by-position`, `udm-heatmap-matches-column`), the fixture
  `tests/fixtures/udm-heatmap-colour.txt` (registered in `docs/test-logs.md`),
  and a `fill=` field on `timeline_cell_report` (the column's fill colour; the
  existing consumers read other fields and are unaffected). On the base:
  AC1 and AC2 exit 255 with runtime warnings and AC1 names no colour (`-`
  against the control's `magenta`); AC3's footer and row are never drawn;
  AC4 reads `256:127` against the control's `256:124`. Three checks pass on
  the base and were shown to fail otherwise: AC3's header and empty-row
  checks fail on a heatmap with data (`2ms … 898ms`, filled cells), and AC5
  fails when the capture's colour name is doctored to `blue` against a
  `256:124` column. The zero-match notice check passes on the base by
  design: the notice is unchanged (`features/user-defined-metrics.md` D8, D9).
- **42d30b5 — the fix.** `normalize_data_for_output()` resolves each
  user-defined metric's colour from its position among the `-udm` specs
  (D1), from the first slot D2 keeps, whether or not the metric gets a
  timeline column; `add_dynamic_column` and `%heatmap_metric_map` read it.
  The histogram's colours still come from the column. The no-value
  scenario's empty-row check was corrected to a blank, unfilled heatmap row
  (it had expected border marks), which is how the built-in duration renders
  with no durations. All four scenarios pass.
- **AC6.** Twelve runs, rendered output and `-V heatmap-palette` each (24
  files): three user-defined metrics that all capture data, on a fixture with
  and without sessions and users, with no heatmap, `-hm` on each metric, `-hg`
  on all three, and `-hm` with `-hg` together. Captured with the base `ltl`
  (deterministic over two runs once the timing and memory lines are left
  out) and compared after the fix: byte-identical.

## Completion gate (on ec98119, version `0.19.0`, this machine)

- **Full harness suite:** 49 of 49 exit 0, no ` at … line N` in any capture;
  `validate-heatmap-palette.sh` 95 passed, 0 failed.
- **Before/after benchmark,** `single-day-access-log-standard`, one run each,
  worktree beside worktree (before on the base f89b8e3, after on ec98119):
  total 6.8 s to 6.7 s (−1.3 %), peak memory 98.4 MB to 98.2 MB.
  `render/normalize_data`, the only stage holding changed code, reads 3 ms
  on both. Three millisecond stages read higher on the one run:
  `detect/registry_build` 22 to 24 ms, `finalize/calculate_statistics` 79 to
  82 ms and its `group_calc` 19 to 21 ms; none of them holds changed code.
