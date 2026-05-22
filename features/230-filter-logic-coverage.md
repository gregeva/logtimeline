# Feature Requirements: Inline Filter Logic Regression Harness (#230)

## GitHub Issues
- [#230 — Validate `-include` / `-exclude` / `-highlight` truth table](https://github.com/gregeva/logtimeline/issues/230) (this work)
- Parent: [#225 — Umbrella for high-priority test-harness coverage gaps]
- Sibling: [#229 — Validate `patterns/` files via test harness](https://github.com/gregeva/logtimeline/issues/229) (`features/225-pattern-files.md`)
- Depends on: [#226 — `-V` section/category selectivity]

## Overview

This research scopes a regression harness that validates the **grammar** of ltl's inline
filter flags (`-i`, `-e`, `-h`) — particularly the `&` (AND), `|` (OR) and `&&` (literal `&`)
operators introduced in #117 — via a truth-table fixture. It complements #229 (which
validates content of the `patterns/*` files). No production code is written here.

Read `features/225-pattern-files.md` first; it owns the foundational analysis of
`build_filter_matcher()` and the `-V filter-summary` design.

## 1. Documented Filter Grammar

Source-of-truth: `parse_and_or_pattern()` (`ltl:1967–1989`), `build_filter_matcher()`
(`ltl:1996–2041`), `match_filter()` (`ltl:2045–2066`), help text (`ltl:1697–1699`).

### Inline forms (`-i` / `-e` / `-h`) — **REGEX**

Each inline `-i ARG` is parsed by `parse_and_or_pattern`, then each AND term is
compiled with `qr/$term/` (`ltl:2032` for the AND/OR path, `ltl:2037` for the
single-regex fast path). Therefore each term is a **Perl regex**, with full
metacharacter support (`.`, `*`, `[...]`, `\d`, anchors, etc).

### File forms (`-if` / `-ef` / `-hf`) — **LITERAL substrings**

Patterns loaded via `read_pattern_file()` are wrapped in `quotemeta()` (`ltl:2016`)
before any compilation. File entries are literal substring matchers and do NOT
support `&`/`|`/`&&` — those characters are themselves quoted into the regex.
(Confirmed in `features/225-pattern-files.md` §1.)

### Operators (inline only)

| Operator | Meaning | Source |
|---|---|---|
| `\|` | OR — split into OR groups (`split(/\|/, …)`) | `ltl:1975` |
| `&` | AND — split each OR group into AND terms (`split(/&/, …)`) | `ltl:1980` |
| `&&` | Literal `&` — replaced by a NUL placeholder before splitting on `&`, then restored | `ltl:1971–1983` |

Precedence: `&` binds tighter than `\|` (help text, `ltl:1697`): `A&B\|C&D` means
`(A AND B) OR (C AND D)`. There is no parenthesis support. There is **no `!`
negation** — `!` is not handled by `parse_and_or_pattern` and would be compiled
into the regex as the literal character `!`.

### Combination of `-i` and `-e` and `-h`

These three filters are built independently (`ltl:4279–4281`) and applied in
sequence inside the read loop:

- `-e` first (`ltl:4991`) — line skipped if it matches `$exclude_filter`
- `-i` next (`ltl:4992`) — line skipped if it does NOT match `$include_filter`
- `-h` later (`ltl:5030`) — surviving lines are marked highlighted if they match

So the effective predicate is `(include match) AND NOT (exclude match)`, with
highlight as a post-filter tag. Repeated `-i` / `-e` / `-h` flags accumulate
into `@include_args` / `@exclude_args` / `@highlight_args`, and each arg becomes
its own OR group(s) within `parse_and_or_pattern`. Multiple `-i` flags therefore
behave as OR (any one of them matching is sufficient).

## 2. Existing Coverage

`grep` of `tests/validate-*.sh` for `-i`/`-e`/`-h`/`--include`/`--exclude`/
`--highlight` returns zero hits. The only filter-related signal anywhere in the
test surface is the `lines_included` row in benchmark TSVs (e.g.
`tests/baseline/results/comparison-v0.14.4-vs-v0.14.5.md`), which is an
end-to-end aggregate — useless for catching grammar bugs. **No regression
harness exercises filter logic today.**

## 3. Truth Table

Each row tests one independent code path through `parse_and_or_pattern` /
`build_filter_matcher` / `match_filter`.

| # | Invocation | Compiled form | Tests |
|---:|---|---|---|
| 1 | `-i A` | `qr/A/` fast path | single inline pattern |
| 2 | `-i A -i B` | `qr/A\|B/` fast path | repeated `-i` ORs (2 args) |
| 3 | `-i 'A\|B'` | `qr/A\|B/` fast path | OR inside single arg |
| 4 | `-i 'A&B'` | AND/OR path, 1 group of 2 terms | AND of two |
| 5 | `-i 'A&B&C'` | AND/OR path, 1 group of 3 | AND of three |
| 6 | `-i 'A&B\|C&D'` | AND/OR path, 2 groups of 2 | precedence (`&` tighter than `\|`) |
| 7 | `-i 'A&&B'` | `qr/A&B/` fast path | escaped literal `&` |
| 8 | `-i 'A&&B&C'` | AND/OR path, 1 group of `[A&B, C]` | escape + real `&` mixed |
| 9 | `-i 'A.*B'` | `qr/A.*B/` fast path | regex metachar (inline IS regex) |
| 10 | `-i A -e B` | two independent filters | exclude wins over include |
| 11 | `-i A -e B -h C` | three filters | highlight independent of include/exclude |
| 12 | `-i A` + `-if FILE` | AND/OR groups merged | inline + file (file = literal) |
| 13 | `-e 'A&B'` | exclude with AND | AND applies to exclude |
| 14 | `-h 'A&B'` | highlight with AND | AND applies to highlight |

Row 12 cross-checks the boundary with #229. Rows 13–14 confirm `&`/`&&` work
identically for all three filter types (same `build_filter_matcher` call site).

## 4. Synthetic Fixture

Proposed file: `tests/filter-fixtures/truth-table.log` — 20 lines, each
line tagged at column 0 with an ID so assertions can pick rows by `grep -c`.
A timestamp prefix is required for ltl to accept the line (parser drops
untimestamped lines).

```
2026-01-01 00:00:00.001 L01 plain A only
2026-01-01 00:00:00.002 L02 plain B only
2026-01-01 00:00:00.003 L03 plain C only
2026-01-01 00:00:00.004 L04 plain D only
2026-01-01 00:00:00.005 L05 has A and B together
2026-01-01 00:00:00.006 L06 has A and C together
2026-01-01 00:00:00.007 L07 has B and C together
2026-01-01 00:00:00.008 L08 has A and B and C
2026-01-01 00:00:00.009 L09 has C and D together
2026-01-01 00:00:00.010 L10 has A and D together
2026-01-01 00:00:00.011 L11 literal ampersand: A&B token
2026-01-01 00:00:00.012 L12 literal ampersand: A&B and C
2026-01-01 00:00:00.013 L13 regex bait: AxB
2026-01-01 00:00:00.014 L14 regex bait: AyyB
2026-01-01 00:00:00.015 L15 nothing relevant
2026-01-01 00:00:00.016 L16 nothing relevant either
2026-01-01 00:00:00.017 L17 only-file-pattern token FILEPAT
2026-01-01 00:00:00.018 L18 FILEPAT and A together
2026-01-01 00:00:00.019 L19 utf8 café résumé naïve A
2026-01-01 00:00:00.020 L20 whitespace test:  A  B  (two spaces)
```

For each truth-table row, the expected set of surviving line-IDs is
deterministic. Example: row 4 (`-i 'A&B'`) survives L05, L08, L18, L20
(four lines containing both `A` and `B`); row 7 (`-i 'A&&B'`) survives L11
and L12 (two lines containing the literal substring `A&B`).

A companion file `tests/filter-fixtures/truth-table.expected.tsv` would
encode `(row_id, included_count, excluded_count, highlighted_count, ids…)`.

## 5. Observable Surface Today

Same as #229 §3 — covered there, not duplicated. Summary: `total_lines_read`
and `total_lines_included` are emitted (`ltl:7430–7431`) under
`=== BENCHMARK DATA ===`, and the summary table prints `LINES INCLUDED`,
`LINES READ`, `HIGHLIGHTED` (`ltl:8507–8509`). Nothing per-pattern, nothing
broken-down by include-vs-exclude effect, nothing per-OR-group.

## 6. Application-Observability Gaps — Coordination with #229

**Recommendation: option (c) — one shared `filter-summary` section with
clearly separated `inline_patterns:` and `*_files:` subsections.**

Rationale:
- Both tickets need the same totals (`included`/`excluded`/`highlighted`).
  Splitting them creates duplicate aggregate counters.
- The compiled-matcher view (`include (merged): …` at `ltl:4295`) already
  combines inline + file patterns in one string — the `-V` consumer expects
  one place to find filter state.
- Section selectivity (#226) lets the harness ask for `filter-summary` once
  and parse both blocks.

Proposed combined layout (extends #229 §4):

```
=== FILTER SUMMARY ===
input_lines_read: 1234567
input_lines_filterable: 1230000
included: 11520
excluded: 0
highlighted: 0
include_inline:
  "A&B": hits=4
  "A&&B": hits=2
exclude_inline: (none)
highlight_inline: (none)
include_files:
  patterns/probes: status=ok loaded=2 hit_total=11520
    /Thingworx/ready: 5760
    /Thingworx/health: 5760
exclude_files: (none)
highlight_files: (none)
dead_patterns: (none)
```

Per-OR-group reporting for inline patterns (`"A&B"`) is the new piece this
ticket adds; the `*_files:` blocks are #229's territory.

## 7. Assertion Strategy

**Recommendation: (a) parse `-V filter-summary` counts**, with `(b)` `-o` CSV
row count as a secondary cross-check on a smoke test.

- (a) gives per-pattern + total visibility; required for the truth table.
- (b) catches the case where `filter-summary` itself is wrong but the
  end-to-end pipeline gives the right answer. One belt-and-braces row at
  the top of the suite is enough.
- (c) parsing the human summary table is brittle (depends on terminal width
  and locale) — avoid.

The harness should always pass `--disable-progress --terminal-width 200` and
fix `LC_ALL=C` (see `tests/validate-regression.sh` for the established
isolation pattern).

## 8. Edge Cases Worth Testing

Beyond the truth table:

| Case | Recommendation |
|---|---|
| `-i ""` (empty) | **Test**: passes through `parse_and_or_pattern` and produces a single OR group `[""]` → `qr//` which matches every line. Document the behavior; do not assume it errors. |
| `-i "&"` | **Test**: splits into `["", ""]` (AND of two empty terms) → both match every line → all lines pass. Likely surprising; capture as a smoke baseline. |
| `-i "!"` | **Test**: `!` is not a grammar token. Compiles to `qr/!/`, matches literal `!` only. Confirms negation is unsupported. |
| `-i "&&"` | **Test**: replaced to `\x00`, restored to `&`, single term `qr/&/`. Matches lines containing a literal `&`. |
| `-i "A B"` (whitespace) | **Test**: ltl does NOT trim — confirmed by `split(/&/, $group, -1)` keeping all chars. Document. |
| UTF-8 (`café`) | **Test**: Perl regex is bytewise by default; ensure source file is UTF-8 and ltl handles it the way it handles real logs. |
| Regex metachars in inline (`A.*B`) | **Test (row 9 above)**: confirms inline IS regex, distinguishes inline from file form. |
| Regex metachars in file (`A.*B`) | **Test**: quotemeta means `.` is literal `.`, NOT any-char. Cross-checks #229 contract. |
| `-i 'A&B' -i 'C'` | **Test**: two args → two OR groups, mixed AND-1-term and AND-2-term groups in the compiled `@$matcher` arrayref. |

The four invalid-looking-but-accepted forms (`""`, `"&"`, `"!"`, `"&&"`) are
the most valuable additions because they pin down **undefined behaviour
that we want to be defined behaviour going forward**.

## 9. Coordination with #229

Ownership split (proposed):

| Concern | Owner |
|---|---|
| `-V filter-summary` section spec | **Joint** — one design doc, this file references #229 §4 |
| `include_inline:` / `exclude_inline:` / `highlight_inline:` subsections | **#230** |
| `include_files:` / `exclude_files:` / `highlight_files:` subsections | **#229** |
| Aggregate totals (`input_lines_read`, `included`, `excluded`, `highlighted`) | **Joint** — built in whichever lands first |
| `dead_patterns` field | **#229** (only meaningful for multi-pattern files) |
| Fixture directory: `tests/filter-fixtures/` (synthetic truth-table log) | **#230** |
| Fixture directory: `tests/pattern-fixtures/` (corrupted pattern files) | **#229** |
| Harness scripts | **Two separate**: `tests/validate-filter-logic.sh` (#230) and `tests/validate-pattern-files.sh` (#229) |

Two harnesses (not one) because the assertion granularity differs: #230
asserts per-truth-table-row PASS/FAIL on a synthetic fixture, while #229
asserts per-pattern hit counts against real log fixtures. Sharing one
script would couple unrelated failure modes.

## 10. ltl Code Changes Required

- [ ] **`-V filter-summary` section emission for inline patterns** —
  iterate `@include_args`, `@exclude_args`, `@highlight_args`, print each
  with its hit count. Requires counting matches per OR group (see #229
  §7 option (a) for the file-side analogue; the same approach applies
  here). Effort: **low–med**, contingent on #229's counter wiring.
- [ ] **Per-OR-group hit counter** — extend `match_filter()` to optionally
  return which OR-group index matched, OR add a sidecar matcher pass when
  `-V filter-summary` is active. Effort: **low** if sidecar-only.
- [ ] **Document grammar edge cases in `docs/usage.md` and `print_help()`**
  for the four under-specified forms (`""`, `"&"`, `"!"`, `"&&"`). Effort:
  **low**.
- [ ] *No grammar bugs uncovered by this research.* The lack of `!`
  support is documented in help text by omission; nothing in source
  suggests it was ever intended.

Total ltl-side effort: **low**, contingent on the #229 / #226 stack.

## 11. Harness Shape Proposal

File: `tests/validate-filter-logic.sh`.

Sketch — numbered steps, no bash code:

1. Define the truth-table baseline as inline arrays / heredoc — one row
   per case in §3 + §8, columns `(label, ltl_args, expected_included,
   expected_excluded, expected_highlighted, expected_ids)`.
2. Stage the synthetic fixture `tests/filter-fixtures/truth-table.log`
   (committed) in a temp directory; never run against real logs.
3. For each row:
   a. Run `ltl --disable-progress --terminal-width 200 -V filter-summary
      <ltl_args> -o tests/filter-fixtures/truth-table.log` capturing
      stdout.
   b. Parse the `=== FILTER SUMMARY ===` block; assert `included`,
      `excluded`, `highlighted` match expected.
   c. Parse the `-o` CSV and assert the surviving line-IDs equal
      `expected_ids` (use `comm -23 <(sort got) <(sort expected)`).
   d. On mismatch, print the failing row label, the args, expected vs got.
4. Emit a TAP-style summary; exit non-zero on any assertion failure.
5. Reuse `tests/validate-regression.sh`'s width/locale isolation
   conventions.

## 12. Open Questions

1. **Empty-string and bare-operator semantics.** Should `-i ""`, `-i "&"`,
   `-i "&&"` be (a) accepted and documented as match-everything, (b)
   rejected with a clear error, or (c) silently treated as no-op? Today
   they're accepted with surprising results. The harness needs to pin
   one of these behaviours.
2. **Negation support.** Issue #117 added `&` but did NOT add `!`. Is
   negation a planned future feature, or is `-e PATTERN` (exclude) the
   intended way to express NOT? If the former, the truth table needs
   reserved rows; if the latter, document explicitly that `!` is literal.
3. **Per-OR-group hit counting cost.** Should the per-group counter be
   always-on, or only computed when `-V filter-summary` is requested?
   #229 §7 recommends sidecar-only for the file path; same recommendation
   here, but confirm before implementing.
4. **Regex injection / DoS.** Inline `-i` accepts arbitrary regex, which
   means a malicious or sloppy pattern (`(a+)+b`) could exhibit
   catastrophic backtracking. Is this in scope for the harness, or
   strictly a future hardening ticket?
5. **Highlight intersection with exclude.** If a line matches both
   `-e P` (excluded) AND `-h Q` (highlighted), the exclude wins
   (`ltl:4991` runs before `ltl:5030`). Should the harness assert this
   ordering explicitly as a row? (Recommend yes.)

## 13. Effort Estimate

- ltl changes (inline emission in `filter-summary`): **0.25 day**, on
  top of #229's counter infrastructure.
- Synthetic fixture + expected TSV: **0.25 day**.
- Harness script (`validate-filter-logic.sh`): **0.5 day**.
- Edge-case rows and grammar-doc updates: **0.25 day**.

**Overall: low effort, ~1–1.5 days of focused work, blocked on #229's
counter wiring and #226's section selectivity.**
