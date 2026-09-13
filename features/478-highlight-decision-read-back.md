# Highlight decision read-back (Issue #478)

## Status

Specified, not implemented. The issue was reframed on 2026-09-13 from a
performance bug into a convergence fix; the performance premise is recorded
below as refuted, with the measurements.

---

## The reframe

**Old framing.** The issue was filed as "BUG: highlight bookkeeping is evaluated
on the hot path when no highlight is active and when the metric is absent". It
asserted two missing gates: an activation gate (highlight work running on runs
with no highlight criterion) and a relevance gate (the bytes highlight
accumulation running on lines carrying no bytes value). It costed the defect at
roughly 2.0 seconds on a 1.43M-line access log, about 12 percent of runtime,
citing three lines from the line-level profile captured under #432 (metric and
aggregate naming alignment, and bytes metric parity).

**What was measured.** Both gates the old title named already exist in the code
and worked when the issue was filed.

- The activation gate is `$highlight_active`, resolved once in
  `adapt_to_command_line_options()` and leading the tag-point condition in
  `read_and_process_logs()`. On a run with no highlight, one falsy scalar read
  short-circuits the whole predicate. This is the hot-loop discipline locked by
  `features/312-numeric-criteria-highlight-selection.md` § Design.
- The relevance gate on bytes exists twice over: the site sits inside
  `if( $bytes_observed_line && !$omit_bytes )` and then inside `if( $bytes )`.
  Measured on the reference access log, the bytes site fires on 7,549 of 20,000
  lines, not on all of them. Duration is gated by
  `if( $duration_observed && !$omit_durations && $duration >= 0 )` and count by
  `if( defined $count )`.
- The cost does not reproduce. An A/B against a probe build with every in-loop
  suffix regex replaced by a scalar flag measured about **0.08 seconds on 16.5
  seconds, roughly 0.5 percent**, inside the run-to-run spread; an independent
  second pass gave about 0.07 seconds on 16.3 seconds. The arithmetic ceiling
  from isolated per-operation cost is about 0.04 seconds. Wall-clock on a
  machine running other work concurrently, so the timings are indicative; the
  order of magnitude is the point, and 2.0 seconds would have been unmissable.

**Why the framing changed.** One thing the old issue observed is real and
survives: the tag point computes the highlight decision correctly and then keeps
no boolean, encoding the answer only by appending `-HL` to `$category_bucket`.
Thirteen sites inside the same loop then re-derive it with
`$category_bucket =~ /-HL$/`. That is one vocabulary with two resolution
surfaces inside one sub, which is the convergence defect CLAUDE.md § Before
writing or changing code names, and it stands without any performance claim.
Shipping the cleanup under a "12 percent faster" heading would be false, so the
title, the branch name and the cross-references are trued up in the same action
per `docs/process/issues.md` § Reframing. The sweep list is at the end of this
document.

---

## 1. The motivating consumer

The consumer is the next person editing `read_and_process_logs()` and adding a
highlight-aware accumulation, which has happened three times in recent memory:
#312 (numeric criteria as highlight and selection) built the tag point, #455
(filter and highlight criteria for success and failure) added two criteria to
it, and #534 (highlight the lines contributed by a specific input file) would
add a sixth. Each such author must today discover, by reading, that "is this
line highlighted" is answered by a regular expression against a string that was
built elsewhere in the same sub, and must reproduce that regular expression
correctly, including its `$` anchor, at every new site.

The loop already contains the answer to what that author should write. The
histogram capture block hoists the decision once:

```perl
if ($histogram_enabled) {
    my $is_highlighted = ($category_bucket =~ /-HL$/);
```

and then reads the scalar eight times below it (`push
@{$histogram_values_hl{duration}}, $duration if $is_highlighted;` and its
siblings). One block of nine does it right. This change generalises that local
idiom to the whole loop: the decision is computed at the tag point that already
computes it, kept in a per-line boolean, and read everywhere else.

There is no user-observable change. Nothing renders differently, no option
changes, no `-V` section changes, no data model or key shape changes.

---

## 2. Requirement

Inside `read_and_process_logs()`, "is this line highlighted" has exactly one
resolution surface: the tag-point predicate. Every in-loop consumer of that
answer reads the value the tag point recorded, rather than re-deriving it from
the `-HL` suffix on `$category_bucket`.

The `-HL` suffix itself remains the storage and rendering carrier. It is not
replaced.

---

## 3. Corrections to the issue body

All nine, each with what was measured.

1. **"No activation gate. The work appears to run regardless of whether any
   highlight criterion was supplied."** False. `$highlight_active` is resolved
   once in `adapt_to_command_line_options()` and leads the tag-point condition,
   short-circuiting the entire predicate on a non-highlighted run.
2. **"The bytes highlight accumulation is evaluated on lines where bytes is
   undefined."** False. Doubly gated by `$bytes_observed_line && !$omit_bytes`,
   then `if( $bytes )`. Measured: fires on 7,549 of 20,000 lines of the
   reference access log. The cited `analysis.md` states the same thing one
   paragraph above the table the issue quotes ("Only 36,409 of 100,000 lines
   carry a bytes value on this corpus, so the guards skip 64% of lines").
3. **"roughly 2.0 seconds on a 1.43M-line access log, about 12% of total
   runtime."** Does not reproduce. Measured about 0.08 s on 16.5 s, roughly 0.5
   percent, against a probe build replacing every in-loop suffix regex with a
   scalar flag; re-measured independently at about 0.07 s on 16.3 s. The
   arithmetic ceiling from isolated per-operation cost is about 0.24 percent.
   The filed figure is 25 to 50 times high.
4. **"three times per line; the pattern is a constant."** Not a constant. An
   instrumented build counting executions per site measured **1.38 per line** on
   the reference access log under the profiled options: the duration site on
   every line plus the bytes site on 38 percent of them. The maximum reached on
   any corpus and option set tried was **7 per line**, not 13, and it is not
   monotonic in feature count: adding `-hm duration -hg duration` to the access
   log *removed* a site, because it changed the resolved bucket-statistics
   demand and took the run off the `-bdm bin` path. A feature-rich A/B measured
   the same 0.4 percent.
5. **The three cited line numbers are from the #432 branch and have drifted.**
   The file is now about 21,060 lines. The sites are referenced in this document
   by their enclosing block inside `read_and_process_logs()` plus a snippet, per
   `docs/process/issues.md` § Where things are recorded.
6. **The "most expensive line" is a misattribution, not a cost.** The cited
   `$log_level =~ s/-HL$//` substitution **matched zero times in 20,000 lines**
   of the profiled access-log corpus, because `$log_level = $status_code > 0 ?
   $status_code : $category_bucket` and a status code can never carry the
   suffix. Its profiled cost is the scalar copy and the ternary sharing the
   statement. A probe that gated it measured no improvement at all. The same is
   structurally true of the other two cited lines: each carries a hash-element
   autovivify-and-add, which is the expensive half, and the profiler charged the
   whole statement to the guard.
7. **"the workflow this must use" is not runnable on this machine.**
   `Devel::NYTProf` is not installed for the current Perl 5.44, and no
   `nytprofcsv` binary exists under any Homebrew Cellar Perl; the 5.42.0 Cellar
   directory still exists, so the remediation is a module reinstall and a re-pin
   of `features/nytprof-profiling-workflow.md` § Environment, not a Perl version
   restoration. This investigation substituted an in-place A/B, which the #432
   analysis itself concluded is the better instrument for a change of this size.
   Recorded here as a finding to be filed separately; see § Out of scope.
8. **The sequencing note is satisfied.** #455 (filter and highlight criteria for
   success and failure) has landed, and `$outcome_highlight_active` with
   `-hf`/`-hs` is in the tag-point condition today. No blocker remains from that
   quarter; the one blocker this issue does carry is #472, recorded in
   § Ordering and blocking.
9. **`tests/profile/samples/` does not exist in this worktree.** It is gitignored
   and was never materialised here; any profiling step must regenerate it.

Two further corrections to the investigation that produced the reframe, recorded
so the numbers in this document are not re-derived wrongly later:

- **The in-loop site count is 13, not 19.** The higher count treated the
  histogram block's eight `$is_highlighted` scalar reads as regex sites, when
  those are already the fixed form.
- **`$category` is not a third resolution surface.** The tag point sets it to
  `'highlight'` or `'plain'`, but all 28 in-loop uses are hash subscripts
  (`$log_messages{$category}{$log_key}`,
  `$threadpool_activity{$category}{$threadpool}{$thread}`). It is never
  compared, tested or branched on. There are two surfaces, not three.

---

## 4. The mechanism today

### The tag point

One site in `read_and_process_logs()`, under the comment beginning "determine if
this line should be highlighted", computes the decision and records it in two
places, neither of them a boolean:

```perl
if( $highlight_active
    && ( !defined( $highlight_filter ) || match_filter($_, $highlight_filter) )
    && ( !$outcome_highlight_active || ( ... ) )
    && ( !$numeric_highlight_active || ( ... ) ) ) {
    $category_bucket .= '-HL';
    $category = 'highlight';
    $in_files_matched{$in_file} = 2 unless $in_files_matched{$in_file} == 2;
} else {
    $category = 'plain';
}
```

### The thirteen read-back sites

All thirteen sit below the tag point in the same sub, in the same iteration of
the per-line loop. Listed by enclosing block.

| # | Enclosing block | Snippet |
|---|---|---|
| 1 | Duration totals, inside `if( $duration_observed && !$omit_durations && $duration >= 0 )` | `$log_analysis{$bucket}{'total_duration-HL'} += $duration if $category_bucket =~ /-HL$/;` |
| 2 | Per-bucket bin-counter feed, inside `if ($bucket_stats_capture_mode eq 'bin')` | `counter_update(\%bucket_stats_counters_hl, $bucket, $duration, $bucket_stats_buckets_per_decade) if $duration > 0 && $category_bucket =~ /-HL$/;   # store parity only` |
| 3 | Bytes totals, inside `if( $bytes_observed_line && !$omit_bytes )` then `if( $bytes )` | `$e->{'total_bytes-HL'} += $bytes if $category_bucket =~ /-HL$/;` |
| 4 | Count totals, inside `if( defined $count )` | `$log_analysis{$bucket}{'count_sum-HL'} += $count if $category_bucket =~ /-HL$/;` |
| 5 | Count totals, same block | `$log_analysis{$bucket}{'count_occurrences-HL'}++ if $category_bucket =~ /-HL$/;` |
| 6 | User-defined metric storage, counting aggregations arm | `if ($category_bucket =~ /-HL$/) { $log_analysis{$bucket}{"udm_${name}_occurrences-HL"}++; ... }` |
| 7 | User-defined metric storage, numeric aggregations arm | `if ($category_bucket =~ /-HL$/) { $log_analysis{$bucket}{"udm_${name}_sum-HL"} += $value; ... }` |
| 8 | Heatmap raw value capture, raw arm | `push @{$heatmap_raw_hl{$bucket}}, $heatmap_value if $category_bucket =~ /-HL$/;` |
| 9 | Heatmap raw value capture, counter arm | `counter_update(\%heatmap_counters_hl, $bucket, $heatmap_value, $heatmap_stream_bpd) if $category_bucket =~ /-HL$/;` |
| 10 | Histogram raw value capture, block entry | `my $is_highlighted = ($category_bucket =~ /-HL$/);` |
| 11 | Thread and thread pool statistics capture | `if( $category_bucket =~ /-HL$/ ) { $log_threadpools{$bucket}{$threadpool}{highlight}{$thread} += 1; }` |
| 12 | Session statistics capture | `if( $category_bucket =~ /-HL$/ ) { $log_sessions{$bucket}{highlight}{$session} += 1; }` |
| 13 | User statistics capture | `if( $category_bucket =~ /-HL$/ ) { $log_users{$bucket}{highlight}{$user} += 1; }` |

Reproduce the count with `awk 'NR>=<sub start>,NR<=<sub end>' ltl | grep -c --
'=~ */-HL\$/'` after locating `sub read_and_process_logs` and the next `^sub`.

### The histogram exception

Site 10 is the exception and the model. It is the only one of the thirteen that
does not re-derive the decision at the point of use: it hoists it into
`my $is_highlighted` at the entry to the histogram block and reads the scalar
eight times below. Those eight reads are already correct and are not part of the
thirteen. After this change site 10 disappears as a computation: the block reads
the loop-level boolean directly, or keeps a local alias to it, and its eight
downstream reads are untouched.

### What stays

- **The message-path substitution** `$log_level =~ s/-HL$//`, inside
  `if( $capture_messages && defined( $message ) )`. This is not a re-derivation:
  it is a load-bearing display transform at the seam where the storage
  vocabulary must be undone before the value becomes a message key. Commenting
  it out regresses the TOP MESSAGES block from `[WARN]` to `[WARN-HL]` on five
  rows of a ThingWorx slice. It also does no work on the corpus the whole
  measurement rests on: it matched zero times in 20,000 lines of the reference
  access log, so it cannot be the source of a saving.
- **The four suffix tests outside the loop**, in `normalize_data_for_output()`,
  in `print_bar_graph()`, and in the bar-fill colour selection. Each iterates
  over category keys, where the `-HL` suffix on the key is the only carrier
  available; there is no per-line boolean in scope to read.
- **The `-HL` carrier itself.** See D5.

---

## 5. Decisions

### D1 — Scope is the thirteen in-loop read-back sites, and nothing else

**Decided.** Replace each of the thirteen `$category_bucket =~ /-HL$/` tests
inside `read_and_process_logs()` with a read of a per-line boolean set at the
tag point. Nothing else in the loop changes; no block is restructured; no key,
store or rendered surface changes.

**After #472 lands the count is twelve.** #472 (the highlight bin-counter
sub-stores are absent from the `-V` telemetry, so a highlighted run
under-reports its own partitions and memory) retires `%bucket_stats_counters_hl`
under its D2 and deletes site 2, the `counter_update(\%bucket_stats_counters_hl,
…)` call annotated `# store parity only`. This issue lands after #472 (see
§ Ordering and blocking), so the implementation edits **twelve** sites and site
2 is gone before it starts. Both counts are stated here because the thirteen is
what the code carries today and what a reader auditing the current file will
count.

**Reason.** The one-resolution-surface rule applies to the sites that resolve
the same vocabulary twice. The other candidates do not: see D2 and D3.

### D2 — The message-path substitution stays

**Decided.** `$log_level =~ s/-HL$//` is untouched.

**Reason.** It is load-bearing, not redundant: removing it corrupts TOP MESSAGES
rows to `WARN-HL`. It is a different operation from the thirteen (undoing the
carrier on a derived value, not answering "is this line highlighted"), and
restructuring the message path to build the key from an unsuffixed lexical would
touch message-key construction, which `tests/validate-csv-output.sh` and the
consolidation harness read, for a measured gain of zero.

### D3 — The four post-loop suffix tests stay

**Decided.** The suffix tests in `normalize_data_for_output()`, in
`print_bar_graph()` and in the bar-fill colour selection are untouched.

**Reason.** They are not read-backs of a per-line decision. They iterate over
category keys after the loop has ended, where the suffix on the key is the only
carrier of the distinction and no per-line boolean exists or could exist.

### D4 — No outer `if ($highlight_active)` wrapping

**Decided.** The highlight blocks are not wrapped in an outer activation test.

**Reason.** The activation gate already exists at the tag point, so on a
non-highlighted run the boolean is false and each site pays one falsy scalar
read. Wrapping would buy tens of milliseconds, below the measured noise floor,
at the cost of restructuring blocks where the plain and highlight feeds alternate
statement by statement (the count block and both user-defined-metric arms are
the clearest cases). That is the largest restructuring of the options for the
smallest measured return.

### D5 — The `-HL` carrier is not replaced

**Decided.** `$category_bucket .= '-HL'` stays as the storage and rendering
carrier. This change alters only how the decision is read back inside the loop.

**Reason.** `-HL` is shared vocabulary reaching the colour table, the category
bucket display order, the STATS CSV column names and the aggregate export.
Replacing it (for instance moving to
`{$bucket}{$category_bucket}{plain|highlight}`) would reopen the core mechanism
locked by `features/312-numeric-criteria-highlight-selection.md` § Design, for a
measured 0.24 percent ceiling.

### D6 — The boolean is a new per-line lexical named `$line_is_highlighted`

**Decided.** A new lexical, set in both arms of the tag point:

```perl
    $category_bucket .= '-HL';
    $category = 'highlight';
    $line_is_highlighted = 1;
    ...
} else {
    $category = 'plain';
    $line_is_highlighted = 0;
}
```

Both arms assign, so the value is never stale from the previous line; that is
the property the whole change rests on, and a single-arm assignment would be a
correctness bug rather than an optimisation.

**Reason for a new variable rather than reusing `$category`.** `$category`
already exists and is set in both arms, but it is a hash key, never a tested
value; testing it would make every site a string compare (`eq 'highlight'`)
where a scalar truth test suffices, and would give one variable two roles. A
boolean keeps the partition key and the decision as separate things.

**Reason for the name.** `$line_is_highlighted` generalises the
`my $is_highlighted` the histogram block already uses, which is the established
local idiom, while the `line_` prefix marks it as loop-scoped per-line state
rather than a block-local alias, and keeps it distinct from `$highlight_active`
(run-scoped: was any criterion supplied at all).

### D7 — The correctness argument

**Decided and verified.** A boolean hoisted at the tag point is equivalent to the
live string test at each of the thirteen sites, because `$category_bucket` is
never reassigned between the tag point and the last suffix test.

Within `read_and_process_logs()` the only writes to `$category_bucket` are:

- the two `$category_bucket = "DATA"` assignments on the CSV data paths, both
  far above the tag point; and
- the `.= '-HL'` at the tag point itself.

Nothing reassigns it afterwards, and all thirteen sites sit below the tag point
in the same loop iteration. The substitution is therefore value-preserving at
every site. Re-verify this by grepping for assignments to `$category_bucket`
within the sub before the first edit; if a new assignment has appeared below the
tag point, this argument is void and the change must stop.

### D8 — No new assertion of a new kind; the coverage gap is closed by #472

**Decided.** This change adds no harness and no `-V` field. See § Harness plan
for the full reasoning and for the dependency on #472's scenarios.

---

## 6. Surfaces touched

| Surface | Change |
|---|---|
| `read_and_process_logs()`, the tag point | One assignment added in each arm, setting `$line_is_highlighted`. |
| `read_and_process_logs()`, twelve read-back sites (thirteen before #472 retires one) | `$category_bucket =~ /-HL$/` becomes `$line_is_highlighted`. |
| `read_and_process_logs()`, the histogram capture block | `my $is_highlighted = ($category_bucket =~ /-HL$/);` becomes a read of the loop-level boolean; its eight downstream reads are untouched. |
| `## GLOBALS ##` | Nothing. The boolean is a lexical in the read loop, declared with the other per-line lexicals, not a package global. |

Not touched: every `-V` section; `--help`; `docs/usage.md`; `docs/explain/`; any
key shape, store, colour table, category order, STATS CSV column or aggregate
export field; the message path; the four post-loop suffix tests; any harness
file.

---

## 7. Harness plan

**No new harness, and no new assertion of a new kind.**

- **No source-text harness.** A check asserting that no `=~ /-HL$/` appears
  inside `read_and_process_logs()` would be the only harness in the repository
  that reads `ltl`'s source text: `tests/HARNESS-DESIGN.md` records no such
  precedent, every harness consumes `-V` sections or rendered output, and its one
  grep example targets a produced artifact. It would also have to pin a line
  range that drifts, and this sub has moved about 3,600 lines since the issue was
  filed.
- **No `-V` counter of highlight-site evaluations.** Self-defeating: it would add
  a per-line counter to the hot path costing more than the change saves.
- **The proof is the existing coverage.** The change is behaviour-neutral by
  construction (D7), so the gate is that everything already asserting highlight
  behaviour keeps passing. Eleven harnesses reference the highlight surface today:
  `tests/validate-aggregate-export.sh`, `tests/validate-category-names.sh`,
  `tests/validate-csv-output.sh`, `tests/validate-filter-summary.sh`,
  `tests/validate-explain.sh`, `tests/validate-outcome-criteria.sh`,
  `tests/validate-regression.sh`, `tests/validate-numeric-criteria-notices.sh`,
  `tests/validate-summary-contribution-bar.sh`, `tests/validate-udm-counting.sh`
  and `tests/validate-runtime-config.sh`. Together with the regression baselines
  in `tests/validate-regression.sh`, which compare rendered output byte for byte
  against blessed captures, these cover the rendered and CSV consequences of
  every one of the thirteen sites except one.

**The one gap, and why it is #472's to close.** Site 2, the
`%bucket_stats_counters_hl` feed, requires `-bdm bin` **and** an active highlight
to execute. No harness runs that combination today:
`tests/validate-histogram-bin-counters.sh`, which owns the bin-counter
substrate, sets no highlight at all. A change that mis-wired that one guard would
ship green.

#472's D10 adds exactly that combination: two arms of one invocation differing
only in the highlight flag, under the bin data model, asserting the highlight
blocks' `partition_count`, `counter_memory_bytes` and `path` values on the
highlighted arm and `path: feature_not_active` on the other. **This issue relies
on those scenarios for coverage of the bin path under an active highlight**, and
that reliance is one of the two reasons for the ordering in the next section.
Note the interaction: #472's D2 also *retires* site 2, so after #472 the site
this change would otherwise have to prove is gone, and the new scenarios cover
the neighbouring highlight bin stores (`%heatmap_counters_hl`,
`%histogram_counters_hl`) that sites 9 and 10 feed.

Every harness that invokes `ltl` already includes the runtime-warning check
(`tests/lib/runtime-warnings.sh`), so a stray `Use of uninitialized value
$line_is_highlighted` from a missed arm surfaces as a failure rather than as
noise on stderr. That is the single most likely implementation error this change
could make, and it is already covered.

---

## Acceptance criteria

Triaged per `docs/test-driven-development.md`.

**Assertable**

- [ ] All eleven harnesses that reference the highlight surface exit 0 with
      assertions actually run, unchanged from the base commit.
      *Method: the full harness suite at the completion gate; the eleven are
      named in § Harness plan.*
- [ ] The regression baselines in `tests/validate-regression.sh` match byte for
      byte, with no baseline re-blessed. A re-blessed baseline on this change is
      a behaviour change and therefore a defect.
      *Method: `CI=1 ./tests/validate-regression.sh`, captured once to the
      scratchpad and inspected there.*
- [ ] The STATS CSV comparison in `tests/validate-csv-output.sh` shows no cell
      change, including every `-HL` column.
      *Method: `CI=1 ./tests/validate-csv-output.sh` before
      `CI=1 ./tests/validate-statistics.sh`, per the shared-cache ordering.*
- [ ] `ltl`'s stderr carries no ` at <file> line <N>` runtime warning on any
      harness run, in particular no uninitialized-value warning naming the new
      boolean.
      *Method: `tests/lib/runtime-warnings.sh`, already included by every
      harness that invokes `ltl`.*
- [ ] Under `-bdm bin` with an active highlight, the highlight bin-counter
      blocks report the same `partition_count` and `counter_memory_bytes` as on
      the base commit.
      *Method: #472's `highlight-blocks-active` scenario in
      `tests/validate-histogram-bin-counters.sh`. This criterion is not
      assertable before #472 lands, which is why #478 is blocked by it.*
- [ ] No occurrence of `=~ /-HL$/` remains between the tag point and the end of
      the per-line loop in `read_and_process_logs()`.
      *Method: manual grep at review time (`grep -c -- '=~ */-HL\$/'` over the
      sub's line range), not a harness. Stated as a review check rather than an
      automated assertion for the reasons in § Harness plan.*

**Unassertable**

- [ ] The change is faster, or not slower, than the base commit. The measured
      effect is about 0.5 percent on a 16.5-second run, which is inside the
      run-to-run spread on this machine, so no benchmark run can assert it
      either way. The completion-gate benchmark is run because the scope table
      requires it for a change to executable `ltl` lines, and its expected and
      acceptable reading is "no measurable change"; see § Completion gate.
- [ ] A future edit does not reintroduce a second resolution surface. Nothing
      mechanical prevents it: the source-text check that would is ruled out in
      § Harness plan. The mitigation is this document plus the pointer added to
      `features/312-numeric-criteria-highlight-selection.md`.

**Unknown**

None. No criterion here needs a verification method that does not exist, so no
prototyping scope arises from the triage. Checked against
`prototype/README.md`'s four triggers: no new or changed data model (D5), no new
per-line cost (one assignment replaces one regex per line, and the sites are
reads either way), no high frequency times high cost, and no unknown
verification method.

---

## Completion gate

Scope per `docs/process/workflow.md` § 3. The diff changes executable lines of
`ltl` and nothing else, so the first row of the scope table applies and both
columns are required.

- **Full harness suite required.** Every `tests/validate-*.sh` exits 0 with
  assertions actually run; `CI=1 ./tests/validate-csv-output.sh` before
  `CI=1 ./tests/validate-statistics.sh` for the shared cache, then the rest, each
  captured once to the scratchpad and inspected there. **The behaviour this
  change could have altered**, which is what the suite is being run to disprove:
  the highlighted subset of every per-bucket accumulation (duration, bytes,
  count, every user-defined metric), the highlighted heatmap and histogram
  captures, and the highlighted thread-pool, session and user tallies. Every one
  of those reaches a rendered or CSV surface an existing harness reads.
- **Before/after benchmark required**, run on this machine in this session with
  `$version_number` restored to `X.Y.Z` before the `after` capture.

**Which benchmark selection.** `single-day-access-log-heatmap-histogram`.

*Reason.* The default `standard` scenario on the reference access log exercises
only two of the thirteen sites: duration on every line and bytes on 38 percent
of them. A gate on a two-site configuration reports noise by construction, which
is a defensible outcome but should be chosen rather than discovered. Adding
`-hm -hg` brings the heatmap capture (sites 8 and 9) and the histogram capture
(site 10) onto the path, taking the measurement to the widest per-line site
count this benchmark's cases can reach without a format carrying sessions, users
or user-defined metrics. Note the instrumented measurement that `-hm -hg` also
*removes* the bin-path site by changing the resolved bucket-statistics demand;
that site is #472's to delete regardless.

```bash
./tests/baseline/run-benchmark.sh single-day-access-log-heatmap-histogram --label 478-before   # on the base commit
./tests/baseline/run-benchmark.sh single-day-access-log-heatmap-histogram --label 478-after
./tests/baseline/compare-results.sh summary \
    tests/baseline/results/478-before.tsv tests/baseline/results/478-after.tsv
```

**What the benchmark is expected to show.** No measurable change: the delta sits
inside the run-to-run spread on every metric, and nothing is worse by more than
5 percent. The benchmark case runs no highlight flag, so every site evaluates
the false branch in both arms, which is precisely the non-highlighted run the
change makes cheapest and the noise floor makes invisible. This expectation is
recorded in advance so that a null result reads as the gate passing rather than
as the change failing to deliver. Both TSVs are deleted afterwards.

**No release-notes bullet.** There is no user-observable change: no option, no
rendered output, no CSV column, no `-V` field, no notice. CLAUDE.md restricts
release-notes bullets to user-observable change.

---

## Ordering and blocking

**#478 is blocked by #472** (the highlight bin-counter sub-stores are absent from
the `-V` telemetry, so a highlighted run under-reports its own partitions and
memory). The native edge is wanted; it is created with:

```bash
BLOCKER_ID=$(gh api repos/{owner}/{repo}/issues/472 --jq '.id')
gh api --method POST repos/{owner}/{repo}/issues/478/dependencies/blocked_by -F issue_id="$BLOCKER_ID"
```

and the issue body carries an agreeing `Blocked by #472 (…)` line, per
`docs/process/issues.md` § Blocking relationships. Both must exist and agree.

**Reason, against the dependency-first test.** This issue cannot proceed to a
clean implementation before #472 lands, for two reasons that run the same way:

1. **#472 deletes one of the thirteen sites.** Its D2 retires
   `%bucket_stats_counters_hl` and removes the `counter_update(…)` call annotated
   `# store parity only`. Doing #478 first would convert a line that #472 then
   deletes, and would plan a read-back around a store that is going away.
2. **#472 adds the only harness coverage of the bin path under an active
   highlight.** Its D10 scenarios are what makes the fifth acceptance criterion
   above assertable at all; without them, site 2's neighbourhood is unasserted
   and a mis-wired guard ships green.

The collision itself is only a textual merge conflict on one line and would not
on its own justify an edge; the coverage dependency does.

**Nothing else blocks.** #455 (filter and highlight criteria for success and
failure) has landed and its sequencing note is satisfied. #528, #527, #482 and
#476 show no interaction with the highlight surface, the `-HL` vocabulary or the
tag point, though their contents were not audited beyond that; re-check before
scheduling any of them alongside.

**#342 (identify redundant logic surfaces across `ltl` that must converge).**
This issue is a worked instance of exactly what that audit is for: one vocabulary
("is this line highlighted") with two resolution surfaces in a single sub, where
one block of nine already shows the converged form. It is recorded here as a
worked example for that audit, not absorbed into it: the fix is thirteen
single-line edits with a proven equivalence argument, and there is no reason to
hold it for a sweep. The pointer onto #342 is posted separately.

---

## Out of scope

**The NYTProf toolchain repair is not part of this issue.** The diagnosis, for
whoever files it: `Devel::NYTProf` is not installed for the current Perl 5.44;
no `nytprofcsv` binary exists under any Homebrew Cellar Perl, although the
5.42.0 Cellar directory itself still exists; and
`features/nytprof-profiling-workflow.md` § Environment pins 5.42.0, while the
#432 analysis already recorded drift to 5.42.2. The remediation is a module
reinstall under the current Perl and a re-pin of the workflow doc, not a Perl
version restoration. It blocks nothing here (this investigation used an in-place
A/B, which the #432 analysis itself concluded is the better instrument at this
scale) but it blocks every future line-level profiling task in the repository.
Recorded as a finding to be filed separately by the architect; deliberately not
filed from this issue, because folding it in would be the scope creep the #432
analysis refused.

---

## The reframe sweep

Every artifact carrying the old framing, per `docs/process/issues.md`
§ Reframing.

| Artifact | State |
|---|---|
| Issue #478 title | Done on GitHub: now "BUG: the highlight decision is re-derived from the -HL category suffix throughout the read loop instead of kept once at the tag point". |
| Issue #478 body | Replacement body drafted for the architect to apply; it drops both refuted gate claims and the 12 percent figure, and carries the `Blocked by #472` line. |
| Branch name | Done: renamed to follow the new title. |
| `features/478-highlight-decision-read-back.md` | This document. |
| `features/312-numeric-criteria-highlight-selection.md` § Design | Dated note added pointing at this document, so the owner of the `-HL` mechanism records where the read-back surface is specified. |
| `tests/profile/results/432-bytes-parity-capture/analysis.md` | Dated amendment appended, original text intact (a committed deliverable under the never-overwrite rule): the corrected figure, the attribution error, and the substitution that never matched. |
| `features/432-metric-aggregate-naming-parity.md` § "Raised, not fixed here" | Carries the old title and the 2.0 s / 12 percent figure. Left for a follow-up decision by the architect: it is a delivered issue's record of what was observed at the time, and the amended `analysis.md` it points at now carries the correction. Flagged rather than edited. |
| `features/418-unsatisfiable-sort-selection-cost.md` | Two references to "#478 (highlight bookkeeping on the hot path)" as an anti-pattern D4 avoids. The anti-pattern reasoning there stands on its own (a per-line package-global read-compare-write measured at about 1.5 percent under #432), so only the parenthesised context is stale. Flagged, not edited: it is a delivered issue's record. |
| `features/455-success-failure-filter-highlight-criteria.md` § Open items | One reference to "#478 (highlight bookkeeping on the hot path)" in a resolved sequencing note. Stale context only; flagged, not edited. |
| Issue #472's cross-reference to #478 | On GitHub, in the #472 issue body and in `features/472-highlight-bin-counter-telemetry.md` § Ordering and § D2, both of which name #478 by the old title. For the orchestrator; the #472 branch is not this worktree's to edit. |

The three delivered feature docs (#432, #418, #455) are flagged rather than
swept because each is a historical record of a completed issue, and CLAUDE.md
forbids change-history phrasing inside them. The correction lives in the
amended `analysis.md`, which is the artifact all three ultimately point at.
