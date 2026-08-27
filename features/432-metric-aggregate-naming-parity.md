# #432 — Metric/aggregate naming alignment and bytes parity

Issue #432 (align built-in metric/aggregate naming with the UDM convention;
`mean_bytes` is the outlier). Stage 6 of the 0.18.0 delivery order recorded in
`features/bin-counter-accuracy-and-observability.md` § D6.

## What this is for

A user who has learned the user-defined-metric vocabulary — `udm_<name>_mean`,
`_min`, `_max`, `_sum`, `_occurrences` — reasonably expects the built-in metrics to
read the same way. `count` does. `bytes` does not: it carries a sum and a mean whose
name is inverted (`mean_bytes`), and nothing else.

The requirement is **metric parity for bytes across the tool's two CSV surfaces** —
per message and per time bucket — so that bytes carries the same aggregate family as
duration and count already do on those same surfaces, under names that follow one
convention.

## The two surfaces, and the third scope that is not one of them

`ltl` emits two CSV surfaces, and they are not built the same way:

| | Surface A — MESSAGES | Surface B — STATS |
|---|---|---|
| row scope | one per consolidated message key | one per time bucket |
| filename | `build_csv_filename('MESSAGES')` | `build_csv_filename('STATS')` |
| header source | a fixed `qw()` literal in `pipeline_render` | derived from `@output_columns` in `normalize_data_for_output` |
| row emitter | `print_message_summary` | the per-bucket row loop |
| header/row coupling | **two independent lists ~800 lines apart** — both must be edited in step | positional, from one list |
| adding a column | edits two literals | appended to `@output_columns` after the layout is built — **CSV-only, not rendered** (see D8) |

There is a **third scope** that is not a CSV surface in this sense: the per-file
`ltl-index.csv` written by `write_index_file()`, which carries whole-file
`bytes_min`/`bytes_max`/`bytes_avg` per input file. It is a different aggregation
level and does not satisfy, or contribute to, parity on Surface A or B. Its
identifiers are renamed under D4 below precisely so this can never be confused again.

## The parity matrix as shipped (release/0.18.0)

Established by audit, 2026-08-27, and adversarially verified per cell (21 agents,
zero refutations, zero scope confusions). Identical gap on both surfaces.

| aggregate | duration | count | **bytes** |
|---|---|---|---|
| occurrences (n) | absent (computed, unemitted) | `count_occurrences` | **absent — not computed** |
| min | `min` | `count_min` | **absent — not computed** |
| mean | `mean` | `count_mean` | **`mean_bytes`** (inverted name) |
| max | `max` | `count_max` | **absent — not computed** |
| sum | `duration` / `duration_nice` | `count_sum` | `bytes` / `bytes_nice` |
| std_dev, cv, p1–p99999, iqr, skewness, kurtosis, bimodality_coef | all present | absent | **absent** |

Bytes carries two of the five basic aggregates. Count carries all five.

The asymmetry is visible in three adjacent lines of the per-message accumulation in
`read_and_process_logs()` — bytes gets a sum and no companion counter, while count
immediately below it maintains its whole family:

```perl
$log_messages{$category}{$log_key}{total_bytes} += $bytes if defined $bytes;

if( defined $count ) {
    $log_messages{$category}{$log_key}{count_sum} += $count if defined $count;
    $log_messages{$category}{$log_key}{count_occurrences}++;
    $log_messages{$category}{$log_key}{count_min} = $count if !defined ... || $count < ...;
    $log_messages{$category}{$log_key}{count_max} = $count if !defined ... || $count > ...;
}
```

At the per-bucket scope the same holds: `$log_analysis{$bucket}{total_bytes}` is a
bare sum with no min, max or observation count.

## F1 — The shipped `mean_bytes` is wrong, and parity is its fix

Found during the audit. `mean_bytes` divides the bytes sum by `occurrences` — the
count of **all matched lines** — while `total_bytes` sums only those lines that
**carried a bytes value**. On any log where some matched lines have no bytes field,
the mean is understated. The source already names the defect at the derivation site
in `print_message_summary`:

```perl
# BUG/ WRONG!!! below assumes all lines have bytes, but not really
my $mean_bytes = int( $total_bytes_num / $occurrences + 0.5 ) if defined $total_bytes_num;
```

The same wrong divisor appears a second time in the sort pre-pass in
`calculate_all_statistics()`, where `$entry->{mean_bytes}` is materialised for
ranking (`$sort_key eq 'mean_bytes'`) — greppable as `$entry->{total_bytes} &&
$entry->{occurrences}`. Both sites must move together, or `-so` ranks on a different
value than the CSV reports.

The correct divisor is a bytes observation count — which is exactly the
`bytes_occurrences` cell the parity matrix shows as missing. **The parity work and
this defect have one fix**, and the defect is what makes `bytes_occurrences` a
requirement rather than a nicety.

Per the architect (2026-08-27): defects surfaced by this audit belong to #432 and do
not get their own issues.

## Locked decisions

D1–D3 were taken in the 0.18.0 specification interview and are transcribed from the
issue body. D4–D7 were taken on 2026-08-27 during the audit walkthrough.

### D1 — Bare metric words alias to the sum

`bytes` = sum of bytes, `duration` / `time` = total duration, `count` = sum of the
count metric. The rule already holds uniformly in the code; it is now stated.
`occurrences` is not an exception to it — it is not a metric, it is how many messages
matched, so there is nothing to sum.

### D2 — `mean_bytes` becomes `bytes_mean`, clean break

No alias, no deprecation path. Called out in the release notes and that is the end of
the story.

### D3 — Duration keeps its bare CLI spellings; CSV headers take the prefix

Duration is the tool's subject, not an extension of it: every statistic in the summary
table is a duration statistic unless it says otherwise, and prefixing twelve columns
with the same word costs width in a table that already auto-hides columns. `duration_*`
spellings are accepted as **aliases** on the CLI, so a user who has learned the
convention guesses `duration_p95` and it works. The **CSV output column headers do**
take the `duration_` prefix, for coherence with the other metric families.

### D4 — The per-file index identifiers are renamed to say "whole file"

**Architect, 2026-08-27:** *"If you need to rename the per file metrics for bytes,
mean bytes, max, please go ahead and do so. It should be clear by their variable names
that they're referring to the whole file."*

The index's `bytes_min` / `bytes_max` collide by name with the per-message and
per-bucket bytes family this issue introduces, at a different aggregation level. During
this audit that collision already produced one false finding — the index columns were
reported as evidence that per-message bytes min/max already existed. Names that state
their scope prevent the next one.

Applies to the index column vocabulary and its in-memory `$fd->{...}` accumulator
fields, including the selection-scoped `sel_` twins.

### D5 — Bytes gains the full basic family on **both** CSV surfaces

**Architect, 2026-08-27: "Yes. To both."**

`bytes_occurrences`, `bytes_min`, `bytes_mean`, `bytes_max` — per message *and* per
time bucket. Renaming the mean alone would create a family with one member and move
the wall one step along, since `bytes_max` would fail exactly as `bytes_mean` does
today.

On Surface B these are **not** rendered columns — see D8.

### D6 — Basic aggregates only; no bytes distribution statistics

The family is `occurrences`/`min`/`mean`/`max`/`sum`. Bytes percentiles, std_dev, cv
and the shape moments are **out of scope**.

Rationale, from the audit: the two classes are structurally different work. Four
scalars on an entry are identical under `-mdm bin` and `-mdm raw` and need only the
initialiser and the accumulation site. A bytes *percentile* would need its own
counter store, a branch in both `calculate_statistics` and `calculate_statistics_bin`,
a telemetry surface, and merge handling in `merge_bin_state` / `merge_consolidation_stats`.
Nothing in the requirement asks for it.

### D8 — The consumers are `-so` and the two CSV files; nothing is rendered

**Architect, 2026-08-27:** *"Consumers are on the sort order as well as the two CSV
files. These new metrics are not printed to the screen anywhere."*

`bytes_occurrences`, `bytes_min`, `bytes_mean` and `bytes_max` are available as `-so`
operands and appear as columns in the MESSAGES and STATS CSVs. They add nothing to the
terminal output. There is therefore no default-visibility question, no auto-hide
priority, and no terminal-width cost.

**This is an established pattern, not a new mechanism.** The STATS surface already
carries CSV-only columns: the 21 duration statistics are appended to `@output_columns`
after the layout is built, gated by `stats_csv_duration_columns_active()`, under a
comment that states the contract — *"`@output_columns` drives the CSV header/data only
here; the terminal render uses `@column_layout`"*. The bytes family follows the same
route.

The gate's own contract carries an obligation the bytes family inherits: the header
emitter and the per-bucket row push in `print_bar_graph` **must both** consult the same
predicate, so rows always match the header.

Corrects an audit conclusion: "a new CSV column on Surface B implies a new rendered
column" was read off the default path and missed the escape hatch duration already
uses.

### D7 — `ltl-index.csv` is aligned to the same convention

`avg` becomes `mean`, `_count` becomes `_occurrences`, metric-first throughout.

**Trap, from the audit:** `line_count` and `match_count` are structural row fields,
not metric aggregates. A naive `_count` → `_occurrences` sweep corrupts them. The six
columns in scope are `duration_count`, `duration_avg`, `bytes_count`, `bytes_avg`,
`count_count`, `count_avg` — and the bytes pair is subject to D4's scope renaming as
well.

## Prototyping obligation

`bytes_occurrences` / `bytes_min` / `bytes_max` are **new per-line capture** at the
per-message and per-bucket scopes (CLAUDE.md § Development Phases 2 — new per-line
hot-path cost). D-c's original premise, that this capability exists nowhere in the
tool, is correct *at these scopes*: the `bytes_min`/`bytes_max` that ship today are
the whole-file index accumulator (D4), a different aggregation level.

The governing precedent is #447 (control-character normalisation), where an unguarded
implementation of a far smaller per-line addition cost **+4.36% of total runtime**
before measurement forced a rework to +0.80%. See
`features/447-message-control-character-normalisation.md` § D4 and
`tests/profile/results/447-control-char-normalisation/`.

Requirements carried forward from that precedent:

- **Order-balanced ABBA design, ≥8 pairs.** Single-order interleaving was proven
  insufficient there: the same code measured +0.44% and +1.99% in different sessions
  because within-arm spread exceeded the effect.
- **The baseline arm reproduces the production call structure verbatim** (#58 F9,
  CLAUDE.md 2026-08-21) — extracted from `ltl`, not wrapped in a convenience sub.
- **Constants come from the source, not from memory** (CLAUDE.md 2026-08-27) — slice
  them out and name the source symbol beside any value that must be restated.

The measurement question is the per-line cost of the added comparisons under their
guard, at both scopes, against the current code as baseline.

## Verification obligations

From the audit of the harness surface. All are consequences of existing rules in
`tests/HARNESS-DESIGN.md`, not new policy.

- **One shared specification, two consumers.** `tests/csv-output/rules/messages-columns.tsv`
  and `stats-columns.tsv` are read by both `validate-csv-output.pl` and
  `compare-statistics-drift.pl`. An unknown CSV column is a hard failure in
  `check_column_structure()`. A partial rename fails both harnesses.
- **Position renumbering.** `messages-columns.tsv` pins an explicit `position` integer
  per column (currently 1..35); `stats-columns.tsv` uses `*` and is order-free. New
  columns on Surface A renumber every subsequent position in the same edit.
- **48 committed baseline CSVs re-blessed.** Each of the 24
  `tests/statistics-drift/baselines/*/` directories holds `messages.csv` and
  `stats.csv` whose headers carry the affected vocabulary. These are deliverables
  (`tests/statistics-drift/README.md` § Capturing baselines). A header-only rename
  should produce a diff confined to line 1 of each file — **any value change in that
  diff is a stop-and-investigate**, except where F1's divisor fix is the known cause,
  which must then be confirmed as the cause rather than assumed.
- **No benchmark baseline needs re-blessing.** Every `metric_name` in
  `tests/baseline/results/*.tsv` is an internal timing/memory/config label; none is in
  this vocabulary. The `tmap` canonicalization block in `compare-results.sh` covers
  TIMING stage labels only and needs no entry.
- **Benchmark scenario labels must not be retitled.** `run-benchmark.sh` defines
  `sort-p99|-so p99` and `sort-skewness|-so skewness`; the label before the pipe is the
  `test_name` column and pairs rows with no canonicalization. Renaming one unpairs
  every historical baseline silently.
- **New assertions proved to fail first.** HARNESS-DESIGN.md § Proving a new assertion
  can fail — each new bytes invariant is demonstrated failing against a sabotaged
  input, directly against `check_layer2_row` where possible, before the healthy path
  is run.
- **A negative assertion can pass vacuously.** `validate-index-read-back.sh` contains
  `assert_no_line ... '^  preseed_duration_min: -$'`; if a renamed key made that
  pattern match nothing the assertion would pass while hiding the regression.
- **The L3 oracle keys by bare statistic names.** `calculate-reference.py` emits
  `out["std_dev"]`, `out["cv"]`, `out["iqr"]` … and `@L3_COLUMNS` in
  `compare-statistics-drift.pl` is a bare-name list pairing oracle values to CSV
  columns. D3 prefixes the CSV headers but says nothing about the oracle — whether the
  oracle keys move or a mapping layer is added is an explicit decision to record, not
  to make silently.

## Open items

- ~~**O1 — Surface B rendered-column visibility.**~~ **Closed 2026-08-27 by D8** —
  the new metrics are consumers of `-so` and the two CSV files only, and are not
  rendered, so no visibility or auto-hide question arises.
- ~~**O2 — `-so` whitelist case sensitivity.**~~ **Closed** — the whitelist now
  matches case-insensitively, as every arm of the ladder below it already did.
- ~~**O3 — Alias normalisation point for D3.**~~ **Closed** — `duration_` is stripped
  once, ahead of both the whitelist and the ladder, so a prefixed spelling reaches
  neither the identity arm nor the `%STAT_FIELD_GROUP` membership test.
- ~~**O4 — Oracle key space.**~~ **Closed** — the oracle keeps its bare statistic keys
  and the mapping to the prefixed CSV columns lives in the comparator, guarded by a
  paired-rows-but-zero-cells check so a stale mapping fails loudly instead of
  comparing nothing.

## Status

**Delivered on branch `432-align-builtin-metric-aggregate-naming`, cut from
`release/0.18.0`.** Audit complete and verified per cell; decisions D1–D8 locked;
O1–O4 all closed.

### What shipped

- Bytes carries `bytes_occurrences` / `bytes_min` / `bytes_mean` / `bytes_max` on both
  CSV surfaces, and as `-so` operands. `mean_bytes` is gone (D2, clean break).
- The duration statistics take the `duration_` prefix on the CSV headers and keep
  their bare CLI spellings, with `duration_*` accepted as an alias (D3).
- The index schema is metric-first, and its bytes columns are `file_bytes_*` so the
  whole-file scope is unmistakable (D4, D7).
- **F1 is fixed.** `bytes_mean` divides by the bytes observation count at both
  derivation sites, so the CSV and `-so` ranking cannot disagree.
- An unobserved bytes metric reports nothing rather than a measured zero — the mean,
  the extrema and the total alike.
- `-ob` discards the metric completely: nothing about bytes is captured at either
  scope, and `-so bytes*` falls back the way any operand with no values does.

### Found and fixed while implementing

- **Consolidation dropped the family.** Both merge paths carried only the bytes sum,
  so a `-g` consolidated row arrived with a total and no observation count. Both now
  move the whole family, as the count blocks beside them already did.
- **The regression goldens rejected every branch build.** The version-banner
  normaliser matched `[0-9.]+`, which excludes the `X.Y.Z-{issue}` marker every
  feature branch stamps, so all 71 scenarios failed for the one difference the
  goldens exist to ignore. Fixed in the validator and the capture script together.
- **A silent-pass hazard in the L3 oracle layer.** The comparison loop skips any
  column absent from the row, so the prefixed CSV headers would have made every cell
  skip while the layer still reported OK. Guarded by a paired-rows-but-zero-cells
  check that fails the run.

### Measured cost

**+2.7%** end-to-end against the branch point (medians of 4 pairs, 1.43M-line access
log, same interpreter both arms), **−0.7%** under `-ob`. Inside the 5% gate.

The benchmark comparison against `v0.17.0-release` reads +5.0%, but that baseline
predates the rest of the 0.18.0 work (#462, #450, #459, #460, #447) and does not
attribute to this change.

The prototype predicted +1.8% and production measures roughly double: its arms were
faithful to each other but its environment was not faithful to production. It got the
ordering of the candidates right — which is what it was for — and the magnitude wrong.
Full record: `tests/profile/results/432-bytes-parity-capture/analysis.md`.

### Raised, not fixed here

Line-level profiling put the highlight suffix test in three of the top thirteen lines
of the script — ~2.0s on the reference corpus, ~12% of runtime — evaluated when no
highlight is active and on lines whose metric is absent. Pre-existing, on a shared
mechanism, and filed as **#478 (highlight bookkeeping evaluated on the hot path when
no highlight is active and when the metric is absent)**.

### Gate

26/26 harnesses pass (1,024 assertions). The 48 statistics-drift baseline CSVs were
re-blessed, and every value change across the 42 compared files is attributed: 78 F1
mean corrections, 368 unobserved-becomes-blank, and 15 `duration_nice` cells carrying
pre-existing formatting drift that no line of this change touches.
