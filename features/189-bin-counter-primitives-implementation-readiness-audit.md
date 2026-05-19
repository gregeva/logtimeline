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

## Audit execution log

The audit was executed as a full codebase sweep against `release/0.14.5` HEAD (commit `422eca7`), not just a verification of the cited anchors. The patterns swept and their hit counts are recorded below so a re-run of the audit can confirm completeness.

| Pattern swept | Sweep query | Hit count | Result |
|---|---|---|---|
| P1 — `find_heatmap_bucket` / `find_histogram_bucket_index` call sites | `grep -nE 'find_heatmap_bucket\|find_histogram_bucket_index' ltl` | 11 hits (2 defs + 9 call sites) | All sites already in B1, B2; no new hits beyond cited. |
| P1b — Other linear/binary search bin-lookup idioms over `*boundaries*` arrays | `grep -nE '@heatmap_boundaries\|@\{?\$?[a-z_]*boundaries' ltl` | Boundary-array consumers at `ltl:4798, 4892, 4961-4965, 6324-6325, 6473-6474` | Rendering-time consumers already cited in spec; no new lookup idioms. |
| P2 — Raw-value array pushes in parse loop | `grep -nE 'push @\{?\$?(log_(analysis\|messages)\|heatmap_raw\|histogram_values)' ltl` | 11 push sites | All catalogued; the `_hl` highlight twins (`%heatmap_raw_hl` at 4694; `%histogram_values_hl` at 4706, 4711, 4716, 4724) are first-class — see new B13. |
| P3 — `calculate_statistics` call sites | `grep -nE 'calculate_statistics\(' ltl` | 2 call sites (`ltl:5218, 5367`) | Both cited in B3. |
| P3b — Direct sort-and-index outside `calculate_statistics` | `grep -nE 'sort \{ \$a <=> \$b \}' ltl` | 6 sort sites; 3 are percentile-derivation (`ltl:4818, 4922, 4987`), 1 is the canonical `calculate_statistics` sort (`ltl:5496`), 2 are `sort keys` (not value sorts). | The `int(N*q)` rank derivation occurs at **four** sites: `ltl:4823-4826`, `ltl:4930-4939`, `ltl:4995-5004`, `ltl:5505-5517` — see B3 clarification. |
| P4 — Log-spaced boundary formula `min * (max/min)^(i/B)` | `grep -nE 'min[^_]* \(.*max.*\/.*min\).*\*\*' ltl` | 2 sites: histogram at `ltl:4964` (cited in spec) and heatmap at `ltl:4812` (NOT cited) | See new B12. |
| P5 — Per-key free / delete sites for raw arrays | `grep -nE 'delete \$?(heatmap_raw\|histogram_values\|log_(analysis\|messages)).*\{\|undef\s+@?\{?\$?...' ltl` | 9 sites: `log_messages` key-record deletes at `ltl:1978, 2018, 2967, 3131`; `heatmap_raw{$bucket}` free at 4855-4856; `log_analysis{$bucket}{durations}` free at 5213-5214; `log_messages{...}{durations}` per-key free at 5401-5402 (**commented out**). | See new B15 (no per-key free today for `log_messages{...}{durations}`) and B16 (consolidation-flow whole-record deletes need counter-store companion). |
| P6 — `Devel::Size::total_size` references | `grep -nE 'Devel::Size\|total_size\(' ltl` | 2 emission sites: `measure_memory_structures` at `ltl:3206-3240` and `print_verbose_output` `MEMORY_FINAL` block at `ltl:6578-6587`. | Audit doc cited `print_memory_breakdown` (no such function); see B5 anchor correction and new B14 (second site). |
| P7 — `=== ... ===` verbose blocks | `grep -nE '"=== [A-Z]' ltl` | **Four** blocks: `=== INDEX READ-BACK ===` (`ltl:836`), `=== Verbose ===` (`ltl:3713`), `=== BENCHMARK DATA ===` (`ltl:6541-6604`), `=== Consolidation Summary (Issue #96) ===` (`ltl:8116`) | See new B17 (production picks block ordering vs. all four, not just one). |
| P8 — CLI flag parsing for `bpd` and related | `grep -nE '\-hgbpd\|histogram_buckets_per_decade\|histogram_bucket_override' ltl` | `-hgbpd` already exists at `ltl:3609`, default 8, histogram-only. | See B9 update and new C7 (conflict resolution with new `-pbpd`). |
| P9 — `tests/validate-*.sh` baseline harness | `ls tests/validate-*.sh` | 3 scripts: `validate-histogram-ticks.sh`, `validate-index-readback.sh`, `validate-regression.sh` | Audit doc cited only `validate-index-readback.sh`; see new B18 (`validate-histogram-ticks.sh` is bin-counter-relevant). |
| P10 — Mode-gated raw-value suppression | `grep -nE 'unless \$heatmap_enabled\|if \$heatmap_enabled' ltl` | 1 data-suppression gate (`ltl:4634`); other `$heatmap_enabled`/`$histogram_enabled` references are simple mode-routing guards. | Spec's exhaustive-coverage claim confirmed. |

The sweep confirms the spec's `Audit findings` section (`features/189-histogram-bin-counter-primitives.md` § "Existing helpers to be unified or replaced") catalogues the principal call sites correctly. The new findings from the sweep — see B5/B6/B10 corrections plus B12–B18 and C7–C8 below — extend the catalogue with surfaces the spec's first pass missed (boundary-formula second site, MEMORY_FINAL second site, four `===` verbose blocks rather than one, `-hgbpd` naming conflict, `validate-histogram-ticks.sh` relevance, per-key free-site asymmetry).

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
│   scope: R1-R6 helpers, =BIN-COUNTER MODE= -V block,         │
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

**Status: LANDED.** A1–A5 are present in the current spec files. A6 is deferred as #189 production's responsibility.

Each item below records what was landed and where it lives in the spec, so a re-audit can verify the landed text against the recommendation.

### A1 — R2 algorithm recommendation: closed-form (LANDED at `features/189-...-primitives.md:122`)

**Pre-edit spec (line 119):** *"Be efficient enough to invoke per-line in the parsing hot path. The exact algorithm (binary search, direct logarithmic computation) is implementation-defined."* — preserved as the contract surface.

**Landed addition (line 122):** keeps the contract open ("implementation-defined") and adds a paragraph immediately below referencing the prototype evidence and recommending closed-form. Specifically:

> Prototype evidence (PR #194, `prototype/189-bin-counter-primitives-validation-report.md` § V2) measured three R2 candidates against a 67 MB Tomcat file (51,469 partitions): closed-form (`floor(B · log(v/min) / log(max/min))`), binary search over a stored boundary array, and linear search over the same array. Closed-form was 3.31× faster than linear, 2.46× faster than binary, with 4.75× lower memory (no boundary array stored per partition). V1's cross-check confirmed all three produce identical bin indices on 857,480 real observations. The recommended R2 implementation for #189 production is closed-form; binary and linear remain conforming alternatives.

**Rationale:** the prototype settled the algorithm choice empirically. Without this addition, #189 production would have to re-derive the same analysis. With it, production starts from "closed-form unless you have a reason not to."

### A2 — Boundary array materialization: on-demand, not stored (LANDED at `features/189-...-primitives.md:124`)

**Pre-edit spec:** ambiguous. R1 line 100 listed `min`, `max`, `bin-count` as observable state but didn't say whether `boundary[i]` is materialized per partition or computed on demand. R4 line 156 says "where `lower = partition.boundary[located_bin]` and `upper = partition.boundary[located_bin + 1]`" — implying an array. R9 line 220 referenced `state_budget_bytes` per consumer but did not address the boundary-array cost.

**Landed addition (line 124):** an implementation-guidance note to R2 stating that the recommended implementation derives `boundary[i]` on demand from `min`, `max`, `B`, `i` using the locked log-spaced formula. Specifically:

> **Boundary materialization (implementation guidance, non-binding):** The closed-form R2 implementation does not require a stored boundary array — `boundary[i] = min · (max/min)^(i/B)` can be computed on demand whenever R4 or rendering code needs a specific boundary value. The prototype measured that storing the array per partition adds ~4.75× memory at locked default bpd=53 (51,469 partitions: 117 MB closed-form vs. 555 MB with boundary arrays). For consumers running at Path A scale (10⁵+ partitions), the recommended implementation materializes boundaries inline at the call site rather than persistently per partition.

**Rationale:** Decision 2's projection of ~212 MB at 10⁵ partitions assumed closed-form (no boundary array). Without this clarification, an implementer who reads R1+R4 in isolation could choose binary search with stored boundaries and end up at ~1.1 GB at Path A scale, a 5× cost overrun against Decision 2's published guidance.

### A3 — `out_of_range_bounded` audit semantics: explicit per-quantile (LANDED at `features/189-...-primitives.md:193`)

**Pre-edit spec (R6 line 187):** *"Expose them to consumers for the per-consumer audit aggregates (`partitions_with_overflow_count`, `partitions_with_underflow_count` per #187 Decision 8)."* — and Decision 8's locked format already shows per-quantile inline `out_of_range_bounded: p50=none p99=high`.

**Landed addition (line 193):** an explicit clarifying paragraph in R6 stating that the audit code is per-quantile, derived at R4 invocation time from the rank's landing position, not a property of the partition itself. Specifically:

> **Audit semantics (per-quantile, not per-partition):** The `out_of_range_bounded` audit code is determined per-quantile by R4 at the moment of invocation, based on whether the target rank for that specific quantile lands in the underflow counter, an in-range bin, or the overflow counter. A partition with `partitions_with_overflow_count > 0` may still report `audit = none` for some quantiles (those whose target rank lands in an in-range bin). Per #187 Decision 4, the overflow/underflow counter's share of total N determines which quantiles fire: a quantile q lands in overflow only when `ceil(q · total_N) > (total_N − overflow_count)`; symmetric for underflow.

**Rationale:** the prototype's V3 Part B (`prototype/189-bin-counter-primitives-validation-report.md` § V3 *Surprises*) demonstrated that a partition with non-zero out-of-range counters reports `audit = none` for quantiles whose rank falls in the in-range region. Without this clarification, consumer tests would naturally assert "if `overflow > 0` then `audit = high` at every quantile of that partition" — which is incorrect and would produce false test failures.

### A4 — Decision 2 memory projection: Perl-overhead footnote (LANDED at `features/187-...-percentiles.md:1172`)

**Pre-edit spec (#187 § *Locked decisions from research* § Decision 2, line 1172):** *"Memory footprint at locked default: 265 bins per partition over 5 decades; ~2.1 KB per partition at 8 B/counter; ~212 MB total across 10⁵ keys (Path A scale)."*

**Landed addition (line 1172):** a footnote noting the Perl-overhead delta measured by the prototype. Specifically:

> **Measured overhead** (prototype evidence, PR #194 § V2 Part A): on real Tomcat data at 51,469 partitions, actual per-partition cost under Perl is 2,381 B (vs. the theoretical 2,136 B floor), and projected total at 10⁵ partitions is 227 MB (+12.3% over the 212 MB guidance). The delta is Perl hash-and-scalar overhead vs. the theoretical `(B+2) × 8` byte counter array. Analysts comparing observed `counter_memory_bytes` in `-V` output against this guidance should expect the small positive offset.

**Rationale:** Decision 2's projection is theoretical. The prototype measured the real cost on D2 data and found the small Perl-overhead delta. Users reading the spec and then comparing `-V` output to its projection should not be surprised by the +12.3% delta.

### A5 — `percentile_precision` field rendering when `-pbpd` is non-tier (LANDED at `features/187-...-percentiles.md:1452`)

**Pre-edit spec (#187 Decision 8 line 1452-1453):** the spec showed examples like `percentile_precision: 4 (--percentile-precision 4; overridden)` and `percentile_precision: 5 (default)` but did not address the case where `-pbpd 100` is specified — 100 doesn't correspond to any of the nine LEVELs in the locked tier table.

**Landed addition (line 1452):** a clarifying clause in Decision 8's `percentile_precision` field definition stating that when `-pbpd N` resolves to a non-tier value, the field renders as `percentile_precision: n/a (-pbpd N specified)`. The literal string `n/a` is part of the locked stability contract for this field.

**Rationale:** the prototype's V4 scenarios surfaced this small format question (`prototype/189-bin-counter-primitives-validation-report.md` § V4 *Findings* finding 2). It's not a contract gap — it's a small cosmetic question Decision 8 didn't anticipate. Calling it out in the spec lets #189 production pick a convention and not have to bikeshed it during implementation.

### A6 (deferred) — Tests for `=== BIN-COUNTER MODE ===` section

`tests/baseline/` does not currently have a scenario asserting the `=== BIN-COUNTER MODE ===` block, but Decision 8's stability contract says "section name, all top-level field names, all consumer-name strings, and all per-consumer field names are part of the locked feature contract." Test coverage for this is a contract surface but is **#189 production's responsibility, not this audit's**. Recorded here so the production ticket knows test scaffolding for the new `-V` section is in scope. See `tests/validate-index-readback.sh` for the existing pattern.

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

**Sweep finding (rank-convention site count):** The `int(N*q)` rank derivation pattern occurs at **four** sites today, not one:

| Site | What it indexes | Owning consumer migration |
|---|---|---|
| `ltl:4823-4826` | Heatmap percentile markers (P50/P95/P99/P999) over `%heatmap_raw{$bucket}` | #34 — `heatmap_markers` |
| `ltl:4930-4939` | `histogram_stats{$metric}{p1..p9999}` ten-value set | #34 — `histogram_view` |
| `ltl:4995-5004` | `histogram_stats_hl{$metric}{p1..p9999}` highlight twin | #34 — `histogram_view` (HL) |
| `ltl:5505-5517` | Canonical `calculate_statistics` engine called from Path A and Path B aggregators | Phase 2 (Path A) + #34 (Path B) |

Three of the four sites are *outside* `calculate_statistics` — each consumer migration encounters its own inline rank-derivation block and replaces it with R4 + the rank-convention release-notes story. The release-notes language is identical across all four migrations; the source-code touch is per-site.

**Owning tickets:**
- The Phase 2 migration ticket — replaces `calculate_statistics` calls at `ltl:5218`, `ltl:5367` for `summary_table` and `csv_output`.
- #34 — for `time_bucket_stats` (Phase 3 group), heatmap percentile markers (currently sorts `%heatmap_raw{$bucket}` at `ltl:4818` and indexes at `ltl:4823-4826`), histogram-mode global percentiles (`ltl:4926-4940`), and histogram-mode highlight percentiles (`ltl:4995-5004`).

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

### B5 — Memory tracking infrastructure (`measure_memory_structures` at `ltl:3206-3240`)

**Today:** `measure_memory_structures` (called from the `-V` emission path) tracks `Devel::Size::total_size` for the migrating globals at `ltl:3220-3232`: `%log_messages`, `%log_analysis`, `%log_stats`, `%heatmap_data`, `%heatmap_data_hl`, `%heatmap_raw`, `%heatmap_raw_hl`, `%histogram_values`. **`%histogram_values_hl` is not tracked here today** — a small pre-existing omission worth fixing alongside the migration.

**Anchor correction:** the audit's earlier draft referred to this function as `print_memory_breakdown`; no such function exists in `ltl`. The actual sub is `measure_memory_structures`.

**Recommended change:** when each consumer migrates and its raw-array global is deleted, the corresponding `Devel::Size` line in `measure_memory_structures` is updated to track the new counter-store global (or removed if memory tracking is consolidated into the `counter_memory_bytes` field of `=== BIN-COUNTER MODE ===`). The `MEMORY_FINAL` block in `print_verbose_output` (`ltl:6578-6587`) is a **second** emission site — see new B14.

**Owning ticket:** each consumer migration touches the corresponding `Devel::Size` line.

### B6 — `=== INDEX READ-BACK ===` block coexistence (`ltl:836`)

**Today:** `@verbose_output` is built up sequentially; `=== INDEX READ-BACK ===` (`ltl:836`) is one of **four** existing `=== ... ===` blocks in the verbose-output pipeline — see B17 for the full inventory.

**Recommended change:** #189 production adds a `=== BIN-COUNTER MODE ===` block to `@verbose_output` at the appropriate point. Decision 8 line 1623 leaves the exact ordering relative to other `-V` sections at implementer discretion; tests should not depend on inter-section ordering.

**Owning ticket:** #189 production.

### B7 — `tests/baseline/` and existing `-V` regression test pattern

**Today:** `tests/validate-index-readback.sh` is the existing pattern for `-V`-section regression tests. `tests/validate-regression.sh` is the broader output-regression harness.

**Recommended change:** #189 production adds `tests/validate-percentile-mode.sh` (or equivalent) following the `validate-index-readback.sh` pattern, asserting the `=== BIN-COUNTER MODE ===` block's run-level header and per-consumer block fields per Decision 8's locked stability contract. Each consumer migration adds its own baseline-regression scenarios per #187 R11.

**Owning tickets:** #189 production owns the new `=== BIN-COUNTER MODE ===` test scaffold; each consumer migration extends the baseline-regression harness for that consumer's user-visible output.

### B8 — `print_help()` (`ltl:1051`)

**Today:** documents existing CLI flags including `-hgbpd`.

**Recommended change:** #189 production adds `--percentile-precision`, `-pbpd`, and `--exact-percentiles` to `print_help()` per Decision 2 line 1190-1193 and Decision 7 line 1429.

**Owning ticket:** #189 production.

### B9 — `adapt_to_command_line_options()` (`ltl:3531`)

**Today:** parses all existing CLI options. Notably already includes **`-hgbpd`** at `ltl:3609` (`'hgbpd=i' => \$histogram_buckets_per_decade`) — the existing histogram-only buckets-per-decade flag, default 8, declared at `ltl:286`. Validation handler at `ltl:3671-3677` clamps to `>= 1` and warns/resets on invalid input.

**Sweep finding (flag-name conflict):** Decision 2 introduces `-pbpd` (universal percentile-mode buckets-per-decade, default 53) — same letter pattern as the existing `-hgbpd` (histogram-only). The two flags differ in scope (`-hgbpd` is histogram-only; `-pbpd` is universal across all consumers) and default (8 vs. 53), and they would coexist literally in `adapt_to_command_line_options` unless production picks a migration path. See new **C7** for the production decision required.

**Recommended change:** #189 production adds parsing for `--percentile-precision N`, `-pbpd N`, and `--exact-percentiles` per Decision 2's flag interaction contract (`-pbpd` wins on conflict against `--percentile-precision`). Validation rules per Decision 2 line 1130 (`4 ≤ -pbpd ≤ 616`; `1 ≤ --percentile-precision ≤ 9`). The `-hgbpd`/`-pbpd` interaction is a separate question — recorded in C7.

**Owning ticket:** #189 production.

### B10 — `README.md` options reference (revised: NOT APPLICABLE)

**Sweep finding:** `README.md` does not contain a CLI options reference. The audit's earlier draft assumed parallel coverage to other ltl options docs, but `grep -nE '\-h[mg]|\-pbpd|--percentile' README.md` returns zero hits — the README defers to the wiki (`docs/usage.md`) for the options reference. Per CLAUDE.md, the convention is "update help text and README.md together when CLI changes," but in practice README.md carries no flag list and so no update is required for the percentile-mode flags. The owning surface is `docs/usage.md` (B11) plus `print_help()` (B8).

**Recommended change:** None for `README.md`. Retain this row as a no-op so the audit's read-only conclusion (verified by sweep) is recorded.

**Owning ticket:** None.

### B11 — `docs/usage.md`

**Today:** analyst-facing documentation, synced to the public wiki on each release. Heatmap options reference at `docs/usage.md:180+`; histogram options reference at `docs/usage.md:202+`. **`-hgbpd` is not documented in `docs/usage.md` today** (sweep confirmed: no `-hgbpd` references in the file) — a pre-existing gap that the migration can incidentally close by documenting the percentile-precision tier table alongside it.

**Recommended change:** #189 production adds analyst-facing explanation of when to use the new flags (per Decision 2 line 1194 and Decision 7 line 1431). Specifically: the `--percentile-precision 1..9` tier table; how to read `=== BIN-COUNTER MODE ===` output; when to consider `--exact-percentiles` opt-out. The natural insertion point sits between the heatmap section and the histogram section, since percentile mode now applies to all consumers.

**Owning ticket:** #189 production.

### B12 — Heatmap log-spaced boundary formula (`ltl:4812`)

**Today:** `calculate_heatmap_buckets` at `ltl:4806-4814` builds `@heatmap_boundaries` using the same locked log-spaced formula the histogram uses — `$heatmap_boundaries[$i] = $effective_min * ($ratio ** ($i / $heatmap_bucket_count));` — distinct from the histogram instance at `ltl:4964`.

**Sweep finding:** the spec's R1 cites only the histogram instance (`ltl:4961-4966`). The audit doc therefore implied the heatmap path uses something else; in fact it uses the same formula at a different site. Two parallel sites is exactly the harmonization scope the unified contract removes.

**Prototype evidence:** V1's cross-check (`prototype/189-bin-counter-primitives-validation-report.md` § V1) verified the closed-form `boundary[i] = min · (max/min)^(i/B)` against 857,480 real observations across both heatmap and histogram contexts. The formula is identical at both sites today; production replaces both with the R1 partition's on-demand boundary computation.

**Recommended change:** under the unified contract, both `ltl:4812` and `ltl:4964` are replaced by R1 partitions whose boundaries are computed via R2's closed-form on demand (or via on-demand `boundary[i]` calls — see Bucket A2). Neither site materializes a stored boundary array per partition.

**Owning ticket:** #34 (heatmap site and histogram site migrate together as the Phase 3 group).

### B13 — Highlight-twin raw arrays (`%heatmap_raw_hl`, `%histogram_values_hl`)

**Today:** the highlight twin of every raw-value accumulator is allocated alongside its base array:

| Twin | Push sites | Free sites | Sort sites |
|---|---|---|---|
| `%heatmap_raw_hl` | `ltl:4694` | `ltl:4856` | (none — copied into heatmap stats only) |
| `%histogram_values_hl` | `ltl:4706, 4711, 4716, 4724` | `ltl:5012` (implicit — see `calculate_histogram_buckets` HL block) | `ltl:4987` (sort for HL percentile stats) |

**Sweep finding:** the audit doc's B4 row 1 lists `%histogram_values{$metric}` (range `ltl:4705-4723`) but does not separately catalogue the HL twin as a distinct migration target. Per the spec's audit-findings entry (`features/189-...-primitives.md` line 364), the HL subset shares the base partition's boundaries — which means under the unified contract the HL twin becomes a **separate per-partition counter store** keyed by `(metric, highlight_subset)`, but addressing the **same partition** as the base metric. This is the Phase 4 highlight-subset contract (#51) operating on the histogram metric in advance of #51 landing — a worth-flagging boundary case.

**Recommended change:** when #34 migrates `histogram_view`/`histogram_bins`, the HL twin migrates in the same step (R3's per-key counter under a partition shared with the base metric). The audit doc's B4 row 4 is the natural place to catalogue this; this B13 row makes the HL twin first-class so the migration ticket doesn't miss it.

**Owning ticket:** #34 (Phase 3 migration).

### B14 — `MEMORY_FINAL` Devel::Size emission block (`ltl:6578-6587`)

**Today:** `print_verbose_output` (`ltl:6533+`) emits a second, tab-separated Devel::Size block tagged `MEMORY_FINAL` at `ltl:6578-6587`. The block tracks: `%log_messages` (6579), `%log_analysis` (6580), and the consolidation-related globals. Notably it **does not** track `%heatmap_raw`, `%heatmap_raw_hl`, `%histogram_values`, or `%histogram_values_hl` — only the per-message and per-time-bucket structures that the consolidation flow free-tracks.

**Sweep finding:** the audit doc's B5 cites `print_memory_breakdown` (no such function — actual sub is `measure_memory_structures` at `ltl:3206`). It misses the second emission site at `ltl:6578-6587`. Two emission sites mean any rename or repurposing of `%log_analysis`/`%log_messages` under the unified contract must update both locations.

**Recommended change:** production updates both `measure_memory_structures` (B5) and `print_verbose_output` (this row) when consumers migrate. Specifically: when `log_messages{}{}{durations}` becomes a counter store under Phase 2, `ltl:6579` continues to track `%log_messages` (which now holds the counter stores instead of raw arrays) — the line stays valid but the value drops by ~100×. Per-consumer counter memory is also tracked separately in the new `counter_memory_bytes` field of `=== BIN-COUNTER MODE ===`.

**Owning ticket:** each consumer migration touches both Devel::Size emission sites.

### B15 — `log_messages{$category}{$log_key}{durations}` has no per-key free site (memory regression resolved by migration)

**Today:** the raw-duration array per `(category, log_key)` is pushed at `ltl:4591` and never freed during the run. At `ltl:5401-5402`, the per-key `undef` / `delete` are present but **commented out**:

```perl
# undef $log_messages{$category}{$log_key}{durations};
# delete $log_messages{$category}{$log_key}{durations};
```

**Sweep finding:** spec cites the push site only. The lack of a per-key free site means today's `summary_table` consumer holds every per-message duration in memory until end of run — a pre-existing memory cost the bin-counter migration eliminates as a side benefit, since the counter store is bounded at ~2.1 KB per partition regardless of N. Worth recording in release notes alongside the rank-convention story: Phase 2 ships both a behavior change (rank convention) and a memory-cost improvement.

**Prototype evidence:** PR #194 § V2 Part A measured 51,469 per-key partitions on a 67 MB Tomcat file at 117 MB total memory under closed-form (vs. 555 MB with boundary arrays). Today's `log_messages{}{}{durations}` arrays on the same data would be dominated by per-message duration counts — `Devel::Size::total_size(\%log_messages)` at end of run is the comparable today-baseline.

**Recommended change:** Phase 2 migration ticket replaces the raw array (B4 row 1) with the counter store (R3) and the commented-out free site (`ltl:5401-5402`) becomes obsolete — counter stores have bounded memory. Release notes should call out the memory-cost improvement as a side benefit (per-message latency state shrinks from O(total messages) to O(bins per key)).

**Owning ticket:** Phase 2 migration ticket.

### B16 — Whole-record `delete $log_messages{$category}{$key}` in consolidation flow (`ltl:1978, 2018, 2967, 3131`)

**Today:** the fuzzy-message-consolidation pipeline (issue #96) deletes per-key records wholesale during cluster absorption at four sites:
- `ltl:1978` — S4 cluster-absorption flow (one of `merge_into_existing` paths)
- `ltl:2018` — S4 cluster-absorption flow (alternate path)
- `ltl:2967` — S1 inline-match flow (key already absorbed by an existing pattern)
- `ltl:3131` — Final-pass absorption flow

Each `delete` removes the entire `$log_messages{$category}{$key}` sub-hash, taking the `durations` array (and any other per-key state) with it.

**Sweep finding:** the audit doc does not call out the consolidation flow's interaction with the per-message counter store. Under Phase 2's migration, the counter store attached to `$log_messages{$category}{$key}` (B4 row 1's replacement) is co-located in the same sub-hash — so these `delete` sites automatically free the counter store alongside the message record. **No explicit change is required** if the migration places the counter store inside `$log_messages{$category}{$key}{...}` per Bucket C2's recommendation; the existing `delete` is already correct.

This row is recorded to **flag the consolidation-flow interaction** for the Phase 2 migration ticket so the ticket explicitly verifies (and includes a test) that consolidation-time deletes free the counter store. If Phase 2 chooses a different counter-store shape (e.g., a separate global hash) that does **not** co-locate with `%log_messages`, all four `delete` sites need explicit companion `delete` calls — which would be a contract breach of R8's per-key lifecycle independence.

**Owning ticket:** Phase 2 migration ticket (validates co-location decision in C2 or adds companion deletes).

### B17 — Verbose-output block ordering (four existing `=== ... ===` blocks)

**Today:** `@verbose_output` and `print_verbose_output` emit four distinct `=== ... ===` blocks:

| Block | Location | Source |
|---|---|---|
| `=== INDEX READ-BACK ===` | `ltl:836` (push to `@verbose_output`) | Pre-seed / index lookup observability (issue #179) |
| `=== Verbose ===` | `ltl:3713` (push to `@verbose_output`) | General `-V` mode header |
| `=== BENCHMARK DATA ===` | `ltl:6541` (`print` direct from `print_verbose_output`) | Benchmark TSV emission (closed with `=== END BENCHMARK DATA ===` at `ltl:6604`) |
| `=== Consolidation Summary (Issue #96) ===` | `ltl:8116` (push to `@verbose_output`) | Fuzzy-message-consolidation telemetry |

**Sweep finding:** the audit doc cites only `=== INDEX READ-BACK ===` (B6). Production must pick `=== BIN-COUNTER MODE ===`'s ordering relative to all four blocks, and must also pick whether to follow the `@verbose_output` push convention (used by 3 of 4) or the direct-print convention (used by `=== BENCHMARK DATA ===`). The push convention is the natural choice — the BENCHMARK DATA block uses direct print only because its TSV format is consumed by `tests/baseline/run-benchmark.sh` separately from the human-readable `-V` output.

**Recommended change:** #189 production adds `=== BIN-COUNTER MODE ===` via the `@verbose_output` push convention, following the pattern at `ltl:836` and `ltl:8116`. The block sits naturally after `=== INDEX READ-BACK ===` (which describes the data substrate the partitions were built from) and before `=== Consolidation Summary ===` (which is end-of-pipeline telemetry). Tests must not assert inter-block ordering per Decision 8.

**Owning ticket:** #189 production. See new C8 for the explicit ordering decision.

### B18 — `tests/validate-histogram-ticks.sh` baseline relevance

**Today:** three `tests/validate-*.sh` baseline tests exist:
- `tests/validate-index-readback.sh` — cited in B7 as the pattern for `=== ... ===` block regression tests
- `tests/validate-regression.sh` — broader output-regression harness
- `tests/validate-histogram-ticks.sh` — **not cited in audit doc**, but directly relevant: asserts histogram tick positioning, which depends on the `histogram_stats{$metric}{p*}` values that today come from `int(N*q)` sort-and-index (`ltl:4930-4939`) and migrate to R4's `ceil(q*N)` rank convention under #34

**Sweep finding:** under #34, tick positions can shift by 1 element per quantile (per V5's rank-convention finding). At locked default bpd=53 this shift is within the binning bound and the existing tick-position assertions may still pass; at `--percentile-precision >= 8`, the shifts become user-visible. The test scenarios must either (a) re-baseline under the new rank convention, or (b) hold the existing baselines at default precision while explicitly exercising the new precision tiers as additional scenarios.

**Recommended change:** #34 reviews `tests/validate-histogram-ticks.sh` scenarios and re-baselines as needed under the new rank convention. Per #187 R11, baseline-regression scenarios are added per-consumer; this test is the histogram consumer's existing baseline.

**Owning ticket:** #34 (Phase 3 migration).

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

### C4 — `=== BIN-COUNTER MODE ===` block wiring

**Question:** where does the block emission live? A new `print_percentile_mode()` sub called from the existing `-V` emission path? Inline in the main flow?

**Recommendation (non-binding):** follow the existing `=== INDEX READ-BACK ===` pattern (`ltl:829+`) — a dedicated subroutine called from the verbose-output assembly path. Decision 8's locked field ordering is deterministic; the subroutine's job is straight emission of the locked fields against the partition state collected so far.

### C5 — Validation harness scope at the primitive level

**Question:** primitive-level unit tests cover R1–R6 per #189 line 481. Cross-consumer composition tests verify R7 (partition independence) and R8 (lifecycle independence). Production picks the test layout — `tests/test-percentile-primitives.sh`? Inline `prove` style? Embedded in `validate-regression.sh`?

**Recommendation (non-binding):** new file `tests/test-percentile-primitives.sh` following the existing `validate-*.sh` pattern. Primitive-level cases: synthetic inputs with hand-computable expected outputs (the prototype's V1 Part A is the source material). Cross-consumer cases: multi-consumer runs with telemetry assertions per Decision 8.

### C6 — Whether the prototype code becomes production or is discarded

**Question:** Decision 10's lock language (`features/187-histogram-bin-counter-percentiles.md` line 1706) says: *"Whether the prototype code becomes the basis for #189's production code, or is discarded after lessons are extracted. #189's discretion."*

**Recommendation (non-binding):** the prototype's `parse_line`, `partition_new`, `partition_extend`, `bin_assign` (closed-form variant), `counter_update`, `percentile` subs are close to production-shape and can be ported with minor cleanup (separate the CLI parsing, drop the V1/V2/V3/V4/V5 driver subs, integrate with ltl's existing data structures). The prototype's `Devel::Size` integration, `--mem` flag, `--r2-cross-check`, `--r2-bench` paths are validation-only and stay in the prototype.

### C7 — `-hgbpd` vs. `-pbpd` flag coexistence

**Question:** the existing `-hgbpd` flag (`ltl:3609`, default 8) controls histogram-only buckets-per-decade. The new `-pbpd` flag (Decision 2, default 53) controls universal-consumer buckets-per-decade. Both will coexist literally in `adapt_to_command_line_options` unless production picks a migration path. Three options:

1. **Coexist with documented precedence.** Both flags continue to work; document that `-pbpd` overrides `-hgbpd` for the histogram consumer when both are set. Compatibility-preserving but adds documentation surface.
2. **Deprecate `-hgbpd` with grace period.** New runs warn when `-hgbpd` is used and direct users to `-pbpd`; remove `-hgbpd` in a subsequent release.
3. **Alias `-hgbpd` to `-pbpd`.** `-hgbpd` continues to parse but updates the universal `$buckets_per_decade` global. Risk: changes the default from 8 to 53 for histogram users who don't pass either flag.

**Recommendation (non-binding):** Option 1 (coexist with documented precedence) for the #189-production landing PR. Option 2 (deprecation) is filed as a separate follow-up ticket after consumer migrations land — at that point `-hgbpd` is genuinely redundant. Option 3 silently changes a default and is risky without an analyst-facing migration note.

**Why this is Bucket C, not Bucket A:** Decision 2 locks the new flag's contract but does not address legacy flag interactions. The decision is genuinely #189-production's call.

### C8 — `=== BIN-COUNTER MODE ===` block ordering vs. four existing blocks

**Question:** per B17, there are four existing `=== ... ===` blocks in the verbose-output pipeline. Where does the new `=== BIN-COUNTER MODE ===` block go in the sequence?

**Recommendation (non-binding):** insert after `=== INDEX READ-BACK ===` (which describes the data substrate the partitions were built from) and before `=== Consolidation Summary ===` (which is end-of-pipeline telemetry). Specifically: push to `@verbose_output` immediately after the existing push at `ltl:836+` and before the consolidation summary push at `ltl:8116`. Decision 8 line 1623 explicitly leaves inter-block ordering at production's discretion, so this is purely an ergonomic choice — but the recommendation tracks the data flow (substrate → percentile mode → consolidation) the analyst sees.

**Why this is Bucket C, not Bucket A:** Decision 8 explicitly defers this to production. Recommended ordering matches the natural reading order; tests assert per-block contents only, never inter-block order.

---

## Recommended PR-sized scope partition for #189 production

When #189 production is opened, the work decomposes naturally into the following PR-sized chunks (recommendation, non-binding):

1. **PR #189-1: Primitive helpers + CLI flag parsing (no `-V` output yet).** R1–R6 helpers landed in `ltl`. `--percentile-precision`, `-pbpd`, `--exact-percentiles` parsed but unused. Unit tests for R1–R6 against synthetic inputs. No consumer changes. Baseline regression passes byte-identically because nothing observable changes.

2. **PR #189-2: `=== BIN-COUNTER MODE ===` `-V` block + `consumers_active: none` state.** The block emits per Decision 8 with `consumers_active: none` because no consumer is migrated. `tests/validate-percentile-mode.sh` asserts the block's run-level header and the no-consumer-active path. Baseline regression continues to pass byte-identically.

3. **PR #189-3: `README.md`, `docs/usage.md`, `print_help()` updates.** Analyst-facing documentation lands. No code changes beyond `print_help()`. Wiki sync happens at next release.

After all three #189 PRs merge, the primitives are in place and the contract surface is documented. Consumer migrations (Phase 2 / #34 / #51) then start as their own tickets.

This partition is **a recommendation**, not a contract. #189 production may bundle PRs 1+2 into a single PR if the team prefers. The boundary that matters is between #189 production (primitives only, no consumer migrated) and consumer migrations (per-consumer baseline-regression validation).

---

## Cross-reference table — Bucket B by owning ticket

For each downstream ticket, the full set of `ltl` code surfaces it touches per this audit:

### #189 production

- B5 (memory tracking in `measure_memory_structures` at `ltl:3206-3240` — new `counter_memory_bytes` field in `=== BIN-COUNTER MODE ===`)
- B6 (`=== INDEX READ-BACK ===` block coexistence — adds new block at appropriate point)
- B7 (`tests/baseline/` — adds `tests/validate-percentile-mode.sh`)
- B8 (`print_help()` — adds three new flags)
- B9 (`adapt_to_command_line_options()` — parses three new flags; `-hgbpd` interaction per C7)
- ~~B10~~ (`README.md` does NOT contain options reference — no-op per sweep finding)
- B11 (`docs/usage.md` — analyst-facing flag explanation; natural insertion point between heatmap and histogram sections)
- **B14 (`MEMORY_FINAL` Devel::Size block at `ltl:6578-6587` — second emission site, updated alongside B5)**
- **B17 (block ordering vs. four existing `=== ... ===` blocks — see C8 for the explicit decision)**

### Phase 2 consumer migration ticket (`summary_table` + `csv_output` + incidental `histogram_view`)

- B3 (`calculate_statistics` calls at `ltl:5218`, `ltl:5367` replaced; rank-convention site `ltl:5505-5517` is the canonical engine)
- B4 row 1 (`log_messages{}{}{durations}` array at `ltl:4591` deleted)
- B5 + B14 (corresponding `Devel::Size` lines in both emission sites removed/repurposed)
- **B15 (no per-key free site today; counter store has bounded memory — release-notes memory-improvement story)**
- **B16 (consolidation-flow whole-record deletes at `ltl:1978, 2018, 2967, 3131` — verify counter-store co-location under C2; add test)**
- Release notes for the rank-convention behavior change per V5 finding 2

### #34 (Phase 3 group: `heatmap_cells`, `heatmap_markers`, `histogram_view`, `histogram_bins`, plus `time_bucket_stats`)

- B1 (`find_heatmap_bucket` at `ltl:4783-4789` deleted)
- B2 (`find_histogram_bucket_index` at `ltl:4890-4905` deleted)
- B3 (`calculate_statistics` calls inside `calculate_heatmap_buckets` at `ltl:4818-4834`, inside `calculate_histogram_buckets` at `ltl:4926-4940`, the HL twin at `ltl:4995-5004`, and inside `calculate_all_statistics` for per-time-bucket per `ltl:5218` replaced — **four rank-derivation sites total**)
- B4 rows 2, 3, 4 (`log_analysis{$bucket}{durations}`, `%heatmap_raw`, `%histogram_values` deleted)
- B5 + B14 (corresponding `Devel::Size` lines in both emission sites removed/repurposed)
- **B12 (heatmap log-spaced boundary formula at `ltl:4812` — second site of the locked formula, replaced alongside histogram `ltl:4964`)**
- **B13 (highlight-twin raw arrays `%heatmap_raw_hl`, `%histogram_values_hl` — migrate alongside base arrays)**
- **B18 (`tests/validate-histogram-ticks.sh` baseline re-evaluated under new rank convention)**
- Pre-existing entanglement: `unless $heatmap_enabled` gate at `ltl:4634` re-evaluated per #189 spec lines 391-392
- Release notes per V5 finding 2

### #51 (Phase 4 highlight subset)

- New consumer, no existing surface to remove. Inherits R3 keying for highlight subset per #187 R12.
- **Note:** B13's HL-twin observations are a precedent — Phase 3 effectively ships a limited form of highlight-subset handling for histogram before #51 lands. #51 should review B13 when scoping its own contract.

---

## What this audit unblocks

- **#189 production** — has a spec that reflects the prototype evidence (Bucket A), a cross-reference doc for everything it touches (Bucket B rows for #189 production), and recorded production-decision territory (Bucket C).
- **#34** — has a clear list of `ltl` symbols to delete or replace (Bucket B rows for #34), the rank-convention release-notes story, and the pre-existing entanglement called out.
- **Phase 2 migration ticket** (not yet opened) — has its scope clearly identified by Bucket B rows assigned to it.
- **#51** — has confirmed it inherits the unified contract by construction with no surprises.

## Spec stability

This audit refines `features/189-histogram-bin-counter-primitives.md` (Bucket A) but does not change any locked decision in `features/187-histogram-bin-counter-percentiles.md`. The contract is the same; the spec around the contract is now grounded in empirical evidence rather than theoretical projection.
