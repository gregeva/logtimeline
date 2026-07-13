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

## Candidate fix directions (not implemented)

- **Deterministic prefix (validated — see below):** replace the `(.+? ){3}` prefix
  with `([^ ]+ ){3}` in both access-log patterns so a failed attempt dies linearly
  instead of backtracking. Keeps both patterns and #345's ordering/classification.
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
- **Per-file format lock-in (strategic, separate issue):** after the first N lines of
  a file classify as one match_type, dispatch straight to that pattern. Collapses the
  cascade to ~one regex per line for homogeneous files; overlaps with
  `features/log-format-registry.md`.

## Deterministic-prefix validation (2026-07-13, micro-benchmark)

Replacing `(.+? ){3}` with `([^ ]+ ){3}` in both access-log patterns, same 276,209-line
probe file, pure-Perl loop applying the #345 pattern order (anchored first):

| prefix | wall time (3 trials) | matches |
|---|---|---|
| `(.+? ){3}` (current) | 3.119 / 3.118 / 3.113 s | A=0 B=276,209 |
| `([^ ]+ ){3}` (fix) | 0.557 / 0.559 / 0.559 s | A=0 B=276,209 |

5.6x faster on the scan; projected read_files on the probe ~6.51 s → ~3.9 s (removes
~90% of the regression). A residual ~+0.3 s (~1 µs/line: the now-cheap failed anchored
attempt on every with-duration line) remains vs the pre-#345 3.64 s baseline; only the
single-pattern or format-lock-in directions eliminate it.

Capture-equivalence checked on both patterns across: with-duration + thread + session,
duration-only, common format, dash bytes, and Nginx ingress quoted referrer/user-agent
lines — all byte-identical between current and hardened prefixes.

**One behavioral delta:** the lazy `.+?` prefix tolerates spaces *inside* the three
leading fields (host, ident, authuser) — e.g. `10.2.3.4 - John Smith [date] ...`
matches today but is NOMATCH with the deterministic prefix (the line falls through the
access-log branches and continues down the cascade). This tolerance is inherently a
product of the backtracking being removed; atomic grouping loses it identically. CLF
permits spaces in authuser, but servers typically log `-` or encode; zero such lines
exist in the probe corpus, and Tomcat/ThingWorx always emit `-`. Accepting this
narrowing is a disposition decision for the fix.

## Cascade-wide lazy-prefix survey (2026-07-13)

Four patterns in the `read_and_process_logs()` format cascade carry the `(.+? ){3}`
prefix. Per-pattern cost on the 276,209-line with-duration probe file (each pattern
run in isolation against every line):

| pattern | role on this file | lazy prefix | deterministic prefix |
|---|---|---|---|
| match_type 12 (CodeBeamer `[Nms] [Ts]`) | fails every line | 0.05 s (0.18 µs/line) | 0.05 s |
| match_type 4 (common, end-anchored) | fails every line | 2.84 s (10.3 µs/line) | 0.29 s (1.0 µs/line) |
| match_type 3 (with-duration — matches) | matches every line | 0.24 s (0.85 µs/line) | 0.23 s |
| match_type 9 (enhanced/JBoss: quoted referrer + UA + trailing duration) | fails every line | 2.83 s (10.2 µs/line) | 0.28 s (1.0 µs/line) |

Full shipped cascade (12 → 4 → 3) over the file: 3.15 s lazy vs 0.58 s
all-deterministic — 5.4x.

Findings:

1. **match_type 12 is free despite running first**: its regex contains the mandatory
   literal `ms] [`, so Perl's fixed-substring pre-check rejects non-CodeBeamer lines
   before the regex engine starts. This is why the v0.15.1 baseline stayed fast with
   this pattern ahead of the cascade. match_type 4 and 9 have no such distinctive
   literal (everything they require appears in every access-log line), so the engine
   runs to an expensive backtracking failure.
2. **match_type 9 has the identical pathology (~10 µs/line on failure) but is latent
   on with-duration files** — match_type 3 matches those lines before the cascade
   reaches 9. It taxes lines that fall through the whole access-log family (unmatched
   lines in mixed-format files). The deterministic prefix fixes it identically; as a
   fail-only path on real corpora it should ride along in the #358 fix.
3. **match_type 9 is shadowed dead code for its own format** — a genuine
   enhanced/JBoss line is captured by match_type 3 first with duration lost (undef)
   and junk thread/session captures. Same shadowing-defect class #345 fixed for
   match_type 4, but the casualty is a real observed duration. Latent in every
   released version (match_type 3 precedes 9 in v0.15.1 too); not part of the #358
   regression. Tracked as #365 (enhanced/JBoss format shadowed, duration silently
   lost); the fix ordering must be coordinated with the #358 fix.

Recommended fix shape for #358: apply the deterministic `([^ ]+ ){3}` prefix to the
match_type 4, 3, and 9 patterns (match_type 12 optionally for consistency — no
measured gain), accepting the spaces-in-authuser narrowing documented above. The
match_type 9 reachability defect is fixed separately under #365.

## Measurement hygiene notes

- `tests/baseline/results/305-post.tsv` totals are poisoned by this regression (noted
  in the issue); do not use as a clean baseline.
- The 57 MB single-file probe above reproduces the regression at ~1/30 the cost of the
  28-file XL selection and is the recommended verification instrument for the fix.
