# Benchmark baselines

## What is in here

| kind | naming | what it is |
|---|---|---|
| Release baseline | `vX.Y.Z.tsv`, `vX.Y.Z-release.tsv` | Captured at a release cut from the `all` tier. The performance record for that release. |
| Development reference | `dev-virtualized-*.tsv` | **Not release baselines.** Captured mid-cycle on the virtualized development host so in-flight work has a valid comparator. Never cited as release figures. |
| Comparison report | `comparison-<from>-vs-<to>.md` | Saved output of `compare-results.sh --save`. |

## The development reference pair

Stage 4 of the 0.18.0 bin-counter drop changes the merge arithmetic and the
percentile source. Attributing what that does needs **two** references on this host —
one for the code before the drop, one for the code as it stands with stages 1–3
merged. Both are `full` tier, 45 cases, captured 2026-08-27 back to back:

| file | code | `ltl` sha256 (first 16) |
|---|---|---|
| `dev-virtualized-v0.17.0-code.tsv` | tag `v0.17.0` | `0f15e6c6ecf3dff3` |
| `dev-virtualized-v0.18.0-pre-stage4.tsv` | `084c2ed` (merged as `48d446b`), stages 1–3 | `f799f6ad414c84bf` |

Both were captured before `release/0.18.0` was version-stamped to `0.18.0`, so both
report `version 0.17.0` and the pre-stage4 file's `ltl` differs from the current
branch tip by that one line. Captures taken from here on identify themselves.

**Gate stage 4 against `dev-virtualized-v0.18.0-pre-stage4.tsv`** — it is the
immediate predecessor, so a difference is the change. The v0.17.0-code file is what
separates a machine effect from a code effect, and is why the numbers below can be
attributed at all.

## The 2026-08-27 hardware discontinuity

The development host moved to a **virtualized machine with abstracted virtual IO
drivers**. Baselines captured before that date are on different hardware from those
captured after, and are not comparable across it.

Separated into its two causes by re-running the **v0.17.0 code itself** on the new
host, so the machine is the only variable:

**A — hardware, same code** (`v0.17.0-release` → `dev-virtualized-v0.17.0-code`):

| stage | change | cases worse/better |
|---|---|---|
| `total` | **+8.9 %** | 42 / 3 |
| `parse/read_files` | +8.2 % | 41 / 4 |
| `finalize/group_similar` | +15.7 % | 10 / 0 |
| `finalize/calculate_statistics` | +14.9 % | 32 / 3 |
| `…/sort_selection` | +19.4 % | 25 / 1 |

The slowdown is **not confined to I/O**. In-memory stages moved 11–19 %, more than
the read path did. An initial single-case reading suggested otherwise; it was taken
on a read-dominated selection whose in-memory stages are sub-200 ms, where the
percentages are quantization rather than signal. Memory is unaffected — `rss_peak` is
2.2 % *lower* with 0 of 45 cases worse, which is what confirms this is execution speed
and not a behaviour change.

**B — code, same machine** (`dev-virtualized-v0.17.0-code` →
`dev-virtualized-v0.18.0-pre-stage4`, i.e. what the drop's stages 1–3 did):

| stage | change | cases worse/better |
|---|---|---|
| `total` | **−2.6 %** | 9 / 36 |
| `parse/read_files` | −2.6 % | 11 / 34 |
| `finalize/group_similar` | −3.4 % | 0 / 10 |
| `finalize/calculate_statistics` | −2.2 % | 4 / 31 |

Stages 1–3 are a net improvement, so no code regression is baked into the reference
stage 4 will be measured against.

## `v0.17.0-release.tsv`

The last release record, on the previous hardware. Comparing current work against it
reports the machine rather than the change. It stays as that release's record.

## Scope of the development references

`full` tier only — the XL selections are a release-gate instrument, not a development
one, and cost hours. Release benchmarking is not done on this host.

## Known gap

**No baseline records the machine that produced it.** The TSV carries version, files,
line counts, timings and memory — no host, CPU, or storage. So a hardware
change is invisible in the artifacts, the committed baselines cannot say which
machine they describe, and `compare-results.sh` silently reports a hardware
difference as a code regression. That is what happened on 2026-08-27 and it cost an
investigation to establish. Recording provenance, and having `compare-results.sh`
refuse or flag a cross-hardware comparison, is unfiled tooling work.
