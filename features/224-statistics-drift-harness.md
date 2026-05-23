# Feature: Statistics-drift test harness (#224)

## Overview

This document is the **umbrella feature/requirements file** for issue #224 — a numeric-drift and algorithmic-correctness test harness for every calculated statistic `ltl` emits to its `-o` CSV outputs. It complements the structural-integrity harness shipped under #223 (`tests/validate-csv-output.sh`) and the rendered-output harness `tests/validate-regression.sh`.

The harness has three independent validation layers, each catching a different class of regression. All three are required; partial coverage is forbidden. The layers are the central design idea of this feature and are documented in detail below.

## GitHub Issue

[#224](https://github.com/gregeva/logtimeline/issues/224) — calculated-statistics drift and correctness harness.

## Status

**Planning complete 2026-05-23.** Awaiting implementation commit on branch `224-percentile-value-harness`.

The CSV is the **observation channel** for this harness, not the thing under test. The harness validates `ltl`'s **internal statistics calculation** — how durations are captured, stored, and reduced into statistics in memory. Wherever this document refers to MESSAGES CSV or STATS CSV, the subject is the underlying calculation surface being observed: per-message-key statistics (observed via MESSAGES CSV) and per-time-bucket statistics (observed via STATS CSV).

## Prerequisites (all merged into `release/0.14.6`)

| Issue | What it shipped | Why #224 needed it |
|---|---|---|
| [#220](https://github.com/gregeva/logtimeline/issues/220) | `-so` accepts 17 statistic names including every percentile and shape value | Enables the `sorted-by-p999` scenario family |
| [#221](https://github.com/gregeva/logtimeline/issues/221) | MESSAGES CSV column names converged with STATS (snake_case lowercase) | The harness's column specs would otherwise carry parallel column lists |
| [#222](https://github.com/gregeva/logtimeline/issues/222) | Added `p25, iqr, p9999, p99999, skewness, kurtosis, bimodality_coef` columns | The harness must baseline against the final column set, not an intermediate one |
| [#223](https://github.com/gregeva/logtimeline/issues/223) | Structural CSV-integrity harness with rules-driven column schemas | Structural correctness is a precondition for meaningful drift comparison; #224 reads #223's rules TSVs |
| [#263](https://github.com/gregeva/logtimeline/issues/263) | Decoupled STATS CSV emission from terminal-width-driven visibility | CSV content must be deterministic per input, independent of terminal geometry |
| [#266](https://github.com/gregeva/logtimeline/issues/266) | Omnibus `-dm` / `--data-model` plus per-surface selectors `-hgdm` / `-hmdm` / `-mdm` / `-bdm`, each accepting `raw|bin` | Replaces the deprecated negative opt-out `--exact-percentiles` with positive selectors; enables the `bin-data-model` scenario family and Layer 4 cross-model agreement (Decision 9). What #266 did NOT ship: the bin-counter implementation for the per-message-key and per-time-bucket surfaces — `-mdm bin` / `-bdm bin` silently fall back to raw today. A future ticket lands those; this harness is wired to surface drift the moment it does. |

## Background — why this harness exists

Upcoming work will intervene on how percentiles and distribution-shape values are calculated for log messages. Before that work begins, we need observable, automated assertions that detect:

1. **Drift** — `ltl`'s arithmetic changing unintentionally between releases (caught by Layer 1).
2. **Internal inconsistency** — rows where the columns don't add up against each other (e.g., a refactor that breaks `mean == duration / occurrences` but happens to keep the absolute value close to baseline; caught by Layer 2).
3. **Wrong methodology** — `ltl`'s percentile interpolation or shape formula disagreeing with the canonical reference implementation, even when no drift has occurred because yesterday's value was also wrong (caught by Layer 3 against an external NumPy/SciPy oracle).

A binary diff doesn't fit because legitimate algorithmic changes can shift values by small amounts. A tiered model with explicit advisory/blocking levels lets intentional change cross the tight tiers while preserving the loose ones. A single-layer drift check is insufficient because drift only knows what yesterday's value was — it cannot tell you whether yesterday's value was correct.

## Decision 1 — Four independent validation layers, all required

The harness validates `ltl`'s calculated values at four independent layers. Each catches a class of regression the others cannot. All four run on every scenario where they apply; failure at any layer blocks the release at T3 or T4. (Layer 4 is specified in detail in Decision 9 below; the summary appears here so the layer list reads as a single contract.)

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

### Layer 4 — Cross-model agreement (raw vs bin at single code state)

- **What it asserts**: at a single code state, the raw-array and bin-counter data models compute statistics that agree within a documented tolerance envelope on the same sample set. Persistent disagreement beyond that envelope is an algorithmic bug in one of the two implementations.
- **Inputs**: per logfile, the produced CSVs from the `default` (raw) scenario and the paired `bin-data-model` scenario.
- **Catches**: cross-model algorithmic divergence. L1 can drift in lockstep across both models; L2 is single-row; L3 compares each model independently against the oracle, not against each other.
- **Source-log reads**: none — operates only on the two paired CSVs.
- **Tier model**: T1 bitwise / T2 ≤1% / T3 ≤4% / T4 >4%. Tolerances are per-scenario and per-column overridable via `tests/statistics-drift/cross-model-tolerances.tsv`. Full specification in Decision 9.

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

Each family exercises a different statistic-affecting code path. All families pin the per-message-key and per-time-bucket data models explicitly via #266's selectors (`-mdm` and `-bdm`); the harness never relies on internal defaults.

- **`default`** — `-bs 240 -n 25 -mdm raw -bdm raw -o` — raw-array data model on both observed surfaces. Standard bucket size, default ranking. Baseline of the path users hit today.
- **`consolidated`** — `-bs 240 -g 90 -n 25 -mdm raw -bdm raw -o` — fuzzy consolidation at 90% changes which samples land in which message-key bucket, exercising the statistics path over consolidated sample populations.
- **`bin-data-model`** — `-bs 240 -n 25 -mdm bin -bdm bin -o` — bin-counter data model selected on both observed surfaces. Today the bin-counter implementation does not yet exist for these surfaces and `ltl` silently falls back to raw, so this scenario's initial baselines are byte-identical to `default`. The scenario is wired anyway so Layer 4 has a pairing to compare and so the harness surfaces drift the moment a future feature ticket lands the bin implementation. The implementing ticket is responsible for re-capturing this scenario's baselines and populating `cross-model-tolerances.tsv` with whatever envelopes are appropriate.
- **`sorted-by-p999`** — `-bs 240 -n 25 -so p999 -mdm raw -bdm raw -o` — ranks output by `p999` (unlocked by #220), exercising the ranking path's use of statistic values to select the top-N messages, which changes which keys appear in MESSAGES CSV.

### Apache HTTP2 microsecond duration: `-du us`

The Apache HTTP2 access log records duration in microseconds. The correct flag is `-du us` (`--duration-unit us`), which tells `ltl` the **input file's duration unit** when auto-detection cannot infer it.

This is distinct from `-ms`, which enables sub-second *timestamp* parsing — a different axis. The Apache timestamps remain at second resolution; only the duration values are sub-second. Without `-du us`, durations are interpreted at the wrong scale and every statistic (min/mean/max, std_dev, every percentile, every shape value) is wrong by 10^k.

Every Apache scenario prepends `-du us`. Other logfiles do not need `-du`: Tomcat 9 and Codebeamer are millisecond and auto-detect correctly; ThingWorx ScriptLog carries `durationMS` in the log lines themselves and auto-detects to ms.

### Resolved scenario options per logfile

- **Apache HTTP2** (4 scenarios): `-du us -bs 240 -n 25 -mdm raw -bdm raw -o` / `-du us -bs 240 -g 90 -n 25 -mdm raw -bdm raw -o` / `-du us -bs 240 -n 25 -mdm bin -bdm bin -o` / `-du us -bs 240 -n 25 -so p999 -mdm raw -bdm raw -o`.
- **Tomcat, ThingWorx, Codebeamer**: the four option-family strings without `-du`.

### Matrix size

**4 logs × 4 option families = 16 scenarios**, 32 baseline CSV files.

If 16 proves too heavy for routine release runs, the `default` and `bin-data-model` families are the **required** ones (8 scenarios, 16 baselines) — these are the two halves of the Layer 4 pairing; `consolidated` and `sorted-by-p999` can be tagged as `extended` and run on demand. This split is operational, not architectural — the harness implements all 16.

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

For Layer-4 failures, the failure line names both implementations and the tolerance source row:

```
FAIL [T4-L4] scenario-pair=apache-default↔apache-bin-data-model file=messages key="plain|[200] GET /…" column=p99
       raw=1320 bin=1485 deviation=12.50% tolerance=4.00%
       asserts: bin-counter percentile must agree with raw within configured tolerance
       produced_by: calculate_statistics() (raw) vs <future-bin-sub>() (bin) in ltl
       contract: features/224-statistics-drift-harness.md § Decision 9 — Layer 4 cross-model agreement
       rule: abs(raw-bin) > tolerance% * raw   (tolerance source: cross-model-tolerances.tsv defaults)
```

Per-scenario summary line:

```
apache-default/messages: 248 cells checked, 0 T4, 0 T3, 2 T2, 5 T1, structural=OK, L3=OK, L4=OK
```

## Decision 8 — Release-process integration

A new step in CLAUDE.md release process, inserted **after** #223's structural validation and **before** benchmarks:

> **Validate statistics drift:** `./tests/validate-statistics-drift.sh` — must exit 0 (no T3/T4 failures across any of the four layers) before proceeding. T1/T2 advisories are non-blocking; review to confirm any drift is intentional. Layer 4 cross-model failures often indicate that a tolerance row in `cross-model-tolerances.tsv` needs to be added or widened — review on a case-by-case basis.

Order rationale: structural correctness (#223) is a precondition for meaningful drift comparison. If columns are missing or mis-typed, the drift harness has nothing to compare. Benchmark runs (1+ hour) come after both validators because there's no point spending an hour on perf benchmarks if statistic-correctness is broken.

## Decision 9 — Layer 4 cross-model agreement

The raw-array and bin-counter data models are independent implementations of the same statistical contract. At any single code state they should produce statistics that agree within a documented tolerance envelope on the same sample set. Layer 4 enforces this. It is the only layer that catches algorithmic divergence between the two implementations at a single code state — L1 can drift in lockstep, L2 is single-row, L3 compares each model independently against the oracle rather than against each other.

### Pairing

For each logfile in the scenario matrix, the engine joins the `default` scenario's output (raw data model) against the `bin-data-model` scenario's output, row-by-row on `(category, message, bucket)`. Every numeric column emitted by both is compared cell-by-cell.

### Tier ladder

Same shape as Layer 1, applied to the cross-model deviation:

| Tier | Default rule | Blocking |
|---|---|---|
| T1 | bitwise identical | Advisory |
| T2 | within ±1% | Advisory |
| T3 | within ±4% | Advisory |
| T4 | beyond ±4% | **Yes** |

### Tolerance overrides — `cross-model-tolerances.tsv`

Per-scenario / per-column tolerance overrides live in a separate TSV at `tests/statistics-drift/cross-model-tolerances.tsv`. Tuning is expected: bin-counter implementations quantize samples into bin boundaries, so percentile drift relative to raw is bounded by bin width at the relevant percentile. Wider tolerances on `p99999` than on `p50` are normal. Widening the tolerance is the contract change; it is reviewed via TSV diffs, not engine code edits.

Schema:

```
scenario  column  t2_pct  t3_pct  notes
```

Resolution rules:

- A row with non-blank `scenario` and `column` applies only to that pair.
- A row with blank `scenario` and non-blank `column` applies to that column across all scenarios.
- A row with non-blank `scenario` and blank `column` applies to all columns of that scenario.
- A row with both blank is a syntax error and the engine refuses to start.
- No matching row → ladder defaults apply (`0` / `1%` / `4%` / `>4%`).
- Multiple matches → most-specific wins (scenario+column > column-only > scenario-only).

The failure-output `rule:` line names the tolerance source: `cross-model-tolerances.tsv defaults` or `cross-model-tolerances.tsv scenario=X column=Y`.

### Skip / sanity-check semantics during transition

Today, the bin-counter implementation does not exist for the per-message-key and per-time-bucket surfaces. `-mdm bin` / `-bdm bin` parse cleanly but silently fall back to the raw-array reduction in `calculate_statistics()` (`ltl:8248`), so the `bin-data-model` scenario produces output byte-identical to `default`. Layer 4 still runs the pairing and reports `T1` on every cell — a wiring sanity check that confirms the pairing logic works end-to-end. When a future feature ticket lands the bin implementation for these surfaces and the outputs begin to diverge, the same harness immediately surfaces it without code change.

A scenario where the flag itself is not exposed (none today, since #266 covers all four surfaces) would emit `L4=N/A` in the per-scenario summary instead of running the pairing. This case exists in the spec for symmetry, not for current use.

## Files

```
tests/
├── validate-statistics-drift.sh             ← driver (Bash, beside other validate-*.sh)
└── statistics-drift/
    ├── README.md                            ← usage + scope + non-overlap with #223
    ├── scenarios.tsv                        ← 16 scenarios
    ├── cross-model-tolerances.tsv           ← per-scenario / per-column Layer-4 tolerance overrides
    ├── compare-statistics-drift.pl          ← Perl engine: L1 drift + L2 intra-row + L3 oracle join + L4 cross-model pairing
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
- [ ] Self-documenting assertion fields (`asserts`, `produced_by`, `contract`) are surfaced on every T3/T4 failure across all four layers.
- [ ] All ten traps from `tests/HARNESS-DESIGN.md` audited and absent.
- [ ] All cross-column invariants from Decision 4 implemented as Layer-2 T4 checks.
- [ ] Layer-3 oracle `tests/statistics-drift/oracle/calculate-reference.py` exists and produces per-`(category, message, bucket)` JSON.
- [ ] Layer-3 failures emit one tier failure per disagreeing cell with all four self-documenting fields, identifying the NumPy/SciPy function used.
- [ ] Driver fails fast (with install hint) if Python 3, NumPy, or SciPy is missing.
- [ ] For totals, counts, durations, and bytes the harness does not read the source log — Layer 1 + Layer 2 only.
- [ ] For the sensitive statistics in Decision 3, Layer 3 reads the source log specifically to feed the oracle.
- [ ] Every Apache HTTP2 scenario prepends `-du us` to its options.
- [ ] `tests/statistics-drift/cross-model-tolerances.tsv` exists with the Decision 9 schema (`scenario  column  t2_pct  t3_pct  notes`) and the engine loads it at startup.
- [ ] Layer 4 pairs the `default` and `bin-data-model` scenarios per logfile and reports `T1` cells / advisory tiers / blocking T4 per the Decision 9 ladder and tolerance overrides.
- [ ] Layer-4 failure lines include the tolerance-source annotation (`cross-model-tolerances.tsv defaults` or scoped row identification).
- [ ] On day one, with the bin path silently falling back to raw, Layer 4 reports `T1=OK` for every paired cell and exits 0 — confirms the pairing wiring is correct.
- [ ] Per-scenario summary line ends with `L4=OK` (or the appropriate non-OK state) on every scenario where the pairing applies.
- [ ] CLAUDE.md release process updated per Decision 8.
- [ ] Release notes for v0.14.6 include a bullet referencing #224.
- [ ] Harness self-validates: exits 0 on freshly captured baselines.

## Verification

When the follow-up implementation lands, every check below must pass.

1. `./tests/validate-statistics-drift.sh` against freshly captured baselines: exits 0, prints one PASS line per scenario, summary line shows `structural=OK`, `L3=OK`, and `L4=OK` for every scenario.
2. `./tests/validate-statistics-drift.sh --show-all`: prints T1/T2 advisories (mostly T1 on fresh baselines), still exits 0.
3. `./tests/validate-statistics-drift.sh --scenario <one>`: runs only the named scenario, exits 0.
4. **Hand-induced T3 (Layer 1)**: bump one baseline cell by 7%, re-run, confirm the failure prints all four self-documenting fields and exits 1.
5. **Hand-induced T4 (Layer 2)**: hand-edit a baseline row so `iqr != p75 − p25`, re-run, confirm T4 with the IQR-derivation invariant identified by name, exit 1.
6. **Hand-induced T3 (Layer 3)**: temporarily change `ltl`'s p99 interpolation method, re-run, confirm the oracle reports a T3-L3 disagreement on `p99` and identifies `numpy.percentile` as the reference. Revert and confirm Layer 3 returns to all-T1.
7. **Day-one Layer-4 sanity**: with the bin implementation absent and the `-mdm bin` / `-bdm bin` selectors falling back to raw, confirm the `default ↔ bin-data-model` pairing reports `T1` for every cell on every logfile.
8. **Hand-induced T4 (Layer 4)**: hand-edit a `bin-data-model` baseline cell to introduce a >4% delta from the paired `default` baseline, re-run, confirm a T4-L4 failure with the tolerance-source annotation and all four self-documenting fields. Add a matching row to `cross-model-tolerances.tsv` widening the tolerance to >12%, re-run, confirm the failure becomes a T2/T3 advisory.
9. **Anchor-missing**: rename one column in the #223 rules TSV, re-run, confirm hard failure (not silent zero-match pass).
10. **Dependency-missing**: temporarily uninstall NumPy, confirm the driver fails fast with an install hint, not a silent skip.
11. CLAUDE.md release-process step renders correctly when read end-to-end.

## Requirements-drift prevention

Two requirements surfaces describe this work:

1. GitHub issue #224 body — canonical user-facing requirements.
2. This file (`features/224-statistics-drift-harness.md`) — per-issue umbrella feature/requirements file (the source of truth for the design).

Any edit to one must propagate to the other in the same commit. The implementation-commit precondition is "all surfaces consistent and signed off."

Working plans under `~/.claude/plans/` are session-private notes and are not a requirements surface — if a planning conversation changes the contract, the change lands here (and in the issue body if user-facing) before implementation starts.

## Cross-references

- `tests/HARNESS-DESIGN.md` — harness design rules (self-documenting assertions, ten traps, naming).
- `tests/validate-csv-output.sh` and `tests/csv-output/` — #223 sibling, structural integrity.
- `tests/validate-histogram-bin-counters.sh` — reference implementation of the self-documenting assertion design.
- `features/187-histogram-bin-counter-percentiles.md` — locked Decision 8 contract surface this file's decision-numbering pattern mirrors.
- `features/225-test-harness-coverage-gaps.md` — umbrella-shape pattern this file follows.
