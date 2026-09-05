# #524 — `--bucket-size` accepts a unit

Issue #524 (`-bs`/`--bucket-size` accepts a value with a unit, converted through
the conversion the user-defined-metric units already use).

Status: implemented on branch `524-bucket-size-accepts-a-unit-2` (the
specification branch was merged and deleted under PR #526). D1 (one ladder,
every time-unit surface converged in this issue), D2 (the ladder, its
spellings, month 30 days and year 365 days) and D4 (precision separate from
bucket width) are locked, including the complete display ladder; D3 (grammar:
bare number unchanged, `-s`/`-ms` set its unit) and D5 (documentation) are
locked. Every decision is locked; the acceptance criteria below are agreed with
them and asserted by `tests/validate-bucket-size-units.sh`. Findings made
while implementing are in § Implementation findings.

## Requirement

`-bs` reads a bare number as minutes, or as seconds under `-s`, or as
milliseconds under `-ms`. A day-, week- or hour-wide bucket has to be worked out
in that unit by hand, which is error-prone and reads badly in a recorded command
line. The bucket size should also accept `<number><unit>`: `-bs 1d`, `-bs 24h`
and `-bs 1440` produce the same timeline. The value may be a decimal
(`-bs 1.5h`, `-bs 0.25month`). `m` stays minute on every surface; a month is
asked for by an unambiguous spelling. The unit ladder runs from nanoseconds to
years with every step filled in.

The conversion is the one the user-defined-metric unit slot already uses, so one
place owns the vocabulary and the multipliers on both surfaces. `--help` and
`docs/usage.md` document the accepted forms in the same change.

## What exists today (audited on the base commit of this branch)

- `-bs` is declared `bucket-size|bs=i` in `GetOptions`; a non-integer value is
  rejected by the option parser before `ltl` sees it. `-bs 0` (or absent) falls
  through to the terminal-height default in `adapt_to_terminal_settings()`.
- `adapt_to_terminal_settings()` converts `$time_bucket_size` to
  `$bucket_size_seconds` by the run's unit (`-s`: as-is, `-ms`: ÷1000, else ×60).
  Everything downstream reads `$bucket_size_seconds`; `$time_bucket_size` itself
  reaches only `-V runtime-config` (`bucket-size:` row) and `-V benchmark-data`
  (`CONFIG time_bucket_size`, printed with `%d`).
- The user-defined-metric unit vocabulary lives as lexicals inside
  `parse_udm_configs()`: `%time_units` (`ns us ms s m h`), a lower-casing
  canonical map with the one alias `min` → `m`, and the byte and SI tables. The
  multipliers live separately in `convert_duration_to_ms()` as an if-ladder over
  the same six tokens. Vocabulary and conversion are therefore two surfaces
  already, both private to their sub.
- `convert_duration_to_ms()` is also called per line in `read_and_process_logs()`
  for every duration when `-du` is set or the format declares a non-`ms` unit.
  It is on the hot path in those runs.
- Two more private unit tables exist with overlapping tokens: `format_time()`
  (display scaling, `us` … `D` for days) and `%rate_multiplier` for `-ru`
  (`s m h d`). `-du` validates its own four tokens inline.

## Decisions

### D1 — One time-unit ladder at file scope, read by every time-unit surface

A single file-scope table is the only definition of time units in `ltl`. Each
step carries: the canonical token, its accepted spellings, its length in
milliseconds, and its display names (short `ms`, medium `msec`, long
`milliseconds`; the names `format_time()` holds today, extended to every step).
Every surface that reads, validates, converts or names a time unit reads this
table; no sub keeps a token list, a unit regex, or a multiplier of its own.
Normalisation and de-duplication are part of this issue, not a follow-up.

| surface | today | after |
|---|---|---|
| `convert_duration_to_ms()` (per-line converter) | if-ladder over six tokens | one lookup, one multiply |
| `parse_udm_configs()` unit slot | lexical `%time_units` + canonical map | reads the table; SI tokens still checked case-sensitively first so `M` stays mega |
| `-bs` (this issue) | integer only | `<number>[<unit>]`, any ladder spelling |
| `-du` validation | inline regex `ns\|us\|ms\|s`, four tokens | any ladder token; `duration_unit_resolved` in `-V csv-output` may carry any canonical token |
| `-ru` | `%rate_multiplier`, `%rate_suffix`, `%rate_csv_suffix`, four tokens, regex validation | any ladder token; multiplier from the ladder length; terminal suffix `/` + short name, CSV suffix `_` + medium name (the existing four render exactly as today: `/m`, `_min`, `_sec`, `_hr`, `_day`) |
| `format_time()` display scaler | private `%units` and `%unit_names`, `us` … `D` | reads the table and climbs the whole ladder, nanoseconds to years, choosing the largest unit the value reaches; names from the table |

Parsing surfaces are mutually sufficient: every spelling `-bs` accepts is
accepted by `-du`, `-ru` and the metric unit slot, and vice versa. The metric
unit slot therefore gains `d`, `w`, `month` and `year`; `-du` gains `m` and up;
`-ru` gains `ns` to `ms` below and `w`, `month`, `year` above. `--help` and
`docs/usage.md` rows for `-du`, `-ru` and the metric unit slot list the ladder.

The display scaler climbs the complete ladder (locked). A summed duration or
corpus span over seven days renders in weeks, over thirty days in months, over
a year in years, with the fixed lengths D2 locks; regression goldens carrying
such values are re-blessed as part of this work. A ladder complete for parsing
but truncated for display would be the split this issue removes.

The byte and SI unit tables in `parse_udm_configs()` are a different value
class and are not part of the time ladder.

### D2 — The ladder and its spellings (locked)

| step | canonical | also accepted | length |
|---|---|---|---|
| nanosecond | `ns` | `nsec` | 10⁻⁶ ms |
| microsecond | `us` | `usec` | 10⁻³ ms |
| millisecond | `ms` | `msec` | 1 ms |
| second | `s` | `sec`, `second`, `seconds` | 1 000 ms |
| minute | `m` | `min`, `minute`, `minutes` | 60 s |
| hour | `h` | `hr`, `hour`, `hours` | 60 min |
| day | `d` | `day`, `days` | 24 h |
| week | `w` | `wk`, `week`, `weeks` | 7 d |
| month | `month` | `mo`, `mon`, `months` | 30 d |
| year | `year` | `y`, `yr`, `years` | 365 d |

Matching is case-insensitive on this table (`1D`, `1H`, `1M` read as day, hour,
minute). `m` is minute everywhere; no spelling that could be read as minute means
month.

Month and year are fixed lengths, not calendar months or years: the timeline's
buckets are fixed-width (`int(epoch / size) * size`), so a calendar-aligned
month is not representable. 30 and 365 days keep every ladder step a whole
number of minutes, so a bucket asked for in any unit resolves to a whole number
in a minute-display run. The mean calendar lengths (30.4375 and 365.25 days)
were considered and rejected: they make a one-month bucket fractional in every
run unit.

### D3 — `-bs` value grammar and resolution (locked)

`-bs <number>[<unit>]`. `<number>` is a decimal (`1`, `1.5`, `.5`) and must be
positive. No whitespace between number and unit. A bare number is never
rejected and keeps today's meaning exactly: minutes, or seconds under `-s`, or
milliseconds under `-ms`; `-s` and `-ms` go on setting the unit of a bare
number, so every existing invocation and fixture is untouched. A number with a
unit is converted by
`convert_duration_to_ms()` and then expressed in the run's unit (minutes, or
seconds under `-s`, or milliseconds under `-ms`), so `$time_bucket_size` and
`$bucket_size_seconds` carry the same meaning they do today. The `GetOptions`
declaration becomes `=s`, and the value is validated once in
`adapt_to_command_line_options()` beside the `-du` and `-ru` validations.

Only a value that cannot be read at all is rejected, with the usage message and
a non-zero exit in the tone of the `-du` and `-ru` rejections: an unknown unit
(`-bs 5x`), no number at all (`-bs d`), a malformed number (`-bs 1.2.3h`), or a
zero or negative width with a unit. A bare number is never in this set. `-bs 0` today silently means
"auto-size"; it is not documented and this issue does not change it.

The resolved value may be fractional in the run's unit (`-bs 90s` on a
minute-display run is 1.5). `$bucket_size_seconds` carries it exactly. The two
`-V` rows that print `$time_bucket_size` print the resolved value in the run's
unit, with decimals only when the value is fractional (`bucket-size: 1440`,
`time_bucket_size 1.5`); the `%d` in `-V benchmark-data` goes.

### D4 — Bucket width and timestamp precision are separate (locked)

A unit on `-bs` sets the bucket width and nothing else. Timestamp precision on
the timeline is the analyst's choice, made with `-s` or `-ms` as today, and is
never inferred from the bucket width in either direction. `-bs 90s` on a plain
run draws 90-second buckets labelled at minute precision (`00:00`, `00:01`,
`00:03`); `-s -bs 90s` labels them with seconds. `-bs 1d` on a plain run keeps
the minute display. `-s` and `-ms` also keep their second job, the unit of a
bare `-bs` number.

A single option that names the timestamp precision outright (minute, second,
millisecond, nanosecond), instead of the two switches, is a separate
enhancement request, filed as issue #525.

### D5 — Documentation (locked)

`--help` row for `-bs` describes the two forms in one sentence and names the
ladder; `-s` and `-ms` rows say they set the unit of a bare number and the
timestamp precision. The `-du`, `-ru` and metric `unit` rows list the ladder
they now share. Same rows in `docs/usage.md`; the examples block gains a
`-bs 1d` example that `tests/validate-doc-examples.sh` runs. No internals in
any of them.

## Not a prototype trigger

No data model changes and no new per-line cost. `convert_duration_to_ms()` is
already on the per-line path when a unit conversion applies; replacing six
string comparisons with one hash lookup and a multiply is a changed constant, not
a new cost. The before/after benchmark at the gate is the measurement; the
`before` capture goes on the base commit before the first line of code.

## Acceptance criteria

Method for the equivalence criteria: two runs are compared on the timeline text
and on `bucket_size_seconds` from `-V benchmark-data`, on
`tests/fixtures/profile-weekend-fold.txt` (spans days) with `-bs 1440 -oe` shaped
to the assertion. A new harness `tests/validate-bucket-size-units.sh` owns them
(file name tracks the surface; `-V benchmark-data` and `-V runtime-config` rows
are the contracts, both existing).

1. **Unit and bare number agree** (assertable): `-bs 1d`, `-bs 24h`, `-bs 1440`
   produce byte-identical timeline output and the same `bucket_size_seconds`.
2. **The run's unit is honoured** (assertable): `-s -bs 2m` matches `-s -bs 120`;
   `-ms -bs 1s` matches `-ms -bs 1000`; `-bs 1h` matches `-s -bs 3600` in
   `bucket_size_seconds`.
3. **Decimals and the minute/month split** (assertable): `-bs 1.5h` matches
   `-bs 90`; `-bs 1m` matches `-bs 1`; `-bs 1month` matches `-bs 43200`;
   `-bs 0.5month` matches `-bs 21600`; `-bs 1M` matches `-bs 1`.
4. **The bare number is unchanged** (assertable): the regression harness passes
   unchanged; `-bs 5`, `-s -bs 30`, `-ms -bs 100` are byte-identical before and
   after on the fixtures the doc examples run.
5. **One mechanism** (assertable, names the mechanism): every spelling on the
   ladder is accepted by `-bs`, `-du`, `-ru` and the user-defined-metric unit
   slot, checked by looping the ladder through all four; `-udm "x:d:max"` is
   reported in `-V udm-specs` with unit `d` and a value converted by the same
   multiplier `-bs 1d` resolves with; `-ru w` scales err-rate by the same length
   `-bs 1w` resolves to. The structural half: exactly one ladder definition
   exists in `ltl`, and no `qw(...)` token list or `ns|us|ms|s`-style regex of
   time units remains outside it.
5a. **Existing surfaces render unchanged below seven days** (assertable): the
   regression harness passes, with goldens re-blessed only where a rendered
   duration reaches a week or more; `-ru s`, `-ru m`, `-ru h`, `-ru d` keep
   their terminal and CSV suffixes; the duration-display harness passes.
5b. **The display ladder is complete** (assertable): a duration of 10 days
   renders `1.4w`, 45 days `1.5mo`, 400 days `1.1y`, 500 ns `500ns`, via
   `format_time()` on a message total or the aggregate-export span.
6. **Rejections** (assertable): `-bs 5x`, `-bs d`, `-bs 1.2.3h`, `-bs -1h`,
   `-bs 0h` exit non-zero with a usage line naming the accepted forms; no
   runtime warning on stderr.
7. **Precision is untouched by the unit** (assertable): `-bs 90s` on a plain
   run renders timestamps at minute precision and `bucket_size_seconds` 90;
   `-s -bs 90s` renders the same timeline as `-s -bs 90`; `-ms -bs 500ms` the
   same as `-ms -bs 500`; `-bs 1d` on a plain run renders the same as
   `-bs 1440`.
8. **`-V` rows report the resolved value** (assertable): `-V runtime-config`
   shows `bucket-size: 1440` for `-bs 1d` and `bucket-size: 1.5` for `-bs 90s`
   on a minute run; `-V benchmark-data` `time_bucket_size` agrees.
   `tests/validate-runtime-config.sh` keeps passing (its bucket-size assertions
   use bare numbers).
9. **Docs agree** (assertable): `tests/validate-help-content.sh` passes; the new
   `-bs 1d` example in `docs/usage.md` runs under
   `tests/validate-doc-examples.sh`.
10. **No runtime warnings** (assertable): no ` at ltl line N` on stderr across
    every run above.
11. **Rendered check** (visual, done by looking): a multi-day corpus from
    `docs/test-logs.md` at `-bs 1d` and `-bs 1w`, and a one-minute window at
    `-bs 500ms`, inspected on the terminal before the work is called done.

No criterion is unassertable or unknown.

## Implementation findings

Recorded on the tree as implemented (2026-09-03).

- **Where the ladder lives.** `@time_unit_ladder` in the globals, with two
  derived lookups (`%time_unit_step` by canonical token,
  `%time_unit_by_spelling` by lower-cased spelling) and one shared
  canonicaliser, `time_unit_canonical()`. The `-ru` multiplier and its two
  suffix tables are now views computed from the ladder (seconds per step, `/`
  plus the short name, `_` plus the medium name), so the four existing rate
  units render exactly as before and every other step follows the same rule.
  The unit a bare `-bs` number carries is resolved once into
  `$bucket_size_unit` and read by the seconds conversion in
  `adapt_to_terminal_settings()`, which no longer restates the minute and
  millisecond multipliers.
- **A zero duration now renders `0ns`, not `0us`.** `format_time()` climbs
  the ladder from its lowest step, and a value that reaches no step renders in
  that step; the old scaler started at microseconds, so zero read `0us`. One
  golden carried the old form, `tests/reference-output/ms-w160.txt` (21 cells
  in the per-bucket duration column, all at zero), and was re-blessed. This is
  the only rendered change below seven days, so acceptance criterion 5a holds
  on every other golden. The proper rendering of a zero duration on that
  column is the cause #444 D16 traces (`features/444-access-log-format-family-and-user-surface.md`);
  the latency cells already render zero in the resolved unit through
  `format_duration()` and are unchanged.
- **Sub-millisecond steps convert by division.** The per-line converter is
  one lookup and one multiply for every step from the millisecond up; the
  nanosecond and microsecond steps carry a divisor instead, because
  `$value / 1000` and `$value * 0.001` are not the same double for every
  value, and the `-du us` and `-du ns` paths must produce the values they
  produced before. The display scaler multiplies by the same divisor when a
  value lands on one of those steps.
- **`min` cannot name the minute in the metric unit slot.** `parse_udm_configs()`
  reads any aggregation name in the unit slot as a mis-slotted function and
  rejects the spec with a corrected spelling (the rule recorded in
  `features/user-defined-metrics.md`), and `min` is both an aggregation and a
  ladder spelling. This predates the ladder: the old private map also carried
  `min`, and the function-name check fired first then too. The other three
  parsing surfaces accept `min`; the metric slot accepts `m`, `minute` and
  `minutes`. The harness exercises the metric slot with `minutes` in place of
  `min` and this note is the record of the one spelling on which the surfaces
  are not mutually sufficient. Reconciling the two rules is the architect's
  call and is not made here.
- **The epoch-timestamp path of CSV input** (`-du` applied to an epoch column)
  converted through its own three-line divisor chain; it now reads the ladder
  step, multiplying for the second and above and dividing below, so `-du m` on
  an epoch column is honoured the same way as `-du us`.
- **Fixture.** `tests/fixtures/bucket-size-units.txt` (four lines: 10, 45 and
  400 days, and a value that reads as 500 ns under `-du ns`) is the display
  ladder's producer; recorded in `docs/test-logs.md`.
- **CSV column rules.** `tests/csv-output/rules/stats-columns.tsv` gains the
  `err-rate_*` and `msg-rate_*` columns for the six new rate suffixes
  (`_nsec`, `_usec`, `_msec`, `_wk`, `_mon`, `_yr`), so the structural
  validator can represent every column the tool can now emit; the
  `duration_unit_resolved` enum in `tests/csv-output/validate-csv-output.pl`
  accepts every canonical token.

## Merge gate

Scope table row: executable lines of `ltl` change, so the full harness suite and
the before/after benchmark on this machine, `single-day-access-log-standard`,
labels `524-before` (base commit) and `524-after`. The per-line converter is the
one hot-path constant touched; any metric worse by more than 5% stops the merge.
`$version_number` restored to `0.18.0` before the gate.
