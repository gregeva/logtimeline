# Issue #358 — read_files ~2x regression: access-log format-cascade ordering

Investigation findings (2026-07-13). Scope of this document: root cause, attribution,
and measured evidence. No fix is implemented yet; candidate fix directions are listed
at the end with their constraints.

## Verdict

The entire ~2x `read_files` regression on `release/0.16.0` is caused by the format-
detection cascade reordering shipped in issue #345 (no latency surfaces for access logs
without durations), commit `61d0669`, merged at `76042be` (PR #351). No other change in
`v0.15.1..7c36e73` contributes measurably.

The end-anchored common-access-log pattern (match_type 4, no duration field) was moved
*ahead* of the broad with-duration pattern (match_type 3) so that duration-less lines
classify truthfully (before #345 the anchored branch was unreachable dead code — the
broad pattern's all-optional tail fields also matched duration-less lines). The cost:
on inputs where lines *do* carry a duration — the dominant real-world case and 100% of
the benchmark corpus — the anchored pattern now runs and **fails on every line**, and
its failure is expensive due to backtracking.

## Failure mechanism

Pattern that fails per line:

```perl
/^(.+? ){3}[\[]([^\]]+)[\]] "([^"]+)" (\d{3}) (\d+|-)$/
```

On a line with a trailing duration (`... 200 5520 25`), the engine matches up through
`(\d+|-)`, then the `$` anchor fails because ` 25` remains. It then backtracks through
every alternative partition of `(.+? ){3}` (each `.+?` can expand across the line) and
every shorter match of `(\d+|-)` before the overall attempt is abandoned. Measured cost
of the failing attempt: **~10.3 µs/line**, versus ~1 µs/line for the succeeding broad
match — an ~11x overhead paid on every access-log line before the real match runs.

## Attribution evidence

Probe: single 57 MB file `logs/AccessLogs/really-big/localhost_access_log-twx01-twx-
thingworx-1.2026-01-05.txt` (276,209 lines, all with durations), options
`-V benchmark-data --disable-progress --terminal-width 200 -bs 1440`, same machine,
back-to-back runs. Ratio verified to match the issue's 28-file/1.5 GB evidence (~1.8x).

### Bisect over first-parent merges of `v0.15.1..7c36e73` (TIMING read_files, seconds)

| commit | what it is | read_files |
|---|---|---|
| v0.15.1 | last release | 3.61 |
| `5dbcc1c` | #327 pt2 merged (end of #320–#335 bug-fix wave) | 3.66 |
| `c1c0b1b` | #323 dynamic-bins pt1 merged | 3.64 |
| `c3152f5` | #346 (-mem counters) merged — **last fast commit** | **3.64** (median of 3: 3.62/3.64/3.66) |
| `76042be` | **#345 merged — first slow commit** | **6.51** (median of 3: 6.49/6.51/6.53) |
| `a8ed76c` | #349 (duration demand decoupling) merged | 6.58 |
| `7c36e73` | branch tip (#323 pt3) | 6.58 |

The #349 duration-statistics demand work and the #323 dynamic-bins work — the prime
suspects named in the issue — add nothing measurable (6.51 → 6.58 across both).

### Micro-benchmark isolating the regex order (same probe file, pure Perl loop)

| order | wall time | notes |
|---|---|---|
| broad with-duration pattern first (pre-#345 order) | 0.283 s | 276,209 matches on first pattern |
| anchored no-duration pattern first (#345 order) | 3.119 s | 276,209 *failed* attempts, then broad match |

Delta of the micro-benchmark (+2.84 s) accounts for the full end-to-end read_files
delta (+2.87 s median). Attribution is complete: it is the failed anchored match, not
the `$durations_observed` gating, the per-line `my $duration_observed = defined
$duration;`, or anything else in the #345 diff.

## Constraints on the fix (from #345's contract — must be preserved)

1. Duration-less common-format lines must still classify as match_type 4 and must not
   fabricate 0-duration samples or activate latency surfaces (`$durations_observed`).
   This is #345's shipped behavior, covered by `tests/validate-format-detection.sh`
   (tomcat-common scenario) and `tests/validate-duration-display.sh`.
2. `-V format-detection` classification must stay truthful (the reorder existed to fix
   exactly this).
3. With-duration output must remain byte-identical (verified across Tomcat 9, Apache
   HTTP2, CodeBeamer logs in #345).

## Candidate fix directions (not implemented, not evaluated beyond feasibility)

- **Single combined pattern, classify by capture presence:** run only the broad
  with-duration pattern and set match_type 3 vs 4 based on `defined $duration` (and
  thread/session captures). Removes the failing attempt entirely; likely restores the
  0.28 s micro cost. Needs care: the broad pattern's `(\S+)?` tails must not
  mis-capture on exotic no-duration variants (e.g. Nginx ingress lines with quoted
  referrer/user-agent after bytes — see the match_type 4 comment removed in #345).
- **Fail-fast guard before the anchored pattern:** cheap pre-test (e.g. line does not
  end in `" (\d{3}) (\d+|-)` followed by more fields) or reordering back with the
  anchored pattern second plus explicit reclassification of broad matches that
  captured no duration.
- **Kill the backtracking in the anchored pattern:** atomic/possessive grouping or an
  unrolled prefix so a failed attempt is linear. Lower risk of classification changes,
  but keeps two patterns scanning every line.

## Measurement hygiene notes

- `tests/baseline/results/305-post.tsv` totals are poisoned by this regression (noted
  in the issue); do not use as a clean baseline.
- The 57 MB single-file probe above reproduces the regression at ~1/30 the cost of the
  28-file XL selection and is the recommended verification instrument for the fix.
