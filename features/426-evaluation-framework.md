# #426 evaluation framework — dimensions, weighting, presentation

**Status: derived from the corpus, NOT approved.** This document exists because the
2026-08-25/26 analysis drifted into asymmetry (recorded in
`features/426-per-message-statistics-store.md` § *Process error — framing drift*): a
different evaluation question had come to be applied to each arm, and the incumbent was
not being evaluated at all. The remedy is to fix the evaluation basis BEFORE rebuilding
the analysis, and to derive it from the specification corpus rather than from recollection.

Nothing here selects a direction. The weightings exist to direct where analytical effort is
spent — the architect's ruling, 2026-08-26: the quantitative view "is not sufficient to
decide on the direction, but can be used to influence where you spend the most time
looking". The dimension register and the weighting hierarchy are for the architect's review
and amendment before the symmetric three-arm analysis is built on them.


Reconciliation of three independently-produced pieces (dimension register, weighting hierarchy, presentation specification) into one record. Arms: **T** (today: dense per-key array, seeded per #187 D5), **S** (span-only columns, verbatim T geometry — P8+P9), **G** (one shared log-spaced grid — P10). The comparison is symmetric: T is a candidate, not a reference.

---

## Reconciliation of the two dimension vocabularies

Piece 1 produced a **74-row corpus-anchored register** (A1–M6) organised by contract source. Piece 2 produced a **14-row decision-axis set** (D1–D14) organised by what the corpus argues about across arms. Piece 3 produced a **third 14-row set**, also called D1–D14, with different content. These are three different *granularities*, not three competing lists — and the D1–D14 collision between Pieces 2 and 3 is a real hazard, since `D1` means "numerical accuracy" in Piece 2 and "output parity with today" in Piece 3.

**Resolution adopted here:**

- Piece 1's A1–M6 is the **register** — the full set of properties an arm must satisfy or be measured on, each anchored to a locked source. It is the authority on CONTRACT/QUALITY.
- Piece 2's axes are the **weighting axes** — the level at which weight can be argued per feature area. Renamed `W1`–`W14` to end the collision.
- Piece 3's axes are the **presentation axes** — the level at which a table row can be filled with a number. Renamed `P1`–`P14`.
- A crosswalk (below) maps all three. No dimension is dropped in reconciliation; anything present in one and absent from another is reported as a gap, not silently merged.

### Crosswalk

| presentation axis (Piece 3) | weighting axis (Piece 2) | register rows (Piece 1) |
|---|---|---|
| **P1** Output parity with today | W9 byte-identity | L1, D10, B6 |
| **P2** Accuracy vs oracle, unmerged | W1 numerical accuracy | B1, B3, B4, B5, A1, A2, A4, A6 |
| **P3** Accuracy after merge | W1 × W7 | B2, C3, F5 |
| **P4** Determinism / order-independence | W6 determinism | C1, C2, C4, C5 |
| **P5** Display fidelity | W2 shape/visual fidelity | D1–D12 (whole group) |
| **P6** Memory | W3 memory footprint | G3, G4, G5, G7, G9 |
| **P7** Fill / build cost | W5 per-line write cost | H1, H2, G1 |
| **P8** Percentile evaluation cost | W4 traversal/compute speed | H3, H5 |
| **P9** Merge and `-g` fold cost | W7 merge correctness (cost side) | H4, C6, G10 |
| **P10** Growth across the bpd ladder | W12 cardinality bound × W3 | G5, G6, I4, I2, I3 |
| **P11** Out-of-range / extreme inputs | W14 degenerate/edge safety | E1, E2, E6, E10, E11, F1, F2, F3 |
| **P12** `-V` observability | W10 observability | J1–J6 |
| **P13** Locked-decision impact | W11 contract/harness stability | K6, K8, K10, K11, K12, A3, A5, M1–M6 |
| **P14** Re-bless / adoption cost | W11 (cost side) | K1–K5, K7, K9, B6, L2–L8 |
| — *no presentation axis* | **W8 adaptivity to per-key range** | E4, E5, E7, E8, D11 |
| — *no presentation axis* | **W13 analyst tunability** | I1, I2, I3, I5, M3, M4 |

### Gaps found by the reconciliation

These are **real gaps**, verified as absent rather than differently-worded:

1. **W8 (adaptivity) has no presentation axis.** Piece 3's fourteen tables never ask "how tightly does this arm fit each key's range". This is the mechanism behind the resolution inversion in P2 and the anchor count in P5-2, but it is never measured as a dimension in its own right. Piece 1 independently ruled that "automatic adaptation" is not a free-standing corpus dimension — its locked content is the D5 *mechanism* (E4/E6) and three enumerated *benefits* (E5, G2, E1). **Resolution: no new table. Instead, the D5 benefits E5/G2/E1 must each appear as an explicit row somewhere** — E5 as the mechanism column in P5-2 (`distinct range anchors`), G2 as a stated precondition in §2 of the document, E1 in P11-1. Recorded as a checklist item, not a dimension.
2. **W13 (analyst tunability) has no presentation axis, correctly.** The architect ruled the tier table out of scope (`the resolution tiers themselves … are not in question`). It is a constraint the arms must not break, not an axis they compete on. Presented as a scope statement in §0, not a table.
3. **K12 (partition independence, #189 R7 — "a hard requirement, not an option") maps onto Piece 3's P13, but is not in P13's row list.** Piece 3's D13-1 enumerates F1, D1, D1A, D2, D3, D4, D5, D7, D8, R2, R4, R5, R6, R12 — **R7 is absent**, and R7 is the requirement most directly in tension with G's single shared grid. Piece 1 flagged this ("not flagged anywhere in the #426 amendment list"); the audit's own decision table lists R7 under `#189 R1–R12` without a per-arm verdict. **Resolution: R7 is added as a mandatory row of P13-1.**
4. **C7 (target-empty merge aliasing) and C8 (merge rebins invisible to telemetry) map to P9/P12 but appear in neither piece's table specs.** Both are undocumented shipped behaviours a replacement must preserve or deliberately fix. **Resolution: C7 becomes a row of P13-1 (`undocumented behaviour, arm must decide`); C8 becomes a row of P12-1.**
5. **D8 (render-stage duplication must be preserved, not fixed) has no home in Piece 3's tables.** It is a CONTRACT that a replacement can silently violate by "improving" the display. **Resolution: a row of P5-1's caption assertions.**
6. **Piece 2 marks W7 (merge) `not established` for area (c) and `N-A` for (d); Piece 1 marks C3 CONTRACT (#287 R2.3) and C5 a gap.** Not a conflict — different surfaces. #287 R2.3 binds message-stats; #189/#201 never bind it for percentile primitives or display. Both are recorded; the *shared code path* (`merge_bin_counter_entries` → `partition_rebin`) is what makes the asymmetry dangerous, and it is Tension 7 below.

### Disagreements between pieces, resolved

| disagreement | resolution | basis |
|---|---|---|
| Piece 2 weights **W8 adaptivity "Contested"** for area (a) and **"High — locked non-revisitable"** for (c); Piece 1 says adaptation is not a dimension at all | Both kept, at different levels. Piece 1 is right that "adaptivity" as an abstract virtue is unsourced; Piece 2 is right that #187 D5's lifecycle clause is locked and non-revisitable. The dimension is **the D5 mechanism**, and its weight is genuinely contested — that contest is item 2 of "What the corpus does not settle". | `features/187-histogram-bin-counter-percentiles.md:1334` — "The auto-resize lifecycle itself is not revisitable." |
| Piece 1 lists **C2 order-independence as QUALITY, explicitly not a contract**; Piece 2 lists W6 determinism as High but separates order-independence | Agree. C1 (fixed-sequence) is CONTRACT; C2 is QUALITY that T does not have. Scoring C2 as a contract would mis-score T as failing something never required. | `features/426-…md:924` — "**explicitly NOT claimed**" |
| Piece 3 says D13-1's source table has **"two arm columns (S, G) and no T column"** and must gain one | Confirmed and adopted. This is the symmetry payoff: T's honest R4 cell. | `features/426-…md:772` — R4 "Not amended. **Contradicted by #426 F25**" |
| Piece 3 treats **S2 as a presentation footnote**, Piece 2's evidence quotes S2 numbers inline | Adopted Piece 3's ruling: three arms, dual cells on merge/fold only. | — |

---

## Evaluation dimensions (derived from the corpus)

The full register. **CONTRACT** = a locked decision or stated requirement a replacement MUST satisfy (breaking it needs an architect amendment). **QUALITY** = a measured or valued property not locked. Every row is anchored to a file + heading + verbatim quote.

### A. Arithmetic and algorithmic

| # | dimension | operational definition | source | C/Q |
|---|---|---|---|---|
| A1 | In-bin interpolation rule | Does the arm reproduce the Prometheus `HistogramQuantile` walk (`ceil(q·N)`, low→high, log-interpolation) bit-for-bit? | 187 § *Decision 1* → "R4 uses the **Prometheus native-exponential `HistogramQuantile` in-bucket interpolation formula**" | CONTRACT |
| A2 | Rank convention (`rank_in_bin` as fraction) | Uses `rank_in_bin`, not bin-midpoint or lower edge | 187 § *Decision 1A* → "R4 uses `rank_in_bin` as the `fraction` parameter. Aligns with Prometheus and New Relic NrSketch; diverges from HdrHistogram and DDSketch" | CONTRACT |
| A3 | Cross-model divergence is deliberate | Raw uses `int()` nearest-rank, bin uses `ceil()`; cross-model equality is never a valid assertion | 426 Part 4 row 9 → "The two paths are **not** expected to agree; cross-model equality is never a valid assertion" | CONTRACT |
| A4 | Grid-agnosticism of the walk | The locked walk still computes correctly on the arm's geometry | 426 § F24 → "92/92 edge cases at both bpd on G" | QUALITY (evidence for A1) |
| A5 | No per-bin sample-count guard, ever | No `bin_count`/`total_N` threshold, no `rank_support` field | 187 § *Decision 3* → "**No per-bin sample-count guard in R4.** R4 returns Decision 1's formula output regardless of `bin_count` or the position of the target rank within the bin" | CONTRACT |
| A6 | Quantile domain coverage | Accepts any q in `(0,1)`; 12-quantile ladders servable | 187 § *R3* → "must accept any quantile in `(0, 1)`" | CONTRACT |

### B. Accuracy

| # | dimension | operational definition | source | C/Q |
|---|---|---|---|---|
| B1 | The one-bin bound and its **scope** ("structural, not empirical") | Every emitted quantile within one bin-width, uniformly across quantiles, derived from geometry | 187 § *R4* → "**Bin-resolution error** — bounded uniformly by partition geometry … The accuracy contract is **structural** … not empirical" | CONTRACT |
| B2 | Post-remap / post-merge retention (the scope B1 does *not* cover) | Does the bound hold after widen / rebin / merge? | 189 § *Revalidation under #426* → "R4's 'structural' bound is not met once a partition has been remapped"; 426 Part 4 row 10 → "T … within-one-bin down to **78%**; G holds **100.00%**. **Correction PROPOSED, NOT APPLIED**" | CONTRACT as written + QUALITY (measured gap) |
| B3 | Accuracy vs the exact oracle, per quantile, per bpd | Max/median deviation from `calculate_statistics` | 187 § *Decision 10* aspect 5 → "the operational accuracy validation" | CONTRACT (validation mandated) |
| B4 | Accuracy by key shape, and its reversal across the ladder | Is the advantage stable or does it flip? | 426 § F37 → "reverses across the tier ladder … at **bpd 16 G is better on both files** … **from bpd 115 up T is ahead on Tomcat**" | QUALITY |
| B5 | Accuracy at the motivating cardinality | Do the arms differ at all on the high-cardinality single-observation population? | 426 § F38 → "**573,026 of 573,318 compared cells are exact for both arms**" | QUALITY |
| B6 | Value-exact drift against committed baselines (re-bless size) | % of cells into T3 (>1%) across five `*-bin-data-model` baselines | 426 § F36 → "At bpd 53: **apache 21.8% T3, tomcat 15.9%, thingworx 31.7%**" | CONTRACT (blocking harness) |

### C. Ordering, determinism, merge

| # | dimension | operational definition | source | C/Q |
|---|---|---|---|---|
| C1 | Determinism, fixed sequence | Same input + flags + order ⇒ byte-identical | 187 § *R6*; 189 § *R5* → "All primitives are deterministic" | CONTRACT |
| C2 | Insertion-order independence | Does permuting arrival order change any value? | 426 Part 4 row 5b → "**explicitly NOT claimed**"; F27 → "T differs on 105/200 keys, up to 0.99 bins; G 0/200" | QUALITY (T lacks it) |
| C3 | Merge fidelity (merged ≡ from-scratch) | Merge equals feeding all samples into one store | 287 § *R2.3* → "observationally identical (up to the bin-resolution bound … and numerically identical on the sidecar-derived statistics)" | CONTRACT |
| C4 | Merge commutativity | `merge(A,B) == merge(B,A)` | 426 § *Merge semantics* → "**NOT claimed; measured false** (F27)" | QUALITY |
| C5 | Merge associativity | Order across ≥3 operands immaterial | 426 § *Not found / uncertain* → "**NOT claimed, not measured** anywhere" | QUALITY (gap) |
| C6 | Merge shape robustness | Rollup, disjoint spans, depth 1/3/7/15, permutations | Revalidation report § *Validation aspects* V8 | QUALITY |
| C7 | Target-empty aliasing | `$target->{partition} = $source->{partition};` by reference | 426 § *Merge semantics* → "**Undocumented anywhere.** A replacement must preserve or deliberately fix" | QUALITY (undocumented; arm must decide) |
| C8 | Merge rebins invisible to telemetry | Does the merge path undercount `total_rebin_events`? | 426 → "`total_rebin_events` and `rebins_per_partition` **undercount on every consolidated run**" | QUALITY (correction proposed, not applied) |

### D. Mass, fidelity, display geometry

| # | dimension | operational definition | source | C/Q |
|---|---|---|---|---|
| D1 | Mass conservation | Σ out == Σ in across capture, rebin, merge | 426 Part 4 row 1; 189 R12 *Invariants preserved* | CONTRACT (rebin) / observed (capture, merge) |
| D2 | No cross-bin mass splitting, any stage | Each source count wholly to one target bin | 34 § *R5 fidelity invariant* → "**No cross-bin mass splitting at any stage.** … No source bin's count may contribute fractionally to multiple targets" | CONTRACT |
| D3 | Geometric-midpoint projection only | `sqrt(lower × upper)` selecting one target bin | 201 § *Fidelity invariant*; 426 Part 4 row 4 (third context: `merge_bin_counter_entries` calls `partition_rebin` twice) | CONTRACT |
| D4 | Peak retention (Y-axis exact) | Peak count preserved at 1.0 | 201 § *(e) — Two-stage stream→finalize* → "`peak_retention = 1.0     [always — no count splitting]` **Y-axis is exact.**" | CONTRACT (mechanism) |
| D5 | Peak X-offset | Displacement bounded by `ceil(B_d × (R_s/B_s) / R_d)` | 426 Part 4 row 3; V6/V7 measured 0 columns | CONTRACT (algebraic) |
| D6 | Per-column, not aggregate, fidelity | Column-by-column comparison; spike-trough structure | 201 report → "**Aggregate metrics (mass, peak, X-offset) are not sufficient.** They can be satisfied while spike-trough structure is destroyed" | CONTRACT (validation method) |
| D7 | Empty-cell / narrow-spike artefacts | The rejected outcome | 201 § *Why finalize to legacy partition shape* → "produced 'narrow spikes with empty columns between' — visually wrong vs. legacy" | CONTRACT (rejected outcome) |
| D8 | Render-stage duplication preserved, not fixed | Display is deliberately non-mass-conserving (~2.86×) | 426 Part 4 row 12 → "shipped display sum 1,647,292 vs true raw 575,800 … duplication, not splitting; deliberately kept" | CONTRACT |
| D9 | Perceptibility threshold as the display target | ~11% of peak, not 1% | 201 report → "roughly **11% of peak** (each character row = 100/9 ≈ 11.1%)" | CONTRACT (judgement basis) |
| D10 | Display-cell identity across arms | Do two arms ever differ in one cell? | 426 § F33 → "**S is display-cell-identical to T on both display geometries**" | QUALITY |
| D11 | Range-anchor consistency (#201 Dimension B) | How many distinct anchors across sibling partitions | 34 R5 → "This range-anchor mismatch (Dimension B in #201's framing) is unrecoverable at render time"; 426 F34 → "**13 distinct range anchors across 24 buckets**" | QUALITY |
| D12 | Boundary-straddle at coarse resolution | Shared projection property or arm-specific? | 426 § F35 → "**T and G do this identically**" | QUALITY |

### E. Range, seeding, adaptivity, out-of-range

| # | dimension | operational definition | source | C/Q |
|---|---|---|---|---|
| E1 | Out-of-range semantics | Distinct over/underflow counters, both in `total_N`, boundary return, no interpolation | 187 § *Decision 4* → "Structurally distinct from the highest finite bin … No interpolation inside overflow" | CONTRACT (goes vacuous under G) |
| E2 | Per-quantile audit enum | `out_of_range_bounded: high\|low\|none`, per quantile not per partition | 187 § *Decision 4* → "The field name and the three-value enum are part of the locked feature contract"; 189 R6 → "Consumer tests must not assert `audit = high` for every quantile" | CONTRACT |
| E3 | Cross-key audit aggregation (`high > low > none`) | How codes aggregate into telemetry | 289 § *Consumer* → "worst-of `high`>`low`>`none`" | CONTRACT (surface-local; doc gap) |
| E4 | Seeding as an explicit design property | Lazy on first observation, span centred on `v_0` at 5 decades | 187 § *Decision 5* → "**The seed heuristic is revisitable from telemetry** … **The auto-resize lifecycle itself is not revisitable.**" | CONTRACT — G overrides a non-revisitable clause |
| E5 | Per-key range tightness | Bin budget spent on the key's own range | 187 § *Why this lifecycle* → "**Tighter per-key resolution.**" | CONTRACT (stated rationale for D5) |
| E6 | Growth on far-outside values | Extend by `10^(decades/2)` vs pure function of value | 187 § *Decision 5 implementation guidance*; § *Decision 4* → overflow "function primarily as a safety net" | CONTRACT |
| E7 | Rebin cost / amortization | Total events, per-partition distribution, amortized O(N) | 187 § *Decision 5 Contract F1* → "amortized O(N) total rebin cost" | CONTRACT |
| E8 | Seed health signal | `rebins_per_partition.p99` in 0–2 | 187 § *Implementation guidance* → "**Healthy-seed signal**" | QUALITY |
| E9 | The observed-range `[min,max]` clamp | Percentiles clamped to sidecar min/max | 289 § *Consumer*; 426 § F39 → "at most **1.046×** against a bin width of **1.044×** … **any representation must keep it**" | CONTRACT (harness-enforced) with authorship gap |
| E10 | Non-positive value handling | Undefined at primitive level; caller `> 0` guard is de-facto contract | 426 § F28 → "**The `v > 0` guard is load-bearing for every representation.**" | CONTRACT (de-facto) / documented gap |
| E11 | Index convention at exact decade boundaries | Off-by-one at exact powers of ten | 426 § F29 | QUALITY (arm-specific defect class) |

### F. Degenerate input and degradation

| # | dimension | operational definition | source | C/Q |
|---|---|---|---|---|
| F1 | Degenerate-input behaviour | Zero ⇒ `-`; all-same ⇒ single bin, every percentile equals it; small N well-defined | 187 § *R5* | CONTRACT |
| F2 | `lower = upper` is reachable | An arm may not declare this unreachable | 426 § *Citation cross-check* A9 → "It would contradict **#187 R5**" | CONTRACT |
| F3 | Boundary-equal assignment determinism | Documented, consistent bin for a value on a boundary | 189 § *Edge cases* | CONTRACT |
| F4 | Degradation mode — graceful vs cliff | Smooth with resolution, or non-monotonic/resonant? | 201 report → "**Non-monotonic behavior is real.** Higher bpd is not always better"; proportional-overlap "regresses catastrophically (1155%)" | QUALITY (decisive in #201's rejection) |
| F5 | Error-model provenance separation | Tier-table midpoint error characterises interpolation, not remap (14–72× larger) | 201 report → "roughly 14× to 72× larger. The Decision 2 tier table was calibrated for the **percentile interpolation** use case, not for **partition→partition re-binning**" | QUALITY |

### G. Streaming, memory, scaling

| # | dimension | operational definition | source | C/Q |
|---|---|---|---|---|
| G1 | Single-pass, no raw retention | No per-line value array survives | 34 § *R4* → "No per-line value array is allocated" | CONTRACT |
| G2 | No prior-run / index dependency | Correct on a first invocation over historical data, one pass | 187 § *Why this lifecycle* → "on the *first* run, in a single pass, in memory-safe form" | CONTRACT |
| G3 | Bounded memory per key | O(partition), not O(samples) | 287 § *R10* → "bounded by `O(partition_size)` rather than `O(sample_count_per_key)`" | CONTRACT |
| G4 | Absolute per-key cost, measured | `Devel::Size` and RSS at production cardinality | 426 § F31 → T 2,381 B, S 955, G 600 | QUALITY |
| G5 | Memory scaling across the bpd ladder | Growth 53 → 616 — *the constraint #426 exists to move* | 189 § *Revalidation* → "T grows 5.8× from bpd 53 to 616, S 1.2×, G 1.4×" | CONTRACT (locked objective) |
| G6 | Cardinality scaling | Unbounded partition counts on the per-message surface | 201 § *Per-family bpd contract* → "F1 cannot use bpd=616 because the partition count is unbounded" | CONTRACT |
| G7 | Memory-attribution walkability | Can `Devel::Size` still name the store, or does it fall into `unattributed`? | 426 § *Breaks SILENTLY* → "**A compact container is highly likely to hit it.**" | QUALITY (instrument integrity — high risk) |
| G8 | Per-key freeability | Lookup-able, enumerable, independently freeable | 189 § *R8* → "Counter stores per key are independently freeable" | CONTRACT |
| G9 | Fill-direction sensitivity | Same span, different arrival order, different memory | 426 § F32 → "3–4× for the same span" | QUALITY (arm-specific) |
| G10 | Deletion / churn cost under `-g` | Tombstones, compaction, restructuring | 426 § *Open questions* Q4; F22 → "**Columnar tombstoning is slower than hash deletion in bin mode**" | QUALITY |

### H. Processing time

| # | dimension | operational definition | source | C/Q |
|---|---|---|---|---|
| H1 | Per-line write cost | ns/line for bin assignment + counter update | 426 § *Open questions* Q2; § *Measurement protocol* | QUALITY |
| H2 | Bin-assignment algorithm cost | Closed-form vs binary vs linear; boundaries stored or derived | 189 § *R2* → "efficient enough to invoke per-line in the parsing hot path"; storing boundaries "adds ~4.75× memory" | CONTRACT (per-line efficiency) / QUALITY (algorithm) |
| H3 | Read-side traversal and comparator | Population walk and sort cost | 426 § *Open questions* Q1 | QUALITY |
| H4 | Merge and `-g` fold cost | Time in consolidation | Revalidation report V2 | QUALITY |
| H5 | Benchmark regression gate (≤5%) | Any metric worse by >5% is stop-and-investigate | CLAUDE.md § *Per-feature workflow* step 1b | CONTRACT (process gate) |

### I. Resolution and the precision lever

| # | dimension | operational definition | source | C/Q |
|---|---|---|---|---|
| I1 | Precision as a query-time analyst lever | Run-time choice, not a recording-time constant | 187 § *F1* → "`buckets_per_decade` is the analyst's lever" | CONTRACT |
| I2 | The tier ladder is source of truth | One `-dmp` lever, 1..9, default 5 | 293 § *Precision-tier → bins-per-decade*; 187 D2 amendment | CONTRACT |
| I3 | Per-surface resolution independence | Only algorithm, lifecycle, in-bin rule, out-of-range are uniform | 187 § *Decision 2 (amended)* → "legitimately per-surface" | CONTRACT |
| I4 | The 53-vs-616 cardinality constraint | Does the arm let an unbounded surface run at display resolution? | 189 § *#426 objective locked 2026-08-25* → "The resolution tiers themselves … are **not in question**" | CONTRACT (locked objective + out-of-scope) |
| I5 | Tier-table cells are a tested contract | `assert_surface_bpd`, 16 exact cells | 426 § *Harnesses* | CONTRACT |

### J. Observability

| # | dimension | operational definition | source | C/Q |
|---|---|---|---|---|
| J1 | `-V` field-name **and field-order** stability | Section name, field names, consumer names, and order are locked | 187 § *Decision 8 Contract*; 426 A3 → "**silent on D8's locked field *order***" | CONTRACT |
| J2 | Field-set liveness | Does the arm render a locked field meaningless? | 426 § F30 → "D8 survives S unchanged; **five fields are inert under G**" | CONTRACT (breaking a field's meaning) |
| J3 | Rebin telemetry as a contract surface | The empirical-tuning instrument | 187 § *`-V` rebin telemetry — contract surface* | CONTRACT |
| J4 | `counter_memory_bytes` as the memory instrument | Does the footprint stay measurable through the shipped instrument? | 426 → "`Devel::Size::total_size($store)` and therefore **moves by construction on any container change**" | QUALITY (instrument fidelity) |
| J5 | `-V` is a testability surface; `-V` creates no demand | Grep-stability over readability; emitting `-V` must not cause capture | 187 § *Decision 8* → "Reader-friendliness is secondary to grep-stability"; 305 → "**-V creates no demand**" | CONTRACT |
| J6 | L3-oracle machine-readability | Oracle reads `effective_algorithm` / `effective_bpd` | 224 § *Layer 3* | CONTRACT |

### K. Test, validation, adoption

| # | dimension | operational definition | source | C/Q |
|---|---|---|---|---|
| K1 | L2 intra-row invariants | Monotonicity, `min ≤ p1`, `p99999 ≤ max`, `iqr == p75 − p25` | 224 § *Decision 4* | CONTRACT |
| K2 | Three layers, none skippable | L1 drift + L2 arithmetic + L3 oracle | 224 § *Decision 3* → "**A skipped layer would produce a false-pass result, which is worse than no test.**" | CONTRACT |
| K3 | Cross-model comparison is NOT a validation axis | Raw-vs-bin agreement asserts nothing | 224 § *Layer 3* → "a tolerance on their difference would assert nothing meaningful" | CONTRACT |
| K4 | Coverage gaps the arm inherits | Bin renders, bin shape moments, bin consolidation merge | 426 § *Breaks SILENTLY* → "**Bin heatmap AND bin histogram renders** — zero golden coverage"; "**Highest-risk uncovered path.**" | QUALITY (risk exposure) |
| K5 | Runtime-warning cleanliness | Any Perl warning is a hard failure, first | 426 § *Harnesses* → "**fires before anything else**" | CONTRACT |
| K6 | Prototype-before-implementation gate | Five aspects re-run before any production code | 187 § *Decision 10*; 189 § *Revalidation under #426* | CONTRACT |
| K7 | Adoption cost / blast radius | Call sites, `-V` emitters, harnesses, docs, decisions | 426 § *Part 3* → "**14** `counter_update` sites"; 7 loud + 10 silent breakage classes | QUALITY |
| K8 | Locked decisions invalidated or made vacuous | Which of F1/D1/D2/D3/D4/D5/D7/D8/R4/R5/R6/R7/R12 need amendment | 426 § *Decisions that go vacuous* | CONTRACT (amendment is the price) |
| K9 | Serialization / on-disk migration surface | Does any bin state reach disk? | 426 § *Serialization — none* → "**A container change has zero on-disk migration surface.**" | CONTRACT (holds for all arms) |
| K10 | Primitive-set integrity | R1–R12 intact and unit-testable, not forked | 189 § *Acceptance criteria* → "without forking, duplicating, or extending them" | CONTRACT |
| K11 | Store-shape freedom (the enabling clause) | The contract is the operation, not the structure | 189 § *R3* → "**The contract is the operation, not the data structure.**" | CONTRACT (what permits any change) |
| K12 | **Partition independence across consumers and keys** | Each `(consumer, key)` holds its own partition; no global registry | 189 § *R7* → "**This is a hard requirement, not an option** … The primitives impose no global registry of partitions." | CONTRACT — **directly at risk under G** |

### L. Surface integration

| # | dimension | operational definition | source | C/Q |
|---|---|---|---|---|
| L1 | `-mdm raw` / `-bdm raw` byte-identity | Raw path byte-identical | 287 § *R12*; 289 § *What the user observes* | CONTRACT |
| L2 | Demand gating compatibility | Capture/compute/storage gateable; undemanded fields never written | 305 § *The demand contract* | CONTRACT |
| L3 | Demand output-compatibility invariants | Demand-off byte-identical; CSV column set never changes | 305 § *Output-compatibility invariants* | CONTRACT |
| L4 | Sidecar statistics stay numerically exact | min/max/mean/std_dev/skew/kurt/BC from sidecars, float-exact | 287 § *R3.2*, *R11* | CONTRACT |
| L5 | Selector resolution chain | Per-surface flag > `-dm` > internal logic | 266 § *Resolution at each call site* | CONTRACT |
| L6 | Render-surface independence | CSV content deterministic per input, independent of geometry | 289 § *Render-surface independence* | CONTRACT |
| L7 | Concurrency posture | Single-threaded; no locking | 189 § *Edge cases* | CONTRACT (uniform) |
| L8 | User-facing doc claims about container shape | Prose commitments that break on a representation change | 426 § *User-facing documentation to update*, quoting `docs/explain/statistics.md` → "one partition per logical series, with a fixed bin footprint per partition" | CONTRACT |

### M. Industry grounding

| # | dimension | operational definition | source | C/Q |
|---|---|---|---|---|
| M1 | Prometheus `+Inf` adopted verbatim | Overflow semantics are a named-source commitment | 187 § *Decision 4* | CONTRACT |
| M2 | HdrHistogram extension over OTEL downshift / DDSketch collapse | Resolution preserved by extending, never collapsing | 187 § *Source citations* → "DDSketch's collapsing-store variant introduces resolution loss … ltl preferred HdrHistogram's purer extension semantics" | CONTRACT |
| M3 | 616 = HdrHistogram 3-sig-digit reference, out of scope | External anchor | 189 § *#426 objective locked* → "revisiting it is out of scope for #426 (architect, 2026-08-25)" | CONTRACT |
| M4 | 53 = OTEP-149 Scale-4 analog | "distinguishes a 5% real regression from bin noise" | 187 § *Decision 2 Contract* | CONTRACT |
| M5 | Unconditional substrate posture | No runtime mode gate inside a migrated surface | 187 § *Decision 6 — DISSOLVED* | CONTRACT |
| M6 | Per-stream-in-fan-out is a documented novel divergence | No library documents this lifecycle; grounding does not preclude a fan-out-specific representation | 187 § *Divergence from industry-standard single-stream lifecycle* → "ltl's adaptation is structurally novel" | CONTRACT (an explicitly open door) |

### Rejected as dimensions (with reasons)

- **"Order dependence" as a requirement** — the corpus supports it only as QUALITY and explicitly disclaims it (C2). Scoring it as a contract mis-scores T as failing something never required.
- **"Automatic adaptation" as a free-standing virtue** — what is locked is the D5 *mechanism* (E4/E6) and its three enumerated *benefits* (E5, G2, E1). Scoring "adaptation" abstractly smuggles D5's mechanism in as its own justification.
- **"Reprojection" as a dimension of merit** — it is a mechanism T and S require and G does not. The symmetric question is its consequences: B2, D1–D5, F5, C8, H4.
- **"Display fidelity" as one item** — the corpus separates aggregate metrics (D1/D4/D5, measured insufficient) from per-column structure (D6/D7/D10) at cost. Merging them reproduces the V6/V7 error that forced #201's re-lock.

---

## Weighting by feature area

Weight is assigned only where the corpus supplies a grounding signal: a locked `Dxx`, a MUST or "hard requirement", a validation aspect built to measure it, an investigation opened because it went wrong, a stated numeric bound, or language naming something as the point or the failure mode. Where the corpus is silent, the cell reads **not established** — that is a finding, not a blank.

Axes are Piece 2's, renamed W1–W14 to avoid the D-collision.

| axis | (a) container / data model #426 #287 | (b) statistics calc #224 #305 #254 | (c) percentile calc #187 #189 #293 | (d) histogram / display #34 #201 |
|---|---|---|---|---|
| **W1** numerical accuracy | Medium *(F38 neutral / F36 large)* | **High** | **High** | **High** *(as visibility threshold)* |
| **W2** shape / visual fidelity | N-A | N-A *(different sense: moments)* | N-A | **Highest** |
| **W3** memory footprint | **High, demoted below W4** | Medium-High | **High** | **Low — explicitly subordinated** |
| **W4** traversal / compute speed | **High — primary justification** | **High — via not computing** | Medium | not established |
| **W5** per-line write cost | **High, as a gate** | Medium | Medium | Medium |
| **W6** determinism | **High** (order-independence NOT required) | **High** (float-order tolerance) | **High** | **High** |
| **W7** merge correctness | **High** | **High** | Low specified / **High** discovered | N-A specified / discovered gap |
| **W8** adaptivity to per-key range | **Contested** | not established | **High — locked non-revisitable** | **Inverted — a liability** |
| **W9** byte-identity | **High** | **High** | Medium — explicitly not for values | **High** (geometry) |
| **W10** observability / `-V` | Medium | Medium | **High** (locked names) | **High** |
| **W11** contract / harness stability | **High** | **High** | **High** | **High** specified / **absent** in practice |
| **W12** cardinality bound | **High — the constraint** | not established | **High — the constraint** | **High — the enabler** |
| **W13** analyst tunability | Out of scope by ruling | Medium | **High** (F1: the analyst's lever) | Medium (display knob only) |
| **W14** degenerate / edge safety | **High** | **High** | **High** | Medium |

### Selected evidence for the High cells

- **(a) W4** — 426 § *Motivation*: "**As-built entry layout costs ~5× on keyed traversal and ~2× on the population walk, in both versions.**" F43: at bpd 616, percentile evaluation T 181.348 s vs S 2.281 s.
- **(a) W3 demoted** — 426 § *Memory decomposition*: "the memory upper bound for replacing the entry hash is ~46% of this store, not 100% … **the memory case is secondary and smaller than the raw per-key figure suggests.**"
- **(a) W12** — 426 Part 1: "**message-stats is the only surface whose partition count is unbounded by anything structural. This is the whole memory profile #426 exists for.**"
- **(b) W1** — 224 § *Background*: "**Wrong methodology** … **because yesterday's value was also wrong**"; 254: "**A regression in the moment math could ship undetected. This harness is the dedicated guard.**"
- **(b) W11** — 224 Decision 5: "**Partial coverage is forbidden — the engine refuses to start if any qualifying column is excluded.**"
- **(c) W8** — 187 D5: "**Tighter per-key resolution** … **The auto-resize lifecycle itself is not revisitable.**"
- **(c) W3** — 189 R2: storing boundary arrays "adds ~4.75× memory at locked default bpd=53 (51,469 partitions: 117 MB closed-form vs. 555 MB with boundary arrays)".
- **(d) W2** — 34 § *R5 fidelity invariant*: "**Memory savings are not worth fidelity loss** … If a candidate implementation reduces memory but smooths the histogram, **the candidate is wrong** … **do not accept the smoothing as a trade.**"
- **(d) W3 Low** — 201 § *Memory cost*: "~25KB per streaming partition × ~70 total F2/F3 partitions ≈ 1.75MB streaming overhead — negligible vs. raw retention."

### Conflicts and inversions between areas

**Inversion 1 — memory vs fidelity (W3 × W2). The sharpest in the corpus.**
Display (d) forbids the trade the container area (a) exists to make. (d): "Memory savings are not worth fidelity loss." (a) trades exactly that (F43: at bpd 616, 79.5× and 12.7×). The conflict is bounded by (d) having ~70 partitions and ~1.75 MB — no memory problem to trade against — but **any shared substrate change must not carry (a)'s memory-first weighting into (d)**.

**Inversion 2 — per-key adaptivity is a locked virtue in (c) and the locked failure mode in (d) (W8).**
(c): "Tighter per-key resolution … The auto-resize lifecycle itself is not revisitable." (d): the same anchoring is "unrecoverable at render time" (#34 R5, quoting #201 Dimension B). (a) measures both signs at once — F34 (global anchor measurably better on the heatmap's keying: G median 0.0667% / max 0.2333% against T 0.2667% / 0.4583%) against F37 (from bpd 115 up T is ahead on Tomcat, mechanism = seed adaptivity growing with resolution). **This inversion is the whole T-vs-G decision.**

**Inversion 3 — the accuracy bound is "structural" in (c) and measured non-structural once (a)'s merge path runs (W1 × W7).**
(c) 187 R4: "structural … not empirical". Discovered: 426 Part 4 row 10 "**C as written; measured false**"; 189 § *Revalidation*: "not met once a partition has been remapped … up to ~2 bins after merges". **The correction is proposed, not applied.**

**Inversion 4 — resolution is per-surface-legitimate in (b)/(c) but pinned by (d).**
187 D2 as amended calls the precision parameter "legitimately per-surface"; 426 § *Framing correction* says "**`buckets_per_decade` 616 is not a tunable knob** … out of scope for this issue". W13 is High for (c) and effectively frozen for (a) and (d).

**Inversion 5 — byte-identity is required in (a)/(b)/(d) and explicitly waived in (c).**
187 R11 waives it for percentile values; 287 R12, 305, and 34 R8 require it. **A container change inherits the strict reading, not (c)'s tolerant one, because (a) is not migrating an algorithm.**

**Tension 6 — (a)'s speed goal is bought at exactly the site (b) declares must not regress (W4 × W5).**
(a): "Sets the heap layout every later pass pays for. **Any change here is measured before it is believed.**" (b) gates the same loop: `duration_count` and `_running_mean` "stay unconditional". A container that fuses columns must preserve "undemanded fields are never written, and absent fields read as `undef`".

**Tension 7 — merge is High in (a)/(b), unspecified in (c)/(d), yet all four share one code path.**
"No document states mass conservation as an invariant for … `merge_bin_counter_entries`"; "No **associativity** claim for merge anywhere." Yet it is the "**Highest-risk uncovered path.**"

**Tension 8 (added in reconciliation) — K12 partition independence vs G's construction.**
189 R7 is "a hard requirement, not an option … The primitives impose no global registry of partitions." G is by construction one shared grid. Whether G's grid counts as a "global registry of partitions" or merely a shared *index function* over independent counter stores is **not resolved anywhere in the corpus**, and it is not in the audit's amendment list. This is either a non-issue or a blocking amendment, and nothing written settles which.

---

## What the corpus does not settle

These require the architect. No document establishes them.

1. **The relative weight of accuracy (W1) against memory + speed (W3+W4) on the per-message surface.** Both halves exist and are never ranked: F38 ("accuracy-neutral" at the 287k fan-out) and F36 ("apache 21.8% T3, tomcat 15.9%, thingworx 31.7%"). Whether a 16–32% T3 re-bless buys 8.4×/2.2× is unstated.
2. **Whether per-key adaptivity (W8 / E4) survives as a value or is retired.** #187 D5 says "not revisitable"; #426 A1 says the proposal "overrides a non-revisitable clause — architect-level, not pre-authorized tuning". The corpus records the conflict and refuses to resolve it.
3. **Merge associativity and post-merge accuracy as contracts.** No associativity claim anywhere; no accuracy bound scoped "after N merges" other than F25, "which is a finding, not a locked contract".
4. **Whether insertion-order independence is a value at all.** "Explicitly NOT claimed" — so G's advantage on it is unweighted.
5. **The `[min,max]` clamp's authority on the message-stats surface.** Documented only on bucket-stats; "no #187-level statement authorises the clamp" — yet it fires on 9.2% of cells and "any representation must keep it".
6. **Whether a locked `-V` field going *inert* (rather than wrong) is acceptable, and whether D8's locked field *order* is at stake.** F30 (five fields inert under G) plus A3's noted omission.
7. **The `MEMORY` attribution rule after the container changes.** Q11 deferred; the silent-break risk is "highly likely".
8. **Whether bucket-stats gets its own weighting.** "Under S and G it is a **third shape**" — neither an F1 fan-out surface nor an F2/F3 display surface.
9. **The merge-surface shape (Q5) and the F7 arbitrary-key-set write (Q6).** Both deferred to implementation planning.
10. **The W2 weight for the bin-mode renders.** High by (d)'s invariant, but "zero golden coverage" — so no threshold exists to weigh a change against (filed as #450, out of scope here).
11. **(added) Whether G's shared grid violates #189 R7.** See Tension 8. Not raised anywhere in the corpus; must be decided before any G implementation is scoped.

---

## Presentation plan

### Document

`prototype/426-representation-comparison.md` — a reader's document, distinct from `prototype/426-bin-primitives-revalidation-report.md`, which stays intact as the aspect record and citation target.

| § | Section | Contents | Why it earns its place |
|---|---|---|---|
| 0 | What this is / is not | Three candidate containers; the same questions asked of all three; T is a candidate, not a reference; this quantifies, it does not decide. Names the out-of-scope ruling (tier table, 616, display geometry). | Sets the symmetry contract and the non-decision contract up front. |
| 1 | The three arms | Mechanism / what it stores / what it does not have, plus the S2 note. One paragraph naming the precision lever (`10^(1/bpd) − 1`: 4.44% @53, 2.02% @115, 0.90% @256, 0.37% @616). | Placing bin width here makes every later accuracy number self-scaling. |
| 2 | Evidence base and its limits | Surfaces × fixtures × bpd actually measured, plus the **Not measured** list verbatim from the aspect record. | Symmetry is only credible if the coverage grid is shown; pre-empts absence-of-evidence readings. |
| 3 | Summary table 1 — dimension × arm | 14 rows (P1–P14) × 3 arms + a `ranking stable?` column + `detail` links. | One-screen orientation. The stability column is what stops it lying. |
| 4 | Summary table 2 — surface × arm | 4 surfaces × 3 arms, each cell three tokens `acc / mem / time`. | Makes the by-surface inversion structural rather than a footnote (F55). |
| 5 | Per-dimension detail, P1–P14 | Each: the question, the tables, a *mechanism* paragraph, an explicit measured-where / not-measured-where line, and an evidence-strength line. | The body. |
| 6 | Per-methodology profiles M-T / M-S / M-G | Same 14 rows, this arm's numbers by surface and bpd, plus "what only this arm gives you" and "what this arm cannot do". | Reading down one arm answers "what am I buying / giving up", which dimension-major never answers. |
| 7 | Inversions and frictions | The three inversion families and the frictions grid. | Trade-offs stated, not left to cross-referencing. |
| 8 | The cost of choosing each arm | Re-bless volume, decisions amended, `-V` fields lost, harness impact, implementation surface. **T's row is filled, not blank.** | Symmetry: "keep today" has a cost column too. |
| 9 | Where to look hardest | Reading order, not a score (see below). | The architect's stated use for the quantitative view. |
| 10 | Open questions this evidence cannot settle | The eleven items above, as questions. | Prevents the document reading as complete. |
| A | Appendix — capture index | Dimension → table → capture file path. | Every number traceable; keeps per-table `source` columns terse. |

§4 sits with §3 rather than in the body because the surface inversion is a summary-level fact — deferring it would let §3 read as a global ranking.

### Arms and the S2 ruling

The evidence carries four store implementations: T, S (dense-view merge), **S2** (native span merge, overrides `merge` alone), and G. S2 is not a fourth candidate — it is how P9's merge is implemented. **Present three arms; wherever a merge or fold cost is reported, the S cell carries two numbers (`S 34.36 → S2 3.65`) with a persistent footnote.** Suppressing S(dense-view) hides the measurement history; suppressing S2 misreports P9. T and G each have one implementation, so their cells carry one number — the rule is applied identically to all three.

### Presentation axes (rows of every dimension-major table)

`P1` output parity · `P2` accuracy unmerged · `P3` accuracy after merge · `P4` determinism / order-independence · `P5` display fidelity · `P6` memory · `P7` fill cost · `P8` percentile evaluation cost · `P9` merge and fold cost · `P10` growth across the ladder · `P11` out-of-range and extremes · `P12` `-V` observability · `P13` locked-decision impact · `P14` re-bless / adoption cost.

P1, P12, P13, P14 have a structurally trivial answer for T. **State those cells explicitly as "trivially — T is the baseline", never blank and never `n/a`.** A blank reads as unmeasured; the explicit statement is what makes T's zero on P14 legible as a real advantage rather than a framing artefact.

### Table specifications

Every table carries a `source:` line naming its capture files. Tables whose data does not exist are marked **NOT FILLABLE** with what is missing.

| table | rows | columns | notes |
|---|---|---|---|
| **T-1** dimension × arm | P1–P14 | `Dimension` \| `T` \| `S` \| `G` \| `Ranking stable?` \| `Detail` | Cells are verdict tokens (`=` `+` `−` `~` `∅`) plus at most one anchor number — never a bare number. `Ranking stable?` ∈ `stable` / `inverts by surface` / `inverts by resolution` / `inverts by data shape`; any non-`stable` value forces the reader to §7. |
| **T-2** surface × arm | message-stats, bucket-stats, heatmap, histogram | `Surface` \| `cardinality profile` \| `T` \| `S` \| `G` \| `the inversion here` | Three tokens per cell: acc / mem / time. |
| **P1-1** parity ledger | one parity scope each | `scope` \| `fixture` \| `bpd` \| `compared` \| `T↔S` \| `T↔G` \| `assertions` | `T↔G` is `differs by design` on every row — **include the column anyway**; omitting it makes the table an S-only artefact. |
| **P2-1** accuracy by resolution | (file, key-shape band) | `file` \| `band (N × spread)` \| `bpd 16 T/G` \| `53` \| `115` \| `616` \| `crossover` | Mean error %, winner bolded per cell. **S column omitted with a standing header line** "S = T on every cell (P1)" — the omission must be stated, not silent. |
| **P2-2** bound conformance | (bpd, scope ∈ key/small/pair/fold) | `bpd` \| `bound 10^(1/bpd)−1` \| `scope` \| `T binning_max` \| `T within 1 bin` \| `G …` \| `pass/fail` | |
| **P3-1** merge-depth ladder | depth 1, 3, 7, 15 | `depth` \| `T max err (bins)` \| `T cells > 1 bin` \| `S` \| `G max err` \| `G cells > 1 bin` | S = T; state once in the caption. |
| **P4-1** order-independence | (fixture, bpd, shape) | `fixture` \| `bpd` \| `shape` \| `T groups differing` \| `T max spread (bins)` \| `S` \| `G` | Shapes: insertion order, pairwise commutativity, 8-key permutation. |
| **P5-1** display fidelity, aggregate | (file, geometry, bpd) | `file` \| `geometry` \| `bpd` \| `T/S abs_dev_pct` \| `T/S max_cell_dev` \| `G …` \| `winner` | Caption asserts D2 (no splitting), D4 (peak retention 1.0), **D8 (duplication preserved)**. |
| **P5-2** per-time-bucket keying (#201 Dim B) | (file, bpd, arm) | `file` \| `bpd` \| `arm` \| `median %` \| `p95 %` \| `max %` \| `mean %` \| **`distinct range anchors`** | The anchor column (13 across 24–25 buckets for T/S; 1 for G) is the *mechanism* column and is mandatory — it also discharges register row E5. |
| **P6-1** memory, unbounded surface | (bpd, arm) | `bpd` \| `arm` \| `keys` \| `Devel::Size B/key` \| `RSS B/key` \| `store MB` \| **`RSS/Devel gap %`** | Gap column mandatory (F54: 12.6–40.6%, largest where the store is smallest — it cuts against the compact arms). Caption carries F52/F53: RSS is valid only one-arm-per-process at scale. |
| **P6-2** memory, bounded surface (the inversion) | (file, bpd) | `file (rows)` \| `bpd` \| `T RSS/Devel` \| `S RSS/Devel` \| `G RSS/Devel` \| `S vs T` | |
| **P7-1 / P8-1 / P9-1** cost | (surface, fixture, bpd, arm) | `surface` \| `fixture (scale)` \| `bpd` \| `arm` \| `median` \| `[min, max]` \| `per-unit` \| `vs T` | per-unit: ns/sample, µs/eval, µs/merge. P9's S rows carry two lines (S dense-view, S2 native). Fill-subtracted figures flagged as such (F12). |
| **P10-1** growth across the ladder | arm | `arm` \| `pct time @53` \| `@616` \| `×` \| `memory @53` \| `@616` \| `×` \| `fold cost ×` | Smallest and most decision-relevant table: the locked objective is what the container change does to the constraint, and the constraint *is* the multiplier. |
| **P11-1** extremes and invalid inputs | input class (`0`, `−5`, `1e-320`, `1e308`, all-overflow, all-underflow, 18-decade key) | `input` \| `T` \| `S` \| `G` \| **`reachable from ltl?`** | Last column essential — several rows are unreachable behind the `> 0` guard (E10), and without it the table over-weights impossible differences. Also carries E1 overflow-as-safety-net and F1/F2 degenerate cases. |
| **P12-1** `-V` field survival | the 10 locked D8 fields, **plus a `merge-rebin telemetry` row (C8)** | `field` \| `T` \| `S` \| `G` \| **`discriminating in shipped ltl?`** | Last column carries F50: three fields are constants in every shipped run and pass trivially for *any* arm. Without it a reader counts "S 10/10, G 4/10" and over-weights it. **Field *order* (J1/A3) asserted in the caption.** |
| **P13-1** locked-decision impact | F1, D1, D1A, D2, D3, D4, D5, D7, D8, R2, R4, R5, **R7**, R12, **C7 aliasing** | `decision` \| `what it locks (plain language)` \| `T` \| `S` \| `G` \| `amendment proposed` | **The T column must be added** — absent from the source table. Filled `holds (is the baseline)` except **R4**, where T's honest cell is `breached after any remap — 2.10 bins at depth 15`. That cell is the symmetry payoff of the whole document. **R7 and C7 are the reconciliation's additions.** |
| **P14-1** re-bless volume | drift scenario | `scenario` \| `keys` \| `cells` \| `T1 %` \| `T2 %` \| `T3 %` \| `worst dev` \| **`G closer`** \| **`G further`** \| **`tie`** | T and S are 0.00% T3 by construction — header line, not rows. Direction columns mandatory: a T3 class carries magnitude only. **Fillable at bpd 53 only**; `codebeamer-bin-data-model` prints as `NOT COVERED`, never omitted, never blank. |
| **M-T / M-S / M-G** | P1–P14 | `Dimension` \| `msg-stats @53` \| `@616` \| `bucket-stats @53` \| `@616` \| `display @616` \| `where best` \| `where worst` | Identical shape for all three — that is what makes them symmetric. Followed by "What only this arm gives you" and "What this arm cannot do". **T's second block is non-empty** (R4 breach after merge; order-dependence; 13 display anchors; 13,616 B/key @616). |

### NOT FILLABLE — deliberately not designed

1. **Real-`ltl` end-to-end cost per arm.** No `ltl` build carries S or G; every cost number is library-behind-the-interface.
2. **G on the `codebeamer-bin-data-model` scenario** — no measurement in either direction (prototype parsers cannot read its bracketed `[293ms]` durations).
3. **Intermediate resolutions 115 / 256 at fan-out cardinality** — only 53 and 616 were run through a fan-out store. Any dimension × bpd grid at fan-out has two columns, not seven. Do not interpolate.
4. **S2 memory** — never re-run; the `_remap_span` transient buffer is unmeasured. P6 carries S; the S2 footnote says memory is inherited-by-argument, not measured.
5. **Per-arm cost on real `-b`-derived time buckets** — V6/V7 buckets are fixed-line-count runs; N-skew untested.

### Presenting a dimension whose ranking inverts

Three inversion families exist, each with a different cause. **Do not use one mechanism for all three** — the treatment should encode the reason.

**(a) Inverts by surface** (memory, F55). *Paired tables, never merged.* P6-1 and P6-2 sit on the same page with a linking sentence carrying the mechanism: the span-only layout trades a dense array for per-row bookkeeping plus an occupied span — it wins when partitions are numerous and sparsely occupied (fan-out span p50 = 1) and loses when they are few and densely occupied (bucket-stats, ~2,000 observations per partition). **Never state a memory ratio without a surface qualifier anywhere in the document**, summary tables and abstract included; T-1's memory cell reads `~ inverts by surface` and carries *both* anchor numbers. A single table with a `surface` column would invite averaging across rows — exactly the error F55 exists to prevent; two tables with different row counts cannot be averaged by eye.

**(b) Inverts by resolution** (accuracy, F37). *Resolution as columns, magnitude in cells, an explicit `crossover` column* — the crossover names *where* the flip is, converting an inversion from a caveat into a datum. Add a "margin at each end" note: on DPM `N<1000 / spread ≥ 1dec` the margin is 3.19 points at bpd 16 and 0.012 points at 616 — the inversion is real but its stakes are ~400× larger at one end. Rejected: a chart (loses the numbers in a markdown/terminal document); rejected: reporting only the shipping rung (hides the mechanism, which is the transferable insight).

**(c) Inverts by data shape** (Σ G span / Σ T bin_count spanning 35× across files; the G low-clamp direction flipping on whether the observed min sits on a grid boundary). *A spread, not a figure.* The cell shows the **range across measured fixtures, with fixture names**: `0.0039 (fan-out) … 0.0286 (Tomcat) … 0.1395 (DPM)`. The table shape must make quoting a single "G is N× smaller" figure impossible.

**Global rule.** Every cell is qualified by (surface, resolution, fixture) or is a range across them. A bare scalar appears only where the evidence shows invariance — and where it does, say so: `1.0000 bins — invariant across depth 1–15, both fixtures, both bpd`.

### Making frictions explicit

§7.2 is a **frictions grid**: one row = one friction (gaining on X costs Y), never one row per dimension.

Columns: `friction` \| `gain (dimension, magnitude)` \| `cost (dimension, magnitude)` \| `arms affected` \| `where it bites` \| `is it escapable?`

| friction | gain | cost | arms | where it bites | escapable? |
|---|---|---|---|---|---|
| Global anchoring vs per-key adaptivity | G: exact R4 bound, 0 breaches at any merge depth; order-independence | G: loses T's seed adaptivity — T ahead from bpd 115 up on Tomcat | G vs T/S | moderate-cardinality multi-observation keys only; moot at 287k keys | **no** — the same mechanism from two sides |
| Span-only layout | S: 2.2× / 12.7× memory, 8.4× / 79.5× percentile time at fan-out | S: +42% memory vs T on bucket-stats @616 | S (and G) | bounded-cardinality surfaces | partially — a per-surface representation choice escapes it, at the cost of two code paths |
| Span-only merge via dense views | — | S: 1.9× slower fold than T | S only | `-g` consolidation | **yes — already escaped** by S2's native merge |
| Removing per-key partition state | G: no rebin, no out-of-range state | G: five `-V` D8 fields inert; `-V` diff stops being a valid gate; needs A2/A3 first; **R7 partition-independence unresolved** | G | harness / observability / locked contract | no — structural |
| Keeping today's representation | T: zero re-bless, zero amendments, all `-V` fields live | T: keeps the R4 breach, the order-dependence, 13 display anchors per 24 buckets, 13,616 B/key @616 | T | everywhere | no |

The `is it escapable?` column is what makes this a decision instrument rather than a list of caveats. Each friction row is also cited inline from the two dimension subsections it connects, as a one-line pointer — the grid is the record, the pointers stop a §5 reader from missing it.

### Surfacing weightings without letting them decide

The architect's brief: the quantitative view *"is not sufficient to decide on the direction, but can be used to influence where you spend the most time looking."* That specifies **a reading order, not a score.**

**Do not include:** any weighted score, composite index, "T scores 6/14", overall arm ranking, or recommendation. A weighted total is a decision wearing arithmetic's clothes — the weights encode the judgement the architect reserved.

**Do include** — §9 built from three declared, non-numeric properties per dimension:

| property | values | why it is a property, not a weight |
|---|---|---|
| Reversibility | `reversible` / `one-way` | Re-blessing baselines is one-way; a cost regression is reversible. Read off the evidence. |
| Blast radius | count of surfaces / decisions / harnesses touched | Counted from P13-1 and the audit, not scored. |
| Evidence strength | `measured at scale` / `measured at small scale` / `projected` / `argued` | A property of the capture, stated in the aspect record. |

§9 is **one ordered list of at most six items**, each phrased "look hardest at X, because Y", where Y is one of the three properties and never a magnitude. Every §5 subsection also ends with an evidence-strength line in the same vocabulary — distributing the honesty so a reader who never reaches §9 still cannot mistake a projected number for a measured one.

### What to exclude, and what to change in the existing write-ups

**Exclude from the new document:**

1. Any recommendation, preferred arm, or "the evidence suggests".
2. Weighted scores or composite rankings.
3. Verifier issue lists from the aspect record — QA metadata, not decision input; one pointer line instead.
4. Reproduction command blocks — they belong to the record; Appendix A carries the capture index.
5. Per-aspect Hypothesis / Method narrative — the comparison is dimension-major; method is cited, not restated.
6. Bare per-key memory ratios with no surface qualifier.
7. S-vs-S2 as separate arms — one footnote plus dual cells in P9.
8. `counter_memory_bytes` as a comparison figure anywhere (F44: it moves 2.7% on byte-identical input). It may appear once in P12-1 as a field "un-assertable on all three arms", never as a memory number.
9. The 51,469-key RSS projections as headline memory (F52: they failed at fan-out by +68% to +385%). Once only, in P6-1's caption, as the cautionary datum motivating the measured-at-scale rule.

**Cut from `prototype/426-bin-primitives-revalidation-report.md`:** nothing. It is the aspect record and citation target; it stays intact.

**Restructure in `features/426-per-message-statistics-store.md`:** § *Session findings (2026-08-25)* runs F33–F55 in production order, with the memory findings F52–F55 split across F41 and F47. **Regroup by dimension, preserving the F-numbers as stable identifiers** — they are cited from three other documents and must not be renumbered. Add a dimension index at the head mapping P1–P14 → F-numbers. That is the only edit needed; the findings themselves are sound.

**One structural gap to fill before publishing:** the aspect record's § *Decisive evidence per locked decision and requirement* table has **two arm columns (S, G) and no T column**. P13-1 requires three, plus the **R7** and **C7** rows this reconciliation added. Adding T's column is not cosmetic — it converts the table from "how do the candidates differ from today" into "how does each of three candidates stand against the locked contract", and it is where T's honest R4 cell appears.

---

### Verification notes

**Quotes verified by grep against the worktree** (`/Users/gregeva/Documents/GitHub/logtimeline/.claude/worktrees/426-per-message-statistics-store`, branch `426-per-message-statistics-store`). 24 checked, 24 located. No fabricated citations found.

| quote (truncated) | file | found? | note |
|---|---|---|---|
| "Prometheus native-exponential `HistogramQuantile`" | `features/187-…percentiles.md:1078` | ✅ | Exact. |
| "`rank_in_bin` as the `fraction` parameter … diverges from HdrHistogram and DDSketch" | `features/187-…:1102` | ✅ | Exact. |
| "No per-bin sample-count guard in R4." | `features/187-…:1368` | ✅ | Exact. |
| "bounded uniformly by partition geometry … applies uniformly across quantiles" | `features/187-…:125` | ✅ | Exact, under § R4. |
| "structural … not empirical" | `features/187-…:128` | ✅ | Exact. Piece 1's bolding of "structural" matches the source; the corroborating 426 rows at :772 and :800 also exist. |
| "The auto-resize lifecycle itself is not revisitable." | `features/187-…:1334` | ✅ | Exact; preceded by "The seed heuristic is revisitable from telemetry" as quoted. |
| "The contract is the operation, not the data structure." | `features/189-…primitives.md:162` | ✅ | Exact (source is unbolded; both pieces bold it — cosmetic). |
| "This is a hard requirement, not an option" | `features/189-…:213` | ✅ | Exact, under § R7. Confirms K12 and its "no global registry of partitions" clause at :219. |
| "Memory savings are not worth fidelity loss." | `features/34-…mode.md:135` and `features/201-…:608` | ✅ | Present in both, with different continuations. Piece 2 attributes the full "the candidate is wrong … do not accept the smoothing as a trade" text to #34 R5 — correct; #201:608 carries a shorter variant. |
| "No cross-bin mass splitting at any stage." | `features/34-…:132`, `features/201-…:605` | ✅ | Both. Piece 1 quotes the #201 wording, Piece 2 the #34 wording; the "mirrored verbatim" claim is corroborated at `426-…:780`. |
| "Reader-friendliness is secondary to grep-stability" | `features/187-…:1506` | ✅ | Exact. |
| "Cross-model comparison … would assert nothing meaningful" | `features/224-…:67` | ✅ | Exact. #289:132 carries the parallel statement. |
| "A skipped layer would produce a false-pass result, which is worse than no test." | `features/224-…:129` | ✅ | Exact. |
| "Partial coverage is forbidden — the engine refuses to start…" | `features/224-…:164` | ✅ | Exact. |
| "explicitly NOT claimed" (insertion-order independence) | `features/426-…:924` | ✅ | Exact, Part 4 row 5b, with the F27 sub-quote. |
| "any representation must keep it" (`[min,max]` clamp) | `features/426-…:1219` | ✅ | Exact. |
| "The `v > 0` guard is load-bearing for every representation." | `features/426-…:534`; report `:1074` | ✅ | Both. Report is Finding F; feature doc is F28. |
| "573,026 of 573,318 compared cells are exact for both arms" | `features/426-…:1208`; report `:971`, `:997` | ✅ | Exact in all three. |
| "one partition per logical series, with a fixed bin footprint…" | `docs/explain/statistics.md:219` | ✅ | **Verified in the user-facing doc itself**, not only via the 426 citation at :902. |
| "616 is the HdrHistogram 3-significant-digit reference … out of scope" + "not in question" | `features/189-…:98` | ✅ | Both clauses in one sentence, as quoted. |
| "structurally novel" (fan-out divergence) | `features/187-…:1341` | ✅ | Exact. |
| "`peak_retention = 1.0     [always — no count splitting]` **Y-axis is exact.**" | `features/201-…:372–374` | ✅ | Exact, and the enclosing heading at :366 is "### (e) — Two-stage stream→finalize", confirming Piece 1's heading attribution. |
| "roughly **11% of peak**" | `prototype/201-projection-comparison-report.md:171` | ✅ | Exact. Corroborated in the feature doc at :516 and :539 with the 1.10% / 5.78% figures. |
| "Aggregate metrics (mass, peak, X-offset) are not sufficient." | `prototype/201-…:219` | ✅ | Exact. |
| "narrow spikes with empty columns between" | `features/201-…:543` | ✅ | Exact. |
| "Highest-risk uncovered path." / "zero golden coverage" | `features/426-…:893`, `:892` | ✅ | Exact. |
| "apache 21.8% T3, tomcat 15.9%, thingworx 31.7%" | `features/426-…:1188` | ✅ | Exact (F36). |
| "**A compact container is highly likely to hit it.**" | `features/426-…:888` | ✅ | Exact. |
| "~5× on keyed traversal and ~2× on the population walk" | `features/426-…:65` | ✅ | Exact. |
| render duplication "1,647,292 vs true raw 575,800 (~2.86× inflation)" | `features/426-…:931` | ✅ | Exact, Part 4 row 12. |
| "silent on D8's locked field *order*" | `features/426-…:799` | ✅ | Exact (A3). |
| F27 / F30 / F33 / F34 / F36 / F37 / F39 / F41 / F43 / F52–F55 exist as numbered findings | `features/426-…:517–1292` | ✅ | All located at the cited F-numbers; T 13,616 B/key @616 confirmed at :1233, T 2,381 B @53 at :549. |

**Could not confirm / not checked:**

- Piece 3's capture-file paths under `prototype/426-results/` (e.g. `v7/v7-summary.tsv`, `message-stats-scale/fanout.txt`, `v8-rebless/rebless-bpd53.tsv`) and the numeric worked-example tables drawn from them were **not opened**. The directory `prototype/426-results` exists; individual files and their column headers are unverified. Every number in Piece 3's worked examples is therefore carried forward as **claimed, not verified** — anyone filling the tables must re-read the captures. This is flagged rather than silently trusted.
- Piece 3's "V9(b)" Tomcat bpd-16 cell already carried its own "verify the bold before publishing" caveat; that caveat is preserved.
- `features/305-…md` "-V creates no demand" and `features/293-…md` tier table were cited by both pieces and are consistent between them, but were not independently grepped in this pass.

**CONTRACT/QUALITY classification checked against quotes.** Two corrections applied to Piece 1's classification:

- **B1** was marked plain CONTRACT. The quote at 187:125–128 supports CONTRACT *as written*, but 426 Part 4 row 10 and 189 § *Revalidation* both state it is measured false after remap, with the correction "**PROPOSED, NOT APPLIED**". Reclassified as **CONTRACT as written + QUALITY (measured gap)**, matching how B2 was already handled. Leaving B1 as unqualified CONTRACT would let a reader score G as "exceeding" a bound T is currently breaching without seeing that the bound's own text is under amendment.
- **E9** (`[min,max]` clamp) was marked CONTRACT on harness enforcement while the same row records "no #187-level statement authorises the clamp". Retained as CONTRACT (a blocking harness asserts it) with the authorship gap stated in the row, and promoted to item 5 of "What the corpus does not settle" — an enforced behaviour with no locked authorisation is exactly the kind of thing a replacement will drop by accident.

All other CONTRACT rows are supported by MUST / "hard requirement" / "locked" / "part of the locked feature contract" / blocking-harness language in their quotes. All QUALITY rows are supported by measurement language or by explicit non-claiming ("NOT claimed", "not measured", "Undocumented anywhere").

**Disagreements between the three pieces, and how they were resolved** — recorded in full in the *Reconciliation* section above. In summary:

1. **D1–D14 name collision between Pieces 2 and 3** (different content, same identifiers). Resolved by renaming to `W1–W14` (weighting) and `P1–P14` (presentation), with Piece 1's `A1–M6` kept as the register. No content merged away.
2. **Adaptivity**: Piece 1 rejects it as a dimension, Piece 2 weights it High-and-Contested. Resolved by scoping it to the D5 *mechanism* plus three enumerated benefits, and routing the unresolved weight to "What the corpus does not settle" item 2. Neither piece was overruled.
3. **Merge as a contract**: Piece 1 CONTRACT (#287 R2.3), Piece 2 "not established" for areas (c)/(d). Not a conflict — different surfaces; both recorded, with the shared-code-path hazard elevated to Tension 7.
4. **Three real gaps found only by reconciliation** and added to the plan: **K12 / #189 R7** (a "hard requirement" absent from P13-1's row list and from the audit's amendment list — added as a mandatory P13-1 row and as Tension 8 and unsettled-item 11), **C7 target-empty aliasing** and **C8 merge-rebin telemetry** (undocumented shipped behaviours absent from every table spec — added to P13-1 and P12-1 respectively), and **D8 render duplication** (a CONTRACT with no table home — added to P5-1's caption assertions).
5. **W8 and W13 have no presentation axis.** W13's absence is correct (out of scope by architect ruling); W8's is not, and is discharged by requiring its three locked *benefits* (E5, G2, E1) to appear explicitly — E5 as P5-2's `distinct range anchors` column, G2 as a §2 precondition, E1 in P11-1.

**Not done, by instruction:** no file was modified; nothing was committed or pushed.
