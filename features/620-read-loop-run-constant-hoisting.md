# Hoisting the read loop's run-constant tests (Issue #620)

## Status

Implemented 2026-10-11 on `620-read-loop-run-constant-hoisting` (§ 10); code
audited for planning at `release/0.19.0` e172dbd. Parent: #622 (the refactoring the redundant-logic-surfaces
audit dispatched). Follow-up: #621 (a switchable generated loop body, not
planned), blocked by this issue.

## 1. The motivating consumer

Every run of `ltl`. The read loop (`read_and_process_logs` :: `while (1) {`)
pays for every test it carries on every line, whether or not the test can ever
change its answer during the run. The audit measured the cost at about 23 ns per
line for a boolean test and 30 to 36 ns for a string compare or hash lookup, the
same on three log families (`features/342-redundant-logic-surfaces-audit-report.md`
§ Item 8, part 2). The patterns that govern the loop
(`docs/architecture-patterns.md` § Demand gates, § Run-scoped activation flags
resolved once, § Hot-loop discipline, § Data-model selectors resolved once per
surface, § Statistics-group consumer registry) each carry a *needs refinement*
status that names this issue; this issue is what closes them.

## 2. Requirement

The read loop stops asking, on every line, questions whose answers are fixed
for the run. Each run-constant condition becomes a boolean resolved once at
option settlement and tested once per line, in the shape the demand-gate
pattern already takes, and capture that has no consumer in the run does not
happen. Each step is a small change proven behaviour-neutral and measured on
its own.

## 3. Corrections to the issue body and the audit record

The issue was written against the tree of 2026-09-27; #605, #616, #619, #525,
#615, #611 and #704 have changed the loop since. Audited at e172dbd:

- **Step 3 (run constants computed per line) has nothing left to move.** The
  millisecond bucket size (`my $bucket_size_ms = int($bucket_size_seconds * 1000 + 0.5);`)
  is gone: the bucket key reads `$bucket_key_scale` and `$bucket_size_ticks`,
  settled once (#525 D14). The re-declared literal `my $max_object_length = 25;`
  is gone (the key's field cuts are the named constants
  `MESSAGE_KEY_THREAD_LENGTH` and `MESSAGE_KEY_OBJECT_LENGTH`). The key length
  is cut once per run (#619). No other assignment in the loop computes a
  value from run constants alone.
- **The string-compare gates (step 1) number twelve, not fifteen.** Five on the
  message-stats mode, three on the bucket-stats mode, one each on the heatmap
  and histogram modes, as the hoist probe found; the grouping sensitivity is
  compared at two loop sites now (`if ($group_similar_sensitivity ne "none") {`
  and `consolidation_fire_checkpoints($category) if $group_similar_sensitivity ne "none";`),
  not five. A third copy after the loop (`# EOF checkpoints`) runs once per
  run and is out of scope.
- **The latency column's predicate (FP.1) has changed but is still written
  three times.** The heatmap term left it; the three copies now read
  `!$hide_stats`: the registry's `timeline-latency-column` entry
  (`active => sub { !$hide_stats },`), the demand block
  (`!$hide_stats                          # timeline latency-statistics column`)
  and `build_column_layout` (`my $show_latency = $durations_observed && !$omit_durations && !$hide_stats;`).
- **The data-model defaults (F1.14) are at fourteen sites, as recorded**: the
  four capture-mode assignments at loop entry, four in
  `emit_percentile_algorithm_verbose`, one in `emit_statistics_demand_verbose`,
  one each in `calculate_heatmap_buckets` and `calculate_histogram_buckets`,
  three in `calculate_all_statistics`. `choose_data_model` is a pass-through to
  `resolve_data_model` and does nothing else.
- **The cache bypass (F8.1) is unchanged**: `format_registry_set_occupant` ::
  `$format_scan_sub = $format_scan_sub_cache{$sig} //= compile_format_scan_sub($format_registry_opts);`.
  `scan_sub_cache_hits` is read by `tests/validate-format-registry.sh` and is
  in every benchmark TSV.
- **The detection record's key list (F8.4) is still written three times**:
  `grep -F 'first_match_line => undef,'` finds the emitter, the loop's
  first-match site and the per-file block after the loop.
- **The consumers of session, user and index capture (F8.9)**, enumerated from
  the code:

  | Store | Written in the loop by | Read by | Read when |
  |---|---|---|---|
  | `%log_sessions` | `## CAPTURE SESSION BASED STATISTICS DATA` | `calculate_all_statistics` → `$log_stats{$bucket}{sessions}` → the terminal sessions column (`normalize_data_for_output`), the STATS CSV and the aggregate export (both through `@populated_graph_columns`), `-V udm-counting` | the column: unless `--hide session`; CSV and export: under `-o`, whether or not the column is hidden (#444 D13); `-V`: when the section is requested |
  | `%log_users` | `## CAPTURE USER BASED STATISTICS DATA` | the same chain, `users` | as above, `--hide user` |
  | `%index_file_data` (per file) | the pre-filter block (`$fd->{match_count}++;`), the post-filter block (`$fd->{sel_match_count}++;`), and the selection half of the nanosecond block after the latches | `write_index_file` (skipped under `-ni`), `detect_index_drift` (`return unless $index_used;`) | never under `-ni` |

  The nanosecond block after the latches updates two things in one block: the
  index's selection bounds (`sel_first_s`, `sel_last_s`) and the heading's
  bounds (`$output_timestamp_min_s`, `$output_timestamp_max_s`). Only the first
  is index capture.
- **The numeric filter bounds** are still tested per in-range line as six
  `defined` tests over three families (`if( defined( $filter_duration_min ) || defined( $filter_duration_max ) ) {`
  and its twins). The highlight bounds are already behind one flag
  (`$numeric_highlight_active = quantity_bounds_given('highlight') ? 1 : 0;`).
- **The full-key lookups #616 handed forward** are still in the loop: 30 of
  `$log_messages{$category}{$log_key}` and 36 of `$log_analysis{$bucket}`.
  `features/616-gated-mean-derivation.md` § 11, drop 2 measured the form that
  takes one reference per entry: 6.2 % faster on a day of web-server access
  log, raw and bin models, faster in all twenty interleaved rounds,
  byte-identical output over fourteen option shapes; no difference on an
  application script log whose lines mostly carry no metric.
- **Gate timing.** The issue's *Done when* says the full harness suite passes
  at each step. `CLAUDE.md` runs the full suite once, as the completion gate;
  each drop is proven by the comparison in § 7 and the harnesses that read
  what it touches. This plan follows `CLAUDE.md`.

## 4. Locked decisions

Locked by the architect on 2026-09-27, stage 15 of the #342 review
(`features/342-redundant-logic-surfaces-audit-report.md` § Review progress),
with stage 16 adding step 6.

- **D1.** The hoisting remedy, delivered as a sequence of proven-neutral
  steps, each its own commit with its own before/after, the hoist probe first.
- **D2.** The steps:
  1. the string-compare gates on the message-stats mode, the bucket-stats mode,
     the heatmap and histogram modes and the grouping sensitivity become
     booleans resolved once (F8.6);
  2. the three user-defined-metric loops gain the outer guard the capture site
     already has (F8.7);
  3. run constants computed per line are computed before the loop (F8.8);
  4. one initialiser sub for the per-file detection record, called before the
     loop and by the emitter (F8.4);
  5. capture responds to its consumers: session, user and per-file index
     capture each get a demand flag in the pattern's shape, so `--hide session`,
     `--hide user` and `-ni` switch the capture off (F8.9);
  6. the raw-or-bin default of each surface is held with the surface inside the
     data-model resolver instead of at its fourteen call sites (F1.14), and the
     timeline latency column's visibility predicate is read from the
     statistics-group registry by the layout and the demand block instead of
     being written three times (FP.1): both flags resolved once, in the shape
     of steps 1 and 5;
  7. the occupant swap routes through the scan-sub resolver so the cache-hit
     telemetry counts it (F8.1; a telemetry defect, not a cost).
- **D3.** Generating the loop body per run is not part of this issue (#621).
- **D4.** The loop remains one readable sub.

Locked by the architect on 2026-10-11, in planning:

- **D5.** Two candidates outside the stage 15 list join this issue as their
  own measured drops, after the locked steps: (A) every message-entry and
  bucket-entry lookup of the loop's message and bucket sections made through
  one reference (#616's hand-forward, measured 6.2 % faster on a day of
  web-server access log), and (B) one flag for the numeric filter bounds, in
  the shape the highlight bounds already take. Grouping the off-by-default
  feature gates one flag per block is not part of this issue: a wrapper of
  that shape around the highlight blocks was declined on a measured 0.24 %
  ceiling (`features/478-highlight-decision-read-back.md`), and #621 is the
  structural form of it.
- **D6.** Capture demand for the session and user stores (drop 4): a store is
  captured when its terminal column is shown or `-o` is given (the STATS CSV
  and the aggregate export carry it whether or not the column is shown,
  #444 D13). Hiding a column removes one consumer; it does not destroy the
  data, which is what discarding a field (`-d session`) does. A `-V` section
  that reports the store's data (`udm-counting`) reads whatever was captured
  but creates no demand, under the standing rule that `-V` creates no demand
  (#349, transcribed in `features/305-shape-moment-extended-percentile-demand.md`
  § Store-level demand): under `--hide session` without `-o`, the store is not
  built and `-V udm-counting` lists no session counts. The same for users.

## 5. Design

Named here so that implementation does not choose. Each drop is one commit on
the issue branch.

**Drop 1: the capture-mode and grouping booleans (D2 step 1).** Beside the four
capture-mode assignments at loop entry, four booleans:
`$message_stats_bin`, `$bucket_stats_bin`, `$heatmap_raw`, `$histogram_raw`.
At option settlement, beside `$group_similar_sensitivity`'s resolution,
`$grouping_active = $group_similar_sensitivity ne "none" ? 1 : 0;`. The twelve
loop sites read them. The capture-mode strings stay: the `-V` emitters and the
benchmark data print them.

**Drop 2: the user-defined-metric guards (D2 step 2).** The three
`foreach my $config (@udm_configs) {` loops in the loop body (consolidation's
new key, per-message storage, time-bucket storage) are each wrapped in
`if (@udm_configs) {`, the guard the capture site uses, as the hoist probe did.

**Step 3** is delivered by #525 and #619 (§ 3); no drop.

**Drop 3: the detection record's initialiser (D2 step 4).**
`new_format_detection_record()` returns the key list once. The record is
created for each file before its loop starts; the loop's first-match site and
the per-file block read it; `note_unmatched_line`, the third copy (the audit
called it the detection emitter), calls the sub. Before this drop is written,
every reader of `$format_detection{$file}` is listed, so that a record existing
from the start of a file changes no `exists` or `defined` test.

**Drop 4: capture demand for session, user and index (D2 step 5).** Three
booleans resolved in the demand block of `adapt_to_command_line_options`,
after `apply_output_visibility` has settled the hide flags (D6):
`$session_capture_demand = ( !$hide_session || $write_messages_to_csv ) ? 1 : 0;`,
`$user_capture_demand` likewise, and `$index_capture_demand = !$no_index`
(under `-ni` nothing reads the record: `write_index_file` is skipped and
`detect_index_drift` returns before reading it), in the shape of
`$bucket_bytes_demand`. The session and user blocks and the two index blocks are
gated on them; the nanosecond block is split so that the heading's bounds are
always updated and the index's selection bounds only under the index demand.

**Drop 5: data-model defaults and the latency predicate (D2 step 6).**
`resolve_data_model` holds each surface's default and never returns undef;
`choose_data_model`, a pass-through, is removed and its callers call the
resolver. The four capture modes and the drop 1 booleans stay resolved at loop
entry: every other caller runs after the read, so nothing gains from moving
them. The registry's `timeline-latency-column`
predicate is evaluated once into `$timeline_latency_column_active`, which the
demand block and `build_column_layout` read.

**Drop 6: the occupant swap through the resolver (D2 step 7).**
`format_registry_set_occupant` calls `format_scan_sub_resolve()`.
`scan_sub_cache_hits` then counts the swap's hit: an intended change to
`-V format-registry` and to the benchmark data on any run whose file triggers
a swap.

**Drop 7: one reference per entry (D5 A).** In the loop's message section,
every access to `$log_messages{$category}{$log_key}` goes through one
reference taken where the entry is created or first found; in the bucket
section, every access to `$log_analysis{$bucket}` through one reference taken
after its `//=` creation. The references already taken (`my $e`, `my $me`,
`my $entry`, `my $be`) are folded into the one per section. The edit is the
`oneref` form of `prototype/616-observation-count-arms/make-probes.pl`,
applied to today's tree. A lookup inside a sub the loop calls is not in scope.

**Drop 8: the numeric filter flag (D5 B).** At settlement, beside
`$numeric_highlight_active`, `$numeric_filter_active = quantity_bounds_given('filter') ? 1 : 0;`.
The three family blocks of `defined` tests sit inside one `if( $numeric_filter_active ) {`;
the tests inside are unchanged (#605 D4: the comparisons stay as they are).

## 6. Acceptance criteria

Each criterion is validated on every path that reads or writes what it names,
listed beside it.

| # | Condition | Observable outcome | Validated on | Triage |
|---|---|---|---|---|
| AC1 | Any drop, on any option shape it reaches | The terminal output, STATS and MESSAGES CSVs, the aggregate export, `ltl-index.csv` and every `-V` section except timing and memory are byte-identical to the base build's; the exceptions are AC5's and AC7's named changes | the § 7 comparison, per drop, over the option shapes listed for that drop | assertable |
| AC2 | Drop 1 or 2 on a run that uses none of the gated features | No string compare on a capture mode or the grouping sensitivity, and no loop over an empty `@udm_configs`, executes per line | `grep` of the loop body for the five compares (zero hits) and for an unguarded `foreach my $config (@udm_configs)` (zero hits) | assertable |
| AC3 | Drop 1 under each capture mode | Raw and bin models of all four surfaces produce the base's output | option shapes: default; message-stats, bucket-stats, heatmap and histogram data models each `raw` and `bin`; `-g` with a mask | assertable |
| AC4 | Drop 3 | The detection record's key list is written once (`grep -c 'first_match_line => undef'` = 1); `-V` format-detection sections unchanged on a file with matches, a file with none, an empty file and a CSV file | the § 7 comparison over those four files | assertable |
| AC5 | Drop 4 under `--hide session` (or `user`) without `-o` | No session (user) store is built: `-mem`'s `log_sessions` (`log_users`) size is that of an empty hash; the terminal output is the base's; `-V udm-counting` lists no session (user) counts, the one intended difference from the base | `-V udm-counting` with `-mem` on an access log carrying sessions and users | assertable |
| AC6 | Drop 4 with the column shown, or under `-o` with or without `--hide session --hide user` | The terminal output, STATS CSV, aggregate export and `-V udm-counting` carry the sessions and users figures exactly as on the base | the § 7 comparison over the three shapes | assertable |
| AC7 | Drop 4 under `-ni` | No per-line index accumulation runs (no `-mem` row reports `%index_file_data`, so this half is shown by the code and by drop 4's timing under `-ni`); without `-ni`, `ltl-index.csv` is byte-identical to the base's, on a run with and without a filter, with and without nanosecond precision | the § 7 comparison and `tests/validate-index-read-back.sh` | assertable |
| AC8 | Drop 5 | No caller of the resolver applies its own default (`grep` for `choose_data_model` and `// 'raw'`, `// 'bin'` beside it: zero hits); the latency predicate is written once | `grep`; the § 7 comparison under `--hide stats`, `-hm`, `-o` | assertable |
| AC9 | Drop 6 on a run that swaps the occupant | `scan_sub_cache_hits` counts the swap's hit; every other `-V format-registry` key is unchanged | a scenario in `tests/validate-format-registry.sh` on a file that triggers a swap | assertable |
| AC11 | Drop 7 | No full-key lookup of a message entry or bucket entry remains in the loop's message and bucket sections (`grep -c` of the two key expressions in the loop body: one each, at the reference) | `grep`; the § 7 comparison over the drop 1 option shapes plus `-o`, `-so bytes`, `-h`, `-udm` | assertable |
| AC12 | Drop 8 | A run with no filter bound evaluates one flag where it evaluated six `defined` tests; a run with any one bound of any family excludes exactly the base's lines (`-V` filter counts and every output identical) | the § 7 comparison: each family's min alone, max alone, both, and no bound | assertable |
| AC10 | Each drop | A before/after on record: interleaved medians with ranges; no metric worse by more than 1 % across rounds | § 7 | assertable |

## 7. Verification surface

**Per drop, the neutrality comparison.** Two builds, the drop's parent commit
and the drop, run over that drop's option shapes on small slices of the corpus
families each shape needs (from `docs/test-logs.md`), with the
`prototype/616-observation-count-arms/prove.sh` method: terminal output, the
CSVs, the export, the index file and the `-V` sections, normalised for timing
and memory rows, compared byte for byte. Runtime-warning check on every run.

**Per drop, the timing.** The expected effect of each drop is near the noise
floor (about 1 % on the access log), so each is measured with the interleaved,
order-balanced driver `prototype/342-read-loop-cost-curve/run-curve.sh`: ten
rounds, parent and drop, on the day of web-server access log and the day of
application log the benchmark uses, plus the benchmark shapes that reach the
drop's code (drop 1: `heatmap-histogram-consolidate` and a bin-model run;
drop 4: the access log with `--hide session --hide user` and with `-ni`). Both
builds run from the same directory kind.

**At the completion gate.** `single-day-access-log-standard` and every
benchmark test the diff reaches (`heatmap*`, `histogram`, `top25-consolidate`,
`sort-*`), `before` on the base commit, `after` on the branch tip, then the
full harness suite.

## 8. Delivery

| Drop | Content | Harnesses that read what it touches |
|---|---|---|
| 1 | Capture-mode and grouping booleans | `validate-statistics.sh`, `validate-histogram-bin-counters.sh`, `validate-heatmap-palette.sh`, `validate-message-grouping.sh`, `validate-regression.sh` |
| 2 | Guards on the three user-defined-metric loops | `validate-udm-specs.sh`, `validate-udm-counting.sh` |
| 3 | The detection record's initialiser | `validate-format-registry.sh`, `validate-format-detection.sh`, `validate-csv-input.sh` |
| 4 | Capture demand for session, user and index | `validate-udm-counting.sh`, `validate-index-read-back.sh`, `validate-aggregate-export.sh`, `validate-csv-output.sh` |
| 5 | Data-model defaults in the resolver; the latency predicate once | `validate-statistics-demand.sh`, `validate-section-layout.sh`, `validate-runtime-config.sh`, `validate-option-resolution.sh` |
| 6 | The occupant swap through the resolver | `validate-format-registry.sh` |
| 7 | One reference per message and bucket entry | `validate-statistics.sh`, `validate-csv-output.sh`, `validate-aggregate-export.sh`, `validate-udm-counting.sh`, `validate-message-grouping.sh` |
| 8 | The numeric filter flag | `validate-filter-summary.sh`, `validate-numeric-criteria-notices.sh` |


## 9. Records to update at delivery

- `docs/architecture-patterns.md`: the five entries named in § 1 lose the
  *needs refinement* lines this issue closes, and gain consumption sites for
  the new flags.
- `features/342-redundant-logic-surfaces-audit-report.md` § Review progress:
  stage 15's status.
- `features/266-data-model-selectors.md` § Resolution at each call site: the
  default held by the resolver.
- #622's Order list; #621 released.

## 10. Implementation record

Branch `620-read-loop-run-constant-hoisting`, cut from `release/0.19.0`
905911a. Every drop was compared with its parent over the same 44 to 51
option shapes on slices of five log families (a web-server access log with
thread and session, one without session, an application log carrying users, a
script log carrying duration and count, a CSV of metrics, an empty file),
with bare `-V`, `-o` and the index file written; timing and memory rows and
the float sums whose last digits follow hash order are normalised. The base
build compared with itself gives no difference over the same shapes.

Timing is the interleaved, order-balanced method of
`prototype/342-read-loop-cost-curve/run-curve.sh`: ten rounds of parent and
drop on the day of web-server access log (761,698 lines) and the day of
application log (479,904 lines) the benchmark uses; per-round delta, median
and range. On this machine two builds that differ only off the per-line path
read up to about ±1.2 % apart on the access log (drops 3, 5 and 6 below),
which is the resolution of a ten-round median here.

| Drop | Commit | Output against parent | Access log, per-round delta | Application log, per-round delta |
|---|---|---|---|---|
| 1, capture modes and grouping as booleans | 116edbc | identical, 44 shapes | −0.93 % (−0.203 to +0.168 s), faster in 7 of 10 | +0.37 % over 20 rounds (−0.162 to +0.069 s), slower in 12 of 20 |
| 2, guards on the user-defined-metric loops | b738701 | identical, 44 shapes | −1.21 % (−0.185 to +0.027 s), faster in 9 of 10 | +0.63 % (−0.030 to +0.081 s), slower in 7 of 10; the guarded loops are on branches this log's lines do not reach |
| 3, the detection record's initialiser | 6491f2b | identical, 51 shapes (multi-file and unmatched-only runs added) | +0.38 % (−0.077 to +0.103 s) | −0.68 % (−0.110 to +0.009 s) |
| 4, capture demand for session, user and index | 9b4bf5a | identical, 51 shapes, except D6's named difference: under `--hide session`/`--hide user` without `-o`, `-V udm-counting` lists no session (4 lines) or user (1 line) counts | default options +1.21 % (−0.231 to +0.234 s), slower in 9 of 10; with `--hide session --hide user -ni` on the thread-session access log **−19.6 %** (6.337 s to 5.081 s, faster in 10 of 10) | default +0.14 %; with `--hide user -ni` **−13.8 %** (3.567 s to 3.059 s, faster in 10 of 10) |
| 5, data-model defaults in the resolver; the latency rule once | 15935c7 | identical, 51 shapes | −1.15 % (−0.195 to +0.092 s) | −0.35 % |
| 6, the occupant swap through the resolver | cae1f1f | identical, 51 shapes; `scan_sub_cache_hits` 3 against 2 on a month-first, day-first, month-first run | +0.29 % (−0.212 to +0.094 s) | −0.41 % |
| 7, one reference per message and bucket entry (D5) | bf33d26 | identical, 61 shapes (each numeric-filter family and end added) | **−4.94 %** (8.201 s to 7.779 s; −0.547 to −0.350 s), faster in 10 of 10; bin models (`-mdm bin -bdm bin`) **−4.07 %** (10.631 s to 10.216 s), faster in 10 of 10 | +0.29 % (−0.056 to +0.034 s) |
| 8, one flag for the numeric filter bounds (D5) | 0103932 | identical, 61 shapes | **−1.80 %** (−0.249 to −0.061 s), faster in 10 of 10 | **−1.48 %** (−0.097 to −0.011 s), faster in 10 of 10 |

Store sizes under drop 4 (`-V benchmark-data -mem`, the thread-session access
log slice): `log_sessions` 29,019 bytes on drop 3 and 120 bytes, an empty
hash, on drop 4 under `--hide session --hide user`.

Harnesses run per drop, each passing with no runtime warning: drop 1
`validate-statistics.sh`, `validate-histogram-bin-counters.sh` (148),
`validate-heatmap-palette.sh` (85), `validate-message-grouping.sh` (51),
`validate-regression.sh` (74 of 74); drop 2 `validate-udm-specs.sh` (250),
`validate-udm-counting.sh` (44); drop 3 `validate-format-registry.sh` (57),
`validate-format-detection.sh` (472), `validate-csv-input.sh` (43); drop 4
`validate-udm-counting.sh` (44), `validate-index-read-back.sh` (98),
`validate-aggregate-export.sh` (163), `validate-csv-output.sh` (42),
`validate-timestamp-precision.sh` (94); drop 5
`validate-statistics-demand.sh` (112), `validate-section-layout.sh` (186),
`validate-runtime-config.sh` (85), `validate-option-resolution.sh` (186);
drop 6 `validate-format-registry.sh` (59, with the new `occupant-swap`
scenario, shown failing on the drop 5 build); drops 7 and 8
`validate-statistics.sh` (25 scenarios, the same 45 expected failures as at
drop 1), `validate-csv-output.sh` (42), `validate-aggregate-export.sh` (163),
`validate-udm-counting.sh` (44), `validate-message-grouping.sh` (51),
`validate-filter-summary.sh` (146), `validate-numeric-criteria-notices.sh` (10).

**Drop 4's cost on a default run, and the follow-up that removed it.** Drop 4
as first committed measured +1.21 % on the default access-log run over ten
rounds, outside the ±1.2 % spread, and +1.07 % (slower in 20 of 20) over
twenty rounds against drop 3. Attribution, twenty rounds each against drop 3
on the day of web-server access log:

| Build | Default options | `-ni` |
|---|---|---|
| drop 4 as committed (9b4bf5a) | +1.27 % (−0.004 to +0.213 s), slower in 18 of 20 | −19.06 % (8.228 s to 6.669 s) |
| drop 4 without its two index gates | +0.09 % (−0.110 to +0.203 s), slower in 11 of 20 | not measured |
| drop 4 with the session and user flags tested after the field tests | +1.08 %, slower in 19 of 20 | not measured |
| drop 4 with the file's index record taken once per file (e8da582) | **−0.99 %** (−0.164 to +0.026 s), faster in 18 of 20 | **−20.14 %** (8.228 s to 6.578 s) |

The two index gates carried the whole cost; each index block also looked up
`$index_file_data{$in_file}` on every line, three lookups a line for a value
fixed per file. Taking that reference once per file pays for the gates. The
session and user flags are tested after the field tests, so a line without
the field pays nothing for them; on this log, which carries no session, that
order made no measurable difference. The per-line index accumulation is
about a fifth of a default access-log run (`-ni` saves 19 to 20 %), far more
than the audit's estimate of about 4 % for those blocks (item 8, part 3).

Found during implementation:

- One grouping compare drop 1 did not reach: the `-V message-grouping`
  accounting's `$group_similar_sensitivity eq "none"` (the hoist probe counted
  only the `ne` form). It is evaluated only when that section is requested, and
  reads `!$grouping_active` in a drop 1 follow-up (6ad86e8, byte-identical
  over 61 shapes).
- The detection record's third copy was `note_unmatched_line`, which the
  audit called the detection emitter.
