# Hypothesis — #567 access-log parse regression

## What is being investigated

A release-tier capture of v0.18.3 against v0.18.2 (77 cases, same host) reports
the movement split by log-format family, not by scenario:

| family | mean total delta | n |
|---|---|---|
| Access logs | +6.40% | 33 |
| ScriptLog (custom) | +6.11% | 11 |
| Thingworx application logs | +0.75% | 33 |

Isolated with code as the only variable (both binaries, same host, interleaved):
`single-day-access-log-standard` +1.7%, `single-day-application-log-standard` 0%.
`rss_peak` is flat on every selection and every line count is identical, so this
is a timing change with no behaviour or data-structure change.

## What the code reading has already established

Every per-line site #567 added is gated, and the gates cost one scalar test per
line when the options are unused:

- `$discard_active` guards the message substitutions (`read_and_process_logs`).
- `$expose_active` guards the exposed-value appends.
- `$discard_any_field` guards the four field `undef`s.
- `EXPOSE_*` are `use constant`, so compile-time.

No benchmark scenario passes `-d` or `-x`, so none of the added code runs in the
regressing cases. The regression therefore cannot be the added code executing.

## Hypothesis

**H1 (structural).** The cost is not in executed added code but in the growth of
`read_and_process_logs`, the per-line loop. The added gates and branches enlarge
a hot sub past a threshold where the interpreter's handling of it changes
(op-tree size, branch layout, register/pad pressure), so the loop costs more per
line even on the paths that skip the new code. Predicts: time spread thinly
across the whole loop rather than concentrated in any new sub, and no new sub
appearing with meaningful exclusive time.

**H2 (format-specific path).** Something in the access-log and ScriptLog parse
path — which Thingworx application-log parsing does not reach — pays a cost the
other family does not. Predicts: a named sub or regex on the access-log branch
with a measurable exclusive-time increase between the two binaries.

The family split is the fact that most needs explaining: H1 alone does not
obviously explain why Thingworx application logs are unaffected, unless the two
families exercise different amounts of the same enlarged loop. H2 explains the
split directly but has no candidate yet from the code reading.

## Method

Profile v0.18.2 and v0.18.3 over the same access-log sample, and the same pair
over a Thingworx application-log sample as the control that should show no
difference. Compare exclusive time per sub between the two binaries in each
family. A sub that grows only in the access-log pair supports H2; a diffuse
increase with no named culprit supports H1.

## Disposition if H1 holds

A structural cost that the gates cannot remove is a design question about where
per-line option handling lives, not a line to fix; it goes back to the architect
with the measurement rather than being refactored unasked.
