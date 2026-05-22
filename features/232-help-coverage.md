# Feature: Help-content correctness harness (#232)

## Overview

This document is the **research and scoping deliverable** for issue #232, a sub-task of the #225 umbrella for high-priority test-harness coverage gaps. #232 covers two static-analysis assertions:

1. Every flag declared in `GetOptions` appears in `print_help()` (and, by extension, in the canonical user-facing reference at `docs/usage.md`) — or is explicitly marked hidden.
2. The version string reported by `-V` / `-v` matches `$version_number` declared in `ltl`.

This is **scoping only** — no code changes are written here. The existing `tests/validate-help-layout.sh` already covers visual column alignment; this harness covers *content correctness*, which has a documented history of drift (CLAUDE.md observation 2026-02-07).

## GitHub Issue

[#232](https://github.com/gregeva/logtimeline/issues/232) (sub-task of [#225](https://github.com/gregeva/logtimeline/issues/225))

## Sources

- `ltl` lines 4092–4168 — `GetOptions` declaration block.
- `ltl` lines 1588–1853 — `print_help()` subroutine.
- `ltl` line 64 — `$version_number`.
- `ltl` lines 1571, 1856, 7419 — emission sites for the version string.
- `docs/usage.md` (lines 28–315) — canonical user-facing options reference (the wiki is overwritten from this file on each release).
- `README.md` — short landing-page; references wiki for options.
- `tests/validate-help-layout.sh` — sibling harness covering layout only.

## § 1. GetOptions inventory

The `GetOptions(...)` call (`ltl:4092–4168`) declares **75 distinct option entries**.

| Form | Count | Notes |
|------|-------|-------|
| Both short and long forms | **66** | E.g. `'bucket-size|bs=i'`, `'verbose|V'`. |
| Long-form only            | **9**  | `disable-progress`, `no-final-pass`, `consolidation-trigger`, `consolidation-ceiling`, `consolidation-max-patterns`, `final-threshold`, `debug-layout`, `validate-layout`, `help`. |

Value-type spec breakdown (per `Getopt::Long` syntax):

| Spec | Meaning                      | Count |
|------|------------------------------|-------|
| (none) | Boolean flag               | 38    |
| `=i`   | Required integer           | 18    |
| `=s`   | Required string            | 14    |
| `:s`   | Optional string            | 3 (`-g`, `-hm`, `-hg`) |
| `:i`   | Optional integer           | 0     |
| sub-ref | Callback (not boolean)     | 5 (`-lbg`, `-hg`, `-hgw`, `-hgh`, `--no-final-pass`) |

**Short-first ordering anomalies.** Five entries declare the *short form first* and the long form second: `hgbpd`, `hgb`, `pbpd`, `pp`, `ep` (lines 4158–4162). Every other entry is `long|short`. Functionally identical to Getopt::Long, but it matters for any naive parser that assumes "first token = long name". The harness must handle both orderings.

**Hidden options (intentionally absent from `print_help`).** Cross-referenced from CLAUDE.md and code comments:

- `--disable-progress` — internal/agent-only flag.
- `--debug-layout`, `--validate-layout` — layout developer flags.
- `--terminal-width|-tw` — hidden test/automation hook (per CLAUDE.md memory).
- `--consolidation-trigger`, `--consolidation-ceiling`, `--consolidation-max-patterns`, `--final-threshold`, `--no-final-pass` — consolidation tuning knobs surfaced only via `-V` and `docs/usage.md` prose (not the canonical table).

There is **no in-code annotation** that marks these as intentionally hidden today. The harness cannot mechanically distinguish "hidden by design" from "accidentally missing"; see § 8.

## § 2. print_help() inventory

`print_help()` (`ltl:1588–1853`) emits a structured help screen via a closure `$opt->($flags, $desc)` (line 1629). Sections, in source order:

1. USAGE (single line)
2. OPTIONS — subsections: *Time & Buckets*, *Filtering*, *Recording & Processing*, *Message Grouping*, *Display & Output*, *Sorting*, *Heatmap*, *Histogram*, *Percentile mode*, *User-Defined Metrics*, *Thread Pool Activity*.
3. ENVIRONMENT (`LTL_CONFIG`)
4. INFO (`-v / --version`, `--help`, `-mem / --memory-usage`)
5. EXAMPLES

Counting `$opt->("…,…", …)` calls that document a *real* CLI flag (excluding UDM sub-rows that document positional `name`/`unit`/`function`/`/regex/` fragments of `-udm`'s spec): **58 documented options**.

The `$opt` closure parses the leading flags string with a regex anchored on `^(\S+,)\s+(.+)$` (line 1632) — i.e. it expects exactly `"-short, --long"`. Long-only entries use the alternate branch matching `^\s+(--\S.*)$` (line 1638). The harness can re-use the same regex to extract documented flags directly from a `--help` capture or from the `$opt->()` calls themselves.

## § 3. Three-way mapping table

GetOptions ⇄ `print_help()` ⇄ `docs/usage.md`. Verified by line-number citations in §1–2 plus `grep` against `docs/usage.md`.

| Long name (GetOptions key)        | Short | In `print_help` | In `docs/usage.md` |
|-----------------------------------|-------|-----------------|---------------------|
| All 58 documented options         | (mix) | yes             | yes                 |
| `terminal-width`                  | `-tw` | **NO**          | **NO**              |
| `disable-progress`                | —     | **NO**          | **NO**              |
| `debug-layout`                    | —     | **NO**          | **NO**              |
| `validate-layout`                 | —     | **NO**          | **NO**              |
| `no-final-pass`                   | —     | **NO**          | **NO**              |
| `consolidation-trigger`           | —     | **NO**          | **NO**              |
| `consolidation-ceiling`           | —     | **NO**          | **NO**              |
| `consolidation-max-patterns`      | —     | **NO**          | **NO**              |
| `final-threshold`                 | —     | **NO**          | **NO**              |
| `histogram-buckets` (`-hgb`)      | `-hgb`| yes (1779)      | **NO** (only `-hgbpd` is in the table at usage.md:238) |

### Findings

- **Code-only orphans (9 long-form-only)**: All currently understood as intentionally hidden, but unmarked in source. Need explicit annotation (§ 8).
- **Code-only orphan with a short form**: `-tw / --terminal-width` is in GetOptions only. Whether this is intentional is a judgement call — its CLAUDE.md memory note says hidden, but unlike `--debug-layout` it has a user-facing use case (driving ltl from a non-TTY context). **Open question**: surface it in help.
- **Help-vs-README drift**: `-hgb / --histogram-buckets` is documented in `print_help()` but missing from the `docs/usage.md` Histogram table. This is the single clearest "real bug" the harness would have caught.
- **No help-side orphans**: every flag documented in `print_help()` is declared in GetOptions. No help-documents-but-code-doesn't-declare cases were found.
- **No short-form rendering inconsistencies** in the print_help text itself — every documented entry uses the `"-x, --long"` convention.

## § 4. Version-string consistency

`$version_number = "0.14.5"` at `ltl:64`. Emission and reference sites:

| Site                             | Form                                       |
|----------------------------------|--------------------------------------------|
| `ltl:1571` (banner inside `print_usage`)   | `log timeline [$version_number]` — interpolated. |
| `ltl:1856` (`print_version`)               | `Version: $version_number\n\n` — interpolated, triggered by `-v / --version`. |
| `ltl:7419` (`print_verbose_output`)        | `version\t$version_number\n` — inside `=== BENCHMARK DATA ===` TSV block, triggered by `-V`. |
| `releases/v0.14.5.md`                      | Hardcoded `0.14.5`. |
| `CLAUDE.md`                                | Not pinned to a version. |
| `README.md`                                | Not pinned. |
| `build/*-package.sh`                       | Greps for "version number pattern" against `-version` output; not a hardcoded literal. |
| `.github/workflows/release-build.yml`      | Driven by `v*` tag, not a literal. |

**Status**: All in-binary emission sites interpolate `$version_number`; there is no hardcoded drift inside `ltl`. The only out-of-tree literal is the release-notes filename `releases/v0.14.5.md`, which is necessarily a per-release artifact, not drift. The harness should still assert this consistency mechanically because the risk surface is *adding a new emission site that forgets to interpolate*.

## § 5. "Suspiciously short" help-entry heuristic

Description-text quality drift is harder to catch than presence drift. Proposed heuristic, ordered by signal-to-noise:

1. **Placeholder tokens** — case-insensitive match against `TODO`, `FIXME`, `XXX`, `undocumented`, `???`, `tk`, `TBD`. Near-zero false-positive rate.
2. **Single-word descriptions** — `split(/\s+/, $desc) < 2`. Cheap, very few legitimate cases (currently none in `print_help`).
3. **Description shorter than the long-form name** — `length($desc) < length($long_name)`. Indicates the author started typing the description but used the option name. Currently never triggered.
4. **Description equals (or contains, ignoring case) only the option's long name with spaces** — e.g. description `"sort ascending"` for `--sort-ascending`. Tautology check.

Heuristics (1) and (2) are recommended for v1 of the harness; (3) and (4) are nice-to-have but riskier on the heatmap-style short rows (e.g. `-hmw` has a 6-word description, well above any threshold). Avoid a raw "shorter than N characters" rule — too noisy on terse but valid entries like `--omit-rate`.

## § 6. Application-observability gaps

This harness is overwhelmingly static analysis of the Perl source and `--help` output. Two possible ltl-side additions were considered:

### (a) `-V version` selectivity section (weak dep on #226)

Today the version literal is emitted in three places (banner, `print_version`, `=== BENCHMARK DATA ===` TSV row). The TSV row (`version\t$version_number`) is already machine-parseable. A dedicated `-V version` section is **not required** — the harness can grep the existing TSV row or call `-v`.

**Recommendation: do not add.** The TSV row at `ltl:7419` is sufficient.

### (b) `--list-options` machine-parseable dump

A flag that prints every GetOptions entry in TSV form (`long-name<TAB>short<TAB>spec<TAB>hidden`). Would simplify harness extraction.

**Trade-off**: adds a permanent CLI surface just to support tests; gives the harness a stable contract against the *Perl source's* `GetOptions` block. But the GetOptions block is already trivially parseable with a 10-line Perl regex (the harness can be Perl, and the regex is robust because the block is hand-formatted one-per-line).

**Recommendation: do not add `--list-options`.** Parse the source directly. Reconsider only if the static parse proves brittle in practice.

## § 7. Assertion shape — one harness or two?

The two concerns are independent in code but related in spirit:

- (a) GetOptions ⇄ print_help ⇄ usage.md mapping.
- (b) Version-string consistency.

**Recommendation: one harness, two test stages**, mirroring `validate-help-layout.sh`'s style. Single file `tests/validate-help-content.sh` (or `.pl` — see § 10) emits two assertion groups, with `set -e` style early-exit on first failure. Rationale: both concerns share the same setup (locate `ltl`, run it, parse source); splitting them doubles the boilerplate without doubling the signal.

## § 8. Edge cases and the "hidden option" convention

**Problem.** The harness needs to know which GetOptions entries are *intentionally* absent from `print_help()`. Today this is implicit knowledge living in CLAUDE.md and code review.

**Three candidate conventions**:

1. **Inline comment annotation.** Append `# hidden` to the GetOptions line:
   ```perl
   'disable-progress' => \$disable_progress,  # hidden
   ```
   Pro: co-located with the declaration; survives copy-paste. Con: requires a tiny parser extension.

2. **Separate sentinel array in source.** Declare `my @HIDDEN_OPTIONS = qw(disable-progress debug-layout validate-layout terminal-width ...)` near the top of the GLOBALS section. The harness reads it. Pro: one source of truth, mechanically trivial. Con: easy to forget to update when adding a new hidden flag — the same drift class this harness is trying to prevent.

3. **External list in the harness itself.** Hardcode the hidden list inside `tests/validate-help-content.sh`. Pro: keeps `ltl` clean. Con: same forget-to-update risk plus loses co-location.

**Recommendation: option 1 (inline `# hidden` comment).** Strongest co-location; harness extension is a one-line regex.

**Other edge cases:**

- The `light-background|lbg` and `no-final-pass` entries use a `sub { }` reference rather than a scalar destination. The harness's GetOptions parser must accept both `=> \$var` and `=> sub { ... }` and `=> \&named_sub` (e.g. `histogram|hg:s` → `\&handle_histogram_option` at line 4155).
- The five "short-first" entries (`hgbpd`, `hgb`, `pbpd`, `pp`, `ep`) require the parser to split `key1|key2` and decide which is short and which is long by length (`length < 6` ≈ short, with manual override for borderline cases like `-osum`, `-tpas`, `-iqs`, `-uuid`, `-hgbpd`, `-pbpd`). Safer: declare short vs long by the convention that **short forms never contain `-`**. Test: `-hgbpd` has no hyphen ⇒ short; `histogram-buckets-per-decade` has hyphens ⇒ long. This rule correctly classifies all 75 entries.
- `-V` (uppercase, verbose) vs `-v` (lowercase, version) — case-sensitive; the harness must preserve case.
- `--help` is in GetOptions but its "short form" is the legacy `-?`, `/help`, `/?` mappings at `ltl:4090`. These should not be treated as drift; the harness should special-case `help`.

## § 9. ltl code changes required

| # | Item | Effort | Notes |
|---|------|--------|-------|
| 1 | Add `# hidden` comment to 10 GetOptions lines (the 9 long-only + `terminal-width`) | XS | One commit, no behavior change. Resolves "which are intentionally hidden". |
| 2 | Decide: surface `-tw / --terminal-width` in `print_help` or keep hidden | XS | One-line judgement call; if surfaced, add to `print_help` and `usage.md`. |
| 3 | Fix existing drift: add `-hgb / --histogram-buckets` row to `docs/usage.md` Histogram section | XS | One-line table addition; this is a *latent* bug the harness will surface. |
| 4 | (Optional) Add docs/usage.md "Developer/hidden options" section listing the 10 hidden flags | S | Nice-to-have for transparency; not required by harness. |
| 5 | `-V version` section | — | **Not recommended** (§ 6a). |
| 6 | `--list-options` mode | — | **Not recommended** (§ 6b). |

No production code paths change. Items 1–3 are all documentation/annotation edits.

## § 10. Harness shape proposal

**Filename**: `tests/validate-help-content.sh` (bash wrapper) calling `tests/validate-help-content.pl` (Perl, because parsing Perl source is what we're doing). Or single `.pl` with shebang and `set -eu`-equivalent `use strict; use warnings;`. Recommend **Perl-only** for symmetry with `validate-help-layout.sh`'s in-script `perl -ne`.

**Steps**:

1. Locate `ltl` relative to `$0`; abort if missing/non-executable.
2. Read `ltl` source. Extract:
   - `$version_number` literal from line ~64 (regex `^my\s+\$version_number\s*=\s*"([^"]+)"`).
   - GetOptions block between `GetOptions(` and the next matching `) or die`.
   - Per line: capture `'(...)'` first arg; split on `|`; classify each token as short (no hyphen) or long (has hyphen or len ≥ 6); detect trailing `=i`/`=s`/`:s` spec; detect trailing `# hidden` comment.
3. Capture `ltl --help --terminal-width 120` with the same terminal-formatting strip used by `validate-help-layout.sh`. Parse using the same `^\s+(-\S+,)?\s+(--\S+)\s{2,}(.+)$` shape that `print_help()` produces.
4. **Assertion A**: every non-hidden GetOptions long-form appears in the parsed help capture. Report orphans both ways.
5. **Assertion B**: every help entry's short form (if any) matches the GetOptions short form for the same long name. (Catches typos like `-hb` vs `-bh`.)
6. **Assertion C**: parse the `docs/usage.md` options tables (rows beginning with `| \`-`) and assert each non-hidden long form appears. Report orphans.
7. **Assertion D**: capture `ltl -v` output; assert it matches `Version: $version_number` exactly.
8. **Assertion E**: capture a quick `ltl -V <small-log>` and grep for `^version\t$version_number$` in the BENCHMARK DATA block.
9. **Assertion F (soft)**: apply § 5 heuristics 1 and 2 to every help description; print warnings (not failures) to stderr unless `--strict`.
10. Exit non-zero on any assertion-A/B/C/D/E failure; exit 0 on heuristic warnings (unless `--strict`).

**Test log for D/E**: use a tiny `logs/` fixture; suggest `logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-4.2026-01-26.txt` truncated to 100 lines via existing sample-capture pattern, or any sub-MB sample.

## § 11. Open questions for human review

1. **Hidden-option convention**: § 8 recommends inline `# hidden` comments. Acceptable, or prefer the sentinel array (option 2)?
2. **`-tw / --terminal-width` disposition**: surface in `print_help` (and `usage.md`) or formally mark hidden? It has a documented user-facing use case (driving ltl from CI / non-TTY contexts), which argues for surfacing.
3. **`docs/usage.md` scope**: should the harness treat `usage.md` as part of the contract (Assertion C is a hard failure) or as a soft warning? It's the canonical wiki source per CLAUDE.md, so a hard failure feels right — confirm.
4. **Description-quality heuristic**: enable § 5 heuristics 1+2 as hard failures or stderr warnings only? Recommend warnings to start.
5. **Harness language**: Perl (mirroring `validate-help-layout.sh`'s embedded Perl) or pure bash with `perl -ne` shell-outs? Recommend Perl for cleaner GetOptions parsing.
6. **One harness or two** (§ 7): confirm single-file recommendation, or split version-consistency into its own file for granular CI failure attribution?

## § 12. Effort estimate

**Overall: LOW.**

| Component                                       | Effort |
|-------------------------------------------------|--------|
| ltl annotation changes (§ 9 items 1–3)          | 30 min |
| `tests/validate-help-content.pl` implementation | 3–4 h  |
| CI wiring + first-run debugging                 | 1 h    |
| **Total**                                       | **half-day to one day** |

No prototypes or experiments needed. The static-analysis surface is well-bounded by the GetOptions block format. Risk is concentrated in (a) the hidden-option convention decision and (b) usage.md table-parsing robustness — both deferred to open questions above.
