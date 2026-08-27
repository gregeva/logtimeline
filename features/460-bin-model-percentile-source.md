# Bin-model percentiles, and the contracts that described them wrongly

Owning issue: **#460** (BUG: bin-model percentiles are computed below the resolution
the tool captured, and the accuracy contract is wrong in eight places). Stage 4b of the
drop recorded in
[`bin-counter-accuracy-and-observability.md`](bin-counter-accuracy-and-observability.md);
that document holds the drop's locked decisions and stage order, this one holds what
stage 4b changed and what it measured.

---

## 0. The contracts this work is bound by

Read [`459-bin-counter-combination-order.md`](459-bin-counter-combination-order.md) § 0
first — it lists the same corpus and the clauses that bind this surface, and nothing
here supersedes it. The clauses this work touches directly:

| where | what it holds, and what this work does to it |
|---|---|
| `187-…md` § R4 | The accuracy contract. Amended here: it was derived for a partition that has never been re-projected. |
| `187-…md` Decision 4, § R7, § Edge cases, § Validation | The out-of-range mechanism, described as a live audit signal. Amended: guards expected to read zero. |
| `187-…md` § R10, Decision 8 | The per-consumer path codes and the locked `-V` field set. Amended: `pre_migration` is retired. |
| `189-…md` § R4, § R6, § R12 | The percentile primitive, the out-of-range counters, and the projection wrapper. |
| `34-…md` § R5, § R6, § R7, § R8 | The display-geometry surfaces. Amended: percentiles no longer come from the finalized partition. |
| `287-…md` § R2.3 | The combination description. Amended: the shipped code computes a union geometry and projects each side into it once. |
| `201-…md` | The stream-at-616, project-at-finalize lifecycle, which is unchanged — only which side consumes the projection changed. |

---

## 1. What was wrong

Two defects, one in the code and one in the documents.

**The code.** The heatmap and histogram surfaces stream at bins-per-decade 616, project
down to display shape at finalize, computed every percentile from the coarse projected
partition, and discarded the high-resolution one. The precision was captured and thrown
away before the number was calculated. One re-projection therefore preceded every
histogram and heatmap percentile the tool shipped, on the default surface, with no flags
— the per-message surface (`calculate_statistics_bin`) was already computing from the
streaming entry and was the pattern to copy.

**The documents.** Eleven passages across four feature docs described behaviour the code
does not have: an accuracy bound derived for a partition that is never re-projected, an
out-of-range audit that cannot fire, a combination described as extending the narrower
histogram onto the wider one, a path code no run can produce, an opt-out flag and two
verbose lines the emitter does not have, a validation report claiming coverage it does
not have, an unreachable equal-edge case, a caller-side guard for values at or below zero
that was not stated as part of the contract, and per-partition memory guidance covering
one of the two layouts.

---

## 2. What changed in the code

**Percentiles are computed from the streaming partition** in
`finalize_histogram_unified()` and `finalize_heatmap_unified()`, including the
histogram's highlight sub-store. The display projection is untouched and still produces
the bars, the cells, the boundaries and both `rebin_finalize_events` increments — what
changed is that the percentile no longer consumes it.

**Retention is by ordering, not by holding.** The streaming entry is still alive at the
point the percentiles are computed; the `delete` that frees it is the last statement of
each loop iteration and stays exactly where it was. D2's "retained, not discarded" is
satisfied without raising peak memory, because nothing downstream reads those stores.

**The value is clamped to the display axis before it is published or mapped.** This is
not optional. The streaming partition's outermost bins extend past the observed extremes
— the five-decade seed and the doubling growth are geometry, not observations — and on
the heatmap the axis floor can additionally sit above the smallest observed value when it
is pre-seeded from the index. Unclamped, the histogram would print a legend value outside
the axis next to a tick pinned to the axis edge, and the heatmap would render a marker
that falls a hair below the axis floor in the **far right** column, because
`find_heatmap_bucket()`'s fall-through returns the last column for anything it does not
match. The clamp keeps the four surfaces that must agree — printed legend value,
published `-V` tick input, computed tick column, rendered axis — consistent by
construction. It is the same remedy, for the same reason, that `calculate_statistics_bin`
already applies.

**`path: pre_migration` is retired.** Every consumer in the block order runs the unified
path, so the value could not be produced; a locked contract value that nothing can emit
and nothing asserts is not instrumentation.

**A notice is printed when consolidation meets the bin message-stats model** (D5). It
names how many message histograms were combined when the run can show that, states the
condition when it cannot, and points at `-mdm raw`. It prints on stderr regardless of
`--disable-progress`, which suppresses progress indicators, not decisions the tool made
on the user's behalf.

---

## 3. What it bought, measured

`tests/fixtures/tomcat-access-duration-spread.txt`, 434 lines, `-hg`, tick values read
from `-V histogram-percentile-ticks` against the exact `-hgdm raw` reference for the same
run:

| metric | exact reference | before | after |
|---|---|---|---|
| duration P50 | 30 | 29.986 (−0.045 %) | 30.009 (+0.030 %) |
| duration P99 | 5455 | 5129.8 (**−5.96 %**) | 5455 (exact) |
| duration P99.9 | 5455 | 5455.0 (exact) | 5455 (exact) |
| bytes P50 | 5520 | 5863.4 (**+6.22 %**) | 5519.6 (−0.007 %) |
| bytes P99 | 409600 | 380842 (**−7.02 %**) | 409600 (exact) |

The pattern is the one the defect predicts: the error was largest where the display
projection is coarsest relative to the data, and it disappears where the streaming
resolution resolves the value exactly.

`-V percentile-algorithm` has always advertised `effective_bpd: 616` for these two
surfaces, and the #224 oracle reads it. That claim was false on exactly the two surfaces
this change fixes, and is now true.

---

## 3a. What moved, and what did not

The complete harness suite passes. Two things in it had to be trued up, and both were
read before they were accepted:

- **18 of the 25 bin reference renders moved**, and nothing else did. 39 lines changed
  across them: percentile legend values, x-axis tick columns, and heatmap marker
  columns. No bar, no cell, no count, and no statistics column moved, and the
  non-panel part of every heatmap row is byte-identical — which is the render-side
  half of D2 holding. The 53 raw scenarios reproduced byte-identically in the same
  capture, so nothing was silently re-blessed.
- **The statistics drift baselines did not move at all.** The re-bless the drop record
  anticipated for this stage did not happen, and should not have: the per-message
  surface already computed from its streaming partition, so a change confined to the
  display surfaces cannot move a `messages.csv` or `stats.csv` cell. The three
  consolidated scenarios still carry their 15 XFAIL entries, now attributed to #469.
- `--explain iqr`'s harness asserted the phrase "bin-width interpolation", which the
  amended wording replaced with "within-bucket interpolation" — the phrase the
  documentation now uses throughout. The assertion follows the wording.

**Benchmark**, `single-day-access-log-standard` against the same-host pre-stage-4
reference: `total` −3.5 %, `parse/read_files` −3.4 %, `rss_peak` −0.4 %. Nothing worse
by more than 5 % (`format_scan_subs` +4.5 %, a measure this change does not touch).

**One defect found in the way.** `tests/baseline/run-benchmark.sh` invoked `$LTL`
unquoted, so on a checkout whose path contains spaces every test failed as "ltl
returned non-zero" before it ran. Fixed in this change because the benchmark gate could
not otherwise be run; it is not part of this issue's subject.

---

## 4. The bound that remains

Consolidation. A consolidated row's member histograms are projected onto one shared union
geometry before they are combined, so its percentiles stay within about one bucket of the
pooled-sample answer. On real duration streams a single collapse leaves the one-bucket
bound on **1.54 %** of evaluations (Tomcat access log) and **2.08 %** (ThingWorx
scriptlog); on generated maximally-disjoint pairs the rate is 1 in 4,000, worst 1.0008 bin
widths. The two figures measure different inputs and the amended contract text names which
is which.

That bound is removed structurally only by **#469** (consolidated rows held on a shared
bucket grid), which is not in this release. The 15 entries in
`tests/statistics-drift/known-failures.tsv` are attributed there, not here — see the drop
record § *Stage 4b's XFAIL entries moved again, to #469* for why, and what #460 is judged
on instead.

---

## 5. Open, for the architect

Two items recorded for this pass are decisions about the locked `-V` contract rather than
defects with one correct fix, and are not taken here:

- **The `/ dimensions` sub-section reported a different epoch from its parent.**
  Settled by the architect on 2026-08-27 and delivered under #473: the sub-section is
  renamed `histogram-bin-counters / display-dimensions`, so its name states that it
  describes the geometry produced by the display projection while its parent's fields
  describe the streaming partitions before it.
- **The highlight sub-stores are observed by nothing.** Whether the highlight subset
  becomes its own consumer name or folds into the parent's figures is a Decision 8
  consumer-name question. Disposition A is a new locked-decision entry plus new harness
  scenarios; disposition B changes what six already-locked field descriptions mean.
  Filed as #473's sibling, #472.
