# One gated derivation of means and totals over accumulators that always carry an observation count (Issue #616)

## Status

**Specification agreed with the architect 2026-09-28 on branch
`616-gated-mean-derivation` off `release/0.19.0`; implementation started
2026-09-30.** The specification was written at `58f8d94`. Implementation starts
from `release/0.19.0` at `a32eb32`, after #273 (store the duration total precise,
format at the output boundary) and #608 (one byte ladder) merged, so D19's
landing order holds and no blocking edge remains. On that commit every site of
section 5.1 was re-resolved inside its sub (section 3, *Re-audit at the start of
implementation*), the version is stamped `0.19.0-616`, and the `before`
benchmarks of section 8 are captured (`616-before`, `616-before-bin`). The D12
prototype ran before drop 1 (section 8, *Prototype findings*), and the arm that
lands is locked (D28). All seven drops have landed (section 11) and the
completion gate passed on 2026-10-01 (section 11, *Completion gate*).

This issue is one of the refactoring issues the #342 review (the audit of
redundant logic surfaces across `ltl`) dispatched under #622 (the parent
refactoring issue). Its findings are recorded in
`features/342-redundant-logic-surfaces-audit-report.md` § Item 4 (aggregation
and statistics gating), § Item 8 (the per-line loop) and § Item 2 (unit and
value formatting). This document owns the specification, the acceptance
criteria and, later, the implementation record.

It is blocked by #608 (one byte ladder and output notation: the regression
goldens are re-blessed in sequence, #608's first) and by #273 (store precise,
format at the output boundary: it lands first and hands this issue its `-od`
scenario, D19). It blocks #514 (count metric capture made explicit and off by
default), #426 (the per-message statistics store's representation), #469
(consolidated message histograms on a shared bucket grid), #620 (hoisting the
read loop's per-line option handling in measured steps) and #619 (one per-run
key cut, which lands third, D19).

---

## 1. The motivating consumer

Two readers, one of each kind.

**The analyst reading a column.** A STATS CSV cell, a timeline cell or a YAML
export block that says `0` has to mean "these lines added up to zero". Today it
can also mean "no line in this bucket carried the metric", and the reader cannot
tell the two apart. The same analyst ranks messages with `-so impact` and sees a
consolidated row ranked as if its requests took half as long as that row's own
mean column says, and a row whose impact changes when two of its lines swap
places. They compare the MESSAGES CSV with the STATS CSV and find two integers
for one mean of the same two lines. They compare the index file with the STATS
CSV for the same file and find two precisions and two bytes means. Each is a
value the tool computed twice and printed differently.

**The next developer who touches an accumulator.** #514 (count metric explicit)
and #426 (per-message store representation) each rewrite every read of a sum
and a count. Today that means finding eleven inline derivations with three gate
shapes, two statistics subs that restate the same formulas over two store
shapes, and a running-mean update written three times in two formulas. With one
gated helper, one statistics sub and one update formula, each of those issues
retargets one site per quantity, and the rule in CLAUDE.md (every accumulator
tracks an observation count; derived output is gated on `count > 0`) is
something the code holds by construction rather than something each site has
to remember.

The change is user-observable (section 5.3 lists every surface). Nothing is
added to the command line.

---

## 2. Requirement

In the architect's terms, transcribed from the issue body, the review-progress
rows of the audit report (stages 1 (the confirmed bugs), 6 (mean and ratio
derivation with observation-count gating), 10 (the run index) and 14 (raw and
bin statistics), all 2026-09-27) and his replies of 2026-09-28 to this
specification's draft and to the review's follow-up questions, organised but
not reinterpreted.

**The rule.** A mean, a ratio or a total is derived once, from an accumulator
that always knows how many observations it holds, and is shown only when it has
one.

**What is wrong today** (the issue body, each measured in the audit):

- A bucket whose only line carries bytes and no duration writes
  `duration_nice=0 msec`, `duration=0` and an empty `duration_mean` to the STATS
  CSV, and the timeline shows `0 milliseconds`; the twin with `-` for bytes
  writes `bytes_nice=0 B`, `bytes=0` and an empty `bytes_occurrences`.
- Impact ranks a consolidated row from a mean of 100 while the row reports a
  mean of 200: impact divides the duration total by every matched line, the
  reported mean by the lines carrying a duration.
- The per-message bytes mean is rounded half up before the CSV writer (`513`)
  while the STATS CSV rounds half to even (`512`) for the same two lines.
- The bytes count increments only when the aggregate family is demanded; the
  total accumulates on every line. The per-message duration count exists only
  when per-message statistics are demanded.
- The per-bucket user-defined mean is computed twice; the count mean has three
  gate shapes across four copies; a self-assignment does nothing; a diagnostic
  substitutes 1 for a zero divisor and prints a reduction of 100 percent on a
  run with no keys (section 3 item 4 finds this cannot occur).

**What is locked** (section 4 restates each): D1 to D10 of 2026-09-27
(unconditional observation counts, the message store behind its `-n 0` gate,
one gated mean helper, output gated on the count, impact from the reported mean,
the bytes mean stored precise, the diagnostic gated, the index means through the
helper at a fixed precision, one statistics sub, one Welford update) and D11 to
D26 of 2026-09-28 (impact derived once after the read loop and reducing to its
occurrences part when there is no duration mean; one update formula chosen by
measurement; the bin-model benchmark pair; each model unchanged against its own
baseline, with the bin model officially supported; the index's empty cell, its
two-decimal precision and its bytes population; one duration count in both
models; the landing order; impact's duration term floored so it is never
negative; impact undefined when durations are thrown away; no count on the
highlighted totals; the latency section a fixed-size block; the heatmap's bytes
pre-seed corrected; an impact topic in `--explain`; the consolidation final
pass as designed) and D27 of 2026-09-29 (impact exempt from the CSV harness's
per-row family check and required on every row whenever durations are read).

**Done when** (the issue body): the two fixtures write empty cells where nothing
was observed; impact and the reported mean agree on every row; the two CSVs
print one value for one mean; a count is present wherever a total is; the raw
and bin paths give identical statistics through the one sub (the drift engine
holds them equal); the per-line cost of the unconditional counts and of the
shared Welford update is measured before and after on the standard benchmark and
reported; the full harness suite passes. The drift-engine clause reads as each
model unchanged against its own baseline (D14), and the benchmark clause is met
by the two pairs of section 8 (D13).

---

## 3. Corrections to the issue body and the audit record

Every sub and snippet the issue and the audit cite was located in the current
`ltl` with `grep -F` inside its enclosing sub, and the confirmation runs were
repeated on the base commit. Captures are in the session scratchpad
(`622/616/runs/`, `616/preseed/`); every run passed `--disable-progress`, and
`-ni` and `-o` unless the index was the subject.

**All cited sites resolve.** Every snippet of § Item 4 and of the audit's
finding that the Welford update is written three times resolves inside the sub
the audit names, and the ones the audit records as copies resolve as often as it
says: four store constructors, two bytes-count increments, two loop updates, two
reduction lines.

**Confirmed as recorded.**

| Observation | Input and options | Result on the base commit |
|---|---|---|
| Zero projected for an unobserved duration | application log, two lines a minute apart, the second carrying `bytes=60` and no duration; `-bs 1 -o -n 5` | second bucket: `duration=0`, `duration_nice=0 msec`, `duration_mean` empty. The first bucket also writes `bytes=0`, `bytes_nice=0 B` with `bytes_occurrences` empty: the same fixture shows both twins |
| Zero projected for unobserved bytes | access log, one path, two lines a minute apart, the second with `-` for its size; same options | second bucket: `bytes=0`, `bytes_nice=0 B`, `bytes_occurrences` empty |
| A line with no metric at all | application log, the second line carrying nothing | both cells empty (the bucket never reaches the store constructor) |
| Two roundings of one mean | access log, one path, sizes 512 and 513 in one minute | MESSAGES `bytes_mean=513`, STATS `bytes_mean=512` |
| Index precision outside `-cp` | the committed twelve-line access fixture with single-sample keys, `-o -cp 0 -bs 1440` | index `duration_mean=128.75`, STATS `duration_mean=129` |

The existing group-consistency assertion of `tests/validate-csv-output.sh`
("if any column in a family is populated, all conditional columns in that family
must be populated in the same row") fails on both zero-projection fixtures today:
`populated=[bytes,bytes_nice] empty=[bytes_min,bytes_mean,bytes_max]`, and the
same for the duration family. No corpus scenario of that harness reaches the
case, which is why it has never fired. The new scenarios of section 6 make it
fire, and fire for the right reason: a total projected as zero beside an empty
mean is exactly the defect of D4 (output gated on the count). They fail on the
base commit and pass once the projection is gated.

**Corrected.**

1. **The impact fixture reproduces at `-g 50`, not `-g 60`.** On four
   application-log lines `Processing request <uuid> done`, two with
   `durationMS=100` and `durationMS=300` and two with none, `-g 50 -so impact`
   gives one row with `occurrences=4`, `duration=400`, `duration_mean=200`,
   `impact=33.622`, as the audit recorded. At `-g 60` the four rows stay
   separate. With `-m uuid` added, `-g 60` gives two rows, because the message
   key carries `durationMS=?` and so separates lines with and without a duration;
   the duration-bearing row reads `impact=37.781`, which agrees with its own mean.
   On these log families an unconsolidated key never mixes lines with and without
   a duration: the application log's key carries the duration key, `-d durationMS`
   discards the duration together with the key, and the access formats do not
   match a line whose duration field is `-`. The divisor defect is reached
   through consolidation.
2. **A second impact defect, not in the audit: impact depends on line order.**
   The read loop updates impact only under `if( $duration > 0 ) {`, while
   `occurrences` counts every line, so a key whose last lines carry a zero
   duration keeps an impact computed from an earlier, smaller occurrence count.
   Two access-log lines of one path, durations 100 and 0: in that order
   `impact=32.236`; reversed, `impact=28.077`. The row reports
   `duration_mean=50` and `occurrences=2` either way, and `log(50^7 × 2)` is
   28.077. The committed statistics-drift baselines hold 45 impact cells that
   differ from `log(duration_mean^7 × occurrences)`, all on the seven scenarios
   over a day of web-application access log in which a quarter of the lines
   carry a zero duration, each by less than 0.1 percent. Two further cells, on
   the two consolidated scenarios over a web-server access log, are empty beside
   `duration_mean=0` and `occurrences=1`. D11 (impact derived once after the
   read loop) removes both. The same baselines also hold 122 impact cells, on
   eight scenarios, whose mean is above zero and below one unit; each is below
   `log(occurrences)` because its duration term is negative, and 38 of them are
   among the 45 above. D20 (the duration term floored) moves all 122 to
   `log(occurrences)`: 129 cells move in all, besides the two empty ones.
3. **The per-message duration count already exists whenever a message accrues a
   duration.** `adapt_to_command_line_options` resolves
   `$message_duration_stats_demand = ( !$omit_durations && $capture_messages ) ? 1 : 0;`,
   and per-message durations accrue only under the same two conditions, so the
   raw model's retained array (or the bin model's `duration_count`) is present on
   every entry that has a duration. The fallback in `calculate_all_statistics`
   `$duration_observed ||= ( ($log_messages{$category}{$log_key}{total_duration} // 0) > 0 );`
   is unreachable. The counts that really are conditional today are the
   bucket store's duration count (bin model only; the raw model's array length
   exists only under the bucket demand, which is off under `-hm` or `-hst` without
   `-o`) and `bytes_occurrences` on both stores (off without `-o` or a
   bytes-family sort).
4. **The substitute divisor in the consolidation diagnostic cannot fire.** The
   per-group block in `pipeline_finalize` starts with
   `next unless $keys_seen > 0;`, so `($keys_seen || 1)` never substitutes, and
   the match rate's `($s->{s3_calls} // 1)` sits inside a `> 0` test. "A run
   with no keys prints a reduction of 100 percent" does not occur. D7 (the
   diagnostic gates like its neighbours) is a change of shape with no observable
   effect.
5. **Four self-assignments, not one.** The group calculation in
   `calculate_all_statistics` assigns `count_occurrences`, `count_min`,
   `count_max` and `count_sum` to themselves; the `count_mean` line between them
   is the real derivation. `features/426-per-message-statistics-store.md`
   § Findings (the eleventh finding, dead code adjacent to the store) already
   records all four.
6. **The statistics harness does not compare the raw and bin models with each
   other.** `tests/validate-statistics.sh` holds each scenario to its own
   committed baseline (its L1 layer) and to a NumPy/SciPy oracle (its L3 layer).
   The two models agree through the oracle, not through a direct comparison, and
   their shape moments differ by construction: a two-pass sum over the sorted
   samples against a running update
   (`features/287-message-stats-bin-counter-data-model.md` records the rounding
   difference). D14 locks the proof that one statistics sub changes nothing as
   each model's output unchanged against its own baseline.
7. **The index's means are not read back by the tool.** `read_index_file`
   pre-seeds from the bounds (`duration_min`, `duration_max`, the bytes and count
   pairs, the first and last timestamps) and `detect_index_drift` compares the
   same bounds. The means are written for a reader outside the tool. D8's fixed
   precision still stands on its own reason: the index is a durable file kept
   across runs and compared across them, so a per-run option must not change
   what it holds for the same file.
8. **The index counts bytes only above zero; both stores count a zero-byte
   response.** The index blocks in `read_and_process_logs` gate on
   `if (defined $bytes && $bytes > 0) {` (once for the file row, once for the
   selection row). On the committed twelve-line access fixture the index holds
   11 bytes observations and mean `20381.82`; the STATS CSV holds 12 and mean
   `18683`. D17 aligns the index with the stores.
9. **The index record is out of date and states a reason for `-`.**
   `features/index-file.md` documents the column names before
   `features/432-metric-aggregate-naming-parity.md` D7 (the index follows the
   metric-first naming convention) renamed them, and says "Empty or
   not-applicable fields use `-` as placeholder to ensure correct column
   alignment when viewed with tools like `column -s, -t`". The reason holds:
   macOS `column -s, -t` collapses an empty field, so a row `a,,c` prints as
   `a c` under the wrong header. D15 rewrites the sentence.
10. **The YAML aggregate export is a third surface of the zero projection.**
    `write_aggregate_export` writes `duration: {data_model: raw, sum: 0}` and
    `bytes: {sum: 0}` for the unobserved buckets above.
    `features/503-yaml-aggregate-export.md` § Conventions says "absent means not
    produced, not observed, or not eligible, never `null` or `0`", so the export's
    own contract supports removing them.
11. **The standard benchmark never runs the Welford update.** Both statistics
    stores default to the raw model, and no scenario of
    `tests/baseline/run-benchmark.sh` passes `-mdm`, `-bdm` or `-dm`, so the
    update that D10 (one Welford update) asks to be measured "under this issue's
    benchmark" is not executed by it. D13 adds the bin-model pair.
12. **The CSV rules type the two bytes means differently.**
    `tests/csv-output/rules/messages-columns.tsv` types MESSAGES `bytes_mean` as
    `int` with 0 decimals; `stats-columns.tsv` types STATS `bytes_mean` as
    `float` with 5.
13. **The CSV rules put `impact` in the duration family.** The MESSAGES rules
    row for `impact` is `conditional:duration`, family `duration`, and it
    stays in that family (D21: impact is defined only while durations are
    read). The group-consistency assertion of
    `tests/csv-output/validate-csv-output.pl` holds every conditional column of
    an active family populated or empty together on each row. Under D11 (impact
    reduces to its occurrences part) a row whose duration is unobserved while
    durations are read carries impact beside empty duration columns, which that
    assertion would read as a failure. D27 exempts impact from the per-row
    all-or-nothing check and gives it its own presence rule: populated on every
    row whenever durations are read, empty on every row when they are thrown
    away by `-od` or `-d duration` (section 5.2 under D11, section 7).
14. **The heatmap's bytes pre-seed never reads the index (pre-existing, found
    while checking D17; corrected in this issue, D24).** `read_index_file`
    looks up `"${hm_metric_col}_min"` with `$hm_metric_col = 'bytes'`, while the
    aggregated bounds are keyed `file_bytes_min` and `file_bytes_max`. Measured
    on a scratch copy of the committed twelve-line access fixture: a first run
    wrote the index; its `duration_max` and `file_bytes_max` were then edited to
    888888 and 999999. `-hm duration -bs 1440 -V index-read-back` reports
    `heatmap_preseed_max: 888888` (the index's value), while `-hm bytes` reports
    `102400` (the live maximum): the bytes arm takes no bound from the index.
    The duration arm already receives a zero minimum from the index today
    (`heatmap_preseed_min: 0` on the same fixture, whose index counts zero
    durations), and both boundary calculations floor the log axis explicitly:
    `my $effective_min = $heatmap_min > 0 ? $heatmap_min : 1;`.
15. **The consolidation final pass carries a lone key into the next level's
    window by design (D26).** #619's record (one per-run key cut; its § 3
    finding on the final pass) measured that the final pass of
    `group_similar_messages` keeps a lone key of one group in the window of the
    next, so two application-log lines with the same thread, logger and body,
    one at ERROR and one at WARN, print under `-g` as one row of 2 occurrences;
    a probe found mixed windows on three of five fixtures. This is the design,
    not a defect: the text of the log message key has no parts that are allowed
    or not allowed to consolidate (D26), and #619's record trues up the
    consolidation record to say so. It decides which lines this issue's consolidated rows hold (the consolidated
    drift scenarios and the `-g 50` impact fixture), not the per-row relations
    the criteria assert: impact is checked against the row's own mean and
    occurrences whatever lines the row holds. The `-g 50` fixture holds one
    level, so it does not reach this behaviour.
16. `docs/explain/statistics.md` lists `impact` under *See also* for the mean,
    and no `impact` topic exists; D25 adds one.

**Re-audit at the start of implementation (2026-09-30, `a32eb32`).** Every
snippet of section 5.1 was searched for with `grep -F` inside the sub its row
names, on the tree implementation starts from.

- All sites resolve, as often as the table says. The one change is #273's
  (store precise): the time-bucket store's duration total is named
  `duration_sum`, in the bucket constructor, in `%log_analysis` and in the
  projected `%log_stats` entry, where the table named it `total_duration` and
  `duration`. The table and section 5.2 are updated to the current names; the
  message store keeps `total_duration`. The design is unchanged.
- The drift-baseline cells section 3 item 2 and section 7 count were recounted
  on the committed baselines of this commit, with the same tolerance (1e-9
  relative, the drift scenarios writing at `-cp full`): 45 impact cells differ
  from `log(duration_mean^7 × occurrences)`, 122 have a mean above zero and below
  one unit, 38 are in both, 129 move in all; 2 impact cells are empty beside
  `duration_mean=0`; 97 per-message `bytes_mean` cells differ from the precise
  `bytes / bytes_occurrences`. All as recorded. One precision on item 2: the 45
  differ by less than 0.1 percent only where the mean is at least one unit
  (largest 0.0004 percent); the 38 with a sub-unit mean differ by up to 3
  percent, and D20 (the floor) moves those to `log(occurrences)` in any case.

---

## 4. Locked decisions

D1 to D10 are the architect's locks of 2026-09-27, restated verbatim from the
issue body with their source in the review-progress rows. D11 to D19 are his
decisions of 2026-09-28, in reply to this specification's draft; D20 to D25 are
his decisions of the same day on the follow-up questions the review of this
specification left open, and D26 his decision of the same day given on #619's
turn (one per-run key cut). D27 is his decision of 2026-09-29 on how the CSV
harness checks impact. D28 is his decision of 2026-09-30 on the D12 prototype's
table, D29 his decision of the same day at the start of drop 2, and D30 his
decision of the same day on drop 2's measured cost. Nothing else in this document is numbered Dxx.

- **D1:** "**Every accumulator keeps its observation count unconditionally**,
  one integer per store entry, for the time-bucket store and the message store
  alike, for duration and for bytes. Where a count exists in one mode it is kept
  and made unconditional, not duplicated. The demand gate governs only the min,
  mean and max." *Locked by the architect 2026-09-27, stage 6 (mean and ratio
  derivation with observation-count gating) of the #342 review; that stage's
  scope carries the impact divisor, folded in from stage 1 (the confirmed
  bugs), as "a per-message count of accrued durations that exists whenever
  impact is computed, and impact read from the one derived mean".*
- **D2:** "**The message store stays behind its existing gate**: under `-n 0`
  (the per-message capture flag,
  `features/458-top-messages-zero-no-per-message-retention.md`) nothing per
  message accumulates, counts included." *Locked 2026-09-27, stage 6 (mean and ratio derivation with observation-count gating).*
- **D3:** "**One helper derives a mean from a sum and a count**, the gate
  inside, called at every site; the per-bucket user-defined mean is derived
  once and its display reads the stored value." *Locked 2026-09-27, stage 6 (mean and ratio derivation with observation-count gating).*
- **D4:** "**Derived output is gated on the count**: a bucket with no
  observation of a metric carries no total and its cell is empty on the STATS
  CSV and the timeline. `defined` over a zero-initialised field is not a gate
  anywhere." *Locked 2026-09-27, stage 6 (mean and ratio derivation with observation-count gating).*
- **D5:** "**Impact reads the same per-message mean the row reports.**"
  *Locked 2026-09-27, stage 6 (mean and ratio derivation with observation-count gating), folded from stage 1 (the confirmed bugs).*
- **D6:** "**The per-message bytes mean is stored precise** and rounded only by
  the CSV formatter (#273's pattern)." #273's pattern is storing a value precise
  and formatting it at the output boundary. *Locked 2026-09-27, stage 6 (mean and ratio derivation with observation-count gating),
  folded from stage 1 (the confirmed bugs).*
- **D7:** "**The consolidation diagnostic gates** on its count like its
  neighbours." *Locked 2026-09-27, stage 6 (mean and ratio derivation with observation-count gating).*
- **D8:** "**The run index's six means** (stage 10, locked 2026-09-27) are
  sites of the helper, and the index keeps a fixed precision outside `-cp`: it
  is a durable file the tool reads back and compares across runs for drift, so a
  per-run option must not change it. Its means are written through the CSV
  formatter at a fixed decimals setting, with the empty cell every other CSV
  surface writes for no data instead of `-`. Today: `-o -cp 0` gives `128.75` in
  the index where the STATS CSV gives `129` for the same file
  (`tests/fixtures/tomcat-access-single-sample-keys.txt`)." *Locked 2026-09-27,
  stage 10 (the run index) of the #342 review. Section 3 item 7 records that only the bounds
  are read back, and why the fixed precision stands.*
- **D9:** "**One statistics sub over both store shapes** (stage 14, locked
  2026-09-27): the raw and bin subs restate the same mean, variance,
  coefficient-of-variation and moment formulas over two store shapes with two
  gate spellings; the drift engine of `tests/validate-statistics.sh` already
  proves them equal on the corpus. One sub takes the count, the sum, the sum of
  squares and the moment sums, the raw and bin paths supply them, and
  percentiles stay per model." *Locked 2026-09-27, stage 14 (raw and bin statistics) of the #342
  review. D14 states how the equality is proved.*
- **D10:** "**One Welford update** (stage 14): the running-mean update is
  written per message and per bucket inside the read loop under bin mode and
  again in the consolidation merge (`merge_bin_state`). One update sub called
  from the two loop sites and the merge; a sub call per line is measured under
  this issue's benchmark, and the loop-hoisting remedies of the audit's item 8
  apply if it costs." *Locked 2026-09-27, stage 14 (raw and bin statistics). D12 states the formula and
  how the arm is chosen.*
- **D11: Impact is derived once, after the read loop, and reduces to its
  occurrences part when there is no duration mean.** Impact is computed from the
  per-message mean the row reports times its occurrences. The per-line update in
  the read loop and the recompute in consolidation go, so impact no longer
  depends on line order, and the drift-baseline cells that carry the order
  dependence are re-blessed. In the architect's words, "if duration is zero or
  undefined impact should be essentially be the occurrences part": the formula
  is written so the duration term contributes nothing when the mean is zero or
  undefined and the occurrences term stands, never an undefined logarithm and,
  while durations are read, never an empty cell. *Locked by the architect
  2026-09-28.* Amended by the architect the same day: the duration term is
  floored so that it is never negative (D20), and when durations are thrown
  away impact is undefined and its cell empty (D21).
- **D12: One Welford update formula, standardised, with parameters where a use
  case really needs them, and its performance measured before the arm is
  fixed.** In the architect's words, adding subroutine calls affects
  performance, so the performance aspect is looked at as part of this decision;
  and the existence of a second formula in the merge is "impetus to investigate
  standardizing on the formula, and perhaps leveraging different parameters
  instead if that is really required to support different use cases". The
  design states one update formula as the target (the parallel combine, of
  which the single-observation update is the one-observation case) and the
  parameters the two loop sites and the merge need. The per-line cost of the
  inline update, the sub call and any parameterised form is measured with the
  interleaved order-balanced driver of the audit's loop measurement, medians
  with ranges, at the bin model. The arm that lands is chosen from that
  measurement and recorded here as a finding with its table. Whether
  non-consolidated bin statistics stay byte-identical is a measured property to
  report, not an assumption. *Locked by the architect 2026-09-28.*
- **D13: The bin-model benchmark pair is the gate instrument for the per-line
  update cost**, on the standard case with the runner's `--options` argument,
  targeting selectively rather than every data-model surface. The architect
  suggested the message statistics only (`-mdm bin`) and asked that the choice
  fit the need. The option string names the selector of each store whose loop
  update site the measurement is for, and the reason is written down (section
  8). *Locked by the architect 2026-09-28.*
- **D14: The raw and bin models are each unchanged against their own
  baseline.** The drop that lands the one statistics sub shows zero drift
  advisories on mean, standard deviation, coefficient of variation and the shape
  statistics for every drift scenario before any baseline is re-blessed, and the
  oracle layer keeps checking both models. The architect noted that the bin
  data model has not been officialised and that doing so here is good: the
  records state the bin model as an officially supported model on both
  statistics stores, with this criterion as its parity proof. *Locked by the
  architect 2026-09-28.*
- **D15: The index's means write the empty cell for no data**, as D8 says; the
  bounds keep `-`; the index record's sentence
  about `-` keeping `column -t` aligned is rewritten to say what the file now
  does. *Locked by the architect 2026-09-28.*
- **D16: The index's fixed precision is two decimals through the CSV
  formatter**, trailing zeros stripped, unaffected by `-cp`. The index
  read-back harness gains a scenario run under `-cp` settings (`full` and a
  decimal count) asserting the index means keep today's two-decimal output
  regardless. *Locked by the architect 2026-09-28.*
- **D17: The index's bytes population is aligned with the stores in this
  issue.** In the architect's words, "we are fixing issues here, not pushing
  them off for later. should be aligning the counting mechanism. in a dataset
  containing zeros and non-zeros, the zeros count as well for the mean
  calculation." The index counts zero-byte responses in its occurrences and
  mean exactly as the two statistics stores do, so the index and the STATS CSV
  agree on the bytes mean for one file. The minimum and maximum follow the
  stores' rule too. The heatmap log-axis pre-seed that reads the index's
  minimum is checked and, if it needs a positive floor, given one explicitly
  rather than through the count. The moved index cells are accepted cost.
  *Locked by the architect 2026-09-28.*
- **D18: One `duration_count` integer in both models**, incremented beside the
  total on every timed line; its per-line cost is reported by the benchmark.
  *Locked by the architect 2026-09-28.*
- **D19: The landing order is #273, then this issue, then #619.** #273 (store
  precise, format at the output boundary) lands first and keeps the
  unobserved-total change with its `-od` scenario. This issue lands second,
  swaps in the count gate, and inherits that scenario as its regression check.
  #619 (one per-run key cut) lands third. Each re-takes its memory baseline on
  the tree it lands on. Native edges: this issue blocked by #273, #619 blocked
  by this issue. The zero-mean impact rule is D11's (the occurrences part), not
  an empty cell; under `-od` impact is undefined (D21). *Locked by the
  architect 2026-09-28.*
- **D20: The duration term of impact is never negative.** In the architect's
  words, "providing duration should cause the impact to be greater than when
  no duration is present." The term is floored: impact is
  `log(max(m, 1)^7 × occurrences)`, with `m` the row's reported mean, so a mean
  below one unit contributes nothing rather than subtracting, and a row with a
  duration ranks at or above a row with the same occurrences and no duration,
  never below. The consequence of the floor: at a mean of one unit or below the
  two rows rank equal; only a mean above one unit ranks a row higher. *Locked
  by the architect 2026-09-28.*
- **D21: When the duration is thrown away, impact is undefined.** In the
  architect's words, "with -od or -d duration, the duration is thrown away, so
  it becomes undefined, and that it is the case for any of its consumers; it's
  not defined." Under `-od` or `-d duration` impact is not derived and its cell
  is empty on every surface. Impact stays in the duration column family; the
  `-od` scenario #273 lands and this issue inherits keeps expecting the impact
  cell empty; the `-od` row of `docs/usage.md` stands. D11's occurrences part
  applies only while durations are read and a row's observed duration is zero
  or unobserved. *Locked by the architect 2026-09-28.*
- **D22: The highlighted totals are not accumulators with counts of their
  own.** In the architect's words, "what you have mentioned here are simply
  selectors which tag a row as being highlighted. The number of occurences for
  a highlighted row then accumulates in the log messages hash. There is no
  notion of counters which tally causality of how rows became highlighted." A
  highlighted row's occurrences accumulate in its message store entry like any
  other, and no count is added to the highlighted totals. *Locked by the
  architect 2026-09-28.*
- **D23: The timeline's latency section is a fixed-size block at the far
  right.** In the architect's words, "the whole table design is built
  backwards from the terminal width, options requested, defaults, data
  present, etc. the latency section is a fixed size which sits at the far
  right. there is no notion of dynamic padding, as all of the columns before
  this one automatically adapt to fill the available space." No padding
  mechanism is added: an empty latency cell for an unobserved bucket occupies
  the block's fixed width like any other cell. *Locked by the architect
  2026-09-28.*
- **D24: The heatmap's bytes pre-seed is corrected in this issue**, under the
  index bytes alignment (D17), with a criterion: `read_index_file` reads
  `file_bytes_min` and `file_bytes_max`, the keys the index writes, where today
  it looks up `bytes_min` and `bytes_max` and finds nothing (section 3 item
  14). *Locked by the architect 2026-09-28.*
- **D25: An `impact` topic is added to `--explain`**, stating the formula, the
  floor (D20), the occurrences-only case (D11) and the undefined case (D21),
  with its row in `docs/usage.md`. *Locked by the architect 2026-09-28.*
- **D26: The consolidation final pass is the design, not a defect.** In the
  architect's words, given on #619's turn: "text contained with the log mesage
  key does not have specific parts which are allowed or not to consolidate". A
  lone key carried into the next level's window, so that an ERROR line and a
  WARN line with the same body consolidate into one row, is intended. This
  document states it as the design (section 3 item 15), and #619's record trues
  up the consolidation record to match. *Locked by the architect
  2026-09-28.*
- **D27: Impact is exempt from the CSV harness's per-row family check and
  required on every row whenever durations are read.** Put to the architect:
  the CSV-output harness requires every conditional column of an active family
  to be all filled or all empty on a row, and under D11 (impact reduces to its
  occurrences part) a row whose duration is unobserved while durations are read
  carries impact beside empty duration columns, which fails that check. His
  reply: "sure". Impact stays in the duration column family in the CSV rules
  (D21) but is exempt from the per-row all-or-nothing consistency check. In
  its place it carries its own presence rule: populated on every MESSAGES row
  whenever durations are read (the occurrences part where a row's duration is
  zero or unobserved, D11), and empty on every row when durations are thrown
  away by `-od` or `-d duration` (D21). The other conditional duration columns
  keep the all-or-nothing check among themselves.
  *Locked by the architect 2026-09-29.*
- **D28: The running-mean update lands as arm (c).** One sub, called from the
  per-message and per-bucket loop sites and from the consolidation merge, with
  the source state (count, mean, the three moment sums) and the store's shape
  flag as parameters; it adopts the source into an empty target, evaluates
  today's one-observation arithmetic when the source holds one observation,
  and the parallel combine otherwise. Chosen on the prototype's table (section
  8, *Prototype findings*): byte-identical to today's output on every run of
  the proof, plain and consolidated, where the combine-only arm (b) moves
  shape-statistic cells in the last bits and costs about 10.8 percent under
  shape demand; its cost, about 2.8 percent of a bin-model run on the access
  log (about 215 ns per call, the call itself), is accepted, and runs on the
  default raw model never call it. The capture-mode hoist is not part of this
  issue: it recovered nothing measurable on top of (c) and is left to #620
  (hoisting the read loop's per-line option handling). *Locked by the
  architect 2026-09-30.*
- **D29: The message store's counts are absent until their first observation.**
  The per-message entry is not initialised with `duration_count` (raw model) or
  `bytes_occurrences` (both models); each is created by its first increment,
  which is still unconditional (D1, D18), and every reader takes an absent count
  as zero. A key that never sees a metric carries no field for it, so a log with
  no durations adds no field to every key, and the MESSAGES CSV keeps
  `bytes_occurrences` empty for a key with no bytes, as today. The time-bucket
  store, one entry per bucket, initialises `duration_count => 0` in both models.
  The counts are owned by the accumulation beside the totals: the running-mean
  update reads the count and never writes it, running before the loop's
  increment and before the merge sums the two counts. *Locked by the architect
  2026-09-30.*
- **D30: Bytes are processed only when a line produces them and a surface
  demands them, at both stores.** In the architect's words: bytes values "come
  from a message. If they are not in that message, then there's nothing to do.
  There is no producer. And hence, all of the consumers reading bytes should be
  skipped using the gates"; and "If there is no demand for bytes, then you
  can't be receiving and processing them. They stay empty." It is the
  application's standing rule that branches are gated and a surface not needed
  is not used. Two gates in series, at the time-bucket store and the message
  store alike: a line carrying no bytes value produces nothing (no total, no
  count, and no zero in their place: neither store is initialised with a bytes
  total), and a run in which no surface demands a store's bytes processes none
  of them, total, count and extrema alike, so every reader finds nothing and its
  cell stays empty. The time-bucket store's bytes are demanded by the
  timeline's bytes column unless it is hidden (`-hb`, `-hi bytes`) and by `-o`
  (the STATS CSV and the YAML export); the message store's by the MESSAGES CSV
  (`-o`) and the bytes sorts, `-so bytes` included, while a message is retained.
  `-ob` switches both off. This supersedes D1's "unconditionally" for bytes:
  D1 was worded by Claude, and the measurement of drop 2 showed a count kept on
  every line that no surface of the run read. *Locked by the architect
  2026-09-30.*

---

## 5. Design

Everything in this section follows from D1 to D27 unless it is labelled
**proposed**. A proposed element is implementation detail the architect did not
decide: a name, a spelling, an argument shape.

### 5.1 The sites

| Quantity | Site (sub :: snippet) | Decision |
|---|---|---|
| Store constructors | `read_and_process_logs` :: `total_duration => 0,` (message, both models) and `duration_sum => 0,` (bucket, both models) | D1, D4, D18 |
| Per-message duration count | `read_and_process_logs` :: `my $n_old = $entry->{duration_count};` (bin, inside `if( $message_duration_stats_demand ) {`); raw has none | D1, D18 |
| Per-bucket duration count | the same snippet under `if( $bucket_duration_stats_demand ) {` (bin only) | D1, D18 |
| Bytes count, both stores | `read_and_process_logs` :: `if( $e->{bytes_occurrences}++ ) {` under `if( $bytes_aggregate_demand ) {` | D1 |
| Welford update, twice in the loop | `read_and_process_logs` :: `my $delta_n  = $delta / $n;` | D10, D12 |
| Welford merge | `merge_bin_state` :: `my $mean_ab = $mean_a + $delta * $n_b / $n_ab;` | D10, D12 |
| Impact in the loop | `read_and_process_logs` :: `if( $duration > 0 ) {` and `my $mean = $log_messages{$category}{$log_key}{total_duration} / $log_messages{$category}{$log_key}{occurrences};` | D5, D11 |
| Impact after consolidation | `group_similar_messages` :: `if (defined $entry->{total_duration} && $entry->{occurrences} > 0 && $entry->{total_duration} > 0) {` | D5, D11 |
| Duration statistics, raw | `calculate_statistics` :: `my $sum_sq_dev = $bucket_data->{sum_of_squares} - $duration_count * ($mean ** 2);` | D9 |
| Duration statistics, bin | `calculate_statistics_bin` :: `my $sum_sq_dev = $sidecar_entry->{sum_of_squares} - $n * ($mean ** 2);` | D9 |
| Per-bucket projection (twice, one per demand branch) | `calculate_all_statistics` :: `duration_sum  => $log_analysis{$bucket}{duration_sum},` and `bytes         => $log_analysis{$bucket}{total_bytes},` | D4 |
| Per-bucket count mean (twice) | `calculate_all_statistics` :: `count_mean    => ( defined $log_analysis{$bucket}{count_sum} && defined $log_analysis{$bucket}{count_occurrences}` | D3 |
| Per-bucket bytes mean (twice) | `calculate_all_statistics` :: `bytes_mean    => $log_analysis{$bucket}{bytes_occurrences} ? (` | D3 |
| Per-bucket user-defined mean (stored, then again for display) | `calculate_all_statistics` :: `$log_stats{$bucket}{"udm_${name}_mean"} = (defined $occ && $occ > 0)` and `elsif ($agg eq 'mean') { $display_value = (defined $occ && $occ > 0)` | D3 |
| Sort pre-pass means | `calculate_all_statistics` :: `$entry->{bytes_mean} = $entry->{bytes_occurrences}` and `$entry->{count_mean} = ( defined $entry->{count_sum} && $entry->{count_occurrences} )` | D3, D11 |
| Group-calculation count mean and the self-assignments | `calculate_all_statistics` :: `: undef if defined $log_messages{$category}{$log_key}{count_occurrences};` | D3 |
| Per-message user-defined mean | `calculate_all_statistics` :: `$log_messages{$category}{$log_key}{"udm_${name}_mean"} = (defined $sum && defined $occ && $occ > 0) ? $sum / $occ : undef;` | D3 |
| Per-message duration observed | `calculate_all_statistics` :: `$duration_observed ||= (` and `delete $log_messages{$category}{$log_key}{total_duration};` (as #273, store the duration total precise, leaves them) | D4, D19 |
| Per-message bytes roll-up | `calculate_all_statistics` :: `$aggregated_data->{total_bytes} += $log_messages{$category}{$log_key}{total_bytes} if defined $log_messages{$category}{$log_key}{total_bytes};` | D4 |
| Per-message bytes mean | `print_message_summary` :: `? int( $total_bytes_num / $bytes_occurrences + 0.5 )` | D3, D6 |
| Consolidation merge | `merge_consolidation_stats` :: `if (defined $source->{total_duration}) {` and `$target->{total_bytes} = ($target->{total_bytes} // 0) + $source->{total_bytes} if defined $source->{total_bytes};` | D1, D4 |
| Consolidation reinject | `group_similar_messages` :: `if (defined $cluster->{total_duration}) {` and `$entry->{duration_count} = $cluster->{duration_count} if defined $cluster->{duration_count};` (bin only) | D1, D4, D18 |
| Column-scaling maxima and scaled keys | `normalize_data_for_output` :: `$max_total{duration} = $log_stats{$bucket}{duration_sum} if ( defined $log_stats{$bucket}{duration_sum}` | D4 |
| Timeline latency block | `print_bar_graph` :: `if( defined $log_stats{$bucket}{bytes} \|\| defined $log_stats{$bucket}{p50}` | D4, D23 |
| STATS `_nice` cells | `print_bar_graph` :: `(defined $log_stats{$bucket}{duration_sum} ? ltrim(format_duration_total(` and its bytes twin | D4 |
| YAML series blocks | `write_aggregate_export` :: `next unless defined $stats->{duration_sum};` and `next unless defined $stats->{bytes};` | D4 |
| Index bytes accumulation (file row and selection row) | `read_and_process_logs` :: `if (defined $bytes && $bytes > 0) {` (twice) | D17 |
| Index means, six | `write_index_file` :: `my $dur_avg   = $fd->{duration_occurrences} > 0 ? sprintf("%.2f", ...` and the five siblings | D3, D8, D15, D16 |
| Heatmap pre-seed from the index (bytes arm corrected) | `read_index_file` :: `$heatmap_min = $index_aggregated{"${hm_metric_col}_min"}{value} + 0;` | D17, D24 |
| Diagnostic reduction | `pipeline_finalize` :: `(1 - $final_remaining / ($keys_seen \|\| 1)) * 100);` (twice) | D7 |

### 5.2 Target shape, by decision

**D1, D2, D18: the counts.**

- The duration count is one field, `duration_count`, in both models (D18): the
  bin model's field made unconditional and added to the raw model. The bytes
  count is `bytes_occurrences`, moved out of the bytes demand gate. No second
  count field is added. The raw model's retained array stays under the
  statistics demand, and its length is no longer read as a count.
- The time-bucket constructor initialises `duration_count => 0` in both
  models; the message entry initialises neither count, each being created by
  its first increment (D29).
- In the loop, the duration count increments beside `total_duration`, under the
  existing `defined $duration && !$omit_durations` (message) and
  `$duration_observed && !$omit_durations && $duration >= 0` (bucket) guards,
  outside the statistics demand. The bytes count increments beside the bytes
  guard, outside `$bytes_aggregate_demand`, which keeps governing `bytes_min`
  and `bytes_max` only. The raw model gains one integer increment per timed line
  per store; its cost is reported by the benchmark (section 8).
- The single-line `$stats_source` handed to consolidation carries
  `duration_count => 1` in both models (today bin only), and
  `merge_consolidation_stats` sums `duration_count` and gates the duration
  family on it rather than on `defined $source->{total_duration}`. The reinject
  in `group_similar_messages` copies `duration_count` in both models.
- D2 holds structurally: every per-message increment is inside
  `if( $capture_messages && defined( $message ) ) {`
  (`features/458-top-messages-zero-no-per-message-retention.md` D1, nothing per
  message under `-n 0`). Nothing is added outside that block.
- The `-HL` totals (`total_duration-HL`, `total_bytes-HL`, `count_sum-HL`) are
  not accumulators with counts of their own (D22): highlighting is a selector
  that tags a row, a highlighted row's occurrences accumulate in its message
  store entry like any other, and there are no counters tallying how rows
  became highlighted. No count is added to them.

**D3: the helper.**

- **Proposed name:** `mean_of($sum, $count)` in `## SUBS ##`, returning
  `$sum / $count` when `$count > 0` and `undef` otherwise. It gates on the count
  only; a caller never passes a counting user-defined aggregation, as today's
  per-message loop already skips them.
- Call sites: the count mean (per bucket, sort pre-pass, group calculation), the
  bytes mean (per bucket, sort pre-pass, group calculation), the user-defined
  mean (per bucket, per message), the duration mean inside the one statistics sub
  (D9), impact (D5, D11) and the six index means (D8).
- **Proposed:** the per-bucket projection is built once, with the statistics
  hash merged in the demand branch, instead of two literal copies (the two
  copies are the source of the "twice" in four rows of 5.1).
- The per-bucket user-defined display value for `mean` reads
  `$log_stats{$bucket}{"udm_${name}_mean"}`.
- The four self-assignments are removed.
- No per-line call: every site of the helper runs after the read loop, since
  D11 removes the per-line impact derivation.

**D4: output gated on the count.**

- The per-bucket projection writes `duration_sum` only when `duration_count > 0` and
  `bytes` only when `bytes_occurrences > 0`; otherwise the keys are absent. The
  `defined` tests downstream then read a count-gated projection rather than a
  zero-initialised field, and the `_nice` cells, the timeline cells, the scaling
  maxima and the YAML blocks follow without a change of their own.
- The per-message group calculation gates the duration total on
  `duration_count > 0`. This replaces the observation decision #273 (store precise) leaves at
  that site (the durations list or the bin-mode counter, extended by #273 to
  `-od`) and its unreachable fallback (D19: this issue swaps in the count gate).
  The bytes roll-up and the merge gate on `bytes_occurrences`.
- The timeline's latency section is a fixed-size block at the far right (D23):
  the table is built backwards from the terminal width, the options requested,
  the defaults and the data present, and every column before the latency
  section adapts to fill the available space. Its `defined` test in
  `print_bar_graph` reads the count-gated projection, and a bucket with no
  observation shows an empty latency cell, which occupies the block's fixed
  width like any other cell. No padding mechanism is added.

**D5, D11: impact.**

- Each row's impact is derived once, after the read loop: in the sort
  pre-pass for every key when `-so impact` ranks the population (the shape that
  #428, the fix for ranking by the bytes and count means, established for
  `bytes_mean` and `count_mean`), otherwise in the group calculation for the
  retained keys, which the table and the MESSAGES CSV read; the group
  calculation does not re-derive a value the pre-pass set. The per-line update in the read loop and
  the recompute in `group_similar_messages` are removed; consolidated entries
  reach the same two derivation points. This removes a division, a power and a
  logarithm per duration-bearing line, and removes the order dependence of
  section 3 item 2.
- The mean is `mean_of(total_duration, duration_count)`. It is the mean the row
  reports in both models: the one statistics sub (D9) derives its mean through
  the same helper over the same pair, and the bin sub already derives it as
  `total_duration / duration_count`.
- The formula, with `m` that mean and `k = $impact_time_exponent` (7), while
  durations are read: `log(max(m, 1) ** k * occurrences)`, with `m` taken as 0
  when the row has no duration observation (D11, D20). The duration term is
  floored, so it is never negative: a mean of one unit or below, zero or
  unobserved contributes nothing and the occurrences term stands. For `m > 1`
  the expression is today's, `log(m ** k * occurrences)`, so every impact cell
  not moved by the divisor, the order, the zero-mean rule or the floor stays
  byte-identical; otherwise the value is `log(occurrences)`.
- Every retained row carries an impact while durations are read: `occurrences`
  is at least 1, so `log(occurrences)` is defined and at least 0. A row of one
  line with no duration, or a zero duration, writes `0`; a row of two such
  lines writes `0.693` at the default precision, and so does a row of two lines
  whose mean is 0.5.
- Consequence of the floor (D20): a row with a mean of one unit or below ranks
  equal to a row with the same occurrences and no duration, never below it; a
  mean above one unit ranks it higher.
- When the duration is thrown away, by `-od` or by `-d duration`, it is
  undefined for every consumer, impact included (D21): impact is not derived
  and its cell is empty on every surface. The `-od` scenario #273 (store
  precise) lands and this issue inherits (D19) keeps expecting `impact` empty,
  and the `-od` row of `docs/usage.md` stands. The occurrences part applies only
  while durations are read and a row's observed duration is zero or
  unobserved.
- The MESSAGES rules row for `impact` stays in family `duration`, type and
  decimals unchanged (D21: impact is defined only while durations are read),
  and is exempt from the per-row family group-consistency check of
  `tests/csv-output/validate-csv-output.pl` (D27, section 3 item 13). In its
  place the validator holds impact to its own presence rule: populated on every
  MESSAGES row of a scenario that declares the duration family active, and
  empty on every row of a scenario that throws durations away by `-od` or
  `-d duration`. The other conditional duration columns keep the all-or-nothing
  check among themselves.
  **Proposed:** the exemption is declared on the rules row itself, by a
  `required` value of its own in place of `conditional:duration`, so the
  validator reads it from the rules file rather than from a column name held in
  its code.
- #618 (one declaration per column) labels impact a `shape` statistic in the
  rules; whichever lands later rebases the row, and #618's per-column
  declaration carries D27's presence rule for impact: populated on every row
  whenever durations are read, empty on every row when they are thrown away.
- An `impact` topic is added to `--explain` (D25): an entry in
  `%explain_topics`, listed by the topic registry, stating the formula, the
  floor, the occurrences-only case and the undefined case; it is mirrored in
  `docs/explain/statistics.md`, whose *See also* for the mean then points at
  it, and named from the `-so` paragraph of `docs/usage.md`.

**D6: the bytes mean.**

- The group calculation stores `bytes_mean` on the retained entry through the
  helper, at full precision, as it already does for `count_mean`.
  `print_message_summary` reads the stored value. The rendering boundary is
  `format_csv_value($bytes_mean, 'bytes_mean')` in the MESSAGES CSV row, the only
  surface that renders the per-message bytes mean (the terminal table does not:
  `features/432-metric-aggregate-naming-parity.md` D8 makes the bytes family a
  CSV and sort family only). Its family is `bytes`, the same as the STATS
  column, so both CSVs round through the same formatter with the same decimals.
- The MESSAGES rules row for `bytes_mean` changes from `int`/0 to the STATS
  row's `float`/5, since under `-cp full` and `-cp N` the value is fractional.
- This adds a site to #273's pattern entry (below, 5.5).

**D7: the diagnostic.** The two reduction percentages take the neighbours' shape,
`$keys_seen > 0 ? ... : 0`. Output is unchanged (section 3 item 4).

**D8, D15, D16, D17: the index.**

- Each of the six means (duration, bytes and count, for the file row and the
  selection row) is `mean_of(...)` written through `format_csv_value` at two
  decimals (D16), with the formatter's trailing-zero strip, so a mean of exactly
  100 writes `100` where today it writes `100.00`, and `128.75` stays `128.75`.
  **Proposed:** `format_csv_value` gains an optional third argument, a decimals
  override, that bypasses both the `-cp` family table and the `full` mode; the
  index passes 2.
- A mean with no observation writes the empty cell (D15). The bounds keep `-`,
  which `features/179-index-read-back.md` locks for a missing bound on the
  read-back side. The not-applicable cells keep `-` (they are not means, so
  D8's empty cell does not apply to them). A row with an empty
  mean therefore prints one column short under macOS `column -s, -t`; the index
  record says so (D15).
- The index's bytes observation rule becomes the stores' (D17): a line whose
  bytes field parsed to a number is an observation, zero included. Both index
  blocks in `read_and_process_logs` (file row and selection row) change
  `if (defined $bytes && $bytes > 0) {` to the definedness test alone, for the
  occurrences, the sum, the minimum and the maximum. On the committed
  twelve-line access fixture the index then holds 12 observations, minimum `0`
  and mean `18683.33`, where the STATS CSV holds 12 observations and mean
  `18683` at default precision (`18683.33` under `-cp 2`): one population, one
  mean.
- The pre-seed check D17 asks for (section 3 item 14): the heatmap's log axis
  already floors explicitly at 1 in both boundary calculations, independent of
  any count, and the duration arm already receives a zero minimum from the
  index today under that floor. A zero bytes minimum needs no new floor.
- The bytes arm of the pre-seed is corrected (D24): `read_index_file` reads the
  keys the index writes, `file_bytes_min` and `file_bytes_max`, where today it
  looks up `bytes_min` and `bytes_max` and finds nothing, so `-hm bytes` is
  pre-seeded from the index's bytes bounds as `-hm duration` is from its
  duration bounds. The bounds it reads are D17's aligned population, whose
  minimum can be `0`, under the existing floor.
- Moved index cells, accepted cost (D17): on any file with a zero-byte response,
  `file_bytes_occurrences`, `file_bytes_min`, `file_bytes_mean` and their
  selection twins; on every row, a mean with trailing zeros loses them and a
  mean with no data goes from `-` to empty. An index written before this change
  holds a positive bytes minimum, so the first run after it on such a file
  reports drift on `file_bytes_min` under `-V index-read-back`, and the
  end-of-run write refreshes the row.
- `read_rate` (lines per second) and `processing_time` are not means and keep
  their inline formats.
- Seams: `write_index_file` is also edited by #525 (one timestamp formatter),
  whose byte-identity criterion is scoped to the timestamp and clock columns, so
  the mean and bytes cells this issue moves do not collide with it.
  `format_csv_value` gains the decimals override here, #608 (one byte ladder)
  replaces the CSV decimals table with the ladder field, and #617 (one
  width-to-format rule) adds the trailing-zero strip helper; whichever lands
  later rebases the others' lines, with no semantic conflict.

**D9, D14: one statistics sub.**

- **Proposed name and signature:**
  `derive_moment_statistics($n, $sum, $sum_sq, $moments, $demand, $t)` returns
  `mean`, `std_dev`, `cv` and, under shape demand with `$n >= 4`, `skewness`,
  `kurtosis`, `bimodality_coef`, with the eligibility floors and the
  cancellation guard of today's two subs, and records the `csv_body` and
  `shape_moments` telemetry outcomes. `$moments` is the three moment sums or
  undef.
- `calculate_statistics` and `calculate_statistics_bin` keep their names and
  their percentile ladders (D9: percentiles stay per model), keep counting
  `stats_calls` on every call including the early returns, and gate their early
  return on `duration_count > 0`, the one gate spelling. The raw path computes
  its moment sums with its existing pass over the sorted samples (the mean from
  `mean_of`) and passes them in; the bin path passes its sidecar sums.
  Keeping both names keeps the `produced_by` strings of
  `tests/validate-statistics-demand.sh` and the `moment_source` line true.
- The raw path's percentile indexing keeps `scalar @sorted`, which equals
  `duration_count` whenever the array is retained.
- The proof is D14's: each model unchanged against its own baseline, before any
  re-bless, with the oracle layer checking both. The bin model is recorded as an
  officially supported model on both statistics stores, with this as its parity
  proof (section 10).

**D10, D12: one Welford update formula.**

- The target is one formula: the Chan–Pébay parallel combine that
  `merge_bin_state` writes. The loop's single-observation update is its case
  with a one-observation source (`n_b = 1`, `mean_b` the value, all three moment
  sums of the source zero), and `merge_bin_state`'s adoption of the source into
  an empty target is its case `n_a = 0`. No use case needs a second formula.
- Parameters the callers need: the source state (count, mean and the three
  moment sums) and the shape flag (whether the moment sums are updated). The two
  loop sites pass a one-observation source and their store's shape flag
  (`$message_stats_demand_shape`, `$bucket_stats_demand_shape`). The merge
  passes an absorbed key's state, or a one-observation source for a
  streaming-consolidation line, and the message store's shape flag, instead of
  reading the global itself. The merge reads the two counts before
  `merge_consolidation_stats` sums them.
- The arms measured before one is fixed (section 8, the prototype):
  (a) today's inline update, the baseline against which (b) to (d) are
  measured; it is not a landing arm, because D10 locks one update sub and D12
  one formula;
  (b) one sub computing the combine formula, called with a one-observation
  source at the loop sites;
  (c) one sub with the combine formula whose one-observation case evaluates
  today's update arithmetic, selected by the source count;
  (d) the better of (b) and (c) with the two capture-mode string compares
  (`$message_stats_capture_mode eq 'bin'`, `$bucket_stats_capture_mode eq 'bin'`)
  resolved to booleans once before the loop, the audit's hoist remedy (its
  probe measured a string compare at 30 to 36 ns per line against 23 ns for a
  boolean).
  If every sub arm costs more than the table's noise band against (a), even
  with the hoist of (d), that result is brought to the architect as a conflict
  with D10 and D12, with the table, before any arm lands.
  The arm that lands is the one the table supports; the table and the choice
  are written into this document as a finding before the drop that lands it.
- Byte identity is measured, not assumed. The mean is the same in every arm:
  `$delta * $n_b / $n_ab` with `$n_b = 1` equals `$delta / $n` exactly. Arm (b)
  evaluates the second moment as `$d2 * $n_a * $n_b / $n_ab` where today's loop
  evaluates `$delta * $delta_n * $n_old`, so its moment sums can differ in the
  last bits on non-consolidated bin rows; arm (c) keeps today's arithmetic for
  one observation. The drop's drift run lists, per bin scenario, every moved
  cell in the mean, standard deviation, coefficient of variation and shape
  columns, and each is attributed.
- The cost is one sub call per duration-bearing line per bin-model store, paid
  only by runs that select the bin model for that store.

### 5.3 What changes on each user surface

| Surface | Today | After |
|---|---|---|
| STATS CSV, a bucket with lines but no duration | `duration=0`, `duration_nice=0 msec` | both empty |
| STATS CSV, a bucket with lines but no bytes | `bytes=0`, `bytes_nice=0 B` | both empty |
| Timeline total columns, same buckets | `0 milliseconds`, `0 B` | blank cell |
| Timeline latency section, a bucket with lines but no observation of its metrics | empty | empty, within the section's fixed-size block at the far right; no padding (D23) |
| YAML export series, same buckets | `duration: {sum: 0}`, `bytes: {sum: 0}` | block absent |
| MESSAGES CSV `impact`, consolidated rows mixing lines with and without a duration | from total ÷ every line | from the row's reported mean |
| MESSAGES CSV `impact`, keys whose last lines carry a zero duration | depends on line order | one value, from the reported mean |
| MESSAGES CSV `impact`, rows with a zero or no duration mean while durations are read | empty | `log(occurrences)` |
| MESSAGES CSV `impact`, rows whose mean is above zero and below one unit | below `log(occurrences)` (a negative duration term) | `log(occurrences)` (D20) |
| MESSAGES CSV `impact` under `-od` or `-d duration` | empty under `-od` | empty under both (D21) |
| `-so impact` ranking | follows the values above | follows the new values; rows with a mean of one unit or below, or none, rank by occurrences |
| MESSAGES CSV `bytes_mean` | integer rounded half up at every `-cp` | rounded by the formatter: `512` at default for 512.5, `512.5` under `-cp full` or `-cp 1` |
| `ltl-index.csv` means | `%.2f`, `-` for no data | two decimals through the formatter whatever `-cp` says, trailing zeros stripped, empty for no data |
| `ltl-index.csv` bytes cells | zero-byte responses not counted | counted, as the STATS CSV counts them |
| `-hm bytes` with an index file present | range from the live data only | pre-seeded from the index's bytes bounds, as `-hm duration` is from its duration bounds (D24) |
| `--explain impact` | no such topic | the formula, the floor, the occurrences-only case and the undefined case (D25) |
| `-V message-grouping` reduction line | unchanged | unchanged |

No option or deprecation is added or changed; `--explain` gains the `impact`
topic (D25), and the `-od` row of `docs/usage.md` stands (D21). **Proposed**
`docs/usage.md` wording: under the CSV output description, "a time bucket in
which no line carried a metric leaves that metric's cells empty, on the
timeline and in the CSV and YAML files"; in the `-so` paragraph, impact is "the
logarithm of occurrences × mean duration to the seventh power, a mean below one
unit counting as one, so that a message with no duration ranks by its
occurrences; empty when durations are not read", pointing at
`ltl --explain impact`; in the index file description, zero-byte responses
count and the means keep two decimals whatever `-cp` is.

### 5.4 Sibling issues

- **#273 (store the duration total precise, format at the output boundary).**
  Lands first (D19); this issue is blocked by it. D6 is its pattern applied to
  the bytes mean. Both issues edit the per-message duration accumulation block
  and the group calculation's duration-total lines; this issue rebases onto
  #273's version and replaces #273's observation decision with the count gate.
  #273's `-od` scenario is this issue's regression check, its `impact`
  expectation still empty (D21). #273's twelve-line `-so duration` scenario
  leaves `impact` empty on four zero-total rows today; after this issue those
  rows write `0` (`log(1)`), as D27's presence rule (impact on every row while
  durations are read) requires.
- **#619 (one per-run key cut).** Lands third (D19) and is blocked by this
  issue; each re-takes its memory baseline on the tree it lands on. Its record
  trues up the consolidation record to state the final pass of section 3 item
  15 as the design (D26).
- **#608 (one byte ladder and output notation).** Already blocks this issue:
  its regression goldens are re-blessed first. The `format_csv_value` seam is
  under D16 above.
- **#617 (one width-to-format rule).** Renders an undefined value as empty; this
  issue makes an unobserved value undefined. The trailing-zero helper seam is
  under D16 above.
- **#525 (one timestamp formatter).** Shares `write_index_file`; the seam is
  under D8 above.
- **#618 (one declaration per column).** The `impact` rules row stays in the
  duration family (D21), exempt from the per-row all-or-nothing family check
  and required instead on every row whenever durations are read, empty on every
  row when they are thrown away by `-od` or `-d duration` (D27); #618's
  per-column declaration carries that presence rule for impact, under D11
  above.
- **#620 (hoisting the loop's per-line option handling).** Blocked by this issue.
  Arm (d) did not land (D28): converting the two capture-mode compares to
  booleans stays #620's step. The prototype measured it on the bin model: alone
  it saved about 0.1 to 0.2 s on a day of access log (−1.7 percent standard,
  −1.0 percent with shape demand), and on top of the one update sub nothing
  measurable (section 8, *Prototype findings*).
- **#514 (count metric capture explicit and off by default), #426 (the
  per-message statistics store's representation), #469 (consolidated message
  histograms on a shared bucket grid)** read the helper, the counts, the statistics sub and the
  update formula this issue lands. **#354** (bin-model memory on
  singleton-dominated logs, on hold) changes the bin store's shape, which the one
  statistics sub then reads; informational.

### 5.5 The pattern entry

A new entry in `docs/architecture-patterns.md`, **proposed title** *Observation
counts and gated means*: every accumulator carries its observation count
unconditionally; every mean is derived by the one helper from a sum and its
count, the gate inside; a total is projected only when its count is positive.
Consumption sites: `mean_of` and its callers, and the one statistics sub.
Owning record: this document. The entry covers counts and gated means only; it
cross-references #273's pattern entry (store precise, format at the output
boundary), whose contract is #268's completion record (CSV precision fixed at
storage time, defeating harness validation and external precise use) and
#273's record (store precise, format at the output boundary; its feature doc),
and to which this issue adds
the per-message bytes mean and the six index means as sites. The *Demand gates*
entry's status moves to established for the observation-count rule, and its
"refined by" line drops this issue.

---

## 6. Acceptance criteria

Each is a condition and an observable outcome, triaged before implementation.
Fixtures are described in section 7.

- [x] **Unobserved buckets write empty cells.** On the application-log fixture
  with a bucket whose only line carries bytes and no duration, and the
  access-log fixture with a bucket whose only line carries `-` for its size, run
  with `-bs 1 -oe -ni -o -n 1`: the STATS CSV passes the existing
  group-consistency assertion of `tests/validate-csv-output.sh` (it fails on the
  base commit, for the zero projection), and the unobserved buckets'
  `duration`/`duration_nice` and `bytes`/`bytes_nice` cells are empty.
  *Assertable:* two new scenarios in `validate-csv-output.sh` reusing its
  group-consistency mechanism.
- [x] **Observed zeros still print.** On the access-log fixture, a bucket whose
  only line carries a zero-byte response writes `bytes=0`, `bytes_occurrences=1`;
  a bucket whose only duration is 0 writes `duration=0`. *Assertable:* same
  scenarios, cell reads.
- [x] **The timeline shows the same empty cell, with and without statistics
  demand, in both models.** Same fixtures, rendered at a pinned width with
  `--debug-layout`, plain and with `-hm duration` and no `-o` (bucket statistics
  demand off), each under `-bdm raw` and `-bdm bin`: the unobserved bucket's
  total cell in the duration and bytes columns is blank. This also proves the
  count exists without a consumer demanding it, in both models (D1, D18).
  *Assertable:* a scenario in `tests/validate-duration-display.sh` using
  `timeline_cell_report` from `tests/lib/rendered-output.sh`. The rendered rows
  are also looked at before the work is called done, at `-bs 1`, on two
  application script logs that between them hold both cases (each counted on
  the base commit from its STATS CSV at `-bs 1`): a day of script log carrying
  `durationMS=` on some lines only, whose first 100k lines give 96 of 121
  one-minute buckets holding lines and no duration; and a script log carrying
  duration, result bytes and result counts, in which 131 of 157 one-minute
  buckets hold a duration and no bytes.
- [x] **Impact equals the formula on every row.** For every MESSAGES row of a
  run that reads durations: `impact == ln(max(duration_mean, 1)^7 × occurrences)`,
  with an empty `duration_mean` read as 0, so `impact == ln(occurrences)` when
  the mean is one unit or below, zero or empty (D11, D20); `impact` is never
  empty on a retained row. Checked within 1e-9 relative at `-cp full`, the
  precision the drift scenarios write. *Assertable:* a new L2 intra-row
  invariant in `tests/statistics-drift/compare-statistics-drift.pl`, which then
  checks every drift scenario in both models, consolidated ones included. It
  fails on the base commit on 129 cells (the 45 order-dependent ones and the
  122 whose sub-unit mean gives a negative duration term, 38 of them in both)
  and on 2 empty cells (section 3 item 2). The presence half is also asserted
  by the CSV-output harness under D27: `impact` populated on every MESSAGES row
  of every scenario that declares the duration family active, whatever the
  row's other duration cells hold, and empty on every row of the `-od` scenario
  and its `-d duration` twin; `impact` takes no part in the duration family's
  per-row all-or-nothing check.
- [x] **Impact does not depend on line order, and a consolidated row's impact
  follows its reported mean.** Two access-log lines of one path with durations
  100 and 0, in both orders: both runs write `impact=28.077`. The four-line
  application-log consolidation fixture at `-g 50 -so impact` writes
  `duration_mean=200`, `occurrences=4`, `impact=38.475`. *Assertable:* fixture
  scenarios in `validate-statistics.sh` (L1 against a committed baseline, plus
  the L2 invariant above).
- [x] **A duration never ranks a row below none.** On the access-log fixture, a
  path of two lines with durations 1 and 0 writes `duration_mean=0.5`,
  `occurrences=2` and `impact=0.693`, the same as a key of two lines with no
  duration, where today's formula gives it a negative value (D20).
  *Assertable:* a fixture scenario in `validate-statistics.sh` (L1), and the L2
  invariant above.
- [x] **With no duration mean, impact is the occurrences part; with the
  duration thrown away, it is undefined.** On the application-log fixture, a
  key of two lines with no duration writes `impact=0.693`, and a key of one
  zero-duration line writes `impact=0`; under `-od`, and again under
  `-d duration`, every row's `impact` cell is empty, as are every duration
  column and `duration_nice` (D21). *Assertable:* a fixture scenario in
  `validate-csv-output.sh` with a `-d duration` twin, and the `-od` scenario of
  #273 (store precise) unchanged. The two-line key with no duration carries
  `impact` beside empty duration columns, which the duration family check
  passes because `impact` is exempt from it (D27).
- [x] **One value for one mean.** On the access-log fixture (one path, sizes 512
  and 513 in one bucket): MESSAGES and STATS `bytes_mean` are both `512` at the
  default precision and both `512.5` under `-cp full`. *Assertable:* fixture
  scenario in `validate-statistics.sh` (L1), and `validate-csv-output.sh` with the
  MESSAGES `bytes_mean` rules row retyped to the STATS row's type.
- [x] **Nothing per message under `-n 0`.** The existing assertions of #458 (the
  per-message store never populated under `-n 0`) keep passing. *Assertable:*
  existing harness coverage, unchanged.
- [x] **The index writes the empty cell for no data and keeps two decimals
  whatever `-cp` says.** On the committed twelve-line access fixture,
  `ltl-index.csv`'s `duration_mean` is `128.75` under the default `-cp`, `-cp 0`,
  `-cp 4` and `-cp full` alike; `count_mean` (the fixture has no count lines) is
  empty on both rows; the `count_min` and `count_max` bounds keep `-`; a mean
  that is a whole number writes without decimals (for example `100`, not
  `100.00`) under every one of those `-cp` settings, on a fixture chosen so
  that one of the six means is integral.
  *Assertable:* new scenarios in `tests/validate-index-read-back.sh`, the
  harness whose subject is the index, one of them run under the `-cp` settings.
- [x] **The index counts bytes as the stores do.** On the same fixture, the
  index's `file_bytes_occurrences` is `12`, `file_bytes_min` is `0` and
  `file_bytes_mean` is `18683.33`, and the STATS CSV of the same run under
  `-cp 2` writes `bytes_mean=18683.33`. *Assertable:* a scenario in
  `validate-index-read-back.sh` reading both files.
- [x] **The bytes heatmap is pre-seeded from the index.** On a scratch copy of
  the committed twelve-line access fixture whose index row has
  `file_bytes_max` edited to 999999, `-hm bytes -bs 1440 -V index-read-back`
  reports `heatmap_preseed_max: 999999`, as `-hm duration` reports an edited
  `duration_max` (D24). *Assertable:* a scenario in
  `validate-index-read-back.sh`; it fails on the base commit, which reports the
  live maximum `102400`.
- [x] **`--explain impact` states the rule.** The topic renders and is listed by
  `ltl --explain`, and it states the formula, the floor, the occurrences-only
  case and the undefined case (D25). *Assertable:* `impact` added to the topic
  list of `tests/validate-explain.sh`, whose `all-topics-render` scenario renders
  every listed topic; the content is checked by reading.
- [x] **The YAML export omits an unobserved metric.** On the two
  zero-projection fixtures, run with `-bs 1 -oe -ni -o -n 1`, the aggregate
  export's series for the unobserved bucket carries no `duration` block
  (application-log fixture) and no `bytes` block (access-log fixture), and the
  observed buckets keep theirs. *Assertable:* a new scenario in
  `tests/validate-aggregate-export.sh`; it fails on the base commit, where the
  blocks read `sum: 0`.
- [x] **One statistics sub changes no statistic in either model.** On the drop
  that lands D9, every drift scenario, raw and bin, shows zero advisories on
  `mean`, `std_dev`, `cv`, `skewness`, `kurtosis` and `bimodality_coef` against
  its own committed baseline, and the L3 oracle layer passes for both models.
  The drop runs before any baseline is re-blessed. *Assertable:*
  `validate-statistics.sh`.
- [x] **The Welford arm is chosen from a measurement.** The prototype's table
  (arms (a) to (d), medians with ranges, at the bin model on both stores and on
  a consolidating selection) and the chosen arm are written into this document
  before the drop that lands it; that drop's drift run lists every moved cell
  in the mean, standard deviation, coefficient of variation and shape columns
  per bin scenario, non-consolidated and consolidated separately, each
  attributed. *Assertable:* the prototype's exit and `validate-statistics.sh`.
- [x] **The per-line cost is measured and reported.** The standard pair and the
  bin-model pair of section 8, compared with `compare-results.sh summary`,
  reported with the count increments' cost (D18) and the update's cost (D12)
  named. *Assertable:* section 8.
- [x] **The helper is the only derivation.** No division of a sum by a count
  remains outside `mean_of`, the one statistics sub and the rates.
  *Unassertable* as a behaviour; checked in review by grep for `/ $` over a count
  or occurrences field.
- [x] **The diagnostic is gated.** *Unassertable*: unreachable today (section 3
  item 4); checked by reading.
- [x] **The landing order holds.** #273 (store precise, format at the output boundary) is merged into the release branch
  before this issue's PR opens, #273's `-od` scenario passes on this branch, and
  the native edges of D19 are recorded. *Unassertable* as a behaviour; checked
  at delivery.
- [x] **The full harness suite passes.** *Assertable:* the completion gate.

---

## 7. Verification surface

**`-V` sections read, none changed.** `csv-output` (the precision contract the
CSV-output harness reads), `statistics-demand` (the `stats_calls` and
`group_calc` counters, whose producers keep their names under D9),
`message-grouping` (the reduction line, unchanged), `index-read-back` (the
pre-seed and drift report the index scenarios read), `benchmark-data` (the
benchmark). No key is added, renamed or removed.

**Harness assertions and goldens that move, and why the contract supports it.**

| Harness or golden | What moves | Supporting contract |
|---|---|---|
| `tests/statistics-drift/baselines/*/messages.csv` | 97 `bytes_mean` cells on the access-log scenarios (integer to precise; every one under 1 percent, so advisory, worst 0.22 percent); 45 `impact` cells on the web-application access-log scenarios (under 0.1 percent), 122 `impact` cells on eight scenarios whose mean is above zero and below one unit (to `log(occurrences)`; 38 of them among the 45) and 2 empty `impact` cells on the consolidated web-server scenarios (to `0`) | D5, D6, D11, D20; #268's completion record (CSV precision fixed at storage time, defeating harness validation and external precise use) and #273's record (store precise, format at the output boundary; its feature doc): storage stays precise, formatted at the output boundary |
| same, bin scenarios | moment-column cells only if the arm chosen under D12 reorders the arithmetic, listed and attributed | D12; the rounding difference `features/287-message-stats-bin-counter-data-model.md` records |
| `compare-statistics-drift.pl` L2 `bytes_deriv` | `produced_by` names `print_message_summary()` and the rule says "integer-typed"; both are rewritten for the stored precise mean | D6 |
| `compare-statistics-drift.pl` L2 | a new impact invariant (section 6) | D5, D11, D20 |
| `tests/csv-output/rules/messages-columns.tsv` | `bytes_mean` becomes `float`, 5 decimals, as in the STATS rules; `impact` stays in the duration family, type and decimals unchanged, its row declaring the exemption from the per-row family check and the every-row presence rule | D6, D21, D27 |
| `tests/csv-output/validate-csv-output.pl` | the per-row group-consistency check skips a column declared exempt; a new per-row check holds such a column populated on every row when its family is declared active and empty on every row of a scenario that throws the family away (`-od`, `-d duration`), declaring `asserts`, `produced_by` and `contract` like its neighbours; every other column's family check is unchanged | D11, D21, D27 |
| The `-od` scenario of #273 (store precise) in `validate-csv-output.sh` | none: its `impact` expectation stays empty, and it runs as this issue's regression check | D19, D21 |
| `tests/reference-output/*` (21 goldens: the heatmap, histogram, highlight and application-log width captures) | `0 B` and zero-duration cells in the timeline's total columns become blank; on the application log those goldens render, 7 of 8 one-minute buckets carry no bytes | D4 (a bucket with no observation of a metric carries no total, and its cell is empty on the STATS CSV and the timeline) |
| `tests/validate-index-read-back.sh` and its generated index fixture | mean cells lose trailing zeros and write empty for no data; bytes cells count zero-byte responses; a new `-hm bytes` pre-seed scenario | D15, D16, D17, D24 |
| `tests/validate-explain.sh` | `impact` joins its topic list | D25 |
| `tests/validate-aggregate-export.sh` | a new scenario on the zero-projection fixtures; the existing fixtures' first buckets are observed and do not move | D4; `features/503-yaml-aggregate-export.md` § Conventions |
| `tests/validate-statistics-demand.sh` | none; `stats_calls` still counts every call | D9 |

Each golden and baseline is re-captured once, after the drop that moves it, with
every changed cell attributed to a decision in the implementation record.

**Fixtures.** Committed fixtures, named `.txt`:

- an application-log fixture: one bucket with a duration-only line, one with a
  bytes-only line, the four `Processing request <uuid> done` lines of the
  consolidation case (two timed, two untimed, one level), a key of two lines
  with no duration, and a key of one zero-duration line;
- an access-log fixture: one path with sizes 512 and 513 in one bucket, a bucket
  with `-` for its size, a bucket with a zero-byte response, and a second path
  with durations 100 then 0, one minute apart, so that the second line's bucket
  holds only a zero duration; a copy with that pair reversed; a third path
  with durations 1 and 0 in one bucket, a mean of 0.5.

The index scenarios use the committed twelve-line access fixture with
single-sample keys. Every other invocation passes `-ni`, `-n 1` or the smallest
`-n` its assertion reads, and `-bs 1 -oe` where the bucket cells are the
subject.

---

## 8. Measurement obligations

All `before` captures are taken on the release-branch commit this issue lands
on, after #273 (store precise) has merged (D19, the landing order), before the first line of code.

**Standard before/after benchmark: required.** The diff changes executable lines
of the read loop (`docs/process/workflow.md` § 3, first row):
`run-benchmark.sh single-day-access-log-standard --label 616-before`, then
`616-after` on the finished commit, compared with `compare-results.sh summary`.
What it measures on the default (raw) models: the added duration and bytes
count increments per line on both stores (D1, D18), and the removal of the
per-line impact derivation (D11). A metric worse by more than 1 percent across
repeated runs is investigated.

**Bin-model benchmark pair: the gate instrument for the update (D13).** The
same selection a second time with `--options "-mdm bin -bdm bin"` under the
labels `616-before-bin` and `616-after-bin`. Why this string:

| Selector | Surface | Update site it exercises | In the standard case |
|---|---|---|---|
| `-mdm` | per-message statistics | the message store's loop update, and the merge under `-g` | runs (messages retained, `-n 10`); no `-g`, so not the merge |
| `-bdm` | per-time-bucket statistics | the bucket store's loop update | runs (the timeline's latency column creates bucket statistics demand) |
| `-hgdm` | histogram | none: its bin counters carry no mean or moment sums, and it already defaults to bin | not rendered |
| `-hmdm` | heatmap | none, for the same reasons | not rendered |

The message selector alone, the architect's first suggestion, leaves the bucket
store's loop update unmeasured, so the string adds `-bdm bin`. It names the two
stores rather than passing `-dm bin`, which would add nothing measurable here.
The merge's one-line case runs only under consolidation, which the standard case
does not do; the prototype below measures it.

What the pair does not exercise: the standard case demands no shape statistic
on either store (`-V statistics-demand` on the web-server access log of the
standard case at `-mdm bin -bdm bin`: `group shape_moments: demanded=0` for
both), so the loop update it times is the running mean alone; the three moment
sums are updated only when skewness, kurtosis or bimodality is demanded (`-o`
on both stores, `-so skewness` on the message store). The arms of D12 differ
chiefly in that moment arithmetic, so the prototype below adds a selection that
demands it.

**Captured 2026-09-30 on `a32eb32`, one run each:** `616-before` 9.412 s total,
peak RSS 104,792,064 bytes; `616-before-bin` 11.850 s, peak RSS 53,821,440
bytes. The runner writes the `--options` string into neither the TSV's
`options` column nor any other row, so the bin-model file is identified by its
label alone; the halved peak memory confirms the bin models took effect. The
`after` pair is captured with the same two option strings.

**Prototype: required by D12, measurement-only, trigger execution frequency ×
per-execution cost** (`prototype/README.md`). Question: which arm of section 5.2
under D10, D12 lands, given its per-line cost at the bin model? Arms (a) to
(d). Method: the interleaved order-balanced driver of
`prototype/342-read-loop-cost-curve/`, ten rounds, medians with ranges, every
selection at `-mdm bin -bdm bin` and every log carrying a duration on its lines,
since a log without one never reaches the update:

| Selection | Log | Options added | What it exercises |
|---|---|---|---|
| access, standard | a day of web-server access log carrying execution time in the duration field (the standard benchmark's) | none | both loop sites, running mean only |
| access, shape | the same | `-o` | both loop sites with the three moment sums |
| application, standard | a day of application script log carrying `durationMS=`, result bytes and result counts on its lines | none | both loop sites, running mean only, on an application-log key population |
| access, consolidated | the same access log | `-g -m uuid` | the merge's one-line and absorbed-key cases |

The standard benchmark's application-log selection is not used: that log
carries no duration on any line (`-V statistics-demand` at `-mdm bin -bdm bin`
computes no statistic on either store), so no arm's code runs on it. The
behaviour proof runs per arm first, on a 100k-line slice of each log, at
`-o -cp full` so that the moment columns are written, plain and consolidated
(`-g -m uuid`): arms (a), (c) and (d) byte-identical to the base on every
statistic; arm (b) with every moved cell in the mean, standard deviation,
coefficient of variation and shape columns listed and attributed (D12). Staged
scale: a 100k-line slice for the proof, the full file for timing. Exit: the arm that
lands, recorded here as a finding with its table. Cost: about half a day of
machine time.

**Prototype findings (2026-09-30, `48117be`, this host).** Scripts in
`prototype/616-welford-update-arms/` (`make-probes.pl` builds each arm from
`ltl` by asserted mechanical edits, slicing the combine out of
`merge_bin_state` and the one-observation update out of the per-message loop
site; `prove.sh` and `compare.pl` the proof; `run-arms.sh` and `summarise.pl`
the timing); results in `tests/profile/results/616-welford-update-arms/`
(`proof.txt`, `arms.tsv`, `summary.md`). Arm (d) was built both ways, as
`b-hoist` and `c-hoist`, and a `hoist` probe (today's code with only the hoist)
separates the hoist's own effect.

*Behaviour proof* (100k-line slices, `-mdm bin -bdm bin -o -cp full`, every
MESSAGES and STATS cell against the base): arm (c), the hoist and `c-hoist`
are byte-identical to the base on all six runs (access log, application script
log, each plain and consolidated with `-g -m uuid`). Arm (b) moves cells on
every run, only in `duration_skewness`, `duration_kurtosis` and
`duration_bimodality_coef`: 137 MESSAGES and 7 STATS cells on the access log,
28 and 7 consolidated, 15 and 2 on the script log, 4 and 2 consolidated. Every
moved cell is within 3.6e-13 relative, except skewness cells of about 1e-16 on
symmetric rows whose exact skewness is 0. Mean, standard deviation and
coefficient of variation never move. Attribution: the combine evaluates the
moment sums in a different order from the one-observation update.

*Timing* (full files, ten interleaved order-balanced rounds, per-round delta
against the same round's base, median and range; the access log has 761,698
lines, each carrying a duration, so two update calls per line, one per store):

| Selection | Base median (range) s | (b) | (c) | hoist | `b-hoist` | `c-hoist` |
|---|---|---|---|---|---|---|
| access, standard | 11.611 (11.186 to 12.108) | +0.259 (−0.409 to 0.454), +2.2% | +0.330 (−0.414 to 0.454), +2.8% | −0.193 (−0.644 to 0.928), −1.7% | +0.379 (−0.314 to 0.632), +3.3% | +0.320 (−0.244 to 1.141), +2.8% |
| access, shape (`-o`) | 12.520 (12.286 to 13.227) | +1.354 (0.896 to 1.778), +10.8% | +0.331 (−0.031 to 0.893), +2.6% | −0.123 (−0.436 to 0.968), −1.0% | +1.269 (0.943 to 1.623), +10.1% | +0.364 (−0.062 to 1.646), +2.9% |
| application script log, standard | 2.403 (2.306 to 2.457) | +0.018, +0.8% | +0.029, +1.2% | +0.022, +0.9% | +0.023, +1.0% | +0.024, +1.0% |
| access, consolidated (`-g -m uuid`) | 14.194 (13.223 to 18.405) | +0.230 (−4.164 to 0.711), +1.6% | +0.221 (−4.459 to 0.724), +1.6% | +0.069, +0.5% | +0.055, +0.4% | +0.341, +2.4% |

Rounds in which the arm was slower than that round's base, of ten: access
standard (b) 7, (c) 8, hoist 3, `c-hoist` 9; access shape (b) 10, (c) 9, hoist 3,
`c-hoist` 9. Peak memory is unchanged in every arm (within 0.3 MB).

Reading: (c) costs about 0.33 s on the access log with or without the moment
sums, about 215 ns per call over 1.52 million calls, which is the call itself;
(b) adds about 1.0 s more under shape demand, about 670 ns per call for the
combine's moment arithmetic. The hoist alone saves about 0.1 to 0.2 s, but on
top of (c) it recovers nothing measurable here (`c-hoist` equals (c) within its
range). The consolidated selection's spread (one base round at 18.4 s) leaves
it inconclusive. The cost falls only on runs that select the bin model for a
store; the default raw model never calls the update. The arm that lands is the
architect's decision on this table.

The unconditional counts are a small change to an existing path; the standard
pair is their evidence (D18) and no prototype is run for them.

---

## 9. Delivery

Drops are commits on the issue branch, each pushed; one PR at the end. The
branch is rebased onto the release branch after #273 (store precise) merges, before the first
drop (D19). Each drop that changes the loop gets an interleaved A/B on the
development host before the next begins.

**Ordering edges** (native, recorded 2026-09-28 with D19): this issue is
blocked by #273 (store precise, format at the output boundary: #273 lands first
and keeps the unobserved-total change; this issue swaps in the
observation-count gate at that site), and #619 (one per-run key cut) is blocked
by this issue (the message-store entry gains its counts before the grouping key
is added).

| Drop | Content | What it proves |
|---|---|---|
| 1 | `mean_of` at the post-loop sites whose output does not change (the count, bytes and user-defined means per bucket, in the sort pre-pass and in the group calculation), the single per-bucket projection, the self-assignments, the diagnostic (D7); the impact, per-message bytes mean and index sites move to the helper in drops 4, 5 and 6 | behaviour-neutral: `validate-csv-output.sh`, `validate-statistics.sh`, `validate-aggregate-export.sh` and `validate-statistics-demand.sh`, the harnesses that read the changed sites, pass with no golden or baseline moved |
| 2 | unconditional counts and one `duration_count` in both models (D1, D2, D18), the count gate replacing the observation decision of #273 (store precise), the count-gated projections, merge and reinject (D4) | the empty-cell criteria; #273's `-od` scenario passing; the 21 goldens re-captured and attributed; loop A/B |
| 3 | one statistics sub (D9), its early return gated on `duration_count > 0` | each model unchanged against its own baseline on every drift scenario, before any drift baseline moves (D14) |
| 4 | impact derived once after the loop, occurrences part without a mean (D5, D11), the duration term floored (D20), undefined when the duration is thrown away (D21); the CSV-output harness's exemption of `impact` from the per-row family check and its every-row presence rule, in the validator and the rules row (D27); the `impact` topic of `--explain` (D25) | the impact criteria and the new L2 invariant; the presence rule executed and seen to assert on every MESSAGES scenario of `validate-csv-output.sh`; the 129 moved and 2 empty impact cells re-blessed; #273's `-od` scenario passing unchanged; the explain topic rendered; loop A/B |
| 5 | the bytes mean stored precise (D6) | the one-value criterion; the 97 cells re-blessed; rules row retyped |
| 6 | the index: means (D8, D15, D16), bytes population (D17), the heatmap's bytes pre-seed (D24) | the index criteria, the `-cp` scenario, the pre-seed scenario |
| 7 | the one Welford formula (D10, D12), in arm (c) (D28) | the prototype's table recorded first; the bin-model pair; the drift run's moved-cell list |

**Merge gate:** the full harness suite on the final commit (CSV output first,
then statistics, sharing the cache, then the rest), the `616-before`/`616-after`
comparison and the bin-model pair, with `$version_number` restored to `0.19.0`.

---

## 10. Records to update at delivery

**Feature docs and user docs.**

- `features/duration-statistics.md` § Stores and primitives: both primitives
  share the one statistics sub; both stores carry `duration_count` in both
  models; the early-return gate is the count; the bin model is an officially
  supported model on both statistics stores, its parity proof being each model
  unchanged against its own baseline (D14).
- `features/287-message-stats-bin-counter-data-model.md` and
  `features/289-bucket-stats-bin-counter-data-model.md`: the update and merge
  sites use the one formula, in the arm chosen under D12; the bin model's
  official status and parity proof (D14).
- `features/516-bytes-aggregate-demand-gate.md`: D1 (the store-level bytes
  demand flag) no longer governs `bytes_occurrences`, which is unconditional
  under this issue's D1; D2 (downstream reads are absence-tolerant) no longer
  applies to the count.
- `features/432-metric-aggregate-naming-parity.md`: D7 (`ltl-index.csv`
  follows the same naming convention) gains the precision rule (two decimals
  through the CSV formatter, unaffected by `-cp`, empty for no data); D5 (bytes
  gains the full basic family on both CSV surfaces) notes that both CSVs round
  the bytes mean through the formatter.
- `features/426-per-message-statistics-store.md` § Findings: the #330 test (a
  message with no duration must not report a measured zero) is the count; the
  four self-assignments are gone.
- `features/user-defined-metrics.md` § Per-Message Storage and § Statistics: the
  mean is derived once by the helper and the display reads it.
- `features/index-file.md`: current column names; the mean precision rule; the
  bytes observation rule (zero included, as the stores); the placeholder
  sentence rewritten to say what the file does: means write the empty cell for
  no data, as every CSV surface does, and the bounds and not-applicable fields
  write `-`, so a row with an empty mean prints one column short under
  `column -s, -t` (D15).
- `features/179-index-read-back.md`: the bytes minimum a row holds can be `0`;
  the heatmap's bytes pre-seed reads `file_bytes_min` and `file_bytes_max`
  (D24); the read-back and the drift comparison are otherwise unchanged.
- `features/503-yaml-aggregate-export.md`: an unobserved metric's block is absent
  per bucket.
- `docs/architecture-patterns.md`: the new entry (5.5), the two sites added to
  #273's pattern entry (store precise, format at the output boundary), and the
  *Demand gates* status line.
- `features/342-redundant-logic-surfaces-audit-report.md` § Review progress:
  stages 6 (mean and ratio derivation with observation-count gating), 10 (the
  run index) and 14 (raw and bin statistics) move to *done* at close-out.
- `docs/usage.md`: the sentences of 5.3; the `-od` row unchanged (D21).
  `--explain`: the `impact` topic (D25), mirrored in
  `docs/explain/statistics.md`, whose *See also* for the mean points at it.
  `--help`: no option row changes.

**Native edges** (recorded 2026-09-28, with D19):

- this issue blocked by #273 (store precise, format at the output boundary;
  D19);
- #619 (one per-run key cut) blocked by this issue (D19);
- already recorded: this issue blocked by #608 (one byte ladder; regression
  goldens re-blessed in sequence).

**Issue comments**, each pointing at this document:

- on #616 (this issue): the specification agreed, D11 to D27 transcribed by what each means;
- on #273 (store precise, format at the output boundary): the edge and its
  reason; its `-od` scenario is this issue's regression check, its `impact`
  expectation staying empty (D21); its four zero-total rows write `impact=0`
  after it; its pattern entry gains the per-message bytes mean and the index
  means as sites;
- on #619 (one per-run key cut): the edge and its reason; the consolidation
  final pass of section 3 item 15 is the design (D26), and #619's record trues
  up the consolidation record to say so;
- on #525 (one timestamp formatter): `write_index_file` is shared; this issue moves the mean and bytes
  cells, #525 the timestamp and clock columns;
- on #608 (one byte ladder) and #617 (one width-to-format rule):
  `format_csv_value` gains a decimals override here, #608
  replaces the decimals table with the ladder field, #617 adds the trailing-zero
  helper; whichever lands later rebases;
- on #514 (count metric capture explicit): impact is derived once after the
  read loop from the reported mean with the duration term floored, the
  occurrences part while durations are read and a row's duration is zero or
  unobserved, undefined under `-od` and `-d duration`; the count-metric work
  lands on that one site (D11, D20, D21);
- on #618 (one declaration per column): the `impact` rules row stays in the
  duration family, is exempt from the per-row all-or-nothing family check, and
  is required on every row whenever durations are read (the occurrences part
  when a row's duration is zero or unobserved), empty on every row when they
  are thrown away by `-od` or `-d duration`; #618's per-column declaration
  carries that presence rule (D11, D21, D27).

**Release notes: yes.** Proposed bullets:

- "Leave a time bucket's duration and bytes cells empty when no line in it
  carried the metric, instead of printing zero; see docs/usage.md."
- "Compute impact from each message row's reported mean duration, never
  below occurrences alone, which it uses when there is none; see docs/usage.md."
- "Pre-seed the bytes heatmap's range from the index file, as the duration
  heatmap already is; see docs/usage.md."
- "Add an `impact` topic to `--explain` stating how impact is computed; see
  docs/usage.md."
- "Round the per-message bytes mean through `-cp` like every other CSV value;
  see docs/usage.md."
- "Count zero-byte responses in the index file and keep its means at two
  decimals whatever `-cp` says; see docs/usage.md."

---

## 11. Implementation record

**Drop 1 (2026-09-30): the helper at the sites whose output does not change.**
`mean_of($sum, $count)` added to `## SUBS ##` beside `log_bucket`, returning
`undef` unless the count is defined and above zero. Called for the per-bucket
count, bytes and user-defined means, the sort pre-pass's bytes and count means,
and the group calculation's count and user-defined means; the per-bucket
user-defined display value for `mean` reads the stored mean. The per-bucket
projection is one literal with the statistics hash merged when the duration
statistics run, where there were two copies, one per branch. The four
self-assignments of the group calculation are removed, and the count mean there
is assigned without its `if defined count_occurrences` suffix: no reader tests
the key's existence, and an undefined count gives `undef` through the helper.
The two reduction percentages of `pipeline_finalize` take the
`$keys_seen > 0 ? ... : 0` shape (D7).

The helper drops two `defined $sum` tests, the per-message count mean's and
user-defined mean's. Neither changes a value: the read loop increments each
count in the same block that adds to its sum (`if( defined $count ) {` for the
count; the per-configuration block for a user-defined metric, counting
aggregations excepted, which the loop skips), the consolidation merge carries
the sum with its count, and every store constructor initialises `total_bytes`
to 0.

Behaviour-neutral, proved by the harnesses that read the changed sites, all on
this commit's tree, none with a golden or baseline changed:
`validate-csv-output.sh` (25 scenarios, 30 pass),
`validate-statistics.sh` (22 scenarios pass; every cell of all 44 MESSAGES and
STATS comparisons in the drift layer's tightest tier), `validate-statistics-demand.sh`
(102 pass), `validate-aggregate-export.sh` (146 pass), `validate-udm-specs.sh`
(186 pass; the user-defined mean display) and `validate-message-grouping.sh`
(27 pass; the reduction line). No runtime warning on any harness's output.

The pattern entry *Observation counts and gated means* is added to
`docs/architecture-patterns.md` in this drop with its seven sites, marked as
needing refinement until the issue completes (section 5.5).


**Drop 2 (2026-09-30): observation counts kept beside their totals, totals
projected only when counted, bytes processed only when produced and demanded.**

*Counts.* The per-message and per-bucket loops increment `duration_count` beside
the duration total on every timed line, in both models, after the running-mean
update, which reads the count as the count before the observation and no longer
writes it (D29). The time-bucket constructor initialises it in both models; the
message entry creates it on the first increment (D29). Each duration block
takes its entry reference once and adds the total and increments the count
through it. Bytes follow D30: `$bucket_bytes_demand` (the timeline's bytes
column unless hidden, or `-o`) and `$message_bytes_demand` (a retained message
and the MESSAGES CSV or a bytes sort, `-so bytes` included) are resolved in
`adapt_to_command_line_options`, `-ob` switching both off; under its store's
demand a line carrying a bytes value adds to the total, a zero-byte response
included, and increments `bytes_occurrences`, with `$bytes_aggregate_demand`
governing `bytes_min` and `bytes_max`; neither store is initialised with a
bytes total, and the per-bucket statistics pass no longer adds up a bytes total
nothing read. The single-line source that streaming consolidation merges
carries `duration_count => 1` in both models and, for a line carrying bytes
under the message store's demand, `bytes_occurrences => 1` with its extrema, so
the merge, which now gates each family on its count, never drops a line's
total for want of a count; on the
access log that path is not reached (`-V message-grouping`: no inline match),
and the consolidated rows' bytes counts were checked against the log itself:
the gap between `occurrences` and `bytes_occurrences` on the two largest rows
equals the number of their lines whose size is `-` (15,005 and 7,386).
`merge_consolidation_stats` reads the target's count before the merge, hands it
to `merge_bin_state`, which no longer writes a count, and sums the counts after
it; the reinject copies `duration_count` in both models.

*Gates.* The group calculation's observation test is the count
(`$log_messages{$category}{$log_key}{duration_count}`), replacing the durations
list, the bin counter and the positive-total fallback; the per-message bytes
roll-up is gated on `bytes_occurrences`. The per-bucket projection writes
`bytes` and `bytes-HL` only when `bytes_occurrences` is positive and
`duration_sum` and `duration_sum-HL` only when `duration_count` is positive
(D4); the `_nice` cells, the timeline cells, the scaling maxima and the YAML
blocks follow with no change of their own.

*New assertions*, each shown failing on the drop 1 tree for the defect and
passing after:
- `tests/validate-csv-output.sh` scenarios `gated-means-application` and
  `gated-means-access` (`-bs 1 -oe -n 1` over the two committed fixtures of
  section 7): on the drop 1 tree the family group-consistency check fails on
  every bucket carrying one metric and not the other (4 rows and 1 row), and
  the new STATS cell reads fail on each projected zero; the observed-zero reads
  (`bytes=0`, `bytes_occurrences=1`; `duration=0`) pass on both trees. The cell
  reads use a new directive of the validator, `@cell`, which reads one cell of
  the MESSAGES or STATS file by a key column; a key matching no row and a
  column the header lacks were each shown to fail.
- `tests/validate-duration-display.sh` scenarios `unobserved-blank-raw`,
  `unobserved-blank-bin`, `unobserved-blank-hm-raw` and
  `unobserved-blank-hm-bin`: the timeline's duration and bytes total cells,
  located by the layout engine's own offsets, are blank for the unobserved
  buckets and show the zero for the observed ones, with the bucket statistics
  demanded (the latency column) and not demanded (`-hm duration` without `-o`,
  `-V statistics-demand`: `store_demand: 0` for the bucket store), under each
  bucket model.
- `tests/validate-aggregate-export.sh` scenario `unobserved-metric-absent`: the
  YAML series writes no `duration` or `bytes` block for an unobserved bucket
  and keeps an observed zero's.

*Harnesses* on this tree: `validate-csv-output.sh` (27 scenarios, #273's `-od`
scenario and its `-so duration` sibling unchanged), `validate-statistics.sh`
(22 scenarios, every cell of the drift layer in its tightest tier), `validate-statistics-demand.sh`, `validate-aggregate-export.sh`,
`validate-duration-display.sh`, `validate-message-grouping.sh`,
`validate-message-grouping-notices.sh`, `validate-byte-units.sh`,
`validate-bucket-size-units.sh`, `validate-csv-input.sh`,
`validate-histogram-bin-counters.sh`, `validate-profile-render.sh`,
`validate-summary-contribution-bar.sh`, `validate-section-layout.sh`,
`validate-filter-summary.sh`, `validate-numeric-criteria-notices.sh`,
`validate-udm-specs.sh` and `validate-udm-counting.sh` pass, with no runtime
warning; `validate-regression.sh` failed on 21 goldens, as section 7 predicts.
What this run proves of the CSV surfaces is narrower than it reads: the CSV
cache that `validate-csv-output.sh` and `validate-statistics.sh` share
(`tests/lib/csv-cache.sh`) fingerprints only the CSV-writing code and trusts
upstream code for its 60-minute validity period, and this run printed no stale
warning, so its 25 pre-existing CSV scenarios and the drift layer read captures
the drop 1 run had taken, not this tree's output; the two new scenarios were
captured fresh. The run on the amended tree below refreshed every capture (31
stale warnings, the captures 184 minutes old) and is the one that validates
this drop's CSV surfaces.

*Goldens.* The 21 were re-captured with `capture-regression.sh` into a scratch
directory and compared line by line with the committed references before any
was replaced: every one of the 135 changed lines differs only where a `0 B`
total cell became blank, at the same width (D4: the application-log captures,
in which most one-minute buckets carry no bytes). No duration cell moved: no
capture holds a bucket whose lines carry no duration among lines that do. The
other 53 re-captured byte-identical. After replacing the 21,
`validate-regression.sh` passes 74 of 74.

*User documentation.* `docs/usage.md`: the display and output section says a
bucket in which no line carried a metric leaves its total empty on the
timeline and in the CSV and YAML files, and the aggregate export's series
bullet says no block is written for such a metric.

*Loop A/B* (section 9: each drop that changes the loop), drop 2 against drop 1
(`6d1a2ac`), ten interleaved order-balanced rounds on this host with the
benchmark runner's invocation, per-round delta against the same round's drop 1
run, median and range (`tests/profile/results/616-drop-ab/`):

| Selection | Drop 1 median (range) s | Drop 2 per-round delta | Rounds slower |
|---|---|---|---|
| day of web-server access log, default (raw) models | 9.649 (9.229 to 10.309) | +0.215 s (−0.084 to 0.558), +2.2% | 9 of 10 |
| the same, `-mdm bin -bdm bin` | 11.986 (11.530 to 13.467) | +0.061 s (−1.113 to 0.681), +0.5% | 6 of 10 |
| day of application script log carrying `durationMS=`, default models | 2.478 (2.363 to 2.551) | −0.030 s (−0.135 to 0.061), −1.2% | 4 of 10 |

Peak memory moves by under 0.5 MB on every selection.

The raw-model cost exceeds section 8's 1 percent threshold and was
investigated. The drop adds, on every line of that access log (each carries a
duration and a size, and the standard invocation demands no bytes aggregate), a
duration-count increment and a bytes-count increment on each store: four
hash-field increments per line, about 280 ns per line in all. A variant taking
the message and bucket entry references once in their duration blocks, so the
count increment reuses the reference the total's addition looked up, measured
the same in a second ten-round run (+0.248 s against drop 2's +0.249 s, both
against drop 1), so the cost is the increments themselves, not the lookups; the
variant was not then kept. These ten-round runs were taken while drop 1 itself
spread by about 11 percent on the access log; the constants measured
afterwards and the twenty-round runs below supersede their reading. Drop 4
removes the per-line impact derivation (a division, a power and a logarithm on
every duration-bearing line), measured in its own A/B.


*Observation-count candidates* (2026-09-30, after D30; prototype
`prototype/616-observation-count-arms/`, results
`tests/profile/results/616-observation-count-arms/`). The per-line cost of the
counts was measured first as constants on this host: an increment of a message
entry's field through the full key (`$log_messages{$category}{$log_key}{...}`,
a key of about 120 characters) costs 98 ns net per line, through an entry
reference taken once 19 ns; a bucket entry's field through `$log_analysis{$bucket}`
36 ns, through a reference 19 ns. Four forms were then built from the tree by
asserted edits and proved byte-identical to each other (STATS, MESSAGES, YAML
and terminal output, 123 comparisons over 14 option shapes: both fixtures,
access and script-log slices, raw and bin models, consolidated, `-od`,
`-so bytes`, `-hm`, `-hb`): `full` (the counts reached by full-key lookups),
`cached` (one entry reference per duration block), `nocount` (no count
increment: a total is not pre-set to zero, so its existence is the observation
test, the divisors come from the statistics stores, and the bytes count is kept
only under the bytes aggregate demand) and `oneref` (every message-entry and
bucket-entry lookup of the loop's message and bucket sections through one
reference: 29 and 36 lookups, most of them predating this issue). Twenty
interleaved order-balanced rounds on full files, per-round delta against the
same round's drop 1 run, median, and the rounds in which the form was slower:

| Selection (drop 1 median, range) | `full` | `cached` | `nocount` | `oneref` |
|---|---|---|---|---|
| day of web-server access log, raw models (8.878 s, 8.756 to 9.149) | +0.014 s, 11/20 | +0.027 s, 14/20 | −0.041 s, 8/20 | −0.546 s (−6.2%), 0/20 |
| the same, `-mdm bin -bdm bin` (11.033 s, 10.950 to 11.261) | −0.157 s, 1/20 | −0.135 s, 5/20 | −0.165 s, 2/20 | −0.678 s (−6.2%), 0/20 |
| day of application script log carrying `durationMS=`, raw (2.264 s, 2.237 to 2.398) | +0.021 s, 13/20 | +0.015 s, 14/20 | +0.025 s, 14/20 | +0.029 s, 15/20 |

Peak memory is within 0.3 MB of drop 1 for every form.

Reading. On the access log the counts in any form are within the noise of drop
1 (under 0.3 percent), where the constants predict about 0.12 s for `full` and
0.04 s for `cached`: D30 removed the per-message bytes work of the standard
invocation (a full-key lookup and an addition on every line), which offsets
them. The earlier ten-round runs of this drop (+2.2 percent, then +1.4 percent)
were taken while drop 1 itself spread by about 11 percent; these supersede
them. `nocount` against `cached` is −0.048 s on the raw access log, slower in
7 of 20 rounds: not separable from noise at this resolution. `oneref` is the
one form clearly apart: 6.2 percent faster on the access log in both models, in
every round, from the loop's pre-existing full-key lookups, which it replaces;
on the script log, whose lines mostly carry no metric, it makes no difference.

*The peak memory the run reports.* `validate-byte-units.sh` scenario
`one-notation-reach` failed intermittently on this drop (3 of 6 runs; 0 of 6 on
the release tip): the summary's MAXIMUM MEMORY USED row and the aggregate
export's `max_memory_used` read the running peak at two moments, before and
after the summary renders, and a render that raised the peak across a 0.1 MB
rounding step made them differ (`41 MB` against `41.1 MB`). Pre-existing in the
order of the end-of-run sequence, exposed by this drop's memory profile, and
fixed here at the architect's direction: `$reported_max_memory_usage` is taken
once after the measurement that precedes the summary, and the summary row, its
memory shares and the export read it; the index row and `-V benchmark-data`
keep the lifetime peak. The scenario then passed 8 of 8 runs.


*Harnesses on the amended tree* (D30, the cached entry references, the reported
peak): `validate-csv-output.sh` (27 scenarios, 32 pass), `validate-statistics.sh`
(22 scenarios, every drift cell in the tightest tier), `validate-statistics-demand.sh`,
`validate-aggregate-export.sh`, `validate-duration-display.sh`,
`validate-regression.sh` (74 of 74), `validate-byte-units.sh`,
`validate-message-grouping.sh`, `validate-message-grouping-notices.sh`,
`validate-heatmap-palette.sh`, `validate-histogram-bin-counters.sh`,
`validate-section-layout.sh`, `validate-summary-contribution-bar.sh`,
`validate-filter-summary.sh`, `validate-numeric-criteria-notices.sh`,
`validate-csv-input.sh`, `validate-profile-render.sh`,
`validate-bucket-size-units.sh`, `validate-index-read-back.sh`,
`validate-udm-specs.sh` and `validate-udm-counting.sh` pass, with no runtime
warning.

*Hand-forward to #620* (hoisting the read loop's per-line work): the `oneref`
form above, every message-entry and bucket-entry lookup of the loop's message
and bucket sections made through one reference, measured 6.2 percent faster on
a day of web-server access log in both models, in every one of twenty rounds,
with byte-identical output. It changes lines that predate this issue and is
left to #620.

**Drop 3 (2026-09-30): one statistics sub over both store shapes (D9, D14).**
`derive_moment_statistics($n, $total, $sum_of_squares, $moments, $demand, $t)`
derives the mean (through `mean_of`), the standard deviation and coefficient of
variation from the sum of squares, and, under shape demand at n ≥ 4, skewness,
kurtosis and the bimodality coefficient from the three central-moment sums,
recording the shape group's `-V statistics-demand` outcome; it returns the six
values. `calculate_statistics` (raw) computes the moment sums with its pass over
the sorted samples, only under shape demand at n ≥ 4, and passes them;
`calculate_statistics_bin` passes the running sums its update keeps, under
shape demand. Both keep their names, their percentile ladders (D9: percentiles
stay per model) and their `stats_calls` count on every call, and both gate
their early return on `duration_count > 0`, the one gate spelling; the three
raw callers (the bucket pass, the sort pre-pass and the group calculation) hand
the count in the aggregate they build.

*Proof (D14),* on captures produced fresh for the run (the CSV cache emptied by
`tests/cleanup-test-artifacts.sh` first, since the cache does not fingerprint
statistics code): `validate-statistics.sh` passes 22 scenarios, raw and bin,
with every cell of all 44 MESSAGES and STATS comparisons in the drift layer's
tightest tier, so no advisory on `mean`, `std_dev`, `cv`, `skewness`,
`kurtosis` or `bimodality_coef`, and the L3 oracle layer OK on all 44; no drift
baseline was re-blessed. `validate-statistics-demand.sh` passes 102 (the
`stats_calls` and group counters, whose producers keep their names) and
`validate-csv-output.sh` 27 scenarios; no runtime warning.

*Cost.* The sub runs once per key after the read loop, never per line. Its
overhead over the inline arithmetic measured 605 ns per call on this host
(the call and the `mean_of` call inside it). The run of the corpus with the
most calls is a day of web-server access log under `-so p99`, 3,194 calls:
about 2 ms. The corpus's highest-cardinality selection (286,621 message keys)
carries no duration and makes no call; were every such key timed, the cost
would be about 0.17 s.

*The CSV cache fingerprints the whole of `ltl`* (architect's direction,
2026-09-30). `csv_cache_ltl_signature` in `tests/lib/csv-cache.sh` digests the
whole `ltl` source and the column rules, where it digested only the subs named
for CSV and the CSV-writing lines, which let a harness run within an hour of an
upstream edit validate the previous tool's output (drop 2's first run above).
Shown on this tree: a first `validate-csv-output.sh` run after the change
refreshed its 28 cached scenarios; a second reused them (the one refresh being
the cache-validity check's own); a third, after a comment line was added inside
`calculate_statistics`, refreshed all 28 again, where the old digest would have
reused them. All three passed. A fresh capture costs about 8.5 minutes on this
host, paid on the first statistics-harness run after an edit.
`tests/HARNESS-DESIGN.md` § Cached capture artifacts expire and the
cache-validity assertions of `validate-csv-output.sh` state the rule.

**Drift harness: the duration row checks read the CSV's own column names**
(architect's direction, 2026-09-30, found while preparing drop 4). Since #432
prefixed the duration statistic columns with `duration_`, five Layer 2 checks of
`tests/statistics-drift/compare-statistics-drift.pl` read bare names (`min`,
`mean`, `max`, `p1` … `p99999`, `iqr`) that no MESSAGES or STATS row carries,
and passed without checking anything: duration order, duration derivation,
percentile monotonicity, percentile bounds and IQR. Measured on a copy of the
committed `tomcat-default` MESSAGES baseline with a percentile ladder broken, an
IQR shifted and a mean altered: the engine as it stood failed it on Layer 1
drift alone, with no Layer 2 finding; with the lookups renamed, the
percentile-order, IQR and derivation checks each fired; over every committed
baseline (44 files) the renamed checks report nothing. The lookups now read the
`duration_` columns. The derivation check, which asserted `mean == duration /
occurrences`, the divisor D5 and D11 remove (the mean divides by the lines that
carried a duration), now asserts `duration_mean >= duration / occurrences`,
equal when every line carried a duration; the CSV carries no timed-line count,
so the exact relation is not checkable from the file. A mean set below
`duration / occurrences` was shown to fail it. The engine now refuses to start
when a column a Layer 2 check reads is unknown to the rules TSV (shown with a
renamed column: exit 2, the column named), so a future rename cannot silence the
checks again. The L1 and L2 `produced_by` strings that named subs no longer in
`ltl` (`accumulate_log_record`, `finalize_buckets`,
`calculate_percentiles_for_bucket`, `calculate_shape_statistics`) name the subs
that produce those values today.

**Drop 4 (2026-09-30): impact derived once, from the reported mean (D5, D11,
D20, D21, D25, D27).** `impact_of($entry)` returns
`ln(max(mean, 1) ** $impact_time_exponent * occurrences)` with the mean from
`mean_of(total_duration, duration_count)`, 0 when there is none, and `undef`
under `-od` or `-d duration` (both set `$omit_durations`). It runs after the
read loop: in the sort pre-pass for every key under `-so impact`, otherwise in
the group calculation for the retained keys. The per-line derivation in the
read loop and the recompute after consolidation are removed.

*Assertions*, each shown failing on the drop 3 tree:
- `compare-statistics-drift.pl` Layer 2 `impact_formula`: impact equals the
  formula within 1e-9 relative and is never empty. On the committed baselines it
  failed on exactly 131 cells, the 129 and 2 of section 3 item 2.
- Three fixture scenarios in `tests/statistics-drift/scenarios.tsv` with
  committed baselines: `gated-means-access` and `gated-means-access-reversed`
  (the access fixture and its copy with one path's durations reversed; both
  write `impact=28.077308218557` for that path, where the drop 3 tree wrote
  32.236 in one order; the path with durations 1 and 0 writes 0.693, where it
  wrote 0) and `gated-means-consolidated` (the four `Processing request` lines
  at `-g 50 -so impact`, kept alone by `-i Processing.request` because the
  fixture's other lines also consolidate at that sensitivity: occurrences 4,
  duration 400, mean 200, impact 38.4745159, where the drop 3 tree wrote 33.622).
- `validate-csv-output.sh`: the `impact` rules row's `required` becomes
  `every-row:duration`, a value the validator now reads as populated on every
  row while the family is active, exempt from the per-row family check, and
  absent or empty when the family is switched off (D27); scenarios
  `gated-means-impact` (the untimed pair writes `0.693`, the zero-duration key
  `0`, by `@cell` reads) and `gated-means-impact-discard` (`-d duration`, every
  impact cell empty). On the drop 3 tree's MESSAGES CSV the every-row check
  failed on each of its four empty impact cells.

*Explain.* The `impact` topic of `--explain`, under a new Ranking group of
`--help statistics`, states the formula, the floor, the occurrences-only case
and the undefined case (D25), mirrored in `docs/explain/statistics.md`; the
`-so` paragraph of `docs/usage.md` states the rule and points at it;
`validate-explain.sh` lists the topic. The number of leading statistics groups
`--help statistics` slices is now counted from the group list, where it was a
literal.

*Baselines re-blessed*, each change attributed against the committed version:
131 `impact` cells over nine scenarios (every new value equal to the formula; 2
were empty), and 425 `bytes_nice` cells (372 MESSAGES, 53 STATS), each the same
byte count written in SI units where the baseline held IEC: #608's default
notation, never re-blessed because the drift engine does not compare the `_nice`
text columns. No other cell and no row order moved.

*Harnesses* (fresh captures): `validate-csv-output.sh` 29 scenarios,
`validate-statistics.sh` 25 scenarios (every drift cell in the tightest tier),
`validate-statistics-demand.sh`, `validate-regression.sh`,
`validate-message-grouping.sh`, `validate-message-grouping-notices.sh`,
`validate-aggregate-export.sh`, `validate-duration-display.sh`,
`validate-explain.sh` (695) and `validate-help-content.sh` pass, no runtime
warning. By the architect's direction of the same day, drops from here run
targeted checks only, and the per-drop loop A/B is left to the completion
gate's before/after benchmark: this drop removes per-line work (a division, a
power and a logarithm on every duration-bearing line) and adds none.

**Drop 5 (2026-09-30): the per-message bytes mean stored precise (D6).** The
group calculation stores `bytes_mean` through `mean_of(total_bytes,
bytes_occurrences)` for the retained keys (the sort pre-pass has already done so
for every key under `-so bytes_mean`); `print_message_summary` reads the stored
value, where it rounded half up to an integer, and the MESSAGES CSV rounds it
through `format_csv_value` like the STATS CSV. The MESSAGES rules row for
`bytes_mean` takes the STATS row's type, `float` with 5 decimals. The drift
engine's `bytes_deriv` check drops its one-byte integer tolerance for 1e-9
relative, and names the sub that stores the mean.

*Assertions:* `validate-csv-output.sh` scenarios `gated-means-bytes-mean-default`
and `gated-means-bytes-mean-full` (the access fixture's path with sizes 512 and
513 alone in its minute, at `-bs 1`): the MESSAGES row and the STATS row both
write `512` at the default precision and both `512.5` under `-cp full`. On the
drop 4 tree the full-precision scenario failed: MESSAGES wrote `513`.

*Baselines re-blessed*, 19 scenarios re-captured, each change attributed against
the committed version: 99 MESSAGES `bytes_mean` cells moved (the 97 of section 7
and the `/gm/sizes` row of each new access-fixture scenario) and no other cell
or row order; all 414 MESSAGES `bytes_mean` cells now equal `bytes /
bytes_occurrences`. The drift engine's Layer 2 checks pass on all 50 baseline
files. Targeted checks only (the architect's direction): the four CSV-output
scenarios above and their neighbours (`access-bytes-duration`,
`gated-means-access`) pass.

**Drop 6 (2026-09-30): the run index (D8, D15, D16, D17, D24).**
`format_csv_value` takes an optional third argument, a fixed decimal count that
bypasses `-cp` and its full mode. `write_index_file` writes the six means (the
duration, bytes and count means of the file row and of the selection row)
through `mean_of` and `format_csv_value` at two decimals, trailing zeros
stripped, and the empty cell for no data; the bounds and the not-applicable
cells keep `-`. The two index blocks of `read_and_process_logs` (file row and
selection row) take every line whose bytes field parsed, zero included, as a
bytes observation, as both statistics stores do. `read_index_file` pre-seeds
the bytes heatmap from `file_bytes_min` and `file_bytes_max`, the keys the
index writes, where it looked up `bytes_min` and `bytes_max` and found nothing.
The heatmap's log axis already floors at 1, so a zero bytes minimum needs no
floor of its own.

*Assertions*, four new scenarios of `tests/validate-index-read-back.sh`, each
shown failing on the drop 5 tree by the same run made directly:
- `index-means-fixed-precision` (the twelve-line access fixture): the file
  row's `duration_mean` is `128.75` under the default `-cp`, `-cp 0`, `-cp 4`
  and `-cp full`; `count_mean` is empty on both rows (the drop 5 tree wrote
  `-`), and the `count_min` bound keeps `-`.
- `index-means-integral` (the gated-means access fixture under
  `-i /gm/order`): the selection row's `duration_mean` is `50` under the default
  precision and `-cp full` (the drop 5 tree wrote `50.00`).
- `index-bytes-counted`: the file row holds `file_bytes_occurrences` 12,
  `file_bytes_min` 0 and `file_bytes_mean` 18683.33, and the STATS CSV of the
  same run under `-cp 2` writes the same bytes mean (the drop 5 tree wrote 11,
  2 and 20381.82).
- `index-heatmap-bytes-preseed`: with both index rows' `file_bytes_max` edited
  to 999999, `-hm bytes -V index-read-back` reports
  `heatmap_preseed_max: 999999` (the drop 5 tree, reading the same edited
  index, `index_used: yes`, reported the live 102400).

The 59 existing assertions of the harness pass on this tree with the prebuilt
index fixture unchanged. `docs/usage.md` carries no description of the index
file's contents; `features/index-file.md` and `features/179-index-read-back.md`
are brought up to date at delivery (section 10).

**Drop 7 (2026-09-30): one running-mean update, arm (c) (D10, D12, D28, D29).**
`welford_update($t, $n_a, $n_b, $mean_b, $M2_b, $M3_b, $M4_b, $shape)` adopts
the source into a target with no observation, applies the one-observation
Welford-Pébay update when the source holds one observation, and the Chan-Pébay
parallel combine otherwise; it keeps the moment sums only under shape demand
and never writes a count (D29). The per-message and per-bucket loop sites call
it with a one-observation source and their store's shape flag, before the count
is incremented; `merge_bin_state` calls it with the source's state and the
target's count taken before the merge, in place of its own adoption and
combine. No inline copy of the update remains.

*Proof:* the tree before and after this drop, run by the prototype's
`prove.sh` on the 100k-line slices of the access log and the application script
log at `-mdm bin -bdm bin -o -cp full` (the shape statistics demanded), plain
and consolidated (`-g -m uuid`): every MESSAGES and STATS cell of all eight
comparisons byte-identical, as the prototype measured for arm (c); no runtime
warning. The bin-model benchmark pair of section 8 runs at the completion gate.

**Completion gate (2026-10-01, `39c7840`, `$version_number` restored to
`0.19.0`).** The full suite, 44 harnesses, captured one file each, CSV output
first and statistics second on an emptied cache: every one exits 0 with
assertions run (3,024 passing assertions in the harnesses that print a count,
and 27, 21, 33, 12 and 40 in the five that print their own format), and no
runtime warning in any output.

Before/after benchmarks on this host (`616-before*` on `a32eb32` at the start of
implementation, `616-after*` on the gated commit; one run each, about twelve
hours apart):

| Case | Before total | After total | Change | Peak RSS |
|---|---|---|---|---|
| day of web-server access log, standard (raw models) | 9.4 s | 8.7 s | −7.4% | 99.9 → 99.4 MB |
| the same, `-mdm bin -bdm bin` | 11.8 s | 11.1 s | −6.6% | 51.3 → 50.5 MB |

No metric regresses beyond 1 percent (`format_scan_subs`, the compiled scan
subs' resident size, reads +48 KB and +16 KB). The twenty-round interleaved runs
of drop 2 are the firmer measure of the counts' cost; these single runs agree
in direction: the drops remove more per-line work (the per-line impact
derivation, the per-message bytes work of a run with no bytes consumer) than
they add. The four TSVs are deleted, as section 3 of the workflow directs.

The visual check of criterion 3, at `-bs 1`: on the day of application script
log, minutes whose lines carry no duration show a blank duration cell beside
minutes showing their total; on the script log carrying duration, bytes and
counts, every minute without bytes shows a blank bytes cell where `0 B` was
printed. Criterion 18: no division of a sum by a count remains outside
`mean_of`, `derive_moment_statistics` and the rates (the remaining divisions
over a count are bin and heatmap geometry, an absorption rate and bar scaling).

