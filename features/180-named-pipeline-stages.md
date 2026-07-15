# Feature: Named pipeline stages — detect, parse, accumulate, finalize, render

## Status

- **Issue:** #180 — **Drop 0 of the 0.17.0 merge train** (parent: #23)
- **Planned:** 2026-07-15 walkthrough session (this document is the repo-side source of truth for the drop; the issue body is its GitHub-side snapshot)
- **Umbrella:** `features/log-format-registry.md` — shared requirements and locked decisions D1–D22 live there, not here

## Overview

Name the five stages of ltl's implicit pipeline — **detect, parse, accumulate, finalize, render** — with explicit entry-point subroutines and documented inter-stage contracts. `## MAIN ##` becomes a thin top-level dispatcher. **Zero behavioral change**: existing subs become callees of named stages; nothing intra-stage is restructured.

Why it is Drop 0: it converts the behavior-bearing drops that follow into bounded refactors-between-named-stages (Drop 1 #58 inserts the format registry into `detect`; Phase 2 #59, later release, adds bucket lifecycle inside `finalize`), and it calibrates the merge-train regression gate itself — a change that must be byte-identical across every golden file proves the gate works before any behavioral drop lands.

## Requirements

### R1 — Named stage entry points

Five subroutines — `pipeline_detect()`, `pipeline_parse()`, `pipeline_accumulate()`, `pipeline_finalize()`, `pipeline_render()` — each with a documented contract: what it receives, what it emits.

### R2 — Stage semantics: roles, not sequential temporal phases

The stages are **roles with contracts — call surfaces crossed repeatedly — not one-pass-each phases**. Two standing facts of the codebase require this:

1. **Fuzzy consolidation (#96) is a streaming mechanism, not a post-read step.** S1 inline matching runs per line inside the read pass (absorbing 98–99.9% of keys as they stream); S2–S4 checkpoints fire mid-stream at intervals; the post-read `group_similar_messages()` call is a final pass, not the mechanism. Finalize-role work firing during the read pass is an existing, proven pattern — Phase 2's bucket-close finalization (later release) is the second instance of the same shape.
2. **The read pass cycles detect → parse → accumulate per line.** The entry points name the roles; the per-line loop legitimately crosses all three per iteration.

**Hard constraint:** this refactor documents where the role boundaries fall inside `read_and_process_logs()`; it must NOT move the inline S1/checkpoint machinery (or any other mid-stream finalize-role work) to make the stages look cleanly sequential — that would be a behavioral change, which this drop forbids.

### R3 — Stage contracts take resolved demand and capture modes as explicit inputs

The statistics demand registry (#305/#303, shipped v0.16.0) resolves a declarative producer/consumer map (`@STAT_CONSUMERS` → `resolve_statistics_group_demand()`) once after full option settlement; demand gates **capture** (read-loop accumulators — accumulate-role code), **compute** (derivation blocks in `calculate_statistics`/`calculate_statistics_bin` — finalize-role code), and **storage** (undemanded fields never written). Per-surface data-model capture modes (#266, `choose_data_model()`) are similarly resolved at read start.

Demand resolution is effectively a plan step ahead of the pipeline whose outputs thread through multiple stages. Therefore each stage's documented contract lists **resolved demand and resolved capture modes as inputs alongside data**. `calculate_all_statistics` is "the statistics step for whatever the consumer map demands," not "the statistics step."

**Hard constraint:** resolver timing (after every option is settled, including the `-os` deprecation fold) and every capture/compute/storage gate are untouched.

### R4 — Audited stage inventory (2026-07-15, post-v0.16.0 tree)

The dispatcher's top-level order, per the code audit (function names are the durable references):

| Order | Sub | Stage role |
|---|---|---|
| 1 | `read_index_file()` | pre-read: prior-run metadata hints (#179) — a detect-stage input |
| 2 | `read_and_process_logs()` | detect + parse + accumulate interleaved per line; consolidation S1/checkpoints (finalize-role) mid-stream; per-line streaming partition accumulation via `counter_update()` under bin capture modes (`%log_messages_counters`, `%bucket_stats_counters` + highlight variants, `_single` inline producer); UDM extraction + #22 global delta; #256 profile folding after range filtering |
| 3 | `initialize_empty_time_windows()` | accumulate |
| 4 | `group_similar_messages()` | finalize (consolidation final pass; gated on `-g` sensitivity) |
| 5 | `calculate_all_statistics()` | finalize (demand-gated) |
| 6 | `finalize_message_stats_unified()` / `finalize_bucket_stats_unified()` | finalize (#187/#189 end-of-parse re-bin of streaming partitions) |
| 7 | `calculate_heatmap_buckets()` / `calculate_histogram_buckets()` | finalize — each a #266 data-model dispatcher (raw → exact path, bin → unified finalize) |
| 8 | `normalize_data_for_output()` | render (prep; includes layout calculation before scaling) |
| 9 | `detect_index_drift()` + `emit_*_verbose()` family + `print_verbose_output()` | render (verbose/telemetry surface) |
| 10 | `print_bar_graph()`, `print_histograms()`, `print_summary_table()`, `print_message_summary()`, `print_threadpool_summary()`, CSV output lifecycle | render |
| 11 | `write_index_file()` | render (post-output; #46) |

**Hard constraint:** the `measure_memory_structures()` / `memory_debug_decomposition()` instrumentation checkpoints woven between steps keep their positions — their labels are observable `-mem`/debug output.

Note the drift direction: v0.15.x–v0.16.0 already moved the pipeline toward the target architecture (streaming accumulation, demand gating, data-model dispatch, unified finalize). This drop names what exists today faithfully; it does not idealize the pipeline back to its 2026-05 shape.

## Out of scope

- Per-bucket open/close hooks for the sliding window (#59 — Phase 2+4 release)
- Replacing the chained-regex detection (#58 — Drop 1)
- Moving consolidation's inline S1/checkpoint machinery out of the read pass (forbidden — behavioral change)
- Reorganizing intra-stage logic (e.g., splitting `calculate_all_statistics`)
- Performance work beyond what falls out naturally

## Decisions

Locked decisions governing this drop live in the umbrella doc: D15 (memory target reframe), D19 (#187/#189 absorption). Drop-local decisions reached in the 2026-07-15 walkthrough:

- **Role-not-phase stage semantics** (R2) — driven by the consolidation-interleaving correction (architect, 2026-07-15).
- **Demand + capture modes as stage-contract inputs** (R3) — driven by the demand-registry review (architect pointed to the #305 producer/consumer map; audit confirmed its reach across stages).

## Acceptance criteria / merge gate

- [ ] Five named entry-point subroutines exist with documented contracts (data + demand + capture-mode inputs).
- [ ] `## MAIN ##` is a thin top-level dispatcher calling the stages in order.
- [ ] Demand-resolution timing and all capture/compute/storage gates untouched — `-V statistics-demand` before/after equality on identical invocations.
- [ ] All golden-file tests byte-identical; full `tests/validate-*.sh` suite exits 0; runtime-warning-clean stderr.
- [ ] Instrumentation checkpoints keep their positions and labels.
- [ ] Benchmark probes show no regression beyond noise (targeted probes; no XL suites during development).
- [ ] Stage contracts documented (inline + short addendum to `docs/staged-processing-pipeline.md`).
- [ ] Pre-existing functions become callees of the named stages.

## Related

- Parent umbrella: `features/log-format-registry.md` (#23)
- `docs/staged-processing-pipeline.md` — S1–S5 architectural template (#96)
- #305/#303 — demand registry (`features/305-shape-moment-extended-percentile-demand.md`)
- #266 — data-model dispatch; #187/#189 — unified bin-counter primitives (`features/189-histogram-bin-counter-primitives.md`)
