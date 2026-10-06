# Numeric, byte and duration inputs accept a value with a unit; one declaration of the bound set first (Issue #605)

## Status

Specification agreed with the architect 2026-10-06 in an interview held
section by section, on branch `605-input-units` off `release/0.19.0` at
f7c5daa. Drop 0 (this document) is committed and pushed (663c9e1); drop 1
(the bound declaration) is committed on the branch. Issue #605 is labelled
`status: in progress`.

| Drop (§ 9) | State |
|---|---|
| 0 specification | done 2026-10-06: committed, comment on #605 listing D11 to D29, #622's order line updated, #688 filed from D12 |
| 1 bound declaration | done 2026-10-06: AC1 to AC5 asserted; `before` benchmark captured (`605-before`, base f7c5daa) |
| 2 quantity units | next; starts on the architect's instruction |
| 3 `-V` content shape | not started |
| 4 patterns and checks | not started |
| 5 records and release note | not started |

**Resuming.** Read § 4 (the locks), § 5 (the agreed design, every subsection
agreed 2026-10-06), § 6 (the criteria), § 9 and *Findings from implementation*
below. `$version_number` reads `0.19.0-605`. The `before` benchmark is
`tests/baseline/results/605-before.tsv` in the `release-0.19.0` worktree
(`.claude/worktrees/release-0.19.0`, at f7c5daa), so the `after` run is taken
from a worktree too. Drop 2 opens by re-reading § 5.3, § 5.4 and § 5.6 against
the code as drop 1 left it.

This issue is a sub-issue of #622 (the refactoring the redundant-logic-surfaces
audit dispatched). It blocks #620 (hoisting the read loop's run-constant tests),
#454 (a notice that statistics describe a filtered subset), #536 (the thread
name as an attribute) and #537 (the access-log remote host as an attribute).

---

## 1. The motivating consumer

**The user, writing a quantity the way it is thought of.** The driver is
usability (architect, interview of 2026-10-06): a quantity is written the way it
is thought of, and the tool does the arithmetic. The model is `-bs` (bucket
size) since #524: a week is `7d`, not 10080 minutes worked out by hand, and four
hours or three days are picked as quickly. This issue gives the same to the
options where a count, a byte size or a duration is typed:

- the twelve filter and highlight bounds: `-dmin 2s` instead of `-dmin 2000`,
  `-bmin 5MB` instead of `-bmin 5000000`, `-hcmin 1.5k` instead of
  `-hcmin 1500`;
- the counts typed large: `-gc 2M` (group ceiling) instead of `-gc 2000000`,
  `-n 1k` (top messages), and the hidden consolidation tunables.

A bare number keeps its meaning on every option, so no existing command line
changes behaviour.

**A bound finer than a millisecond.** Duration bounds are whole milliseconds
today, so `-dmin 0.2` is refused, though an access log recording microseconds
puts a typical request between 0.1 and 2 ms. Durations are already compared as
fractional milliseconds in the read loop; only the option's whole-number type
stands in the way. With a unit, `-dmin 200us` bounds a histogram at 0.2 ms, so
two days' histograms can be given the same axis for a side-by-side comparison.

**What a user sees change.**

- Each option above accepts `<number><unit>` in the units of its kind:
  plain-number multipliers on counts, the byte ladder on byte sizes, the
  time-unit ladder on durations.
- A value the option cannot read stops the run with a usage error that quotes
  it and lists the units its kind accepts. Today `-dmin 5s` prints
  `Value "5s" invalid for option dmin (integer number expected)` followed by
  `Error: required options not provided`, and names no accepted form.
- A negative bound is a usage error (today `-dmin -5` is accepted silently).
- A duration bound finer than the log records gets a note.
- One *Units* section in `docs/usage.md` and `ltl --help units` describe the
  accepted forms; option rows point to it.
- `-V option-resolution` shows each such option as entered beside the value it
  resolved to.
- The aggregate export's `excluded:` mapping reports the numeric exclusion
  count whenever the filter surface exists, zero included, as the `-V` filter
  summary already does.

**What changes inside.** The twelve bounds are declared once, and the lists
written by hand today (option parsing, provenance, runtime configuration, the
index signature, the activation tests, the inverted-range check, the export,
the help rows) derive from it. One parse reads `<number><unit>` for every
option, so a future option that takes a quantity calls it; a harness check
fails when one does not.

**Ordering.** #620 (hoisting the read loop's run-constant tests) is blocked by
this issue so the tests on the twelve bounds are hoisted once, from the
declaration. #454, #536 and #537 are blocked by it so they land after the
declaration exists. These are ordering edges; this issue carries no
requirement on their behalf.

---

## 2. Requirement

Four parts. The declaration comes first, so the unit parse lands on one
declaration rather than on twelve options (stage 11 of the #342 review); then
the unit parse; then the `-V` content shape (§ 2.4), which the new section is
written to; then the pattern, documented once the parse it describes exists
(§ 9).

### 2.1 One declaration of the bound set

The twelve numeric bounds (duration, bytes and count; each with a filter
minimum and maximum and a highlight minimum and maximum) are declared once.
Each declared bound carries its metric, its role (filter or highlight), its end
(minimum or maximum), its short and long option names, and whether it belongs
in the index signature (filters do, highlights do not:
`features/312-numeric-criteria-highlight-selection.md` § Decisions, Option
surface). The declaration holds numeric bounds only. The signature renders each
filter bound as its runtime value, not as typed (D16), so equal values written
differently share one index.

What derives from it:

- every list of the bound set written by hand today: option parsing, option
  provenance, the `-V runtime-config` values, the active-filter test, the index
  signature, the highlight activation test, the inverted-range check, and the
  aggregate export's `excluded:` test;
- the help rows of the twelve options, in one phrasing (today one meaning,
  "inclusive", is written two ways);
- the settlement checks: the inverted-range check, and beside it a new check
  that a negative bound is a usage error.

The read loop's comparisons against the twelve values stay inline, as they are,
under the hot-loop rule; the twelve values stay where the loop reads them.

The numeric exclusion count is reported by every consumer whenever the filter
surface exists, zero when nothing was excluded: the aggregate export's
`excluded:` mapping carries `numeric` always, as the `-V filter-summary`
section already does.

### 2.2 Inputs accept a value with a unit

The options of D13 accept `<number><unit>` and
behave as if the equivalent bare value had been given. A bare number keeps its
current meaning on every option.

- **Kinds.** Each option has one kind and reads only that kind's vocabulary:
  a count reads the plain-number multipliers, a byte size the byte ladder of
  #608, a duration the time-unit ladder of #524 (`m` is minute). Spellings
  match case-insensitively within the kind. Every spelling the output prints
  for a kind is accepted on input of that kind, with `G` and `kil` added for
  counts.
- **Values.** A bound accepts a value that resolves to a fraction and applies
  it as written; a size the tool acts on (`-n`, `-gc`, the consolidation
  counts) must resolve to a whole number. A negative bound is a usage error.
- **Rejection.** A value the option cannot read (a unit of the wrong kind, a
  bare multiplier on a byte option, a malformed value, a fraction on a size)
  stops the run with a usage error that names the option, quotes what was
  typed and lists the units the option's kind accepts.
- **Notes.** A duration bound finer than the unit the log's durations are
  recorded in gets a behavioural note; the bound is applied as written.
  Every message that names a value quotes it as typed.
- **Exposure.** `-V runtime-config` carries each value converted to the unit
  `ltl` uses internally. A new `-V option-resolution` section shows each
  unit-bearing option as entered beside the value it resolved to.
- **Documentation.** One *Units* section in `docs/usage.md`, and
  `ltl --help units`, describe the kinds, their spellings and examples; the
  option rows say a unit is accepted and point there. Unit lists in `--help`
  are interpolated from the ladders. The long byte words are listed in
  `docs/usage.md` only.

### 2.3 The pattern

The way an option accepts a quantity with a unit is a documented pattern that a
developer meets while planning and cannot bypass unnoticed:

- an entry in `docs/architecture-patterns.md`, naming the shared parse, the
  three vocabularies, the declaration of unit-bearing options and the rules
  above;
- a path-scoped rule under `.claude/rules/` that loads when `ltl` is edited and
  points to the entry;
- a harness scenario that fails when an option whose value is a number is
  neither declared as unit-bearing, with its kind, nor listed among the options
  that stay bare numbers, with its reason; and that asserts every spelling the
  output prints for a kind is accepted on input of that kind.

`-bs` and `-tp` already resolve through the time-unit ladder and are cited as
sites that follow the pattern.

### 2.4 One content shape for every `-V` section

The `-V` sections share one content shape, written down from what they already
use (D25), and the sections that depart from it are converted, with their
harnesses (D26 to D28): snake_case keys, `yes`/`no` booleans, `-` for an absent
value, entity blocks where a section reports several entities. A harness check
fails on a line that departs from it (D29). The new `option-resolution` section
is the first written to it.

---

## 3. Corrections to the issue body and the audit record

Each was checked against `ltl` on `release/0.19.0` (f7c5daa) on 2026-10-06.

1. **The plain-number spellings.** The body says `1m` is a million "as
   `format_number()` uses them". `format_number()` prints `M` for a million and
   `B` for a billion (short tier), `Mil`, `Bil`, `Tril` (medium) and the words
   (long); the `-udm` unit slot accepts `k`, `K`, `M`, `G`, `T` case-sensitively.
   Settled by the interview: case-insensitive within the kind, every printed
   tier accepted, `G` and `kil` added (D11, D12).
2. **"The units `ltl` already uses on output".** Not every spelling the output
   prints is accepted on input today: the byte ladder accepts its tokens only,
   while `format_bytes()` prints the words (`kilobytes`, `mebibytes`) at its
   long tier. Settled: byte options accept the words (D24).
3. **The candidate options.** The body lists the twelve bounds as candidates and
   leaves the full list to an analysis. Settled: the twelve, `-n`, `-gc` and the
   three hidden consolidation counts (D13).
4. **"The six bound families".** The stage-11 lock names "the six bound
   families (metric; filter min and max; highlight min and max; the four option
   names; ...)". The parenthesis describes one entry per metric (three), while
   the inverted-range table has six rows (filter and highlight per metric).
   The declaration of § 2.1 is stated per bound (twelve), each carrying its
   metric, role and end, from which either grouping derives.
5. **"The six help rows".** The audit counts six help rows for the filter
   bounds. There are twelve rows in `print_help` and twelve in `docs/usage.md`
   (the six filter rows and the six highlight rows). "Inclusive" is written two
   ways among the filter rows: `-dmin` and `-dmax` say "(inclusive: entries
   exactly at N are kept)", the four byte and count rows say "(inclusive)"; the
   highlight rows say "at or above" and "at or below". None of the twelve
   states the unit of a bare number (milliseconds for a duration, bytes for a
   byte size).
6. **The hand-written enumerations.** The audit counts eight lists of the bound
   set; all eight are present: the `GetOptions` entries in
   `adapt_to_command_line_options`, the name list in `_resolve_short_to_long`,
   the values in `emit_runtime_config_verbose`, `has_active_filters`,
   `serialize_filters`, the `$numeric_highlight_active` test and the
   inverted-range table (both in `adapt_to_command_line_options`), and the
   `excluded:` test in `write_aggregate_export`. Beyond them, the twelve file-
   scope declarations, the help rows and the read loop's comparisons name the
   set; the loop stays inline (§ 2.1).
7. **What a typed unit does today.** `-dmin 5s` prints `Value "5s" invalid for
   option dmin (integer number expected)` followed by `Error: required options
   not provided`; no accepted form is named.
8. **The third vocabulary is already declared for output.**
   `features/608-byte-unit-ladder.md` § 5.2 hands the plain-number multipliers
   (`%si_units`, private to `parse_udm_configs`) to this issue to declare. A
   file-scope `@number_unit_ladder` already exists: `format_number()`, the
   count arm of `value_text()`, reads it for its three tiers. The input
   vocabulary is that ladder, not a new table.
9. **Stale records, trued up with this issue (§ 10).**
   `features/user-defined-metrics.md` § Unit Types lists the time units as `ns`
   to `h`; the ladder also has `d`, `w`, `month`, `year` and the long
   spellings. The `time_unit_canonical` consumption site in
   `docs/architecture-patterns.md` names `-du`, `-ru`, `-bs` and the `-udm`
   slot, not `-tp`, which resolves through it since #525.

---

## 4. Locked decisions

These are the architect's. They are restated, not reinterpreted. Nothing else
in this document is numbered Dxx.

**From stage 11 of the redundant-logic-surfaces review (#342), 2026-09-27.**
The lock, verbatim: "F5.3, F5.4, F5.5, F5.6 fold into #605 as its first
requirement (one declaration of the six bound families; enumerations, help rows
and settlement checks derive; a negative bound is a usage error beside the
inverted-range check; the exclusion count reported by every consumer whenever
the filter surface exists, zero when none); #454, #536, #537 blocked by #605; no
separate issue". Its parts:

- **D1 — One declaration of the bound set, first.** The bound set is declared
  once; the hand-written enumerations, the help rows (one phrasing) and the
  settlement checks derive from it; the unit parse then lands on the one
  declaration. *Locked by the architect 2026-09-27, stage 11 (#342).* The
  declaration's reach is narrowed by D21 (numeric bounds only).
- **D2 — A negative bound is a usage error**, checked at settlement beside the
  inverted-range check, from the same declaration. *Locked by the architect
  2026-09-27, stage 11 (#342).*
- **D3 — The numeric exclusion count is reported by every consumer whenever
  the filter surface exists**, zero when nothing was excluded: the aggregate
  export's `excluded:` mapping carries `numeric` always, as the `-V` filter
  summary already does. *Locked by the architect 2026-09-27, stage 11 (#342).*
- **D4 — The read loop's comparisons stay inline** under the hot-loop rule.
  *Locked by the architect 2026-09-27, stage 11 (#342) (issue body: "The
  comparison sites in the read loop stay inline under the hot-loop rule"), and
  stage 16 ("F5.1 is #605 as locked": the closed interval is coded twice, filter
  and highlight, with no shared per-line sub).*
- **D5 — Ordering.** #454, #536 and #537 are blocked by this issue (stage 11);
  #620 (hoisting the read loop's run-constant tests) is blocked by it (stage
  15); this issue was blocked by #608 (one byte ladder), delivered 2026-09-29
  (stage 2). These edges order the work; they carry no requirement onto this
  issue. *Locked by the architect 2026-09-27.*

**From the unit ladders this issue reads.**

- **D6 — Durations read the one time-unit ladder.** "A single file-scope table
  is the only definition of time units in `ltl` ... no sub keeps a token list, a
  unit regex, or a multiplier of its own." Its spellings are
  `features/524-bucket-size-unit.md` D2's table, with the long sub-second
  spellings of `features/525-timestamp-precision-option.md` D6. "`m` is minute
  on every time-unit surface; no spelling that could be read as minute means
  month. The ladder governs time units only: a plain-number input reads `m` as
  a million, and a byte input takes explicit byte units." *Locked by the
  architect: #524 D1 and D2; the last sentence confirmed on this issue
  2026-09-26.*
- **D7 — A bare number keeps its meaning; `-bs` is the model grammar.** "This is
  an alternative way of writing large values, not a change of meaning. A bare
  number with no unit keeps its current function on every option; existing
  command lines do not change behaviour" (issue body). The grammar of
  `features/524-bucket-size-unit.md` D3: `<number>[<unit>]`, a decimal, no
  whitespace between number and unit, validated once at settlement, an
  unreadable value rejected with a usage message and a non-zero exit. D2 adds a
  rejection a bare number can meet on a bound: a negative value. *Locked by the
  architect: the issue body; #524 D3.*
- **D8 — Help rows interpolate the ladder.** "A help row that names a unit
  vocabulary interpolates the ladder's list, never a literal, for time units and
  byte units alike, with a help-content harness scenario asserting it; the
  threshold rows of #605 (inputs with a unit) then follow the rule."
  *Locked by the architect 2026-09-27: `features/608-byte-unit-ladder.md` D8.*
- **D9 — Byte sizes read the one byte ladder** of #608, through
  `byte_unit_canonical()`, built in the shape of the time-unit ladder
  (`features/608-byte-unit-ladder.md` D5); D24 amends its one-spelling-per-token
  rule for input. *Locked by the architect: #608.*
- **D10 — `-tp` already follows the pattern.** "The precision values resolve
  through the time-unit ladder ... #605 later cites `-tp` as a surface already
  following its pattern." *Locked by the architect 2026-09-29:
  `features/525-timestamp-precision-option.md` D6.*


**In reply to this specification's interview (2026-10-06).**

- **D11 — Units match case-insensitively within the option's own kind.** A count
  option reads only the plain-number multipliers, a duration option only the
  time-unit ladder, a byte option only the byte ladder, and each matches its
  spellings without regard to case (`KB`, `kB`, `Kb` and `kb` are one unit;
  `-cmin 5m` and `-cmin 5M` are both five million; `-dmin 5m` is five minutes).
  No ladder lists case variants: one spelling per entry, matched lower-cased,
  as `time_unit_canonical` and `byte_unit_canonical` already do. Case is
  significant only on a surface that accepts more than one kind, the `-udm`
  unit slot, which keeps its existing rule (plain-number multipliers checked
  case-sensitively first, so `m` is minute and `M` is mega there). *Locked by
  the architect 2026-10-06.*
- **D12 — A count option accepts every tier the output prints, plus `G` and `kil`.**
  The spellings of the number ladder's three tiers (short `k`, `M`, `B`, `T`;
  medium `Mil`, `Bil`, `Tril`; long `thousand`, `million`, `billion`,
  `trillion`), `G` for a billion as the `-udm` unit slot accepts it, and `kil`
  for a thousand, matching the medium tier's other steps. `B` on a count option
  is a billion; only byte options read the byte ladder. What the medium tier
  prints for a thousand (`k` today) is not this issue's: #688 (the medium tier
  writes a thousand as `Kil`) owns it. *Locked by the architect 2026-10-06.*
- **D13 — Which options take a unit.** The twelve bound options (`-dmin`, `-dmax`,
  `-bmin`, `-bmax`, `-cmin`, `-cmax` and their six highlight mirrors), and the
  counts where a large value is typed: `-n` (top messages), `-gc` (group
  ceiling), and the hidden `--consolidation-trigger`,
  `--consolidation-ceiling` and `--consolidation-max-patterns`. Widths, heights,
  percentages, precision tiers, bucket counts, decimals and the hidden detection
  window stay bare numbers. `-bs` and `-tp` already follow the pattern.
  *Locked by the architect 2026-10-06.*
- **D14 — The pattern is met while planning and enforced when an option is added.**
  A developer adding an option that takes a quantity meets the pattern while
  planning, through its entry in `docs/architecture-patterns.md` and a
  path-scoped rule that loads when `ltl` is edited; and a check fails when an
  option taking a quantity bypasses the shared parse. Documentation and a pointer alone
  are not enough. *Locked by the architect 2026-10-06.* The check fails in a
  harness scenario, run at the completion gate or whenever the harness is run
  (*locked by the architect 2026-10-06*). Its shape, as put to the architect
  with that question: every option whose value is a number is either in the
  declaration of unit-bearing options, with its kind, or in a short list of
  options that stay bare numbers, each with its reason; a numeric option in
  neither fails (§ 5).
- **D15 — `-V runtime-config` carries the converted value.** The section exposes the
  configuration the runtime is given, so a value entered with a unit appears in
  the unit `ltl` uses internally (`-dmin 200us` as `duration_min: 0.2`, the key snake_case by D26), as
  `-bs 7d` already appears as `bucket-size: 10080`. The value as the user typed
  it belongs on a surface for the options as entered, not here. *Locked by the
  architect 2026-10-06.*
- **D16 — The index signature is written from the runtime values.** The filter part
  of the index signature (`serialize_filters`) renders each filter bound as its
  runtime value, the value `-V runtime-config` carries, never as typed: `-dmin
  200us` and `-dmin 0.2` write the same signature and reuse the same index.
  *Locked by the architect 2026-10-06.*
- **D17 — This issue builds the `-V option-resolution` section.** Each option that
  accepts a unit (the options above, with `-bs` and `-tp`) is shown as entered
  beside the value it resolved to, so a harness can assert that `-dmin 200us`
  was entered as `200us` and resolved to `0.2`. The section name was reserved
  in `tests/HARNESS-DESIGN.md` § Reserved section names by #231 (CLI option
  parsing and conflict detection, closed) and never built. *Locked by the
  architect 2026-10-06.*
- **D18 — Messages quote a value as typed.** A warning, error or note that names an
  option's value (the inverted-range warning, the negative-bound error, the
  note on a bound finer than the log carries) quotes it as the user entered it:
  `-dmin 2s is above -dmax 500ms`, not `-dmin 2000 is above -dmax 500`.
  *Locked by the architect 2026-10-06.*
- **D19 — An unreadable value stops the run.** A unit of the wrong kind (`-bmin 5s`),
  a bare multiplier on a byte option (`-bmin 1M`), or a malformed value
  (`-cmin 5x`) is a usage error with a non-zero exit, as `-bs` already does. The
  message names the option, quotes what was typed, and lists the units the
  option's kind accepts, interpolated from its ladder (`-bmin 1M: a byte size
  needs a byte unit: B, kB, MB, GB, TB, KiB, MiB, GiB, TiB`). This replaces
  today's generic "required options not provided" for these options. *Locked
  by the architect 2026-10-06.*
- **D20 — A bound accepts a fraction; a size does not.** A filter or highlight bound
  accepts a value that resolves to a fraction and applies it as written
  (`-bmin 1.5B` keeps lines of 2 bytes and more), as a sub-millisecond duration
  bound does. An option that sets a size the tool acts on (`-n`, `-gc`,
  `--consolidation-trigger`, `--consolidation-ceiling`,
  `--consolidation-max-patterns`) refuses a value that does not resolve to a
  whole number, with the usage error above (`-n 2.5`, `-gc 1.2345k`); `-n 1.5k`
  is 1500 and accepted. *Locked by the architect 2026-10-06.*
- **D21 — The bound declaration holds the numeric bounds only.** Duration, bytes and
  count, each with its filter and highlight minimum and maximum. Text-attribute
  filters are not part of it. *Locked by the architect 2026-10-06.*
- **D22 — A duration bound finer than the log records gets a note.** When a duration
  bound is given in a unit finer than the unit the log's durations are recorded
  in, a behavioural note says so, quoting the bound as typed and naming the
  log's unit (`Note: -dmin 200us is finer than the log's durations, which are
  recorded in whole milliseconds`). The shape follows the existing precision
  note printed by `resolve_timestamp_precision`; unlike it, nothing is clamped:
  the bound is applied as written. *Locked by the architect 2026-10-06.*
- **D23 — One shared *Units* section; option rows point to it; `--help units`.**
  `docs/usage.md` gains one *Units* section describing the three kinds, their
  spellings and examples. Each option row that accepts a unit says so and
  points to it, rather than listing the units itself. `ltl --help units`
  prints the same content in the terminal. The unit lists in that content are
  interpolated from the ladders (#608's D8, help rows interpolate the ladder's
  list). *Locked by the architect 2026-10-06.*
- **D24 — Anything the output prints, an input of that kind accepts.** Byte options
  also accept the long-tier words `format_bytes()` prints (`kilobytes`,
  `kibibytes`, … `tebibytes`, and `bytes`), matched case-insensitively,
  amending for input the one-spelling-per-token rule of
  `features/608-byte-unit-ladder.md` § 5.2. Time options already accept every
  spelling `format_time()` prints; count options accept every tier by D12. The failing check asserts this for all three kinds. The long byte
  words are not listed in `--help` (neither the option rows nor `--help
  units`), whose lines would grow too long; the *Units* section of
  `docs/usage.md` lists them. *Locked by the architect 2026-10-06.*
- **D25 — The `-V` content shape is written down as a pattern, from what the
  sections already use.** The convention the existing sections share (§ 5.6.1)
  is recorded as the standard every section follows; `option-resolution`
  follows it. *Locked by the architect 2026-10-06.*
- **D26 — The sections that diverge are converted to the standard in this
  issue, with their harnesses.** Keys are snake_case in every section (the
  `runtime-config` keys included); a boolean is `yes` or `no`, never `1` or `0`.
  Every harness and record that reads a converted key or value is updated in the
  same commit (`tests/HARNESS-DESIGN.md` § Stability contract). *Locked by the
  architect 2026-10-06.*
- **D27 — An absent value is `-`.** A key with nothing to report carries `-`,
  replacing `(not set)` and the `none` that means absence. A `none` that is a
  value in its own right (`lookup: none`, no index lookup happened) stays.
  *Locked by the architect 2026-10-06.*
- **D28 — `message-grouping` is converted to the standard in this issue.** The
  section and its `grand-totals` sub-section, today a padded report per
  category and phase, become entity blocks of snake_case `key: value` facts
  (`category: plain|200`, `phase: streaming`, `keys_seen: 12`, ...); the
  `accounting` sub-section, already a tab-separated table of bulk records,
  stays. Every harness reading the section is updated in the same commit.
  *Locked by the architect 2026-10-06.*
- **D29 — The `-V` content shape has a failing harness check.** A harness
  scenario reads every section and fails on a line that departs from the
  standard: a key that is not snake_case, an entity line not of the form
  `<entity>: <name>`, or an absent value written as anything but `-`.
  Booleans are `yes`/`no` by D26. *Locked by the architect 2026-10-06.*

---

## 5. Design

Read against `ltl` on `release/0.19.0` (f7c5daa). What a lock settles is
written as settled; everything else is **proposed** until the architect agrees
it.

### 5.1 The sites this work reaches, as they are today

**The bound set.** Twelve file-scope scalars, `my ( $filter_duration_min,
$filter_duration_max );` and five lines like it, named by hand at:

| Site | What it holds | Subset |
|---|---|---|
| `adapt_to_command_line_options`, `GetOptions` | `'duration-min\|dmin=i' => \$filter_duration_min`, twelve entries, all `=i` | all twelve |
| `_resolve_short_to_long` (called by `_classify_argv_provenance`) | `'duration-min\|dmin', 'duration-max\|dmax', ...` among every option's names | all twelve |
| `emit_runtime_config_verbose` | `'duration-min' => $filter_duration_min,` | all twelve |
| `adapt_to_command_line_options`, inverted-range table | `[ $filter_duration_min, $filter_duration_max, '-dmin', '-dmax', 'no log entries can match' ],` six rows, the only place a metric's min, max and option names are paired | all twelve, as six pairs |
| `has_active_filters` | `return 1 if defined $filter_duration_min \|\| defined $filter_duration_max;` | six filters |
| `serialize_filters` (the index signature) | `push @parts, "-bmax=$filter_bytes_max" if defined $filter_bytes_max;`, alphabetical by short name; highlights left out by omission | six filters |
| `write_aggregate_export` | `$excluded->{numeric} = $excluded_numeric if grep { defined } ($filter_duration_min, ...)` | six filters |
| `adapt_to_command_line_options`, `$numeric_highlight_active` | `grep { defined } $highlight_duration_min, ...` | six highlights |
| `print_help`, `docs/usage.md` | twelve rows each, three phrasings (§ 3 item 5) | all twelve |
| `read_and_process_logs` | the filter blocks (`if( defined( $filter_duration_min ) && $duration < $filter_duration_min ) { $excluded_numeric++; next; }`) and the one compound highlight test | all twelve; stays inline (D4) |

**The other options of D13.** `'top-messages|n=i' => \$top_n_messages`,
`'group-ceiling|gc=i' => \$consolidation_final_ceiling`, and the hidden
`'consolidation-trigger=i'`, `'consolidation-ceiling=i'`,
`'consolidation-max-patterns=i'`, all in `adapt_to_command_line_options`; none
is validated beyond Getopt's integer check.

**The unit parsing that exists.**

- `-bs`, inline in `adapt_to_command_line_options`: `my $decimal =
  qr/-?(?:\d+(?:\.\d+)?|\.\d+)/;`, then `/^($decimal)([A-Za-z]+)$/`,
  `time_unit_canonical($spelling)`, `convert_duration_to_ms($width,
  $canonical)`; an unreadable value goes to `print_usage("Invalid bucket size
  ...")` and `exit 1`. The only `<number><unit>` split in the tool.
- `-udm` unit slot, in `parse_udm_configs`: its own number pattern (`my
  $udm_number_re = qr/-?\d+(?:\.\d+)?/;` at file scope) and a private
  multiplier table, `my %si_units = ( 'k' => 1000, 'K' => 1000, 'M' => 1000**2,
  'G' => 1000**3, 'T' => 1000**4 );`, checked case-sensitively before
  `time_unit_canonical($unit) // byte_unit_canonical($unit)`.
- The three vocabularies: `@time_unit_ladder` with `time_unit_canonical` and
  `$time_unit_list`; `@byte_unit_ladder` with `byte_unit_canonical`,
  `%byte_unit_bytes`, `$byte_unit_list`; `@number_unit_ladder`, read today only
  by `format_number()` for output.

### 5.2 The declaration (agreed with the architect 2026-10-06)

One file-scope table, the quantity units declaration: the options that take a
quantity, read by every site
of § 5.1 except the read loop. One row per option:

| Field | Meaning | Example (`-dmin`) |
|---|---|---|
| `long`, `short` | option names | `duration-min`, `dmin` |
| `kind` | the vocabulary its unit is read from: `duration`, `bytes` or `count` | `duration` |
| `value` | `bound` (a fraction is applied as written) or `size` (must be whole), D20 | `bound` |
| `target` | a reference to the scalar the value lands in | `\$filter_duration_min` |
| `bound` | for the twelve bounds only: `role` (`filter` or `highlight`), `end` (`min` or `max`), and `signature` (1 for a filter, 0 for a highlight, D16 and #312's option surface) | `{ role => 'filter', end => 'min', signature => 1 }` |

Seventeen rows: the twelve bounds and the five sizes of D13. The bound set of
D1 is the rows that carry `bound`; D21 holds, as the table carries no
text-attribute filter. The twelve scalars stay where they are, so the read
loop's comparisons are unchanged (D4); the table points at them.

What each site becomes:

| Site | Reads |
|---|---|
| `GetOptions` | one `"$long\|$short=s" => $target` per row |
| `_resolve_short_to_long` | `"$long\|$short"` per row |
| `emit_runtime_config_verbose` | `$long => ${$target}`, the runtime value (D15) |
| inverted-range check | rows with `bound` grouped by metric and role, min beside max; the message chosen by role |
| negative-bound check (D2) | every row with `bound`, beside the inverted-range check |
| `has_active_filters` | any defined target among `role => 'filter'` rows |
| `serialize_filters` | rows with `signature => 1`, in today's order (alphabetical by short name), each as its runtime value (D16) |
| `$numeric_highlight_active` | any defined target among `role => 'highlight'` rows |
| `write_aggregate_export` | `numeric` written always (D3); no test of the bounds remains |
| help rows | generated per row, in one phrasing (§ 5.8) |

**The signature string stays byte-identical for every command line valid
today.** A bound given as a bare whole number renders as it does now
(`-dmin=200`), so an index written by an earlier release is still reused; a
value that only a unit could produce (`0.2`) renders as Perl's plain number.
This follows from D16: the signature serializes the canonical internal value.

### 5.3 One parse for a quantity (agreed with the architect 2026-10-06)

One sub reads an option's text against its row and returns the runtime value,
or the problem that stops the run:

```
resolve_quantity_option($row, $text) -> ($value, $problem)
```

1. **Split.** One file-scope number pattern, the one `-bs` uses today
   (`-?(?:\d+(?:\.\d+)?|\.\d+)`), moved out of `adapt_to_command_line_options`
   and named once. The text is a number alone, or a number immediately followed
   by letters; anything else is malformed (D7: no whitespace between number and
   unit).
2. **Bare number.** Taken as it is, in the option's base unit (milliseconds for
   a duration bound, bytes, a count), exactly as today (D7).
3. **Number with a unit.** The letters are resolved in the row's kind only
   (D11): `time_unit_canonical` then `convert_duration_to_ms` for a duration;
   `byte_unit_canonical` then `%byte_unit_bytes` for a byte size;
   `number_unit_canonical` (§ 5.4) then the step's factor for a count. A
   spelling that does not resolve in the row's kind is a problem: an unknown
   unit, or one of another kind (`-bmin 5s`), or a bare multiplier on a byte
   option (`-bmin 1M`, D19).
4. **Value rule** (D2, D20). A `bound` row refuses a negative value and keeps a
   fraction; a `size` row refuses a value that is not whole. A bare number on a
   size row keeps every value Getopt's integer check accepts today (D7),
   negatives included.
5. **Record.** The text as entered is kept beside the value, keyed by the
   option's long name, for `-V option-resolution` (D17) and for every message
   that quotes the value (D18).

The sub runs once per given option, at settlement in
`adapt_to_command_line_options`, after `GetOptions` (every row is now `=s`) and
before the inverted-range and negative-bound checks, which read the resolved
values and quote the entered text. A problem goes to `print_usage` and
`exit 1`, in the form of D19: the option, the text as typed, and the units of
its kind interpolated from the ladder (`$time_unit_list`, `$byte_unit_list`,
the number ladder's list).

**`-bs` calls the same sub.** Its inline split goes. `-bs` is not a row of the
table (its bare number is in the run's unit, minutes, seconds under `-s`,
milliseconds under `-ms`, and `-bs 0` is auto-size, #524 D3); it calls the sub
with its own base unit and keeps its own value rule (positive with a unit).
`-tp` takes a unit name, not a quantity, and keeps `time_unit_canonical`
directly.

**Not part of this.** `$udm_number_re` matches a value captured from a log line
on the hot path; it is not an option's text, and stays.

### 5.4 The three vocabularies (agreed with the architect 2026-10-06)

- **Durations:** `@time_unit_ladder` as it is. It already accepts every
  spelling `format_time()` prints (checked 2026-10-06), so D24 adds nothing.
- **Byte sizes:** `@byte_unit_ladder` gains, for input, the words
  `format_bytes()` prints at its long tier (`bytes`, `kilobytes`, ...,
  `tebibytes`, and the singular each prints at a value of 1), as further keys of
  `%byte_unit_by_spelling` pointing at the step's token (D24). Every surface
  that resolves through `byte_unit_canonical` gains them, the `-udm` unit slot
  included, keeping the parsing surfaces mutually sufficient as #524 D1 asks of
  the time ladder. `$byte_unit_list` stays the tokens only: the words are not
  listed in `--help` (D24).
- **Counts:** `@number_unit_ladder`, today read only by `format_number()`,
  becomes the input vocabulary too. Each step's short, medium and long names
  are accepted, plus an `also` list per step for the spellings output does not
  print: `kil` on the thousand step, `G` on the billion step (D12). A new
  `number_unit_canonical($spelling)` resolves case-insensitively over them, in
  the shape of `time_unit_canonical`; `$number_unit_list` is the list a message
  or help row interpolates.
- **The `-udm` unit slot's multipliers.** `%si_units` goes; the slot reads its
  case-sensitive multipliers from the number ladder. It cannot take the whole
  count vocabulary: there, `B` must stay the byte and `m` the minute (D11). So
  each step names the symbols the slot accepts (`k` and `K`, `M`, `G`, `T`), and
  the slot keeps its order: those symbols case-sensitively first, then the time
  ladder, then the byte ladder.

### 5.5 Settlement checks and messages (agreed with the architect 2026-10-06)

All three read the resolved value and quote the text as entered (D18).

- **Negative bound (D2).** A usage error and `exit 1`, from the declaration's
  `bound` rows, before the inverted-range check:
  `Invalid -dmin '-5ms': a bound cannot be negative`.
- **Inverted range.** Unchanged in behaviour: a warning, the run continues. It
  compares the resolved values and quotes the entered ones:
  `Warning: -dmin 2s is greater than -dmax 500ms - the range is unsatisfiable,
  no log entries can match`.
- **A duration bound finer than the log records (D22).** The unit the log's
  durations are recorded in is the one already declared: `-du` when given,
  otherwise the `duration_unit` of each file's detected format (every format
  that carries a duration declares `ms` today); a format with no duration
  declares none and contributes nothing. A bound is finer when it was entered
  with a unit whose ladder step is shorter than that unit (`-dmin 200us` on a
  millisecond log); a bare number is in the base unit and never is. The check
  runs once after the read, beside `resolve_byte_notation` and
  `resolve_timestamp_precision`, which read the same per-file detection, and
  prints one note per such bound:
  `Note: -dmin 200us is finer than the log's durations, which are recorded in
  milliseconds`. Nothing is clamped.

### 5.6 The `-V option-resolution` section (agreed with the architect 2026-10-06)

D17's section, under the name #231 reserved in `tests/HARNESS-DESIGN.md`
§ Reserved section names; it instruments what the user sees as option
resolution: what was entered and what the tool took it to mean. Emitted at
settlement, once the parse of § 5.3 has run. One entity block per unit-bearing
option the run was given (a row of the declaration, `-bs` or `-tp`), in the
declaration's order, `-bs` and `-tp` last; an option not given has no block. A
bare number has a block too, its entered and resolved values equal. The shape is
the entity-block convention the existing sections share (§ 5.6.1):

```
=== option-resolution ===
option: duration-min
  entered: 200us
  resolved: 0.2
  unit: ms
option: bucket-size
  entered: 7d
  resolved: 10080
  unit: m
=== END option-resolution ===
```

| Key | Meaning |
|---|---|
| `option` | the long name, opening the block (kebab-case, as `-V runtime-config` names options) |
| `entered` | the text as given, from the command line or the configuration variable |
| `resolved` | the runtime value, as `-V runtime-config` carries it (D15) |
| `unit` | the unit of `resolved`: `ms` for a duration bound, `B` for a byte size, `count` for a count, the run's unit for `-bs`; `-` for `-tp`, whose value is a unit name |

The owning harness is `tests/validate-option-resolution.sh` (the file name
tracks the section). The name moves from *Reserved* to *Implemented* in
`tests/HARNESS-DESIGN.md` in the commit that emits it.

#### 5.6.1 The shape the existing `-V` sections share (surveyed 2026-10-06)

Every section was captured from one run (`-V` with a heatmap, grouping, a
user-defined metric, `-o`, a bucket size and a duration bound, on a web
application access log carrying execution time in the duration field) and its
lines classified. `tests/HARNESS-DESIGN.md` records the delimiters and the
naming rules, not the content's shape; nothing records it.

- **Scalar facts: `key: value`, one per line, snake_case keys.** `filter-summary`,
  `heatmap-palette`, `csv-output`, `percentile-algorithm`, `profile`,
  `format-detection / scan`, `format-detection / classification`, the top of
  `index-read-back` and `format-registry`. `runtime-config` keys are the
  options' long names (kebab-case), because the key is the option.
- **Several entities of one kind: an entity block.** `<entity>: <name>` at the
  left margin, its facts indented two spaces as `key: value`: `file:` in
  `index-read-back` and `format-detection`, `consumer:` in
  `histogram-bin-counters`, `store:` in `statistics-demand`.
- **Many small entities: one line each, `<entity>: <name> key=value ...`.**
  `entry:` in `format-registry`, `udm:` in `udm-specs`, `group` lines in
  `statistics-demand`.
- **Bulk records: tab-separated with a header row.** `benchmark-data`,
  `message-grouping / accounting`, `aggregate-export / heatmap-ladder`,
  `section-layout`.
- **Units travel in the key, the value is a bare number:** `sample_us`,
  `counter_memory_bytes`, `sample_file_bytes`.
- **A resolved value's source is a parenthesised annotation:**
  `data_model_precision: 5 (default)`, `byte_notation: si (default)`,
  `precision_mode: default (default)`; `runtime-config` writes `; clamped from
  <asked>`.

Where they diverge:

| Question | Forms in use |
|---|---|
| An absent value | `-` (`index-read-back`, `format-detection`), `none` (`udm-counting`, `index-read-back`), `(not set)` (`runtime-config`) |
| A boolean | `yes`/`no` (`index-read-back`, `format-detection`, `heatmap-palette`, `csv-output`, `profile`) and `1`/`0` (`runtime-config` demand rows, `statistics-demand`) |
| Free text | `message-grouping` and its `grand-totals` sub-section print human-formatted lines (`Threshold: 85%  Trigger: 5000`), padded for the eye, not keyed |

#### 5.6.2 The standard and the conversion (agreed with the architect 2026-10-06)

**Where the standard is written.** `tests/HARNESS-DESIGN.md` gains a
*Content shape* section beside *Delimiter contract*: the forms of § 5.6.1 as
the rule, with D26 (snake_case keys, `yes`/`no` booleans) and D27 (`-` for an
absent value) settled. That file is already mandatory reading before any `-V`
change (CLAUDE.md, *Before writing or changing code*). `docs/architecture-patterns.md`
gains an entry naming it, whose consumption sites are the sections' emitters.

**What is converted (D26, D27, D28).** From the survey run; the inventory is
completed in the drop that converts, from every section each harness requests.

| Section | Today | Converted |
|---|---|---|
| `runtime-config` | `include (merged): (not set)` and three like it | `include_merged: -` |
| `runtime-config` | `bucket-duration-stats-demand: 1`, `message-duration-stats-demand: 1` | `bucket_duration_stats_demand: yes` |
| `runtime-config / command-line`, `/ environment-variable` | option long names as keys (`bucket-size: 60`), a flag as `1` (`no-index: 1`) | `bucket_size: 60`, `no_index: yes` |
| `statistics-demand` | `store_demand: 1`; `group terminal_core: demanded=1 ...`, `group_calc terminal_core: ...` | `store_demand: yes`; `group: terminal_core demanded=yes ...`, `group_calc: terminal_core ...` (the entity name after the colon) |
| `heatmap-palette` | `light_bg: 0` | `light_bg: no` |
| `udm-counting` | `counting_udms: none` | `counting_udms: -` |
| `message-grouping`, `/ grand-totals` | padded report (D28) | entity blocks of snake_case facts |

A `1` or `0` that is a count stays a number; only a value that answers yes or no
converts. `index-read-back`'s `lookup: none` is a value (no lookup happened)
and stays (D27).

### 5.7 The numeric exclusion count (agreed with the architect 2026-10-06)

`write_aggregate_export` writes `$excluded->{numeric} = $excluded_numeric;`
unconditionally (D3), as `emit_filter_summary_verbose` already reports
`excluded_numeric` on every run; the `grep { defined } (...)` over the six
filter bounds goes with it. The export's other conditional causes
(`time_window`, `profile`, `filter`, each written only when its option is
given) are outside D3 and unchanged.

### 5.8 User surfaces (agreed with the architect 2026-10-06)

**The twelve bound rows, one phrasing** (D1), generated from the declaration in
`print_help`, mirrored in `docs/usage.md`:

| Row | Text |
|---|---|
| filter minimum | `Hide log entries whose <metric> is below N; an entry at N is kept. <unit sentence>` |
| filter maximum | `Hide log entries whose <metric> is above N; an entry at N is kept. <unit sentence>` |
| highlight minimum | `Highlight log entries whose <metric> is at or above N, without filtering anything out. <unit sentence>` |
| highlight maximum | `Highlight log entries whose <metric> is at or below N, without filtering anything out. <unit sentence>` |

`<metric>` is `duration`, `response size` or `count`. The unit sentence names
the bare number's unit, which no row states today (§ 3 item 5), and points to
the *Units* section: `A bare N is in milliseconds; N also takes a time unit (see
'ltl --help units').`, `A bare N is in bytes; N also takes a byte unit (...)`,
`N also takes a count unit (...)`. The rows of `-n`, `-gc` and the hidden
consolidation counts gain the count sentence.

**The *Units* section of `docs/usage.md`** (D23): the three kinds; per kind the
spellings (interpolated lists in `--help`; in `docs/usage.md` the byte words
too, D24), the case rule (D11), the base unit of a bare number per option,
fractions on bounds and whole numbers on sizes (D20), and examples (`-dmin
200us`, `-bmin 5MB`, `-bmin 2MiB`, `-gc 2M`, `-bs 7d`).

**`ltl --help units`** prints the same content, without the long byte words
(D24), from a renderer beside `print_help_statistics`. It is added to the topic
dispatch in `dispatch_informational_options`, to its error text (`try:
statistics, formats, profile`) and to the `-?, --help [<topic>]` row; those
three lists are #614's to derive from one topic table (its stage-4 lock 5), and
this issue adds `units` to each as they stand.

**Release notes.** One bullet: numeric, byte and duration options accept a value
with a unit; see `docs/usage.md` § Units. The negative-bound error and the
duration note are part of the same change.

### 5.9 The patterns, their pointers and their checks (agreed with the architect 2026-10-06)

**The quantity units pattern (D14).**

- **Entry.** `docs/architecture-patterns.md` gains *Quantity units*
  (the architect's name for the pattern, 2026-10-06), after *Declarative table with one
  resolver*, whose ladders it reads (the audit's item P placed it there).
  Definition: an option whose value is a count, a byte size or a duration is a
  row of the declaration (§ 5.2) and is read by `resolve_quantity_option`
  (§ 5.3) against its kind's vocabulary (§ 5.4); a numeric option that stays a
  bare number is listed with its reason. Consumption sites: the declaration,
  `resolve_quantity_option`, the `-bs` call, `number_unit_canonical`, the
  generated help rows, `emit_option_resolution_verbose`. The *Declarative
  table* entry's `time_unit_canonical` and `byte_unit_canonical` sites gain the
  options of the quantity units declaration and `-tp` (§ 3 item 9), and a `number_unit_canonical` site is
  added; *One resolution surface per vocabulary* drops #605 from its status
  line.
- **The bare-number list.** A file-scope table beside the declaration, each
  numeric option that stays bare with its reason (`'heatmap-width' => 'columns,
  not a quantity'`), so the choice is made where a developer adding an option
  sees it.
- **Pointer.** `.claude/rules/ltl-source.md` gains one line: an option whose
  value is a count, a byte size or a duration is a row of the quantity units
  declaration and is read by `resolve_quantity_option`; a numeric option that
  stays bare is listed with its reason; see the entry.
- **Check.** `tests/validate-option-resolution.sh` (named for the section it
  validates) carries two structural scenarios in the shape of
  `validate-byte-units.sh`'s `one-ladder-structure` (the source is read, each
  rule a `CHECK` line):
  - `quantity-units-declared`: every `GetOptions` entry typed `=i` or `=f` is
    in the bare-number list; every declaration row is typed `=s` and is read by
    `resolve_quantity_option`; no number-and-unit split exists outside it;
  - `printed-spellings-accepted`: for each kind, every spelling the output
    prints (the time ladder's short, medium and long names, the byte ladder's
    tokens and words, the number ladder's three tiers) resolves through that
    kind's canonical sub (D24).

**The `-V` content-shape pattern (D25, D29).**

- **Record.** `tests/HARNESS-DESIGN.md` § Content shape (§ 5.6.2).
- **Entry.** The existing *`-V` telemetry sections as the test surface* entry
  gains the content shape in its definition and § Content shape as part of its
  owning record.
- **Pointer.** The `.claude/rules/ltl-source.md` line on `-V` changes ("read
  `tests/HARNESS-DESIGN.md` first") names § Content shape.
- **Check.** `tests/validate-verbose-content-shape.sh`: runs `ltl` on the
  smallest set of invocations that requests every registered section, and fails
  on a line that breaks D29 (a key that is not snake_case, an entity line not
  of the form `<entity>: <name>`, an absent value other than `-`); a registered
  section none of its invocations emits is a failure too, so a new section
  cannot escape it.

---

## 6. Acceptance criteria

Each is a condition and an observable outcome, triaged per
`docs/test-driven-development.md`. Every `ltl` invocation is shaped to its
assertion (`-bs 1440 -ni` and only the options the assertion reads). The
surface named is where the outcome is observed.

**The bound declaration (§ 2.1)**

- [ ] **AC1.** Every site of § 5.1 except the read loop reads the declaration:
  no list of the twelve bound scalars, or of their option names, exists outside
  it. *Assertable:* structural `CHECK` in `validate-option-resolution.sh`
  (`quantity-units-declared`).
- [ ] **AC2.** `-dmin -5` (and a negative value on each of the twelve) stops the
  run with a non-zero exit and `Invalid -dmin '-5': a bound cannot be
  negative`; `-n -1` behaves as before. *Assertable:* exit code and stderr.
- [ ] **AC3.** An `-o` run with no bound writes `numeric: 0` in the export's
  `excluded:` mapping. *Assertable:* `-V aggregate-export` and the YAML file.
- [ ] **AC4.** The twelve help rows use the one phrasing of § 5.8 and state the
  bare number's unit; each matches its `docs/usage.md` row. *Assertable:*
  `validate-help-content.sh` parity.
- [ ] **AC5.** For every command line valid today, the index signature is
  byte-identical to the base build's (`-dmin 200 -bmax 5000` writes
  `-bmax=5000;-dmin=200`, highlights absent). *Assertable:*
  `index_filter_signature` in `-V runtime-config`, base against branch.

**Units on input (§ 2.2)**

- [ ] **AC6.** A bare number is unchanged on every option of D13: the same
  output and the same `-V runtime-config` value as the base build.
  *Assertable:* the regression goldens; `option-resolution` shows `entered`
  equal to `resolved`.
- [ ] **AC7.** A value with a unit behaves as its bare equivalent: `-dmin 2s` as
  `-dmin 2000`, `-bmin 5MB` as `-bmin 5000000`, `-bmin 2MiB` as `-bmin
  2097152`, `-hcmin 1.5k` as `-hcmin 1500`, `-gc 2M` as `-gc 2000000`. Same
  `excluded_numeric` and `lines_highlighted`, same `resolved`. *Assertable:*
  `-V filter-summary`, `-V option-resolution`.
- [ ] **AC8.** `-dmin 200us` on a log whose durations carry a fraction of a
  millisecond keeps the lines at 0.2 ms and above and excludes those below.
  *Assertable:* `excluded_numeric` on a new committed fixture of bracketed
  microsecond durations either side of 200 µs (no tracked fixture carries
  sub-millisecond values today).
- [ ] **AC9.** Case and spellings: `-cmin 5m` and `-cmin 5M` both resolve to
  5000000; `-dmin 5m` to 300000; `-bmin 1KB`, `1kb`, `1kB` and `1kilobyte`
  to 1000; `-cmin 1kil`, `1thousand`, `1G`, `1B`, `1Bil` to their factors.
  *Assertable:* `-V option-resolution`.
- [ ] **AC10.** Every spelling the output prints for a kind is accepted on
  input of that kind. *Assertable:* structural `printed-spellings-accepted`.
- [ ] **AC11.** `-bmin 5s`, `-bmin 1M`, `-cmin 5x`, `-n 2.5`, `-gc 1.2345k`
  each stop the run with a non-zero exit and a message naming the option,
  quoting the text and listing the kind's units as the ladder's interpolated
  list. *Assertable:* exit code, stderr against the list `--help units` prints.
- [ ] **AC12.** `-dmin 2s -dmax 500ms` warns `-dmin 2s is greater than -dmax
  500ms`, quoting both as typed. *Assertable:* stderr.
- [ ] **AC13.** `-dmin 200us` on a log whose format declares milliseconds prints
  the note of § 5.5; `-dmin 2ms` and `-dmin 0.2` print none; the bound is
  applied either way. *Assertable:* stderr and `excluded_numeric`.
- [ ] **AC14.** `-V runtime-config` carries `duration_min: 0.2` for `-dmin
  200us`; `-dmin 200us` and `-dmin 0.2` write the same signature.
  *Assertable:* `-V runtime-config`.
- [ ] **AC15.** `-V option-resolution` has one block per given unit-bearing
  option, `-bs` and `-tp` included, and none for an option not given.
  *Assertable:* the section.
- [ ] **AC16.** `ltl --help units` prints the three kinds with the ladders'
  interpolated lists and no long byte word; `docs/usage.md` § Units lists the
  words; each unit-bearing option's row points to it. *Assertable:*
  `validate-help-content.sh`.

**The patterns (§ 2.3, § 5.9)**

- [ ] **AC17.** `quantity-units-declared` fails on a copy of `ltl` with a new
  `=i` option absent from the bare-number list, and on a copy whose `-dmin` row
  is read without `resolve_quantity_option`. *Assertable:* the harness's
  can-fail proof (`tests/HARNESS-DESIGN.md` § Proving a new assertion can fail).
- [ ] **AC18.** `validate-verbose-content-shape.sh` passes on every registered
  section after the conversion, and fails on a doctored line of each rule (a
  kebab-case key, `(not set)`, a malformed entity line) and on a registered
  section no invocation emits. *Assertable:* the harness and its can-fail
  proof.
- [ ] **AC19.** After the conversion (D26 to D28), every harness reading a
  converted section asserts the same facts it asserted before, under the new
  keys. *Assertable:* the full suite, each converted assertion seen failing on
  the old key first.
- [ ] **AC20.** The patterns entry, the `.claude/rules/ltl-source.md` lines and
  `tests/HARNESS-DESIGN.md` § Content shape exist and name each other.
  *Unassertable* that a developer reads them; their presence is a review item
  at the merge gate. The checks of AC17 and AC18 carry the enforcement.

**Cross-cutting**

- [ ] **AC21.** No ` at <file> line <N>` on `ltl`'s stderr in any scenario.
  *Assertable:* `tests/lib/runtime-warnings.sh`.
- [ ] **AC22.** No regression on the read loop. *Assertable:* the before/after
  benchmark (§ 8).

---

## 7. Verification surface

**New harnesses**

| Harness | Asserts |
|---|---|
| `tests/validate-option-resolution.sh` | AC1, AC2, AC6 to AC15, AC17: the section, the unit behaviour, the rejections and notes, and the two structural scenarios `quantity-units-declared` and `printed-spellings-accepted` |
| `tests/validate-verbose-content-shape.sh` | AC18: every registered section against the content shape |

**Harnesses changed**

| Harness | Change |
|---|---|
| `validate-help-content.sh` | AC4 (twelve rows, one phrasing, parity), AC16 (`--help units`, the *Units* section); the `J-unit-list-parity` scenario gains the count list |
| `validate-index-read-back.sh` | AC5 (signature byte-identical to the base build), AC14 (equal values, one signature) |
| `validate-aggregate-export.sh` | AC3 (`numeric: 0`) |
| `validate-byte-units.sh` | `one-ladder-structure` admits the number ladder's `also` spellings (`G`) without reading them as a byte prefix table; `%si_units` gone |
| consumers of converted keys (D26 to D28) | `validate-runtime-config.sh`, `validate-bucket-size-units.sh`, `validate-message-discard.sh`, `validate-message-mask.sh`, `validate-message-expose.sh` (`runtime-config`); `validate-statistics-demand.sh`; `validate-heatmap-palette.sh`, `validate-screenshot-capture.sh` (`heatmap-palette`); `validate-udm-counting.sh`, `validate-format-detection.sh` (`udm-counting`); `validate-message-grouping.sh`, `validate-message-control-characters.sh`, `validate-statistics.sh` (`message-grouping`); `validate-timestamp-precision.sh` (reads `aggregate-export` and `index-read-back`). The list is completed by `grep -r "=== <name> ===" tests/` and a search for each converted key in the drop that converts (`tests/HARNESS-DESIGN.md` § Stability contract) |
| `validate-regression.sh` | goldens re-captured where `--help` rows or a converted `-V` key appear in them, once, in the drop that changes them |

**Fixtures.** A committed `.txt` fixture of bracketed microsecond durations
either side of 200 µs (AC8, AC13); the twelve-bound boundary fixture already
used by the numeric-criteria harnesses serves AC2, AC7 and AC12. Every fixture
is confirmed tracked with `git ls-files` before a scenario is planned on it.

---

## 8. Measurement obligations

- **What touches the read loop.** The twelve scalars and the comparisons stay
  (D4); a bound may now hold a fraction, which the comparison already handles.
  Nothing new runs per line. The parse, the checks and the note run once per
  run.
- **No prototype.** No new data model, no new per-line path, and every
  verification method is known (`prototype/README.md` § When a prototype is
  required).
- **The before/after benchmark** on `single-day-access-log-standard`, the
  `before` captured on the base commit before the first `ltl` change, both runs
  from the same kind of checkout (two worktrees side by side). The conversion of
  `-V` sections runs only under `-V`, outside the benchmark's timed path.

---

## 9. Delivery

Each drop is a commit and a push on `605-input-units`. One PR at the end.
`$version_number` reads `0.19.0-605` from the first `ltl` change and is
restored to `0.19.0` before the gate.

| Drop | Content | Criteria |
|---|---|---|
| 0 | this specification | the design and criteria are the architect's |
| 1 | the `before` benchmark on the base commit; the declaration's twelve bound rows and every site of § 5.1 derived from it; the negative-bound check; `numeric` always in the export; the twelve help rows in one phrasing | AC1 to AC5 |
| 2 | `resolve_quantity_option`, the number vocabulary and the byte words; the five size rows; `-bs` on the shared parse; rejections, the inverted-range quote and the duration note; `-V option-resolution`; the *Units* section and `--help units`; the sub-millisecond fixture | AC6 to AC16 |
| 3 | `tests/HARNESS-DESIGN.md` § Content shape; the sections converted (D26 to D28) with every consumer in the same commit; `validate-verbose-content-shape.sh` | AC18, AC19 |
| 4 | the *Quantity units* entry, the bare-number list's structural check, the `.claude/rules/ltl-source.md` lines, the `-V` entry's content shape | AC17, AC20 |
| 5 | the records of § 10; the release note | AC21, AC22 at the gate |

**Merge gate.** The full harness suite (`CI=1 ./tests/validate-csv-output.sh`,
then `CI=1 ./tests/validate-statistics.sh`, then the rest) on the commit being
merged; the before/after benchmark on `single-day-access-log-standard`;
`tests/validate-help-content.sh`.

---

## 10. Records to update

**With this specification (drop 0).**

| Record | Update |
|---|---|
| #605 | a comment pointing here: specification agreed, D11 to D29 locked 2026-10-06 |
| #688 (the medium tier writes a thousand as `Kil`) | filed 2026-10-06 from D12 |

**At implementation delivery.**

| Record | Update |
|---|---|
| `docs/architecture-patterns.md` | the *Quantity units* entry; the *Declarative table with one resolver* sites (§ 5.9); *One resolution surface per vocabulary* drops #605 from its status line; the *`-V` telemetry sections* entry gains the content shape |
| `tests/HARNESS-DESIGN.md` | § Content shape; `option-resolution` from *Reserved* to *Implemented*; the converted sections' descriptions where they name a key |
| `.claude/rules/ltl-source.md` | the quantity units line; the `-V` line names § Content shape |
| `features/608-byte-unit-ladder.md` § 5.2 | the one-spelling-per-token rule amended for input by D24 |
| `features/user-defined-metrics.md` § Unit Types | the time units the ladder carries (§ 3 item 9); the multipliers read from the number ladder |
| `features/312-numeric-criteria-highlight-selection.md` § Option surface | the twelve options accept a unit and are declared once (D1, D13) |
| `features/342-redundant-logic-surfaces-audit-report.md` § Review progress | stage 11 to *done* when this issue closes |
| `features/503-yaml-aggregate-export.md` § D12 and the schema comment | `excluded.numeric` written on every run (D3); done in drop 1 |
| the owning feature docs of the converted sections | each section contract that names a converted key or value |
| #620 (hoisting the read loop's run-constant tests) | a comment: the twelve bounds are declared in one table, whose rows point at the scalars the loop reads |
| #614 (operand checks) | a comment: `units` was added to the `--help` topic dispatch, its error and its row, three lists its topic table derives |
| Release notes | one bullet (§ 5.8) |

---

## Findings from implementation

- **Drop 1 (2026-10-06).** The twelve bounds are the rows of one file-scope
  table, `@quantity_options` in `ltl`, beside the twelve scalars it points at.
  The eight hand-written lists of § 3 item 6 and the twelve help rows read it;
  `tests/validate-option-resolution.sh` `quantity-units-declared` found
  exactly those eight sites on the base build (43 lines naming a bound scalar,
  54 quoting a bound option name, the twelve help rows among them) and finds none after, and fails on a copy of `ltl`
  with one scalar test and one quoted option name added back. The `GetOptions`
  rows are still `=i`; they become `=s` with the parse in drop 2.
- **The help rows carry the bare unit only, until units exist.** Drop 1 writes
  § 5.8's phrasing with `N is in milliseconds.` and `N is in bytes.` (nothing
  for a count); the word *bare* and the pointer to `ltl --help units` join the
  rows in drop 2, with the *Units* section they point at.
- **AC5's surface.** `index_filter_signature` is a key of `-V index-read-back`,
  not of `-V runtime-config` as AC5 is worded; the assertion reads it there
  (`tests/validate-index-read-back.sh` `bound-signature-unchanged`, five command
  lines, expected values captured from the base build at f7c5daa).
- **The export's key rules.** `tests/aggregate-export/rules/keys.tsv` declared
  `population.lines.excluded.numeric` conditional on a numeric threshold; D3
  makes it required, and `features/503-yaml-aggregate-export.md` § D12 records
  the amendment.
- **Running from a worktree.** A worktree has no `logs/`; every harness and the
  benchmark run with `LTL_LOGS_DIR` pointing at the main checkout's corpus
  (`tests/HARNESS-DESIGN.md` § The log corpus is resolved).

## Findings from the interview

- **Sub-millisecond duration bounds need no new machinery.** A line's duration
  is converted to milliseconds with its fraction kept (`convert_duration_to_ms`
  divides microseconds and nanoseconds down), and the filter comparison in
  `read_and_process_logs` compares that fractional value
  (`$duration < $filter_duration_min`). Only the option's whole-number type
  (`'duration-min|dmin=i'`) refuses `0.2` today. With a unit, `-dmin 200us` is
  stored and applied as 0.2 ms, exactly as written (architect, 2026-10-06).
- **The log's duration unit is the declared one** (architect, 2026-10-06): `-du`
  when given, else the format spec's `duration_unit`; it is not detected from
  the data (§ 5.5).
- **A bound finer than the log carries** is settled by D22: a note,
  in the shape of the existing precision note printed by
  `resolve_timestamp_precision`; nothing is clamped.
