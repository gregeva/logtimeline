# #414 read-phase regression — profile analysis (ScriptLog, 1k / 10k profiles, 100k wall-clock, bisection)

## Hypothesis
`read_and_process_logs` pays a higher per-line cost on ScriptLog under the generated
scan sub than under the v0.16.0 inline cascade; expected call/iteration count = lines read.

## Method
- Construct: `logs/ThingworxLogs/CustomThingworxLogs/ScriptLog.2025-04-09.1.log`, standard
  scenario shape (`--disable-progress -bs=60 --terminal-width=200`), samples 1k and 10k.
- Arms: 0.17.0 branch head (`414-readphase-new`, at release/0.17.0 `30371a4`, carries #413)
  vs v0.16.0 detached worktree (`414-readphase-old`), same Perl 5.42.2, same machine.
- Cross-validation: `lines_read` 1000/10000 both arms; loop-statement counts 10000 both arms.

## What NYTProf showed (10k)

`read_and_process_logs` incl 0.1632 s (old) → 0.1757 s (new), +7.7%. Decomposed:

| component | old | new |
|---|---|---|
| per-line: excl + CORE:match + CORE:subst + readline (+ scan sub, new) | 0.1625 | 0.1633 |
| fixed per file/run: `format_scan_sub_resolve` (lazy compile, #413) + `select_format_variants` + `sample_file_for_detection` | — | 0.0123 |

- Regex work is equal: the ScriptLog pattern costs 0.0310 s on the old cascade's
  `if ($csv_detected)` line and 0.0319 s on the scan sub's L128. The old cascade ran
  50,273 `CORE:match` calls (5/line) vs the new path's 30,616 (3/line) — the reduction
  is small on ScriptLog because this format sat early in the old cascade, unlike access
  logs, which now skip several failed tries per line (their −10–15%).
- The new per-line machinery the old path did not have: the sub call
  (`$format_scan_sub->($_)` 0.0028 s), the record return (`return $entries[0]` 0.0075 s),
  and the caller-side unpack — ~1 µs/line under the profiler, offset at 10k by the
  two fewer regex tries.
- Statement times inside the loop are otherwise the same on both arms
  (`grep { $_ eq $category_bucket } @log_levels` 0.0087 → 0.0124 is the one outlier).

## Cross-validation
NYTProf loop counts 10,000 == `lines_read` 10,000 (both arms). Scan sub called 10,000×
+ 41 detection-sample calls (`sample_file_for_detection`). Clean.

## Diagnosis (provisional at 10k)
Under NYTProf the per-line cost is equal to within 0.5%; the whole +12 ms delta is fixed
detection/compile cost, which is invisible at 460 MB. NYTProf under-reports exactly the
cost the new path added — sub entry/exit, list return, record unpack (#58 finding F9:
prototype-vs-production +0.8–2.2 s/M lines for per-line closures) — so the profiler
cannot resolve a +4–6% wall-clock delta that is ~0.5 µs/line. The 100k stage must be a
wall-clock comparison (median-of-3, both binaries, `-V benchmark-data`) rather than
another NYTProf run; if it reproduces the +4–6%, attribution is the per-line call/return
shape of the generated scan sub, not the regex.

## Surprises
- `format_scan_sub_resolve` (the #413 lazy compile) now lands inside `parse/read_files`
  timing — 11 ms profiled, ~4 ms unprofiled (`detect/scan_sub_compile`).
- `extract-profile.pl --lines` reports "no line-level data" although the profile carries
  it (`line_time_data(['line'])` works); the script's line accessor needs a look.

## 100k wall-clock stage and bisection (2026-08-24)

Wall-clock, `head -100000` of the same file (40.6 MB), `--disable-progress -V benchmark-data
--terminal-width 200 -bs 60`, median-of-3 ABAB: `parse/read_files` **0.874 s (0.869–0.875)
→ 0.923 s (0.921–0.925), +5.6%**, reproducing the benchmark's +4–6%; ≈0.44 µs/line net of
~5 ms fixed cost. #58's own blessing battery had pure-scriptlog at −1.5% vs the pre-registry
cascade, so the cost landed after #58 merged. Bisection over the release-branch merge
commits (`ltl` at each commit, same construct, 3 runs sorted):

| merge | issue | read_files (s) |
|---|---|---|
| a78ec23 | #58 format registry | 0.864 0.872 0.875 |
| 390e441 | #23 umbrella docs | 0.860 0.865 0.878 |
| **3e6dc3a** | **#382 GC Pause Remark/Cleanup** | **0.896 0.896 0.919** |
| c2a2ea9 / ab264c8 / bcb4033 | #388 / #384 / #400 | 0.885–0.902 |
| **ab17cfc** | **#396 Windchill method-server format** | **0.910 0.911 0.919** |
| 20830ae … 3d2d5b8 | #395 … #422 (head) | 0.904–0.937 |

## Diagnosis

`read_and_process_logs` evaluates `unless (grep { $_ eq $category_bucket } @log_levels)`
on every line; Perl's `grep` never short-circuits, so the cost is one string compare per
list element per line. `@log_levels` grew 31 → 49 entries: +8 in #382 (Pause Remark /
Pause Cleanup / To-space exhausted / Using G1, each with its `-HL` twin) and +10 in #396
(CONFIG / CREATE / DESTROY / START / FINISH, likewise). Microbenchmark (1M iterations ×3,
`$category_bucket = 'INFO'`): grep over 31 = 0.52 µs, over 49 = 1.13 µs (+0.61 µs/line);
a hash `exists` is ~0.03 µs. The measured +0.44–0.49 µs/line sits inside that constant.
The two bisection steps (+3.5% at #382, +3% at #396) are the two list growths.

Why the pattern in the benchmark: every format pays it, but access logs gained 10–15% from
the registry's regex savings (they sat late in the old cascade) which swamps it; ScriptLog
sat early, gained ~nothing from the registry, and shows the list growth undiluted. Not a
scan-path cost at all — #414's original title hypothesis (registry scan path) was wrong and the issue has been reframed; the registry is exonerated.

Other `@log_levels` consumers: `resolve_csv_column_family()` (CSV output, per column) and
four per-bucket `foreach` loops in render — none per-line, none in the stats phase, so this
does not explain #415.

Candidate fix (not implemented): a `%log_level_set` built once beside `@log_levels` and an
`exists` test in the loop — removes the whole 1.1 µs/line, not just the 0.6 µs regression
(~12% of ScriptLog's ~9 µs/line read cost).
