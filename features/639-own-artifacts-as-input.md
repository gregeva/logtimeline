# #639 — ltl reads its own index file, and its `-o` outputs, as input logs

Sub-issue of #629 (defects with a user-defined metric using a custom regex and
capture group); umbrella record `features/629-udm-custom-regex-defects.md`.
Owning areas: `features/index-file.md`, `features/179-index-read-back.md`.

## Requirement

A run never analyses ltl's own index, whatever glob the user gives, and the
index keeps pre-seeding later runs in that directory. Whether the `-o` output
files are treated the same way is open in the issue.

## Findings

Measured on release/0.18.5; identical on release/0.19.0.

- **Reproduction.** A scratch directory of two MethodServer log4j logs, the
  #629 metric spec, run three times with `*`:
  - Run 1 writes `ltl-index.csv`, no warnings.
  - Run 2 receives the index as an input: `-V format-detection` shows it as
    `format: csv`, and the three CSV warnings of #629 print. The metric's
    `produced:` line is the same as run 1's: it was registered and fed from the
    logs. `-V index-read-back` shows the logs at `tier_1_selection, fresh` but
    the index at `lookup: none`, so the run is `index_used: no`. The run then
    writes rows for the index into the index.
  - Run 3 and every run after: the index is `stale_size` (it is rewritten at
    the end of every run), so under the same-tier rule for multi-file runs in
    `features/179-index-read-back.md` pre-seeding never activates again.
- **Written on every run.** `write_index_file()` runs at the end of the render
  pipeline `unless $no_index`, independent of `-o`. `locate_index_file()`
  returns `ltl-index.csv` in `.` when writable, otherwise the system temp
  directory. The temp file `.ltl-index.<pid>.tmp` is not matched by `*`.
- **`-ni` stops the read and the write, not the ingestion**: an existing index
  is still read as input under `-ni`.
- **`-o` outputs are ingested too.** `<stamp>-LTL-STATS-<args>.csv`,
  `<stamp>-LTL-MESSAGES-<args>.csv` (from `build_csv_filename()`) and
  `<stamp>-LTL-AGGREGATE.yaml` (from `write_aggregate_export()`) are read by a
  later `*` run. Without a metric they add unmatched lines (39,037 → 39,126
  lines read) and block pre-seeding. With a metric and `-ni`, both CSVs are
  detected as CSV; the STATS rows are skipped only because the quoted
  timestamp is rejected (#640, CSV input timestamps), not by design.
- **No exclusion exists.** `adapt_to_command_line_options()` expands each
  argument with `bsd_glob()` (or `expand_recursive_pattern()` under `-r`),
  keeps `-f` files, and deduplicates under `-r` only. `read_index_file()` never
  compares an input path with the index path. Per #445 (unquoted glob expanded
  by the shell before `-r`), a name the shell expanded is indistinguishable
  from one the user typed.
- **Warnings.** `UDM metric '<name>' not found in CSV headers` and
  `CSV message column '<name>' not found in headers`, both in
  `detect_and_parse_csv_header()`, do not name the file. CSV detection runs
  only when `-udm` is given, which is why #629 saw the warnings only with a
  metric.
- **#615 (CSV input as a header-instantiated registry entry, 0.19.0) does not
  change this**: it keeps the lazy detection and `detect_and_parse_csv_header()`
  unchanged, so the index would still be confirmed as CSV.

## Records that bear on it

`features/index-file.md` § Location: primary `ltl-index.csv` in the working
directory with relative paths, fallback in the temp directory with absolute
paths; written atomically. `features/179-index-read-back.md`: pre-seed only
when every input file matches fresh at the same tier.
`features/503-yaml-aggregate-export.md` D18 names the aggregate YAML.

## Candidate designs

- **Exclude by name when input files are enumerated**, after the `-f` filter,
  with a notice naming the skipped file. Cheap, runs before
  `read_index_file()`, catches an index in another directory
  (`ltl logs/*/*`). A deliberately named `ltl ltl-index.csv` is refused too;
  a renamed file passes. Extending the rule to the `-o` name shapes takes a
  position on feeding a STATS CSV back deliberately.
- **Recognise by header signature** in the read-only detection sample
  (`sample_file_for_detection()`): the index header and the MESSAGES header are
  distinctive; the STATS header is not. Survives renames; gives detection a new
  responsibility.
- **Keep ltl's files out of `*`.** Either skip the file that is the same
  device and inode as the path `locate_index_file()` resolves (exact, misses an
  index in another directory), or rename the index to a dot-file (conflicts
  with `features/index-file.md` § Location and the `-ni` help text, orphans
  existing indexes, does nothing for `-o` files).

## Harness

`tests/validate-index-read-back.sh` (no scenario globs `*` beside the index;
the fix's scenario: two runs with `*`, the index has no `file:` block and the
second run reads `index_used: yes`). `tests/validate-recursive-file-selection.sh`
for the notice and the `-r '*'` path.
