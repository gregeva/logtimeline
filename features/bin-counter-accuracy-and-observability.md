# Bin-counter accuracy and observability

**Status:** stage 1 (#462) delivered; stages 2-4 not started
**Release:** 0.18.0
**Issues:** #462 (observability carrier, absorbs #461), #450 (test coverage), #459 (merge arithmetic), #460 (contract amendment pass)
**Out of this release:** #354 (per-message store memory), #412 (notices surface)

This document is the record for the drop. The contracts it changes live in the
feature docs that own them — `features/187-histogram-bin-counter-percentiles.md`,
`features/189-histogram-bin-counter-primitives.md`,
`features/287-message-stats-bin-counter-data-model.md`,
`features/34-histogram-bin-counter-mode.md` — and are amended **there**, at source.
Nothing in this file restates contract text: a second copy is a copy that drifts.

---

## Why this drop exists

Four defects were filed out of one investigation, all on the bin-counter surfaces,
all touching the same `-V` block and the same locked decisions. Worked separately
they would open one contract document four times. They are one piece of work.

The mechanism underneath three of them: combining two bin-counter histograms
re-projects both sides onto a union geometry, assigning each source bin's entire
count to the single target bin containing that bin's geometric midpoint. Nothing is
split. The step is lossy, and it composes — the second combination re-projects
counts the first already displaced.

Measured displacement: 1.25 bin widths after one combination, 2.10 after fifteen.
Raising resolution does not rescue it — 2.06 at bins-per-decade 616. The loss is
structural, not resolution-limited.

---

## Locked decisions

### D1 — Histograms are combined once, at finalize, from pristine counts

Clustering is unchanged: message keys are absorbed into clusters progressively, as
they are today. What is deferred is the **arithmetic on the bin counters**.

When a key is absorbed, the cluster **keeps that member's histogram alongside the
others, untouched, in its original geometry**. Nothing is projected and nothing is
added at absorption time. At finalize the cluster computes one union geometry over
**all** its members at once and projects each member's original, never-touched
counts into it exactly once, then sums.

Every member takes exactly one projection from pristine counts, and the union
geometry is a min/max over the whole membership, so it does not depend on arrival
order. This is both order-independent and strictly more accurate than today — one
displacement instead of N.

**Cost, accepted knowingly:** on the bin surface, consolidation stops reclaiming
memory. A cluster of 40 keys holds 40 partitions until the end of the run. See D3
for how that is bounded, and #354 for the related defect this makes worse.

**Scope:** the guarantee governs **every combination of two bin-counter
histograms**, not only consolidation under `-mdm bin`. Architect's reasoning: these
are platform design patterns off the same model, and a second combination path
would drift away from the first. Today consolidation is the only caller; any future
merger (multi-file roll-up, index read-back, a paired-event surface) inherits the
guarantee rather than silently reintroducing the loss.

**Boundary:** this is independence of the *merge* order given the same final cluster
membership. Which keys land in which cluster is decided by the fuzzy matcher and is
a separate mechanism.

### D2 — Percentiles are computed from the highest-fidelity counters available

The histogram surface streams at bins-per-decade 616, projects down to display
shape at finalize, computes percentiles **from the coarse projected partition**, and
discards the high-resolution one. The precision is captured and then thrown away
before the number is calculated. One re-projection therefore precedes every
histogram percentile the tool ships — on the default surface, no flags required.

Under this decision:

- the streaming partition is **retained, not discarded** — the memory argument for
  discarding it never justified throwing the precision away;
- **percentile calculation is driven off the highest-fidelity bin counters**;
- the render side keeps its own display-geometry representation, so bar heights and
  the no-cross-bin-mass-splitting fidelity invariant are untouched.

**Hard requirement:** the percentile tick marks must line up accurately with the
percentile values that are printed and with their placement on the histogram. This
is validated by test, not by inspection — see D6.

The same pattern applies to the heatmap's percentile markers.

### D3 — Retention is measured before it is capped

Holding every member histogram is unbounded by construction, and unbounded
retention is dangerous. A cap is expected. Its value is **not decided up front**.

The observability lands first, prototypes are run against the real logs already in
the corpus, and the ceiling — whether one is needed, and what it is — is decided
from runtime data and folded back into the design. Implementation includes testing,
learning from runtime data, and reintegrating that back into the design cycle.

Architect's reasoning: we don't want to solve problems that we don't have; that is
what the observability is for.

### D4 — The observability surface is designed for the end state, not for today

Counters are defined once, for the shape the system is moving to, and implemented
where they can be today. Counters that cannot be implemented until a later stage are
still designed now, and the downstream issues are updated so they implement against
the same design. One coherent surface; no redefinition mid-drop.

The surface must expose:

- how many member histograms are alive across merged keys, over the run;
- their memory footprint;
- the maximum member count reached across the population;
- re-binning, **counted per mechanism** (below).

**Per-mechanism counting.** Three distinct mechanisms re-bin counts, and one summed
figure cannot be acted on — a number that rises tells you nothing about whether the
seed is wrong, consolidation is churning, or a histogram was rendered. They are
counted separately: streaming growth (a key's histogram outgrows its range and
doubles); combination re-projection; and the finalize projection into display shape,
which happens on every heatmap or histogram run.

**`total_rebin_events` is retired.** The per-mechanism counters replace it and the
references are swept. It is a locked field name; retiring it is part of the
amendment pass (D7).

Audience: these surfaces are for debugging and for the test harnesses. Harnesses
travel with the code version; comparing captures across releases is not a concern
this design serves.

### D5 — The user is told when consolidation degrades bin-model percentiles

Consolidation on the bin surface is lossy by nature. Where the tool can determine
that it occurred, it says so. Where it cannot determine it, it still states that the
condition applies. The notice points the user at `-mdm raw` for higher precision.

It prints regardless of `--disable-progress`: that flag suppresses progress
indicators, not decisions the tool made on the user's behalf.

The notice ships ad-hoc in this drop. It is registered on #412 (notices surface —
structured pre-chart render area) as a producer to be collected when that work
happens; #412 is not in 0.18.0.

### D6 — Stage order

Committed and pushed progressively, each stage merged back to `release/0.18.0`.

1. **Observability** — #462, carrying the whole `-V` surface, with #461 folded in.
2. **Test harness** — #450: the `-g` × `-mdm bin` scenarios and their assertions,
   **plus tick-mark position assertions**. `tests/validate-histogram-ticks.sh`
   asserts tick *presence* today (`tick_count == distinct_legend_columns`, no stray
   tick characters, colour parity) but not tick *position*: a tick in the wrong
   column with the right total count passes. Without a position assertion the D2
   requirement cannot be shown to hold and drift is undetectable.
3. **Capture the new baseline**, before anything changes.
4. **The merge mechanism** — #459, and the D2 percentile-source change.

The re-bless of the stage-3 baseline after stage 4 is the before/after measurement
of what D1 bought, per quantile, on real logs.

**The rest of the release follows the same sequence**, because two of the remaining
issues move numbers the stage-3 baseline depends on and must land after stage 4 —
never between the capture and the changes it measures:

5. **#447** — control-character normalisation on ingest. Changes the message key, so
   it changes consolidation grouping and what the baselines contain.
6. **#432** — metric/aggregate naming, bytes min/mean/max, CSV headers, index
   alignment. Renames baseline columns and adds new per-line capture.
7. **#418** — unsatisfiable sort notice and early objection. After #432 so its
   messages are written against the final statistic names, not rewritten.
8. **#443** (with #449 folded in) — user-defined metric diagnostics and `-V` surface.
9. **#445** — quoting documentation and the `-r` failure message.

8 and 9 touch nothing the others touch. Their positions are a choice, not a
constraint, and no native dependency is recorded for them.

### D7 — One amendment pass over the contracts, eight corrections

Three corrections were filed on #460; five more were drafted against the same
documents by the same investigation and marked owed regardless of any redesign. All
eight land in one pass. Architect's reasoning: make this as simple and as coherent
as possible.

The three from #460:

1. The accuracy claim in `features/187-…md` § R4 is derived for a partition that has
   never been re-projected. Amended to state the measured post-projection reality,
   **and the direction of travel** — after D1 a single projection stays within one
   bin width on 3,999 of 4,000 evaluations (worst 1.0008); it is the compounding
   that reached 2.10.
2. `features/287-…md` § R2.3 describes the merge as extending the narrower partition
   onto the wider one. The shipped code computes a union geometry and re-projects
   both sides. The shipped behaviour is correct; the description is wrong, and it
   misdirected work under #426. The same paragraph cites a sub that does not perform
   the merge, and line numbers that have drifted.
3. The out-of-range mechanism — overflow/underflow counters and the per-quantile
   audit — is documented as live but cannot fire under the current growth policy.

The five further corrections: the validation report overstates its own coverage; the
primitives are undefined for values at or below zero and the caller-side guard is
part of the contract; the equal-edge case is unreachable; the contract describes an
exact-percentiles opt-out flag and two verbose lines that do not exist in the shipped
emitter; the per-partition memory guidance describes only one of the two layouts.

**The out-of-range counters stay.** They are designed-in safety instrumentation for
conditions that should never occur, and remain visible in `-V` so that if one ever
fires it can be investigated. The contract text and the harness prose are trued up to
describe them as guards expected to read zero — not as an audit signal expected to
go non-zero.

### D8 — The accuracy trade is documented for users

Documented on both surfaces, at different depth: **succinct** on the `--help` /
`docs/usage.md` surface, **expanded** in `docs/explain/statistics.md`. Someone
choosing between `-mdm raw` and `-mdm bin` is making an accuracy-for-memory trade and
can currently see only the memory half.

The notice (D5) catches them at the moment it affects them; the documentation lets
them choose before it does.

### D9 — Re-binning is counted on the store entry; the finalize projection at its own sites

Locked 2026-08-26 during #462, from the code as it stands.

The three mechanisms cannot share one carrier. Growth and combination are counted
on the **store entry** — the `{partition, bins, overflow, underflow}` hashref — and
not on the partition, because a combination replaces the target's partition with a
fresh one from `partition_rebin()`. A count held on the partition is therefore
discarded at exactly the moment consolidation happens, which is the mechanism by
which consolidation was invisible: `-g 70` folding 17 partitions into 13 left every
re-bin field byte-identical to the un-consolidated run. `partition_new()` and
`partition_rebin()` no longer carry a `rebins` slot and `partition_extend()`
increments none — one carrier, not two.

The finalize projection cannot be observed from a snapshot at all. It runs after the
only snapshot and deletes the partitions it projects. It is counted at its four call
sites, into the consumer's telemetry hash, independently of the snapshot.

**Rejected:** moving the snapshot to after the projection loops. It is the smaller
change, but `partition_count`, `max_partition_bins` and `counter_memory_bytes` would
then describe the display geometry rather than the 616-bpd streaming geometry — the
same field names silently meaning something else.

**Invariant this establishes:** `rebin_finalize_events == partition_count` on the
heatmap and histogram surfaces, and exactly `0` on `summary_table`, `csv_output` and
`time_bucket_stats`, which read percentiles from the streaming partition and never
project. Both are asserted by `tests/validate-histogram-bin-counters.sh`.

### D10 — Retention is emitted from stage 1, with today's values

`members_live`, `members_max` and `members_memory_bytes` ship now rather than waiting
for D1's retention change, so that the harness in #450 can assert their shape before
#459 moves their values — which is the reason observability leads the drop.

`members` is carried on the store entry, seeded at 1 and folded in on combination, so
the definitions do not change when D1 lands:

- `members_live` — member histograms alive across combined keys. **Conserved under
  combination**: measured 17 both with and without `-g 70`, while `partition_count`
  fell from 17 to 13.
- `members_max` — the largest membership any one entry reached. 1 un-consolidated, 2
  under `-g 70` on the same fixture.
- `members_memory_bytes` — footprint of the retained member histograms. Equal to
  `counter_memory_bytes` today, because combination still collapses members into one
  histogram. **That equality is the signal that no member is being retained yet**, and
  the two diverge the moment D1 lands.

### D11 — `counter_memory_bytes` becomes a derived figure, not a live measurement

Closes #461, folded into #462.

**Attribution, measured before deciding.** Six runs per arm on
`tests/fixtures/tomcat-access-duration-spread.txt`: without `-g`, the figure moved
46277 / 45189 (2.4 % spread) while `partition_count`, `max_partition_bins` and the
re-bin fields stayed constant; with `-g 70`, 50802 / 49970 (1.6 %), likewise with the
content fields constant; under `PERL_HASH_SEED=0 PERL_PERTURB_KEYS=0`, one value per
arm. The variance is **the allocator alone**. It reproduces with no consolidation at
all, so no merge happens and the hash-iteration-order route — where a different merge
order would yield a different union geometry and genuinely different stored contents —
is ruled out as a necessary cause. The step is discrete (1088 bytes, one bucket-array
doubling), not continuous drift.

**The model, and a finding that changed it.** The first implementation modelled
Perl's allocation with constants calibrated against `Devel::Size` on synthetic
stores, and claimed agreement within 4.6 %. Measured against **real** stores it was
wrong by 88–92 % — the synthetic baseline did not reproduce the production data
shape, the same failure mode as #58's F9. Re-fitting against real stores then showed
why no such model can work: per-slot allocation ranges from 8 to ~170 bytes depending
on array density and growth history, so a two-term fit is off by up to 53 % on some
shape, and a three-term fit only converges by taking a physically meaningless
negative coefficient. **Allocation depends on how a structure grew, not on what it
holds** — which is the same property that made the field unstable in the first place.
Any model of it reintroduces that dependence in disguise.

`counter_memory_bytes` therefore reports the counters' **payload**: per partition,
its geometry (six numbers) plus the bin slots it spans. Exact, content-defined, no
calibration constants. It is **not** an absolute footprint, and says so in the code:
across eleven real stores spanning three surfaces and 1–3,074 partitions, allocation
was **10.6–16.4× the payload — a 1.54× spread end to end**, which is far tighter than
any additive model achieved. That makes it a sound instrument for the comparison D3
needs (two runs, two configurations, before and after a change) and an unsound one
for an absolute ceiling.

**For absolute footprint, use RSS**, already the measure of record per
`features/426-per-message-statistics-store.md` § F44(b) — `-mem` and the
per-structure figures from `named_structure_sizes()`. D3's ceiling is set from those,
with this field as the relative signal.

**Verified:** byte-identical across six runs in every arm, with and without a fixed
hash seed. The `Devel::Size` dependency is retained for `named_structure_sizes()`,
which is a different question (real footprint, reported alongside RSS per
`features/426-per-message-statistics-store.md` § F44(b)).

### D12 — `overflow_total` and `underflow_total` are emitted

Both were already produced by `snapshot_counter_telemetry()` and printed by nothing.
D7 keeps the out-of-range counters as designed-in safety instrumentation for
conditions that should never occur; a guard that is computed and then discarded is not
instrumentation. They are emitted and documented as expected to read zero.

---

## Open items carried out of stage 1

- **The highlight sub-stores are not observed.** `%heatmap_counters_hl`,
  `%histogram_counters_hl` and `%bucket_stats_counters_hl` take streaming growth, and
  the first two take a finalize projection each, and no consumer block reports any of
  it. Deliberately out of scope for #462: whether the highlight subset is its own
  consumer, or folds into the parent's figures, is a Decision 8 consumer-name question,
  not a counter question. `%bucket_stats_counters_hl` additionally has no consumer at
  all beyond `named_structure_sizes()`.
- **`path: pre_migration` is unreachable.** All seven consumer names are in
  `%migrated`, so the value can no longer be produced. It is a locked D8 path value
  asserted by nothing; its retirement belongs to the amendment pass in #460.
- **The `/ dimensions` sub-section reports a different epoch from its parent.** It is
  built after the display projection and drained inside the same `-V` brackets as
  fields describing the streaming geometry, with nothing marking the boundary.
  Not changed here; recorded for #460.
- **`features/426-*` and `prototype/` retain `total_rebin_events`.** Both are the
  frozen record of the investigation that produced this drop, describing what the tool
  did at the time they were written. They are not swept.

---

## Deferred to the development flow

These are decided from measurement during implementation, not up front:

- **Whether retention is capped, and at what value** (D3).
- **Disposition of `counter_memory_bytes`** — **settled 2026-08-26, see D11**: a
  derived, reproducible figure. The benchmark gate's 5 % threshold stands.

---

## Relationships

- **#354** (`-mdm bin` costs more per-message memory than `-mdm raw` on
  singleton-dominated logs) — D1 makes this measurably worse on exactly the input
  shape it names. Deliberately **not** in this release: the scope of the drop is
  already large, `-mdm bin` is not a path users take, and the memory growth is
  accepted for now. The decision is hinged on what the measurements from this drop
  show.
- **#412** (notices surface) — not in 0.18.0. D5's notice is registered there as a
  producer to collect.
- **#426** (per-message statistics store) — `not planned`, on hold as a decision
  record. It produced every measurement cited here. Its shared-grid arm, measured at
  0 % divergence, is the representation that was dispositioned as not to be
  delivered; D1 works within the per-key-edges representation instead.
- **#450** — stage 2 of this drop.
