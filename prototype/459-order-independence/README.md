# #459 combination-order probes

Instruments for the stage-4 investigation recorded in
`features/459-bin-counter-combination-order.md`. Every one of them loads the
production subs sliced verbatim out of `ltl` by `extract-subs.sh` (written to
`/tmp/459-subs.pl`), so what they measure is the shipped combination path and
not a convenience re-implementation of it.

Run `./extract-subs.sh` first; then any probe.

| probe | question it answers |
|---|---|
| `order-independence.pl` | Does the deferred collapse give the same stored counts and percentiles whatever order members arrived in? |
| `accuracy-vs-pooled.pl` | What did deferring buy against the pre-change eager combination, measured against a single partition over the pooled samples? |
| `grid-anchored-seed.pl` | Would snapping each partition's seed floor to a global grid remove the projection loss? |
| `merge-resolution.pl` | Does projecting the combined result at a finer resolution than its inputs stop the error compounding across repeated collapses? |
| `fold-exactness.pl` | Is doubling the range at a fixed bucket count (halving buckets-per-decade) a lossless coarsening? |
| `fold-compounding.pl` | Does repeated folding compound error, or stay bounded by the current bucket width? |
| `growth-alignment.pl` | Does today's range growth move counts, or shift them in place? |
| `canonical-fold-target.pl` | On a canonical grid with a fixed bucket budget, is the combined row independent of arrival order and of batch boundaries? |
| `extract-real-groups.py` | Produces the real per-message duration streams behind each consolidated row, grouped as `ltl -g` grouped them, using the statistics oracle's verbatim parsers. |
| `real-corpus-comparison.pl` | Both candidate designs on those real groups: agreement across orders and batch boundaries, accuracy against the raw durations, peak memory, absorb cost. |

**Known defect, fixed 2026-08-27.** The probes originally seeded a member with
`counter_entry_new()` without then observing that first value; production's
`counter_update()` seeds *and* observes. Every member was short one sample and
single-sample members contributed nothing. All probes were corrected and re-run. Any
future probe here must seed and observe, the way `counter_update` does.

**Second defect, fixed the same day.** Four probes declared a partition seed span of 4
decades; the shipped value is 5. The seed span decides how much of a partition a key
occupies before it has seen anything beyond its first value, which is the mechanism the
per-key-versus-grid comparison turns on — it is not a free parameter. Every probe now
declares the shipped value. **Any constant a probe restates from `ltl` is a realism
risk**: prefer slicing it out of the source, and where that is impractical, state where
the value came from in a comment.
