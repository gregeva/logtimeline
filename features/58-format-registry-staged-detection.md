# Feature: Format registry and staged detection (Phase 1)

## Status

- **Issue:** #58 — **Drop 1 of the 0.17.0 merge train** (parent: #23; follows Drop 0 #180)
- **Planned:** 2026-07-15 walkthrough session (this document is the repo-side source of truth for the drop; the issue body is its GitHub-side snapshot)
- **Umbrella:** `features/log-format-registry.md` — shared requirements (sections 1–5, 11) and locked decisions D12/D13/D17/D18/D20 live there
- **Fixes:** #369 (access-log read-phase regression). **Unblocks:** #17's declarative path (format-carried units)

## Overview

Replace the implicit match-type conditional chain (~13 hardcoded `elsif` regex branches, static order, evaluated per line) with a data-driven **format registry** scanned as a **self-ordering array of compiled patterns**. Drop 1 replaces *how a line is recognized* — nothing else: no processing-model change, no unit auto-detection, no I/O decoupling.

The cost class removed: on a 1.43M-line access log, profiling measured 6.46s of failed ThingWorx pattern attempts alone (~40% of hot-loop time); the v0.16.0 cascade true-up regressed access-log read phase 4–11.5% (#369). The format a file matched is currently remembered only as an integer `match_type` and a lossy `$is_access_log` boolean.

## Requirements

### R1 — Registry entry schema

One entry per format carrying everything downstream code currently infers from the match-type integer:

- compiled pattern (`qr//`) + pattern source (never reconstruct source from `qr//` stringification — `docs/regex-best-practices.md`)
- field mapping (which captures are timestamp, message, duration, bytes, count, …)
- **time contract** (three parts, all declarative — D23):
  - *layout* — the timestamp parse pattern
  - *precision* — what the format resolves to (s / ms / µs); drives sub-second bucketing (`-ms`), the integer-milliseconds hash-key rule, and cross-checks the `ts_precision` hint from index read-back (#179)
  - *timezone semantics* — (a) offset present in the line → parse and honor it; (b) offset absent, format documented as UTC → registry pins UTC; (c) offset absent, format writes local time → registry pins "local", and what local means resolves through the configuration cascade (CLI firmest → registry/user config → default). The format *knows*; the engine never guesses — same declarative pattern as duration units. Consumers: #155 (UTC normalization) reads cases (a)/(b); #154 (fixed rendering offset) is the display-side override.
- duration field + **declared duration unit** (D18 — declarative format-carried knowledge, e.g. Tomcat 9 `%D` = milliseconds), with an **ambiguity marker** for variants (Tomcat 9 ms vs Tomcat 10.1+/Apache HTTP µs `%D`)
- access-log property (replacing `$is_access_log`)
- **`event_pairs` reservation (D23 — reserved in this drop, consumed by #372 in the Phase 2+4 release):** an optional array of pair-pattern declarations, each holding two independent patterns (`start_pattern` / `end_pattern`, asymmetry inherent), a correlation binding (captures matched by name across the two patterns), a log-key composition template (rebuilding the merged key from captures of both sides), and a metric mapping onto canonical record fields. This drop **validates** the slot at load time (user YAML with pair declarations fails loudly, never silently) but does not consume it — placeholder-with-contract, so #372 lands without schema churn. The schema must not bake in "one line = one event."
- format name/description + sample lines (samples become per-format test fixtures)

### R2 — Detection mechanism: move-to-front ordered scan (LOCKED, D20)

An ordered array of compiled regexes, one per registry entry, tested front-to-back per line. On a match at position *i*, the winner **moves to the front**. The matched entry IS the registry entry — extraction runs from its definition.

- Detection is a **change-point workload** (one format for millions of consecutive lines; change points at file boundaries): MTF converges in one match per change point; steady-state per-line cost is one successful compiled match at index 0. Delivers the original "detect once per file" intent globally with no per-file reset bookkeeping.
- Stray-line worst case: intruder jumps to front; the next normal line pays exactly one failed match and restores order.
- Bubble-up-one (the `docs/regex-best-practices.md` sketch, proven in `match_consolidation_patterns()`) was argued and **rejected for this use**: its noise-damping pays off at high pattern counts with genuinely interleaved traffic (the consolidation problem), not ~13 patterns over near-constant streams.
- D13's multi-format/fallback contract falls out of the structure: no separate fallback path — a line failing the front pattern scans deeper; a format shift reorders the array.
- Lines matching **nothing** (continuation lines, stack traces) pay the full scan under any ordering, exactly as today. If profiling shows this cost class matters, a cheap pre-filter is an in-drop design point, independent of ordering policy.

### R3 — Built-in format migration with extraction parity

All ~13 cascade branches become registry entries. **Audit constraint (2026-07-15):** the cascade's outputs (`match_type`-conditional extraction, `$is_access_log` behavior, CSV/UDM header detection state) are consumed deep into the read loop — entries must carry all of it. Parity is per-format testable: each migrated format produces identical fields to its old branch on its sample fixtures.

### R4 — User-defined formats via YAML (D12)

Loaded at startup; validated with clear, actionable errors; able to extend or override built-ins. In-drop decision: YAML::PP vs YAML::Tiny, weighed against the PAR-packaged builds.

### R5 — Format-carried units (D18 boundary)

Duration unit is registry metadata. Precedence: explicit `-du` override → format-carried unit (this drop) → index read-back (#179) → sample-based auto-detection (#17 — NOT in this drop; no unit auto-detection or speculative unit tracking inside the rewrite). Ambiguous variants get a warning; *resolving* the ambiguity statistically stays #17's follow-on (its ~100-line sampling window is the D17 detection window — see the design-tie comments on #181/#17).

### R6 — Detect-stage integration

The registry slots into #180's named `detect` role; `read_index_file()` hints (#179 — timestamp range, `ts_precision`) are available detect-stage inputs. The D17 minimal detection window (hold first ~N lines; per-line re-scan on cache-miss) is the only line-holding built — no full reader/processor decoupling (#181 is architecture guidance only).

## Out of scope

- Processing model changes (#59 — Phase 2+4 release)
- Metric visibility/purpose (#60 — Drop 2)
- Unit auto-detection or unit tracking (#17, D18)
- Full buffered-read I/O decoupling (#181, D17)
- Extraction improvements — this drop is extraction *parity* per format, not enhancement

## In-drop design decisions to settle

- Pattern priority when multiple registry entries could match the same line (umbrella Q2)
- Format definition inheritance — "like tomcat9 but microseconds" (umbrella Q3)
- Strict mode vs. current permissive behavior for unrecognized formats (umbrella Q5)
- YAML module choice (R4)
- Whether a no-match pre-filter is warranted (R2)

## `-V format-detection` section-contract (stub — to be locked in-drop)

The existing `format-detection` section (`emit_format_detection_verbose()`) gains ordering/scan-depth telemetry sufficient to prove MTF behavior: per-format match counts, scan-depth distribution (or total failed-attempt count), final array order. Per `tests/HARNESS-DESIGN.md`: line shapes and counter semantics are locked here when implemented, and the consuming harness is updated in the same change. This document becomes the owning feature doc for that section-contract.

## Acceptance criteria / merge gate

- [ ] All existing tests byte-identical: golden files + full `tests/validate-*.sh` suite exits 0; runtime-warning-clean stderr.
- [ ] **#369 probe**: `TIMING/read_files` on an access-log selection improves vs. the v0.16.0 baseline — cost class removed, not shaved. Targeted single-file probe, median-of-3; no XL suites during development.
- [ ] Detection observability per the section-contract above.
- [ ] Extraction parity per migrated format (sample-line fixtures).
- [ ] At least one user-defined YAML format loads and parses a fixture; malformed definitions produce clear errors.
- [ ] Format-carried unit applied for a known format; `-du` wins; ambiguity warning fires on the Tomcat `%D` case.
- [ ] Gate passes → merge to `release/0.17.0`; #369 fix comment + close; #17's declarative half delivered (sampling follow-on stays open).

## Related

- Parent umbrella: `features/log-format-registry.md` (#23) — D12/D13/D17/D18/D20
- Prerequisite: #180 (Drop 0 — named stages; native `blocked_by` recorded)
- `docs/regex-best-practices.md` — pattern-count scaling, ordering policies, alternation rejection, qr// handling
- #369 (fixed by this drop), #17 (declarative half delivered), #179 (detect-stage hints)
