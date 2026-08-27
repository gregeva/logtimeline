# Analysis — #432 bytes parity capture, hot-loop cost

Companion to `hypothesis.md`, written after measurement. Feature doc:
`features/432-metric-aggregate-naming-parity.md`.

## Method

Candidate accumulation shapes measured against the production code as baseline, at
both scopes, by `prototype/432-bytes-parity/bytes-capture-cost.pl`. The baseline arms
reproduce the production blocks sliced verbatim out of `ltl` by
`prototype/432-bytes-parity/extract-blocks.sh` (#58 F9), which fails hard on a missing
anchor rather than silently measuring nothing.

Order-balanced ABBA, 8 pairs, 1,000,000 lines per run, 20,000 distinct message keys,
1,440 buckets, 85% of lines carrying a bytes value. Medians with ranges.

A correctness gate runs before any timing: every candidate must agree with an
independently computed reference on all ~19,900 keys, and the fixture must be shown
capable of demonstrating F1. Both were enforced, and the gate earned its place — see
*What the gate caught* below.

## Result

Per-line deltas are over the accumulation loop only. The end-to-end column projects
onto the reference run measured the same session:
`localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt`, 1,430,678 lines,
baseline median **16.38 s** over 3 runs (16.28 / 16.38 / 16.73) — the same corpus and
the same baseline as #447, so the two are directly comparable.

| Scope | Arm | Median | vs baseline | Per line | Pairs positive | Projected end-to-end |
|---|---|---|---|---|---|---|
| per message | baseline | 0.2811 s | — | — | — | — |
| per message | count-family idiom | 0.5293 s | +88.3% | +248 ns | 8/8 | +2.2% |
| per message | entry reference | 0.4087 s | +48.2% | +133 ns | 8/8 | +1.2% |
| **per message** | **entry ref + seeded extrema** | **0.3784 s** | **+35.5%** | **+99 ns** | 8/8 | **+0.9%** |
| per bucket | baseline | 0.1082 s | — | — | — | — |
| per bucket | count-family idiom | 0.2977 s | +175.2% | +189 ns | 8/8 | +1.6% |
| **per bucket** | **entry ref + seeded extrema** | **0.2150 s** | **+98.9%** | **+107 ns** | 8/8 | **+0.9%** |
| **both scopes** | **entry ref + seeded extrema** | **0.5882 s** | **+53.4%** | **+205 ns** | 8/8 | **+1.8%** |

Every arm was positive in 8/8 pairs with non-overlapping ranges, so unlike #447 the
effect here sits well clear of the noise floor and the ABBA design is confirming a
result rather than rescuing one.

**The naive shape costs 2.4x the chosen one.** Copying the shipped `count` idiom
verbatim to both scopes projects to **+3.8%** end-to-end — within striking distance of
#447's rejected +4.36% arm. The chosen shape projects to **+1.8%**.

## Hypotheses

**H1 — hash element access dominates, not the comparison. CONFIRMED.** Caching the
entry reference and writing through it removed +115 ns/line at the per-message scope
(+248 → +133), a 46% reduction, with no change to the arithmetic performed. The
shipped `count` block re-resolves `$log_messages{$category}{$log_key}{...}` **six
times in four lines**; each resolution is two hash lookups.

**H2 — the `!defined` test is a per-line cost payable once. CONFIRMED.** Seeding both
extrema at first observation removed a further +34 ns/line (+133 → +99). The standard
idiom evaluates a definedness test on every line for the life of a key to handle only
its first line; at 850k observations over 20k keys that is ~830k wasted tests.

**H3 — the two scopes are not equally expensive. CONFIRMED, and the direction was
predicted correctly but for the wrong reason.** Per bucket is cheaper in absolute
loop terms (0.108 s baseline vs 0.281 s) because 1,440 keys stay cache-resident against
20,000. But as a *delta* the two are near-identical (+107 vs +99 ns/line), and per
bucket is far worse in *relative* terms (+98.9% vs +35.5%) because its baseline does so
little. The prediction that bucket writes would be near-free because the entry is
already in hand was wrong: the baseline resolves `$log_analysis{$b}{total_bytes}` once,
so the three new fields are three genuinely new resolutions.

**H4 — under +1.5% for both scopes. REFUTED, narrowly.** The chosen shape projects to
**+1.8%**, above the stated bound. Recorded as stated so the miss stands: the
prediction was made before knowing the per-bucket delta would match the per-message
one rather than being a fraction of it.

## What the gate caught

The correctness gate failed on its **first** run, with
`total_bytes = 0, expected undef` for a key whose lines all lacked a bytes value.

The reference was wrong, not the candidates. Production 0-initialises `total_bytes` at
entry creation (`ltl:11092`), so a key that never observed bytes reads **0**, which is
indistinguishable from a key whose bytes genuinely summed to zero. That is precisely
the failure mode CLAUDE.md's 2026-07-09 entry names — *gate on observation counts, not
defined-ness* — and it is the same distinction F1 turns on: `bytes_occurrences` is the
field that separates "never observed" from "summed to zero", which is why it is a
requirement of the fix and not an ornament.

Had the gate been written to compare only the arms against each other, all three would
have agreed with one another and the discrepancy would never have surfaced.

## F1 demonstrated, not asserted

Per #447 lesson 2 — a probe that reports zero must be shown capable of reporting
non-zero — the fixture is built with 15% of matched lines carrying no bytes value, and
the probe **fails hard** if no key can demonstrate the defect.

On the full run: **11,235 of 19,871 keys (57%)** produce a different mean under the
correct divisor than under the shipped one, worst case **83.3% understated**.

The shipped `mean_bytes` divides by `occurrences` (all matched lines); the correct
divisor is `bytes_occurrences` (lines that carried bytes). The magnitude is set by
what fraction of a key's lines carry no bytes field, so on a log where every matched
line has a bytes value the defect is invisible — which is why it has survived.

## Recommendation

Implement both scopes with the **entry reference + seeded extrema** shape: +205 ns/line,
projected +1.8% end-to-end. Do **not** copy the shipped `count` idiom, which measures
2.4x worse for identical results.

Two consequences worth carrying into implementation:

1. **The seeded shape changes the initialiser contract.** `bytes_min`/`bytes_max` must
   be absent (not 0-initialised) at entry creation, since the first-observation branch
   is selected by `$e->{bytes_occurrences}++` returning false. 0-initialising them
   would silently pin every minimum at 0 — the same defect class as F1.

2. **The existing `count` blocks are now known-suboptimal by measurement.** Converging
   them onto the same shape is not in #432's scope, but the measurement exists and
   should be recorded where the next person to touch that code will find it.

## Lessons

1. **Write the correctness gate against an independent reference, not against the
   other arms.** Three mutually-agreeing candidates prove nothing; the reference is
   what caught the initialiser semantics.
2. **A prediction stated numerically can be refuted.** H4's +1.5% was wrong and is
   recorded as wrong. The value of stating it was in learning *why* — the per-bucket
   delta matched the per-message one instead of being a fraction of it.
3. **The cheapest correct shape and the idiomatic shape are not the same here**, and
   the gap (2.4x) is large enough to matter on a hot path executed once per line.
