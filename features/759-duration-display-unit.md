# A duration's display unit is pegged to the unit it is read in (Issue #759)

## Status

**Specification in progress.** Work started 2026-10-29 on `release/0.20.0`;
the specification is written here on the release branch, and the issue branch
is cut from it when implementation starts. Phase 1 (the requirement) is
written; phases 2 to 7 follow, each brought to the architect before the next.

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
