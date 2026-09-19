# Profiling Analysis: 584-consolidation-regression

Profiled 2026-09-19 on the reproduction described in `hypothesis.md`. Devel::NYTProf
6.15, Homebrew Perl 5.44.0, `/opt/homebrew/bin/perl`.

Samples are the first 40,000 and 100,000 lines of one day of the affected corpus
(a single-server Tomcat access log carrying a UUID in about a fifth of its request
paths), `-bs 1440 -n 25 -g`, default sensitivity 85.

## The hypothesis was wrong

`match_consolidation_patterns()` was predicted to be the largest single term. It is
not. At 100k lines it holds 0.70 s exclusive (8.0%) over 65,915 calls — 0.013 ms per
call, an order of magnitude cheaper per call than the isolation benchmark suggested,
because most misses reject on the first few patterns rather than scanning the list.

The dominant term is `find_consolidation_candidates()`.

| sub | 40k excl | 100k excl | 100k share | 100k calls | ms/call |
|---|---|---|---|---|---|
| `find_consolidation_candidates` | 2.5800 s | 3.4424 s | 36.7% | 12,232 | 0.324 |
| `read_and_process_logs` | 0.7280 s | 1.7671 s | 39.4% incl | 1 | — |
| `build_consolidation_ngram_index` | 0.5758 s | 0.7686 s | 13.2% | 79 | 17.958 |
| `match_consolidation_patterns` | 0.5164 s | 0.7019 s | 8.0% | 65,915 | 0.013 |
| `get_consolidation_trigrams` | 0.4968 s | 0.6579 s | 6.1% | 33,688 | 0.020 |
| `dice_coefficient` | — | 0.0264 s | 0.2% | 2,721 | 0.010 |

`process_final_pass_window()` carries 46.1% inclusive: the final pass is where the
work happens, and the candidate search is what it spends its time in.

`dice_coefficient` at 2,721 calls against 12,232 searches is the shape of the
problem. The searches are not finding partners to score — they are walking to
exhaustion and returning nothing. Scoring is 0.2% of the run; the walk is 36.7%.

## Where the time goes inside the search

Line-level timings inside `find_consolidation_candidates` (ltl:10813-10901), 100k
sample, 12,232 calls:

| line | executions | time | what it is |
|---|---|---|---|
| 10825 | 12,232 | 560 ms | sort every source trigram by posting length (per call) |
| 10853 | 5,518,831 | 424 ms | binary search for `$s_max`, once per probe position |
| 10860 | 2,745,917 | 366 ms | binary search to the first in-range id in the posting list |
| 10824 | 12,232 | 284 ms | build `%posting_length` over every source trigram (per call) |
| 10862 | 1,880,898 | 278 ms | candidate visit in the posting walk |
| 10884 | 1,313,574 | 170 ms | scoring test |
| 10900 | 12,232 | 152 ms | sort the (usually empty) result list |
| 10868 | 1,217,850 | 129 ms | initialise a newly seen candidate |

Per search: about 50 probe positions walked, 154 candidate visits, 100 candidates
initialised, and 0.22 candidates actually scored. The stop rules do not fire.
`last if @results` cannot, because there is no partner to find; the exhaustion rule
`last if $new_hi < $id_lo && $live <= 0` rarely does, because candidates stay live
while the size range still admits them.

Two costs are paid per call regardless of how far the walk goes: lines 10824 and
10825 build and sort a posting-length map over all of the source's trigrams (mean
111 distinct trigrams on this corpus). Measured in isolation that pair is 0.064 ms,
a fifth of the 0.324 ms per call. The rest is the walk.

## Why the search is doing this at all

The search is not defective. It is being asked to find partners that do not exist,
once per surviving key, and the surviving keys are the UUID-bearing ones.

Two keys from this corpus differing only in their trailing UUID score **Dice 63 as
written and 90 with the UUID normalised** (both 127 characters, 112 trigrams each).
The default sensitivity is 85, so the pair groups when the UUID is normalised out of
the comparison and does not group when it is compared as written.

The day file holds 36,541 distinct UUIDs and leaves 36,791 surviving message rows.
Essentially every distinct UUID becomes a permanent row of its own.

## The counterfactual

The same 100k sample, same code, with `-m uuid` so the UUIDs never reach the
similarity comparison:

| | default | `-m uuid` |
|---|---|---|
| `finalize/group_similar` | 10.438 s | 0.690 s |
| total | 18.059 s | 6.082 s |
| `rss_peak` | 171.6 MB | 126.3 MB |
| `COUNTS log_messages_entries` | 21,565 | 235 |

`find_consolidation_candidates` leaves the top six subs entirely under `-m uuid`,
where it had held 36.7% of exclusive time. The profile becomes an ordinary read-bound
run.

## Attribution

The cost is second-order. Comparing UUIDs as written is the change; the search cost
is what that change produces, because it leaves a population of keys with no partners
and calls the search on each of them.

Measured by bisection on one day of the corpus, `-bs 1440 -n 25 -g`:

| commit | rows | `group_similar` |
|---|---|---|
| `e153589` before #571 | 467 | 0.72 s |
| `3defdcb` #571, final pass at the -g sensitivity | 467 | 0.70 s |
| `0c7c950` #569, UUIDs compared as written | 36,790 | 23.05 s |
| `22a7e8f` #569, the new candidate search | 36,791 | 6.83 s |

`0c7c950` is the step that changes the outcome. `22a7e8f` recovers two thirds of the
time its predecessor lost and does not recover the grouping. #571 is flat here because
this invocation already runs at 85; it would bite at a higher `-g`.

## Why it only shows on the largest selections

The retained population grows linearly with the input, because each distinct UUID is a
row. On v0.18.1 it was nearly flat.

| days | v0.18.1 rows | 0.18.2 rows | v0.18.1 `group_similar` | 0.18.2 `group_similar` |
|---|---|---|---|---|
| 1 | 467 | 36,791 | 0.73 s | 6.91 s |
| 2 | 531 | 74,693 | 0.77 s | 13.40 s |
| 4 | 988 | 147,866 | 1.87 s | 30.18 s |
| 28 (benchmark) | 1,313 | 1,136,511 | 55.2 s | 2655.6 s |

Between 1 and 4 days the 0.18.2 cost is close to linear in retained rows, about 190 us
per row. At 28 days it is about 2,336 us per row, roughly 12x that. Two things grow
together at that scale: the number of searches (one per surviving key) and the work
inside each (the id range the size filter admits, and the number of candidates that
stay live through the walk, both grow with the window population). Neither is visible
at small sizes, which is why the standard tiers stayed flat and only `full`/`xl`/`all`
moved.

The streaming phase contributes by getting out of the way. At 4 days `-V` reports
`S1 Inline match: 100`, `S6 Evicted: 150057`, `EMA=0.0%, max_survivals=0`: the adaptive
eviction guard (#135) observes a zero absorption rate and evicts the whole working set
from streaming, so the entire retained population is deferred to the final pass. The
guard is behaving as designed, on an absorption rate the UUID change drove to zero.

## Learnings

- **A cost can be entirely second-order.** Nothing in `find_consolidation_candidates`
  regressed; it got faster. It became the hotspot because the population it is called
  on changed shape. Profiling the hot sub would have attributed this to the search.
- **`dice_coefficient` call count is the health signal for consolidation.** 2,721
  scores against 12,232 searches means the searches are failing. A healthy run scores
  far more often than it searches.
- **Isolation benchmarks over-estimated the pattern matcher.** 18.5 us per miss
  measured against a synthetic 100-pattern list, 13 us per call measured in situ
  against the real list. Early rejection dominates; the synthetic patterns all shared
  a long literal prefix and so rejected late.
- **`COUNTS log_messages_entries` belongs in any consolidation regression triage.** It
  separates "consolidation is slow" from "consolidation stopped working", and here it
  gave the answer before any profiling.

## Cross-validation

`find_consolidation_candidates`: NYTProf reports 12,232 calls; the `-V`
`find_candidates calls` counters for the same run sum to 12,232 across every
streaming and final-pass block. Exact, no tolerance needed.

## What is stored here

`summary.txt` per sample: the NYTProf subroutine table, sorted by exclusive time.

The `-V` captures these were cross-validated against are **not** committed. On this
corpus the `message-grouping` blocks carry consolidated message rows built from real
request paths, which name live servers; this is a public repository. The counters
quoted above were read from those captures at the time of the run, and any of them is
reproducible with the invocations named in `hypothesis.md`.
