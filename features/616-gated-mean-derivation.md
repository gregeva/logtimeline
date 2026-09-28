# One gated derivation of means and totals over accumulators that always carry an observation count (Issue #616)

## Status

**Specification agreed with the architect 2026-09-28 on branch
`616-gated-mean-derivation` off `release/0.19.0`; implementation not started.**
The specification was written at `58f8d94`. No code has changed, the version is
not stamped, and the `before` benchmarks are not captured: they are taken on the
release-branch commit this issue lands on, after #273 (store the duration total
precise, format at the output boundary) has merged (D19, the landing order).

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
pass as designed).

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
    stays there (D21: impact is defined only while durations are read). The
    group-consistency assertion of `tests/csv-output/validate-csv-output.pl`
    holds every conditional column of an active family populated or empty
    together on each row. Under D11 a row whose duration is unobserved while
    durations are read carries impact as its occurrences part beside empty
    duration columns, which that assertion reads as a failure while the row
    keeps `conditional:duration` (section 5.2 under D11).
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

---

## 4. Locked decisions

D1 to D10 are the architect's locks of 2026-09-27, restated verbatim from the
issue body with their source in the review-progress rows. D11 to D19 are his
decisions of 2026-09-28, in reply to this specification's draft; D20 to D25 are
his decisions of the same day on the follow-up questions the review of this
specification left open, and D26 his decision of the same day given on #619's
turn (one per-run key cut). Nothing else in this document is numbered Dxx.

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

---

## 5. Design

Everything in this section follows from D1 to D26 unless it is labelled
**proposed**. A proposed element is implementation detail the architect did not
decide: a name, a spelling, an argument shape.

### 5.1 The sites

| Quantity | Site (sub :: snippet) | Decision |
|---|---|---|
| Store constructors | `read_and_process_logs` :: `total_duration => 0,` (message and bucket, both models) | D1, D4, D18 |
| Per-message duration count | `read_and_process_logs` :: `my $n_old = $entry->{duration_count};` (bin, inside `if( $message_duration_stats_demand ) {`); raw has none | D1, D18 |
| Per-bucket duration count | the same snippet under `if( $bucket_duration_stats_demand ) {` (bin only) | D1, D18 |
| Bytes count, both stores | `read_and_process_logs` :: `if( $e->{bytes_occurrences}++ ) {` under `if( $bytes_aggregate_demand ) {` | D1 |
| Welford update, twice in the loop | `read_and_process_logs` :: `my $delta_n  = $delta / $n;` | D10, D12 |
| Welford merge | `merge_bin_state` :: `my $mean_ab = $mean_a + $delta * $n_b / $n_ab;` | D10, D12 |
| Impact in the loop | `read_and_process_logs` :: `if( $duration > 0 ) {` and `my $mean = $log_messages{$category}{$log_key}{total_duration} / $log_messages{$category}{$log_key}{occurrences};` | D5, D11 |
| Impact after consolidation | `group_similar_messages` :: `if (defined $entry->{total_duration} && $entry->{occurrences} > 0 && $entry->{total_duration} > 0) {` | D5, D11 |
| Duration statistics, raw | `calculate_statistics` :: `my $sum_sq_dev = $bucket_data->{sum_of_squares} - $duration_count * ($mean ** 2);` | D9 |
| Duration statistics, bin | `calculate_statistics_bin` :: `my $sum_sq_dev = $sidecar_entry->{sum_of_squares} - $n * ($mean ** 2);` | D9 |
| Per-bucket projection (twice, one per demand branch) | `calculate_all_statistics` :: `duration      => $log_analysis{$bucket}{total_duration},` and `bytes         => $log_analysis{$bucket}{total_bytes},` | D4 |
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
| Column-scaling maxima and scaled keys | `normalize_data_for_output` :: `$max_total{duration} = $log_stats{$bucket}{duration} if ( defined $log_stats{$bucket}{duration}` | D4 |
| Timeline latency block | `print_bar_graph` :: `if( defined $log_stats{$bucket}{bytes} \|\| defined $log_stats{$bucket}{p50}` | D4, D23 |
| STATS `_nice` cells | `print_bar_graph` :: `(defined $log_stats{$bucket}{$key} ? ltrim(format_duration_total(` and its bytes twin | D4 |
| YAML series blocks | `write_aggregate_export` :: `next unless defined $stats->{duration};` and `next unless defined $stats->{bytes};` | D4 |
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
- Both constructors initialise `duration_count => 0`; the lazy message entry
  gains `bytes_occurrences => 0` so the loop increments without a definedness
  test.
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

- The per-bucket projection writes `duration` only when `duration_count > 0` and
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
- The MESSAGES rules row for `impact` stays `conditional:duration`, family
  `duration`, type and decimals unchanged (D21): impact is defined only while
  durations are read. Section 3 item 13 records how the family group-consistency
  assertion reads a row whose duration is unobserved while durations are read.
  #618 (one declaration per column) labels impact a `shape` statistic in the
  rules; whichever lands later rebases the row, and its declaration reads D21's
  rule: impact is defined whenever durations are read and undefined, with an
  empty cell, when they are thrown away.
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
  rows write `0` (`log(1)`), so the duration family is consistent on them.
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
  duration family, defined whenever durations are read and undefined when they
  are thrown away (D21), under D11 above.
- **#620 (hoisting the loop's per-line option handling).** Blocked by this issue.
  If arm (d) lands, converting the two capture-mode compares to booleans, #620's
  record is trued up in the same change so the step is not done twice.
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

- [ ] **Unobserved buckets write empty cells.** On the application-log fixture
  with a bucket whose only line carries bytes and no duration, and the
  access-log fixture with a bucket whose only line carries `-` for its size, run
  with `-bs 1 -oe -ni -o -n 1`: the STATS CSV passes the existing
  group-consistency assertion of `tests/validate-csv-output.sh` (it fails on the
  base commit, for the zero projection), and the unobserved buckets'
  `duration`/`duration_nice` and `bytes`/`bytes_nice` cells are empty.
  *Assertable:* two new scenarios in `validate-csv-output.sh` reusing its
  group-consistency mechanism.
- [ ] **Observed zeros still print.** On the access-log fixture, a bucket whose
  only line carries a zero-byte response writes `bytes=0`, `bytes_occurrences=1`;
  a bucket whose only duration is 0 writes `duration=0`. *Assertable:* same
  scenarios, cell reads.
- [ ] **The timeline shows the same empty cell, with and without statistics
  demand, in both models.** Same fixtures, rendered at a pinned width with
  `--debug-layout`, plain and with `-hm duration` and no `-o` (bucket statistics
  demand off), each under `-bdm raw` and `-bdm bin`: the unobserved bucket's
  total cell in the duration and bytes columns is blank. This also proves the
  count exists without a consumer demanding it, in both models (D1, D18).
  *Assertable:* a scenario in `tests/validate-duration-display.sh` using
  `timeline_cell_report` from `tests/lib/rendered-output.sh`. The rendered rows
  are also looked at on a real application log before the work is called done.
- [ ] **Impact equals the formula on every row.** For every MESSAGES row of a
  run that reads durations: `impact == ln(max(duration_mean, 1)^7 × occurrences)`,
  with an empty `duration_mean` read as 0, so `impact == ln(occurrences)` when
  the mean is one unit or below, zero or empty (D11, D20); `impact` is never
  empty on a retained row. Checked within 1e-9 relative at `-cp full`, the
  precision the drift scenarios write. *Assertable:* a new L2 intra-row
  invariant in `tests/statistics-drift/compare-statistics-drift.pl`, which then
  checks every drift scenario in both models, consolidated ones included. It
  fails on the base commit on 129 cells (the 45 order-dependent ones and the
  122 whose sub-unit mean gives a negative duration term, 38 of them in both)
  and on 2 empty cells (section 3 item 2).
- [ ] **Impact does not depend on line order, and a consolidated row's impact
  follows its reported mean.** Two access-log lines of one path with durations
  100 and 0, in both orders: both runs write `impact=28.077`. The four-line
  application-log consolidation fixture at `-g 50 -so impact` writes
  `duration_mean=200`, `occurrences=4`, `impact=38.475`. *Assertable:* fixture
  scenarios in `validate-statistics.sh` (L1 against a committed baseline, plus
  the L2 invariant above).
- [ ] **A duration never ranks a row below none.** On the access-log fixture, a
  path of two lines with durations 1 and 0 writes `duration_mean=0.5`,
  `occurrences=2` and `impact=0.693`, the same as a key of two lines with no
  duration, where today's formula gives it a negative value (D20).
  *Assertable:* a fixture scenario in `validate-statistics.sh` (L1), and the L2
  invariant above.
- [ ] **With no duration mean, impact is the occurrences part; with the
  duration thrown away, it is undefined.** On the application-log fixture, a
  key of two lines with no duration writes `impact=0.693`, and a key of one
  zero-duration line writes `impact=0`; under `-od`, and again under
  `-d duration`, every row's `impact` cell is empty, as are every duration
  column and `duration_nice` (D21). *Assertable:* a fixture scenario in
  `validate-csv-output.sh` with a `-d duration` twin, and the `-od` scenario of
  #273 (store precise) unchanged.
- [ ] **One value for one mean.** On the access-log fixture (one path, sizes 512
  and 513 in one bucket): MESSAGES and STATS `bytes_mean` are both `512` at the
  default precision and both `512.5` under `-cp full`. *Assertable:* fixture
  scenario in `validate-statistics.sh` (L1), and `validate-csv-output.sh` with the
  MESSAGES `bytes_mean` rules row retyped to the STATS row's type.
- [ ] **Nothing per message under `-n 0`.** The existing assertions of #458 (the
  per-message store never populated under `-n 0`) keep passing. *Assertable:*
  existing harness coverage, unchanged.
- [ ] **The index writes the empty cell for no data and keeps two decimals
  whatever `-cp` says.** On the committed twelve-line access fixture,
  `ltl-index.csv`'s `duration_mean` is `128.75` under the default `-cp`, `-cp 0`,
  `-cp 4` and `-cp full` alike; `count_mean` (the fixture has no count lines) is
  empty on both rows; the `count_min` and `count_max` bounds keep `-`; a mean
  that is a whole number writes without decimals (for example `100`, not
  `100.00`) under every one of those `-cp` settings, on a fixture chosen so
  that one of the six means is integral.
  *Assertable:* new scenarios in `tests/validate-index-read-back.sh`, the
  harness whose subject is the index, one of them run under the `-cp` settings.
- [ ] **The index counts bytes as the stores do.** On the same fixture, the
  index's `file_bytes_occurrences` is `12`, `file_bytes_min` is `0` and
  `file_bytes_mean` is `18683.33`, and the STATS CSV of the same run under
  `-cp 2` writes `bytes_mean=18683.33`. *Assertable:* a scenario in
  `validate-index-read-back.sh` reading both files.
- [ ] **The bytes heatmap is pre-seeded from the index.** On a scratch copy of
  the committed twelve-line access fixture whose index row has
  `file_bytes_max` edited to 999999, `-hm bytes -bs 1440 -V index-read-back`
  reports `heatmap_preseed_max: 999999`, as `-hm duration` reports an edited
  `duration_max` (D24). *Assertable:* a scenario in
  `validate-index-read-back.sh`; it fails on the base commit, which reports the
  live maximum `102400`.
- [ ] **`--explain impact` states the rule.** The topic renders and is listed by
  `ltl --explain`, and it states the formula, the floor, the occurrences-only
  case and the undefined case (D25). *Assertable:* `impact` added to the topic
  list of `tests/validate-explain.sh`, whose `all-topics-render` scenario renders
  every listed topic; the content is checked by reading.
- [ ] **The YAML export omits an unobserved metric.** On the two
  zero-projection fixtures, run with `-bs 1 -oe -ni -o -n 1`, the aggregate
  export's series for the unobserved bucket carries no `duration` block
  (application-log fixture) and no `bytes` block (access-log fixture), and the
  observed buckets keep theirs. *Assertable:* a new scenario in
  `tests/validate-aggregate-export.sh`; it fails on the base commit, where the
  blocks read `sum: 0`.
- [ ] **One statistics sub changes no statistic in either model.** On the drop
  that lands D9, every drift scenario, raw and bin, shows zero advisories on
  `mean`, `std_dev`, `cv`, `skewness`, `kurtosis` and `bimodality_coef` against
  its own committed baseline, and the L3 oracle layer passes for both models.
  The drop runs before any baseline is re-blessed. *Assertable:*
  `validate-statistics.sh`.
- [ ] **The Welford arm is chosen from a measurement.** The prototype's table
  (arms (a) to (d), medians with ranges, at the bin model on both stores and on
  a consolidating selection) and the chosen arm are written into this document
  before the drop that lands it; that drop's drift run lists every moved cell
  in the mean, standard deviation, coefficient of variation and shape columns
  per bin scenario, non-consolidated and consolidated separately, each
  attributed. *Assertable:* the prototype's exit and `validate-statistics.sh`.
- [ ] **The per-line cost is measured and reported.** The standard pair and the
  bin-model pair of section 8, compared with `compare-results.sh summary`,
  reported with the count increments' cost (D18) and the update's cost (D12)
  named. *Assertable:* section 8.
- [ ] **The helper is the only derivation.** No division of a sum by a count
  remains outside `mean_of`, the one statistics sub and the rates.
  *Unassertable* as a behaviour; checked in review by grep for `/ $` over a count
  or occurrences field.
- [ ] **The diagnostic is gated.** *Unassertable*: unreachable today (section 3
  item 4); checked by reading.
- [ ] **The landing order holds.** #273 (store precise, format at the output boundary) is merged into the release branch
  before this issue's PR opens, #273's `-od` scenario passes on this branch, and
  the native edges of D19 are recorded. *Unassertable* as a behaviour; checked
  at delivery.
- [ ] **The full harness suite passes.** *Assertable:* the completion gate.

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
| `tests/csv-output/rules/messages-columns.tsv` | `bytes_mean` becomes `float`, 5 decimals, as in the STATS rules; `impact` unchanged, in the duration family | D6, D21 |
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

**Prototype: required by D12, measurement-only, trigger execution frequency ×
per-execution cost** (`prototype/README.md`). Question: which arm of section 5.2
under D10, D12 lands, given its per-line cost at the bin model? Arms (a) to
(d). Method: the interleaved order-balanced driver of
`prototype/342-read-loop-cost-curve/`, ten rounds, medians with ranges, on the
access-log and application-log selections at `-mdm bin -bdm bin`, and on a
consolidating selection (`-g -m uuid -mdm bin`) for the merge's one-line case,
after a behaviour proof per arm on the 100k-line slice: arms (a), (c) and (d)
byte-identical to the base on every statistic; arm (b) with every moved cell in
the mean, standard deviation, coefficient of variation and shape columns listed
and attributed (D12). Staged scale: a
100k-line slice for the proof, the full day for timing. Exit: the arm that
lands, recorded here as a finding with its table. Cost: about half a day of
machine time.

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
| 4 | impact derived once after the loop, occurrences part without a mean (D5, D11), the duration term floored (D20), undefined when the duration is thrown away (D21); the `impact` topic of `--explain` (D25) | the impact criteria and the new L2 invariant; the 129 moved and 2 empty impact cells re-blessed; #273's `-od` scenario passing unchanged; the explain topic rendered; loop A/B |
| 5 | the bytes mean stored precise (D6) | the one-value criterion; the 97 cells re-blessed; rules row retyped |
| 6 | the index: means (D8, D15, D16), bytes population (D17), the heatmap's bytes pre-seed (D24) | the index criteria, the `-cp` scenario, the pre-seed scenario |
| 7 | the one Welford formula (D10, D12), in the arm the prototype's table supports | the prototype's table recorded first; the bin-model pair; the drift run's moved-cell list |

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

- on #616 (this issue): the specification agreed, D11 to D26 transcribed by what each means;
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
  duration family, defined whenever durations are read (the occurrences part
  when a row's duration is zero or unobserved) and undefined, with an empty
  cell, when they are thrown away (D11, D21).

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
