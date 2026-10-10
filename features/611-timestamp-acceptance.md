# One application-wide pattern for accepting a timestamp (Issue #611)

Sub-issue of #622 (refactoring dispatched by the redundant-logic-surfaces
audit). Audit record: `features/342-redundant-logic-surfaces-audit-report.md`,
findings F3.2 (the impossible-date guard), F3.3 (the CSV epoch arm's input) and
F3.10 (the `-st`/`-et` bound parser); #612 (the separator half of F3.10) was
merged into this issue.

## Status

- 2026-10-10: work started on `611-impossible-dates` off `release/0.19.0`.
  The situation below was measured on the base commit (8372942) before any
  change. The architect agreed the four-drop delivery of § 7 and directed
  that the drops run in sequence without stopping between them.
- Drop 1 (46f298f): this record and the pattern entry.
- Drop 2: the per-line arms (C1 to C5). Measured on the reproductions of § 4:
  every per-line case runs to exit 0 with the line not matched, counted and
  noted once; under the wrong `-lf` pin on the Integration Runtime fixture,
  38 records matched and 86 not matched for an impossible date, where the
  base code counted those 86 at the previous line's time (124 matched).
  Harnesses `validate-format-detection.sh` (458), `validate-csv-input.sh`
  (33), `validate-format-registry.sh` (57), `validate-filter-summary.sh` (109)
  and `validate-verbose-content-shape.sh` pass. `single-day-access-log-standard`
  against `611-before`: `parse/read_files` 8.4 s both (+25 ms, +0.3%), total
  +0.3%, peak RSS −0.2%, one run each; the gate's `after` run is the measure.

## 1. The motivating consumer

A user reading a large log, or many of them, whose input contains one line
with a date that cannot exist. Today that one line ends the run on most of the
places that read a timestamp, with a Perl library message naming no file, line
or value. The same user typing a start or end bound in the form the tool
itself writes (`2025-05-07T00:02:00`) gets a run that silently ignores the
time of day. The pattern is also what #387 (user-declared YAML formats)
inherits: a layout a user declares gets the same acceptance rules as a built-in
one.

## 2. Requirement

One documented pattern for how a timestamp is accepted and what happens when
it is invalid or ambiguous, common to the whole application, recorded in
`docs/architecture-patterns.md` and applied to every place that reads a
timestamp: the generated scan block of each scanned format (ISO, Apache common
log, asctime layouts), the CSV block (ISO and epoch), the `-st`/`-et` bound
values, and the index read-back. Done when the `T` form and the space form
give the same filtered run, a malformed date on any of these places gives the
user the same kind of outcome, the run continues where the contract says it
continues, the inverted-layout detection signal still fires, and no place
reaches a library call that can end the run on user input.

## 3. Contracts the pattern is designed from

| Contract | Source | What it requires here |
|---|---|---|
| A line is matched only once its timestamp parses; nothing reported per line or per file | #640 D1 (`features/640-csv-unplaced-rows-silent.md`); extended to scanned lines by the architect 2026-09-30 | an unplaceable line is read and not matched; any message is run-level |
| A line whose date is impossible under every live layout is not matched | `features/log-format-registry.md` D52, amended by the architect 2026-09-30 | the line contributes to no bucket, statistic or metric; counting it at the previous line's time is data corruption |
| An impossible date is evidence against the current layout | D52 probe (a), N5, IF5 in `features/log-format-registry.md` | the signal reaches variant selection before the line is given up, and a flip re-scans the line |
| A CSV file's date order is settled once from its sampled rows | `features/615-csv-registry-entry.md` D9, D15, D18 | a sampled-row date failure still drives the day-first retry |
| A CSV row impossible under the file's order ends the run | `features/615-csv-registry-entry.md` D7 | locked as a holding position until this issue changes it on the one generated parse |
| A guard alone is not enough | `features/log-format-registry.md`, the #385 mitigation note | silencing the failure while leaving the rest transposed trades a loud failure for a quiet wrong answer; the user is told |

## 4. The situation as measured (base commit 8372942)

Each case is a minimal synthetic input (two to four lines) read with
`--disable-progress -ni -V -bs 1`; CSV cases add `-udm 'value::max'`.

| Place | Input | Observed today |
|---|---|---|
| Scanned ISO, group of one | a Thingworx application log line dated month 13 | run continues; line counted at the previous line's time (4 of 4 lines matched); per-file note `… has an impossible date component … such lines are kept at the previous line's time - use -lf …` |
| Scanned ISO, group of one | the same log, a line dated 30 February | run ends, exit 255: `Day '30' out of range 1..28 at (eval 108) line 216.` |
| Scanned Apache common log | an access log line dated 31 June | run ends, exit 255: `Day '31' out of range 1..30 at (eval 108) line 206.` |
| Scanned asctime | an Apache mod_jk line dated 30 February | run ends, exit 255: `Day '30' out of range 1..28 at (eval 108) line 203.` |
| CSV, ISO | a row dated 30 February between two valid rows | run ends, exit 255: `Day '30' out of range 1..28 at (eval 111) line 14.` (D7 of #615, as locked) |
| CSV, ISO | a row dated month 13 between rows dated `2025-06-01` | the file is read day first (#615 D15), 3 of 4 lines matched, the valid rows read as 6 January |
| CSV, epoch | a row reading `abc` after an epoch row | not matched, silently (2 of 4 lines matched): already delivered by #640 D3, so the F3.3 half of this issue is done |
| CSV, ISO | quoted `"2025-06-01 10:00"` (ltl's own STATS CSV shape), or unquoted without seconds | no row matched, nothing said (0 of 3 lines) |
| CSV, epoch | 13-digit epoch milliseconds | 2 rows matched, placed at a wrong time: the run's range line reads `1970-01-01 00:00 and 1970-01-01 00:00` |
| `-st` | `2025-05-05T00:00:02` | two Perl warnings (`Garbage at end of string in strptime: T00:00:02 at …/Time/Piece.pm line 637`), time of day dropped: 0 lines excluded, where the space form excludes 1 |
| `-st` | `2025-13-01 00:00:00` | run ends, exit 255: `Error parsing time at …/Time/Piece.pm line 637, <$fh> line 1.` |
| `-st` | `yesterday` | `Warning: unhandled date/time format - option not taken into account`, run continues unfiltered |
| Index read-back | `iso_timestamp_parts()` | already evaluates `timegm` under `eval` and returns undef; requires the `T` separator, which ltl always writes; consumers skip an undef value |

Where each arm parses today:

- Scanned formats: `format_timestamp_src()` emits the parse into each
  generated block. The memo-miss branch of the ISO layouts tests
  `substr(…, month_off, 2) > 12 || substr(…, day_off, 2) > 31`, signals
  `format_probe_signal(…, 'impossible_date', …)`, and otherwise carries
  `$timestamp = $format_last_ts_epoch // 0;`. The `timegm` call on a
  date-cache miss is unguarded on every layout, so a day the cheap test passes
  (30 February, 31 June) ends the run; the Apache common log and asctime
  layouts have no cheap test at all.
- CSV: `csv_block_src()` passes its layout (`csv`, `csv_ddmm`, `csv_epoch`)
  through the same `format_timestamp_src()`. The CSV layouts take the
  unguarded parse. `csv_validate_block()` reads a croak on a sampled row as a
  date failure (D9's day-first retry).
- Bounds: `calculate_start_end_filter_timestamps()` matches five shapes with
  the space separator only and parses with `Time::Piece->strptime`, lazily at
  the first matched line, because the time-of-day forms are anchored to the
  first line's date.

Every call into the time library that can reach user input:

| Site | Call | Guarded today |
|---|---|---|
| `format_timestamp_src()`, ISO layouts (`iso_ms`, `iso_ms_ddmm`, `iso_flex`, `iso_flex_frac`, `csv`, `csv_ddmm`) | `timegm( 0, 0, 0, substr(…, day_off, 2), substr(…, month_off, 2) - 1, … )` | no |
| `format_timestamp_src()`, `asctime` | `timegm( 0, 0, 0, substr(…, 4, 2), $format_month_map{…} - 1, … )` | no |
| `format_timestamp_src()`, `apache_clf` | `timegm( 0, 0, 0, $day, $format_month_map{$month_str} - 1, $year )` | no |
| `calculate_start_end_filter_timestamps()` | `Time::Piece->strptime( $value, … )`, five forms | no |
| `iso_timestamp_parts()` (index read-back) | `eval { timegm($6, $5, $4, $3, $2 - 1, $1) }` | yes |
| `format_sample_probes()` (detection sample) | `eval { timegm($sec, $mi, $h, $dy, $mo - 1, $y) }` | yes |

## 5. Design

Claude's design, 2026-10-10, under the architect's direction to deliver the
four drops of § 7 in sequence without stopping between them. The choices
below (C1 to C9) carry no architect lock. They are reviewed at the PR, and any
of them the architect changes is changed before merge.

### 5.1 The pattern

A timestamp is accepted in two steps, everywhere it is read:

1. **Shape.** The text has one of the forms the place accepts: the format's
   pattern for a scanned line, the file's kind for a CSV row, the documented
   forms for an option value. A line whose timestamp has no accepted shape is
   read and not matched, silently, like any line no format recognises (#640 D1).
2. **Date.** The calendar date the shape names exists. The date is resolved
   once per distinct date, on the date cache's miss, by one sub that returns
   undef instead of dying (C1). Nothing else calls the time library on user
   input.

What happens to a date that cannot exist depends on where it was read:

- **Per-line arms (scanned and CSV).** Under an ISO layout, a component out
  of range (month > 12 or day > 31) is first the layout signal of D52 (a):
  `format_probe_signal()` eliminates the member, and a flip re-scans the
  line under the new occupant (C2). With no flip, and for every other
  impossible date (30 February, 31 June, day or month 00), the line is not
  matched: it contributes to no bucket, statistic or metric, and the
  timestamp memo is left as it was, so the next line is not read at this
  line's time (C3). The line is counted by format (C4).
- **Option values (`-st`, `-et`).** A value in no accepted form, or whose
  date cannot exist, is a usage error naming the accepted forms, raised
  before any file is read (C6).
- **Index read-back.** A value that does not parse is skipped, as today.

The user is told once per run, after the read, never per line or per file
(C5). `-V` carries the counts (C4).

Accepted forms (C7, C8):

| Place | Forms |
|---|---|
| Every ISO date-time | `YYYY-MM-DD` then a space or `T`, then `HH:MM:SS`, an optional fraction after `.` or `,` of up to nine digits |
| `-st`, `-et` | an ISO date-time; the same without seconds; a date alone; a bare time `HH:MM[:SS[.fraction]]` (time-of-day window); single-digit month, day and hour as today |
| CSV, ISO kind | an ISO date-time; the same without seconds; either quoted in double quotes |
| CSV, epoch kind | epoch seconds, with an optional fraction; a 13-digit integer part is epoch milliseconds; `-du` overrides both |
| Index read-back | the option parser's date-time forms (one parser, C9) |

### 5.2 Choices

- **C1 — One date resolver on the date cache's miss.**
  `timestamp_date_cache_add()` takes the date's year, month and day, calls
  `timegm` under `eval`, caches and returns the midnight epoch, or returns
  undef (caching nothing) when the date cannot exist or a component is
  missing (an unknown month name). The emitted parse of every layout reads
  `my $midnight = $timestamp_date_cache{…} // timestamp_date_cache_add(…)`
  and branches on `defined $midnight`. The cheap range test on the memo-miss
  branch goes: the resolver answers it. Cost: an `eval` once per distinct
  date, a `defined` test once per distinct timestamp string; nothing per line
  on a dense stream.
- **C2 — The layout signal fires on an out-of-range component only.** Month >
  12 or day > 31 under the entry's layout, as today; D52 (a) is unchanged. A
  date whose components are in range but which does not exist (30 February)
  is not evidence against the layout: under the other order of the group its
  month would be out of range too, so a signal would eliminate the right
  member and flip the rest of the file to the wrong one.
- **C3 — Not matched means returned as no match, before anything is
  recorded.** The scan sub returns undef from the block, the per-entry
  closure returns false, the CSV block returns undef. The read loop's
  existing no-match path counts the line as unmatched. Neither
  `$format_last_ts_str` nor `$format_last_ts_epoch` moves. While a file's
  first decision is pending (the detection-window prefill on input with no
  sample), the line is held as matched, and the replay under the final
  occupant decides it, so a flip inside the window still recovers it.
- **C4 — Counted per file and format.** The emitted branch increments
  `$timestamp_impossible_lines{$format_current_file}{<slug>}`, a constant key
  compiled in. Validation paths (`format_validate_scan_sub()`,
  `csv_validate_block()`) leave the count as they found it. `-V
  format-detection` reports each file's total as `impossible_date_lines`;
  `-V filter-summary` reports the run's total as `lines_unmatched_impossible_date`,
  a part of `lines_unmatched`.
- **C5 — One run-level note per format, after the read.** `Note: <N> line(s)
  were not matched because their date cannot exist under the <slug> format's
  date layout`, followed by ` - use -lf to pin the correct log format` when
  the format has another member in its variant group or the run pinned a
  format. No file name, no line number, no value. The once-per-file note in
  `format_probe_signal()` goes.
- **C6 — The bound values are settled with the options.** One parser reads
  `-st` and `-et` when the options are adapted, before the read; the epoch of
  a date form is fixed then, and a bare time keeps its time of day, anchored
  to the first line's date as today. An unreadable value is a usage error
  through `print_usage()` naming the forms; `Time::Piece` leaves the bound
  path.
- **C7 — Either separator, everywhere an ISO date-time is read.** Scanned
  formats already normalise through their declared transform; the bound
  parser and the index read-back accept both.
- **C8 — CSV forms.** The ISO kind's trim also strips surrounding double
  quotes; a value without seconds reads as second 0. An epoch file whose
  line-2 integer part has 13 digits is read in milliseconds, the unit carried
  into the file's precision evidence as `-du ms` would carry it. Microsecond
  and nanosecond epochs (16 and 19 digits) are not covered: the issue names
  milliseconds only.
- **C9 — One date-time parser for options and the index.** `iso_timestamp_parts()`
  becomes the parser of the date-time forms, returning `[ seconds,
  nanoseconds ]`, and the bound parser calls it.

Not covered: a clock time out of range (`25:61:00`) is read arithmetically on
every arm today and is outside this issue, which concerns dates. Offsets
stay with #155 (timezone offsets normalised to UTC).

## 6. Acceptance criteria

All assertable. Inputs are minimal synthetic fixtures committed as `.txt`
under `tests/fixtures/`, except AC3, which uses the Integration Runtime
fixture the detection harness already stages.

- [x] **AC1** A Thingworx application log whose lines include one dated
      month 13 runs to exit 0 with that line not matched and contributing
      nothing (`lines_included` counts only the valid lines), counted
      (`impossible_date_lines`, `lines_unmatched_impossible_date`), and the
      one run-level note of C5 on stderr; no per-file note. *Asserted by the
      `impossible-date` scenarios of `validate-filter-summary.sh` and
      `validate-format-detection.sh`.*
- [x] **AC2** The same with 30 February on the scanned ISO arm, 31 June on an
      Apache common log access log and 30 February on an Apache mod_jk log
      (asctime): each exits 0 with the line not matched, counted and noted,
      and nothing on stderr carries ` at <file> line <N>`. *Same scenarios.*
- [x] **AC3** The detection signal still fires: the existing
      `validate-format-detection.sh` scenarios for sample elimination and the
      late flip (IF5) pass unchanged; under `-lf` pinned to the wrong member
      of the date-layout group, the lines whose day exceeds 12 are not
      matched and counted, the rest matched, and the note carries the `-lf`
      hint. *The `format-pin` scenario of `validate-format-detection.sh`.*
- [x] **AC4** A CSV whose middle row is dated 30 February runs to exit 0
      with that row not matched and counted under `csv`; a CSV whose rows are
      real dates only day first is still read day first (#615 D15). *The
      `impossible-date` scenario of `validate-filter-summary.sh`; the
      day-first scenarios of `validate-csv-input.sh`.*
- [ ] **AC5** *Unassertable from the command line.* On input with no
      detection sample (read through the detection window), a line impossible
      under the layout first chosen and valid under the one the window
      settles on would be matched at its own time. Found in drop 2: a file
      without a sample is one that is not a regular file, and the file
      selection keeps regular files only (`@in_files = grep { -f $_ }
      @in_files;` in `adapt_to_command_line_options`), so no run reaches the
      pending decision. The hold of C3 is kept, as the existing pending branch
      of `format_probe_signal()` is, for the window's own design.
- [ ] **AC6** `-st` and `-et` given as `YYYY-MM-DDTHH:MM:SS` and as
      `YYYY-MM-DD HH:MM:SS` give the same `excluded_time_window` on the same
      input, with a fraction and without.
- [ ] **AC7** `-st` or `-et` given a value in no accepted form, or with an
      impossible date, exits non-zero before reading any file, with a usage
      error naming the accepted forms; no Perl module text on stderr.
- [ ] **AC8** A CSV with quoted timestamps, one without seconds, ltl's own
      STATS CSV at each of `-tp m`, `s`, `ms`, and a CSV of 13-digit epoch
      milliseconds each place their rows at the instants an unquoted,
      full-second (or epoch-seconds) twin of the same file places them.
- [ ] **AC9** The `single-day-access-log-standard` benchmark after the change
      is within noise of `611-before`.

Validation paths for the invariant "no library call can end the run on user
input": every row of the table in § 4 above, each reached by AC1 to AC8:
ISO layouts by AC1, AC3, AC4; asctime and `apache_clf` by AC2; the bound
parser by AC6, AC7; the index read-back by the existing
`validate-index-read-back.sh` scenarios; the sample probes by AC3.

## 7. Delivery

1. **Drop 1.** This record and the pattern entry in
   `docs/architecture-patterns.md`.
2. **Drop 2.** The per-line arms: C1 to C5; harness scenarios for AC1 to
   AC5; the once-per-file note and its assertion go; before/after benchmark.
3. **Drop 3.** The bound values and the index read-back: C6, C7, C9;
   `docs/usage.md` § Filtering and the `-st`/`-et` help rows name the forms;
   scenarios for AC6, AC7.
4. **Drop 4.** The CSV forms: C8; scenarios for AC8.

Records updated by the drops: `features/log-format-registry.md` (D52's
note withdrawn as delivered, N5, the impossible-date diagnostic entry),
`features/615-csv-registry-entry.md` D7 (superseded), `features/user-defined-metrics.md`
§ CSV Columnar Input (accepted forms), `features/503-yaml-aggregate-export.md`
§ `-V filter-summary` section contract, `tests/HARNESS-DESIGN.md` reserved
names (section descriptions), release notes.
