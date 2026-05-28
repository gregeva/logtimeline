# Feature: Degenerate-input regression harness (#233)

## Overview

Research/scoping deliverable for **#233** (sub-task of **#225** — high-priority
test-harness coverage gaps). #233 covers ltl's behavior on degenerate inputs:
empty files, single-line files, files with no parseable timestamps, all-filtered
runs, and time-range exclusions. The risks are division-by-zero in percentile /
stats code, `Use of uninitialized value` warnings leaking to stderr, summary
tables with nonsensical content (e.g. epoch-zero timestamps), and silent
"success" exits on what is morally an empty result.

This document **does not propose implementation**. It enumerates cases, traces
current behavior through ltl source, defines expected behavior, and recommends
how to wire assertions through the `-V` sections being designed by sibling
sub-tasks #228, #229, #230, and #231.

## § 1. Enumerated degenerate cases

| # | Label | Description |
|---:|---|---|
| (a) | `empty-file` | 0-byte file |
| (b) | `whitespace-only` | newlines/tabs/spaces, no content |
| (c) | `single-line-parseable` | one valid timestamped line |
| (d) | `single-line-unparseable` | one line with no recognizable timestamp |
| (e) | `many-lines-unparseable` | N>>1 lines, none match any format regex |
| (f) | `all-filtered-by-pattern` | `-i` / `-e` excludes every line |
| (g) | `all-filtered-by-time` | `-st` / `-et` excludes every line |
| (h) | `single-bucket-only` | all data falls into one bucket |
| (i) | `nonexistent-file` | path doesn't exist (cross-check with #231 row 21) |
| (j) | `directory-arg` | path is a directory (cross-check with #231 row 22) |
| (k) | `binary-garbage` | non-text file (e.g. `/bin/ls`) — corruption case |
| (l) | `negative-time-range` | `-st > -et` — degenerate range itself |

Cases (i)–(l) are added by the research — (i)/(j) are already covered by #231
shared-error-path work, but a harness still needs assertions for them.

## § 2. Current behavior — traced through source

`@in_files` is populated and validated at `ltl:4312–4318`; a non-existent path
or directory `die`s with `"unable to open any files"` at 4318 (cases i, j).
After that, every accepted file enters `read_and_process_logs()` at `ltl:4523`,
streamed line-by-line through a 13-format regex cascade (`ltl:4564–4774`, see
`features/225-format-detection.md` § 1). Each parsed line increments
`$total_lines_read` (`ltl:4572`); each line passing the format regex and any
`-i`/`-e`/`-st`/`-et` filter increments `$total_lines_included` (`ltl:5053`)
and updates `$output_timestamp_min`/`$output_timestamp_max` (`ltl:5039–5040`).

After the read loop, control reaches:

1. `initialize_empty_time_windows()` at `ltl:6407`. Iterates from
   `$output_timestamp_min` to `_max` in bucket steps. Defaults are `0`
   (`ltl:151–152`). With no data, the loop iterates exactly once (bucket 0 ≤ 0)
   and creates one empty bucket — silent, no warning.
2. `calculate_all_statistics()` at `ltl:6055`. The loop is `foreach my $bucket
   ... keys %log_analysis` — an empty hash means the loop never executes. Safe.
3. `calculate_statistics()` at `ltl:6365–6371` is guarded:
   `return unless $occurrences > 0` and `return unless ... @{...durations}`.
   Percentile indexing at `ltl:6396–6402` is therefore unreachable when
   `duration_count == 0`. **No division-by-zero risk under existing guards.**
   The bin-counter `percentile()` at `ltl:804–834` is also guarded
   (`return (undef, 'none') if $total_N == 0`).
4. `normalize_data_for_output()` (`ltl:6823`) protects scaling with explicit
   `!= 0` guards (`ltl:7045`, `ltl:7046`, `ltl:7061`).
5. `print_bar_graph()` at `ltl:7484` is gated by `if ($total_lines_included)`
   (`ltl:7488`). The empty-graph fallback (`ltl:7757`) prints:
   `Read $total_lines_read lines, however no lines matched any of the
   patterns within the timeframe.`
6. `print_summary_table()` (`ltl:8438`) **runs unconditionally**. With no data
   it calls `strftime(..., gmtime(0))` (`ltl:8451–8452`), so the summary shows
   `1970-01-01 00:00:00` as both min and max — visually meaningless but not a
   crash. `LINES INCLUDED 0`, `LINES READ N` are emitted as usual.

### Per-case behavior summary

| # | Case | Crash? | Friendly msg? | Exit | Notes |
|---:|---|---|---|---:|---|
| a | empty | no | yes, line 7757 | 0 | summary table shows 1970 epoch |
| b | whitespace | no | yes | 0 | identical to (a) |
| c | single-line parseable | no | full graph | 0 | one-bucket render; stats may show `min=mean=max` |
| d | single-line unparseable | no | yes | 0 | identical to (a); no signal it was a *format* failure |
| e | many unparseable | no | yes | 0 | identical to (d) at the user level — **the format mismatch is invisible** |
| f | all filtered by `-i`/`-e` | no | yes | 0 | summary shows `LINES READ > LINES INCLUDED = 0` |
| g | all filtered by `-st`/`-et` | no | yes | 0 | indistinguishable from (f) at output level |
| h | single-bucket-only | no | full graph | 0 | one bar; CV/stddev may be 0 — odd but valid |
| i | non-existent file | yes (`die`) | yes via `print_usage` | 255 | shared with #231 |
| j | directory arg | yes (`die`) | yes via `print_usage` | 255 | message says "unable to open any files" — misleading |
| k | binary garbage | no | yes (no lines parse) | 0 | identical to (e); no corruption signal |
| l | negative time range | depends | warns | 0 | `calculate_start_end_filter_timestamps` accepts; `_min > _max` produces zero-bucket loop |

**Key observation:** cases (a)/(b)/(d)/(e)/(f)/(g)/(k) all collapse to the same
single output line. The user cannot tell *why* there is no data.

## § 3. Expected behavior — recommendation per case

Per #231's research, **exit-code policy is deferred to a separate ticket.**
This sub-task respects that and proposes only that exit codes be **made
observable as-is**, not changed.

| # | Case | Expected stdout/stderr | Expected exit |
|---:|---|---|---:|
| a | empty | "no lines read from <file> (file is empty)" | preserve current (0) |
| b | whitespace | "no lines read from <file> (whitespace only)" | preserve (0) |
| c | parseable | full graph as today | preserve (0) |
| d | unparseable | "read 1 line; no parseable timestamps found — log format unrecognized" | preserve (0) |
| e | many unparseable | "read N lines; no parseable timestamps found — log format unrecognized" | preserve (0) |
| f | all filtered | "read N lines; all N lines excluded by include/exclude patterns" | preserve (0) |
| g | all time-filtered | "read N lines; all N lines outside time range [start..end]" | preserve (0) |
| h | single bucket | normal output; **no special treatment** | preserve (0) |
| i | nonexistent | inherits #231 `print_usage` cleanup | preserve (255 today) |
| j | directory | inherits #231 — message should say "is a directory", not "unable to open any files" | preserve (255 today) |
| k | binary | identical to (e); no special branch | preserve (0) |
| l | neg time range | warn at parse, but treat as case (g) at output | preserve (0) |

The summary table at `ltl:8451–8454` should be **suppressed when
`$total_lines_included == 0`** (or print "n/a" for min/max timestamps) — the
1970 epoch display is a soft bug, not a crash.

## § 4. Code-quality gaps (bounded changes)

| # | Cases | Change | Effort |
|---:|---|---|---:|
| 1 | a–g, k | At top of post-read flow, branch on `$total_lines_included == 0` and emit a case-specific message instead of the single generic one at `ltl:7757`. The case is determined by counters already available (`$total_lines_read`, format-match count, filter-rejection count). | low |
| 2 | a, b, d, e, k | Suppress summary table or emit "(no data)" placeholders when `$total_lines_included == 0` instead of `1970-01-01` strftime output (`ltl:8451–8454`). | low |
| 3 | a–g | Add a small `%degenerate_reason` accumulator during read (one of `empty`, `whitespace`, `no_timestamps`, `all_pattern_filtered`, `all_time_filtered`). | low |
| 4 | j | Distinguish directory from missing-file in the `ltl:4314–4318` validation — currently both fail with the same message. | trivial |
| 5 | l | In `calculate_start_end_filter_timestamps` (`ltl:4421`), warn when `_start > _end`. | trivial |
| 6 | n/a | **No division-by-zero fixes needed** — existing guards (`ltl:6368`, `6371`, `7045–7046`, `7061`, `834`) cover the percentile/scale paths. The harness should **assert** this rather than fix something. | n/a |

Total scope: roughly half a day of fixes plus harness work.

## § 5. Synthetic fixture strategy

**Recommendation: generate at test time inside the harness for all cases except
(c), (e), (h).**

Rationale: cases (a)–(b)/(d)/(k)/(l) are trivially expressible as `: >`,
`printf "\n\n\t\n"`, `echo "no timestamp"`, `head -c 256 /usr/bin/ls`,
`-st > -et` — checking these into the repo adds noise. Cases (c), (e), (h) are
substantive enough (a real timestamped line, ~50 unparseable lines that *look*
plausible, a 3-line single-bucket sample) that they deserve files under
`tests/degenerate-fixtures/`.

This mirrors #230's split: synthetic minimal-content fixtures under
`tests/filter-fixtures/` are committed; trivial degenerate inputs are
ephemeral.

## § 6. Observable surface today

Per § 2 and per `features/225-format-detection.md` § 3 and
`features/225-filter-logic.md` § 5:

- No `-V` section today reports degenerate-input state.
- The empty-result message at `ltl:7757` is human-readable only — no
  per-case slug, no machine-parseable form.
- `=== BENCHMARK DATA ===` (`ltl:7430–7431`) carries `lines_read` /
  `lines_included` — these distinguish (a/b/d/e) from (f/g) but not from each
  other.
- `print_summary_table()` (`ltl:8508–8509`) carries the same two counters in
  human form.

The format-detection deficit identified by #228 is the load-bearing gap for
cases (d)/(e)/(k) — without per-file `match_type` observability, "no parseable
timestamps" is indistinguishable from "empty file".

## § 7. Application-observability — recommend Option C (coordinated)

- **Option A** — single `no_data: yes/reason: <slug>` on `=== FILTER SUMMARY ===`
  conflates format/parse failures with filter failures. Reject.
- **Option B** — new `=== DEGENERATE INPUT ===` section. Cleanest, but
  duplicates state that #228 (format match counts) and #230 (filter inclusion
  counts) already need to emit.
- **Option C (recommended)** — reuse #228's `=== FORMAT DETECTION ===` for
  cases (d)/(e)/(k) (`matched_lines: 0` per file, plus a new section-level
  `no_parseable_timestamps: yes` if every file is zero), and #229/#230's
  `=== FILTER SUMMARY ===` for cases (f)/(g) (`included: 0` plus a new
  `degenerate_reason: all_pattern_filtered|all_time_filtered|...`). Cases
  (a)/(b) get a one-line `=== FILTER SUMMARY ===` field `input_lines_read: 0`.

Option C costs one new enum field in each of two already-proposed sections, no
new section. The single ltl owner field is `degenerate_reason`, surfaced in
`filter-summary` when `included == 0`. Enum values:
`empty_input | no_parseable_timestamps | all_pattern_filtered |
all_time_filtered | mixed`.

## § 8. Assertion strategy — worked examples

For each case the harness asserts (1) exit code, (2) stdout/stderr content,
(3) the relevant `-V` section field, and (4) **no Perl warnings on stderr**
(`grep -E 'Use of uninitialized value|Argument .* isn.t numeric' stderr` must
return 0 hits).

```
Case (a) — empty-file
  in:  : > $TMP/empty.log
  cmd: ltl --disable-progress -V filter-summary $TMP/empty.log
  exit:    0
  stderr:  empty (no Perl warnings)
  stdout:  contains "no lines read"
  -V:      FILTER SUMMARY > input_lines_read: 0
           FILTER SUMMARY > degenerate_reason: empty_input

Case (e) — many unparseable
  in:  yes "not a log line" | head -50 > $TMP/garbage.log
  cmd: ltl --disable-progress -V format-detection,filter-summary $TMP/garbage.log
  exit:    0
  stderr:  empty
  stdout:  contains "no parseable timestamps"
  -V:      FORMAT DETECTION > <file> > matched_lines: 0
           FILTER SUMMARY   > degenerate_reason: no_parseable_timestamps

Case (f) — all filtered by include pattern
  cmd: ltl --disable-progress -V filter-summary -i 'NEVER_MATCH' \
        tests/degenerate-fixtures/single-bucket.log
  -V:      FILTER SUMMARY > input_lines_read: 3
           FILTER SUMMARY > included: 0
           FILTER SUMMARY > degenerate_reason: all_pattern_filtered

Case (g) — all filtered by time range
  cmd: ltl --disable-progress -V filter-summary -st 1999-01-01 -et 1999-01-02 \
        tests/degenerate-fixtures/single-bucket.log
  -V:      FILTER SUMMARY > degenerate_reason: all_time_filtered

Case (h) — single-bucket-only
  cmd: ltl --disable-progress -V format-detection \
        tests/degenerate-fixtures/single-bucket.log
  exit:    0
  stderr:  empty
  stdout:  must contain bar graph (one row), summary table with LINES INCLUDED 3
  -V:      FORMAT DETECTION > matched_lines >= 3
  Negative assertion: no division-by-zero warning; min/mean/max present.
```

The no-Perl-warnings assertion is the highest-value cheap signal — it catches
silent regressions in the percentile / scaling guards if any future refactor
removes them.

## § 9. Coordination with other sub-tasks

| Field | Owner | Sub-task |
|---|---|---|
| `=== FORMAT DETECTION ===` section spec | #228 | shared consumer here |
| `matched_lines: 0` per-file detection | #228 | this sub-task asserts the field exists and is correct on cases (a)/(d)/(e)/(k) |
| `=== FILTER SUMMARY ===` section spec | #229 + #230 | shared consumer here |
| `input_lines_read`, `included`, `excluded` counters | #229/#230 | cases (f)/(g) assertions |
| `degenerate_reason` enum field (NEW) | **#233** (this sub-task) | added under `=== FILTER SUMMARY ===`; values listed in § 7 |
| `die` / `exit` formatting for cases (i)/(j) | #231 | this sub-task asserts post-#231 message text |
| Distinguishing directory from missing file (case j) | #231 + #233 | message text change is #231's; assertion is here |

The hard ordering: #226 (`-V` selectivity) → #228 + #229/#230 (sections
exist) → **#233 wires assertions on top**. #233 itself adds one new field
(`degenerate_reason`) into a section another sub-task owns; this is the
minimum surface-area contribution.

## § 10. ltl code changes required

| Change | Owner | Effort |
|---|---|---|
| Branch the empty-result message at `ltl:7757` on a `%degenerate_reason` accumulator built during read | #233 | low |
| Add `degenerate_reason` enum emission inside `=== FILTER SUMMARY ===` (`ltl:7430` area or new emitter) | #233 | low (sits on #229/#230 emitter) |
| Suppress 1970-epoch timestamps in summary table when `$total_lines_included == 0` (`ltl:8451–8454`) | #233 | trivial |
| Distinguish directory vs missing-file at `ltl:4314–4318` | #231 | trivial |
| Warn when `-st > -et` in `calculate_start_end_filter_timestamps` (`ltl:4421`) | #233 | trivial |
| Confirm and document existing div-by-zero guards (`ltl:6368, 6371, 7045, 7046, 7061, 834`) | n/a | docs only |

No new sections, no new flags. Total ltl-side effort: **0.5–1 day**, blocked
on #228/#229/#230 emitters landing first.

## § 11. Harness shape proposal

File: `tests/validate-degenerate-inputs.sh`. Bash, generates ephemeral inputs
in `$TMP`, references committed fixtures for substantive cases.

1. Define case table inline — `(label, generator_cmd_or_fixture_path,
   extra_args, expected_exit, expected_stdout_grep, expected_filter_summary_kv,
   expected_format_detection_kv)`.
2. For each row:
   a. Materialize input (run generator into `$TMP` or reference fixture).
   b. Invoke `./ltl --disable-progress --terminal-width 200 -V format-detection,filter-summary <extra_args> <input>` with `LC_ALL=C`, capture stdout/stderr/exit.
   c. Assert exit code matches expected.
   d. Assert stderr contains **zero** Perl-warning patterns (uninitialized,
      non-numeric, deep recursion).
   e. Grep stdout for the case-specific user-facing string.
   f. Parse `=== FILTER SUMMARY ===` and `=== FORMAT DETECTION ===`; assert
      key/value expectations.
3. Emit TAP summary; exit non-zero on any assertion failure.
4. Reuse `tests/validate-regression.sh`'s LC/width/`--disable-progress`
   isolation conventions.

Coordinates with `tests/validate-format-detection.sh` (#228),
`tests/validate-filter-logic.sh` (#230), `tests/validate-pattern-files.sh`
(#229) — same `-V` parsing helpers should be factored into a shared bash
library to avoid duplication.

## § 12. Open questions

1. **Should the summary table be suppressed entirely when there is no data,
   or should it print with explicit `n/a` placeholders?** Suppression is
   simpler; placeholders preserve column alignment for scripted consumers.
2. **Is `degenerate_reason: mixed` worth the complexity** (multi-file run
   where one file is empty and another is all-filtered), or should the
   harness only cover single-file degenerate cases and defer mixed-input
   cases to a follow-up?
3. **Case (l) — negative time range** (`-st > -et`). Is this a hard error
   (die at parse) or a soft warning (treat as all-filtered)? Today it's
   silently accepted. Recommend: warn + accept, but pin the choice before
   the harness ships.
4. **Binary-garbage (case k) overlap with #227** (binary smoke tests).
   #227 already proposes smoke-running the static binary; does #233's
   binary-garbage *input* case duplicate #227's coverage, or is it a
   distinct concern (input file is binary, vs ltl binary itself)?
   Recommend: keep as a distinct degenerate-input case — #227 is about
   the executable, #233 is about feeding garbage *to* it.
5. **Does emitting a per-case `degenerate_reason` violate the existing
   `=== FILTER SUMMARY ===` design contract being negotiated by #229/#230?**
   The field name has to be agreed across all three sub-tasks before any
   one of them ships its emitter.

## § 13. Effort estimate

- ltl changes (degenerate-reason accumulator + summary suppression +
  directory-vs-missing): **0.5 day**, blocked on #229/#230 emitters.
- Synthetic fixtures (3 committed files) + ephemeral-input generators:
  **0.25 day**.
- Harness script (`validate-degenerate-inputs.sh`): **0.5 day**.
- Coordination overhead with #228/#229/#230/#231 (field naming, shared
  parser): **0.25 day**.

**Overall: low effort, ~1.5 days of focused work, blocked on the
`=== FORMAT DETECTION ===` (#228) and `=== FILTER SUMMARY ===` (#229/#230)
emitters and on #226's `-V` selectivity. The most valuable single
contribution is the no-Perl-warnings stderr assertion — it locks in the
already-correct division-by-zero guards documented in § 4 row 6.**

## Related

- **Blocks** #233 (this harness)
- **Depends on** #226 (`-V` selectivity), #228 (`=== FORMAT DETECTION ===`),
  #229/#230 (`=== FILTER SUMMARY ===`), #231 (error-message cleanup for cases i/j)
- **References:** `ltl:4312–4318` (file validation), `ltl:4421–4457`
  (time-range parsing), `ltl:4523–4774` (read/format cascade),
  `ltl:5039–5053` (timestamp min/max + included counter), `ltl:6055–6404`
  (statistics with existing zero-sample guards), `ltl:6407–6437`
  (empty-bucket initialization), `ltl:7488` (graph-vs-message branch),
  `ltl:7757` (current empty-result message), `ltl:8438–8517`
  (summary table including 1970-epoch bug),
  `features/225-format-detection.md`, `features/225-filter-logic.md`,
  `features/225-pattern-files.md`, `features/225-cli-validation.md`.
