# Feature: Memory ceiling and the adaptive memory controller

**Issue:** #2 — Performance: Implement maximum memory usage ceiling and default auto-detection
**Status:** `status: backlog`. Not blocked. No implementation started.

## Why this file exists now

This document was deliberately unwritten for most of the issue's life: it was to be started *from
the representation #426 (compact per-message statistics store) delivers*, and #2 carried a native
`blocked_by` edge to it.

**#426 was dispositioned `not planned` on 2026-08-26** — the investigation completed, the evidence
stands, no implementation is scheduled. It will not deliver a new representation. The dependency was
therefore resolved and dropped (architect, 2026-08-26), and this design targets the **current**
one-hash-per-message layout.

That is not a loss for this issue. #426 measured the current layout in depth before stopping, and
those measurements are exactly what a memory-ceiling design needs. They are recorded below so this
work does not have to re-derive them — and so that the traps #426 hit while measuring memory are not
walked into a second time.

## Inherited evidence — measured, not estimated

Sources: `features/426-three-arm-comparison.md` (the analysis), findings F33–F55 in
`features/426-per-message-statistics-store.md`, captures under `prototype/426-results/`. Every figure
below is from a capture file, one configuration per process.

### E1 — Per-entry cost of the current layout, at scale

286,659 distinct message keys, 288,025 observations, bin data model:

| resolution | bytes/key | store | percentile pass over all keys |
|---|---|---|---|
| default (bins-per-decade 53) | 2,423 | 662 MB | 17.6 s |
| finest (bins-per-decade 616) | **13,616** | **3.72 GB** | 181.3 s |

**The per-entry cost is not a constant.** It grows ×5.6 in memory and ×10.3 in time across the
resolution ladder, because today's per-key bin array is sized by the partition rather than by the
data — a key with three observations at the finest tier still carries a 4,619-element array. A
ceiling budget or eviction estimate computed at one precision tier does not transfer to another.

### E2 — Per-entry cost must carry a surface qualifier

The compact representations #426 evaluated are 2.2×–12.7× *smaller* than today's on the per-message
store and **42% larger** on the per-time-bucket store. The direction of the effect depends on whether
partitions are numerous and sparsely occupied or few and densely occupied.

**Consequence for this issue:** any lever reasoning "evict N entries to recover M bytes" must be
stated per surface. A single per-entry figure spanning the message store, the per-time-bucket store,
the heatmap and the histogram will be wrong by more than the effect being chased.

### E3 — The measure itself has failure modes (this is the trap)

1. **Resident-set exceeds `Devel::Size` by 12.6–40.6%** on every arm, surface and resolution
   measured, and **the gap fraction is largest where the store is smallest**. So `Devel::Size`
   understates real footprint, and understates it *most* for the compact cases. The `-mem`
   per-structure map is a `Devel::Size`-class measure while this controller steers on RSS: the two do
   not agree, and the difference is systematic, not noise. This quantifies per structure the ~4–9%
   untracked residual #356 found.
2. **Small-scale memory measurements do not project.** At 51,469 keys the compact arms' RSS delta
   read *below* their own `Devel::Size` — the store fit inside memory the interpreter had already
   mapped, so the measurement captured allocator slack rather than the store. **The sign inverts by
   286,659 keys.** Projections built from the small runs failed at fan-out by +68% to +385%, while
   `Devel::Size` projections from the same runs held to within −12%/+19%. A ceiling calibrated on
   small runs will be wrong on large ones.
3. **One process cannot measure two configurations.** Building a second store in a process that has
   already grown understates it by up to **47%**, because later allocations reuse pages the first
   freed. Any calibration harness for this issue runs one configuration per process.
4. **`counter_memory_bytes` is not reproducible** (#461) — it varies 2.7% between runs on
   byte-identical input, being `Devel::Size` over a hash-backed store with a per-process hash seed.
   It cannot serve as a control signal or a regression assertion as it stands.

### E4 — The `-V` audit surface this issue plans to build on has known gaps

The issue specifies a `-V` audit surface so the controller is observable. Two defects in the existing
bin-counter verbose block would be inherited by anything built on it:

- **Three fields are constants in shipped runs** and discriminate nothing — the out-of-range
  counters are unreachable because the histogram is always grown instead (#460).
- **Merge-driven re-binning is invisible**: the counters reset on merge, so telemetry reads as
  "geometry is stable" during precisely the runs where it churns most (#462).

Neither is caused by this issue, and both should be resolved before the controller's audit builds on
that surface — otherwise the audit inherits the blind spots.

## Relationships

- **#458 — `-n 0`, retain and compute nothing per message.** The *user-declared* route to a minimal
  footprint, where this issue is the *automatic* one. The two must agree on what a run with no
  message retention looks like. **A coordination relationship, not a dependency** — neither blocks
  the other, and the test that settles it is that this issue can proceed to a clean design before
  #458 lands, and vice versa.
- **#426 — compact per-message statistics store** (`not planned`, open as a decision record). The
  source of the evidence above. Was recorded as a blocker; the dependency was resolved and dropped
  on 2026-08-26 when #426 was dispositioned.
- **#56 / `features/memory-baseline-profiling.md`** — the measurement instrument (the `-V
  benchmark-data` block, the per-structure `MEMORY` rows, the runner and comparison tooling). This
  issue's calibration uses it, subject to the E3 caveats.
- **#356** — the untracked peak-RSS residual, whose constraints (freed memory does not return to the
  OS; eviction buys reuse, not reclamation) shape what the ceiling can achieve. Recorded in the issue
  body.
- **#354, #347, #323, #96, #44** — as recorded in the issue body.

## Open — to resolve when this issue is picked up

1. Whether the ceiling's per-entry arithmetic is derived per surface and per precision tier (E1, E2
   say it must be) or whether the controller instead measures live rather than predicting.
2. Which measure the controller steers on, given E3.1: RSS is what matters to the OS, the
   per-structure map is what attributes it, and they differ systematically.
3. Whether #460 and #462 are prerequisites for the `-V` audit surface, or whether this issue defines
   its own audit fields independent of the bin-counter block.
