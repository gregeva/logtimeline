# Analysis — #447 control-character normalisation, hot-loop cost

Companion to `hypothesis.md`, written after measurement.

## Method

`ltl` was measured as two binaries differing only by the normalisation: an arm
with it and a baseline arm without. Runs used
`--disable-progress -ni -bs 1440 -oe -n 5 --terminal-width 120` on
`logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt`
(1,430,678 lines), medians over interleaved pairs.

**Single-order interleaving proved insufficient.** The same code measured +0.44%
in one session and +1.99% in another; within-arm spread (0.36 s) is larger than
the effect being measured (0.13 s). The reported figure comes from an
**order-balanced ABBA design** over 8 pairs, which cancels monotonic drift.

## Result

| Arm | Median | vs baseline | Per line |
|---|---|---|---|
| baseline | 16.383 s | — | — |
| sub call, unguarded | 17.192 s | **+4.36%** | +503 ns |
| **inline, guarded (shipped)** | 16.514 s | **+0.80%** | **+92 ns** |

Shipped arm positive in 7/8 ABBA pairs. **82% of the original regression was
removed.**

## Hypotheses: confirmed, and one refuted

**H1 — the sub call dominated. CONFIRMED.** Inlining alone took a
1000-message loop from 3,050/s to 6,614/s (+117%). A Perl sub call with argument
passing, a lexical copy and a return-value copy costs more than the two rewrites
it wrapped.

**H2 — the guard removes most of the rest. CONFIRMED.** Guarded-inline measured
9,539/s against unguarded-inline's 6,614/s (+44%). `tr` in counting mode is one
character-class scan with no modification and no copy, and on an access log
essentially no message contains a control character, so the common case skips
both rewrites.

**H3 — the residual is the guard scan and is irreducible. STANDS.** +92 ns/line
for one scan of every message is the floor for any implementation that must know
whether a message is clean.

**Refuted along the way — skipping unmatched lines saves nothing.** Gating the
normalisation on `$is_line_match` was expected to pay on a log where half the
lines are unmatched (`cxserver.1-16.log`: 497,750 matched, 502,133 unmatched).
Measured **-0.11%, 3/6 pairs** — noise. The reason: an unmatched line's
`$message` is empty or undef, and `tr` over an empty string costs nothing. The
guard was already skipping that work. The gate was kept for what it says, not
what it saves, and its comment records the measurement so it is not re-litigated.

## What the investigation turned up that the profile was not looking for

**The record lexicals are not reset per line.** They are cleared as a side effect
of the scan's failed list-assignment matches — a failed `( $a, $b ) = $s =~ /.../`
sets every capture target to undef. A **space-led line** is rejected by the
whitespace dispatch *before any format block runs*, so it performs no such match
and `$message` still holds the previous matched line's text.

This was found by testing the space-led path specifically after an initial probe
reported zero stale messages across the whole corpus — the probe was measuring a
path that could not exhibit the behaviour. Message-key construction already sits
behind `if( $is_line_match )`, so no output was ever wrong; but it is the reason
the normalisation must not run ahead of that condition, and
`tests/validate-message-control-characters.sh` scenario 3 is now regression cover
for it.

## Lessons

1. **Order-balance any A/B whose effect is smaller than its within-arm spread.**
   Single-order interleaving gave a 4.5x range on identical code.
2. **A probe that reports zero has to be shown capable of reporting non-zero.**
   The stale-message probe read zero because the corpus never exercised the
   space-led early return, not because the behaviour was absent.
3. **Measure the work-avoidance before assuming it.** Skipping half the lines
   sounded obviously worth it and measured as nothing.
