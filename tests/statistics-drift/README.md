# Statistics-drift test harness

Numeric-correctness test harness for every calculated statistic `ltl` emits to
its `-o` CSV outputs. Sibling to `tests/csv-output/` (Issue #223). Source of
truth: `features/224-validate-statistics-test-harness.md`.

## Four validation layers

| Layer | What it asserts | Catches | Reads source log? |
|---|---|---|---|
| **L1 — Drift** | Current CSV equals previously captured baseline CSV, tiered | Silent inter-release arithmetic regressions | No |
| **L2 — Intra-row consistency** | Each row's columns are arithmetically consistent (e.g., `mean == duration / occurrences`, full percentile monotonicity, `iqr == p75 − p25`) | Arithmetic mistakes that leave values close to baseline but internally inconsistent | No |
| **L3 — External oracle** | `ltl` agrees with NumPy/SciPy for the algebraically sensitive statistics over the same sample set | Wrong methodology — interpolation bugs, sign errors, biased vs unbiased formulas | Yes, only to feed the oracle |
| **L4 — Cross-model agreement** | The raw-array (`default`) and bin-counter (`bin-data-model`) scenarios agree within a documented tolerance envelope at a single code state | Raw-vs-bin algorithmic divergence that L1/L2/L3 cannot see | No |

All four layers run on every scenario where they apply. Failure at T3 or T4
(across any layer) blocks the release.

## Tier model

L1 and L3 share the same ladder:

| Tier | Rule | Blocking? |
|---|---|---|
| T1 | byte-identical / perfect agreement | No (advisory) |
| T2 | `abs(new − old) ≤ 1% × old` | No (advisory) |
| T3 | `abs(new − old) ≤ 5% × old` but > 1% | **Yes** |
| T4 | cross-column invariant violated (L2) | **Yes** |

L4 uses a separate ladder appropriate for cross-model deviation: T1 bitwise /
T2 ≤1% / T3 ≤4% / T4 >4%, with per-scenario / per-column overrides in
`cross-model-tolerances.tsv`.

## Scenario matrix

4 logs × 4 option families = 16 scenarios. See `scenarios.tsv` for the full
manifest. Apache HTTP2 scenarios prepend `-du us` because its log records
duration in microseconds and auto-detection cannot infer this. All scenarios
pin `-mdm` and `-bdm` explicitly via #266's selectors.

| Family | Options | Purpose |
|---|---|---|
| `default` | `-bs 240 -n 25 -mdm raw -bdm raw -o` | Raw-array baseline |
| `consolidated` | `-bs 240 -g 90 -n 25 -mdm raw -bdm raw -o` | Fuzzy consolidation at 90% |
| `bin-data-model` | `-bs 240 -n 25 -mdm bin -bdm bin -o` | Bin-counter data model (falls back to raw today) |
| `sorted-by-p999` | `-bs 240 -n 25 -so p999 -mdm raw -bdm raw -o` | Percentile-based ranking |

## Usage

```bash
./tests/validate-statistics.sh                              # all scenarios, all layers
./tests/validate-statistics.sh --show-all                   # include T1/T2 advisories
./tests/validate-statistics.sh --scenario apache-default    # single scenario
./tests/validate-statistics.sh --capture-baselines          # rebaseline (with prompt)
./tests/validate-statistics.sh --capture-baselines --scenario apache-default
```

Exit codes:
- `0` — no T3/T4 failures across any layer (T1/T2 advisories may have printed)
- `1` — at least one T3/T4 failure

## Orchestration

The driver participates in the test-suite-wide CSV cache. The `CI`
environment variable signals orchestration mode:

| State | Behavior |
|---|---|
| `CI` unset / empty | Standalone — driver calls `cleanup-test-artifacts.sh` at end of run |
| `CI=1` (or any non-empty) | Orchestrated — driver leaves `tests/.artifacts/csv/` in place; orchestrator owns cleanup |

`CI` is the industry-standard signal set by GitHub Actions, GitLab CI,
CircleCI, Jenkins, Travis, etc., so harnesses running under any CI get the
correct behavior automatically.

When `validate-csv-output.sh` and `validate-statistics.sh` run as a pair in
a release process, set `CI=1` for both invocations and then call
`./tests/cleanup-test-artifacts.sh` once at the end. The second harness
reuses cached CSVs from the first wherever the option string matches,
reducing combined runtime dramatically.

## External dependencies

Layer 3 requires Python 3, NumPy, and SciPy. The driver fails fast with an
install hint if any are missing — it does not silently skip Layer 3.

Modern Homebrew Python (macOS) and modern Linux distros (Ubuntu 24.04+,
Debian 12+, Fedora 38+) enforce PEP 668, which blocks `pip3 install`
against the system-managed Python. Use `--user` to install into your home
directory without sudo or override flags:

```bash
# macOS
brew install python
pip3 install --user numpy scipy

# Ubuntu/Linux
sudo apt-get install python3 python3-pip
pip3 install --user numpy scipy
```

Verify with `python3 -c "import numpy, scipy"`.

If you prefer a project-local venv, the harness driver honors the venv's
Python when invoked with `PATH=$(pwd)/.venv/bin:$PATH`. See the top-level
README's "Test-harness dependencies" section for the venv pattern.

## Cross-model tolerance overrides

Per-scenario / per-column Layer-4 tolerance overrides live in
`cross-model-tolerances.tsv` with schema `scenario  column  t2_pct  t3_pct  notes`.
Most-specific match wins. See the file header for full resolution rules.

## L2 cross-column invariants

All apply within a single row; failure of any is a T4. Source: Decision 4 of
the feature file.

- Duration ordering: `min ≤ mean ≤ max`
- Duration derivation: `mean == duration / occurrences`
- Bytes ordering: `mean_bytes ≤ bytes`
- Bytes derivation: `mean_bytes == bytes / occurrences`
- Count ordering: `count_min ≤ count_mean ≤ count_max`
- Count derivation: `count_mean == count_sum / count_occurrences`
- Percentile monotonicity (full ladder): `p1 ≤ p5 ≤ p10 ≤ p25 ≤ p50 ≤ p75 ≤ p90 ≤ p95 ≤ p99 ≤ p999 ≤ p9999 ≤ p99999`
- Percentile bounded by min/max: `min ≤ p1` and `p99999 ≤ max`
- IQR derivation: `iqr == p75 − p25`

## L3 oracle scope

External-oracle validation is reserved for statistics where the algorithm has
non-trivial degrees of freedom and quiet methodology bugs are plausible:
`p1, p5, p10, p25, p50, p75, p90, p95, p99, p999, p9999, p99999`, `std_dev`,
`cv`, `skewness`, `kurtosis`, `bimodality_coef`, `iqr`. Source: Decision 3.

Statistics with a single canonical definition (`min`, `mean`, `max`,
`duration`, `bytes`, `mean_bytes`, `occurrences`, `count_*`, `impact`, level
counts, rate counts) are validated by L1 + L2 only.

## Files in this directory

```
tests/statistics-drift/
├── README.md                        ← this file
├── scenarios.tsv                    ← 16 scenarios (4 logs × 4 families)
├── cross-model-tolerances.tsv       ← per-scenario / per-column L4 tolerance overrides
├── compare-statistics-drift.pl      ← L1+L2+L3+L4 engine
├── oracle/
│   └── calculate-reference.py       ← NumPy/SciPy oracle (per-scenario invocation)
└── baselines/
    └── <scenario>/
        ├── messages.csv             ← captured -o MESSAGES baseline
        └── stats.csv                ← captured -o STATS baseline
```

The driver `validate-statistics.sh` lives one level up in `tests/` alongside
the other `validate-*.sh` siblings.

## Capturing baselines

Baselines are **deliverables**, not disposable artifacts. Do not regenerate
casually:

- Regenerate only when the new values are known-correct (e.g., after an
  intentional change to a statistic algorithm that has been reviewed).
- The `--capture-baselines` flag prompts for confirmation before overwriting.
- Always inspect the diff of the regenerated baselines before committing.

## Relationship to other suites

| Suite | Concern |
|---|---|
| `validate-regression.sh` | Rendered terminal output byte-identity |
| `validate-csv-output.sh` (#223) | CSV structural and type-wise correctness |
| `validate-statistics.sh` (#224, this) | Numeric drift, intra-row consistency, oracle correctness, cross-model agreement |

The three harnesses layer cleanly: terminal layout, CSV structure, CSV values.
Run `validate-csv-output.sh` before `validate-statistics.sh` — structural
correctness is a precondition for meaningful drift comparison.
