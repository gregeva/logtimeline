# Feature: Statistics-drift test harness (#224)

## Overview

This document is the **umbrella feature/requirements file** for issue #224 — a numeric-drift and algorithmic-correctness test harness for every calculated statistic `ltl` emits to its `-o` CSV outputs. It complements the structural-integrity harness shipped under #223 (`tests/validate-csv-output.sh`) and the rendered-output harness `tests/validate-regression.sh`.

The harness has three independent validation layers, each catching a different class of regression. All three are required; partial coverage is forbidden. The layers are the central design idea of this feature and are documented in detail below.

## GitHub Issue

[#224](https://github.com/gregeva/logtimeline/issues/224) — calculated-statistics drift and correctness harness.

## Status

**Planning complete 2026-05-23.** Awaiting implementation commit on branch `224-percentile-value-harness`.

## Prerequisites (all merged into `release/0.14.6`)

| Issue | What it shipped | Why #224 needed it |
|---|---|---|
| [#220](https://github.com/gregeva/logtimeline/issues/220) | `-so` accepts 17 statistic names including every percentile and shape value | Enables the `sorted-by-p999` scenario family |
| [#221](https://github.com/gregeva/logtimeline/issues/221) | MESSAGES CSV column names converged with STATS (snake_case lowercase) | The harness's column specs would otherwise carry parallel column lists |
| [#222](https://github.com/gregeva/logtimeline/issues/222) | Added `p25, iqr, p9999, p99999, skewness, kurtosis, bimodality_coef` columns | The harness must baseline against the final column set, not an intermediate one |
| [#223](https://github.com/gregeva/logtimeline/issues/223) | Structural CSV-integrity harness with rules-driven column schemas | Structural correctness is a precondition for meaningful drift comparison; #224 reads #223's rules TSVs |
| [#263](https://github.com/gregeva/logtimeline/issues/263) | Decoupled STATS CSV emission from terminal-width-driven visibility | CSV content must be deterministic per input, independent of terminal geometry |

## Background — why this harness exists

Upcoming work will intervene on how percentiles and distribution-shape values are calculated for log messages. Before that work begins, we need observable, automated assertions that detect:

1. **Drift** — `ltl`'s arithmetic changing unintentionally between releases (caught by Layer 1).
2. **Internal inconsistency** — rows where the columns don't add up against each other (e.g., a refactor that breaks `mean == duration / occurrences` but happens to keep the absolute value close to baseline; caught by Layer 2).
3. **Wrong methodology** — `ltl`'s percentile interpolation or shape formula disagreeing with the canonical reference implementation, even when no drift has occurred because yesterday's value was also wrong (caught by Layer 3 against an external NumPy/SciPy oracle).

A binary diff doesn't fit because legitimate algorithmic changes can shift values by small amounts. A tiered model with explicit advisory/blocking levels lets intentional change cross the tight tiers while preserving the loose ones. A single-layer drift check is insufficient because drift only knows what yesterday's value was — it cannot tell you whether yesterday's value was correct.

## Decision 1 — Three independent validation layers, all required

The harness validates `ltl`'s calculated values at three independent layers. All three run on every scenario; failure at any layer blocks the release at T3 or T4.

### Layer 1 — Drift (baseline comparison)

- **What it asserts**: `ltl`'s current output equals its previously captured output for the same scenario.
- **Inputs**: baseline CSV (committed to the repo), fresh CSV (just produced by `ltl … -o`).
- **Catches**: silent regressions where `ltl`'s arithmetic changes unintentionally between releases.
- **Source-log reads**: none — operates only on CSVs.
- **Tier model**: T1 byte-identical, T2 ≤1% advisory, T3 ≤5% blocking, T4 cross-column invariant violated.

### Layer 2 — Internal consistency (intra-row arithmetic)

- **What it asserts**: each row's columns are arithmetically consistent with each other. The full invariant list is locked in Decision 4 below.
- **Inputs**: each row of the produced CSV. For drift confirmation, the baseline row is also checked so a regression that violates Layer 2 in both surfaces still surfaces (rather than registering as T1 drift).
- **Catches**: arithmetic mistakes that produce internally inconsistent rows even when no drift has occurred — e.g., a refactor that breaks the derivation of `mean` but happens to keep its absolute value close to baseline.
- **Source-log reads**: none for this layer. Intra-row checks computed from the source would be tautological — the harness would just re-implement `ltl`'s sums.

### Layer 3 — External-oracle validation (algorithmic correctness)

- **What it asserts**: for the algebraically sensitive statistics (Decision 3 below), `ltl`'s output matches an independent calculation performed by NumPy / SciPy over the same input samples.
- **Inputs**: the source log file (to extract per-message duration samples) and the produced CSV (to read `ltl`'s computed statistic).
- **Catches**: methodology regressions. Drift alone cannot catch wrong methodology because drift only knows about yesterday's value, which may have been wrong too.
- **Source-log reads**: yes, but **only to feed the oracle**, never to re-implement `ltl`'s arithmetic inline in the harness. The oracle *is* the independent implementation.
- **Tier model**: same T1/T2/T3 thresholds as Layer 1, applied to (oracle vs `ltl`) deviation. T1 means perfect agreement; T3+ blocks the release.

## Decision 2 — Strict non-overlap with #223

#224 asserts **one thing #223 does not and cannot**: numeric drift and algorithmic correctness of computed values. The two harnesses share no assertions and share no scope.

### What #223 owns (and #224 must NOT re-assert)

- Column presence / absence
- Column ordering / position index
- Data-type correctness (int / float / nice / timestamp)
- Fixed-decimal rules (max decimals per column)
- Family-group consistency (all-or-nothing population within a family)
- Population correctness (required vs conditional)

### What #224 owns (and #223 does not)

- Per-cell numeric drift across releases (Layer 1).
- Per-row cross-column arithmetic consistency (Layer 2).
- Algorithmic correctness against an external oracle (Layer 3).

### Precondition contract

The harness assumes structural correctness because #223 enforces it.

- The release-process step running `validate-statistics-drift.sh` is ordered **after** `validate-csv-output.sh`. If #223 has not been run or has failed, #224's failure modes are undefined and the harness emits a single diagnostic line pointing the reader at #223.
- The comparison engine does not re-implement #223's checks. If a baseline CSV and a fresh CSV disagree on column presence or ordering, that is a #223 regression — #224 emits a single `STRUCTURE_DRIFT: run validate-csv-output.sh first` diagnostic and exits non-zero, rather than emitting per-cell T4 failures that would shadow the real diagnosis.

## Decision 3 — Layer-3 oracle scope (algebraically sensitive statistics)

External-oracle validation is reserved for statistics where the algorithm has non-trivial degrees of freedom and quiet methodology bugs are plausible.

### In Layer 3

| Statistic | Why it needs an oracle |
|---|---|
| `p1, p5, p10, p25, p50, p75, p90, p95, p99, p999, p9999, p99999` | Multiple valid interpolation methods (linear, nearest-rank, exclusive, inclusive) produce different values for small samples; the oracle pins which method `ltl` is supposed to use. |
| `std_dev` | Bessel-corrected vs population formula; the oracle pins which. |
| `cv` | `cv = std_dev / mean` — derived, but kept in Layer 3 because it propagates `std_dev`'s methodology. |
| `skewness` | Fisher vs Pearson formula; biased vs adjusted; the oracle pins which. |
| `kurtosis` | Excess vs raw kurtosis; the oracle pins which. |
| `bimodality_coef` | Sarle vs alternative formulations; the oracle pins which. |
| `iqr` | Layer 2 already checks the derivation `iqr == p75 − p25`; Layer 3 checks that p25 and p75 themselves are correct. |

### Not in Layer 3 (Layer 1 + Layer 2 are sufficient)

`min`, `mean`, `max`, `duration`, `bytes`, `mean_bytes`, `occurrences`, `count_*`, `impact`, level counts, rate counts. These have a single canonical definition; methodology bugs are implausible.

### Oracle tool

- **NumPy / SciPy.** Specifically: `numpy.percentile(samples, q, method='linear')` (or whichever method `ltl` documents), `numpy.std(samples, ddof=?)`, `scipy.stats.skew(samples, bias=?)`, `scipy.stats.kurtosis(samples, fisher=?)`. The methodology parameters are pinned per-statistic in the oracle script.
- Oracle script lives at `tests/statistics-drift/oracle/calculate-reference.py`.
- Inputs: the source log file path + the same `-i`/`-e`/`-bs` scoping `ltl` used (so the sample set is identical).
- Outputs: a JSON file keyed by `(category, message, bucket)` with the oracle's value for each Layer-3 statistic.
- The Perl comparison engine joins oracle JSON to `ltl`'s CSV and emits one tier failure per Layer-3 cell that disagrees beyond T3 tolerance.

### Tolerance for Layer 3

Layer 3 must tolerate float-format quantization: `ltl` writes at most 5 decimals per column (per #223). Oracle values are quantized to the same decimal precision before comparison.

### Layer-3 dependencies

Python 3, NumPy, SciPy. The driver fails fast with a clear install hint if any are missing; it does **not** silently skip Layer 3. A skipped layer would produce a false-pass result, which is worse than no test.

## Decision 4 — Layer-2 cross-column invariants

All invariants below apply within a single row. Failure of any is a T4. Tolerance is float-format-aware (±1 in last decimal places for derived equalities; strict for ordering).

### Duration family

- **Ordering**: `min ≤ mean ≤ max` whenever all three are populated.
- **Derivation**: `mean == duration / occurrences` (total duration divided by sample count equals the mean).

### Bytes family

- **Ordering**: `mean_bytes ≤ bytes` (mean of a non-negative set is bounded by its sum when occurrences ≥ 1).
- **Derivation**: `mean_bytes == bytes / occurrences`.

### Count family

- **Ordering**: `count_min ≤ count_mean ≤ count_max`.
- **Derivation**: `count_mean == count_sum / count_occurrences`.

### Percentile family

- **Monotonicity (full ladder)**: `p1 ≤ p5 ≤ p10 ≤ p25 ≤ p50 ≤ p75 ≤ p90 ≤ p95 ≤ p99 ≤ p999 ≤ p9999 ≤ p99999`.
- **Bounded by min/max**: `min ≤ p1` and `p99999 ≤ max`.
- **IQR derivation**: `iqr == p75 − p25`.

Each invariant is documented in the harness with its three self-documenting fields (`asserts`, `produced_by`, `contract`) so a failure surfaces both the arithmetic mismatch and the contract that says the arithmetic must hold.

## Decision 5 — Column-set scope (all-or-nothing)

The harness consumes every column whose `type` is numeric (`int` or `float`) per the `tests/csv-output/rules/{messages,stats}-columns.tsv` schema, except pure identifiers (`category`, `message`, `timestamp`). Partial coverage is forbidden — the engine refuses to start if any qualifying column is excluded.

The columns this resolves to today:

- **`occurrences`** — sample count per row; included as the divisor in derivation checks.
- **bytes family**: `mean_bytes`, `bytes`. (`bytes_nice` is `nice` type → excluded.)
- **count family**: `count_occurrences`, `count_min`, `count_mean`, `count_max`, `count_sum`.
- **duration family**: `min`, `mean`, `max`, `std_dev`, `duration`, `impact`. (`duration_nice` is `nice` type → excluded.)
- **percentile family**: `p1`, `p5`, `p10`, `p25`, `p50`, `p75`, `iqr`, `p90`, `p95`, `p99`, `p999`, `p9999`, `p99999`.
- **shape family**: `cv`, `skewness`, `kurtosis`, `bimodality_coef`. May be legitimately blank when `n < 4` or `std_dev == 0` (per #222); blank-on-both-sides registers as T1.
- **STATS-only level family**: `ERROR`, `WARN`, `INFO`, `DEBUG`, `TRACE`, `FORCE`, `DATA`, `5xx`, `4xx`, `3xx`, `2xx`, `1xx`, `Pause Young`, `Pause Full`.
- **STATS-only rate family**: `err-rate_sec/min/hr/day`, `msg-rate_sec/min/hr/day`.

In short: if `ltl` calculated it and emitted it as a number, the harness asserts drift on it.

The engine reads the canonical column list from the #223 rules TSVs at startup. **No hard-coded duplicate column list anywhere in #224.** The rules TSVs are #223's source of truth; #224 consumes them.

## Decision 6 — Scenario matrix

Scenarios are designed to **exercise statistic-calculation code paths**, not to mirror #223's curated set (which exists to exercise structural column presence and is orthogonal to drift).

The manifest at `tests/statistics-drift/scenarios.tsv` is three columns: `scenario`, `logfile`, `options`. The fourth column #223 carries (`expected_families`) does not apply here — #224 always asserts on every numeric calculated-value column and lets blank-on-both-sides register as T1.

### Golden log files

Chosen for variety of timestamp precision, sample distribution shape, and dataset size — all of which affect percentile arithmetic.

1. `logs/AccessLogs/ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log` — Apache HTTP2, **microsecond** duration values. Tests percentile math at sub-millisecond resolution.
2. `logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-07.txt` — Tomcat 9, **millisecond**, **production-scale** (277 MB). Tests percentile math at high sample counts where HDR bin counters and exact-percentile arrays diverge in behavior.
3. `logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log` — ThingWorx ScriptLog, **durationMS** with sparse, **heavy-tailed** distribution. Tests percentile math where `p999`/`p9999`/`p99999` fall in long tails.
4. `logs/Codebeamber/codebeamer_access_log.2025-10-29.txt` — Codebeamer access log, **mixed-distribution** sample set.

### Option families

Each family exercises a different statistic-affecting code path.

- **`default`** — `-bs 240 -n 25 -o` — standard bucket size, default ranking. Baseline statistics path (HDR bin counters).
- **`consolidated`** — `-bs 240 -g 90 -n 25 -o` — fuzzy consolidation at 90% changes which samples land in which message-key bucket, exercising the statistics path over consolidated sample populations.
- **`exact-percentiles`** — `-bs 240 -n 25 --exact-percentiles -o` — forces the in-memory array path instead of HDR bin counters. **Critical**: this is the path the upcoming statistic-computation work will intervene on, and the tier model exists specifically to catch drift between the two paths.
- **`sorted-by-p999`** — `-bs 240 -n 25 -so p999 -o` — ranks output by `p999` (unlocked by #220), exercising the ranking path's use of statistic values to select the top-N messages, which changes which keys appear in MESSAGES CSV.

### Apache HTTP2 microsecond duration: `-du us`

The Apache HTTP2 access log records duration in microseconds. The correct flag is `-du us` (`--duration-unit us`), which tells `ltl` the **input file's duration unit** when auto-detection cannot infer it.

This is distinct from `-ms`, which enables sub-second *timestamp* parsing — a different axis. The Apache timestamps remain at second resolution; only the duration values are sub-second. Without `-du us`, durations are interpreted at the wrong scale and every statistic (min/mean/max, std_dev, every percentile, every shape value) is wrong by 10^k.

Every Apache scenario prepends `-du us`. Other logfiles do not need `-du`: Tomcat 9 and Codebeamer are millisecond and auto-detect correctly; ThingWorx ScriptLog carries `durationMS` in the log lines themselves and auto-detects to ms.

### Resolved scenario options per logfile

- **Apache HTTP2** (4 scenarios): `-du us -bs 240 -n 25 -o` / `-du us -bs 240 -g 90 -n 25 -o` / `-du us -bs 240 -n 25 --exact-percentiles -o` / `-du us -bs 240 -n 25 -so p999 -o`.
- **Tomcat, ThingWorx, Codebeamer**: the four option-family strings without `-du`.

### Matrix size

**4 logs × 4 option families = 16 scenarios**, 32 baseline CSV files.

If 16 proves too heavy for routine release runs, the `default` and `exact-percentiles` families are the **required** ones (8 scenarios, 16 baselines); `consolidated` and `sorted-by-p999` can be tagged as `extended` and run on demand. This split is operational, not architectural — the harness implements all 16.

## Decision 7 — Failure-output format

Every failure surfaces all four self-documenting fields, machine-grep friendly:

```
FAIL [T3] scenario=apache-default file=messages key="plain|[200] GET /…" column=p99
       baseline=1234 new=1320 deviation=6.97%
       asserts: p99 latency value is stable under unchanged percentile algorithm
       produced_by: calculate_percentiles_for_bucket() in ltl
       contract: features/220-percentile-so-values.md § percentile-arithmetic-stability
       rule: abs(new-old) > 5% * old
```

For Layer-3 failures, the `asserts` and `contract` fields reference the oracle:

```
FAIL [T3-L3] scenario=apache-default file=messages key="plain|[200] GET /…" column=p99
       ltl=1320 oracle=1310 deviation=0.76%
       asserts: p99 must match numpy.percentile(samples, 99, method='linear')
       produced_by: calculate_percentiles_for_bucket() in ltl
       contract: features/224-statistics-drift-harness.md § Decision 3 — Layer 3 methodology
       rule: abs(ltl-oracle) > 5% * oracle
```

Per-scenario summary line:

```
apache-default/messages: 248 cells checked, 0 T4, 0 T3, 2 T2, 5 T1, structural=OK, L3=OK
```

## Decision 8 — Release-process integration

A new step in CLAUDE.md release process, inserted **after** #223's structural validation and **before** benchmarks:

> **Validate statistics drift:** `./tests/validate-statistics-drift.sh` — must exit 0 (no T3/T4 failures across any layer) before proceeding. T1/T2 advisories are non-blocking; review to confirm any drift is intentional.

Order rationale: structural correctness (#223) is a precondition for meaningful drift comparison. If columns are missing or mis-typed, the drift harness has nothing to compare. Benchmark runs (1+ hour) come after both validators because there's no point spending an hour on perf benchmarks if statistic-correctness is broken.

## Files

```
tests/
├── validate-statistics-drift.sh             ← driver (Bash, beside other validate-*.sh)
└── statistics-drift/
    ├── README.md                            ← usage + scope + non-overlap with #223
    ├── scenarios.tsv                        ← 16 scenarios
    ├── compare-statistics-drift.pl          ← Perl engine: drift + intra-row + Layer-3 join
    ├── oracle/
    │   └── calculate-reference.py           ← NumPy/SciPy oracle (per-scenario invocation)
    └── baselines/
        └── <scenario>/
            ├── messages.csv                 ← captured -o MESSAGES baseline
            └── stats.csv                    ← captured -o STATS baseline
```

The existing scaffolding at `tests/percentile-values/` is renamed wholesale to `tests/statistics-drift/` via `git mv` in the implementation commit.

## Acceptance Criteria

- [ ] `tests/validate-statistics-drift.sh` exists and is executable.
- [ ] `tests/percentile-values/` is removed (or `git mv`'d to `tests/statistics-drift/`).
- [ ] `tests/statistics-drift/{scenarios.tsv, compare-statistics-drift.pl, README.md}` exist; `scenarios.tsv` has the 3-column shape (`scenario`, `logfile`, `options`).
- [ ] 32 baseline CSV files captured under `tests/statistics-drift/baselines/`.
- [ ] `compare-statistics-drift.pl` reads the canonical column list from `tests/csv-output/rules/{messages,stats}-columns.tsv` at startup. No hard-coded duplicate column list anywhere in #224.
- [ ] Engine refuses to start (with a self-documenting diagnostic) if any qualifying column is missing from its column spec.
- [ ] Engine emits a startup line listing every column it will compare, so the reader can independently verify the family is covered completely.
- [ ] Engine does **not** re-implement #223's structural checks. If column-set / row-count / type drift is detected, it emits `STRUCTURE_DRIFT: run validate-csv-output.sh first` and exits non-zero.
- [ ] Self-documenting assertion fields (`asserts`, `produced_by`, `contract`) are surfaced on every T3/T4 failure across all three layers.
- [ ] All ten traps from `tests/HARNESS-DESIGN.md` audited and absent.
- [ ] All cross-column invariants from Decision 4 implemented as Layer-2 T4 checks.
- [ ] Layer-3 oracle `tests/statistics-drift/oracle/calculate-reference.py` exists and produces per-`(category, message, bucket)` JSON.
- [ ] Layer-3 failures emit one tier failure per disagreeing cell with all four self-documenting fields, identifying the NumPy/SciPy function used.
- [ ] Driver fails fast (with install hint) if Python 3, NumPy, or SciPy is missing.
- [ ] For totals, counts, durations, and bytes the harness does not read the source log — Layer 1 + Layer 2 only.
- [ ] For the sensitive statistics in Decision 3, Layer 3 reads the source log specifically to feed the oracle.
- [ ] Every Apache HTTP2 scenario prepends `-du us` to its options.
- [ ] CLAUDE.md release process updated per Decision 8.
- [ ] Release notes for v0.14.6 include a bullet referencing #224.
- [ ] Harness self-validates: exits 0 on freshly captured baselines.

## Verification

When the follow-up implementation lands, every check below must pass.

1. `./tests/validate-statistics-drift.sh` against freshly captured baselines: exits 0, prints one PASS line per scenario, summary line shows `structural=OK` and `L3=OK` for every scenario.
2. `./tests/validate-statistics-drift.sh --show-all`: prints T1/T2 advisories (mostly T1 on fresh baselines), still exits 0.
3. `./tests/validate-statistics-drift.sh --scenario <one>`: runs only the named scenario, exits 0.
4. **Hand-induced T3 (Layer 1)**: bump one baseline cell by 7%, re-run, confirm the failure prints all four self-documenting fields and exits 1.
5. **Hand-induced T4 (Layer 2)**: hand-edit a baseline row so `iqr != p75 − p25`, re-run, confirm T4 with the IQR-derivation invariant identified by name, exit 1.
6. **Hand-induced T3 (Layer 3)**: temporarily change `ltl`'s p99 interpolation method, re-run, confirm the oracle reports a T3-L3 disagreement on `p99` and identifies `numpy.percentile` as the reference. Revert and confirm Layer 3 returns to all-T1.
7. **Anchor-missing**: rename one column in the #223 rules TSV, re-run, confirm hard failure (not silent zero-match pass).
8. **Dependency-missing**: temporarily uninstall NumPy, confirm the driver fails fast with an install hint, not a silent skip.
9. CLAUDE.md release-process step renders correctly when read end-to-end.

## Requirements-drift prevention

Three requirements surfaces describe this work:

1. GitHub issue #224 body — canonical user-facing requirements.
2. This file (`features/224-statistics-drift-harness.md`) — per-issue umbrella feature/requirements file.
3. Working plan at `/Users/gregeva/.claude/plans/there-have-been-a-lexical-globe.md` (private to the implementation session).

Any edit to one must propagate to the others in the same commit. The implementation-commit precondition is "all surfaces consistent and signed off."

## Cross-references

- `tests/HARNESS-DESIGN.md` — harness design rules (self-documenting assertions, ten traps, naming).
- `tests/validate-csv-output.sh` and `tests/csv-output/` — #223 sibling, structural integrity.
- `tests/validate-histogram-bin-counters.sh` — reference implementation of the self-documenting assertion design.
- `features/187-histogram-bin-counter-percentiles.md` — locked Decision 8 contract surface this file's decision-numbering pattern mirrors.
- `features/225-test-harness-coverage-gaps.md` — umbrella-shape pattern this file follows.
