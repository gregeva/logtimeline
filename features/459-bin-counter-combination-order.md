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

> **Probe correction, 2026-08-27.** The first run of every probe seeded a member's
> histogram with `counter_entry_new()` and did not then observe that first value —
> production's `counter_update()` seeds *and* observes. Each member was therefore
> missing one sample, and single-sample members contributed nothing at all. Every
> probe was fixed and re-run; the numbers below are from the corrected runs. No
> conclusion reversed, but two moved materially and are flagged where they appear
> (F4, and the grid-anchored arm in § 5).



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

**F4 — The shared grid is NOT settled, and this drop's first reading of it was
wrong.** The earlier research (#426 F37) measured per-message shared-grid seeding as
losing to per-key adaptive seeding at higher resolutions — ahead from 115 buckets per
decade up (0.021 % against 0.239 % on Tomcat's most populous band), mixed at 53 — and
priced a switch at 16–32 % of per-key percentiles moving more than 1 % (F36). That is
a real cost and it stands. It is **not** a decision to close the topic, and the
architect has said explicitly that it remains open (2026-08-27).

This drop's own probe of the idea
(`prototype/459-order-independence/grid-anchored-seed.pl`) first reported that
snapping each partition's seed floor to a global grid "does not reach zero". That
reading was wrong twice over: the probe carried the seeding defect noted at the top of
this section, and the union bucket count was derived with `int()`, which on
grid-aligned extents lands a hair under an exact integer and truncates, shifting every
edge. With both corrected, the grid-anchored arm reads **exactly zero** median
deviation at every depth measured, and zero maximum at depths 2 and 5:

| members | seeded on first value (today) | seeded on a global grid, bucket count rounded |
|---|---|---|
| 2 | 0.255 / 0.427 | **0.000 / 0.000** |
| 5 | 0.174 / 0.377 | **0.000 / 0.000** |
| 15 | 0.152 / 0.439 | **0.000 / 0.342** |
| 40 | 0.066 / 0.196 | **0.000 / 0.125** |

(median / maximum, in member bucket widths, against a single partition over the
pooled samples.) The residual at depths 15 and 40 traces to the same truncation
inside `partition_extend`'s growth, not to the idea. What this does **not** measure is
F37's finding — the accuracy of the per-key streaming representation itself across the
resolution ladder — which is the ground the earlier rejection stood on. The two
questions are separable and only one of them has been re-opened here.

**A constraint the architect stated, 2026-08-27:** histogram *bounds* cannot be
anchored, because any line still to be read can move them. That is one of the
attributes that made grid counters inappropriate. It is worth recording precisely what
a canonical grid does and does not fix, because the two are easy to conflate: it fixes
the **bucket edges** (bucket j is [10^(j/B), 10^((j+1)/B)), a function of the
resolution alone), and it fixes **nothing about the range**. The occupied span grows
freely as lines arrive — a new value simply addresses an index that was not occupied
before, with no geometry re-derived and no count moved. Whether that distinction
satisfies the constraint is the architect's call, not settled here.

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
| combined at the members' resolution | 0.039 / 0.204 | **0.294 / 0.523** |
| combined at 616 buckets per decade | 0.072 / 0.304 | **0.105 / 0.304** |

Batching at the same resolution costs ~7× in typical error. Batching into a finer
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
| 16 | 512 | 77 | **0 of 12** | 0.68 member buckets |
| 16 | 2 048 | 308 | **0 of 12** | 0.51 |
| 64 | 512 | 77 | **0 of 12** | 0.46 |
| 64 | 2 048 | 308 | **0 of 12** | 0.46 |
| 256 | 512 | 77 | **0 of 12** | 0.12 |
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

## 7. Measured — both designs on the real corpus

Sections 4–6 ran on generated members. This runs on the real thing: the actual
per-message duration streams behind every consolidated row, grouped exactly as
`ltl -g` grouped them, extracted with
`prototype/459-order-independence/extract-real-groups.py` (which reuses the statistics
oracle's verbatim parsers, so the durations are the ones the oracle checks `ltl`
against). Reference is the exact percentile of the pooled raw durations — not a
modelled partition. Six arrival orders crossed with batch boundaries at 8, 64 and
all-at-once. Bucket budget 512.

| | Codebeamer (20 rows, 120 keys) | ThingWorx (16 rows, 3 409 keys) | Tomcat (159 rows, 2 595 keys) |
|---|---|---|---|
| agreement, deferred | identical | identical | identical |
| agreement, canonical | identical | identical | identical |
| error vs raw, deferred (p50 / p95 / max) | 0.495 / 0.894 / 0.895 | 0.201 / 0.772 / **1.289** | 0.306 / 0.821 / **1.333** |
| error vs raw, canonical (p50 / p95 / max) | **0.044 / 0.097 / 0.159** | **0.136 / 0.547 / 0.813** | **0.048 / 0.398 / 0.673** |
| peak memory, deferred | 130 KB | 4 450 KB | 2 911 KB |
| peak memory, canonical | 39 KB | **42 KB** | 233 KB |
| memory ratio | 3.4× | **106×** | 12.5× |
| cost per absorbed member | 48.7 vs 17.1 µs | 64.0 vs 22.5 µs | 49.6 vs 19.4 µs |
| coarsest resolution reached | 308 | 77 | 77 |

(errors in member bucket widths, one bucket = 4.44 % at 53 buckets per decade.)

How often each design leaves the one-bucket accuracy bound, over every quantile of
every grouped row:

| | Codebeamer | ThingWorx | Tomcat |
|---|---|---|---|
| hold-then-collapse | 0 of 180 | **3 of 144 (2.08 %)** | **22 of 1 431 (1.54 %)** |
| canonical grid | 0 of 180 | **0 of 144** | **0 of 1 431** |

Four things this establishes on real data rather than generated data:

- **Both designs are order-independent, and the canonical one is also independent of
  where the batch boundaries fall.** Byte-identical stored counts in every
  combination.
- **The deferred design breaches the one-bucket accuracy bound on two of the three
  logs** (1.29 and 1.33 member bucket widths). The canonical one stays under one
  bucket everywhere, worst 0.81.
- **The canonical design is more accurate at every quantile band**, by 1.5× to 11× at
  the median.
- **It is 3.4–106× smaller and ~2.6× cheaper per absorbed member**, because it
  absorbs on arrival and holds nothing.

---

## 8. How the two representations coexist

Architect's question, 2026-08-27. Two histogram shapes, each used where it is better,
with one hand-off point between them.

**A message that is never grouped keeps exactly what it has today.** Its histogram is
seeded around its own first duration, its bucket edges adapt to its own data, and
nothing about it changes — which matters, because that adaptivity is what the earlier
research measured as winning at higher resolutions. With `-g` off, nothing in this
design is reachable at all.

**A consolidated row gets the second shape:** buckets on shared edges, addressed by
index rather than by a stored range. Bucket *j* covers 10^(j/B) to 10^((j+1)/B), so
the resolution B is the only thing that defines where edges fall. The row stores
occupied indices and their counts — nothing else, no min, no max, no bin_count.

**The hand-off happens once per absorbed message, and it is the only lossy step.**
When consolidation absorbs a key, that key's own histogram is read once: each occupied
bucket's geometric midpoint is turned into a grid index and its count added there. The
key's histogram is then released. It is never read again, never re-projected, and
never held — which is why nothing accumulates and why order stops mattering.

Values arriving directly on the row — the streaming path where a line matches an
existing cluster — skip the hand-off entirely and address their grid index straight
away.

**Range expands by occupying indices, not by recomputing anything.** Take the
architect's example: a row whose first messages carry durations of 200 ms and above
occupies the indices covering those. A line arriving later at 60 ms computes its index,
finds it unoccupied, and occupies it. Nothing is re-derived, nothing already counted
moves, and no earlier decision constrained what could arrive. The same is true upward,
and the same is true if the very next line is 3 ms or 90 s.

That is the difference from fixing a range: today's histograms store `[min, max]` and
must re-derive geometry when a value falls outside, which is a remap. A grid stores no
range to fall outside of.

**Memory is bounded by folding, which is exact.** The row carries a bucket budget. If
the span between its lowest and highest occupied index exceeds it, resolution halves:
index *j* becomes floor(j/2), so adjacent buckets pair up and no count leaves the
interval it was in (§ 5). Resolution therefore starts fine and coarsens only as far as
the row's actual range forces — a narrow row keeps fine buckets, a row spanning five
decades ends up coarser, and both cost the same memory.

**Both shapes read out through the same percentile code.** `percentile()` uses a
partition's bucket count and range ratio and never reads its resolution, so a grid row
presents as `min = 10^(lowest/B)`, `max = 10^((highest+1)/B)`, `bin_count = highest -
lowest + 1` and is consumed identically. No consumer needs to know which shape it was
handed.

**What each shape is doing for its case.** The per-message shape spends its buckets
where one message's durations actually sit, which is why it wins on a single key. The
grid shape gives up that adaptivity — a consolidated row spans many messages, so there
is no single key's distribution to adapt to — and buys back exactness under combination
and growth. The two are not competing representations of the same thing; they are
matched to two different situations.

---

## 9. What this changes about the earlier investigation

The earlier investigation is `426-per-message-statistics-store.md` (per-message
statistics store; `not planned`, retained as a decision record). Its measurements
stand. Three things move.

**Sharpened — how often a single projection leaves the one-bucket bound.** That
investigation measured a *single* merge of two maximally disjoint generated keys as
staying within one bucket on 3,999 of 4,000 evaluations, i.e. 0.025 % breach. On real
grouped rows a single collapse breaches on **1.54 % (Tomcat) and 2.08 % (ThingWorx)**
of evaluations — 60–80× that rate, on the shape the tool actually meets. Nothing is
contradicted: the synthetic figure describes maximally disjoint pairs, the real figure
describes real groupings. But **#460's amendment pass quotes the synthetic figure** as
the direction of travel for the corrected accuracy bound, and it should quote the real
one instead, or both.

**Scoped, not overturned — why the shared grid lost.** That investigation rejected the
shared grid on two grounds: it is behind per-key adaptive seeding at higher resolutions
(a key's partition adapts to that key's own data), and switching would move 16–32 % of
per-key percentiles by more than 1 %. Both were measured over the **per-message
streaming representation**, replacing it everywhere. The design in § 6–8 leaves that
representation untouched and puts a grid only on **consolidated rows**, where the
adaptivity argument has nothing to adapt to — a consolidated row spans many messages by
definition — and where the re-bless is confined to rows that only exist because
grouping created them. So the rejection is not contradicted; it was measured over a
scope this design does not enter. Whether the per-message case should also be revisited
is open at the architect's instruction (F4), and is a different question from this one.

**Corroborated on real data.** That investigation's grid arm measured 600 B per key
against 2,381 B, and a 51,468-merge fold at 0.093 s against 3.28 s. On the real
corpus the same comparison reads 42 KB against 4 450 KB peak (106×) and 22.5 µs
against 64.0 µs per absorbed message (2.8×). Its finding that the grid is
insertion-order-independent and merge-commutative while today's representation is
neither is confirmed end to end, across arrival order *and* batch boundaries.

**Amendments it proposed, which this design makes live but narrows.** Three of its
proposed amendments were written as contingent on adopting the grid everywhere. Under
this design they apply only to consolidated rows:

- the partition-seed decision (#187 Decision 5) is untouched for per-message
  histograms and does not describe a consolidated row at all;
- the overflow/underflow decision (#187 Decision 4) is **structurally vacuous on a
  grid row** — there is no range to fall outside of — which is a stronger statement
  than the one #460 is currently set to make (that the counters are guards expected to
  read zero);
- the verbose field set (#187 Decision 8) needs a per-row answer: growth events and
  the growth distribution are meaningless for a grid row, and `max_partition_bins`
  becomes the bucket budget rather than an observation.

These are for the amendment pass to absorb, not for this issue to settle.

---

## 10. Where this stands, and the proposed direction

### Delivered on the branch, not merged

`459-bin-counter-combination-not-commutative`: the deferred collapse of § 1, proved
order-independent in § 2 and on the real corpus in § 7, with the retention it causes
measured across the corpus and the resolution ladder and its telemetry shipped. It
meets #459's stated requirement — the same answer whatever order members arrived in.

### Proposed direction

**Replace the retention with a grid-addressed consolidated-row histogram (§ 6–8).** On
the real corpus it is the better answer on every axis measured: order-independent *and*
batch-boundary-independent, more accurate at every quantile band (1.5–11× at the
median), the only one of the two that never leaves the one-bucket accuracy bound
(0 breaches in 1 755 evaluations against 25), 3.4–106× smaller, and ~2.8× cheaper per
absorbed message. It also dissolves the retention ceiling question rather than
answering it, because nothing is retained.

Shape, in one paragraph: an ungrouped message is untouched — same histogram, same
adaptive seeding, and with `-g` off none of this is reachable. A consolidated row
carries buckets on shared edges addressed by index, with no stored range to fall
outside of, so it expands by occupying an index and never re-derives geometry. A key's
own histogram is read once as it is absorbed and then released, which is the only lossy
step. Memory is held to a bucket budget by folding, which is exact. Both shapes read
out through the same percentile code.

**Sequencing.** The branch as it stands is a coherent, order-independent improvement
that is strictly better than what ships today, and it is what #459 asked for. The grid
design is a different mechanism reaching further, and it should be its own requirement
rather than absorbed into this one — which also keeps the decision to adopt it separable
from the decision to merge what is already proved.

### Decisions for the architect

1. **Is a grid on the consolidated row in bounds?** The constraint stated on
   2026-08-27 is that histogram *bounds* cannot be anchored, because a line still to be
   read can move them. A grid anchors bucket **edges** and fixes nothing about the
   range (§ 8). Confirmed as the right distinction on 2026-08-27; the design rests on
   it.
2. **The bucket budget per consolidated row**, and whether it is user-visible or
   internal. Measured at 512: coarsest resolution reached was 77 buckets per decade on
   the two large logs and 308 on the small one.
3. **Where the work is filed** — a new requirement, per the sequencing above, or an
   extension of #459.
4. **What #460's amended accuracy bound quotes.** It is currently set to quote the
   synthetic single-merge figure (within one bucket on 3,999 of 4,000). The real-corpus
   figure is 1.54–2.08 % breaching (§ 9).

### Still open, at the architect's instruction (2026-08-27)

The shared grid for the **per-message** histograms. The earlier investigation priced it
and found it behind adaptive seeding at higher resolutions, but that was never a
decision to close the topic, and this drop's own probe of it was wrong on first reading
(F4). To be returned to, separately from the consolidated-row question.

### Closed by measurement

The retention ceiling as an accuracy trade — § 6 and § 7 remove the ceiling rather than
tuning it.
