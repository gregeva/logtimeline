# One timestamp formatter, then a single timestamp-precision option (Issue #525)

## Status

Specification agreed with the architect 2026-09-29 on branch
`525-timestamp-precision-option` off `release/0.19.0`. Implementation in
progress: drop 1 (the one formatter) delivered 2026-10-02, § 10.
Amended 2026-09-29, after the agreed specification merged, with D13
(the run index writes at the run's resolved precision and its drift check
follows the runtime options), D14 (the bucket key's scale follows `-bs` alone)
and D15 (the drift check compares at the run's precision, or at the stored
row's when that is coarser); amended again 2026-09-29 with D16 (a
minute-precision run writes whole-second index timestamps under a precision
column that says minute), D17 (the index's selection rows carry the precision
column as the file rows do) and D18 (drift compares timestamps as numbers
rounded to the comparison precision, never as strings); amended again
2026-09-29 with D19 (an index row written before this change, whose precision
column carries `-`, is read at the precision its stored timestamps' digits
carry, and no old row is rewritten). The architect's decisions are § 4 (D1 to
D19); no element of the run index's design remains **proposed**. A design
element that no decision settles is implementation detail and is marked
**proposed**.

---

## 1. The motivating consumer

Two consumers, one after the other.

**The analyst zooming into a timeline.** Timestamp precision is the analyst's
choice: minutes for a day, seconds for a burst, milliseconds or microseconds for
what happens inside a second. Today the choice is spread over two switches
(`-s`, `-ms`), the minute default cannot be named, and nothing finer than the
millisecond can be asked for. Worse, the same instant already renders two ways
in one run: with `-ms`, the run summary heading reads `10:00:01.122` for a line
written at `10:00:01.123`, while the run index (`ltl-index.csv`) writes `.123`
for the same line. An analyst comparing the heading with the index, or with the
log, sees two answers. And nothing stops a precision the log never carried: `-ms`
on a log with whole-second timestamps prints `.000` on every label.

**The next change to timestamp rendering.** Every future change to how a
timestamp is written lands on however many sites write one. Two are queued: this
issue's new precisions, and the fixed timezone offset for rendering (#154, which
shifts every rendered timestamp by a fixed offset and is blocked by this issue).
Today there are three formatter subs, five inline copies of the ISO pattern, a
separate stamp for output file names and a fourth sub-second derivation inside
the read loop. Landing either change on that many sites is how the `.122`
against `.123` divergence came about. One formatter first means each later
change is made once.

---

## 2. Requirement

Transcribed from the issue body, the stage 9 lock of the #342 review
(redundant-logic-surfaces audit) and the architect's decisions of 2026-09-29,
organised, not reinterpreted.

### Part one: one timestamp formatter (first requirement, locked 2026-09-27)

- Every site that renders or writes a timestamp calls one formatter, the stamp
  in output file names included (D8).
- The formatter takes an epoch, a precision and an optional `Z`.
- The sub-second part is rounded once, in one place, with carry (D7).
- It replaces the three formatter subs, the ISO pattern restated inline five
  times in the index writer, the index reader and the aggregate export (one of
  them with `Z`), and the file-name stamp.
- Each later precision is then added to one formatter, and the fixed timezone
  offset for rendering (#154) shifts one formatter.

### Part two: the single precision option

- One option, `-tp, --timestamp-precision` (D9), names the timestamp precision:
  minute, second, millisecond, microsecond or nanosecond (D3), written as the
  time-unit ladder's token or its long spelling.
- `-tp` sets the precision at which timestamps are read, stored and rendered,
  and nothing about the bucket width: a bare `-bs` number is minutes whatever
  `-tp` says, and with `-bs` absent the width is the one a run without any
  switch gets (D11).
- The precision printed never goes below the precision the file contains: the
  tool uses the nearest true precision the file provides, read from the
  timestamp field's stated unit and the digits it carries, and says so on
  stderr (D4, D10).
- `-s` and `-ms` are deprecated with a notice for one release; a removal issue
  is filed (D5). Given with a `-tp` of a different precision, either stops the
  run with a usage error (D12).
- The values resolve through the existing time-unit ladder, which gains the long
  sub-second spellings for every time-unit option (D6).
- `--help`, `docs/usage.md` and `-V runtime-config` carry it in the same change
  (D9).
- The run index handles the new precisions: it writes its timestamps at the
  run's resolved precision, whole seconds at minute precision under a
  precision column that says minute (D16), and states the precision on its
  selection rows as on its file rows (D17); its drift check is relevant to the
  options given at runtime (D13), comparing at the run's precision, or at the
  stored row's precision when that is coarser (D15), as numbers, never as
  strings (D18); a row written before this change, whose precision column
  carries `-`, is read at the precision its timestamps' digits carry, with no
  rewrite (D19).
- The bucket key's scale follows `-bs` alone, never the timestamp precision
  (D14).

### Governing decisions from other records

These are locked elsewhere and bind this work. They are restated here, not
renumbered.

| Record | Decision, by what it says |
|---|---|
| `features/524-bucket-size-unit.md` D4 (width and precision separate) | Bucket width and timestamp precision are separate. A unit on `-bs` sets the width and nothing else; precision is never inferred from the width. `-s` and `-ms` keep their second job, the unit of a bare `-bs` number. The single precision option is named there as this issue, "instead of the two switches". |
| `features/524-bucket-size-unit.md` D1, D2 (one ladder, its spellings) | One time-unit ladder at file scope is the only definition of time units; no sub keeps a token list of its own. The ladder's spellings, with `m` as the minute on every time surface. This issue amends the spelling table (D6 below). |
| `features/617-width-to-format-rule.md` D4, D16 (zero in the source's unit; never below the stated unit) | A zero duration renders in the source's resolved unit; a value is never rendered in a unit smaller than its stated unit. D4 below is the same rule for timestamps. |
| `features/608-byte-unit-ladder.md` D9 (decimals default to the source's resolution) | The default decimals on every surface are the source's resolution; more is asked for with `-cp`. |
| `features/503-yaml-aggregate-export.md` D6 (`generated_at` is a clock reading) | The export's `generated_at` is `gmtime()` in `%Y-%m-%dT%H:%M:%SZ`, a real clock reading. |
| `features/503-yaml-aggregate-export.md` D7, D8 (export strings are the heading's) | The export's observation window and bucket timestamps are the strings the run summary heading and the STATS CSV print, verbatim, at the run's precision; under `-pr` the folded day and time strings. |
| `features/179-index-read-back.md` § freshness | The on-disk file time is formatted as `YYYY-MM-DDTHH:MM:SS` UTC and compared by string equality with the index row's `file_mtime`. |
| Audit report § Review progress, stage 10 (the run index) | The run index keeps a fixed precision outside `-cp` (the CSV precision option) for its means, because it is read back and compared for drift. Its timestamps are governed by D13, D15 and D18 instead: written at the run's resolved precision and compared for drift at that precision, or at the stored row's precision when that is coarser, as numbers rather than strings. |

---

## 3. Corrections to the issue body and the audit record

Verified against `release/0.19.0` at 58f8d94 by `grep -F` inside the named subs
and by captured runs (captures in the session scratchpad, not in the repository).

1. **Where the `-s` and `-ms` rows live.** They are in `docs/usage.md`
   § Time & Buckets, not § Display & Output as the issue's Links section says.

2. **`-s` and `-ms` have three jobs, not two.** Besides the timestamp precision
   and the unit of a bare `-bs` number, they set the unit of the default bucket
   width chosen from the terminal height when `-bs` is absent
   (`adapt_to_terminal_settings` :: `$time_bucket_size = 120;` is read in the
   run's unit). Measured on a three-line application log with no `-bs`: a plain
   run reports `bucket_size_seconds 7200.00` in `-V benchmark-data`; the same
   run with `-ms` reports `0.12`, a 120-millisecond default bucket.

3. **`-ms` also changes the bucket-key data model.** Under `-ms` the bucket key
   is an integer count of milliseconds (`read_and_process_logs` ::
   `my $epoch_ms = int($bucket_epoch * 1000 + 0.5);`, and the same derivation in
   `initialize_empty_time_windows`); otherwise it is a floating epoch in
   seconds. Every consumer of a bucket key tests `$print_milliseconds` to know
   which: `format_bucket_timestamp`, `print_bar_graph` ::
   `my $wday = (gmtime($print_milliseconds ? $bucket / 1000 : $bucket))[6];`,
   and `build_column_layout` :: `+ ($print_milliseconds ? 4 : 0)`.

4. **There are three timestamp formatters and a fourth derivation, not two.**
   `format_epoch_iso` rounds; `format_observation_timestamp` truncates the
   product of a binary fraction; `format_bucket_timestamp` prints an exact
   integer millisecond key. The read loop's bucket key rounds to the nearest
   millisecond before flooring to the bucket.

5. **The truncated millisecond is reconfirmed on the current tree.** On an
   application log with millisecond timestamps `.123`, `.456`, `.789`, run with
   `-ms -bs 1000`: the heading reads `2026-01-26 10:00:01.122 and 2026-01-26 10:00:03.789`;
   the index's `first_timestamp` reads `2026-01-26T10:00:01.123`.

6. **The rounding formatter does not carry (not in the audit).**
   `format_epoch_iso` :: `my $ms = int(($epoch - $int_part) * 1000 + 0.5);`
   rounds a fraction of `.9995` or more to 1000 and prints it with `%03d`, so the
   index receives a four-digit fraction. Measured on a four-line application log
   whose last line is at `10:06:13.9996`, read with `-ms -bs 100`: the index's
   `last_timestamp` is `2025-02-20T10:06:13.1000`; the heading, truncating, says
   `10:06:13.999`; the read loop, rounding, puts the line in the `10:06:14.000`
   bucket. Three answers for one line. Because the index's drift check compares
   timestamps as strings (`_lt` :: `return ($a lt $b) if $a =~ /^\d{4}-\d{2}-\d{2}T/;`),
   `.1000` sorts before `.123` of the same second.

7. **The five inline ISO sites are where the audit says.**
   `write_index_file` :: `my $now_iso = strftime("%Y-%m-%dT%H:%M:%S", gmtime());`,
   `my $mtime_iso = strftime(... gmtime($fd->{file_mtime}));` and
   `my $current_mtime = strftime(... gmtime($fd->{file_mtime}));`;
   `read_index_file` :: `my $on_disk_mtime = strftime("%Y-%m-%dT%H:%M:%S", gmtime($stat[9]));`;
   `write_aggregate_export` :: `$determining->{generated_at} = strftime("%Y-%m-%dT%H:%M:%SZ", gmtime());`.
   The ISO formatter has one caller the audit did not list:
   `detect_index_drift` :: `$live_v_fmt = format_epoch_iso($live_v);`, which
   formats live values to compare them with the index as strings.

8. **Nanoseconds are not parsed, and the data model cannot hold them.**
   - The generic sub-second strip keeps at most six digits
     (`format_entry_block_src` emits
     `s/(:\d{2}:\d{2})[.,](\d{1,6})/$1/` and
     `$fractional_ms = $2 * (10 ** (3 - length($2)))`): microseconds survive as a
     fractional millisecond; digits seven to nine are dropped. Measured on a
     line written at `.123456789`: it parses and buckets correctly, the three
     trailing digits are discarded.
   - Formats declaring `frac => 'fixed3'` carry milliseconds only; the
     access-log formats (`frac => 'none'`) carry whole seconds.
   - The parsed instant is held as a floating epoch in seconds. At present-day
     epochs its resolution is 2⁻²² s, about 238 ns: `.123456789` is held as
     `.123456717`. Microseconds survive the round trip; nanoseconds cannot.
   - `-st`/`-et` accept one to six fractional digits.

9. **The registry's declared timestamp `precision` is read by no code.** Every
   format spec declares `time => { ..., precision => 'ms' | 's', ... }`; only
   `frac` and `layout` are read (`format_entry_block_src` ::
   `my $frac = $spec->{time}{frac} // 'generic';`). The format-registry record
   (`features/58-format-registry-staged-detection.md` § R1) says the field
   "drives sub-second bucketing (`-ms`), the integer-milliseconds hash-key rule,
   and cross-checks the `ts_precision` hint"; none of the three reads it. No
   spec declares a microsecond or nanosecond precision. Declared against the
   fraction kind: ten fixed-three-digit formats declare `ms`; seven
   whole-second formats declare `s`; of the three variable-length-fraction
   formats, two declare `ms` and one `s`. D4 (the precision printed never goes
   below the file's) gives the field its first reader.

10. **The index's `ts_precision` column carries `s` or `ms` only.**
    `features/index-file.md` lists `"s", "ms", "us"`; the read loop sets
    `$fd->{ts_precision} = 'ms' if $fractional_ms > 0 && ...` and nothing sets
    `us`.

11. **The precision values' long names are not ladder spellings.** The
    time-unit ladder accepts `ms`, `msec`, `us`, `usec`, `ns`, `nsec`, `s`,
    `second`, `seconds`, `m`, `minute`, `minutes`, but not `millisecond`,
    `milliseconds`, `microsecond`, `microseconds`, `nanosecond` or
    `nanoseconds`; those exist only as the `long` display names
    (`@time_unit_ladder` :: `{ token => 'ms', spellings => [qw( ms msec )], ...`).
    D6 (the precision values resolve through the ladder, which gains the long
    spellings) adds them.

12. **The native blocked-by edge covered the whole issue, and is removed.** #525
    was natively blocked by #605 (inputs accept a value with a unit), which is
    itself blocked by #608 (the byte ladder), while the parent refactoring issue
    #622 lists #525 among its roots with no blockers. What part two lacked was
    only the long spellings, an amendment to the ladder's spelling table, not
    #605's pattern. D6 (values through the ladder; the edge on #605 removed)
    removes the edge; #622's Order list is right to call #525
    a root, and the corrected ordering is: #525 blocks #154 (fixed timezone
    offset for rendering) and the removal issue of D5; nothing blocks #525.

13. **`docs/architecture-patterns.md` § One resolution surface per vocabulary
    does not name #525** among the issues that refine it, although stage 9
    (timestamp rendering) of the #342 review assigns the timestamp formatter
    copies to it.

14. **The file-name stamp is a sixth timestamp site.** `run_file_stamp` ::
    `$run_file_stamp = sprintf("%04d-%02d-%02d_%02d%02d%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec);`
    builds the local-time stamp in the aggregate export's and the CSV's output
    file names from `localtime` fields, a pattern of its own. D8 (the
    file-name stamp is in scope) brings it under the formatter.

---

## 4. Locked decisions

Only the architect's decisions are numbered here.

- **D1. One timestamp formatter, as the first requirement.** Verbatim from the
  review record: "one timestamp formatter: epoch, precision, optional `Z`,
  rounded once; the five inline sites call it". The truncated millisecond (the
  audit measured `.122` in the heading against `.123` in the index for a `.123`
  line) and the five inline ISO patterns fold into this issue as its first
  requirement; no separate issue. Locked by the architect 2026-09-27, stage 9
  of the #342 review (`features/342-redundant-logic-surfaces-audit-report.md`
  § Review progress, stage 9 row; the issue body's § First requirement).

- **D2. The fixed rendering offset waits for the one formatter.** #154 (fixed
  timezone offset for rendering) is blocked by this issue, so the offset is
  applied in one formatter rather than at every rendering and writing site.
  Locked by the architect 2026-09-27, stage 9 of the #342 review; native edge
  recorded.

- **D3. The option covers minute, second, millisecond, microsecond and
  nanosecond.** The architect: "microseconds are missing in your precision list
  and are required to be covered." The values are the time-unit ladder's tokens
  and long spellings: `m` or `minute`, `s` or `second`, `ms` or `millisecond`,
  `us` or `microsecond`, `ns` or `nanosecond`; `-tp ms` is valid, as is
  `-tp millisecond`. Locked by the architect 2026-09-29.

- **D4. The precision printed never goes below the precision the file
  contains.** Like the rule that a zero renders in the source's unit and a value
  never renders in a unit smaller than the stated one, the requested timestamp
  precision is not allowed to go down to a precision the file does not contain.
  The tool finds the nearest true precision the file provides, from the
  fractional digits its timestamps carry (per file or per format, as the
  registry's declared time-precision field and the parse's digit count give it),
  uses that, and prints a stderr informational message naming the precision used
  and why (what was found in the file). The precision combines with the unit the
  field carries; in the architect's words: "This would of course need to
  combine with the duration units, as 893.234 would carry a different precision
  if the field was showing seconds, milliseconds, or microseconds." D10 settles
  which unit: the one the timestamp field states, never the duration field's.
  Precision is resolved through the unit ladder, not by digit count alone.
  Nanosecond stays a legitimate requested value. Today's parse keeps at most six
  fractional digits, so until the sub-second data model carries nine, a file
  carrying nanoseconds resolves to microsecond with the notice. Carrying
  nanoseconds exactly is this issue's final drop, prototype-gated (integer
  nanoseconds beside integer seconds from the parse's digit string,
  demand-gated, staged scale, exit on exact reproduction at no cost when not
  requested); if #386 (format data model: per-format analysis precision) lands
  first, it supplies the model and this drop reads it. Locked by the architect
  2026-09-29.

- **D5. `-s` and `-ms` are deprecated.** The architect: "first, they should be
  marked as deprecated, with a GitHub issue created to deprecate them completely
  at some point. the --bs now carries the possibility to specify units, so the
  unit switching provided by -s is replaced by -bs 30s." They print a
  deprecation notice for one release pointing at `-tp` and at a unit on `-bs`,
  and keep their jobs for that release. A GitHub issue is filed in the Deliver
  stage, blocked by this issue, to remove them completely (#630, § 11). The
  precision printed in the timestamp matches the precision sought: in the
  architect's words, "If I am investigating at the millisecond level today
  using "-ms -bs 100" I'd get 10 time buckets per second, and see their
  millisecond values like this: .000, .100, .200, .300, .400, .500, .600, .700,
  .800, .900. In the future, with the changes proposed here, I should be able
  to get that same result using "-bs 100ms -tp ms"." The pair reproduces it
  because `-bs` carries its unit; `-tp` sets no width (D11). After the removal a
  bare `-bs` number is always minutes, as the separation of width and precision
  in `features/524-bucket-size-unit.md` D4 requires. Locked by the architect
  2026-09-29.

- **D6. The precision values resolve through the time-unit ladder; the edge on
  #605 (inputs accept a value with a unit) is removed.** The long spellings
  `millisecond(s)`, `microsecond(s)` and `nanosecond(s)` are added to the
  ladder's spelling table, amending the spelling decision of
  `features/524-bucket-size-unit.md` D2 for every time-unit option (`-bs`,
  `-du`, `-ru`, the `-udm` unit slot). #605 later cites `-tp` as a surface
  already following its pattern. #154 (fixed timezone offset) stays blocked by
  this issue. Locked by the architect 2026-09-29.

- **D7. Rounded once, with carry.** Round half-up at the last displayed
  sub-second digit, carrying into seconds, minutes and the date. Minute and
  second precision keep truncation, as clocks and bucket labels do. The read
  loop's millisecond bucket key, which already rounds, is untouched. Locked by
  the architect 2026-09-29.

- **D8. The file-name stamp is in scope.** Every site that renders or writes a
  timestamp calls the one formatter, the stamp in output file names included.
  Locked by the architect 2026-09-29.

- **D9. The option is `-tp, --timestamp-precision`,** with a `-V runtime-config`
  key naming the requested and the resolved precision (the notice's content,
  machine-readable), its `--help` row and its `docs/usage.md` row. Locked by the
  architect 2026-09-29.

- **D10. The true precision is read from the timestamp field's stated unit and
  its digits.** The true precision the file provides is read from the unit the
  timestamp field states and the fractional digits it carries: a clock time
  states the second, so a fraction of `.234` is a millisecond. The duration
  field's unit plays no part in the timestamp precision. On today's formats,
  all clock times, this changes nothing; an epoch-number timestamp in a future
  format states its unit. Settles how D4's precision combines with the field's
  unit. Locked by the architect 2026-09-29.

- **D11. Time precision and time bucket size are separate.** The architect:
  "time precision and time bucket size are two seperate things, which were
  previously wired together for simplicity, but here we are disconnecting them
  so that the tools use is more coherent and UI is scalable. -tp ms would only
  play on the time precision of the timestamps, this means on the rendering,
  but also on the reading. We typically don't care about the millisecond part,
  so reading and storing it isn't needed. However if -tp ms is stated, then the
  first thing to do is to make sure that we are capturing it, and storing the
  timestamp at the appropriate precision, then later, we'll need to print or
  output it at the correct precision. -bs 60 would be 60 minutes, as I say, we
  are not migrating the existing code from -s and -ms to the -tp surface, we
  are designing something more coherent that replaces those other commands."
  `-tp` plays only on the precision of the timestamps, on the reading as well
  as the rendering: without it the sub-second part need not be read or stored;
  with `-tp ms` or finer, the parse first captures the timestamp at that
  precision and stores it at that precision, and every later output prints it
  at that precision. `-tp` says nothing about the bucket width: `-bs 60` is 60
  minutes whatever `-tp` says, a bare `-bs` number is minutes, and with `-bs`
  absent the width is the one a run without any switch gets (derived from the
  terminal height, in minutes), never derived from `-tp`. The `-s` and `-ms`
  behaviour is not migrated onto `-tp`: the new option is the more coherent
  design that replaces them, and `-bs 100ms -tp ms` reproduces `-ms -bs 100`
  because `-bs` carries its unit (D5). Locked by the architect 2026-09-29.

- **D12. `-s` or `-ms` beside a different `-tp` is a usage error.** `-s` or
  `-ms` given together with a `-tp` of a different precision stops the run with
  a usage error naming both; given with the same precision, the run proceeds
  with the deprecation notice (D5). Locked by the architect 2026-09-29.

- **D13. The run index writes at the run's resolved precision; its drift check
  follows the runtime options.** The architect: "run index needs to be able to
  handle the new time formats, and drift check should be relevant to the
  command line options provided at runtime." The index writes its first and
  last timestamps, and their selection twins, at the precision the run resolved
  (the requested `-tp` clamped to the file's true precision, § 6.4), and its
  `ts_precision` column states which. The drift check compares the stored and
  live values at the precision the current run's options give, never as
  strings of unequal precision: a whole-second run over a file whose index row
  was written at millisecond precision reports no drift. Where the stored row
  is coarser than the run, the comparison is at the row's precision (D15: a
  finer run over a coarser row reports no drift the row cannot express). The
  capture gate (§ 6.3) is therefore not held open for the index's sake: the
  index reads what the run captured. Locked by the architect 2026-09-29.

- **D14. The bucket key's scale follows `-bs` alone.** Put to the architect: a
  width with a millisecond part keys buckets in integer milliseconds, a width
  with a microsecond part in integer microseconds, anything else in seconds.
  The architect: "yes". The key never depends on the timestamp precision:
  `-tp` changes how a key is rendered, not how it is formed. Locked by the
  architect 2026-09-29.

- **D15. The drift check compares at the run's precision, or at the stored row's
  when that is coarser.** Put to the architect: the drift check compares at the
  run's precision, or at the stored row's precision when that is coarser, so a
  millisecond run over an index row written in whole seconds reports no false
  drift. The architect: "yes". A stored timestamp carries no digit finer than
  the precision it was written at, so a run at a finer precision over a row
  written at a coarser one reports no drift that the coarser row cannot express;
  a run at a coarser precision than the row compares at its own. Refines D13
  (the index at the run's resolved precision, drift relevant to the runtime
  options). Locked by the architect 2026-09-29.

- **D16. A minute-precision run writes whole-second index timestamps under a
  precision column that says minute.** Put to the architect: "a run at minute
  precision writes its index timestamps as whole seconds, because the index's
  date-time format has no coarser form; the precision column says minute, so a
  read-back knows the row's true precision." The architect: "yes". The index's
  date-time format has no form coarser than the whole second, so a minute run
  writes whole seconds there, and the row's `ts_precision` column says `m`: the
  column states the precision the run resolved, not the precision the string's
  shape shows. Refines D13 (the index at the run's resolved precision). Locked
  by the architect 2026-09-29.

- **D17. The index's selection rows carry the precision column.** Put to the
  architect: "the index's selection rows (the per-selection rows a later run
  can rewrite while the file row stays) carry the precision column too,
  instead of the - they carry today, so drift is judged per row at the
  precision that row was written with." The architect: "yes". A selection row
  can be written by a later run, at another precision, than the file row it
  sits beside, so each row states its own precision, and the drift check reads
  each row's timestamps at the precision stated on that row. Locked by the
  architect 2026-09-29.

- **D18. Drift compares timestamps as numbers, never as strings.** Put to the
  architect: "drift compares timestamps as numbers rounded to the comparison
  precision, never as strings, so .1000 against .123 and other string-order
  accidents cannot report drift." The architect: "yes". The stored and the live
  timestamp are each brought to an integer at the comparison precision (D13,
  D15) with the formatter's rounding and compared as numbers; no timestamp is
  compared as a string. Locked by the architect 2026-09-29.

- **D19. An index row written before this change is read at the precision its
  digits carry.** Put to the architect: "an index selection row written before
  this change still carries - in its precision column; its precision is read
  from the digits its stored timestamps carry, so an old row needs no
  rewrite". The architect: "Q1 yes". An index row written before this change,
  whose precision column carries `-`, has its precision read from the
  fractional digits its stored timestamps carry: none is the whole second,
  three the millisecond, six the microsecond. The drift check then judges that
  row at that precision as it judges any row at its stated one (D15, D17), and
  no old row is rewritten to carry a precision. Locked by the architect
  2026-09-29.

---

## 5. Surfaces this work reaches

| Surface | Today | Sub and snippet |
|---|---|---|
| Timeline bucket labels, STATS CSV `timestamp`, export bucket `timestamp` | integer ms key under `-ms`, epoch seconds otherwise | `format_bucket_timestamp` :: `return strftime($output_timestamp_format, gmtime($bucket / 1000)) . sprintf(".%03d", $bucket % 1000)` |
| Run summary heading, export `observation.start`/`end` | truncates the binary fraction | `format_observation_timestamp` :: `$str .= sprintf ".%03d", ($epoch - int($epoch)) * 1000 if $print_milliseconds;` |
| Index `first_timestamp`, `last_timestamp` and their selection twins | rounds, no carry | `format_epoch_iso` :: `my $ms = int(($epoch - $int_part) * 1000 + 0.5);`, called by `write_index_file` and `detect_index_drift` |
| Index drift comparison | live values formatted at milliseconds, compared with the stored strings as strings | `detect_index_drift` :: `$live_v_fmt = format_epoch_iso($live_v);`; `_lt` :: `return ($a lt $b) if $a =~ /^\d{4}-\d{2}-\d{2}T/;` |
| Index `ts_precision` | `s` or `ms`, set per line from whether a fraction was seen | `read_and_process_logs` :: `$fd->{ts_precision} = 'ms' if $fractional_ms > 0 && $fd->{ts_precision} eq 's';` |
| Index `entry_date`, `file_mtime` | inline ISO, whole seconds | `write_index_file` :: `my $now_iso = ...`, `my $mtime_iso = ...`, `my $current_mtime = ...` |
| Index freshness check | inline ISO, compared by string equality | `read_index_file` :: `my $on_disk_mtime = ...` |
| Export `generated_at` | inline ISO with `Z` | `write_aggregate_export` :: `$determining->{generated_at} = ...` |
| Output file-name stamp (export and CSV file names) | local time, its own `sprintf` pattern | `run_file_stamp` :: `$run_file_stamp = sprintf("%04d-%02d-%02d_%02d%02d%02d", ...)` |
| Timestamp column width | restates the format, adds 4 under `-ms` | `build_column_layout` :: `my $timestamp_w  = length(strftime($output_timestamp_format, gmtime(0))) + ($print_milliseconds ? 4 : 0);` |
| Label shape | `%Y-%m-%d %H:%M`, the `-pr` fold forms, `:%S` appended under `-s`/`-ms` | `adapt_to_command_line_options` :: `$output_timestamp_format .= ":%S" if $print_seconds \|\| $print_milliseconds;` |
| Bucket key (read loop, hot path) | integer ms under `-ms`, rounded to nearest ms | `read_and_process_logs` :: `my $epoch_ms = int($bucket_epoch * 1000 + 0.5);`; `initialize_empty_time_windows` :: same derivation |
| Bare `-bs` unit and default width unit | set by `-s`/`-ms` | `adapt_to_command_line_options` :: `$bucket_size_unit = $print_seconds ? 's' : $print_milliseconds ? 'ms' : 'm';` |
| Time-unit ladder spellings | no long sub-second spellings | `@time_unit_ladder` :: `{ token => 'ms', spellings => [qw( ms msec )], ...`; resolved by `time_unit_canonical` |
| True precision of a file | not resolved; the declared field unread | `format_registry_specs` :: `time => { ..., precision => 'ms', ... }`; `sample_file_for_detection` reads the sample before the first line |
| Deprecation notices | the existing option notices | `adapt_to_command_line_options` :: `print STDERR "Warning: -os/--omit-stats is deprecated: use ...` |
| `-V runtime-config` | `seconds:`, `milliseconds:` rows | `emit_runtime_config_verbose` :: `'seconds' => $print_seconds,` |
| Help and docs | `-bs`, `-s`, `-ms` rows; the "Millisecond zoom into one minute" example; the resolution-zoom technique's `-bs 5s -s` example | `print_help`, `docs/usage.md` § Time & Buckets, `--explain` resolution-zoom, `docs/explain/techniques.md` |

Out of scope, with the reason: `format_sample_probes`, `fold_epoch` and
`profile_included_weekdays` (read `gmtime` fields to compare dates or place a
line in a profile period, render nothing); the `-V format-detection` `sample_part` rows
(print the raw strings read from the file).

---

## 6. Design

### 6.1 Part one: the one formatter (D1, D7, D8)

**Shape (proposed).** One sub, `format_timestamp($epoch, %opt)`:

| Argument | Values | Meaning |
|---|---|---|
| `$epoch` | seconds, fractional | the instant; a bucket key in integer sub-second units is passed divided by its scale |
| `precision` | `m`, `s`, `ms`, `us`; `ns` from the final drop | canonical ladder tokens. The lock's "none" is whole seconds (`s`) on the ISO sites; `m` is the display default |
| `shape` | `iso`, `run` or `file` | `iso` is `%Y-%m-%dT%H:%M:%S`; `run` is the run's label shape (`%Y-%m-%d %H:%M`, or the `-pr` fold forms), with seconds added when the precision is finer than the minute; `file` is the output file-name stamp `%Y-%m-%d_%H%M%S` in local time |
| `z` | boolean | appends `Z` (the export's `generated_at` only) |

The `shape` argument is not in D1's list. It is needed because the display
strings, the ISO strings and the file-name stamp differ in separator, in their
minute default, in the fold forms and (for the stamp) in taking local time;
without it "one formatter" becomes three. The file-name stamp keeps its value
and its once-per-run caching in its caller; only the formatting moves.

**Rounding, once, with carry (D7).** For a precision with `d` fractional digits,
the formatter computes one integer `int($epoch * 10**d + 0.5)`, splits it into
whole seconds and the remainder, and passes the whole seconds to `strftime`. The
carry into the second, minute and date is therefore automatic and `.1000` cannot
be produced. At microsecond precision the product is about 1.8 × 10¹⁵, inside
the 2⁵³ range where a double holds every integer, so the rounding is exact. At
`s` and `m` there are no sub-second digits and the whole seconds are taken by
truncation, as today (`strftime` of the integer part), so every default and
second-precision rendering is unchanged.

**Byte identity where the copies agree.** A bucket key under millisecond
precision is an exact integer count of milliseconds; dividing it by 1000 and
rounding the product back recovers it exactly, so every bucket label and STATS
CSV timestamp is byte-identical. Every index and export string on integer-second
sources is byte-identical, and so is the file-name stamp. The only strings that
change are the heading's (and the export's `observation` strings, which are the
heading's by `features/503-yaml-aggregate-export.md` D7) when a line's fraction
is not an exact binary fraction, and the index's in the carry case. The index
comparison is scoped to its timestamp and clock columns (`first_timestamp`,
`last_timestamp` and their selection twins, `entry_date`, `file_mtime`):
`write_index_file` is also edited by #616 (one gated derivation of means), which
writes the index means at a fixed precision through the CSV formatter, so the
mean cells are that issue's to compare.

**Call sites after part one (proposed).**

| Site | Call |
|---|---|
| bucket labels, CSV, export buckets | `format_timestamp($key_seconds, precision => $timestamp_precision, shape => 'run')` |
| heading, export observation | `format_timestamp($epoch, precision => $timestamp_precision, shape => 'run')` |
| index first and last timestamps, drift comparison | `format_timestamp($epoch, precision => 'ms', shape => 'iso')` in part one; the run's precision from drop 3 (D13, § 6.3) |
| index `entry_date`, `file_mtime`, freshness | `format_timestamp($epoch, precision => 's', shape => 'iso')` |
| export `generated_at` | `format_timestamp(time(), precision => 's', shape => 'iso', z => 1)` |
| output file-name stamp | `format_timestamp(time(), precision => 's', shape => 'file')` |
| column width | `length(format_timestamp(0, precision => $timestamp_precision, shape => 'run'))` |

`format_epoch_iso`, `format_observation_timestamp` and `format_bucket_timestamp`
go; their `'-'` for an absent index timestamp stays with its two callers, the
index writer and the drift comparison, which own that convention. `$timestamp_precision` is one run-scoped value holding a
canonical token; in drop 1 it is resolved once at option settlement from
`-s`/`-ms`.

**The index in part one.** Part one keeps the index's timestamps at
milliseconds and its clock readings at whole seconds, with no `Z`, so its
strings are byte-identical wherever the copies agreed. From drop 3 its
timestamps follow the run's resolved precision and its drift check the run's
options (D13, § 6.3). The clock readings `entry_date` and `file_mtime` stay at
whole seconds: the freshness check compares `file_mtime` by string equality
with the on-disk time (`features/179-index-read-back.md` § freshness).

**The millisecond bucket key is left alone (D7).** The read loop's
integer-millisecond key already rounds half-up at the millisecond, the same rule
the formatter applies, so heading, index and bucket agree after part one (in the
carry case, all three say the next second).

### 6.2 The long spellings on the ladder (D6)

The ladder's spelling table gains `millisecond`, `milliseconds`, `microsecond`,
`microseconds`, `nanosecond` and `nanoseconds` on their steps. Because every
time-unit surface resolves through the one resolver (`time_unit_canonical`,
`features/524-bucket-size-unit.md` D1: no sub keeps a token list of its own),
`-bs`, `-du`, `-ru` and the `-udm` unit slot accept them in the same change,
case-insensitively as every spelling is. The canonical tokens and the display
ladder do not change. `features/524-bucket-size-unit.md` D2's table is updated
with the amendment, citing D6.

**Seam with #608 (byte unit ladder).** #608's help rows interpolate the time
ladder's canonical-token list (`ns, us, ms, s, m, h, d, w, month, year`) for
`-bs`, `-du`, `-ru` and the `-udm` unit slot. The long spellings added here
widen what the ladder's resolver accepts and do not lengthen the canonical-token
lists #608 interpolates into the help rows; the rejections do not enumerate the
accepted spellings either. Whichever issue lands second rebases on the other's
help rows: this issue edits the `-bs`, `-s` and `-ms` rows after #608's
interpolation and adds the `-tp` row in the same interpolated form, restricted
to the five precision steps.

### 6.3 Part two: the precision option (D3, D5, D9, D11, D12)

**The option.** `-tp, --timestamp-precision <precision>` (D9). The short form is
free and not an abbreviation risk (`Getopt::Long` runs with `no_auto_abbrev`).
The value is resolved once at settlement through `time_unit_canonical`,
restricted to the five precision steps (D3), into the run-scoped
`$timestamp_precision`.

**What reads it (D11, D13, D14).** Every reader of `$print_seconds` and
`$print_milliseconds` for the timestamp precision reads `$timestamp_precision`
instead: the label shape, the formatter's `precision`, the capture gate, the
column width and the run index (D13). Every reader of them for the bucket key
reads the key's scale instead (D14): the read loop's key derivation and
`initialize_empty_time_windows`, the bucket label's division of the key, and
the fold weekday in `print_bar_graph`. `-s` and `-ms` set `$timestamp_precision`
to `s` and `ms`; the key's scale follows from the width they give a bare `-bs`
number.

**`-s` and `-ms` beside `-tp` (D12).** Given together with a `-tp` of a
different precision, the run stops with a usage error naming both; given with
the same precision, the run proceeds with the deprecation notice.

**Read and stored at the precision (D11).** The parse captures the sub-second
digits, and the run stores them, at the precision the run asks for, clamped to
the file's true precision (§ 6.4); a run that asks for no sub-second digit need
not read or store them. The capture is a hot-path gate, chosen once at
settlement and compiled into the generated scan block, never tested per line
(proposed): the block (`format_entry_block_src` ::
`$fractional_ms = $2 * (10 ** (3 - length($2)));`, and its fixed-three-digit
twin) is built with or without the fraction arithmetic, so a run without it
still strips the fraction for the time parse but does not convert or add it.
Two other consumers read the fraction whatever the precision, and the gate
opens for them (D11: the width and the bounds work whatever `-tp` says): a
bucket width with a sub-second part (`-bs 100ms` places each line by its
fraction) and a sub-second `-st`/`-et` bound. The run index is not one of them
(D13): it writes what the run captured, at the run's resolved precision. The
capture is therefore skipped on a run that asks for no sub-second digit, sets
no sub-second width and gives no sub-second bound, whether or not it writes the
index.

**The run index at the run's precision (D13, D16, D17).** The index writes
`first_timestamp` and `last_timestamp`, and their selection twins, through the
formatter at the run's resolved precision in the `iso` shape, whose floor is the
whole second (§ 6.1): a minute-precision run writes whole seconds, which every
run reads (D16). The `ts_precision` column states the precision the run
resolved for the row: `m`, `s`, `ms` or `us` (`ns` from the final drop), so a
minute run's row says `m` over whole-second strings (D16). It is set once, when
the precision is resolved, in place of today's per-line setting in the read
loop. Selection rows state it too, in place of the `-` they carry today, since
a selection row can be written by a later run than its preserved file row
(D17).

**The drift check at the run's precision (D13, D15, D17, D18, D19).**
`detect_index_drift` compares the stored and live values at the run's resolved
precision, the one it writes the index at (D13), or at the stored row's own
precision where that is coarser (D15), since a stored value carries no digit
finer than it was written (the source-resolution floor of § 6.4, applied to
the index). The stored row's precision is the one its `ts_precision` column
states, file and selection rows alike, so each row is judged at the precision
it was written with (D16, D17). A selection row written before this change,
whose column carries `-`, has its precision read from the digits its stored
timestamps carry, none for the whole second, three for the millisecond, six
for the microsecond, and is not rewritten (D19). Both values are brought to
integers at that precision with the formatter's rounding (§ 6.1) and compared
as numbers, never as strings (D18): `_lt` and `_gt` no longer compare
timestamps as strings, so the string order that puts `.1000` before `.123` of
the same second, and every other string-order accident, cannot report drift. A
whole-second run over a row written at millisecond precision therefore
compares whole seconds and reports no drift; a millisecond run over a row
written at whole seconds compares at the row's whole seconds and likewise
reports none (D15); a millisecond run over a row a minute run wrote compares
at the minute (D16); a millisecond run over a row written before this change
with three-digit timestamps and `-` in its column compares at the millisecond
(D19); a millisecond run over a millisecond row reports a line one millisecond
past the stored bound. The `-V index-read-back` drift block writes its `live=`
value at the comparison precision; its keys do not change.

**The bucket key below the second (D14).** The millisecond key is untouched
(D7). The key's scale (1, 1000 or 1 000 000) is a run constant chosen at
settlement from the bucket width alone (D11: the width is `-bs`'s): a width
with a millisecond part keys in integer milliseconds, one with a microsecond
part in integer microseconds, any other in seconds; the key never depends on
the timestamp precision. Every key consumer reads the scale in place of
`$print_milliseconds`. The microsecond key is derived the same way beside the
millisecond one (`int($bucket_epoch * 1_000_000 + 0.5)`, exact below 2⁵³), with
the bucket size in microseconds computed once before the loop, so the per-line
work at millisecond scale is today's (proposed).

**Bucket width (D11).** `-tp` sets no width. A `-bs` value with a unit sets the
width and nothing else (`features/524-bucket-size-unit.md` D4); a bare `-bs`
number is minutes whatever `-tp` says (`-tp ms -bs 60` gives 60-minute
buckets); with `-bs` absent the width is the switch-less default derived from
the terminal height in minutes, so `-tp ms` alone gives minute-scale buckets
whose labels carry milliseconds. While `-s` and `-ms` exist they keep their jobs
for the deprecated release (D5): a bare `-bs` number and the default width are
read in their unit, so `-ms` alone keeps its 120 ms default. A width finer than
the precision (`-bs 100ms -tp s`) is valid, and its labels repeat within one
second, as in § 6.4's case of a width finer than the file's precision.

**Deprecation of `-s` and `-ms` (D5).** Each prints one stderr line at option
settlement, in the tone of the existing option notices: "Warning:
-ms/--milliseconds is deprecated: use -tp ms for the timestamp precision, and
give -bs a unit (-bs 100ms) for the bucket width" (and the `-s/--seconds` twin,
`-tp s` and `-bs 30s`). It
is a behavioural notice and always prints, `--disable-progress` included. The
switches' three jobs are unchanged for the release. #613 (one name vocabulary)
owns one deprecation-notice helper that every deprecated spelling calls; if it
has landed, these two notices call it; if not, they are written in the existing
notices' shape and #613 routes them through its helper with the others.

**User surfaces.**

| Surface | Change |
|---|---|
| `--help`, `docs/usage.md` § Time & Buckets | a `-tp` row listing the five values (the ladder tokens, with the long spellings noted as accepted); the `-bs` row names `-tp` where it says the timestamp precision stays with `-s` and `-ms`; the `-s` and `-ms` rows say they are deprecated in favour of `-tp` and a unit on `-bs` |
| examples | the millisecond-zoom example in `--help` and `docs/usage.md` written as `-bs 100ms -tp ms`; the resolution-zoom technique's `-bs 5s -s` written as `-bs 5s -tp s` |
| `-V runtime-config` | the precision key of § 6.4; the `seconds:` and `milliseconds:` rows stay while the switches exist |
| stderr | the two deprecation notices; the precision notice of § 6.4 |
| release notes | bullets per § 11 |

### 6.4 The true precision of the file (D4)

**The rule.** The requested precision is clamped to the nearest true precision
the file provides. It is the rule of `features/617-width-to-format-rule.md` D16
(a value never renders in a unit smaller than its stated unit) and D4 (a zero
renders in the source's resolved unit), applied to timestamps. This document
names that shape once, the **source-resolution floor**: a rendering never goes
below the resolution its source states, and when a request asks for more, the
floor wins and a notice says so. #617's rules are its unit instances; this is
its timestamp instance. `features/608-byte-unit-ladder.md` D9 (default decimals
are the source's resolution) shares the default but not the floor: `-cp` may
ask for more decimals there, while no option asks a timestamp below its file
(D4).

**Resolution through the ladder (D10).** The true precision is read from the
unit the timestamp field states and the fractional digits it carries: the ladder
step of the stated unit, descended one step for every three fractional digits.
A clock timestamp (`HH:MM:SS`) states the second, so `.234` is a millisecond and
`.234567` a microsecond. The duration field's unit plays no part in the
timestamp precision. Every registered format carries a clock time, so on today's
formats the rule changes nothing; an epoch-number timestamp in a future format
states its unit (one in milliseconds carries microseconds with three digits),
and the ladder arithmetic covers it with no digit table of its own.

**Where the digits come from (proposed).** Per format and per file, before the
file's first line, with no per-line cost:

| Fraction kind the format declares | True precision |
|---|---|
| none (whole seconds) | the declared `precision` field (`s`) |
| fixed three digits | the declared `precision` field (`ms`) |
| variable length | the most fractional digits among the timestamps of the detection sample (`sample_file_for_detection`: front, middle and end parts), converted through the ladder from the field's stated unit; second when the sample carries no fraction (the declared field is never finer than what the sample shows) |

A fraction whose length is not a multiple of three covers only the steps its
digits complete (proposed): four digits (`.9996`) give millisecond, two digits
give second, since the next step down would print a digit the file never
carried. The resolved precision is capped at microsecond until the final drop
(D4), because the parse keeps six digits.

**A run over several files (proposed).** The timeline is one run-wide
rendering, so the run takes the finest precision every file provides (the
coarsest of the files' true precisions); no file's timestamps then print a digit
it did not carry. The notice names each file's precision when they differ.

**The notice.** One stderr line when the resolved precision is coarser than the
requested one, naming the precision used and what was found, in plain words
(proposed text): "Note: timestamps are shown to the millisecond: microsecond
precision was asked for, and the log's timestamps carry milliseconds." and, for
nanosecond before the final drop, "Note: timestamps are shown to the
microsecond: nanosecond precision was asked for, and at most six fractional
digits are read from a timestamp." It is a behavioural notice and always
prints. Minute precision is never clamped. The clamp applies to the precision
however it is requested, `-s` and `-ms` included (D4), so a deprecated switch
and its `-tp` equivalent give the same run on every file.

**The machine-readable form (D9).** `-V runtime-config` carries a
`timestamp-precision` row naming the resolved precision's canonical token and,
when it differs from the requested one, the requested token in the section's
existing annotation grammar (`; clamped from <requested>`; proposed rendering:
`timestamp-precision: ms; clamped from us`). The section's rows are composed as
finished strings at option settlement (`emit_runtime_config_verbose` ::
`push @verbose_output, "=== runtime-config ===";`, called from
`adapt_to_command_line_options`), before any file is sampled, so this row is
written after detection by the true-precision resolution into the section, not
composed with the others at settlement (proposed). The section's contract owner
is
`features/225-test-harness-coverage-gaps.md`, updated in the same commit; #613
(one name vocabulary) lists expose and discard names in the same section and
cites the same owner.

**Bucket width finer than the resolved precision (proposed).** A width is never
changed by the precision (`features/524-bucket-size-unit.md` D4, and D11). When
the width is finer than the file's true precision (`-bs 100ms -tp ms` on a
whole-second log), only the buckets aligned to the file's tick can hold a line,
and their labels at the resolved precision repeat within one tick. The notice
then adds that buckets narrower than the timestamps' precision are empty by
construction.

### 6.5 Nanosecond, the final drop (D4, prototype-gated)

Nanosecond precision cannot be rendered truthfully on the current data model
(correction 8: the parse keeps six digits and the floating epoch resolves about
238 ns). Delivering it needs the sub-second part carried exactly from the parse
through the time filter, the bucket key, the observation bounds and the
formatter: integer nanoseconds beside integer seconds, taken from the parse's
digit string, demand-gated so that a run not asking for nanosecond pays nothing.
That is a data-model change on the per-line path, which `prototype/README.md`
requires be prototyped (§ 9). If #386 (per-format analysis precision) lands
first, it supplies the model and this drop reads it instead of building one.
Until this drop lands, `-tp ns` is accepted and resolves to microsecond with
the notice.

### 6.6 Records trued up, and the pattern entry

- `docs/architecture-patterns.md` § One resolution surface per vocabulary: the
  formatter added as a consumption site; the status line names #525 among the
  refining issues (correction 13). This issue's token only.
- `features/524-bucket-size-unit.md` D2's spelling table: the long spellings,
  citing D6; D4's closing paragraph points at this document for what `-s` and
  `-ms` become (D5).
- `features/58-format-registry-staged-detection.md` § R1 and
  `features/log-format-registry.md`: the declared `precision` field recorded as
  read by the true-precision resolution (D4), and no longer described as driving
  sub-second bucketing.
- `features/index-file.md`: `first_timestamp` and `last_timestamp` written at
  the run's resolved precision, whole seconds at minute precision (D16);
  `ts_precision` states the precision the run resolved for the row, `m`, `s`,
  `ms` or `us` (`ns` from the final drop), on file and selection rows alike, in
  place of the selection rows' `-` (correction 10, D13, D16, D17).
- `features/179-index-read-back.md`: the note on `ts_precision` and the drift
  conditions: each row's timestamps compared at the precision the run's options
  give, or at the precision that row's column states when that is coarser, as
  numbers rounded to that precision, never as strings; a row written before
  this change, with `-` in the column, read at the precision its timestamps'
  digits carry, without rewrite (D13, D15, D17, D18, D19).
- `features/503-yaml-aggregate-export.md`: its implementation note naming the
  two timestamp subs points at the one formatter.
- The audit report's stage 9 row moves to *done* when this issue closes.

---

## 7. Acceptance criteria

Key requirements only, each a condition and an observable outcome. Proposed
harness `tests/validate-timestamp-precision.sh` (named for the feature; it owns
no `-V` section), with `--list` and `--scenario`. Fixtures are a few lines each,
generated by the harness in its scratch directory in a log4j-style
application-log shape whose fraction is variable-length: a three-digit set with
fractions that are not exact binary fractions (`.123`, `.456`, `.789`), a carry
set (`.9996`, and `23:59:59.9996`), a six-digit set, a nine-digit set, and a
two-digit set; plus a committed web-server access-log fixture with whole-second
timestamps chosen from `docs/test-logs.md`. Every run passes
`--disable-progress -ni`, except the index scenarios, which run in a scratch
directory, and is shaped to the assertion that reads it.

**Drop 1: the one formatter**

- [x] **One formatter (names the mechanism, D1, D8).** Outside
  `format_timestamp`, no `strftime` call with a date or time pattern, no
  `sprintf(".%03d"` and no string built from `localtime` or `gmtime` fields
  remains in `ltl`; the field readers that render nothing (`fold_epoch`,
  `profile_included_weekdays`, `format_sample_probes`, the fold weekday in
  `print_bar_graph`) are exempt by name; the three former subs are gone and `run_file_stamp` calls
  the formatter. *Assertable:* structural scenario over `ltl` (the shape of
  `features/524-bucket-size-unit.md`'s "exactly one ladder" check).
- [x] **One rounding (D7).** On the three-digit set under `-ms -bs 1000`: the
  heading's first bound, the export's `observation.start` and the index's
  `first_timestamp` all end in `01.123`. *Assertable:* heading from stdout,
  `-V aggregate-export`, the index file.
- [x] **Carry (D7).** On the carry set under `-ms -bs 100`: the heading's last bound, the
  index's `last_timestamp` and the line's bucket label name the following second
  at `.000`; the `23:59:59.9996` line names the next day's `00:00:00.000`; no
  four-digit fraction appears in any output. *Assertable.*
- [x] **Minute and second truncate (D7).** On the carry set under `-s -bs 1s`, the
  `10:06:13.9996` line's label and heading bound read `10:06:13`. *Assertable.*
- [x] **Unchanged where the copies agreed.** The regression goldens pass
  unchanged; on integer-second sources the index's timestamp and clock columns
  (the mean cells being those of #616, one gated derivation of means) and the export are byte-identical before and
  after; `generated_at` keeps `%Y-%m-%dT%H:%M:%SZ`; the output file names keep
  the `YYYY-MM-DD_HHMMSS` local-time stamp; `validate-aggregate-export.sh` and
  `validate-index-read-back.sh` pass unchanged. *Assertable.*
- [x] **Older index rows stay fresh.** An index written by the base commit is
  read by the new build as `freshness: fresh` in `-V index-read-back` (the
  string-equality check on `file_mtime`). *Assertable.*

**Drop 2: the long spellings on the ladder**

- [ ] **Every time-unit option accepts them (D6).** `-bs 100ms`,
  `-bs 100millisecond` and `-bs 100milliseconds` give the same
  `bucket_size_seconds`; `microsecond(s)` and `nanosecond(s)` likewise; `-du`,
  `-ru` and the `-udm` unit slot resolve the long spellings to the same token as
  the short ones, in any case. *Assertable:* `validate-bucket-size-units.sh`
  (its `-bs`, `-du`, `-ru` scenarios) and `validate-udm-specs.sh`.
- [ ] **One spelling table (names the mechanism, D6).** The long spellings
  appear only in the ladder's table; no other sub lists a time-unit spelling.
  *Assertable:* the existing one-ladder structural check.

**Drop 3: the option and the deprecation**

- [ ] **Values (D3).** `-tp` accepts `m`, `minute`, `s`, `second`, `ms`,
  `millisecond`, `us`, `microsecond` and the ladder's other spellings of those
  four steps, in any case; every spelling of a step gives the same run.
  *Assertable.*
- [ ] **The architect's pair (D5).** On the three-digit set, `-bs 100ms -tp ms`
  prints ten buckets per second labelled `.000`, `.100` … `.900`, and its
  timeline, heading and STATS CSV timestamps are byte-identical to
  `-ms -bs 100`'s; the only difference is `-ms`'s deprecation line on stderr.
  *Assertable.*
- [ ] **Equivalence with the switches (D5, D11).** `-tp m` renders as the
  default; `-tp s -bs 30s` as `-s -bs 30`; `-bs 100ms -tp ms` as `-ms -bs 100`
  (the architect's pair, above). *Assertable.*
- [ ] **Width and precision separate (D11).** `-tp ms` alone reports the same
  `bucket_size_seconds` in `-V benchmark-data` as the run without any switch,
  with its labels at millisecond precision; `-tp ms -bs 60` gives 60-minute
  buckets; `-tp s -bs 90s` renders like `-s -bs 90s`; `-bs 1d` alone keeps
  minute labels. *Assertable:* extends `validate-bucket-size-units.sh`'s
  `precision/90s-on-minute-run` scenario (a unit on `-bs` leaves the label
  precision untouched).
- [ ] **Read and stored at the precision (D11).** On the three-digit set,
  `-tp ms` renders the heading's bounds as `01.123` and `03.789` from the stored
  timestamps. The scan block generated for a run that asks for no sub-second
  digit, sets no sub-second width and gives no sub-second bound carries no
  fraction arithmetic whether or not it writes the index (D13); the one
  generated for `-tp ms` does. *Assertable:* the heading from stdout; the two
  block variants by a structural check on `format_entry_block_src`'s output.
  The per-line effect is measured (§ 9).
- [ ] **The index at the run's precision (D13, D16, D17).** In a scratch
  directory, a `-tp ms` run on the three-digit set writes `first_timestamp`
  ending `T10:00:01.123` and `ts_precision` `ms` on its file and selection rows
  (D17: no selection row carries `-`); the same run without `-tp`, at minute
  precision, writes `T10:00:01` and `m` (D16); a `-tp s` run writes
  `T10:00:01` and `s`; a `-tp us` run on the six-digit set writes six digits
  and `us`. *Assertable:* the index file, `validate-index-read-back.sh`.
- [ ] **Drift at the runtime precision (D13, D15, D16, D17, D18, D19).** A
  row written at millisecond precision read back by a whole-second run, a row
  written at whole seconds read back by a `-tp ms` run (compared at the row's
  coarser precision, D15), a row written by a minute run read back by a
  `-tp ms` run (compared at the minute its column states, D16), and a row
  written before this change, with `-` in its precision column and
  whole-second timestamps, read back by a `-tp ms` run (compared at the whole
  second its digits carry, D19), each report `drift_detected: no`, although
  under string comparison each pair differs; an old row with `-` and
  three-digit timestamps is compared at the millisecond (D19);
  the precision column of each file and selection row states the resolved
  precision of the run that wrote that row (D17), and a selection row
  rewritten at another precision than its file row is judged at its own. A row
  whose `last_timestamp` is narrowed by one millisecond reports
  `last_timestamp: ... drifted=yes` under `-tp ms` and `drift_detected: no`
  under a whole-second run. The drift comparison holds no string comparison of
  timestamps (D18). *Assertable:* `validate-index-read-back.sh`, rows
  orchestrated by its `edit_index_row` helper, read from `-V index-read-back`;
  the last by a structural check on `detect_index_drift`.
- [ ] **Microsecond (D3, D7, D14).** On the six-digit set under `-tp us -bs 500us`,
  labels carry six fractional digits (`.000500`); the heading's bounds reproduce
  the written six digits, `.999999` included, without carrying. *Assertable.*
- [ ] **Key scale from `-bs` alone (D14).** On the three-digit set,
  `-bs 100ms -tp us` gives the same buckets as `-bs 100ms -tp ms`, each label
  carrying six fractional digits where the other carries three (`.100000`
  against `.100`); `-tp us` alone gives the same `bucket_size_seconds` and
  bucket count as the run without any switch. *Assertable:* labels from
  stdout, `-V benchmark-data`.
- [ ] **Deprecation (D5, D12).** `-s` and `-ms` each print exactly one stderr
  line naming `-tp` and a unit on `-bs`, with and without `--disable-progress`;
  a bare `-bs` number and the default width keep their meaning under each
  switch; `-ms -tp ms` and `-s -tp s` run with the notice. *Assertable.*
- [ ] **Rejections (D12).** An unknown value and a ladder step outside the five
  (`-tp h`) exit non-zero with a usage line listing the accepted values; `-s` or
  `-ms` with a different `-tp` exits non-zero with a usage error naming both;
  each having run nothing, with no runtime warning. *Assertable.*
- [ ] **Reported (D9).** `-V runtime-config` shows `timestamp-precision:` with
  the canonical token for `-tp` given in any spelling. *Assertable:*
  `validate-runtime-config.sh`.
- [ ] **Documented (D9).** `validate-help-content.sh` passes with the new and
  edited rows; the new `docs/usage.md` example runs under
  `validate-doc-examples.sh`. *Assertable.*

**Drop 4: the true precision of the file**

- [ ] **Clamped, with the notice (D4).** `-tp ms` on the whole-second access-log
  fixture renders labels and heading at second precision and prints one notice
  naming second and that the timestamps carry whole seconds; `-tp us` on the
  three-digit set renders milliseconds with the notice naming millisecond;
  `-tp ms` on the three-digit set prints no notice. The index follows the
  resolved precision (D13): the `-tp ms` run on the whole-second fixture writes
  whole-second index timestamps and `ts_precision` `s`. *Assertable.*
- [ ] **Machine-readable (D9).** In those runs `-V runtime-config` reads
  `timestamp-precision: s; clamped from ms` and `ms; clamped from us`, and no
  annotation when nothing is clamped. *Assertable:* `validate-runtime-config.sh`.
- [ ] **Resolved through the ladder (D4).** The four-digit carry set resolves to
  millisecond and the two-digit set to second (proposed rule, § 6.4); a
  fixed-three-digit format resolves to millisecond from its declared field.
  *Assertable* on the clock layouts; the stated-unit arithmetic for a field in
  milliseconds or microseconds has no registered format today and is asserted
  structurally (the step is read from the ladder, no digit table exists).
- [ ] **Nanosecond before the final drop (D4).** `-tp ns` and `-tp nanosecond`
  are accepted from this drop, in any case. `-tp ns` on the nine-digit set
  renders six fractional digits and the notice names microsecond and the
  six-digit limit. *Assertable.*
- [ ] **Several files (proposed rule, § 6.4).** `-tp ms` over the three-digit
  set and the whole-second fixture together renders at second precision, the
  notice naming each file's precision. *Assertable.*
- [ ] **The deprecated switches follow the rule (D4).** `-ms` on the
  whole-second fixture renders at second precision with the notice; the
  regression golden that runs `-ms` over a whole-second access log is
  re-captured in this drop, its diff limited to the dropped `.000`.
  *Assertable.*

**Drop 5: nanosecond carried exactly (prototype-gated)**

- [ ] On the nine-digit set, `-tp ns` renders all nine digits as written,
  `.999999999` included without carrying; on the three-digit set, `-tp ns` resolves to
  millisecond with the notice; the per-line cost with nanosecond not requested
  is within benchmark noise. *Assertable* once the data model exists; the model
  itself is prototype scope (§ 9).

**Every drop**

- [ ] **No runtime warnings** on stderr across every run above. *Assertable:*
  `tests/lib/runtime-warnings.sh`.
- [ ] **Looked at.** The timeline at each precision, at 80 and 160 columns, on a
  corpus log with sub-second timestamps and on one with whole seconds (the
  notice in place), inspected before the work is called done. *Unassertable by
  harness:* a visual surface, verified by eye.

---

## 8. Verification surface

| Item | Detail |
|---|---|
| `-V` sections read | `runtime-config`, `index-read-back`, `benchmark-data` (`bucket_size_seconds`), `aggregate-export` |
| `-V` sections changed | `runtime-config` gains `timestamp-precision:` with the clamp annotation (contract owner `features/225-test-harness-coverage-gaps.md`, updated in the same commit; #613 (one name vocabulary) edits the same section and cites the same owner) |
| New harness | `tests/validate-timestamp-precision.sh`, with `--list` and `--scenario` |
| Harnesses extended | `validate-bucket-size-units.sh` (long spellings on `-bs`, `-du`, `-ru`; precision untouched with `-tp`), `validate-udm-specs.sh` (long spellings in the unit slot), `validate-index-read-back.sh` (the index at the run's precision, with a precision column on every row, and the drift check at the runtime precision as numbers, an old row with `-` read at its digits' precision, D13, D16, D17, D18, D19), `validate-runtime-config.sh`, `validate-help-content.sh`, `validate-doc-examples.sh` |
| Goldens that move | drops 1 to 3: none (bucket labels are byte-identical by the rounding argument of § 6.1). Drop 4: the golden running `-ms -bs 1000` over a whole-second access log loses its `.000` (D4 applies to the deprecated switches, § 6.4) |
| Fixtures | generated by the new harness in its scratch directory (§ 7); the whole-second access-log fixture is an existing committed `.txt` chosen from `docs/test-logs.md` |

---

## 9. Measurement obligations

| Drop | Before/after benchmark | Prototype |
|---|---|---|
| 1, the formatter | yes: executable lines of `ltl` change (scope table, `docs/process/workflow.md` § 3). The per-line loop is untouched; expected neutral | no |
| 2, the long spellings | yes by the scope table; settlement only, expected neutral | no |
| 3, the option | yes: the per-line bucket-key branch reads the key scale instead of `$print_milliseconds`, a microsecond branch is added, and the capture gate (D11, § 6.3) changes the generated scan block. The gate shows only on a log with sub-second timestamps, so the before/after pair adds `single-day-application-log-standard` to `single-day-access-log-standard`; the gate holds with the index written (D13), so no `-ni` run is needed to see it. The per-line `ts_precision` setting leaves the read loop | no: trigger (a) does not apply because the microsecond key is the existing integer-key model at another scale, and (b) does not because its derivation is the millisecond one with a different constant, chosen at settlement; the gate removes arithmetic from a block already generated per format at settlement. The benchmark is the evidence |
| 4, the true precision | yes: detection reads the sample's fraction lengths; no per-line work | no |
| 5, nanosecond | yes | **yes**, a data-model change on the hot path |

**Nanosecond prototype (D4).**
- *Question:* how to carry the sub-second part exactly from the parse to the
  formatter, the bucket key and the time filter, at no per-line cost when
  nanosecond is not asked for.
- *Arms:* the current floating epoch (baseline); integer seconds plus integer
  nanoseconds from the parse's digit string, emitted only when the run asks for
  nanosecond (a demand-gated variant of the generated strip). A third arm, the
  epoch as one 64-bit integer of nanoseconds, is measured for comparison
  (proposed).
- *Scale, staged:* 1k, 10k, 100k, then 1m lines, on a dense
  millisecond-timestamp application log and on the nine-digit set; a stage that
  fails the exit stops the scale-up.
- *Exit:* nine digits reproduced exactly on every line; the arm not asked for
  within 1% of baseline (medians of three, with ranges).
- If #386 (per-format analysis precision) lands first, the prototype measures
  its model instead of building one.

---

## 10. Delivery

Each drop is a commit and push on the issue branch; one PR at the end.

1. **The one formatter,** the file-name stamp included. § 6.1. Changes one
   rendered string class (the heading and export `observation` in the
   non-binary-fraction and carry cases) and the index carry case.
2. **The long spellings on the ladder.** § 6.2. Every time-unit option.
3. **The option,** minute to microsecond, with the capture gate, the run index
   at the run's precision (D13), the bucket key's scale from `-bs` (D14), and
   `-s` and `-ms` deprecated. § 6.3.
4. **The true precision of the file,** with the notice and `-tp ns` resolving to
   microsecond. § 6.4.
5. **Nanosecond carried exactly,** after the prototype. § 6.5.

**Drop 1, delivered 2026-10-02.** `format_timestamp($epoch, precision, shape, z)`
replaces `format_epoch_iso`, `format_observation_timestamp` and
`format_bucket_timestamp`; the five inline ISO sites, `run_file_stamp` and the
timestamp column width call it. Its fractional digits come from the time-unit
ladder's `decimals` (ms 3, us 6), so it keeps no unit table of its own.
`$timestamp_precision` (`m`, `s` or `ms`) is settled once from `-s`/`-ms`
and keys the label format's `:%S`; the bucket key's scale still follows
`-ms` until drop 3 (D14). The index's first and last timestamps stay at the
millisecond and the drift comparison is still by string until drop 3 (D13,
D18).

Measured against the base commit (3b673ee) with captures of the summary heading,
the timeline, the STATS and MESSAGES CSVs, the aggregate export and the run
index, on three generated application logs (fractions `.123`/`.456`/`.789`; a
line at `10:06:13.9996`; a line at `23:59:59.9996`) and the committed
whole-second access-log fixture `tests/fixtures/gated-means-access.txt`, under
the default, `-s`, `-ms` and `-pr week`. Per-run clock values were masked and
their shapes compared. Every product is byte-identical except these strings:

| Run | Surface | Base | Drop 1 |
|---|---|---|---|
| `.123` line, `-ms` | heading first bound, export `observation.start` | `10:00:01.122` | `10:00:01.123` |
| `.100` line, `-ms` | heading first bound, export `observation.start` | `10:06:10.099` | `10:06:10.100` |
| `.789` line, `-pr week -ms` | heading last bound, export `observation.end` | `Mon 10:00:03.788` | `Mon 10:00:03.789` |
| `10:06:13.9996` line, `-ms` | heading last bound, export `observation.end` | `10:06:13.999` | `10:06:14.000` |
| `10:06:13.9996` line, `-ms` and `-s` | index `last_timestamp`, file and selection rows | `10:06:13.1000` | `10:06:14.000` |
| `23:59:59.9996` line, `-ms` | heading, export, index | `2025-02-20 23:59:59.999`, index `23:59:59.1000` | `2025-02-21 00:00:00.000` |

The line's bucket label was already `10:06:14.000` (and `2025-02-21
00:00:00.000`), so heading, index and bucket now agree. An index written by the
base build is read by the new one as `freshness: fresh`, `lookup:
tier_1_selection`. `tests/validate-timestamp-precision.sh` holds drop 1's
criteria (7 assertions; the five covering changed behaviour fail against the
base build with the values above, and the truncation and freshness ones fail
against a deliberately broken copy). `validate-regression.sh` (74),
`validate-aggregate-export.sh` (161) and `validate-index-read-back.sh` (74)
pass unchanged.

**Merge gate.** Full harness suite and the before/after benchmark
(`single-day-access-log-standard`, labels `525-before` on the base commit and
`525-after`), with `single-day-application-log-standard` (`525-app-before`,
`525-app-after`) for drop 3's capture gate; both before runs taken
2026-10-02 on 3b673ee, `$version_number` restored before the gate, `--help` and
`docs/usage.md` agreeing.

---

## 11. Records to update

### At the Deliver stage of the review (issue records, before implementation)

| Record | Change |
|---|---|
| Native edge "#525 blocked by #605" | removed (D6): read the shape with `gh api repos/gregeva/logtimeline/issues/525/dependencies/blocked_by`, then `gh api --method DELETE repos/gregeva/logtimeline/issues/525/dependencies/blocked_by/{605's id}` |
| #525 body | the "Blocked by #605" line dropped; the title, the Requirement paragraph and the Outcome add microsecond; the Links line's `docs/usage.md` § Display & Output corrected to § Time & Buckets; the open question on `-s` and `-ms` answered by a pointer to this document (D5) |
| Native edge "#154 blocked by #525" | stays (D2) |
| Native edge "#620 blocked by #525" | added 2026-09-30 (ordering correction): D14 rewrites the per-line millisecond bucket-size line that #620 (the hoisting remedy) moves out of the loop in its step 3, so no line is moved twice |
| Removal issue, filed | title "Enhancement: Remove the -s and -ms switches once -tp and a unit on -bs have carried a release"; label `enhancement`; status `backlog` via `./build/issue-status.sh`; body in the architect's terms (the two switches deprecated under #525 with a one-release notice; removal makes `-tp` the one precision surface and a bare `-bs` number always minutes), following `docs/process/issues.md` § Filing a requirement (no design); natively blocked by #525, with the prose line. Filed as #630 |
| Comment on #605 (inputs accept a value with a unit) | the edge is removed; `-tp` resolves through the time-unit ladder with the long spellings, a surface already following #605's pattern for #605 to cite |
| Comment on #608 (byte unit ladder) | the seam of § 6.2: the long spellings widen what the ladder's resolver accepts and do not lengthen the canonical-token lists #608 interpolates into the help rows; this issue edits the `-bs`, `-s` and `-ms` rows after the interpolation and adds the `-tp` row in the same form |
| Comment on #154 (fixed timezone offset for rendering) | stays blocked by this issue (D2): the offset shifts the one formatter, which is unblocked now that the edge on #605 is removed |
| Comment on #524 (bucket size unit) | the amendment: the long sub-second spellings on the ladder for every time-unit option (D6); `-s` and `-ms` deprecated (D5); time precision and bucket size disconnected (D11) |
| Comment on #525 | points at this document for the agreed specification and the removal issue's number |

### At implementation

| Record | Change |
|---|---|
| `docs/usage.md` § Time & Buckets | `-tp` row; `-bs`, `-s`, `-ms` rows; examples |
| `--help` (`print_help`) | the same rows and the millisecond-zoom example |
| `--explain` resolution-zoom and `docs/explain/techniques.md` | the `-bs 5s -s` example written as `-bs 5s -tp s` |
| `docs/architecture-patterns.md` | § 6.6, this issue's token only |
| `features/524-bucket-size-unit.md`, `features/503-yaml-aggregate-export.md`, `features/index-file.md`, `features/179-index-read-back.md`, `features/58-format-registry-staged-detection.md`, `features/log-format-registry.md` | § 6.6 |
| `features/225-test-harness-coverage-gaps.md` | the `runtime-config` row added |
| Audit report § Review progress | stage 9 to *done* at close |
| Completion comment on #525 | names the removal issue's number and any recorded skip |
| Release notes | yes: "Fix the run heading's millisecond timestamps to match the log and the run index." (drop 1); "Add `-tp` to set the timestamp precision, minute to nanosecond, never finer than the log's timestamps. See docs/usage.md." (drops 3 and 4); "Deprecate `-s` and `-ms`: use `-tp` and a unit on `-bs`." (drop 3); "Accept millisecond, microsecond and nanosecond spelled out wherever a time unit is taken." (drop 2) |
