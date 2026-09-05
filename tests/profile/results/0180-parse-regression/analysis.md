# Profiling Analysis: 0180-parse-regression

Investigation of the v0.18.0-first vs v0.17.0-release benchmark regression:
parse/read_files +15.9% suite-wide (+17.5 min), rss_peak +21.6%, %log_messages
+28.2%. Reference case: single-day-access-log-standard (148 MB, 0.76M lines),
invocation `--disable-progress -ni -V benchmark-data -mem --terminal-width 200
-bs 60` (the benchmark shape plus `-ni` for hermetic A/B).

## Hypothesis

See hypothesis.md: expected the delta concentrated in the classification/outcome
work (#453/#452/#455). That expectation was WRONG in proportion — those explain
under a third.

## Method

1. Per-case TSV comparison normalised to seconds per million lines: access-log
   cases +1.1–1.7 s/Mline, application logs +0.3–0.5, custom logs ~0,
   consolidate-heavy cases ~flat (added cost diluted by grouping).
2. Same-machine interleaved A/B (3x each): HEAD read_files 9.62 s vs v0.17.0
   8.67 s — +0.95 s reproduced, ranges tight (±0.02).
3. NYTProf 100k-line profiles of BOTH versions (v0.17.0 via a scratch worktree),
   line-time aggregation keyed by source text to survive line-number drift.
   read_and_process_logs exclusive: 1.759 vs 1.569 s; the generated scan sub's
   exclusive time is EQUAL (0.537 vs 0.542) — extraction codegen is not the cost.
4. Isolation variants (patched copies, real un-profiled runs, interleaved):

| Variant (what was disabled) | read_files | recovered |
|---|---|---|
| HEAD (round 1 / round 2)                                   | 9.62 / 9.49 | — |
| V1: per-message `outcomes[]++` writes                      | 9.51 | ~0.11 s |
| V2: V1 + per-bucket outcome accounting (`%bucket_outcomes`, totals, pct-qualifying, cls-sig compare) | 9.46 | ~0.05 s |
| V3: V2 + classifier statement nulled (scan-block regexes)  | 9.36 | ~0.10 s |
| G1: #447 control-char `tr///` scan                         | 9.41 | ~0.08 s |
| G2: #432 bytes min/max/occurrences family (both scopes) reverted to pre-#432 shape | 9.20 | ~0.30 s |
| ALL (V3+G1+G2 union)                                       | 8.69 / 8.68 | ~0.85 s |
| v0.17.0 (same rounds)                                      | 8.63 / 8.58 | — |

The union lands within ~0.07 s (<1%) of v0.17.0: **these groups are the whole
regression**. Residual is spread micro-additions (per-line
`$fdd->{metrics_observed}` write, `$capture_messages` conditional, `sel_*`
occurrence counters).

## Memory attribution

humungous-log-uniqueness (286K unique message keys), MEMORY/log_messages:

| Build | log_messages | rss_peak |
|---|---|---|
| HEAD          | 181.3 MB | 268 MB |
| V1 (no per-message outcomes) | 133.2 MB | 218 MB |
| v0.17.0       | 133.2 MB | 217 MB |

**100% of the %log_messages growth is the per-message `outcomes` array refs**
(~168 bytes/key for a 3-slot array). The suite-wide +21.8 GB in log_messages and
most of the +24.9 GB rss_peak follow.

## Diagnosis

The regression is four deliberate per-line features, two of which are captured
without a demand gate although their only consumers are optional surfaces:

1. **#432 bytes aggregate family (~0.30 s, 33%)** — per-message AND per-bucket
   `bytes_occurrences`/`bytes_min`/`bytes_max`. Feature doc D8 records the only
   consumers: `-so bytes_*` sorts and the two CSV files; nothing is rendered.
   The capture runs unconditionally — a default terminal run pays it for
   surfaces it will never produce. (#432's own analysis measured the +4.0% and
   it was accepted; the demand question was not raised there.)
2. **#453/#452 classification + outcome accounting (~0.26 s, 29%)** — of which:
   - per-message `outcomes[]++` (~0.11 s + ALL the log_messages memory): its
     only consumers are the MESSAGES CSV successes/failures columns and the
     consolidation merge — CSV-gated surfaces, capture is not.
   - the compiled classifier statement (~0.10 s): two anchored alternation
     regexes per line (`^(?:4xx|5xx)$` then `^(?:1xx|2xx|3xx)$`) on a 3-char
     value; codegen could emit eq-chains for all-literal alternations.
   - per-bucket `%bucket_outcomes` + run totals (~0.05 s): feeds the DEFAULT
     surfaces (summary classified rows, timeline % columns, errRate) —
     legitimately ungated.
3. **#447 control-char normalisation (~0.08 s, 9%)** — the `tr///` count IS the
   documented gate (D1–D5, measured at introduction). Deliberate.
4. **Residual micro-spread (~0.1 s)** — accepted small costs.

## Cross-Validation

read_and_process_logs called once, scan sub 100,045 calls vs lines_read=100000
(45 = registry sample validation), both versions. No [WARN]s.

## Surprises

- The scan sub (extraction + inlined classification) contributes nothing
  measurable to the version delta at sub level; the classifier's cost shows up
  only in the V3 isolation (~0.10 s/0.76M).
- The largest single contributor (#432 bytes family) was the one with the most
  careful measurement record — measured for cost, not for demand.

## Action

None yet — findings first. Candidate fixes proposed to the architect:
demand-gate the #432 bytes family and the #453 per-message outcomes on their
actual consumers (the existing stats-demand flag pattern), optional eq-chain
classifier codegen.

## Learnings

- A hot-path capture needs BOTH measurements: what it costs, and who consumes
  it. #432's analysis proved the cost acceptable without asking whether a
  default run has any consumer for the captured family.
- Line-time aggregation keyed by normalised source text is an effective way to
  diff NYTProf profiles across versions with heavy line drift.
