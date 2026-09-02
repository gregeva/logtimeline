# Performance baselining

`run-benchmark.sh` captures timing and memory for a set of file selections × scenarios
into a TSV; `compare-results.sh` reports one TSV against another. A captured TSV is a
**baseline**: the reference a later capture is judged against.

```bash
./tests/baseline/run-benchmark.sh <tier|selection> --label <name>
./tests/baseline/compare-results.sh summary <baseline.tsv> <current.tsv>
./tests/baseline/compare-results.sh --save  <baseline.tsv> <current.tsv>   # writes comparison-<a>-vs-<b>.md
```

| tier | what it runs | when |
|---|---|---|
| `quick` | one test | smoke |
| `full` | the five standard file selections × all scenarios (55 tests) | development |
| `xl` | the two extra-large selections (1.5 GB and 7.6 GB) × all scenarios | release |
| `all` | everything (77 tests) | release |

A single selection can be named directly — `run-benchmark.sh single-day-access-log-standard`
— which is what the per-feature completion gate uses.

## Same-machine comparability

**A benchmark comparison is only meaningful when both sides were captured on the same
machine.** Timing is a property of the code *and* the host it ran on, and the TSV
records only the code. This is the single most important thing to understand about
these numbers.

It follows that the two uses of this tooling have different requirements:

- **Release benchmarking is executed rigorously, on consistent hardware**, so that the
  release-to-release record is a like-for-like performance history. It is not run on
  whatever machine happens to be free. If a release comparison shows an unexplained
  regression, **the first thing to check is whether it was captured on the appropriate
  hardware** — a host difference reads exactly like a code regression, and is the more
  likely explanation of the two.
- **Development benchmarking needs only same-machine comparability.** The question a
  developer is asking is "did my change cost anything", and that is answered by
  comparing against a reference captured on the machine doing the work. The absolute
  numbers do not need to match the release history, and should not be quoted as if
  they did.

**The technique that satisfies the development case** — and the one in use here — is to
capture a reference on the current host and compare within it:

1. Capture a `full`-tier reference from the current code on the current machine, named
   `dev-virtualized-*` so it cannot be mistaken for a release baseline.
2. Gate in-flight work against that reference. A difference is then the change.
3. When the host changes, re-establish the reference. Where the size of the host effect
   itself matters, re-run a **known prior version's code** on the new host: with the
   code held constant the machine is the only variable, which separates a host effect
   from a code effect cleanly.

Development references are working artifacts of a cycle. They are committed so the
comparisons are reproducible and auditable, and they are never cited as release
figures.

## Results naming

| kind | naming | what it is |
|---|---|---|
| Release baseline | `vX.Y.Z.tsv`, `vX.Y.Z-release.tsv` | Captured at a release cut from the `all` tier, on release hardware. The performance record for that release. |
| Development reference | `dev-<host-class>-*.tsv` | A working reference for a development cycle. Not a release baseline. |
| Comparison report | `comparison-<from>-vs-<to>.md` | Saved output of `compare-results.sh --save`. |

Since `$version_number` is stamped at branch creation (`docs/process/workflow.md` § Version stamping),
a TSV's `version` row identifies the code that produced it, and the filename records the
host class and the point in the cycle.

## Current development references

The 0.18.0 bin-counter drop. Stage 4 changes the merge arithmetic, so attributing what
it does needs two references on this host — one for the code before the drop, one for
the code as it stands with stages 1–3 merged. Both are `full` tier, 45 cases, captured
2026-08-27 back to back:

| file | code | `ltl` sha256 (first 16) |
|---|---|---|
| `dev-virtualized-v0.17.0-code.tsv` | tag `v0.17.0` | `0f15e6c6ecf3dff3` |
| `dev-virtualized-v0.18.0-pre-stage4.tsv` | `084c2ed` (merged as `48d446b`), stages 1–3 | `f799f6ad414c84bf` |

**Gate stage 4 against `dev-virtualized-v0.18.0-pre-stage4.tsv`** — it is the immediate
predecessor, so a difference is the change.

Each file's `version` row states the code it holds, which is why the v0.17.0-code file
reads `0.17.0` and its sibling reads `0.18.0`. They are not meant to match; the version
describes the build, not the cycle the file belongs to.

The XL selections were not run for these: they are a release instrument, and release
benchmarking is not done on this host.

## Worked example — the 2026-08-27 host change

The development host moved to a virtualized machine with abstracted virtual IO drivers.
This is what step 3 above looks like in practice, and is a useful calibration of how
large a host effect can be.

Re-running the **v0.17.0 code itself** on the new host holds the code constant, so the
machine is the only variable:

**A — host effect, same code** (`v0.17.0-release` → `dev-virtualized-v0.17.0-code`):

| stage | change | cases worse/better |
|---|---|---|
| `total` | **+8.9 %** | 42 / 3 |
| `parse/read_files` | +8.2 % | 41 / 4 |
| `finalize/group_similar` | +15.7 % | 10 / 0 |
| `finalize/calculate_statistics` | +14.9 % | 32 / 3 |
| `…/sort_selection` | +19.4 % | 25 / 1 |

Worth noting because it is counter-intuitive: the effect is **not confined to I/O**.
In-memory stages moved 11–19 %, more than the read path. A single-case reading suggested
otherwise and was misleading — it was taken on a read-dominated selection whose
in-memory stages are sub-200 ms, where the percentages are quantization rather than
signal. Memory is unaffected: `rss_peak` is 2.2 % *lower* with 0 of 45 cases worse,
which is what confirms a host effect rather than a behaviour change.

**B — code effect, same host** (`dev-virtualized-v0.17.0-code` →
`dev-virtualized-v0.18.0-pre-stage4`):

| stage | change | cases worse/better |
|---|---|---|
| `total` | **−2.6 %** | 9 / 36 |
| `parse/read_files` | −2.6 % | 11 / 34 |
| `finalize/group_similar` | −3.4 % | 0 / 10 |
| `finalize/calculate_statistics` | −2.2 % | 4 / 31 |

An 8.9 % apparent regression and a 2.6 % real improvement, in the same pair of files.
That is the whole argument for same-machine comparability in one table.

`v0.17.0-release.tsv` remains that release's record on its own hardware. Comparing
current work against it reports the host, not the change.
