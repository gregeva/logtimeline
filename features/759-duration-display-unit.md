# A duration's display unit is pegged to the unit it is read in (Issue #759)

## Status

**Specification in progress.** Work started 2026-10-29 on `release/0.20.0`;
the specification is written here on the release branch, and the issue branch
is cut from it when implementation starts. Phase 1 (the requirement, § 1 and
§ 2) is confirmed by the architect; phase 2 (the surfaces, § 3) is written;
phases 3 to 7 follow, each brought to the architect before the next.

| Phase | What it produces |
|---|---|
| 1. Requirement | the motivating consumer, the requirement and the reproduction (§ 1, § 2) |
| 2. Surface inventory and contracts | every place a duration is rendered or its precision is stated, each with the record line behind its current contract, for the architect to confirm |
| 3. Record reconciliation | each related record read or dismissed with its reason; each locked decision the reversal touches marked as standing, amended or falling |
| 4. Design questions | asked one at a time |
| 5. Prototype decision | settled by how the precision of what is read is detected |
| 6. Acceptance criteria | derived from the requirement, validated on every surface of phase 2 |
| 7. Delivery plan | the drops, the user-facing changes and the records to update at delivery |

Every run quoted in this document was captured on 2026-10-29 with
`--disable-progress`, against `ltl` as on `release/0.20.0` at 04cfa8a1 and as
tagged `v0.19.0`.

---

## 1. The motivating consumer

**The analyst reading a log whose durations are recorded in seconds.** A web
application access log can carry execution time in seconds with three
decimals, read with `-du s`. Those durations carry millisecond precision, yet
every surface shows them pegged to seconds: requests of 6, 8 and 10 ms all read
`0s` in the messages table, a P50 of 30 ms reads `0s` in the percentile legend,
and the heatmap axis opens `0s 0s`. Read from the same requests recorded in
milliseconds, the same surfaces separate them.

**The analyst reading a notice.** A duration bound given in milliseconds on
that log is reported as finer than the log's durations, "which are recorded in
seconds". The log carries millisecond precision and the bound is applied at it;
the notice tells the analyst the opposite.

---

## 2. Requirement

From the issue body and the architect's explanations of 2026-10-29, organised
in this document's words. The examples illustrate the aim; they are not the
specification.

**The defect.** The unit a duration is displayed in is pegged to the unit it is
read in. The two have no relationship: what is seen on screen and the unit of
measure a value is recorded in are decorrelated. The rendering already adapts
the unit to the value it shows; the pegging is what overrides it. Read in
seconds, 0.01 s is 10 ms, yet it renders `0s`.

**Where the source unit and the precision matter.** In only a couple of places:

- **A zero** carries no magnitude for the rendering to adapt to, so the unit
  that follows it reflects the data: the duration unit the format registry (or
  `-du`) gives, together with the precision detected in what is read. For
  example, an nginx access log storing durations in seconds with three
  decimals carries millisecond precision, so its zero is expressed in
  milliseconds rather than seconds.
- **A unit the data's precision cannot reach is never rendered**, since
  choosing it implies a precision the data does not have. For example,
  durations in seconds with three decimals carry millisecond precision, so
  nothing below a millisecond is rendered.

**The finer-bound notice.** It states a precision the log does not carry,
naming the stated unit as the unit the durations are recorded in. It is
corrected to fit the same position.

**Why the current behaviour exists.** #617 (one width-to-format rule) locked
D16: "a value is never rendered in a unit smaller than its stated unit". It was
asked for because files were rendering `0 microseconds` or `0 nanoseconds`
where that precision did not exist. Its scope was misunderstood, and the stated
unit was made the floor of the display. The architect reversed D16 on
2026-10-29, and his account of the zero amends D4 (a real zero renders in the
source's resolved unit) (`features/617-width-to-format-rule.md` § 4). Both points above are
cross-checked against the other precision decisions and requirements in
phase 3.

**Not in scope.** How values are rendered: the rendering already adapts the
unit to the value. The defect is the pegging that overrides it, and the notice.

**Done when** (the issue body): a duration's display unit is no longer pegged
to the unit it is read in, and no notice states a precision the log does not
carry.

### Reproduction

The committed fixture `tests/fixtures/tomcat-access-duration-spread.txt`
(integer milliseconds), and a copy holding the same durations in seconds with
three decimals:

```bash
awk '{ $NF = sprintf("%.3f", $NF/1000); print }' tests/fixtures/tomcat-access-duration-spread.txt > spread-seconds.txt
./ltl --disable-progress -hg -hm -n 20 tests/fixtures/tomcat-access-duration-spread.txt
./ltl --disable-progress -du s -hg -hm -n 20 spread-seconds.txt
./ltl --disable-progress -dmin 50ms -n 3 tests/fixtures/tomcat-access-duration-spread.txt
./ltl --disable-progress -du s -dmin 50ms -n 3 spread-seconds.txt
```

| Surface | Read in milliseconds | Same values in seconds, `-du s` |
|---|---|---|
| Percentile legend | `P50: 30ms  P75: 451ms` | `P50: 0s  P75: 0.5s` |
| Heatmap x-axis | `1ms 7ms 63ms 538ms 5.5s` | `0s 0s 0.1s 0.5s 5.5s` |
| Messages table Min / P50 / P99.9 | `6ms 8ms 10ms`; `58ms 60ms 166ms` | `0s 0s 0s`; `0.1s 0.1s 0.2s` |
| Messages table Duration | `24 msec` | `0.02 seconds` |
| `-dmin 50ms` notice | none | `-dmin 50ms is finer than the log's durations, which are recorded in seconds` |

The same in `v0.19.0` and on `release/0.20.0`; `v0.19.0` prints the notice as
a plain `Note:` line. The notice is #605's D22 (a duration bound finer than the
log records gets a note; `features/605-input-units.md` § 4).

The architect's observation, on a web application access log carrying
execution time in seconds with three decimals, read with
`-r -du s -st 2026-10-25 -hg -so duration -n 20 -hm -hgh 12 -i <one service path>`:
the percentile legends, the heatmap and histogram x-axis values (opening
`0s`), and the messages table (Min `0s`).

---

## 3. Surfaces and their current contracts

Every place a duration is rendered, or its unit or precision is stated, found
from the code: the callers of the display dispatch (`value_text()`, 70 call
sites, and `value_column()`, 3; 18 and 2 of them render a duration under the
floor, 11 render the tool's own timings with none, § 3.4), the readers of
`$duration_unit_resolved`, and the readers of `-du`. Each row names the
record line that sets its current contract and what the reproduction's two
inputs showed (§ 2, read in milliseconds → the same values in seconds under
`-du s`); *code path* marks a row no capture reached.

```
-du <unit> ──▶ adapt_to_command_line_options()
                 $duration_unit_resolved = -du, else 'ms'
                   │
                   ├──▶ resolve_value_kind()   floor => $duration_unit_resolved // 'ms'
                   │      │                    (a user-defined metric: floor => its declared unit)
                   │      └──▶ value_text() / value_column() ──▶ duration arm
                   │             format_time( floor => $floor, resolution => $floor )      § 3.1
                   ├──▶ %csv_family_decimals   duration and percentile decimals            § 3.2
                   └──▶ -V csv-output, YAML provenance: duration_unit_resolved             § 3.3
-du, else each file's format duration_unit ──▶ note_finer_duration_bounds()                § 3.2
read path: convert_duration_to_ms() at the include point; every value is held in ms       § 3.5
```

### 3.1 Durations rendered through the dispatch: the floor at the unit read in

| Surface | Sub | Budget row | Record behind the current contract | Observed |
|---|---|---|---|---|
| Timeline P50, P95, P99, P99.9 | `print_bar_graph` | latency cell | `features/617-width-to-format-rule.md` § 5 *The budget table*, latency cell (D9): "as today: `P50:99ms`, `P50:500ns` under `-du ns`"; the floor from D16 | `P50:58ms` → `P50:0.1s`; a zero `P50:0ms` → `P50:0s` |
| Timeline duration column | `print_bar_graph` (`value_column`) | timeline column | 617 D10 (tier and fit resolved once per timeline column); the floor from D16 | `58 milliseconds` → `0.06 seconds`; a zero `0 milliseconds` → `0 seconds` |
| Messages table Min, P50, P99.9 | `print_message_summary` | latency cell | 617 § 5 *The budget table*, latency cell | `6ms 8ms 10ms` → `0s 0s 0s` |
| Messages table Duration | `print_message_summary` (`value_column`) | messages total | 617 D18 (the messages-table total is walked by its own column width) | `24 msec` → `0.02 seconds` |
| Heatmap header and footer scale | `get_heatmap_column_header`, `print_heatmap_footer_scale` | chart label | 617 § 5 *The budget table*, chart label: "the floor (D16) and the zero rule (D4)" | header `1ms … 5.5s` → `0s … 5.5s`; footer `1ms 7ms 63ms 538ms 5.5s` → `0s 0s 0.1s 0.5s 5.5s` |
| Histogram x-axis labels, percentile selection and legend | `calculate_histogram_x_labels`, `select_histogram_percentiles`, `render_histogram_legend` | chart label | as the heatmap | axis `1ms 3ms 12ms 40ms 137ms 467ms 1.6s 5.5s` → `0s 0s 0s 0s 0.1s 0.5s 1.6s 5.5s`; legend `P50: 30ms` → `P50: 0s` |
| `-V` display-dimensions lines (`histogram-array`, `histogram-bin-counters`) | `format_histogram_dimensions_line` | dimensions line | 617 § 5 *The budget table*, dimensions line; § 5 *The floor and the zero rule (D4, D16)* names these lines | `min=1ms` → `min=0s` |
| CSV `duration_nice` (STATS, MESSAGES) | `build_stats_csv_columns`, `build_messages_csv_columns` | nice cell | 617 § 5 *The budget table*, nice cell (D18: the CSV keeps a fixed budget) | MESSAGES `24 msec`, `7 msec`, `286 msec` → `0 sec`, `0 sec`, `0.3 sec` |
| A user-defined time metric on the timeline, heatmap and histogram surfaces | the same subs, the metric named | as the surface | 617 D16: "a user-defined metric's declared unit, is the floor of the ladder for every rendering, zero included; a user-defined time metric's zero renders in its own declared unit (`0s` for a seconds metric)" | code path |
| A user-defined byte metric on the same surfaces | the same subs | as the surface | 617 D16, the same sentence: the declared unit is the floor for any user-defined metric | code path |

### 3.2 Precision stated outside the dispatch

| Surface | Sub | Record behind the current contract | Observed |
|---|---|---|---|
| The finer-bound notice | `note_finer_duration_bounds` | `features/605-input-units.md` § 4 D22: "When a duration bound is given in a unit finer than the unit the log's durations are recorded in, a behavioural note says so"; 605 § 5: "The unit the log's durations are recorded in is the one already declared: `-du` when given, otherwise the `duration_unit` of each file's detected format" | `-dmin 50ms`: none → `-dmin 50ms is finer than the log's durations, which are recorded in seconds` |
| CSV duration and percentile decimals, and `-V csv-output` `decimals_duration`, `decimals_percentile` | `adapt_to_command_line_options` (`%csv_family_decimals`) | `features/608-byte-unit-ladder.md` D18 (the ladder step's decimals field is the rounding precision relative to the millisecond storage unit: `ns` 6, `us` 3, `ms` and every longer token 0) and its table row *CSV decimals*: "the duration and percentile families read the step's decimals" | `0` → `0`: seconds and milliseconds share the step's 0 |

### 3.3 The unit read in, stated as such

These name the unit a value is read in, which is what they report; they state
neither a display unit nor a precision.

| Surface | Sub | Record | Observed |
|---|---|---|---|
| `-V csv-output` `duration_unit_resolved` | the `csv-output` emitter | 617 § *Verification surface* reads it as the expected floor (AC2, AC8, AC9, AC11) | `ms (default)` → `s (-du s)` |
| YAML export `duration_unit_resolved`, `duration_unit_source` | `write_aggregate_export` | `features/503-yaml-aggregate-export.md` F14: "`duration_unit_resolved` names the source unit"; D20: "the duration unit is stated once in provenance" | `ms`, `default` → `s`, `-du s` |
| The notice that a format's producers differ in their duration unit ("assumed ms"), and the notice that `-du` is not applied to a format whose lines name their own unit | `format_variant_ambiguity_note` | none found | code path |

### 3.4 Durations rendered with no floor

The tool's own timings and the population span: the summary stage timings and
total time, and the YAML export's population duration and total time. They
pass a kind and no metric, so `resolve_value_kind()` gives them no floor (617
§ 5 *The budget table*, summary timing and export duration: "no floor"). The
export's population duration read `14.4 hours` on both inputs.

### 3.5 Not a surface: where the values are read

`read_and_process_logs()` converts each duration to milliseconds at the
include point (503 F14); once held, a value no longer shows how many decimals
it was written with. The read is where the precision of what is read is
visible. The detection sample (`sample_file_for_detection()`) already records,
per format, the most fractional digits among its sampled timestamps
(`frac_digits`, read by `resolve_timestamp_precision()`); nothing records them
for durations.
