# Feature: the histogram bin-counter `-V` emitter gates its path label on observed values

Record for issue #546 (BUG: the histogram bin-counter -V emitter labels a
consumer unified when no value was observed, so the no-consumer state the
contract promises is misreported).

Owning contract: `features/187-histogram-bin-counter-percentiles.md`
§ R7 (`-V` observability), § R10 (per-consumer path-reporting codes),
§ Decision 8 (`-V` reporting verbosity and format) and its § Edge cases row
for no matched messages.

---

## The reframe

### The old framing

The issue was filed as "four locked clauses of the histogram bin-counter `-V`
contract have no emission site": `--exact-percentiles`, `opt_out_active`,
`opt_out_notice` and `consumers_active`, all four said to be locked clauses of
the section's contract with no implementation, all four to be disposed of
together as one audit finding with one cause.

### What was measured

Three separate measurements overturn that framing.

**The three opt-out names are not clauses of this section's contract.**
`grep -c 'exact.percentiles\|exact_percentiles\|opt_out_active\|opt_out_notice'`
over `features/187-histogram-bin-counter-percentiles.md` returns zero across
the whole file. Decision 8's Contract paragraph states the replacement
positively ("There is no run-level opt-out line. Decision 7's selectors are per
surface, so the opt-out state is reported per consumer, on the consumer's
`path:` line"), and its implementation guidance repeats it ("Asserting the
opt-out: there is no run-level line to grep"). Decision 7 (the user-facing
opt-out, re-locked onto the per-surface data-model selectors on 2026-08-27 via
#460, bin-model percentiles computed from the counters that captured them)
reads "There is no run-level banner and no run-level opt-out line." The owning
record is already correct on all three, and already explains itself. What
survives is stale prose in records that never owned the contract.

**The fourth clause is a live defect, but not the one the old title names.**
The old body said the `consumers_active: none` state "cannot occur as the
section is built today". The state occurs readily. What fails is the label.
Run

```
./ltl --disable-progress -ni -bs 1440 -oe -dm bin \
  -V histogram-bin-counters tests/fixtures/format-detection/wgm-client.txt
```

(44 lines, occurrence tallies only, no duration, bytes or count at line level)
and `summary_table` reports:

```
consumer: summary_table
  path: unified
  partition_keying: (category, log_key)
  partition_count: 0
  ... every telemetry field 0 ...
  percentiles_emitted: p1 p5 p10 p25 p50 p75 p90 p95 p99 p999 p9999 p99999
  out_of_range_bounded: p1=none p5=none ... p99999=none
```

A zero-partition block under `unified`, carrying a twelve-quantile percentile
ladder for percentiles that do not exist. Decision 8's implementation guidance
names this exact case and forbids it: "when a consumer is on the `unified` path
but no data triggered partition construction (e.g., zero matched values), the
consumer's `path:` should be `feature_not_active`, not `unified`. Don't emit
zero-partition blocks under `unified`." § Edge cases says the same thing as
required behaviour, in its row for no matched messages: "Percentiles emit `-`;
no partition is constructed; `-V` reports `feature_not_active` per R10." § R10
defines the code the same way: "`feature_not_active` — no values were matched;
no percentile computation occurred. The partition is not constructed."

Add the heatmap and the histogram to the same no-value run and five of the
seven consumers mislabel:

```
./ltl --disable-progress -ni -bs 1440 -oe -dm bin -hm duration -hg duration \
  -V histogram-bin-counters tests/fixtures/format-detection/wgm-client.txt
```

| consumer | reported today | required by § R10 and § Edge cases |
|---|---|---|
| `summary_table` | `unified`, `partition_count: 0` | `feature_not_active` |
| `csv_output` | `feature_not_active` (only because `-o` was off) | `feature_not_active` |
| `time_bucket_stats` | `feature_not_active` | `feature_not_active` |
| `heatmap_markers` | `unified` | `feature_not_active` |
| `heatmap_cells` | `unified`, `partition_count: 0` | `feature_not_active` |
| `histogram_view` | `unified`, `partition_count: 0` | `feature_not_active` |
| `histogram_bins` | `unified` | `feature_not_active` |

**The two removals that caused the drift are five days and two issues apart.**
`consumers_active: none` shipped as scaffolding under #189 (the bin-counter
`-V` block) and was removed on 2026-05-20 by the commit whose message reads
"Replace `consumers_active: none` with all seven per-consumer blocks in the
locked Decision-8 order" (#34 Phase 2, the histogram bin-counter mode). The
opt-out surface was removed on 2026-05-26 under #287 (the message-stats
bin-counter data model) as a declared breaking change, which updated `ltl`,
five harnesses, `docs/usage.md`, `tests/HARNESS-DESIGN.md` and the release
notes. Neither removal amended the owning decision. The issue's "one audit
finding with one cause" is wrong on the history.

### Why the framing changed

Three of the four clauses were already removed from the owning record under
#287 (the message-stats bin-counter data model) and its Decision 7 re-lock:
there is nothing left to decide on them at the contract level, only stale prose
elsewhere. The fourth clause's absence is a **symptom of the gate**, not a
separate missing feature: the emitter never detects the no-consumer state,
because it asks "is this feature switched on" rather than "did anything get
matched". Correct the gate and every consumer on a no-value run reports
`feature_not_active`; the state the contract promises to report becomes
readable straight off the seven path labels, with no new field.

So the defect is the wrong path label, and the issue is now framed on it.

---

## Motivating consumer

**A reader of the section on a no-value run.** The section's stated primary
purpose in Decision 8 is testability and cold reading by an agent. Today it
tells such a reader that the summary table ran the unified path over a
partition set that does not exist, and prints a twelve-quantile audit ladder
for percentiles that were never computed. That reading is not merely
uninformative, it is false, and it is false in the direction that hides the
cause: a reader debugging "why are my percentiles blank" sees `path: unified`
and looks downstream of the partition, when nothing ever reached it.

**The owning harness.** `tests/validate-histogram-bin-counters.sh` asserts
`path:` lines in five places and names the mechanism in one `produced_by`
("emit_bin_counter_mode_verbose() in ltl - %feature_active map"). It passes 84
of 84 on the branch head while the contract's no-value behaviour is unmet,
because no scenario runs the section against input that carries no value. The
harness cannot distinguish "the invariant holds" from "nothing put the
invariant under test" here.

---

## Requirement

On a run where a consumer's feature is switched on but no value the consumer
would bin was observed, the consumer's `-V` block reports
`path: feature_not_active` and no further fields, per § R10 and § Decision 8's
edge-case guidance. No consumer reports `path: unified` with
`partition_count: 0`.

The `consumers_active: none` clause is retired from the contract rather than
implemented, because the corrected path labels carry the signal.

---

## Corrections to the old issue body

Recorded because each was asserted in the body and each is wrong.

1. **"the section is documented as carrying `--exact-percentiles`,
   `opt_out_active` and `opt_out_notice`"** is false of the owning record: zero
   occurrences of any of the three in
   `features/187-histogram-bin-counter-percentiles.md`. Decision 7 and
   Decision 8 both affirmatively state there is no run-level opt-out line. Only
   `consumers_active` is a live clause of this section's contract.

2. **"the `consumers_active: none` behaviour in four places"** undercounts.
   Four passages sit inside Decision 8 (the Contract paragraph, the Section
   presence paragraph with its fenced example, the "No consumers active:"
   fenced example, and the Rationale bullet) plus a fifth outside it, in § R7's
   section-presence line. Five passages.

3. **"the 'none' state cannot occur as the section is built today"** is wrong,
   and it is the correction the reframe turns on. The state occurs; the emitter
   mislabels it, in the specific shape Decision 8's implementation guidance
   forbids. This is not the #460 situation of a locked value nothing could
   emit; it is the inverse, a value emitted where the contract says it must not
   be.

4. **"All four are decided together: they are one audit finding with one
   cause"** is wrong on the history: two removals, five days apart, under #34
   (histogram bin-counter mode) and #287 (message-stats bin-counter data
   model). Three of the four have no live design choice left in them.

5. **"#472 deliberately left these four undecided"** has no source. The #472
   spec (the highlight bin-counter sub-stores are absent from the `-V`
   telemetry) is entirely about the three highlight counter stores and their
   two new consumer names; it defers only to
   `features/bin-counter-accuracy-and-observability.md` § Open items carried
   out of stage 1 and `features/460-bin-model-percentile-source.md` § 5, and
   neither of those sections mentions any of the four clauses. The four were
   not deferred, they were not carried forward. The phrase existed only in
   #546's own body.

6. **Decision 8's only worked invocation for the no-consumer state does not
   parse.** The text reads "e.g., `ltl -ll <file> -V` with no
   percentile-relevant features enabled". `-ll` is not a flag; the run exits 1
   with `Unknown option: ll`. Corrected here (see Decision 4 below).

7. **`features/426-per-message-statistics-store.md`'s locked-decision inventory
   row for #187 Decision 7 reads "Never amended; contradicted by shipped
   code".** Stale: Decision 7's heading carries "re-locked onto the per-surface
   selectors 2026-08-27 via #460". The #426 audit predates that amendment.
   Corrected here (see Decision 4 below).

---

## The mechanism today

### The `%feature_active` literal

In `sub emit_bin_counter_mode_verbose`, the consumer-activity gate tests option
flags, not observed values:

```perl
my %feature_active = (
    summary_table     => 1,
    csv_output        => $write_messages_to_csv ? 1 : 0,
    time_bucket_stats => ($durations_observed && $bucket_duration_stats_demand) ? 1 : 0,
    heatmap_markers   => $heatmap_enabled ? 1 : 0,
    heatmap_cells     => $heatmap_enabled ? 1 : 0,
    histogram_view    => $histogram_enabled ? 1 : 0,
    histogram_bins    => $histogram_enabled ? 1 : 0,
);
```

`summary_table` is a hard literal `1`: it can never report `feature_not_active`
at all. Six of the seven entries ask only whether the feature is switched on.
Exactly one, `time_bucket_stats`, conjoins an observed-value term, which is why
it is the one consumer that already behaves as § R10 requires.

The loop that reads the map then chooses the label:

```perl
if (!$feature_active{$consumer}) {
    push @verbose_output, "  path: feature_not_active";
    next;
}
if ($consumer_opted_out_to_raw{$consumer}) {
    push @verbose_output, "  path: user_opt_out";
    next;
}
push @verbose_output, "  path: unified";
```

So the fix has one site: conjoin an observed-value term to every entry of
`%feature_active`. No branch of the loop, and no other structure in the sub,
needs to change.

### The correct shapes are already in the tree

`time_bucket_stats`'s existing `($durations_observed && $bucket_duration_stats_demand)`
is the shape to follow: a demand term conjoined with an observation term, both
already maintained by the read loop. For the CSV consumer the correct gate
already exists as a sub, `stats_csv_duration_columns_active()`, which returns
`($write_messages_to_csv && !$omit_durations && $durations_observed) ? 1 : 0`,
the three-part gate the emitter currently bypasses by testing
`$write_messages_to_csv` alone. Per the one-resolution-surface-per-vocabulary
rule, the emitter calls that sub rather than restating its terms.

The observation terms the read loop already maintains (`$durations_observed`,
`$bytes_observed`, and for the count family the `count_occurrences` tallies in
`%log_analysis`) are the same ones `apply_pre_walk_sort_gate()` reads for its
own "was the family's source metric observed anywhere in the run" question.
Nothing new is accumulated per line.

### The buffer-stranding hazard

There is a second site that contributes to this section.
`sub finalize_histogram_unified` pushes the display-dimensions sub-section into
`$verbose_section_buffer{'histogram-bin-counters'}` under its own guard
(`section_requested('histogram-bin-counters') && @metrics_with_data`), and the
emitter drains it with
`delete $verbose_section_buffer{'histogram-bin-counters'}` at a point **after**
the consumer loop and before the closing bracket.

An implementation that reached the no-value state with an early `return` placed
before the loop would strand that buffer: neither emitted nor cleared. This
specification does not add such a return. The fix changes only the values in
`%feature_active`, so the loop still runs, every consumer still emits its
block, and the drain still executes in place. Suppressing what the loop prints
(by the label the map produces) is safe; returning early is not. The two rarely
coincide in practice, because the sub-section requires `@metrics_with_data`,
but the ordering is a real constraint on any future short-form work and is
recorded here for that reason.

---

## Decisions

### D1 — The defect is the wrong path label, and the fix is an observed-value term in the gate — **LOCKED (2026-09-13)**

`%feature_active` in `emit_bin_counter_mode_verbose()` tests option flags
rather than observed values, so a consumer reports `path: unified` with
`partition_count: 0` and a full percentile ladder on a run where nothing was
matched. Decision 8's implementation guidance forbids exactly that ("Don't emit
zero-partition blocks under `unified`"), § Edge cases requires
`feature_not_active` for a run with no matched messages, and § R10 defines the
code as "no values were matched".

The fix conjoins an observed-value term for every consumer, following the shape
`time_bucket_stats` already uses, and calls
`stats_csv_duration_columns_active()` for the CSV consumer rather than
restating its three terms.

**Rationale.** It is the same locked decision, the same sub and the same hash
literal that any `consumers_active` work would open, so the Decision 8 sweep
happens once. It corrects a statement that is actively false to a reader (the
tool reports that a partition ran the unified path while reporting that no
partition exists) rather than only adding a line that says nothing happened.
And the correct shapes are already in the tree, so the change introduces no new
vocabulary.

### D2 — `consumers_active: none` is retired, not implemented — **LOCKED (2026-09-13)**

The clause is retired from Decision 8 and from § R7's section-presence line
with a dated amendment in the style of the `path: pre_migration` retirement
under #460 (bin-model percentiles computed from the counters that captured
them). The corrected path labels are the signal: on a no-value run every
consumer reports `feature_not_active`, which is the state the retired line was
to announce. No short form is implemented, and no new field is added next to
`data_model_precision:`.

**Rationale.** With the gate corrected, a summary line whose only content is
"the seven lines below all say the same thing" earns nothing, and adding it
would create a second place the same state is asserted from, which is the
condition that let the section and its contract drift apart in the first place.
The #460 precedent states the principle this follows: a locked contract value
that nothing emits and nothing asserts is not instrumentation. Here the
inverse-but-equivalent case applies: the state is fully reported by an
existing field, so a second reporting surface for it is redundant contract.

### D3 — The stale-prose sweep is not this issue — **LOCKED (2026-09-13)**

Fifteen records still describe the removed bin-counter opt-out flag and fields
as live. That sweep is #548. This issue touches only the owning record's
Decision 8 and § R7, the emitter, and the owning harness.

**Rationale.** The two halves share only the phrase "audit finding". The sweep
has no code, no harness and no release note, and folding it in would put a
dozen unrelated feature-doc edits into a PR that must be reviewed against the
locked decision it amends.

### D4 — Two corrections in the paragraphs this change opens are folded in — **DECIDED (2026-09-13), delegated**

Folded in, because both sit in text this change is already rewriting and
neither carries design content:

- Decision 8's non-parsing example invocation `ltl -ll <file> -V` is replaced
  with a real one that reaches the no-value state, measured in this
  investigation:
  `ltl --disable-progress -ni -bs 1440 -oe -dm bin -V histogram-bin-counters tests/fixtures/format-detection/wgm-client.txt`.
- `features/426-per-message-statistics-store.md`'s locked-decision inventory
  row for #187 Decision 7, reading "Never amended; contradicted by shipped
  code", is corrected to name the 2026-08-27 re-lock via #460.

The `shares_partitions_with` divergence is also folded in, and is resolved
rather than deferred; it is large enough to carry its own decision, D10 below.

### D5 — `tests/HARNESS-DESIGN.md`'s worked examples are re-based on output the tool produces — **DECIDED (2026-09-13), delegated**

Its § Self-documenting assertions uses `consumers_active: none` three times as
the worked example of a well-documented assertion. This change is what makes
those examples false, so they are replaced in this change with an example from
the same section's own subject matter, naming output the tool produces.

The checklist gap in the same document is also closed here, and carries its own
decision, D11 below.

### D6 — The harness gets a new scenario on a no-value fixture — **DECIDED (2026-09-13), delegated**

A new scenario in `tests/validate-histogram-bin-counters.sh` runs the section
against `tests/fixtures/format-detection/wgm-client.txt` and asserts
`path: feature_not_active` on all seven consumers and that no `path: unified`
appears anywhere in the section. `scenario_always_present` is left exactly as
it is: it is about header presence and stays that way.

Every assertion in the new scenario is demonstrated to fail against the current
build before the emitter is changed, and the failure is recorded.

**Rationale.** A positive assertion on a committed fixture is stronger and
simpler than an absence check, and it is the one shape that puts the
no-value invariant under test at all. It also satisfies the rule that a lookup
matching nothing is a failure and never a pass: the seven positive assertions
carry the scenario, and the single negative assertion rides on top of them
rather than standing alone.

### D7 — Invocation coherence for the new scenario — **DECIDED (2026-09-13), delegated**

The scenario's invocation is `-ni -bs 1440 -oe` plus `-dm bin` and the section
selector, on the 44-line fixture. Nothing rendered is read: every assertion
reads a `path:` line. `-dm bin` is required, not decoration, because without it the
per-message surface resolves to `raw` and `summary_table` reports
`user_opt_out`, which masks the very label under test.

This scenario is the one place in the harness that reads a different input file
from the shared 5,000-line access log, because the shared log carries a
duration on every line and therefore cannot carry the signal. The fixture is
committed and tracked (`.txt`, per the fixture-naming rule).

### D8 — Ordering against #472 — **DECIDED (2026-09-13), delegated**

**#472 (the highlight bin-counter sub-stores are absent from the `-V`
telemetry) should land first.** Both branches amend the same Decision 8
paragraphs and both edit `%feature_active` in the same sub, so they will
conflict textually. #472's amendment **adds** two consumer names to the locked
consumer table and the block order; this one **retires** a clause and re-gates
every entry of the map. Adding names to an accurate table and then re-gating
the enlarged map is one clean sequence; the reverse leaves this issue's
amendment describing a seven-entry map that #472 immediately makes nine.

Both are dated amendments in a decision that already carries four of them, so
the second branch rebases and appends rather than merging prose.

**No `blocked_by` edge is recorded.** Applying the dependency-first test: this
issue can proceed to a clean implementation before #472 lands. Its fix is
complete over the seven consumers that exist today, its harness scenario
asserts those seven, and nothing in it reads anything #472 produces. The
dependency is a document-conflict one, not a content one, so it is an
informational note and not a gate. If the architect wants the edge recorded
anyway, the command is
`gh api --method POST repos/{owner}/{repo}/issues/546/dependencies/blocked_by -F issue_id="$(gh api repos/{owner}/{repo}/issues/472 --jq '.id')"`;
it has not been run.

**Interaction.** #472's two new highlight consumers must also report
`feature_not_active` on a no-value run, for the same reason and by the same
gate. Whichever of the two lands second extends the new scenario to cover the
full consumer list at that point. If #472 lands first, this issue's scenario is
written against nine consumers; if this one lands first, #472 extends the
scenario it finds.

### D9 — No existing capture or reference changes — **DECIDED (2026-09-13), delegated, verified**

Any capture or reference carrying `path: unified` with `partition_count: 0`
would change. `grep -rln "partition_count" tests/` matches exactly one file,
`tests/validate-histogram-bin-counters.sh`, and its assertions are regex
patterns of the form `[0-9]+` against runs that do have values, not captured
reference output. No committed reference file under `tests/` contains the
section's per-consumer blocks. Confirmed in the worktree; nothing to update.

### D10 — The shared-partition direction is locked to the store's owner, and all three pairs are written into the contract — **DECIDED (2026-09-13), delegated**

**The emitter's declared direction is correct. No code change.** The contract
paragraph is what is incomplete, and the owning harness's note deferring the
question is withdrawn.

**The code evidence.** For each pair, one consumer's telemetry is snapshotted
from a counter store and the other is assigned that same snapshot. The
consumer the snapshot is taken from owns the partitions; the one assigned to it
reads them. All three finalize subs use the identical two-line shape:

```perl
$bin_counter_telemetry{summary_table}   = snapshot_counter_telemetry(\%log_messages_counters);
$bin_counter_telemetry{csv_output}      = $bin_counter_telemetry{summary_table};

$bin_counter_telemetry{heatmap_cells}   = snapshot_counter_telemetry(\%heatmap_counters);
$bin_counter_telemetry{heatmap_markers} = $bin_counter_telemetry{heatmap_cells};

$bin_counter_telemetry{histogram_view}  = snapshot_counter_telemetry(\%histogram_counters);
$bin_counter_telemetry{histogram_bins}  = $bin_counter_telemetry{histogram_view};
```

The stores are populated in the read loop by `counter_update()` against
`%log_messages_counters`, `%heatmap_counters` and `%histogram_counters`
respectively. Nothing writes a fourth store for the aliased consumer, and the
`rebin_finalize_events` increment in each finalize sub lands on the owner's
entry (`$bin_counter_telemetry{heatmap_cells}{rebin_finalize_events}++`,
`$bin_counter_telemetry{histogram_view}{rebin_finalize_events}++`), never on
the sharer's. So the owners are `summary_table`, `heatmap_cells` and
`histogram_view`; the sharers are `csv_output`, `heatmap_markers` and
`histogram_bins`. The emitter's map declares exactly that:

```perl
my %shares_with = (
    heatmap_markers => 'heatmap_cells',
    histogram_bins  => 'histogram_view',
    csv_output      => 'summary_table',
);
```

**Observed.** On `tests/fixtures/tomcat-access-duration-spread.txt` with
`-ni -bs 1440 -oe -dm bin -hm duration -hg duration`, the section emits
`shares_partitions_with: heatmap_cells` inside the `heatmap_markers` block and
`shares_partitions_with: histogram_view` inside the `histogram_bins` block,
with `heatmap_cells` and `histogram_view` each carrying the full telemetry
block. That is the direction the stores establish.

**The contract amendment.** Decision 8's shared-partition paragraph illustrates
only `csv_output` sharing with `summary_table` and leaves the other two
undeclared, which is what let the harness record the shipped heatmap direction
as suspect. The paragraph is amended to list all three pairs with the direction
locked, and to state the rule that produced it: the consumer whose store the
telemetry is snapshotted from is the upstream, and the one assigned that
snapshot emits the short block naming it.

The block order is contract-visible here and is stated with the pairs: because
the locked order places `heatmap_markers` before `heatmap_cells`, a sharer's
short block can appear **before** its upstream's full block. That is not a
defect and a reader must not infer direction from position.

**The harness note is withdrawn.** The `asserts` text on the
`time_bucket_stats` negative assertion currently ends "Inverting the heatmap
sharing is a separate follow-up." That clause is removed: the question is
settled here, the shipped direction is the correct one, and leaving the note
would keep a resolved question open in the one place a reader looks at the
moment of failure.

**Rationale.** A contract that names one of three instances of a relationship
is not a contract over the relationship, and the gap cost exactly what an
undeclared contract costs: a shipped, correct behaviour was recorded in the
harness as possibly wrong, and stayed that way. Deciding it from the stores
rather than from the illustration means the locked direction is the one the
code can be checked against, in all three cases, by the same rule.

### D11 — The stability-contract checklist names the owning feature doc — **DECIDED (2026-09-13), delegated**

`tests/HARNESS-DESIGN.md` § Stability contract is the checklist both removals
that caused this defect were vetted against, and both complied with it as
written. Its discovery step searched only `tests/`, and its update step listed
`CLAUDE.md`, `docs/usage.md`, `README.md` and `print_help()` but never the
locked decision that owns the section. It is corrected in this change, not
forwarded.

**Replacement text**, applied to the document in this commit:

1. Updating every consumer in the same commit. Discover them with
   `grep -r "=== old-name ===" tests/` and `grep -rn "old-name" features/` for
   both the section name and the key, since the owning feature doc's locked
   decision is a consumer of the name even though it runs nothing.
2. Running each affected harness end-to-end and confirming it still **asserts**,
   not merely exits 0.
3. Updating the owning feature doc's section contract and the locked decision
   that fixes it, in the same commit. This is mandatory for any key or value
   change, not only a rename: a locked decision that still names a removed key,
   or that omits a key the tool emits, is the defect this step exists to
   prevent, and it is invisible to a `tests/`-only search. Then this document's
   reserved-names list and any per-feature reference (`CLAUDE.md`,
   `docs/usage.md`, `README.md`, `print_help()`).

**Rationale.** The two documents disagreed on required scope, and the
disagreement is what produced this defect twice, five days apart, under two
unrelated issues. `CLAUDE.md`'s "Before writing or changing code" checkpoint
already requires the owning feature doc's section contract to be updated in the
same commit as any `-V` section or key change; the checklist the author
actually follows at the moment of the change did not. Closing the gap where the
work happens is worth more than recording it as a finding, and it is three
lines.

It stays here rather than moving to #545 (harnesses accept an unknown scenario
selector or flag silently) because this change is the one that proves the gap:
the amendment it makes to the owning decision is exactly the step the checklist
omitted.

---

## The amended contract text

### Decision 8 — the retirement amendment

A dated amendment block quote is added at the head of Decision 8, in the form
the decision's four existing amendments use:

> **Amendment 2026-09-13 (#546)**: `consumers_active: none` is retired. The
> state it announced — no consumer computing percentiles or bin counts this run
> — is reported by the per-consumer `path:` lines, which read
> `feature_not_active` on every consumer when no value the consumer would bin
> was observed. A second reporting surface for a state an existing locked field
> already carries is redundant contract, and the retirement follows the
> `path: pre_migration` precedent set on 2026-08-27 by #460. The section stays
> always present under `-V`: the run-level header and the seven per-consumer
> blocks are emitted on every run, including a run where nothing was matched.
> All other Decision 8 field names, consumer-name strings and per-consumer
> lockings remain in effect verbatim.

Consequential edits inside Decision 8, each replacing text that named the
retired line:

- The Contract paragraph's second sentence becomes: "The section is **always
  present** under `-V`, regardless of which consumers are active; when no
  consumer is computing percentiles or bin counts in the current run, every
  per-consumer block reports `path: feature_not_active`."
- The Section presence paragraph becomes a statement of the same behaviour,
  with a real invocation replacing `ltl -ll <file> -V`.
- The "No consumers active:" fenced example is rewritten to show the seven
  `feature_not_active` blocks the corrected emitter produces.
- The Rationale bullet's clause "the `consumers_active: none` case handles the
  no-percentile-feature scenario" becomes "the no-value run is reported by
  `path: feature_not_active` on every consumer block."
- The implementation-guidance edge-case bullet for `partition_count: 0` gains
  the mechanism: the gate that produces the label conjoins the consumer's
  demand term with an observation term, per the shape `time_bucket_stats`
  already uses and `stats_csv_duration_columns_active()` for the CSV consumer.

### Decision 8 — the shared-partition paragraph

The paragraph that today illustrates one pair is replaced by one that locks all
three, states the rule that decides the direction, and warns about block order:

> **Special case: shared-partition consumers**: when one consumer is a
> downstream rendering of another consumer's partitions, the downstream
> consumer's block uses `shares_partitions_with: <upstream-consumer-name>`
> instead of repeating the partition-state fields. **The direction is decided by
> the store**: the upstream is the consumer whose counter store the run's
> telemetry is snapshotted from, and the downstream is the consumer that is
> given that same snapshot. The three shipped pairs are locked as:
>
> | downstream (emits the short block) | upstream (named in it) | store |
> |---|---|---|
> | `csv_output` | `summary_table` | the per-message per-key counters |
> | `heatmap_markers` | `heatmap_cells` | the per-time-bucket heatmap counters |
> | `histogram_bins` | `histogram_view` | the per-metric histogram counters |
>
> `time_bucket_stats` has a store of its own and is in no pair, so it always
> emits the full block.
>
> A downstream block can appear **before** its upstream's block, because the
> locked display order is independent of the sharing direction:
> `heatmap_markers` precedes `heatmap_cells` and `histogram_bins` follows
> `histogram_view`. Direction is never inferred from position.
>
> The downstream block then carries only:
> - `path: unified` (or other R10 code).
> - `shares_partitions_with: <upstream-consumer-name>`.
> - `percentiles_emitted: <space-separated list>` (may differ from the upstream
>   consumer's set).
> - `out_of_range_bounded: <inline per-quantile>` (per-quantile audit specific
>   to this consumer's percentile set).

The dated amendment at the head of Decision 8 records the addition alongside
the `consumers_active: none` retirement.

### R7 — the section-presence line

The line

> **Section presence**: always emitted under `-V`; reports
> `consumers_active: none` when no consumer is computing.

becomes

> **Section presence**: always emitted under `-V`. When no consumer is
> computing, every per-consumer block reports `path: feature_not_active`;
> there is no run-level no-consumer line (Decision 8, amended 2026-09-13 via
> #546).

---

## Surfaces touched

| Surface | Change |
|---|---|
| `ltl`, `sub emit_bin_counter_mode_verbose` | Every entry of `%feature_active` conjoins an observed-value term; the CSV entry calls `stats_csv_duration_columns_active()`. No other change in the sub. |
| `features/187-histogram-bin-counter-percentiles.md` | Decision 8 dated amendment plus five consequential edits; the shared-partition paragraph rewritten to lock all three pairs (D10 above); § R7 section-presence line. |
| `features/426-per-message-statistics-store.md` | The stale "Never amended" row for #187 Decision 7 (D4 above). |
| `tests/HARNESS-DESIGN.md` | § Self-documenting assertions worked examples re-based (D5 above); § Stability contract checklist corrected (D11 above). |
| `tests/validate-histogram-bin-counters.sh` | One new scenario (D6, D7 above); sharing assertions added and the withdrawn follow-up note removed (D10 above). |
| `releases/` | One bullet (below). |
| User-facing surfaces | None. `docs/usage.md` names no clause of this section, no `--help` row changes, and the section name is unchanged. |

**Prototype triggers: none fire.** No store, partition or counter is touched.
The emitter runs once per run at output time, and only when `-V` names the
section, so there is no per-line cost and no data-model change. The
verification method is known: the owning harness already asserts `path:` lines
of exactly this shape across eleven scenarios.

---

## Harness plan

`tests/validate-histogram-bin-counters.sh` gains one scenario,
`scenario_no_values_observed`, run after `scenario_always_present`.

- **Invocation.** The section selector plus `-ni -bs 1440 -oe -dm bin` on
  `tests/fixtures/format-detection/wgm-client.txt`, through a small sibling of
  `run_section` that takes the fixture path (the existing helper hard-codes the
  shared access log). Runtime-warning cleanliness is checked on the capture's
  stderr, as every scenario does.
- **Assertions.** `assert_header_present`, then one `assert_line` per consumer
  matching `^  path: feature_not_active$` scoped to that consumer's block, in
  the locked block order; then one `assert_no_line` for `^  path: unified$`.
  Each carries `asserts` in plain language, `produced_by` naming
  `emit_bin_counter_mode_verbose() in ltl (the %feature_active observed-value
  gate)`, and `contract` pointing at
  `features/187-histogram-bin-counter-percentiles.md` § R10 and § Decision 8's
  edge-case guidance.
- **Fail-first.** The scenario is run against the unchanged `ltl` and the
  failures recorded before the emitter is touched. Expected failing at that
  point: the `summary_table` assertion, and the `assert_no_line` for
  `path: unified`. The other six consumers already pass on this invocation
  because their features are off, which is why the scenario alone is not
  sufficient evidence and the fail-first capture is part of the deliverable.
  A second fail-first capture with `-hm duration -hg duration` added
  demonstrates the four heatmap and histogram consumers mislabelling; whether
  that becomes a second scenario or flags added to the first is settled during
  implementation, and the criterion below is written so that either satisfies
  it.

### Sharing assertions on a value-bearing run

Per D10, the harness asserts every `shares_partitions_with:` line the contract
locks, on a run where all three pairs are live: the section selector plus
`-ni -bs 1440 -oe -dm bin -o -hm duration -hg duration`, so the per-message,
heatmap and histogram surfaces all populate their stores and `csv_output` is
switched on. Assertions, each naming both ends of the pair:

- Inside the `csv_output` block, `shares_partitions_with: summary_table`. (The
  harness already asserts this one in its CSV-shared scenario; it is carried
  into the consolidated set rather than duplicated.)
- Inside the `heatmap_markers` block, `shares_partitions_with: heatmap_cells`.
- Inside the `histogram_bins` block, `shares_partitions_with: histogram_view`.
- `heatmap_cells`, `histogram_view` and `summary_table` each emit
  `partition_keying:` and `partition_count:`, so an upstream is never reduced
  to a short block.
- `time_bucket_stats` emits no `shares_partitions_with:` line, which the
  harness already asserts.

Each assertion is scoped to its consumer's block rather than matched loose
against the section, because the target name alone does not say which block
carried it.

**Measured coverage before the change**, counting harness assertion patterns
carrying each value the contract names:

| contract value | assertions today |
|---|---|
| `path: unified` | 2 |
| `path: user_opt_out` | 2 |
| `path: feature_not_active` | 1 |
| `shares_partitions_with: summary_table` | 1 |
| `shares_partitions_with: heatmap_cells` | **0** |
| `shares_partitions_with: histogram_view` | **0** |

Two of the six locked values are asserted nowhere, which is the coverage gap
criterion 13 closes and the reason the follow-up note could sit in the harness
unchallenged: nothing was reading those two lines.

Fail-first for the sharing assertions takes the form the situation allows.
The emitter is already correct here, so the new assertions pass on the
unchanged build, and a passing new assertion proves nothing on its own. The
demonstration is therefore that the same assertion scoped to the **wrong**
consumer fails: `shares_partitions_with: heatmap_cells` asserted inside the
`heatmap_cells` block, and `shares_partitions_with: histogram_view` inside the
`histogram_view` block, are each run once and shown to fail. That is what
proves the block scoping is real rather than a loose section-wide match that
would pass whichever block carried the line.

The `asserts` text of the existing `time_bucket_stats` negative assertion loses
its trailing clause "Inverting the heatmap sharing is a separate follow-up",
per D10.

---

## Acceptance criteria

| # | Criterion | Triage | Method |
|---|---|---|---|
| 1 | On a run whose input carries no value a consumer would bin, with the per-message surface pinned to the bin data model, the `summary_table` block reports `path: feature_not_active` and no further fields. | Assertable | New harness scenario, `assert_line` on the block. |
| 2 | On the same run with the heatmap and the histogram enabled, `heatmap_markers`, `heatmap_cells`, `histogram_view` and `histogram_bins` each report `path: feature_not_active`. | Assertable | Same scenario with those flags, or a sibling scenario. |
| 3 | No consumer block anywhere in the section reports `path: unified` on a no-value run. | Assertable | `assert_no_line` riding on criteria 1 and 2, never standing alone. |
| 4 | On a run that does carry values, every consumer's reported path is unchanged from the current build. | Assertable | The harness's existing eleven scenarios pass unchanged, and their pass count is unchanged. |
| 5 | The CSV consumer's activity is decided by `stats_csv_duration_columns_active()` rather than a restatement of its terms. | Assertable | Read the sub: the `%feature_active` entry for `csv_output` is a call to it. |
| 6 | `time_bucket_stats`, which already gates on an observation, is unchanged in behaviour and in shape. | Assertable | Its existing scenarios pass; the map entry is untouched. |
| 7 | The display-dimensions sub-section is still drained inside the parent brackets on every run that produces it. | Assertable | The harness's existing `scenario_display_dimensions` passes unchanged, including its `=== END histogram-bin-counters ===` assertion. |
| 8 | No text in `features/187-histogram-bin-counter-percentiles.md` names an output of this section that the tool cannot produce. | Assertable | `grep -c 'consumers_active' features/187-histogram-bin-counter-percentiles.md` returns 0 outside the dated amendment that retires it. |
| 9 | Decision 8's worked invocation for the no-consumer state runs and exits 0. | Assertable | Run the invocation as written in the doc. |
| 10 | On a run where all three pairs are live, each downstream consumer emits `shares_partitions_with:` naming its locked upstream, inside its own block: `csv_output` names `summary_table`, `heatmap_markers` names `heatmap_cells`, `histogram_bins` names `histogram_view`. | Assertable | Three block-scoped `assert_line` calls in the sharing scenario. |
| 11 | On the same run, `summary_table`, `heatmap_cells` and `histogram_view` each emit `partition_keying:` and `partition_count:`, and `time_bucket_stats` emits no `shares_partitions_with:` line. | Assertable | `assert_line` on the three upstreams; the harness's existing `assert_no_line` on `time_bucket_stats`. |
| 12 | The direction each `shares_partitions_with:` declares is the one the code establishes: the named upstream is the consumer whose counter store the run's telemetry was snapshotted from. | Assertable | Read the three finalize subs: the named upstream is the argument side of `snapshot_counter_telemetry()` and the emitting consumer is assigned that snapshot. Checked at review, held by criterion 10 thereafter. |
| 13 | Every `path:` value and every `shares_partitions_with:` target Decision 8 names is asserted by at least one scenario in `tests/validate-histogram-bin-counters.sh`. | Assertable | For each contract value in turn, grep the harness and confirm at least one `assert_line` pattern carries it: the three path codes `unified`, `user_opt_out` and `feature_not_active`, and the three sharing targets `summary_table`, `heatmap_cells` and `histogram_view`. A value with no match fails this criterion. |
| 14 | `tests/HARNESS-DESIGN.md` § Stability contract instructs the author to search `features/` as well as `tests/`, and names the owning feature doc's section contract and locked decision as a mandatory consumer of any key or value change. | Assertable | Read the three numbered steps. |
| 15 | No text in `tests/validate-histogram-bin-counters.sh` defers the shared-partition direction as an open question. | Assertable | Grep the harness for the follow-up wording about inverting the heatmap sharing; no line returns. |
| 16 | A reader of the section on a no-value run can tell from the section alone that nothing was matched. | Assertable through criteria 1 to 3 | Legibility is a judgement, but its whole mechanical content is that every consumer reads `feature_not_active` and none reads `unified`, which criteria 1 to 3 assert. It is verified by eye once on the rendered section during the fix, and stands on that proxy. |

---

## Completion gate

Executable lines of `ltl` change and `tests/validate-histogram-bin-counters.sh`
changes, so per `docs/process/workflow.md` § 3 the scope test requires the full
harness suite and a before/after benchmark, both on the commit being merged and
on this machine, with `$version_number` restored first.

The changed code is once-per-run emit-time code behind `-V`, so no measurable
benchmark change is expected. The benchmark is run because the table requires
it, not because a regression is anticipated; a metric worse by more than 5% is
stop-and-investigate as usual.

**Behaviours this change could have altered**, named before the gate is
launched: the `path:` label of every consumer on every run (the whole of the
change); and, only if an early return were introduced, the drain of the
display-dimensions sub-section. This specification does not introduce one, and
criterion 7 exists to hold that.

The shared-partition work under D10 alters no behaviour at all: the emitter's
declared directions are already the ones the stores establish, so that half of
the change is contract text plus assertions over output the tool already
produces. It is named here so the gate's scope is not read as covering a code
change it does not contain.

---

## Release note

**Yes, one bullet.** A `-V` value changes on a documented surface that carries a
stability contract: consumers on a run where no value was observed now report
`feature_not_active` rather than `unified` with an empty partition set. That is
user-observable for anyone reading or scripting against the section.

The bullet reflects the change only, never the pre-existing behaviour of the
section, and classifies under bug fixes.

---

## Findings forwarded to the architect

One item. The two divergences this investigation raised on the bin-counter
section are resolved in this change rather than forwarded: the shared-partition
direction under D10 and the stability-contract checklist under D11.

1. **`tests/validate-runtime-config.sh` carries a pattern alternative that can
   never match.** One `assert_no_line` pattern includes
   `--exact-percentiles is deprecated`, a warning for a flag removed under
   #287 (the message-stats bin-counter data model), so that alternative passes
   vacuously; a header comment in the same file names the same deprecation. The
   scenario asserting the flag is rejected is correct and must not be weakened.
   This belongs with #548's stale-prose sweep or with #545 (harnesses accept an
   unknown scenario selector or flag silently), not here: it is in a different
   harness, about a different section, and touches nothing this change opens.

---

## Implementation status

**Implemented on this branch, rebased onto `release/0.18.1` after #472 (the
highlight bin-counter sub-stores are absent from the `-V` telemetry) merged.**
The ordering D8 asked for held: #472 added `heatmap_cells_highlighted` and
`histogram_view_highlighted` to the locked consumer table and the block order,
and this change re-gated the enlarged map. Two textual conflicts arose in
Decision 8 and were resolved by appending this issue's amendment to #472's
heading and keeping #472's nine-consumer display order, exactly as D8
prescribed ("the second branch rebases and appends rather than merging prose").

### Findings established during implementation

1. **The no-value defect is over nine consumers, not seven, and the count in
   the retirement amendment was replaced rather than raised.** Re-measured on
   the branch head after the rebase, with
   `-ni -bs 1440 -oe -dm bin -hm duration -hg duration` on the 44-line
   `tests/fixtures/format-detection/wgm-client.txt`, five consumers mislabelled:
   `summary_table`, `heatmap_markers`, `heatmap_cells`, `histogram_view` and
   `histogram_bins`. The two highlight consumers already reported
   `feature_not_active`, because no highlight was live. The amendment's phrase
   "the seven per-consumer blocks" is now "every per-consumer block in the
   locked display order", so a later consumer addition cannot make it false
   again — which is the failure mode that produced this issue twice.

2. **A gate on the counter store alone would have relabelled every run the user
   pinned to `raw`, and was rejected for it.** `partition_count` is available at
   emit time and reads zero on a no-value run, which makes it a tempting
   observation term. Measured on the same fixture with `-dm raw`, the four
   surface consumers report `user_opt_out` today. The loop tests
   `%feature_active` **before** `%consumer_opted_out_to_raw`, so a
   store-derived term would have turned those four into `feature_not_active`
   and silently destroyed the opt-out report that § R10 and Decision 7 (the
   per-surface data-model selectors, re-locked 2026-08-27 via #460) both
   require. **The constraint this establishes**: the observation term in
   `%feature_active` must be a property of the *values seen*, never of the
   counter stores, because the stores are empty by construction on the raw
   path. Every term used here satisfies that.

3. **The heatmap's observation is `$heatmap_min`; the histogram's needed a
   resolution sub of its own.** The heatmap tracks its min and max above the
   raw/bin branch in the read loop, so `$heatmap_min` being defined is one
   observation that holds under either data model — the property finding 2
   requires. The histogram has no equivalent: the raw path pushes onto
   `%histogram_values` and the bin path records `%histogram_data_min`, and
   neither is written by the other. `histogram_value_observed()` therefore
   answers from both stores. It tests the arrays for *holding a value*, not the
   keys for existing, because `%histogram_values` is pre-seeded with an empty
   array per built-in metric and a `keys` test over it would report an
   observation on every run.

4. **The heatmap's index pre-seed does not make the observation term lie, and
   was checked rather than assumed.** `$heatmap_min` is also set before the
   parse pass from the index's stored min and max for the heatmap's metric
   column, when an index is used and the pre-seed population is the correct
   one. That is not a false observation: the index carries a min and max for
   that column only because the metric was observed when the index was built
   over the same population, so `unified` is the right label there. Verified by
   running each of the two fixtures twice, once building the index and once
   using it: on the no-value fixture the heatmap consumers read
   `feature_not_active` on both passes (no index min or max exists to pre-seed
   from), and on a 3,000-line slice of the access log they read `unified` on
   both passes. The indexed and non-indexed labels are identical in both cases.

5. **`summary_table` moved from a hard literal `1` to the conjunction the
   messages table already uses.** `print_message_summary()` resolves its
   statistics variant as `$message_duration_stats_demand && $durations_observed`,
   the same demand-plus-observation pair the contract's edge-case guidance
   describes. The emitter now reads that pair rather than asserting the
   consumer is unconditionally active, which is what made `summary_table` the
   one consumer that could never report `feature_not_active`.

6. **No value-bearing label changed.** Every consumer's `path:` line was
   captured before and after the change across the eleven invocation shapes the
   harness's existing scenarios use (default, per-message bin and raw,
   per-bucket bin and raw, heatmap bin, histogram bin, highlight active and
   inactive, always-present, display-dimensions), on the 5,000-line access log.
   The two captures are byte-identical, which is criterion 4 discharged by
   measurement rather than by the suite passing.

### Harness

`tests/validate-histogram-bin-counters.sh` goes from 84 to 147 passing
assertions across 18 scenarios, 0 failing.

- **`scenario_no_values_observed`** runs `-dm bin -hm duration -hg duration` on
  the committed fixture through `run_section_on()`, a sibling of `run_section`
  taking the input file (the existing helper hard-codes the shared access log).
  It asserts `path: feature_not_active` block-scoped on all nine consumers in
  the locked order, then one `assert_no_line` for `^  path: unified$` riding on
  those nine. Iterating the whole locked order means a consumer added without a
  gate of its own fails here rather than passing silently.
- **Fail-first, recorded.** Run against the unchanged `ltl` the scenario failed
  6 of its 11 assertions, and exactly the ones predicted: the five mislabelling
  consumers named in finding 1, plus the `path: unified` absence check. The
  other four consumers passed because their features were off, which is why the
  fail-first capture rather than the scenario alone is the evidence.
- **`scenario_shared_partition_direction`** (D10) runs `-dm bin -n 3 -o
  -hm duration -hg duration` so all three pairs are live in one run, and
  asserts each downstream's `shares_partitions_with:` naming its locked
  upstream, block-scoped, plus each upstream emitting its own
  `partition_keying:` and `partition_count:` rather than being reduced to a
  short block. It runs in a scratch directory it creates and removes, because
  `-o` writes export products into the working directory. This closes the
  coverage gap the specification measured: `shares_partitions_with:
  heatmap_cells` and `shares_partitions_with: histogram_view` had no assertion
  anywhere before this change.
- The withdrawn follow-up clause on the `time_bucket_stats` negative assertion
  is removed (D10), and the `csv_output` inactive assertion's `asserts` text no
  longer names the single option flag, since that consumer is now decided by
  `stats_csv_duration_columns_active()`.

### Acceptance criteria

All sixteen hold. Criteria 1, 2 and 3 (no-value labels and the absence of
`unified`) are asserted by `scenario_no_values_observed`; criterion 4 by the
before/after capture in the finding that no value-bearing label changed, and
the unchanged existing scenarios;
criterion 5 by the `csv_output` entry being a call to
`stats_csv_duration_columns_active()`; criterion 6 by `time_bucket_stats`'s map
entry being untouched; criterion 7 by `scenario_display_dimensions` still
asserting its `=== END histogram-bin-counters ===` line; criterion 8 by
`consumers_active` surviving only inside the dated amendment that retires it;
criterion 9 by the doc's worked invocation exiting 0 with clean stderr;
criteria 10 to 13 by `scenario_shared_partition_direction` and the value sweep;
criterion 14 by the three numbered steps of `tests/HARNESS-DESIGN.md`
§ Stability contract; criterion 15 by the follow-up wording returning no line;
criterion 16 by eye on the rendered section, where all nine blocks read
`feature_not_active` and none reads `unified`.
