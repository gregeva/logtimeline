# #640 — CSV input reports rows it cannot place on the timeline, per row and per file

Sub-issue of #629 (defects with a user-defined metric using a custom regex and
capture group); umbrella record `features/629-udm-custom-regex-defects.md`.
Owning area: `features/user-defined-metrics.md` § CSV Columnar Input.

## Requirement

A CSV row is placed on the timeline only when its timestamp parses; a row
that cannot be placed is read and not matched, silently, as any other line.
Informational messages about user-defined metrics on CSV input are run-level,
never per row or per file (D1). The column-choice and accepted-form defects
found in the investigation are deferred to release 0.19.0 (D2).

## Findings

Measured on release/0.18.5 with a 25-case round-trip matrix; identical
outcomes on release/0.19.0, where `detect_and_parse_csv_header()`,
`format_epoch_iso()`, `parse_iso_date_to_epoch()`,
`calculate_start_end_filter_timestamps()` and `compile_format_time_parser()`
are unchanged.

- **Detection** happens only when `-udm` is given (the lazy block
  `if (@udm_configs && !$csv_detected) {` in `read_and_process_logs()`); without
  it a CSV is read silently as unmatched lines. Fields are split with a plain
  `split(/\Q$csv_separator\E/, $_, -1)`, which keeps quotes.
- **Column choice.** `detect_and_parse_csv_header()`: a column named
  `timestamp` (case-insensitive), otherwise
  `$csv_timestamp_col = 0;  # Fall back to first column`. No other name, no
  check of content. For `ltl-index.csv` column 0 is `entry_type`, so every row
  warns on `'file'`. A header naming its time column `created_at` has its id
  column read as time.
- **Accepted forms** (the CSV ISO arm strips a fraction, then tests
  `/^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}/`, anchored at the start only):

  | Form | Result |
  |---|---|
  | space or `T` separator; `.5`, `.495`, `.123456`; trailing `Z`; epoch seconds | accepted |
  | `+02:00`, `+0200` offsets | accepted, offset silently dropped (`10:00:05+02:00` reads as 10:00:05 UTC) |
  | `YYYY-MM-DD HH:MM`; a quoted value; `dd/mm/yyyy`; `yyyy/mm/dd`; compact `20260601T100005` | skipped with the "neither epoch nor ISO" warning |
  | 13-digit epoch milliseconds | read as seconds; every row falls outside the time window, no warning |

- **What ltl writes, and whether it reads back** (a 300-line web application
  access log fixture, `-o` at default, `-s` and `-ms` precision):
  - STATS CSV: column `timestamp`, from `format_bucket_timestamp()`, quoted by
    Text::CSV (`"2025-05-07 00:00"`). **Fails at every precision.**
  - MESSAGES CSV: no timestamp column; not a time series.
  - `ltl-index.csv` (`write_index_file()`): `entry_date`, `file_mtime` as
    `%Y-%m-%dT%H:%M:%S`; `first_timestamp`, `last_timestamp` via
    `format_epoch_iso()` with `.mmm` always. Fails as CSV input (column 0).
    Its own write and read-back agree: `read_index_file()` compares the `T`
    strings, `parse_iso_date_to_epoch()` requires `T`.
- **Index write defect.** `format_epoch_iso()` rounds `int(frac*1000+0.5)`
  without carry: a row at `10:00:05.999600` is written as
  `2026-06-01T10:00:05.1000`, which the string comparison sorts before `.123`.
  Recorded in #525 (one timestamp formatter) § 3 item 6.
- **`-st`/`-et` reject the `T` form**: `-st 2026-06-01T10:01:00` prints a
  `Garbage at end of string in strptime` runtime warning, filters from
  midnight, and exits 0. Owned by #611 (one rule for accepting timestamps),
  into which #612 was merged.

- **The index read as CSV input.** Measured on the index from the #629
  reproduction, with `-ni -bs 1 -udm "line_count::sum"`:
  - The file is comma-separated (26 fields, no tab). Tab-separated input is
    already supported: `detect_and_parse_csv_header()` picks among `,`, `;`
    and tab by count, and `-ucs` overrides it.
  - Every row is skipped on `'file'`, the `entry_type` value in column 0,
    with the "neither epoch nor ISO" warning; `produced: occurrences=0`.
  - The index's own timestamp is `entry_date` (column 2), the time the entry
    was written. `first_timestamp` and `last_timestamp` are not the row's time:
    they record what ltl saw inside the analysed file the row describes.
  - Selection rows write `-` for an absent value; a `-` in a numeric column
    prints the #638 (non-numeric capture) runtime warning.
- **Disposition of the index (architect).** The index is not a file ltl is
  designed to analyse: its first field is an entry type, not a time. ltl does
  not parse it. Its lines are skipped, as ltl skips any line that has no
  acceptable timestamp where one is expected; a file read to the end with no
  matched line prints no error or warning, and the file list shows that
  nothing matched in it.

## Decisions

- **D1 — A CSV row is a line like any other: no parsable timestamp, no match,
  no message; metric messages are run-level.** A line is matched only once its
  timestamp parses, and only a matched line goes on to metric extraction or any
  other processing; every other line is read and not matched, silently.
  Applied to CSV input:
  - The `CSV timestamp '…' is neither epoch nor ISO` row warning and the
    per-file skipped-row total are removed. Such a row counts in lines read and
    not matched, and the file list shows the file's match status. Rows without
    a parsable timestamp are still kept away from the date parse, so the crash
    #328 (UDM unable to find its metric in CSV headers) fixed cannot return.
  - `UDM metric '<name>' not found in CSV headers`, today printed per file as
    soon as a header is read, becomes one run-level note per `-udm` spec after
    the read, in the existing shape `Note: -udm '<spec>': …`. It prints only
    when CSV rows matched and the metric's column was missing from their
    header, and gives a count of such files, never their names.
  Rationale (architect): the tool's informational messages are run-level, one
  per option or spec, after the read; ltl exists to handle long lists of files,
  so a message never lists file names, and per-file match and highlight status
  already has its own surfaces. Consequence: `ltl-index.csv`, or any CSV
  without a parsable timestamp, read as input produces no message and shows as
  nothing matched in the file list.

- **D2 — Release 0.18.5 delivers D1 only; column choice and accepted forms
  are deferred to release 0.19.0.** Which column carries the timestamp is added
  to #615 (CSV input as a header-instantiated registry entry; its § 2 on
  release/0.19.0); the quoted STATS CSV timestamp, a timestamp without seconds
  and epoch milliseconds are added to #611 (one application-wide rule for
  accepting timestamps; its issue body), whose CSV contract is corrected to
  D1. Offsets stay with #155. Neither issue covered these before. Consequence
  accepted until 0.19.x: a STATS CSV fed back to ltl shows nothing matched, and
  a CSV whose column 0 holds a numeric id is placed on wrong dates.

- **D3 — The same rule holds for an epoch-timestamp CSV (architect, locked
  2026-09-30).** In a CSV whose first data row carried epoch seconds, a row
  whose timestamp is not a number is read and not matched, silently, like any
  other unplaceable row. Before this, it reached the epoch conversion with a
  Perl runtime warning and was placed at epoch 0 (1 January 1970). Asserted by
  the `unplaced-rows` scenario of `tests/validate-csv-input.sh`.

## Acceptance criteria

- [x] A CSV file with no parsable timestamp in any row (the index is the
      reference case) produces no stderr output and shows as nothing matched
      in the file list; `-V filter-summary` counts its rows as read and not
      matched (assertable: `tests/validate-csv-input.sh`).
- [x] A CSV mixing parsable and unparsable rows places the parsable rows on
      the timeline and prints no per-row or per-file timestamp message
      (assertable: same harness).
- [x] A CSV row without a parsable timestamp is skipped before the metric
      capture: it sets no `delta` baseline and does not count in
      `matched_lines` (assertable: four-row ISO CSV whose second data row reads
      `not a date`, `-udm 'value::delta:sum'`: the third data row's delta is
      165, not 70, and `-V format-detection` reports `matched_lines: 2` for the
      three data rows, not 3). Today the capture and the match count run
      before the timestamp check (`features/615-csv-registry-entry.md` § 3
      item 4 on release/0.19.0 measured this; #615 D8 is amended to match).
- [x] With `-udm` naming a column absent from a CSV whose rows matched, stderr
      carries exactly one `Note: -udm '<spec>': …` line for that spec across
      any number of such files, giving their count and no file name
      (assertable: two such files in one run).
- [x] With the same `-udm` over a CSV whose rows never matched, no such note
      prints (assertable: the index as input).
- [x] No row without a parsable timestamp reaches the date parse: no runtime
      warning, no fatal error (assertable: `tests/lib/runtime-warnings.sh`
      on a quoted-timestamp CSV, the #328 reproduction shape).

Gate (2026-09-30, commit bdc3135, version 0.18.5): full suite 43 of 43
harnesses exit 0; `single-day-access-log-standard` before/after on this
machine: total 9.7 s to 9.5 s (single run, the change is off the log-line
path), rss_peak 100.1 MB to 99.6 MB, lines read and included identical.
The index criterion is asserted with the index read beside a log that
produces the metric: read alone, the run-level zero-match note (#443) rightly
prints, since nothing in that run produced it.

## Implementation

- `csv_timestamp_placeable()` decides whether a CSV row can be placed: epoch
  seconds when the file's first data row was epoch, otherwise the ISO shape
  the date parse already required (`/^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}/`,
  anchored at the start, so accepted forms are unchanged). Both CSV paths
  call it (the header-confirming second line and every later row) before the
  row counts as a match; a refused row goes to `note_unmatched_line()` like
  the CSV header. The later check in the timestamp parse arm, its per-row
  warning and the per-file total are removed.
- The epoch arm is new (D3): an epoch CSV row whose timestamp is not a number
  previously reached `int()` with a Perl runtime warning
  (`Argument "abc" isn't numeric in int`) and was placed at epoch 0.
- `detect_and_parse_csv_header()` no longer prints; `udm_note_sources()`,
  called once per file on its first matched line, counts the files whose
  header lacks the metric's column (`@udm_csv_unbound_files`), and
  `emit_udm_csv_unbound_notices()` prints after the read, beside the other
  `-udm` notices: `Note: -udm '<spec>': no column named '<name>' in the header
  of N CSV file(s)`.
- `-V filter-summary`: an unplaceable CSV row moves from `excluded_other` to
  `lines_unmatched`; the section contract in
  `features/503-yaml-aggregate-export.md` is updated to match.
- `-V udm-specs` `source=` reflects only files whose rows matched: a CSV none
  of whose rows is placed no longer contributes `csv:<column>`.
- Measured on the base commit and this branch with the same inline fixtures
  (the `tests/validate-csv-input.sh` scenarios): base prints the row warning,
  counts `matched_lines: 3` and a delta sum of 70 on the mixed-row CSV, prints
  `not found in CSV headers` once per file, and emits the runtime warning on the
  epoch fixture; this branch passes all 15 assertions, base fails the 11 that
  carry #640's contract.

## Overlapping specifications on release 0.19.0

- **#615 (CSV input as a header-instantiated registry entry)**, specification
  only, implementation not started. Keeps `detect_and_parse_csv_header()`
  unchanged with "named `timestamp` or column 0"; its D1 has the template
  declare which column carries the timestamp, the natural home for a column
  rule. D5 removes the inline CSV epoch and ISO arms in favour of generated
  code; D7/D8 keep today's handling of impossible and unaccepted timestamps;
  § 2 defers accepted forms, offsets and `-st`/`-et` to #611.
- **#611**: one application-wide rule for accepting a timestamp, ordered after
  #615 (D6) so the rule lands once, in generated code.
- **#155**: timezone offsets normalised to UTC.
- **#525**: one timestamp formatter on the write side.

Consequence for a fix on 0.18.5: a change inside `detect_and_parse_csv_header()`
(column choice) survives #615 and is carried forward as is. A change to the
accepted forms, the fraction strip or quote handling touches the inline arms
#615 D5 removes, and pre-empts #611.

## Existing timestamp parsing

No single sub covers the accepted set. `compile_format_time_parser()` (fixed
positions, either separator, no validation, drops anything after position 19);
its generated copy in `format_entry_block_src()`; `parse_iso_date_to_epoch()`
(`T` only, whole seconds); `calculate_start_end_filter_timestamps()` (space
only, `Time::Piece->strptime`, its own fraction strip). The fraction strip is
written three times and the separator rule four ways.

## Candidate designs

- **Column choice only, in `detect_and_parse_csv_header()`.** Either widen the
  name lookup and, when nothing matches, warn once per file naming the column
  used; or take the first column whose first data value parses as a time. The
  second would choose the index's `entry_date` and draw a timeline of run
  dates: a quiet wrong answer, worse than today's skip. Neither makes the STATS
  CSV round-trip.
- **Accept ltl's own written forms** (strip quotes, accept `HH:MM` without
  seconds). Makes the STATS round-trip work at every precision; touches the
  arms #615 removes and the rule #611 owns, and changes the #328 skip-and-warn
  contract text.
- **No format change on 0.18.5; route to the owning issues**: column rule into
  #615's header template, accepted forms into #611, offsets into #155, the
  index rounding into #525.

## Harness

`tests/validate-csv-input.sh` (single scenario `csv-input`, inline fixtures;
#615's test plan already lists new scenarios there): rows per form, a
column-choice case, a round-trip of a real STATS CSV.
