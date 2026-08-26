# Statistics-drift test harness

Numeric-correctness test harness for every calculated statistic `ltl` emits to
its `-o` CSV outputs. Sibling to `tests/csv-output/` (Issue #223). Source of
truth: `features/224-validate-statistics-test-harness.md`.

## Three validation layers

| Layer | What it asserts | Catches | Reads source log? |
|---|---|---|---|
| **L1 — Drift** | Current CSV equals previously captured baseline CSV, tiered | Silent inter-release arithmetic regressions | No |
| **L2 — Intra-row consistency** | Each row's columns are arithmetically consistent (e.g., `mean == duration / occurrences`, full percentile monotonicity, `iqr == p75 − p25`) | Arithmetic mistakes that leave values close to baseline but internally inconsistent | No |
| **L3 — Algorithm-aware external oracle** | `ltl` agrees with NumPy/SciPy for the algebraically sensitive statistics over the same sample set, with the reference computation dispatched by the algorithm declared in ltl's `-V percentile-algorithm` section (#280) | Wrong methodology — formula bugs, sign errors, biased vs unbiased formulas | Yes, only to feed the oracle |

All three layers run on every scenario. Failure at T3 or T4 blocks the release.

## Tier model

L1 and L3 share the same ladder:

| Tier | Rule | Blocking? |
|---|---|---|
| T1 | byte-identical / perfect agreement | No (advisory) |
| T2 | `abs(new − old) ≤ 1% × old` | No (advisory) |
| T3 | `abs(new − old) ≤ 5% × old` but > 1% | **Yes** |
| T4 | cross-column invariant violated (L2) | **Yes** |

## Scenario matrix

4 logs × 4 option families, plus the #289 heatmap pair and the #450
bin-consolidated rows = **21 scenarios**. See `scenarios.tsv` for the full
manifest. Apache HTTP2 scenarios prepend `-du us` because its log records
duration in microseconds and auto-detection cannot infer this. All scenarios
pin `-mdm` and `-bdm` explicitly via #266's selectors.

| Family | Options | Purpose |
|---|---|---|
| `default` | `-bs 240 -n 25 -mdm raw -bdm raw -o` | Raw-array baseline |
| `consolidated` | `-bs 240 -g 90 -n 25 -mdm raw -bdm raw -o` | Fuzzy consolidation at 90% |
| `bin-data-model` | `-bs 240 -n 25 -mdm bin -bdm bin -o` | Bin-counter data model, honoured end to end |
| `bin-consolidated` | `-bs 240 -g 90 -n 25 -mdm bin -bdm bin -o` | The `-g` × bin cross — the only path reaching `merge_bin_counter_entries()` (#450). Apache, ThingWorx and Codebeamer only |
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

The install command depends on which `python3` the harness will invoke. The
top-level `README.md` § Test-harness dependencies documents the matrix in
detail; the short version:

- macOS, Homebrew Python (`/opt/homebrew/bin/python3` or `/usr/local/bin/python3`):
  `brew install numpy scipy` (PEP 668 blocks `pip --user` against brew Python;
  numpy and scipy ship as brew formulas).
- macOS, Apple Command-Line-Tools Python (`/Library/Developer/CommandLineTools/...`):
  `python3 -m pip install --user numpy scipy` (no PEP 668).
- Ubuntu/Linux, pre-PEP-668 distros:
  `python3 -m pip install --user numpy scipy`.
- Ubuntu/Linux, PEP-668 distros (Ubuntu 24.04+, Debian 12+, Fedora 38+) or any
  system where the above is blocked: project-local venv
  (`python3 -m venv .venv && .venv/bin/python -m pip install numpy scipy`,
  then run the harness with `PATH=$(pwd)/.venv/bin:$PATH`).

Verify the install landed under the harness's interpreter by running
`python3 -c "import numpy, scipy"` from a non-interactive shell — PATH
ordering can differ between your interactive shell and the harness's,
which is the most common cause of "install said success, harness can't
find the modules." If this happens, re-run the install using the full
absolute path `which python3` reports from the harness's shell.

The harness's fail-fast hint detects which Python it resolved and prints
the matching install command for that case.

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

**Layer 3 covers consolidated rows** (#462). A consolidated row's key is a
wildcard pattern that appears nowhere in the log, so the oracle — which groups
by exact message key and implements no fuzzy merge — could not form its sample
set and skipped it. The harness now captures `ltl -V message-grouping`'s
cluster-membership sub-section per consolidating scenario and passes it to the
oracle as `--cluster-membership`, which folds each member into its cluster
before computing. The division: **`ltl` supplies the grouping**, which is the
fuzzy matcher's decision and not a statistic, and **the oracle computes the
arithmetic over each group itself**, which is what it exists to check.

Unpaired rows are still counted and reported as `unpaired=N (wildcard=M)`, and
a scenario where every row went unpaired is named `NO CELLS COMPARED` rather
than reporting `L3=OK` (#450) — so a future regression in the pairing shows up
instead of quietly reducing coverage.

### Known Layer-3 failures

`known-failures.tsv` registers comparisons that breach the blocking threshold
because of a filed, open defect in `ltl` rather than a miscalibrated harness.
An entry suppresses the block for one (scenario, file_kind, column, key_class)
and is reported as `XFAIL` with its issue on every run; the comparison still
happens and the deviation is still printed, and the scenario reports
`L3=OK-WITH-XFAIL` rather than `L3=OK`.

**Entries are self-clearing.** If a registered comparison passes, the engine
fails the run with `KNOWN-FAILURE-STALE` — a fix cannot land without its
entries being removed in the same change.

The current entries are all #459: combining two bin-counter histograms
re-projects both sides onto a union geometry, and the displacement compounds
with merge depth. Measured against the oracle, percentiles drift 2.7–4.2% and
IQR up to 32.6% on the two deep-merge scenarios. `apache-bin-consolidated`, at
52 projections, stays inside the threshold, and the raw `*-consolidated`
scenarios agree exactly — which is what identifies the bin merge as the cause
rather than the grouping.


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
├── scenarios.tsv                    ← 21 scenarios (see the matrix above)
├── compare-statistics-drift.pl      ← L1+L2+L3 engine
├── oracle/
│   └── calculate-reference.py       ← algorithm-aware NumPy/SciPy oracle
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
| `validate-statistics.sh` (#224, this) | Numeric drift, intra-row consistency, algorithm-aware oracle correctness |

The three harnesses layer cleanly: terminal layout, CSV structure, CSV values.
Run `validate-csv-output.sh` before `validate-statistics.sh` — structural
correctness is a precondition for meaningful drift comparison.
