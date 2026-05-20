# Issue #213 — Consolidation regression at XL scale in v0.14.5

Investigation feature doc. Tracks attribution analysis, A/B diagnostics, and profiling.

## Phase 1 — Verify attribution (in progress)

### Step 1.1 — Cross-tabulate existing v0.14.4 vs v0.14.5 default-percentile TSV data

Issue #213 attributes the regression to `group_similar` based on `TIMING/group_similar` deltas. Per issue comment 2, this attribution should be **verified, not assumed**, before committing to profiling.

Source data: `tests/baseline/results/v0.14.4.tsv` and `tests/baseline/results/v0.14.5.tsv` (both 49 tests, same machine, released binaries). Extraction script: `tests/analysis/213-xtab.pl` (this issue).

#### Phase timing — all four XL consolidate scenarios

| Phase | month-single -n25 -g | month-single -hm -hg -g | month-many -n25 -g | month-many -hm -hg -g |
|---|---|---|---|---|
| read_files | 129.0 → 142.3 (+10%) | 135.9 → 171.3 (+26%) | 589.2 → 678.2 (+15%) | 626.1 → 846.2 (+35%) |
| initialize_buckets | 0.000 → 0.000 | 0.000 → 0.000 | 0.000 → 0.000 | 0.000 → 0.000 |
| **group_similar** | **4.47 → 105.5 (23.6×)** | **4.50 → 79.4 (17.6×)** | **24.0 → 1102.4 (46.0×)** | **26.7 → 840.7 (31.5×)** |
| calculate_statistics | 7.76 → 8.63 (+11%) | 3.10 → 3.09 (−0%) | 41.2 → 45.0 (+9%) | 18.1 → 17.8 (−2%) |
| heatmap_statistics | 0.000 → 0.000 | 14.17 → 0.06 (**−100%**) | 0.000 → 0.000 | 69.9 → 0.08 (**−100%**) |
| histogram_statistics | 0.000 → 0.000 | 22.97 → 0.01 (**−100%**) | 0.000 → 0.000 | 114.2 → 0.01 (**−100%**) |
| normalize_data | 0.003 → 0.003 | 0.003 → 0.003 | 0.003 → 0.004 | 0.003 → 0.004 |
| **total** | **141.2 → 256.4 (+82%)** | **180.6 → 253.9 (+41%)** | **654.4 → 1825.5 (+179%)** | **855.0 → 1704.7 (+99%)** |

#### Attribution conclusion: `group_similar` confirmed as the dominant cause

Share of `total` delta attributable to `group_similar` growth:

| Scenario | Δ total | Δ group_similar | Share |
|---|---|---|---|
| month-single -n25 -g | +115.2 s | +101.0 s | **88%** |
| month-single -hm -hg -g | +73.3 s | +74.9 s | **>100%** (`heatmap_statistics` + `histogram_statistics` improved by ~37 s; `group_similar` regression more than offsets that gain) |
| month-many -n25 -g | +1171.1 s | +1078.4 s | **92%** |
| month-many -hm -hg -g | +849.7 s | +814.0 s | **96%** |

The attribution holds. `read_files` did grow (+10–35%) but it is not the dominant component of the regression at any XL scenario.

Two genuine v0.14.5 *improvements* surfaced by this cross-tab and worth recording:

- `heatmap_statistics` and `histogram_statistics` dropped to ~zero on the two `-hm -hg` scenarios (the bin-counter migration from issue #34 worked as designed — no work was "hidden" by moving into another phase, and the COUNTS confirm the workload is the same).
- `rss_peak` on the two `-hm -hg` scenarios dropped 60% / 69% (v0.14.4 → v0.14.5: 3.3 GB → 1.3 GB on single-server; 16 GB → 5 GB on many-servers) thanks to the same bin-counter migration eliminating `heatmap_raw` and `histogram_values`. The consolidation regression is in spite of these wins, not because of them.

#### Workload sanity check (COUNTS)

All four scenarios show:
- `log_messages_entries` delta: +0.0% to +1.0%
- `log_occurrences_entries`: identical
- `log_stats_entries`: identical

The workload is the same. The regression is not driven by "more data."

#### Memory anomaly inside the consolidation area

Despite identical workload, the persistent consolidation structures show large v0.14.4 → v0.14.5 deltas:

| Structure | v0.14.4 → v0.14.5 (month-single -n25 -g) |
|---|---|
| `consolidation_clusters` | 507.7 → 506.7 MiB (~unchanged) |
| `consolidation_patterns` | 0.3 → 0.3 MiB (~unchanged) |
| `consolidation_key_message` | 0.1 → 2.5 MiB (**+1590%, 17×**) |
| `consolidation_unmatched` | 0.2 → 1.6 MiB (**+700%, 8×**) |
| `consolidation_key_trigrams` | (absent in v0.14.4 tsv) → 36.8 MiB |
| `consolidation_key_trigrams_norm` | (absent in v0.14.4 tsv) → 25.9 MiB |
| `consolidation_ngram_index` | (absent in v0.14.4 tsv) → 36.0 MiB |
| `consolidation_posting_size` | (absent in v0.14.4 tsv) → 1.0 MiB |

The same shape of delta appears in all four XL scenarios.

Caveat: the `consolidation_*_trigrams*` / `ngram_index` / `posting_size` structures *do exist* in v0.14.4 (they were introduced earlier — first integrated in commit `7c872fe` in v0.13.0 and tracking was added in commit `77063d5` which is included in v0.14.4 per `git tag --contains`). The v0.14.4 tsv shows them as present for some std-tier scenarios but absent for the XL consolidate rows. That means the HWM sampler in v0.14.4 may have missed them at the XL scale (they're transient per-checkpoint structures; whether they were sampled at peak appears scenario-dependent). The v0.14.4 baseline numbers for these specific structures cannot be trusted as zero — they are "unmeasured" at this scale, not "didn't exist." This investigation should not conclude the structures were absent in v0.14.4 from the tsv alone.

The 17× growth in `consolidation_key_message` (a *persistent* structure) is a more reliable signal of changed behaviour at the same workload.

### Step 1.2 — Locate the source change in the consolidation hot path

Cross-checked all v0.14.4..v0.14.5 commits to `ltl`:

```
git log v0.14.4..v0.14.5 --oneline -- ltl
```

15 commits, none with a subject mentioning consolidation, `find_candidates`, `group_similar`, `trigram`, or `ngram`. The commits are: issue #34 phases (bin-counter migration), issue #189 (percentile mode primitives + CLI + docs), issue #185 (histogram tick marks), issue #179 (index read-back), and version bump.

Confirmed via diff search:

```
git diff v0.14.4..v0.14.5 -- ltl | grep -E "consolidation|find_candidates|trigram|ngram_index"
```

returns **only** three lines — all context lines inside `measure_memory_structures`. No `+` / `−` lines touching consolidation logic, ngram code, or `group_similar_messages`.

**Conclusion: the consolidation source code is byte-identical between v0.14.4 and v0.14.5.** The `group_similar_messages`, `build_consolidation_ngram_index`, `find_candidates`, `get_consolidation_trigrams`, and surrounding helpers are unchanged.

This is the most important finding so far, because it changes what profiling should look for.

### Open question: what caused unchanged code to slow down 23–46× on identical workload?

Possibilities — in approximate order of plausibility:

1. **Different inputs reaching `group_similar`.** Something upstream (e.g., during `read_files` or earlier per-message processing) now populates the consolidation hash structures differently — e.g., longer `$capped_msg` values per log_key, or more keys per `cat_gk`, or different `$log_key` shapes. The 17× growth in `consolidation_key_message` at constant `log_messages_entries` (~1300) implies either ~17× more entries are being retained at the measurement moment, or each entry's stored string is ~17× longer. Either case would balloon trigram-extraction and ngram-intersection costs without touching the consolidation code.
2. **Different shared/global state by the time `group_similar` runs.** New globals added in v0.14.5 (issue #34 partition primitives, issue #189 percentile primitives) might subtly change how an earlier hot path populates the consolidation hashes.
3. **Heap layout / GC interaction.** v0.14.5 carries a much heavier memory-tracking instrumentation footprint (per the new `partition_state` consumers). Unlikely to explain 23–46× at this magnitude but cannot be ruled out a priori.
4. **Timing-attribution artifact.** Some lazy initialization (e.g., first call to a new partition-state primitive) may charge wall-clock time against `group_similar` if triggered there. Worth checking but does not naturally explain a workload-proportional scaling (regression grows with input size).

(1) is the leading hypothesis. The investigation should focus on what populates `consolidation_key_message` / `consolidation_unmatched` and verify whether each per-key string grew, or whether more keys are now being retained for the checkpoint phase.

## Phase 2 — `--exact-percentiles` A/B diagnostic

Per issue #213 comment 1. Goal: determine whether disabling v0.14.5's new bin-counter / percentile path (#34 + #189) via `-ep` recovers v0.14.4 timings for `group_similar`, or whether the regression survives the revert.

`--exact-percentiles` was introduced in v0.14.5; v0.14.4 has no such flag (its default code path is the legacy sort-based percentile path). So the A/B is a three-way comparison, not four-way:

- v0.14.4 default = legacy path (reference) — `tests/baseline/results/v0.14.4.tsv`
- v0.14.5 default = new bin-counter path — `tests/baseline/results/v0.14.5.tsv`
- v0.14.5 `-ep` = legacy path running on v0.14.5 codebase — captured this phase

Captured fresh on the same machine, single run each, same files as the existing baselines.

### A/B results — `month-single-server-access-logs-top25-consolidate` (`-bs 1440 -n 25 -g`)

| Phase | v0.14.4 default | v0.14.5 default | v0.14.5 `-ep` |
|---|---:|---:|---:|
| read_files | 128.96 s | 142.26 s | 146.83 s |
| **group_similar** | **4.47 s** | **105.51 s** | **106.12 s** |
| calculate_statistics | 7.76 s | 8.63 s | 8.40 s |
| heatmap_statistics | 0.000 | 0.000 | 0.000 |
| histogram_statistics | 0.000 | 0.000 | 0.000 |
| normalize_data | 0.003 | 0.003 | 0.003 |
| **total** | **141.20 s** | **256.40 s** | **261.35 s** |
| rss_peak | 1699.3 MiB | 1707.0 MiB | 1688.2 MiB |

`-ep` is essentially identical to v0.14.5 default (`group_similar` delta is 0.6 s; `total` delta is 5 s — within run-to-run noise). No histogram is computed in this scenario, so the new percentile primitives never engage; that the `-ep` flag has near-zero effect on this run is consistent.

### A/B results — `month-single-server-access-logs-heatmap-histogram-consolidate` (`-bs 1440 -hm -hg -g`)

| Phase | v0.14.4 default | v0.14.5 default | v0.14.5 `-ep` |
|---|---:|---:|---:|
| read_files | 135.87 s | 171.35 s | 160.64 s |
| **group_similar** | **4.50 s** | **79.41 s** | **175.12 s** |
| calculate_statistics | 3.10 s | 3.09 s | 3.55 s |
| heatmap_statistics | 14.17 s | 0.06 s | 12.60 s |
| histogram_statistics | 22.97 s | 0.01 s | 24.16 s |
| normalize_data | 0.003 | 0.003 | 0.003 |
| **total** | **180.62 s** | **253.93 s** | **376.08 s** |
| rss_peak | 3326.7 MiB | 1333.8 MiB | 3340.4 MiB |

`-ep` correctly reverts:
- `heatmap_statistics` and `histogram_statistics` back to v0.14.4-level values (12.6 s + 24.2 s vs 14.2 s + 23.0 s);
- `rss_peak` back to v0.14.4-level (3340 MiB vs 3327 MiB) — the heatmap_raw / histogram_values memory bloat returns.

So the new percentile/bin-counter path is properly disabled by `-ep`. But `group_similar` does **not** recover — it stays at 175.1 s (still 39× worse than v0.14.4's 4.5 s; actually *worse* than v0.14.5 default's 79.4 s on this scenario).

The 79 → 175 s gap between default and `-ep` on the hm-hg scenario is itself interesting. Most plausible explanation: heap-pressure interaction. Under `-ep` the per-bucket `heatmap_raw` + `histogram_values` structures balloon RSS to 3.3 GB; the same `group_similar` work then runs against a fatter heap and slower Perl GC. This is a second-order effect, not the primary regression — the primary regression is the unchanged 100×+ slowdown that persists under *both* code paths.

### A/B conclusion

Per the decision tree in issue #213 comment 1:

> If `--exact-percentiles` runs still show the regression vs v0.14.4, the cause is in code that runs regardless of percentile path. The search broadens to the other v0.14.5 changes (#179, #185, #201, or shared infrastructure touched by #34's "primitive amendments" commit).

**Outcome: regression survives `-ep` on both targets.** The new bin-counter / percentile path (issues #34 + #189) is ruled out as the cause. Confirms what the source diff already showed in Phase 1 — the consolidation code is byte-identical; only upstream/shared changes could produce this.

### Suspect commits narrowed

From the 15 commits in `v0.14.4..v0.14.5 -- ltl`, removing the now-eliminated #34/#189 work and the version bump leaves:

| Commit | Issue | Notes |
|---|---|---|
| `946bb06` `a6b32f2` `d19e0b3` `af1f65d` `8300f03` `a177c47` | #179 | Index read-back (six steps) — runs during `read_files`; could affect what's stored in `log_messages` and downstream key generation. |
| `4f71a03` | #185 | Histogram tick marks — **eliminated**: the top25 -g run has no histogram and still regresses identically. |
| `db0349d` | #34 phase 3 commit 1 ("primitive amendments for #201 architecture") | Adds globals / scaffolding for partition state. Despite being labeled #34, this commit's content is shared infrastructure that runs regardless of `-ep`. |
| (no dedicated #201 commit in `v0.14.4..v0.14.5 -- ltl`) | #201 | The #201 display geometry consumers landed via the #34 phase 3 commits (`ffa8272`, `64af4d1`, `84bb04d`). These are guarded by `-ep` for the consumer-side work; the *primitive scaffolding* in `db0349d` is unguarded. |

Working suspect list for the next phase: **#179 (index read-back) and `db0349d` (#201 primitive scaffolding)**, in roughly that order of suspicion. #179 changes what flows into `log_messages` (and therefore into `consolidation_key_message`), which is the cleanest mechanism to explain the 17× growth in stored-string size at constant entry count.

## Phase 3 — Verbose `-V` Consolidation Summary A/B (overturns the premise of #213)

Per user prompt. Goal: compare the per-`cat_gk` consolidation statistics (`find_candidates calls`, S1-S6 stage counts, checkpoints, patterns, final-pass `Windows processed`) between v0.14.4 and v0.14.5 on the same target, to see whether the 23× wall-clock regression corresponds to a 23× growth in any algorithmic quantity.

Captured fresh on the current machine:
- v0.14.4: `git show v0.14.4:ltl > /tmp/ltl-v0.14.4`, then `/opt/homebrew/bin/perl /tmp/ltl-v0.14.4 --disable-progress -V -mem ...` → `/tmp/v144-verbose.out`
- v0.14.5: current `./ltl` (HEAD of main) with the same args → `/tmp/v145-verbose.out`
- Same target: `month-single-server-access-logs-top25-consolidate` (`-bs 1440 -n 25 -g`, 28 files, ~12M lines, 1.5 GB)
- Sequential, no CPU contention.

### Consolidation Summary diff — dominant `cat_gk` `plain|200`

| Metric | v0.14.4 fresh | v0.14.5 fresh | Δ |
|---|---:|---:|---:|
| **Streaming Keys seen** | **2,766,004** | **2,766,004** | **identical** |
| Streaming S1 Inline match | 2,735,954 | 2,735,954 | identical |
| Streaming S2 Ceiling filter | 24 | 24 | identical |
| Streaming S4 Pairwise discovery | 1,010 | 1,010 | identical |
| Streaming S4 Re-scan absorbed | 23,706 | 23,706 | identical |
| Streaming S5 Unmatched | 41 | 41 | identical |
| Streaming S6 Evicted | 5,269 | 5,269 | identical |
| Streaming Eviction EMA | 42.9% | 42.9% | identical |
| **Streaming `find_candidates` calls** | **3,077** | **3,077** | **identical** |
| Streaming S3 attempts | 2,472 | 2,472 | identical |
| Streaming S3 skipped | 19,991 | 19,991 | identical |
| Streaming Cross-cluster merges | 59 | 59 | identical |
| Streaming Cleanup keys scanned | 24,716 | 24,716 | identical |
| Streaming Checkpoints | 8 | 8 | identical |
| Streaming Patterns | 261 | 261 | identical |
| Final Pass Keys seen | 5,338 | 5,338 | identical |
| Final Pass S3 Pattern match | 3,580 | 3,592 | +0.3% |
| Final Pass Windows processed | 123 | 128 | +4% |
| **Final Pass `find_candidates` calls** | **1,143** | **1,147** | **+0.4%** |
| Final Pass S4 Pairwise | 322 | 338 | +5% |
| Final Pass S4 Re-scan | 554 | 547 | -1% |
| Final Pass New patterns | 161 | 169 | +5% |
| Pass 2 S3 Absorbed | 328 | 317 | -3% |
| Reduction | 2,766,004 → 817 | 2,766,004 → 814 | identical 100% |

**All algorithmic counters are identical or near-identical between versions.** No meaningful workload-shape change. Same number of candidates considered, same number of trigram lookups, same eviction behaviour, same reduction outcome.

This invalidates the "input shape changed" / "consolidation_key_message growth → more work" hypotheses from Phase 1. The work being done is the same.

### Same-machine TIMING comparison

| Phase | v0.14.4 fresh | v0.14.5 fresh | Δ |
|---|---:|---:|---:|
| read_files | 151.49 s | 145.09 s | **−4%** |
| **group_similar** | **108.48 s** | **103.98 s** | **−4%** |
| calculate_statistics | 10.13 s | 8.69 s | −14% |
| **total** | **270.10 s** | **257.76 s** | **−5%** |

**v0.14.5 is ~5% faster than v0.14.4 on the same machine. There is no consolidation regression.**

### What the baseline TSV comparison was actually measuring

The 23–46× XL "regression" came from comparing `v0.14.4.tsv` against `v0.14.5.tsv`. Per the commit message of `efa5ea1`:

> "This commit re-runs all 35 std-tier tests against the release/0.14.4 HEAD ... The 14 XL month-* rows are **preserved from the original capture** (44 rows/test, missing #171's metrics) — **their corpus isn't available on the machine that did this backfill.**"

Confirmed by inspecting `FILES` rows: the XL v0.14.4 entries record `/Users/gregeva/Documents/GitHub/logtimeline/...` paths; the v0.14.5 XL entries record `/Users/geva/Documents/GitHub/logtimeline/...` paths. **Different machines.**

So the XL baseline comparison was cross-machine, not cross-version. The "regression" mostly reflects how much slower the current machine is than the machine that captured the original v0.14.4 XL rows. (For context: this machine takes ~108 s of `group_similar` on v0.14.4 source; the other machine took 4.47 s — that's a ~25× hardware speed difference for this workload, not a code regression.)

The std-tier XL story is consistent with this: the backfill re-ran std tests on the current machine; v0.14.5 std-tier consolidate scenarios all showed slight *improvements* in the comparison (per the issue body itself). That is, when v0.14.4 and v0.14.5 were captured on the same machine, no regression appeared. Only the XL rows — where v0.14.4 came from a different machine — showed the dramatic "regression."

### Phase 3 conclusion

**There is no v0.14.4 → v0.14.5 consolidation regression at XL scale.** The reported regression is a baseline-comparison artifact caused by mixing same-machine v0.14.5 captures against different-machine v0.14.4 captures for the XL corpus. Recovery work in the consolidation code is not needed.

The earlier Phase 1/2 sub-findings remain valid as factual observations but their *interpretation as a regression* falls away:

- The consolidation source is byte-identical between v0.14.4 and v0.14.5 (true, and consistent with there being no regression).
- The `-ep` A/B showed no change vs default — also consistent with no underlying regression in the consolidation path.
- The 17× growth in `consolidation_key_message` and the "ngram_index missing from v0.14.4 XL rows" anomaly is also explained: it's an HWM sampling difference / different-machine measurement variance, not a behavioural change.

### Recommended next actions

1. **Re-capture v0.14.4 XL baseline on the current machine** so `tests/baseline/results/v0.14.4.tsv` is fully same-machine vs `v0.14.5.tsv`. Replace the 14 preserved XL rows with fresh captures from `/tmp/ltl-v0.14.4`. The two fresh captures already in `/tmp/v144-verbose.out` and `/tmp/v145-verbose.out` are usable starting points; ideally re-run all four XL consolidate scenarios (top25, hm-hg, both single and many).
2. **Update `tests/baseline/results/comparison-v0.14.4-vs-v0.14.5.md`** once the same-machine baseline exists — the existing comparison will show ~−5% across the board for XL consolidate, in line with the std-tier results, instead of the spurious +179% / +99%.
3. **Close issue #213** with a postmortem comment summarizing the cross-machine baseline diagnosis. Reference this feature doc. The issue should not drive any code change.
4. **Issue #209 (FILES portability)** — this incident is a concrete example of the harm. Worth raising in that thread that comparing TSVs across machines silently produces false regressions of arbitrary magnitude. The `FILES` rows already record the per-row machine path; `compare-results.sh` could surface a warning when the `FILES` paths of two rows differ, or refuse to compare with a `--allow-cross-machine` flag.
5. **No profiling needed.** Cancel the pending NYTProf task in this investigation.

### Lesson

Phase 1 confirmed the *attribution* (where the time was going) and Phase 2 narrowed the *suspect set* — both valid analytical steps — but neither questioned whether the baseline numbers themselves were comparable. The verbose `-V` A/B was the diagnostic that exposed the baseline as cross-machine. Worth recording as a generally-applicable instinct: when source-diff and code-analysis turn up no plausible mechanism for a measured regression, re-validate the measurement before continuing the investigation.
