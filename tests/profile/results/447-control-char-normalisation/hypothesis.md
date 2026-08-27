# Hypothesis — #447 control-character normalisation, hot-loop cost

Written before profiling, per features/nytprof-profiling-workflow.md § Pre-Profiling Checklist.

## What changed

One normalisation of `$message` on the ingest path in `read_and_process_logs()`,
at the point every ingest path has finished writing it. It runs **once per
matched line**, so on a 1.43M-line access log it runs 1.43M times.

## What was measured before this profile

| Arm | Median | Delta vs baseline | Per line |
|---|---|---|---|
| baseline (no normalisation) | 16.473 s | — | — |
| sub call, unguarded | 17.192 s | **+4.36%** | +503 ns |
| inline, guarded on `tr` count | 16.739 s | +0.44% | +51 ns |

5 alternating runs per arm, medians, `-bs 1440 -oe -n 5` on
`localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt` (1,430,678 lines).
The sub-call arm was positive in 5/5 pairs; the guarded arm in 3/5, which is at
the noise floor.

## Hypothesis

1. **The sub call, not the string work, was the dominant cost.** A Perl sub call
   with argument passing, a lexical copy and a return-value copy costs more than
   the two rewrites it wraps. Micro-benchmark support: inlining alone took the
   shape from 3,050/s to 6,614/s (+117%).

2. **The guard removes almost all remaining cost, because almost no line has a
   control character.** `tr/\x00-\x1f\x7f//` in counting mode is a single
   character-class scan with no modification and no copy. On an access log the
   expected hit rate is ~0%, so the common case pays one scan and skips both
   rewrites. Micro-benchmark support: guarded-inline 9,539/s vs unguarded-inline
   6,614/s (+44%).

3. **Therefore the residual +0.44% is the guard scan itself**, ~51 ns/line, and
   is irreducible without giving up the invariant — any correct implementation
   must at minimum look at every message once to know whether it is clean.

## What the profile should show

- No `normalize_message_text` entry at all (the sub was removed; the work is
  inline in `read_and_process_logs`).
- `read_and_process_logs` remains the dominant exclusive-time sub, as it was
  before this change; its share should be indistinguishable from baseline.
- No new sub appearing in the top entries attributable to #447.

## What would falsify it

- A measurable line-level cost inside `read_and_process_logs` attributable to
  the `tr` guard beyond the ~51 ns/line measured end-to-end.
- The guard failing to short-circuit (i.e. the rewrites running on clean lines),
  which would show as `s///` and `tr///d` time on an input with no control
  characters.
