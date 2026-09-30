# #640 — CSV input takes the wrong timestamp column and cannot read the timestamps ltl writes

Sub-issue of #629 (defects with a user-defined metric using a custom regex and
capture group); umbrella record `features/629-udm-custom-regex-defects.md`.
Owning area: `features/user-defined-metrics.md` § CSV Columnar Input.

## Requirement

CSV input reads its time from the column that carries it, and a STATS CSV that
`ltl` wrote can be read back as input.

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

- **The index as a CSV input test case** (architect: `ltl-index.csv` is a test
  case for CSV input and should give valid output). Measured on the index from
  the #629 reproduction, with `-ni -bs 1 -udm "line_count::sum"`:
  - The file is comma-separated (26 fields, no tab). Tab-separated input is
    already supported: `detect_and_parse_csv_header()` picks among `,`, `;`
    and tab by count, and `-ucs` overrides it; the same index converted to
    tabs reads identically.
  - As written: every row is skipped on `'file'` (column 0), `produced:
    occurrences=0`.
  - With only the header `first_timestamp` renamed to `timestamp`: the
    `2026-08-11T19:30:10.495` values parse, `produced: occurrences=20
    buckets=8`. The index writes a readable timestamp and CSV input reads that
    form; the failure is solely which column is taken.
  - The index has four time columns (`entry_date`, `file_mtime`,
    `first_timestamp`, `last_timestamp`) with different meanings, and its
    selection rows write `-` for an absent value; those rows are skipped
    (`CSV timestamp '-'`), and a `-` in a numeric column prints the #638
    (non-numeric capture) runtime warning.

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
