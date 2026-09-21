# Analysis — #567 access-log parse regression

## Measurement

**Bisect**, 10 interleaved rounds (each commit once per round, so drift is shared),
`single-day-access-log-standard`, 155 MB access log, 50 runs total:

| commit | what it added | median | vs base |
|---|---|---|---|
| `v0.18.2` base | — | 8.985 s | — |
| `fb36c5c` | requirements and decisions, no code | 9.025 s | +0.45% |
| `e39c23b` | option surface, resolution, reporting | 9.075 s | +1.00% |
| `7deb7a4` | runtime-config reports provided options | 9.095 s | +1.22% |
| `62db306` | discard applied across the run | 9.130 s | +1.61% |

The cost **accumulates across commits rather than stepping at one**. No single
commit carries it.

**Profile**, NYTProf, 100k-line samples, both binaries, access log and a Thingworx
application log as control. Exclusive time by sub, generated scan subs collapsed
(their eval numbering shifts between builds and otherwise reads as a false ±0.5 s):

| sub | access base -> head | application base -> head |
|---|---|---|
| `read_and_process_logs` | 1.659 -> 1.694 s (**+2.1%**) | 1.106 -> 1.109 s (+0.3%) |
| generated scan sub | 0.501 -> 0.498 s | 0.211 -> 0.205 s |
| `CORE:match` | 0.101 -> 0.103 s | 0.184 -> 0.184 s |
| `CORE:subst` | 0.169 -> 0.170 s | 0.054 -> 0.053 s |
| `CORE:readline` | 0.030 -> 0.026 s | 0.024 -> 0.022 s |

The whole regression is `read_and_process_logs` exclusive time. Every other sub is
flat, and no new sub appears in the profile.

## What the per-line statements show

Both binaries execute **the same 114 statements 100,000 times each** — one per line
read. No statement added by #567 executes on these runs, which is what the
`$discard_active`, `$expose_active` and `$discard_any_field` gates are for.

Two statements appear to gain ~0.004 s each in HEAD and two to lose ~0.004 s each;
they are adjacent statements exchanging attribution and cancel exactly. An earlier
reading of an apparent 200k -> 300k call-count jump on `if( defined $count )` was an
artifact of aggregating line data by source text, where unrelated sites share a line;
the code at that site is byte-identical between the two binaries.

## Conclusion

**H1 (structural) holds; H2 (format-specific path) is rejected.** The cost is diffuse
inside the per-line loop, with no named culprit and no added statement executing —
exactly H1's prediction. H2 predicted a sub or regex growing only in the access-log
pair, and no such sub exists.

`read_and_process_logs` is ~870 lines and #567 added gates and branches inside it.
The loop costs ~2% more per line on access logs even where the new code is skipped.

**Why access logs and not application logs.** The same loop is slower in both
(+2.1% vs +0.3% exclusive), but the access-log path spends a far larger share of its
work inside `read_and_process_logs` itself (1.66 s of 2.63 s total exclusive) than the
application-log path does (1.11 s of 1.70 s, with more time in its generated scan sub
and `CORE:match`). A cost spread across the loop body therefore lands harder on the
family that lives in the loop body. The ScriptLog family (+6.11% in the release
capture) is expected to behave like access logs for the same reason; that has not
been profiled.

## Disposition

A diffuse interpreter-level cost from loop growth is not a line to fix. The candidates
are design choices — moving per-line option handling out of the loop body, or
generating the per-line path per run the way the format scan sub already is — and both
are larger than this issue. Recorded for the architect with the measurement; not
actioned.
