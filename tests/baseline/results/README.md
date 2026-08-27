# Benchmark baselines

## What is in here

| kind | naming | what it is |
|---|---|---|
| Release baseline | `vX.Y.Z.tsv`, `vX.Y.Z-release.tsv` | Captured at a release cut from the `all` tier (every file selection including XL). The performance record for that release. |
| Development reference | `dev-reference-*.tsv` | **Not a release baseline.** Captured mid-cycle so in-flight work has a valid comparator. Never cited as a release figure. |
| Hardware control | `hwcontrol-*.tsv` | A named prior version's code re-run on current hardware, to separate a machine change from a code change. |
| Comparison report | `comparison-<from>-vs-<to>.md` | Saved output of `compare-results.sh --save`. |

## The 2026-08-27 hardware discontinuity — read before comparing across it

The development machine moved to a **virtualized host with abstracted virtual IO
drivers**. Every baseline captured before that date is on different hardware from
every baseline captured after it, and the two are not comparable.

This was separated into its two causes by re-running the **v0.17.0 code itself** on
the new hardware (`hwcontrol-v0170-on-virtualized.tsv`), so the machine is the only
variable:

**A — hardware, same code** (`v0.17.0-release` → `hwcontrol-v0170-on-virtualized`):

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
percentages are quantization rather than signal. Memory is unaffected — `rss_peak`
is 2.2 % *lower* with 0 of 45 cases worse, which is what confirms this is execution
speed and not a behaviour change.

**B — code, same machine** (`hwcontrol-v0170-on-virtualized` →
`dev-reference-virtualized-2026-08-27`, i.e. what v0.18.0's work so far did):

| stage | change | cases worse/better |
|---|---|---|
| `total` | **−2.6 %** | 9 / 36 |
| `parse/read_files` | −2.6 % | 11 / 34 |
| `finalize/group_similar` | −3.4 % | 0 / 10 |
| `finalize/calculate_statistics` | −2.2 % | 4 / 31 |

The 0.18.0 bin-counter drop is a net improvement, so no code regression is baked
into the development reference.

## Which file to compare against

- **Gating in-flight 0.18.0 work:** `dev-reference-virtualized-2026-08-27.tsv`
  (`full` tier, 45 cases, current code, current hardware).
- **Judging what the hardware did:** the A/B pair above.
- **`v0.17.0-release.tsv`:** the last release record on the previous hardware. Still
  the correct release-to-release comparator *for that hardware*; comparing current
  work against it reports the machine, not the change.

The XL selections were deliberately not run for the development reference: they are a
release-gate instrument, not a development one, and cost hours. A release cut still
needs the `all` tier — and on this hardware it has no same-hardware predecessor, so
the v0.18.0 release comparison needs deciding rather than assuming.

## Known gap

**No baseline records the machine that produced it.** The TSV carries version, files,
line counts, timings and memory — no host, CPU, or storage. So a hardware change is
invisible in the artifacts, the eleven baselines here cannot say which machine they
describe, and `compare-results.sh` will silently report a hardware difference as a
code regression. That is what happened on 2026-08-27, and it cost an investigation to
establish. Recording provenance, and having `compare-results.sh` refuse or flag a
cross-hardware comparison, is unfiled tooling work.
