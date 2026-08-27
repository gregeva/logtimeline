# Combining bin-counter histograms — order independence, and what it costs

Owning issue: **#459** (BUG: combining bin-counter histograms is not commutative —
the answer depends on combination order). Stage 4a of the drop recorded in
[`bin-counter-accuracy-and-observability.md`](bin-counter-accuracy-and-observability.md);
that document holds the drop's locked decisions and stage order, this one holds the
#459 investigation.

Probes: [`prototype/459-order-independence/`](../prototype/459-order-independence/)
(see its README for what each one asks). All of them load the production subs sliced
verbatim out of `ltl`, so they measure the shipped path.

---

## 1. What was wrong, and what was built

Each message key seeds its own histogram around its own first observed duration, so
no two keys' bucket edges line up. Combining two of them therefore re-projected both
onto a union geometry by geometric midpoint — a lossy step — and every subsequent
combination re-projected counts that had already been projected. Combine the same
group in a different sequence and the stored counts differ, and so do the
percentiles.

Implemented per the drop's locked decision D1: **combining projects nothing**. The
source's counts are kept in their own untouched geometry on the target's
`member_entries` list, and `collapse_bin_counter_entry()` computes one union geometry
over the whole membership and projects each member into it exactly once, from counts
nothing has displaced. The union is a min/max over the whole set, so it does not
depend on arrival order.

Two readings settled during implementation:

- **A single log line is not a member.** The streaming inline path merges a per-line
  single-sample source into a cluster; treating each as a member would retain one
  histogram per line. It is an ordinary value insertion into the cluster's own
  histogram instead — exact, projects nothing. `counter_update`'s per-entry work was
  split into `counter_entry_new()` and `counter_entry_observe()` so both callers
  share one surface, which also removed a temporary store and a hash insert from the
  hot path.
- **Members are released at collapse, and measured on the way out.** Holding them
  through statistics and rendering buys only observation. `members_memory_bytes`
  reports what retention cost at its peak; `counter_memory_bytes` stays the live
  figure.

Telemetry follows the mechanism: `rebin_merge_events` reads 0 everywhere,
`rebin_finalize_events` on the per-message consumer reports the collapse projections,
and `members_per_partition` was added because a total and a maximum cannot size a
ceiling — a total says nothing about whether the load is spread or concentrated.

---

## 2. Findings


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

**F6 — Drift against the committed reference numbers is confined to the intended surface.** 49 cells moved, all in the
three `*-bin-consolidated` scenarios' `messages` rows, all percentile or IQR columns.
No count, no min, no max, and no scenario outside the bin data model moved.


---

## 3. What a ceiling would mean

**The mechanism.** A row that reaches the ceiling collapses what it is holding — one
union geometry over those histograms, each projected into it once — and carries on
holding that single result plus new arrivals. So a row never holds more than the
ceiling, and a row of N histograms takes ceil(N / ceiling) collapses instead of one.
It is not a return to combining pair by pair.

**Two counts that must not be confused, because only one of them is about accuracy.**

- *Projection operations performed* — roughly one per histogram whatever the ceiling
  is. That is a speed property, not an accuracy one.
- *Projections a single count passes through before it is read* — 1 with no ceiling,
  ceil(N / ceiling) with one. This is the lossy one, and avoiding it entirely is the
  whole point of deferring the work to the end.

**Why the earliest-absorbed counts drift furthest.** The first batch collapses into
one result; that result is then one input among the next batch's arrivals, and if
they widen the range it is projected again. Ten batches later the first batch's
counts have been carried through ten projections, while the histograms that arrived
in the last batch have been through one — they met the final geometry directly. With
no ceiling *everything* is a last arrival: one geometry, one projection each.

A qualifier that cuts the effect down in practice: a carried result is only
re-projected when the union actually widens. If a later batch brings nothing outside
the existing range it is reused untouched. That is the same behaviour seen on the
real logs (F2), where the widest values arrive early and the union then stops moving.
So ceil(N / ceiling) is the worst case, not the realised depth.

**What it costs, against the depth curve the earlier research measured.** A single
projection stays within one bucket on 3,999 of 4,000 evaluations. Against depth, the
old pair-by-pair merge measured 1.25 buckets at depth 1, 1.40 at depth 3, 1.51 at
depth 7 and 2.10 at depth 15. A ceiling puts the deepest rows back onto that curve,
at a depth the ceiling chooses.

**Peak memory and worst-row depth per candidate ceiling.** Peak memory is the sum over
rows of min(row's histograms, ceiling); depth is for the deepest row on that log.

| ceiling | ThingWorx peak held / worst-row collapses | Tomcat peak held / worst-row collapses | Codebeamer peak held / worst-row collapses |
|---|---|---|---|
| none | 4 478 KB / 1 | 3 172 KB / 1 | 144 KB / 1 |
| 512 | 3 099 KB / 3 | 3 172 KB / 1 | 144 KB / 1 |
| 256 | 1 844 KB / 6 | 3 034 KB / 2 | 144 KB / 1 |
| 128 | 1 095 KB / 11 | 2 688 KB / 3 | 144 KB / 1 |
| 64 | 673 KB / 21 | 2 170 KB / 5 | 129 KB / 2 |
| 32 | 421 KB / 41 | 1 632 KB / 10 | 91 KB / 3 |
| 16 | 245 KB / 81 | 1 233 KB / 20 | 72 KB / 5 |
| 8 | 140 KB / 161 | 898 KB / 40 | 62 KB / 10 |

(at the default 53 buckets per decade; multiply by 11.6 for the top resolution — the
ThingWorx `none` row is 52 042 KB there, and the 128 row is 12 724 KB.)

The shape of the trade differs by log because the shape of the grouping does. On the
ThingWorx scriptlog nearly all the memory is in two rows, so a ceiling is extremely
effective and extremely concentrated: 128 recovers three quarters of the memory and
puts 5 rows of 17 onto a depth-11 curve. On the Tomcat access log the load is spread
over 166 rows, so the same ceiling recovers only 15 % and touches 4 rows. On
Codebeamer nothing above 128 has any effect at all.

**And a consequence that cuts against what #459 delivered.** Any ceiling makes the
answer depend on arrival order again: the row's geometry comes from whichever
histograms were in the batch when the first collapse fired, so a different order gives
a different starting range and a different number of collapses. Deferring everything to
one collapse at the end is precisely what made order irrelevant. Section 5 is what
removes this objection.

**The ceiling value is not decided here.** The numbers above are what it should be
decided from.

## 4. Considered — a retention ceiling whose combined resolution follows depth

Architect's direction, 2026-08-27: *"allow the histograms needing the precision to
take more memory, and keep the ones that don't small."*

**Shape.** A grouped row holds at most a fixed number of member histograms. On
reaching it, the row collapses what it holds into one combined histogram and carries
on. The combined histogram of a row that hit the ceiling is built at a **higher
resolution than its members**; a row that never reaches the ceiling collapses once, at
the default resolution, and is unchanged in every respect.

**Why the higher resolution is the load-bearing part.** A member's own quantisation
cannot be undone — its counts already sit at its own bucket midpoints. But the
projection that places those midpoints onto the combined scale need not add error of
its own, and it barely does when the combined scale is much finer. So the carried
result stops decaying across successive collapses, which is the entire cost of having
a ceiling. Measured (`prototype/459-order-independence/merge-resolution.pl`, 256
members, deviation from a single partition over the pooled samples, in member bucket
widths, median / worst):

| | one collapse | batched at a ceiling of 8 (32 collapses) |
|---|---|---|
| combined at the members' resolution | 0.076 / 0.204 | **0.363 / 0.523** |
| combined at 616 buckets per decade | 0.061 / 0.304 | **0.069 / 0.304** |

Batching at the same resolution costs ~5× in typical error. Batching into a finer
combined scale is as accurate as not batching at all.

**Memory, modelled from the measured per-row grouping and per-row payloads.** Peak
retention as a percentage of holding everything:

| ceiling / combined resolution | ThingWorx | Tomcat | Codebeamer |
|---|---|---|---|
| 8 / default 53 | 3.2 % | 18.2 % | 13.2 % |
| 8 / 256 | 5.1 % | 24.9 % | 15.1 % |
| 8 / 616 | 8.6 % | 36.8 % | 18.4 % |
| 16 / 256 | 7.5 % | 23.2 % | 18.7 % |
| 32 / 256 | 7.6 % | 27.9 % | 25.9 % |

The crossover that makes this work: one combined histogram at 616 buckets per decade
costs what **17–39 retained member histograms** cost, measured across the five logs.
Any row grouping more than that is cheaper as one high-resolution histogram than as
its members — and more accurate than collapsing it at the default resolution.

**Open, for the architect.**

- The ceiling value, and whether it is user-visible or internal.
- How combined resolution is chosen: one fixed step up, or a ladder that follows how
  many histograms the row absorbed.
- Whether percentiles are then read from a per-row histogram whose resolution varies
  by row — the statistics contract currently describes one resolution per surface.
- Whether this rides #459 (combination order-independence, delivered) or is filed as
  its own requirement, since the ceiling was deferred to the development flow rather
  than scoped into that issue.


---

## 5. Measured — folding is a lossless coarsening, and it does not compound

Raised by the architect, 2026-08-27: if the range can be grown by adding decades, why
can the resolution not be *lowered* as decades are added, so memory flattens out while
precision stays where it matters?

It can, and the operation is exact. Doubling the log-span while holding the bucket
*count* fixed — so buckets-per-decade halves — makes each pair of adjacent buckets one
bucket. Every count stays inside the interval it was already in; nothing is moved to a
midpoint, which is the step that loses information.
`prototype/459-order-independence/fold-exactness.pl` confirms total mass and per-bucket
identity are preserved through the fold.

The property that matters is that it **does not compound**.
`prototype/459-order-independence/fold-compounding.pl`, 20,000 samples, error against
the raw sorted data measured in whatever the *current* bucket width is:

| folds | buckets | buckets/decade | worst error, in current bucket widths |
|---|---|---|---|
| 0 | 3 080 | 616 | 0.31 |
| 1 | 3 080 | 308 | 0.19 |
| 2 | 3 080 | 154 | 0.09 |
| 3 | 3 080 | 77 | 0.04 |
| 4 | 3 080 | 38.5 | 0.03 |
| 5 | 3 080 | 19.2 | 0.06 |

Resolution falls 32-fold and the error never leaves a fraction of a bucket, because a
count can never leave its own bucket — only find itself in a wider one. This is
structurally unlike geometric-midpoint re-projection, where a bucket's mass is moved
to whichever bucket contains its midpoint and repeated moves accumulate.

Two supporting checks recorded so they are not re-derived:

- **Today's range growth does not move counts on the cases probed.**
  `prototype/459-order-independence/growth-alignment.pl` extends a partition past its
  maximum and finds the existing counts land as a pure index shift at every resolution
  in the tier table. The probe is small (a handful of occupied buckets) and is
  evidence, not proof; it is recorded because it removes growth from the list of
  suspects rather than because it settles it.
- **Per-row resolution is computationally free.** `percentile()` reads `bin_count` and
  `log_ratio`, never `bpd`. Rows carrying different resolutions therefore change no
  arithmetic and cost nothing; the only surface that assumes one resolution per
  consumer is a single `-V` line reporting `effective_bpd`. A design in which
  resolution varies row by row is a reporting question, not a contract obstacle.

**An open question this raises and does not answer.** If memory is to be spent where
precision is needed, "needed" can key on two different things, and they do not select
the same rows:

- **depth** — how many histograms the row absorbed, which sets how many collapses its
  counts pass through and therefore its exposure to decay;
- **span** — how much range the row covers, since memory is buckets-per-decade ×
  decades and a bucket is a *percentage* width, so a wide row has coarse buckets in
  relative terms at any setting.

Section 6 makes the question largely moot by letting resolution follow span inside a
fixed budget, but it is recorded because it is the question a depth-keyed design would
have to answer.

---

## 6. Measured — a canonical grid with a fixed bucket budget

Architect's objection, 2026-08-27: a canonical grid still has a problem as the range
grows at the next consolidation. Measured, and it does not — because with a canonical
grid, growth is not a re-derivation of geometry at all.

Bucket j covers [10^(j/B), 10^((j+1)/B)). The grid is defined by the resolution B
alone, not by any observed value. So:

- **Widening the range addresses more grid indices.** Nothing is recomputed and
  nothing is moved. There is no geometry to re-derive, which is the step that costs
  today.
- **Halving B maps index j to floor(j/2).** Every pair of buckets becomes one, and no
  count leaves the interval it was already in. Exact, and the result is identical to
  having binned at the lower resolution from the start, because the coarser grid is a
  strict subset of the finer one.

Both operations are exact, so the only lossy step remaining is the single projection
of each member's own (non-canonical, adaptively-seeded) buckets onto the grid.

`prototype/459-order-independence/canonical-fold-target.pl`: a combined-row target
starting at 616 buckets per decade with a fixed bucket budget, absorbing members as
they arrive and folding whenever the occupied span exceeds the budget. Twelve arrival
orders (arrival, reversed, ten shuffles) crossed with three batch sizes (8, 32, all at
once), against the raw sorted samples:

| members | budget | final buckets/decade | order and batch mismatches | worst error vs the raw data |
|---|---|---|---|---|
| 16 | 512 | 77 | **0 of 12** | 0.82 member buckets |
| 16 | 2 048 | 308 | **0 of 12** | 0.73 |
| 64 | 512 | 77 | **0 of 12** | 0.22 |
| 64 | 2 048 | 308 | **0 of 12** | 0.30 |
| 256 | 512 | 77 | **0 of 12** | 0.14 |
| 256 | 2 048 | 308 | **0 of 12** | 0.14 |

Byte-identical stored counts across every order AND every batch boundary — the
property a retention ceiling would otherwise have destroyed — with the error under
one member bucket width throughout and improving with depth.

**What this displaces.** Members are absorbed as they arrive and never held, so the
retention this drop set out to measure and cap does not arise. Memory becomes one
bounded histogram per grouped row: at a 512-bucket budget, 4 KB per grouped row —
70 KB across the ThingWorx scriptlog's 17 grouped rows against 4 488 KB retained, and
680 KB across the Tomcat access log's 166 against 3 648 KB. The ceiling question, the
ceiling's cost in re-projection depth, and the resolution-follows-depth proposal above
all dissolve: resolution follows *range*, automatically, inside a fixed budget.

**What is not yet established.** Whether anchoring the COMBINED row's histogram to a
canonical grid is in bounds given that the earlier research rejected anchoring the
PER-MESSAGE histograms — the adaptivity argument that decided that (a message's
partition adapts to that message's own data) does not obviously transfer to a row that
already spans many messages, but that is reasoning, not measurement. Also unmeasured:
cost per absorbed member against the shipped path, and the behaviour on the real
corpus rather than on generated members.

---

## 7. Where this stands

**Delivered on the branch** (`459-bin-counter-combination-not-commutative`, not
merged): the deferred collapse of section 1, proved order-independent in section 2,
with the retention it causes measured in section 2 and its telemetry shipped.

**Superseded by measurement, not yet built:** the canonical-grid target of section 6
achieves the same order-independence, adds independence from batch boundaries, holds
memory to a fixed budget per grouped row, and needs no retention at all. On the
deepest log it is 70 KB against 4 488 KB. If it is adopted, sections 3 and 4 — the
ceiling, its value, its cost in depth — cease to be questions rather than being
answered.

**Open, and for the architect:**

- Whether anchoring the **combined row's** histogram to a canonical grid is in bounds.
  The earlier research rejected anchoring the **per-message** histograms because a
  message's partition adapts usefully to that message's own data; a combined row
  already spans many messages, so the argument does not obviously transfer. This is
  reasoning, not measurement, and is the one claim in section 6 that is not measured.
- The bucket budget per grouped row, if section 6 is adopted, and whether it is
  user-visible or internal.
- Whether the work lands on #459 or is filed as its own requirement. #459's stated
  requirement — the same answer whatever order members arrived in — is delivered by
  what is on the branch; section 6 is a different mechanism reaching further.
- What happens to the remaining oracle deviations. They are the accuracy-bound
  correction owned by #460 (bin-model percentiles computed below the captured
  resolution, plus the eight-correction amendment pass), not a #459 residual — see F3.

**Not open:** a shared grid for the per-message histograms (settled by the earlier
research, F4), and the ceiling-versus-no-ceiling trade as an accuracy question
(section 6 removes it).
