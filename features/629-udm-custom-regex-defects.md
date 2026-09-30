# #629 — Multiple defects when using a user-defined metric with a custom regex and capture group

Umbrella record for #629. The report's four observations were investigated on
release 0.18.5 (v0.18.4 plus the version stamp) and on release/0.19.0; every
finding below behaves identically on both. Each defect has its own sub-issue
and owning doc; this doc maps the report onto them.

## Reproduction

A Windchill MethodServer log4j log family at DEBUG, carrying two shapes of the
metric's text:

- 592,322 timestamped lines of the form `DataSource ID 62 dataQueue size73889`
- 2,971 multi-line entries whose header line ends in the user name and ` - `,
  followed by continuation lines without a timestamp: ` MaxPoll Size : 200`,
  ` dataQueue size : 22440`, ` currentl chunk Size : 200`

Command: `-d count -n 20 -s -bs 15 -udm "dataQueue:B:max:/dataQueue size(.+)/"`
with a `*` glob, run from inside the log directory, twice.

## The report's observations, mapped

| Observation in #629 | What was measured | Owned by |
|---|---|---|
| Runtime warning `Argument " : 100000" isn't numeric` at the value coercion | All 2,971 warnings come from the continuation lines; every timestamped line captures a clean number. `-V udm-specs` reports `occurrences=592322`, the timestamped lines only | #637 (patterns tried on continuation lines), `features/637-udm-continuation-lines.md` |
| (found while investigating the above) | On a timestamped line, a non-numeric capture is recorded as 0 or as its leading digits, with a warning | #638 (non-numeric capture recorded as a fabricated value), `features/638-udm-non-numeric-capture.md` |
| "dataQueue … not being registered as a metric (not found in CSV headers)" | The metric is registered and fed from the logs; on the second run `-V udm-specs` reports the same `produced:` line as on the first. The warning comes only from `ltl-index.csv` being read as CSV input | #639 (own index and `-o` outputs read as input), `features/639-own-artifacts-as-input.md` |
| "CSV output was not activated, so functionality relating to the output CSV files should be gated" | The index is not a CSV-output feature: it is written on every run unless `-ni`, by design (`features/index-file.md`). The defect is that a later `*` run reads it, and the `-o` files, as input | #639 |
| "Inconsistency on how timestamps are being written to and read from the index file" | The index's write and read-back agree (both use the `T` form). CSV input takes column 0 as the timestamp when no column is named `timestamp` (for the index: `entry_type`, value `file`), and rejects the quoted minute-precision timestamp ltl's own STATS CSV carries | #640 (CSV input timestamp column and accepted forms), `features/640-csv-input-timestamp-column.md` |

## Side findings, not filed

- `-V udm-specs` reports `source=` from whichever file was read last: when
  `ltl-index.csv` sorts last, the run reports `source=csv:unbound` although
  every value came from log lines (`udm_read_as()` reads the global
  `$csv_detected`). On the same run the unit rendered as `unit=b(bytes)`
  against `unit=B(bytes)` on the first run; not investigated.
- `tests/validate-index-read-back.sh --list` regenerates the harness's
  fixtures (the two derived 5k-line slices under `logs/` and the prebuilt
  index) when it judges them stale, instead of only listing scenario names.

## Branching

Work lands on `release/0.18.5`. Every defect is present unchanged on
release/0.19.0, so each fix is carried forward when main is merged into it;
#640 overlaps specifications on that line (#615, #611, #525), recorded in its
own doc.
