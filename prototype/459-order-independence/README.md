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
