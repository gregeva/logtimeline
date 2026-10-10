# CSV input as a header-instantiated registry entry: one generated parse for every input (Issue #615)

## Status

Specification agreed with the architect 2026-09-28 on branch
`615-csv-registry-entry` off `release/0.19.0`; implementation not started.
Issue #615 (CSV input as a header-instantiated registry entry) is labelled
`status: in progress`. Nothing in `ltl` has changed on the branch.

Re-audited 2026-10-08 against `release/0.19.0` at 8230949, after #525 (one
timestamp formatter, then a single timestamp-precision option), #605 (units on
inputs) and #640 (CSV rows with an unplaceable timestamp read silently) landed:
§ 3 items 9 to 11 record what moved, and D16 (a CSV timestamp is read under the
run's standard capture rules) and D17 (a CSV file takes part in the
timestamp-precision pattern as every input does) were locked in reply. #525
was reopened the same day for its several-files rule (a run gives way only to
the finest precision any processed file carries), merged in PR #691, and this
branch rebased onto `release/0.19.0` at 485e533. Drop 1, the prototype, was
measured the same day; its findings are § 8a. Drops 2 to 5 were delivered
the same day (§ 9): CSV input is read through the block generated from each
file's header, and the uncalled parse closures are gone.

The design is locked in outline by the architect (§ 4: D1 to D6 from stage 5 of
the redundant-logic-surfaces review, 2026-09-27; D7 to D15 in reply to this
specification's questions, 2026-09-28). It stays prototype-gated (D3, a
prototype decides the design): the prototype scoped in § 8 runs, and its
findings are recorded here, before any `ltl` change. Elements of § 5 settled by
a lock are written as settled; what remains labelled **proposed** is
implementation detail the architect has not decided, and carries no authority
until he agrees it.

This issue is a sub-issue of #622 (the refactoring the redundant-logic-surfaces
audit dispatched). It blocks #611 (one application-wide pattern for accepting a
timestamp and for an invalid or ambiguous date) and #387 (user-configurable YAML
format definitions); both edges are native and verified. It also blocks #386
(per-format analysis precision) by D13; that edge is recorded with this
specification's delivery (§ 10).

---

## 1. The motivating consumer

Three issues wait on this one: #611 and #387 by native edges already recorded,
and #386 by D13, whose edge is recorded with this specification's delivery.

**#611, the timestamp acceptance pattern.** #611 designs one rule for what
happens when a timestamp cannot be accepted, and applies it to every place that
parses one. Today CSV input parses its timestamps in two hand-written arms of the
read loop, one for ISO values and one for epoch values, beside the generated
blocks every scanned format uses. If #611 landed first, it would write its
pattern into those two arms and into the generator, then again when the arms are
replaced. With this issue first, #611 writes its pattern once, into the
generated source, and CSV input inherits it.

**#387, user-declared formats.** A format a user declares in YAML is a template
the tool instantiates on demand. A CSV file is already that kind of thing: its
field positions come from its own header, not from a built-in spec. Building CSV
input as a header-instantiated entry is the first use of the mechanism #387
needs, on an input the tool already reads.

**#386, per-format analysis precision.** #386 (default analysis precision per
format, with demand-driven sub-second handling) rewrites the fractional-second
strip in the generated source. It is blocked by this issue (D13), so that
rewrite lands once, in the generated source, and covers CSV too, instead of
leaving an inline copy behind.

For the user, a CSV file read with `-udm` gives the same timeline, statistics
and index as before. Three things a user can see change:

- a CSV file whose sampled dates are real dates only when read day first
  (year, day, month) is read day first, where today the run aborts on the first
  such row (D15: the file's date order is settled once, from its sampled rows,
  by D9's validation with a day-first retry);
- the `-ucs` and `-ucm` rows of `--help` and `docs/usage.md` describe what the
  options do (D14);
- the compile counts of `-V format-registry` and `-V benchmark-data` include the
  CSV block on CSV runs (D11).

What changes inside is that there is one text for parsing a timestamp in the
tool, so a change to that text reaches every input.

---

## 2. Requirement

The architect's terms, transcribed from the issue body, the stage 5 lock of the
redundant-logic-surfaces review and the 2026-09-28 locks, organised, not
reinterpreted.

**What is wanted.** CSV input is read like any other log format: a registry entry
whose per-line block is generated from the same source text as every scanned
format's block, so there is one parse of a timestamp in the tool. What makes CSV
different is that its field positions come from each file's header rather than
from the spec, so the entry is a template the header instantiates, per file. The
header row builds the routine that reads all the lines: it says which custom
metrics there are and where their values sit, and that mapping is compiled into
the routine (D10).

**What is wrong today** (the audit report's § Item 3, measured there):

- The inline CSV arm in the read loop and the generated scan blocks carry the
  same parse twice: the same substring offsets, the same time-library call order,
  the same fractional-second strip. A comment says they agree; nothing checks
  it. A closure is compiled for every registry entry and called only by the CSV
  ISO arm; the seven Apache closures are never called.
- The CSV arm has no last-seen memo, so it recomputes the time of day on every
  row where the scanned blocks reuse the previous epoch.
- Epoch-or-ISO detection for CSV is written in two arms of the loop.
- Any change to the generated source (the per-format precision work in #386
  rewrites the fractional strip there) leaves the inline arm behind.

**Findings in scope** (the stage 5 and stage 15 decisions of the review):

| Finding | What the audit found |
|---|---|
| F3.1 | the timestamp parse (substring offsets, `timegm` argument order, time-of-day arithmetic) written twice, in the generated block source and in per-entry closures, tied only by a comment |
| F3.5 | the fractional-second strip and its normalisation to milliseconds written in the generated source and again in the CSV ISO arm |
| F3.6 | CSV epoch detection written in the steady CSV arm and again in the lazy-detection confirm arm |
| F3.7 | the last-seen memo present on scanned arms and absent on both CSV arms |
| F8.3 | the whole CSV data-line sequence (timestamp trim, epoch test, message from `-ucm`, the `DATA` category, record reset, classification) written twice |

**Added from #640 (CSV input takes the wrong timestamp column), deferred here
by the architect on 2026-09-30.** Which column carries a CSV file's timestamp
is in scope. Today `detect_and_parse_csv_header()` takes a column named
`timestamp` (case-insensitive) and otherwise column 0, with no check of what
column 0 holds. Measured on release/0.18.5: a header whose time column is named
`created_at` has its numeric id column read as epoch seconds, placing every row
on a wrong date with no indication; `ltl-index.csv`, whose own time column is
`entry_date` (column 2), has `entry_type` read as its time. The template's
declaration of which column carries the timestamp (D1) is where the rule is
settled. Record: `features/640-csv-unplaced-rows-silent.md` on
release/0.18.5.

**Done when** (issue body): a CSV file is read through a generated block and
gives the same timeline, statistics and index as before; there is one parse text
for a timestamp in the tool; the benchmark shows no regression on scanned formats
and reports the CSV cost per line against the inline arm.

**Out of scope, by the architect's ordering.** What happens to an invalid,
impossible or unaccepted timestamp on any row (the audit's findings on the
impossible-date guard, the CSV epoch arm's input, the timezone suffix and the
`-st`/`-et` parser) belongs to #611 (the timestamp acceptance pattern), which
lands on the one generated parse this issue produces. This issue keeps today's
per-row behaviour: the abort on a date that is impossible under the order the
file is read with (D7), and a row whose timestamp is neither epoch nor ISO read
and not matched, silently, before any further processing (D8, as #640 D1
delivers it on release 0.18.5). The one date question this issue does answer is per file,
before any row is read: which of the two date orders the file's sampled rows are
written in (D9). It is settled once, so a file whose sampled dates are real only
when read day first is read day first instead of aborting (D15).

---

## 3. Corrections to the issue body and the audit record

Verified against the worktree's `ltl` at `release/0.19.0` (the only change to
`ltl` since the audit's runs is the release version stamp), by `grep -F` on the
cited snippets, by reading the subs, and by captured runs. Each item names what
was looked for and what was found.

1. **Only the confirm arm's epoch test can fire; the steady arm's copy is
   unreachable.** Looked for: the two epoch-detection copies the issue and the
   audit's findings on epoch detection and the data-line sequence describe as
   live. Found: `read_and_process_logs` ::
   `if ($line_number == 2 && defined $timestamp_str && $timestamp_str =~ /^\d+(\.\d+)?$/) {`
   sits in the steady arm, which runs only when `$csv_detected` is set.
   `$csv_detected` is set in one place, `detect_and_parse_csv_header` ::
   `$csv_detected = 1;`, which is called only from the lazy-detection block at
   line 2, after the steady arm has already been passed for that line; it is
   reset to 0 at every file start. The steady arm therefore first runs on line
   3, and its line-2 test never matches. Epoch mode is decided by the confirm
   arm's copy alone. The duplication is real as text; its divergence risk is
   nil, because one copy is dead.

2. **Every per-entry closure except the `csv` entry's own is uncalled, not only
   the Apache ones.** Looked for: which closures `compile_format_time_parser`
   builds and which are called. Found: `build_format_registry` ::
   `$entry->[FR_TIME_PARSE]      = compile_format_time_parser( $spec->{time}{layout} );`
   builds one for every entry in `format_registry_specs()` (21 entries). The
   only caller is `read_and_process_logs` ::
   `$timestamp = $line_entry->[FR_TIME_PARSE]->($timestamp_str);`, where
   `$line_entry` is always `$format_registry_entry{csv}`. So the one closure
   ever called is the `csv` entry's (its layout `csv` falls through to the ISO
   branch); the twenty others, ISO and Apache alike, are built and never
   called. Scanned formats have parsed inline in the generated block since the
   single-generated-scan-sub decision of the format-registry drop
   (`features/58-format-registry-staged-detection.md`, D39: one generated sub
   with inline timestamp handling).

3. **The emitter keys its impossible-date guard on the `iso_*` layouts, and the
   `csv` entry does not declare one.** Looked for: what `format_entry_block_src`
   would emit for the `csv` entry's declared time contract
   (`time => { layout => 'csv', precision => 'ms', tz => 'utc' }`, no `frac`).
   Found: `format_entry_block_src` :: `my $frac = $spec->{time}{frac} // 'generic';`
   selects the generic strip, the same text as the CSV ISO arm's; and
   `format_entry_block_src` :: `my $miss_src = $layout =~ /^iso_/` emits the
   month and day range test, the probe signal and the re-scan only for `iso_*`
   layouts, so layout `csv` gets the memo and the unguarded parse. Passing the
   `csv` contract through the existing emitter unchanged reproduces today's CSV
   behaviour on an impossible date, plus the memo. That is D7 (the run still
   aborts on an impossible date).

4. **A CSV row skipped for its timestamp has already fed the user-defined-metric
   capture and the per-file match count.** Looked for: the order of the steps
   between the CSV arms and the timestamp parse. Found: the ISO parse and its
   skip (`read_and_process_logs` ::
   `if (!defined $timestamp_str || $timestamp_str !~ /^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}/) {`)
   run after the user-defined-metric capture (which updates the `delta`
   baseline in `%udm_last_value`) and after the format-detection tracking
   (`$fdd->{matched_lines}++`). Measured on a four-row ISO CSV whose second data
   row reads `not a date`, with `-udm 'value::delta:sum'`: the third data row's
   delta is 70, the difference from the skipped row's value, where skipping the
   row outright would give 165; `-V format-detection` reports `matched_lines: 3`
   for three data rows of which one was skipped. D8 removes both: the row is
   skipped before the capture and the match count (§ 5.5).

5. **The CSV February 30 case exits 255, not 1.** Looked for: the audit
   table's exit code for a CSV row carrying `2025-02-30`. Found: a two-row CSV
   read with `-udm 'value::max' --disable-progress -V` aborts with the time
   library's range message naming a source line and exits 255, as the month-13
   case does. The audit table records exit 1 for this case. The behaviour
   (the run aborts) is as recorded.

6. **Stage 5's order column says "after #611"; its decision and the native
   edges say the reverse.** Looked for: the ordering between this issue and #611
   (the acceptance pattern). Found: the audit report's § Review progress,
   stage 5, *Order reason* reads "after #611; before #387 and #386", written
   before the stage was decided; its *Decision* reads "#611 (acceptance pattern)
   blocked by it", and the native edges agree: this issue blocks #611 and #387
   (user-declared YAML formats), and #611 blocks #387. The decision and the
   edges are correct; the order column is stale. This document records the
   correction; the audit report's column is not edited. The same column puts
   this issue before #386 (per-format analysis precision), which no native edge
   recorded; D13 locks that edge.

7. **Nothing clears the last-seen memo per file.** Looked for: where
   `$format_last_ts_str` and `$format_last_ts_epoch` are reset. Found: only in
   `format_registry_set_occupant` (an occupant swap, with the date-cache clear)
   and `format_record_reset` (validation and build). A CSV block that carries
   the memo (D1) resets it at instantiation (§ 5.4). A run of a day-first slice
   of the Integration Runtime family followed by a CSV carrying the same date
   string showed no cross-file leak on this ordering: the CSV rows land on their
   own dates, because the occupant returns to the default member at the next
   file, which clears the cache and the memo. A CSV block read day first (D9)
   is the new case that can leave day-first readings in the date cache; § 5.4
   clears them.

8. **The `-ucs` and `-ucm` help rows describe something other than what the
   options do.** Looked for: the options' rows against `detect_and_parse_csv_header`.
   Found: the `-ucs` row in `--help` and `docs/usage.md` reads "Set the CSV
   field delimiter when using `-ucm` (default: comma)", but the header reader
   auto-detects comma, semicolon or tab from the header, and `-ucs` overrides
   that whether or not `-ucm` is given. The `-ucm` row ("Treat the message field
   as CSV and name the columns for use with `-udm`") differs from what the
   option does: it names the header columns whose values form the message. D14
   corrects both rows in this issue.

The findings the issue cites are otherwise confirmed as written: the two parse
texts are identical today (substring offsets, argument order, arithmetic); the
fractional strip is the same regex and normalisation in both places; the CSV ISO
arm goes to the date cache with no memo and the epoch arm uses neither.

**Re-audit of 2026-10-08** (`release/0.19.0` at 8230949, by `grep -F` on every
snippet of § 5.1 and by reading the subs; nothing run):

9. **The fractional strip is no longer the same in both places; the inline CSV
   arms read outside the run's capture rules.** Looked for: the claim above that
   the strip is the same regex and normalisation in the generated source and the
   CSV ISO arm. Found: #525 (single timestamp-precision option) gave the emitter
   a read gate, two booleans settled once and passed as compile options
   (`build_format_registry` ::
   `capture_fraction => $timestamp_capture_fraction, capture_ns => $timestamp_capture_ns`).
   The generic strip now reads up to nine digits when the gate is open, strips
   without reading when it is closed, and keeps the digits as text only under
   `-tp ns` (`format_entry_block_src` ::
   `my $capture = $opts->{capture_fraction} // 1;`). The CSV ISO arm still reads
   up to six digits on every row and always keeps them as text
   (`read_and_process_logs` :: `if ($timestamp_str =~ s/(:\d{2}:\d{2})[.,](\d{1,6})/$1/) {`);
   the epoch arm always takes the fraction from the floating value and never
   keeps text digits (`$fraction_digits = '';`). A CSV file is also no source of
   its file's true precision: `resolve_timestamp_precision` reads digit counts
   the detection sample takes only for lines a scanned entry matched. The
   rules are written up as `docs/architecture-patterns.md` § *Timestamp
   precision: requested by the user, bounded by what each file carries*.
   Settled by D16 (the read gate) and D17 (a CSV file's sampled rows are its
   precision evidence).
10. **#640 D1 has landed on `release/0.19.0`; D8 is today's behaviour.** Looked
    for: the ISO shape check of § 3 item 4
    (`if (!defined $timestamp_str || $timestamp_str !~ /^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}/) {`).
    Found: absent; both CSV arms now call `csv_timestamp_placeable` before the
    message, the category and the metric capture
    (`read_and_process_logs` :: `unless (csv_timestamp_placeable($timestamp_str)) {`),
    and a row that fails it is counted by `note_unmatched_line` and leaves the
    loop. The four-row case of item 4 therefore reads 165 on the base commit,
    not 70; AC2's 165 is a parity expectation, not a change this issue makes.
11. **One § 5.1 snippet no longer matches.** `my $compute = ($layout eq 'apache_clf')`
    is now the second arm of a chain that starts
    `my $compute = ($layout eq 'asctime')`; § 5.1 is trued up. The other
    snippets of § 5.1 match as written.

---

## 4. Locked decisions

These are the architect's. They are restated, not reinterpreted. Nothing else in
this document is numbered Dxx.

**From stage 5 of the redundant-logic-surfaces review (2026-09-27).**

- **D1 — CSV input is a registry entry instantiated from each file's header.**
  The CSV input becomes a registry entry: a template that declares how the
  header is read (which column carries the timestamp, which columns carry the
  values user-defined metrics name) and whose per-line block is generated per
  file from that header, through the emitter the scanned formats use, memo
  included, and cached by the header's shape. The per-file block is the file's
  own arm; a CSV file is never interleaved with scanned lines, so it need not
  sit inside the shared scan sub. *Locked by the architect 2026-09-27, stage 5
  of the redundant-logic-surfaces review (#342) (the issue body's first lock).*
  **Amended by the architect 2026-10-08, after the prototype (§ 8a): an epoch
  CSV block carries no memo** ("yes, amend D1: no memo for epoch CSV"). The
  memo was measured costing 46 to 101 ns per row on epoch CSV at one row per
  second and saving nothing at ten rows per second, because a hit saves only
  turning the whole-second text into a number. An ISO CSV block keeps the
  emitter's memo exactly as the scanned formats have it.
- **D2 — The registry's existing compile-and-cache mechanism is reused.** The
  registry's existing on-demand compile and signature cache is the mechanism,
  keyed per file instead of per scan order. *Locked by the architect 2026-09-27,
  stage 5 of the redundant-logic-surfaces review (#342).*
- **D3 — A prototype decides the design.** This is a new capability in the hot
  path: a prototype (`prototype/README.md`) measures the inline arm against a
  header-instantiated generated block on one CSV file, same output, cost per
  line, before the design is fixed. *Locked by the architect 2026-09-27, stage 5
  of the redundant-logic-surfaces review (#342).* D12 sets what the prototype
  measures.
- **D4 — The uncalled closures go.** The uncalled per-entry closures go with the
  inline arm. *Locked by the architect 2026-09-27, stage 5 of the
  redundant-logic-surfaces review (#342).*
- **D5 — Scope.** The audit's findings on the two parse texts (F3.1), the two
  fractional strips (F3.5), the two epoch-detection copies (F3.6) and the memo
  missing from CSV (F3.7) are this issue's (*locked by the architect 2026-09-27,
  stage 5 of the redundant-logic-surfaces review (#342)*), and so is the
  duplicated CSV data-line sequence (F8.3) (*locked by the architect 2026-09-27,
  stage 15 of the redundant-logic-surfaces review (#342)*).
- **D6 — Ordering.** #611 (the timestamp acceptance pattern) is blocked by this
  issue so that the pattern lands on one generated parse (*locked by the
  architect 2026-09-27, stage 5 of the redundant-logic-surfaces review (#342)*);
  #387 (user-declared YAML formats) is blocked by this issue, because a
  user-declared layout is instantiated by the same template mechanism (*recorded
  by the architect's edge audit of 2026-09-27 in the review sessions log, stages
  1 and 5*).

**In reply to this specification's questions (2026-09-28).**

- **D7 — A CSV row with an impossible date keeps today's behaviour.** The run
  aborts on a row whose date is impossible (month 13, February 30) under the
  order the file is read with, as it does today. The CSV entry passes through
  the emitter with its declared layout, so it does not inherit the scanned
  formats' impossible-date guard (which keeps such a row at the previous row's
  time). #611 (the timestamp acceptance pattern) owns any change, on the one
  generated text. *Locked by the architect 2026-09-28; the clause "under the
  order the file is read with" is the architect's amendment of 2026-09-28
  (D15).* **Superseded by #611** (one application-wide timestamp acceptance
  pattern, `features/611-timestamp-acceptance.md` C3): such a row is not
  matched, is counted, and is noted once per run; the day-first retry of D9
  still reads the block's undef return on a sampled row as a date failure.
- **D8 — A row with an unacceptable timestamp is not matched, and nothing
  further happens to it.** A row whose timestamp is neither epoch nor ISO is
  read and not matched: it is skipped before the metric capture and the
  per-file match count, never sets the `delta` baseline, does not count in
  `matched_lines`, and prints nothing, per row or per file. This is #640 D1
  (`features/640-csv-unplaced-rows-silent.md`, release 0.18.5): a line is
  placed on the timeline only once its timestamp parses, and only a placed line
  goes on to any further processing. The measured case of § 3 item 4 (the next
  row's delta read 70 from the skipped row) becomes 165. *Locked by the
  architect 2026-09-28; amended by the architect 2026-09-30 to follow #640 D1,
  replacing "the skip stays after the metric capture, as today".*
- **D9 — An instantiated CSV block is validated on the file's actual data, not
  on synthetic rows.** Following the tool's standard practice, the block is
  validated on rows sampled from several parts of the file through the existing
  detection sample mechanism (front, middle and end parts, as the detection
  sample reads them); the file descriptor is then reset before the first data
  row. This gives assurance about a wrong date layout: a validation that fails
  on a day/month ambiguity re-instantiates the block with the day and month
  flipped (the day-first layout) and validates again. The registry's
  proven-before-use guarantee carries over, the file's own column wiring
  included. *Locked by the architect 2026-09-28 ("validate it on the actual data
  using the existing model looking to validate across multiple plarts of the
  file, then just reset the file descriptor ... you could fail the validation,
  and then re-write it with the day/month flipped").*
- **D10 — The header row builds the routine that reads all the lines.** The
  objective is to know which custom metrics there are and to map the values to
  them. That index and mapping happens once, on the header row, and is compiled
  into the generated routine, which then reads every line: the block carries the
  column positions as constants and extracts the timestamp and each named
  metric's value itself, with no per-row column-map lookup in a shared block.
  The header-shape signature includes the metric columns. *Locked by the
  architect 2026-09-28 ("the index/mapping only needs to happen on the header
  row in order to build the routine which will read all of the lines").*
- **D11 — At most one CSV block is alive at a time.** The rule on how many subs
  a run compiles is purposeful here, and the way to stay within it is eviction:
  when a new file requires generating a new block (a different header shape),
  the previous CSV block is deleted, so no more than two compiled subs exist at
  once (the scan sub and the current CSV block). The existing compile and
  cache-hit counters count CSV blocks; the registry harness's invariant
  assertions are restated to include the CSV block (a run pinned to `csv`
  reports its scan sub plus one CSV block; two same-shape files report one block
  compile and one cache hit). *Locked by the architect 2026-09-28 ("you should
  delete the compiled sub IF a new file requires generating a new one (so you
  are compliant if there are only 2 existing at a time)").*
- **D12 — The prototype measures two families, and delivery benchmarks a named
  CSV case.** The prototype measures an epoch family and an ISO family, each at
  one row per distinct second and at several rows per second, generated to the
  corpus specimens' row shapes at 1k, 10k, 100k and 1M rows. At delivery a named
  CSV selection is added to the benchmark runner outside every tier and run by
  name before and after. *Locked by the architect 2026-09-28.*
- **D13 — #386 (per-format analysis precision) is blocked by this issue.** The
  ordering is a native edge, so #386's fractional-strip rewrite lands once, in
  the generated source, and CSV inherits it. *Locked by the architect
  2026-09-28.*
- **D14 — The `-ucs` and `-ucm` help rows are corrected in this issue.** As a
  records fix: the delimiter is auto-detected (comma, semicolon or tab) and
  `-ucs` overrides it with or without `-ucm`; `-ucm` names the header columns
  whose values form the message. The `docs/usage.md` rows follow in the same
  commit. *Locked by the architect 2026-09-28.*
- **D15 — A CSV file's date order is settled once, from its sampled rows,
  before any row is read.** D9's validation with the day-first retry decides the
  order the file is read with. A CSV whose sampled dates are real only when read
  day first (a two-row file dated `2025-13-01`) is read day first instead of
  aborting. D7's abort on month 13 or February 30 applies only to a row that is
  impossible under the order the file is read with. This is a user-visible
  change and gets a release-notes line (§ 10). *Locked by the architect
  2026-09-28 ("yes I lock the reading about user-visible change getting a
  release note line").*

**In reply to the re-audit (2026-10-08).**

- **D16 — A CSV file's timestamp is read under the run's standard capture
  rules.** The CSV block takes its fraction handling from the emitter under the
  same compile options as every scanned format: the fraction is read only when
  the read gate is open, up to nine digits, and kept as written only under
  `-tp ns` (`docs/architecture-patterns.md` § *Timestamp precision*, rule 3; owning
  record `features/525-timestamp-precision-option.md` D4, D21, D23). There is
  no CSV-specific digit count: the default is the emitter's, and `-tp`
  controls it. The epoch layout follows the same gate. Where this reads digits
  the inline arms dropped, the output changes (§ 5.9); AC1 is restated to
  match. *Locked by the architect 2026-10-08 ("yes, you should align to the
  standard capture rules and reference the read pattern and write it up").*
- **D17 — A CSV file takes part in the timestamp-precision pattern as every
  input does.** A CSV file is one of the execution's processed files, and
  every rule of `docs/architecture-patterns.md` § *Timestamp precision*
  applies to it as to a scanned file. Its true precision is read from the
  rows D9 validates on: the unit its timestamp field states (an ISO clock time
  states the second; an epoch value states its unit, #525's D10)
  and the fraction digits those rows carry. It bounds the user's `-tp` only as
  rule 4 says (`features/525-timestamp-precision-option.md` D4 as amended
  2026-10-08): the request gives way only to the finest precision any
  processed file carries, so a CSV carrying less than another processed file
  does not lower the run. The command-line options that act on the pattern
  act on a CSV file the same way: `-tp`, a width that is not a whole number of
  seconds, a `-st`/`-et` bound with a fraction and `-o` (D16). *Locked by the
  architect 2026-10-08 ("this should be a common pattern [and] the command
  line options that influence this pattern should also be the same"); the
  several-files reading is his amendment of #525's D4 the same day.*

**After drop 3 (2026-10-08).**

- **D18 — Every CSV file's date order is settled starting month first,
  whatever file came before it.** A file is read day first only when its own
  sampled rows are real dates only that way. The block kept in memory from
  an earlier file is reused only for the date order being tried, so a file
  whose dates are all ambiguous (day and month both 12 or less) is read
  month first, as it would be on its own, even after a day-first file with
  the same header. The cost: when day-first files with the same header
  follow each other, each one generates a month-first block that fails and
  then a day-first block, two compiles, about 2 ms per file (§ 8a, per
  file). This replaces § 5.4's earlier reading, under which the block in
  memory was tried first in whatever order it had, and an ambiguous file
  read after a day-first one was read day first. *Locked by the architect
  2026-10-08 ("Yes for Option B").*

**Where D7 and D9 meet (settled by D15).** D9 decides the file's date order
once, from the sampled rows, before any row is read; D7 governs a row whose date
cannot exist under the order the file is read with. So a file whose sampled rows
are real dates only when read day first is read day first, and a row outside the
sample that is impossible under the chosen order aborts the run as today. The
audit's two-row month-13 fixture (`2025-13-01`) is such a file: its only data
row is in the sample and reads as 13 January day first, so it now reads rather
than aborts. The February 30 fixture (`2025-02-30`) is impossible in both
orders, so it aborts as today.

Standing decisions this work must keep (not re-locked here, owned elsewhere):

| Record | Decision | What it means for this work |
|---|---|---|
| `features/log-format-registry.md` | D32 (CSV stays a stateful per-file stage outside the scan array, with a non-scanned `csv` entry; lazy detection mechanics unchanged) | the header is still stashed at line 1 and confirmed at line 2 when the scan fails and the field counts validate; only the data-line handling becomes generated |
| `features/log-format-registry.md` | D60 (zero code generation at startup; generation where it is about to be used) | the CSV block is generated at CSV confirmation, never at startup |
| `features/log-format-registry.md` | D53 (the detection evidence sample: a read-only look at a seekable file before its first line, through its own handle, nothing held or replayed) | the sampled rows D9 validates on come from this sample; the sample's own handle is the one that moves, the production read does not |
| `features/log-format-registry.md` | trap F11 of the lazy scan-sub compilation record (a mid-run compile disturbs nothing of the run's state) | validating the CSV block snapshots and restores the record lexicals, the memo and the date cache |
| `features/log-format-registry.md` | N3 (the date cache is keyed by date string alone; an occupant change clears it and the memo) | the CSV block clears the memo and the date cache at instantiation, and a day-first CSV block leaves no day-first reading behind (§ 5.4) |
| `features/58-format-registry-staged-detection.md` | A6 and P8 (the fast path's exact semantics and the date cache's parity) | per-row epoch, fractional milliseconds, cache keys and the index precision hint stay identical for a month-first file |
| `features/525-timestamp-precision-option.md` | D4 (the precision printed never goes below what the file contains), D21 (the read gate is decided per consumer, the export among them), D23 (nanosecond carried by exact bounds) | the CSV block reads its fraction under the same gate and compile options as the scanned blocks (D16) |
| `features/user-defined-metrics.md` | § CSV Columnar Input (a row whose timestamp is neither epoch nor ISO is an unmatched line, silently, per #640 D1) and § Epoch timestamps (epoch detected on the first data row; `-du` sets its unit) | kept as they are (D7, D8); #611 (the timestamp acceptance pattern) owns any change |

D31 of the format registry (the time contract compiled to per-layout parse
closures) is the decision that this issue's D4 (the uncalled closures go)
retires in its closure form: since the single-generated-scan-sub decision, the
parse lives in the generated source and the closures serve only CSV. Recording
that retirement against D31 is a record true-up that follows from D4 (§ 10).

---

## 5. Design

Settled elements cite the lock that settles them. What is labelled
**proposed** is implementation detail the architect has not decided.

### 5.1 The sites this work reaches, as they are today

Cited by sub plus an in-body snippet.

| Site | Snippet | Today |
|---|---|---|
| `format_entry_block_src` | `my $compute = ($layout eq 'asctime')` | the live parse for every scanned format, emitted as source text into each block: fraction handling by the declared `frac`, then the memo, then the layout parse on a memo miss |
| `format_entry_block_src` | `my $capture = $opts->{capture_fraction} // 1;` | the read gate's compile options selecting the fraction text: strip without reading, read up to nine digits, or read and keep the digits under nanosecond (§ 3 item 9) |
| `read_and_process_logs` | `if ($timestamp_str =~ s/(:\d{2}:\d{2})[.,](\d{1,6})/$1/) {` | the CSV ISO arm's own strip: up to six digits, every row, outside the gate |
| `read_and_process_logs` | `unless (csv_timestamp_placeable($timestamp_str)) {` | the skip of a row whose timestamp is neither epoch nor ISO, in both CSV arms, before the capture (#640 D1; § 3 item 10) |
| `format_entry_block_src` | `push @body, qq{if (\$timestamp_str eq \$format_last_ts_str) { \$timestamp = \$format_last_ts_epoch; }` | the last-seen memo |
| `format_entry_block_src` | `my ($day_off, $month_off) = $layout eq 'iso_ms_ddmm' ? (5, 8) : (8, 5);` | the emitter's date-order choice: day-first offsets for the day-first ISO layout, month-first for every other |
| `compile_format_time_parser` | `my ($day_off, $month_off) = $layout eq 'iso_ms_ddmm' ? (5, 8) : (8, 5);` | the closure copy of both parse families, built per entry |
| `build_format_registry` | `$entry->[FR_TIME_PARSE]      = compile_format_time_parser( $spec->{time}{layout} );` | the closure's only construction site |
| `sample_file_for_detection` | `seek $sfh, $offset, 0;` | the detection sample: its own handle, seeked to the front, middle and end parts (three parts of 8 KiB, or the whole file when it is no larger), whole lines only |
| `read_and_process_logs` | `delete $sample->{lines};   # conclusions are retained, lines are not` | the sampled lines are dropped once the evidence consumers have read them, before line 1 |
| `read_and_process_logs` | `if ($csv_detected) {` | the steady CSV arm: split, trim, dead epoch test, message from `-ucm`, `DATA`, record reset, classify |
| `read_and_process_logs` | `# Confirmed CSV — process line 2 as data` | the confirm arm at line 2: the same sequence, with the live epoch test |
| `read_and_process_logs` | `my $col_idx = $csv_udm_col_indices[$config_idx];` | the shared metric capture's CSV branch: a per-row, per-metric lookup of the column the header mapped |
| `read_and_process_logs` | `$timestamp = int($epoch_val);` | the CSV epoch arm, before the category gate, with the `-du` scaling |
| `read_and_process_logs` | `} elsif (!$csv_epoch_timestamp && $match_type == 13) {` | the CSV ISO arm, after the category gate: strip, shape check (skip, count, warn once per file), closure call |
| `read_and_process_logs` | `my $timestamp_epoch = $timestamp + ($fractional_ms / 1000);` | the join point every arm feeds |
| `detect_and_parse_csv_header` | `$csv_detected = 1;` | the header reader: separator, column map, timestamp column (named `timestamp` or column 0), metric and message columns |
| `udm_read_as` | `my ($col_name) = grep { $csv_col_index{$_} == $col } keys %csv_col_index;` | `-V udm-specs` names each metric's source column from the header's column map (read once per report, not per row) |
| `format_scan_sub_resolve` | `return $format_scan_sub = $format_scan_sub_cache{$sig}` | the signature cache the lock names as the mechanism |
| `compile_format_scan_sub` | `format_validate_scan_sub($sub, \@entries);` | every generated sub validated against its entries' samples before it serves a line |
| `format_registry_specs` | `{ name => 'csv', slug => 'csv', match_type => 13, scanned => 0,` | the stateful `csv` entry: no pattern, no samples, time layout `csv` |

Measured constant (captured runs, this machine, three runs each): today's
whole-run read cost of CSV input on a network-latency CSV whose first column is
an epoch timestamp with a six-digit fraction (166,912 rows, `-udm` on one
column, `-bs 1440 -oe -n 1 -ni`) is `TIMING parse/read_files` median 1.812 s
(1.805 to 1.816 s), about 10.9 µs per row, re-measured 2026-10-08 on
`release/0.19.0` at 485e533 because the code had moved since the specification
(2026-09-28: median 1.725 s, 1.674 to 1.743 s, 10.3 µs per row; 5% higher now,
the arms' shape unchanged). The timestamp arm is a small share of
that, so a whole-run comparison alone cannot resolve the difference between two
arm shapes (§ 8).

### 5.2 Target shape

One emitter produces every timestamp parse in the tool. The scanned formats'
blocks and the CSV block both take their fraction handling, memo and layout parse
from it. The CSV block is generated from the header at CSV confirmation, with the
column positions compiled in, validated on the file's own sampled rows, held as
the one live CSV block, and called as the file's own arm.

```
before line 1  detection sample: front, middle, end parts     (D53, its own handle)
line 1   stash as potential header                            (unchanged, D32)
line 2   scan fails, header validates, field count validates  (unchanged, D32)
         -> header shape = (separator, timestamp column, timestamp kind,
                            each metric's column, message columns)  (D10)
         -> month first: the live CSV block if built for this shape
            and order (D2, D11: cache hit), else generate it   (D1, D18)
         -> validate the block on this file's sampled rows      (D9)
            date failure -> day first: the live block if built for it,
            else evict and generate it, validate again         (D9, D11, D18)
         -> block(line 2)
line 3+  block(line)                                            (the file's arm)
```

### 5.3 The emitter split (proposed)

The timestamp part of `format_entry_block_src` (the `frac` selection, the memo,
the layout `$compute` text and the `iso_*` miss branch) moves into its own
emitter sub, called by `format_entry_block_src` and by the CSV template's
instantiation. For every scanned entry the generated source is byte-identical
before and after the split; that is the proof the split changed nothing on the
hot path of scanned formats (criterion AC4, the byte-identical dump).

The epoch parse becomes a layout the same emitter produces, with no memo (D1 as
amended 2026-10-08): the `-du` scaling
(`read_and_process_logs` :: `my $step = $time_unit_step{$duration_unit_override};`)
is a run constant and is folded into the emitted text at generation, as the
query-string option already is (`format_entry_block_src` ::
`if ($t eq 'strip_query_string') { next if $opts->{include_query_string}; }`).
Its fraction follows the read gate (D16): closed, the fraction is not read;
open, it is read from the value; under `-tp ns` the digits after the point
are kept as written in `$fraction_digits`, as the generic strip keeps them,
rather than derived from the floating value (proposed; a `-du` scaling of a
fractional epoch value below the second leaves no text digits to keep, and
falls back to the floating value).

The day-first CSV reading (D9) is a second CSV layout, day-first and unguarded
like `csv` (D7): the emitter's date-order choice picks the day-first offsets for
it as it does for the day-first ISO layout, and its miss branch stays the `csv`
one, so the day-first CSV block aborts on an impossible date as the month-first
one does. The layout's name is an implementation detail.

### 5.4 The CSV template and its instantiation

- **The template is the `csv` entry.** It keeps `scanned => 0`, no pattern, and
  its time contract; it gains the declaration of what the header supplies. Its
  declared layout stays `csv`, so the emitter gives it the generic strip, the
  memo and the unguarded ISO parse (§ 3 item 3; D7).
- **The header reader is `detect_and_parse_csv_header`, unchanged.** It already
  resolves the separator, the column map, the timestamp column and the metric
  and message columns. It is the template's "how the header is read". Its column
  map stays for `-V udm-specs`, which names each metric's source column from it
  once per report.
- **The header builds the routine (D10).** The header shape is the separator, the
  timestamp column, the timestamp kind decided on the first data row (epoch or
  ISO, as § Epoch timestamps of the user-defined-metrics record specifies), each
  `-udm` metric's column position (none for a metric the header does not
  carry), and the `-ucm` message columns. It is known at line 2. The cache
  signature is that shape plus the date order. A file's order is settled
  starting month first whatever file came before it (D18): at each order
  tried, a live block built for the same header and that order is validated
  on the file's sampled rows and serves the file (a cache hit) when they
  pass. The signature is
  prefixed `csv:` so it is told apart from a scan order in the cache's listing
  (proposed).
- **The block covers the whole data-line sequence** (the audit's finding on the
  CSV data-line sequence written twice): the split on the separator, the
  timestamp field's trim, the fraction and layout parse (with the memo for ISO,
  without it for epoch: D1 as amended), each named
  metric's raw value read at its compiled position (trimmed, an empty or missing
  field giving no value, as today), the message from the `-ucm` columns or the
  fixed label, the `DATA` category, the reset of the record fields CSV does not
  produce, and the classification call.
- **The shared metric capture keeps what is common to every input.** Transform
  (`delta`, `idelta`), unit conversion, counting and aggregation stay in the
  shared capture block, which reads the values the CSV block extracted, by the
  metric's position in the `-udm` list, with no column-map lookup per row (D10).
  The skip of a row with an unacceptable timestamp comes before it (D8).
- **Instantiation clears the memo and the date cache** (`$format_last_ts_str`,
  `$format_last_ts_epoch`, and the date cache), as an occupant swap does (N3:
  the date cache is keyed by date string alone). A file read day first clears
  them again when it ends, so no day-first reading reaches the next file
  (proposed: at the file's end; the requirement is that nothing leaks).
- **At most one CSV block is alive (D11).** The next file with the same header
  shape is served by the live block (a cache hit); a file with a different shape
  generates a new block and the previous one is deleted from the cache and from
  every reference, so its memory is released. Files alternating between two
  shapes compile once per change of shape; that is the cost D11 accepts.
- **The two inline arms go.** The steady arm and the confirm arm call the block;
  the epoch arm (`$timestamp = int($epoch_val);`) and the ISO arm
  (`} elsif (!$csv_epoch_timestamp && $match_type == 13) {`) are removed, and
  with them `$csv_epoch_timestamp`'s per-line test. The lazy detection D32
  keeps (stash line 1, confirm at line 2) is untouched.

### 5.5 Where a row with an unacceptable timestamp is skipped

Settled by D8: before the metric capture and the per-file match count. The
block runs at the top of the loop, where the parse for scanned lines runs; a
row whose timestamp fails the shape check is not parsed and leaves the loop as
an unmatched line, with no message, as #640 D1 has it on release 0.18.5. No
delta case is handed on: a skipped row sets no baseline.

### 5.6 Validation of an instantiated block

Settled by D9: every CSV block is proven on the file's own rows, sampled from
several parts of the file through the existing detection sample, before it
serves line 2; a failure on a day/month ambiguity retries with the day-first
layout. How:

- **The rows.** The detection sample already reads the front, middle and end
  parts of the file through its own handle, before line 1, and hands its lines
  to the evidence consumers; the whole file when it is no larger than the three
  parts. The sample's own lines are kept until line 2 decides whether the file
  is CSV, then released (proposed). Today only the sample's conclusions are kept
  and its lines are dropped before line 1. Keeping the sample's lines holds no
  production line and replays nothing, so D53's separation from the production
  read is kept; the retained size is at most the three 8 KiB parts. The header
  line and blank lines are not validated.
- **The reading position.** This is how D9's descriptor reset is met: the
  sample reads through its own handle (D53, a read-only look before line 1), so
  the descriptor that moved is the sample's, and the production read stands at
  line 2 with nothing read past it. The sample's handle is closed before line 1.
  The production read is never moved by validation: line 2 is in hand when the
  block is validated, and the read continues at line 3. Nothing is replayed or
  lost; the line accounting of `-V filter-summary` is the observable proof
  (AC6 (c), every line accounted once).
- **What a row must show** (proposed). The block's split of the row carries each
  compiled position's value equal to the value the header's column map names
  for that row (the wiring proof: timestamp, every metric, every message
  column), and the row's timestamp, when it is of the file's kind, gives a real
  date under the block's date order. A row whose timestamp is not of the file's
  kind, or neither epoch nor ISO, is not a failure: it is handled per row by
  D7 and D8.
- **A wiring mismatch** stops the run before line 2 is processed, with the
  registry's codegen diagnostic, as a generated scan sub that fails its samples
  does.
- **A date failure** (an ISO row that is not a real date month first) evicts
  the month-first block, generates the block day first and validates it on the
  same rows, so no more than two compiled subs exist at once (D11). If every row
  passes day first, the day-first block serves the file. If the day-first block
  fails too, it is evicted and the month-first block is generated again and
  serves the file; today's per-row behaviour follows, including the abort on a
  row impossible month first (D7, D15) (proposed: the month-first block is the
  fallback, and its regeneration counts as a compile).
- **A file the sample cannot read** does not occur today: a named pipe is
  rejected at input validation before detection runs (the format-registry
  record's finding on the non-seekable fallback). If it becomes possible, the
  rows come from the fallback D53 names for such input, the held-line window, as
  detection's evidence does (proposed).
- **The file's precision evidence (D17).** `resolve_timestamp_precision`
  runs after the read and resolves the run's precision from each file's sample
  conclusions in `%format_detection_sample` (`formats`, and `frac_digits` per
  entry, which `sample_file_for_detection` counts only for lines a scanned
  entry matched). The validation records the same two conclusions for the
  `csv` entry from the rows it validates: the entry under `formats`, and the
  most fraction digits among the sampled timestamps under `frac_digits`, 0
  when none carries one. The `csv` entry declares no `frac`, so the existing
  generic branch of the resolution reads that count with no change to it
  (proposed). An epoch file's digits are counted after its point, in the unit
  `-du` gives it (proposed: the unit passed to `fraction_precision` follows
  `-du`, seconds without it).
- **State.** Validation runs under the snapshot and restore a mid-run compile
  requires (trap F11 of the lazy scan-sub compilation record): record lexicals,
  memo and date cache are as they were before it ran, and no metric state
  (the `delta` baseline included) is touched, because validation runs the block
  and not the shared capture.

### 5.7 Compile telemetry

Settled by D11: the CSV block goes through the registry's cache (D2) and the
existing counters count it; no new keys.

- `scan_subs_compiled` counts CSV blocks generated, at the codegen boundary; a
  day-first retry counts as a second compile, and a fallback to month first as a
  third (proposed: every generation is counted, so the count reads against the
  codegen the run paid for).
- `scan_sub_cache_hits` counts a CSV confirmation served by the live block.
- `compiled_orders` lists the cache's signatures, so it shows the live CSV
  shape's signature beside the scan orders; an evicted shape leaves the list
  (proposed: the contract sentence is restated from "every compiled order" to
  "every signature in the cache").
- `scan_subs_rss_bytes` includes the CSV block's compile-boundary delta.

The invariants the registry contract and harness state are restated to include
the CSV block: a single-format scanned file compiles at most two subs
(unchanged); a run pinned with `-lf` to a scanned format compiles exactly one
(unchanged); a run pinned to `csv` compiles its scan sub plus one CSV block; a
second CSV file with the same header shape adds one cache hit and no compile; a
second CSV file with a different header shape adds one compile, and the cache
holds one CSV signature.

The compile time joins the `TIMING detect/scan_sub_compile` accumulator (the
compile-cost row, D64). The `benchmark-data` section's `COUNTS
format_scan_subs_compiled` and `COUNTS format_scan_sub_cache_hits` re-emit the
same variables, so those rows move on CSV runs; the move is attributed in this
issue's completion comment only. The inventory line `entry: csv ... role=stateful`
keeps its value; the contract's sentence that the `csv` entry "is neither
scanned nor compiled" becomes "is not scanned; it is compiled per header shape,
one block alive at a time".

### 5.8 What goes (D4: the uncalled closures go)

- `compile_format_time_parser` and its per-entry construction in
  `build_format_registry`.
- The `FR_TIME_PARSE` slot. The later slot constants are renumbered (proposed;
  they are file-scope constants read only inside `ltl`). #608 (the byte ladder)
  adds a byte-notation slot and names it explicitly; whichever of the two lands
  second rebases the constants.
- The emitter's comment "as compile_format_time_parser" and the closure's
  comment block.
- `%format_month_map` stays; the emitted Apache parse reads it.
- The shared capture's per-row column lookup for CSV (D10).

### 5.9 User surfaces

- **`--help` and `docs/usage.md`, the `-ucs` and `-ucm` rows (D14).** Proposed
  wording, plain words, no internals: `-ucs` "Set the CSV field delimiter,
  overriding the one detected from the header (comma, semicolon or tab)"; `-ucm`
  "Name the CSV header columns whose values form the message (default: a fixed
  label)". Same commit for both surfaces; `tests/validate-help-content.sh`
  confirms they agree.
- **A CSV file whose sampled dates are real only day first reads instead of
  aborting (D9, D15).** A user-visible change (D15): stated in
  `features/user-defined-metrics.md` § CSV Columnar Input, in one sentence
  beside the CSV rows of `docs/usage.md`, and in a release-notes line (§ 10).
  The sentence's wording is proposed: a CSV file's dates are read year, month,
  day, or year, day, month when the file's own rows read as real dates only that
  way.
- **A CSV timestamp is read at the run's precision (D16).** Expected from the
  code, not yet measured; the prototype's precision matrix (§ 8) measures it:

  | Run's precision | CSV ISO, up to six fraction digits | CSV ISO, seven to nine digits | CSV epoch with a fraction |
  |---|---|---|---|
  | minute or second, no sub-second width or bound, no `-o` (gate closed) | same output; the fraction is no longer read | same | same |
  | `ms`, `us`, or the gate opened by a width, a bound or `-o` | same | digits seven to nine now count, so a microsecond label, a sub-second bucket edge or the export's population duration can differ in its last place | same |
  | `ns` | same | digits seven to nine shown, where today they read as zeros after the sixth | the digits are taken as written, where today they come from the floating value (about 238 ns resolution) |

  The second and third columns are user-visible changes at `us` and `ns`.
- **A CSV file is a source of its file's precision (D17).** Today a CSV file
  carries no precision evidence, so a run over CSV input alone never gives way
  to what its timestamps carry: `-tp ns` on a CSV whose timestamps carry three
  fraction digits prints nanosecond labels padded with six zeros, with no
  notice. After, that run is shown to the millisecond with the notice a
  scanned log gets. Beside other files, a CSV counts as one processed file
  under rule 4 of the pattern: it never lowers a run that another file
  carries finer. A user-visible change.
- **Telemetry.** The compile counts of § 5.7, and the `TIMING
  detect/scan_sub_compile` row on CSV runs, which now includes one small compile
  per header shape.
- Unchanged: every other option, notice, CSV cell and rendered string. The
  per-row and per-file CSV timestamp warnings are gone, as #640 D1 removes
  them on release 0.18.5 (D8).

### 5.10 The pattern entries

`docs/architecture-patterns.md` is edited only at this issue's own tokens in
lines other issues share.

- *Declarative format registry compiled into generated, cached scan subs*: the
  `FR_TIME_PARSE` consumption site goes; the CSV instantiation site is added;
  the status line's refinement on the two parse texts closes (its "#615" clause
  removed, the cache-bypass clause for #620 (the hoisting remedy, which carries
  the cache-bypass telemetry) kept). The entry gains a paragraph
  on the template variant: an entry whose field positions come from the input,
  instantiated per input shape through the same emitter and cache, validated on
  the input's own sampled rows, one instance alive at a time. A separate pattern
  entry waits for the second consumer (#387, user-declared formats).
- *One resolution surface per vocabulary*: #615 is dropped from the status
  line's list of refining issues when it lands.
- *Generated code compiled from source strings*: the per-file CSV block is a
  fourth instance; its consumption site is added.

---

## 6. Acceptance criteria

Each is a condition and an observable outcome, triaged. Where a lock names a
mechanism to reuse, the criterion names it.

- [ ] **AC1. Same output for a month-first or epoch CSV.** An ISO CSV (with and
      without a fraction, with the space and the `T` separator), an epoch CSV
      (whole and fractional seconds), an epoch CSV read with `-du ms`, a CSV
      with two `-udm` columns and one `-udm` name the header does not carry, and
      a CSV read with `-ucm` give the same bucket timestamps and metric values,
      the same `-V filter-summary` line accounting and the same `-V
      format-detection` per-file counts as before, with stderr clean of runtime
      warnings, except where the run's precision now reads digits the inline
      arms dropped (D16, § 5.9): an ISO CSV with seven to nine fraction digits
      at `us` or `ns` or under an open read gate, and a fractional epoch CSV at
      `ns`, give the values the emitter's capture rules produce, derived by hand
      from the fixture text. **Assertable**: new
      scenarios in `tests/validate-csv-input.sh`, fixtures generated inline,
      each run `-ni -bs 1 -o`; the expected bucket rows derived by hand from the
      fixture values, not captured from a run; the runtime-warning check
      (`tests/lib/runtime-warnings.sh`) in every scenario.
- [ ] **AC2. The bad-row behaviour holds** (D7, D8, D15). A row whose
      timestamp is neither epoch nor ISO is read and not matched, prints
      nothing, is absent from `matched_lines`, and leaves the next row's
      `delta` reading from the previous placed row (165 on the four-row
      fixture of § 3 item 4); a February 30 row aborts the run; a month-13 row outside
      the sample of a file whose sampled rows settled month first aborts the
      run, being impossible under the order the file is read with (D15); an
      epoch file's text row is handled as today.
      **Assertable**: the skip and its accounting by the scenarios
      `csv-input` in `tests/validate-csv-input.sh` and `csv-unparseable-row` in
      `tests/validate-filter-summary.sh` as #640 leaves them; the rest by comparison,
      not a harness (so #611, the acceptance pattern, can change them without
      rewriting harnesses): the prototype's parity battery, and at delivery the
      same fixtures run on the base commit's `ltl` and the branch's, outputs
      diffed, recorded in the drop.
- [ ] **AC3. One parse text.** The ISO parse, the fractional strip and the epoch
      parse each appear once in `ltl`, inside the emitter;
      `compile_format_time_parser`, `FR_TIME_PARSE`, the two inline CSV arms and
      the shared capture's per-row CSV column lookup are absent. **Assertable**
      at review by `grep -c` of each text in `ltl`, recorded in the delivery
      drop; not a harness (a source-structure check).
- [ ] **AC4. The CSV block comes from the scanned formats' emitter** (D1: the
      block is generated through that emitter). The emitter sub that emits the
      scanned formats' timestamp handling emits the CSV block's, and every
      scanned entry's generated source is byte-identical before and after the
      emitter split. **Assertable** by a one-time dump of each entry's generated
      source on the base commit and on the split commit, diffed, recorded in
      § 9's drop 2.
- [ ] **AC5. The header builds the routine** (D10: column positions compiled in,
      metric values read by the block). The instantiated block's source carries
      the timestamp, metric and message positions as constants, and two CSV
      files with the same columns in a different order compile two blocks and
      give the same metric values. **Assertable**: the ordering pair as a
      scenario in `tests/validate-format-registry.sh` (compile count and
      `compiled_orders`, two-row fixtures generated inline, `-bs 1440 -oe -ni`)
      with the metric values checked in `tests/validate-csv-input.sh`; the
      constants by a one-time dump of one instantiated block, recorded in the
      drop.
- [ ] **AC6. The block is validated on the file's own sampled rows, with the
      day-first retry** (D9, D15). (a) A CSV larger than the three sample
      parts, written year, day, month, whose front rows are all ambiguous (day
      and month both 12 or less) and whose end-part rows carry a day above 12
      is read day first, every row on the date derived by hand: the decision
      came from the sample, not from line 2. (b) A small CSV whose sampled rows
      are real dates only day first (a two-row file dated `2025-13-01`) is read
      day first, where the base commit aborts (D15). (c) On both, `-V
      filter-summary` accounts for every line of the file exactly once: nothing
      replayed, nothing lost. (d) `compiled_orders` shows the day-first
      signature. (e) A month-first CSV read after a day-first CSV with the same
      header is read month first: the live day-first block fails the second
      file's sampled rows, and a month-first block replaces it. (f) A CSV
      whose dates are all ambiguous, read after a day-first CSV with the same
      header, is read month first (D18). **Assertable**:
      scenarios in `tests/validate-csv-input.sh` (a to c, e and f) and
      `tests/validate-format-registry.sh` (d), fixtures generated inline, (a)
      above 24 KiB. A block whose compiled position disagrees with the header's
      column map on a sampled row stops the run before line 2 with the
      registry's codegen diagnostic: **assertable** by an authoring-time
      sabotage proof (`tests/HARNESS-DESIGN.md` § Proving a new assertion can
      fail), recorded here; the gate itself runs on every CSV run.
- [ ] **AC7. At most one CSV block alive; the existing counters count it** (D11,
      and D2's registry cache). A run pinned to `csv` reports `scan_subs_compiled:
      2`; two month-first CSV files of the same header shape report the same
      compile count as one file and two more cache hits (the second file's
      scan order and the CSV block); two of different shapes report one more
      compile and one more cache hit (the scan order), and `compiled_orders`
      lists one CSV signature, the second file's. Two day-first files of the
      same header shape report two more compiles than one (D18). The existing invariant assertions (a single-format file at most
      two, a pinned run exactly one) are restated to say what they count.
      **Assertable**: new scenarios in `tests/validate-format-registry.sh`,
      two-row fixtures generated inline, `-bs 1440 -oe -ni`, the counts read
      from paired runs of one and two files; the release of the evicted block is
      read from the cache listing, not from memory.
- [ ] **AC8. The memo is carried by an ISO CSV block, and not by an epoch CSV
      block** (D1 as amended 2026-10-08). In an ISO CSV, rows repeating a
      timestamp string reuse the previous epoch. **Unassertable as behaviour**:
      the memo is invisible in output by design. Its effect is measured by the
      prototype's several-rows-per-second fixtures (§ 8).
- [ ] **AC9. No regression on scanned formats.** The before/after benchmark on
      `single-day-access-log-standard` shows no metric worse by more than 1%
      across repeated runs, and the registry's startup and per-compile
      validation passes on every harness run. **Assertable**: the completion
      gate's before/after benchmark (`docs/process/workflow.md` § 3).
- [ ] **AC10. The CSV cost per line is reported against the inline arm** (the
      issue's done-when; D3 and D12, the prototype on two families and the named
      benchmark case). For the epoch and ISO families, at one row per second and
      several per second, at 1k to 1M rows, the generated block's cost per row
      is reported with the inline arm's, medians with ranges, and is not worse
      beyond the run-to-run range; the once-per-file cost of generation and
      validation is reported beside it. At delivery the named CSV selection is
      run by name before and after. **Assertable**: the prototype's measurement
      (§ 8) and the named case's before/after comparison.
- [ ] **AC11. The `-ucs` and `-ucm` rows say what the options do** (D14).
      `--help` and `docs/usage.md` agree; a semicolon-separated CSV read with no
      `-ucs` and no `-ucm` is split on semicolons; a CSV read with `-ucs` and no
      `-ucm` is split on the given delimiter; `-ucm` columns form the message.
      **Assertable**: `tests/validate-help-content.sh` for the parity; the three
      behaviours as scenarios in `tests/validate-csv-input.sh`.

- [ ] **AC12. A CSV file is a source of its file's precision** (D17).
      `-tp ns` on an ISO CSV whose timestamps carry three fraction digits
      shows them to the millisecond and prints the notice a scanned log
      prints; `-tp ms` on a whole-second CSV alone shows them to the second;
      `-tp ms` over a millisecond application log and a whole-second CSV shows
      the run to the millisecond with no notice (rule 4, the finest any
      processed file carries); an epoch CSV read with `-du ms` and no fraction
      carries the millisecond. **Assertable**: scenarios in
      `tests/validate-timestamp-precision.sh` beside its `truth/*`
      scenarios, fixtures generated inline, the notice read from stderr and
      the precision from the runtime-config row. The mixed-file case rests on
      the several-files rule of #525's amended D4, merged 2026-10-08 (PR #691).

Triage: eleven assertable, one unassertable (AC8, output-invisible by design, its
cost measured instead), none unknown. The prototype is a cost prototype
(`prototype/README.md`'s case of a new code path in the hot path), not a
verification-method prototype.

---

## 7. Verification surface

**`-V` sections read.** `filter-summary` (line accounting), `format-detection`
(per-file `matched_lines`, `scan_attempts`, `format:`), `format-registry`
(inventory and compile state), `udm-specs` (each metric's source column,
unchanged), `benchmark-data` (`TIMING parse/read_files`, `TIMING
detect/scan_sub_compile`, `COUNTS`).

**`-V` section changed: `format-registry`** (D11). No key is added or renamed;
what `scan_subs_compiled`, `scan_sub_cache_hits`, `scan_subs_rss_bytes` and
`compiled_orders` count widens to include the CSV block, and the contract
sentence on the `csv` entry is corrected (§ 5.7). Owning contract:
`features/log-format-registry.md` § `-V format-registry` section-contract,
updated in the same commit as the emitter, the harness and
`tests/HARNESS-DESIGN.md` § Reserved section names (its `format-registry`
description gains the CSV block). `benchmark-data`'s `COUNTS
format_scan_subs_compiled` and `COUNTS format_scan_sub_cache_hits` read the same
variables and move on CSV runs; attributed in the completion comment.

**Harnesses.**

| Harness | What moves | Why the contract supports it |
|---|---|---|
| `tests/validate-csv-input.sh` | new scenarios for AC1 (same output for a month-first or epoch CSV), AC5 (the header builds the routine: the metric values), AC6 (validation on sampled rows with the day-first retry: a to c, and e) and AC11 (the `-ucs` and `-ucm` rows say what the options do: the behaviours) | the CSV Columnar Input contract names the values; D9, D14 and D15 are the new contract lines; nothing existing changes |
| `tests/validate-format-registry.sh` | new scenarios for AC5 (the header builds the routine: the compile count), AC6 (d) (the day-first signature listed) and AC7 (one CSV block alive, counted by the existing counters); the `asserts` text of the election invariants and of the inventory assertion that says `csv` is outside the compiled scan restated to include the CSV block | D11 restates the invariants; the keys and the `role=stateful` value are unchanged (`tests/HARNESS-DESIGN.md` § Stability contract) |
| `tests/validate-help-content.sh` | nothing in the harness; it checks the corrected rows agree (AC11, the `-ucs` and `-ucm` rows say what the options do) | the rows change on both surfaces in one commit |
| `tests/validate-timestamp-precision.sh` | new scenarios for AC12 (a CSV file is a source of its file's precision) | D17 brings CSV input under `features/525-timestamp-precision-option.md` D4 as amended 2026-10-08; the notice's wording is unchanged |
| `tests/validate-filter-summary.sh` | nothing | the unparseable-row accounting is as #640 D1 leaves it (D8) |
| `tests/validate-format-detection.sh` | nothing | `format: csv`, `match_type: 13` and `event_ledger: no` are unchanged; CSV rows stay outside `scan_attempts` |

**Fixtures.** Generated inline by the harnesses, following
`tests/validate-csv-input.sh`'s convention (their content is the contract under
test). Any fixture that becomes committed is named `.txt`. Shapes: a two-column
`timestamp,value` CSV per timestamp form; a CSV with two metric columns and the
same columns reordered; a pair of same-shape files and a different-shape file
for the eviction scenarios; a small day-first CSV; a day-first CSV above 24 KiB
whose front rows are ambiguous and whose end rows are not; a day-first and a
month-first CSV with the same header, read in that order; a semicolon CSV.

---

## 8. Measurement obligations

**Before/after benchmark: yes.** The diff touches executable lines of `ltl`, and
the emitter it changes produces the per-line block of every scanned format
(`docs/process/workflow.md` § 3, scope table, first row).
`single-day-access-log-standard` before, on the base commit, and after, on the
commit being merged.

**CSV cost at delivery (D12).** The benchmark runner has no CSV file selection
today. A named selection is added to `tests/baseline/run-benchmark.sh` in no
tier, so it runs when named and never joins a release tier unasked, and is
described in `tests/baseline/README.md` in the boundary-notes section #619 (the
per-run key cut) also adds to; whichever lands second merges the two notes. The
selection names the network-latency epoch CSV with one `-udm` column as its base
option (proposed: the corpus's ISO CSV has 119 rows, too few for a benchmark
case, so the ISO family is measured by the prototype). Its `standard` scenario is
captured before, on the base commit's `ltl`, and after, beside the access-log
case.

**Prototype: yes, as its own stage (D3, D12).**

- **Question.** Does a header-instantiated generated block, emitted by the
  scanned formats' emitter with the memo and with the column positions compiled
  in, cost no more per CSV row than today's inline arms and column-map lookup,
  with identical output; and what does generating and validating it once per
  file cost?
- **Method.** The pattern of the variant-selection prototype (#384, filename
  provenance and variant groups): the driver evaluates `ltl`'s own source up to
  `## MAIN ##` and drives the production subs, so the inline arm is the
  production code path verbatim (its call structure, the closure call, the
  shared capture's column lookup and the arm order included), not a
  re-expression of its logic. Constants are sliced from `ltl`, never restated.
- **Arms.**
  - A: today's inline arms (steady arm, the shared capture's per-row column
    lookup, then the epoch or ISO arm with the closure call).
  - B: the generated block per header shape (D10: timestamp and metric values
    read at compiled positions), with the memo and the skip flag of § 5.5,
    feeding the shared capture.
  - B-no-memo: B without the memo. This arm attributes the memo's cost or
    benefit. It is not a candidate: D1 includes the memo.
  - Per file, not per row: B's generation plus the validation of § 5.6 on the
    sample's rows, with and without the day-first retry.
- **Fixtures, staged 1k → 10k → 100k → 1M rows, generated, neutral content**
  (D12). Two families, each at one row per distinct second (the memo always
  misses) and at several rows per second (it mostly hits), each carrying one
  and three metric columns:
  - an epoch CSV with a six-digit fractional second in the first column, in the
    shape of the network-latency specimen;
  - an ISO CSV in the shape of the system-metrics specimen.

  Both specimens are too small for the upper sizes (119 and 166,912 rows), so
  the fixtures are generated to their row shapes. A day-first ISO fixture and
  the bad-row fixtures of AC2 are added for correctness only. For D16 (a CSV
  timestamp read under the run's capture rules), an ISO fixture whose
  fractions carry seven to nine digits and an epoch fixture with a
  nine-digit fraction are added, also for correctness only.
- **Measures.** The cost of the timestamp and data-line handling per row,
  metric extraction included, with the rest of the loop excluded, and the
  whole-run `TIMING parse/read_files` at 1M. Medians of at least five
  order-balanced rounds, with ranges. At about 10.3 µs per row whole-run
  (§ 5.1), a difference of a tenth of a microsecond is about 1%, inside the
  whole-run range, so the isolated measure is the deciding one.
- **Correctness first.** Per row, the (timestamp, fractional milliseconds,
  epoch) triple and every metric value are identical between A and B on every
  month-first and epoch fixture at every size. Per run, the STATS CSV, `-V
  filter-summary`, `-V format-detection` per-file counts and the index row are
  identical. This is the parity battery that also holds the bad-row behaviours
  of AC2 (the `delta` baseline, the match count, the February 30 abort, a
  month-13 row outside the sample of a file settled month first aborting, the
  epoch text row). On the day-first fixture the arms differ by design (D9,
  D15): A aborts, B reads day first on the dates derived by hand.
- **The precision matrix (D16).** Every fixture runs at `-tp m`, `s`, `ms`,
  `us` and `ns`, and with `-o` at the default precision. The read gate's state
  is read from `CONFIG timestamp_fraction_capture` of `-V benchmark-data`, never
  assumed. Where the gate and precision cannot see a difference (§ 5.9's first
  column, and every column with the gate closed), A and B are identical as
  above. Where they can, the per-row triple differs by design; B's values are
  checked against values derived by hand from the fixture text, and each
  difference is reported by precision, fixture and the surface it reaches
  (bucket label, heading bounds, index row, export).
- **Exit criterion.** Parity holds everywhere it is required and B is at or
  below A within the run-to-run range on every family and density. If B is
  slower on one beyond the range, the findings (attribution included: the memo,
  the sub call, the split, the compiled extraction) go to the architect before
  the design is fixed. A memo that costs on a family is raised as a conflict
  with D1 (which includes the memo), not removed.
- **Record.** Findings and the decision into this document as a section of its
  own. The driver and generator live under `prototype/615-csv-generated-block/`.

---

## 8a. Prototype findings (drop 1, 2026-10-08)

Measured on `release/0.19.0` at 485e533, one machine (Apple M1 Pro, Perl
5.44), with the instruments in `prototype/615-csv-generated-block/` (its
README says how to run them). The fixtures are generated to the two
specimens' row shapes (§ 8) into a scratch directory.

**How the arms were built.** Arm A is the production read loop's own text,
sliced from `read_and_process_logs` by anchor lines: the per-line
declarations, the steady CSV arm, the shared metric capture, the epoch arm,
the category gate and the ISO arm with its closure call. Arm B is the same
loop with the steady arm replaced by a call to the block generated for the
header shape, and the capture's CSV branch replaced by
`$matched_value = $csv_udm_values[$config_idx];`. B's ISO timestamp text is
the timestamp part of `format_entry_block_src`, sliced verbatim and called
as the proposed split (§ 5.3) would call it; the day-first layout takes the
day-first offsets the way `iso_ms_ddmm` does. B's epoch layout is prototype
text written to § 5.3: fraction from the floating value when the gate is
open, digits from the text under nanosecond, the `-du` scaling folded in as
a constant. For the whole-run measures, `patch-ltl.pl` writes a copy of `ltl`
(in scratch, never committed) whose read loop runs B: the block is
instantiated at CSV confirmation, validated on the detection sample's rows
(kept until line 2), and both inline arms are removed.

### Parity (correctness first)

**Per row** (`parity.sh`). The output of A and B is compared row by row:
epoch seconds, fractional milliseconds, the fraction digits under
nanosecond, every metric value, the message, the category and the
classification outcome. Fifteen correctness fixtures of 2,000 rows each
were run at `-tp m`, `s`, `ms`, `us` and `ns` and with `-o`. Every value of
B was also checked against values derived by hand from the fixture text by
a separate calendar routine that shares no code with `ltl`.

- **Identical everywhere identity is required.** With the fraction left out
  of the comparison, A and B agree on every row of every month-first and
  epoch fixture at every precision: the ISO, `T`-separator, semicolon and
  epoch shapes, `-du ms`, one and three metrics, a metric the header does
  not carry, `-ucm`, and the bad-row fixtures. A row whose timestamp is
  text, empty, or of the other kind is unmatched in both arms (63 and 46
  rows), and a `delta` metric's values agree row for row, so a skipped row
  sets no baseline in either arm (D8). B and B-no-memo agree on every row.
- **With the read gate open** (`ms`, `us` and `-o`), the whole row is
  identical on every fixture whose fractions carry up to six digits, ISO
  and epoch alike.
- **Differences, each by design and each equal to the hand-derived value:**

  | Case | A | B |
  |---|---|---|
  | gate closed (`m`, `s`), any fraction | reads the fraction | fraction 0, as every scanned format (D16) |
  | ISO with 7 to 9 fraction digits, gate open | first six digits | up to nine digits: 1,926 of 2,000 rows differ in the fraction |
  | epoch with a fraction, `ns` | digits from the floating value | digits as written in the text |
  | ISO with 7 to 9 digits, `ns` | the digits held are the first six | all nine |

- **Date order and aborts (D7, D9, D15).**
  - *Day-first file* (yyyy-dd-MM; ambiguous dates at the front, days above
    12 in the middle and end parts). Month-first validation fails, B
    re-instantiates day first (2 compiles) and reads all 2,000 rows, each
    equal to the hand-derived day-first value. A aborts at row 669 on
    `Month '12' out of range` (month 13), as today.
  - *A February 30 row inside the end part of the sample.* Validation fails
    month first and day first, and B falls back to month first (3 compiles).
    Both arms abort at the same row.
  - *A month-13 row outside the sample.* Validation passes month first (1
    compile), and both arms abort at the same row (row 502).

**Whole run** (`wholerun.sh parity`; `ltl` against the patched copy, each run
`-bs 1 -o -V`, in its own directory). Nineteen runs: the fixtures above,
three without `-ni` (so the index is written) and four at `-tp ns`.

- The STATS CSV, the MESSAGES CSV, the `-V filter-summary` section and the
  `-V format-detection` section are byte-identical in all nineteen runs.
- Neither arm printed a runtime warning.
- The YAML export and the index row are identical once the wall-clock fields
  are left out (`generated_at`, `total_time`, `max_memory_used`, and the
  index's entry date, read rate, memory and processing time), except in
  these D16 cases:
  - the export's `duration_seconds` for the ISO file with 7 to 9 digits
    (`666.915688037872` in A, `666.915687561035` in B);
  - at `ns`, the export's `start` and `end` and the index row's first and
    last timestamps: digits seven to nine (`06:40:00.063566000` in A,
    `06:40:00.063566800` in B, the fixture's text); epoch digits as written
    (`.916025877` in A from the float, `.916025874` in B, the text).

### Cost per row

`timing.sh`: the arm loop over the rows held in memory, so file reading is
left out. Each figure is the median of five rounds, with the three arms run
in a rotated order each round, in nanoseconds per row (range in brackets).
Below 200k rows a pass repeats the rows until it covers at least 200k.
"Closed" is the default minute precision, "open" is `-tp ms`. Shown at 1M
rows. Across all 64 configurations (four sizes) B's median is below A's by
38 to 845 ns per row.

| Fixture (1M rows) | Metrics | Gate | A | B | B-no-memo | B − A | Memo (B − B-no-memo) |
|---|---|---|---|---|---|---|---|
| epoch, 1 row/s | 1 | closed | 3565 (3541–3584) | 3242 (3236–3359) | 3196 (3193–3206) | −323 (−9.1%) | +46 |
| epoch, 1 row/s | 3 | closed | 5131 (5097–5260) | 4705 (4682–4806) | 4604 (4596–4646) | −426 (−8.3%) | +101 |
| epoch, 1 row/s | 1 | open | 3574 (3536–3612) | 3467 (3454–3479) | 3394 (3384–3414) | −107 (−3.0%) | +73 |
| epoch, 1 row/s | 3 | open | 5122 (5106–5248) | 4869 (4864–4875) | 4799 (4796–4820) | −253 (−4.9%) | +70 |
| epoch, 10 rows/s | 1 | closed | 3531 (3527–3562) | 3195 (3188–3244) | 3193 (3184–4006) | −336 (−9.5%) | +2 |
| epoch, 10 rows/s | 3 | closed | 5126 (5111–5369) | 4630 (4614–4712) | 4606 (4599–4672) | −496 (−9.7%) | +24 |
| epoch, 10 rows/s | 1 | open | 3572 (3560–3704) | 3416 (3393–3435) | 3419 (3372–3456) | −156 (−4.4%) | −3 |
| epoch, 10 rows/s | 3 | open | 5145 (5122–5170) | 4793 (4784–4811) | 4821 (4791–4832) | −352 (−6.8%) | −28 |
| ISO, 1 row/s | 1 | closed | 3779 (3769–3891) | 3404 (3385–3454) | 3373 (3353–3474) | −375 (−9.9%) | +31 |
| ISO, 1 row/s | 3 | closed | 5671 (5653–5758) | 5062 (5041–5238) | 5028 (5019–5316) | −609 (−10.7%) | +34 |
| ISO, 1 row/s | 1 | open | 3817 (3808–3849) | 3397 (3391–3420) | 3366 (3352–3383) | −420 (−11.0%) | +31 |
| ISO, 1 row/s | 3 | open | 5565 (5541–5618) | 5054 (5024–5083) | 5004 (4982–5114) | −511 (−9.2%) | +50 |
| ISO, 10 rows/s | 1 | closed | 3760 (3742–4005) | 3151 (3124–3186) | 3353 (3323–3524) | −609 (−16.2%) | −202 |
| ISO, 10 rows/s | 3 | closed | 5570 (5523–5675) | 4811 (4777–4905) | 5076 (5064–5981) | −759 (−13.6%) | −265 |
| ISO, 10 rows/s | 1 | open | 3790 (3762–3846) | 3145 (3124–3175) | 3346 (3310–3388) | −645 (−17.0%) | −201 |
| ISO, 10 rows/s | 3 | open | 5582 (5572–5595) | 4831 (4814–4836) | 5020 (5001–5042) | −751 (−13.5%) | −189 |

B's median is below A's on every family, density, metric count, gate state
and size. At 1M rows every B range lies below the A range of the same row.
At the smaller sizes four of the 48 configurations overlap:
- the epoch family at one row per second, one metric, gate open, at 1k and
  10k: medians −120 and −38 ns, B's range reaching into A's;
- the ISO family at one row per second, one metric, at 10k: one slow round
  in B each (maxima 7,412 and 4,019 ns, medians −336 and −360 ns).

Where the saving comes from:

- **The removed per-row work.** A passes the row through
  `csv_timestamp_placeable`, a sub call that tests the epoch flag and runs
  the shape regex. Its capture looks up each metric's column through
  `@csv_udm_col_indices` with three bounds tests, and it tests the epoch
  flag twice more. Its ISO arm calls the parse closure, a sub call with
  `my $ts` copied. B tests the shape inline, reads each metric at a
  compiled position, and parses inline. With three metrics B saves 100 to
  250 ns more per row than with one: the capture's per-metric lookup.
- **With the gate open, the epoch saving is smaller** (−107 against −323 ns
  at one row per second). B then computes the fraction and strips it from
  the text for the memo key, which A does not do.
- **The memo.** On ISO at ten rows per second it saves 189 to 265 ns per
  row: one string compare replaces the date-cache lookup and the
  time-of-day arithmetic. On ISO at one row per second it misses on every
  row and costs 31 to 50 ns (about 1% of B). On epoch at one row per second
  it costs 46 to 101 ns (1.3 to 2.1% of B). On epoch at ten rows per second
  it is between −28 and +24 ns, inside the range. On epoch it cannot pay at
  any density: on a hit it saves only the numeric conversion of the
  whole-second text, which costs no more than the string compare it
  replaces, and on a miss it adds the compare and two stores.

### Whole run

`wholerun.sh timing`: `TIMING parse/read_files` of `-V benchmark-data`,
one metric, `-bs 1440 -oe -n 1 -ni`, five runs per arm with alternating
order, in seconds.

| Input | A | B | B − A |
|---|---|---|---|
| epoch, 1 row/s, 1M rows | 10.819 (10.750–11.030) | 10.403 (10.304–10.411) | −0.416 (−3.8%) |
| epoch, 10 rows/s, 1M rows | 10.764 (10.674–10.849) | 10.268 (10.153–10.315) | −0.496 (−4.6%) |
| ISO, 1 row/s, 1M rows | 11.237 (11.180–11.261) | 10.691 (10.538–10.747) | −0.546 (−4.9%) |
| ISO, 10 rows/s, 1M rows | 11.148 (11.094–11.392) | 10.282 (10.198–11.191) | −0.866 (−7.8%) |
| network-latency CSV (corpus, 166,912 rows) | 1.798 (1.783–1.810) | 1.691 (1.683–1.700) | −0.107 (−6.0%) |

The whole-run savings agree with the per-row ones (for example, −323 ns per
row on the epoch family at one row per second, against −416 ms over a
million rows). On the network-latency CSV A's median, 1.798 s, matches
§ 5.1's re-measure of 1.812 s.

### Per file

`csv-block.pl --mode perfile`, median of 21 runs (range), in microseconds.
"Instantiate" covers generating and compiling the block, then validating
it on the sample's rows under the snapshot and restore, with any day-first
retry.

| File | Metrics | Sample rows | Outcome | Compiles | Generate + compile | Instantiate |
|---|---|---|---|---|---|---|
| epoch | 1 | 394 | validated | 1 | 159 (155–289) | 1,470 (1,453–1,569) |
| epoch | 3 | 394 | validated | 1 | 215 (212–296) | 2,044 (2,030–2,227) |
| ISO | 1 | 361 | month first | 1 | 216 (211–304) | 1,445 (1,433–1,505) |
| ISO | 3 | 361 | month first | 1 | 270 (268–360) | 2,049 (2,038–2,129) |
| ISO, day-first | 1 | 362 | day first after retry | 2 | 213 (211–319) | 2,115 (2,092–2,232) |
| ISO, February 30 in the sample | 1 | 362 | month first after both fail | 3 | 213 (211–312) | 2,719 (2,699–2,873) |

That is 1.4 to 2.7 ms per CSV file, paid once: 0.1% of the network-latency
CSV's 1.69 s read. Validation is most of it, about 3.4 µs per sampled row
for one metric; how that splits between the snapshot and restore, the block
call and the wiring check was not measured.

### Exit criterion

Met. Parity holds everywhere it is required, row by row and run by run, and
B is at or below A on every family and density: below beyond the run-to-run
range at 1M rows and in the whole run, and within it in the four small-size
configurations named above. One
finding remains before the design is fixed: a memo that costs on a family
is a conflict with D1 (which includes the memo), and the memo costs on two
families:
- on epoch at one row per second: 46 to 101 ns, 1.3 to 2.1% of B;
- on ISO at one row per second: 31 to 50 ns, about 1%.

B remains 3 to 11% below A on both with the memo in.

**Decision (2026-10-08).** The architect amended D1: an epoch CSV block
carries no memo, and an ISO CSV block keeps the emitter's memo as the scanned
formats have it. On the families measured, that takes the epoch figures to
the B-no-memo column above and leaves the ISO figures as B.

---

## 9. Delivery

Each drop is a commit and a push on the issue branch. One PR at the end.

| Drop | Content | What it proves |
|---|---|---|
| 0 | this specification, agreed with the architect; the issue comments and native edge of § 10's first table | the design and criteria are the architect's |
| 1 | the prototype (§ 8), findings and the architect's decisions recorded here; no `ltl` change | the generated block's cost and parity, before the design is fixed (D3) |
| 2 | the named CSV selection added to the benchmark runner, and both before captures taken on the base commit's `ltl`; then the emitter split (§ 5.3), scanned formats' generated source byte-identical | AC4 (scanned entries' generated source byte-identical across the split); no scanned-format behaviour changes |
| 3 | the CSV template, header-built block, validation on sampled rows with the day-first retry, one-block eviction and counters; the two inline arms and the shared capture's CSV lookup replaced; the `-V format-registry` contract, harness scenarios and reserved-names entry in the same commit | AC1 (same output for a month-first or epoch CSV), AC2 (today's bad-row behaviour), AC5 (the header builds the routine), AC6 (validation on sampled rows with the day-first retry), AC7 (one CSV block alive, counted by the existing counters), AC12 (a CSV file is a source of its file's precision) |
| 4 | the `-ucs` and `-ucm` rows in `--help` and `docs/usage.md` (D14), with their behaviour scenarios | AC11 (the `-ucs` and `-ucm` rows say what the options do) |
| 5 | the closures, the `FR_TIME_PARSE` slot and its renumbering (D4); records trued up (§ 10) | AC3 (one parse text) |

**Drop 2, as delivered (2026-10-08).**

- **Named CSV selection.** `network-latency-csv` was added to
  `tests/baseline/run-benchmark.sh` in a tier of its own, `named`, which
  `quick`, `full`, `xl` and `all` never run. Its base option is
  `-udm latency_ms`, and `tests/baseline/README.md` says so in its tier table
  and boundary notes.
- **Before captures.** Both were taken in this branch's worktree on `ltl` at
  the base commit (485e533, version `0.19.0`), before any change to `ltl`,
  into `tests/baseline/results/615-before.tsv`:
  `single-day-access-log-standard`, and `network-latency-csv-standard`
  (`TIMING parse/read_files` 1.888 s, peak memory 43.2 MB).
- **Emitter split (AC4, the byte-identical part).** The timestamp part of
  `format_entry_block_src` (the fraction under the read gate, then the memo
  fronting the layout parse) is now its own sub, `format_timestamp_src`, which
  `format_entry_block_src` calls. `prototype/615-csv-generated-block/dump-entry-src.pl`
  dumps every scanned entry's generated source as `format_entry_block_src`
  returns it: 30 entries under four compile-option combinations (gate closed,
  gate open, nanosecond, and gate open with the query string kept), 120
  sources. The dump on the base commit's `ltl` and on the split's are
  byte-identical (SHA-256 `9901d453…fa330e7` for both). The other half of
  AC4, the CSV block coming from the same sub, is drop 3's.

**Drop 3, as delivered (2026-10-08).**

- **The block.** `csv_block_shape` records a header's shape: layout,
  separator, timestamp column, each `-udm` metric's column (-1 where the
  header has none) and the `-ucm` columns. `csv_block_src` generates the
  block's source from that shape, with its timestamp text from
  `format_timestamp_src` (AC4's second half). `format_timestamp_src` gains
  two layouts:
  - `csv_ddmm`: the `csv` layout read day first, with the day-first offsets
    and the unguarded parse (D7).
  - `csv_epoch`: no memo (D1 as amended). Its `-du` scale is folded in as a
    constant, and its fraction follows the read gate: digits as written
    under `-tp ns` (none when `-du` scales the value), from the number when
    the gate is open, none when it is closed.
  - Every scanned entry's generated source is still byte-identical to the
    base commit's: the dump of § 9's drop 2, re-run on this drop, has
    SHA-256 `9901d453…`, unchanged.
- **The constants (AC5).** `prototype/615-csv-generated-block/dump-csv-block.pl`
  dumps the block for one header. For `size,host,timestamp,latency` read
  with `-udm latency -udm size::sum -udm absent -ucm host`, it prints the
  signature `csv:csv:sep=comma:ts=2:udm=3/0/-1:msg=1`, and the source:
  - reads `$f[2]` for the timestamp;
  - reads `$f[3]` and `$f[0]` for the two metrics, and sets the third,
    which the header does not carry, to no value;
  - takes `$f[1]` for the message.
- **The validation (D9, D15).**
  - **Rows.** A run with `-udm` keeps the detection sample's lines for CSV
    confirmation at line 2. The rows validated are those lines less the
    header and blank lines. A CSV file releases them at line 2; a file that
    is not CSV holds them, at most the three 8 KiB parts, until it ends,
    since releasing them sooner would add a test to every line.
  - **Wiring.** A placed row must give, at each compiled position, the
    value the header's column map names: the timestamp to the second, each
    metric, the message.
  - **Date order.** A parse that croaks is a date failure, answered with
    the other order. When both orders fail, the month-first block is
    generated again and serves the file.
  - **A wiring failure** stops the run before line 2, with `ltl: format
    registry: the CSV block for <file> reads a sampled row's values from
    other columns than its header names (produced_by csv_block_src())`.
  - **State.** Validation runs under the snapshot and restore of a mid-run
    compile.
  - The § 5.6 elements marked proposed are implemented as written there.
- **One block alive (D11).** The block is the one `csv:` signature in
  `%format_scan_sub_cache`; generating another deletes it. It counts in:
  - `scan_subs_compiled`, at every generation;
  - `scan_sub_cache_hits`, when the live block passes a same-shape file's
    rows;
  - `scan_subs_rss_bytes`;
  - `TIMING detect/scan_sub_compile`, its validation inside the timer, as a
    scan sub's is.
  - The memo and the date cache are cleared at each CSV confirmation, and
    again when a file read day first ends.
- **The read loop.** Both inline arms call the block. Removed with them:
  - the epoch arm and the ISO arm;
  - `csv_timestamp_placeable`, `$csv_epoch_timestamp` and the per-line
    `my @csv_fields`;
  - the shared capture's per-metric column lookup: the capture now reads
    `$csv_udm_values[$config_idx]`.

  The file's kind (epoch or ISO) is read once, from line 2, in
  `csv_block_for_file`.
- **Precision evidence (D17).** `csv_block_for_file` records the `csv`
  entry in the file's detection sample: the rows placed under `formats`,
  the most fraction digits under `frac_digits`, and an epoch file's `-du`
  unit under `frac_unit`. `resolve_timestamp_precision` passes that unit to
  `fraction_precision`, seconds without it. The `-V format-detection`
  listing `sample_formats` names scanned entries only, so it is unchanged.
- **Same output (AC1, AC2).** `wholerun.sh parity` was run with `LTL_A`
  set to the base commit's `ltl` (485e533) and `LTL_B` to this drop's: the
  nineteen runs of § 8a. The STATS CSV, the MESSAGES CSV, `-V
  filter-summary` and `-V format-detection` are identical, except for one
  STATS file: the fractional epoch fixture at `-tp ns`. There the labels
  are now shown to the microsecond, with the precision notice, because the
  file's six digits now bound the run (D17). The YAML export differs in its
  version line; at `-tp ns`, the export and the index row differ in the
  D16 cases § 8a lists, with the same values.
- **The date-order fixtures.**
  - The day-first file reads all 2,000 rows (3 compiles); the base aborts
    at row 669.
  - A February 30 row in the sample, and a month-13 row outside it, abort
    on both commits. The abort message now names the generated block
    (`at (eval N) line 14.`) where the base named an `ltl` line.
  - An unplaceable line 2, an epoch file with text and ISO rows, and a run
    under `--detection-window=3` give the same `-V filter-summary`
    accounting on both commits.
- **Harnesses.**
  - `tests/validate-csv-input.sh`: eight scenarios, 13 assertions, the
    expected values derived by hand from the fixtures:
    - `block-iso`, `block-epoch`, `block-message-columns`: AC1;
    - `block-fraction-digits`: D16;
    - `block-column-order`: AC5;
    - `day-first-sampled`: AC6 (a) and (c), on a 30,812-byte file;
    - `day-first-small`: AC6 (b) and (c);
    - `day-first-then-month-first`: AC6 (e).
  - `tests/validate-format-registry.sh`: four scenarios, nine assertions:
    - `csv-pinned`, `csv-same-shape`, `csv-different-shape`: AC5 and AC7;
    - `csv-day-first`: AC6 (d).

    The `asserts` text of the `csv` inventory line and of the election
    invariants is restated.
  - `tests/validate-timestamp-precision.sh`:
    - `truth/csv-file`: AC12, eight assertions;
    - `truth/unknown-precision`: its label restated, since its CSV is read
      without `-udm` and so is not read as CSV;
    - `capture/generator`: re-pointed at `format_timestamp_src`. Drop 2's
      split broke it: it sliced `format_entry_block_src`, which no longer
      holds the fraction text, and drop 2 ran no harness.
  - `produced_by` fields naming the removed `csv_timestamp_placeable` are
    corrected in `tests/validate-csv-input.sh` and
    `tests/validate-filter-summary.sh`.
- **Sabotage proofs** (`tests/HARNESS-DESIGN.md` § Proving a new assertion
  can fail):
  - **The base commit's `ltl`** fails every assertion of new behaviour: the
    day-first scenarios, the nine digits, the CSV precision, the compile
    counts. It passes the same-output ones.
  - **A copy whose block reads each metric one column to the right** stops
    before line 2 with the wiring diagnostic.
  - **The same copy with that stop removed** fails `block-iso`'s value
    assertion.
  - **A copy whose block reads the timestamp one column to the right**
    stops with the wiring diagnostic.
- **Harnesses run on this drop:** `csv-input` 28, `format-registry` 56,
  `timestamp-precision` 94, `filter-summary` 87, `udm-specs` 244,
  `section-layout` 176, `format-detection` 453, `verbose-content-shape` 1
  and `scenario-selector` 26 assertions, all passing.
- **Correction to AC7** (agreed by the architect 2026-10-08). "Two CSV
  files of the same header shape report the same compile count as one file
  and one more cache hit" reads two more cache hits as measured: the second
  file's scan order, resolved again before its first line, is a hit of its
  own. Two files of different shapes add one, the scan order. AC7 is
  restated to match.
- **D18 applied after the drop.** As delivered in d0b11d0,
  `csv_block_for_file` validated the block in memory first, in whatever
  date order it had. It now tries month first, then day first, reusing the
  block in memory only for the order being tried.
  `day-first-then-ambiguous` in `tests/validate-csv-input.sh` (AC6 (f)) and
  a second run in `csv-day-first` in `tests/validate-format-registry.sh`
  (two day-first files: `scan_subs_compiled: 5`) assert it; both fail on
  d0b11d0's `ltl` and pass on this one.
- **Contract.** `features/log-format-registry.md` § `-V format-registry`
  section-contract and `tests/HARNESS-DESIGN.md` § Reserved section names
  are restated to count the CSV block (§ 5.7), with the signature's form.

**Drop 4, as delivered (2026-10-08).**

- **The rows (D14).** `print_help()` in `ltl` and `docs/usage.md` carry the
  same two descriptions, the wording proposed in § 5.9:

  | Option | Before | After |
  |---|---|---|
  | `-ucm` | Treat the message field as CSV and name the columns for use with `-udm` | Name the CSV header columns whose values form the message (default: a fixed label) |
  | `-ucs` | Set the CSV field delimiter when using `-ucm` (default: comma) | Set the CSV field delimiter, overriding the one detected from the header (comma, semicolon or tab) |

  `tests/validate-help-content.sh` passes, 94 assertions.
- **The behaviours (AC11).** Two scenarios in `tests/validate-csv-input.sh`,
  with the expected values derived by hand:
  - `separator-detected`: a semicolon-separated and a tab-separated CSV,
    read with no `-ucs` and no `-ucm`, are split on their own delimiter.
  - `separator-option`: a `|`-separated CSV is split on `|` with `-ucs '|'`
    and no `-ucm`; without `-ucs` all three of its lines are unmatched.

  The third behaviour, the `-ucm` columns forming the message, is drop 3's
  `block-message-columns`. The harness passes, 33 assertions.
- **Sabotage proofs.** An `ltl` copy that ignores `-ucs` fails the `-ucs`
  assertion, and a copy that detects only the comma fails both detection
  assertions.
- The day-first sentence beside the CSV rows of `docs/usage.md` (§ 5.9,
  D15) belongs to the records of drop 5.

**Drop 5, as delivered (2026-10-08).**

- **What goes (D4).** `compile_format_time_parser` and its per-entry
  construction in `build_format_registry` are removed, with the
  `FR_TIME_PARSE` slot. The later slot constants move down by one
  (`FR_ANC_SET` 17 to `FR_BYTE_NOTATION` 29); #608 (the byte ladder) had
  already landed its byte-notation slot, so this issue, landing second,
  rebased them. `%format_month_map` stays, read by the emitted Apache and
  asctime parses, with its comment restated.
- **One parse text (AC3)**, by `grep -cF` in `ltl` at this drop:

  | Text | Count | Where |
  |---|---|---|
  | `timegm( 0, 0, 0, substr(\$timestamp_str, $day_off, 2)` (the ISO parse) | 1 | `format_timestamp_src` |
  | `[.,](\d{1,9})/$1/` (the fractional strip) | 2 | `format_timestamp_src`, its nanosecond and open-gate variants |
  | `int($timestamp_str)` and `int($epoch_val)` (the epoch parse) | 1 each | `format_timestamp_src`, without and with `-du` |
  | `compile_format_time_parser`, `FR_TIME_PARSE`, `csv_epoch_timestamp`, `csv_timestamp_placeable`, `csv_udm_col_indices[$config_idx]`, `my @csv_fields` | 0 | |

  Other `timegm(` sites remain outside this issue's scope:
  - `format_sample_probes`, which reads sampled dates under both orders for
    variant selection;
  - `iso_timestamp_parts` and `calculate_start_end_filter_timestamps`, the
    `-st`/`-et` parser with its own six-digit strip. § 2 places that parser
    with #611 (the timestamp acceptance pattern).
- **Records (§ 10).**
  - `features/log-format-registry.md`: D31 annotated (its closure form
    retired), D32 annotated (CSV data lines read by the generated block),
    N10 naming `format_timestamp_src` and the day-first CSV layout.
  - `features/58-format-registry-staged-detection.md`: D31 and D32 annotated
    the same way; P9's "split-based extraction closure" annotated as built.
  - `features/user-defined-metrics.md` § CSV Columnar Input: the block, the
    `-ucs`/`-ucm` wording, the date order (D9, D15, D18), the capture rules
    and precision (D16, D17).
  - `docs/architecture-patterns.md`, at this issue's tokens:
    - *Declarative format registry*: the closure site removed, the CSV
      site and the template paragraph added, and the parse-text refinement
      closed (the cache-bypass refinement, #620, kept).
    - *Generated code compiled from source strings*: the CSV block as its
      fourth instance.
    - *One resolution surface per vocabulary*: #615 dropped from the status
      line.
    - *Timestamp precision*: the CSV refinement closed and the CSV sites
      added.
    - The read-gate snippet's sub is corrected to `format_timestamp_src` in
      two entries, since drop 2 moved it.
  - `docs/usage.md`: the day-first sentence beside the CSV rows (§ 5.9, D15).
  - The audit report's review-progress line, the release notes and the
    completion comment come with the merge.
- **Prototype instruments.** `csv-block.pl` and `patch-ltl.pl` slice the
  inline arms, which no longer exist on the branch; the prototype README
  says they run against 485e533.

**Completion gate (2026-10-08), on 08ac4e4, `$version_number` 0.19.0.**

- **After benchmark, first.** Both cases, run in this worktree against the
  `before` captures of drop 2:

  | Case | Metric | Before | After | Change |
  |---|---|---|---|---|
  | `network-latency-csv-standard` | `TIMING/total` | 1.9 s | 1.8 s | −155 ms (−8.1%) |
  | `network-latency-csv-standard` | `MEMORY/rss_peak` | 41.2 MB | 41.5 MB | +240 KB (0.6%) |
  | `single-day-access-log-standard` | `TIMING/total` | 8.9 s | 9.1 s | +153 ms (+1.7%), one run |

  The access-log case's single run was above the 1% threshold, so it was
  run five more times, interleaved and order-balanced. The base commit's
  `ltl` was run from the `release/0.19.0` worktree beside this one; that
  worktree's `ltl` is identical to 485e533.

  | `single-day-access-log-standard` | Base, median (range) | Branch, median (range) |
  |---|---|---|
  | `parse/read_files` | 8.722 s (8.416–8.874) | 8.636 s (8.440–8.851) |
  | `total` | 8.826 s (8.514–8.974) | 8.742 s (8.538–8.955) |

  No regression: the branch's median is 1.0% below the base's, and the
  ranges overlap. The +1.7% was one run's variation. This agrees with
  scanned formats' generated source being byte-identical (drop 2, rechecked
  in drop 3).
- **Full harness suite, after.** `CI=1 validate-csv-output.sh` (42 pass),
  then `CI=1 validate-statistics.sh` (25 of 25 scenarios), then the other 47
  `tests/validate-*.sh`. All 49 exit 0, each with its assertions run and
  none failing.
- `tests/validate-help-content.sh` passes, 94 assertions.

**Merge gate.** The full harness suite, `CI=1 ./tests/validate-csv-output.sh`
then `CI=1 ./tests/validate-statistics.sh` then the rest, on the commit being
merged; the before/after benchmark on `single-day-access-log-standard` and on the
named CSV case; `tests/validate-help-content.sh`; `$version_number` stamped
`0.19.0-615` during the work and restored to `0.19.0` before the gate.

---

## 10. Records to update

**With this specification's delivery (drop 0).**

| Record | Update |
|---|---|
| #386 (per-format analysis precision) | native edge: blocked by this issue (D13) |
| #611 (the timestamp acceptance pattern) | a comment pointing here: a row whose timestamp is unacceptable is not matched and prints nothing (D8, #640 D1); a CSV file's date order is settled once per file from its sampled rows with a day-first retry, before any row is read (D9, D15), and a row impossible under that order keeps today's abort (D7) until it lands its pattern; its inverted-layout design builds on this |
| #608 (the byte ladder) | a comment: this issue removes the time-parse closure slot and renumbers the later slot constants, #608 adds a byte-notation slot; whichever lands second rebases the constants |
| #619 (the per-run key cut) | a comment: both issues add to one boundary-notes section of `tests/baseline/README.md` (this issue the named CSV selection, #619 its boundary note); whichever lands second merges. #619 moves a CONFIG line of `-V benchmark-data` on `-o` and `-g` runs; this issue moves the compile-count COUNTS rows on CSV runs |
| #615 | a comment pointing here: specification agreed; the nine decisions of 2026-09-28 (D7 to D15) recorded |

**At implementation delivery.**

| Record | Update |
|---|---|
| `features/log-format-registry.md` | D31 (the time contract compiled to per-layout closures) annotated: its closure form is retired by this issue's D4 (the uncalled closures go), the parse living in the emitted source; D32 (CSV stays a per-file stage outside the scan array) unchanged, with a line that its data-line handling is now a per-file generated block built from the header, validated on the sampled rows, one alive at a time; the `-V format-registry` section-contract (§ 5.7: what the counts include, the restated invariants, the `csv` entry sentence); N10 (the day-first ISO layout) no longer names `compile_format_time_parser`, and names the day-first CSV layout beside it |
| `features/58-format-registry-staged-detection.md` | D31 (per-layout parse closures) cross-referenced as above; P9's description of the `csv` entry ("split-based extraction closure") checked against the block |
| `features/user-defined-metrics.md` § CSV Columnar Input | CSV rows are parsed by the block generated from the header, which reads each metric's value at its column; a file whose dates read as real only day first is read day first; the skip-and-warn wording stays |
| `docs/architecture-patterns.md` | only this issue's tokens in shared lines (§ 5.10): *Declarative format registry*, the time-parse closure site removed, the CSV site and template paragraph added, the parse-text refinement closed; *One resolution surface per vocabulary*, #615 dropped from the status line's list; *Generated code compiled from source strings*, the fourth instance; *Timestamp precision*, the CSV refinement closed and the CSV block added as a consumption site (D16, D17) |
| `tests/HARNESS-DESIGN.md` § Reserved section names | the `format-registry` description gains the CSV block |
| `tests/baseline/run-benchmark.sh`, `tests/baseline/README.md` | the named CSV selection and its note in the shared boundary-notes section (D12) |
| `docs/usage.md`, `--help` | the `-ucs` and `-ucm` rows (D14); the day-first sentence beside the CSV rows (§ 5.9, D15) |
| `features/342-redundant-logic-surfaces-audit-report.md` § Review progress | stage 5 to *done* when this issue closes; its stale order column is corrected here (§ 3 item 6), not in the report |
| #615 completion comment | the COUNTS rows of `-V benchmark-data` that move on CSV runs (compile count and cache hits), attributed to D11 |
| Release notes | one bullet for the day-first CSV reading, required by D15 (wording proposed: "Read a CSV file's dates day first when its own rows are real dates only that way; see `docs/usage.md`"); none for the help rows, which describe behaviour the options already had, or for the telemetry |
