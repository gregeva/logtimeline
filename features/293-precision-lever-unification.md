# Issue #293 — Unify the precision lever

Rename `--percentile-precision` → `--data-model-precision` (tiered 1..9, default 5),
make it the single resolution knob, derive each bin-counter surface's bins-per-decade
from the tier, and remove the raw bpd flags (`-pbpd`, `-bsbpd`).

This reopens #187 Decision 2 (the locked precision-lever contract) and must be re-locked
there.

## Scope and sequencing

Both phases land in this ticket, on branch `293-unify-precision-lever`, as two commits.
The flag removal is not deferred — it happens here.

**Commit 1 — the single lever.** Rename `--percentile-precision` → `--data-model-precision`
(short form `-dmp`), tiered 1..9, default 5. The tier resolves a **per-surface** bpd via
the table below — each surface reads its own row, not one shared bpd. All four bin-counter
surfaces derive their resolution from this one lever.

**Commit 2 — remove the redundant knobs.** Delete `-pbpd` / `--percentile-buckets-per-decade`
and `-bsbpd` / `--bucket-stats-buckets-per-decade` outright. Resolve the data-model-selector
(`-hgdm`/`-hmdm`/`-mdm`/`-bdm`/`-dm`) vs. precision categorization so their relationship is
clear: the selectors choose *which* data model a surface uses (raw vs. bin); the precision
lever sets *how finely* the bin model resolves. There is no precedence/conflict logic between
the lever and the removed flags — the flags simply no longer exist.

## Precision-tier → bins-per-decade (source of truth)

| Surface | **1** | **2** | **3** | **4** | **5** *(default)* | **6** | **7** | **8** | **9** |
|---|--:|--:|--:|--:|--:|--:|--:|--:|--:|
| **Histogram** | 53 | 80 | 115 | 256 | **616** | 616 | 616 | 616 | 616 |
| **Heatmap** | 53 | 80 | 115 | 256 | **616** | 616 | 616 | 616 | 616 |
| **Bucket-stats** | 16 | 32 | 53 | 53 | **53** | 115 | 616 | 616 | 616 |
| **Per-message** | 4 | 8 | 16 | 32 | **53** | 80 | 115 | 256 | 616 |

### Intent encoded in the curves

- **Tier 5 is the default and reproduces today's per-message and bucket-stats behavior**
  (both 53 bpd). A user who never touches the lever sees no change on those surfaces.
- **Above tier 5, bucket-stats climbs faster than per-message and reaches 616 earlier**
  (tier 7 vs tier 9). This lets one lever serve the SRE case "sharp per-time-bucket
  percentiles, coarser per-message" without a second flag:
  - tier 7 → bucket-stats 616, per-message 115
  - tier 8 → bucket-stats 616, per-message 256
  - tier 9 → both 616
  Tiers 8–9 tune per-message only (bucket-stats already maxed at 7).
- **Per-message is the slow climber** — it is the highest-cardinality surface (one
  partition per log key, 10⁵+), so bpd multiplies its memory hardest. It only reaches
  616 at tier 9, the explicit "I accept the memory" setting.
- **Bucket-stats steps 53 → 115 → 616** (it does not stop at 256).

### Open points flagged against the current code

- **Histogram and heatmap are pinned at 616 today** (`$histogram_stream_bpd`,
  `$heatmap_stream_bpd`) with no exposed lever. The table above lets the lever *coarsen*
  them below tier 5 (53/80/115/256) — a **new behavior**, not a codification of current
  behavior.

## Observability (verbose `-V` output)

The `-V percentile-algorithm` section is the trace surface for this feature. It must let a
human (and the #224 L3 oracle) confirm that the table was applied: which tier is active,
where it came from, and the bpd each surface resolved to.

- **Tier line.** Rename the existing `-V` content key `percentile_precision:` →
  `data_model_precision:`, emitted as `data_model_precision: <tier> (<source>)`. The
  `<source>` annotation drops all `-pbpd` / `--percentile-precision` vocabulary (those flags
  are gone); it is `default` or `--data-model-precision N`.
  - This is a **`-V` content-key rename → breaking change.** It triggers the HARNESS-DESIGN
    consultation: discover every consumer (`grep -rn 'percentile_precision' tests/`), update
    them in the **same commit**, and execute each affected harness to confirm it still
    asserts (exit 0 is insufficient — the assertion lines must match).
- **Per-surface bpd.** Keep the existing per-surface `effective_bpd: N` line in each surface
  block, now **derived from the active tier via the table** rather than read from a
  per-surface global. The tier line plus the four `effective_bpd` lines together prove the
  resolution end-to-end (e.g. tier 7 → histogram 616, heatmap 616, bucket-stats 616,
  per-message 115). The L3 oracle continues to read `effective_bpd` per surface.

## Test-harness integration

Every named consumer of the renamed `-V` key and the removed flags is updated in the same
commit as the change that affects it. Per HARNESS-DESIGN, a grep that matches nothing is a
failure, and exit 0 is not proof — each touched harness is executed and confirmed to assert.

- **`validate-runtime-config.sh`**
  - Rewrite the precision assertion (today `^percentile-precision: 7$`) for the new key
    name (`^data_model_precision: 7 ...$`) and the new source vocabulary.
  - **Delete** the `warning-pbpd-overrides-pp` scenario — the `-pbpd` vs `--percentile-precision`
    conflict it tests no longer exists.
  - **Add table-assertion scenarios:** run `-dmp` at representative tiers and assert each
    surface's `effective_bpd` matches the table cell. The table becomes a tested contract,
    not just a doc — derivation regressions are caught.
- **`validate-histogram-bin-counters.sh`** — asserts the bin-counter `-V` telemetry,
  including the bpd-bearing lines; update for the renamed key / derived bpd.
- **`validate-statistics.sh`** — the L3 oracle reads `effective_bpd` from `-V`; confirm it
  still resolves the correct per-surface bpd after derivation moves to the table.
- **`validate-help-content.sh` / `validate-help-layout.sh`** — assert visible long-form flags
  appear in `docs/usage.md` / `README.md`; update for the renamed flag and the two removed
  flags (the harness halts at the first missing long-form — re-run after removal to confirm
  no further gaps hide behind it).
- **`validate-explain.sh`** — `--explain` prose references `-pbpd` / `-pp`; update to the new
  lever and remove references to the deleted flags.

## Documentation (one sweep, same commit as the change)

Light and to the point. The message every user-facing surface lands, in analyst terms:
there is **one lever** (`--data-model-precision`, 1..9, default 5) for dialing in precision;
turning it up **increases precision in stages across the surfaces** (not all at once); the
trade-off is **precision vs. memory**, and the staging lets the analyst buy precision where
it matters at a controlled memory cost.

Per the user-facing-docs rule: describe what the analyst gets, never the mechanism. No
bins-per-decade numbers as the headline, no internal identifiers, no issue numbers, no
per-surface table dumped into `--help`. Stay silent on backward-compat — describe the knob
as it is now, with no reference to the removed flags.

- **`print_help()` (`-dmp`):** one terse line — precision tier 1..9 (default 5), higher =
  finer resolution at higher memory cost.
- **`docs/usage.md`:** a short paragraph carrying the single-lever + staging + memory
  trade-off message, **plus one sentence naming the staging order** across surfaces
  (which surfaces sharpen first as the tier rises, through to the per-message surface at the
  top) — without bpd numbers and without the tier table.
- **`README.md`:** options-reference entry updated for the renamed flag; the two removed
  flags deleted.
- **`--explain` prose** (`$explain_percentiles_compute`, `$explain_iqr_compute`): update the
  existing sentences that name `-pbpd` / `--percentile-precision` to point at the one lever
  and convey that the bin-counter surfaces resolve at the precision the tier sets. Do not
  grow the topics — edit what is already there.

All of the above plus any remaining `-pbpd`/`-pp`/`-bsbpd` mention are swept in the same
commit as the change that affects them.
