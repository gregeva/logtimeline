# Analysis — #432 bytes parity capture, hot-loop cost

Companion to `hypothesis.md`, written after measurement. Feature doc:
`features/432-metric-aggregate-naming-parity.md`.

## Method

Two arms, `release/0.18.0` as baseline and this branch, both run through the same
interpreter (`/opt/homebrew/bin/perl <script>`) so the shebang path cannot differ
between them. End-to-end wall clock on
`logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt`
(1,430,678 lines), `--disable-progress -ni -bs 1440 -oe -n 5 --terminal-width 120`,
3 pairs, medians.

Line-level attribution from `tests/profile/run-profile.sh` at the 100k sample, read
through `nytprofcsv`. The runner's cross-validation confirmed `lines_read=100000`
against the profile's own call counts.

## Result

| Run | base | this branch | delta |
|---|---|---|---|
| normal | 16.44 s | 17.09 s | **+4.0%** |
| `-ob` (bytes discarded) | 16.50 s | 16.38 s | **−0.7%** |

Under `-ob` the cost is *gone*, not merely reduced. That is the proof the option gate
short-circuits: a run that discards the metric does no work for it.

### Where the time goes, per 100k lines

| Lines | Cost |
|---|---|
| per-message family (counter + two extrema) | 0.0111 s |
| per-bucket family (counter + two extrema + flag) | 0.0116 s |
| the two guard tests, on every line | 0.0150 s |
| **total attributable** | **0.0377 s** |

Projected onto 1.43M lines: **0.54 s**, against ~0.65 s measured end-to-end. The
profile accounts for the delta.

Only 36,409 of 100,000 lines carry a bytes value on this corpus, so the guards skip
64% of lines — the counter and extrema lines each show ~36.4k calls against the
guards' 100k.

## Hypotheses

**H1 — hash element access dominates. HOLDS, and it is why the guards cost what they
do.** The two guard tests together (0.0150 s) cost more than either family's actual
work (0.0111 / 0.0116 s), because they run on every line while the work runs on 36%.

**H2 — seeding beats the `!defined` test. HOLDS.** The seeded branch means
`bytes_min`/`bytes_max` are two compare-and-maybe-assign lines at 0.0032/0.0021 s and
0.0025/0.0017 s; no definedness test appears in the profile at all.

**H3 — the two scopes are not equally expensive. REFUTED for this shape.** They are
within 5% of each other (0.0111 vs 0.0116 s). The prediction that per-bucket would be
materially cheaper because the entry is already in hand was wrong for the same reason
recorded in the prototype: the baseline resolves that entry once, so the family's
fields are genuinely new resolutions at both scopes.

**H4 — under +1.5% for both scopes. REFUTED.** Measured **+4.0%**. The prototype
predicted +1.8% and was itself already above its own bound; production is roughly
double the prototype's projection.

## Why the prototype under-predicted, and what that means for the next one

The prototype measured accumulation loops over pre-built arrays. Production runs the
same accumulation interleaved with regex extraction, format dispatch, timestamp
parsing and bucket-key construction — so every hash write competes for cache against
work the prototype did not model, and each costs more in place than it did in
isolation.

This is the #58 F9 lesson recurring one layer out. There, a prototype's *baseline arm*
was a convenience sub and hid the machinery the candidate added. Here both arms were
faithful to each other, but the *environment* was not faithful to production, and a
prototype that is internally consistent can still mispredict by 2x. The prototype was
right about the **ordering** of the candidates — which is what it was for, and the
shape it chose is still the cheapest of the three — and wrong about the magnitude.

**For the next prototype of a hot-path change:** the ratio between candidates
transfers from an isolated loop; the absolute per-line cost does not. State
predictions as ratios, or measure in place.

## The largest hot-path cost here is not this change

Line-level profiling put the `-HL` suffix regex in three of the top thirteen lines of
the whole script:

| Line | Cost / 100k | Code |
|---|---|---|
| 11031 | 0.0651 s | `$log_level =~ s/-HL$//;` |
| 11383 | 0.0480 s | `$log_analysis{$bucket}{'total_duration-HL'} += $duration if $category_bucket =~ /-HL$/;` |
| 11462 | 0.0267 s | `$e->{'total_bytes-HL'} += $bytes if $category_bucket =~ /-HL$/;` |

**0.14 s per 100k lines, ~2.0 s on the reference corpus — roughly 12% of total
runtime**, spent re-deriving a highlight flag from a string suffix on every line.
Three of these run per line; the pattern is a constant.

This is **pre-existing and not caused by this change** — line 11462 appears in the
list only because the bytes block it lives in was merged under the new option gate,
and it carries the same cost it always did. It is not fixed here: it is a separate
change to a shared mechanism, and folding it into a naming issue would be exactly the
scope creep the repository's rules forbid. Recorded so the measurement is not lost.

## Lessons

1. **An option that discards a metric must gate its capture, not just its output.**
   The first implementation paid full per-line cost under `-ob` and would have shipped
   that way. `-ob` is documented in CLAUDE.md, `--help` and `docs/usage.md`, and
   appears seven times in `ltl` beside the edited code — reading the option gates for
   the metric being touched is part of editing that path, not a later optimisation.
2. **Profile with the project's runner.** `tests/profile/run-profile.sh` handles sample
   truncation, cross-validation against `ltl -V` counters, and output layout; ad-hoc
   `-d:NYTProf` invocations produced nothing usable here and cost time.
3. **A prototype transfers ratios, not absolutes.** See above.
4. **Bisecting by hand is slower than one line-level profile.** Several arm-patching
   rounds narrowed nothing; the profile attributed the whole delta in one run.

## Environment note

`features/nytprof-profiling-workflow.md` § Environment records the tool paths under
Perl **5.42.0**; the installed toolchain is **5.42.2** (`/opt/homebrew/Cellar/perl/5.42.2/bin/nytprofcsv`).
The doc anticipates exactly this drift and says to update the paths when Homebrew
upgrades Perl. `run-profile.sh` resolves `nytprofhtml` from the same versioned path
and was run here with `--no-html`, so the drift did not surface as a failure.

---

## Amendment, 2026-09-13: the highlight-suffix projection above is wrong by 25 to 50 times

Appended under the never-overwrite rule; nothing above this line is changed. The
section "The largest hot-path cost here is not this change" stands as the record
of what the instrument reported. This amendment records what the projection
turned out to be worth when it was measured directly, so that no future reader
acts on the 2.0 s / 12 percent figure. That figure is what caused #478 (the
highlight decision is re-derived from the `-HL` category suffix throughout the
read loop instead of kept once at the tag point) to be filed as a performance
bug; the issue has since been reframed as a convergence fix, and the full record
is `features/478-highlight-decision-read-back.md`.

**The corrected figure.** An A/B against a probe build with every in-loop `-HL`
suffix regex replaced by a scalar flag measured **about 0.08 seconds on 16.5
seconds, roughly 0.5 percent**, inside the run-to-run spread. An independent
second pass measured about 0.07 s on 16.3 s. The arithmetic ceiling from
isolated per-operation cost is about 0.04 s, so even 0.08 s is generous. The
projection above reads 2.0 s and about 12 percent. Both are wall-clock on a
machine running other work concurrently, so the timings are indicative; the
order of magnitude is the point.

**Why the arithmetic above is internally consistent and still wrong.** 2.0 s of
a 16.44 s baseline really is 12 percent, and 0.14 s per 100k lines really does
scale to about 2.0 s on 1.43M lines. The error is not in the arithmetic: it is
in the attribution model. The profiler charges a statement's whole cost to its
line, and two of the three lines in the table above carry a hash-element
autovivify-and-add beside the guard:

```perl
$log_analysis{$bucket}{'total_duration-HL'} += $duration if $category_bucket =~ /-HL$/;
$e->{'total_bytes-HL'} += $bytes if $category_bucket =~ /-HL$/;
```

The hash write is the expensive half, and it is the work the program is there to
do; only the guard is the redundancy. This same analysis establishes, in "Where
the time goes, per 100k lines", that hash element access dominates on this path.
That finding was simply not applied to its own three `-HL` lines.

**The third line did no work at all.** The most expensive line in the table,
`$log_level =~ s/-HL$//`, **matched zero times in 20,000 lines** of the profiled
access-log corpus. It sits on the message path, where `$log_level = $status_code
> 0 ? $status_code : $category_bucket`, and a status code can never carry the
suffix. Its 0.0651 s per 100k is the scalar copy and the ternary sharing the
statement, not a substitution doing work. A probe that gated the line measured
no improvement. The substitution is nonetheless load-bearing on formats with no
status code: commenting it out regresses TOP MESSAGES rows from `[WARN]` to
`[WARN-HL]`.

**Two smaller corrections to the same section.** "Three of these run per line;
the pattern is a constant" does not hold. An instrumented build counting
executions per site measured **1.38 per line** on the reference access log under
the profiled options (the duration site on every line, the bytes site on 38
percent), and the maximum reached on any corpus and option set tried was 7 per
line. It is also not monotonic in feature count: adding `-hm duration -hg
duration` *removed* a site by changing the resolved bucket-statistics demand.
And the line numbers in the table are from the #432 branch; the file has since
grown to about 21,060 lines and `read_and_process_logs` has moved about 3,600
lines, so the sites must be located by snippet rather than by number.

**The lesson, stated as the lessons above are.** A line-level profile attributes
cost to a statement, not to a clause within it. Before a guard's profiled cost
becomes a projection, check what else shares its statement, and check that the
operation being blamed actually executes on the profiled corpus.
