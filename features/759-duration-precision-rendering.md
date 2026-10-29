# Under -du s, a duration's millisecond precision is not rendered (Issue #759)

## Status

**Specification in progress.** Work started 2026-10-29 on `release/0.20.0`;
the specification is written here on the release branch, and the issue branch,
`759-duration-precision-rendering`, is cut from it when implementation starts. Phases 1 and 2 (the requirement
and the surfaces, § 1 to § 3) are confirmed by the architect; phase 3 (the
records, § 4) is written, with D1 locked; phase 4 (the design questions, § 5)
is settled, D2 to D5 locked; phase 5 (§ 6) needs no prototype; phase 6 (the
acceptance criteria) is confirmed; phase 7 (the delivery plan, § 7) is
proposed for the architect's confirmation.

| Phase | What it produces |
|---|---|
| 1. Requirement | the motivating consumer, the requirement and the reproduction (§ 1, § 2) |
| 2. Surface inventory and contracts | every place a duration is rendered or its precision is stated, each with the record line behind its current contract, for the architect to confirm |
| 3. Record reconciliation | each related record read or dismissed with its reason; each locked decision the reversal touches marked as standing, amended or falling |
| 4. Design questions | asked one at a time |
| 5. Prototype decision | settled by how the precision the raw data carries is detected |
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
every surface renders them in seconds: requests of 6, 8 and 10 ms all read
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

**The defect.** Under `-du s`, a duration's millisecond precision is not
rendered. An nginx access log storing durations in seconds with three decimals
is read with `-du s`; the three decimals are the millisecond precision of the
seconds unit, so 0.123 should render as 123 ms and 0.010 as 10 ms. The tool
renders 0.010 as `0s`.

**Reading and rendering are separate.** Reading gives a value its unit, so it
converts to any other unit, and its precision, and stores it in the standard
raw data model. Rendering formats from that model into a unit relevant to the
user that fits the interface: a large value read in milliseconds renders in a
larger time unit. The rendered unit is not the unit read in.

**Where the raw data's unit and precision matter.** In only a couple of places,
and always combined, so that what is displayed is relevant to the raw data:

- **A zero** carries no magnitude for the rendering to adapt to, so the unit
  that follows it is the raw data's unit (from the format registry, or `-du`)
  combined with the precision the raw data carries. For example, an nginx
  access log storing durations in seconds with three decimals carries
  millisecond precision, so its zero is expressed in milliseconds rather than
  seconds.
- **A unit the raw data's precision cannot reach is never rendered**, since
  choosing it implies a precision the data does not have. For example,
  durations in seconds with three decimals carry millisecond precision, so
  nothing below a millisecond is rendered.

**The finer-bound notice.** It states a precision the raw data does not carry,
naming the stated unit as the unit the durations are recorded in. It is
corrected to the same position: it never states a precision the raw data does
not carry.

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
unit to each value's magnitude. The defect is that the precision a duration
carries is not rendered under `-du s`, and the notice. Widened by D4 (§ 5):
the timestamp precision reads a part-group of fractional digits by the same
rule as a duration's decimals.

**Done when** (the issue body): under `-du s`, a duration's millisecond
precision is rendered (0.010 s reads `10ms`, 0.123 s reads `123ms`), and no
notice states a precision the raw data does not carry.

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
| The notice that a format's producers differ in their duration unit ("assumed ms"), and the notice that `-du` is not applied to a format whose lines name their own unit | `format_variant_ambiguity_note`, `defer_format_unit_notes` | `features/58-format-registry-staged-detection.md` § S7 unit-ambiguity note (D18); `features/412-notice-surfaces.md` notice row 16 | code path |

### 3.4 Durations rendered with no floor

The tool's own timings and the population span: the summary stage timings and
total time, and the YAML export's population duration and total time. They
pass a kind and no metric, so `resolve_value_kind()` gives them no floor (617
§ 5 *The budget table*, summary timing and export duration: "no floor"). The
export's population duration read `14.4 hours` on both inputs.

### 3.5 Not a surface: where the values are read

`read_and_process_logs()` converts each duration to milliseconds at the
include point (503 F14); once held, a value no longer shows how many decimals
it was written with. The read is where the precision the raw data carries is
visible. The detection sample (`sample_file_for_detection()`) already records,
per format, the most fractional digits among its sampled timestamps
(`frac_digits`, read by `resolve_timestamp_precision()`); nothing records them
for durations.

### 3.6 Timestamp precision read from a fraction's digits (D4)

Added by D4: the surfaces that turn a timestamp's fractional digits into a
precision through `fraction_precision()`, whose reading of a part-group of
digits changes.

| Surface | Sub | Record behind the current contract | Today |
|---|---|---|---|
| The `-tp` clamp, its note and the `-V runtime-config` `timestamp_precision` row | `resolve_timestamp_precision` | `features/525-timestamp-precision-option.md` § 6.4 (a fraction covers only the steps its digits complete, proposed and implemented) | two digits resolve to the second; four to the millisecond |
| A run-index row's precision when its precision column is empty | `index_row_precision` | 525, the run-index read-back (the stored fraction's digits) | as the clamp |
| `validate-timestamp-precision.sh`, the scenario asserting that a two-digit fraction resolves to the second | | 525 | asserts the rule D4 replaces |

---

## 4. Records reconciled

Every record the search returned (`./process/find-records.sh --issues` over
`-du`, `--duration-unit`, `duration_unit_resolved`, `resolve_value_kind`,
`format_time`, `value_text`, `note_finer_duration_bounds`, the notice's text,
*stated unit*, *declared unit*, *source unit*, *source precision* and
*resolution*), read and given a disposition against § 2's two points: *stands*;
*reversed* or *amended* (by the architect, recorded in the owning doc);
*touched* (a question for phase 4); *describes the delivered code* (true today,
updated when #759 delivers, phase 7); or *dismissed*, with the reason.

### 4.1 Locked decisions

| Record | What it says | Disposition |
|---|---|---|
| 617 D16 | the stated unit is the floor of every rendering, a user-defined metric's declared unit included | reversed 2026-10-29 (recorded in the 617 doc) |
| 617 D4 | a real zero duration renders in the source's resolved unit on every surface | amended 2026-10-29: the unit that follows a zero is the raw data's unit (from the format registry, or `-du`) combined with the precision the raw data carries |
| `features/444-access-log-format-family-and-user-surface.md` R17 and D16 | the mixed `0us` / `ms` rendering on the thread-session shape is fixed at its cause: `format_duration_total()` renders a zero total in the resolved source unit | amended with D4; § 4.3 measures what the amendment means on that shape |
| 617 D19, `features/608-byte-unit-ladder.md` D18 and D9 | a value is rounded to the floor step's resolution first and no rendered digit is finer than it; that resolution is the step's decimals field relative to the millisecond storage unit (`ns` 6, `us` 3, `ms` and every longer token 0); one default decimals rule from the step on every surface, the CSV's duration and percentile families included | touched: each reads the stated unit's step. Which precision they read once the floor is gone, and so how a computed value (a mean, an interpolated percentile) finer than the detected precision is rounded, is a phase 4 question |
| `features/605-input-units.md` D22 and § 5 | a duration bound finer than the unit the log's durations are recorded in gets a note; that unit is `-du` when given, otherwise each file's format `duration_unit` | D22 stands (a bound finer than the log records gets a note); § 5's definition of what the log records is amended to the raw data's unit combined with the precision it carries, as the architect directed for the notice (§ 2) |
| 605 D30 | a format whose lines name their own unit (`[150us]`) declares `line`, contributes no unit to anything that compares against the log's unit, and D22's note does not fire on it | touched: such a log's raw data still carries a precision; whether the note compares against it is a phase 4 question |
| 617 D9, D10, D18 | the latency cells' budget; tier and fit once per timeline column; the messages-table total walked by its width | stand: they govern the rendering, which is out of scope |
| 617 D22 | the tool's own timings take their unit from their magnitude and have no floor | stands |
| 617 AC8, AC9; § 3 correction 7; § 5 *The budget table*, chart label, *Changes* ("the floor (D16) and the zero rule (D4)") | assert or describe the floor | fall with D16 and change with D4; `validate-value-display` scenarios `zero-duration` and `floor-unit`, which assert them, are rewritten under #759's criteria (phase 6) |
| `features/503-yaml-aggregate-export.md` F14, D20 | every stored duration is milliseconds; provenance names the source unit once | stand |
| 617 § 5 *The budget table*, summary timing and export duration rows | the tool's own timings and the population duration: no floor | stand |
| `features/525-timestamp-precision-option.md` D4 (as amended 2026-10-08) and D10 | timestamps are never shown finer than the files carry; the true precision is the unit the timestamp field states with the fractional digits it carries, through the ladder; the request gives way only to the finest precision any processed file carries | stand; the existing reading, for timestamps, of a unit combined with the precision the raw data carries, which phase 4 weighs for durations |
| `features/58-format-registry-staged-detection.md` § S7 unit-ambiguity note (D18) | a format whose producers differ in their duration unit, read without `-du`, gets a note that durations are assumed to be milliseconds | stands: it names the unit a value is read in |

### 4.2 Other records

| Record | What it says | Disposition |
|---|---|---|
| #292 (closed; no feature doc) | a millisecond source no longer shows synthesized sub-millisecond digits (`58ms`, not `58.2ms`); the fix added a source-unit floor and `0ms` for zero | its intent is § 2's second point; what it built is carried by 617 D19 and 608 D18 above; the closed thread is history |
| `features/460-bin-model-percentile-source.md` | percentiles were computed from the re-projected display partition | dismissed: the bin partition's resolution, not the source's unit or precision |
| #491 (closed) | an evidence-selected microsecond format and `-du us` render at different precisions | dismissed: closed as filed in error, no defect |
| #17 (open), `features/duration-unit-autodetection.md` | detect the duration unit from sampled values | relates: the detection sample hands its lines forward for unit sampling; #759 needs the precision of the same values, #17 their unit; neither waits for the other |
| #386 (open) | per-format analysis precision for timestamps | dismissed: timestamps' analysis precision |
| `features/log-format-registry.md` § 1 *Duration unit*, § 4 *Duration Unit Handling*, the unit-system scope boundary (D18) | each format declares `duration_unit` (a ladder token, or `line`); `-du` takes precedence; unit auto-detection by sampling values is #17's, not the #23 rewrite's | stand: the unit in § 2's first point is this field, with `-du` over it |
| 58, the per-line conversion chain | `-du` wins, else the entry's duration unit, through `convert_duration_to_ms()` | stands: the unit a value is read in |
| `features/412-notice-surfaces.md`, notice rows 16 and 24 | `-du` not applied to a format naming the unit per line; a duration bound finer than the log's recorded unit | row 16 stands; row 24's trigger changes with 605 § 5 above |
| `features/user-defined-metrics.md` § *Since #617*; `docs/architecture-patterns.md` *Width-to-format rule* ("with its floor") and the timestamp-precision entry ("the timestamp instance of the rule that a value never renders in a unit smaller than its stated unit"); `features/524-bucket-size-unit.md` § *Since #617*; `features/273-store-precise-duration-totals.md` (a zero in the source unit; `duration_nice` `0 msec`) | the floor and the zero in the source unit | describe the delivered code; updated when #759 delivers |
| `docs/usage.md`, the `-du` row; `--help` | the unit the log is read in | stand: no user-facing statement of the floor was found |
| `releases/v0.19.0.md` | "never below the log's own unit (#617)" | shipped release notes, not edited; 0.20.0's notes carry #759's fix |
| `features/342-redundant-logic-surfaces-audit-report.md` F2.1, F2.5 | the zero and the per-source-unit decimals, as audit findings | dismissed: the audit points at 444, 524, 617 and 608, read above |
| `docs/explain/statistics.md` *impact*; `features/616-gated-mean-derivation.md` D20 | impact's duration term is floored at one unit | dismissed: a numeric floor in a computation, not a rendering |
| `features/224-validate-statistics-test-harness.md`, `features/528-record-lexical-retained-representation.md`, `features/747-harness-checks-on-a-failed-run.md` | `-du us` and `-du ns` as the input unit of harness and memory runs; the `duration_unit_resolved` row a harness needs | dismissed: they read a file's unit |
| Records matching only on *resolution* | the word in another sense: the histogram's bin resolution, a timestamp's, a measurement's | dismissed |

### 4.3 Finding: the thread-session access-log shape carries microsecond precision

The thread-session shape is the Tomcat access log whose lines end with the
request's duration in milliseconds, the thread name and the session ID:

```
10.0.0.3 - alice [05/May/2025:00:00:02 +0000] "POST /Thingworx/WS HTTP/1.1" 200 2644 446.268 https-jsse-nio-8443-exec-111 -
```

`446.268` is 446 milliseconds and 268 microseconds. Measured on the first
200,000 lines of the corpus's log of this shape: 198,970 durations carry a fraction, 172,848 of them three
digits, 23,678 two and 2,444 one; trailing zeros are not written, so the
precision is the most digits seen, not each value's own.

Read as § 2 reads seconds with three decimals, milliseconds with three
decimals carry microsecond precision. On this shape:

- the unit that follows a zero, the raw data's unit combined with its
  precision, is the microsecond: the `0us` that 444 R17 recorded as a defect, and fixed by
  rendering a zero in the resolved source unit (`0ms`). 444's finding traced
  that `0us` to the scaler climbing from its lowest step, not to the file's
  precision;
- a value below a millisecond, which 617 D19's ceiling at the millisecond step
  rounds to a whole millisecond today, is within the precision the file
  carries (the phase 4 question of § 4.1).

**D1 — On the thread-session shape a zero is followed by the microsecond:
`0us`.** The shape's raw data is milliseconds written with three decimals, so
it carries microsecond precision, and the unit that follows a zero is the raw
data's unit combined with its precision. Put to the architect with the
alternative that 444 R17's fix (a zero in the resolved source unit, `0ms`)
stands on this shape; the architect chose `0us`, and R17's fix gives way on
this shape. Locked by the architect 2026-10-29; recorded on 444 R17.

---

## 5. Design decisions

**The precision.** The raw data's precision is the smallest unit its durations
reach: the unit they are read in, one ladder step finer for every three
decimals written. It takes the place of the unit read in where the display's
floor and rounding are set today (`resolve_value_kind()` hands it to
`format_time()` as `floor` and `resolution`). A zero is shown in it, and
nothing finer than it is shown. On a log whose durations carry no decimals it
is the unit read in, and the display is unchanged. Confirmed by the architect
2026-10-29:

| Durations written as | Precision | A zero shows as |
|---|---|---|
| `446` (milliseconds, no decimals) | millisecond | `0ms` |
| `446.268` (milliseconds, three decimals) | microsecond | `0us` |
| `12` under `-du s` (whole seconds) | second | `0s` |
| `0.123` under `-du s` (seconds, three decimals) | millisecond | `0ms` |

- **D2 — A log's duration decimals are counted in the detection sample.**
  `sample_file_for_detection()`, which reads three 8 KB parts of each file
  (start, middle, end; the whole file under 24 KB) to recognise its format
  before the first line is processed, counts the decimals of the duration on
  each line it recognises, as it does for timestamps (`frac_digits`), and
  keeps the most seen per format. The precision is the unit the durations are
  read in (`-du`, else the format's `duration_unit`) descended by those
  decimals. Nothing is added per line, so no prototype is needed (phase 5). A
  file that cannot be sampled (standard input) carries no count and keeps the
  unit read in. Rejected: counting on every line as it is read (exact, but a
  cost on every line of every file); a precision written into each format's
  definition (it cannot know the decimals of a log read under `-du`, which is
  the reported case). The architect chose the sample 2026-10-29, the
  mechanism he directed for timestamps on 2026-10-08
  (`features/525-timestamp-precision-option.md` § 6.4). Locked by the
  architect 2026-10-29.
- **D3 — A duration written with one or two decimals steps down one unit, as
  three do.** A partial group of decimals is a full group whose trailing zeros
  are not written. The architect: "the situation that you are describing here
  is also equal to writing 12.300. The fact that those two units, those two
  zeros, aren't there, they are still milliseconds." So `12.3` ms carries
  microsecond precision and reads `12.3ms`, `0.4` ms reads `400us`, and `0.05`
  s under `-du s` reads `50ms`. Rejected: stepping down only for a complete
  group of three (`fraction_precision()` as timestamps use it today), which
  shows `0.01` s as `0s`, the reported defect, and drops the `.3` of `12.3`
  ms. Locked by the architect 2026-10-29.
- **D4 — Timestamps follow D3: one rule in `fraction_precision()` for
  timestamps and durations alike, delivered by #759.** A part-group of
  decimals steps down one unit wherever decimals are turned into a precision:
  the `-tp` clamp and its note (`resolve_timestamp_precision()`), a run-index
  row's precision when its precision column is empty
  (`index_row_precision()`), and the durations' precision (D2). `-tp ms` on a
  log whose timestamps read `12:00:00.23` shows the millisecond with no note,
  where today it clamps to the second and the note says the timestamps "carry
  whole seconds"; `-tp us` on `12:00:00.9996` shows the microsecond. The
  timestamp rule it replaces (a fraction covers only the steps its digits
  complete) was proposed and implemented under #525 (timestamp precision
  option) and never decided by the architect
  (`features/525-timestamp-precision-option.md` § 6.4, amended in the same
  action). Rejected: a parameter keeping the two readings apart, two readings
  of the same digits in one sub. The scope of #759 widens to this timestamp
  change; § 3.6 lists its surfaces. Locked by the architect 2026-10-29.
- **D5 — A user-defined metric's decimals are counted on each value as the
  metric reads it.** In `read_and_process_logs()`, after a captured value
  passes the number test and before it is converted, its decimals are
  counted; the metric's precision is its declared unit descended by the most
  decimals seen (D3's rule), and it replaces the declared unit as the floor
  and rounding of every display of the metric. `-udm
  pause:s:max:/pause=([\d.]+)/` over `pause=0.012` reads `12ms`, where the
  declared-unit floor reads `0s` today; a byte metric takes the same count
  (`size=1.5` declared in `kB` reaches the byte). The cost is one count per
  matched value, only in runs with `-udm`: a before/after benchmark with a
  `-udm` run, no prototype. Rejected: counting in the detection sample's lines,
  which a `-udm` run keeps (no per-line cost, but a metric on lines too rare
  to appear in 24 KB, such as GC pauses, falls back to its declared unit and
  shows the reported defect). Locked by the architect 2026-10-29.

Settled by the records, taken without a question:

- **A run over several files takes the finest precision any file carries**, as
  the timestamp precision does (`features/525-timestamp-precision-option.md`
  D4 as amended 2026-10-08): one file written with fewer decimals does not
  lower the run.
- **A computed value (a mean, an interpolated percentile) is rounded at the
  precision.** The default decimals are the source's resolution on every
  surface (`features/608-byte-unit-ladder.md` D9), now read from the precision
  instead of the unit read in: a mean of 10.4 ms reads `10ms` on a log of
  whole milliseconds and `10.4ms` on a log written to the microsecond.
- **The CSV duration and percentile decimals follow the precision.** The
  default decimals are the same on every surface, the CSV's duration and
  percentile families included (`features/608-byte-unit-ladder.md` D9; `-cp`
  is the knob for more). On the thread-session shape, written to the
  microsecond, those columns go from `446` to `446.268`; under `-du s` on
  seconds with three decimals they stay whole milliseconds. The decimals are
  resolved today at option settlement (`%csv_family_decimals`), before any
  file is sampled, so they move after the read.
- **The finer-bound notice compares a bound against the precision of the
  durations read, on every log.** The architect, 2026-10-29: "Precision is not
  about the line. It is about the metrics which have been read from it." No
  format is a special case: the format whose lines write each duration's unit
  beside it gets its precision from the durations read from it, as every
  other format does, and the notice fires on it like any other log. The
  exclusion `features/605-input-units.md` D30 gave that format falls; the
  wording names the precision (`which are recorded to the millisecond`).

---

## 6. Prototype decision

No prototype. A built-in duration's decimals are counted in the detection
sample, once per file (D2); a user-defined metric's are counted on each value
it reads, beside the number test the read loop already runs on that value
(D5): a small change to an existing path, with no new data model and no new
code path. The hot path is touched only by D5, in runs with `-udm`, so the
before/after benchmark runs the standard case
(`single-day-access-log-standard`) and `network-latency-csv`, the benchmark
test that reads a user-defined metric (`-udm latency_ms`).

---

## Acceptance criteria

**Confirmed by the architect 2026-10-29.** Each criterion names its input
by its characteristics, its outcome, and where it is asserted. Assertions read
the rendered output against what each input's known decimals give; no `-V` key
is added for the precision. Every scenario carries the runtime-warning check.

- [ ] **AC1 — The reported defect** (§ 2, D2). The same durations, read once
      in milliseconds and once in seconds with three decimals under `-du s`,
      render the same text on every duration surface of § 3.1: the timeline
      P50 to P99.9 cells and duration column, the messages-table Min, P50,
      P99.9 and Duration, the heatmap header and footer, the histogram axis
      labels and percentile legend, the `-V` display-dimensions lines, and the
      STATS and MESSAGES CSV `duration_nice`. `0.010` reads `10ms`, `0.123`
      reads `123ms`. Input: the committed duration-spread access-log fixture
      and a committed copy of it in seconds with three decimals. *Assertable:*
      `validate-value-display`, a new scenario comparing the two captures.
- [ ] **AC2 — A zero is shown in the precision** (617 D4 as amended, D1).
      Zero durations read `0ms` on whole milliseconds, `0us` on milliseconds
      written with three decimals, `0s` on whole seconds under `-du s`, and
      `0ms` on seconds written with three decimals under `-du s`: on the
      heatmap header, the timeline latency cells and duration column, and the
      display-dimensions line. *Assertable:* `validate-value-display`
      `zero-duration`, rewritten; the four inputs are generated by the harness
      from the committed zero-duration fixture.
- [ ] **AC3 — Nothing is shown below the precision** (§ 2). On whole
      milliseconds no duration reads in micro- or nanoseconds (the existing
      assertion, its contract re-pointed here); on seconds with three decimals
      under `-du s`, none reads below the millisecond; on milliseconds with
      three decimals, a 0.5 ms duration reads `500us` and none reads in
      nanoseconds. *Assertable:* `validate-value-display` `floor-unit`,
      rewritten.
- [ ] **AC4 — A part-group of decimals steps down one unit** (D3). `12.3` ms
      reads `12.3ms`, `0.4` ms reads `400us`, and `0.05` s under `-du s` reads
      `50ms`. *Assertable:* `validate-value-display`, a new scenario.
- [ ] **AC5 — A computed value is rounded at the precision** (608 D9; 617 D19
      read from the precision). A percentile falling between two written
      values shows no digit finer than the precision: none below the
      millisecond on whole milliseconds, the microsecond's digits on
      milliseconds written to the microsecond. *Assertable:*
      `validate-value-display` `common-maxima` or a new scenario, beside 617's
      ceiling criterion.
- [ ] **AC6 — Several files take the finest precision any carries**. A file of
      whole milliseconds read with a file of milliseconds written to the
      microsecond: a zero reads `0us`. *Assertable:* `validate-value-display`,
      a new scenario.
- [ ] **AC7 — A user-defined metric's precision is its declared unit and its
      decimals** (D5). `-udm elapsed:s:max` over the committed seconds-metric
      fixture (`0`, `0`, `0.25`, `2`; two decimals, so the millisecond): `0.25`
      reads `250ms` on its timeline column and heatmap labels, a zero `0ms`,
      `2` reads `2s`, and the display-dimensions line reads `min=0ms`. Over
      whole seconds only, a zero reads `0s`. A byte metric declared in `kB`
      whose values carry a decimal renders `0.5` in bytes, not `0.5kB`.
      *Assertable:* the user-defined assertions of `zero-duration` and
      `floor-unit` inverted, and a byte case added.
- [ ] **AC8 — The CSV duration and percentile decimals follow the precision**
      (608 D9). `-V csv-output` `decimals_duration` and `decimals_percentile`
      read `3` on milliseconds written with three decimals, `0` on whole
      milliseconds, and `0` on seconds with three decimals under `-du s`; on
      the first, the MESSAGES CSV duration cells carry the three decimals.
      `-du ns`, `-du us`, `-du ms` and `-du m` on whole values keep `6`, `3`,
      `0` and `0`, and `-cp` still decides when given. *Assertable:*
      `validate-byte-units` `ladder-decimals`, its contract re-pointed and the
      cases added.
- [ ] **AC9 — The finer-bound notice compares against the precision, on every
      log** (§ 5, the notice). On seconds with three decimals under `-du s`,
      `-dmin 50ms` prints no note and `-dmin 200us` prints `-dmin 200us is
      finer than the log's durations, which are recorded to the millisecond`;
      on whole milliseconds, `-dmin 200us` prints the same wording; on the
      format whose lines write each duration's unit, over `[150us]` values,
      `-dmin 200us` prints none and `-dmin 200ns` prints `... which are
      recorded to the microsecond`. *Assertable:* `validate-option-resolution`
      `finer-bound-note`, rewritten.
- [ ] **AC10 — Timestamps read a part-group of digits by the same rule** (D4).
      `-tp ms` on timestamps with two-digit fractions shows the millisecond
      with no note; `-tp us` on them clamps to the millisecond with a note
      naming milliseconds; `-tp us` on four-digit fractions shows the
      microsecond with no note; a run-index row with an empty precision column
      and a two-digit fraction reads the millisecond. *Assertable:*
      `validate-timestamp-precision` `truth/*` and `index/older-row-fresh`,
      rewritten where they assert the rule D4 replaces.
- [ ] **AC11 — An input with no decimals, or whole groups of three, renders
      unchanged.** Every output on such an input is identical to the base:
      every duration call site of `value_text()` and `value_column()` (§ 3.1),
      the CSV decimals, the notice, the timestamp clamp and the run index.
      `duration_unit_resolved` in `-V csv-output` and the YAML export still
      names the unit read in (§ 3.3). *Assertable:* `validate-regression`,
      every golden byte-identical except those whose input carries fractional
      durations or part-group timestamp fractions, each listed with its
      reason; the `validate-value-display` scenarios not rewritten pass
      unchanged.
- [ ] **AC12 — Looked at on real data** (a visual surface). The reproduction
      pair and the corpus's thread-session access log, rendered with `-hm
      duration -hg duration`: the legends, axes and messages table read in the
      precision. *Unassertable by a harness on corpus data:* inspected before
      delivery and recorded here.

---

## 7. Delivery plan

**Proposed, for the architect's confirmation.**

**Before the first line of code.** The issue branch
`759-duration-precision-rendering` is cut from `release/0.20.0`,
`$version_number` set to `0.20.0-759`, and the `before` benchmark captured on
the base commit: `single-day-access-log-standard` and `network-latency-csv`
(§ 6).

**The drops**, one at a time, each run before and after on the inputs it
changes, then committed and pushed on the issue branch with its harness
assertions:

| Drop | What changes | What a user sees | Criteria |
|---|---|---|---|
| 1. One rule for a part-group of decimals | `fraction_precision()` steps a part-group of decimals down one unit (D3, D4) | `-tp ms` on timestamps written with two-digit fractions shows the millisecond, with no note; an older run-index row's precision likewise | AC10 |
| 2. The duration precision, counted and applied | the detection sample counts the decimals of each recognised line's duration, the format writing its unit on each line included (D2); after the read, one resolution beside the timestamp precision gives the run's precision, the finest any file carries, or the unit read in where nothing was counted; `resolve_value_kind()` hands it to `format_time()` as floor and resolution | the reported defect fixed: under `-du s`, `0.010` reads `10ms`; on milliseconds written with three decimals, a zero reads `0us` and 0.5 ms reads `500us` | AC1 to AC6, AC11 |
| 3. The CSV decimals | the duration and percentile families' decimals resolved after the read from the precision, and reported so by `-V csv-output` | three decimals in those CSV columns on a log written to the microsecond | AC8 |
| 4. The finer-bound notice | `note_finer_duration_bounds()` compares against the precision, every format included; the wording names the precision | `-dmin 50ms` on seconds with three decimals prints no note; the note reads `recorded to the millisecond` | AC9 |
| 5. A user-defined metric's precision | the read loop counts the decimals of each value a metric reads (D5); `resolve_value_kind()` hands the metric's precision to its arm | a seconds metric's `0.25` reads `250ms` | AC7 |

Then AC12 is looked at and recorded, the records below are updated, and the
completion gate runs: the `after` benchmark of § 6 first, then the full suite.

**User-facing text.**

- `docs/usage.md` § quantity bounds: "a unit finer than the one the log's
  durations are recorded in" names the precision the durations carry.
- `docs/usage.md` and `--help`, the `-cp` row: "per-family decimals derived
  from the source's duration unit" names the precision the durations carry.
- The `-du` and `-tp` rows stand.
- `releases/v0.20.0.md`: the release-notes decision is taken at close-out.

**Records to update at delivery** (§ 4's *describes the delivered code*):

- `features/617-width-to-format-rule.md`: § 5 *The floor and the zero rule*,
  the budget table's chart-label row, the *User surface changes* rows for a
  zero and for a value below its floor, and AC8 and AC9 marked replaced by
  this issue's criteria.
- `features/444-access-log-format-family-and-user-surface.md`, the *Since
  #617* line.
- `features/user-defined-metrics.md` and `features/524-bucket-size-unit.md`,
  their *Since #617* lines; `features/273-store-precise-duration-totals.md`,
  criterion 3's "a zero renders in the source unit" (its `0 msec` assertion on
  whole milliseconds stands).
- `features/525-timestamp-precision-option.md`, the run-index read-back's
  statement of the part-group rule.
- `features/605-input-units.md` § 5, the notice's definition of what the log
  records; `features/412-notice-surfaces.md` notice row 24 ("finer than the
  log's recorded unit").
- `features/608-byte-unit-ladder.md`, the *CSV decimals* table row (the step
  of the precision, not of the unit read in).
- `docs/architecture-patterns.md`: *Width-to-format rule* ("with its floor"),
  and *Timestamp precision* rule 4 (the rule a value never renders below its
  stated unit).
- The comments of `resolve_value_kind()`, `format_time()`,
  `note_finer_duration_bounds()` and the CSV decimals resolution in `ltl`.
