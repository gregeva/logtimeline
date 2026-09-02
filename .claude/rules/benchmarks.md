---
paths:
  - "tests/baseline/**"
  - "tests/profile/**"
  - "tests/analysis/**"
---
# Benchmark and analysis tooling

- Result TSVs, comparison reports and analysis records are deliverables. They
  are never overwritten for a test or a debug run; use a separate `--label` or
  a scratch copy.
- Per-feature performance is before/after on this machine: the `before` run is
  captured on the base commit before the first change, and compared to the
  finished change with `compare-results.sh summary`. A released `vX.Y.Z.tsv`
  was captured on another machine and proves nothing about a change.
- `run-benchmark.sh full|xl|all` and the XL file selections are release
  instruments and never run during issue work.
- A claim about what `compare-results.sh` reports is read from its output,
  never derived by comparing its input TSVs.
- A filter change is scoped by the dimension that produces the symptom: a test
  case missing from one run is noise, a metric present on one side only is news.
- Changes here touch nothing that asserts against `ltl`; the completion gate is
  skipped and the skip recorded in the completion comment.
