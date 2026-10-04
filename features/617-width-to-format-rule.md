# One width-to-format rule and one dispatch per metric kind (Issue #617)

## Status

Specification agreed with the architect 2026-09-28. Implementation started
2026-10-04 on branch `617-width-to-format-rule` off `release/0.19.0` (2c04a38),
`$version_number` stamped `0.19.0-617`, the before benchmark captured on the
base commit (`tests/baseline/results/617-before.tsv`). Drops 1, 2 and 3 are
committed (§ Delivery progress).

This issue is a sub-issue of #622 (the refactoring dispatched by the #342 audit
review). It blocks #514 (the count metric becomes explicit and off by default):
every count surface changes hands there and lands on the one dispatch this issue
builds. It is blocked by #613 (one vocabulary for names: the kind resolver reads
its built-in metric table's family column) and by #608 (one byte ladder and
output notation: the byte formatter's tokens and climb, and the regression
goldens re-blessed in sequence, #608 first, then #616, then this issue). The
Deliver stage records two more edges: blocked by #273 (store the precise total
duration), because the messages-table total is formatted at #273's emit sites,
which this rule then walks by the column's width (D18); and by #616 (gated
means: goldens re-blessed after it; native edge recorded in the Deliver stage).

Every run quoted in this document was captured on 2026-09-28 against the tree
above, with `--disable-progress`, into the session scratchpad; the regression
goldens were counted on their escape-stripped text.

---

## 1. The motivating consumer

Two readers, one on each side of the tool.

**The analyst reading one run.** The same number appears on several surfaces of
one run: the timeline row, the heatmap header, the histogram axis, the messages
table, a notice. Today it is spelled differently on each, so the reader has to
decide whether `1.50 k` and `1.5k` are the same value, whether `0ns` on the
heatmap and `0ms` on the timeline describe the same lines, and what `864.7`
with no unit or `119 millisecon` means. A value that reads one way everywhere,
at the precision its space affords and never cut, lets the reader compare
surfaces without translating between them.

**The next change to a display surface.** Four open issues move display
surfaces, and each would otherwise reach five copies of "which formatter for
this metric kind", two copies of "which tier for this width" and four ways of
fitting a value to a width:

| Issue | What it moves |
|---|---|
| #514 (count metric explicit, off by default) | every count surface changes hands |
| #608 (one byte ladder, SI or IEC notation per run) | the byte formatter every byte surface calls |
| #497 (rows exceed the terminal width), #498 (messages-table headings degrade) | the widths these formatters fill |
| #412 (a notices surface) | every notice line, and the numbers inside them |

With one rule and one dispatch each of these edits one place, and a new surface
calls the dispatch with the width it has, or names its budget, instead of
choosing a formatter and its arguments.

### What a reader sees today

| Input | Surface | Renders |
|---|---|---|
| one application-log line carrying a count of 1500, `-bs 1 --terminal-width 220` | timeline count column | `1.50 k` |
| same, `-hm count` | heatmap header | `1.5k heatmap [count] 1.5k` |
| same, `-hg count` | histogram x-axis and percentile legend | `1.5k` |
| two access-log lines with a duration of zero, `-hm duration -bs 1` | heatmap header and footer | `0ns heatmap [duration] 0ns` |
| same | timeline latency cells; messages-table total | `P50:0ms`; `0 msec` |
| two application-log lines whose key `elapsed` is zero, read as a user-defined metric in seconds, `-hm` on it | heatmap header | `0ns heatmap [e] 0ns` |
| three access-log lines of one path, durations 10, 20 and 30 ms (coefficient of variation exactly one half), `-o` | timeline CV cell; messages-table CV cell; both CSVs | `CV:0.50`; `0.50`; `0.5` |
| 1,200 lines in the classification-verification shape matching neither outcome rule, `-lf classification_verification` | warning; legend; messages table; summary | `Warning: 1200 included line(s) (100.0%) ...`; `INFO: 1.2k`; `1200`; `LINES READ 1200` and `1200 (100%)` |
| two access-log lines, the first with a duration of 999 ms, `-bs 1 -n 0` | timeline duration column at `--terminal-width 130` | `999 millisecon` |
| the 19-line numeric-boundary application-log fixture (one one-minute bucket, 18 lines carrying a count key), a user-defined rate of that key per second, `-ru s -bs 1 -o -n 0` | STATS CSV, same row | `msg-rate_sec` `0.3`; the user-defined `cnt_rate_sec` `0` |

The regression goldens (`tests/reference-output/`, 74 captures) freeze the same
defects: 21 of them carry at least one value cut by its column (`16.4 K` and
`2.8 M` for kibibytes and mebibytes, `864.7` with the unit gone, `119 millisecon`);
11 carry a CV cell with a trailing zero (`CV:3.00`, `CV:2.30`); 21 carry a count
at two decimals (45 values, two of them ending in zero, `1.30 Mil`); 4 carry a
histogram y-axis tick that rounds 1,155 samples to `1k` above a tick reading `866`.

---

## 2. Requirement

In the architect's terms, transcribed from the issue body and the #342 review's
stages 7 (value formatting call shapes), 8 (notices) and 16 (patterns file
refinement) (`features/342-redundant-logic-surfaces-audit-report.md` § Review
progress), with the architect's answers of 2026-09-28 (§ 4), organised but not
reinterpreted.

**The rule.** A value is rendered by one rule that knows the metric kind and the
width it has. The rule decides how far to abbreviate (the tier), whether the
space before the unit fits (the fit), and how many decimals the width affords.
Every display surface calls it with its width or a named budget. The rule is the
same for every kind: counts, durations, bytes and user-defined values have no
rule of their own.

**Why.** Each surface carries its own argument set today, so one value prints
three ways in one run, and the same rules are written five, seven and three
times: "which formatter for this metric kind" five times, "which tier for this
width" twice, "fit a value to a width" three ways, "strip trailing zeros" with
seven idioms.

**Done when** (the issue body):

- one value prints one way at one tier and fit across the timeline, the heatmap
  header and the histogram;
- the zero fixture reads the source unit on every surface;
- no display surface prints a trailing zero;
- the CV cell and the CSV agree;
- every formatter takes a width or a named budget and nothing else;
- the harnesses that read rendered values assert the new spellings.

**Constraint inherited from the audit** (`features/342-redundant-logic-surfaces.md`
§ 2 Constraints): convergence does not change documented behaviour except where
copies already disagree; there the documented contract wins and the deviation is
called out in the PR body. `validate-regression` freezes rendered surfaces byte
for byte, so every golden that moves is listed with the disagreement that
licenses it.

---

## 3. Corrections to the issue body and the audit record

Verified in the worktree's `ltl` by `grep -F` inside the named sub, and by the
captured runs of § 1.

1. **The double trailing-zero strip is in the CSV cell formatter, not the
   duration formatter.** The issue body says one formatter strips twice. In
   `format_time` the two idioms (`$formatted_value =~ s/0+$//;` and
   `$formatted_value =~ s/\.0+(?=\s|$)//;`) sit on the two exclusive branches of
   `if (defined $significant)`, so one value meets one of them. It is
   `format_csv_value` that applies two in sequence to one value
   (`$formatted =~ s/\.0+$//;` then `$formatted =~ s/(\.\d*?)0+$/$1/;`). The
   count of idioms stands: six live, plus the unused
   `sub normalize { $_[0] =~ s/\.0+$//r }`, which nothing calls.
2. **The cited dispatch snippet appears twice, not three times.**
   `format_heatmap_value` :: `return $ut eq 'time'  ? format_time($value, 'ms') :`
   is written once for the heatmap's user-defined metric and once for the
   histogram's; the third dispatch in the sub is its built-in name chain
   (`if ($metric eq 'duration') {`). The total of five dispatch copies holds with
   `print_bar_graph`'s display branch and its STATS CSV builder.
3. **There is a fourth width rule.** Besides the two width-to-tier copies,
   `print_bar_graph`'s fall-through branch for the sessions, users and thread-pool
   columns maps width to decimals:
   `my $decimals = $col_w > 10 ? 2 : ($col_w > 8 ? 1 : 0);`.
4. **Three guards cut a value that does not fit, and they fire.** The width
   rules choose a tier from the column width alone, never from the value, and
   bytes have no width rule at all. What does not fit is cut:
   `print_bar_graph` :: `my $value_char = (split //, $trend_value )[$i];` prints
   exactly the column's width of the proportional-column value;
   `print_bar_graph` :: `$cell_text = substr( $cell_text, 0, $col_w ) if length($cell_text) > $col_w;`
   cuts the value-only cells; `printf( "...P50:%-6.6s..."` and `CV:%4.4s` cut the
   latency and CV cells. Measured: a 999 ms bucket at `--terminal-width 130`
   reads `999 millisecon`; 21 of 74 regression goldens freeze a cut value (§ 1).
   The audit's finding that the three fit-to-width mechanisms are identical in
   effect did not measure the proportional columns.
5. **The heatmap's user-defined branch is live for non-counting metrics.** It
   appends no rate suffix and is unreachable by a rate metric, as the audit
   measured (the heatmap refuses counting aggregations first). It is reached by
   every other user-defined metric: a user-defined maximum of a millisecond key
   on the numeric-boundary application-log fixture, `-hm` on it, renders its
   header through that branch (`10ms ... heatmap [x] ... 201ms`). Only the rate
   case is dead code. D15 settles what happens to it: the branch folds into the
   dispatch and user-defined heatmaps keep their units.
6. **The histogram y-axis loses up to half a unit.** `render_histogram_row` ::
   `my $count_str = format_number($count_val, 'medium', undef, 0);` rounds a
   tick of 1,155 samples to `1k` directly above a tick reading `866` (four
   goldens with a combined duration histogram).
7. **The zero rule reads the built-in duration's unit for every time value.**
   `format_duration_total` renders zero in `$duration_unit_resolved`, the unit
   of the built-in duration field, and the timeline's user-defined time arm calls
   it; a user-defined time metric declared in seconds is converted to
   milliseconds on capture and its zero has no unit of its own on any surface.
   Its heatmap header reads `0ns` (§ 1).
8. **The CSV-skip summary warning prints from two skipped rows up.**
   `read_and_process_logs` :: `if ($csv_skipped_timestamp_rows > 1) {`; the first
   skipped row prints its own warning naming the file, the line number and the
   value.
9. **A `-V` line is fed by a presentation formatter.**
   `format_histogram_dimensions_line` :: `my $min_fmt = format_heatmap_value($stats->{min}, $metric);`
   writes the display-dimensions lines of the `histogram-array` and
   `histogram-bin-counters` sections; `validate-histogram-bin-counters` asserts
   the duration line's shape with `min=[^ ]+`, so a space inside the value would
   break it. A bytes line carries one today (`format_bytes` returns the value, a
   space and the unit); no assertion reads it.
10. **The unclassified-lines warning is producible.** The classification harness
    records that no shipped format can produce a non-zero leakage warning, and
    asserts none. The verification format, seated with `-lf classification_verification`,
    produces it (§ 1), so its numbers can be asserted.
11. **`docs/percentage-presentation.md` schedules a migration this issue
    triggers.** Its migration table moves the histogram's percent ticks
    (`render_histogram_row` :: `$y_pct = sprintf(" %3d%%", $pct_val);` and
    `render_histogram_x_axis` :: `$result .= $box->{corner_br} . sprintf(" %3d%%", 0);`)
    to the percentage formatter "at the next touch of that renderer"; this issue
    touches `render_histogram_row`, so the migration comes due here.
12. **"The CV cell and the CSV agree" has a precision gap by design.** The CV
    cell has a four-character budget and two decimals below ten; the STATS and
    MESSAGES CSVs give the `shape` family three decimals (`%csv_family_decimals`,
    `shape => 3`). They can agree as strings only where the CSV value fits the
    cell's budget; elsewhere the cell is the CSV value rounded to the budget.
13. **Lock 5's switch is `-pv`, not `-ov`.** The issue body names "the
    precise-values switch" and the architect confirms it is `-pv` (no conversion
    or shortening of the numbers). The #342 review's stage 7 row writes `-ov`, a
    transcription error: `--omit-values` and `--rate-unit` relate to the legend
    but are not that switch (D17). The stage 7 row is corrected by this issue's
    delivery comment, not edited.
14. **Four notices print a measured count inline, not two.** Stage 8 names the
    unclassified-lines warning and the CSV-skip warning. Two more interpolate a
    raw count: `report_skipped_final_pass` ::
    `"Note: the final consolidation pass was skipped over $skipped_keys message"`
    and the unregistered-levels note, whose `scalar(keys %$tokens)` prints how
    many levels were not recognised. Four others already format their count
    through `format_number(..., 'medium')`: the unregistered-levels note's
    per-level and total line counts, the numeric-filter note, the
    unreadable-directories note and `bin_consolidation_notice`.
15. **A user-defined rate is rounded to a whole number in the CSVs.**
    `format_csv_value` gives the built-in rate columns one decimal by their name
    (`$column =~ /^(err|msg)-rate/`); a user-defined rate column is resolved by
    `resolve_csv_column_family` from its name's suffix, which is the rate unit's
    spelling (`_sec`, `_min`), so it lands in the `count` family (a per-minute
    suffix reads as the minimum statistic) or in none, at zero decimals.
    Measured in § 1 on the STATS CSV: in one minute of 19 lines,
    `msg-rate_sec` reads `0.3` and the user-defined rate of the 18 lines carrying
    the key (0.3 per second) reads `0` in the same row; the MESSAGES CSV writes
    its user-defined rate cells through the same sub. The CSV rules file
    types the user-defined rate columns as floats of up to five decimals.
16. **The time scaler climbs down past the input's unit.** `format_time` starts
    its climb at the ladder's lowest step whatever unit the value came in, so a
    value below one unit of its source renders in a smaller unit (a user-defined
    seconds metric's 0.25 renders `250ms`); the heatmap, the histogram labels
    and the display-dimensions lines call it directly. The latency cells escape
    it only because `format_duration` rounds to the source's resolution first.
    Read from the sub; the goldens it moves are counted at the re-bless (AC20).

---

## 4. Locked decisions

### Locked 2026-09-27 (the #342 review)

Each was locked by the architect in the #342 review and transcribed into the
issue body; they are restated here, not reinterpreted.

- **D1 — One width-to-format rule, resolved from the width a surface has**
  (locked by the architect 2026-09-27, stage 7 of the #342 review). In this
  order: the tier (short, medium, long: how far the number is abbreviated), the
  fit (loose, tight: the space before the unit; loose by default, tight before
  dropping a tier), the decimals up to the tier's maximum (precision when the
  width affords it, fewer when not). A surface passes its width, or names tier
  and fit when it has a fixed budget; it never passes decimals or spacing itself.
- **D2 — One dispatch per metric kind** holds the rule and chooses the formatter;
  the five copies and the two width-to-tier copies go (locked by the architect
  2026-09-27, stage 7).
- **D3 — Trailing zeros are stripped after the decimals are chosen, on every
  display surface**, by one helper every formatter calls, the
  coefficient-of-variation cell included within its budget. A zero in the last
  place adds no information; the decimals are the precision, the strip is the
  visual load (locked by the architect 2026-09-27, stage 7).
- **D4 — A real zero duration renders in the source's resolved unit on every
  surface** (`features/444-access-log-format-family-and-user-surface.md` R17 and
  D16 applied to the heatmap header), never the scaler's lowest step. An absent
  value is #616's empty cell, never a zero (locked by the architect 2026-09-27,
  stage 7).
- **D5 — Tables and the summary print exact occurrence counts**; the legend
  keeps its tier with the precise-values switch. Recorded as the rule (locked by
  the architect 2026-09-27, stage 7).
- **D6 — Notices are display surfaces**: a count in a notice renders through the
  rule at the medium tier and a percentage through the percentage formatter, as
  `docs/percentage-presentation.md` requires of every presented percentage; no
  notice formats a number inline. Sites: the unclassified-lines warning and the
  CSV-skip warning. The `docs/architecture-patterns.md` § Behavioural notices
  entry's refinement closes with it; #412 (notices surface) later moves the lines
  and inherits the rule (locked by the architect 2026-09-27, stage 8).
  **Amended by D14 (2026-09-28):** every measured count in a notice goes through
  the rule, at four sites, not two. Each notice names its own tier or budget:
  medium by default, exact where precision is the point.
- **D7 — The heatmap value formatter's user-defined branch** appends no rate
  suffix where the timeline does, but cannot be reached by a rate metric (the
  heatmap refuses counting aggregations first); the dispatch rewrite removes the
  branch rather than keeping dead code (locked by the architect 2026-09-27,
  stage 16). **Amended by D15 (2026-09-28):** the branch is folded into the
  dispatch, not removed; user-defined heatmaps keep their units. Only the
  unreachable rate case goes.
- **D8 — The three fit-to-width mechanisms** (shed one digit, loop the decimals
  down, fix by magnitude) are the one rule of D1 (locked by the architect
  2026-09-27, stage 7).

### Locked 2026-09-28 (the architect's answers to this draft's questions)

- **D9 — Layout-fixed cells name a budget; only the timeline's proportional and
  value-only cells pass a width.** The latency cells (P50 to P99.9), the
  messages-table duration cells, the four-character CV cell and the axis labels
  each name a budget. The latency cells share one: short tier, tight fit, their
  width for the decimals. The tight latency contract the harnesses enforce
  stands. The messages-table total is walked by its column's width instead
  (D18). Locked by the architect 2026-09-28.
- **D10 — Tier and fit are resolved once per timeline column, against its
  widest value; decimals per value.** One vocabulary down a column, and no value
  cut. Locked by the architect 2026-09-28.
- **D11 — The long tier is never tight, and within each step decimals give way
  before the space.** A whole-word unit keeps its space (`999milliseconds` is
  never rendered). The walk is long loose, medium loose, medium tight, short
  loose, short tight. Locked by the architect 2026-09-28.
- **D12 — Counts have no rule of their own.** The architect: "why would this have
  a different rule set than everything else?" Counts follow the same tier
  maxima and the same width walk as every other kind. The timeline's two
  decimals and the heatmap's one are both outcomes of the one rule applied to
  each surface's width or budget. The record states one set of per-tier decimal
  maxima for every kind, not a count-specific maximum. Locked by the architect
  2026-09-28.
- **D13 — A file-scope budget table.** Each fixed surface names a row: its tier,
  its fit, its width where it has one, and a precision where a locked record
  fixes one (the aggregate export's three significant digits). Callers pass
  only the row name. The per-kind formatters keep their parameter shape as
  internal arms of the dispatch. The output of the aggregate export and of the
  percentage surfaces is unchanged. Locked by the architect 2026-09-28.
  **Amended by D20 and D22 (2026-09-28):** the aggregate export's output is
  unchanged except through the rounding carry at a unit boundary, which reaches
  its total time and peak memory through the calls it shares with the terminal
  (D20), and its population duration through the one rule (D22).
- **D14 — Every notice uses the formatters and the tiering, and each notice
  determines the right approach for what it exposes and why.** The architect:
  "those should use our functions and tiering, but each message needs to be able
  to determine the right approach depending on what it is exposing and why."
  Every measured count in a notice goes through the rule, the four notices that
  print a count inline included (the unclassified-lines warning, the CSV-skip
  warning, the skipped final consolidation pass note and the unregistered-levels
  note's level count), not only the two warnings the #342 review's notices stage
  named. Each notice names its own tier or budget deliberately: medium by
  default, exact where precision is the point. This record states per notice
  what it exposes and which budget it names. Line numbers, option operands and
  echoed settings stay verbatim. Locked by the architect 2026-09-28.
- **D15 — One dispatch resolves every metric's kind.** The heatmap's
  user-defined branch is folded into the dispatch, not removed: user-defined
  heatmaps keep their units. The rate arm is reachable from the timeline and from
  the CSV output (the architect: "rate is also exposed on CSV output"), and the
  design names the CSV sites. Locked by the architect 2026-09-28.
- **D16 — A value is never rendered in a unit smaller than its stated unit.** The
  source's resolved unit, or a user-defined metric's declared unit, is the floor
  of the ladder for every rendering, zero included; a user-defined time metric's
  zero renders in its own declared unit (`0s` for a seconds metric). The
  architect: "sure, noting the rule that the unit can never be smaller than the
  stated unit." Locked by the architect 2026-09-28.
- **D17 — Lock 5's switch is `-pv` (precise values: no conversion or shortening
  of the numbers).** `--omit-values` and `--rate-unit` relate to the legend but
  are not that switch. The stage 7 row's `-ov` was a transcription error,
  corrected by this issue's delivery comment. Locked by the architect 2026-09-28.
- **D18 — The messages-table total duration is walked by its own column width.**
  The architect: "these are two different render surfaces, but I don't really
  care what CSV _Nice gets. The messages tables column width certainly does
  depend on its own width." Once #273 formats the total at its emit sites, the
  table cell passes its column's width; the MESSAGES CSV `duration_nice` cell
  keeps a fixed budget. #617 is blocked by #273 (native edge recorded in the
  Deliver stage). Locked by the architect 2026-09-28.
- **D19 — From #608's locks of 2026-09-28, restated without re-asking**
  (`features/608-byte-unit-ladder.md` D16, D18 and D19). This issue owns the
  rounding carry at a unit boundary (999,999 bytes rendering `1000 kB`, and the
  count formatter's `1000 k`). It reads the ladder step's decimals field, the
  rounding precision relative to the millisecond storage unit, as its decimals
  ceiling. Bytes are a tiered kind exactly like every other kind (the architect,
  in #608's D19: "These rules established yesterday were in fact primarily
  focused at bytes."). A tier spelling the byte ladder lacks is added to the
  ladder step. Locked by the architect 2026-09-28.
- **D20 — The rounding carry reaches the aggregate export through the calls it
  shares with the terminal.** The export prints total time and peak memory
  through the terminal's own calls (`features/503-yaml-aggregate-export.md`
  D19), so the carry D19 gives this issue reaches the export too. Asked whether
  it should, the architect: "yes". A total time or peak memory at a unit
  boundary changes in the export as it does on the terminal (59,960 ms reads
  `1 min`, not `60 sec`). 503 D19's rule that these fields print what the
  terminal prints stands; D13's "the output of the aggregate export is
  unchanged" reads "unchanged except through the carry". Locked by the
  architect 2026-09-28.
- **D21 — A user-defined rate follows the mechanism `--rate-unit` applies to the
  message and error rates, in the CSVs as on every surface.** The architect:
  "interesting, yes, have the UDM rates follow the mechanism applied by the
  --rate-unit as in the message and error rates." A user-defined rate metric's
  CSV columns belong to the rate family, resolved from the metric by the kind
  resolver (D15), never guessed from the column name's suffix; their cells carry
  the one decimal the built-in rate columns carry in the default precision mode
  (under `--csv-precision full` or a decimal count, that mode decides, as it
  does for the built-in rate columns); their unit and heading suffix follow
  `-ru`. A user-defined rate of 0.3 per second prints `0.3` where it prints `0`
  today (correction 15). These rate cells are the only CSV cells this issue
  changes, and the change is accepted. Locked by the architect 2026-09-28.
- **D22 — The tool's own timings render by the one rule, their unit chosen
  relative to their magnitude.** The architect: "these, as all the others, and
  relative to their magnitude." The summary stage timings and total time, and
  the aggregate export's total time and population duration, are not exempt:
  they go through the dispatch like every other value, the unit chosen by the
  climb from their magnitude, the decimals by their budget row, the strip and
  the carry applied. No source unit is stated for them (their input unit is how
  the tool stores the clock, not a unit a log or a metric states), so they have
  no floor and D16 does not bind them. Locked by the architect 2026-09-28.

### Locked 2026-10-04 (drop 2, the walk measured on the goldens)

- **D23 — A surface names its intent, and each intent maps to a tolerance.**
  Width says how much space a value has; intent says how far the rendered
  value may stray from the stored one, which is what decides between a digit,
  the space before the unit and the length of the unit. The architect: "there
  is also an intended use aspect of this. If its a log message giving an
  approximation, then 2 thousand would perhaps be better ... in the many column
  scenarios, the readability would be typically most important ... depending on
  what number is displayed, precision could be more important than readability,
  as 2.6k tells a very different story than 3k does." Asked whether the intent
  is a tolerance the caller passes or a named intent: "named intents, each
  mapping to a tolerance". The caller sets the intent (a budget row names it; a
  surface that passes a width names it beside the width). The walk takes the
  most readable spelling (long before medium before short, loose before tight)
  whose rounding error stays within the intent's tolerance for every value the
  surface shows; the tier's maximum decimals stays the ceiling (D12) and the
  column-wide resolution stays (D10). Amends D1 and D11, whose fixed order
  (decimals give way first, the space second, the tier last) gave up a
  significant digit on 216 rendered values of the regression goldens. The
  intents, their tolerances and each surface's intent were locked below.
  **Refined by the architect (2026-10-04):** "it's the producer who is setting
  the number of significant digits. The intent is only providing preference
  mechanism for the width formatting and algorithm adaption to the various
  parts of that given the use. Hence, this is something that the producer would
  also need to provide." The digits stay where § 5 puts them (a precision a
  record locks for the surface, else the tier's maximum, never finer than the
  source's resolution, then fewer to fit the width); the producer also names
  the intent, which adds no digit count and only orders the choices among
  spellings. An intent for a notice is human-readable prose (the full word,
  `2 thousand`), not an approximation: "the intent is not for the value to be
  approximate the intent is it for it to be human readable prose".
  **Names locked by the architect (2026-10-04):** `prose` (a number inside a
  sentence: the full word, digits given up within its tolerance even when there
  is room), `tabular` (a column of values read against each other: the longer
  unit and the space, a digit given up only within its tolerance) and `precise`
  (a value read on its own terms). `precise` is a preference, not an absolute:
  the space gives way first, then the unit shortens (long, medium, short), and
  only when the value still does not fit at the short tier with no space do the
  decimals give way. The unit is never cut (D10). The architect: "If you meant
  that the preference is to not give up digits in general, then this logic
  holds."
  **The tolerance's meaning, accepted by the architect (2026-10-04):** the
  reference is the most exact spelling that fits the width (the producer's
  digits, at the shortest tier and tightest fit); a loss the width forces is in
  the reference and is never limited by the tolerance. The tolerance prices only
  a voluntary trade: where a more readable spelling (the space, a longer unit)
  also fits once a digit is dropped, it is taken if the value moves from the
  reference by no more than the intent's tolerance. 2,640 with room for five
  characters: the reference `2.6k`; `3 k` fits but moves the value 15%. 12.17 min
  with room for six: the reference `12.2m`; `12 min` moves it 1.6%.
  **Tolerances locked by the architect (2026-10-04):** `precise` 0 (no
  voluntary trade), `tabular` 5%, `prose` 25%, each the most a voluntary trade
  may move a value from the reference.
  **Surface intents locked by the architect (2026-10-04):** `tabular` for the
  timeline value columns (duration, bytes, count, user-defined, sessions, users,
  thread pools), the success and failure count cells and the messages-table
  total; `prose` for the notice counts that report a scale (the *notice* row of
  § Notices); `precise` for the legend totals and rates, the chart labels, the
  progress line, the summary timings and memory, the `_nice` CSV cells and the
  aggregate export (unchanged output); no intent for the cells whose tier and
  fit are named and whose decimals only the width removes (latency, CV, axis
  tick, dimensions line) and for the exact counts (*exact count*, *notice
  exact*). With room, `tabular` keeps the digit (9.7 min stays `9.7 min`); it
  trades one only when the exact spelling does not fit the more readable tier.
  The architect: "make sure that we'll have an easy way to change these in the
  future, as we'll certainly have to tune some of them": every surface's intent
  is a field of its budget table row (the width-passing surfaces have rows of
  their own) and the tolerances are one table beside it, so a retune edits one
  line and no call site.
  **The order of what gives way, per intent (architect, 2026-10-04):** for
  `tabular`, "Tabular should first give up on the unit name. And then some of
  the decimal precision, but not all of it. This is where I think your
  tolerance notion comes in. And then the space. And then more decimals of
  precision." So an intent is its tolerance and its own order: `tabular` keeps
  the reference's digits and the space while the unit shortens (long, medium,
  short); then gives up decimals within 5%, still loose at the short tier; then
  the space; then the decimals the width forces. With room for `16.8 kB` a
  bytes column keeps it rather than `17 kilobytes`; 12.17 min with six
  characters reads `12.2 m`, with five `12 m`. `precise` keeps its order
  (within each tier the space before the unit shortens; digits last), `prose`
  its preference for the full word with the fewest digits within 25%. Each
  intent's tolerance and order are one entry of one table.

- **D24 — The per-tier maximum decimals: short 1, medium 1, long 2, for every
  kind** (locked by the architect 2026-10-04: "Yeah, sounds good"). The values
  proposed in § Decimals, measured on the goldens before the lock: 39 count
  values in the timeline count column at the medium tier go from two decimals
  to one (`1.68 k` reads `1.7 k`); every fixed surface reads as today. A
  producer whose budget row fixes its own precision keeps it (D13).

- **D25 — Not climbing is a candidate of the walk, for every kind, up to five
  digits** (locked by the architect 2026-10-04: "yes, every kind, with a
  five-digit limit"). The tiers only spelled a value at the largest step it
  reaches; under 10,000 the plain number is often shorter, exact and easier to
  read. The architect: "moving the decimal and adding the long thousand
  description is actually more complicated to read and less precise". A
  surface that walks (its row names no tier) also considers the value at its
  floor step, unclimbed (`1800`, `12345`, `1800 B`), and takes it when it shows
  the value's most exact spelling, its integer part has at most five digits, it
  fits, and it is no wider than the spelling the intent's walk chose. 1,800 in
  a notice reads `1800`, not `2 thousand`; 1,234,567 stays `1.2M`; 1,800 ms
  stays `1.8 s` (`1800ms` is wider). Rows that name their tier (the legend,
  the chart labels, the fixed cells) keep it.

### Governing decisions in other records, read and in force

`features/501-legend-category-total-shortening.md` D1 (the tier is a parameter
of the count formatter, in the position the duration formatter uses), D2 (three
tiers: `1.2M`, `1.2Mil`, `1.2 million`), D3 (every call names its tier), D4
(`-pv` reaches the legend's totals only), D5 (the strip runs on the number before
the unit); `features/444-access-log-format-family-and-user-surface.md` R17 and
D16 (a zero total in the source unit); `docs/percentage-presentation.md` (one
percentage formatter, per-surface parameters, degrades to fit, no trailing zero);
`features/448-category-summary-share-and-bar.md` N1 (the percentage formatter's
signature); `features/503-yaml-aggregate-export.md` D13 (the population duration
at three significant digits, trailing zeros stripped) and D19 (total time and
peak memory as the terminal prints them, same calls);
`features/524-bucket-size-unit.md` D1 (one time-unit ladder, no private unit
tables); `features/column-layout-refactor.md` (widths come from the layout; no
line exceeds the terminal width); `features/608-byte-unit-ladder.md` (committed
on branch `608-byte-unit-ladder`, not yet on `release/0.19.0`) D7 (one byte
notation per run), D16 (the climb), D18 (the step's decimals field), D19 (bytes
a tiered kind); `features/273-store-precise-duration-totals.md` (a draft in the
`273-store-precise-duration-totals` worktree, not yet committed; the
messages-table total and `duration_nice` formatted at the emit sites).

---

## 5. Design

D1 to D22 settle the shape. What remains **proposed** is implementation detail
the architect did not decide: names, the budget rows' values beyond those a
record fixes, the per-tier decimal maxima's values, the long-tier byte spellings
and the per-notice budget choices. Each carries the label where it appears.

### Vocabulary

| Term | Meaning here |
|---|---|
| kind | what a value measures: duration, bytes, count, a unitless user-defined number, a rate, the coefficient of variation, a percentage |
| tier | how far the number is abbreviated: short, medium, long (`features/501-legend-category-total-shortening.md` D2). Not the precision tier 1 to 9 of `--data-model-precision` |
| fit | the space before the unit: loose (`1.5 k`) or tight (`1.5k`) |
| decimals | digits after the point, up to the tier's maximum |
| width | the characters a surface gives the value |
| budget | a named row of the budget table: tier, fit, a fixed width where the surface has one, a precision where a locked record fixes one |
| floor | the smallest unit a value may render in: the source's resolved unit, or a user-defined metric's declared unit (D16) |

### The shape

- **One dispatch** takes a kind, a value in the kind's canonical unit (with its
  input unit where the caller holds another, as the summary's elapsed seconds
  do), the floor unit where the kind has one, and either a width or a budget
  name. It returns the rendered string, or an empty string for an undefined
  value (D4's absent value). No surface calls anything else to render a number
  (D2, D13).
- **One kind resolver, called by the dispatch, resolves every metric's kind**
  (D15): a built-in metric from #613's built-in metric table, family column; a
  user-defined metric from its unit type and aggregation, a counting rate or
  distinct rate resolving to the rate kind, with its declared unit as the floor.
  The heatmap's and the histogram's user-defined branches fold into the
  resolver: the separate code goes (D15, which amends D7), the user-defined
  kinds they serve render through the dispatch in their own units (D15).
- **The per-kind formatters are the dispatch's internal arms**: `format_time`,
  `format_bytes`, `format_number`, `format_cv_display`, `format_percentage`.
  They keep the parameter shape `features/501-legend-category-total-shortening.md`
  D1 locked (value, input scale where there is one, tier, space, decimals) and
  are called by the dispatch only (D13). D1's "never passes decimals or spacing"
  binds the surfaces; 501 D3's "every call names its tier" is met by the budget
  row or the resolved tier.
  `format_duration` stays as the latency arm's rounding step to the source's
  resolution (#608 D18) and is called only by the dispatch;
  `format_duration_total`'s zero rule moves into the dispatch's floor handling
  and the sub goes; `format_heatmap_value` goes, its callers naming the *chart
  label* or *dimensions line* row.
- **The budget table at file scope** holds one row per fixed surface (D13). It
  follows the shape of `%TIER_BPD` (`docs/architecture-patterns.md` § Precision
  tiers: one table per surface). The percentage surfaces' parameters in
  `docs/percentage-presentation.md` § The surfaces (mode, digits, width, floor,
  parentheses, padding) are rows of the same table, so their callers pass only
  the row name and their output is unchanged.
- **The kinds table** holds, per kind, its unit vocabulary per tier (read from
  the time-unit ladder, the number ladder and #608's byte ladder, never a
  private copy) and the one set of per-tier decimal maxima (D12).

### The budget table

Rows and their values are **proposed** except where the *Fixed by* column names
a lock or a record; every row reproduces what its surface prints today, except
where the *Changes* column says otherwise.

| Row (proposed name) | Surfaces | Tier | Fit | Width | Precision | Fixed by | Changes |
|---|---|---|---|---|---|---|---|
| latency cell | timeline P50, P95, P99, P99.9; messages-table Min, P50, P99.9 (**proposed**: the messages-table duration cells name the latency row) | short | tight | the cell's own width | decimals by the width, up to the tier's maximum | D9 | the rounding carry at a unit boundary (D19); otherwise as today: `P50:99ms`, `P50:500ns` under `-du ns` |
| CV cell | timeline and messages-table CV | long (a unitless kind: the tier sets only the decimals ceiling) | none | 4 | decimals by the width | D9 | the strip (D3): `0.5`, `3`, `0` |
| axis tick | histogram y-axis count ticks | medium | tight | the y-axis label field | decimals by the width | D9 | `1.2k` where `1k` today (correction 6) |
| chart label | heatmap header and footer, histogram x-axis labels, percentile legend | duration short, count and unitless medium, bytes short | duration, count, unitless tight; bytes loose | none | the tier's maximum | D9 | the floor (D16) and the zero rule (D4) |
| dimensions line | the `-V` display-dimensions lines of `histogram-array` and `histogram-bin-counters` | as the chart label | tight for every kind | none | the tier's maximum | the seam with `validate-histogram-bin-counters` | a bytes line loses its space (`min=16.8kB`; `min=16.4KiB` under `-bn iec`) |
| legend total | legend category totals | short | tight | none | the tier's maximum; exact under `-pv` | 501 D2 and D4, D17 | none |
| legend rate | legend rates and the legend's width pass | medium | tight | none | the tier's maximum | 501 D2 | none |
| progress | progress line counts and rate | medium | tight | none | the tier's maximum | | none |
| notice | a notice count where scale is the point | medium | tight | none | the tier's maximum | D6, D14 | the four inline sites (§ Notices) |
| notice exact | a notice count where precision is the point | none | none | none | exact integer | D14 | § Notices |
| exact count | messages and thread-pool tables' occurrences; summary counts and category rows | none | none | none | exact integer | D5 | none |
| summary timing | summary stage timings and total time; aggregate export total time | medium | loose | none | the tier's maximum; no floor | 503 D19, D22 | the rounding carry at a unit boundary (D19; on the export, D20) |
| summary memory | summary peak memory; aggregate export peak memory | medium | loose | none | the tier's maximum | 503 D19 | #608's notation and the rounding carry at a unit boundary (D19; on the export, D20) |
| memory breakdown | `-mem` breakdown rows | medium | loose | none | whole units | | #608's notation and the rounding carry at a unit boundary (D19) |
| export duration | aggregate export population duration | long | loose | none | three significant digits; no floor | 503 D13, D22 | the rounding carry at a unit boundary (D22) |
| nice cell | STATS `duration_nice` and `bytes_nice`; MESSAGES `duration_nice` and `bytes_nice` | medium | loose | none | the tier's maximum | D18 (the CSV keeps a fixed budget) | #608's notation and the rounding carry at a unit boundary (D19) |
| CSV cell | every numeric STATS and MESSAGES cell, the rate columns included | none | none | none | the run's `--csv-precision` per family, through `format_csv_value` | audit § Item 2, sites closed as deliberate; D21 for the rate columns | the user-defined rate cells, which join the rate family (D21, § The rate arm) |
| percentage rows | category share and classified rows; success/failure columns; progress percentage; memory breakdown percentage; histogram percent ticks and the `0%` corner; the notice share | the parameters of `docs/percentage-presentation.md` § The surfaces, one row each; the ticks integer, width 3; the notice share three significant digits | | | | D13, the percentage convention | none, except the notice share, which the formatter reaches for the first time under D6: `(100.0%)` reads `(100%)` (the ticks move to the formatter byte-identical, correction 11) |

A new surface adds a row or passes a width; it never calls an arm.

### The resolution walk for a surface that passes a width

Only the timeline's proportional cells (the duration, bytes, count,
user-defined, sessions, users and thread-pool columns), its value-only cells
(the success and failure columns' count fallback) and the messages-table total
(D18) pass a width (D9). The rule walks the (tier, fit) steps in D11's order and
takes the first step at which the value fits the width with no decimals; it then
gives that step the most decimals, up to the tier's maximum, that still fit.
Decimals give way first, the space second, the tier last (D1, D11).

| Step | Tier | Fit | Example, 1234 ms |
|---|---|---|---|
| 1 | long | loose | `1.23 seconds` |
| 2 | medium | loose | `1.2 sec` |
| 3 | medium | tight | `1.2sec` |
| 4 | short | loose | `1.2 s` |
| 5 | short | tight | `1.2s` |

The long tier has no tight step (D11). A value that does not fit at step 5 with
no decimals is never cut (D10): on the timeline the layout's minimum column
width holds the widest value at step 5, and below it the column auto-hides; a
fixed-budget surface sizes its budget for its widest value. The former clipping
guards remain only as an assertion that this holds.

For a timeline column the walk resolves the tier and fit **once per column**,
against the widest value the column will show, and the decimals per value (D10).
The column's values are known when `normalize_data_for_output` scales them,
before the first row renders. The messages-table total resolves the same way
against its own column (D18).

### Decimals: the common maxima, the ceiling, the carry

**One set of per-tier maxima for every kind** (D12). The values are
**proposed**:

Locked as D24.

| Tier | Maximum decimals | Why |
|---|---|---|
| short | 1 | the tier chosen when space is least; the latency cells' one-decimal contract, which the duration-display harness enforces, is this row applied to a short-tier budget |
| medium | 1 | what the legend rates, the chart labels, the progress line, the notices, the summary timings and the `_nice` cells print today |
| long | 2 | the walk reaches the long tier only when the column is widest, which is when the width affords precision |

Under this set the timeline's two decimals and the heatmap's one are outcomes of
the one rule, as D12 requires: a count of 1140 reads `1.14 thousand` in a
column wide enough for the long tier, `1.1 k` in one that resolves medium, and
`1.1k` on the heatmap header, whose budget is medium tight. A unitless kind with
no ladder (the coefficient of variation) takes the ceiling of the tier its
budget names. Percentages keep their own parameters (the percentage rows).

**The ceiling from the source's resolution** (D19). The rule reads the ladder
step's decimals field (`features/608-byte-unit-ladder.md` D18: `ns` 6, `us` 3,
`ms` and every longer token 0, as the rounding precision relative to the
millisecond storage unit) for the floor step. A value is rounded to that
resolution first, and a rendered digit is never finer than it: a millisecond
source shows no decimals at the millisecond step (`58ms`, never `58.2ms`), and
`1.2 s` keeps its decimal because a tenth of a second is coarser than a
millisecond. The tier's maximum and the width then bound what is left.

**The rounding carry** (D19). The climb chooses a step from the raw value
(#608 D16); if rounding at the chosen decimals reaches the next step's
multiplier, the value renders at the next step: 999,999 bytes reads `1 MB`, not
`1000 kB`, and a count of 999,960 reads `1 Mil`, not `1000 k`. The carry is the
one rule, so it applies to every kind with a ladder (D12): 59,960 ms reads
`1 min`, not `60 sec`.

### The floor and the zero rule (D4, D16)

The duration and byte arms never render a value in a unit smaller than the
floor: the source's resolved unit for the built-in duration and bytes, the
declared unit for a user-defined metric. The climb starts at the floor step, not
at the ladder's lowest step (correction 16). A value of exactly zero renders at
the floor, at the tier and fit the walk or the budget chose (`0ms`, `0 msec`,
`0 milliseconds`; `0s` for a seconds-declared user-defined metric), on every
surface: the timeline, the heatmap header, the histogram labels, the
display-dimensions `-V` lines. A seconds-declared metric's 0.25 reads `0.3s` (the
tier's maximum; the resolution allows it), never `250ms`. An undefined value
renders empty; a zero-initialised field that should be undefined is #616's to
fix.

The tool's own measurements (the summary stage timings and total time, the
aggregate export's total time and population duration) go through the rule like
every other value, the unit chosen relative to their magnitude (D22). They have
no floor, because no source unit is stated for them: their input unit is how the
tool stores the clock, not a unit a log or a metric states. Under the medium
tier's proposed maximum of one decimal they render as today apart from the carry
at a unit boundary (D20, D22). No regression golden moves for them: the goldens
strip timings and memory as nondeterministic, and `validate-aggregate-export`
asserts the population duration at no unit boundary (`4 days`, `9 seconds`).

### Bytes as a tiered kind (D19)

The byte arm reads #608's ladder: the steps, the value climb, the token per
notation. The tokens alone give one spelling per step, so the tiers are
**proposed** as: short and medium, the step's token (`kB` under SI, `KiB` under
IEC); long, the unit's word (`kilobytes`, `kibibytes`, `megabytes`, `mebibytes`,
up to `terabytes` and `tebibytes`, and `bytes` for the byte step), added as a
field of the same ladder step per notation so the byte vocabulary stays in
#608's one table. Tier, fit and decimals for bytes are this issue's; the ladder,
the climb and the notation are #608's.

### The rate arm (D15, D21)

A rate is a count per rate unit. Its kind resolves in the one resolver, from the
built-in `err-rate` and `msg-rate` columns and from a user-defined `rate` or
`drate` aggregation. It is reached from two surfaces:

- **The timeline.** The rate suffix (`%rate_suffix`, `/` and the rate unit's
  short spelling) is part of the rate kind's unit and counts against the
  column's width; the number walks as a count.
- **The CSV output** (D21). A user-defined rate follows the mechanism
  `--rate-unit` applies to the message and error rates: its columns belong to
  the rate family, resolved from the metric by the kind resolver, not guessed
  from the column name's suffix by `resolve_csv_column_family`, and its unit
  and heading suffix follow `-ru`. The sites: the STATS CSV header built in the
  main flow (the `err-rate` and `msg-rate` headings take `%rate_csv_suffix`),
  the user-defined rate columns' headings in `udm_csv_columns`, and their cells,
  written by `print_bar_graph`'s CSV builder and by `print_message_summary`
  through `format_csv_value`. The heading suffix comes from the rate kind's unit
  (the rate unit's medium spelling), the cell from the *CSV cell* row. The
  built-in rate headings and cells are unchanged.
- **The rate cells** (D21). The rate kind's *CSV cell* row carries the one
  decimal the built-in rate columns carry in the default precision mode, for
  every rate column, so a user-defined rate of 0.3 per second prints `0.3` where
  it prints `0` today (correction 15). These are the only CSV cells this issue
  changes, and the change is accepted (D21); under `--csv-precision full` or a
  decimal count, that mode decides as it does for the built-in rate columns.

The heatmap refuses counting aggregations, so the rate arm is not reached from
the charts.

### Surfaces and sites

| Surface | Site today | After | Decision |
|---|---|---|---|
| Timeline duration, bytes, count, user-defined, sessions, users and thread-pool columns | `print_bar_graph` :: `my $time_format = $col_w >= 15 ? 'long' : ($col_w >= 10 ? 'medium' : 'short');`, `my $fmt = $col_w >= 15 ...`, `format_number( $log_stats{$bucket}{$key}, 'medium', ' ', 2)`, `format_bytes( $log_stats{$bucket}{$key}, 'B' )`, `my $decimals = $col_w > 10 ? 2 : ...`, the rate suffix `$trend_value .= $rate_suffix{$rate_unit}` | the dispatch with the column's width less the leading space; tier and fit per column, decimals per value; the rate suffix part of the rate kind's unit | D1, D2, D8, D10, D11, D12, D15 |
| Timeline value-only cells (the success and failure columns' count fallback) | `print_bar_graph` :: `: format_number( $cell_count, 'medium' );` then `substr` | the dispatch with the cell width | D1, D2, D9 |
| Timeline latency cells and messages-table Min, P50, P99.9 | `format_duration( $log_stats{$bucket}{p50}, 6 )`; `format_duration( $min, $col_width{3} )` | the *latency cell* budget | D9 |
| CV cells, timeline and messages table | `format_cv_display` :: `return sprintf('%.2f', $cv);` | the *CV cell* budget; the strip applies | D3, D8, D9 |
| Heatmap header and footer, histogram x-axis labels, percentile legend | `format_heatmap_value` (seven callers) | the *chart label* budget; the floor and the zero rule apply; the user-defined branches fold into the resolver | D2, D4, D9, D15, D16 |
| Histogram y-axis count ticks | `render_histogram_row` :: `format_number($count_val, 'medium', undef, 0)` | the *axis tick* budget | D1, D8, D9 |
| Histogram percent ticks and the `0%` corner | `sprintf(" %3d%%", $pct_val)`; `sprintf(" %3d%%", 0)` | the percentage formatter through its row: integer, width 3; byte-identical | `docs/percentage-presentation.md` migration table, D13 |
| Histogram display-dimensions `-V` lines | `format_histogram_dimensions_line` :: `format_heatmap_value($stats->{min}, $metric)` | the *dimensions line* budget, tight for every kind | D4, D16, the seam with `validate-histogram-bin-counters` |
| Legend category totals and rates; the legend width pass | `legend_category_total`; `format_number( $occurrences, 'medium' )` in `print_bar_graph` and `normalize_data_for_output` | the *legend total* and *legend rate* budgets; both passes name the same row | D5, D17, 501 D2 and D4 |
| Messages and thread-pool tables' occurrences; summary counts and category rows | `sprintf( "%$col_width{2}s", $occurrences )`; `sprintf( $table_format, "LINES READ", $total_lines_read )`; `share_row_text` | the *exact count* row; unchanged | D5 |
| Messages-table total duration | today `calculate_all_statistics` :: `format_duration_total( ..., 'medium', 'space' )` stored as a string; after #273, its emit site in `print_message_summary` | the dispatch with the total column's width, at #273's emit site | D18 |
| MESSAGES CSV `duration_nice`; STATS CSV `duration_nice`, `bytes_nice`; MESSAGES `bytes_nice` | #273's emit site; `print_bar_graph`'s CSV builder :: `ltrim(format_duration_total(..., 'medium', ' '))`, `format_bytes(..., 'B')` | the *nice cell* budget; unchanged apart from #608's notation and the rounding carry (D19) | D18 |
| Summary stage timings, total time, peak memory, memory breakdown; aggregate export total time and peak memory | `format_time( $elapsed_..., 's', 'medium', " " )`; `format_bytes( $max_memory_usage, 'B' )`; `format_bytes( $size, 'B', 0 )` | the *summary timing*, *summary memory* and *memory breakdown* budgets; the export names the same rows, so 503 D19's same calls hold by construction and the carry reaches the export | D13, D20, D22, 503 D19 |
| Aggregate export population duration | `format_time($span, 's', 'long', ' ', 3)` | the *export duration* budget | D13, D22, 503 D13 |
| Progress line counts and rate | `progress_line_text` :: `format_number( $line_number // 0, 'medium' )` | the *progress* budget; unchanged | D13 |
| Notices | every notice site of § Notices | each names its own row | D6, D14 |
| STATS and MESSAGES numeric cells, rate columns included; `-V` sections; the aggregate export's exact values; the run index | `format_csv_value`, raw `sprintf` | the *CSV cell* row through `format_csv_value`, which calls the strip helper for its own strip, output byte-identical apart from the user-defined rate cells (D21) | D3, D15, D21 |

What goes: the five dispatch copies, the two width-to-tier copies, the
width-to-decimals rule, `format_duration`'s one-digit shed,
`format_percentage`'s decimals loop and `format_cv_display`'s magnitude branches
as separate mechanisms (the walk is the one rule, D8), the three clipping guards
as the way a value is fitted (they remain only as the assertion that a value
never exceeds its width), the heatmap's two user-defined branches as separate
code, folded into the resolver (D15, which amends D7), the name-based rate
override in `format_csv_value` (the rate kind carries it), and the unused
`normalize`.

### The strip helper (D3)

One helper removes zeros at the right-hand end of the decimals, and the point
with the last of them, from the number before the unit is appended (the order
501 D5 set). Every arm calls it after its decimals are chosen, and so does
`format_csv_value`, whose output stays byte-identical (it already strips).
Digits that are not trailing stay (`0.034`). The CV cell passes through it
inside its budget: `0.50` reads `0.5`, `3.00` reads `3`, `0.00` reads `0`.

The seam in `format_csv_value`: this issue adds the helper call; #608 replaces
the CSV decimals table with the ladder step's field; #616 adds a decimals
override. Whichever lands later rebases the others' lines; none changes another's
output.

### Notices (D6, D14)

Every measured count a notice prints goes through the dispatch, and every
percentage through the percentage formatter. Each notice names its row by what
it exposes and why; the choices are **proposed**:

| Notice | What it exposes, and why the reader reads it | Numbers and their row |
|---|---|---|
| Unclassified-lines warning (`emit_classification_percentage_notices`) | the size of a coverage gap in a format's classification patterns: its scale says whether to investigate | the count, *notice*; the share, the notice share row (three significant digits): `1.2k included line(s) (100%)` |
| CSV-skip warning (`read_and_process_logs`) | gone: #640 (unplaced CSV rows are silent) removed the warning before implementation; nothing to render | none |
| CSV header without a user-defined metric's column (`emit_udm_csv_unbound_notices`, added by #640 after this specification) | how many CSV files lacked the column a `-udm` metric names, never their names | the file count, *notice* |
| Final consolidation pass skipped (`report_skipped_final_pass`) | how much data a skipped pass would have grouped, to judge the trade the tool made | the message count, *notice*; the `--group-similar` threshold echoed and the cliff-edge similarity offered as a value to type into `--group-similar`, both verbatim |
| Unregistered levels (the level-rejection note) | which level tokens were dropped and how many lines each cost, so a reader tells a rounding error from a loss that matters | the number of levels, which precedes their list, *notice exact*; the per-level and total line counts, *notice* (unchanged) |
| Numeric-filter note | how many lines a numeric filter removed for carrying no value, to explain a shrunken total | *notice* (unchanged) |
| Unreadable directories | how many directories a recursive sweep skipped, followed by their names | *notice exact*: the count agrees with the list; it differs from today only at 1,000 directories or more |
| Bin consolidation note (`bin_consolidation_notice`) | how many message histograms were combined, the scale of the approximation | *notice* (unchanged) |

Line numbers, option operands the user typed, file names and settings echoed
back (`-g 85`, a similarity threshold) are identifiers or echoes, not
measurements, and stay verbatim (D14). A notice added later names its row the
same way; any notice found at implementation that prints a measured number and
is not in this table is added to it in the same drop.

### Boundaries with other issues

| Issue | It owns | This issue owns |
|---|---|---|
| #608 (byte ladder, output notation) | the byte ladder's steps and tokens per notation, the value-based climb, SI or IEC per run, the ladder step's decimals field | the byte arm's tier, fit and decimals; the long-tier byte spellings, added to #608's ladder step; the rounding carry (D19). #617 is blocked by #608 (recorded) |
| #273 (store the precise total duration) | moving the messages-table total and `duration_nice` from a stored string to the emit sites | the width the table total passes and the budget the CSV cell names (D18). #617 is blocked by #273 (Deliver stage) |
| #616 (gated means, empty cell for no observation) | making an unobserved value undefined; the decimals override in `format_csv_value` | rendering undefined as empty; the strip call in `format_csv_value`. #617 is blocked by #616 (Deliver stage) |
| #613 (one table of built-in metrics) | the built-in metric table and its family column; the heatmap value formatter's built-in chain rewritten to read it | the kind resolver, which routes the family through the dispatch. #617 is blocked by #613 (recorded) |
| #514 (count metric explicit) | which count surfaces exist | the count arm they call |
| #618 (one declaration per CSV column) | the per-column declaration the STATS and MESSAGES writers, the aggregate export and the run index read | a user-defined rate's columns in the rate family under the `--rate-unit` mechanism (D21); #618's declaration reads that family from the metric, not from the column name |
| #497, #498 (rows exceed the width; headings degrade) | the widths the tables are given | how a value fills a width it is given |
| #412 (notices surface) | where notices print | how their numbers render, and each notice's row |
| #525 (one timestamp formatter) | timestamps | nothing: timestamps are not a metric kind here |

Regression goldens are re-captured on the tree #608 and #616 leave, in the
sequence #608, #616, then this issue.

### User surface changes

- **Options, `--help` rows, `docs/usage.md` rows, deprecations:** none.
- **Rendered strings that change:**

| Class | Before | After | Licensed by |
|---|---|---|---|
| trailing zero in a count, user-defined number or CV | `1.50 k`, `1.30 Mil`, `CV:3.00`, `0.50` | `1.5 k`, `1.3 Mil`, `CV:3`, `0.5` | D3 |
| decimals of a timeline value | `1.14 k` at every width | `1.14 thousand` where the column resolves the long tier, `1.1 k` where it resolves medium | D1, D12 |
| value cut by its column | `999 millisecon`, `16.4 K`, `864.7` | `999 msec` or a shorter tier, `16.8 kB` (SI, the default for an access log; `16.4 KiB` under `-bn iec`) or a shorter tier, the whole value | D1, D8, D10, `features/column-layout-refactor.md` (no value exceeds its space) |
| tier and fit re-resolved per column | the width thresholds 15 and 10 | the walk, once per column | D1, D10, D11 |
| long-tier bytes | no long tier | `16.8 kilobytes` (`16.4 kibibytes` under `-bn iec`) where a column resolves long | D19 |
| rounding carry | `1000 kB`, `1000 k`, `60 sec` | `1 MB`, `1 Mil`, `1 min` | D19, D12; on the aggregate export's total time and peak memory, D20; on the tool's own timings, D22 |
| zero on a chart label or a dimensions line | `0ns` | the floor unit: `0ms`, `0s` for a seconds-declared metric | D4, D16 |
| a value below its floor unit | `250ms` for a seconds-declared metric's 0.25; a sub-millisecond chart label on a millisecond source | `0.3s`; the label at the source's resolution in milliseconds | D16 |
| histogram y-axis tick | `1k` above `866` | `1.2k` | D1, D8, D9 |
| notice numbers | `1200 included line(s) (100.0%)`, `skipped 1500 CSV rows`, `skipped over 1500 messages` | `1.2k included line(s) (100%)`, `skipped 1.5k CSV rows`, `skipped over 1.5k messages` | D6, D14 |
| unreadable-directories count at 1,000 or more | `1k directories` | `1000 directories` | D14 (exact where the count must agree with the list) |
| bytes dimensions line (`-V`) | `min=16.8 kB` (`min=16.4 KiB` under `-bn iec`) | `min=16.8kB` (`min=16.4KiB` under `-bn iec`) | the *dimensions line* budget |
| user-defined rate cell in both CSVs | `0` | `0.3` | D15, D21, correction 15 |

- **CSV cells:** the numeric cells are unchanged apart from the user-defined
  rate cells (D21). The `_nice` cells are unchanged apart from #608's notation
  and the rounding carry (D19: 999,999 bytes reads `1 MB`, not `1000 kB`).
- **`-V`:** no section, sub-section or key changes. The display-dimensions
  lines' `min=` and `max=` values read the floor unit and are tight for every
  kind.

### The pattern entry

`docs/architecture-patterns.md` gains **Width-to-format rule: one dispatch per
metric kind**: definition (one dispatch; one kind resolver; a width or a budget
row name; the walk; the common decimal maxima; the floor, the zero rule and the
carry; the strip), intended uses (any number a person reads; a new surface adds
a budget row or passes a width, never a formatter call; a notice names the row
that fits what it exposes), reasoning (the § 1 measurements), consumption sites
(the dispatch, the kind resolver, the budget table, the kinds table, one call per
surface), owning record (this document), status *established* at delivery. In
the shared status lines this issue edits only its own token: the **One
resolution surface per vocabulary** entry drops #617 from its refinement list;
the **Behavioural notices** entry's number-rendering refinement closes, as
amended by D14 (each notice names its row), and its swallowed-warning half stays
with #614. The new entry names the Precision tiers entry's one-table-per-surface
shape as its model; the Precision tiers entry is not edited.

---

## Acceptance criteria

Each is a condition and an observable outcome; *assertable* criteria name the
harness and the fixture shape. The new render-invariant harness is
`tests/validate-value-display.sh`, named for the capability as
`validate-duration-display.sh` is, since it validates no `-V` section (name
**proposed**). Every `ltl` invocation is shaped to its assertion: `-bs 1 -n 0
-ni` and `--terminal-width` pinned, everything unread switched off.

- [ ] **AC1** (D1, D2, D12). One application-log line carrying a count of 1500,
      rendered on the timeline count column, the heatmap header (`-hm count`) and
      the histogram x-axis (`-hg count`): every rendering is `1.5` followed by the
      unit of the tier and fit that surface resolved or named, and two surfaces
      at the same tier and fit print the same string. No surface prints `1.50`.
      *Assertable:* `validate-value-display`, scenario *count-spelling*,
      `--terminal-width 220`, three runs.
- [ ] **AC2** (D9). Layout-fixed cells name a budget: across `--terminal-width`
      100 to 220, one bucket's P50 to P99.9 cells print the same string at every
      width, short tier, tight, within the cell; the messages-table Min, P50 and
      P99.9 cells likewise. The latency contract stands: every duration cell
      carries a unit, a zero reads the resolved unit, at most one decimal and none
      in the source unit, and `P50:500ns` under `-du ns`.
      *Assertable:* `validate-value-display`, scenario *fixed-budget-sweep*; the
      existing assertions of `validate-duration-display` and
      `validate-bucket-size-units`, unchanged.
- [ ] **AC3** (D1, D8, D10). No value is cut: at every `--terminal-width` from
      100 to 220 in steps of 10, every proportional and value-only timeline cell
      holds a whole value, a number followed by a complete unit spelling of one
      tier of its kind, no longer than the cell; within one column every value
      carries the same tier and fit, while decimals may differ by value. The
      cell is read through the layout engine's own offsets.
      *Assertable:* `validate-value-display`, scenario *fit-sweep*,
      `timeline_cell_report` (`tests/lib/rendered-output.sh`) on `--debug-layout`
      captures, a fixture whose bucket totals span milliseconds to minutes and
      bytes to mebibytes.
- [ ] **AC4** (D11). The long tier is never tight: over every *fit-sweep*
      capture, no long-tier unit word (`milliseconds`, `seconds`, `thousand`,
      `million`, `kilobytes`) directly follows a digit; and decimals give way
      before the space: over the same captures, no column renders tight at a
      tier where the same values, with fewer decimals, fit loose at that tier
      within the cell.
      *Assertable:* scenario *fit-sweep*, the loose spelling of each tight cell
      measured against the cell width from `--debug-layout`.
- [ ] **AC5** (D12, the common maxima). No rendered value carries more decimals
      than the maximum of the tier it renders at, for every kind; a count of 1140
      reads `1.14 thousand` where its column resolves the long tier and `1.1 k` or
      `1.1k` where it resolves medium, and `1.1k` on the heatmap header.
      *Assertable:* `validate-value-display`, scenario *common-maxima*, a
      two-line application-log fixture carrying counts of 1140 and 5, at two
      terminal widths chosen to resolve long and medium, plus `-hm count`.
- [ ] **AC6** (D3). No rendered value ends in a trailing fractional zero: in
      every timeline value cell (read through the layout engine's offsets,
      `timeline_cell_report`), every latency and CV cell, every chart label, axis
      tick and dimensions-line value, and every notice number, over the captures
      of every `validate-value-display` scenario and every regression golden, no
      value matches a decimal point followed by digits ending in `0`. Timestamps
      and message text are not value cells and are not read.
      *Assertable:* `validate-value-display`, scenario *no-trailing-zero*, a
      render-invariant over the stripped text.
- [ ] **AC7** (D3, D9). Three access-log lines of one path with durations 10, 20
      and 30 ms: the timeline CV cell reads `CV:0.5`, the messages-table CV cell
      `0.5`, the MESSAGES CSV `duration_cv` cell `0.5`. Where a CV has more
      decimals than the cell affords, the cell is the CSV value rounded to the
      cell.
      *Assertable:* `validate-value-display`, scenario *cv-agreement*, `-o -bs 1`.
- [ ] **AC8** (D4, D16). Two access-log lines with a duration of zero, `-hm
      duration -bs 1`: the heatmap header's minimum and maximum read `0` followed
      by the resolved source unit, which the harness reads from `-V csv-output`
      `duration_unit_resolved`; `0ns` appears nowhere in the capture. A
      seconds-declared user-defined metric of zero reads `0s` on its heatmap
      header and its timeline column.
      *Assertable:* `validate-value-display`, scenario *zero-duration*.
- [ ] **AC9** (D16). No value renders below its floor: a seconds-declared
      user-defined metric carrying 0.25 and 2 reads in seconds (`0.3s` or its
      tier's spelling) on the timeline column, the heatmap labels and the
      display-dimensions line, never in milliseconds; on a millisecond-source
      access log, no duration on any surface reads `us` or `ns`.
      *Assertable:* `validate-value-display`, scenario *floor-unit*, the
      zero-seconds fixture with two more lines; the millisecond half over the
      *fit-sweep* captures and a `-hm duration -hg duration` run.
- [ ] **AC10** (D19, the carry). One access-log line with 999,999 bytes reads
      `1 MB` under SI (`-bn si`), never `1000 kB`; one application-log line
      carrying a count of 999,960 reads `1 Mil` (or its tier's spelling), never
      `1000 k`; a 59,960 ms duration reads `1 min`, never `60 sec`.
      *Assertable:* `validate-value-display`, scenario *boundary-carry*, three
      one-line fixtures, timeline and heatmap header.
- [ ] **AC11** (D19, the ceiling). A millisecond-source duration shown at the
      millisecond step carries no decimals on any surface, the columns that pass
      a width included; one shown at the second step carries at most the tier's
      maximum.
      *Assertable:* scenario *fit-sweep*, the same captures, the source unit read
      from `-V csv-output`.
- [ ] **AC12** (D19, bytes tiered). Across the *fit-sweep* widths the bytes
      column resolves more than one tier (the long-tier word at the widest, the
      token below), and every byte spelling is the ladder's for the run's
      notation.
      *Assertable:* scenario *fit-sweep*.
- [ ] **AC13** (D5, D17). 1,200 lines in the classification-verification shape:
      the messages table reads `1200`, the summary `LINES READ 1200`, the legend
      `1.2k`, and under `-pv` the legend reads `1200`.
      *Assertable:* `validate-value-display`, scenario *exact-counts*, fixture
      generated in the harness's scratch directory.
- [ ] **AC14** (D6, D14). Each notice renders its numbers through the row § Notices
      names: the unclassified warning reads `1.2k included line(s) (100%)`; a CSV
      input with 1,500 rows whose timestamps do not parse prints
      `skipped 1.5k CSV rows`; a skipped final consolidation pass over 1,500
      messages reads `skipped over 1.5k messages` with the threshold verbatim; the
      unregistered-levels note prints its level count exact and its line counts at
      the medium tier; a recursive sweep with 1,000 or more unreadable directories
      prints their count exact.
      *Assertable:* `validate-classification-percentages`, new scenario with
      `-lf classification_verification`; `validate-csv-input`, new scenario with
      a generated CSV; `validate-message-grouping`, the final-pass scenario
      extended to a generated input above 1,000 messages; `validate-log-level-vocabulary`,
      the unregistered-levels scenario extended to a line count above 1,000;
      `validate-recursive-file-selection`, the unreadable-directory scenario
      extended to 1,000 directories made unreadable at run time.
- [ ] **AC15** (D15, the kinds). A user-defined time metric's heatmap header and
      its timeline column render one value identically at the same tier and fit;
      a user-defined non-counting metric renders heatmap labels in its own unit;
      the per-kind formatters have one caller, the dispatch, and every call to
      the dispatch passes a width or a budget row name and no tier, fit, spacing
      or decimals argument.
      *Assertable:* `validate-value-display`, scenario *user-defined-kind*, the
      numeric-boundary application-log fixture with a maximum of its millisecond
      key; the structural half by a source count recorded in the completion
      comment.
- [ ] **AC16** (D15, D21, the rate arm). A user-defined rate on the timeline
      carries the rate suffix and walks as a count; in the STATS and MESSAGES
      CSVs the built-in rate headings and cells are byte-identical, the
      user-defined rate headings carry the rate unit's spelling, and a
      user-defined rate of 0.3 per second reads `0.3` in its cell, as
      `msg-rate_sec` does in the same row.
      *Assertable:* `validate-csv-output`, a scenario on the numeric-boundary
      application-log fixture with a user-defined rate, `-ru s -bs 1 -o -n 0`,
      reading both rate columns of the same row; `validate-value-display`,
      scenario *rate-suffix*, for the timeline.
- [ ] **AC17** (D18). The messages-table total duration fits its column at every
      `--terminal-width` from 100 to 220: a whole value, never cut, its tier
      resolved against the column's widest total; the MESSAGES CSV
      `duration_nice` cell reads the same string at every width.
      *Assertable:* `validate-value-display`, scenario *messages-total*, on the
      tree #273 leaves, a fixture of several paths whose totals span
      milliseconds to minutes, `-o`.
- [ ] **AC18** (D13, D20, D22). The fixed-budget surfaces print what they print
      today, apart from #608's notation and the rounding carry at a unit boundary
      (D19; on the aggregate export, D20; on the tool's own timings, D22); the
      budget table itself changes no output (D13): the legend, the latency
      cells, the progress line, the summary timings and memory, the memory
      breakdown, the `_nice` CSV cells, the aggregate export's total
      time, peak memory and population duration, and every percentage surface,
      the histogram percent ticks included.
      *Assertable:* the existing assertions of `validate-aggregate-export`,
      `validate-duration-display`, `validate-bucket-size-units`,
      `validate-progress-line`, `validate-summary-contribution-bar` and
      `validate-csv-output`, unchanged; and `validate-regression`, whose diff is
      classified in AC20.
- [ ] **AC19** (the dimensions line). The display-dimensions lines of
      `histogram-array` and `histogram-bin-counters` hold `min=` and `max=` values
      with no space for duration and for bytes.
      *Assertable:* `validate-histogram-bin-counters`, its dimensions-line
      pattern extended to a bytes histogram (`-hg bytes`).
- [ ] **AC20** (the audit's constraint that convergence changes documented
      behaviour only where copies already disagree). Every line that changes in a
      re-blessed regression golden, compared with the goldens as #608 and #616
      leave them, belongs to one of the classes of § Design, *User surface
      changes*; a line in no class blocks the re-bless.
      *Assertable:* a classifier run over the before and after goldens, its
      per-class counts recorded in this document at delivery.
- [ ] **AC21** (visual). The rendered output of a single-day web application
      access log carrying execution time, and of an application log carrying
      count and duration keys, at widths 100, 120, 160 and 200, with `-hm
      duration`, `-hm count` and `-hg duration,bytes`, is looked at before and
      after each drop by the architect.
      *Unassertable* by a harness: readability is a judgement; the captures are
      the evidence.
- [ ] **AC22** (D1, D8, D9, the axis tick). A duration histogram whose tallest
      bin holds 1,155 samples labels that tick `1.2k`, and no two y-axis ticks
      read the same string.
      *Assertable:* `validate-value-display`, scenario *axis-tick*,
      `-hg duration`.

Triage: twenty-one assertable, one unassertable, none unknown.

---

## Verification surface

**`-V` sections read:** `csv-output` (`duration_unit_resolved`, the expected
floor for AC2, AC8, AC9 and AC11); `--debug-layout` (the column offsets for AC3,
AC4, AC5, AC11, AC12 and AC17). **Changed:** no section or key; the
`histogram-array` and `histogram-bin-counters` display-dimensions lines keep
their keys and read the floor unit, tight for every kind (D16, AC19).
`tests/HARNESS-DESIGN.md` is read before the dimensions-line assertion is
extended.

**Harnesses whose assertions or goldens move, and why the contract supports the
new value:**

| Harness | What moves | Contract that supports it |
|---|---|---|
| `validate-regression` | 11 goldens' CV cells, 21 goldens' two-decimal counts, 21 goldens' cut values, 4 goldens' y-axis ticks, every golden whose timeline column re-resolves its tier, and any chart label below its floor; no golden for the tool's own timings, which the goldens strip as nondeterministic (D22) | D1, D3, D8, D10, D12, D16; the copies already disagreed (§ 1); `features/column-layout-refactor.md` (no value exceeds its space) |
| `validate-duration-display` | its checker's messages-table row anchor, `my $cv_shaped = qr/^[0-9]+\.[0-9]+$/;`, requires a decimal point in the CV cell; a stripped CV (`3`, `0`) must still anchor; its three `produced_by` declarations name the dispatch's *latency cell* budget in place of `format_duration()` | D3 |
| `validate-histogram-bin-counters` | the dimensions-line pattern extended to bytes | the *dimensions line* budget |
| `validate-classification-percentages` | a scenario for the non-zero leakage warning, recorded today as unproducible | D6, D14; correction 10 |
| `validate-csv-input` | a scenario for the skip-count warning's number | D6, D14 |
| `validate-message-grouping` | the final-pass notice's count above 1,000 | D14 |
| `validate-log-level-vocabulary` | the unregistered-levels note's counts above 1,000 | D14 |
| `validate-recursive-file-selection` | the unreadable-directories count at 1,000, exact | D14 |
| `validate-byte-units` | the boundary-carry assertion #608 left pointing here: 999,999 bytes under `-bn si` reads `1 MB`, not `1000 kB`; its contract re-pointed to D19 | D19; #608's hand-forward of the carry |
| `validate-csv-output` | a scenario for the rate columns of both CSVs | D15 |
| `validate-value-display` (new) | AC1 to AC13, AC15 to AC17, AC22 | D1 to D5, D8 to D13, D15 to D19 |

Harnesses expected not to move, run whole at the gate:
`validate-histogram-ticks` (reads the `-V` tick inputs, not the labels),
`validate-aggregate-export` (503 D13 and D19; no assertion reads a value at a
unit boundary, so the carry of D20 and D22 does not reach them),
`validate-bucket-size-units` (`P50:500ns` in the latency budget),
`validate-summary-contribution-bar`, `validate-progress-line`,
`validate-statistics-demand`, `validate-category-names`.

**Fixtures** (committed as `.txt`; each the smallest that carries its signal):

| Fixture | Shape |
|---|---|
| `tests/fixtures/value-display-count-1500.txt` | one application-log line in the key=value shape, count 1500 |
| `tests/fixtures/value-display-count-1140.txt` | two application-log lines, counts 1140 and 5 |
| `tests/fixtures/value-display-zero-duration.txt` | two access-log lines, one path, duration zero |
| `tests/fixtures/value-display-cv-half.txt` | three access-log lines of one path, durations 10, 20 and 30 ms |
| `tests/fixtures/value-display-seconds-udm.txt` | four application-log lines carrying a key read as a seconds-declared user-defined metric, values 0, 0, 0.25 and 2 |
| `tests/fixtures/value-display-fit.txt` | access-log lines, one per bucket, whose totals render in milliseconds, seconds and minutes and in bytes, kilobytes and megabytes |
| `tests/fixtures/value-display-carry.txt` | three lines: an access-log line of 999,999 bytes, an access-log line of 59,960 ms, an application-log line carrying a count of 999,960 |
| `tests/fixtures/value-display-messages-total.txt` | access-log lines of several paths whose per-path totals span milliseconds to minutes |
| generated in the harness scratch directory | 1,200 lines in the classification-verification shape; a CSV input with 1,500 unparseable timestamps; inputs above 1,000 messages and 1,000 unregistered-level lines |

Any file a harness or a check makes `ltl` write (the CSVs, the aggregate
export, the run index) is written into the harness's scratch directory, or
deleted by whoever ran the check before it returns.

---

## Measurement obligations

**Before/after benchmark: yes.** The diff touches executable lines of `ltl`
(`docs/process/workflow.md` § 3 scope table). The `before` is captured on the
base commit before the first line of code
(`single-day-access-log-standard --label 617-before`).

**Prototype: none.** The work adds no data model, adds no per-line cost, and
every criterion has a known method. The one per-key site is the messages-table
total, rendered once per displayed message at #273's emit site; it walks its
column once per table and its decimals once per value. The timeline walk runs
once per visible column and once per value for its decimals, a few thousand
renders on a day of one-minute buckets.

---

## Delivery

Drops are commits pushed to the issue branch; one PR at the end. Before the
first line of code, the Deliver stage records the native edges #617 blocked by
#273 (store the precise total duration) and by #616 (one gated derivation of
means: the goldens are re-blessed after it), and the before benchmark is
captured. #608, #613, #616 and #273 land first; each drop's goldens are
re-captured on the tree they leave.

1. **One dispatch, one kind resolver, the budget table, the strip, the floor
   and zero rules** (D2, D3, D4, D13, D15 amending D7, D16). The kinds table, the
   resolver (reading #613's family column), the budget table with today's
   spellings, the strip helper, the rate arm at the timeline and the CSV sites;
   every surface calls the dispatch; the heatmap's user-defined branches fold
   into the resolver; `normalize` and the private dispatch copies go; the
   histogram percent ticks move to the percentage formatter. Proves AC1 (at
   named budgets), AC2, AC6, AC7, AC8, AC9, AC15, AC16, AC18, AC19. Goldens move
   for the trailing zeros and the floor.
2. **The width rule** (D1, D8, D9, D10, D11, D12, D18, D19). The walk, the
   per-column resolution, the common maxima, the ceiling, the carry, the
   long-tier byte spellings on #608's ladder step; the timeline columns, the
   value-only cells and the messages-table total pass their width; the y-axis
   ticks name the *axis tick* budget; #608's boundary-carry assertion in
   `validate-byte-units` is re-pointed; the one-digit shed, the decimals loop,
   the magnitude branches and the width-to-decimals copy go. Proves AC3, AC4,
   AC5, AC10, AC11, AC12, AC17, AC20, AC22. Goldens move for the cut values, the
   re-resolved tiers, the carry and the y-axis.
3. **Notices and the records** (D5, D6, D14, D17). Every notice on its row; the
   five new harness scenarios; the pattern entry and the records below. Proves
   AC13, AC14; AC21 is looked at.

### Delivery progress

**Drop 1 (2026-10-04): one dispatch, the kind resolver, the budget table, the
strip, the floor.** `value_text()` is the dispatch; `resolve_value_kind()` the
kind resolver (a built-in metric's family from `@builtin_metrics`, a
user-defined metric's from its unit type and aggregation through
`udm_config_by_name()`, its declared unit the floor); `%value_budget` the budget
table; `@number_unit_ladder` and `%tier_decimals` (short 1, medium 1, long 2, the
proposed maxima, which reproduce every fixed surface's output today) the kinds
table; `strip_trailing_zeros()` the strip helper, called by every arm,
`format_percentage` and `format_csv_value`. `format_heatmap_value`,
`format_duration` and `normalize` are gone; `format_time`, `format_bytes`,
`format_number` and `format_cv_display` are the dispatch's arms. A user-defined
rate's STATS cell resolves to a `rate` CSV family (one decimal by default), with
the built-in `err-rate` and `msg-rate` columns, which replaces the name-based
override in `format_csv_value`.

Sequencing within the issue: every fixed-budget surface moved in drop 1. The
surfaces that pass a width (the timeline's proportional and value-only cells
and the messages-table total) stay on `format_duration_total`,
`format_number` and `format_bytes` until drop 2 gives the dispatch its walk;
routing them through a width before the walk exists would have meant a
temporary copy of the width-to-tier rules inside the dispatch. The timeline
column of a user-defined time metric already passes its declared unit as the
floor, so AC8's timeline half is proven in drop 1. AC15's structural half (the
arms have one caller) is proven at drop 2.

Proven in drop 1, by `tests/validate-value-display.sh` (scenarios
*count-spelling*, *fixed-budget-sweep*, *zero-duration*, *floor-unit*,
*cv-agreement*, *user-defined-kind*, *rate-suffix*, *no-trailing-zero*; 11 of its
20 assertions fail against the base tree, each on a behaviour this drop
changes), `validate-histogram-bin-counters` scenario *display-dimensions* (the
bytes line, AC19), `validate-csv-output` scenario *udm-rate-cell* (AC16, the CSV
half; fails against the base tree's `0`), and the unchanged assertions of
`validate-duration-display`, `validate-bucket-size-units`,
`validate-aggregate-export`, `validate-progress-line`,
`validate-summary-contribution-bar` and `validate-histogram-ticks` (AC18).

Regression goldens moved by drop 1, against the base commit's captures (which
equal the committed goldens): 18 of 74 files, 36 lines, in three classes.

| Class | Files | Example |
|---|---|---|
| trailing zero in a CV cell (D3) | 11 | `CV:3.00` reads `CV:3`; the timeline CV value is left-aligned in its four characters, as the latency cells beside it are |
| trailing zero in a count (D3) | 2 | `1.30 Mil` reads `1.3 Mil` |
| a latency cell's decimal given way to its width rounds instead of being cut (D1, D8) | 5 | under `-du us` a messages-table P50 of 72.6 ms read `72ms` and reads `73ms` |

The third class is not in § Design, *User surface changes*: `format_duration`
removed the fractional digit with `s/\.\d+//`, which truncates; the dispatch
renders the value again at fewer decimals, which rounds.

**Findings from drop 1, outside this issue.** A heatmap of a user-defined time
metric whose every value is zero dies with `Can't use an undefined value as an
ARRAY reference` in `get_heatmap_column_header` on the base commit as on this
branch (input: two application-log lines carrying `elapsed=0`,
`-udm 'elapsed:s:max' -hm elapsed`). AC8's heatmap half for a user-defined
metric is therefore asserted only for the built-in duration.

**Drop 2 (2026-10-04): the width rule with intents (D23).** `value_column()`
resolves a width-passing surface's tier and fit once per column through
`value_walk_row()`: the steps of the row's intent's walk in order
(`%value_intent`: each intent's tolerance and its order of what gives way),
the first at which every value fits the width and shows what the step allows
(the reference's digits, or digits within the tolerance), the reference being
`value_reference()`, the most exact spelling that fits across every spelling.
Each value's decimals then come from `value_spelling()`: the most that fit, up
to the tier's maximum, or, for `prose`, the fewest within the tolerance. Every row of
`%value_budget` names its intent; the width-passing surfaces have rows of their
own (*timeline column*, *timeline count cell*, *messages total*); a row that
names no tier walks for one on its own value (*notice*). The arms return the
value their text shows. `format_time` holds a value with a source floor to the
source's resolution (the ceiling, D19, now on every surface); `format_time`,
`format_bytes` and `format_number` carry a value that rounds up to the next
step's size (D19); `@byte_unit_ladder` gains the long-tier word per notation;
the axis tick names its six-character width. `format_duration_total` is gone:
every arm has one caller, the dispatch (AC15's structural half).

AC4 as written (decimals give way before the space) is superseded by D23; it
now reads: no long-tier word is tight, one tier and one fit run down each
column, and the walk takes a voluntary trade only within the column's intent.

Proven in drop 2 by `tests/validate-value-display.sh` scenarios *fit-sweep*
(AC3, AC4, AC11, AC12), *common-maxima* (AC5, on the proposed maxima),
*boundary-carry* (AC10), *messages-total* (AC17) and *axis-tick* (AC22), and
the order of what gives way for `tabular` (*fit-sweep*: 16,800 bytes reads
`16.8 kilobytes` or `16.8 kB`, `17 kB` only where `16.8 kB` does not fit; it
fails on the first walk, which read `17 kilobytes` at width 180); the
assertions of each fail against the drop 1 tree except *messages-total*'s,
proven on a doctored render (the drop 1 total column did not overflow these
widths), and `validate-byte-units` re-pointed to the carry (999,999 bytes reads
`1 MB`; 1,048,575 bytes reads `1 MiB` under IEC). `validate-duration-display`'s
observed-zero bytes assertion accepts any byte spelling of zero (`0 B`, `0B`,
`0 bytes`): the invariant is that the zero shows.

Regression goldens moved by drop 2, against drop 1's, every changed value in a
class (the first walk, before the order of D23, gave up a significant digit on
216 values; this one on 87, every one within 5%).

| Class | Values | Example |
|---|---|---|
| the space alone (the walk) | 167 | `3m` reads `3 m` |
| same value, another tier or fit (the walk) | 161 | `3.7 kB` reads `3.7 kilobytes` |
| more decimals at the long tier | 73 | `3 minutes` reads `2.96 minutes` |
| a count at the medium tier's one decimal (the proposed maxima) | 39 | `1.68 k` reads `1.7 k` |
| a millisecond-source value at the millisecond step loses its decimal (D19) | 25 | `207.7ms` reads `208ms`; `3.6ms` reads `4ms` |
| a digit traded within 5% where the exact digits did not fit loose (`tabular`, D23) | 22 | `16.8 k` (unit cut) reads `17 kB` |
| a cut value made whole | 5 | `885.5` (unit cut) reads `885 kB`; `119 millisecon` reads `119 msec` |
| the histogram y-axis tick (correction 6) | 4 | `1k` reads `1.1k` and `1.2k` |

The before/after single-day benchmark probe on this machine reads 8.6 s on
both sides (-0.1%); the gate's pairs are taken at the merge gate.

**Drop 3 (2026-10-04): the notices and the records.** Every measured count in
a notice renders through `value_text()` at the row § Notices names: *notice*
(intent `prose`) for a scale, *notice exact* for a count a list beside it must
agree with, *notice share* for the leakage warning's percentage. The
percentage arm's decimals loop moved into the dispatch (`percentage_decimals()`
gives the mode's decimals; `value_text()` lowers them to fit), output unchanged.
The `--explain` timeout-clustering example and `docs/explain/techniques.md`
read "the coefficient of variation is 0" and the example's y-axis ticks
`1.1k`/`1.4k`. Records trued up: `docs/architecture-patterns.md` (the entry
*Width-to-format rule: one dispatch per metric kind*; the two status edits),
`docs/percentage-presentation.md`, and features 501, 444, 524, 608, 273, 448,
503, column-layout-refactor, heatmap, histogram-charts, user-defined-metrics and
452; the #342 audit report's stages 7 and 8 move to *done* when this issue
closes.

Proven in drop 3 by `validate-value-display` scenario *exact-counts* (AC13; it
holds on the base tree too, as D5 records existing behaviour, and is proven on
doctored captures), and for AC14 by new scenarios in
`validate-classification-percentages` (*leakage-warning-numbers*),
`validate-message-grouping` (*skip-final-pass-notice-count*),
`validate-log-level-vocabulary` (*unregistered-level-numbers*) and
`validate-recursive-file-selection` (*unreadable-directory-count*), each failing
against the drop 1 tree.

**Merge gate:** `$version_number` restored; the full harness suite on the final
commit (`CI=1` CSV output, then statistics, then the rest); the before/after
benchmark on this machine; `validate-help-content`; the golden diff
classification (AC20) recorded here.

---

## Records to update at delivery

| Record | Update |
|---|---|
| Issue #617 | the native edges blocked by #273 and by #616, recorded at the start of the Deliver stage; the delivery comment, pointing here, which also corrects the #342 review's stage 7 row: the switch is `-pv`, not `-ov` (D17) |
| Issue #273 | a comment: the messages-table total its emit site formats is walked by the column's width under this issue (D18); the `duration_nice` cell keeps a fixed budget |
| Issue #608 | a comment: the long-tier byte spellings this issue adds to the ladder step, per notation (D19); the carry lives here |
| Issue #616 | a comment: the strip helper call in `format_csv_value`, beside #616's decimals override |
| Issue #613 | a comment: the kind resolver reads the family column and routes it through the dispatch |
| `docs/architecture-patterns.md` | the new entry; the two status edits of § Design, *The pattern entry*, each touching only this issue's token |
| `features/342-redundant-logic-surfaces-audit-report.md` | the findings on the zero duration, the three count spellings, the heatmap's user-defined branch, the dispatch copies, the trailing zeros, the notices' counts and percentages, the raw occurrences and the fit-to-width rules moved on to this record; stages 7 and 8 *done*. The stage 7 row's `-ov` is not edited (the correction is the delivery comment) |
| `features/501-legend-category-total-shortening.md` | the legend's tiers are budget rows; D1's signature is the arm the dispatch calls |
| `features/444-access-log-format-family-and-user-surface.md` | R17's zero rule applies on every surface, through the dispatch, at the floor unit |
| `features/524-bucket-size-unit.md` | the `0ns` note no longer describes any surface |
| `features/608-byte-unit-ladder.md` | the ladder step's long-tier fields; the carry hand-forward closed |
| `features/273-store-precise-duration-totals.md` | the table total passes its column's width |
| `docs/percentage-presentation.md` | the notice share row in § The surfaces; the histogram tick migration marked done; the degrade loop is the rule's walk; the parameters live in the budget table |
| `features/448-category-summary-share-and-bar.md` | N1: the formatter's parameters come from the budget table |
| `features/503-yaml-aggregate-export.md` | D13 and D19 are budget rows; the carry at a unit boundary reaches the total time, peak memory and population duration (D20, D22) |
| `features/column-layout-refactor.md` | a value is fitted to its column, never cut |
| `features/heatmap.md`, `features/histogram-charts.md`, `features/user-defined-metrics.md` | labels and user-defined values render through the dispatch; the floor is the metric's declared unit; a user-defined rate's CSV cell |
| `--explain` timeout-clustering example and `docs/explain/techniques.md` | "the coefficient of variation is 0.00" follows the cell (`0`); the example's hand-written y-axis counts follow the *axis tick* budget (no two ticks read `1k`) |
| `docs/usage.md`, `--help` | no row changes |
| Release notes | yes, one bullet: "Show every value one way on every surface, fitted to its column without trailing zeros, never below the log's own unit." |
