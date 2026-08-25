# #415 stats-phase drift — profile analysis (constructs c1, 100k sample)

## Hypothesis
`calculate_all_statistics` and its helpers show identical call counts between v0.16.0 and 0.17.0 (matching byte-identical `-V statistics-demand` / `-V percentile-algorithm` sections) but higher per-call cost under 0.17.0 — the drift is per-operation, not extra work.

## Method
- Construct: humungous-log-uniqueness `-so p99`, `--data-model=raw`, harness-shaped (`-bs 60`, `--terminal-width=200`), 100k-line sample.
- Arms: 0.17.0 tree (`415-statsdrift-new`) vs v0.16.0 detached worktree (`415-statsdrift-old`), same Perl 5.42.2, same machine, run back-to-back.
- Bin-counter involvement excluded beforehand: with `-dm raw` pinned on all four stores (verified via `-V runtime-config`), the end-to-end drift persists (median 0.462 s → 0.554 s, +19.9%, median-of-3, non-overlapping ranges); negative control (single-day access log `-hg`) flat.

## What NYTProf showed (100k)
| sub | old incl/excl | new incl/excl |
|---|---|---|
| calculate_all_statistics | 0.1372 / 0.0853 | 0.1581 / 0.0889 (+15% incl) |
| measure_memory_structures | 0.1125 | 0.1254 (+11%) |
| named_structure_sizes | 0.0836 | 0.0940 (+12%) |
| read_and_process_logs (excl) | 1.2736 | 1.1064 (faster) |
| compile_format_scan_sub | n/a | 28 calls, 0.0968 s (startup precompile, #413) |
| format_registry_promote | n/a | 13 calls, 0.0410 s |

Line-level (Devel::NYTProf::Data API, sub line range): the hot statements are the per-key loop over `%log_messages{$category}` (entry fetch + `$n` gate) and the `@by_occ` occurrences-sort comparator. Source is byte-identical between versions; per-statement counts match exactly (99,487 loop iterations = `COUNTS log_messages_entries` both arms; ~102.3k comparator entries both arms); per-statement TIME is +14–35% in 0.17.0.

## Cross-validation
NYTProf loop count 99,487 == `-V` `COUNTS log_messages_entries` 99,487 (both arms). Clean.

## Diagnosis
Not a statistics-code change (none exists; code and counts identical). Not bin-counter related (raw-pinned drift persists). The slowdown is concentrated in subs that traverse the large `%log_messages` hash (stats loop +15%, memory measurement walkers +11–12%) while the sequential read loop is unaffected — consistent with degraded memory locality of large-hash traversal in the 0.17.0 process, whose heap carries ~+20 MB of eagerly compiled scan-order subs allocated before the hash is built (#413; RSS 89 → 111 MB at this sample). Mechanism is inferred from the profile shape; not yet directly proven.

## Surprises
- `format_registry_promote` costs 3.15 ms/call mid-run (13 calls here) — compile-on-promotion cost visible in parse phase.
- run-profile.sh treats every bare token in ltl args as an input file to truncate — options must use `=`-joined forms.

## Next step (pending architect)
Discriminating probe for the locality hypothesis (requires a scratch-copy code edit, not yet approved): disable the eager precompile loop in `build_format_registry()` on a throwaway copy, re-run construct 1 median-of-3. Collapse of the drift attributes #415 to #413; persistence sends the investigation to allocator/heap layout beyond the precompile.

## Addendum: -so p99 vs default occurrences sort (0.17.0 only, architect-directed)

Timing (full 97 MB file, `-dm raw`, median-of-3):

| arm | finalize/calculate_statistics | delta |
|---|---|---|
| default (occurrences sort) | 0.315 s (0.309–0.316) | — |
| `-so p99` | 0.554 s (0.532–0.555) | +76% |

`-V statistics-demand` under `-so p99` on this log: `sort_selection: statistic=p99 defined=0 fill=286659 demoted=0`, all `group_calc … computed=0` — **zero keys reach the n≥4 percentile-eligibility floor, zero percentiles are computed**. The entire +0.24 s is (a) the population-wide per-key eligibility walk over `%log_messages` and (b) the 286,659-key fill-block occurrences sort (comparator does two hash lookups per comparison).

Profile agreement (100k sample, `calculate_all_statistics`): 0.083 s incl / 0.017 s excl (default) vs 0.158 s incl / 0.089 s excl (`-so p99`) — the difference sits on the loop/comparator statements, not percentile math.

Implication for the sort-on-statistic cost model: on singleton-dominated logs, the population-stats obligation of `-so <statistic>` degenerates into pure walk-and-sort overhead with zero statistical yield — the population price is paid even when no key can rank. This is also where the cross-version drift concentrates (same statements), which is why sort-on-statistic scenarios drift hardest between v0.16.0 and 0.17.0.

## Tooling fix landed under this ticket

`run-profile.sh` classified any non-dash token as an input file, truncating option values (`-V` section lists, `-so` operands, long-option values) into empty samples → zero-line profiled runs. Both arg walkers now apply one on-disk test (`-e` / glob expansion) before treating a token as a sample source. Commit eefda5a on branch 415-calculate-statistics-drift.

## Re-measure with the #417 sub-stage instrument (2026-08-24, post-merge of release/0.17.0)

Same construct (humungous `-so p99`, `-dm raw`, `-mem`, harness-shaped), median-of-3
ABAB, v0.16.0 worktree binary vs this branch (now carrying #417), same machine,
back-to-back. Runtime-config byte-identical to the earlier arms.

| row | old (v0.16.0) | new (0.17.0 + #417) | delta |
|---|---|---|---|
| calculate_statistics (parent) | 0.465 s (0.461–0.501) | 0.560 s (0.533–0.563) | **+20.4%** |
| ├ population_walk | — | 0.264 s (0.259–0.269) | 47% of phase |
| ├ sort_selection | — | 0.282 s (0.261–0.283) | 50% of phase |
| ├ bucket_stats / group_calc / threadpool_stats | — | 0.000 s each | 0% |
| └ untimed | — | 0.013 s | 2% |
| total | 2.934 s | 3.155 s | +7.5% |

- Drift reproduces at the same magnitude as the earlier raw-pinned measurement
  (+19.9% then, +20.4% now) — stable, not session noise.
- The instrument attributes 97% of the phase to exactly the two blocks the
  NYTProf statement-level analysis identified: the per-key eligibility walk over
  `%log_messages` (population_walk) and the 286,659-key fill-block occurrences
  sort (sort_selection). Denominators: `COUNTS log_messages_population 286659`,
  `sort_selection: statistic=p99 defined=0 fill=286659` — zero statistical yield,
  as before. Every sub-stage that does per-key *computation* (group_calc,
  bucket_stats) is 0.000: the drift lives entirely in hash traversal + sort.
- `-mem` in the same runs: rss_peak 212.5 MB (old) → 232.6 MB (new), unattributed
  76 → 95 MiB — the ~+20 MB pre-hash heap the locality hypothesis (#413 eager
  precompile) predicts is present in these exact runs.
- Cross-version conclusion now rests on comparable TIMING rows (the pause
  condition): identical work counts, identical sub-stage shape expected, cost
  concentrated where large-hash traversal locality would put it. The
  discriminating probe (scratch-copy disable of the eager precompile loop in
  `build_format_registry()`, re-run this construct) remains the one unproven
  link and still awaits approval — alternatively, #413's fix landing in this
  release provides the same discrimination for free at the next re-measure.

## Re-measure after #413 (2026-08-24, branch at release/0.17.0 head `30371a4`)

Same construct (humungous `-so p99`, `-dm raw`, `-mem`, harness-shaped), median-of-3
ABAB, v0.16.0 worktree binary vs release/0.17.0 head (carrying #413 and #417), same
machine, back-to-back. `COUNTS format_scan_subs_compiled 1` confirms the lazy
compile is in effect; work counts identical across arms
(`log_messages_population 286659`); no runtime warnings either arm.

| row | old (v0.16.0) | new (0.17.0 + #413) | delta |
|---|---|---|---|
| calculate_statistics (parent) | 0.473 s (0.471–0.476) | 0.555 s (0.537–0.558) | **+17.3%** |
| ├ population_walk | — | 0.274 s (0.258–0.282) | 49% of phase |
| ├ sort_selection | — | 0.267 s (0.263–0.269) | 48% of phase |
| ├ bucket_stats / group_calc / threadpool_stats | — | 0.000 s each | 0% |
| parse/read_files | 2.404 s (2.403–2.407) | 2.493 s (2.481–2.513) | +3.7% |
| total | 2.878 s | 3.056 s | +6.2% |
| rss_peak | 206.0 MB | 207.0 MB (205.8–207.7) | +1 MB (was +20 MB) |

- **Locality-via-eager-precompile hypothesis refuted.** #413 removed the +20 MB
  pre-hash heap (rss gap 20 MB → 1 MB) and the drift stepped down only
  +20.4% → +17.3%, still non-overlapping. The heap was at most a minor
  contributor; the dominant cause is elsewhere.
- Shape unchanged: 97% of the phase in the two `%log_messages` traversal
  blocks, zero per-key computation cost.
- `parse/read_files` is also +3.7% in the same runs with identical line
  counts — the read-phase symptom #414 tracks. Whether the two phases share a
  per-operation cause is the open question; #414's staged NYTProf attribution
  runs first (see the cross-link comments on both issues, 2026-08-24).

## Re-measure after #414 and locality ladder (2026-08-24, branch rebased on release/0.17.0 `7372120`)

Same construct, median-of-3 ABAB, v0.16.0 worktree binary vs this branch (carrying
#413, #414, #417), same machine, back-to-back. Work counts identical
(`log_messages_population 286659`), `MEMORY log_messages` byte-identical
(133,188,237 B both arms), no runtime warnings either arm.

| row | old (v0.16.0) | new (0.17.0 + #414) | delta |
|---|---|---|---|
| calculate_statistics | 0.484 s (0.471–0.486) | 0.555 s (0.554–0.560) | **+14.7%** |
| parse/read_files | 2.431 s (2.412–2.455) | 2.132 s (2.111–2.157) | −12.3% (#414) |
| total | 2.903 s | 2.694 s | −7.2% |
| rss_peak | 216.0 MB | 217.7 MB | +1.7 MB |

#414's cause (per-line `@log_levels` grep) was read-phase only and its analysis
records that it does not reach the stats phase; the read-phase +3.7% seen in the
previous re-measure is now accounted for and reversed. The stats drift stands.

### Statement-level split (NYTProf, 100k sample, `415-statsdrift-{old,new}-post414`)

`calculate_all_statistics` 0.1500 → 0.1743 s incl (+16%). Per statement, identical
counts both arms (99,487 loop iterations; ~102.5k comparator entries):

| statement | old | new | delta |
|---|---|---|---|
| `my $entry = $log_messages{$category}{$log_key}` | 0.0300 s | 0.0387 s | +29% |
| comparator `$log_messages{$category}{$a}{occurrences}` | 0.0282 s | 0.0338 s | +20% |
| comparator `…{$b}{occurrences}` | 0.0287 s | 0.0338 s | +18% |
| `scalar @{ $entry->{durations} // [] }` | 0.0129 s | 0.0150 s | +16% |
| `foreach my $log_key (keys %{…})` | 0.0184 s | 0.0196 s | +7% |
| `push @fill_block, $log_key` | 0.0067 s | 0.0067 s | 0% |
| `next` | 0.0048 s | 0.0048 s | 0% |
| `if (!$message_duration_stats_demand || $n < $n_floor` | 0.0047 s | 0.0045 s | 0% |

The process is not uniformly slower: statements that do not touch the hash are
identical to the microsecond. Every keyed access into `%log_messages{$category}`
and every dereference into an entry is +16–29%; the sequential `keys` walk is +7%.
The memory walkers (`measure_memory_structures`, also a traversal of the same
hash) show the same +14%.

### Hash internals are identical in kind (Devel::Peek, scratch copies, 100k)

Both arms: category hash `FLAGS = (OOK,SHAREKEYS)`, `MAX = 262143`,
`KEYS = 99487`, fill 82.6k–82.7k, hash quality 127%; key SVs returned by `keys`
are shared-HEK COW strings (`POK,IsCOW,pPOK`, `LEN = 0`, 123 bytes) in both, so
lookups reuse the cached hash value in both; entry hashes `SHAREKEYS`, 1 key,
`MAX = 7`, in both. Hashing cost, bucket count and key representation are ruled
out.

### Locality ladder (scratch copies, 100k, best-of-5 per level, two ABAB rounds)

Probe: `locality-ladder-probe.pl` (this directory), injected before
`calculate_all_statistics()` on throwaway copies of both scripts. `lookup` is the
comparator-shaped loop (`$h->{$k}{occurrences}` over all keys); `walk` is the
population-walk shape (`keys` + entry field dereference). L0 is the hash as the
read phase built it; each further level rebuilds one more layer into freshly
allocated memory while keeping the rest.

| level | what is fresh | old lookup | new lookup | old walk | new walk |
|---|---|---|---|---|---|
| L0 as built | nothing | 0.0387 / 0.0396 | 0.0445 / 0.0443 (**+13%**) | 0.0565 / 0.0521 | 0.0573 / 0.0619 (**+10%**) |
| L1 | outer hash entries + value RVs (`%f = %$h`) | 0.0280 / 0.0268 | 0.0320 / 0.0340 (**+20%**) | 0.0455 / 0.0383 | 0.0345 / 0.0357 |
| L2 | L1 + inner entry hashes rebuilt | 0.0080 / 0.0076 | 0.0078 / 0.0076 (0%) | 0.0253 / 0.0247 | 0.0272 / 0.0276 |
| L3 | L2 + key strings re-copied | 0.0110 / 0.0109 | 0.0115 / 0.0111 (0%) | 0.0271 / 0.0281 | 0.0269 / 0.0277 |

Entry-head addresses span the same number of 16 KB pages in both arms (912–914).

Findings:

1. **The old/new gap lives in the inner per-message entry hashes.** It survives
   rebuilding the outer hash (L1: +20%) and vanishes the moment the entry hashes
   are rebuilt into fresh memory (L2: 0%). Hashing, key strings and the outer
   bucket array are exonerated (also by the Peek comparison).
2. **Mechanism: heap placement of the entry hashes, set during the read phase.**
   Each entry hash is a head + body + bucket array + HE + HEK + value SV allocated
   at the moment the message is first seen, interleaved with whatever else the
   read loop allocates and frees per line. 0.17.0's read loop (registry scan sub,
   #58) has a different per-line allocation/free pattern, so consecutive entries
   land in a different free-list order — a less dense layout for the traversal
   that follows. Nothing in the statistics code changed; the traversal pays for
   how the read loop left the heap.
3. **Larger than the drift: as-built entry layout costs 5× on keyed traversal in
   BOTH versions** (L0 0.039–0.044 s vs L2 0.008 s; walk 2×). The +15% drift is a
   worsening of an already scattered layout. That is a data-model observation
   (per-message stats as one small hash each), not a 0.17.0 regression, and
   belongs with the #349 demand-contract / #2 message-stats design, not here.

### Bisect with the L0 lookup metric (2026-08-24)

Metric: `bisect-l0-probe.pl` injected before `calculate_all_statistics()` on each
commit's `ltl` (extracted with `git show sha:ltl`, no checkout), 100k sample,
best-of-5 in each of 2 runs (`bisect-measure-l0.sh`). Session endpoints:
v0.16.0 0.0355 s, release head 0.0404 s (+14%); threshold 0.038.

First-parent merges on `release/0.17.0` (22 commits touching `ltl`):

| step | commit | L0 | verdict |
|---|---|---|---|
| [10] | `ab264c8` merge #402 (#384 filename evidence) | 0.0418 | bad |
| [4] | `12f29d6` merge #381 (#379 glob paths) | 0.0357 | good |
| [7] | `1bee009` merge #392 (#390 wording) | 0.0421 | bad |
| [5] | `a78ec23` merge #389 (#58 format registry) | 0.0407 | **first bad** |

Inside the #58 branch (7 commits touching `ltl`):

| step | commit | L0 | verdict |
|---|---|---|---|
| [3] | `bd8a972` Replace the match-type cascade with the format-registry scan (#58 S5) | 0.0411 | **first bad** |
| [1] | `4ee50a1` detect-stage TIMING row (#58 S3) | 0.0360 | good |
| [2] | `b6495c2` shadow mode proving registry/cascade parity | 0.0366 | good |

The layout change enters with the generated scan sub replacing the inline
cascade in the read loop (S5): same keys, same entry shape, different per-line
allocation/free sequence around each entry's creation. Consistent with the
ladder: the statistics code is untouched by that commit.

### Tooling fixes landed under this section

- `classify_option_error()` reported only the first word of a rejected token
  (`/(\S+)/`), so a quoted option string passed as one argument was reported as
  `unknown option '--disable-progress'` — a valid option named as the culprit. The
  whole token is now captured and quoted verbatim.
- `run-profile.sh` carried a hand-maintained, stale list of value-taking options
  (`-terminal-width` is not a spelling; `-so`, `-dm`, `-V`, `-lf`, `-tw`, the
  `-*min/-*max` family were missing). Both arg walkers now derive the set from
  ltl's own `GetOptions` specs (`build_value_option_sets()` / `option_arity()`),
  mirroring Getopt::Long's required/optional value consumption.
- `make_sample()` printed its progress lines to stdout inside a command
  substitution, so "Creating sample: …" leaked into the ltl argument string on a
  first-time sample. Progress now goes to stderr.

## Status

Attributed 2026-08-24: heap placement of the per-message entry hashes, changed
by the read loop's generated scan sub (`bd8a972`, #58 S5); statistics code
exonerated. Finding 3 (as-built layout costs 5× on keyed traversal in both
versions) is filed as a data-model follow-up. Disposition of #415 itself: see
the issue thread.
