# #517 — Per-message success/failure counts captured only on demand

Issue #517 (per-message success/failure counts are captured per line although
only the MESSAGES CSV reads them). Fixes part of the v0.18.0-first
parse/read_files regression and all of the `%log_messages` memory growth
attributed in `tests/profile/results/0180-parse-regression/analysis.md`
(~0.11 s time on single-day-access-log-standard; +48.1 MB store growth on the
286K-unique-messages selection, +21.8 GB suite-wide).

## Requirement

The per-message outcome counters (the `outcomes` success/failure array on each
`%log_messages` entry, and its seed in the consolidation stats source) are
captured only when a surface that reads them is active. Today that is only the
MESSAGES CSV successes/failures columns (`-o`,
`features/453-success-failure-classification-event-ledger.md`). The
default-surface classification figures (summary SUCCESS/FAILURE CLASSIFIED
rows, timeline percentage columns, errRate) read the run totals and
`%bucket_outcomes` and are untouched.

Open feature #456 (per-message success/failure indicator in the messages and
summary tables) will add a rendered consumer; when it lands, its option state
joins this gate's demand terms.

## Decisions

### D1 — One store-level demand flag, resolved beside the sibling gates

`$message_outcomes_demand`, computed in the demand-resolution block of
`adapt_to_command_line_options()` (beside `$bytes_aggregate_demand`, #516 D1),
true when `-o` is active. All three write sites test it: the two per-line
`outcomes[]++` writes (main capture path and the consolidation-absorbed else
branch) and the per-new-key consolidation `stats_source` seed.

### D2 — Downstream reads are absence-tolerant, so nothing else moves

The MESSAGES CSV writer already guards (`$outcomes ? ... : 0`) and runs only
under `-o`, where the flag is true; `merge_consolidation_stats()` copies the
array only when the source carries it; the cluster projection copies it only
when present.

## Acceptance criteria

1. **Default run skips capture and recovers the store growth** (assertable):
   on the 286K-unique-messages benchmark selection, `MEMORY/log_messages`
   returns to its pre-#453 level (isolation-measured 133.2 MB vs 181.3 MB) and
   `parse/read_files` recovers on the access-log selection. Asserted by the
   before/after benchmark on both targeted selections.
2. **MESSAGES CSV unchanged under `-o`** (assertable): successes/failures
   columns byte-identical before/after on a fixture carrying both outcomes
   (existing mechanism: the `outcomes` array read by the MESSAGES CSV writer).
   Asserted by direct diff.
3. **Consolidated run unchanged under `-g -o`** (assertable): the consolidation
   merge still carries outcome counts into cluster rows; MESSAGES CSV
   byte-identical before/after. Asserted by direct diff.
4. **No runtime warnings** (assertable): stderr carries no ` at ltl line N`
   lines on the criterion 1–3 runs.
5. **Full suite green** (assertable): every `tests/validate-*.sh` passes on the
   finished commit (completion gate).

## Merge gate

Per-feature workflow step 1: full harness suite + before/after benchmark
(517-before captured on the base commit for both targeted selections).
