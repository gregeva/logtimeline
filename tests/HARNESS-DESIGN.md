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

When a test harness needs to assert against internal application state, the application exposes that state via a dedicated, named section of `-V` output. Harnesses do not grep rendered analytical output (the bar graph, the summary table, the histogram). Rendered output exists for humans and changes when humans want it to; observability output exists for harnesses and is governed by the stability contract below.

The contract is two-way:

- The harness commits to consuming a stable, named section by its name.
- The application commits to keeping that section's content under the stability contract: additions are non-breaking; renames and removals are breaking changes that require updating every consumer in the same commit.

This avoids the anti-pattern where harnesses scrape display output and break every time the display layout shifts. It also keeps `-V` itself comprehensible: each section is owned by one or more harnesses (or by the user for interactive debugging) with a clear purpose.

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
- `runtime-config` — effective runtime configuration: LTL_CONFIG and merged include/exclude/highlight/threadpool regexes
- `index-read-back` — index pre-seed lookups, freshness, aggregated bounds, drift detection (Issue #179)
- `histogram` — legacy in-memory histogram dimensions
- `histogram-bin-counters` — bin-counter feature state and finalized histogram dimensions (Issue #187)
- `message-grouping` — fuzzy message consolidation (Issue #96)
- `benchmark-data` — machine-parseable TSV: version, files, line counts, timings, memory, structure counts

**Reserved by sub-issues, not yet implemented:**
- `format-detection` (Issue #228)
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

## See also

- `ltl --help` — current `-V` surface and known section names
- `ltl -V list` — runtime-discoverable registry of section names and one-line descriptions
- Issue #226 — framework that this document is built on
- CLAUDE.md § `-V` discipline — the mandatory pointer back to this document
