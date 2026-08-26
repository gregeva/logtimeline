# V4 — `-V histogram-bin-counters` output under the proposed representation

Mirror of #189 V4 for the #426 revalidation. Instrument: `prototype/426-revalidate-v4.pl`
(driver `prototype/426-revalidate-v4.sh`); library `prototype/426-revalidate-lib.pm`
(unchanged). Fixture: `logs/AccessLogs/localhost_access_log.2025-03-21.txt` — 22,264
lines, 14,062 positive durations, 635 keys (`revalidate-v4-all.txt` line 1). All numbers
below are from files under `prototype/426-results/revalidate-v4-*`.

### Hypothesis

The Decision 8 section, as ltl renders it today (`emit_bin_counter_mode_verbose`,
ltl:4625–4776, the #293 form: `data_model_precision: <TIER> (<source>)` + per-consumer
blocks), renders field-for-field and value-for-value from arm S (span-only columnar,
verbatim geometry) with only `counter_memory_bytes` differing, and renders from arm G
(shared grid) with five Decision 5/Decision 4 fields structurally constant. The
precision lever (Decision 2) and the opt-out (Decision 7) do not depend on the
representation.

### Method

1. Real ltl captured once per scenario the current lever can express:
   `-mdm bin` (default tier 5), `-mdm bin -dmp 7`, `-mdm bin -dmp 9`, `-mdm raw`
   (`revalidate-v4-ltl-real*.txt`).
2. The six #189 V4 scenarios mapped onto today's ltl. #293 dissolved `-pbpd` and
   `--percentile-precision` (both strings: 0 occurrences in `ltl`); the only knob is
   `--data-model-precision 1..9`, and the opt-out is `-mdm raw` (there is no
   `--exact-percentiles`). Mapping:

   | # | #189 V4 scenario | today | prototype rendering |
   |---|---|---|---|
   | 1 | default | tier 5 → bpd 53 | rendered, all arms |
   | 2 | `--percentile-precision 7` | `-dmp 7` → bpd 115 | rendered, all arms |
   | 3 | `-pbpd 100` | **unreachable** (flag dissolved) | substitute `-dmp 9` → bpd 616, all arms |
   | 4 | `-pbpd` + `--percentile-precision` | **unreachable** (no competing flag) | not rendered; reason printed |
   | 5 | overflow audit (`--max-rebins 0`) | no ltl flag (prototype hook) | T/S with `max_rebins=0`; G rendered (no cap exists) |
   | 6 | `--exact-percentiles` | `-mdm raw` → `path: user_opt_out` | rendered, all arms |

3. Per scenario the script builds T, S, G from the same samples, prints the T/S digest
   comparison **before** any block (exit non-zero on divergence), then renders each
   arm's section through one renderer that copies the emitter's lines, including the
   `// 0` defaulting of missing telemetry fields. Inactive consumer blocks are copied
   from the real run (`time_bucket_stats: user_opt_out` because `-mdm` pins
   message-stats only). `out_of_range_bounded` is aggregated over every key with ltl's
   precedence (`calculate_statistics_bin`, high > low > none) at the native `ceil(q·N)`
   rank; ltl aggregates only the keys its statistics pass walks.
4. For G two blocks per scenario: the locked field set exactly as today's emitter would
   print it, and a **proposed** variant (labelled, not locked).
5. `revalidate-v4-diff.txt`: `diff` of the real section against the prototype's T and S
   blocks (`counter_memory_bytes` masked, both values reported), field-name diff and raw
   value diff against G.
6. Timing after parity: one arm per process, scenarios 1 and 3, one warmup + 3 timed
   runs of telemetry + audit + render; Devel::Size of the store and RSS delta of the
   store build (`revalidate-v4-timing-{T,S,G}.txt`, summarised in
   `revalidate-v4-timing.tsv`).

### Result

**Parity (revalidate-v4-all.txt lines 4, 173, 342, 520; ALL PARITY PASS line 782).**

| scenario | bpd | T digest = S digest | G digest |
|---|---|---|---|
| 1 | 53 | `fefe624f…` yes | `08d50bed…` |
| 2 | 115 | `6e55c317…` yes | `36ce32c7…` |
| 3 | 616 | `bb067777…` yes | `12d69796…` |
| 5 (cap 0) | 53 | `ee54df46…` yes | `08d50bed…` (= scenario 1: the cap has no meaning under G) |

**Real ltl vs prototype T and S (revalidate-v4-diff.txt).** With `counter_memory_bytes`
masked the sections are byte-identical for scenarios 1, 2, 3 and 6 (`IDENTICAL` ×8: T and
S each). Field names of the G block are identical to the real section in every scenario
(`FIELD NAMES IDENTICAL` ×4).

| scenario | field | real ltl | T | S | G (locked set) |
|---|---|---|---|---|---|
| 1 (bpd 53) | partition_count | 635 | 635 | 635 | 635 |
| | total_rebin_events | 1 | 1 | 1 | 0 |
| | max_partition_bins | 397 | 397 | 397 | 0 (`// 0`) |
| | partitions_with_overflow/underflow_count | 0 / 0 | 0 / 0 | 0 / 0 | 0 / 0 |
| | rebins_per_partition | p50=0 p95=0 p99=0 max=1 | same | same | all 0 |
| | out_of_range_bounded | all none | all none | all none | all none |
| | counter_memory_bytes | 1,522,959 | 1,598,689 | 650,952 | 445,386 |
| 2 (bpd 115) | max_partition_bins | 862 | 862 | 862 | 0 |
| | counter_memory_bytes | 2,353,215 | 2,451,241 | 793,600 | 587,274 |
| 3 (bpd 616) | max_partition_bins | 4,619 | 4,619 | 4,619 | 0 |
| | counter_memory_bytes | 9,180,903 | 9,336,673 | 1,938,664 | 1,728,466 |
| 6 (`-mdm raw`) | summary_table block | `path: user_opt_out` only | identical | identical | identical |

(revalidate-v4-diff.txt; revalidate-v4-all.txt lines 22–28, 64–70, 106–112, 191–197,
233–239, 275–281, 360–366, 402–408, 444–450.)

**Scenario 5 — overflow audit (revalidate-v4-all.txt lines 529–544, 571–586, 612–628).**
Under `max_rebins=0` T and S both report `total_rebin_events: 0`, `max_partition_bins: 265`
(seed only, 53×5), `partitions_with_overflow_count: 1`, overflow_total=6,
`out_of_range_bounded: p1..p75=none p90..p99999=high` — identical lines in both arms. G
under the same run: rebins 0, overflow 0, every quantile `none`, digest unchanged from
scenario 1 — the cap and the audit have nothing to act on.

**G proposed block (revalidate-v4-all.txt lines 139–152, 308–321, 477–490).** Replacement
telemetry rendered per bpd:

| bpd | grid_index_range | span_slots p50/p95/p99/max | counter_slots_total | counter_memory_bytes |
|---|---|---|---|---|
| 53 | 0..231 | 1 / 51 / 80 / 191 | 6,536 | 445,386 |
| 115 | 0..503 | 1 / 110 / 173 / 412 | 13,439 | 587,274 |
| 616 | 0..2695 | 1 / 588 / 923 / 2,202 | 69,272 | 1,728,466 |

Rendered form (bpd 53, lines 139–152):

```
consumer: summary_table
  path: unified
  partition_keying: (category, log_key)
  partition_count: 635
  grid_bpd: 53
  grid_index_range: 0..231
  span_slots: p50=1 p95=51 p99=80 max=191
  counter_slots_total: 6536
  counter_memory_bytes: 445386
  percentiles_emitted: p1 p5 p10 p25 p50 p75 p90 p95 p99 p999 p9999 p99999
  out_of_range_bounded: p1=none ... p99999=none
```

**Timing and memory (revalidate-v4-timing.tsv; one arm per process; median of 3, min–max).**

| arm | bpd | telemetry+audit+render | Devel::Size bytes | RSS delta of store build |
|---|---|---|---|---|
| T | 53 | 0.1805 s (0.1803–0.1846) | 1,521,689 | 1,456 kB |
| S | 53 | 0.0225 s (0.0220–0.0226) | 708,808 | 512 kB |
| G | 53 | 0.0190 s (0.0186–0.0190) | 503,490 | 208 kB |
| T | 616 | 1.9239 s (1.9119–1.9288) | 9,235,513 | 9,264 kB |
| S | 616 | 0.0826 s (0.0817–0.0835) | 2,756,960 | 1,168 kB |
| G | 616 | 0.0694 s (0.0690–0.0697) | 2,554,858 | 1,168 kB |

The audit walk dominates (12 quantiles × 635 keys; T's `percentile` sums the dense bins
array on every call, S/G walk only the span) — the same shape as #426 F19's population
pass. Timing here is a by-product; V4 is a rendering aspect.

### Surprises

1. **`counter_memory_bytes` is not reproducible across processes even in real ltl.**
   Three identical runs: 1,522,959 / 1,482,319 / 1,482,319 (`revalidate-v4-ltl-real-memvar.txt`);
   the prototype's T store also moved between processes (1,598,689 in the all-scenario
   run, 1,521,689 in the timing run). Devel::Size of a hash depends on its bucket-array
   size, which varies with hash-seed randomisation. The field was never a stable
   assertion target; the #189 V4 report did not test it for stability.
2. **Two of the six #189 scenarios are unreachable in today's ltl.** #293 removed the
   numeric `-pbpd` and the `--percentile-precision` tier flag; Decision 8's
   `; overridden` annotation, the `n/a (-pbpd N)` rendering (#189 V4 finding 2) and the
   `buckets_per_decade:` line no longer exist. The #189 V4 scenario set predates the
   amendment; this report records the mapping rather than reproducing dissolved output.
3. **The opt-out path never touches a store.** Under `-mdm raw` the real section is
   `path: user_opt_out` with no counter store built (`finalize_message_stats_unified`
   returns on an empty `%log_messages_counters`); the prototype's three arms print the
   identical block because there is nothing arm-specific to print.

### Findings and actions

1. **Every Decision 8 field survives unchanged under S.** Byte-identical sections
   (memory masked) against real ltl at bpd 53, 115, 616 and under `-mdm raw`; identical
   T/S audit lines under the overflow cap. `counter_memory_bytes` differs (S is 2.4–4.8×
   smaller: 650,952 vs 1,598,689 at 53; 1,938,664 vs 9,336,673 at 616 — same-process
   Devel::Size) — a value difference, which the Decision 8 stability contract permits
   ("field *values* may evolve"). **Action:** none for S; Decision 8 needs no amendment
   for P8/P9.
2. **Five Decision 8 fields are vacuous under G:** `total_rebin_events` (always 0),
   `max_partition_bins` (no such quantity; today's emitter would print 0 through `// 0`),
   `partitions_with_overflow_count` / `partitions_with_underflow_count` (always 0 — an
   index exists for every positive value), `rebins_per_partition` (all 0), and the
   Decision 4 audit `out_of_range_bounded` (constant `none`; `percentile` under G can
   never return high/low). They are the Decision 5 telemetry whose stated purpose was
   "empirical seed-heuristic tuning" — under P10 there is no seed and no heuristic. The
   field *names* still parse, so nothing greps break, but the lines carry no
   information. **Action:** if P10 is locked, Decision 8 needs an amendment entry
   (field-name changes require one per the stability contract); the field set as-is is
   not wrong, only inert.
3. **Minimal amendment (proposal, not a lock).** Keep `path`, `partition_keying`,
   `partition_count`, `counter_memory_bytes`, `percentiles_emitted`; replace the five
   inert lines with `grid_bpd: <N>`, `grid_index_range: <lo>..<hi>`,
   `span_slots: p50= p95= p99= max=` (the per-key occupied-span distribution — the
   direct successor of `rebins_per_partition` as the "how much did the geometry grow"
   signal) and `counter_slots_total: <N>` (the counter-array footprint in slots, the
   deterministic counterpart of `counter_memory_bytes`). Keep `out_of_range_bounded`
   as a constant line or drop it — its enum can only ever read `none`. Rendered above
   for bpd 53/115/616.
4. **Decision 2 (precision lever) is representation-independent.** bpd is the one
   number all three arms consume: the tier → bpd mapping resolves before any store
   exists (`bpd_for_surface`, ltl:1268), T/S digests are identical at every tier tried
   (53, 115, 616), and G's digest changes with bpd (`08d50bed…` / `36ce32c7…` /
   `12d69796…`) as the grid resolution changes. The `data_model_precision:` line is
   emitted from `$data_model_precision_level`/`_source` (ltl:4637) with no store input.
5. **Decision 7 (opt-out) is representation-independent.** The `-mdm raw` block is
   identical from all three arms and from real ltl because the bin producer never fires
   and no store is consulted. (#189 V4's `opt_out_active:` / `opt_out_notice:` header
   lines are not in today's emitter — the opt-out surfaces only as the per-consumer
   `path: user_opt_out`; that is a pre-existing drift between the Decision 8 text and
   the shipped emitter, not caused by #426.)
6. **`counter_memory_bytes` should not be used as a regression assertion in any arm**
   (finding S1). `counter_slots_total` in the proposed block is the deterministic
   alternative for G; for S the analogous count would be the sum of `pbc` or of span
   lengths — not rendered here (outside this aspect's brief).

### Reproduction

```
bash prototype/426-revalidate-v4.sh          # everything below, in order
# real ltl
./ltl --disable-progress -ni -mdm bin -V histogram-bin-counters --terminal-width 200 -bs 1440 -oe logs/AccessLogs/localhost_access_log.2025-03-21.txt > prototype/426-results/revalidate-v4-ltl-real.txt
# (plus -dmp 7, -dmp 9 and -mdm raw variants -> revalidate-v4-ltl-real-{dmp7,dmp9,raw}.txt)
# all arms, all scenarios, parity digests, locked + proposed G blocks
perl prototype/426-revalidate-v4.pl --file logs/AccessLogs/localhost_access_log.2025-03-21.txt > prototype/426-results/revalidate-v4-all.txt
# diff against real ltl -> prototype/426-results/revalidate-v4-diff.txt (see the .sh)
# timing, one arm per process
perl prototype/426-revalidate-v4.pl --file logs/AccessLogs/localhost_access_log.2025-03-21.txt --arm T --scenario 1,3 --timing 3
# counter_memory_bytes run-to-run variance in real ltl
bash prototype/426-revalidate-v4-memvar.sh > prototype/426-results/revalidate-v4-ltl-real-memvar.txt
```
