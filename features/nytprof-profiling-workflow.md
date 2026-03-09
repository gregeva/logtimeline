# NYTProf Profiling Workflow

## Purpose

Standardized workflow for profiling ltl with Devel::NYTProf. Eliminates repeated
tool-discovery friction and ensures consistent, comparable profiling sessions with
built-in cross-validation against ltl's internal counters.

Issue: #138

---

## Environment

- macOS, Homebrew Perl 5.42.0, NYTProf 6.14
- **Hardcoded tool paths — no PATH dependency:**
  - `perl`:         `/opt/homebrew/bin/perl`
  - `nytprofhtml`:  `/opt/homebrew/Cellar/perl/5.42.0/bin/nytprofhtml`
  - `nytprofcsv`:   `/opt/homebrew/Cellar/perl/5.42.0/bin/nytprofcsv`
  - `nytprofcalls`: `/opt/homebrew/Cellar/perl/5.42.0/bin/nytprofcalls`

**If Homebrew upgrades Perl:** update the `NYTPROFHTML` path in `run-profile.sh` and
paths above. The `/opt/homebrew/bin/perl` symlink updates automatically; the nytprof
tool paths in `/opt/homebrew/Cellar/perl/<version>/bin/` do not.
Verify: `/opt/homebrew/bin/perl -MDevel::NYTProf::Data -e 'print "ok\n"'`

---

## Directory Structure

```
tests/profile/
  run-profile.sh        Main entry point — runs ltl under NYTProf
  extract-profile.pl    Programmatic text extractor (no HTML parsing)
  samples/              Pre-truncated sample files (gitignored)
    <basename>-1k.log
    <basename>-10k.log
    <basename>-100k.log
  results/              All profiling output — DELIVERABLES, same protection as benchmarks
    <label>/
      <sample_size>/
        nytprof.out     Raw profile data
        nytprof/        HTML report (unless --no-html)
        verbose.txt     ltl -V output for cross-validation
        summary.txt     Text summary from extract-profile.pl
```

Results in `tests/profile/results/` follow the same protection policy as
`tests/baseline/results/` — they are deliverables and must never be overwritten
without `--force`.

---

## Profiling Best Practices

These are standing rules for every profiling session. No exceptions.

1. **Profile with intent.** Know what you are looking for before running. State a
   hypothesis. Example: "I expect `dice_coefficient` to dominate at 100k lines."
   If you don't have a hypothesis, read the `-V` verbose output from a regular run first.

2. **Start at the smallest sample size.** Use 1k lines first. Verify the behavior
   exists and locate it. Only scale up when you know what to look for.

3. **Compare across sample sizes.** If `excl_time` for `dice_coefficient` grows
   proportionally to line count, it's expected linear behavior. If it grows faster
   than linearly (e.g., 10x time for 10x lines), that's a signal worth investigating.

4. **Cross-validate against `-V` verbose output every time.** NYTProf call counts
   for hot functions must align with ltl's internal counters. This is not optional.
   See the Cross-Validation section below.

5. **Sort by `excl_time` for bottleneck hunting.** Inclusive time shows what's expensive
   including callees (useful for understanding the call tree). Exclusive time shows where
   the CPU is actually burning (useful for finding the real bottleneck).

6. **Check call counts, not just time.** `dice_coefficient` called 7,500 times at 0.09ms
   each is a very different problem than `read_and_process_logs` taking 4s total.
   A surprisingly high call count often reveals an unexpected recursion or hot loop.

7. **Never profile with files > 10 MB.** NYTProf adds ~4x overhead. A 277 MB file
   that runs in 15s normally takes 60s+ under the profiler. Use `--samples` to
   automatically truncate to 1k/10k/100k lines. Only add `full` to `--samples` after
   samples confirm you understand the behavior.

8. **Repeat surprising numbers.** NYTProf output can vary ±10% on small inputs due to
   OS scheduling. If a number looks surprising, run the same sample again before drawing
   conclusions.

---

## Sample-Size Strategy

The `--samples` option truncates input files to different line counts before profiling.
Each size serves a different purpose:

| Size   | Lines   | Typical wall time | Purpose |
|--------|---------|-------------------|---------|
| `1k`   | 1,000   | ~2s under profiler | Immediate feedback, locate the hot function |
| `10k`  | 10,000  | ~5-10s             | Detect O(N²) behavior before it's expensive |
| `100k` | 100,000 | ~30-60s            | Production-representative, validate scaling |
| `full` | all     | varies             | Only after samples confirm understanding |

Sample files are cached in `tests/profile/samples/` and reused across runs. They are
gitignored. If you need to refresh a sample (e.g., to use a different source file),
delete the cached file.

---

## Cross-Validation Against `-V` Output

ltl's `-V` (verbose) flag emits internal counters that must be reconciled with NYTProf
call counts. This is the most important check in any profiling session — it catches
over-calling bugs and accounting gaps that pure timing analysis misses.

### What `-V` emits

**BENCHMARK DATA block** (machine-parseable TSV between `=== BENCHMARK DATA ===` markers):
- `lines_read` — total lines processed
- `TIMING total` — wall time
- `MEMORY rss_peak` — peak RSS in bytes

**Consolidation summary** (when `-g` is active):
- `fc_calls` — total `find_candidates()` calls across all checkpoints
- S1 inline count — lines absorbed via inline matching during parsing
- S2 ceiling count — keys above occurrence ceiling (excluded from discovery)
- S3 checkpoint count — keys absorbed during checkpoint re-scanning
- S4 pairwise count — keys absorbed during pairwise discovery
- S5 unmatched count — keys that survived all stages

### What to check

| NYTProf metric | Should match ltl -V metric | Tolerance |
|---------------|---------------------------|-----------|
| `find_candidates` call count | `fc_calls` in consolidation summary | ≤5% |
| `match_against_patterns` call count | S1 inline count | ≤5% |
| `read_and_process_logs` call count | 1 (called once) | exact |
| `dice_coefficient` call count | Derived: `fc_calls × avg_candidates_per_call` | directional |

### When to investigate discrepancies

- `find_candidates` NYTProf count >> `fc_calls` from `-V`: function is being called from
  an unexpected code path (e.g., in a loop that should be bypassed).
- `match_against_patterns` count >> S1 inline count: patterns are being re-evaluated
  against keys that should have been absorbed already.
- `dice_coefficient` count growing super-linearly: trigram pre-filter is not effective
  enough, or candidate list is much larger than expected.

`extract-profile.pl --verbose-file verbose.txt` runs these checks automatically and
prints `[WARN]` for any discrepancy > 5%.

---

## Quick Start

```bash
cd /Users/gregeva/Documents/GitHub/logtimeline

# Standard run: 1k/10k/100k samples of a real log file
./tests/profile/run-profile.sh -- \
    --disable-progress \
    logs/AccessLogs/localhost_access_log.2025-03-21.txt

# With a label
./tests/profile/run-profile.sh --label issue-138 -- \
    --disable-progress \
    logs/AccessLogs/localhost_access_log.2025-03-21.txt

# Profile consolidation specifically
./tests/profile/run-profile.sh --label consolidation-debug -- \
    --disable-progress -g 85 \
    logs/AccessLogs/localhost_access_log.2025-03-21.txt

# Profile heatmap mode
./tests/profile/run-profile.sh --label heatmap -- \
    --disable-progress -hm \
    logs/AccessLogs/localhost_access_log.2025-03-21.txt

# Only 100k and full (skip 1k/10k after initial investigation)
./tests/profile/run-profile.sh --samples 100k,full --label scaling -- \
    --disable-progress -g 85 \
    logs/AccessLogs/localhost_access_log.2025-03-21.txt

# Single run, no sample truncation (use sparingly)
./tests/profile/run-profile.sh --no-samples --label single -- \
    --disable-progress \
    logs/ThingworxLogs/CustomThingworxLogs/ScriptLog.GetComplexPlotByIndex.log

# Re-extract from existing results with different options
/opt/homebrew/bin/perl tests/profile/extract-profile.pl \
    --file tests/profile/results/issue-138/10k/nytprof.out \
    --verbose-file tests/profile/results/issue-138/10k/verbose.txt \
    --sort excl --top 40

# Focus on consolidation functions
/opt/homebrew/bin/perl tests/profile/extract-profile.pl \
    --file tests/profile/results/issue-138/100k/nytprof.out \
    --match "consolidat|dice|candidate|checkpoint" \
    --verbose-file tests/profile/results/issue-138/100k/verbose.txt

# Line-level hotspots for a specific sub
/opt/homebrew/bin/perl tests/profile/extract-profile.pl \
    --file tests/profile/results/issue-138/100k/nytprof.out \
    --lines dice_coefficient
```

---

## Example Output

```
====================================================================================================
Profile:  tests/profile/results/issue-138/10k/nytprof.out
Script:   /Users/gregeva/Documents/GitHub/logtimeline/ltl
Perl:     5.42.0
CPU time: 3.8421 s (sum of exclusive times)
Subs:     25 shown of 87 matching (from 143 total)
Sort:     incl time | Filter: Perl subs only
ltl -V:   lines_read=10000  total=1.234s  rss=48 MB
====================================================================================================

Rank  Subroutine                                              Calls     Incl(s)   Excl(s)  ms/call  %Tot
----------------------------------------------------------------------------------------------------
   1  read_and_process_logs                                       1   2.1234    0.0120   2123.4   55.2
   2  calculate_all_statistics                                    1   0.9876    0.0080    987.6   25.7
   3  match_against_patterns                                   2140   0.4320    0.4320      0.202  11.2
   4  dice_coefficient                                         1250   0.1820    0.1820      0.146   4.7
   5  find_candidates                                           430   0.0980    0.0340      0.228   2.6
   ...

Note: %Tot = incl_time / 3.8421 s (total Perl CPU time)
      Use --sort excl to rank by exclusive time

====================================================================================================
Cross-Validation: NYTProf call counts vs ltl -V output
----------------------------------------------------------------------------------------------------
  find_candidates:        NYTProf=    430  ltl-V=    428  diff=+0.5%  [OK]
  match/inline vs S1:     NYTProf=   2140  ltl-V=   2138  diff=+0.1%  [OK]
  read_and_process_logs:  NYTProf calls=1  ltl-V lines_read=10000

  [OK] All cross-validation checks within 5% tolerance.
```

---

## `extract-profile.pl` Options Reference

| Option | Description | Default |
|--------|-------------|---------|
| `--file <path>` | Path to nytprof.out | `./nytprof.out` |
| `--top N` | Show top N subroutines | 25 |
| `--sort incl\|excl` | Sort by inclusive or exclusive time | `incl` |
| `--all` | Include XSubs `[xs]` and opcodes `[op]` | Perl only |
| `--package <pkg>` | Filter to specific package | (none) |
| `--match <pattern>` | Regex filter on subroutine name | (none) |
| `--lines <subname>` | Show line-level hotspots for a sub | (none) |
| `--verbose-file <path>` | Parse ltl -V output for cross-validation | (none) |

---

## What NOT to Do

- **Do not parse HTML.** `extract-profile.pl` uses `Devel::NYTProf::Data` directly.
  Never open `nytprof/index.html` or parse it with scripts — it is slow, fragile, and
  the API gives you everything you need.

- **Do not assume nytprofhtml is in PATH.** It is not symlinked to `/opt/homebrew/bin`.
  Always use the full path: `/opt/homebrew/Cellar/perl/5.42.0/bin/nytprofhtml`.

- **Do not write nytprof.out to the project root.** `run-profile.sh` handles this by
  `cd`-ing to the output directory before running perl. Never run `perl -d:NYTProf ltl`
  from the project root — the `nytprof.out` there is a stub.

- **Do not use nytprofcsv for subroutine data.** `nytprofcsv` generates per-line data
  in CSV format, not per-subroutine summaries. Use `Devel::NYTProf::Data` API instead.

- **Do not profile with large files.** Files > 10 MB incur prohibitive NYTProf overhead.
  Use `--samples` to truncate to 1k/10k/100k lines. Only use `full` after samples show
  you understand the behavior.

- **Do not skip cross-validation.** Always pass `--verbose-file` to `extract-profile.pl`.
  Skipping it leaves potential over-calling bugs undetected.

---

## NYTProf Data API Quick Reference

```perl
use Devel::NYTProf::Data;

my $profile = Devel::NYTProf::Data->new({ filename => 'nytprof.out', quiet => 1 });

# All subroutines as a hash: name => SubInfo object
my %subs = %{ $profile->subname_subinfo_map };

# SubInfo methods (Devel::NYTProf::SubInfo):
$si->subname      # Full name: 'main::dice_coefficient'
$si->package      # Package: 'main'
$si->calls        # Call count
$si->incl_time    # Inclusive time (s) — includes time in callees
$si->excl_time    # Exclusive time (s) — time in this sub only
$si->kind         # 'sub', 'xsub', 'opcode'
$si->is_xsub      # Boolean
$si->is_opcode    # Boolean
$si->first_line   # First line number in source
$si->last_line    # Last line number in source
$si->fid          # File ID (for line_time_data lookup)
$si->fileinfo     # Devel::NYTProf::FileInfo object

# Line-level data for a subroutine
my $fi   = $si->fileinfo;
my $fid  = $si->fid;
my $data = $fi->line_time_data([$fid]);
# $data->[$lineno] = [$count, $time_seconds]

# Profile metadata
my $attrs = $profile->attributes;
# Keys: application, perl_version, profiler_duration, profiler_start_time
```

---

## Understanding the Numbers

**Inclusive time (`Incl(s)`):** Time spent in this subroutine *plus all its callees*.
Use for understanding the call tree and finding which top-level operations dominate.

**Exclusive time (`Excl(s)`):** Time spent *only* in this subroutine, not in callees.
Use for finding where CPU is actually burning. Sort by this when hunting bottlenecks.

**`%Tot`:** `incl_time / sum(all excl_times)`. This is relative to total measurable Perl
CPU time (the sum of all exclusive times). It is *not* relative to wall-clock time — Perl
startup, I/O wait, and OS overhead are not included.

**Call count as signal:** A function with 100K calls at 0.001ms each (total 0.1s) is often
more actionable than a function with 1 call at 0.1s — the former usually has a fix
(e.g., caching, pre-filtering) while the latter may simply be unavoidable work.

**NYTProf overhead:** NYTProf adds approximately 4x overhead to Perl execution. This is
why sample sizes are critical. Absolute times under profiling are not representative
of production performance — use them for relative comparisons only.
