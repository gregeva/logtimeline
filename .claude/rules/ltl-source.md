---
paths:
  - "ltl"
---
# Editing ltl

- Grep for the domain nouns before writing any parsing, resolution, matching or
  formatting logic; call the existing sub. A new `elsif` ladder restating names,
  units or aliases defined elsewhere is a defect, and near-duplicates found on
  the way are converged in the same change.
- Every accumulator carries an observation count; derived output is gated on
  `count > 0`, never on `defined` over a zero-initialised field.
- Comments describe the current state. No "renamed from", "used to be", issue
  narratives or change history; git holds that.
- A new option has a short form and a long form, a `print_help()` row and a
  `docs/usage.md` row in the same commit (`tests/validate-help-content.sh`
  enforces parity). A description never restates the row indicator.
- Behavioural notices (auto-disable, fallback, limit hit) always print;
  `--disable-progress` suppresses progress indicators only.
- Adding or changing a `-V` section or key: read `tests/HARNESS-DESIGN.md`
  first, find every consumer with `grep -r "=== name ===" tests/`, update the
  owning feature doc's section contract, and execute each affected harness.
- Log formats are changed through their spec in `format_registry_specs()`
  (pattern, field map, transforms, time contract, samples, classification),
  never through hot-loop code. Record: `features/log-format-registry.md`.
- Anything executed per line, or per key at high cardinality, is a hot-path
  change: the before benchmark is captured on the base commit first, and a new
  data model or per-line cost is prototyped (`prototype/README.md`).
- `$version_number` reads `X.Y.Z-{issue}` on a feature branch and is restored
  to `X.Y.Z` before the completion gate.
- A locked decision (Dxx in the owning feature doc) is not overridable here.
  A problem found mid-implementation is brought to the architect with
  candidate designs.
