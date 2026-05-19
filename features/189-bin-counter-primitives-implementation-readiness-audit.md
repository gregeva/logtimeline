# Feature: Implementation-readiness audit for #189 bin-counter primitives

## Overview

This document is the implementation-readiness audit that sits between PR #194 (the prototype + validation report on `release/0.14.5`) and the start of #189 production implementation. It re-organizes the prototype's findings by **code surface** rather than by validation aspect, identifies every `ltl` symbol/line that will be touched by downstream tickets, and surfaces three categories of consequence:

- **Bucket A** — refinements to `features/189-histogram-bin-counter-primitives.md` that should land before #189 production begins, so the spec reflects what the prototype empirically validated.
- **Bucket B** — `ltl` code surfaces any consumer migration will encounter, with the recommended change captured once so each migration ticket can read the audit instead of re-deriving the analysis.
- **Bucket C** — implementation decisions #189 production still owes (the prototype gave evidence but didn't lock them — they're production concerns).

## GitHub Issue

[#195](https://github.com/gregeva/logtimeline/issues/195)

## Sources

This audit consolidates evidence from:

- `prototype/189-bin-counter-primitives-validation-report.md` — empirical findings from the prototype's V1–V5 validation against real D2 Tomcat data.
- `features/187-histogram-bin-counter-percentiles.md` § *Locked decisions from research* — the unified contract.
- `features/189-histogram-bin-counter-primitives.md` § R1–R12, *Audit findings*, *Consumer-side requirements* — the implementation contract and call-site inventory.
- `ltl` at `release/0.14.5` HEAD (commit `940bc98`) — the code surface this audit cross-references.

Line numbers below refer to `release/0.14.5` HEAD; symbols and global identifiers are the stable anchors.

## What this audit is not

- **Not a code change.** This audit is read-only against `ltl`. Bucket A produces `features/*.md` edits; Buckets B and C produce documentation for downstream tickets to act on. No `ltl` lines are modified by this issue.
- **Not the production implementation.** Production primitives are #189's scope; this audit unblocks that work but does not perform it.
- **Not a consumer migration.** Each consumer migration is its own ticket (Phase 2 for `summary_table`/`csv_output`; #34 for the Phase 3 group; #51 for Phase 4); this audit unblocks them but does not perform them.

---

## Delivery sequence (where this audit sits)

```
┌─────────────────────────────────────────────────────────────┐
│ PR #194 (merged) — prototype + validation report            │  done
│   evidence: V1-V5 against real D2 Tomcat data               │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ #195 (this audit) — implementation-readiness audit          │  ◄ here
│   output: this doc + Bucket A spec refinements              │
│   no ltl code changes                                       │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ #189 production — primitive helpers in ltl                  │
│   scope: R1-R6 helpers, =PERCENTILE MODE= -V block,         │
│   --percentile-precision / -pbpd / --exact-percentiles      │
│   CLI flags, primitive-level unit tests, baseline           │
│   harness scenarios. NO CONSUMER IS MIGRATED.               │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ Consumer migrations (separate tickets per #187 R9 phasing): │
│   Phase 2 — summary_table + csv_output (+ histogram_view    │
│             global percentiles incidentally)                 │
│   Phase 3 — heatmap_cells, heatmap_markers, histogram_bins  │
│             (owned by #34)                                  │
│   Phase 4 — #51 highlight subsets                           │
│   Phase 5 — any future consumer (inherits by construction)  │
└─────────────────────────────────────────────────────────────┘
```

---

## Bucket A — Spec refinements to `features/189-histogram-bin-counter-primitives.md`

These edits land as commits on this branch. Each commit message references the prototype evidence that motivated the refinement.

### A1 — R2 algorithm recommendation: closed-form

**Today's spec (line 119):** *"Be efficient enough to invoke per-line in the parsing hot path. The exact algorithm (binary search, direct logarithmic computation) is implementation-defined."*

**Recommended edit:** keep the contract open ("implementation-defined") but add a paragraph immediately below referencing the prototype evidence and recommending closed-form. Specifically:

> Prototype evidence (PR #194, `prototype/189-bin-counter-primitives-validation-report.md` § V2) measured three R2 candidates against a 67 MB Tomcat file (51,469 partitions): closed-form (`floor(B · log(v/min) / log(max/min))`), binary search over a stored boundary array, and linear search over the same array. Closed-form was 3.31× faster than linear, 2.46× faster than binary, with 4.75× lower memory (no boundary array stored per partition). V1's cross-check confirmed all three produce identical bin indices on 857,480 real observations. The recommended R2 implementation for #189 production is closed-form; binary and linear remain conforming alternatives.

**Rationale:** the prototype settled the algorithm choice empirically. Without this addition, #189 production would have to re-derive the same analysis. With it, production starts from "closed-form unless you have a reason not to."

### A2 — Boundary array materialization: on-demand, not stored

**Today's spec:** ambiguous. R1 line 100 lists `min`, `max`, `bin-count` as observable state but doesn't say whether `boundary[i]` is materialized per partition or computed on demand. R4 line 156 says "where `lower = partition.boundary[located_bin]` and `upper = partition.boundary[located_bin + 1]`" — implying an array. R9 line 220 references `state_budget_bytes` per consumer but does not address the boundary-array cost.

**Recommended edit:** add an implementation-guidance note to R1 stating that the recommended implementation derives `boundary[i]` on demand from `min`, `max`, `B`, `i` using the locked log-spaced formula. Specifically:

> **Boundary materialization (implementation guidance, non-binding):** The closed-form R2 implementation does not require a stored boundary array — `boundary[i] = min · (max/min)^(i/B)` can be computed on demand whenever R4 or rendering code needs a specific boundary value. The prototype measured that storing the array per partition adds ~4.75× memory at locked default bpd=53 (51,469 partitions: 117 MB closed-form vs. 555 MB with boundary arrays). For consumers running at Path A scale (10⁵+ partitions), the recommended implementation materializes boundaries inline at the call site rather than persistently per partition.

**Rationale:** Decision 2's projection of ~212 MB at 10⁵ partitions assumed closed-form (no boundary array). Without this clarification, an implementer who reads R1+R4 in isolation could choose binary search with stored boundaries and end up at ~1.1 GB at Path A scale, a 5× cost overrun against Decision 2's published guidance.

### A3 — `out_of_range_bounded` audit semantics: explicit per-quantile

**Today's spec (R6 line 187):** *"Expose them to consumers for the per-consumer audit aggregates (`partitions_with_overflow_count`, `partitions_with_underflow_count` per #187 Decision 8)."* — and Decision 8's locked format already shows per-quantile inline `out_of_range_bounded: p50=none p99=high`.

**Recommended edit:** add an explicit clarifying line to R6 stating that the audit code is per-quantile, derived at R4 invocation time from the rank's landing position, not a property of the partition itself. Specifically:

> **Audit semantics (per-quantile, not per-partition):** The `out_of_range_bounded` audit code is determined per-quantile by R4 at the moment of invocation, based on whether the target rank for that specific quantile lands in the underflow counter, an in-range bin, or the overflow counter. A partition with `partitions_with_overflow_count > 0` may still report `audit = none` for some quantiles (those whose target rank lands in an in-range bin). Per #187 Decision 4, the overflow/underflow counter's share of total N determines which quantiles fire: a quantile q lands in overflow only when `ceil(q · total_N) > (total_N − overflow_count)`; symmetric for underflow.

**Rationale:** the prototype's V3 Part B (`prototype/189-bin-counter-primitives-validation-report.md` § V3 *Surprises*) demonstrated that a partition with non-zero out-of-range counters reports `audit = none` for quantiles whose rank falls in the in-range region. Without this clarification, consumer tests would naturally assert "if `overflow > 0` then `audit = high` at every quantile of that partition" — which is incorrect and would produce false test failures.

### A4 — Decision 2 memory projection: Perl-overhead footnote (edit to `features/187-histogram-bin-counter-percentiles.md`)

**Today's spec (#187 § *Locked decisions from research* § Decision 2, line 1172):** *"Memory footprint at locked default: 265 bins per partition over 5 decades; ~2.1 KB per partition at 8 B/counter; ~212 MB total across 10⁵ keys (Path A scale)."*

**Recommended edit:** add a footnote noting the Perl-overhead delta measured by the prototype. Specifically:

> **Measured overhead** (prototype evidence, PR #194 § V2 Part A): on real Tomcat data at 51,469 partitions, actual per-partition cost under Perl is 2,381 B (vs. the theoretical 2,136 B floor), and projected total at 10⁵ partitions is 227 MB (+12.3% over the 212 MB guidance). The delta is Perl hash-and-scalar overhead vs. the theoretical `(B+2) × 8` byte counter array. Analysts comparing observed `counter_memory_bytes` in `-V` output against this guidance should expect the small positive offset.

**Rationale:** Decision 2's projection is theoretical. The prototype measured the real cost on D2 data and found the small Perl-overhead delta. Users reading the spec and then comparing `-V` output to its projection should not be surprised by the +12.3% delta.

### A5 — `percentile_precision` field rendering when `-pbpd` is non-tier

**Today's spec (#187 Decision 8 line 1452-1453):** the spec shows examples like `percentile_precision: 4 (--percentile-precision 4; overridden)` and `percentile_precision: 5 (default)` but does not address the case where `-pbpd 100` is specified — 100 doesn't correspond to any of the nine LEVELs in the locked tier table.

**Recommended edit:** add a clarifying line to Decision 8's `percentile_precision` field definition stating that when `-pbpd N` resolves to a non-tier value, the field renders as `percentile_precision: n/a (-pbpd N specified)` or similar. The exact format is at #189 production's discretion within the locked stability contract; document the convention chosen.

**Rationale:** the prototype's V4 scenarios surfaced this small format question (`prototype/189-bin-counter-primitives-validation-report.md` § V4 *Findings* finding 2). It's not a contract gap — it's a small cosmetic question Decision 8 didn't anticipate. Calling it out in the spec lets #189 production pick a convention and not have to bikeshed it during implementation.

### A6 (deferred) — Tests for `=== PERCENTILE MODE ===` section

`tests/baseline/` does not currently have a scenario asserting the `=== PERCENTILE MODE ===` block, but Decision 8's stability contract says "section name, all top-level field names, all consumer-name strings, and all per-consumer field names are part of the locked feature contract." Test coverage for this is a contract surface but is **#189 production's responsibility, not this audit's**. Recorded here so the production ticket knows test scaffolding for the new `-V` section is in scope. See `tests/validate-index-readback.sh` for the existing pattern.

---

## Bucket B — `ltl` code surfaces any consumer migration will encounter

The cross-reference. For each affected symbol/line, captures (a) the prototype's relevant finding, (b) which downstream ticket touches it, (c) the recommended change.

### B1 — `find_heatmap_bucket` (`ltl:4783-4789`)

**Today:** linear search over `@heatmap_boundaries`. Returns in-range bin index; silently clamps out-of-range values to the last bin.

**Prototype evidence:** V2 Part B measured linear search at 5.39 s for 343 K observations vs. closed-form at 1.63 s (3.31× slower) and 555 MB memory vs. 117 MB (4.75× more memory). V1 confirmed all three R2 algorithms produce identical bin indices.

**Recommended change:** delete `find_heatmap_bucket` and replace its call sites with the unified-contract R2 (closed-form). The heatmap's silent out-of-range clamping is replaced by Decision 4's separate-counter overflow/underflow contract (R6).

**Owning ticket:** #34 (Phase 3 migration of `heatmap_cells` and `heatmap_markers`).

### B2 — `find_histogram_bucket_index` (`ltl:4890-4905`)

**Today:** binary search over per-metric boundary array. Returns in-range bin index always (out-of-range adjusted before the call).

**Prototype evidence:** V2 Part B measured binary search at 4.00 s vs. closed-form at 1.63 s (2.46× slower), same memory footprint as linear because the boundary array is still required (555 MB).

**Recommended change:** delete `find_histogram_bucket_index` and replace its call sites with closed-form R2. Existing out-of-range adjustment logic gets replaced by Decision 4's overflow/underflow counters.

**Owning ticket:** #34 (Phase 3 migration of `histogram_view` and `histogram_bins`).

### B3 — `calculate_statistics` (`ltl:5488-5528`)

**Today:** sort-and-index core for both per-message (Path A) and per-time-bucket (Path B) percentile derivation. Uses `int($n * fraction)` (0-based floor) indexing — `$sorted[int($n * 0.99)]` returns the (int(n·0.99)+1)-th element from 1.

**Prototype evidence:** V5 measured the rank-convention difference between Prometheus `ceil(q · N)` (locked Decision 1) and ltl's `int(N · q)` (existing). Invisible at locked default bpd=53 (masked by binning noise); becomes the dominant user-visible error source at bpd ≥ 256. At bpd=616, P90 binning_max = 0.33% but raw_max (including rank-convention difference) = 1.87%.

**Recommended change:** `calculate_statistics` is **not deleted by #189 production** — it stays in place for any consumer that has not yet migrated (#187 R10/R11 retain it through the migration phases). Each consumer migration replaces its `calculate_statistics` *call* with an R4 invocation. After every consumer migrates, the function can be retired or kept as the `--exact-percentiles` opt-out path (#187 R11a / Decision 7).

**User-visible behavior change:** P50 of a low-N key today is `sorted[int(0.5 · N)] = sorted[N/2]` (the (N/2+1)-th element); under the unified contract it becomes the R4 interpolation against `ceil(0.5 · N) = N/2` rank (the (N/2)-th element). Different element for any non-trivial N. Release notes for each consumer migration must call this out; framing per the validation report: industry-standard query-time analyzer convention (Prometheus + New Relic), a quality improvement, not a regression.

**Owning tickets:**
- The Phase 2 migration ticket — replaces `calculate_statistics` calls at `ltl:5218`, `ltl:5367` for `summary_table` and `csv_output`.
- #34 — for `time_bucket_stats` (Phase 3 group), heatmap percentile markers (currently sorts `%heatmap_raw{$bucket}` at `ltl:4818`), and the histogram-mode global percentiles (currently in `calculate_histogram_buckets` at `ltl:4926-4940`).

### B4 — Raw value arrays (multiple sites)

The unified contract eliminates four raw value arrays. Each migration ticket deletes one or more:

| Array | Site | Today | Replaced by | Owning ticket |
|---|---|---|---|---|
| `log_messages{$category}{$log_key}{durations}` | `ltl:4591` | Per-message duration array, pushed during parse | Per-`(category, log_key)` counter store via R3 | Phase 2 |
| `log_analysis{$bucket}{durations}` | `ltl:4634` | Per-time-bucket duration array, gated `unless $heatmap_enabled` | Per-`time_bucket` counter store (or shared with heatmap counters when active) | #34 (Phase 3) |
| `%heatmap_raw{$bucket}` | `ltl:4693` | Per-time-bucket raw value array, accumulated during parse | Per-`time_bucket` counter store via R3 (already keyed by `time_bucket`) | #34 (Phase 3) |
| `%histogram_values{$metric}` | `ltl:4705-4723` | Per-metric raw value array, accumulated during parse | Single global counter store per metric via R3 | #34 (Phase 3) |

**Prototype evidence:** these arrays are the dominant memory consumers in the analysis pipeline today. The contract's design eliminates per-value storage in favor of per-bin counters (~2.4 KB per partition at locked default).

**Pre-existing entanglement worth flagging to #34:** `log_analysis{$bucket}{durations}` at `ltl:4634` is gated `unless $heatmap_enabled` — heatmap takes ownership of duration values when active and per-time-bucket percentiles are suppressed. Under the unified contract, heatmap's counter store *is* the natural source for per-time-bucket percentiles via R4. The gate may be removed when #34 migrates these consumers together. Recorded in #189 spec lines 391-392 and noted here so #34 has the context.

### B5 — Memory tracking infrastructure (`ltl:3223+`)

**Today:** `print_memory_breakdown` (in the `-V` section) already tracks `Devel::Size::total_size` for `%log_stats`, `%heatmap_data`, `%heatmap_data_hl`, `%heatmap_raw`, `%histogram_values`, etc.

**Recommended change:** when each consumer migrates and its raw-array global is deleted, the corresponding `Devel::Size` line is updated to track the new counter-store global (or removed if memory tracking is consolidated into the `counter_memory_bytes` field of `=== PERCENTILE MODE ===`).

**Owning ticket:** each consumer migration touches the corresponding `Devel::Size` line.

### B6 — `=== INDEX READ-BACK ===` block coexistence (`ltl:836+`)

**Today:** `@verbose_output` is built up sequentially; `=== INDEX READ-BACK ===` is the existing convention for verbose-mode observability sections.

**Recommended change:** #189 production adds a `=== PERCENTILE MODE ===` block to `@verbose_output` at the appropriate point. Decision 8 line 1623 leaves the exact ordering relative to other `-V` sections at implementer discretion; tests should not depend on inter-section ordering.

**Owning ticket:** #189 production.

### B7 — `tests/baseline/` and existing `-V` regression test pattern

**Today:** `tests/validate-index-readback.sh` is the existing pattern for `-V`-section regression tests. `tests/validate-regression.sh` is the broader output-regression harness.

**Recommended change:** #189 production adds `tests/validate-percentile-mode.sh` (or equivalent) following the `validate-index-readback.sh` pattern, asserting the `=== PERCENTILE MODE ===` block's run-level header and per-consumer block fields per Decision 8's locked stability contract. Each consumer migration adds its own baseline-regression scenarios per #187 R11.

**Owning tickets:** #189 production owns the new `=== PERCENTILE MODE ===` test scaffold; each consumer migration extends the baseline-regression harness for that consumer's user-visible output.

### B8 — `print_help()` (`ltl:1051`)

**Today:** documents existing CLI flags including `-hgbpd`.

**Recommended change:** #189 production adds `--percentile-precision`, `-pbpd`, and `--exact-percentiles` to `print_help()` per Decision 2 line 1190-1193 and Decision 7 line 1429.

**Owning ticket:** #189 production.

### B9 — `adapt_to_command_line_options()` (`ltl:3531`)

**Today:** parses all existing CLI options.

**Recommended change:** #189 production adds parsing for `--percentile-precision N`, `-pbpd N`, and `--exact-percentiles` per Decision 2's flag interaction contract (`-pbpd` wins on conflict). Validation rules per Decision 2 line 1130 (`4 ≤ -pbpd ≤ 616`; `1 ≤ --percentile-precision ≤ 9`).

**Owning ticket:** #189 production.

### B10 — `README.md` options reference

**Today:** documents existing CLI flags.

**Recommended change:** #189 production adds `--percentile-precision`, `-pbpd`, and `--exact-percentiles` to the options reference per CLAUDE.md (existing convention to update help text and README.md together when CLI changes). Per Decision 7's deprecation contract, `--exact-percentiles` carries a deprecation notice in its documentation.

**Owning ticket:** #189 production.

### B11 — `docs/usage.md`

**Today:** analyst-facing documentation, synced to the public wiki on each release.

**Recommended change:** #189 production adds analyst-facing explanation of when to use the new flags (per Decision 2 line 1194 and Decision 7 line 1431). Specifically: the `--percentile-precision 1..9` tier table; how to read `=== PERCENTILE MODE ===` output; when to consider `--exact-percentiles` opt-out.

**Owning ticket:** #189 production.

---

## Bucket C — Implementation decisions #189 production still owes

The prototype gave evidence but didn't lock these — they're production concerns and #189 production has discretion over them.

### C1 — Where the primitives live in `ltl`

**Question:** top of `## SUBS ##` after `## GLOBALS ##`? A new dedicated section? An external library file? The prototype is standalone (`prototype/189-bin-counter-primitives.pl`); production has to pick.

**Recommendation (non-binding):** add a new section in `ltl` named per ltl's existing section-marker convention (something like `## HISTOGRAM BIN-COUNTER PRIMITIVES (R1-R6 per #189) ##`) at the top of `## SUBS ##`. Helpers stay in the main `ltl` script (consistent with the project's "single Perl script" architectural choice) rather than being broken into a separate `.pm`.

### C2 — Partition allocation, freeing, and reference shape

**Question:** the prototype uses a single global hash keyed by `(category, log_key)` for Path A. Production has more keying shapes to support (per-`time_bucket` for heatmap; `()` global for histogram view). Does production use one big global hash per consumer, or attach partitions to existing per-consumer data structures (e.g., `$log_messages{$cat}{$key}{partition}` alongside the existing `{durations}`)?

**Recommendation (non-binding):** the second approach (attach partitions to existing per-consumer data structures) integrates more cleanly with existing memory-management code paths and the consumer-side R8 lifecycle requirements. The prototype's "one global hash" was fine for validation but is not the right production shape because freeing a per-time-bucket counter (an R8 contract surface) requires the partition to be addressable by the consumer's natural key.

### C3 — Decision 2 CLI flag wiring details

**Question:** Decision 2 locks the contract; production picks how `--percentile-precision N`, `-pbpd N`, and the conflict resolution between them are implemented in `adapt_to_command_line_options()`. How are out-of-range values reported? How does the resolved `(bpd, source)` pair propagate to the partition constructor and to `emit_telemetry()`?

**Recommendation (non-binding):** parse both flags during option parsing; resolve to `($bpd, $precision_source)` once, store on a global or pass through to partition construction explicitly. The prototype uses a global `$precision_source` string for the `-V` source annotation (`prototype/189-bin-counter-primitives.pl:79-91`); production might prefer a struct.

### C4 — `=== PERCENTILE MODE ===` block wiring

**Question:** where does the block emission live? A new `print_percentile_mode()` sub called from the existing `-V` emission path? Inline in the main flow?

**Recommendation (non-binding):** follow the existing `=== INDEX READ-BACK ===` pattern (`ltl:829+`) — a dedicated subroutine called from the verbose-output assembly path. Decision 8's locked field ordering is deterministic; the subroutine's job is straight emission of the locked fields against the partition state collected so far.

### C5 — Validation harness scope at the primitive level

**Question:** primitive-level unit tests cover R1–R6 per #189 line 481. Cross-consumer composition tests verify R7 (partition independence) and R8 (lifecycle independence). Production picks the test layout — `tests/test-percentile-primitives.sh`? Inline `prove` style? Embedded in `validate-regression.sh`?

**Recommendation (non-binding):** new file `tests/test-percentile-primitives.sh` following the existing `validate-*.sh` pattern. Primitive-level cases: synthetic inputs with hand-computable expected outputs (the prototype's V1 Part A is the source material). Cross-consumer cases: multi-consumer runs with telemetry assertions per Decision 8.

### C6 — Whether the prototype code becomes production or is discarded

**Question:** Decision 10's lock language (`features/187-histogram-bin-counter-percentiles.md` line 1706) says: *"Whether the prototype code becomes the basis for #189's production code, or is discarded after lessons are extracted. #189's discretion."*

**Recommendation (non-binding):** the prototype's `parse_line`, `partition_new`, `partition_extend`, `bin_assign` (closed-form variant), `counter_update`, `percentile` subs are close to production-shape and can be ported with minor cleanup (separate the CLI parsing, drop the V1/V2/V3/V4/V5 driver subs, integrate with ltl's existing data structures). The prototype's `Devel::Size` integration, `--mem` flag, `--r2-cross-check`, `--r2-bench` paths are validation-only and stay in the prototype.

---

## Recommended PR-sized scope partition for #189 production

When #189 production is opened, the work decomposes naturally into the following PR-sized chunks (recommendation, non-binding):

1. **PR #189-1: Primitive helpers + CLI flag parsing (no `-V` output yet).** R1–R6 helpers landed in `ltl`. `--percentile-precision`, `-pbpd`, `--exact-percentiles` parsed but unused. Unit tests for R1–R6 against synthetic inputs. No consumer changes. Baseline regression passes byte-identically because nothing observable changes.

2. **PR #189-2: `=== PERCENTILE MODE ===` `-V` block + `consumers_active: none` state.** The block emits per Decision 8 with `consumers_active: none` because no consumer is migrated. `tests/validate-percentile-mode.sh` asserts the block's run-level header and the no-consumer-active path. Baseline regression continues to pass byte-identically.

3. **PR #189-3: `README.md`, `docs/usage.md`, `print_help()` updates.** Analyst-facing documentation lands. No code changes beyond `print_help()`. Wiki sync happens at next release.

After all three #189 PRs merge, the primitives are in place and the contract surface is documented. Consumer migrations (Phase 2 / #34 / #51) then start as their own tickets.

This partition is **a recommendation**, not a contract. #189 production may bundle PRs 1+2 into a single PR if the team prefers. The boundary that matters is between #189 production (primitives only, no consumer migrated) and consumer migrations (per-consumer baseline-regression validation).

---

## Cross-reference table — Bucket B by owning ticket

For each downstream ticket, the full set of `ltl` code surfaces it touches per this audit:

### #189 production

- B5 (memory tracking — new `counter_memory_bytes` field in `=== PERCENTILE MODE ===`)
- B6 (`=== INDEX READ-BACK ===` block coexistence — adds new block at appropriate point)
- B7 (`tests/baseline/` — adds `tests/validate-percentile-mode.sh`)
- B8 (`print_help()` — adds three new flags)
- B9 (`adapt_to_command_line_options()` — parses three new flags)
- B10 (`README.md` — adds three new flags to options reference)
- B11 (`docs/usage.md` — analyst-facing flag explanation)

### Phase 2 consumer migration ticket (`summary_table` + `csv_output` + incidental `histogram_view`)

- B3 (`calculate_statistics` calls at `ltl:5218`, `ltl:5367` replaced)
- B4 row 1 (`log_messages{}{}{durations}` array at `ltl:4591` deleted)
- B5 (corresponding `Devel::Size` line removed/repurposed)
- Release notes for the rank-convention behavior change per V5 finding 2

### #34 (Phase 3 group: `heatmap_cells`, `heatmap_markers`, `histogram_view`, `histogram_bins`, plus `time_bucket_stats`)

- B1 (`find_heatmap_bucket` at `ltl:4783-4789` deleted)
- B2 (`find_histogram_bucket_index` at `ltl:4890-4905` deleted)
- B3 (`calculate_statistics` calls inside `calculate_heatmap_buckets` at `ltl:4818-4834`, inside `calculate_histogram_buckets` at `ltl:4926-4940`, and inside `calculate_all_statistics` for per-time-bucket per `ltl:5218` replaced)
- B4 rows 2, 3, 4 (`log_analysis{$bucket}{durations}`, `%heatmap_raw`, `%histogram_values` deleted)
- B5 (corresponding `Devel::Size` lines removed/repurposed)
- Pre-existing entanglement: `unless $heatmap_enabled` gate at `ltl:4634` re-evaluated per #189 spec lines 391-392
- Release notes per V5 finding 2

### #51 (Phase 4 highlight subset)

- New consumer, no existing surface to remove. Inherits R3 keying for highlight subset per #187 R12.

---

## What this audit unblocks

- **#189 production** — has a spec that reflects the prototype evidence (Bucket A), a cross-reference doc for everything it touches (Bucket B rows for #189 production), and recorded production-decision territory (Bucket C).
- **#34** — has a clear list of `ltl` symbols to delete or replace (Bucket B rows for #34), the rank-convention release-notes story, and the pre-existing entanglement called out.
- **Phase 2 migration ticket** (not yet opened) — has its scope clearly identified by Bucket B rows assigned to it.
- **#51** — has confirmed it inherits the unified contract by construction with no surprises.

## Spec stability

This audit refines `features/189-histogram-bin-counter-primitives.md` (Bucket A) but does not change any locked decision in `features/187-histogram-bin-counter-percentiles.md`. The contract is the same; the spec around the contract is now grounded in empirical evidence rather than theoretical projection.
