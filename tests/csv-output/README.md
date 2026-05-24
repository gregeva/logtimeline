# CSV-output integrity harness

Issue #223. Sibling to `tests/statistics-drift/` (Issue #224).

## What this harness validates

Categorical, pass/fail correctness of `-o` CSV outputs:

1. **Column structure** — expected columns are present, fixed-position columns
   appear at their expected index, dynamic-position columns appear when their
   family is active.
2. **Population correctness** — required columns are never empty; conditional
   columns are populated when their family is active; every data row has the
   same column count as the header (alignment).
3. **Functional group consistency** — within each row, if any column in a
   family is populated, *all* conditional columns in that family must be
   populated. No partial-family emission.
4. **Data-type correctness** — numeric columns hold numbers (no `NaN`/`Inf`/
   strings); `nice` columns hold human-readable strings with unit tokens
   (no bare numbers); integer columns reject decimals; timestamps parse.
5. **Fixed-decimal rule** — per-column `max_decimals` cap declared in the
   rules TSV. Universal ceiling is 5; specific columns may declare tighter.

## What this harness does NOT validate

- Numeric drift of values themselves (that's `tests/statistics-drift/`, #224).
- Cross-column arithmetic relationships (that's #224's territory).
- Algorithmic correctness against an external oracle (that's #224's territory).
- Cross-model agreement between raw and bin data models (that's #224's territory).
- Layout/rendering of the bar graph (that's `validate-regression.sh`).

## Files

```
tests/
├── validate-csv-output.sh                  ← bash driver
└── csv-output/
    ├── README.md                           ← this file
    ├── scenarios.tsv                       ← scenario × log × options × families
    ├── validate-csv-output.pl              ← data-driven Perl validator
    └── rules/
        ├── messages-columns.tsv            ← per-column rules for MESSAGES CSV
        └── stats-columns.tsv               ← per-column rules for STATS CSV
```

## Running

```bash
./tests/validate-csv-output.sh                          # all scenarios
./tests/validate-csv-output.sh --scenario thingworx-script
```

Exit 0 means structural integrity holds. Exit 1 means at least one FAIL line
was emitted; investigate before continuing the release.

## Rules TSV schema

One row per column:

| Field | Meaning |
|---|---|
| `column` | Exact column name as emitted by `ltl` |
| `position` | 1-based index (fixed) or `*` (dynamic, match by name) |
| `type` | `int`, `float`, `nice`, `string`, `timestamp`, `enum:a,b,c` |
| `required` | `yes`, `no`, or `conditional:<family>` |
| `max_decimals` | Integer 0–5, or `n/a` for non-numeric types |
| `family` | `meta`, `duration`, `bytes`, `count`, `percentile`, `shape`, `level`, `udm` |

`conditional:<family>` columns are required to be populated when the family
is declared active in the scenario; the group-consistency check then enforces
that all `conditional:<family>` columns are uniformly populated within a row.

## Scenarios TSV schema

One row per scenario:

| Field | Meaning |
|---|---|
| `scenario` | Short identifier; pass to `--scenario` |
| `logfile` | Path under repo root |
| `options` | `ltl` command-line options (excluding `--disable-progress` and `-o`, which the harness adds) |
| `expected_families` | Comma-separated families expected to be active for this scenario |

## Known outstanding finding

The `access-bytes-duration` scenario currently FAILs on group-consistency for
boundary buckets — STATS rows have duration totals populated but per-sample
statistics (`min`, `mean`, `max`, `std_dev`, percentiles, shape) empty.
Tracked separately as a bug; the harness is correctly catching real
data-emission inconsistency.

## Updating rules when columns change

The rules TSVs are the canonical structural expectation. They are
hand-maintained — there is no `--regenerate` flag. When `ltl` adds, renames,
or removes a CSV column:

1. Update `ltl` itself (column emission code at the `print_message_summary`
   and `print_bar_graph` sites).
2. Update the matching rules TSV (`messages-columns.tsv` or `stats-columns.tsv`)
   in the same commit.
3. Run the harness — it must still exit 0 against the modified `ltl`.
4. Update `releases/v<version>.md` and the GitHub issue.

This discipline ensures the rules file is the single source of truth for
what the CSV outputs *should* look like at any release tag.

## Relationship to other suites

| Suite | Concern |
|---|---|
| `validate-regression.sh` | Rendered terminal output byte-identity |
| `validate-csv-output.sh` (this) | CSV structural & type-wise correctness |
| `validate-statistics.sh` (#224) | Numeric drift, intra-row consistency, oracle correctness, cross-model agreement |

These three layer cleanly: terminal layout, CSV structure, CSV values.
