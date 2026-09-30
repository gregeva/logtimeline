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
| "dataQueue … not being registered as a metric (not found in CSV headers)" | The metric is registered and fed from the logs; on the second run `-V udm-specs` reports the same `produced:` line as on the first. The warning comes only from `ltl-index.csv` being read as CSV input | #640 D1 (a CSV row without a parsable timestamp is an unmatched line, silently; the metric-column note is run-level). #639 (own files read as input) closed as not planned: ltl's own files stay ordinary input, `features/639-own-artifacts-as-input.md` D1 |
| "CSV output was not activated, so functionality relating to the output CSV files should be gated" | The index is not a CSV-output feature: it is written on every run unless `-ni`, by design (`features/index-file.md`). A later `*` run reads it, and the `-o` files, as ordinary input; after #640 D1 the index produces no message and shows nothing matched | #640; #639 closed as not planned |
| "Inconsistency on how timestamps are being written to and read from the index file" | The index's write and read-back agree (both use the `T` form). CSV input takes column 0 as the timestamp when no column is named `timestamp` (for the index: `entry_type`, value `file`), and rejects the quoted minute-precision timestamp ltl's own STATS CSV carries | #640 (CSV input timestamp column and accepted forms), `features/640-csv-unplaced-rows-silent.md` |

## Side findings

- `-V udm-specs` reports `source=` from whichever file was read last, and
  shows unit `B` as `b` on a run that reads a CSV file. Both are in the scope
  of #638 (`features/638-udm-non-numeric-capture.md` D5).
- `tests/validate-index-read-back.sh --list` regenerates the harness's
  fixtures (the two derived 5k-line slices under `logs/` and the prebuilt
  index) when it judges them stale, instead of only listing scenario names.

## Branching

- **Release branch: `release/0.18.5`**, cut from main (v0.18.4 plus a
  documentation commit) on 2026-09-30; its first commit sets
  `$version_number` to `0.18.5`. Every feature doc of this cluster is
  committed there. Pull requests for #637, #638 and #640 target
  `release/0.18.5`.
- Every defect is present unchanged on release/0.19.0, so each fix reaches it
  when release 0.18.5 has merged to main and main reaches release/0.19.0.
  Records on release/0.19.0 already assume the 0.18.5 behaviour: #615 D8
  (`features/615-csv-registry-entry.md`) follows #640 D1.
- Deferred to release 0.19.0, recorded there: CSV timestamp column choice
  (#615 § 2), accepted CSV timestamp forms (#611 body), the byte-unit spelling
  shown by `-V udm-specs` (#608, already delivered on release/0.19.0), and
  D52's amendment (`features/log-format-registry.md`: a line with an
  impossible date is not matched; delivered by #611).

## Resumption

State at 2026-09-30: #637 delivered; #638 is next.

| Issue | State | Specification |
|---|---|---|
| #637 (metric patterns tried on continuation lines) | delivered: PR #641 merged to `release/0.18.5` (merge a994c82), issue closed | `features/637-udm-continuation-lines.md` |
| #638 (non-numeric capture recorded as a fabricated value) | spec complete: D1 to D5 locked, acceptance criteria written | `features/638-udm-non-numeric-capture.md` |
| #640 (CSV input reports rows it cannot place, per row and per file) | spec complete: D1, D2 locked, acceptance criteria written | `features/640-csv-unplaced-rows-silent.md` |
| #639 (own index and `-o` outputs read as input) | closed as not planned | `features/639-own-artifacts-as-input.md` D1 |

Where the three fixes meet in the code: #637 and #638 both change the
`## USER DEFINED METRICS CAPTURE` block in `read_and_process_logs()` (#637 its
gate, #638 its value validation, skip count and notice); #640 moves the CSV
timestamp check ahead of that same block, removes the CSV per-row and per-file
warnings, and turns `UDM metric … not found in CSV headers` in
`detect_and_parse_csv_header()` into a run-level note. #638 D5 also changes
`udm_read_as()` (`source=`) and the `-V udm-specs` section.

**Sequence (architect, 2026-09-30): #637, then #638, then #640, one after
another.** Each issue branches from `release/0.18.5` only after the previous
one's PR has merged and its close-out is complete, because all three change
the same metric-capture block. Recorded as native blocked-by edges: #638 is
blocked by #637, #640 is blocked by #638. Start with #637.

Next steps, per issue, following `docs/process/workflow.md`:

1. Check out `release/0.18.5` and sync it; branch `{issue}-{short-description}`
   from it; `./build/issue-status.sh set {issue} "in progress"`; set
   `$version_number` to `0.18.5-{issue}`.
2. All three touch the read loop: capture the `before` benchmark on the base
   commit (`./tests/baseline/run-benchmark.sh single-day-access-log-standard --label {issue}-before`).
3. Read `tests/HARNESS-DESIGN.md` before touching a harness or a `-V` section
   (#638 D4 and D5 change `-V udm-specs`); read `docs/architecture-patterns.md`
   and grep for the domain nouns before writing code (#638 needs one shared
   number shape, see its § Existing number shapes).
4. Build the committed `.txt` fixtures the acceptance criteria describe; the
   investigation's scratch fixtures were session-local and are not kept.
   Harnesses: `tests/validate-udm-specs.sh` (#637, #638),
   `tests/validate-udm-counting.sh` (#638), `tests/validate-csv-input.sh` and
   `tests/validate-filter-summary.sh` (#640).
5. Implement to the acceptance criteria; update `--help` and `docs/usage.md`
   in the same commit where #638 D2 requires.
6. Completion gate on the commit being merged (version restored to `0.18.5`,
   full suite, `after` benchmark), PR to `release/0.18.5`, close-out per
   `docs/process/workflow.md` § 4, one issue at a time.
7. When #637, #638 and #640 are closed: close #629, then cut release 0.18.5
   (`docs/process/workflow.md` § 5).

Not filed, recorded only: `tests/validate-index-read-back.sh --list`
regenerates the harness's fixtures instead of only listing scenario names
(§ Side findings).
