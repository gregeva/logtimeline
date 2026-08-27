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
   asserted tick *presence* only — the cardinality inequality
   `1 <= tick_count <= legend_entries` (the doc previously described this as an
   equality against distinct legend columns; the code has always asserted the
   inequality), no stray tick characters, colour parity — but not tick *position*:
   a tick in the wrong column with the right total count passed. See D15 for what
   the position assertion added here does and does not gate. Without a position assertion the D2
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

### D13 — The bin renders are added alongside the raw ones, not in place of them

Locked 2026-08-26. Both display surfaces default to the bin data model, so the
byte-compare suite was asserting a path users reach only by asking for it. 25 bin
counterparts are added; the 25 `-dm raw` scenarios stay, because they assert a
different, still-shipped path. Each surface now carries both arms and the pair is
itself the raw-vs-bin diff. All 25 new goldens differ from their raw twin — the
coverage is real, not a set of copies.

Each new scenario pins **only the surface it asserts** — `-hmdm bin` / `-hgdm bin`,
not `-dm bin` — per HARNESS-DESIGN's invocation-coherence rule. `-dm bin` would also
flip per-time-bucket statistics, moving the timeline P50/P95 cells inside every
histogram scenario's asserted bytes: an unrelated surface in the diff.

### D14 — Only the new scenarios are blessed; the existing ones are the gate

The stage-3 capture writes to a scratch directory, from which only the new files are
copied in. The existing 46 goldens are then diffed against that same capture: all 46
reproduced byte-identically, which proves both that nothing was silently re-blessed
and that the capture is deterministic. Same for the drift baselines — three new
directories, the 18 existing ones untouched.

Blessing today's values is deliberate: they carry the compounding loss, so stage 4's
diff measures what D1 bought.

**The bin-consolidated `stats.csv` is a byte duplicate of its `bin-data-model`
sibling** on all three logs, because consolidation never touches bucket-keyed
partitions. It is captured anyway, as the harness does for every scenario, and
recorded here so nobody reads it as independent coverage. The merge signal is
entirely in `messages.csv` (32–50 differing lines per log).

### D15 — Tick position is asserted exactly, from published inputs

**Superseded the tolerance-based form on 2026-08-26, at the architect's direction.**
The first attempt predicted tick columns from the rendered legend, whose values are
rounded by `format_heatmap_value()` to one decimal and a unit. That mispredicted 3 of
9 columns and forced a tolerance which, sized to the rounding, was wide enough to be
inert on the widest histograms — 10 of 10 percentiles display-limited at `-hgw 75`
and `-hgw 95`.

The architect's correction: being unable to determine where a tick should be is an
**observability** defect, and it belonged in the observability issue rather than
being absorbed as test slack. `-V histogram-percentile-ticks` now publishes the four
inputs of `calculate_histogram_percentile_ticks()` at full precision — `bar_width`,
the axis `min` and `max`, and each selected percentile value. The harness recomputes
the mapping and compares against the columns recovered from the rendered axis:
`-V` supplies the expected, the render supplies the actual.

**The computed columns are deliberately not published.** A harness reading them back
would compare `ltl` with itself and assert nothing; the mapping expression, not its
output, is what is under test.

**Equality, no tolerance.** Verified exact on all six panels across four widths and a
two-metric run. Proven by sabotage: replacing the log mapping with a linear one
fails; **a uniform 3-column shift now fails too** — it passed silently under the
tolerance; and a one-column drift on a single percentile class fails, which is
precisely what D2 requires be provable and what the tolerance could not do.

### D16 — The oracle's blind spot on consolidated rows is made visible

Layer 3 pairs `ltl` rows to oracle rows by exact message key, and the oracle
implements no fuzzy merge, so a consolidated row's wildcarded key can never pair. The
skip was silent — not counted, not reported — so a scenario whose merge arithmetic
the oracle never examined still reported `L3=OK`, which reads as agreement.

Every summary line now reports `unpaired=N (wildcard=M)`, and a scenario where every
row went unpaired is named `NO CELLS COMPARED` rather than `L3=OK`.

The counter immediately corrected the assumption behind it: L3 is **not** wholly blind
on a consolidated scenario. It still pairs the unmerged remainder — 129–208 cells per
scenario — and only the merged rows go unpaired, 6–16 per scenario, 100 % of them
wildcarded. So the blind spot is precisely the merge arithmetic, which is carried by
Layers 1 and 2. Recorded in `tests/statistics-drift/README.md` § L3 oracle scope.

**This is pre-existing and wider than this drop**: it applies to the four
`*-consolidated` scenarios that predate #450, not only the new rows.

---

### D17 — Consolidation publishes its grouping, so the oracle can check merged rows

The blind spot D16 made visible was closed rather than documented. A consolidated
row's key is a wildcard pattern that appears nowhere in the log, so the statistics
oracle could not form its sample set. `-V message-grouping` now carries a
`cluster-membership` sub-section — canonical key to member keys — recorded only when
the section is requested, so a normal run pays nothing. `validate-statistics.sh`
captures it per consolidating scenario and passes it to the oracle as
`--cluster-membership`.

**The division that makes this sound:** `ltl` supplies the *grouping*, which is the
fuzzy matcher's decision and not a statistic; the oracle computes the *arithmetic*
over each group independently, which is what it exists to check. Recovering the
grouping by pattern-matching the wildcard key against raw messages was rejected — a
key can match a pattern it was not assigned to, which would manufacture false
failures.

**Result, and it validated itself.** All four raw `*-consolidated` scenarios went
from 6–16 unpaired rows to **zero, with zero T3** — raw consolidation concatenates
sample arrays losslessly, so exact agreement there is what proves the grouping is
right. L3 coverage on those scenarios rose from 129–208 cells to 227–400.

### D18 — The oracle immediately found #459, and the finding is registered, not suppressed

With merged rows checked for the first time, the two deep-merge scenarios breached:
**`thingworx-bin-consolidated` 25 comparisons, `codebeamer-bin-consolidated` 8**, all
on wildcarded keys, all on percentiles and IQR — counts, min, max and mean agree.
Percentile deviations **2.7–4.2 %**, IQR to **32.6 %** (a difference of two displaced
percentiles, so it carries both errors). `apache-bin-consolidated`, at 52
projections, stays inside the threshold.

This is the compounding merge loss of #459, measured against an independent oracle
for the first time rather than inferred from a prototype — and it is the clearest
evidence yet for the D1 fix.

**It is registered, not tolerated.** `tests/statistics-drift/known-failures.tsv`
suppresses the block for exactly these (scenario, file_kind, column, key_class)
combinations, attributes each to #459, and still prints the deviation on every run;
the scenarios report `L3=OK-WITH-XFAIL`, never `L3=OK`. Widening the threshold was
rejected: it would hide the defect the drop exists to fix.

**The registry is self-clearing.** If a registered comparison passes, the engine
fails the run with `KNOWN-FAILURE-STALE`, naming the entry and its issue — so #459
cannot land without deleting its entries in the same change. Proven by sabotage:
registering a comparison that passes fails the run.

---

## Current state — where to resume

**Last updated 2026-08-27.** Read this first if work on the drop is being picked up
after a break.

| stage | issue | state |
|---|---|---|
| 1 — observability | #462 (absorbs #461) | **delivered**, merged to `release/0.18.0`, closed |
| 2 — test coverage | #450 | **delivered**, merged, closed |
| 3 — baseline capture | part of #450 | **captured**, deliberately carrying today's compounding loss |
| 4 — merge arithmetic + percentile source | #459, #460 | **not started.** Both unblocked, both `status: in progress`, no branch cut |
| 5–9 — the rest of the release | #447, #432, #418, #443 (+#449), #445 | not started; order fixed by D6 |

#462 was reopened after its first delivery and completed a second time: the surface
shipped without the two observables that make its own requirements testable (D15,
D17). Both landed before it was closed again.

### Stage 4 has an acceptance test it did not have before

`tests/statistics-drift/known-failures.tsv` registers the 33 oracle comparisons that
#459's defect currently breaks, each attributed to it. The registry is self-clearing,
so **#459 cannot land without deleting its entries in the same change** — the engine
fails the run with `KNOWN-FAILURE-STALE` the moment a registered comparison starts
passing. Done, for #459, means:

- `known-failures.tsv` holds no #459 entries;
- `validate-statistics.sh` reports `L3=OK` (not `OK-WITH-XFAIL`) on all seven
  consolidated scenarios;
- `rebin_merge_events` reads 0, and `rebin_finalize_events` on `summary_table` rises
  from its contractually-zero value to `members_live` — which breaks an invariant
  #462 locked, so `tests/validate-histogram-bin-counters.sh` and `features/187`
  § Decision 8 are amended in the same commit;
- `members_memory_bytes` diverges from `counter_memory_bytes`, which is the direct
  measurement of what D1's retention costs.

### Re-blessing the stage-3 baseline is a deliberate act, not a step

L1 is drift against the blessed baseline, and for the merged rows it is now one of
only two numeric checks (L3 being the other, newly available). Re-blessing removes
the L1 check on those rows for that run, so it is done from a diff that has been
read, not automatically. The rest of each row — counts, min/max, the exact-value
statistics — must not move and stays a genuine regression gate throughout.

### The benchmark comparator moved with the hardware

The machine moved to a virtualized host with abstracted virtual IO drivers. Separated
into its two causes by re-running the **v0.17.0 code itself** on the new hardware, so
the machine is the only variable:

- **Hardware, same code** — `total` **+8.9 %** (42 of 45 cases worse), `read_files`
  +8.2 %, `group_similar` +15.7 %, `calculate_statistics` +14.9 %, `sort_selection`
  +19.4 %. The slowdown is **not confined to I/O**: in-memory stages moved more than
  the read path did. Memory is unaffected (`rss_peak` −2.2 %, 0 of 45 worse), which
  is what confirms this is execution speed rather than a behaviour change.
- **Code, same machine** — the drop's work so far is a net **−2.6 %** on `total`
  (36 of 45 cases better), so no code regression is baked into the reference. This
  also retro-validates stages 1–3 suite-wide; they had only been gated on one case.

**Consequence:** `v0.17.0-release` reports the machine, not the change, and cannot
gate anything here. Two same-host references are committed instead, because
attributing what stage 4 does needs both a pre-drop and an immediate-predecessor
point — `dev-virtualized-v0.17.0-code.tsv` and
`dev-virtualized-v0.18.0-pre-stage4.tsv`, `full` tier, 45 cases each. **Stage 4 gates
against the pre-stage4 file**; the v0.17.0-code file is what separates a machine
effect from a code effect. Both are development references, not release baselines.
Release benchmarking is not done on this host.

The baselining process, the naming convention and the worked example: `tests/baseline/README.md`.

---

---

## Stage 4a — #459 implementation plan

Locked design is D1. This is how D1 lands in the code; it introduces no decision D1
did not already make, and the two readings it settles are marked as such.

### The data model

A counter-store entry gains one field:

- `member_entries` — an arrayref of **pristine** entry hashrefs, each in its own
  original geometry, never projected and never added into. `members` stays the
  integer count it already is (`1 + @member_entries`, recursively), so the retention
  telemetry #462 shipped is unchanged in meaning.

`merge_bin_counter_entries($target, $source)` **stops projecting**. It appends the
source — and any members the source itself carried — to `$target->{member_entries}`,
folds `overflow` / `underflow` / `rebin_growth`, and adds to `members`. The
adopt-wholesale branch for an empty target is unchanged. `rebin_merge` is no longer
incremented anywhere, because no combination projects any more.

`collapse_bin_counter_entry($entry)` is new and is where D1's arithmetic happens: one
union `min` / `max` over the entry's own partition **and every member at once**, one
`bin_count` from that, then each side projected into it exactly once and summed. A
side whose geometry already equals the union is not projected at all, so exactness is
preserved where it is available. Returns the projection count. The union is a
min/max over the whole membership, so it does not depend on the order the members
arrived in — which is the guarantee.

### Two readings this settles

**A single log line is not a member.** D1 says "when a *key* is absorbed, the cluster
keeps that member's histogram". The streaming S1-inline path merges a *per-line*
single-sample source into a cluster; treating each of those as a member would retain
one partition per line. It is instead an ordinary **value insertion** into the
cluster's own partition — `bin_assign` + increment, which is exact and projects
nothing, so the guarantee is not weakened. The producer site therefore hands
`merge_bin_state` a `bin_value` rather than a temporary single-sample `bin_entry`,
and the per-entry observation logic is lifted out of `counter_update` into
`counter_entry_observe($entry, $value)` so both callers share one surface. This also
removes a temporary hash and a store insert from the hot path.

**Members are freed at collapse, and measured on the way out.** Retaining them past
collapse would carry dead weight through statistics and rendering for no purpose but
observation. The payload is captured as a high-water figure at collapse instead, so
`members_memory_bytes` reports what retention actually cost at its peak while
`counter_memory_bytes` stays the live figure. The two diverge, which is the signal
D10 designed them to give.

### Where collapse happens

At the **cluster reinject loop** in `group_similar_messages` — the point where a
cluster's `bin_entry` lands in `%log_messages_counters`. Every cluster passes through
it exactly once, in sorted order, after every merge path has run. That is "at
finalize" in D1's sense.

D1 also scopes the guarantee to *every* combination of two bin-counter histograms,
not just today's caller, so a future merger must not be able to reintroduce the loss
by forgetting to collapse. `calculate_statistics_bin` therefore collapses lazily as a
safety net if it is ever handed an entry with members outstanding — one array test on
a path that already walks the entry.

### Telemetry consequences, and the contracts they amend

| field | before | after |
|---|---|---|
| `rebin_merge_events` | rises with consolidation | **0** — nothing projects at merge time |
| `rebin_finalize_events` (`summary_table` / `csv_output`) | contractually 0 | the collapse projections |
| `members_memory_bytes` | equal to `counter_memory_bytes` | high-water member payload; diverges |
| `counter_memory_bytes` | live payload | unchanged |

The projection count is accumulated during collapse and drained into
`$bin_counter_telemetry{summary_table}` by `finalize_message_stats_unified`, which
runs after the consumer — the same pattern `%message_stats_audit` already uses.

Amended in the same commit: `features/187-histogram-bin-counter-percentiles.md`
§ Decision 8 (the `rebin_finalize_events`-is-zero and members-equal-store contracts
both stop being true), and the assertions in
`tests/validate-histogram-bin-counters.sh` that hold them.

### Done

The acceptance test already exists. `tests/statistics-drift/known-failures.tsv` holds
the #459 entries, the registry is self-clearing, and a registered comparison that
starts passing fails the run — so the entries are deleted in this change or it does
not merge. Beyond that: `L3=OK` (not `OK-WITH-XFAIL`) on the consolidated scenarios,
the full harness suite, and the benchmark gated against
`tests/baseline/results/dev-virtualized-v0.18.0-pre-stage4.tsv`.

The L1 re-bless on the merged rows is the per-quantile measurement of what this
bought, and is read before it is accepted (see § Re-blessing the stage-3 baseline).

### Stage 4a findings — D1 is implemented; the acceptance criteria were attributed to the wrong issue

**F1 — The guarantee holds, exactly.** `prototype/459-order-independence/order-independence.pl`
combines the same members in ten orders (arrival, reversed, eight shuffles) at
depths 2, 5, 15 and 40, using the production subs sliced verbatim out of `ltl`.
Stored counts are byte-identical and all nine percentiles are bit-identical in
every order, at every depth. Projections equal member count exactly — one per
member, which is the floor.

**F2 — The defect this fixes is invisible to the oracle by construction, and the
acceptance criteria were written as if it were not.** #426 F45 already established
what order-dependence costs: merging the same key set in different orders lands on
different state on **68 % of groups** at bins-per-decade 53 and **92 %** at 616, with
a per-quantile spread up to **2.00 bins** — and that "the harness cannot see it,
because the order is deterministic for a given input". That is exactly what F1 above
now measures at zero. The statistics oracle compares one deterministic run against a
recomputation of the same input; it has no way to observe that a different order
would have given a different answer. Expecting its complaints to clear was a category
error in D18's attribution, not a shortfall in the change.

**F3 — The oracle's complaints are the accuracy-bound correction, which #460 owns.**
#426 F46 measured the same thing directly: the one-bin bound written into #189 R4
holds only while no remap has occurred, every merge is a remap, and **the correction
applies to today's shipped code regardless of which representation is adopted**. The
residual here is that bound: worst percentile deviation 4.18 % against a bucket
4.44 % wide, i.e. inside one bucket, which is what #426 F48 measured for a *single*
projection (within one bin on 3,999 of 4,000 evaluations, worst 1.0008). The
registered known-failures are therefore re-attributed from #459 to #460's amended
bound rather than deleted. Measured movement across the three consolidated bin
scenarios: 33 breaches → 28, median 3.82 % → 3.76 %, worst percentile 4.20 % → 4.18 %,
worst spread 32.55 % → 27.18 %. Cluster depth on these logs never drove the old code
past one bucket either, because once the target's geometry covers the membership the
union stops widening and the target stops being re-projected — the depth that matters
is the number of times the union grew, not the number of merges.

**F4 — A shared grid is not the alternative; that was settled before this drop.**
#426 F37 measured it and the advantage reverses with resolution: seeding each key's
partition around its own first value is adaptive to that key's data, and that
advantage **grows** with bins-per-decade — the current representation is ahead from
115 up (0.021 % against 0.239 % on Tomcat's most populous band) and the two are mixed
at 53. F36 priced the switch at 16–32 % of per-key percentiles moving more than 1 %.
The resolution lever is the supported way to shrink this residual: the per-message
surface runs at 53 bins per decade by default, and `--data-model-precision` takes it
to 80, 115, 256 and 616, where one bucket is 0.374 %.

**F5 — Retention impact analysis: how many histograms a grouped row holds, and what
that costs.** Five real logs from the corpus, each run at all five resolutions the
precision lever reaches (4, 16, 53, 115 and 616 bins per decade on the per-message
surface; 53 is the default). Fuzzy grouping at 90 %, top 25 rows, bin data model.
`members_per_partition` was added to the verbose telemetry for this — a total and a
maximum cannot size a ceiling, because a total says nothing about whether the load is
spread across rows or sits in one of them.

| log | rows | histograms held | per row p50 / p95 / max | live KB | held KB | ratio | peak RSS MB |
|---|---|---|---|---|---|---|---|
| GC (79 MB) | 11 | 11 | 1 / 1 / 1 | 15.3 | 15.3 | 1.0 | 74 |
| Apache access (98 KB) | 15 | 55 | 1 / 33 / 33 | 26.3 | 71.4 | 2.7 | 27 |
| Codebeamer access (83 KB) | 123 | 223 | 1 / 2 / 76 | 158.5 | 267.1 | 1.7 | 30 |
| Tomcat access (148 MB) | 643 | 3 074 | 1 / 12 / 314 | 912.3 | 3 647.7 | 4.0 | 128 |
| ThingWorx ScriptLog (30 MB) | 26 | 3 419 | 4 / 791 / 1 283 | 59.0 | 4 488.1 | **76.1** | 81 |

(at the default 53 bins per decade; `live` is the histograms that survive to the
statistics, `held` is those plus every member retained until its row was finalized.)

- **The count of retained histograms does not depend on resolution** — it is a
  property of how the log groups. Every log above holds the same number at 4 bins per
  decade as at 616.
- **The memory does, linearly.** ThingWorx at 616: 50 324 KB held against 672 KB
  live, and process peak RSS 146 MB against 81 MB at the default. Tomcat at 616:
  40 736 KB held, peak RSS 182 MB. Resolution and retention multiply.
- **The distribution is extremely skewed, and that is what makes a ceiling cheap.**
  The median grouped row holds 1–4 histograms everywhere. The cost is in a handful of
  rows: ThingWorx's 17 grouped rows hold 3 411 histograms between them, and the top
  two hold 2 074 of those.

What a per-row ceiling would recover, computed from the exact grouping each run
published:

| ceiling | ThingWorx held | rows affected (of 17) | Tomcat held | rows affected (of 166) | Codebeamer held | rows affected (of 20) |
|---|---|---|---|---|---|---|
| 8 | 3.1 % | 10 | 28.3 % | 45 | 43.3 % | 1 |
| 16 | 5.5 % | 10 | 38.9 % | 25 | 50.0 % | 1 |
| 32 | 9.4 % | 6 | 51.4 % | 18 | 63.3 % | 1 |
| 64 | 15.0 % | 6 | 68.4 % | 10 | 90.0 % | 1 |
| 128 | 24.5 % | 5 | 84.7 % | 4 | 100 % | 0 |
| 256 | 41.2 % | 4 | 95.7 % | 2 | 100 % | 0 |

**The trade a ceiling buys and pays.** Members beyond the ceiling have to be combined
as they arrive, which is the arithmetic this issue removed — so a capped row gets its
order-dependence back for the part above the ceiling, while every row under the
ceiling keeps the guarantee. The ceiling therefore decides how many rows on a real
log lose the property, not whether the property exists. At 32 that is 6 of 17 rows on
ThingWorx and 18 of 166 on Tomcat; at 128, 5 and 4.

**The ceiling value is not decided here.** The numbers above are what it should be
decided from.

**F6 — Drift against the committed reference numbers is confined to the intended surface.** 49 cells moved, all in the
three `*-bin-consolidated` scenarios' `messages` rows, all percentile or IQR columns.
No count, no min, no max, and no scenario outside the bin data model moved.

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
