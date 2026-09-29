# Store the message total duration precise, format it at the rendering boundary (Issue #273)

## Status

Specification agreed with the architect 2026-09-29 on branch
`273-store-precise-duration-totals` off `release/0.19.0`. Drop 1 (the message
store) and drop 2 (the time-bucket store) implemented 2026-09-29; the
completion gate passed on 49d3e09 (§ Completion gate).

**Drop 1 progress.** The two CSV-output scenarios (`messages-sort-duration`,
`messages-omit-durations`) were written first. The `-od` scenario failed on the
base with `duration_nice` = `0` on all twelve MESSAGES rows and nothing else;
the sort scenario passed on the base and failed on a build whose sort key
named a missing field (row 4 carried a total of 2 below a row of 1); the
zero-cell check failed on a MESSAGES CSV doctored to read `0ns`; the STATS
absence check of a switched-off family failed on a STATS CSV carrying the
duration columns (23 columns reported). After the change both scenarios pass.
Criterion 6's method changed with the architect (§ Acceptance criteria 6).

**Drop 2 progress.** A bucket's duration total and its highlighted share are
named `duration_sum` and `duration_sum-HL` from the read loop to the last
reader, in `%log_analysis` and `%log_stats` alike (architect, 2026-09-29: a
field named `duration` cannot hold a total; the metric plus the `sum`
statistic is the name, as `count_sum`, a user-defined metric's `<name>_sum`
and the per-file index record's `duration_sum` already are). The exposed
surfaces keep their names: the STATS CSV header stays `duration` (#432 D1, a
bare metric word is its sum) and the aggregate export's key stays `sum`.
Readers that walk the graph columns resolve the field through
`column_total_field()` over `%column_total_field` (`duration =>
'duration_sum'`), which maps a column id to its total's field only where they
differ (a consumption site of the declarative-table pattern); scaled-bar keys and the bar
maximum stay keyed by the column id. Bytes and the message store's
`total_duration` keep their names; their naming is #613's (one vocabulary for
names). The staged statistics input keeps `total_duration` and no longer
seeds `total_duration-HL`. Both statistics subs
now read the mean's numerator from the staged input. For
`calculate_statistics_bin` that needed one caller change beyond the bucket
path: the message-key sort pre-pass passed an empty staged input and relied on
the sub reading the message entry's total, so it now stages
`{ total_duration => $entry->{total_duration} }` as its raw twin does. No
statistics drift scenario sorts on a computed statistic under the bin data
model, so that call was proven directly: on the 5,000-line Tomcat access log
with millisecond durations, `-bs 60 -n 15 -mdm bin -bdm bin -cp full -o` with
`-so mean`, `-so p99` and `-so cv`, the terminal output and both CSVs are
byte-identical to the drop 1 commit, with no runtime warning. After the
rename, the same log compared against the drop 1 build under `-bs 60 -n 15
-cp full -o` with `-mdm bin -bdm bin -so mean`, with `-mdm raw -bdm raw -h
GetDateAndTime` and with `-mdm bin -bdm bin -so p99 -hdmin 200`: terminal
output, MESSAGES and STATS CSVs byte-identical, the aggregate export differing
only in its run-time and memory lines, no runtime warning.

Every site below was re-located in the worktree's `ltl` (base 4b238ff; `ltl`
is unchanged since 58f8d94) by enclosing sub plus an in-body snippet that
`grep -F` finds inside that sub. The runs quoted were captured once to the
session scratchpad and read from the files.

---

## 1. The motivating consumer

The nice duration string exists for the MESSAGES CSV: the architect wanted the
human-readable total the terminal shows to be present in the CSV beside the raw
number. Today that string is made in the statistics phase and written over the
accumulated number, so the store holds a number for half the run and a string
for the rest, and a second field keeps the number for the sort and the CSV's
numeric cell. The architect called this a quick fix that has always bothered
him, and asked for it to be cleaned up now (§ 4, the locks of 2026-09-29).

Three consumers need the per-message total to stay a number for its whole life.

1. **The CSV row.** The raw total and its nice rendering sit side by side in the
   MESSAGES CSV (`duration` and `duration_nice`). With one precise field, the
   raw cell reads it through the CSV number formatter and the nice cell is
   rendered from it once, just before the row is written.
2. **The next renderer of the total.** Stage 7 of the #342 review (the triage
   of the audit of redundant logic surfaces) locked one width-to-format rule
   with a tier axis and a fit axis, filed as #617 (one width-to-format rule),
   which lets each surface pass its width or name the tier it wants. The
   messages table's total cannot take part while the statistics phase has
   already turned the number into the string `24 msec` at the medium tier. The
   audit recorded exactly this (the formatted string stored where every other
   statistic is a number, so "a future renderer that wants a different tier
   cannot have one").
3. **The one declaration per CSV column** (#618, locked in stage 12 of the same
   review): every column gets one declaration with a value accessor. For the
   bytes pair the accessor is "the number" and "the number through the bytes
   formatter". Without this issue the duration pair would be the single column
   whose accessor reads a pre-formatted field while its numeric twin reads a
   second field holding the same number.

The bytes total in the same sub already has the target shape: the store holds
the precise number and the unit string is made at the emit site
(`print_message_summary` ::
`my $total_bytes = defined $total_bytes_num ? format_bytes( $total_bytes_num,'B' ) : undef;`).
This issue gives the duration total the same shape.

Nothing a user reads changes on the default, grouping, bin data model or `-cp`
paths. The one user-visible change is under `-od` (§ 5), where the two CSV
cells of the same total disagree today.

---

## 2. Requirement

In the architect's terms, from the issue body (filed 2026-05-25 during #271, the
integer-truncated mean fix), the #342 review locks of 2026-09-27 and his
replies of 2026-09-29, organised but not reinterpreted.

- **The duration accumulator never changes type.** The accumulated total is a
  number and stays a number. A field that means "total accumulated duration"
  does not change type depending on whether it has been through the display
  formatter.
- **The nice rendering is for the CSV and happens once, just before it is
  written.** The CSV carries the terminal's human-readable render beside the
  retained raw value. The render is made at the write, never earlier, never
  stored.
- **Internal consumers converge.** The other internal consumers of duration
  and total_duration converge on fewer surfaces: fewer variables, fewer
  conversions. This covers the time-bucket store as well as the message store.
- **No nice formatting in the hot-path loop.**
- **The precise sibling goes outright.** `total_duration_num` is removed, not
  kept as an alias; nothing external uses it. The `ltl-index.csv` surface is
  checked for any use of it.
- **No regression** in the structural CSV harness (`tests/validate-csv-output.sh`,
  from #223), the statistics drift harness (`tests/validate-statistics.sh`,
  from #224), or the regression suite.
- **Framing.** Architectural cleanup, not a correctness bug. The issue deferred
  it until #271 (precise mean inside `calculate_statistics`) and #268 (every
  computed statistic stored precise, rounding at the CSV emit boundary, with
  `--csv-precision`) shipped, because they establish the storage-stays-precise
  pattern this issue extends. Both have shipped (§ 3, item 3).
- **From the review.** Finding F2.15 (the message total duration stored as a
  formatted string) is this issue (D1). This issue's pattern is the one the
  per-message bytes mean follows when #616 (one gated derivation of means and
  totals) stores it precise (D2).

---

## 3. Corrections to the issue body and the audit record

Verified in the worktree's `ltl` at 4b238ff (unchanged since 58f8d94).

| # | What the issue or audit says | What the current code and records show |
|---|---|---|
| 1 | The overwrite is at a line number in `ltl`. | The overwrite still exists: `calculate_all_statistics` :: `$log_messages{$category}{$log_key}{total_duration} = format_duration_total( $aggregated_data->{total_duration}, 'medium', 'space' ) if defined $aggregated_data->{total_duration};`. The line before it re-assigns the sibling from the same number: `$log_messages{$category}{$log_key}{total_duration_num} = $aggregated_data->{total_duration} if defined $aggregated_data->{total_duration};`. Both sit in the group-calculation loop over the top-N keys, inside `if( defined $aggregated_data->{total_duration} && $message_duration_stats_demand ) {`. |
| 2 | Three math readers deliberately read `total_duration_num`. | `total_duration_num` still exists. It has five writers and two readers. **Writers:** `read_and_process_logs` :: `$log_messages{$category}{$log_key}{total_duration_num} += $duration;` (every line with a duration, beside the identical `{total_duration} += $duration`); `read_and_process_logs` :: `$stats_source->{total_duration_num} = $duration;` (first line of a new key under consolidation); `merge_consolidation_stats` :: `$target->{total_duration_num} = ($target->{total_duration_num} // 0) + ($source->{total_duration_num} // 0);`; `group_similar_messages` :: `$entry->{total_duration_num} = $cluster->{total_duration_num};`; and the re-assignment in item 1. **Readers:** the sort key, set in `adapt_to_command_line_options` :: `$sort_key = "total_duration_num";` for `-so duration` (and `time`) and read by the `calculate_all_statistics` comparator `my $occurrences_a = $log_messages{$category}{$a}{$sort_key} // 0;`; and the MESSAGES CSV numeric cell, `print_message_summary` :: `format_csv_value($total_duration_num,'duration'),`. One comment names it: `calculate_all_statistics` :: `# total_duration_num, bytes, impact, count_*) are not in it.` |
| 3 | Defer until #271 (precise mean inside `calculate_statistics`) and #268 (every computed statistic stored precise) ship. | Both are closed as shipped (2026-05-25, merged on `release/0.14.6`; the user-facing record is `releases/v0.15.0.md`). Neither has a feature doc. The storage-stays-precise contract is recorded only in #268's completion comment and that release note ("All computed statistics are now stored at full precision internally; rounding moves to the CSV-emit boundary"). |
| 4 | The rendering paths call `format_time()` at emit. | The stored string is made by `format_duration_total`, the totals wrapper that renders a zero in the source's resolved unit (#444 R17 and D16). Calling `format_time` directly would render a zero at the ladder's lowest step: the audit measured `0ns` in the heatmap header (`-hm duration -bs 1` on a synthetic access log whose durations are zero), which calls it directly, against `0 milliseconds` on the timeline's zero bucket and `0ms` in its latency cells of a synthetic access log with millisecond durations at `-bs 1`: one value, two units. On the twelve-line access log with one request per endpoint, four keys whose only duration is zero render `0 msec` in the table and in `duration_nice` today. The emit sites call the totals formatter, not the ladder scaler. |
| 5 | The consolidation merge path reads both fields. | It is `merge_consolidation_stats` (sum of both) and the copy block in `group_similar_messages` (both copied onto the canonical entry). Both run in `pipeline_finalize` before `calculate_all_statistics`, so neither ever sees the formatted string. They carry a redundant numeric sibling, not a type hazard. |
| 6 | Every downstream math reader reads the sibling on purpose. | The sort does not need to: it runs in `calculate_all_statistics` before the group-calculation loop overwrites the field, so `total_duration` still holds the same number there. The MESSAGES CSV numeric cell is the only reader after the overwrite that needs the number. |
| 7 | (not in the issue) | The overwrite is conditional, and one case leaves the two CSV cells of the total disagreeing. Under `-od` (`--omit-durations`) nothing accumulates, but the key's lazy initialiser in `read_and_process_logs` still sets `total_duration => 0`, and the removal of an unobserved total in `calculate_all_statistics` is skipped under `-od` (`} elsif ( !$duration_observed && !$omit_durations ) {`). Measured on the twelve-line access log with one request per endpoint, `-od -o -bs 1440 -oe -ni -n 12`, and on the 434-line access log with `-n 3`: every MESSAGES row has `duration`, the 21 duration statistic columns and `impact` empty, and `duration_nice` = `0` (a bare number in a column the CSV rules type as "value plus unit"). No harness runs `-od` with `-o`, so nothing asserts it. The messages table is unaffected: its statistics variant is off under `-od` (`print_message_summary` :: `my $statistics_variant = ( $message_duration_stats_demand && $durations_observed ) ? 1 : 0;`). |
| 8 | The audit's finding on the message total stored as a formatted string (F2.15) and #616's issue body (one gated derivation of means and totals) name `features/561-retained-durations-as-numbers.md` as the "storage stays precise" contract. | That document records retained duration samples kept as numbers rather than strings, to halve the two sample stores' memory. It names `total_duration` and `total_duration_num` only as numeric accumulations outside its scope. The contract this issue extends is #268's (item 3). |
| 9 | `features/426-per-message-statistics-store.md` says the field is overwritten by `format_time(...)`. | It is `format_duration_total` (item 1). |
| 10 | (scope check) | This is the only formatted value stored in a data store. A search for assignments of any `format_*` call or `sprintf` into `%log_messages`, `%log_stats`, `%log_analysis`, `%heatmap_data` or `%log_occurrences` finds this one site. The `int(...)` results in `normalize_data_for_output` write separate scaled bar-length keys and overwrite nothing. |
| 11 | "External dependencies the author missed." | None. No harness, rules TSV, `-V` section, user doc or `--help` row names `total_duration_num`, and the sort key is not printed on any `-V` section. Three prototype scripts mirror the read loop with the sibling (`prototype/426-store-mini.pl`, `prototype/426-bin-store-mini.pl`, `prototype/528-record-lexical-retained-representation/retained-representation.pl`); they are frozen measurement records, not consumers. |
| 12 | (the `ltl-index.csv` surface, D8) | The run index reads neither the sibling nor the formatted string. `write_index_file` writes each file's duration columns from the per-file index record, not the message store: `my $dur_avg   = $fd->{duration_occurrences} > 0 ? sprintf("%.2f", $fd->{duration_sum} / $fd->{duration_occurrences}) : '-';`, with `duration_min` and `duration_max` beside it, and the same for the selection row from `sel_duration_sum`. Those sums are their own per-line accumulators in `read_and_process_logs` (`$fd->{duration_sum} += $duration;` and `$fd->{sel_duration_sum} += $duration;`). `read_index_file` and `detect_index_drift` read only the `duration_min` and `duration_max` columns (`[ duration_min   => $unfiltered ? 'duration_min'   : 'sel_duration_min',   'min' ],`). The index keeps writing the precise numbers it writes today with no change. |
| 13 | (the hot-path scan, D6) | No display formatter is reachable per line today. Inside `read_and_process_logs`, the only calls to `format_number`, `format_duration*`, `format_time`, `format_bytes`, `format_csv_value`, `format_epoch_iso`, `strftime` or `sprintf` are the end-of-read notices after the loop (for example `print STDERR "Note: " . format_number($count, 'medium')`); the `format_*` names inside the loop are the format registry's detection calls, not display. The per-line bucket key is integer arithmetic. The per-line cost this issue removes is the sibling accumulation, one hash update per line with a duration. The total's formatter runs today once per displayed key in the statistics phase, not per line. The one formatting callee, `progress_line_text`, is reached only through the repaint gate (`if ($total_lines_read % PROGRESS_LINE_STRIDE == 0 && !$disable_progress) {`), not per line. |
| 14 | (the time-bucket store, D9) | The bucket store holds one number under three names. The read loop accumulates it in `%log_analysis` (`read_and_process_logs` :: `$log_analysis{$bucket}{total_duration} += $duration;`, with the highlighted share in `'total_duration-HL'`); `calculate_all_statistics` stages it into a hash built for that one bucket (`$aggregated_data->{total_duration} += $log_analysis{$bucket}{total_duration};`) and copies it into `%log_stats` under the metric's column id (`duration      => $log_analysis{$bucket}{total_duration},`, in both the statistics branch and the no-statistics branch, with `'duration-HL'`). The statistics subs read the first two names (`calculate_statistics` :: `my $mean = $bucket_data->{total_duration} / $duration_count;` from the staged hash; `calculate_statistics_bin` :: `my $mean = $sidecar_entry->{total_duration} / $n;` directly off the bucket accumulator); every reader that works across metrics reads the third. The staged hash also seeds `'total_duration-HL' => 0,`, which nothing adds to or reads. All three hold a number throughout; nothing formats one in place. Bytes (`total_bytes` copied to `bytes`) and count (`count_sum` copied to `count`) have the same pair shape; D9 names the duration pair. |

**The issue's acceptance criteria, re-derived.** The first (the stored total is
precise) stands, strengthened by D3 (the field never changes type). The second
stands as a removal (D8). The third stands, corrected by item 4: the emit sites
call the totals formatter. The fourth (no regression in the three suites)
stands and is the completion gate plus acceptance criteria 5 and 8 below.

---

## 4. Locked decisions

These are the architect's. Nothing else in this document is numbered Dxx.

- **D1: F2.15 is this issue.** The finding that the message total duration is
  stored as a formatted string, where every other statistic is stored as a
  number, is dispositioned to #273 with no separate issue. *Locked by the
  architect 2026-09-27, stage 16 of the #342 review (the ten findings no
  stage had claimed are placed: "F2.15 is #273").*
- **D2: this issue is the precision pattern the per-message bytes mean follows.**
  The bytes mean is stored precise and rounded only by the CSV formatter, per
  this issue's pattern. The bytes mean itself is #616's work (its lock 6), not
  this issue's. *Locked by the architect 2026-09-27, stage 1 of the #342 review
  (the 513/512 bytes mean folded into stage 6, "#273 is the precision pattern
  it follows") and stage 6 (filed as #616).*
- **D3: the duration accumulator never changes type.** The accumulated
  per-message total is a number and stays a number for the whole run.
  Overwriting it with the nice string was a quick fix and is cleaned up now.
  One precise field holds the per-message total from the first line to the
  last renderer. *Locked by the architect 2026-09-29.*
- **D4: the nice rendering exists for the CSV and happens once, just before the
  row is written.** The impetus for the nice string was the MESSAGES CSV, where
  the terminal's human-readable render is present beside the retained raw
  value. It is rendered exactly once at the CSV write site, and for the
  messages table at the table's own emit site (which the width-to-format rule
  of #617 then walks by the column's width), never earlier and never stored.
  *Locked by the architect 2026-09-29.*
- **D5: internal consumers of duration and total_duration converge, on both
  stores.** The other internal consumers of duration and total_duration
  converge on fewer surfaces: fewer variables, fewer conversions. It covers the
  message store (the per-message total and its sibling) and the time-bucket
  store (the bucket accumulator and its copy in the statistics store, D9).
  Every reader and writer of either store's total is listed, with what remains
  after the change (§ 5). *Locked by the architect 2026-09-29.*
- **D6: no nice formatting in the hot-path loop.** Any formatting call
  reachable per line in the read loop is a defect this issue removes or
  reports. The per-line path carries only the numeric accumulation, and the
  before/after benchmark on the standard case measures it. *Locked by the
  architect 2026-09-29.*
- **D7: under `-od -o` both the numeric and the nice duration cells are
  empty.** The removal of an unobserved total extends to `-od`; one
  release-notes line; a new CSV-output scenario proves it. #616 (one gated
  derivation of means and totals) later swaps its observation-count gate in at
  that one site and inherits the scenario. *Locked by the architect 2026-09-29
  ("J1. yes").*
- **D8: `total_duration_num` is removed outright, not kept as an alias.**
  Nothing external uses it. The `ltl-index.csv` surface (`write_index_file`,
  `read_index_file`, the drift check) is checked for any read of the sibling or
  of the formatted string and adjusted so the index keeps writing the precise
  numbers it writes today; § 3 item 12 records what was found (no read of
  either; no change needed). *Locked by the architect 2026-09-29 ("J3. no, it
  should not be kept 'just in case'. Nothing externally uses it.").*
- **D9: the convergence covers the time-bucket store.** The per-bucket
  accumulator `total_duration` and its copy under the name `duration` in the
  statistics store are converged to one surface, since every metric-generic
  reader (the copy into the statistics store, the per-bucket staging into the
  statistics input, the bucket mean in the statistics subs, the bar scaling,
  the timeline's nice duration cell, the STATS CSV and the aggregate export)
  reads one or the other (§ 3 item 14). It is delivered in a drop of its own,
  with its own proof that the output is unchanged. *Locked by the architect
  2026-09-29 ("K1. yes this convergence should cover the time bucket store as
  well.").*

**Ordering with #618 (one declaration per CSV column).** This is not an
architect's lock. It is a routine ordering judgement, recorded as a native edge
(#618 blocked by #273) when this document was delivered on 2026-09-29, and the
architect can overturn it. #618 gives every CSV column, `duration_nice`
included, one declaration with a value accessor, read by both CSV writers. If
#618 landed first, its `duration_nice` accessor would read a stored string
while its `duration` accessor read a second field, and this issue would then
have to rewrite both. This issue can finish without #618. #617 (one
width-to-format rule) and #616 (one gated derivation of means and totals) were
already recorded as blocked by #273.

**Decisions in other records that bind this work** (cited, not re-numbered):

| Record | What it fixes for this work |
|---|---|
| #268 completion record and `releases/v0.15.0.md` | Computed statistics are stored precise; rounding happens at the CSV emit boundary through `format_csv_value`. |
| `features/444-access-log-format-family-and-user-surface.md` R17, D16 | A zero total renders in the source's resolved unit. |
| #617 lock (stage 7, F2.1: zero in the source unit everywhere) | A real zero duration renders in the source's resolved unit on every surface; an absent value is #616's empty cell. |
| `features/617-width-to-format-rule.md` D18 (on #617's branch; comment on this issue) | The messages-table total, once formatted at this issue's emit site, is walked by the table's column width; the CSV `duration_nice` cell keeps a fixed budget. |
| `features/616-gated-mean-derivation.md` D19 and D21 (on #616's branch; comment on this issue) | This issue lands first and keeps the unobserved-total change with its `-od` scenario; impact stays empty under `-od`; #616 swaps in the observation-count gate at that site and inherits the scenario; this issue writes the precise-storage entry in `docs/architecture-patterns.md`, #616's entry covers observation counts and gated means only. |
| #616 locks 1 and 4 (stage 6) | Every accumulator keeps an unconditional observation count; derived output is gated on the count, and `defined` over a zero-initialised field is not a gate anywhere. |
| `features/561-retained-durations-as-numbers.md` (accepted 2026-09-13) | `-cp full` exports numbers without the log line's trailing zeros; unaffected here, since the total is arithmetic. |
| The #330 behaviour recorded in `calculate_all_statistics` and `features/426-per-message-statistics-store.md` § Findings | A message key with no observed duration emits blank total cells, never a zero indistinguishable from a measured zero. |

---

## 5. Design

Settled by D3 to D9 unless marked **proposed** (implementation detail the
architect did not decide).

### The target shape

The message store keeps one field, `total_duration`, holding the accumulated
duration as a number from the first line to the last renderer (D3, D8). The
two emit sites in `print_message_summary` render it, each once per row it
writes, and store nothing (D4). This is the shape the bytes pair already has.

The time-bucket store holds each bucket's total on one surface from the read
loop to the last reader, instead of an accumulator copied under a second name
into the statistics store (D5, D9).

### Every reader and writer of the message total, before and after (D5)

| Site (sub :: snippet) | Role today | After |
|---|---|---|
| `read_and_process_logs` :: the lazy initialisers `total_duration => 0,` (bin and raw branches) | seed the number | unchanged |
| `read_and_process_logs` :: `$log_messages{$category}{$log_key}{total_duration} += $duration;` | per-line accumulation (hot path) | unchanged; the only per-line write of the total |
| `read_and_process_logs` :: `$log_messages{$category}{$log_key}{total_duration_num} += $duration;` | per-line sibling accumulation (hot path) | removed |
| `read_and_process_logs` :: `my $mean = $log_messages{$category}{$log_key}{total_duration} / $log_messages{$category}{$log_key}{occurrences};` | per-line impact from the number | unchanged (the impact gate is #616's) |
| `read_and_process_logs` :: `$stats_source->{total_duration} = $duration;` | new-key seed under consolidation | unchanged |
| `read_and_process_logs` :: `$stats_source->{total_duration_num} = $duration;` | sibling seed | removed |
| `merge_consolidation_stats` :: `$target->{total_duration} = ($target->{total_duration} // 0) + $source->{total_duration};` | consolidation merge | unchanged; the merge of the one field |
| `merge_consolidation_stats` :: `$target->{total_duration_num} = ($target->{total_duration_num} // 0) + ($source->{total_duration_num} // 0);` | sibling merge | removed |
| `group_similar_messages` :: `$entry->{total_duration}     = $cluster->{total_duration};` | group copy onto the canonical entry | unchanged; the copy of the one field |
| `group_similar_messages` :: `$entry->{total_duration_num} = $cluster->{total_duration_num};` | sibling copy | removed |
| `group_similar_messages` :: `my $mean = $entry->{total_duration} / $entry->{occurrences};` | impact recompute | unchanged |
| `adapt_to_command_line_options` :: `$sort_key = "total_duration_num";` | sort key for `-so duration` and `-so time` | names `total_duration`; `sort_key_metric_family` already maps an unlisted key to the duration family, so the parse-time sort gate is unchanged |
| `calculate_all_statistics` :: `my $occurrences_a = $log_messages{$category}{$a}{$sort_key} // 0;` (both comparators: the metric sort into `@by_metric` and the pool re-sort into `@sorted_log_keys`) | sort comparators | unchanged; read the one field |
| `calculate_all_statistics` :: `my $cut_val = $log_messages{$category}{$by_metric[$cut]}{$sort_key} // 0;` and `&& (($log_messages{$category}{$by_metric[$pool_end + 1]}{$sort_key} // 0) == $cut_val);` | display cut and tie extension of the candidate pool under the sort key | unchanged; read the one field |
| `calculate_all_statistics` :: `total_duration => $entry->{total_duration},` | sort pre-pass input to `calculate_statistics` | unchanged |
| `calculate_statistics_bin` :: `my $mean = $sidecar_entry->{total_duration} / $n;` | bin data model: reads the message entry's total directly, from the sort pre-pass (`calculate_statistics_bin(` with `$entry`) and from the group-calculation loop (with `$log_messages{$category}{$log_key}`), both before the overwrite | unchanged; reads the one field |
| `calculate_all_statistics` :: `$duration_observed ||= ( ($log_messages{$category}{$log_key}{total_duration} // 0) > 0 );` | observation fallback | unchanged (#616 replaces it with its count) |
| `calculate_all_statistics` :: `$aggregated_data->{total_duration} += $log_messages{$category}{$log_key}{total_duration};` | staging copy into `calculate_statistics`'s input | unchanged; it is that sub's input contract, shared with the bucket path |
| `calculate_statistics` :: `my $mean = $bucket_data->{total_duration} / $duration_count;` | reads the staging copy (raw data model) and the sort pre-pass input | unchanged |
| `calculate_all_statistics` :: `delete $log_messages{$category}{$log_key}{total_duration};` under `} elsif ( !$duration_observed && !$omit_durations ) {` | removal of an unobserved total, skipped under `-od` | applies in every mode (D7) |
| `calculate_all_statistics` :: the re-assignment and the overwrite of § 3 item 1 | number copied to the sibling, string written over the number | both removed; nothing is written back for the total, since the field already holds the number |
| `calculate_all_statistics` :: `# total_duration_num, bytes, impact, count_*) are not in it.` | comment | names `total_duration` |
| `print_message_summary` :: `my $total_duration_num = $log_messages{$grouping}{$key}{total_duration_num};` and `my $total_duration = $log_messages{$grouping}{$key}{total_duration};` | two locals, one number and one string | one local holding the number |
| `print_message_summary` :: `defined $log_messages{$grouping}{$key}{total_duration}` in the statistics-variant row test | presence test | unchanged |
| `print_message_summary` :: the table cell `sprintf( "%$col_width{7}s", defined $total_duration ? $total_duration : "" )` | prints the stored string | renders the number here (below) |
| `print_message_summary` :: `format_csv_value($total_duration_num,'duration'),` then `$total_duration,` in the MESSAGES row | numeric cell from the sibling, nice cell from the stored string | numeric cell from the one local; nice cell rendered here (below) |

What remains: one field, one per-line write, one local at the emit, two nice
renderings (one at each emit site) and the CSV number formatting of the raw
cell. Before the change: two fields, two per-line writes, two locals, and a
conversion in the statistics phase whose result is stored.

### Every reader and writer of the bucket total, before and after (D5, D9)

| Site (sub :: snippet) | Role today | After |
|---|---|---|
| `read_and_process_logs` :: the lazy initialisers of `$log_analysis{$bucket}` (`total_duration => 0,`, bin and raw branches) | seed the bucket accumulator | seed the one surface |
| `read_and_process_logs` :: `$log_analysis{$bucket}{total_duration} += $duration;` and `$log_analysis{$bucket}{'total_duration-HL'} += $duration if $line_is_highlighted;` | per-line accumulation of the total and its highlighted share (hot path) | the only per-line writes, onto the one surface; still numeric, still one hash update each |
| `calculate_all_statistics` :: `$aggregated_data->{total_duration} += $log_analysis{$bucket}{total_duration};` | stages the bucket's total into the statistics input (the staged hash holds this one bucket) | reads the one surface; it remains the statistics subs' input, shared with the message store |
| `calculate_all_statistics` :: `'total_duration-HL' => 0,` in the staged hash | seeded, never added to or read | removed |
| `calculate_statistics` :: `my $mean = $bucket_data->{total_duration} / $duration_count;` | bucket mean (raw data model), from the staged input | unchanged; reads the staged input |
| `calculate_statistics_bin` :: `my $mean = $sidecar_entry->{total_duration} / $n;` with the bucket accumulator as the sidecar entry | bucket mean (bin data model), read off the accumulator by name | reads the bucket's total without a second name (the proposal below) |
| `calculate_all_statistics` :: `duration      => $log_analysis{$bucket}{total_duration},` and `'duration-HL' => $log_analysis{$bucket}{'total_duration-HL'},` (the statistics branch and the no-statistics branch) | copies the total into `%log_stats` under the metric's column id | no second name: the statistics store carries the one surface |
| `normalize_data_for_output` :: `$max_total{duration} = $log_stats{$bucket}{duration} if ( defined $log_stats{$bucket}{duration} && $log_stats{$bucket}{duration} > $max_total{duration} );` | largest bucket total, for bar scaling | reads the one surface |
| `normalize_data_for_output` :: `$log_stats{$bucket}{$scaled_key} = ( defined $log_stats{$bucket}{$key} && defined $max_total{$key} && $max_total{$key} != 0 ) ? int(( $log_stats{$bucket}{$key} / $max_total{$key} ) * $col_width ) : 0;` (and its `-HL` twin) | scaled bar length, read by column id | reads the one surface |
| `print_bar_graph` :: `$trend_value = " " . format_duration_total( $log_stats{$bucket}{$key}, $time_format, $time_space );` | the timeline's nice duration cell, rendered at emit by column width | unchanged rendering; reads the one surface |
| `print_bar_graph` :: `(defined $log_stats{$bucket}{$key} ? ltrim(format_duration_total($log_stats{$bucket}{$key}, 'medium', ' ')) : undef),` and `format_csv_value( $log_stats{$bucket}{$key}, 'duration' );` | STATS CSV nice and raw cells | unchanged rendering; read the one surface |
| `write_aggregate_export` :: `$block->{sum}         = aggregate_number($stats->{duration});` (with `$stats` the bucket's `%log_stats` entry) | the aggregate export's per-bucket sum | reads the one surface |

What remains: one name for a bucket's total and one for its highlighted share,
from the first line to the last reader. Before the change: two names for each,
a copy between them, and a seeded field nobody reads.

**Proposed** (the choice of the surviving name, made in the drop and held to
its byte-identity proof): three things fix it. Every reader that works across
metrics keys the statistics store by the column id (`duration`, with `-HL` for
the highlighted share), a convention bytes and count share. `calculate_statistics`
reads `total_duration` from its input hash on both stores. `calculate_statistics_bin`
reads `total_duration` directly off whichever entry it is given, a message
entry or the bucket accumulator. The proposal is that the bucket store takes
the column id from the read loop on, the staging line keeps filling the
statistics input's `total_duration`, and the bin sub's bucket-path read of the
mean's numerator comes from that staged input, so neither statistics sub needs
two names. The message store's field keeps `total_duration` (D3, D8).

### The two emit sites

Both in `print_message_summary`, both calling `format_duration_total` (§ 3
item 4), both rendering only when their write happens:

- **The messages-table cell** (`print_message_summary` ::
  `sprintf( "%$col_width{7}s", defined $total_duration ? $total_duration : "" )`,
  the `Duration` column of the statistics variant). It renders the number at the
  medium tier with a space, the arguments the statistics phase uses today, so
  the string is unchanged. The tier stays `medium`: choosing a tier by the
  column width is #617's change at this site (its D18).
- **The MESSAGES CSV `duration_nice` cell** (`print_message_summary` :: the
  `$total_duration,` slot directly after
  `format_csv_value($total_duration_num,'duration'),` in the MESSAGES row).
  It renders the same number with the same arguments, once, as the row is
  built for `$csv->print`; the `duration` cell beside it is the same number
  through `format_csv_value`, the retained raw value. It keeps a fixed budget
  under #617.

**Proposed:** each site makes its own call, guarded by the condition that
writes it (the statistics-variant row for the table, `$write_messages_to_csv`
for the CSV), and a row with no total renders an empty cell at both sites, as
today.

### What changes on each user surface

| Surface | Change |
|---|---|
| Options, `--help` rows, `docs/usage.md` rows | none |
| Notices, deprecations | none |
| Messages table total (`Duration` column) | none; same formatter, same tier, same spacing |
| MESSAGES CSV `duration` | none on any path; under `-od` it stays empty (today because the sibling never accumulates; after, because the unobserved total is absent) |
| MESSAGES CSV `duration_nice` | none on the default, consolidation, bin data model and `-cp` paths; under `-od` it becomes empty where it reads `0` today (D7) |
| STATS CSV, timeline, heatmap, histogram, aggregate export | none; none reads the message total, and the bucket total they read is converged without a change in value (D9) |
| `--explain` mean text and `docs/explain/statistics.md` (`total_duration / count` per time bucket) | none; the text is a formula in words, not a field reference |
| Run index (`ltl-index.csv`) | none; it reads its own per-file accumulators (§ 3 item 12) |
| `-so duration` / `-so time` | same ranking; the comparator reads the one field |
| `-V` sections | no section, key or format changes; the `MEMORY log_messages` value of `-V benchmark-data` is expected to fall by one field per message key that saw a duration |

### Boundaries with the neighbouring issues

- **#616 (one gated derivation of means and totals).** This issue owns the
  **representation** of the message total (one precise field, rendered at
  emit). #616 owns **when** a total is shown (the unconditional per-message
  duration count and the count gate, its locks 1 and 4) and the per-message
  bytes mean (its lock 6, which applies this issue's pattern). This issue lands
  first and gates the unobserved total on the existing observation decision in
  `calculate_all_statistics` (the durations list or the bin-mode observation
  counter), extended to `-od` (D7). #616 then replaces that decision with its
  count at the one site and inherits the `-od` scenario (its D19 and D21).
  Where #616 reads a bucket's total, it reads the bucket store's converged
  surface (D9).
- **#617 (one width-to-format rule).** Walks the messages-table cell by the
  column's width at the emit site this issue creates; the CSV `duration_nice`
  cell keeps a fixed budget (its D18).
- **#618 (one declaration per CSV column).** Declares `duration` as the number
  through `format_csv_value` and `duration_nice` as the number through the
  totals formatter, both reading the one field this issue leaves.

### The pattern entry

`docs/architecture-patterns.md` has no entry for storing values precise and
formatting them at the output boundary, and no feature doc owns the contract
(§ 3 items 3 and 8). This issue adds the entry *Precise storage, formatting at
the output boundary*: a value in a data store keeps the type and precision the
computation produced for its whole life; rounding and unit formatting happen
only where the value leaves the tool, per surface, once per write, and the
result is never stored. Reasoning from measured cases: the integer-truncated
mean behind #271 made the emitted standard deviation 15.664 against the
reference implementation's 12.495 on a 155,109-sample access-log message;
storage-time rounding behind #268 hid any drift below display precision from
the statistics harness; the formatted total here left no tier to a renderer.
Consumption sites after this issue, each cited in the entry as sub plus
snippet: `calculate_statistics` ::
`my $mean = $bucket_data->{total_duration} / $duration_count;` (the precise
mean); `print_bar_graph` ::
`ltrim(format_duration_total($log_stats{$bucket}{$key}, 'medium', ' '))` (the
STATS nice cell); `print_message_summary` ::
`my $total_bytes = defined $total_bytes_num ? format_bytes( $total_bytes_num,'B' ) : undef;`
(the bytes pair) and the duration pair's two emit-site calls;
`format_csv_value` at every CSV emit. Owning record: this document, with #268's completion record. Status: established;
#616 adds the per-message bytes mean as a site, and its own entry (observation
counts and gated means) cross-references this one.

---

## Acceptance criteria

Triaged per `docs/test-driven-development.md`. Derived from D3 to D9 and the
issue body.

**Assertable**

- [x] **1. The accumulator never changes type; one precise field (D3, D8).**
      Given the change, `ltl` holds no field named `total_duration_num`, and
      every write to a message entry's `total_duration` is arithmetic (the lazy
      initialiser, the per-line accumulation, the consolidation seed, merge and
      copy) or its removal when unobserved; no formatter's result is assigned
      into any data store.
      *Method: a source check in the PR: `grep -F 'total_duration_num' ltl`
      returns nothing, and the writes of `{total_duration}` are listed by sub
      against the message-store table of § 5; a formatter result assigned into
      `%log_messages`, `%log_stats`, `%log_analysis`, `%heatmap_data` or
      `%log_occurrences` is a failure (the search of § 3 item 10 finds none).*
- [x] **2. Converged readers (D5).** `print_message_summary` reads the total
      once into one local; the sort key names `total_duration`; the total is
      rendered nice only by the two `format_duration_total` calls at the emit
      sites, and the CSV `duration` cell passes it through `format_csv_value`.
      *Method: a source check in the PR against the message-store table of
      § 5; each row's "after" column is found as written.*
- [x] **3. The nice rendering at the write, raw value beside it (D4).** The
      MESSAGES `duration_nice` cell is rendered from the stored number by
      `format_duration_total` in the row being written, and the `duration` cell
      beside it is the same number through `format_csv_value`; the
      messages-table cell is rendered by the same formatter at its own emit
      site. A zero renders in the source unit.
      *Method: the diff shows both `print_message_summary` sites calling the
      totals formatter; criterion 5 proves the strings unchanged; the sort
      scenario of criterion 4 also asserts that each row whose `duration` is
      `0` carries `duration_nice` = `0 msec` (the source unit), which a direct
      call of the ladder scaler would fail.*
- [x] **4. `-so duration` ranks by the stored total.** With `-so duration`, the
      MESSAGES rows are in non-increasing order of `duration`.
      *Method: a new `tests/validate-csv-output.sh` scenario on the twelve-line
      synthetic access log with millisecond durations, one request per
      endpoint (`tests/fixtures/tomcat-access-single-sample-keys.txt`: totals
      from 1,000 ms down to four zeros), `-bs 1440 -oe -ni -n 12 -so duration`,
      with two opt-in per-scenario checks added to
      `tests/csv-output/validate-csv-output.pl`: the ordering check (MESSAGES
      rows non-increasing on a named column) and the zero-cell check (each row
      whose `duration` is `0` carries the scenario's declared `duration_nice`,
      here `0 msec`), each declaring `asserts`, `produced_by` and `contract`,
      declared as the directives `@non_increasing` and `@zero_duration_nice`
      in the scenario's expected-categories file beside `@no_highlight_rows`.
      No harness runs `-so duration` today; a sort key naming a missing field
      ranks every key at zero and passes every existing assertion, which is
      the failure the scenario is shown to catch. The
      scenario does not declare the duration family active: on this fixture the
      base leaves `impact` empty on the four zero-total rows beside a populated
      total, which the family-consistency check would report; that gate is
      #616's (the impact gate, audit finding F4.6), not this issue's.*
- [x] **5. Output byte-identical elsewhere.** The messages table, the MESSAGES
      CSV `duration` and `duration_nice` cells, and every other output are
      byte-identical to the base on the raw and bin data models, with and
      without consolidation, and at `-cp full`; the run index's duration
      columns are unchanged.
      *Method: `tests/validate-regression.sh` passes with no reference
      re-captured; `tests/validate-statistics.sh` passes against its unchanged
      baselines, whose default, consolidated, bin data model, bin-consolidated
      and sorted scenarios over four log families carry both cells;
      `tests/validate-csv-output.sh` passes its existing scenarios;
      `tests/validate-index-read-back.sh` passes unchanged.*
- [x] **6. An unobserved total is empty in both cells under `-od` (D7).** Under
      `-od -o`, every MESSAGES row has every duration column, `duration_nice`
      and `impact` empty.
      *Method: a new `tests/validate-csv-output.sh` scenario on the same
      twelve-line fixture, `-bs 1440 -oe -ni -n 12 -od`, declaring the duration
      family switched off (`-duration` in its families column). Declaring the
      family active, as first specified, does not work: the declaration binds
      both CSVs, and under `-od` the STATS CSV leaves its duration columns out,
      which the validator reports as missing. The harness therefore learns the
      switched-off state `-od` creates: every column the rules make
      `conditional:duration` (the duration statistics, percentiles, dispersion,
      shape, the total, its nice twin and impact) is absent from the STATS
      header and empty in every MESSAGES row. It fails on the base
      (`duration_nice` = `0` on all twelve rows) and passes after; the STATS
      absence check is shown to fail on a STATS CSV that carries the columns.
      Architect's direction 2026-09-29.*
- [x] **7. No nice formatting per line; cost measured (D6).** The per-line path
      of `read_and_process_logs` carries only numeric accumulation of the
      total: no display formatter is reachable per line. The before/after
      benchmark shows no metric worse by more than 1 percent across repeated
      runs, and `MEMORY log_messages` no higher than the base.
      *Method: a source check in the PR covering `read_and_process_logs` and
      every sub it calls inside the per-line loop: a display formatter
      reachable per line is a failure. The one formatting callee,
      `progress_line_text`, is reached only through the repaint gate
      (`if ($total_lines_read % PROGRESS_LINE_STRIDE == 0 && !$disable_progress) {`),
      not per line. Then `tests/baseline/run-benchmark.sh
      single-day-access-log-standard` before and after, and
      `compare-results.sh summary`.*
- [x] **8. The bucket total on one surface, output unchanged (D5, D9).** Given
      the bucket-store drop, a bucket's total and its highlighted share are
      each held under one name from the read loop to the last reader: no site
      copies them under a second name, and the staged statistics input seeds no
      highlighted total that nothing reads. Every output is byte-identical to
      the commit before the drop.
      *Method: a source check in the drop's commit against the bucket-store
      table of § 5, each row's "after" column found as written. Then, on the
      drop's commit and alone, before the next change:
      `tests/validate-regression.sh` passes with no reference re-captured and
      `tests/validate-statistics.sh` passes against its unchanged baselines,
      which include the STATS CSV of each scenario, where every bucket row
      carries the bucket total's raw and nice cells. This is the drop's own
      behaviour-neutral proof, separate from criterion 5's for the message
      store.*

**Visual**

- [x] **9. The messages-table total reads as before.** On a real web-server
      access log carrying millisecond durations, with `-n 12 -so duration`
      (statistics variant on), the messages table's `Duration` column is looked
      at on the base and on the change: every total, zero totals included,
      reads identically in the source unit, with the same alignment.
      *Method: both renders captured to the scratchpad and looked at side by
      side before the PR; criterion 5's byte-identity is the machine check.*

**Unassertable**

None. The property the issue guards (a future reader never gets a string where
it expects a number) is now a stated invariant (D3), checked in the code by
criterion 1 and carried forward by the pattern entry.

**Unknown**

None. No prototyping scope.

---

## Verification surface

| Surface | Read or changed | Why the documented contract supports the value |
|---|---|---|
| `-V` sections | none read by a new assertion, none changed | no key, header or format moves |
| `-V benchmark-data` `MEMORY log_messages` | read by the benchmark only | a value, not a key; expected lower |
| `tests/validate-csv-output.sh` | two scenarios added (criteria 4 and 6); two opt-in directives (ordering, zero cell) and the switched-off family declaration added to `tests/csv-output/validate-csv-output.pl`, documented in `tests/csv-output/README.md` | the rules TSV types `duration_nice` as a unit-bearing string conditional on durations; a switched-off family's columns are absent where dynamic and empty where fixed |
| `tests/validate-statistics.sh` | no baseline moves | output is byte-identical |
| `tests/validate-regression.sh` | no reference moves | output is byte-identical |
| `tests/validate-index-read-back.sh` | unchanged, run in the gate | the index reads its own per-file accumulators (§ 3 item 12) |
| Every other harness | unchanged | none reads the stored field or the `-od` MESSAGES row |

**Fixtures.** No new fixture. Both scenarios use the committed twelve-line
synthetic access log with millisecond durations and bytes, one request per
endpoint, four of them with a zero duration
(`tests/fixtures/tomcat-access-single-sample-keys.txt`, already read by
`tests/validate-statistics-demand.sh`): the smallest input that carries
distinct totals, zero totals and every key in one row each. `-bs 1440 -oe -ni`
because the assertions read the MESSAGES CSV only; `-n 12` so every key is a
row.

Each new scenario lists under `--list`, runs alone under `--scenario`, carries
`asserts`, `produced_by` (by function name) and `contract`, includes the
runtime-warning check, and is shown to fail on the base before the change is
applied. Any `ltl` output a check writes into the worktree is deleted by the
run that made it.

---

## Completion gate

Run 2026-09-29 on 49d3e09 (`$version_number` restored to `0.19.0`), on the
architect's development machine.

**Harness suite.** All 43 `tests/validate-*.sh` exit 0, run with `CI=1`,
`validate-csv-output.sh` first and `validate-statistics.sh` second; every
summary reports assertions run, no FAIL line, no runtime warning. Among them:
CSV output 25 scenarios, statistics drift 22 scenarios, regression 74,
aggregate export 146, index read-back all passing, statistics demand 102.

**Benchmark.** `single-day-access-log-standard` (the 761,698-line Tomcat 9
access log with millisecond durations), three runs each, interleaved; the
before runs on the base `ltl` (identical in `release/0.19.0` at 977e017 and
at the specification commit), the after runs on 49d3e09. Medians with ranges:

| Metric | Before | After | Change |
|---|---|---|---|
| `TIMING parse/read_files` | 9.05 s [8.98–9.39] | 8.95 s [8.80–9.12] | −1.1% |
| `TIMING finalize/calculate_statistics` | 104 ms [101–117] | 102 ms [99–103] | −1.9% |
| `TIMING total` | 9.18 s [9.10–9.51] | 9.06 s [8.92–9.23] | −1.3% |
| `MEMORY log_messages` | 28.17 MB [28.17–28.18] | 28.03 MB [28.02–28.03] | −0.52% |
| `MEMORY log_stats` | 28,220 B | 28,230 B | +0.03% |
| `MEMORY rss_peak` | 104.2 MB [104.1–104.5] | 104.3 MB [104.1–104.4] | +0.16% |

No metric is worse by more than 1 percent. The message store falls by one
numeric field per message key that saw a duration, as § Measurement
obligations expected. The read loop is no slower: the ranges overlap and the
medians favour the change, consistent with one hash update per timed line
removed. `compare-results.sh summary` on the first pair alone reports
`rss_peak` +0.3% (+320 KB) as a regression; over three runs the medians
differ by 0.16% with overlapping ranges, and the only store the change
touches got smaller, so it is run-to-run variation of the process peak, not
an effect of the change. `log_stats` grows by 10 bytes, the
longer `duration_sum` key.

---

## Measurement obligations

- **Before/after benchmark: yes (D6).** The diff touches executable lines of
  `ltl`, one of them a statement executed on every line with a duration in
  `read_and_process_logs` (the scope table in `docs/process/workflow.md` § 3,
  first row). The `before` TSV is captured on the base commit before the first
  line of code; the `after` on the gate commit, on this machine, same case
  (`single-day-access-log-standard`), same session. Expected: no slower,
  message-store memory lower, since one hash update per timed line and one
  field per timed key go.
- **Prototype: none (proposed).** The change removes one redundant accumulation
  and one redundant field and moves one formatter call from the per-key
  statistics loop to the per-row emit; it adds no data model, no code path and
  no capability. Under `prototype/README.md` and `docs/process/workflow.md`
  § 2 step 2 a smaller hot-path change is evidenced by the benchmark alone.

---

## Delivery

Two drops, each a commit and a push on the issue branch, then one PR against
`release/0.19.0`:

1. **The message store.** The two new `tests/validate-csv-output.sh` scenarios
   and the validator's ordering and zero-cell checks: the `-od` scenario is
   shown to fail on the base; the sort scenario passes on the base and is shown
   to fail on a build whose sort key names a field that does not exist. Then
   the message-store change of § 5, the pattern entry, and the record updates
   below. Criteria 1 to 6.
2. **The time-bucket store (D9).** The bucket-store convergence of § 5, alone
   in its commit, with its own behaviour-neutral proof: the regression goldens
   and the statistics drift harness pass unchanged on that commit (criterion
   8).
3. The completion gate on the commit being merged: the full harness suite
   (`CI=1` `validate-csv-output.sh`, then `validate-statistics.sh`, then the
   rest) and the before/after benchmark, with `$version_number` restored to
   `0.19.0` first. The benchmark covers both drops, since each touches a
   per-line statement (criterion 7).

---

## Records updated with this document

| Record | Update |
|---|---|
| Issue #273 | a comment pointing at this document for the 2026-09-29 locks (D3 to D9) and the ordering with #618 |
| Native edge #618 blocked by #273 | added when this document is committed, with a comment on #618 (one declaration per CSV column) saying in plain words why: its `duration_nice` accessor reads the one precise field this issue leaves, instead of a stored string beside a second numeric field |
| Issue #616 | a comment stating the 2026-09-29 locks it lands after: it gates the one unobserved-total site this issue leaves, inherits the `-od` scenario, and reads the bucket store's converged surface |

## Records to update at delivery

| Record | Update |
|---|---|
| `docs/architecture-patterns.md` | the new entry *Precise storage, formatting at the output boundary* (§ 5), in the same commit as the code |
| `features/fuzzy-message-consolidation.md` | the IQ-08 merge-field table and the PF-25 and IQ-03 lines drop `total_duration_num`; the "overwritten with formatted string" note goes |
| `features/426-per-message-statistics-store.md` | the aggregates field class drops `total_duration_num`; the dual-typed note and the related-issues line for this issue state the landed shape. Its mini-store prototypes mirror the read loop with the sibling, so a resumed #426 (per-message statistics store) re-slices its baseline arm from the current loop |
| `features/342-redundant-logic-surfaces-audit-report.md` and the records of shipped work that name the sibling as it was (`features/303-calculated-statistic-sort-path.md`, `features/561-retained-durations-as-numbers.md`, `features/528-record-lexical-retained-representation.md`, `features/137-final-pass-redesign.md`) | not edited; § 3 items 3 and 8 here carry the corrections |
| `features/616-gated-mean-derivation.md` (on #616's branch) | none: it already cites #268's completion record and this document as the storage-stays-precise contract, and its § 5.4 records the empty `impact` on this issue's four zero-total rows as its impact gate's change. #616's issue body still links `features/561-retained-durations-as-numbers.md`; a comment on #616 points at its feature doc for the corrected citation |
| `docs/usage.md`, `--help` | none |
| Release notes | one bullet (D7): "Leave the MESSAGES CSV `duration_nice` cell empty under `-od/--omit-durations` (#273)." |
