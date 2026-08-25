# Test harness and application-observability design

This document is the source of guidance, best practices, and requirements for test harnesses in this repository and for the application-observability surface they consume. It is normative, not advisory — the rules below are MUSTs unless otherwise stated.

If you are adding a new harness, modifying an existing one, or changing any `-V` output in `ltl`, read this document first.

## Why this exists

Test harnesses make assertions against application output. When the application output and the harness drift apart silently — a section gets renamed, a key gets removed, a format changes — three things happen:

1. The harness either fails loudly (best case) or silently passes despite asserting nothing useful (worst case).
2. The reader looking at a failure can't tell whether to escalate (real regression), delete (stale assertion), or restore (feature was removed by mistake).
3. The cost of getting back to a working harness compounds because the *intent* of each assertion was never written down where the assertion lives.

The rules in this document exist to prevent each of those failure modes. They reflect actual incidents in this repository, not hypothetical concerns.

## Application-observability contract

When a test harness needs to assert against internal application state, the application exposes that state via a dedicated, named section of `-V` output. Harnesses do not grep rendered analytical output (the bar graph, the summary table, the histogram) to obtain internal state. Rendered output exists for humans and changes when humans want it to; observability output exists for harnesses and is governed by the stability contract below.

**This prohibition is about *what the harness treats as the system under test*.** When the value being asserted is internal state — a computed percentile, a bin count, a resolved config — the render is an unstable proxy and `-V` is mandatory. When the value being asserted is *a property of the rendered surface itself* — that every duration cell carries a unit, that columns align, that no ANSI escape bleeds past its cell — the render **is** the system under test, and asserting on it is correct. That second category is governed by [Render-invariant harnesses](#render-invariant-harnesses) below, not by this prohibition.

The contract is two-way:

- The harness commits to consuming a stable, named section by its name.
- The application commits to keeping that section's content under the stability contract: additions are non-breaking; renames and removals are breaking changes that require updating every consumer in the same commit.

This avoids the anti-pattern where harnesses scrape display output and break every time the display layout shifts. It also keeps `-V` itself comprehensible: each section is owned by one or more harnesses (or by the user for interactive debugging) with a clear purpose.

### Counters serving benchmark attribution: one source, two surfaces

A counter that serves benchmark attribution (a denominator for per-element cost, a population size a release comparison normalizes by) has ONE computation site — the block boundary in its owning functional category. It is exposed in that category's own `-V` section (the development-time assertion surface, with semantics recorded in the owning feature-doc section contract) and re-emitted by `benchmark-data` as a `COUNTS` row reading the same variable (the attribution surface, captured into the benchmark TSVs).

Single source, two surfaces: `benchmark-data` never computes an independent duplicate of a functional counter, and a functional counter that a benchmark comparison needs is never benchmark-only. This keeps the value assertable during development of the functional category and directly attributable in benchmarking data, without the two surfaces drifting apart. (Pre-existing `COUNTS` rows that measure final structure state at emission time — e.g. `log_messages_entries` — are a different quantity from a block-boundary population and are not silently converged; where both exist, the owning feature doc records the distinction.)

## Render-invariant harnesses

A render-invariant harness asserts that the *rendered terminal output* obeys the rules required for visual consistency and determinism — properties that exist only in the rendered surface and have no internal-state equivalent to read from `-V`. For these harnesses, grepping the (ANSI-stripped) display output is the correct and required approach: the rendered surface is the system under test, not a proxy for it.

This is distinct from a state-observability harness (the kind the contract above governs), which asserts on *computed values* and must read `-V`. The two are not interchangeable:

| | State-observability harness | Render-invariant harness |
|---|---|---|
| System under test | Internal computed state | The rendered terminal surface |
| Reads from | A named `-V` section | ANSI-stripped display output |
| Example assertion | "p99 for this bucket equals 224" | "every duration cell carries a unit suffix" |
| Fails when | The computation regresses | The rendering becomes inconsistent |

**A render-invariant harness asserts invariants, not frozen values.** It must not duplicate the snapshot regression harness (`validate-regression.sh`), which freezes exact output and fails on any change. A render-invariant assertion is a *property* that holds across runs regardless of the specific data — "matches `<number><unit>`", "no two adjacent columns overlap" — so that buggy-but-stable output (the failure mode that motivated this category) cannot pass.

**Obligations specific to this category:**

- **Pin the layout.** Run `ltl` at an explicit `--terminal-width` so the rendered surface is deterministic; width-dependent layout must not make the assertion flaky.
- **Strip ANSI before asserting.** Color/escape sequences are not part of the invariant; strip them first (`sed -E 's/\x1b\[[0-9;]*m//g'`) so the assertion sees the glyphs a human reads.
- **`-V` may still supply the *expected* value.** A render-invariant assertion may read internal state from `-V` to compute what the render *should* show, then compare it against what the render *does* show. This is the legitimate intersection: `-V` provides the expected (internal precision, resolved unit); the stripped render provides the actual; the assertion compares the two. Reading `-V` for the *expected* side does not make this a state-observability harness — the *asserted* side is still the rendered surface.
- **Same self-documenting-assertion contract.** Every assertion declares `asserts` / `produced_by` / `contract` and surfaces all three on failure, exactly as the [Self-documenting assertions](#self-documenting-assertions) section requires. `produced_by` names the rendering function (e.g. `format_duration() in ltl`).

The reference implementation is `tests/validate-duration-display.sh` (Issue #292): it asserts that every duration value rendered in the summary table and the timeline carries a unit, that zero renders in the resolved unit, and that displayed fractional precision matches the resolved-unit precision read from `-V`.

## Selectivity and grep work together

Harnesses use `-V <section-name>` to narrow the application's output to the section they care about, then `grep` (or `sed`/`awk`) within that narrowed output. Selectivity does not replace grep; it makes grep clean. Without selectivity, every harness pays the cost of parsing every other section's content; with selectivity, each harness sees only what it asked for.

The mechanism: `ltl -V` accepts the name of a registered section, a comma-separated list (`-V a,b`), or the flag repeated (`-V a -V b`). Bare `-V` emits all sections. `-V list` prints the registry. See `ltl --help`. The framework is Issue #226.

## Naming rules

These are mandatory. Names are part of the stability contract and a poorly chosen name will outlive any other decision in the harness.

**Top-level sections are named for the semantic feature they instrument.** Not for the variables manipulated, not for the algorithm used, not for the shape of the output produced. If the section reports on what the user calls "message grouping," its name is `message-grouping` — not `consolidation` (the technique), not `s1-s6-counts` (the output shape), not `dice-similarity` (the algorithm). The implementer is expected to read the code carefully enough to state, in plain language, what user-facing capability the section makes observable, and to name from that.

**Sub-sections are named for the function they serve within the parent feature.** Same rule recursively. A sub-section that reports the resulting histogram dimensions is `dimensions` — not `bucket-calculation` (the process) or `final-stats` (the output shape).

**All names are lowercase kebab-case.** This is the form used as the CLI argument, the literal string emitted in the section delimiter (`=== name ===`), and the literal string a harness greps for. The same token serves all three roles, which is why it has to be one consistent style.

**Harness file names track the section they validate.** A harness for the `histogram-bin-counters` section lives in `tests/validate-histogram-bin-counters.sh`. When a section is renamed, the harness file is `git mv`'d to match in the same commit. This makes the relationship between harness and section discoverable from the filesystem alone, and prevents the situation where the file name still reflects an old section name (and a reader has to open the file to find out what it actually validates).

**Naming is implementation work, not a one-time judgment.** When the user is not available to name something, the implementer reads the code and proposes a name on the same basis (semantic feature for sections, function for sub-sections). "I'll name it for what the user-facing capability is" is the right reflex; "I'll name it for the function in the source code that emits it" is the wrong one.

## Delimiter contract

Every section is bracketed by a start and an end marker:

```
=== section-name ===
... section content ...
=== END section-name ===
```

Sub-sections use the same form with `/` as the nesting separator:

```
=== section-name / sub-name ===
... sub-section content ...
=== END section-name / sub-name ===
```

End markers are required. They exist so harnesses can use range extraction (`sed -n '/=== section/,/=== END section/p'`) unambiguously. The next-section-as-end pattern (`sed -n '/=== a/,/=== b/p'`) is inclusive of the end line and drags adjacent content; explicit end markers eliminate that brittleness.

## Reserved section names

This list prevents collisions across parallel work. Update it when adding a new section.

**Implemented:**
- `runtime-config` — effective runtime configuration: LTL_CONFIG, merged include/exclude/highlight/threadpool regexes, resolved duration-statistics demand booleans (Issue #349), and per-flag resolved values (including the numeric highlight criteria, Issue #312)
- `index-read-back` — index pre-seed lookups, freshness, aggregated bounds, drift detection (Issue #179); `heatmap_preseed_min`/`heatmap_preseed_max` expose the live post-preseed heatmap bounds when a heatmap is active (Issue #310)
- `histogram-array` — raw-array histogram dimensions; active when a surface resolves to the raw values data model
- `histogram-bin-counters` — HDR-style bin-counter histogram state and finalized histogram dimensions (Issue #187)
- `message-grouping` — fuzzy message consolidation (Issue #96)
- `heatmap-palette` — heatmap color palette resolution: active metric, light/dark selection, source of selection, gradient arrays (Issue #250)
- `profile` — timeline folding (--profile): resolved mode, fold period, included weekdays, included vs dropped sample counts (Issue #256)
- `udm-counting` — per-bucket counting-aggregation UDM state: occurrences, distinct cardinality, display and highlight values, plus sessions oracle reference (Issue #313)
- `statistics-demand` — per-store resolved statistics-group demand with raising consumers, per-store moment source, per-store statistics-calculation counters (`stats_calls` invocations plus per-group `group_calc` computed/skipped_demand/ineligible outcomes), calculated-statistic sort selection (`sort_selection` defined/fill/demoted split, `sort_calc` per-pass attribution), and block-boundary populations (per-store `population`, phase-level `threadpool_population` — the sub-stage timing denominators, Issue #417) (Issues #305, #303, #417)
- `benchmark-data` — machine-parseable TSV: version, files, line counts, timings (per-stage `TIMING` rows, the `finalize/calculate_statistics/*` sub-stage rows, Issue #417 — contract in features/417-substage-statistics-timing.md — and the `detect/scan_sub_compile` accumulator, Issue #413), memory, structure counts (including the re-emitted block-boundary populations per the one-source-two-surfaces rule above)
- `format-detection` — per-file detected format slug/match_type and matched/unmatched/scan-attempt counts, plus the `format-detection / scan` sub-section: registry scan-order telemetry (final MTF order, promotions, per-entry match counts, sampled no-match cost) (Issues #228, #58, #388, #384; contract in features/log-format-registry.md § `-V format-detection` section-contract)
- `format-registry` — the compiled registry itself: entry inventory (name, slug, group, variant-default, scanned/stateful role), structure (variant groups with occupants, static scan order, derived pinned-ancestor constraints), and scan-sub compile state (subs compiled, cache hits, accumulated compile-boundary RSS delta, compiled order signatures). Per-file detection telemetry stays in `format-detection` (Issue #413; contract in features/log-format-registry.md § `-V format-registry` section-contract)

**Reserved by sub-issues, not yet implemented:**
- `filter-summary` (Issues #229, #230 — shared section, ownership decided during research)
- `option-resolution` (Issue #231)

## Stability contract

A section's name and content are a contract with the harnesses that consume it.

**Additions are non-breaking.** New keys, new sub-sections, new lines may be added at any time. Harnesses should not assert on the *absence* of unexpected lines unless that absence is itself a contracted invariant.

**Renames and removals are breaking changes.** Renaming a section (`=== bin-counter-mode ===` → `=== histogram-bin-counters ===`) or a key (`opt_out_active` → `exact_percentiles_optout`) requires:

1. Updating every consumer in the same commit. Discover them with `grep -r "=== old-name ===" tests/` or the equivalent.
2. Running each affected harness end-to-end and confirming it still **asserts**, not merely exits 0.
3. Updating this document's reserved-names list and any per-feature reference (CLAUDE.md, docs/usage.md, README.md, print_help).

This rule exists because of a specific class of failure observed in this repository: a section header was renamed without updating the harness that asserted on it. The harness's assertions for that header failed loudly, but the failure was not noticed because the harness was not re-run after the rename. The "run each affected harness and confirm it still asserts" step is what catches that.

## Shared specification files

Some harnesses consume a shared machine-readable specification of application output — today, the column-rules TSVs under `tests/csv-output/rules/` consumed by both `validate-csv-output.pl` and `compare-statistics-drift.pl`. Three rules govern these files; all three were derived from one incident (Issue #320 uncovered 14 emitted-but-unspecified `-HL` level columns; the enforcement asymmetry that let them ship — the structural validator silently accepting columns the drift engine refuses — was closed under Issue #335, which made an unknown CSV column a hard failure in `check_column_structure()`).

**Completeness tracks the application, not the scenarios.** The spec must cover every column (or key) the application *can* emit — including conditional and dynamic variants (`-HL` highlight columns, rate-unit suffixes, UDM families) — not merely the columns current scenarios happen to produce. When ltl gains a new output column or a new dynamic variant of an existing one, its spec rows land **in the same commit**. A spec that only covers exercised output makes every unexercised surface silently un-testable: the first scenario that touches it fails (or worse, passes unasserted) for reasons unrelated to what that scenario tests.

**Every consumer enforces the same strictness.** When two harnesses read one spec, they must agree on what a violation is. If one refuses unknown columns and the other silently accepts them, the weaker consumer defines the effective contract and drift ships through it. When adding a consumer, match the strictest existing consumer's behavior; when that is not possible, document the asymmetry in both consumers and open a ticket to close it.

**Enforcement lives in code, not comments.** A comment asserting that "X is already checked elsewhere" is not a check. Before writing `next unless $rule;  # unknown column already flagged...`, verify the flagging exists — and if the referenced check is in another phase or file, name the function that performs it so the claim is verifiable. This is the spec-file analog of the missing-anchor rule: a claimed-but-absent check produces false confidence, which is worse than no check.

## A gate only guards surfaces a scenario exercises

A strict validation gate (all-or-nothing column coverage, refuse-on-unknown, format checks) asserts nothing about surfaces no scenario traverses. The bin-counter drift engine would always have refused a highlight-bearing STATS CSV — but since no statistics-drift scenario used highlights, the gate's incompatibility with a whole feature surface went unnoticed until #320.

When adding a strict gate, enumerate the application surfaces it constrains and confirm at least one scenario traverses each; where a surface has no scenario, either add one or record the gap explicitly (a `log()`-style note in the harness header or a tracked ticket). "The gate has never fired" must be distinguishable between "the invariant holds" and "nothing ever put the invariant under test."

## Proving a new assertion can fail

Exit code 0 on a healthy input is not evidence that an assertion works — an assertion with a wrong anchor, a wrong file, or an over-permissive pattern also exits 0. Every **new** assertion (and every assertion whose anchor or logic changes) must be demonstrated to fail before it is trusted to pass:

1. Construct a minimal input that violates the invariant (a hand-crafted CSV row with a broken partition, a doctored render, a fixture line with the metric removed).
2. Run the assertion against it — directly against the checker/engine where possible, not through the full harness — and confirm it fails *with the expected diagnostic* (the asserts/produced_by/contract triple surfaces, the exit code is non-zero).
3. Then run the healthy path and confirm it passes.

This is the same discipline the stability contract requires after renames ("confirm it still asserts"), applied at authoring time. The sabotage probe for Issue #320's `level_partition` invariant is the reference example: probing with a deliberately broken CSV is what exposed that the rules TSV could not even represent the columns the invariant needed.

## Harnesses must fail on missing anchors

A harness that greps for a section header, key name, or other anchor and finds zero matches MUST exit non-zero. A grep that matches nothing is not a passing test — it is an unasserted test, which is worse than no test at all because it produces false confidence.

This applies to every existing and future harness, not only `-V` consumers. Any harness that uses `grep`, `sed`, `awk`, or equivalent to extract content from application output must treat "anchor not found" as a hard failure with the same severity as a wrong value.

The reason this rule exists is twofold:

- A renamed or removed section produces no matches in the harness. Without this rule, the harness exits 0, the CI is green, and the rename ships undetected.
- An anchor-not-found failure carries different diagnostic information from a wrong-value failure. Surfacing them as the same outcome (non-zero exit, named scenario) lets the reader act on whichever one matches reality.

### Specific traps to recognize and avoid

The rule above is the principle. These are the concrete failure modes that have surfaced in this repository and the patterns a harness author must use to avoid each.

#### Trap 1: `set -e` plus `2>/dev/null` suppression

```bash
# WRONG — silent failure
"$@" 2>/dev/null | strip_nondeterministic > "$outfile"
```

If the captured command fails or crashes, stderr is discarded and the script has no diagnostic to report. The `>` redirect succeeds (writing an empty file), the pipeline returns 0, and downstream code consumes the empty file as authoritative.

```bash
# RIGHT — preserve stderr, check exit code, check non-empty result
set +e
"$@" 2>"$stderrfile" | strip_nondeterministic > "$outfile"
local pipe_status=("${PIPESTATUS[@]}")
set -e
if [[ "${pipe_status[0]}" -ne 0 ]]; then
    echo "FAIL: command exited ${pipe_status[0]}; stderr:" >&2
    sed 's/^/    /' "$stderrfile" >&2
    exit 1
fi
if [[ ! -s "$outfile" ]]; then
    echo "FAIL: captured output is empty" >&2
    exit 1
fi
```

Use `${PIPESTATUS[@]}` to check the first command in a pipeline, not the last. Without it, `set -o pipefail` is required to catch upstream failures in a `cmd | filter` chain.

#### Trap 2: `|| true` / `|| echo "fallback"` swallowing failures

```bash
# WRONG — error becomes silent success
local lines_read=$(grep "^lines_read" "$file" | awk '{print $2}' || true)
```

`|| true` was the right tool somewhere else (where you genuinely want to continue with a default), but in an assertion context it turns a missing anchor into an empty string the script then carries forward as if it were a real value.

```bash
# RIGHT — separate concerns; check the extracted value explicitly
local lines_read
lines_read=$(grep "^lines_read" "$file" | awk '{print $2}')
if [[ -z "$lines_read" ]]; then
    echo "FAIL: missing anchor 'lines_read' in $file" >&2
    exit 1
fi
```

`|| echo "?"` is acceptable only in *display* contexts (e.g., a status line that says "rss=? MB" when measurement failed), never in assertion contexts.

#### Trap 3: Empty `sed` range output is ambiguous

```bash
# AMBIGUOUS — empty result could be "section empty" or "start anchor missing"
local body
body=$(sed -n '/^=== name ===/,/^=== END name ===/p' "$file")
```

When `/^=== name ===/` is not found, `sed -n` prints nothing. The consuming code cannot distinguish "section was emitted but its body is empty" from "section header is missing entirely" — those have completely different remediations.

```bash
# RIGHT — check the start anchor was present before consuming the body
if ! grep -qE '^=== name ===$' "$file"; then
    echo "FAIL: missing section header '=== name ===' in $file" >&2
    exit 1
fi
local body
body=$(sed -n '/^=== name ===/,/^=== END name ===/p' "$file")
```

Or grep-then-strip rather than range-extract: `grep -A 9999 '^=== name ===' "$file"` followed by separate validation of the end marker.

#### Trap 4: `awk END` runs even on no matching rows

```bash
# WRONG — prints empty string when anchor missing; downstream proceeds
local version
version=$(awk -F'\t' '$3 == "version" { v=$4 } END { print v }' "$file")
```

`awk`'s `END` block executes regardless of whether any rows matched. An undefined variable prints as empty string. The caller gets `""` rather than an error.

```bash
# RIGHT — check the extracted value before using it
local version
version=$(awk -F'\t' '$3 == "version" { v=$4 } END { print v }' "$file")
if [[ -z "$version" ]]; then
    echo "FAIL: missing 'version' anchor in $file" >&2
    echo "      Expected: column 3 == \"version\"" >&2
    exit 1
fi
```

Or push the validation into awk (`END { if (v == "") exit 1; print v }`) and check awk's exit code — but the bash-side check above is clearer to a future reader.

#### Trap 5: `grep -c` returning zero looks like a successful count

```bash
# AMBIGUOUS — zero is a valid grep -c result, not necessarily an error
local count
count=$(grep -c '^selection,' "$file")
```

`grep -c` prints `0` for no matches. The exit code is non-zero on no-match (unless `-c` with `-q` is suppressing it, depending on grep version), but the captured value looks fine. Downstream comparisons proceed against zero.

```bash
# RIGHT — separate "is the anchor present" from "how many rows match"
if ! grep -q '^selection,' "$file"; then
    echo "FAIL: no 'selection,' rows in $file" >&2
    exit 1
fi
local count
count=$(grep -c '^selection,' "$file")
```

For scenarios where zero genuinely is a meaningful count (e.g., "this run should produce zero unmatched lines"), say so explicitly in the assertion and structure the check as a numeric comparison against an expected value, not as a presence check.

#### Trap 6: Unconditional counter advancement

```bash
# WRONG — counter ticks regardless of whether the assertion actually fired
run_test() {
    # ... does some work, may have failed silently ...
    count=$((count + 1))
}
```

If the work inside the function silently failed (any of traps 1–5), `count` still increments. The final report shows N tests "ran" when in reality some of them did not actually assert anything. This is the harness equivalent of the missing-anchor-as-pass anti-pattern at the orchestration level.

```bash
# RIGHT — counter only advances on confirmed success
run_test() {
    # ... do work, with hard failures on any anchor not matching ...
    if [[ ! -s "$outfile" ]]; then
        fail=$((fail + 1))
        return 1
    fi
    pass=$((pass + 1))
}
```

The summary line at the end of a harness (`"Results: N passed, M failed"`) must reflect actual assertions made, not iterations attempted.

#### Trap 7: `local x=$(...)` masks the inner command's exit code

```bash
# TRAP — $? after this line is 0 even if the inner command failed
local tmpfile=$(mktemp /nonexistent-path/XXX 2>/dev/null)
```

The `local` keyword's own return value (0) overrides the captured command's exit code. `set -e` will not catch a failure inside the `$(...)`.

```bash
# RIGHT — declare and assign separately so $? reflects the command
local tmpfile
tmpfile=$(mktemp)
if [[ -z "$tmpfile" || ! -e "$tmpfile" ]]; then
    echo "FAIL: mktemp produced no file" >&2
    exit 1
fi
```

This affects every assignment where the inner command can fail meaningfully: `local x=$(grep ...)`, `local x=$(awk ...)`, etc. Separate the declaration from the assignment whenever you want `set -e` to catch the failure.

#### Trap 8: Intentional non-zero exits in a `pipefail` pipeline

```bash
# WRONG — diff returns 1 on differences (intentional!), pipefail propagates,
# set -e aborts the harness before the Results summary prints
set -euo pipefail
diff --unified=3 "$ref" "$tmp" | head -30
```

Some commands (`diff`, `grep`, sometimes `cmp`) return non-zero to *report a finding*, not to report failure. Under `set -o pipefail`, that non-zero propagates through the pipeline; under `set -e`, the script aborts. The harness terminates mid-run with no diagnostic about what was actually intended.

```bash
# RIGHT — neutralize the intentional non-zero, preserve the diagnostic
{ diff --unified=3 "$ref" "$tmp" || true; } | head -30
```

The `|| true` is correct here because the diff is *diagnostic output*, not an assertion. The assertion that drove this branch already fired (`diff -q` succeeded or failed earlier); the `diff --unified=3` exists only to show the human what differs.

This is the inverse of Trap 2 (`|| true` swallowing assertion failures). The distinction: `|| true` is wrong on the assertion itself, right on the diagnostic command that runs *after* an assertion has already failed. If you find yourself reaching for `|| true`, ask: is this command asserting something, or is it explaining a prior assertion's result?

#### Trap 9: Temp artifacts written next to deliverables

```bash
# WRONG — writes a diagnostic .stderr file alongside the deliverable
local outfile="$REF_DIR/$name.txt"      # deliverable
local stderrfile="$REF_DIR/$name.stderr" # transient artifact in the same dir
"$@" 2>"$stderrfile" > "$outfile"
```

Two separate problems compound: (a) the directory `$REF_DIR` contains tracked, committed reference files — putting transient `.stderr` files in it pollutes the deliverables area and risks committing them by accident; (b) without explicit cleanup the transient files persist across runs and confuse future readers ("is this `.stderr` left over from a real failure, or just normal noise from last week?").

```bash
# RIGHT — transient artifacts go in a temp dir with a cleanup trap
STDERR_DIR=$(mktemp -d)
trap 'rm -rf "$STDERR_DIR"' EXIT

local outfile="$REF_DIR/$name.txt"           # deliverable
local stderrfile="$STDERR_DIR/$name.stderr"  # transient, auto-cleaned
"$@" 2>"$stderrfile" > "$outfile"
```

Rule: a harness directory under `tests/` that contains tracked files (regression references, fixtures, captures) is a *deliverables area* and only the tracked files belong in it. Transient capture, temp output, intermediate state — all go in `$(mktemp -d)` with an `EXIT` trap to clean up.

#### Trap 10: `mktemp -d` without an `EXIT` trap

```bash
# WRONG — explicit cleanup at end-of-script only fires on normal exit
TMP_DIR=$(mktemp -d)
# ... lots of work, may abort under set -e ...
rm -rf "$TMP_DIR"   # never runs if any prior command aborted
```

`set -e` causes the script to terminate immediately on any failure. The explicit `rm -rf` at the end is skipped. Every aborted run accumulates a `/tmp/tmp.XXX/` directory the script will never clean up.

```bash
# RIGHT — cleanup runs unconditionally via EXIT trap
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
# ... lots of work — even if it aborts, EXIT trap fires ...
```

Add the trap on the *same logical line* as the `mktemp` so it can't be forgotten between declaration and use. If the harness uses multiple temp dirs, set the trap to clean all of them: `trap 'rm -rf "$DIR1" "$DIR2"' EXIT`.

#### Trap 11: backticks inside double-quoted prose are command substitutions

```bash
# WRONG — bash RUNS `more`: the harness blocks on a pager waiting for a terminal
assert_line "$out" \
    asserts     "fallback for environments where the pager cannot interpret ANSI (notably legacy Windows `more`)" \
    ...
```

`asserts`, `produced_by` and `contract` strings are documentation, and documentation habitually quotes identifiers with markdown backticks. Inside a double-quoted bash string a backtick pair is a command substitution: the quoted word is executed, its output is spliced into the string, and if the word happens to be a real command (`more`, `less`, `script`, `time`, …) the harness runs it — silently when it exits at once, as a hang when it waits on a terminal. `validate-explain.sh` stalled an entire suite run for 36 minutes this way (2026-08-23): in an interactive terminal `more` exited immediately, so the defect only surfaced when the suite ran in the background.

```bash
# RIGHT — escape the backticks, or single-quote the string
    asserts     "fallback ... (notably legacy Windows \`more\`)" \
    asserts     'fallback ... (notably legacy Windows `more`)' \
```

Review gate: `grep -n '`' tests/validate-*.sh` — every backtick on a non-comment line is either escaped or inside single quotes. A harness that needs a variable *and* a backtick in one string escapes the backtick.

## Invocation coherence: every `ltl` run is shaped to the test that invokes it

A harness does not run `ltl` "the default way" and read off the part it cares about. Every invocation — in a scenario, a capture helper, a probe, a sabotage proof — is tuned so that the tool does exactly the work the assertion needs and nothing else: the fastest runtime, the minimum memory, and an output whose shape is the one being asserted. Anything the run computes that the assertion never reads is waste at best and, on the wrong input, a resource problem at worst.

The mechanical gate before writing any `ltl` command line in a test:

1. **What does this run prove?** Name the surface under assertion (a `-V` section, a rendered block, an exit code, a stderr diagnostic).
2. **What does that surface NOT depend on?** Everything else is switched off or made trivially cheap through the tool's own options. A format-detection or evidence assertion is identical at any bucket size, so it runs with the coarsest bucket (`-bs 1440`) and no empty buckets (`-oe`); a column-layout assertion runs with `-n 1`; a stderr-diagnostic assertion needs no rendered table at all where an option suppresses it.
3. **Does the input's shape match the run?** Fixtures spanning months, or a file set whose files sit years apart, make the default time axis allocate thousands of empty buckets — `-oe` and a day-sized bucket are mandatory there unless the time axis *is* the subject. Use the smallest fixture that carries the signal.
4. **Consult the tool's documentation (`docs/usage.md`, `--help`) for the options that do this** before inventing a workaround in the harness. Where the right shape is not obvious — a scenario that needs the time axis *and* a wide span, say — the choice is an architect decision, recorded in the scenario's comment.

The scenario's comment states the shape and why (one line: *"`-bs 1440 -oe`: detection assertions; fixtures span months"*). A harness run whose options were never chosen against its own assertion is a defect in review, whether or not it passes.

Every harness invocation also passes `-ni` (`--no-index`) unless the index is the subject (`validate-index-read-back.sh`): without it each run reads and rewrites the working directory's `ltl-index.csv`, which on a developer's checkout is the dominant cost of a small run (measured ~0.4 s per invocation against a 2,000-row index) and appends a test row the developer never asked for.

Precedent: #384 (2026-08-23) — ten new format-detection scenarios and the ad-hoc parity checks behind them ran multi-year fixtures at default (and hourly) buckets, building tens of thousands of empty buckets to assert a per-file selection that never reads a bucket. #399 (audit every test harness for invocation coherence) tracks the audit of every existing harness against this rule.

## The log corpus is resolved, never composed

Harnesses read their inputs from the log corpus: `logs/` under the repo root by default, or wherever `LTL_LOGS_DIR` points. A harness never builds that location itself — no `"$REPO_DIR/logs/..."`, no bare `logs/...` assumed relative to the repo root. It sources `tests/lib/logs-dir.sh` and reads `$LOGS_DIR`, or calls `resolve_log_path` for a path that arrives as data (a scenario-table column, a fixture-source list).

Two reasons this is a rule and not a preference:

1. **`logs/` is gitignored, so it exists only in the checkout that populated it.** A second clone or a git worktree has no corpus, and every harness that composes the repo-root path is unrunnable there — the failure is an unrelated-looking "file not found" or, worse, a pass. `LTL_LOGS_DIR` points such a checkout at the real corpus.
2. **A partially-applied override is worse than none.** When only some call sites honour it, the harness finds its inputs through one path and silently skips the work gated on another. During #436 exactly this happened: `validate-statistics.sh` reported 18/18 passing while the L3 oracle was skipped on all 36 cells (`L3=N/A`), because one of two copies of the same path-resolution logic had been updated. The suite was green and proving materially less than it claimed.

Consequences for harness authors:

- **One resolution surface.** `resolve_log_path` is it. A new `if [[ "$logfile" = /* ]]` ladder is a review defect — that duplication is what produced the silent skip above.
- **Verify an override end-to-end, not by exit code.** A harness that resolves its corpus correctly and one that quietly skips its most expensive layer both exit 0. Check the counters the run reports (`L3=OK`, assertion counts, scenario counts) against a known-good run on the default path.
- **Where the recorded path is part of the assertion, keep it relative.** `validate-regression.sh`, `capture-regression.sh` and `tests/baseline/run-benchmark.sh` pass repo-relative paths so no absolute path reaches captured references or the benchmark TSV (#209). These run from the directory *containing* the corpus rather than resolving an absolute path, which keeps `logs/...` intact under an override; because the captured prefix is the literal string `logs/`, an overriding corpus directory must itself be named `logs`, and they fail fast when it is not.

## Runtime-warning cleanliness

Every harness that invokes `ltl` MUST capture the invocation's stderr and fail the run if it contains a Perl runtime warning. A runtime warning (uninitialized value, substr outside of string, non-numeric argument, out-of-range date field, ...) is an unguarded data path — a bug that has not yet found the input that makes it fatal or wrong — and a harness that discards stderr certifies code it never looked at.

**The discriminator:** interpreter-emitted warnings always carry the suffix ` at <file> line <N>`; intentional `ltl` diagnostics printed to stderr never do. The check is:

```bash
if grep -qE ' at .+ line [0-9]+' "$stderr_capture"; then
    # hard failure — surface the deduplicated warnings plus the
    # asserts/produced_by/contract triple
fi
```

`produced_by` for this assertion is "whichever ltl code path the warning text names" — the warning itself carries the emitting line, so the failure output should include the (deduplicated, counted) warning lines.

**Obligations:**

- New harnesses include this check from the first commit; it is part of the capture step, not an optional extra assertion.
- The check is implemented once in `tests/lib/runtime-warnings.sh` (`assert_no_runtime_warnings <stderr_file> <context>`); harnesses source that library rather than re-implementing the pattern. Shared capture helpers (`tests/lib/csv-cache.sh`) perform the check at the point of capture so their consumers don't repeat it.
- Discarding stderr (`2>/dev/null`) in a harness is prohibited for the same reason as Trap 1 above — and this section extends that rule: even *captured-but-uninspected* stderr is a gap.
- When a capture helper is invoked via command substitution (`out=$(run_xxx ...)`), the check must run at the call site in the main shell — counters incremented inside the substituted function are lost with the subshell. The helper writes `<capture>.stderr`; the caller checks it (see `check_capture_warnings()` in `tests/validate-histogram-bin-counters.sh`).
- Splitting a previously merged (`2>&1`) capture relocates *intentional* ltl diagnostics out of the stdout capture: any assertion that greps for an intentional stderr message must be re-pointed at the stderr capture in the same change.

The rule exists because the `udm-counting` csv-output scenario exercised the exact code path of a per-message uninitialized-division bug and emitted 125 warnings on every run — invisibly, because no harness read stderr (Issue #326). The sweep that brought every harness under the check was Issue #341.

## Self-documenting assertions

**Every assertion must answer three questions at the moment of failure, without the reader leaving the harness output:**

1. **What invariant of the application is being asserted?** A plain-language statement of the contract, not the regex. ("When no bin-counter consumer is migrated and active, the section emits `consumers_active: none` as a placeholder line.")
2. **Where in the application is that invariant produced?** A function name in `ltl` (not a line number — those drift). ("emit_bin_counter_mode_verbose() in ltl")
3. **What contract makes the invariant stable?** A pointer to the contract that lets the reader judge whether the failure is a real regression, a stale assertion, or a removed feature that should be restored. ("features/187-histogram-bin-counter-percentiles.md § Decision 8 — stability-contracted to harnesses; renames are breaking.")

These three pieces of information are recorded *with the assertion itself*, in the harness source. When the assertion fails, the harness surfaces all three alongside the regex pattern and the path to the captured output. The reader sees the failure and can act without opening any external file.

An assertion whose failure message is only the regex pattern is incomplete and must be rewritten.

**This rule exists because of a specific failure in this repository:** an assertion authored in one release was read cold three days later, after the section header it tested had been renamed. The reader had no way to determine from the harness itself whether the missing match meant (a) a real regression, (b) stale code, or (c) a feature that should be restored — three completely opposite remediations, no signal in the test. Hours of archaeology were needed to act on a one-line failure. Self-documenting assertions exist to make that archaeology unnecessary.

The reference implementation of this rule is `tests/validate-histogram-bin-counters.sh`. New harnesses should match its shape; existing harnesses are retrofitted under a separate ticket.

### Implementation shape

The exact API may evolve, but every assertion-runner in this repository must accept and surface the three documentation fields. A typical Bash shape:

```bash
assert_line "$out" \
    pattern     '^consumers_active: none$' \
    asserts     'Section reports `consumers_active: none` when no bin-counter consumer is migrated and active' \
    produced_by 'emit_bin_counter_mode_verbose() in ltl' \
    contract    'features/187-histogram-bin-counter-percentiles.md § Decision 8 — stability-contracted; renames are breaking'
```

On failure, the harness prints:

```
  FAIL  default
        pattern:     ^consumers_active: none$
        asserts:     Section reports `consumers_active: none` when no bin-counter consumer is migrated and active
        produced_by: emit_bin_counter_mode_verbose() in ltl
        contract:    features/187-histogram-bin-counter-percentiles.md § Decision 8 — stability-contracted; renames are breaking
        (not found in /tmp/xxxxxx)
```

The reader can now act without leaving the failure output.

### When the assertion isn't a simple line grep

Some assertions don't fit the "match this regex against this output file" shape — for example, checking that multiple grep conditions ALL hold against an on-disk artifact, running a Perl one-liner to validate CSV well-formedness, or counting rows of a specific type. For those, use a sibling helper `assert_command` that takes the same documentation fields plus a `command` (eval'd; PASS if exit code 0) and a `label` (short human-readable summary for the PASS line, since the command itself is too verbose to print on every PASS).

```bash
assert_command \
    command     'grep -q "^selection,.*,-dmin=50$" ltl-index.csv && grep -q "^selection,.*,-dmin=100$" ltl-index.csv' \
    label       'both -dmin=50 and -dmin=100 selection rows preserved after write' \
    asserts     'After the run, the end-of-run write must preserve the pre-existing -dmin=50 selection row AND append a new -dmin=100 selection row' \
    produced_by 'write_index_file() in ltl (end-of-run #46 write side; merge-with-existing semantics)' \
    contract    'features/179-index-read-back.md § Interactions with existing features § "With write side (#46)"'
```

On failure, `assert_command` surfaces the `command` (so the reader can re-run it) plus all the documentation fields. Use `assert_line` for "match this regex in this file" and `assert_command` for everything else — both share the same three documentation field requirements.

## When a harness needs new observable state

If a harness needs to assert against application state that is not currently exposed via a `-V` section: open or update a ticket against the application requesting a new section (or a new field within an existing section). Do not work around the gap by grepping the bar graph, the summary table, or other rendered output.

The ticket should specify:
- Proposed section name (per the naming rules above) or the existing section it extends
- What invariant the harness needs to assert (the *asserts* field of one or more assertions)
- Where the invariant is produced in `ltl` (the *produced_by* field)
- Stability requirements (the *contract* field — what guarantees the harness needs)

The application implementation lands first; the harness lands after, asserting on the new section.

## When `-V` output changes

When modifying any `-V` section header, sub-section header, content key name, content format, or removing any of the above:

1. Consult this document's stability contract section. Renames and removals are breaking; additions are non-breaking.
2. Identify every consumer with `grep -r "=== name ===" tests/` (or the equivalent for the changed token).
3. Update every consumer in the same commit. Do not dribble updates across commits.
4. Run each affected harness end-to-end and confirm it asserts (not merely that it exits 0). The "must fail on missing anchors" rule means an assertion that no longer finds its anchor will fail; if your change should preserve the assertion, update the anchor.
5. Update `docs/usage.md`, `README.md`, and `print_help()` in `ltl` for any user-visible surface change.
6. Update this document's reserved-names list if a name was added or removed.

A CLAUDE.md rule points to this section for any contributor (human or LLM-driven) editing `-V`.

## When this document changes

The rules above are derived from incidents. Add new rules when an incident reveals a class of failure not yet covered; remove rules only when the incident class no longer applies (and record why, in the commit message).

Render-invariant harnesses (the category above) were added after Issue #292: three duration-display bugs shipped — values rendered with no unit (`58` instead of `58ms`), zero rendered without a unit, and synthesized sub-millisecond precision on a millisecond-resolution source — because the only display coverage was snapshot regression, which freezes output and cannot catch a buggy-but-stable value. No harness asserted the *invariants* the rendered surface must hold to, so the snapshots simply froze the bugs as "correct."

## See also

- `ltl --help` — current `-V` surface and known section names
- `ltl -V list` — runtime-discoverable registry of section names and one-line descriptions
- Issue #226 — framework that this document is built on
- CLAUDE.md § `-V` discipline — the mandatory pointer back to this document
