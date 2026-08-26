# #426 — Per-message statistics store: symmetric comparison of three bin-container representations

---

## 0. Scope and method

### 0.1 What this document is

An evidence assembly for one decision: **what container holds the per-message bin counters** on the substrate shared by four surfaces — per-message statistics (`-mdm bin`), bucket statistics, heatmap, and histogram. Three candidate representations are compared symmetrically. Every number is copied from a capture file under `prototype/426-results/` and its source is named. No measurement was run to produce this document.

**T is a candidate, not a reference.** A previous revision of this analysis judged S on "does anything observable change", G on "what would adoption cost", and T on nothing — recorded as a process error in `features/426-per-message-statistics-store.md` § *Process error — framing drift*. Here T is asked every question the others are asked, including its own adoption cost and its own contract breaches.

### 0.2 The three arms, in plain language

| arm | what it is | how a value becomes a bin |
|---|---|---|
| **T** | **Today's shipped code.** One dense array of bin counts **per key**, seeded around that key's *first observed value* (#187 Decision 5 — the per-key seeded partition with HdrHistogram-style doubling), grown by doubling when a value falls outside, and **re-projected** (`partition_rebin`) whenever the geometry changes. | Each key has its own bin edges. The edges depend on which observation arrived first. |
| **S** | **Span-only columns** (proposal P8+P9). The *identical arithmetic and geometry as T*, stored as a column of just the occupied span instead of a dense array. | Identical to T, bin for bin. S is a container change, not an arithmetic change. |
| **G** | **One shared log-spaced grid** (proposal P10). A value's bin index is a pure function of the value: `floor(bpd × log10 v)`. No per-key seeding, no rebin, no out-of-range state. | Every key in the store uses the same bin edges. |

`bpd` = buckets per decade, the resolution parameter (53 / 115 / 256 / 616 in the measured ladder). "Rebin"/"remap" = re-projecting existing counts onto new bin edges, by geometric midpoint. `-g` = fuzzy message consolidation, which merges bin stores.

**S2 is not a fourth arm.** It is how S's merge is implemented — `Store::S2` inherits everything from S and overrides `merge` alone. Every merge/fold figure therefore carries two S numbers: `S <dense-view> → S2 <native>`.

### 0.3 Standing statement — S = T, stated not silent

**S is digest-identical to T on every parity-tested surface in the corpus:** whole-store MD5 at 4,153 / 51,469 / 286,659 keys at bpd 53 and 616; all 90 display-finalize rows (3 geometries × 5 rungs × 2 files, 0 differing cells); all 10 bucket-stats configurations, with bit-identical accuracy figures measured independently of the digest; all four merge shapes at both bpd on both fixtures (`PARITY_OK=1`); 155 native-span-merge assertions including element-for-element raw span arrays; the `-V` section byte-compared against real `ltl`.

The single divergence anywhere in the corpus is probe **A21** (adopt-by-reference into an empty target, then add to *both* keys) — a state `ltl` cannot reach, because `merge_log_message_entry_into_cluster` deletes the source counter slot immediately after the adopt.

**Consequence for the tables:** where a table's dimension is accuracy or output, the S column would restate the T column exactly. It is **omitted by rule, with the omission stated in the table's caption** — never left silently blank. Where S can differ (memory, cost, merge implementation, `-V` field values), it carries its own measured column.

### 0.4 What was measured, on what

| surface | fixtures | scale |
|---|---|---|
| per-message (unbounded key cardinality) | `bin-twxdur-full.log` fan-out; 2026-01-14 fan-out; Tomcat 2025-05-05 | **286,659 keys** / 288,025 obs; 51,469 keys / 339,832 obs; 4,153 keys |
| bucket statistics (bounded) | DPM ScriptLog; Tomcat 2025-05-07 | 62 buckets / 122,798 obs; 29 buckets / 575,800 obs |
| display finalize (heatmap, histogram, heatmap-keyed) | DPM + Tomcat 2025-05-07 | 90 rows: 3 geometries × 5 rungs × 2 files |
| `-V` observability | 2025-03-21 | 635 keys, byte-compared to real `ltl` |
| re-bless volume | 4 committed `*-bin-data-model` scenarios | 605–37,609 cells each |

### 0.5 Method rules carried from the evidence

- **RSS is the measure of record, but only at the scale being claimed, one arm per process** (F52/F53 — the projection failures). 51,469-key RSS projections to 10⁵ keys failed at fan-out by **+68% to +385%**, while `Devel::Size` projections from the same runs held to −12%/+19%. A process building more than one arm misreports per-arm RSS by up to **47%**.
- **RSS exceeds `Devel::Size` on every arm, surface and bpd measured, by 12.6–40.6%, and the gap fraction is largest where the store is smallest** (F54). `Devel::Size` understates a compact store's real footprint *more* than a large one's. Both columns are printed side by side; no ratio here comes from `Devel::Size` alone.
- **Never state a memory ratio without a surface qualifier** (F55 — the memory inversion). The bounded and unbounded surfaces are kept as separate tables with different row counts precisely so no reader can average across them.
- **Every cost number is library-behind-the-interface.** No `ltl` build carries S or G; real-`ltl` end-to-end per-arm cost is **NOT FILLABLE**.

### 0.6 Locked decisions are decisions under review

Where this evidence pressures a locked decision, it is surfaced with the contradiction and the magnitude. **No locked decision is reported here as foreclosing an option.** Two are under direct pressure — #187 D5 (whose lifecycle clause reads "not revisitable") and #189 R7 ("a hard requirement, not an option") — and both are carried to § 7 as re-decidable.

---

## 0.7 Verification

Twelve numbers spot-checked against the captures before assembly. Two disagreements found and resolved.

| # | claim | as written | capture | verdict |
|---|---|---|---|---|
| 1 | T pct eval, msg-stats @616, 286,659 keys | 181.348 s | `message-stats-scale/fanout.txt` | ✅ confirmed, incl. range [181.257, 181.921] |
| 2 | T B/key @616, fan-out, `Devel::Size` | Part 1: **13,616**; Part 2/P6-1: **13,688** | `message-stats-scale/fanout.txt` = 13,616 (Devel MB 3,722.4); `n3n6n8/n6-v3A-armT-bpd616` = 13,688 | ⚠️ **both right, different captures.** 13,616 is the scale-run figure (3,722.4 MB); 13,688 is the one-arm-per-process V3A run (3,742.09 MB). **Resolved: cite 13,616 / 3,722.4 MB for the scale surface, 13,688 / 3,742.09 MB in the RSS-paired table, and never mix them in one ratio.** |
| 3 | S bucket-stats DPM @616 `Devel::Size` | 3,588,988 B | `v7/v7-summary.tsv` | ✅ capture confirms. Feature doc's 3,590,876 is a re-run variant; **capture wins**. |
| 4 | T max merge error, depth 15, bpd 53 DPM | 2.1026 bins, 98/1000 >1 bin | `n5-merge-shapes/T-bpd53-dpm.txt` | ✅ confirmed; p95 1.2259 confirmed |
| 5 | G breaches across all depth evaluations | 0 of 16,000; max exactly 1.000000, `_gt1eps = 0` | `n5-merge-shapes/G-bpd{53,616}-{dpm,fanout}.txt` | ✅ confirmed |
| 6 | T order-dependence, 8-key permutation, fan-out @53 | 24/25 groups, spread 2.0006 | `n5-merge-shapes/T-bpd53-fanout.txt` | ✅ confirmed; G 0/25, 0.0000 confirmed |
| 7 | S2 native fold, 286,658 merges @616 | 16.1192 s | `native-span-merge/timing-fanout-full-bpd616.txt` | ✅ confirmed [16.0283, 16.3002]; T 199.5215 confirmed |
| 8 | re-bless T3, `thingworx-bin-data-model` | 31.67% | `v8-rebless/rebless-bpd53.tsv` | ✅ confirmed; direction split 23.82% closer / 32.36% further confirmed |
| 9 | display anchors, Tomcat @616 | 13 across 24 buckets; T median 0.2667% vs G 0.0667% | `v6-all.tsv` (`heatmap-keyed` rows) | ✅ confirmed |
| 10 | `counter_memory_bytes` non-determinism | 5,988,852 / 6,149,748 / 5,988,852 (2.7%) | `n7-audit-census/ltl-repeat-3.out` | ✅ confirmed |
| 11 | fan-out exact-cell count | 573,026 of 573,318 | `accuracy-by-key-shape/fanout-bpd53.txt` | ✅ confirmed, both arms |
| 12 | S bucket-stats penalty vs T @616 DPM | Part 1 "+42%"; Part 2 same | 3,588,988 / 2,531,282 = **1.4179** | ✅ +41.8%, rounds to +42% — confirmed |
| 13 | T pct eval @616 independent reproduction | 175.97 s / 204.63 µs | `n3n6n8/n6-pct-armT-bpd616-reproduction.txt` | ⚠️ **differs from the 181.348 s headline by 3.0%** — a second run of the same measurement, not a contradiction. **Resolved: the fan-out scale capture is the cited figure; the reproduction is corroboration, and the 3% spread is the honest run-to-run band on this measurement.** |

Both disagreements were between *captures*, not errors of transcription. Neither changes any ranking.

---

## 1. The summary view

### 1.1 Contract gate

CONTRACT dimensions only. **A breach is not a low score — it is a decision for the architect**, reported with the decision it pressures and the magnitude of the evidence.

| contract | T | S | G |
|---|---|---|---|
| **#187 D1 / D1A** — Prometheus `HistogramQuantile` in-bin walk, `ceil(q·N)`, `rank_in_bin` as fraction | **HOLDS** | **HOLDS** — digest-identical | **HOLDS** — same value/audit semantics on every reachable edge case, same rank crossover at bpd ≈ 256 |
| **#187 D2** — precision lever, per-surface tiers | **HOLDS.** Its *memory guidance* (~212 MB at 10⁵ keys) is T-specific | **HOLDS**; guidance does not carry (91 MB Devel / 57 MB RSS; bpd sensitivity ×1.23 vs T's ×5.77) | **HOLDS**; one grid per bpd (57 MB / 19 MB; ×1.36) |
| **#187 D3** — no per-bin sample-count guard | **HOLDS** | **HOLDS** | **HOLDS** — `bin_count=1` returns `upper`, no special-case |
| **#187 D4** — over/underflow counters + `out_of_range_bounded` | **HOLDS as written** — but **dead code in shipped `ltl`**: `counter_update` always extends, so `percentile` never takes its `low`/`high` exits | **HOLDS** — identical, dead alike | **VACUOUS** — any positive double gets an index; counters identically 0; audit constant `none`. **Needs amendment A2/A3** |
| **#187 D5** — per-key seeded partition, doubling, rebin telemetry. *"The auto-resize lifecycle itself is not revisitable."* | **HOLDS** — and its costs are now measured: 100% of 725 pair merges remap both sides; 13 display anchors/24 buckets; sole cause of the R4 breach and of order-dependence | **HOLDS** — verbatim, identical rebin telemetry at all three cardinalities | **VACUOUS** — no seed, extend or rebin. **UNDER REVIEW — architect-level** (§ 7.1) |
| **#187 D7** — `-mdm raw` opt-out | **HOLDS** | **HOLDS** | **HOLDS** — identical block from every arm |
| **#187 D8** — `-V` section, field set **and field order** | **HOLDS** — but 4 of 10 fields discriminate; `counter_memory_bytes` non-deterministic within T itself (2.7% on byte-identical input); merge-driven rebins invisible (C8) | **HOLDS** — byte-identical to real `ltl` (memory masked) at 53/115/616 and `-mdm raw` | **6 fields inert, 7 of 10 un-diffable. Needs amendment A3.** Field-order contract for the replacement lines is **unrecorded** |
| **#187 R2** — bin assignment matches locked boundary computation | **HOLDS** | **HOLDS** | **HOLDS except exact powers of ten** — 1 of 985 values, 38 of 857,480 obs, one index low, value = the closed bin's upper boundary, **zero attribution error**. A convention must be recorded |
| **#187 R4** — accuracy bound, described as **"structural, not empirical"** | **BREACHED after any remap** — 2.1026 bins @depth 15 (48→98 of 1,000 across depths 1→15); p95 itself crosses 1 bin by depth 3; 2.06 bins even at bpd 616; also 1 unmerged key @256 and 1 @616 | **BREACHED — inherits T exactly** | **HOLDS in every scope, tier and merge shape** — 0 breaches in 16,000 depth + 4,000 disjoint + 20 rollup evaluations; max exactly 1.000000 |
| **#189 R5** — determinism | **HOLDS** (fixed-sequence, which is all R5 promises) | **HOLDS** — = T | **HOLDS**, and additionally order-independent |
| **#189 R7** — partition independence: *"a hard requirement, not an option … no global registry of partitions"* | **HOLDS** | **HOLDS**; adopt-by-reference cannot be reproduced by any columnar row — S copies (C7) | **UNRESOLVED.** Grid shared; counts not; merge is an index-wise add touching neither source. Whether a shared *index function* is "a global registry" is settled **nowhere in the corpus** and appears in **no amendment list** (§ 7.2) |
| **#189 R12 / #201** — `partition_rebin` as finalize wrapper | **HOLDS** — it is the remap whose accuracy cost R4 records; `rebins` reset to 0, so merge rebins are invisible | **HOLDS** — finalized cells identical to T in all 90 rows | **NOT USED** — G's merge is an index-wise add; finalize places mass by value |
| **#287 R2.3** — merge fidelity for message-stats | **HOLDS as coded.** R2.3's *prose* is wrong about the code: it says "extend the narrower side"; the shipped code rebins **both** sides into a union geometry | **HOLDS** — S2 built against the shipped mechanism, bit-identical | **HOLDS** — index-wise add is trivially fidelity-preserving |
| **#34 R5** — memory savings never worth fidelity loss | **HOLDS** — no smoothing | **HOLDS** — no smoothing | **HOLDS** — no smoothing. Mass retention 1.000000 and peak X-offset 0 for **every arm on all 90 rows** |

**Two breaches, not one arm's.** T and S breach R4; the correction (**A4**) is *proposed, not applied*, and **is owed to shipped code regardless of which arm is adopted**. G needs amendments A2/A3 and leaves R7 unresolved. No arm passes the gate clean.

### 1.2 Emphasis score — QUALITY dimensions only

**This score takes no decisions. Its only purpose is to direct where findings are presented in more depth.** It is not a ranking of the arms.

**Area weights (one line, with reasoning):** per-message **0.40**, bucket-stats **0.20**, heatmap **0.25**, histogram **0.15** — cardinality (≈286,000 / tens / tens / ≈4 partitions) sets the ordering but is compressed hard toward the corpus's own load-bearing judgements, because raw cardinality share would put per-message at ~0.999 and erase the three surfaces where #34 R5 and #201 place the strictest contracts.

| QUALITY dimension | per-msg (0.40) | bucket (0.20) | heatmap (0.25) | histo (0.15) | T | S | G |
|---|---|---|---|---|---|---|---|
| P2 accuracy, unmerged | H | H | M | M | **0.72** | 0.72 | **0.70** |
| P3 accuracy after merge | H | — | — | — | 0.20 | 0.20 | **0.40** |
| P4 order-independence | M | L | L | L | 0.06 | 0.06 | **0.30** |
| P5 display fidelity | — | L | H | H | 0.20 | 0.20 | **0.22** |
| P6 memory | H | M | L | L | 0.28 | **0.42** | **0.48** |
| P7 fill cost | M | M | M | M | 0.15 | 0.34 | **0.50** |
| P8 percentile cost | H | M | L | L | 0.09 | **0.50** | **0.55** |
| P9 merge / fold cost | H | — | — | — | 0.14 | 0.20 → **0.32** | **0.40** |
| P10 ladder growth | H | M | L | L | 0.08 | **0.50** | **0.52** |
| **weighted total** | | | | | **1.92** | **3.14 → 3.26** | **4.07** |

### What this emphasis misses

- **Display fidelity (P5) is the dimension the corpus rates highest and workload share weights lowest.** #34 R5 states it categorically — "if a candidate reduces memory but smooths the histogram, **the candidate is wrong**". At 0.25+0.15 area weight it contributes least to the total, and the score therefore under-reads the one dimension carrying a categorical prohibition.
- **P1 output parity and P14 re-bless are CONTRACT-adjacent and excluded**, so the score is blind to S's 0.00% T3 and G's 15.88–31.67% blocking re-bless — the largest single practical difference between them.
- **P12 observability and P13 locked-decision impact are excluded**, so G's 3 discriminating `-V` fields lost and its unresolved R7 do not appear.
- **P11 extremes is excluded** as unreachable behind `ltl`'s `> 0` guard on every arm.
- **The inversions are invisible to any scalar.** P2 inverts by resolution, P6 by surface, P5 by data shape — a single cell per dimension necessarily picks one side.

---

## 2. Dominance check

**No arm dominates any other.** Checked pairwise:

- **G over T?** No. T is better on P2 from bpd 115 up on Tomcat (0.0210% vs 0.2385% @616), better on P6 at bucket-stats @616 (2,531,282 B vs 2,714,054), better on P5 aggregate on 7 of 10 DPM display cells, and better on P12 (10 live `-V` fields vs 4) and P14 (0.00% vs 31.67% T3).
- **G over S?** No — same three counterexamples, plus S's 0.00% re-bless.
- **S over T?** No. S is **+42% memory at bucket-stats @616** and **+67% RSS on Tomcat @616**, and its bucket-stats ladder growth (×8.70) is steeper than T's (×6.35).
- **T over anything?** No. T is worst on every cost axis on every surface measured, and breaches R4 after any remap.

The evidence supports **no ordering of the arms**. What it supports is a set of named frictions (§ 6) in which each arm is on the winning side of some and the losing side of others. Any total ordering read off § 1.2 would be an artefact of the weights, not of the measurements.

---

## 3. Dimension-major tables

### T-1 — Dimension × arm (master overview)

`=` identical to today · `+` measurably better · `−` measurably worse · `~` inverts / mixed · `∅` vacuous by construction.

| Dimension | T | S | G | Ranking stable? | Detail |
|---|---|---|---|---|---|
| **P1** output parity | `=` trivially — T *is* the baseline output | `=` digest-identical on every surface (0 differing cells in 90 display rows; identical whole-store MD5) | `−` differs by design: 15.9–31.7% of cells T3 @53 | **stable** | P1-1, P14-1 |
| **P2** accuracy, unmerged | `~` best from bpd 115 up on Tomcat (0.021% vs 0.239%); 1 key breaches bound @256 | `=` T exactly (bit-identical, 10/10 configs) | `~` best at bpd 16 on both files (3.60% vs 6.78%); 100% within 1 bin at every tier | **inverts by resolution** (crossover ≈ 53–115) **and by data shape** | P2-1, P2-2 |
| **P3** accuracy after merge | `−` breaches R4; 2.10 bins @depth 15 | `−` = T | `+` 0 breaches in 20,020 evaluations; max exactly 1.000000 | **stable** | P3-1 |
| **P4** determinism | `−` order-dependent on 52–96% of key groups; spread to 2.00 bins | `−` = T exactly | `+` 0/25 groups, spread exactly 0.0000 | **stable** | P4-1 |
| **P5** display fidelity | `~` wins 10 of 20 aggregate cells; **13 range anchors** across 24 buckets | `=` cell-identical to T, all 90 rows | `~` wins 10 of 20; 1 anchor; 4× better per-bucket median @616 Tomcat | **inverts by data shape** | P5-1, P5-2 |
| **P6** memory | `~` smallest at bucket-stats @616; largest at fan-out (13,616 B/key @616) | `~` 12.7× smaller than T at fan-out; **+42% larger** at bucket-stats @616 | `~` smallest at fan-out (720 B/key); above T on DPM bucket-stats @616 | **inverts by surface** | P6-1, P6-2 |
| **P7** fill cost | `−` 1,471 ns/sample @53 | `+` 0.66–0.70× T | `+` 0.43× T (635 ns/sample) | **stable** | P7-1 |
| **P8** percentile cost | `−` 181.3 s at 286,659 keys @616 | `+` 79.5× faster @616 | `+` fastest (1.73 s @616) | **stable** | P8-1 |
| **P9** merge / fold cost | `−` 18.20 s / 199.52 s fold @53/@616 | `~` dense-view 34.36 s **worse than T**; native S2 3.65 s **5.0× better** | `+` 0.093 s at 51,469-key fold; 56–745× per merge | **stable once S2 is the implementation** | P9-1 |
| **P10** ladder growth | `−` ×10.3 time, ×5.6 memory | `+` ×1.08 time, ×1.008 memory | `+` ×1.07 time, ×1.011 memory | **stable** | P10-1 |
| **P11** extremes | `−` **hangs** on a negative value | `−` = T (hangs) | `~` dies on 0/negatives; accepts 1e-320 / 1e308 that break T | **stable** (all unreachable behind `> 0`) | P11-1 |
| **P12** `-V` observability | `=` trivially — populates all 10 D8 fields | `=` all 10, same values | `−` 6 of 10 inert; 7 of 10 un-diffable | **stable**, but only 4 of 10 discriminate on any arm | P12-1 |
| **P13** locked-decision impact | `~` holds all **except R4**, breached after any remap | `=` holds all listed; diverges only on C7 aliasing | `−` D4/D5/R6 vacuous; R1/R9 replaced; **R7 unresolved** | **stable** | P13-1 |
| **P14** adoption cost | `=` trivially — 0 cells, 0 amendments, 0 call sites | `=` 0.00% T3; 14 `counter_update` sites re-pointed | `−` 15.9–31.7% T3; 1 scenario NOT COVERED | **stable** | P14-1 |

---

### P1-1 — Parity ledger

`T↔G` reads *differs by design* on every row. The column is retained deliberately: omitting it would make this an S-only artefact and would exempt G from the parity question rather than answering it.

| scope | fixture | bpd | compared | T↔S | T↔G |
|---|---|---|---|---|---|
| per-key percentile store | Tomcat 2025-05-05 (4,153 keys) | 53, 616 | whole-store MD5 | **IDENTICAL** `3962d9c2…` / `8bb68875…` | differs by design |
| per-key percentile store | fan-out (51,469 keys) | 53, 616 | fill digest | **IDENTICAL** `c87c9822…` / `a0ac7c4c…` | differs by design |
| per-key percentile store | fan-out full (286,659 keys) | 53, 616 | 5,000-pair merge digest | **IDENTICAL** `93d28ae5…` / `a300ba83…` | differs by design |
| `-V` D8 section | 2025-03-21 (635 keys) | 53, 115, 616 + `-mdm raw` | byte-compare vs real `ltl`, memory masked | **IDENTICAL ×8** | names identical ×4; **6 values inert** |
| display finalize (3 geometries) | DPM + Tomcat | 53, 80, 115, 256, 616 | every display cell, 90 rows | **IDENTICAL — 0 differing cells** | differs by design |
| bucket-stats store | DPM + Tomcat | 16, 32, 53, 115, 616 | per-key canonical + MD5 + accuracy figures | **IDENTICAL, 10/10** | differs by design |
| merge shapes (rollup, disjoint, depth, order) | DPM + fan-out | 53, 616 | digests + error distributions + order counts | **IDENTICAL, 12/12** (`PARITY_OK=1`) | differs by design |
| S2 native merge | A1–A20 + DPM + fan-out | 53, 616 | 155 digests + raw span arrays element-for-element | **IDENTICAL (S2 = S = T)** | differs by design |
| **aliasing probe A21** | synthetic | 53, 616 | store digest | **DIFFERS** — T `c6f0afcb…` vs S/S2 `b782feea…` | differs by design |

A21 is the only T↔S divergence anywhere, and `ltl` does not reach it (F40 — the source counter slot is deleted immediately after the adopt).

---

### P2-1 — Accuracy by resolution (mean error vs exact oracle, per key-shape band)

**S is omitted by rule, not oversight: S = T on every cell.** Bit-identical error figures measured independently in all 10 V7 configurations.

| file | band (N × spread) | bpd 16 T/G | bpd 53 T/G | bpd 115 T/G | bpd 616 T/G | crossover |
|---|---|---|---|---|---|---|
| DPM | N<10 / <0.1dec (2,054) | 1.3219 / **1.0239** | **0.4799** / 0.5207 | 0.2986 / **0.2832** | **0.0710** / 0.0814 | oscillates |
| DPM | N<100 / <1dec (2,120) | 4.3649 / **3.7655** | **1.1983** / 1.3806 | 0.6170 / **0.6151** | 0.1335 / **0.1176** | 16→53, re-crosses 115 |
| DPM | N<100 / ≥1dec (1,338) | 6.0624 / **4.7997** | 1.6294 / **1.6243** | **0.8041** / 0.8651 | 0.1609 / **0.1344** | 53→115, re-crosses 256 |
| DPM | N<1000 / ≥1dec (186) | 6.7845 / **3.5972** | 1.6682 / **1.0591** | **0.7313** / 0.8793 | 0.1373 / **0.1254** | 53→115, re-crosses 256 |
| Tomcat | N<100 / <1dec (594) | 4.5469 / **4.1273** | not measured | **0.3359** / 0.5851 | **0.0673** / 0.1206 | 16→115 |
| Tomcat | N<1000 / <1dec (250) | 8.4607 / **8.2232** | not measured | **0.4984** / 1.1283 | **0.0468** / 0.2110 | 16→115 |
| Tomcat | **N≥1000 / <1dec (132)** | 9.6489 / **9.3206** | **0.9531** / 2.7706 | **0.4478** / 1.2406 | **0.0210** / 0.2385 | 16→53 |
| Tomcat | N≥1000 / ≥1dec (52) | 6.7494 / **6.2913** | not measured | **0.4526** / 0.8812 | **0.0772** / 0.1636 | 16→115 |
| fan-out | N<10 / <0.1dec (**573,026**) | — | **0.0000 / 0.0000 — exact for both** | — | — | nothing to cross |
| fan-out | N<10 / <1dec (184) | — | 0.9372 / **0.8754** | — | — | — |
| fan-out | N<100 / ≥1dec (16) | — | 1.4606 / **1.0149** | — | — | — |

**Margin at each end.** On DPM `N<1000 / ≥1dec` the margin is **3.19 points at bpd 16** and **0.012 points at 616**. The inversion is real; its stakes are ~265× larger at the coarse end. Both arms are sub-1% on every band at bpd 616 on both files.

**Mechanism (F37 — the resolution crossover).** T seeds each key around its own first value (#187 D5), concentrating bins where the key has values — an advantage that *grows* with resolution. G never spends resolution on a seeded range the key does not occupy — which dominates when bins are *scarce*.

**Not fillable:** rungs 32/80/256 on Tomcat; any rung but 53 at fan-out cardinality.

---

### P2-2 — Bound conformance (`binning_max` ≤ `10^(1/bpd) − 1`)

**S omitted by rule — S = T on every row.**

| bpd | bound | scope | T max | T within 1 bin | G max | G within 1 bin | verdict |
|---|---|---|---|---|---|---|---|
| 53 | 4.44% | key (328 keys, N≥100) | 3.44–4.44% | 100% | 4.16–4.44% | 100% | both PASS |
| 115 | 2.02% | key | 1.56–2.01% | 100% | 1.81–2.02% | 100% | both PASS |
| **256** | 0.90% | key | **0.93%** | 99.7% | **0.90%** | **100%** | **T FAIL (1 key)** · G PASS |
| 616 | 0.37% | key | 0.33–0.37% | 100% | 0.36–0.37% | 100% | both PASS |
| 53 | 4.44% | small (2,517 keys) | ≤ bound | 100.00% | ≤ bound | 100.00% | both PASS |
| 256 | 0.90% | small | 1.31% (P50) | 99.96% | 0.90% | **100.00%** | T marginal FAIL · G PASS |
| 53 | 4.44% | **pair** (1,258 merges) | **6.03%** / 1.35 bins | 96.4–96.6% | 4.44% / 1.00 | **100%** | **T FAIL** · G PASS |
| 115 | 2.02% | pair | **2.86%** / 1.41 | 97.8–99.1% | 2.02% / 1.00 | **100%** | **T FAIL** · G PASS |
| 256 | 0.90% | pair | **1.34%** / 1.48 | 93.2–99.5% | 0.90% / 1.00 | **100%** | **T FAIL** · G PASS |
| 616 | 0.37% | pair | **0.55%** / 1.46 | 99.4–99.6% | 0.37% / 1.00 | **100%** | **T FAIL** · G PASS |
| 53 | 4.44% | **fold** (7 merges, 314 groups) | **7.27%** / 1.64 | 90.8–99.4% | 4.44% / 1.00 | **100%** | **T FAIL** · G PASS |
| 115 | 2.02% | fold | **2.75%** / 1.36 | 93.9–99.4% | 2.02% / 1.00 | **100%** | **T FAIL** · G PASS |
| 256 | 0.90% | fold | **1.87%** / **2.06** | **78.0**–97.1% | 0.90% / 1.00 | **100%** | **T FAIL** · G PASS |
| 616 | 0.37% | fold | **0.66%** / 1.75 | 93.0–98.4% | 0.37% / 1.00 | **100%** | **T FAIL** · G PASS |
| 16–616 | — | bucket-stats (3,005 comparisons) | 4 outside, all integer-quantisation | 99.69–100% | 0 outside | **100%** | both effectively PASS |

G's every apparent ">1" is exactly `1.000000` with `_gt1eps = 0` — the bound is attained, never exceeded. This is the direct evidence pressuring **#187 R4's "structural, not empirical"**: as written the bound is a CONTRACT that today's shipped code does not meet after any remap.

---

### P3-1 — Merge-depth ladder (200 groups × 16 keys, bpd 53, DPM; 1,000 evaluations per depth)

**S = T on every cell** (digest-identical on all four merge shapes at both bpd on both fixtures, `PARITY_OK=1`). The S column is printed anyway so the arm is not exempted from the question.

| depth | T max err (bins) | T cells >1 bin (of 1000) | S | G max err | G cells >1 bin |
|---|---|---|---|---|---|
| 1 | 1.2502 | 48 | = T (1.2502 / 48) | **1.000000** | **0** |
| 3 | 1.4046 | 66 | = T (1.4046 / 66) | **1.000000** | **0** |
| 7 | 1.5125 | 78 | = T (1.5125 / 78) | **1.000000** | **0** |
| 15 | **2.1026** | **98** | = T (2.1026 / 98) | **1.000000** | **0** |

Monotone in all four measured cells; **G is 0 breaches in 16,000 depth evaluations**:

| bpd / fixture | T depth 1 → 3 → 7 → 15 (max bins) | T breaches 1 → 15 | G, all depths |
|---|---|---|---|
| 53 / fan-out | 0.9914 → 1.3331 → 1.4234 → 1.3715 | 0 → 14 | max 1.000000, 0 |
| 53 / DPM | 1.2502 → 1.4046 → 1.5125 → **2.1026** | 48 → 98 | max 1.000000, 0 |
| 616 / fan-out | 0.4925 → 1.1296 → 1.2855 → 1.3069 | 0 → 6 | max 1.000000, 0 |
| 616 / DPM | 1.4860 → 1.7021 → 1.6769 → **2.0637** | 46 → 47 | max 1.000000, 0 |

**Raising bpd does not rescue T** (2.06 bins at 616): the error is proportional to bin *count*, not bin *width*. On DPM @53 T's **p95 itself** crosses one bin by depth 3 (1.0660) and reaches 1.2259 at depth 15 — no longer a tail case. **Disjointness is not the mechanism**: a single maximally disjoint merge (gaps to 4.84 decades) stays within one bin on 3,999 of 4,000 evaluations (worst 1.0008). **Depth is.**

Depth was measured to 15 only; a real `-g` fold goes far deeper, so the asymptote is **not measured**.

---

### P4-1 — Order-independence

| fixture | bpd | shape | T differing | T max spread | S | G |
|---|---|---|---|---|---|---|
| Tomcat 05-05 | 53 | insertion order, 200 keys | 105/200 (52.5%) | 0.873 | = T | **0/200 · 0.000** |
| Tomcat 05-05 | 616 | insertion order | 105/200 | 0.985 | = T | **0/200 · 0.000** |
| Tomcat 05-07 | 53 | insertion order | 105/200 | not measured | = T | **0/200** |
| DPM | 53 | insertion order | 187/200 (93.5%) | not measured | = T | **0/200** |
| Tomcat 05-05 | 53 | pairwise commutativity, 200 pairs | 2/200 — **`rebins` telemetry field only**; bins/boundaries/percentiles identical | 0 | = T | **0/200** |
| Tomcat 05-05 | 616 | pairwise commutativity | 2/200 (same field) | 0 | = T | **0/200** |
| fan-out | 53 | 8-key permutation into neutral target (25 groups × 4 orders) | **24/25 (96.0%)** | **2.0006** | = T | **0/25 · 0.0000** |
| fan-out | 616 | 8-key permutation | 23/25 (92.0%) | 1.0003 | = T | **0/25 · 0.0000** |
| DPM | 53 | 8-key permutation | 17/25 (68.0%) | **2.0003** | = T | **0/25 · 0.0000** |
| DPM | 616 | 8-key permutation | 21/25 (84.0%) | 1.0002 | = T | **0/25 · 0.0000** |

G's canonical strings are **byte-identical** across all orderings, independently reproduced: T and S reach 3–4 distinct canonical states from the same 8-key set for 5 of 6 groups; G reaches exactly 1 for all 6. Only 4 of 8! = 40,320 orderings were sampled, so T's counts are **lower bounds**.

**Scope caveat (C2 — the unclaimed quality).** Insertion-order independence is QUALITY, **explicitly not claimed** by #189 R5, which promises only fixed-sequence determinism — held by all three arms. Scoring this as a contract would mis-score T as failing something never required.

---

### P5-1 — Display fidelity, aggregate (total absolute deviation vs the exact display)

**Verified on all 90 rows:** **D2** no cross-bin mass splitting — mass retention `1.000000` for **every arm on every row**; **D4** peak retention exact and peak X-offset `0` for every arm on every row (two exceptions, both T/S, both coarse: DPM 0.999928 @53 and 0.999068 @80; G 1.000000 on both); **D8** render-stage duplication preserved, not "fixed" (shipped display sum 1,647,292 vs true raw 575,800, ~2.86× — deliberately untouched in all three arms).

| file | geometry | bpd | T/S dev % | T/S max cell | G dev % | G max cell | winner |
|---|---|---|---|---|---|---|---|
| DPM | heatmap | 53 | **1.3779** | **332** | 1.6352 | 250 | T/S |
| DPM | heatmap | 80 | **33.1406** | 19,926 | 33.2432 | 19,926 | T/S (boundary straddle) |
| DPM | heatmap | 115 | **0.3958** | **57** | 1.0358 | 174 | T/S |
| DPM | heatmap | 256 | **0.2883** | **94** | 0.3257 | 132 | T/S |
| DPM | heatmap | 616 | 0.2948 | 143 | **0.2915** | **132** | G (0.0033 pt) |
| DPM | histogram | 53 | **0.9414** | **158** | 2.9398 | 703 | T/S |
| DPM | histogram | 80 | 1.8127 | 484 | **1.4365** | **480** | G |
| DPM | histogram | 115 | **0.7720** | **208** | 1.3909 | 480 | T/S |
| DPM | histogram | 256 | **0.1889** | **34** | 0.1922 | 97 | T/S (0.0033 pt) |
| DPM | histogram | 616 | **0.0700** | **16** | 0.0961 | 34 | T/S |
| Tomcat | heatmap | 53 | 5.2008 | 5,875 | **3.1278** | **5,180** | G |
| Tomcat | heatmap | 80 | 3.5443 | 4,553 | **1.9788** | **1,838** | G |
| Tomcat | heatmap | 115 | 1.5033 | 2,229 | **0.0618** | **176** | **G (24×)** |
| Tomcat | heatmap | 256 | 0.7676 | 1,583 | **0.3856** | **674** | G |
| Tomcat | heatmap | 616 | **0.0337** | **89** | 0.0806 | 211 | T/S |
| Tomcat | histogram | 53 | **9.7701** | 25,155 | 9.9785 | 25,155 | T/S (0.21 pt) |
| Tomcat | histogram | 80 | 7.6131 | 20,837 | **1.1080** | **2,045** | **G (6.9×)** |
| Tomcat | histogram | 115 | 8.6770 | 24,382 | **0.4988** | **925** | **G (17×)** |
| Tomcat | histogram | 256 | 0.0302 | 83 | **0.0115** | **33** | G |
| Tomcat | histogram | 616 | 0.0740 | 126 | **0.0003** | **1** | **G (247×)** |

**Neither arm dominates:** T/S wins 10 of 20, G wins 10. By file: T/S ahead on 7 of 10 DPM cells; G ahead on 7 of 10 Tomcat cells.

The 33% cells at DPM bpd 80 are a **boundary straddle both arms share**: the source bin holding the value `2` (19,926 obs, 16.2% of the file) has its geometric midpoint at 2.013, just across a display-cell boundary, so its whole mass lands one cell over. **T and G do this identically** (both cell 3 @80, both cell 2 @616). The deviation curve is consequently non-monotonic in resolution.

---

### P5-2 — Per-time-bucket keying (#201 Dimension B — per-bucket range anchoring, "unrecoverable at render time")

**`distinct range anchors` is the mechanism column and is mandatory**: it measures #187 D5's stated benefit E5 ("tighter per-key resolution") on the surface where #34 R5 calls the same anchoring unrecoverable. It is Inversion 1 in one column.

| file | bpd | arm | median % | p95 % | max % | mean % | **distinct anchors** |
|---|---|---|---|---|---|---|---|
| Tomcat (24 buckets) | 616 | T = S | 0.2667 | 0.4333 | 0.4583 | 0.2234 | **13 of 24** |
| Tomcat | 616 | **G** | **0.0667** | **0.1750** | **0.2333** | **0.0806** | **1** |
| Tomcat | 53 | T = S | **3.4417** | 6.2417 | 7.2250 | 3.9612 | **13 of 24** |
| Tomcat | 53 | G | 3.5750 | **5.2333** | **5.2750** | **3.1315** | **1** |
| DPM (25 buckets) | 616 | T = S | 0.2800 | 0.6000 | 0.6800 | 0.3049 | **13 of 25** |
| DPM | 616 | **G** | 0.2800 | 0.6000 | 0.6800 | **0.2905** | **1** |
| DPM | 80 | T = S | **1.4000** | **36.1200** | **38.4560** | **8.9990** | **13 of 25** |
| DPM | 80 | G | 33.3200 | 39.6000 | 61.0800 | 33.5421 | **1** |

**At the resolution these surfaces run at (616):** on Tomcat the global anchor is **4× better on the median, ~2× on the max**; on DPM the arms are **statistically identical** (median 0.2800% each — a tie, not a win). The DPM bpd 80 row is the boundary straddle of P5-1, not an anchoring effect.

T and S are identical in every cell — the anchoring is arithmetic S reproduces verbatim, so the 13 anchors are as much S's property as T's.

**Not measured:** buckets here are contiguous fixed-line-count runs, not `-b` wall-clock buckets; bucket-N skew is untested.

---

### P6-1 — Memory, unbounded surface (fan-out, 286,659 keys)

**One arm per process on every row** (F52/F53). See § 0.5 for the projection-failure rule this enforces.

| bpd | arm | `Devel::Size` B/key | RSS B/key | store MB (Devel) | store MB (RSS) | **RSS/Devel gap** |
|---|---|---|---|---|---|---|
| 53 | T | 2,367 | 2,899 | 647.04 | 792.52 | **+22.5%** |
| 53 | S | 1,067 | 1,395 | 291.67 | 381.38 | **+30.8%** |
| 53 | **G** | **712** | **959** | **194.63** | **262.30** | **+34.8%** |
| 616 | T | 13,688 | 16,211 | 3,742.09 | 4,432.72 | **+18.4%** |
| 616 | S | 1,073 | 1,400 | 293.29 | 382.81 | **+30.5%** |
| 616 | **G** | **718** | **965** | **196.26** | **263.94** | **+34.5%** |

**The gap column cuts against the compact arms** (F54). RSS exceeds `Devel::Size` on every arm, surface and bpd by **12.6–40.6%**, and the gap *fraction is largest where the store is smallest*. Even on RSS the ranking is unchanged: at bpd 616 T is **4,432.7 MB** against S 382.8 and G 263.9 — **11.6× and 16.8×**.

*(Scale-run capture, cited separately and never mixed into these ratios: T 13,616 B/key / 3,722.4 MB @616 — `message-stats-scale/fanout.txt`.)*

Prior-scale reference (51,469 keys), retained because it is where the RSS sign inverted: Devel B/key T 2,381 / S 955 / G 600 @53; T 13,730 / S 1,173 / G 817 @616. RSS *deltas* there read **below** `Devel::Size` for S and G because those stores fit inside arena slack — the measurement F52 rules out as a basis for any claim.

---

### P6-2 — Memory, bounded surface (62 DPM buckets / 29 Tomcat buckets) — **the inversion**

**Mechanism, not caveat.** Span-only trades a dense array for **per-row bookkeeping plus an occupied span**. It wins when partitions are *numerous and sparsely occupied* (fan-out: occupied span p50 = **1**), and loses when they are *few and densely occupied* (a bucket partition with ~2,000 obs over a wide range occupies most of its span). P6-1 and P6-2 are two tables with different row counts so that nothing averages across them.

| file (rows) | bpd | T RSS kB / Devel B | S RSS kB / Devel B | G RSS kB / Devel B | S vs T (Devel) |
|---|---|---|---|---|---|
| DPM (62) | 16 | 208 / 194,786 | 224 / **168,348** | **128 / 136,422** | **0.86×** |
| DPM | 53 | **416** / **398,378** | 512 / 412,692 | **352 / 341,054** | 1.04× |
| DPM | 115 | **688** / **674,890** | 912 / 791,212 | **672 / 645,686** | 1.17× |
| DPM | 616 | **3,120** / **2,531,282** | 4,256 / 3,588,988 | 2,912 / 2,714,054 | **1.42× — S +42%** |
| Tomcat (29) | 16 | 112 / 82,909 | 80 / **68,335** | **64 / 54,209** | **0.82×** |
| Tomcat | 53 | 240 / **167,093** | 224 / 168,247 | **176 / 141,193** | 1.01× |
| Tomcat | 115 | **288** / **285,805** | 480 / 329,503 | 336 / 271,649 | 1.15× |
| Tomcat | 616 | **1,200** / **1,030,629** | 2,000 / 1,504,815 | 1,264 / 1,143,857 | **1.46× — +67% RSS** |

**S is worse than T at bpd ≥ 115 on both fixtures.** G is smallest or joint-smallest in **6 of 8** cells but is *above* T at DPM 616 (2,714,054 vs 2,531,282) and Tomcat 616 RSS (1,264 vs 1,200 kB).

Absolute magnitudes are **≤ 4 MB throughout** and RSS deltas are 16 kB-quantised — differences under ~50 kB should not be over-read. Memory is weighted **Low and explicitly subordinated** on the display area (#201: ~1.75 MB streaming overhead, "negligible"), so the inversion's practical bite is on bucket-stats.

---

### P7-1 — Fill / build cost

| surface | fixture (scale) | bpd | arm | median | [min, max] | per-unit | vs T |
|---|---|---|---|---|---|---|---|
| msg-stats | fan-out (339,832 samples / 51,469 keys) | 53 | T | 0.500 s | [0.481, 0.518] | 1,471 ns/sample | 1.00× |
| | | 53 | S | 0.349 | [0.335, 0.364] | 1,026 | **0.70×** |
| | | 53 | **G** | **0.216** | [0.214, 0.223] | **635** | **0.43×** |
| | | 616 | T | 0.552 | [0.529, 0.572] | 1,623 | 1.00× |
| | | 616 | S | 0.362 | [0.334, 0.394] | 1,065 | **0.66×** |
| | | 616 | **G** | **0.210** | [0.210, 0.212] | **619** | **0.38×** |
| msg-stats | fan-out full (288,025 samples / **286,659 keys**) | 53 | T | 1.518 | [1.401, 1.628] | 5,270 | 1.00× |
| | | 53 | S | 1.233 | [1.220, 1.243] | 4,281 | **0.81×** |
| | | 53 | **G** | **0.697** | [0.693, 0.702] | **2,420** | **0.46×** |
| | | 616 | T | 2.966 | [2.899, 3.024] | 10,298 | 1.00× |
| | | 616 | S | 1.294 | [1.286, 1.307] | 4,493 | **0.44×** |
| | | 616 | **G** | **0.738** | [0.731, 0.752] | **2,562** | **0.25×** |
| bucket-stats | DPM (122,798 / 62) | 53 | T | 0.1120 | [0.1118, 0.1122] | 912 | 1.00× |
| | | 53 | S | 0.0779 | [0.0778, 0.0790] | 634 | **0.70×** |
| | | 53 | **G** | **0.0544** | [0.0542, 0.0548] | **443** | **0.49×** |
| | | 616 | T | 0.1265 | [0.1253, 0.1277] | 1,030 | 1.00× |
| | | 616 | S | 0.0999 | [0.0995, 0.1002] | 813 | 0.79× |
| | | 616 | **G** | **0.0562** | [0.0558, 0.0562] | **458** | **0.44×** |
| bucket-stats | Tomcat (575,800 / 29) | 53 | T | 0.5331 | [0.5319, 0.5336] | 926 | 1.00× |
| | | 53 | S | 0.3646 | [0.3641, 0.3658] | 633 | 0.68× |
| | | 53 | **G** | **0.2592** | [0.2588, 0.2595] | **450** | **0.49×** |
| | | 616 | T | 0.5458 | [0.5442, 0.5473] | 948 | 1.00× |
| | | 616 | S | 0.3733 | [0.3732, 0.3735] | 648 | 0.68× |
| | | 616 | **G** | **0.2621** | [0.2613, 0.2626] | **455** | **0.48×** |

**Ranking stable: G < S < T on every row.** Build is flat in bpd for all arms on bucket-stats; at fan-out T grows ×1.95 (1.518 → 2.966) while S grows ×1.05 and G ×1.06.

**NOT FILLABLE:** real-`ltl` end-to-end per-line cost per arm — no `ltl` build carries S or G.

---

### P8-1 — Percentile evaluation cost

| surface | fixture (scale) | bpd | arm | median | [min, max] | per-unit | vs T |
|---|---|---|---|---|---|---|---|
| msg-stats | fan-out (51,469 keys; 360,283 evals) | 53 | T | 7.470 s | — | 20.73 µs/eval | 1.00× |
| | | 53 | S | 0.952 | — | 2.64 | **7.8×** |
| | | 53 | **G** | **0.787** | — | **2.19** | **9.5×** |
| | | 616 | T | 75.190 | — | 208.70 | 1.00× |
| | | 616 | S | 1.271 | — | 3.53 | **59×** |
| | | 616 | **G** | **1.024** | — | **2.84** | **73×** |
| msg-stats | fan-out full (286,659 keys × 3q = 859,977 evals) | 53 | T | 17.634 | [17.616, 17.640] | 20.51 | 1.00× |
| | | 53 | S | 2.112 | [2.111, 2.118] | 2.46 | **8.4×** |
| | | 53 | **G** | **1.616** | [1.609, 1.617] | **1.88** | **10.9×** |
| | | 616 | T | **181.348** | [181.257, 181.921] | 210.9 | 1.00× |
| | | 616 | S | 2.281 | [2.260, 2.287] | 2.65 | **79.5×** |
| | | 616 | **G** | **1.731** | [1.697, 1.733] | **2.01** | **104.8×** |
| bucket-stats | DPM (62 × 11q) | 53 | T | 0.02349 | [0.02348, 0.02358] | 34.4 µs/bucket·q | 1.00× |
| | | 53 | S | 0.01239 | [0.01236, 0.01252] | 18.2 | 1.90× |
| | | 53 | **G** | **0.01143** | [0.01125, 0.01144] | **16.8** | **2.05×** |
| | | 616 | T | 0.28252 | [0.28159, 0.28534] | 414 | 1.00× |
| | | 616 | S | 0.12720 | [0.12690, 0.12729] | 187 | 2.22× |
| | | 616 | **G** | **0.10931** | [0.10923, 0.11000] | **160** | **2.58×** |
| bucket-stats | Tomcat (29 × 11q) | 616 | T | 0.11126 | [0.11095, 0.11178] | 349 | 1.00× |
| | | 616 | S | 0.04463 | [0.04454, 0.04499] | 140 | 2.49× |
| | | 616 | **G** | **0.03939** | [0.03939, 0.03941] | **123** | **2.82×** |
| `-V` + audit + render | 2025-03-21 (635 keys, 12q) | 53 | T | 0.1805 | [0.1803, 0.1846] | — | 1.00× |
| | | 53 | S | 0.0225 | [0.0220, 0.0226] | — | **8.0×** |
| | | 53 | **G** | **0.0190** | [0.0186, 0.0190] | — | **9.5×** |
| | | 616 | T | 1.9239 | [1.9119, 1.9288] | — | 1.00× |
| | | 616 | S | 0.0826 | [0.0817, 0.0835] | — | 23.3× |
| | | 616 | **G** | **0.0694** | [0.0690, 0.0697] | — | **27.7×** |

**Mechanism, measured directly:** `percentile()` walks all `bin_count` bins per quantile regardless of occupancy. At DPM bucket-stats bpd 616 T's mean allocated `bin_count` is 4,569.4 against 257.7 mean occupied bins — **occupancy 5.6%**, so T walks ~18× more bins than are occupied. T's cost is 78 ns (@53) / 68 ns (@616) per `bin_count` slot.

**Ranking stable: G < S << T on every row.** Only the magnitude varies — 1.9–2.8× on the bounded surface, 8.4–104.8× at fan-out. *(Run-to-run band on the 181.348 s figure: an independent reproduction read 175.97 s, a 3.0% spread — § 0.7 #13.)*

---

### P9-1 — Merge and `-g` fold cost

S rows carry two lines: `S` = dense-view harness (V2/V5/V8), `S2` = native span merge, bit-identical to it.

| surface | fixture (scale) | bpd | arm | median | [min, max] | per-unit | vs T |
|---|---|---|---|---|---|---|---|
| pair merges | fan-out, 725 pairs (**fill-subtracted**) | 53 | T | — | — | 89.17 µs/merge | 1.00× |
| | | 53 | S (dense) | — | — | 121.07 | **0.74× (slower)** |
| | | 53 | **G** | — | — | **5.81** | **15.3×** |
| | | 616 | T | — | — | 753.75 | 1.00× |
| | | 616 | S (dense) | — | — | 1,047.15 | 0.72× (slower) |
| | | 616 | **G** | — | — | **29.23** | **25.8×** |
| pair merges | fan-out full, 5,000 pairs (**clean**) | 53 | T | 0.3590 s | [0.3378, 0.3706] | 71.80 | 1.00× |
| | | 53 | S (dense) | 0.4590 | [0.4542, 0.4597] | 91.80 | 0.78× (slower) |
| | | 53 | **S2** | **0.0727** | [0.0709, 0.0732] | **14.55** | **4.9×** |
| | | 616 | T | 3.5195 | [3.4746, 3.5352] | 703.90 | 1.00× |
| | | 616 | S (dense) | 4.5105 | [4.4060, 4.5600] | 902.10 | 0.78× (slower) |
| | | 616 | **S2** | **0.2682** | [0.2647, 0.2752] | **53.64** | **13.1×** |
| `-g` fold | fan-out, 51,468 merges | 53 | T | 3.280 | — | 63.74 | 1.00× |
| | | 53 | S (dense) | 5.872 | — | 114.10 | 0.56× (slower) |
| | | 53 | **G** | **0.0927** | — | **1.80** | **35.4×** |
| | | 616 | T | 33.222 | — | 645.49 | 1.00× |
| | | 616 | S (dense) | 60.475 | — | 1,175.01 | 0.55× (slower) |
| | | 616 | **G** | **0.1166** | — | **2.27** | **285×** |
| `-g` fold | fan-out full, 286,658 merges (**fill-subtracted**) | 53 | T | 18.2006 | [18.1471, 18.2060] | 63.49 | 1.00× |
| | | 53 | S (dense) | 34.3621 | [34.2508, 34.4488] | 119.87 | 0.53× (slower) |
| | | 53 | **S2** | **3.6454** | [3.6336, 3.6642] | **12.72** | **5.0×** |
| | | 616 | T | 199.5215 | [197.9879, 201.0986] | 696.03 | 1.00× |
| | | 616 | S (dense) | 414.1805 | [410.9016, 414.7124] | 1,444.86 | 0.48× (slower) |
| | | 616 | **S2** | **16.1192** | [16.0283, 16.3002] | **56.23** | **12.4×** |
| rollup (2,000 → 1) | fan-out | 53 | T | 0.1116 | [0.1115, 0.1116] | 53.8 | 1.00× |
| | | 53 | S | 0.1926 | [0.1924, 0.1930] | 93.7 | 0.58× (slower) |
| | | 53 | **G** | **0.00197** | [0.00197, 0.00198] | **0.96** | **56×** |
| | | 616 | T | 1.1958 | [1.1725, 1.2172] | 589.7 | 1.00× |
| | | 616 | S | 2.0123 | [1.9556, 2.0210] | 983.9 | 0.59× (slower) |
| | | 616 | **G** | **0.00255** | [0.00254, 0.00255] | **1.24** | **475×** |
| disjoint pairs (200) | DPM | 53 | T | — | — | 89.2 | 1.00× |
| | | 53 | S | — | — | 124.2 | 0.72× (slower) |
| | | 53 | **G** | — | — | **2.76** | **32×** |
| | | 616 | T | — | — | 893.8 | 1.00× |
| | | 616 | S | — | — | 1,248.4 | 0.72× (slower) |
| | | 616 | **G** | — | — | **15.14** | **59×** |

**Scaling exponent, 53 → 616 on the 286,658-merge fold — the structural result, not the constant: T ×10.96 · S ×12.05 · S2 ×4.42.** T and S track `bin_count` (544 → 6,324, ×11.6) because both walk the full partition width; S2 tracks the source spans, overwhelmingly single-bin in a fold. G's fold cost is bounded by the source span too: ×1.26.

**S2 memory is NOT FILLABLE.** S2 stores exactly what S stores, verified element-for-element, but neither `Devel::Size` nor RSS was measured and the `_remap_span` transient buffer is unquantified. P6 carries S; S2's memory is inherited-by-argument, not measured.

**Caveat on the two pair-merge blocks:** fill-subtracted V2 figures and the clean measurement are on **different fixtures as well as different methods** — not a like-for-like pair.

---

### P10-1 — Growth across the ladder (bpd 53 → 616, fan-out, 286,659 keys)

The smallest table here and the most decision-relevant: the locked objective is what the container does to the cardinality constraint, and **the constraint is the multiplier**.

| arm | pct time @53 | @616 | × | memory @53 | @616 | × | fold × |
|---|---|---|---|---|---|---|---|
| **T** | 17.634 s | **181.348 s** | **×10.29** | 662.3 MB | **3,722.4 MB** | **×5.62** | **×10.96** |
| **S** | 2.112 | 2.281 | **×1.08** | 291.7 | 293.9 | **×1.008** | ×12.05 (dense) → **×4.42** (S2) |
| **G** | 1.616 | 1.731 | **×1.07** | 194.7 | 196.9 | **×1.011** | **×1.26** (51,469-key fold) |

Corroborating memory growth at 51,469 keys (`Devel::Size`): T ×5.77 · S ×1.23 · G ×1.36. On the 4,153-key Tomcat surface: T 9.28 → 56.72 MB (×6.11), S 3.83 → 8.38 (×2.19), G 2.37 → 6.92 (×2.92).

**Mechanism:** T's dense array is sized by the *partition*, not the *data* — a single-sample key at the seed centre allocates 133 slots @53 and 1,540 @616, all NULL but one. Occupied span p50 stays **1** at both resolutions.

**Scope statement, verbatim from the evidence:** this is evidence about what the per-message row *could* afford. It is **not** a proposal to change `%TIER_BPD`, which is locked, and the resolution tiers are out of scope by the architect's 2026-08-25 ruling.

---

### P11-1 — Extremes and invalid inputs

**`reachable from ltl?` is essential** — without it the table over-weights differences that cannot occur. Every `ltl` `counter_update` call site is gated `> 0` (four counter + eight histogram sites), so the whole `v ≤ 0` block is unreachable on **every** arm.

| input | T | S | G | reachable from ltl? |
|---|---|---|---|---|
| `0` (fresh key) | dies `Illegal division by zero` after 130 doublings | = T | dies `Can't take log of 0` | **No** |
| `0` (existing partition) | dies | = T | dies | **No** |
| `−5` (fresh key) | **HANGS — unbounded loop, 5 s alarm fired** | = T (hangs) | dies `Can't take log of -5` | **No** |
| `−5` (existing partition) | **HANGS** | = T | dies | **No** |
| `1e-320` | index accepted, then `bin_count = Inf` | = T (+ `Non-finite repeat count` warning) | index **−16,961**, correct | **No** |
| `1e308` | max = `Inf`, `p50 = NaN` | = T | index **16,324**, correct | **No** |
| all-overflow (under synthetic `max_rebins=0`) | returns 316.23, audit `high` — 3.5 decades below true | = T | span 318, returns **1,000,000 exactly**, audit `none`, rel err **0** | **No** — the cap is a prototype hook; uncapped T answers within one bin |
| all-underflow (capped) | returns 0.00316, audit `low` | = T | 1.0087e-6, audit `none` (0.87%, within one bin) | **No** |
| 18-decade key `{1e-6, 1e-3, 1, 1e12}` | 3 rebins; 0.96 bins @53, **1.38 @616** (bound breached) | = T | span 954 / 11,088; every quantile ≤ 1.00 bins | **Yes in principle** |
| 12-decade key, 3 insertion orders (1,013 samples) | 662–794 bins; q0.5 = **98.85 / 100.10 / 100.01 by order** | = T | q0.5 = **100.189 in every order** | **Yes** |
| `lower = upper` (F2 — an arm may not *declare* it unreachable) | unreachable through `partition_new`; #189 tested on a synthetic partition | = T | **impossible by construction** — verified for i ∈ [−2000, 2000] | **No** on both — but neither arm declares it away |
| all-same value × N (F1 degenerate) | one occupied bin; max rel err 2.196% (0.49 bins) @53 | = T | span 1; 4.029% (0.91 bins) @53 | **Yes** — common |
| single observation (F1 degenerate) | returns `upper`: +2.196% @53, +0.0000% @616 | = T | +4.294% @53, +0.029% @616 | **Yes — dominant at fan-out** (573,026 of 573,318 cells exact for both) |
| `bin_count = 1`, zero-count partition (F1) | returns `upper` / `(undef,'none')` | = T | same | **Yes** |

**E1 (out-of-range as safety net) goes vacuous under G, not violated** — proved structurally: `Store::G::percentile` ends in `die "unreachable"`. **The same fields are already dead code in shipped `ltl` on T and S** (F50 — the inert-field finding): every captured `ltl` run emits twelve `none`.

**E10 — the `v > 0` guard is load-bearing for every representation**, and T's failure mode is the worse one: an unbounded loop rather than a die.

---

### P12-1 — `-V histogram-bin-counters` field survival (Decision 8)

**Field order (J1/A3).** D8's locked contract covers field *order* as well as names, and the #426 audit is **silent on it**. Order is preserved under S by construction (byte-identical sections). Under G the replacement lines have **no recorded order contract** — an unresolved gap.

| field | T | S | G | discriminating in shipped `ltl`? |
|---|---|---|---|---|
| `path` | yes | yes | yes | no — consumer-level constant |
| `partition_keying` | yes | yes | yes | no — constant, never read from the store |
| `partition_count` | yes | yes | yes (same meaning) | **YES** — exact for T and S on all three fixtures |
| `total_rebin_events` | yes | yes | **INERT** | **YES** — exact for T and S (15 / 116 / 2) |
| `max_partition_bins` | yes | yes | **INERT** (→ `span_max`) | **YES** — exact for T and S (397 on all three) |
| `partitions_with_overflow_count` | yes | yes | **INERT** — structurally 0 | no — constant `0` in every shipped run |
| `partitions_with_underflow_count` | yes | yes | **INERT** — structurally 0 | no — constant `0` in every shipped run |
| `rebins_per_partition` | yes | yes | **INERT** (→ `span_p50/p95/p99/max`) | **YES** — exact for T and S |
| `counter_memory_bytes` | populable | populable (2.4–4.8× smaller) | populable | **no — un-assertable on ANY arm**: three identical `ltl` invocations gave 5,988,852 / 6,149,748 / 5,988,852 (**2.7% on byte-identical input**, per-process hash seed) |
| `percentiles_emitted` | yes | yes | yes | no — a **static** hardcoded table; `ltl` printed twelve even in runs computing four |
| `out_of_range_bounded` | populable | populable | **INERT** — constant `none` | no — constant `none` in every shipped run captured |
| **merge-rebin telemetry (C8)** | **undercounts** — `partition_rebin` returns `rebins => 0`, so merge rebins are invisible even on T (`fold_rebins=0` on an accumulator re-geometried 265 → 531 bins) | = T (same defect) | N/A | no — undercounts on **every consolidated run**; correction **PROPOSED, NOT APPLIED** |

**Totals with the discrimination column applied.** A naive count reads "S 10/10, G 4/10". The honest count: **only 4 of the 10 locked fields discriminate as parity assertions in shipped `ltl` on any arm**, and **all four are exact for S**. Under G all four go inert, so **a plain `-V` diff is a valid gate for S and is not one for G**. Six fields go inert under G; adding `counter_memory_bytes` (inert as an *assertion* on all three arms) brings G's un-diffable total to **7 of 10** — but the count of genuinely *discriminating* fields lost is **3**.

**Two aggregation scopes, reproduced:** `ltl` aggregates partition-shape fields over the whole store but `out_of_range_bounded` over **only the display-slot keys**. Same store: 20 display keys → twelve `none`; 2,514 store keys → twelve non-`none` codes. A replacement validated by walking the store would report a scope artefact as a defect. T and S agree at both scopes.

---

### P13-1 — Locked-decision impact

**The T column is mandatory and is the symmetry payoff of this document.** The source table had S and G columns and no T column — which converted the question from "how does each candidate stand against the locked contract" into "how do the candidates differ from today". T's honest **R4** cell is what that omission hid.

| decision | what it locks | T | S | G | amendment |
|---|---|---|---|---|---|
| **F1** | bpd is the analyst's query-time lever | holds | holds | holds | none |
| **D1 / D1A** | Prometheus in-bin walk, `ceil(q·N)`, `rank_in_bin` as fraction | holds | holds — digest-identical | holds — same semantics, same envelope, same rank crossover at bpd ≈ 256 | none |
| **D1 guidance** `lower = upper` | a case the walk must handle | **vacuous** — `partition_new` cannot produce it | vacuous | vacuous — impossible by construction | none (F2 forbids *declaring* it unreachable) |
| **D2** | precision lever; per-surface tiers | holds. Memory guidance is **T-specific** (~212 MB at 10⁵) | holds; guidance does not carry (91 MB / 57 MB; ×1.23) | holds; one grid per bpd (57 MB / 19 MB; ×1.36) | **D2's memory guidance needs a span-based replacement under S or G** |
| **D3** | no per-bin sample-count guard | holds | holds | holds | none |
| **D4** | overflow/underflow counters + audit enum | holds as written — **dead code in shipped `ltl`** | = T | **vacuous** | **A2/A3** if P10 locks |
| **D5** | per-key seeded partition, doubling, rebin telemetry. *"The auto-resize lifecycle itself is not revisitable."* | holds — costs now measured: 100% of 725 pairs remap both sides; 13 display anchors; sole cause of the R4 breach and of order-dependence | holds — verbatim; identical telemetry at 4,153 / 51,469 / 286,659 keys | **vacuous** — no seed, extend or rebin; replaced by span telemetry (0 of 4,153 keys exceed T's seed) | **UNDER REVIEW — architect-level** (§ 7.1) |
| **D7** | `-mdm raw` opt-out | holds | holds — builds no store | holds | none |
| **D8** | `-V` field set **and order** | holds — 4 of 10 discriminate; `counter_memory_bytes` non-deterministic within `ltl` itself; merge rebins invisible | holds — byte-identical to real `ltl` at 53/115/616 and `-mdm raw` | **6 inert; 7 of 10 un-diffable**; names still parse | **amendment required by D8's own rule; field-order contract unrecorded** |
| **R2** | bin assignment matches locked boundary computation | holds — closed form has the same ULP property at exact powers of ten | holds | holds except exact powers of ten: **1 of 985 values, 38 of 857,480 obs**, one index low, value = the closed bin's upper boundary, zero attribution error | **a convention must be recorded** (closed form as-is vs boundary-checked at ~2 extra `**` per add); the digest baseline depends on it |
| **R4** | percentile primitive; accuracy bound, **"structural, not empirical"** | **BREACHED after any remap — 2.10 bins @depth 15**; 48 → 98 of 1,000 across depths; p95 crosses 1 bin by depth 3; also 1 key @256 and 1 @616; 1.38 bins on a wide-range key after three doublings | **= T exactly** — inherits the breach | **met in every scope, tier and shape** — 0 breaches in 20,020 evaluations; every apparent ">1" is exactly 1.000000 | **A4 — applies to TODAY'S SHIPPED CODE regardless of arm.** R4's own text is under amendment: "PROPOSED, NOT APPLIED" |
| **R5** | determinism | holds for a fixed sequence (all R5 promises). **Not** order-independent: 52–96% of groups, spread to 2.00 bins | = T | holds, **and additionally** order-independent and merge-commutative | none (C2 is QUALITY, explicitly not claimed) |
| **R7** | partition independence — *"a hard requirement, not an option … no global registry of partitions"* | holds | holds. Its **adopt-by-reference** path cannot be reproduced by any columnar row — S copies | **UNRESOLVED.** Grid shared; counts not; rows independent; merge touches neither source. Settled **nowhere**; appears in **no amendment list** | **must be decided before any G implementation is scoped** (§ 7.2) |
| **R12** | `partition_rebin` as finalize wrapper (#201) | holds — the remap whose accuracy cost R4 records and whose time cost P9 records; `rebins` reset to 0 | holds — S's finalized cells identical to T's in all 90 rows | **not used** — G's merge is an index-wise add; finalize places mass by value | none stated |
| **C7 — target-empty adopt-by-reference aliasing** *(undocumented shipped behaviour; an arm must decide, not inherit by accident)* | when the merge target is empty, `$target->{partition} = $source->{partition}` **by reference** | **the shipped behaviour** — reachable in `ltl` (`merge_bin_state` creates exactly that empty target) but safe as used: the wrapper deletes the source slot immediately | **copies** — a columnar row cannot share an arrayref without corruption. Observable only via probe A21 | **copies** — no aliasing possible | **a replacement must preserve the delete, not the aliasing.** Whether `ltl`'s adopt path should itself become a copy is an open architect call |

**Decisions under review that this evidence pressures** — carried to § 7 with options costed.

---

### P14-1 — Re-bless volume (bpd 53 — **fillable at bpd 53 only**)

**T and S are 0.00% T3 by construction** — T *is* the committed baseline; S is digest-identical on every surface tested. Neither moves a single cell of any `*-bin-data-model` baseline. That zero is a real property of both arms and is the entirety of their re-bless cost.

**The direction columns are mandatory**: a T3 classification carries magnitude only — it says a cell moved more than 1%, and nothing about whether it moved *toward* or *away from* the true value.

| scenario | keys | cells | T1 % | T2 % | **T3 %** (blocking) | worst dev | **G closer** | **G further** | **tie** |
|---|---|---|---|---|---|---|---|---|---|
| `apache-bin-data-model` | 55 | 605 | 51.07 | 27.11 | **21.82** | 3.8923% @p1 | 142 (23.47%) | 154 (25.45%) | 309 (51.07%) |
| `tomcat-bin-data-model` | 3,074 | 33,814 | 73.33 | 10.79 | **15.88** | 4.1625% @p75 | 1,907 (5.64%) | 7,111 (21.03%) | 24,796 (73.33%) |
| `tomcat-heatmap-bin` | 3,074 | 33,814 | 73.33 | 10.79 | **15.88** | 4.1625% @p75 | 1,907 (5.64%) | 7,111 (21.03%) | 24,796 (73.33%) |
| `thingworx-bin-data-model` | 3,419 | 37,609 | 43.82 | 24.52 | **31.67** | 4.5191% @p95 | 8,959 (23.82%) | 12,170 (32.36%) | 16,480 (43.82%) |
| `codebeamer-bin-data-model` | — | — | — | — | — | — | — | — | **NOT COVERED** |

`codebeamer-bin-data-model` prints as **NOT COVERED, never blank.** The prototype's two verbatim parsers do not read that log's bracketed `[293ms]` duration, which `ltl` reads through the format registry. A limitation of the prototype's parsers, **not an `ltl` finding** — the scenario is unmeasured in either direction.

**T3 is concentrated mid-ladder and vanishes at the tails** — `thingworx`: p1 18.22% → p25 57.39% → p50 58.79% → p75 60.34% → p95 38.23% → p99 2.16% → p999 **0.00%** → p9999 **0.00%**; `tomcat`: p1 16.07% → p25 34.52% → p50 34.09% → p90 12.85% → p999 2.15% → p9999 0.00%; `apache`: peak p10 41.82%, p99/p999/p9999 all 0.00%.

**Direction is mixed, and that is the finding.** Against this, at fan-out cardinality the choice is accuracy-neutral: **573,026 of 573,318 cells exact for both arms**, and of the 292 non-degenerate cells G is closer on every band.

**Fillable at bpd 53 only.** The enumeration reproduces the per-key percentile computation rather than running `ltl`'s CSV pipeline — it enumerates the shift `compare-statistics-drift.pl` would classify without producing the classified diff itself.

**Adoption surface beyond re-bless:** **T = 0** call sites, 0 amendments, 0 `-V` fields lost. **S** re-points **14** `counter_update` sites (1 message + 1 consolidation + 2 bucket + 2 heatmap + 8 histogram) and loses 0 `-V` fields. **G** re-points the same 14, loses 3 discriminating `-V` fields (6 inert), requires A2/A3 (A4 owed regardless), and leaves **R7 unresolved**. The uncovered-path risk **all three inherit**: the bin heatmap and bin histogram renders have **zero golden coverage** — every `hg-*`, `hl-histogram-*` and `heatmap-*` scenario in `tests/validate-regression.sh` carries `-dm raw`, fencing the whole render-regression suite off the bin path.

---

## 4. Arm-major profiles

All three tables carry identical rows and columns; that identity is the symmetry contract. `msg-stats` = unbounded per-key fan-out surface (286,659 keys) unless a cell names the 51,469-key fixture. `display @616` = the finalize contract at the rung the display surfaces run at.

### M-T — keep today's representation

| Dimension | msg-stats @53 | @616 | bucket-stats @53 | @616 | display @616 | where best | where worst |
|---|---|---|---|---|---|---|---|
| **P1** parity | trivially — T is the baseline | trivially | trivially | trivially | trivially | everywhere by definition | nowhere — but the baseline is not evidence of correctness |
| **P2** accuracy | 573,026/573,318 exact (tied with G); of 292 non-degenerate, G closer on every band | sub-1% on every band, both files | max rel err 0.04390 dpm / 0.04126 tomcat | 0.00373 / 0.00452; 4 of 3,005 > 1 bin, all quantisation | see @616 | **bpd ≥115 Tomcat** (0.0210% vs 0.2385%) | **bpd 16 wide-spread** (6.7845% vs 3.5972%) |
| **P3** merge accuracy | pairs 1.35–1.48 bins, within-1-bin 96.4–99.6% | 0.55% / 1.46 bins | **no merge path** | no merge path | no merge path | shallow: disjoint merge ≤1 bin on 3,999/4,000 | **depth 15: 2.1026 bins, 98/1000, p95 1.2259** — breaches its own R4 |
| **P4** determinism | fixed-sequence holds. Order: **24/25 (96%)**, spread 2.0006 | 23/25 (92%), 1.0003 | 17/25 (68%), 2.0003 | 21/25 (84%), 1.0002 | T=S identical, all 90 rows | fixed-sequence determinism — absolute | **68–96% of groups land on different state** |
| **P5** display | n/a | n/a | n/a | n/a | mass 1.000000, peak offset 0; hm dpm 0.2948%, tomcat 0.0337%; hg dpm 0.0700%, tomcat 0.0740% | **Tomcat heatmap @616**; DPM hm @53/115/256 | **13 range anchors across 24–25 buckets**; median 0.2667% vs 0.0667%; the only 2 peak-retention misses in 90 rows |
| **P6** memory | 662.3 MB, 2,423 B/key | **3,722.4 MB, 13,616 B/key** | 398,378 B / 416 kB | **2,531,282 B — smallest arm** | ≤4 MB | **bucket-stats @616 — smallest arm** | **msg-stats @616 — 12.7× S, 18.9× G** |
| **P7** fill | 1.518 s [1.401,1.628] | 2.966 [2.899,3.024] | 0.1120 dpm / 0.5331 tomcat | 0.1265 / 0.5458 | flat in bpd | nowhere | **slowest arm everywhere**: 1.23–1.45× S, 2.06–2.18× G |
| **P8** percentile | **17.634 s** [17.616,17.640] | **181.348 s** [181.257,181.921] | 0.02349 | 0.28252 / 0.11126 | — | nowhere | **79.5× S, 105× G @616**; walks ~18× more bins than occupied for keys whose median span is **1** |
| **P9** merge/fold | fold **18.2006 s**, 63.49 µs | fold **199.5215 s**, 696.03 µs | no merge path | no merge path | — | vs S(dense), 1.9× faster | **×10.96 ladder**; 5.0×/12.4× slower than S2; 56–745× slower than G |
| **P10** growth | — | **time ×10.3, memory ×5.6**; fold ×10.96 | — | Devel ×6.35 | — | nowhere | **T's growth IS the constraint #426 exists to move** |
| **P11** extremes | overflow 0 / underflow 0 on 4,153 real keys | 0/0; max bins 4,619 | 0/0 | clamp 9.24% hi / 2.79% lo dpm; 9.09% / 28.53% tomcat | — | E1 is **live state** T can populate — G cannot | **`0` dies; `−5` unbounded loop; `1e-320` → `Inf`; `1e308` → `NaN`** |
| **P12** `-V` | trivially — 10/10 live | trivially | trivially | trivially | trivially | **all ten D8 fields populable** | **`counter_memory_bytes` non-deterministic within T itself (2.7%)**; merge rebins invisible |
| **P13** locked decisions | trivially — 0 amendments | trivially | trivially | trivially | trivially | **zero amendments — the only arm with this** | **R4 breached by T itself**; A4/A5 owed regardless of arm |
| **P14** adoption | trivially — 0.00% T3 | trivially | trivially | trivially | trivially | **zero re-bless, zero blast radius** | the cost is what T *keeps*, not what it changes |

**What only this arm gives you**

1. **Zero adoption cost on every axis at once** — no re-bless (0.00% T3 against all committed bin baselines), no amendment, no `-V` change, no implementation surface, no harness work, no doc sweep. Nothing else is free on all six simultaneously.
2. **All ten D8 `-V` fields live**, including the four that discriminate. A `-V` diff is a valid gate.
3. **Per-key seed adaptivity that improves with resolution** (E5). From bpd 115 up on Tomcat T is ahead and stays ahead at 616 — 0.0210% vs 0.2385%, an order of magnitude.
4. **The smallest store on a bounded-cardinality surface** — 2,531,282 B vs S 3,588,988 (+42%) and G 2,714,054 (+7%) at bucket-stats @616.
5. **Live out-of-range state.** D4's counters are structurally present and populable (demonstrated under a cap). *Qualifier (F50):* unreachable in shipped `ltl` on T too — what T uniquely retains is the *capacity*, not a live signal.

**What this arm cannot do**

1. **Hold its own accuracy contract after a merge.** R4's bound is stated "structural … not empirical"; T breaches it monotonically — 1.2502 → 1.4046 → 1.5125 → **2.1026 bins** at depths 1/3/7/15, with the **p95 itself** crossing one bin by depth 3. Raising resolution does not rescue it (2.06 @616). This is a property of shipped code today, not a cost of changing away from it.
2. **Produce order-independent `-g` results.** 68–96% of groups; spread to **2.00 bins**; 3–4 distinct canonical states from 4 of 40,320 orderings — and **the harness cannot see it**, because the order is deterministic for a given input. C2 means T fails no contract here; it lacks a property.
3. **Give the display a consistent range anchor.** 13 anchors across 24–25 buckets — #201 Dimension B, "unrecoverable at render time" (#34 R5). Tomcat @616: median 0.2667% vs 0.0667%, max 0.4583% vs 0.2333%.
4. **Make per-message resolution affordable.** 13,616 B/key and 181.348 s at bpd 616 on 286,659 keys, vs S's 1,073 B and 2.281 s. The coarse rung pays for the container, not for the statistics.
5. **Merge or fold cheaply.** 18.2006 s / 199.5215 s for 286,658 merges, ×10.96 ladder; **100% of 725 consecutive pairs required a double rebin** — consecutive keys seed on different first samples, so the union geometry matches neither side.
6. **Report its own memory reproducibly.** 2.7% spread on byte-identical input; and `fold_rebins=0` on an accumulator re-geometried 265 → 531 bins.

---

### M-S — span-only columns, verbatim T geometry

| Dimension | msg-stats @53 | @616 | bucket-stats @53 | @616 | display @616 | where best | where worst |
|---|---|---|---|---|---|---|---|
| **P1** parity | **digest-identical to T** | **digest-identical** | digest-identical **+ bit-identical accuracy figures independently** | digest-identical, 10/10 | **cell-identical, all 90 rows** | everywhere — strongest parity result in the corpus | one divergence anywhere: probe A21, unreachable in `ltl` |
| **P2** accuracy | = T exactly | = T | = T bit-for-bit | = T bit-for-bit | = T, every cell | inherits T's best | inherits T's worst, incl. the bpd-256 bound failure |
| **P3** merge accuracy | = T (all four shapes) | = T | no merge path | no merge path | no merge path | — | **inherits T's R4 breach in full**; S2 reproduces the projection bit-for-bit, so the native merge does not fix it |
| **P4** determinism | = T: 24/25, 2.0006 | = T: 23/25 | = T | = T | = T | fixed-sequence holds | **inherits T's order-dependence exactly** — which is itself the parity proof |
| **P5** display | n/a | n/a | n/a | n/a | **identical to T in every cell**; inherits #201's validation by construction | inherits T's wins | **inherits the 13 anchors and both peak misses** — changes nothing in either direction |
| **P6** memory | 291.7 MB, **1,067 B/key** | **293.9 MB, 1,073 B/key** | 412,692 B / 512 kB — already above T | **3,588,988 B — +42% vs T** (Tomcat +67% RSS) | ≤4 MB | **msg-stats @616 — 12.7× smaller than T** | **bucket-stats @≥115 — the largest arm** |
| **P7** fill | 1.233 [1.220,1.243] | 1.294 [1.286,1.307] | 0.0779 / 0.3646 | 0.0999 / 0.3733 | — | consistently 0.66–0.70× T | 1.6× G — the per-key partition state S still carries |
| **P8** percentile | **2.112 s** — **8.4× T** | **2.281 s** — **79.5× T** | 0.01239 | 0.12720 / 0.04463 | — | **msg-stats @616** | 1.16–1.31× G |
| **P9** merge/fold | fold **S 34.3621 → S2 3.6454**; pairs S 91.80 → **S2 14.55 µs** | fold **S 414.1805 → S2 16.1192**; pairs S 902.10 → **S2 53.64 µs** | no merge path | no merge path | — | **S2 @616: 12.4× T, 25.7× S(dense)**; ladder ×12.05 → **×4.42** | S(dense) was the worst arm here — **escaped, not inherent** |
| **P10** growth | — | **time ×1.08, memory ×1.008**; fold ×12.05 → **×4.42** | — | Devel **×8.70 — steeper than T's ×6.35** | — | **flattest msg-stats ladder of any arm** | **steepest bucket-stats ladder of the three** |
| **P11** extremes | 12 telemetry fields identical to T; 30/30 canonical matches | identical | identical | clamp identical to T | — | reproduces D4/D5 semantics verbatim | **inherits T's failure modes exactly** (+ a `Non-finite repeat count` warning S alone emits) |
| **P12** `-V` | **all 10 fields YES, same values as T** | all 10 | all 10 | all 10 | — | **a `-V` diff is a valid gate for S** | `counter_memory_bytes` 2.4–4.8× smaller — a true reading that makes the field un-diffable; inherits C8 |
| **P13** locked decisions | all unchanged | unchanged | unchanged | unchanged | R12 exercised and carried unchanged | **zero amendments for adoption** | **R7's adopt-by-reference cannot be reproduced by any columnar row** — C7 must be decided, not inherited |
| **P14** adoption | **0.00% T3 by construction** | 0.00% | 0.00% | 0.00% | 0.00% | **zero re-bless — the only non-T arm with this** | 14 call sites; `MEMORY` attribution "highly likely" to break silently |

**What only this arm gives you**

1. **The memory and speed of a compact container with no observable change of any kind.** Digest-identical across every fixture, rung, geometry and merge shape tested. **0.00% T3.** No other container-changing arm has this.
2. **8.4× / 79.5× percentile evaluation and 2.2× / 12.7× memory on the surface #426 exists for**, with ladder growth almost removed (×1.08 / ×1.008 against T's ×10.3 / ×5.6) — measured at 286,659 keys, built at size, not projected.
3. **A fold that scales with occupied span rather than bpd, with no semantic change.** S2 is 12.4× T at bpd 616 and drops the ladder exponent from ×10.96 to **×4.42**, bit-identical across 155 assertions including element-for-element raw span equality.
4. **A `-V` section that remains diffable against real `ltl`** — all ten fields with T's values; every field but `counter_memory_bytes` matches `ltl` exactly on the smallest fixture.

**What this arm cannot do**

1. **Fix anything.** Every T defect is inherited by design: the R4 breach, the order-dependence, the 13 anchors, the bpd-256 bound failure, the `−5` infinite loop, the `1e-320` geometry break, C8's invisible merge rebins. "Changes nothing observable" cuts both ways.
2. **Save memory on a bounded-cardinality surface — it costs memory there.** +42% (Devel) / +67% (RSS) at bucket-stats @616; largest arm at every rung ≥115 on both fixtures; ladder growth ×8.70 vs T's ×6.35.
3. **Reproduce the adopt-by-reference path** — no columnar row can. Observable only via A21, unreachable in `ltl`. A decision (C7), not an inheritance.
4. **Beat G on any cost axis.** 1,026 vs 635 ns/sample; 2.112 vs 1.616 s; 1,067 vs 712 B/key; S2's 3.6454 s vs G's 0.0927 s at 51,469 keys.
5. **Escape the memory-instrument risk.** `counter_memory_bytes` un-diffable; `MEMORY\tunattributed` absorbing the delta rated "**highly likely**" for a compact container (G7), with in-tree precedent (`format_scan_subs`).

---

### M-G — one shared log-spaced grid

| Dimension | msg-stats @53 | @616 | bucket-stats @53 | @616 | display @616 | where best | where worst |
|---|---|---|---|---|---|---|---|
| **P1** parity | **differs by design** — 15.88–31.67% T3 | not measured at fan-out | differs by design; N-conservation passes everywhere | differs by design | differs by design | — | **the only arm that changes observable output**; direction mixed |
| **P2** accuracy | 573,026/573,318 exact (tied); **of 292 non-degenerate, closer on every band** | not measured | max rel err 0.04321 / 0.04430 | 0.00374 / 0.00374; **within 1 bin 100.00% in all 10 configs** | see P5 | **bpd 16 — better on both files**, 3.19 pt margin | **bpd ≥115 Tomcat** — 0.2385% vs 0.0210%; margin 0.012 pt |
| **P3** merge accuracy | max **1.00 bins, 100% within 1 bin at every q and tier** | 1.00 bins; 100% | no merge path | no merge path | no merge path | **0 breaches in 20,020 evaluations; max exactly 1.000000** | nowhere — structural |
| **P4** determinism | **0/25 groups, spread 0.0000** | **0/25, 0.0000** | 0/25 | 0/25 | globally anchored | **exactly order-independent and merge-commutative**; byte-identical canonical strings | nowhere — but the corpus does not claim this as a requirement, so it is unweighted |
| **P5** display | n/a | n/a | n/a | n/a | mass 1.000000, offset 0; hm dpm 0.2915%, tomcat 0.0806%; hg dpm 0.0961%, **tomcat 0.0003% (1 cell)** | **1 range anchor**: Tomcat @616 median 0.0667% vs 0.2667%; largest single-cell margin in the set | **Tomcat heatmap @616: 0.0806% vs 0.0337%** — the ranking flips by file, geometry and rung |
| **P6** memory | 194.7 MB, **712 B/key** | **196.9 MB, 718 B/key** | 341,054 B / 352 kB — **smallest** | 2,714,054 B — **above T (+7%)**, below S | ≤4 MB | **smallest in 6 of 8 bucket cells and at msg-stats both rungs** | **bucket-stats @616 — above T by 7%** |
| **P7** fill | **0.697 s**, **635 ns/sample** | **0.738 s**, 619 ns | **0.0544** / **0.2592** | **0.0562** / **0.2621** | — | **cheapest fill everywhere** — one `floor(bpd·log10 v)` | nowhere |
| **P8** percentile | **1.616 s**, 1.88 µs/eval | **1.731 s**, 2.01 µs | **0.01143** | **0.10931** / **0.03939** | — | **cheapest everywhere** — 105× T @616 | nowhere |
| **P9** merge/fold | fold **0.0927 s, 1.80 µs**; rollup 0.96 µs; disjoint 1.05–2.76 µs | fold **0.1166 s, 2.27 µs**; rollup 1.24 µs | no merge path | no merge path | — | **56–475× T on rollup, 81–745× on disjoint**; fold ×1.26. Under rollup **also more accurate** than T (p50 0.08–0.11 vs 0.09–0.47) | nowhere on cost |
| **P10** growth | — | time ×1.07, **memory ×1.011**; fold ×1.26 | — | Devel ×7.96 | — | **flattest fold ladder of any arm** | **bucket-stats ×7.96 — steeper than T's ×6.35** |
| **P11** extremes | **structurally none** — every positive double indexable; counters identically 0 | same | clamp 9.38% hi / **5.28% lo** dpm | **eliminates 100% of Tomcat's low clamps** (0.00% vs 28.53%) | — | **needs no growth cap**; 0 of 4,153 real keys exceed T's seed; 0.43–0.45× T's bytes on the 1..1e9 worst case | **`0` and `−5` die immediately**; clamp direction is a *data* property — adds low clamps on DPM, removes them on Tomcat |
| **P12** `-V` | **6 of 10 fields have no source** | same | same | same | — | span telemetry substitutes with the same *shape* | **a `-V` diff is not a valid gate** until A2/A3. **F50: 3 of the 6 pass trivially for any arm — discriminating fields lost is 3** |
| **P13** locked decisions | **D4, D5, R1, R6 vacuous; D8's field set changes** | same | same | same | R12 as finalize exercised | **satisfies R4 literally** — "structural" becomes true | **#187 D5's non-revisitable clause directly overridden; #189 R7 unresolved** |
| **P14** adoption | **T3: apache 21.82%, tomcat 15.88%, heatmap-bin 15.88%, thingworx 31.67%**; worst 3.89–4.52%; codebeamer **NOT COVERED** | not measured | — | — | — | T3 **zero at p999/p9999**; direction mixed | **largest adoption cost of the three**: blocking re-bless of 4 of 5 baselines, ≥3 amendments, unresolved R7, plus S's whole implementation surface |

**What only this arm gives you**

1. **The R4 bound as an actual structural property** — 0 breaches in 20,020 evaluations, max exactly 1.000000, `_gt1eps = 0`. R4's sentence becomes literally true, because no count is ever re-projected.
2. **Exact order-independence and merge-commutativity** — 0/25 groups, spread 0.0000, byte-identical canonical strings; G reaches 1 canonical state where T reaches 3–4. *Qualifier:* the corpus does not claim this (C2), so its weight is unsettled (§ 7.7).
3. **A single global range anchor on the display surface** — 1 anchor vs 13, and better at the rung the display runs at (median 0.0667% vs 0.2667%).
4. **The cheapest arm on every cost axis, surface and rung measured** — and under the rollup shape *simultaneously more accurate* than T, so there is no speed/accuracy trade on that shape at all.
5. **No out-of-range state and no growth cap to tune** — 1e-320 and 1e308 both indexable where T's geometry breaks; span bounded by the key's own data; 0 of 4,153 real keys exceed T's seed.
6. **Better accuracy where bins are scarce** — 3.19 points at bpd 16 on DPM `N<1000/spread≥1dec`.

**What this arm cannot do**

1. **Avoid a blocking re-bless.** 15.88–31.67% T3 at bpd 53 on **4 of 5** scenarios; the fifth is **NOT COVERED**, not clean. Re-blessing committed baselines is one-way.
2. **Keep #187 D5**, whose lifecycle clause is marked non-revisitable. D5/D4/R1/R6 go **vacuous, not violated** — but that still requires an architect amendment, and the corpus states the conflict without resolving it (§ 7.1).
3. **Be validated by a `-V` diff against `ltl`** until A3 lands. *Honest qualifier (F50):* 3 of the 6 inert fields are constants in every shipped run and pass trivially for T and S too — genuinely discriminating fields lost is **3**, not 6.
4. **Settle whether it violates #189 R7.** Resolved nowhere; in no amendment list (§ 7.2).
5. **Match T's accuracy where bins are plentiful** — 0.2385% vs 0.0210% @616 Tomcat. *Qualifier:* both sub-1% there; margin 0.012 pt against 3.19 pt at bpd 16.
6. **Claim a general display-fidelity win.** The aggregate ranking flips by file, geometry and rung — 10 of 20 cells each. Only the per-time-bucket anchoring result is unidirectional.
7. **Escape the boundary-straddle artefact** — which is not its to fix: T and G produce it identically.

### Capture index

| Dimension | primary captures |
|---|---|
| P1, P12 | `revalidate-v2-parity-{T,S}-bpd{53,616}.txt`; `native-span-merge/parity-*.txt`, `span-invariant.txt`; `n7-audit-census/` (22 files); `revalidate-v4-ltl-real*.txt`, `revalidate-v4-diff.txt` |
| P2, P14 | `accuracy-by-key-shape/{dpm-ladder,tomcat-ladder,tomcat-bpd53,fanout-bpd53}.txt`; `v8-rebless/{run-bpd53.txt,rebless-bpd53.tsv}`; `revalidate-v5-{key,small}-bpd*.tsv` |
| P3, P4, P9 | `n5-merge-shapes/{T,S,G}-bpd{53,616}-{fanout,dpm}.txt`, `driver.txt`, `timings.tsv`, `verify.txt`, `verify-order.txt`; `revalidate-v5-{pair,fold}-bpd*.tsv`; `revalidate-v1-determinism.tsv`; `native-span-merge/{pairs,timing}-fanout-bpd*.txt` |
| P5 | `v6-{dpm,tomcat}-{53,80,115,256,616}/`, `v6-all.tsv` (90 rows); `v6-probe/boundary-straddle.txt` |
| P6–P8, P10 | `message-stats-scale/fanout.txt`; `revalidate-v2-{T,S,G}-bpd{53,616}.txt`, `revalidate-v2.tsv`; `v7/v7-summary.tsv` (41 files); `n3n6n8/n6-*`; `n3n6n8/n6-pct-armT-bpd616-reproduction.txt` |
| P11 | `revalidate-v3-part{A,B,C}.txt`; `revalidate-v1-partA.txt`; `v7/v7-clamp-magnitude.txt` |
| P13 | Report § *Decisive evidence per locked decision*; § *Proposed amendments* A1–A11 |

**NOT FILLABLE, stated rather than blank:** real-`ltl` end-to-end cost per arm; G on `codebeamer-bin-data-model`; rungs 115/256 at fan-out cardinality (do not interpolate); **S2 memory** (never re-run; `_remap_span` transient unmeasured); per-arm cost on real `-b` wall-clock buckets (V6/V7 buckets are fixed-line-count runs; N-skew untested).

---

## 5. The inversions

Ten. Eight named by the framework; **two the evidence shows and the framework's list missed**, marked as such. Treatment follows cause: *by surface* → paired figures never averaged; *by resolution* → resolution as the axis with an explicit crossover; *by data shape* → a range across named fixtures, never a scalar.

### Inversion 1 — Per-key adaptivity: a locked virtue for percentiles, the locked failure mode for display

**The load-bearing one.** The *same mechanism* — D5's seeding around the key's first observed value — is the stated rationale for D5 and the diagnosed failure mode in #201.

- #187 D5 § *Why this lifecycle*: "**Tighter per-key resolution.**" And: "The auto-resize lifecycle itself is not revisitable."
- #34 R5 quoting #201 Dimension B: the same anchoring is "**unrecoverable at render time**."

**Threshold: not a parameter, but what the key means.** When the key is a logical series whose percentiles are read on their own, adaptivity is a benefit that grows with resolution. When the key is a *time bucket* rendered side by side on one shared axis, adaptivity is per-bucket range anchoring, and it is destructive. Both keyings exist in shipped `ltl` on one substrate.

**Mechanism.** Seeding on `v₀` makes bin edges a function of *which observation arrived first in that key*. For an isolated percentile this concentrates the budget where the key has values. For a rendered row it means bucket 7 and bucket 8 have different edges — not commensurable, and no render-time step recovers the alignment.

| side | measured cells |
|---|---|
| adaptivity **wins** | Tomcat from bpd 115 up, ahead at 616: `N≥1000/<1dec` **0.0210% (T) vs 0.2385% (G)**. DPM @616: T ahead on 2 of 4 bands |
| adaptivity **loses** | **13 distinct anchors across 24–25 buckets** (T/S) vs 1 (G). Tomcat @616 median **0.2667% vs 0.0667%**, max 0.4583% vs 0.2333%. The only two peak-retention misses in 90 rows are T/S |
| adaptivity **loses, second surface** | T's seed puts boundaries at 0.9896 below Tomcat's true min of 1, so p1 lands under min on **100% of buckets** (low-clamp 28.53%); G's boundary *is* 1, low-clamp **0.00%** |
| adaptivity **irrelevant** | fan-out: **573,026 of 573,318 cells exact for both arms** — at the motivating cardinality the population is single-observation-dominated |

**Locked decision under pressure.** D5's non-revisitability clause is contradicted by its own second sign, measured. → § 7.1.

### Inversion 2 — Memory inverts by surface (F55)

**Threshold:** partition count against per-partition occupancy — a *shape*, not a key count. Span-only wins when partitions are **numerous and sparsely occupied**, loses when **few and densely occupied**.

**Mechanism.** At fan-out, occupied span p50 = **1 bin** while T allocates 133 slots @53 / 1,540 @616 — S pays one row's bookkeeping and recovers 132 / 1,539 empty slots. At bucket-stats a partition holds ~2,000 obs over a wide range and occupies most of its span — S pays the bookkeeping and recovers nothing.

| unbounded (286,659 keys) | bounded (62 DPM buckets) |
|---|---|
| @53 T 2,423 / S 1,067 / G 712 B/key — **S 2.2× smaller** | @53 T 398,378 / S 412,692 / G 341,054 B — S already **+3.6%** |
| @616 T 13,616 / S 1,073 / G 718 B/key — **S 12.7× smaller** | @616 T 2,531,282 / S **3,588,988** / G 2,714,054 — **S +42%, G +7%** |
| ladder: T ×5.6, S ×1.008, G ×1.011 | ladder: T ×6.35, **S ×8.70**, G ×7.96 |

Tomcat @616 is sharper: S 2,000 kB RSS vs T 1,200 — **+67%**. **The sign flips inside the flip:** on msg-stats S has the flattest ladder growth of the three; on bucket-stats the *steepest*.

### Inversion 3 — Accuracy inverts by resolution, in opposite directions on the two files (F37)

**Crossover: bpd ≈ 53–115.** At 16 G is ahead on both files; at 53 mixed on DPM, T ahead on Tomcat; from **115** up T is ahead on Tomcat and stays ahead at 616.

**Mechanism.** T's adaptive bins pay off *more* as the budget grows. G's refusal to waste bins on unoccupied range dominates when bins are *scarce*.

Full band table at **P2-1**. Margin at each end on DPM `N<1000/≥1dec`: **3.19 points at bpd 16, 0.012 points at 616** — the inversion is real, its stakes ~265× larger at the coarse end. Both arms sub-1% on every band at 616.

### Inversion 4 — The bound is "structural" in the decision text and measured non-structural once the merge path runs

**Threshold: merge depth 3.** At depth 1 T's p95 is 0.9990 (inside the bound); by depth 3 the **p95 itself** is 1.0660 — the breach stops being a tail case.

**Mechanism.** Each remap re-projects **already-remapped** counts by geometric midpoint; displacement compounds. **Not disjointness**: one maximally disjoint merge (gaps to 4.84 decades, union to 6,068 bins) stays within one bin on **3,999 of 4,000** evaluations (worst 1.0008). It is *successive* merges.

| depth | T max | T p95 | T >1 bin | G max | G >1 bin |
|---|---|---|---|---|---|
| 1 | 1.2502 | 0.9990 | 48 | **1.0000** | **0** |
| 3 | 1.4046 | **1.0660** | 66 | **1.0000** | **0** |
| 7 | 1.5125 | 1.1223 | 78 | **1.0000** | **0** |
| 15 | **2.1026** | **1.2259** | 98 | **1.0000** | **0** |

Raising resolution does not rescue it (2.0637 @616). **R4's "structural … not empirical" is measured false on shipped code**; A4 is proposed, not applied, and applies to T regardless of arm. G's exact adherence is a property of having no remap — not a benefit that must be bought.

### Inversion 5 — Byte-identity required in three areas, explicitly waived in one

#187 R11 waives byte-identity for percentile values; #287 R12, #305 and #34 R8 all require it. **Threshold: the 1% T3 tier** in `compare-statistics-drift.pl` — below advisory, above blocking.

**Mechanism.** A container change is not an algorithm migration, so it inherits the **strict** reading. That is what converts G's accuracy profile — better on several axes — into a blocking harness event: **21.82 / 15.88 / 15.88 / 31.67% T3**, worst 3.89–4.52%, concentrated p10–p95, **zero at p999/p9999**, direction mixed. S is 0.00% by construction; T trivially 0.00%.

### Inversion 6 — Resolution is per-surface-legitimate in two areas, pinned in two

#187 D2 as amended calls the precision parameter "legitimately per-surface"; the #426 framing correction says bpd 616 "is not a tunable knob … out of scope"; #189's locked objective says the tiers "are **not in question**".

**Mechanism, and the datum that pressures it.** The msg-stats ladder tops out where it does partly *because of the container*: 181.348 s and 3,722.4 MB at bpd 616 against S's 2.281 s and 293.9 MB. **The container change moves the constraint; it does not move the table.** Recorded as evidence about what the per-message row *could* afford — explicitly not a proposal to change `%TIER_BPD`.

### Inversion 7 — Merge is High-weight in two areas, unspecified in two, and all four share one code path

#287 R2.3 binds merge fidelity for message-stats ("observationally identical … numerically identical on the sidecar-derived statistics"); #189/#201 never bind it. **No associativity claim exists anywhere**; no accuracy bound is scoped "after N merges" other than F25/F46, "a finding, not a locked contract".

**Mechanism, and why the asymmetry is dangerous.** All four surfaces reach `merge_bin_counter_entries` → `partition_rebin`. And R2.3's *prose* is wrong about the code: it says "extend the narrower side"; the shipped code **rebins both sides** into a union geometry. S2 is built against the shipped mechanism, which is why it reaches bit-identical digests.

**Measured:** `-g 90 × -mdm bin` through `merge_bin_counter_entries` is **entirely unasserted** — every `*-consolidated` statistics-drift scenario is raw-model; no `*-bin-consolidated` scenario exists. The audit's words: "**Highest-risk uncovered path.**" It is where T's 2.10-bin breach and 96%-of-groups order-dependence both live.

### Inversion 8 — Partition independence against G's construction

**Text.** #189 R7: "**This is a hard requirement, not an option** … The primitives impose no global registry of partitions."

**Two readings, both defensible from the evidence.** *Violates:* G is one shared geometry for every key in a store. *Does not violate:* rows remain independent and separately freeable; merge is an index-wise add touching neither source; what is shared is an **index function**, not a registry of partition objects — G's store holds only `{row, key, bins}`, with no partition record at all.

**Status:** resolved nowhere; **absent from the amendment list** — it appears in no A-row. Either a non-issue or a blocking amendment. → § 7.2.

### Inversion 9 (added) — Low-clamp direction inverts by *data shape*, not by arm

**Mechanism:** purely whether the observed minimum sits on a grid boundary. Tomcat's min is exactly `1 = 10^0`, on a G boundary — so `grid_lower` for that bin *is* the minimum and interpolation cannot fall below it. DPM's min is `2`, off-grid (`grid_lower(grid_index(2)) = 1.91875` @53).

| fixture | min | on grid? | T/S low-clamp | G low-clamp | direction |
|---|---|---|---|---|---|
| Tomcat | 1 | **yes** | 28.53% | **0.00%** | G removes 100% of low clamps |
| DPM | 2 | **no** | 2.79% | **5.28%** | G nearly **doubles** low clamps |

A live example of the rule that a cell must be a range across named fixtures, never a scalar: "G eliminates low clamps" is true on one fixture and false on the other, and the determining fact is a property of the *data*. High clamps are essentially identical across all three arms.

### Inversion 10 (added) — S's merge cost inverts against its own implementation, not against another arm

**Threshold: the implementation of `merge` alone** — `Store::S2` inherits `add`/`_extend`/`percentile`/`entry`/`geometry`/`canonical`/`telemetry`/`memory_bytes` unchanged and overrides **only `merge`**.

**Mechanism.** S's dense-view merge materialises a dense array plus a partition hash per side, hands them to the verbatim `merge_bin_counter_entries`, then re-scans and copies the span back — on **every one** of 286,658 fold merges. `_remap_span` walks only the occupied span, computing each destination index with the same expression in the same order.

| bpd | T | S (dense) | S2 (native) | S's position |
|---|---|---|---|---|
| 53 | 18.2006 s | 34.3621 s | **3.6454 s** | worst arm → **5.0× better than T** |
| 616 | 199.5215 s | 414.1805 s | **16.1192 s** | worst arm → **12.4× better than T** |
| ladder | ×10.96 | ×12.05 | **×4.42** | tracks `bin_count` → tracks occupied span |

The one inversion in the comparison that is **escapable and already escaped** — and the reason every merge/fold cell carries dual `S → S2` numbers. Reporting S's V2 merge cost alone inverts the arm's standing on the dimension.

---

## 6. The frictions

One row per friction — *gaining X costs Y* — never one per dimension. The `escapable?` column is what makes this a decision instrument rather than a list of caveats.

| # | friction | gain | cost | arms | where it bites | escapable? |
|---|---|---|---|---|---|---|
| 1 | Memory/speed vs display fidelity | P6/P8: the container case | P5: #34 R5 forbids this trade outright | any shared substrate | display only | **structurally moot** |
| 2 | Per-key adaptivity vs cross-key comparability | P2 @≥115: 0.0210% vs 0.2385% | P5: 13 anchors/24 buckets; 0.2667% vs 0.0667% | G vs T/S | moderate-cardinality keys; all rendered rows | **no** — one mechanism, two signs |
| 3 | Accuracy high-res vs low-res | G @16: 3.5972% vs 6.7845% (3.19 pt) | T @616: 0.0210% vs 0.2385% (0.012 pt) | G vs T/S | the tier ladder | **no** — the crossover is the mechanism |
| 4 | Merge cost/correctness vs per-key precision | 0 breaches/20,020; 56–745× faster | 15.88–31.67% T3 re-bless | G vs T/S | `-g`; committed baselines | **no** — same mechanism |
| 5 | **Keeping today's representation** | 0 re-bless, 0 amendments, 10/10 `-V` | R4 breach 2.10 bins; 68–96% order-dependence; 13 anchors; 13,616 B/key; 181.348 s | **T** | everywhere | **no** |
| 6 | Span-only by surface | 2.2×/12.7× memory, 8.4×/79.5× time at fan-out | **+42%** memory vs T at bucket-stats @616 | S (and G) | bounded surfaces | **partially** — per-surface choice, at the price of two code paths |
| 7 | Span-only merge via dense views | — | 1.9× slower fold than T | S only | `-g` | **yes — already escaped** (S2) |
| 8 | Removing per-key partition state | no rebin, no out-of-range state, no cap | 3 discriminating `-V` fields inert; `-V` diff stops being a gate; R7 unresolved | G | harness / observability / contract | **no** — structural |
| 9 | **Compact container vs the memory instrument** | the smaller store | `MEMORY\tunattributed` absorbs the delta — "**highly likely**" | S, G | `-V benchmark-data` | **partially** — a dedicated RSS-delta path |

### Friction 1 — memory/speed against display fidelity. *The corpus forbids this trade for display.*

**Categorical**, #34 R5: "**Memory savings are not worth fidelity loss** … If a candidate reduces memory but smooths the histogram, **the candidate is wrong** … **do not accept the smoothing as a trade.**"

**Each side.** The container area exists to make exactly this trade — 79.5× on percentile time and 12.7× on memory at bpd 616. The display area has ~70 partitions and ~1.75 MB streaming overhead, which #201 calls "negligible vs. raw retention", with memory weighted **Low and explicitly subordinated**.

**Why it discharges.** The display area **has no memory problem to trade against**, so the trade is never actually offered there. And the fidelity evidence is unusually clean: 90 rows, and **T and S never differ in a single cell**, mass retention 1.000000 and peak X-offset 0 for *every* arm, G included. **No arm smooths the histogram.** D2, D4 and D8 hold across all three.

**The live obligation is weighting hygiene, not a trade:** a shared-substrate change must not carry the container area's memory-first weighting into display. Where a G-vs-T display difference exists it is *fidelity against fidelity* (the 13-anchor result), never fidelity against memory.

### Friction 2 — per-key adaptivity against cross-key comparability

**Gain:** 0.0210% vs 0.2385% on Tomcat `N≥1000/<1dec` @616 — an order of magnitude, growing with resolution. **Cost:** 13 anchors across 24–25 buckets, #201 Dimension B; median 0.2667% vs 0.0667%; and a second sign — T's seed puts boundaries below Tomcat's true min, so p1 lands under min on 100% of buckets.

**Which surface pays:** percentile gains; display and bucket-stats pay. **Not escapable** — one mechanism, two sides. **Moot at the motivating cardinality** (573,026/573,318 exact for both).

### Friction 3 — accuracy at high resolution against accuracy at low resolution

**Gain, low end:** G at bpd 16, 3.5972% vs 6.7845% — 3.19 points, ahead on every band on both files. **Cost, high end:** T from bpd 115 up on Tomcat, 0.0210% vs 0.2385% — 0.012 points.

**The asymmetry that matters:** stakes are **~265× larger at the low-resolution end**; both arms sub-1% on every band at 616. So the arm winning the *ratio* at high resolution wins a contest whose absolute magnitude has nearly vanished. Which end matters is a weighting the corpus does not supply → § 7.5. **Not escapable** — the crossover *is* the mechanism.

### Friction 4 — merge cost/correctness against per-key precision

**Gain:** 0 breaches in 20,020 evaluations; exact order-independence; 56–745× faster on rollup and disjoint pairs; and under rollup *also more accurate* than T (p50 0.08–0.11 vs 0.09–0.47 bins). **Cost:** 15.88–31.67% T3 blocking, worst 3.89–4.52%, direction mixed and read as two columns.

**Which surface pays:** the five committed bin-model baselines — and **re-blessing is one-way**. **Not escapable:** merge correctness and the value shift have the same cause (no per-key seed to anchor to).

### Friction 5 — keeping today's representation. **T is the arm that pays.**

**Gain:** zero re-bless, zero amendments, ten live `-V` fields, zero implementation surface, zero blast radius, zero doc sweep. On the adoption axis T is unbeatable.

**Cost — what T keeps by staying:**

| what T keeps | measured size |
|---|---|
| R4 breached after any remap | **2.1026 bins @depth 15**; 98/1,000 >1 bin; p95 crosses 1 bin by depth 3; 2.06 bins even at 616 |
| Order-dependent `-g` results | **68–96% of groups**, spread to **2.00 bins**; 3–4 distinct states from 4 of 40,320 orderings; **invisible to the harness** |
| 13 display range anchors | across 24–25 buckets; median 0.2667% vs 0.0667%; the only 2 peak-retention misses in 90 rows |
| Per-message cost at resolution | **13,616 B/key and 181.348 s** @616 on 286,659 keys; ×10.3 time / ×5.6 memory across the ladder |
| Fold cost | 18.2006 s / **199.5215 s** for 286,658 merges; ×10.96; 100% of pairs need a double rebin |
| An unreproducible memory instrument | **2.7% spread on byte-identical input**; merge rebins invisible |

**Not escapable within the arm.** Two qualifiers in T's favour: order-independence is QUALITY the corpus **explicitly does not claim** (C2), so T fails no contract there; and A4/A5 apply to shipped code **regardless of which arm is adopted** — adopting another arm does not by itself discharge them.

### Friction 6 — span-only layout, by surface

**Gain:** 2.2× / 12.7× memory and 8.4× / 79.5× percentile time at the unbounded surface, ladder ×1.008 / ×1.08 against T's ×5.6 / ×10.3. **Cost:** +42% Devel / +67% RSS at bucket-stats @616; largest arm at every rung ≥115 on both fixtures; ladder ×8.70 vs T's ×6.35.

**Partially escapable** — a per-surface representation choice takes the gain without the cost, at the price of two code paths on one substrate, which is exactly the coupling Inversion 7 warns about. Absolute magnitudes on the bounded surfaces are ≤4 MB, so the honest reading is that S costs slightly more memory there and buys back time (1.9× faster).

### Friction 7 — span-only merge via dense views

**Cost:** 1.9× slower fold than T — the only axis on which S was the worst of the three. **Escapable, and already escaped:** S2 overrides `merge` alone → 3.6454 s / 16.1192 s (5.0× / 12.4× better than T), bit-identical across 155 assertions. Recorded because reporting S's V2 merge figures without the addendum inverts the arm's standing.

### Friction 8 — removing per-key partition state

**Gain:** no rebin (so R4 holds structurally), no out-of-range state, no cap to tune, no seed to be order-dependent about; every positive double indexable where T's geometry breaks. **Cost:** six locked D8 fields inert; a `-V` diff **stops being a valid gate** until A2/A3; D5's non-revisitable clause overridden; **R7 unresolved**.

**Not escapable — structural.** *Honest qualifier (F50):* three of the six inert fields are constants in every shipped run and pass trivially for T and S too. Genuinely discriminating fields lost: **3**. The arm-native substitutes preserve the *shape* of two more (`span_p50/p95/p99/max` for `rebins_per_partition`, `span_max` for `max_partition_bins`).

### Friction 9 (added) — the compact container against the memory instrument. **S and G pay.**

**Gain:** the smaller store itself. **Cost — two measured instrument failures that cut against the compact arms:**

- **`MEMORY\tunattributed` absorbing the delta** if the substrate moves where `Devel::Size` cannot walk. Rated "**a compact container is highly likely to hit it**", with in-tree precedent (`format_scan_subs` required a dedicated RSS-delta path). It **breaks silently** — nothing detects a `MEMORY\t*_counters` row vanishing.
- **RSS exceeds `Devel::Size` by 12.6–40.6% on every arm, surface and bpd, and the gap fraction is largest where the store is smallest** (F54). Tomcat @53: S 40.6%, G 39.3%; fan-out @53: T 18.4%.

**Partially escapable** — a dedicated RSS-delta path. The measurement discipline it forces is already established: **RSS at the scale being claimed, one arm per process**; never projected (51,469-key projections failed at fan-out by +68% to +385%), never from a multi-arm process (misreports by up to 47%).

---

## 7. Decisions the architect must take

Thirteen open items. Every one is re-decidable. None is foreclosed by anything in this document.

### 7.1 #187 Decision 5 — "the auto-resize lifecycle itself is not revisitable"

**Decision.** Does the per-key seeded partition with doubling and rebin remain mandatory, or may a representation without it be considered?

**Evidence pressuring it.** The same mechanism is the locked *virtue* for percentile accuracy and the locked *failure mode* for display (#201 Dimension B, #34 R5's "unrecoverable at render time"), **and** it is the sole cause of the R4 breach and of order-dependence. The clause forecloses G by its own words while its own second sign is measured against it.

**Magnitude.** ×10.3 time and ×5.6 memory across the ladder at 286,659 keys; 13 display anchors per 24 buckets; 2.10 bins at merge depth 15; 68–96% of merge groups order-dependent. Against: T ahead by an order of magnitude on Tomcat percentiles from bpd 115 up.

**Options.** *Keep as locked* — G is out of scope, T/S is the choice, and the R4/display costs are accepted and documented. *Amend to revisitable* — G becomes a candidate; costs A1/A2/A3 amendments, a blocking re-bless, and the R7 question (§ 7.2). *Amend narrowly* — declare the lifecycle revisitable only for the display-keyed surfaces, accepting two code paths on one substrate (Inversion 7's coupling warning).

### 7.2 #189 R7 — "a hard requirement, not an option … no global registry of partitions"

**Decision.** Does one shared log-spaced *index function* over independent counter rows constitute "a global registry of partitions"?

**Evidence pressuring it.** Both readings are defensible from the code as prototyped: the grid is shared, but the rows are independent and separately freeable, merge is an index-wise add touching neither source, and G's store holds no partition record at all — only `{row, key, bins}`.

**Magnitude.** Unquantified. **Nothing in the corpus decides it, and R7 appears in no amendment list anywhere** — it is either a non-issue or a blocking amendment, and no written artefact says which.

**Options.** *Rule it a non-issue* — record the reasoning on the issue and G proceeds. *Rule it a violation* — G is out regardless of § 7.1's outcome. *Defer* — the worst option: it must be decided **before any G implementation is scoped**, since it can invalidate the whole design after the work.

### 7.3 #187 R4 — the accuracy bound is not structural. **This is owed to shipped code regardless of arm.**

**Decision.** Amend R4's text (amendment **A4**, proposed not applied) to scope the bound to unmerged partitions, or to state the measured post-merge envelope.

**Evidence.** T (and S) breach it monotonically with merge depth: 2.1026 bins at depth 15, 48 → 98 of 1,000 cells, p95 crossing one bin by depth 3, and 2.06 bins even at bpd 616. Also two unmerged single-key breaches (@256, @616).

**Options.** *Amend the text* — cheapest; the contract then matches the code. *Fix the code* — no known fix within T's mechanism; the error is inherent to compounding midpoint re-projection. *Adopt G* — makes the original sentence literally true, at § 7.1 and § 7.2's cost.

### 7.4 The `-V` field set under a representation change (D8, A2/A3)

**Decision.** If a representation without rebin is adopted, what replaces the six inert D8 fields, **and in what order** — D8's locked contract covers field order, and the audit is silent on it.

**Magnitude.** 6 fields inert; 7 of 10 un-diffable; but only **3** genuinely discriminating fields are lost (F50 — three of the six are constants in every shipped run and pass trivially for T and S too). Arm-native substitutes preserve the shape of two.

**Options.** *Amend D8 with the span fields and a recorded order* — required by D8's own rule. *Keep the field names with inert values* — parses, but a `-V` diff stops being a gate. *Do not adopt* — the fields stay live.

### 7.5 Which end of the resolution ladder the accuracy weighting favours

**Decision.** Is the accuracy that matters the one at the coarse rungs or the fine ones?

**Magnitude.** G ahead by **3.19 points at bpd 16**; T ahead by **0.012 points at 616** — ~265:1 in absolute stakes, with the ratio favouring T. Both arms sub-1% on every band at 616 on both files.

**Options.** *Weight absolute error* — favours G. *Weight relative error at the tier actually used per surface* — favours T where the surface runs fine and G where it runs coarse. *Decline to weight* — then Friction 3 stays open and no arm can be preferred on accuracy.

### 7.6 The bpd-256 rank crossover and the exact-power-of-ten convention (R2)

**Decision.** For G, record a convention: closed form as-is (1 of 985 values, 38 of 857,480 observations index one low, at the closed bin's exact upper boundary, **zero attribution error**), or boundary-checked at ~2 extra `**` per add.

**Magnitude.** Tiny in error, but **the digest baseline depends on which is chosen** — it must be recorded before any baseline is blessed.

### 7.7 Is order-independence a property worth having? (C2)

**Decision.** #189 R5 promises only fixed-sequence determinism. Should insertion-order independence be *claimed*?

**Evidence.** T is order-dependent on 68–96% of merge groups with spread to 2.00 bins, and **the harness cannot detect it** because the order is deterministic for a given input. G is exactly order-independent.

**Magnitude.** Two `-g` runs on the same data always agree, so nothing user-visible breaks today. The exposure is that a change to iteration order — a hash-seed change, a key-ordering refactor — silently moves percentiles by up to 2 bins with no harness signal.

**Options.** *Claim it* — makes G's property a requirement T fails. *Explicitly decline it* — records the current state as intentional and closes the question. *Leave unstated* — the status quo, and the reason this dimension is unweighted in § 1.2.

### 7.8 The uncovered merge path (Inversion 7)

**Decision.** Does `-g × -mdm bin` get golden coverage before any container change lands?

**Evidence.** No `*-bin-consolidated` statistics-drift scenario exists; every `*-consolidated` scenario is raw-model. The audit calls it the "**highest-risk uncovered path**" — and it is exactly where T's 2.10-bin breach and 96% order-dependence live. Independently, every `hg-*`, `hl-histogram-*` and `heatmap-*` regression scenario carries `-dm raw`, fencing the render suite off the bin path.

**Options.** *Add coverage first* — the change then has a gate. *Change first* — the riskiest path stays unasserted through the change. **This risk is inherited by all three arms**, T included: staying put does not close it.

### 7.9 The memory instrument (Friction 9, G7)

**Decision.** Does `-V benchmark-data` get a dedicated RSS-delta path before a compact container lands?

**Evidence.** `MEMORY\tunattributed` silently absorbing the delta is rated "highly likely" for a compact container, with in-tree precedent. `counter_memory_bytes` is already **un-assertable on every arm** (2.7% spread on byte-identical input).

### 7.10 The adopt-by-reference aliasing (C7)

**Decision.** Should `ltl`'s empty-target adopt path become a copy?

**Evidence.** Undocumented shipped behaviour, safe only because `merge_log_message_entry_into_cluster` deletes the source slot immediately. No columnar row can reproduce it — S and G copy. A replacement must preserve **the delete**, not the aliasing.

**Options.** *Make it a copy in `ltl` first* — removes a latent hazard and eliminates the only T↔S divergence in the corpus. *Leave it and document the delete as load-bearing.*

### 7.11 D2's memory guidance is T-specific

**Decision.** Replace D2's ~212 MB-at-10⁵-keys guidance with a span-based model if S or G is adopted.

**Magnitude.** The guidance overstates S by ~2.3× (91 MB Devel / 57 MB RSS) and G by ~3.7×, and its implied bpd sensitivity (T ×5.77) is wrong for both (×1.23, ×1.36).

### 7.12 The `codebeamer` coverage gap

**Decision.** Does the fifth bin baseline get measured before any re-bless decision?

**Evidence.** `codebeamer-bin-data-model` is **NOT COVERED** — the prototype's parsers cannot read its bracketed `[293ms]` durations, which `ltl` reads through the format registry. It is unmeasured **in either direction**, not clean. A re-bless decision taken on four of five scenarios is taken on incomplete evidence.

### 7.13 Per-surface representation, or one substrate?

**Decision.** May different surfaces use different containers?

**Evidence.** The memory inversion (F55) means no single container is smallest everywhere: S is 12.7× smaller at fan-out and +42% larger at bucket-stats @616; G is smallest in 6 of 8 bucket cells but above T at DPM 616.

**Magnitude.** A per-surface choice takes each gain without its cost. The price is two code paths on the substrate all four surfaces currently share through `merge_bin_counter_entries` → `partition_rebin` — the coupling Inversion 7 identifies as already dangerous *with one* path, since merge is High-weight in two areas and unspecified in the other two.

**Options.** *One substrate* — accept whichever inversion the chosen arm carries. *Per-surface* — accept the divergence risk and the doubled merge surface. *Hybrid* — one container, per-surface tuning only (which is what D2's tiers already are).
