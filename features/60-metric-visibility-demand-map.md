# Feature: Configurable metric visibility and purpose — the generalized demand map (Phase 3)

## Status

- **Issue:** #60 — **Drop 2 of the 0.17.0 merge train** (parent: #23; follows Drop 1 #58; the former "#59 prerequisite" was removed by the D21 re-cut — the visibility model gates stores, not the processing model)
- **Planned:** 2026-07-15 walkthrough session (this document is the repo-side source of truth for the drop; the issue body is its GitHub-side snapshot)
- **Umbrella:** `features/log-format-registry.md` — section 8, decisions D15/D21

## Overview

Every metric — built-in (duration, bytes, count, sessions, threadpools) or user-defined — declares its purpose and visibility: graph column, CSV output, time-bucket rows, message-level stats, or internal-only. The chain "what we collect → what we calculate → where it's used" becomes configuration, not code.

**This is wiring, not invention.** Every capability already exists, proven:

- the demand resolver (#305/#303, resolving the #349 producer/consumer-decoupling bug; measured −38% message-store memory on statistic-sort runs)
- the render-time visibility cascade of the #33 column-layout engine (`build_column_layout()`, `auto_hide_narrow_columns()`)
- data-presence gating (`max_total > 0` flips metric columns visible)
- auto-detection of dynamic columns (sessions/threadpools/UDMs via `add_dynamic_column()`)
- CLI hide flags; `-V` provenance reporting

What does not exist is the coherent frame: **one resolution surface, one cascade, one declared producer/consumer vocabulary** all of them speak.

## The two resolution layers this drop synchronizes

- **Plan time (demand)** — decides capture/compute/storage before any file is read. The #305 pattern: consumers declare what they read; a resolver runs once after option settlement; demand gates capture, compute, and storage independently.
- **Render time (layout engine, #33)** — decides what is *drawn*: data presence + terminal space + `hide_order` auto-degrade. Layout is calculated before scaling (data scales into the widths). Render can only **narrow** what demand captured.

**Cross-layer invariant: demanded ⊇ rendered.**
- Demand without data → no column (presence gate, render time).
- Data without demand → must not exist (the #349 contract).
- An auto-hidden column's data remains for other demanded consumers (CSV, summary tables — the #33 "Data Model vs UI Rendering Separation" principle, now stated as a cross-layer contract).
- A CLI-hidden metric with no other consumer is never captured.

## Settled design rulings (architect, 2026-07-15)

1. **Configuration is always a cascade**: CLI (firmest) → registry/user configuration → built-in defaults, resolved once at plan time. No single-surface configuration.
2. **Data presence is itself a gate**: a metric with no observed data earns no column regardless of configured visibility (already implemented render-side; retained).
3. **Metric entry ≠ metric configuration**: the registry entry describes what a metric *is* (producer side); column width behavior, visibility, `hide_order` are configuration *for* the metric (consumer side) — they live in the configurable space, not in the entry.
4. **Presets are not the model**; they may exist as defaults for specific metric sets. Today's auto-detection/auto-adaptation is the default behavior to preserve.
5. **Metric families are an addressable configuration granularity**: "omit this family" / "show this family in the table below" as one setting, without enumerating members.
6. **Existing CLI flags (`-hs` etc.) are the already-exposed configuration plane** over the demand map — declared inputs to the cascade, not a parallel mechanism.

## Requirements / Scope

1. **One demand map, generalized** — extend the #305 producer/consumer resolution from duration-statistic groups to all metric families (duration, bytes, count, sessions, threadpools, UDMs). `resolve_statistics_group_demand()` becomes a client/special case of the general resolver — one resolution surface, no parallel sibling (per the one-resolution-surface rule).
2. **The layout engine becomes a declared consumer** — the graph table enters the demand map explicitly, instead of its needs being implied by scattered display flags. The demanded ⊇ rendered invariant governs the interface.
3. **Configuration cascade, resolved once** — CLI → registry/user configuration → defaults, at plan time, into the demand map.
4. **Per-metric render configuration migrates out of code** — `build_column_layout()`'s hardcoded per-metric settings (`hide_order`, spacing, default visibility, color index) become metric configuration, overridable through the same cascade.
5. **Metric families** — family-level settings feeding both plan-time demand and render-time defaults, preserving auto-detection as default behavior.
6. **Display-flag gate sweep** — inventory every remaining capture/compute site gated on a display flag (the #349 defect class); route each through the demand map or record it exempt-with-reason. **The inventory is a written deliverable in this document.**
7. **Observability** — demand resolution for all families inspectable with provenance (`-V statistics-demand` extended or a sibling section — see section-contract stub below).

## Out of scope

- Processing-model changes (#59 — Phase 2+4 release)
- Derived metrics as demand participants (#61 — the model leaves room: a derived metric is a consumer of its inputs and a producer for its own consumers; internal-only inputs is the canonical case)
- Representation degradation under memory pressure (#2 umbrella — visibility decides *where values surface*, never fidelity)
- Changes to the layout engine's render-time algorithms (widths, linear decay, auto-hide loop — they work; this drop wires to them, not into them)

## In-drop design items

- Shape and location of the registry/user visibility configuration (file format; relationship to Drop 1's YAML format definitions)
- Family definitions and membership (which families; whether user formats can declare family membership)
- Whether any presets ship, and their composition

## `-V` section-contract (stub — to be locked in-drop)

Either `statistics-demand` is extended to cover all families, or a sibling section is registered. Per `tests/HARNESS-DESIGN.md`: new/renamed sections and keys are breaking changes; the owning feature doc (this one, for the generalized map) locks line shapes and counter semantics in the same change as implementation, and consuming harnesses update in the same commit. The existing `statistics-demand` contract remains owned by `features/305-shape-moment-extended-percentile-demand.md`; its observable behavior must not shift (see gate).

## Acceptance criteria / merge gate

**Default parity (the hard gate):**
- [ ] No visibility configuration supplied → today's behavior exactly: golden files byte-identical; full `tests/validate-*.sh` suite exits 0; runtime-warning-clean stderr.
- [ ] `-V statistics-demand` unchanged for identical invocations (the #305 resolution is a client of the general resolver).
- [ ] Layout parity: same terminal widths → same columns rendered, same auto-hide decisions (`--debug-layout` / `--validate-layout` before/after on the same fixtures).

**New contracts, each demonstrably true:**
- [ ] Cascade precedence: firmer layer wins — one test per precedence pair (CLI vs registry config; registry config vs default).
- [ ] demanded ⊇ rendered: auto-hidden column's data still reaches CSV/summary consumers; a CLI-hidden metric with no other consumer is never captured (assert via `-mem` / `-V` provenance).
- [ ] Data-presence gate regression-pinned: demanded metric with no observations → no column, no phantom output.
- [ ] Family addressing: omit-family / show-family affects every member, none others.
- [ ] `internal_only`: feeds dependents, appears on no surface, storage released after dependent computation — measured via `-mem`.

**Sweep accountability:**
- [ ] Display-flag gate inventory recorded in this document: every site listed, migrated or exempt-with-reason — no silent leftovers.

**Observability & docs:**
- [ ] `-V` section-contract locked per HARNESS-DESIGN rules; harnesses updated in the same change.
- [ ] New user-facing options documented in `print_help()` + `docs/usage.md` in the same commit (parity enforced by `validate-help-content.sh`); short + long forms for every option.

Gate passes → merge to `release/0.17.0`; completes the 0.17.0 merge train (Drops 0/1/2).

## Related

- Parent umbrella: `features/log-format-registry.md` (#23) — section 8, D15/D21
- Prerequisite: #58 (Drop 1; native `blocked_by` recorded)
- Foundations: #305/#303 (`features/305-shape-moment-extended-percentile-demand.md`), #349 (decoupling contract, resolved), #33 (`features/column-layout-refactor.md` — layout engine, "Data Model vs UI Rendering Separation")
