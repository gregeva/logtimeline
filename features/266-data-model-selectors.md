# Issue #266 — Explicit statistical data-model selectors

## Status

Design phase. No code changes yet. Approval gate: this doc must be reviewed and signed off before any implementation begins.

## Problem

`ltl` reduces duration samples into statistics through one of two data models:

- **raw** — every observed duration retained, sorted at calculation time, statistics computed by direct array operations.
- **bin** — HDR-style bin-counter, samples bucketed at capture time into bins-per-decade primitives, statistics derived from bin counts.

The choice is independent per consumer surface. There are four surfaces:

| # | Surface (internal calculation path) | Today's data model | Today's selector |
|---|---|---|---|
| 1 | Histogram statistics (consumed by `-hg`) | bin (raw under `--exact-percentiles`) | `--exact-percentiles` (negative opt-out) |
| 2 | Heatmap statistics (consumed by `-hm`) | bin (raw under `--exact-percentiles`) | `--exact-percentiles` (negative opt-out) |
| 3 | Per-message-key statistics | raw (only path wired) | none |
| 4 | Per-time-bucket statistics | raw (only path wired) | none |

These four surfaces are *internal data-reduction paths*. Each takes captured duration samples and produces a statistics record. Downstream consumers (terminal columns, CSV writers, `-V` sections, histogram/heatmap renderers) read from whatever the surface produced — they are not the surface itself. The data-model selectors target the reduction path, not the renderer.

Two problems block #224:

1. `--exact-percentiles` is a global negative opt-out covering surfaces 1 and 2 only. A test matrix that wants to pin "this scenario measures the bin-counter reduction on the per-message-key statistics path" has no way to say so.
2. Surfaces 3 and 4 have no bin-counter dispatch site at all. A test scenario asking for `bin` on those surfaces today has nowhere for the request to land.

## Design

### Five new CLI flags

All accept `raw|bin`. Short-and-long pair per the project convention.

| Flag (short / long) | Surface | Scope |
|---|---|---|
| `-dm` / `--data-model raw\|bin` | All surfaces (omnibus) | Sets default for every surface unless a per-surface flag overrides |
| `-hgdm` / `--histogram-data-model raw\|bin` | Histogram | Per-surface override |
| `-hmdm` / `--heatmap-data-model raw\|bin` | Heatmap | Per-surface override |
| `-mdm` / `--message-stats-data-model raw\|bin` | Per-message-key statistics | Per-surface override |
| `-bdm` / `--bucket-stats-data-model raw\|bin` | Per-time-bucket statistics | Per-surface override |

### The flags have no defaults

This is the core framing. The five new flags exist to **pin** the data model when the caller needs certainty (test harness, reproducibility, A/B comparison). They do not exist to *participate* in the surface's normal decision-making.

When a flag is unset, it contributes nothing — the surface's existing internal logic chooses the data model exactly as today. The flags are a purely additive override layer.

### Resolution at each call site

For each of the four surfaces, at the point the surface decides which data model to use:

1. If the surface's per-surface flag is set → use its value.
2. Else if `-dm` is set → use its value.
3. Else → the surface's existing internal logic decides, unchanged from today (this includes the existing `--exact-percentiles` consultation for surfaces 1 and 2).

### Validation

`raw` and `bin` are the only accepted values. Any other value (`--data-model dense`, `--message-stats-data-model 7`) causes `ltl` to die at option-parse time with a clear error.

### Conflicting flags

Last one on the command line wins, per Getopt::Long default behavior. No special-case logic. If a user writes `-dm raw -dm bin`, the result is `bin`. If a user writes `--exact-percentiles --data-model bin`, the result on surfaces 1 and 2 is `bin` because the new flag was set and takes the resolution-chain step 1 path; `--exact-percentiles` is only consulted in step 3.

### Two-branch dispatch at every call site

All four surfaces use the same call-site shape after this change:

```
my $dm = resolve_data_model(<surface>);   # 'raw' | 'bin' | undef
if (defined $dm && $dm eq 'bin') {
    # bin-counter path
} else {
    # raw path
}
```

- **Surfaces 1 and 2** already have both paths wired (gated today by `--exact-percentiles`). This change swaps the gate from `$exact_percentiles_optout` to the resolved data-model selector. When the selector is `undef`, the surface's internal logic — including the existing `--exact-percentiles` consultation — runs unchanged, preserving today's behavior exactly.
- **Surfaces 3 and 4** today have only the raw path. This change adds the two-branch dispatch structure as architectural foundation. The selector is resolved at the call site exactly as on surfaces 1 and 2, but the surface always executes the raw path regardless of what the selector resolves to. When the bin-counter reduction for these surfaces is built in a follow-up issue, the `bin` branch starts honoring the selector with no change to the call-site shape. #266 lays the foundation; it does not fill in the bin branch.

### `--exact-percentiles` continues to work

The flag continues to function identically to today on surfaces 1 and 2. It is not removed by this issue and its semantics do not change.

What changes:

- The deprecation warning at `ltl:5884` updates to name the new flags as replacements:

  > `--exact-percentiles` is deprecated; use `--data-model raw` (omnibus) or `--histogram-data-model raw` / `--heatmap-data-model raw` (per-surface) instead. `--exact-percentiles` is equivalent to `--data-model raw` on the histogram and heatmap surfaces, which is what it has always controlled. This flag will be removed in a future release.

- The flag continues to be consulted only inside the surface's internal logic — i.e. only at resolution-chain step 3, when no new flag is set for that surface. If the user passes both `--exact-percentiles` and `-dm bin` (or `-hgdm bin` / `-hmdm bin`), the new flag wins because the new flag is consulted at step 1; `--exact-percentiles` never gets a vote.

This issue does not remove `--exact-percentiles`. Removal is a separate follow-up gated on user migration.

### `-V runtime-config` surfacing

The existing pattern at `ltl:1434–1566` is row-per-configured-flag inside `command-line` and `environment-variable` sub-sections. The sub-section header carries the source; rows carry only `value` or `value; overridden` or `value; clamped from <orig>`. There is no `(--flag-name)` source-trail suffix on individual rows.

The five new flags are added to the `%resolved_values` hash. Per the existing partitioning rule, a flag is emitted **only** if it appears in the command-line or environment-variable provenance. An unset flag emits nothing. This is exactly what we want: the runtime-config section is a record of explicit configuration, not a reconstruction of the surface's decision tree.

Examples:

- User passes nothing → no data-model lines anywhere.
- User passes `-dm raw` → command-line sub-section gains `data-model: raw`.
- User passes `-hgdm bin --data-model raw` → command-line sub-section gains both `data-model: raw` and `histogram-data-model: bin`. No annotation between them — the user can read the precedence from the flag names.

The `exact-percentiles` row already in `%resolved_values` at `ltl:1504` stays in place. When the user passes both `--exact-percentiles` and a new flag that affects the same surface, both rows appear in the command-line sub-section with their plain values. The "which one effectively won" question is answered by the resolution rule, not by an annotation — same as how the existing CLI vs env-var precedence is communicated by sub-section placement, not by row-level source trails.

## Code touch points

| File:line | What changes |
|---|---|
| `ltl:5800–5878` (`GetOptions`) | Add five entries. Use `=s` with a value-validation callback (see "Implementation notes" below). |
| `ltl:5884–5886` (deprecation warning) | Update message to name the new flags. |
| `ltl` (new globals, near other option globals) | Five new scalars holding the parsed `raw`/`bin`/`undef` values. |
| `ltl` (new sub, near other small helpers) | `resolve_data_model($surface)` — returns `'raw'`, `'bin'`, or `undef` per the resolution rule. |
| `ltl:7132, 7148, 7282, 7523` (histogram exact-path gates) | Replace `$exact_percentiles_optout` consultation with `resolve_data_model('histogram')` consultation, falling back to the existing logic when `undef`. |
| `ltl:1856` (histogram consumer exact-path gate) | Same as above. |
| Heatmap dispatch sites (located alongside histogram sites) | Same pattern with `resolve_data_model('heatmap')`. |
| `ltl:8248` (`calculate_statistics`) | Add two-branch dispatch shell at the top. `resolve_data_model('message-stats')` is called and its value is available, but the surface always proceeds down the raw path today. The `bin` branch is a stub left for the follow-up issue. |
| Per-time-bucket statistics sub (sibling of `calculate_statistics`) | Same as above with `resolve_data_model('bucket-stats')`. Locate by tracing the per-time-bucket reduction in `calculate_all_statistics`. |
| `ltl:1456–1506` (`%resolved_values` in `emit_runtime_config_verbose`) | Add five rows. |
| `print_help()` | Document the five new flags in the appropriate section. |
| `docs/usage.md` | Document the five new flags. |
| `README.md` | Mention in the options reference. |
| `CLAUDE.md` | No change unless a release-process or helper-tools surface mentions `--exact-percentiles`; sweep to confirm. |
| `releases/v0.14.6.md` | Add one bullet per the bullets-only rule. |

## Implementation notes

### Validating `raw|bin` at option-parse time

Getopt::Long does not have native enum validation. Idiomatic pattern (used elsewhere in ltl for similar checks, e.g. `duration-unit`):

```
'data-model|dm=s'                    => sub { _validate_dm('data-model',                 $_[1]); $data_model_omnibus    = $_[1]; },
'histogram-data-model|hgdm=s'        => sub { _validate_dm('histogram-data-model',      $_[1]); $data_model_histogram   = $_[1]; },
'heatmap-data-model|hmdm=s'          => sub { _validate_dm('heatmap-data-model',        $_[1]); $data_model_heatmap     = $_[1]; },
'message-stats-data-model|mdm=s'     => sub { _validate_dm('message-stats-data-model',  $_[1]); $data_model_message     = $_[1]; },
'bucket-stats-data-model|bdm=s'      => sub { _validate_dm('bucket-stats-data-model',   $_[1]); $data_model_bucket      = $_[1]; },
```

`_validate_dm($flag_name, $value)` dies with: `--$flag_name: '$value' is not a valid data model; valid values are 'raw' and 'bin'`.

### `resolve_data_model($surface)` shape

```
sub resolve_data_model {
    my ($surface) = @_;
    my $per_surface = {
        histogram     => $data_model_histogram,
        heatmap       => $data_model_heatmap,
        'message-stats' => $data_model_message,
        'bucket-stats'  => $data_model_bucket,
    }->{$surface};
    return $per_surface if defined $per_surface;
    return $data_model_omnibus if defined $data_model_omnibus;
    return undef;
}
```

Returns `undef` deliberately so callers can distinguish "user pinned raw" from "user said nothing." The two cases need different code paths because the second one preserves the existing internal logic including `--exact-percentiles`.

### Short forms

All five flags have explicit short forms per the project convention (`feedback_short_forms_required`):
- `-dm`, `-hgdm`, `-hmdm`, `-mdm`, `-bdm`.

## Test plan

1. **Regression** — `tests/validate-regression.sh` passes with no changes.
2. **CSV structure** — `tests/validate-csv-output.sh` passes for every combination of the five flags.
3. **Byte-identity at defaults** — Run `ltl -o` on a small Tomcat log and a ThingWorx log without any new flag; output (CSV files used as a convenient observable surface for the per-message-key and per-time-bucket statistics paths) is byte-identical to a baseline captured from `release/0.14.6` before this change.
4. **Per-surface override** — Run with `-hgdm raw` against a known histogram-mode input; output matches an `--exact-percentiles -hg` invocation on the same input from before this change.
5. **Omnibus override** — Run with `-dm raw -hg`; same expected result as test 4.
6. **Surface 3 selector accepted but not honored** — Run with `-mdm bin -o`; ltl exits 0, and the per-message-key statistics (observed via CSV and terminal columns) are byte-identical to the no-flag baseline (raw path executed regardless of the selector).
7. **Surface 4 selector accepted but not honored** — Same with `-bdm bin -o`, observed via the per-time-bucket statistics in CSV.
8. **Invalid value** — Run with `--data-model dense`; ltl exits non-zero with the validation error message.
9. **Conflicting last-wins** — Run with `-dm raw -dm bin -hg`; histogram output matches a `-hg` invocation without any new flag (because no new flag survives → step 3 → existing internal logic → bin per histogram's baked-in default).
10. **`-V runtime-config` rows** — Run with `-V runtime-config -dm raw -hgdm bin`; output contains `data-model: raw` and `histogram-data-model: bin` in the command-line sub-section; no `(--…)` annotations on either row.
11. **Deprecation warning text** — Run with `--exact-percentiles`; STDERR contains the updated warning naming the new flags.

## Acceptance criteria mapping (issue body → this doc)

| Issue criterion | Where addressed |
|---|---|
| All five flags accept `raw`/`bin`, reject other values | Validation section, Implementation notes / `_validate_dm` |
| Per-surface flags override `-dm`; `-dm` overrides baked-in | Resolution section + `resolve_data_model` |
| All five flags in `print_help()` and `docs/usage.md` | Code touch points |
| Histogram/heatmap identical at `-hgdm bin` / `-hmdm bin` to today's non-`--exact-percentiles` | Two-branch dispatch section + tests 3, 4, 5 |
| Histogram/heatmap identical at `-hgdm raw` / `-hmdm raw` to today's `--exact-percentiles` | Two-branch dispatch + tests 4, 5 |
| Bin path implemented for per-message-key and per-time-bucket statistics | **Reframed**: #266 puts the dispatch foundation in place; surfaces 3 and 4 always run raw today regardless of selector. The bin reduction lands in a follow-up. |
| Per-message-key / per-time-bucket statistics byte-identical at defaults | Test 3 |
| `-V runtime-config` emits source-annotated lines per flag | `-V runtime-config` surfacing section + test 10 |
| Deprecation notice on `--exact-percentiles` names new flags | Deprecation section + test 11 |
| `tests/validate-regression.sh` passes | Test 1 |
| `tests/validate-csv-output.sh` passes for every data-model combination | Test 2 |
| Docs sweep references new flags | Code touch points |
| Release notes bullet added | Code touch points |

### Note on the surfaces 3/4 acceptance criterion

The issue body's criterion "MESSAGES CSV and STATS CSV statistics emit when `-mdm bin` / `-bdm bin` is selected" is reframed here: #266 puts the dispatch foundation in place but does not implement the bin-counter reduction for these surfaces. The issue body should be amended to reflect this split, with a follow-up issue tracking the actual reduction implementation.

## Out of scope

- Removing `--exact-percentiles` (per issue body).
- Changing default data-model selection on any surface (per issue body).
- Changes to bin-counter precision `-pbpd` (per issue body).
- Anything in #224 itself (per issue body).
- Implementing the bin-counter reduction for surfaces 3 and 4 — foundation only; reduction lands in a follow-up.

## Related

- `features/187-histogram-bin-counter-percentiles.md`
- `features/189-bin-counter-primitives-implementation-readiness-audit.md`
- `features/224-statistics-drift-harness.md`
- Issue #231 — current deprecation warning and `-V runtime-config` source-annotation pattern.
