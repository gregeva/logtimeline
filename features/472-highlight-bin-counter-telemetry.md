# Highlight bin-counter telemetry (Issue #472)

## Status

- **Issue**: #472 (the highlight bin-counter sub-stores are absent from the `-V`
  telemetry, so a highlighted run under-reports its own partitions and memory)
- **Branch**: `472-the-highlight-bin-counter-sub-stores-are-absent-from-the-v-telemetry-so-a-highlighted-run-under-reports-its-own-partitions-and-memory`
- **Target release**: v0.18.1
- **Phase**: specification and acceptance criteria agreed; no production code written

## Governing contracts, read before planning

| Record | What it governs here |
|---|---|
| `features/187-histogram-bin-counter-percentiles.md` § Decision 8 (`-V` reporting verbosity and format) | The locked contract this work amends: the section name, every field name, every consumer-name string, the block field order, the short `shares_partitions_with` block shape, the display order, and the stability clause that makes a new consumer name a decision rather than a change. Its consumer table already reserves names for highlight subsets. |
| same doc, § Edge cases | Carries a row stating as required behaviour that the highlight subset has no consumer name and no block reports it. That row is the defect written down as a contract, and is rewritten here. |
| `features/bin-counter-accuracy-and-observability.md` D3 (retention is measured before it is capped) | Why the gap matters: the retention ceiling is to be sized from runtime data gathered by this surface, and on a highlighted run the surface sizes it from the parent partitions alone. |
| same doc, D4 (the observability surface is designed for the end state, not for today) | One coherent surface, no redefinition mid-drop. Argues for naming the highlight consumers now and for reusing the existing full block shape rather than inventing a reduced one. |
| same doc, D9 (re-binning is counted on the store entry; the finalize projection at its own sites) | The invariant the new assertions are written against, and wrong in the tree in two ways. Trued up here (decision D9-correction below). |
| same doc, D10 (retention is emitted from stage 1) and D11 (`counter_memory_bytes` is a derived comparison figure) | Define `members_live`, `members_max`, `members_memory_bytes` and `counter_memory_bytes`, the four fields a highlight block repeats for its own store. D11 also directs absolute-footprint questions to RSS and `named_structure_sizes()`, which is the surface that already sees the highlight stores. |
| same doc, § Open items carried out of stage 1 | The drop record that carried this item forward out of #462 (the bin-counter `-V` telemetry carrier). Closed here by pointer. |
| `features/460-bin-model-percentile-source.md` § 5 | The hand-forward that filed this issue, recording what each disposition costs. Closed here by pointer. |
| `features/426-per-message-statistics-store.md` open question 6 and row V8 | Open question 6 asks whether `%bucket_stats_counters_hl` is in scope to remove. Claimed by this issue and closed by pointer. Row V8 records `consumers_active` and three siblings as locked clauses with no emission site; explicitly **not** decided here (D8 below). |
| `features/312-numeric-criteria-highlight-selection.md` | Owner of the highlight selection surface and of the single tag point (the `-HL` suffix on `$category_bucket`, `$category = 'highlight'`) that feeds every `_hl` structure. |
| `tests/HARNESS-DESIGN.md` §§ Reserved section names, Stability contract, When `-V` output changes, Self-documenting assertions, Proving a new assertion can fail, Invocation coherence | The procedure this change follows, and the form the amended section contract takes. |
| `docs/test-driven-development.md` | Acceptance criteria triage. |
| `prototype/README.md` § When a prototype is mandatory | Triggers (a) to (d). None fires; see § Prototype. |

---

## 1. The motivating consumer

A highlighted histogram run under `-o` publishes a percentile ladder for the
highlighted subset. In the YAML aggregate export, `aggregate_mapping()` writes
`measurements.histogram.<metric>.highlighted` with `occurrences` and the full
twelve-quantile ladder:

```perl
my $hl = $histogram_stats_hl{$metric};
if ($hl && ($hl->{count} // 0) > 0) {
    my $hl_block = aggregate_mapping();
    $hl_block->{occurrences} = aggregate_number($hl->{count});
    $percentiles_gated += aggregate_percentiles($hl_block, $hl, $hl->{count}, @ladder);
    $block->{highlighted} = $hl_block;
}
```

Those quantiles come from `finalize_histogram_unified()`, which computes them
from the streaming highlight partition with `percentile($src_hl, $q)` under the
parent's clamp, commented at the site `Same source and the same clamp as the
parent`. That is a shipped, user-facing number whose data model, partition
count, growth history, display re-binning and out-of-range audit are reported by
no `-V` field. Every equivalent figure for the parent's ladder is reported.

The second consumer is the retention ceiling. D3 (retention is measured before
it is capped) says the ceiling is decided from runtime data gathered by this
surface rather than guessed up front. On a run with a live highlight the surface
reports the parent partitions only, so the peak partition count and payload the
ceiling would be sized from are understated by whatever the highlight subset
holds, with nothing in the output saying so.

---

## 2. Requirement

On a run with a live highlight, the `=== histogram-bin-counters ===` section
reports the highlight subset's own partition count, growth history, display
projections, payload and retention, separately from the parent's, on each
surface that derives something from a highlight store. On a run with no live
highlight, the same blocks are present and report that the feature is not
active. A store that derives nothing is retired rather than reported.

---

## 3. Corrections to the issue body

Every sub name, store name and factual claim in the issue body verifies against
the tree at `3e727a6`. Five corrections and additions:

1. **The motivating consumer is missing.** The issue names the telemetry gap but
   not the shipped output behind it: the `highlighted:` percentile ladder in the
   YAML aggregate export, above. The on-screen highlight legend is the lesser
   half.
2. **The framing is three surfaces, not four, and the fourth already folds.**
   The per-message surface (`summary_table` and `csv_output`) has no highlight
   store: its counter key is `"$category\x1f$log_key"` with `$category` set to
   `highlight` or `plain`, and its block prints `partition_keying: (category,
   log_key)`. Its figures already move with the highlight. The defect is
   specific to the parallel-store surfaces.
3. **The memory framing is wrong in the issue's direction.** `-mem` reports
   high-water marks, not live residency: `measure_memory_structures()` only ever
   raises `%memory_high_water_marks`, which is why `heatmap_counters` still reads
   a figure after `finalize_heatmap_unified()` has deleted every one of its keys.
   The claim is therefore not "memory the run is holding and not accounting for"
   but "a peak partition count and payload the telemetry never sized", which is
   exactly what D3's ceiling needs.
4. **`features/187-…` § Edge cases already documents today's behaviour as
   required behaviour.** The row reads: "Highlight pattern present | The
   highlight subset streams its own parallel partitions and its percentiles come
   from them; it has no consumer name of its own in the `-V` block order, so no
   block reports it." It has to be rewritten under every disposition, including
   leaving the code alone, and belongs in the blast radius.
5. **The reservation the fix leans on points at a closed phase.** Decision 8
   reserves names for "Future consumers (highlight subsets per Phase 4 …) …
   when their migration phase locks them". Phase 4's owning ticket, #51
   (optimize heatmap and histogram memory usage for highlight data), closed
   2026-05-26 as no longer applicable, because the post-#34 architecture makes
   the sharing it proposed impossible. The trigger fired and passed with no
   names locked; this doc locks them.

One correction to the pre-interview brief, found while auditing the tree: the
brief states that always-printing the highlight blocks regenerates "every
capture-regression reference carrying this section". No `run_test` line in
`tests/capture-regression.sh` passes `-V` at all, and no reference under
`tests/reference-output` or `tests/rendered-output` contains the string
`histogram-bin-counters`. The only consumer of this section in the whole suite is
`tests/validate-histogram-bin-counters.sh`. The consequence recorded in D4 below
is therefore nil in practice, and is stated as a check rather than as work.

---

## 4. The mechanism today

Three omissions, all structural, referenced by enclosing sub name plus a snippet.

**(i) No highlight store is snapshotted.** `snapshot_counter_telemetry()` takes
one `$store` hashref, is generic over it, and reads only fields
(`rebin_growth`, `members`, `overflow`, `underflow`, `partition->{bin_count}`)
that `counter_update()` already populates on highlight entries exactly as on
parent entries. It is called on four stores and no `_hl` store:

```perl
$bin_counter_telemetry{heatmap_cells}   = snapshot_counter_telemetry(\%heatmap_counters);
$bin_counter_telemetry{heatmap_markers} = $bin_counter_telemetry{heatmap_cells};
```

The data is present; the call is missing.

**(ii) There is no name to print the figures under.**
`emit_bin_counter_mode_verbose()` iterates a closed `@consumer_order` of the
seven locked names, and five further per-consumer tables (`%feature_active`,
`%shares_with`, `%percentile_set`, `%partition_keying`,
`%consumer_opted_out_to_raw`) are keyed by those same names. There is no eighth
key, and Decision 8's stability clause forbids inventing one without a locked
decision entry. This is why #462 (the bin-counter `-V` telemetry carrier) left
the item open rather than fixing it in passing.

**(iii) The two highlight display projections are uncounted at their sites.** In
`finalize_heatmap_unified()` the parent loop ends:

```perl
$bin_counter_telemetry{heatmap_cells}{rebin_finalize_events}++;
delete $heatmap_counters{$bucket};
```

and the highlight loop immediately below runs the same `partition_rebin()`
display projection and increments nothing. `finalize_histogram_unified()` has
the identical shape, its highlight branch guarded `if ($highlight_active &&
$src_hl)` with an inner `if ($n_hl > 0)`. Because
`snapshot_counter_telemetry()` seeds `rebin_finalize_events` to zero by design
and the finalizers count at their own sites, fixing (i) alone would leave a
highlight block reading `rebin_finalize_events: 0` against a non-zero
`partition_count`.

**The consequence, measured.** On the 5,000-line Tomcat access log fixture
`docs/test-logs.md` names for this harness, invoked `-ni -bs 1440 -oe -hm
duration -hg duration -bdm bin` with and without `-hdmin 100` (which marks 287
of the 5,000 lines and prints `HIGHLIGHTED 287` on the same output), the two
`=== histogram-bin-counters ===` sections are byte-identical, both reporting
`partition_count: 1` and `counter_memory_bytes: 24744` for `heatmap_cells` and
for `histogram_view`. On the same two arms `-mem` reports `heatmap_counters_hl`
at 18 KiB and `histogram_counters_hl` at 18 KiB present in the highlighted arm
and absent in the other. At `-bs 1` (five time buckets) `heatmap_cells` reports
`partition_count: 5` in both arms while the run holds ten heatmap partitions.
The tool measures the same structures on two of its own surfaces and gives two
answers.

**Not in the mechanism.** `named_structure_sizes()` already enumerates all three
`_hl` counter stores and needs no change. No render, no exported value and no
percentile a user reads changes. This is an observability change plus one
retirement.

---

## 5. Decisions

Locked by the architect unless marked otherwise. D1 and D2 are the architect's;
D3 to D10 were delegated with their reasons stated below; D9-correction is a
correction to an existing decision in another document rather than a new
decision here.

### D1 — The highlight subsets get their own consumer names

**Locked 2026-09-12.** The highlight subset is reported under its own consumer
name in the `=== histogram-bin-counters ===` section. Its figures are not folded
into the parent's, and the heatmap and histogram highlight stores are not
re-keyed as compound-key stores to match the per-message surface.

Rationale. The section's principle is attribution: retention is sized and memory
attributed per consumer, which is what D3's ceiling and any later profiling of
highlight cost both need. Decision 8's consumer table already reserves names for
highlight subsets. The per-message surface carries the highlight as a dimension
of its compound key and is attributable there too, so naming the highlight here
makes the section more uniform in what it can attribute, not less. Folding would
change the meaning of six locked field descriptions (`partition_count`,
`counter_memory_bytes`, `members_live`, `members_max`, `members_memory_bytes`,
`rebin_growth_events` and `rebin_finalize_events`) with every existing shape
assertion still passing, so the change would land with no test able to see it,
which is the failure mode this issue reports. Re-keying is a data-model change
no consumer asks for.

### D2 — `%bucket_stats_counters_hl` is retired

**Locked 2026-09-12.** The store is deleted: its `counter_update()` call in the
parsing loop of `read_and_process_logs()` (annotated `# store parity only`), its
declaration in `## GLOBALS ##`, and its `Devel::Size::total_size` line in
`named_structure_sizes()` go together. No highlight consumer name is created for
the per-time-bucket surface.

Rationale. The store has exactly three references and no consumer or derivation:
`finalize_bucket_stats_unified()` contains no reference to it at all, and the
declaration comment concedes that no highlight statistics are derived from it.
Store parity is not a requirement any consumer states. Deleting it removes a
per-line site evaluated on every highlighted run under `-bdm bin`, which is a
site #478 (the highlight decision is re-derived from the -HL category suffix
throughout the read loop instead of kept once at the tag point) would otherwise
have to convert. If the
per-time-bucket surface later gains highlight statistics, the store is three
lines to restore, and this decision is the record of why it went.

This issue owns the answer. `features/426-per-message-statistics-store.md` open
question 6 ("is it in scope for #426 to remove, or does store parity have a
purpose the code does not record?") is closed by pointer to this decision.

### D3 — One highlight consumer per store with a derivation

**Decided here.** Two new consumer names, and only two:

| new consumer name | store | parent |
|---|---|---|
| `heatmap_cells_highlighted` | `%heatmap_counters_hl` | `heatmap_cells` |
| `histogram_view_highlighted` | `%histogram_counters_hl` | `histogram_view` |

No `heatmap_markers_highlighted` and no `histogram_bins_highlighted`. Those two
parents carry no store of their own: they are `shares_partitions_with` blocks
over their siblings' partitions, so a highlight twin of each would restate the
highlight parent's figures and nothing else. No `time_bucket_stats_highlighted`,
because D2 retires the only store it could report.

The names use the `_highlighted` suffix. `highlighted` is the word every user
surface already uses (the `HIGHLIGHTED` summary row, the `highlighted:` block in
the YAML aggregate export, the option long forms `--highlight-duration-min` and
its five siblings), while `hl` is an internal abbreviation and the `-V` consumer
names are otherwise spelled out (`summary_table`, `time_bucket_stats`). The
suffix form also sorts adjacent to its parent and reads as the subset it is.

### D4 — The highlight blocks always print

**Decided here.** Both blocks appear on every run that emits the section. When no
highlight is active, or the surface itself is inactive or opted out to raw, the
block carries its `path:` line alone, with `path: feature_not_active` in the
no-highlight case.

Rationale. Decision 8 locks the section as always present with every consumer
printing at least a `path:` line on every `-V` run, and `feature_not_active` is
the existing vocabulary for exactly this state. A conditional eighth and ninth
consumer would make the section's block count vary by run, which is a shape the
contract does not have and which a grep-stable surface should not acquire.

Consequence, checked rather than assumed: the only consumer of this section in
the test suite is `tests/validate-histogram-bin-counters.sh`. No `run_test` line
in `tests/capture-regression.sh` passes `-V`, and no committed reference output
contains the section, so no capture-regression reference regenerates. If that
changes before the work lands, the references regenerate in the same commit.

### D5 — Display order: strictly appended

**Decided here.** `heatmap_cells_highlighted` and `histogram_view_highlighted`
are appended after `histogram_bins`, in that order. The display order becomes:

```
summary_table, csv_output, time_bucket_stats, heatmap_markers, heatmap_cells,
histogram_view, histogram_bins, heatmap_cells_highlighted, histogram_view_highlighted
```

Rationale. Decision 8's order clause reads "later-added consumers append to the
end of this order". That is locked text and it covers this case as written.
Interleaving each highlight block after its parent reads better by eye, but it
would set the clause aside for a readability gain on a surface whose own contract
states that reader-friendliness is secondary to grep-stability. No amendment to
the order clause is made.

### D6 — The two highlight finalize projections are counted

**Decided here.** The `partition_rebin()` call in the highlight loop of
`finalize_heatmap_unified()` and the one in the highlight branch of
`finalize_histogram_unified()` each increment their own block's
`rebin_finalize_events`, symmetric with the parent sites.

Rationale. An uncounted display projection is the same class of omission this
issue is about, and without the count the field would read zero against a
non-zero `partition_count` inside a block whose parent is asserted on the
opposite equality.

The D9 equality (`rebin_finalize_events == partition_count` on the heatmap and
histogram surfaces) therefore holds unconditionally on
`heatmap_cells_highlighted`: the highlight loop iterates `keys
%heatmap_counters_hl` and projects each once. On
`histogram_view_highlighted` it holds **conditionally**: the branch is guarded
`if ($highlight_active && $src_hl)` with an inner `if ($n_hl > 0)`, so a metric
whose highlight store exists but holds no observations is snapshotted as a
partition and never projected. The contract states the equality there as holding
when every highlight partition carries at least one observation, and the harness
asserts it on a scenario constructed to satisfy that, never as an unconditional
invariant.

### D7 — Percentile fields on the histogram highlight only

**Decided here.** `percentiles_emitted` and `out_of_range_bounded` appear on
`histogram_view_highlighted` and on neither the heatmap highlight nor any other
new block.

Rationale. The histogram highlight publishes the twelve-quantile ladder in the
aggregate export's `highlighted:` block, so those two fields are the only report
of which quantiles it publishes and whether any landed out of range. The heatmap
highlight derives cell counts, not percentiles, and carries neither field, which
mirrors the asymmetry the contract already has: `heatmap_cells` carries no
percentile fields either.

`percentiles_emitted` on `histogram_view_highlighted` is the twelve-slug ladder
the export writes (`p1 p5 p10 p25 p50 p75 p90 p95 p99 p999 p9999 p99999`), not
the ten-slug set `histogram_view` reports. The two differ because the parent's
set is the on-screen legend's and the highlight's published set is the export's,
and a field that says which quantiles a consumer publishes has to say the true
ones. That difference is stated in the amended contract so a reader does not
read it as a defect.

### D8 — `consumers_active` and its three siblings are not decided here

**Recorded as an open item, not decided.** `consumers_active: none` is locked in
Decision 8 in four places and emitted nowhere, alongside `--exact-percentiles`,
`opt_out_active` and `opt_out_notice`. All four are recorded together as row V8
of `features/426-per-message-statistics-store.md` (four locked D7/D8 clauses
with no emission site). They live in the same decision and the same emitter this
work edits, but they are one audit finding with one cause and deciding one leaves
three standing. Disposition is the architect's, against that row, separately from
this issue. Nothing in this work depends on the outcome: the two new blocks print
unconditionally per D4, so they neither produce nor prevent a "no consumers
active" state.

### D9-correction — D9's invariant sentence is trued up

**Correction to `features/bin-counter-accuracy-and-observability.md` D9, dated
2026-09-12,** made in this pass because the new assertions are written against
that sentence and it is wrong in the tree in two ways:

- It says the finalize projection is "counted at its four call sites". There are
  **three** write sites to `rebin_finalize_events`: the parent loop of
  `finalize_heatmap_unified()`, the parent loop of `finalize_histogram_unified()`,
  and the assignment in `finalize_message_stats_unified()` that carries #459's
  collapse accounting.
- It says the field is "exactly 0 on `summary_table`, `csv_output` and
  `time_bucket_stats`". That is true of `time_bucket_stats` and of the two
  per-message consumers only on a run with no consolidation. Under `-mdm bin -g
  70` on the Tomcat access log fixture, `summary_table` reports **167**, and
  `ltl`'s own comment at the site says the field is no longer contractually zero
  for that consumer. Decision 8's field description was already amended for this
  under #459 (bin-counter combination order); D9's summary sentence was not.

The corrected sentence states three write sites, the `time_bucket_stats` zero as
the only unconditional zero, the per-message consumers as carrying the collapse
count, and the heatmap and histogram equality as asserted by
`tests/validate-histogram-bin-counters.sh` **once this issue adds those
assertions**. Today the harness asserts the `time_bucket_stats` zero and no
heatmap or histogram consumer block at all.

### D10 — Harness scope

**Decided here.** `tests/validate-histogram-bin-counters.sh` gains, in this
order:

1. **The parent blocks the highlight assertions are stated against**, which the
   harness does not have today: a `heatmap_cells` block scenario and a
   `histogram_view` block scenario asserting the locked field list, the
   `partition_keying` value, and the D9 equality `rebin_finalize_events ==
   partition_count`. This is the minimum, not the whole coverage gap: a highlight
   assertion stated against parent arithmetic that no scenario pins can pass
   while the parent drifts. Anything beyond the parent blocks those assertions
   rest on is filed separately.
2. **The highlight scenarios**: two arms of one invocation differing only in the
   highlight flag, asserting on the highlighted arm `partition_count`,
   `counter_memory_bytes`, `rebin_finalize_events == partition_count` where D6
   says the equality holds, `path: unified`, and on
   `histogram_view_highlighted` the twelve-slug `percentiles_emitted` and the
   `out_of_range_bounded` audit line; and on the un-highlighted arm `path:
   feature_not_active` on both new blocks.

Every new assertion carries the `asserts` / `produced_by` (function name) /
`contract` triple, and every one is demonstrated to fail before it is trusted to
pass, per `tests/HARNESS-DESIGN.md` § Proving a new assertion can fail.

---

## 6. The amended `-V` section contract

Form per `tests/HARNESS-DESIGN.md` § Reserved section names and § Stability
contract. This is an **addition** to `=== histogram-bin-counters ===`: two new
consumer-name strings and two new blocks. No existing name, field or value
changes meaning, so nothing here is a breaking change to an existing consumer.

### New consumer-name strings

| `-V` consumer name | Covers | Store | Parent |
|---|---|---|---|
| `heatmap_cells_highlighted` | Heatmap cell counts for the highlighted subset | `%heatmap_counters_hl` | `heatmap_cells` |
| `histogram_view_highlighted` | Histogram percentile ladder for the highlighted subset, published in the aggregate export's `highlighted:` block | `%histogram_counters_hl` | `histogram_view` |

Both are locked strings under Decision 8's stability contract from the moment
they ship: renaming either later is a breaking change requiring a further
decision entry and a sweep of every consumer.

### Display order

Appended after `histogram_bins`, `heatmap_cells_highlighted` first:

```
summary_table, csv_output, time_bucket_stats, heatmap_markers, heatmap_cells,
histogram_view, histogram_bins, heatmap_cells_highlighted, histogram_view_highlighted
```

### `path:` values

Both blocks are always present. The `path:` value resolves in this order:

| Condition | `path:` |
|---|---|
| The parent surface is not enabled (`-hm` absent for the heatmap block, `-hg` absent for the histogram block) | `feature_not_active` |
| The parent surface is enabled but no highlight is live (no `-h`, no `-hf`, none of the six numeric highlight bounds, no outcome highlight) | `feature_not_active` |
| The parent surface resolved to the raw data model (`-hmdm raw` / `-hgdm raw`, or `-dm raw`) | `user_opt_out` |
| Otherwise | `unified` |

When `path:` is `feature_not_active` or `user_opt_out`, the `path:` line is the
whole block, exactly as for the seven existing consumers.

### Block field set when `path: unified`

`heatmap_cells_highlighted` carries the full Decision 8 block, in the locked
field order, with no percentile fields:

```
consumer: heatmap_cells_highlighted
  path: unified
  partition_keying: time_bucket
  partition_count: <N>
  rebin_growth_events: <N>
  rebin_merge_events: <N>
  rebin_finalize_events: <N>
  max_partition_bins: <N>
  partitions_with_overflow_count: <N>
  partitions_with_underflow_count: <N>
  overflow_total: <N>
  underflow_total: <N>
  counter_memory_bytes: <N>
  members_live: <N>
  members_max: <N>
  members_memory_bytes: <N>
  members_per_partition: p50=<N> p95=<N> p99=<N> max=<N>
  rebins_per_partition: p50=<N> p95=<N> p99=<N> max=<N>
```

`histogram_view_highlighted` carries the same fields with
`partition_keying: metric_global` and the two percentile fields appended in the
locked positions:

```
consumer: histogram_view_highlighted
  path: unified
  partition_keying: metric_global
  [... the same fifteen fields ...]
  percentiles_emitted: p1 p5 p10 p25 p50 p75 p90 p95 p99 p999 p9999 p99999
  out_of_range_bounded: p1=none p5=none p10=none p25=none p50=none p75=none p90=none p95=none p99=none p999=none p9999=none p99999=none
```

Every field carries the meaning Decision 8 already locks for it, measured over
the highlight store instead of the parent store. No field is redefined, and no
new field name is introduced.

### Invariants

1. **Attribution.** Each block's figures describe its own store only. The
   parent's `partition_count` and `counter_memory_bytes` do not change when a
   highlight becomes active; the run's total is the reader's sum of the two
   blocks, never a single printed figure.
2. **Display projection.** `rebin_finalize_events == partition_count` on
   `heatmap_cells_highlighted` whenever `path: unified`. On
   `histogram_view_highlighted` the same equality holds when every highlight
   partition carries at least one observation; a metric whose highlight store
   holds none is counted in `partition_count` and never projected (D6).
3. **Percentile fields.** `percentiles_emitted` and `out_of_range_bounded`
   appear on `histogram_view_highlighted` only, and `percentiles_emitted` there
   is the twelve-slug export ladder, which is a longer set than the ten-slug set
   `histogram_view` reports. The difference is deliberate: the parent's set is
   the legend's, the highlight's is the export's.
4. **Presence.** Both blocks are emitted on every run that emits the section,
   regardless of whether a highlight is live.
5. **Retired store.** No consumer name reports `%bucket_stats_counters_hl`,
   which no longer exists (D2), and `-mem` no longer lists a
   `bucket_stats_counters_hl` row.

### Reserved-names entry

`tests/HARNESS-DESIGN.md` § Reserved section names, the `histogram-bin-counters`
entry, gains a clause naming the two highlight consumer blocks and this issue as
their amending issue, in the same commit as the code.

---

## 7. Surfaces touched

**`ltl`**

| Sub | Change |
|---|---|
| `emit_bin_counter_mode_verbose()` | Two entries in `@consumer_order`, `%feature_active` (gated on `$highlight_active` alongside `$heatmap_enabled` / `$histogram_enabled`), `%partition_keying`, `%consumer_opted_out_to_raw`, and one entry in `%percentile_set` for the histogram highlight only. No entry in `%shares_with`: both new consumers own their store. The block loop itself is unchanged. |
| `finalize_heatmap_unified()` | One `snapshot_counter_telemetry(\%heatmap_counters_hl)` call beside the existing parent snapshot, and one `rebin_finalize_events` increment at the highlight `partition_rebin()` site in the loop over `keys %heatmap_counters_hl`. |
| `finalize_histogram_unified()` | The same two additions in the `if ($highlight_active && $src_hl)` branch, with the snapshot taken before the branch so a highlight store that exists but holds nothing is still reported. |
| `read_and_process_logs()` | The `counter_update(\%bucket_stats_counters_hl, …)` call annotated `# store parity only` is deleted (D2). |
| `named_structure_sizes()` | The `bucket_stats_counters_hl => Devel::Size::total_size(...)` line is deleted (D2). |
| `## GLOBALS ##` | `my %bucket_stats_counters_hl;` and its comment are deleted; the comment on `%bucket_stats_counters` is trued up so it no longer describes a parity store. |

`snapshot_counter_telemetry()` is unchanged: it is already generic over its one
`$store` argument.

**Not touched.** `named_structure_sizes()` keeps its `heatmap_counters_hl` and
`histogram_counters_hl` rows, which are correct. No render, no percentile value,
no exported number changes. `docs/usage.md` and `print_help()` need no option
change; the `-V list` description string for `histogram-bin-counters` in the
section registry already reads "per-consumer partition keying" and is left as it
stands, since it describes the block shape rather than enumerating consumers.

**Feature docs, amended in this pass**

- `features/187-histogram-bin-counter-percentiles.md` § Decision 8: a dated
  amendment adding the two consumer-name strings, their block shapes, their
  `path:` resolution, the always-print rule and the appended display order; and
  the § Edge cases row for a present highlight pattern rewritten to describe the
  contracted behaviour instead of the defect.
- `features/bin-counter-accuracy-and-observability.md`: D9's invariant sentence
  corrected (D9-correction), and the open item "The highlight sub-stores are not
  observed" closed with a pointer here.
- `features/460-bin-model-percentile-source.md` § 5: the highlight item closed by
  pointer here.
- `features/426-per-message-statistics-store.md`: open question 6 closed by
  pointer to D2.

**Harness**

`tests/validate-histogram-bin-counters.sh` per D10, and
`tests/HARNESS-DESIGN.md`'s reserved-names entry.

---

## 8. Harness plan

`tests/validate-histogram-bin-counters.sh`, the sole consumer of this section.
Fixture and invocation shape stay as the harness already sets them: the
5,000-line Tomcat access log slice `docs/test-logs.md` names as this harness's
configuration-class fixture, and `-ni -bs 1440 -oe`, which keeps the timeline to
the one bucket the partition assertions need and switches off everything the
assertions do not read.

Four new scenarios:

| Scenario | Invocation adds | Asserts |
|---|---|---|
| `heatmap-cells-bin` | `-hm duration -hmdm bin` | The `heatmap_cells` block: `path: unified`, `partition_keying: time_bucket`, the locked field list in order, and `rebin_finalize_events` equal to `partition_count`. The parent arithmetic the highlight scenario is stated against. |
| `histogram-view-bin` | `-hg duration -hgdm bin` | The `histogram_view` block: the same shape with `partition_keying: metric_global`, the ten-slug `percentiles_emitted`, the audit line, and the same equality. |
| `highlight-blocks-active` | `-hm duration -hmdm bin -hg duration -hgdm bin -hdmin 100` | Both highlight blocks at `path: unified`; on each a positive `partition_count`, a positive `counter_memory_bytes`, and `rebin_finalize_events` equal to `partition_count`; on `histogram_view_highlighted` the twelve-slug `percentiles_emitted` and the `out_of_range_bounded` line; and that the parent blocks' `partition_count` is unchanged from the `heatmap-cells-bin` / `histogram-view-bin` arms, which is what makes the attribution invariant assertable rather than asserted by eye. |
| `highlight-blocks-inactive` | `-hm duration -hmdm bin -hg duration -hgdm bin` (same arm, no highlight flag) | Both highlight blocks present with `path: feature_not_active` and no further field lines. |

The third and fourth scenarios are the two arms of one invocation differing only
in `-hdmin 100`, which is the verification method demonstrated in the
investigation: the same run, the same fixture, one flag, and the telemetry
differing in the contracted way.

Per `tests/HARNESS-DESIGN.md` § Proving a new assertion can fail, each new
assertion is run against a deliberately broken capture first (a block with the
consumer line renamed, a `path:` line flipped, a `rebin_finalize_events` value
edited off the equality) and shown to fail with its `asserts` / `produced_by` /
`contract` triple surfaced, before the healthy path is run.

The harness's runtime-warning check (`tests/lib/runtime-warnings.sh`, already
wired through `check_capture_warnings`) covers every new capture.

---

## Acceptance criteria

Triaged per `docs/test-driven-development.md`. All criteria are **assertable**;
none is unassertable and none is unknown, so no prototyping scope arises from
the triage.

**Assertable**

- [ ] When a heatmap renders under the bin data model with a live highlight, a
      block named `consumer: heatmap_cells_highlighted` reports `path: unified`
      with a `partition_count` of at least 1 and a `counter_memory_bytes` of at
      least 1. *Method: `tests/validate-histogram-bin-counters.sh` scenario
      `highlight-blocks-active`, `assert_line` on each field.*
- [ ] When a histogram renders under the bin data model with a live highlight, a
      block named `consumer: histogram_view_highlighted` reports `path: unified`
      with a `partition_count` of at least 1 and a `counter_memory_bytes` of at
      least 1. *Same scenario.*
- [ ] On two runs of one invocation differing only in the highlight flag, the
      `partition_count` and `counter_memory_bytes` of `heatmap_cells` and
      `histogram_view` are unchanged, and only the highlight blocks differ.
      This is the attribution invariant: the highlight is reported beside the
      parent, never inside it. *Method: the `heatmap-cells-bin` /
      `histogram-view-bin` arms compared against `highlight-blocks-active`.*
- [ ] `heatmap_cells_highlighted` reports `rebin_finalize_events` equal to its
      own `partition_count` on every run where it reports `path: unified`,
      because the highlight loop in `finalize_heatmap_unified()` projects each
      highlight partition exactly once, the same mechanism the parent loop is
      counted by. *Method: `assert_command` comparing the two extracted values
      inside the block.*
- [ ] `histogram_view_highlighted` reports `rebin_finalize_events` equal to its
      own `partition_count` on a run where every highlight partition carries at
      least one observation. *Same method, on a scenario constructed to satisfy
      that condition; the conditionality is stated in the assertion's `asserts`
      field so a later reader does not generalise it.*
- [ ] `histogram_view_highlighted` reports `percentiles_emitted` as the
      twelve-slug ladder the aggregate export's `highlighted:` block publishes,
      and an `out_of_range_bounded` line carrying one `pN=` pair per slug in the
      same order. *Method: exact-line assertion on both lines.*
- [ ] `heatmap_cells_highlighted` reports neither `percentiles_emitted` nor
      `out_of_range_bounded`, mirroring `heatmap_cells`. *Method: an
      `assert_command` that extracts the block's line range and confirms neither
      key appears within it.*
- [ ] On a run with the heatmap and histogram active under the bin data model
      and no highlight flag of any kind, both highlight blocks are present and
      each reports `path: feature_not_active` as its only field. *Method:
      scenario `highlight-blocks-inactive`.*
- [ ] The parent `heatmap_cells` and `histogram_view` blocks report the locked
      Decision 8 field list, in the locked order, with
      `rebin_finalize_events` equal to `partition_count` on each. *Method:
      scenarios `heatmap-cells-bin` and `histogram-view-bin`; this is the
      coverage D9 already claims and the harness does not have.*
- [ ] No `-V` output and no `-mem` output names `bucket_stats_counters_hl`, and
      a run under `-bdm bin` with a live highlight produces the same
      `time_bucket_stats` block as before the retirement. *Method: an
      `assert_command` grepping a `-mem` capture for the absent name, plus the
      existing `bucket-stats-bin` scenario, which asserts that block today and
      must continue to pass unchanged.*
- [ ] Every new capture is free of Perl runtime warnings on stderr. *Method:
      `check_capture_warnings` on each new capture, already the harness's
      pattern.*
- [ ] Each new assertion fails on a deliberately broken capture, with its
      `asserts`, `produced_by` and `contract` fields surfaced. *Method: the
      sabotage probe run at authoring time per `tests/HARNESS-DESIGN.md`
      § Proving a new assertion can fail.*

**Unassertable**

None.

**Unknown**

None. The verification method is known and was demonstrated during the
investigation: two runs of one invocation differing only in the highlight flag,
compared field by field.

---

## Prototype

No prototype is mandatory. Against `prototype/README.md` § When a prototype is
mandatory:

- **(a) new or changed data model** — not triggered. No store, entry shape or
  partition geometry changes. Every field the new snapshots read is already
  populated on the highlight entries by `counter_update()`. D2 removes a store,
  which is a recorded decision rather than a new or changed model.
- **(b) new per-line hot-path cost** — not triggered, and D2 removes one: the
  `counter_update(\%bucket_stats_counters_hl, …)` site evaluated per line on a
  highlighted run under `-bdm bin`. Everything this work adds runs at finalize
  and at emit, once per run.
- **(c) impactful by frequency times cost** — not triggered.
  `snapshot_counter_telemetry()` runs once per store per run and is
  O(partitions); the two new increments are one each per projected partition, at
  sites that already re-bin.
- **(d) unknown verification method** — not triggered. The method is known and
  demonstrated (above), and the triage produced no criterion in the unknown
  state.

One limit on the evidence, stated before rather than after: every figure quoted
in § 4 comes from one 5,000-line fixture at a partition count of 1 or 5. D3's
retention ceiling is a question about many partitions. If the D3 argument is
wanted quantitative rather than directional, one further arm on a larger log of
the same family, at no benchmark tier, would give the fraction of partitions and
payload the highlight represents at a realistic partition count.

---

## Completion gate

Scope per `docs/process/workflow.md` § 3. The diff changes executable lines of
`ltl` (the emitter tables, two finalizers, the deleted streaming site and
declaration) and changes `tests/validate-histogram-bin-counters.sh`. Both rows of
the scope table demand the same thing, so:

- **Full harness suite required.** Every `tests/validate-*.sh` exits 0 with
  assertions actually run, `CI=1 ./tests/validate-csv-output.sh` before
  `CI=1 ./tests/validate-statistics.sh`, then the rest, each captured once to the
  scratchpad and inspected there. The behaviour this change could have altered:
  the `=== histogram-bin-counters ===` section's content on every run, and the
  per-time-bucket bin path on highlighted runs under `-bdm bin` (D2's deleted
  site). `tests/validate-help-content.sh` covers the `--help` and `docs/usage.md`
  agreement, unchanged here.
- **Before/after benchmark required**, `single-day-access-log-standard`, labelled
  `472-before` on the base commit and `472-after` with `$version_number` restored
  to `0.18.1`, compared on this machine in this session.

**What the benchmark is expected to show.** The benchmark case runs no highlight
flag, so D2's deleted per-line site is not evaluated in either arm and the
expected reading is **no measurable change**: within run-to-run noise on every
metric, and nothing worse by more than 5 %. The hot-path reduction D2 buys is
real but sits on a path this case does not take; claiming it from this benchmark
would be claiming a number the instrument cannot see. If it is wanted measured,
the arm is the same case with a numeric highlight bound and `-bdm bin` added to
both sides, which is a separate measurement and not part of this gate.

---

## Release note

One bullet in `releases/v0.18.1.md`, under a verbose-output or observability
heading:

> - The verbose bin-counter section now reports the highlighted subset's own
>   partitions, re-binning and counter payload, beside the figures for the whole
>   population rather than folded into them. Both blocks appear on every run,
>   reporting that the feature is not active when no highlight is live. (#472)

The retired store is internal and observable only as one fewer row in `-mem`'s
per-structure listing, which is a debugging surface; it gets no bullet of its
own and is recorded in D2.

---

## Ordering

**#478 (the highlight decision is re-derived from the -HL category suffix
throughout the read loop instead of kept once at the tag point) should be
blocked by #472.** The interaction runs one way: #478 replaces the same
`$category_bucket =~ /-HL$/` streaming sites that feed these stores with a
boolean kept at the tag point, and D2
deletes one of those sites outright. Doing this issue first leaves #478 one
site fewer to convert and the bin-path harness coverage its criteria rely on;
doing #478 first moves code this issue's fix has to read. Neither carries a native edge today. The edge to record, not run
here:

```bash
BLOCKER_ID=$(gh api repos/{owner}/{repo}/issues/472 --jq '.id')
gh api --method POST repos/{owner}/{repo}/issues/478/dependencies/blocked_by -F issue_id="$BLOCKER_ID"
```

with the agreeing `Blocked by #472 (highlight bin-counter telemetry)` prose line
in #478's body, per `docs/process/issues.md` § Blocking relationships.

**D2's retirement must be noted on #478** in the same action, so that issue does
not plan an activation gate around the `counter_update(\%bucket_stats_counters_hl,
…)` site, which will not exist.

**Against the other open issues touching this surface.** Any issue amending
`features/187-histogram-bin-counter-percentiles.md` § Decision 8 should be
sequenced rather than run in parallel with this one: Decision 8 amendments are
dated in-place edits and two concurrent branches amending it conflict textually.
The same applies to `features/bin-counter-accuracy-and-observability.md` D9 and
to `tests/validate-histogram-bin-counters.sh`.

**Within this issue** the order is: the Decision 8 amendment and the Edge cases
rewrite together, then the D9 correction, then the code, then the harness parent
scenarios, then the harness highlight scenarios.

---

## Open items

- **`consumers_active` and its three siblings** (`--exact-percentiles`,
  `opt_out_active`, `opt_out_notice`): four locked D7/D8 clauses with no emission
  site, recorded together as row V8 of
  `features/426-per-message-statistics-store.md`. Not decided here (D8 above).
  For the architect to dispose of against that row, as one finding rather than
  four.
- **The rest of the heatmap and histogram coverage gap** in
  `tests/validate-histogram-bin-counters.sh`, beyond the parent blocks D10 folds
  in. If it proves larger than the two parent scenarios, it is filed as its own
  issue rather than grown into this one.
