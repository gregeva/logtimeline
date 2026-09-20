# Feature: Name what to expose, discard or mask by a regular expression

## Status

- **Issue:** #582. Duplicating #5 (obfuscate or ignore a part of the message named by a pattern), closed into this issue 2026-09-20. Not blocked, and blocking nothing.
- **Phase:** specification; decisions D1 to D12 locked 2026-09-20. Acceptance criteria not yet derived — that is the next step before code (`docs/test-driven-development.md`).
- **Record:** this file. The issue body is its snapshot.
- **Governing records:** `features/user-defined-metrics.md` (the grammar this one is modelled on: the spec field table, D1 no silent reinterpretation, D2 whole match when no capture group, D4 the three diagnostic tiers, D5 parse-time hard defects, D6 the one strong-intent hint, D7 production derived after the read loop, D10 `-V udm-specs` as its own section, D12 the documented match target); `features/566-preserve-named-values-in-message.md` (`--expose`: D1 the token rule, D2 command-line order, D7 loss not presence); `features/567-discard-named-values-from-message.md` (`--discard`: D10 and D11 the comma-separated list, D12 nothing survives into any count while filters see the raw line, D14 a built-in name resolves first, D18 `-V runtime-config`); `features/580-mask-uuid-and-ip-address.md` (`--mask`: D3 one fixed placeholder per identifier version, D4 masking runs on the formed message after `--expose` and `--discard`).

## Motivating consumer

An analyst whose messages stay apart because of a part of the line that no name reaches: a per-occurrence error code written with no key beside it, a value at a fixed position in the line. `--expose`, `--discard` and `--mask` each name a part by a name — a key found by the token rule, or one of `--mask`'s built-in identifiers — and a part written as neither cannot be named at all. Hundreds of thousands of lines that are the same error stay apart as one message each, cost the memory of holding every one, and reach no statistics because each has a count of one.

## Requirements (architect's terms, 2026-09-20)

- **Regular-expression support on all three verbs.** `--expose`, `--discard` and `--mask` accept a regular expression as `-udm` does, so that a part of the line can be named by its shape where no name reaches it.
- **One grammar, common across the three.** The structure and usage extend across mask, discard and expose. In its most basic form a spec is a name, or a comma-separated list of names, exactly as the three options take today; the optional add-ons build out their capabilities in a standard manner across the verbs.
- **The work is not cut up.** The name and replacement fields are designed coherently as part of this issue, not filed separately. This touches the shipped implementations of `--expose`, `--discard` and `--mask` rather than only extending them.
- **`-udm`'s irrelevant fields go away.** Unit and function/aggregation have no meaning when the verb is a text operation rather than a measurement.
- **Detection of the final field follows `-udm`.** Where the potential exists to detect what the last field is, it is detected as `-udm` detects its own.
- **A static placeholder (#5).** The analyst can say what goes in the gap, rather than the part being thrown away or replaced by a shape derived from a built-in name.

## Decisions

- **D1 — LOCKED 2026-09-20 (architect) — One spec grammar across the three verbs: `name[:replacement]:<pattern-or-key>`.** Every field after the name is optional, and a bare name or a comma-separated list of names goes on meaning what it means today on all three options (567 D10, D11). `-udm`'s unit and function fields do not carry over: neither has meaning when the verb is a text operation rather than a measurement.

  | Spec | Reads as |
  |---|---|
  | `-d sign` | bare name, as today |
  | `-d sign,sT` | comma-separated list, as today |
  | `-m uuid` | built-in name, shape placeholder as today |
  | `-m uuid:#` | built-in name, `#` repeated per character masked |
  | `-m uuid:REDACTED` | built-in name, whole match becomes `REDACTED` |
  | `-d errcode::/ErrorCode\(([^)]*)\)/` | pattern, discarded outright |
  | `-d errcode:...:/ErrorCode\(([^)]*)\)/` | pattern, replaced by `...` |
  | `-x remote:/^(\S+)/` | pattern, appended as `remote=<value>` |

- **D2 — LOCKED 2026-09-20 (architect) — The last field is recognised as `-udm` recognises its own.** Slash-delimited is a regular expression, bare is a literal key, absent means the name is the key (`-udm` D12). The documented form is the same on all three verbs, and `name:/regex/` and `name::/regex/` both reach the pattern, because the last slash-delimited field is the pattern wherever it sits — the rule `-udm` already applies in reading `rows:/…/` and `rows:::/…/` the same.

- **D3 — LOCKED 2026-09-20 (architect) — The name is the token to match and becomes the label.** As `-udm`'s name is both the default extraction key and the column header, the name here is what is matched when no key or pattern is given, and what the part is called. `--expose` labels what it appends with it (`remote=<value>` from `-x remote:/^(\S+)/`); on `--discard` and `--mask` it is the label diagnostics report the spec by. A bare `-x fileName` goes on finding its value by the token rule and labelling it `fileName=` (566 D1).

- **D4 — LOCKED 2026-09-20 (architect) — The pattern matches the raw log line; the verb changes the message.** As `-udm`'s pattern matches the whole raw line (its D12). This is the only reading consistent with the three shipped surfaces: `--mask` substitutes into the formed message after the exposed values are appended (580 D4), `--discard` finds the part in the line but removes text only from the message and leaves the raw line for `-include`, `-exclude` and `-highlight` (567 D12), and `--expose` must read the raw line because its purpose is to reach a value that forming the message dropped. A pattern confined to the extracted message could never expose anything the message had already lost.

- **D5 — LOCKED 2026-09-20 (architect) — The verb acts on the capture group when there is one, otherwise on the whole match.** `-udm` D2 unchanged: with a capture group its text is the part exposed, discarded or masked; without one, the whole matched text is. The group is a narrowing device, so a pattern can anchor on surrounding context it does not itself act on — `/ErrorCode\(([^)]*)\)/` masks the code and leaves `ErrorCode(` and `)` standing, where `/ErrorCode\([^)]*\)/` takes the whole construct.

- **D6 — LOCKED 2026-09-20 (architect) — The replacement is one rule on both verbs: a single character repeats per character replaced; a string of two or more is used whole.** `-m uuid:#` preserves the identifier's width and `-m uuid:REDACTED` gives every match the same size, so the analyst chooses a fixed-width or a fixed-size result. The field is optional and available to the built-in names and the internal metrics, not only to patterns. Absent, a built-in name keeps its shape placeholder (580 D3) and `--discard` removes outright as it does today.

- **D7 — LOCKED 2026-09-20 (architect) — `--discard` with a replacement and `--mask` with a replacement are the same operation, and that is accepted.** Coherence across the three surfaces is worth more than avoiding the duplication: the point is to support an analyst's thinking about their logs and analysis, not to make each verb do something no other verb can. The verbs stay distinct in what they do to the *data* rather than in what the message shows: a discarded part takes no part in any count or statistic (567 D12) whatever mark is left in its place.

- **D8 — LOCKED 2026-09-20 (architect) — A replacement on `--expose` is accepted and ignored.** `--expose` adds to the message and takes nothing away, so the field has nothing to replace there. It is not a parse-time rejection: the field is optional and simply meaningless on that verb, and `-x remote:XXX:/^(\S+)/` exposes the first field with the `XXX` doing nothing.

- **D9 — LOCKED 2026-09-20 (architect) — A slash-delimited field in the replacement slot is corrected, not diagnosed. This is a departure from `-udm` D1.** `-d errcode:/ErrorCode\(([^)]*)\)/`, one colon where two were meant, is read as the pattern; an informational message states the mistake and the run continues.

  Recorded as a departure rather than as following precedent. `-udm` D1 holds that a malformed spec is diagnosed and never silently reinterpreted, because reinterpreting would change the meaning of specs that are correct today. That reasoning does not reach this case: a slash-delimited field in the replacement slot has no valid reading, since nobody replaces a discarded value with literal regex source, so there is no correct reading to change. It is the only case in which a spec is reinterpreted.

- **D10 — LOCKED 2026-09-20 (architect) — The undelimited case keeps `-udm` D6 unchanged.** A replacement field carrying regex characters (`\ ( ) [ ] * + ? ^ $ |`) but no delimiters is matched literally and earns the D6 hint in the zero-match notice only — *if you meant a regex, wrap it in slashes* — never at parse time, because the user may have meant that literal text. The two cases split on the delimiters: delimited is conclusive and corrected (D9), undelimited is near-certain and hinted.

- **D11 — LOCKED 2026-09-20 (architect) — `:` separates fields and is escaped as `\:` inside one.** A name carrying a colon is written `\:`, so `-d foo:bar` is always two fields and never a key named `foo:bar`. This reaches only a colon inside the name a key is written by: it does not reach the token rule's separator, which matches `\bkey\s*[=:]\s*(value)` with the key `quotemeta`'d, so the `:` there belongs to the pattern rather than to the spec and a line written `foo:bar` goes on being named by `-d foo` as today.

- **D12 — LOCKED 2026-09-20 (architect) — The diagnostics take a surface of their own, and nothing lands on a `-udm` `-V` section.** This is not the `-udm` feature: it takes `-udm`'s design patterns and none of its sections. A new `-V` surface targets the three verbs, a parent level with sublevels per verb where a verb needs one, reporting which specs matched and which matched nothing. It follows `-udm` D7 (the run-wide production is derived after the read loop by one walk over accumulators that already exist, never a per-line counter on the hot path) and D10 (a new section rather than an extension of an existing one).

## Why the diagnostics are in scope

The zero-match case has to be visible, for the analyst and for the harnesses this issue needs. A pattern is a selector aimed at text with no certainty it exists in the input, and a spec that matched nothing must say so.

`-udm` has this: `-V udm-specs` reports per spec how it was read, each compiled pattern, the run-wide production, the intent hint and parse-time rejections, and a zero-match notice fires per metric that produced nothing. The three message options have no equivalent — `-V runtime-config` reports the configuration the user gave (567 D18) and nothing reports what a spec produced, so a pattern that matched nothing is silent today. D12 closes that gap.

## Data and invocation

Both specimens are cross-checks rather than only examples: each targets a value that is also reachable by a name, so the pattern form has a known-good result to be measured against.

- **`--discard` and `--mask`.** A ThingWorx application log of hundreds of thousands of unique error messages (`docs/test-logs.md` § ThingworxLogs), carrying a per-occurrence code as `ErrorCode(<code>)` with no key beside it: 286,444 of its 288,025 lines, verified 2026-09-20. Without masking they are one message each, none reaching the statistics. It is #5's own specimen, truncated to the size the scenario needs (architect, 2026-09-20). Its codes are hexadecimal UUIDs, so `--mask uuid` reaches them by name: **a pattern capturing the code inside the parentheses must produce the same message count as `--mask uuid`.**
- **`--expose`.** The remote address in the first field of a Tomcat or Apache access log (`docs/test-logs.md` § AccessLogs). The formed message is `[status] METHOD /path` — verified 2026-09-20 on one day of Windchill access logs — so the remote address survives nowhere in it and no key names it, while which caller drove a slow endpoint is a first question once a problem is narrowed to an API. The same value is the subject of #537, which gives it a built-in name and parses it as an attribute so it can be filtered and highlighted too. The two do not compete: once #537 lands, `--expose remote-host` is the way to reach it by name (567 D14, a built-in name resolves first), and this issue's pattern form is the general mechanism. **A pattern targeting the first field must produce the same message output as #537's built-in name.**

## Next step

Acceptance criteria derived from these decisions and agreed before code, per `docs/test-driven-development.md`, including which harness reads each and what it asserts.
