# Feature: Index file read-back with drift detection and refresh

## Overview

ltl writes `ltl-index.csv` today via the #46 feature, recording both whole-file metadata (`file` entries) and per-run filter-specific statistics (`selection` entries). No code path reads either back. This feature adds startup read-back with **most-specific-to-less-specific lookup** — selection entry first when filters match, file entry as fallback — plus end-of-run drift detection that refreshes the matching index entry when live values exceed pre-seeded bounds. The pre-seeded values become a primitive consumable by downstream features.

## GitHub Issue

[#179](https://github.com/gregeva/logtimeline/issues/179)

## Motivation

**The data is already on disk.** Every run writes a selection entry; many runs write a file entry. Failing to read either back means each run starts cold, even when the file is unchanged and the same filters were used recently.

**Filter-specific bounds matter.** A run with `-dmin=100 -i error` filters live values to a subset whose min/max/timestamps are different from the whole-file population. Pre-seeding from a `file` entry under those filters would over-state the bounds. Selection entries exist precisely so filtered runs have correctly-scoped pre-seed data. The index is therefore a two-layer cache and read-back must use both layers correctly.

**Several downstream features need pre-run knowledge of bounds.** #34 (two-pass streaming), #44 (file heuristics), #23 Phase 2 (detect-stage hints), #51 (bucket-count structures). Each consumer must use bounds matching the filter context of the current run; this feature provides that. Self-healing drift detection at end of run ensures the index never silently locks in narrower-than-actual bounds.

This feature does not improve runtime on today's architecture in a measurable way. Its value is providing a primitive for downstream consumers. This is documented to prevent benchmarking confusion later.

## Scope

### In scope (v1)

- Read existing `ltl-index.csv` at startup.
- Compute the current run's filter signature using the same logic that produces `selection` entries' `filters` column today.
- For each input file, perform tiered lookup:
  1. **Tier 1 (most-specific):** Find a `selection` entry where `file_path` matches and `filters` matches the current signature exactly.
  2. **Tier 2 (less-specific):** If no Tier 1 match, find the `file` entry for `file_path` (whole-file bounds).
  3. **No match:** No pre-seed for that file.
- Freshness check on whichever tier is selected.
- Pre-seed in-memory bound state from the matched entry's columns: `duration_min/max`, `bytes_min/max`, `count_min/max`, `first_timestamp`, `last_timestamp`, `ts_precision`.
- End-of-run drift comparison, layer-aware: filtered run that matched a Tier-1 selection entry compares live filtered values against pre-seed; refresh occurs at the selection-entry layer. Unfiltered run compares live whole-file values; refresh occurs at the file-entry layer. Tier-2 fallback for a filtered run: drift comparison is against live filtered values, but since Tier 2 is intentionally looser, drift here means "selection entry didn't exist yet" — next-run write creates it.
- Multi-file rule: pre-seed activates only when **every** input file has a fresh entry at the **same tier**. Mixed tiers across files in one run → skip pre-seed.
- A dedicated `=== INDEX READ-BACK ===` section in `-V` verbose output with sufficient detail to assert correct operation externally (per-file lookup result with matched-row identity, run-level aggregated bounds with provenance, per-file drift detail).
- A new test runner that orchestrates `ltl-index.csv` state directly to trigger each scenario, runs ltl, and asserts against the `=== INDEX READ-BACK ===` section.

### Out of scope (deferred)

- Cross-tier degradation within one run (e.g., Tier 1 for some files, Tier 2 for others). Adds complexity without clear v1 value.
- Cross-file aggregation hints beyond global min-of-mins / max-of-maxes.
- New CLI flags (e.g., `--no-index`, `--reindex`).
- Skipping the parse pass entirely or skipping any per-line work — every line is still read for matching, statistics, and rendering.
- Pre-seeding of histogram boundary arrays (requires #51 / Phase-2 boundary-pre-allocation work).
- Pre-seeding of the heatmap boundary array — only the scalar min/max are pre-seeded in v1.

### Explicit non-goals

- This feature does not improve runtime on today's architecture in a measurable way. Its value is providing a primitive for #34/#44/#23/#51 to consume. This is documented to prevent benchmarking confusion later.

## Behavior

### Startup read-back

When `ltl-index.csv` is present at the resolved path (cwd if writable, else system temp — same resolution as the write side), parse all entries. Compute the current run's filter signature; if no filters are active, the signature is `-`. For each input file, perform tiered lookup as defined above, then apply the freshness check to whichever tier matched.

### Freshness check

For both tiers, freshness is determined by the parent `file` entry's `file_size` + `file_mtime` matching the on-disk file.

A `selection` entry is fresh only when its companion `file` entry is fresh. The selection entry itself does not store `file_size` / `file_mtime` (those columns are `-`); they are inherited from the `file` entry for the same `file_path`. A stale `file` entry invalidates all selection entries for that file (consistent with the existing #46 invalidation rule).

Format: on-disk mtime is formatted to `YYYY-MM-DDTHH:MM:SS` UTC string and compared by string equality with the entry's `file_mtime`. `file_size` is compared as integer.

A mismatch in either field marks the entry stale, and lookup falls through to the next less-specific tier (Tier 1 stale → try Tier 2; Tier 2 stale → no pre-seed for that file).

### Multi-file pre-seed rule

Pre-seed activates only when every input file produces a fresh match at the **same tier**.

- All-files Tier 1: pre-seed activates from selection entries.
- All-files Tier 2: pre-seed activates from file entries (this includes the all-files-unfiltered case, which is Tier 2 by definition).
- Any mix (some Tier 1, some Tier 2, some none): skip pre-seed for the whole run.

Rationale: simplest invariant; avoids the question of how to merge bounds drawn from different filter populations.

### Pre-seeded values

When pre-seed activates, the following values populate in-memory state at start of run:

| Pre-seed target | Source columns | Aggregation across files |
|---|---|---|
| Duration bound (min) | `duration_min` | `min` across files |
| Duration bound (max) | `duration_max` | `max` across files |
| Bytes bound (min/max) | `bytes_min` / `bytes_max` | `min` / `max` |
| Count bound (min/max) | `count_min` / `count_max` | `min` / `max` |
| First timestamp | `first_timestamp` | earliest |
| Last timestamp | `last_timestamp` | latest |
| ts_precision | `ts_precision` (file entry only — selection entries have `-`) | per-file, not aggregated; see note |

**Note on `ts_precision`.** ltl normalizes all timestamps to milliseconds internally; stored bound values (`duration_min/max`, `bytes_min/max`, `count_min/max`) in `ltl-index.csv` are already in milliseconds. `ts_precision` is metadata about source-log timestamp resolution (for memory estimation and display purposes), carried per-file, not aggregated for arithmetic. Selection entries do not carry `ts_precision` (the column is `-` per #46 schema); when the active tier is Tier 1, `ts_precision` is read from the companion `file` entry.

Pre-seeded values populate the same in-memory state that the live read pass updates. The read pass continues to run today's `<` / `>` comparisons; it just starts with non-undef values when pre-seed is active.

### Drift detection (end of run)

After the parse pass completes, drift comparison is layer-aware based on which tier was active.

For each input file that contributed pre-seed values:

| Active tier | Compared values |
|---|---|
| Tier 1 (selection entry) | Live filtered values (the `selection`-row data the write side produces) vs pre-seeded selection bounds |
| Tier 2 (file entry, unfiltered run) | Live whole-file values vs pre-seeded file bounds |
| Tier 2 (file entry, filtered run) | Live filtered values vs pre-seeded file bounds. Drift here means the selection entry needed for this filter signature did not yet exist; the run's end-of-run write creates it. This is normal, not an error. |

Drift conditions per metric: `live min < pre-seeded min`, `live max > pre-seeded max`, `live first_ts < pre-seeded first_ts`, `live last_ts > pre-seeded last_ts`. Any drift on any metric on any file flags the run as drifted.

### Drift refresh

The existing #46 write logic already overwrites both `file` and `selection` entries with live values at end of run:

- The `file` entry is rewritten unless on-disk mtime matches the existing entry.
- The `selection` entry for `(file_path, current_filters)` is always rewritten (the read-and-preserve loop explicitly drops the prior matching selection entry).

Drift refresh therefore happens as a side-effect of the existing end-of-run write. Read-back adds no new write step; it observes whether the upcoming write will be a no-op (no drift) or load-bearing (drift). The atomic-write guarantee from #46 (write-temp-then-rename) is preserved.

### `-V` verbose output

The feature emits a dedicated `=== INDEX READ-BACK ===` section in `-V` output, separate from the benchmark-data block (which is reserved for benchmark regression tracking). The section is **always emitted under `-V`**, so its presence/absence is not itself diagnostic — the `index_used` line inside it is.

The section content must be sufficient for an external test to assert that read-back operated correctly. That means exposing **which rows were matched per file** and **what aggregated bounds were derived**, not just a yes/no flag. The section has four layers of detail.

#### Layer 1 — Run-level summary

```
=== INDEX READ-BACK ===
index_used: yes|no
index_filter_signature: <serialized filters or "-">
heatmap_preseed_min: <value or "-">    (only when a heatmap is active)
heatmap_preseed_max: <value or "-">    (only when a heatmap is active)
```

`index_filter_signature` is the run's filter signature. Always emitted. Lets tests confirm the run was identified with the expected filter context.

`heatmap_preseed_min` / `heatmap_preseed_max` are the live heatmap bounds after any index pre-seed, emitted only when a heatmap is active. They are the values that scale the heatmap axis, and let tests confirm that a filtered run is never seeded with a whole-file (Tier-2) maximum.

#### Layer 2 — Per-file lookup result

For each input file, in input order, one block:

```
file: <path>
  lookup: tier_1_selection|tier_2_file|none
  matched_entry_date: <ISO 8601 from the matched row, or "-" when lookup=none>
  freshness: fresh|stale_mtime|stale_size|no_entry
  preseed_duration_min: <value or "-">
  preseed_duration_max: <value or "-">
  preseed_bytes_min: <value or "-">
  preseed_bytes_max: <value or "-">
  preseed_count_min: <value or "-">
  preseed_count_max: <value or "-">
  preseed_first_timestamp: <ISO or "-">
  preseed_last_timestamp: <ISO or "-">
```

This is the per-file source-of-truth view. Tests assert against `lookup`, `freshness`, and the specific pre-seed values pulled from each matched row. `matched_entry_date` is emitted because it uniquely identifies which row was consumed when multiple selection entries exist for the same file.

#### Layer 3 — Run-level aggregated bounds (when pre-seed active)

Emitted only when `index_used: yes`, after all per-file blocks:

```
aggregated_preseed:
  duration_min: <min-of-mins> (from <path>)
  duration_max: <max-of-maxes> (from <path>)
  bytes_min: <value> (from <path>)
  bytes_max: <value> (from <path>)
  count_min: <value> (from <path>)
  count_max: <value> (from <path>)
  first_timestamp: <earliest> (from <path>)
  last_timestamp: <latest> (from <path>)
```

The `(from <path>)` suffix names which input file contributed the winning value. For single-file runs this is redundant but kept for format consistency. For multi-file runs it lets tests assert "the global `duration_max` came from file B" — which is the way to verify min-of-mins / max-of-maxes was computed correctly.

#### Layer 4 — Drift detection result (when pre-seed active)

```
drift_detected: yes|no
```

When `drift_detected: yes`, additionally one block per drifted file:

```
drift_file: <path>
  duration_min: live=<live> preseed=<preseed> drifted=yes|no
  duration_max: live=<live> preseed=<preseed> drifted=yes|no
  bytes_min: ...
  bytes_max: ...
  count_min: ...
  count_max: ...
  first_timestamp: ...
  last_timestamp: ...
```

Per-metric `drifted=yes|no` so tests can assert exactly which metrics drifted, not just that drift occurred. Required for asserting drift-refresh scenarios — verifying that the specific narrowed bound is the one that drifted, not some unrelated metric.

#### Stability of label format

Section name (`=== INDEX READ-BACK ===`), all top-level keys (`index_used`, `index_filter_signature`, `aggregated_preseed`, `drift_detected`), per-file block keys (`file`, `lookup`, `freshness`, `matched_entry_date`, all `preseed_*`), and all `drift_*` keys are part of the feature contract. Tests read these labels; consumers may read them; they are not implementation-internal. Renaming a label is a spec change, not an implementation change.

## Interactions with existing features

### With write side (#46)

Read-back uses the same path resolution, the same CSV settings, the same column schema, and the same filter signature format produced by the existing write side. No format changes. The end-of-run write is unchanged in mechanism — it already refreshes both file and selection entries from live values. Read-back adds no new write step; it observes whether the refresh was a no-op.

### With multi-file runs

Each input file is checked independently for tier matching and freshness. Pre-seed activates only when all input files match at the same tier and are fresh. Drift is tracked per file; a multi-file run reports the list of drifted files in `-V`.

### With filtered runs

Filters are the *primary* reason this feature has tiered lookup. A filtered run looks for a Tier 1 selection entry matching `(file_path, filter_signature)`. This is the most-specific match and the most accurate pre-seed.

Filter signature comparison is exact-string against the value produced by the existing serialization. Different filter values → different signatures → different selection entries. The signature is alphabetically sorted and URL-encoded by the existing write side; read-back reproduces the same signature for the current run and compares as exact strings. Repeated multi-value filter flags are canonicalized by sorting the values within each flag, so the same logical selection produces one identical signature regardless of the order the values were given on the command line (e.g. `-e A -e B` and `-e B -e A` match the same selection entry).

A filtered run that does not find a matching selection entry falls back to the file entry (Tier 2). The file entry's bounds describe the *whole file*, which over-states a filtered population, so a filtered Tier-2 run is **not** pre-seeded from the file entry's bounds for heatmap scaling — the live pass discovers the filtered bounds directly, exactly as an un-indexed run would. (An unfiltered run's file bounds equal its filtered bounds, so unfiltered Tier-2 pre-seeding is retained.)

### With unfiltered runs

An unfiltered run has filter signature `-`. Per the multi-file rule, an unfiltered run's natural tier is Tier 2 (the file entry). The spec treats unfiltered = Tier 2 as the canonical case to keep multi-file mixing rules clean. (A Tier 1 selection entry with `filters = -` and a Tier 2 file entry describe the same population — whole file — so they would always agree.)

## Edge cases and behavior under stress

| Case | Behavior |
|---|---|
| `ltl-index.csv` missing | No pre-seed; `index_used: no`; behavior identical to today. |
| `ltl-index.csv` present but unreadable (permissions) | Warn to stderr; no pre-seed; behavior identical to today. |
| `ltl-index.csv` present but malformed (CSV parse error / truncated) | Warn to stderr; no pre-seed; do not crash. End-of-run write proceeds as today (the existing write logic handles the corrupt case by overwriting). |
| Index entry missing one or more bound columns (`-` placeholder) | Treat the missing column as "no pre-seed for that bound"; pre-seed any other columns that are present. |
| Filter signature differs by encoding-equivalent strings (e.g., legacy non-encoded entry) | Treat as no Tier 1 match — fall through to Tier 2. The on-disk entry will be replaced on next write. |
| Selection entry written before intra-flag value canonicalization (its `filters` key used the pre-canonicalization value order) | No longer matches the canonical signature — falls through to Tier 2 (which is now safe for filtered runs) and is rebuilt in canonical form on the next end-of-run write. Self-healing; no migration needed. |
| File mtime changes between startup read and end-of-run write | The on-disk file changed mid-run. Today's write side captures live `file_mtime` at write time, so the index reflects actual file state. Drift detection unaffected (it compares pre-seed vs live, not against on-disk mtime). |
| Extremely fast run where mtime resolution doesn't change | Freshness passes correctly because `file_size` is also compared. |
| User deletes `ltl-index.csv` during the run | End-of-run write recreates it as today. No special handling needed. |
| Two ltl processes running concurrently against the same cwd | Out of scope. Atomic-rename gives last-writer-wins; this is pre-existing #46 behavior and #179 does not change it. |
| A file's bounds widen unboundedly run after run | Each run refreshes the matching entry; no accumulation of stale narrow bounds. Self-healing. |
| Filter applied this run that has never been seen before | No Tier 1 match (signature is new). Tier 2 fallback if file entry is fresh. End-of-run write creates a new selection entry for this signature. Next run with same filters gets Tier 1. |
| File entry is fresh, but selection entry for current filters has expired (>90 days) and was purged | No Tier 1 match. Tier 2 fallback. End-of-run write creates a fresh selection entry. |

Piped/stdin input is not a supported ltl input mode and is not addressed by this feature.

## Acceptance criteria

- [ ] When `ltl-index.csv` contains a fresh `selection` entry for `(input_file, current_filter_signature)`, the in-memory pre-run bound state is populated from that entry before the parse pass begins, and `-V` reports `index_tier: tier_1_selection`.
- [ ] When no fresh `selection` entry matches the current filters but a fresh `file` entry exists for the input file, the in-memory pre-run bound state is populated from the `file` entry, and `-V` reports `index_tier: tier_2_file`.
- [ ] When `ltl-index.csv` does not contain any usable entry for an input file, behavior is identical to today's (no pre-seed, no warning, no error), and `-V` reports `index_used: no`.
- [ ] When an entry exists but `file_size` or `file_mtime` does not match the on-disk file, the entry is stale; pre-seed falls through tiers per spec.
- [ ] In a multi-file run, pre-seed activates only when every input file matches at the same tier and all matches are fresh; otherwise no pre-seed.
- [ ] Global pre-seeded duration bound is the min-of-mins and max-of-maxes across all per-file fresh entries at the active tier.
- [ ] At end of run, any live captured value exceeding (or falling below) its pre-seeded bound is flagged as drift, layer-aware: filtered run drifts against selection-entry pre-seed; unfiltered run drifts against file-entry pre-seed.
- [ ] When drift is flagged, the matching entry (selection or file) is refreshed via the existing end-of-run write. The next run with identical filters reads the refreshed bounds and observes no drift.
- [ ] `-V` output emits a complete `=== INDEX READ-BACK ===` section per the format defined in this document: run-level summary (`index_used`, `index_filter_signature`), per-file lookup blocks (`lookup`, `freshness`, `matched_entry_date`, all `preseed_*` values), aggregated-pre-seed block when active (with `(from <path>)` provenance), and drift detail blocks when drift detected (with per-metric `drifted=yes|no`).
- [ ] All test scenarios defined in **Validation** below pass: each scenario's index-orchestration setup produces the expected `=== INDEX READ-BACK ===` output when ltl is run with the scenario's args.
- [ ] No new CLI flag is introduced.
- [ ] All existing tests in `tests/validate-regression.sh` pass byte-identically against the pre-feature baseline. Two consecutive runs with identical filters (the second consuming the index written by the first) produce identical output.
- [ ] Two consecutive runs with *different* filters produce different selection entries; the second run does not erroneously consume the first run's selection entry.
- [ ] A malformed index file does not crash ltl; it is treated as if absent for read-back purposes; a warning is emitted to stderr.

## Validation

Three layers. Test definitions and the index-orchestration contract are part of this feature so it is testable on day one — tests are part of the feature deliverable, not a deferred concern.

### Existing regression suite (no changes)

`tests/validate-regression.sh` — all 15 tests must pass byte-identically. Validates that pre-seeding does not change rendered output, since pre-seed values converge with live values during the parse pass.

### New test suite for #179: index read-back scenarios

A new test runner is introduced as part of this feature. Each scenario:

1. **Sets up an isolated test directory** containing the input log file(s) for the scenario.
2. **Orchestrates `ltl-index.csv` state** by writing specific rows directly into the file — bypassing ltl entirely. This is the test harness's primary mechanism: the test author crafts the exact index state needed to trigger the scenario.
3. **Runs ltl** with the scenario's CLI args and `-V`.
4. **Asserts** specific lines under the `=== INDEX READ-BACK ===` section against expected values.

Without writing index rows directly, scenarios like `drift-refresh-tier1` (requires bounds narrower than reality) and `expired-selection-entry` (requires a row with an old `entry_date`) are unreachable from running ltl alone. Direct orchestration is the load-bearing test contract.

#### Index orchestration — supported operations

Tests construct index state via these operations on `ltl-index.csv`:

| Operation | Purpose |
|---|---|
| Create a new index file with a header row and zero or more entry rows | Seed any state from scratch |
| Append a `file` row with specific column values for a specific input file | Set Tier 2 bounds, mtime, size, line/match counts |
| Append a `selection` row with specific column values and a specific `filters` signature | Set Tier 1 bounds for a specific filter context |
| Set `entry_date` to a specific past or current ISO 8601 timestamp | Test expiration logic (>90 days = purged on next write) |
| Set `file_mtime` and `file_size` to match or mismatch the on-disk file | Test freshness check |
| Truncate or corrupt the file | Test malformed-index handling |

#### Test scenarios

Each scenario is a named test case with explicit setup, action, and assertions. `<F>` denotes a test input log file with known content (e.g., produces `duration_min=10`, `duration_max=500` when fully parsed). `<F1>` and `<F2>` denote two distinct files with known distinct bound values.

| Scenario | Setup | Action | Assertions |
|---|---|---|---|
| `cold-no-index` | No `ltl-index.csv` exists. | `ltl <F>` (unfiltered, with `-V`). | `index_used: no`. After run: `ltl-index.csv` exists with one `file` row and one `selection` row (filters=`-`) for `<F>`. |
| `warm-unfiltered` | Run `cold-no-index` first to produce a fresh index. | `ltl <F>` again with same args. | `index_used: yes`, `index_tier: tier_2_file`, `freshness: fresh`, `matched_entry_date` matches the row from the prior run, `preseed_duration_min: 10`, `preseed_duration_max: 500`, `drift_detected: no`. Output byte-identical to first run. |
| `cold-filtered-tier2-fallback` | Run `cold-no-index` first (creates `file` row + selection row for filters=`-`). | `ltl -dmin=50 <F>`. | `index_used: yes`, `index_tier: tier_2_file` (no Tier 1 match for `-dmin=50;`), `index_filter_signature: -dmin=50;`, pre-seed values come from the `file` row. After run: a new `selection` row exists with `filters=-dmin=50;`. |
| `warm-tier1-filtered` | Run `cold-filtered-tier2-fallback` first (creates a selection row for `-dmin=50;`). | `ltl -dmin=50 <F>` again. | `index_used: yes`, `index_tier: tier_1_selection`, `index_filter_signature: -dmin=50;`, `matched_entry_date` matches the selection row from the prior run, `drift_detected: no`. |
| `warm-tier2-different-filters` | Index has a selection row for `-dmin=50;` and a fresh file row. | `ltl -dmin=100 <F>`. | `index_used: yes`, `index_tier: tier_2_file`, `index_filter_signature: -dmin=100;`. After run: a new selection row exists for `-dmin=100;`; the prior `-dmin=50;` row is preserved. |
| `stale-mtime` | Index has a fresh row; `touch <F>` to advance mtime after the index was written. | `ltl <F>`. | `index_used: no`, per-file `freshness: stale_mtime`. After run: index row's `file_mtime` updated to current. |
| `stale-size` | Manually edit the file row in the index to have a different `file_size`; do not change the on-disk file. | `ltl <F>`. | `index_used: no`, per-file `freshness: stale_size`. |
| `drift-refresh-tier1` | After a `warm-tier1-filtered` baseline, manually narrow the selection row's `duration_max` to a value smaller than `<F>`'s actual filtered max (e.g., `duration_max=100` when actual is `400`). | `ltl -dmin=50 <F>`. | `index_used: yes`, `index_tier: tier_1_selection`, `drift_detected: yes`. Drift block shows `duration_max: live=400 preseed=100 drifted=yes`, other metrics `drifted=no`. After run: selection row's `duration_max` is `400`. Re-run: `drift_detected: no`. |
| `drift-refresh-tier2` | Manually narrow the file row's `duration_max`. | `ltl <F>` (unfiltered). | `index_tier: tier_2_file`, `drift_detected: yes`. Drift block identifies `duration_max` as drifted. Re-run: `drift_detected: no`. |
| `multi-file-all-fresh-tier2-unfiltered` | Two file rows, one each for `<F1>` and `<F2>`, both fresh. `<F1>`: `duration_min=10, duration_max=500`. `<F2>`: `duration_min=5, duration_max=300`. | `ltl <F1> <F2>`. | `index_used: yes`, `index_tier: tier_2_file`. Per-file blocks both show `lookup: tier_2_file`, `freshness: fresh`. `aggregated_preseed.duration_min: 5 (from <F2>)`, `aggregated_preseed.duration_max: 500 (from <F1>)`. |
| `multi-file-all-fresh-tier1` | Selection rows for `-dmin=50;` exist for both `<F1>` and `<F2>`, both fresh. | `ltl -dmin=50 <F1> <F2>`. | `index_used: yes`, `index_tier: tier_1_selection`. Aggregation per metric uses the winning file. |
| `multi-file-mixed-tiers` | `<F1>` has a Tier 1 selection row for `-dmin=50;`. `<F2>` has only a Tier 2 file row (no matching selection). | `ltl -dmin=50 <F1> <F2>`. | `index_used: no` (mixed-tier strict-skip rule). Per-file blocks show `<F1>: lookup: tier_1_selection`, `<F2>: lookup: tier_2_file` so the test can verify the *reason* for the skip. When mixed-tier triggers a skip, per-file `lookup` values still report what each file *would* have matched at, but no `aggregated_preseed` block is emitted and `index_used: no`. |
| `multi-file-one-stale` | `<F1>` fresh, `<F2>` mtime-stale. | `ltl <F1> <F2>`. | `index_used: no`. `<F1>: freshness: fresh`, `<F2>: freshness: stale_mtime`. |
| `malformed-index` | Truncate `ltl-index.csv` mid-row, or corrupt CSV quoting. | `ltl <F>`. | Warning emitted to stderr. `index_used: no`. After run: index is overwritten with valid content. |
| `missing-bound-column` | A file row with `duration_max=-` (placeholder) but other bounds set. | `ltl <F>`. | `index_used: yes`, per-file `preseed_duration_max: -`, other preseeds populated. Live discovery handles the missing bound as today (no pre-seed for that metric). |
| `expired-selection-entry` | A selection row with `entry_date` >90 days old. | `ltl -dmin=50 <F>`. | The expired row is purged at end-of-run write per existing #46 logic. Tier 2 fallback applies since no Tier 1 match. After run: new selection row exists with current `entry_date`. |
| `unwritable-cwd` | cwd is read-only; index lives in `tmpdir()` with absolute paths per #46. | `ltl <F>`. | Read-back resolves the temp-dir index correctly. Per-file `lookup` reflects the matched entry. |

#### Assertion mechanics

Tests parse the `=== INDEX READ-BACK ===` section from `-V` output and assert specific keys equal specific values. The format defined in **`-V` verbose output** above is the contract. Tests do not assert against rendered bar-graph output (that's the existing regression suite's job); they assert against the read-back section.

### `-V` instrumentation as the validation surface

The labels and structure defined in this document are the test contract. Without that level of detail in `-V`, scenarios like `multi-file-all-fresh-tier2-unfiltered` (which must assert "the global `duration_max` came from `<F1>`") are not assertable.

## Related issues

- **#46 (closed)** — provides the data this feature consumes. Schema, filter signature format, atomic-write contract, and the dual-layer (file + selection) entry design come from there.
- **#34** — two-pass streaming. Pass 1 (bound discovery) becomes conditional on the index being fresh at the active tier; #34 will consume the same pre-seeded bounds defined here, layer-aware.
- **#44** — file heuristics. Consumes pre-seeded `match_count`, `line_count`, timestamp range, and bound metadata for time/memory estimation. Layer-aware: filtered runs get filter-specific estimates from selection entries.
- **#23 Phase 2** — detect stage uses `first_timestamp`, `last_timestamp`, and `ts_precision` from pre-seed as detection hints. Phase 2's `finalize` stage uses pre-seeded bounds for bucket setup. Filter-aware via the same tiered lookup.
- **#51** — highlight-data memory optimization. Consumes pre-seeded bounds when allocating count-based bucket structures.
- **#180** — when named pipeline stages land, the read-back step described here moves into the `detect` stage's setup. The spec does not depend on #180 having shipped.
- **#181** — buffered read pipeline. Independent of this feature; both feed into #23.

## Spec stability

This document is intended to be stable across the implementation cycle. Two categories of change are expected post-merge:

1. Clarifications when an unspecified case is encountered (move it from "unspecified" to "specified" in **Edge cases**).
2. Updates when downstream features (#34, #44, #51, #23 Phase 2) actually consume the primitive — at that point, this doc may add a "Consumed by" subsection per consumer to record what each feature reads from the pre-seed and at which tier.

The spec does **not** track implementation status, code locations, or commit history. Those live in commit messages and the issue itself.
