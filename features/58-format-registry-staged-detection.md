# Feature: Format registry and staged detection (Phase 1)

## Status

- **Issue:** #58 — **Drop 1 of the 0.17.0 merge train** (parent: #23; follows Drop 0 #180)
- **Planned:** 2026-07-15 walkthrough session (this document is the repo-side source of truth for the drop; the issue body is its GitHub-side snapshot)
- **Umbrella:** `features/log-format-registry.md` — shared requirements (sections 1–5, 11) and locked decisions D12/D13/D17/D18/D20 live there
- **Prerequisite #180: COMPLETE (2026-08-20, PR #380)** — the named stage entry points exist; see R6 for the concrete anchors this drop builds against
- **Fixes:** #369 (access-log read-phase regression). **Unblocks:** #17's declarative path (format-carried units)

## Overview

Replace the implicit match-type conditional chain (~13 hardcoded `elsif` regex branches, static order, evaluated per line) with a data-driven **format registry** scanned as a **self-ordering array of compiled patterns**. Drop 1 replaces *how a line is recognized* — nothing else: no processing-model change, no unit auto-detection, no I/O decoupling.

The cost class removed: on a 1.43M-line access log, profiling measured 6.46s of failed ThingWorx pattern attempts alone (~40% of hot-loop time); the v0.16.0 cascade true-up regressed access-log read phase 4–11.5% (#369). The format a file matched is currently remembered only as an integer `match_type` and a lossy `$is_access_log` boolean.

## Requirements

### R1 — Registry entry schema

One entry per format carrying everything downstream code currently infers from the match-type integer:

- compiled pattern (`qr//`) + pattern source (never reconstruct source from `qr//` stringification — `docs/regex-best-practices.md`)
- field mapping (which captures are timestamp, message, duration, bytes, count, …)
- **time contract** (three parts, all declarative — D23):
  - *layout* — the timestamp parse pattern
  - *precision* — what the format resolves to (s / ms / µs); drives sub-second bucketing (`-ms`), the integer-milliseconds hash-key rule, and cross-checks the `ts_precision` hint from index read-back (#179)
  - *timezone semantics* — (a) offset present in the line → parse and honor it; (b) offset absent, format documented as UTC → registry pins UTC; (c) offset absent, format writes local time → registry pins "local", and what local means resolves through the configuration cascade (CLI firmest → registry/user config → default). The format *knows*; the engine never guesses — same declarative pattern as duration units. Consumers: #155 (UTC normalization) reads cases (a)/(b); #154 (fixed rendering offset) is the display-side override.
- duration field + **declared duration unit** (D18 — declarative format-carried knowledge, e.g. Tomcat 9 `%D` = milliseconds), with an **ambiguity marker** for variants (Tomcat 9 ms vs Tomcat 10.1+/Apache HTTP µs `%D`)
- access-log property (replacing `$is_access_log`)
- **`event_pairs` reservation (D23 — reserved in this drop, consumed by #372 in the Phase 2+4 release):** an optional array of pair-pattern declarations, each holding two independent patterns (`start_pattern` / `end_pattern`, asymmetry inherent), a correlation binding (captures matched by name across the two patterns), a log-key composition template (rebuilding the merged key from captures of both sides), and a metric mapping onto canonical record fields. This drop **validates** the slot at load time (user YAML with pair declarations fails loudly, never silently) but does not consume it — placeholder-with-contract, so #372 lands without schema churn. The schema must not bake in "one line = one event."
- format name/description + sample lines (samples become per-format test fixtures)

### R2 — Detection mechanism: move-to-front ordered scan (LOCKED, D20)

An ordered array of compiled regexes, one per registry entry, tested front-to-back per line. On a match at position *i*, the winner **moves to the front**. The matched entry IS the registry entry — extraction runs from its definition.

- Detection is a **change-point workload** (one format for millions of consecutive lines; change points at file boundaries): MTF converges in one match per change point; steady-state per-line cost is one successful compiled match at index 0. Delivers the original "detect once per file" intent globally with no per-file reset bookkeeping.
- Stray-line worst case: intruder jumps to front; the next normal line pays exactly one failed match and restores order.
- Bubble-up-one (the `docs/regex-best-practices.md` sketch, proven in `match_consolidation_patterns()`) was argued and **rejected for this use**: its noise-damping pays off at high pattern counts with genuinely interleaved traffic (the consolidation problem), not ~13 patterns over near-constant streams.
- D13's multi-format/fallback contract falls out of the structure: no separate fallback path — a line failing the front pattern scans deeper; a format shift reorders the array.
- Lines matching **nothing** (continuation lines, stack traces) pay the full scan under any ordering, exactly as today. If profiling shows this cost class matters, a cheap pre-filter is an in-drop design point, independent of ordering policy.

### R3 — Built-in format migration with extraction parity

All ~13 cascade branches become registry entries. **Audit constraint (2026-07-15):** the cascade's outputs (`match_type`-conditional extraction, `$is_access_log` behavior, CSV/UDM header detection state) are consumed deep into the read loop — entries must carry all of it. Parity is per-format testable: each migrated format produces identical fields to its old branch on its sample fixtures.

### R4 — User-defined formats via YAML (D12) — **re-scoped to a follow-up issue (D37, 2026-08-20)**

The user-facing YAML surface (loader, config folder/file convention, CLI option, YAML::PP hard dependency) moves to its own issue, natively blocked by #58. This drop delivers R4's substrate: the registry schema, the sparse-override merge shape (D35), and the full D24 validation machinery, all in code and exercised by the built-ins at load.

### R5 — Format-carried units (D18 boundary)

Duration unit is registry metadata. Precedence: explicit `-du` override → format-carried unit (this drop) → index read-back (#179) → sample-based auto-detection (#17 — NOT in this drop; no unit auto-detection or speculative unit tracking inside the rewrite). Ambiguous variants get a warning; *resolving* the ambiguity statistically stays #17's follow-on (its ~100-line sampling window is the D17 detection window — see the design-tie comments on #181/#17).

*Implemented (2026-08-21, S7):*

- **Resolution chain at the per-line conversion site** (`read_and_process_logs()`, the Issue #17 conversion block): `-du` wins; otherwise the winning entry's `FR_DURATION_UNIT` applies via `convert_duration_to_ms()` when it declares a non-ms unit. Every built-in declares `ms` or no unit, so the format-carried branch converts nothing today — it exists so a non-ms format declaration (user-defined format, future Apache split) is honored without code changes. The run-level CSV-emission resolution (`$duration_unit_resolved`/`$duration_unit_source`) is untouched: it is a run-level value and format-carried units are per-file.
- **S7 unit-ambiguity note (D18).** Trigger: the **first** file in the run binding an entry with `unit_ambiguous => 1` (today exactly mt3 / slug `tomcat_access_with_duration`) **without** `-du` — emitted once per run at the first-match block, gated by `$format_unit_ambiguity_warned`. The note is phrased **run-level with no filename** (#390): the assumption covers every file the format binds in the run, so citing the arbitrary first-binding file would wrongly imply the others are unaffected. It is also **format-generic** (#390): the condition is the registry's ambiguity flag — any current or future entry can carry it — so the text names no specific log type, and it points at `-du` generically rather than prescribing a unit (the correct unit depends on the file's producer, which only the user knows). Exact text (part of this contract; the consuming harness asserts it): `Note: the detected log format's duration unit varies across producers; durations are assumed to be milliseconds - use -du to specify the appropriate duration unit for the files being analyzed`. It is an intentional stderr diagnostic: it never carries an ` at ... line` suffix (runtime-warning discriminator, HARNESS-DESIGN.md § Runtime-warning cleanliness). Contracted absences: any `-du` value suppresses it (the note surfaces an assumption; `-du` removes the assumption), and entries without the ambiguity flag never emit it. Consumers: `tests/validate-format-detection.sh` scenario `unit-ambiguity-warning` (presence + both absences); `capture-regression.sh`/`validate-regression.sh` are unaffected — their references capture filtered stdout only, and their stderr inspection is the runtime-warning check, which the note passes by construction.

### R6 — Detect-stage integration

The registry slots into #180's named `detect` role — concretely (post-Drop 0, 2026-08-20): the pre-read detect surface is `pipeline_detect()` (today `read_index_file()` + the startup memory checkpoint), and the per-line match-type cascade this drop replaces lives inside `read_and_process_logs()` under `pipeline_parse()`. Each `pipeline_*()` sub carries a contract header comment (receives/emits + resolved demand and capture modes as standing inputs); the headers on `pipeline_detect()`/`pipeline_parse()` are updated **in the same change** that moves detection into the registry, as is `docs/staged-processing-pipeline.md` § "Named Pipeline Stages". `read_index_file()` hints (#179 — timestamp range, `ts_precision`) are available detect-stage inputs. The D17 minimal detection window (hold first ~N lines; per-line re-scan on cache-miss) is the only line-holding built — no full reader/processor decoupling (#181 is architecture guidance only).

**Detection timing nomenclature (contract from #180's 2026-08-20 decision):** timing surfaces follow `stage/step` form. When this drop adds detection cost, the machine row is `TIMING	detect/<step>` and the summary-table row is `DETECT: <NAME>` with the display string **≤30 characters** (the summary table's category column is fixed at width 30; longer strings overflow). New labels need no `compare-results.sh` compat mapping — only renames of pre-existing labels do (the #180 rename map already exists there).

*Implemented (2026-08-21):* `TIMING	detect/registry_build` (benchmark-data section) and summary row `DETECT: FORMAT REGISTRY BUILD` (29 chars) time `build_format_registry()` inside `pipeline_detect()`; the value is included in `TIMING total`. Measured ~3–4 ms (compile + all D24 validation gates). The label was added to the `strip_nondeterministic()` timing-label alternation in `validate-regression.sh`/`capture-regression.sh` in the same change (the filter enumerates summary-row labels; an unlisted label would leak into the compared render).

## Out of scope

- Processing model changes (#59 — Phase 2+4 release)
- Metric visibility/purpose (#60 — Drop 2)
- Unit auto-detection or unit tracking (#17, D18)
- Full buffered-read I/O decoupling (#181, D17)
- Extraction improvements — this drop is extraction *parity* per format, not enhancement

## Research and prototype phase — MANDATORY before implementation

The registry is a new data model on the hottest path in the tool: consulted per line across tens of millions of lines, replacing hardcoded inline extraction with data-driven indirection. Changing the data model after implementation is a far larger task than validating it up front — so this drop follows the full workflow: **research → prototype → validate → refine design → record decisions → implement**. Precedent: #187 Decision 10 (prototype validation as a hard prerequisite), delivered in `prototype/` per the standard development phases.

### Research (precedes the prototype; the prototype is built on its output)

- Survey candidate entry representations and dispatch shapes; ground them against the repo's measured constants and prior findings before building anything: per-sample hash-field update ≈ 1.0–1.2 µs (#306 — bounds any per-line bookkeeping the registry adds), `docs/regex-best-practices.md` (pattern-count scaling, alternation rejection, `qr//` handling), `docs/perl-performance-optimization.md`, and the NYTProf workflow for profiling.
- Identify the candidate implementations for the highest-risk axis — **data-driven extraction dispatch**. Today each cascade branch extracts fields with inline positional code; a registry must express this as data. Candidates to research (non-exhaustive): per-format extraction closures compiled once at load; a generic capture-map loop consulted per line; named captures (`%+`) vs positional; hybrid (data-driven definitions compiled into per-format code refs at startup).

### Research findings (2026-08-20) — inputs to the prototype

Internet survey of industry practice (lnav, Fluent Bit, Logstash/grok, Vector/VRL, Promtail/Loki, GoAccess, Splunk), the multi-pattern-matching and self-organizing-list literature, and Perl-specific dispatch mechanics. These findings are *hypotheses and candidates* — the prototype is the sole proof point on speed (per this drop's exit criteria); nothing below is a decision until measured.

#### F1 — MTF is the literature-correct heuristic for this workload (validates D20)

- Sleator & Tarjan (CACM 1985) prove move-to-front is 2-competitive against the optimal offline algorithm on *any* request sequence; transpose and frequency-count are not ([paper](https://courses.grainger.illinois.edu/ece511/Fa2005/papers/Sleator.1985.CACM.pdf)). Bentley & McGeoch's empirical study finds MTF best on real, locality-heavy streams ([ACM](https://dl.acm.org/doi/pdf/10.1145/3341.3349)).
- Under locality-of-reference models, MTF is provably the *uniquely optimal* list-update algorithm (Angelopoulos, Dorrigiv & López-Ortiz, SOFSEM 2008 / [JACM bijective analysis](https://dl.acm.org/doi/10.1145/2450142.2450143)). A change-point stream is the extreme of locality.
- The known pathologies confirm the choice: frequency-count's failure mode is *inertia after a distribution shift* — exactly wrong at file boundaries; MTF's adversarial case (round-robin with no repeats) does not occur here.
- Industry precedent: lnav locks a detected format per file (first 15k lines, then lock-on, documented as a performance decision) *and* within a format moves the last-matched regex to the front — per-format MTF in production ([lnav format docs](https://docs.lnav.org/en/latest/formats.html)). MTF with a hoisted front-pattern fast path ("try cached winner, fall into the scan on miss") subsumes lnav's hard lock while staying robust to concatenated/mixed files.

#### F2 — Failed-match cost dominates a cascade; anchoring is the highest-leverage fix

- Elastic's grok benchmark ("[Do you grok Grok?](https://www.elastic.co/blog/do-you-grok-grok)"): a non-matching line costs up to **~6× a successful match** on a backtracking engine, because an unanchored pattern retries at every offset; `^` anchoring made failure detection ~10× cheaper — near parity with success. This is the mechanism behind the measured 6.46s of failed ThingWorx attempts (#369).
- Fail-fast literal/tight-class heads (`^\d{4}-` not `^.*`) let the engine reject at position 0; greedy mid-pattern catch-alls are the failure-path blow-up risk (Friedl; [Russ Cox](https://swtch.com/~rsc/regexp/regexp1.html)).
- Elastic's tiered matching (cheap shared-header pre-match → payload dispatch) bought 2.5× *unanchored* but the benefit disappears once patterns are anchored — anchor first, tier only if measurement still demands it.
- Atomic groups `(?>…)`/possessive quantifiers prune the failure-path backtrack tree (orders of magnitude on non-matching input per Friedl) — relevant only for patterns sharing a head (e.g. common timestamp prefixes) that diverge deep in the line; lower priority once anchored.
- Migration consequence: registry-pattern audit for `^` anchoring and fail-fast heads is part of the cascade migration (R3), and every failure path — including the all-formats-fail stack-trace case — becomes a near-O(1) position-0 rejection ×13.

#### F3 — Prefilter ideas that transfer to a pure-Perl scan

- The engine-level techniques (ripgrep/RegexSet/Hyperscan literal prefilters, rare-byte memchr, Teddy/Aho-Corasick) do not transfer as engines, but their *contract* does: a guard must be a **superset test** — it may pass non-matches but must never reject a true match (Hyperscan's prefilter semantics; [regex-internals](https://burntsushi.net/regex-internals/)).
- Perl's own regex optimizer already extracts anchored literal heads and runs a Boyer-Moore pre-check ([perlperf](https://perldoc.perl.org/perlperf)) — so explicit `index()`/`substr` guards add value mainly (a) to skip the `=~` invocation overhead itself, and (b) as a *shared* discriminator ruling out most of the list in one test, which per-pattern optimization cannot do.
- **First-character discriminator for the no-match population** (answers R2's open pre-filter question): continuation/stack-trace lines almost universally start with whitespace or a non-digit/non-`[` character; one `substr($line,0,1)` class test can route them past the whole scan. Must be verified as a superset test against all 13 formats' heads in the prototype.
- `index()` ≈10× a fixed-token regex for literal guards ([PerlMonks](https://www.perlmonks.org/?node_id=777323)); value concentrates on the miss path (patterns 2..13 during a scan).

#### F4 — Specificity/overlap is a correctness gate for MTF (feeds umbrella Q2)

lnav's hard rule — *each regex must match exactly one message shape* — exists because a generic pattern shadows specific ones, and lnav orders specific-before-generic by cross-testing every format's samples at startup. MTF *dynamically* reorders, so if any two registry patterns can match the same line, MTF can promote the generic one and misclassify a whole file. The prototype/implementation must cross-test all 13 patterns against every format's sample fixtures (the R1 samples) and either tighten to mutual exclusivity or pin the ambiguous entries' relative order. This turns umbrella Q2 (pattern priority) from a policy question into a testable invariant.

#### F5 — Industry schema consensus validates R1, with adoptable refinements

Across lnav/Fluent Bit/grok/Promtail/GoAccess, format definitions converge on exactly R1's shape: identity + anchored named-capture patterns + per-field *type* metadata separate from the regex + a structured timestamp contract + sample lines. Specifics worth adopting:

- **Samples are mandatory executable tests** (lnav errors at load if a sample fails its format) — strengthens R1's "samples become fixtures" into a load-time self-check candidate.
- **Duration-unit-as-metadata is established practice**: lnav `duration-field` + `duration-divisor`; GoAccess encodes the unit in the specifier itself (`%T` s / `%L` ms / `%D` µs / `%n` ns, first-wins). Runtime unit sniffing is *not* industry practice — confirms the D18 boundary.
- **Offset-less timezone policy is a standard, named knob**: Fluent Bit `time_offset`/IANA-zone/system-TZ fallback; Promtail `location`; lnav `convert-to-local-time` — matches the R1 three-case contract (D23). Promtail additionally names an explicit *unparseable-timestamp policy* (`action_on_failure`: fudge/skip).
- **Unmatched-line disposition is an explicit, observable policy everywhere** (lnav continuation lines, grok `_grokparsefailure` counters, GoAccess `--invalid-requests`) — supports the `-V format-detection` telemetry contract (match counts, scan depth, no-match counts).
- **Explicit pinning outranks detection** wherever both exist (Splunk's precedence chain; lnav `file-pattern`); half the industry (Fluent Bit, Vector, Promtail) refuses to auto-detect at all — detection is a convenience layered on a registry, never a substitute for one. A per-format file-pattern scoping hint is a cheap future-compatible slot to reserve in the YAML schema.

#### F6 — Perl extraction-dispatch mechanics (single-run magnitudes on perl 5.44/darwin; re-measure in the prototype)

Micro-benchmark preserved at `prototype/58-research-microbench.pl`; all numbers are one-run magnitudes, not blessed medians.

- **Named-capture *access* via `%+` is the trap, not named groups themselves**: `%+`/`%-` are tied hashes with per-key FETCH magic ([Tie::Hash::NamedCapture](https://perldoc.perl.org/Tie::Hash::NamedCapture)). Measured on a 6-field log-line extract: positional `$1..$6` 1363 ns/iter; `%+` access 2801 ns (~2× the entire match+extract); `@{^CAPTURE}` 1811 ns; `@-`/`@+`+substr 3521 ns. Named groups *in the pattern* read positionally cost nothing (1355 ns) — so registry patterns can keep named groups for self-documentation while generated extraction reads `$1..$n`, with name→ordinal resolved once at load.
- **qr// storage placement is second-order**: literal 941 ns vs lexical qr 1094 vs array-element 1097 vs hashref-element `$entry->{pattern}` 1158 vs interpolated 1152 — ~60 ns/line for hashref vs lexical (~0.6 s per 10M lines). Never *interpolate* a qr into another pattern at match time (documented 5–10% penalty, open [p5p #19405](https://github.com/Perl/perl5/issues/19405)); compose once at load. `/o` is off the table (perlop: "almost never a good idea" on modern perls).
- **Call overhead of leaving the elsif chain**: empty sub 33 ns; 3-arg sub/coderef ~86 ns; hash-dispatched coderef ~100 ns → one extraction-coderef call per line ≈ 0.9–1.0 s per 10M lines (~3–8% of a 1–3 µs/line budget). Fewer args / `$_[0]` access shrinks it. A **per-file/steady-state cached format coderef** (call the current winner directly, no dispatch) recovers most of it — matrix variant.
- **Load-time codegen of data-driven specs into closures is the established Perl fast path**: Type::Tiny ([Eval::TypeTiny](https://typetiny.toby.ink/Eval-TypeTiny.html)), Moose inlined accessors, Eval::Closure. No published generic-interpreter-vs-compiled-closure ratio exists for parsing — the prototype must produce it; the generic capture-map loop (candidate b) pays per-line per-field interpreter cost that closures pay once at load, so it enters the matrix as the expected loser / honest baseline.
- **Timestamp parsing**: known-fast class is compiled regex + direct arithmetic (`Time::Local::timegm`) with a **last-seen-date cache** (consecutive lines share the date part) — ~1M parses/s class vs 10–30× slower for Date::Parse/DateTime-based strptime paths ([Time::Str announcement](https://blogs.perl.org/users/chansen/2026/05/introducing-timestr.html); Perl Cookbook 3.8). Do not route per-line through `Time::Piece->strptime` with a runtime format string; compile the declared layout into the generated extraction closure.

#### F7 — YAML module (feeds the R4 in-drop decision)

- **YAML::PP** — recommended candidate: pure Perl (PAR-safe on all three platforms), YAML 1.2, spec-compliant type resolution, actively maintained (v0.41.0, 2026-06); slowest parser but load-once-config irrelevant; error messages carry line/position though self-admittedly improvable.
- **YAML::Tiny** — viable only if deliberately restricting users to a subset (no anchors/aliases, no tags, no flow collections); known to accept some invalid YAML → weaker validation UX for R4's "clear, actionable errors".
- **YAML::XS rejected**: fastest but YAML 1.1-era divergences and XS shared objects are the primary source of PAR packing failures ([PAR-Packer #67](https://github.com/rschupp/PAR-Packer/issues/67)) — unnecessary risk for a config read once at startup.
- Decision itself (YAML::PP vs YAML::Tiny) stays in-drop pending a startup-latency check of YAML::PP's compile cost.

#### F8 — Ranked prototype candidates (what the matrix must measure)

1. Anchoring + fail-fast head audit of all 13 patterns (F2) — prerequisite; makes everything else measurable.
2. First-character superset discriminator ahead of the scan for the no-match population (F3).
3. MTF as locked, plus the hoisted front-pattern fast path (F1); measure against a detect-and-lock-per-file variant (lnav model) to confirm the front-cache subsumes it.
4. Extraction dispatch: load-time codegen closures (lead) vs generic capture-map loop (baseline-of-honesty) vs inline cascade (today's baseline); positional reads throughout, `%+` excluded from the hot path (F6).
5. Per-pattern `index()`/fixed-offset guards — expected modest after anchoring; measure, don't assume (F3).
6. Specificity cross-test of all patterns against all sample fixtures as a correctness gate, not a perf item (F4).
7. Compiled timestamp arithmetic + date-cache inside the generated closures (F6).

### Application-code audit (2026-08-20) — mapping the research onto `ltl`

Read-through of the cascade in `read_and_process_logs()` (the `elsif` chain binding `$match_type` 1–13), its downstream consumers, and the `-V format-detection` surface. Each item states what the code actually does, which research finding it modulates, and what the prototype must therefore cover. Function names + snippets are the durable references; line numbers drift.

#### A1 — All 13 patterns are already `^`-anchored; the cost is shared-head overlap, not unanchored retry

Elastic's headline 6× unanchored-failure penalty (F2) is *not* the mechanism here — every cascade branch anchors at `^`. The measured #369 cost comes from anchored patterns that share long common heads and diverge late: five access-log variants share `^([^ ]+ ){3}[\[]` (mt12/4/9/3 plus mt9's quoted tail), and six formats share a `^\d{4}-\d{2}-\d{2}` timestamp head (mt1 standard, mt1 generic, mt10, mt2, mt6, mt8). A failed attempt on a same-head sibling runs deep into the line before rejecting. Consequences for the prototype: (a) the F2 payoff to measure is atomic/possessive heads and head-sharing order, not first-position rejection; (b) the existing in-code constraint — the `([^ ]+ ){3}` access-log prefix "must remain backtracking-free" (comment above mt12) — is a locked property registry patterns must keep; (c) failure-cost must be measured per pattern-*pair* (right-format line vs each wrong same-head pattern), not just per pattern.

#### A2 — The cascade encodes a deliberate, load-bearing specific-before-generic partial order; unconstrained MTF breaks it

F4's overlap warning is confirmed in our own code, with comments as evidence:

- mt10 (Connection Server standard) sits above the generic mt1/mt2 branches — "needed to move this before other more generic patterns".
- mt4 (common access) is `$`-anchored after bytes specifically "so it wins over the broader with-duration pattern below" (mt3).
- mt9 (JBoss) is `$`-anchored above mt3 because mt3's "all-optional tail would otherwise claim these lines with duration=undef and junk thread/session captures".
- mt2 (RAC) is a broad bracketed-timestamp catch-all: it *also matches mt10's lines* (capturing the thread as the level), so mt10 above mt2 is correctness, not preference.
- mt3 is the access-family catch-all with an all-optional tail; mt12/mt4/mt9 must stay above it.
- Known codified misclassification: Apache HTTP 2.x `%D` (µs) binds to `tomcat_access_with_duration` — the slug-map comment block above `%match_type_to_slug` documents it and the harness codifies current behavior (the D18 ambiguity case).

**A pure MTF array over these patterns is unsound**: one stray mt3-shaped line promotes the catch-all above mt4/mt9/mt12 and silently misclassifies every subsequent line of those formats. The registry needs an explicit priority structure — e.g. specificity tiers with MTF *within* tier, or a pinned partial order with MTF over unordered pairs — settled in the prototype. Tightening patterns to mutual exclusivity instead is *not* available in this drop: extraction parity (R3) freezes which lines match which branch, including on malformed input. This refines D20, it does not overturn it: the workload argument stands; the reorder rule gains constraints.

#### A3 — Cascade branches are capture + normalization + derived values, not pure recognition

Every branch mutates its captures before downstream code sees them: metric masking for grouping (`s/ ((bytes|durationM[sS])\s*=\s*)(\d+)/ $1?/g` in mt1, `? millseconds` in mt10), HTTP status bucketing (`s/(\d)\d{2}/$1xx/`), timezone chops, `tr/T/ /` and `tr/,/./` timestamp normalization, CLI-gated trims (`$include_query_string`, `$include_session`), ephemeral-port masking (mt10), GC heap delta `convert_bytes($heap_from) - convert_bytes($heap_to)` clamped at 0 (mt6), and Edge-SDK PID-strip + `\w+\.cpp:\d+` object hoist (mt11). A registry entry must therefore carry a *transform stage*, not just a capture map — this materially favors the compiled-closure candidates (F6 lead) over a generic capture-map loop, which would need a declarative mini-language to express these. Prototype fixture obligation: per-format sample lines that exercise every mutation (masked metrics, query strings, sessions, GC heap forms, cpp-tagged Edge lines), asserting byte-identical `$message`/field output.

#### A4 — `$is_access_log` is only partly format-static; the registry flag must be split

The access-log family, GC (mt6, "need this to have statistics calculated"), and CSV set it statically — but mt1 sets it *per line* only when ` bytes=`/` durationMs=` appear in the message, and the format-independent count-metric and UDM extraction blocks set it on any format (`$is_access_log = 1 if %udm_values`). It gates three statistics-capture paths (`if ($is_access_log)` in consolidation stats-source build, per-message stats, per-bucket stats). A naive static registry property would switch ThingWorx logs to always-on statistics — a behavior change. The registry needs two concepts: a format-level *statistics-eligible* property and the per-line *metrics-observed* dynamic; parity fixtures for mt1 must include both metric-bearing and plain lines.

#### A5 — The record representation is itself a hot-path axis: today's cascade binds ~19 pre-initialized scalars per line

The loop initializes 12 string + 7 numeric scalars every line and the cascade binds them by list-assignment inside the `elsif` conditions. Against the #306 constant (~1.0–1.2 µs per hash-field update), returning a per-line record *hash* from an extraction closure could add ~10 µs/line — far exceeding any dispatch savings. The prototype matrix must measure record shape explicitly: closure returning a fixed-order list into the existing scalars vs hashref record vs writing package/closure variables. (This was implicit in charter item 2; the audit makes it a named risk.)

#### A6 — Timestamp machinery already implements F6's fast path; the registry must preserve its exact semantics

`%timestamp_cache` (epoch per unique post-strip timestamp string) is precisely the research-recommended cache; the two parse families (ISO `substr`+`timegm`, Apache `dd/Mon/yyyy` via `%month_map`) are selected by the mt-number groupings `match_type == 1 || 2 || 5 || ...` vs `3 || 4 || 9 || 12` — the classic "code knows what's declared nowhere" this drop replaces with the R1 time contract. Parity constraints: fractional-ms is stripped by a *shared* `s/(:\d{2}:\d{2})[.,](\d{1,6})/$1/` after per-branch timezone chops, so the cache key excludes both offset and fraction; offsets are *discarded* today (mt1/access chop them, mt5 chops `+HH:MM`) and must remain discarded in this drop (the declarative tz semantics get consumers only in #155/#154); the index `ts_precision` hint flips on `$fractional_ms > 0`; CSV adds the epoch path plus the #328 unparseable-timestamp skip-and-warn. The mt13 ISO-shape guard (`$timestamp_str !~ /^\d{4}-...` → skip row) and the mt3-junk duration guard (`$duration !~ /^[0-9]+(?:\.[0-9]+)?$/` → undef) are behavior to keep byte-identical.

#### A7 — CSV (mt13) is not a regex format and cannot live in the MTF array as-is

CSV detection is stateful and lazy (#107): active only when `@udm_configs` is non-empty, line 1 stashed as potential header, confirmed only when line 2 *also fails every log pattern* and field-counts validate (`detect_and_parse_csv_header()`); extraction is `split`-based with column-index UDMs, and any log-format match on lines 1–2 disqualifies CSV. In-drop schema decision: either registry entries support a non-regex *matcher kind* (coderef matcher), or CSV remains a special pre/post-scan stage outside the array. Either way the ordering dependency — CSV confirmation requires the full scan to have *failed* — must survive MTF.

#### A8 — Today there is no lock: detection is per-line, and the per-file binding is observability-only

`%format_detection` binds `match_type`/slug at the *first* matching line per file, then only counts `matched_lines`/`unmatched_lines`; every line still runs the full cascade. So the registry's MTF changes runtime behavior of detection order but must not change the reported per-file semantics (`first_match_line`, matched/unmatched counts, slug set). The slug names are a locked harness contract (`tests/validate-format-detection.sh`; slug map states renames are breaking, and the Apache-µs note already anticipates a harness update when the registry lands). The `-V` section-contract stub below inherits these preserved keys plus the new scan-depth/order telemetry.

#### A9 — Format-carried duration units, as they exist implicitly today (feeds R5)

mt1 `durationMs`=ms; mt10 `N milliseconds`=ms; mt12 `[%Dms]`=ms explicit (its `[%Ts]` seconds capture is discarded); mt3 `%D` assumed ms (Tomcat 9) — the ambiguous case (Apache/Tomcat 10.1+ µs) that gets the D18 marker + warning; mt9 trailing integer=ms; mt6 GC pause decimal ms; CSV/`-du` via `convert_duration_to_ms()`. The registry entries transcribe exactly this table; the ambiguity warning has precisely one trigger today (mt3's slug).

#### A10 — Adjacent per-line costs observed during the audit (explicitly *not* this drop's scope)

Recorded so the prototype baselines don't mistake them for cascade cost, and as candidates for later issues: the log-level gate is a per-line linear `grep { $_ eq $category_bucket } @log_levels`; UDM patterns match via interpolation (`if (/$pattern/)`) paying the qr-interpolation penalty (F6, p5p #19405) per line per config; the count-metric regex runs on every matched message. All stay behavior-identical in this drop.

#### A11 — Message-metric probes (bytes/durationMs/count/UDM): the two-step extraction dimension

The secondary in-message metric extraction is a two-step design: the format regex recognizes the line, then separate probes extract optional named metrics from the message. The original shield — "the generic second step only runs against ThingWorx lines" — holds today for ` bytes=`/` durationMs=` (inside the mt1 branch) but **not** for the count probe (`if( !$omit_count && defined $message )` sits outside the cascade and runs on every matched line of every format) or for the UDM probes (likewise format-independent). Part of the intended shield no longer exists.

Fusing the probes into the single compiled format regex is *not* the expected win: optional position-variable metrics require optional scanning groups (`(?:.*? bytes\s*=\s*(\d+))?`), which re-introduce mid-pattern unbounded scans on every line including the metric-less majority (F2), go combinatorial when metrics can appear in any order, and couple recognition cost to extraction cost — every failed detection attempt by another format also pays the tail. Precedent: the #306 fused-moment lesson (the fused update measured 7–8× the pass it replaced; premises are measured, not assumed).

Registry-native design instead: the entry carries a declared optional `message_metrics` list (name, pattern, unit, mask template), compiled at load into the per-format extraction closure — encoded into the compiled *closure*, not the compiled *regex*. This restores the shield declaratively (only formats declaring probes pay them — count included), turns mt1's implicit behavior into data, unifies vocabulary with the UDM configs (one resolution surface per vocabulary), and permits an `index($message, ' bytes')` literal pre-check before each probe regex — the same sub-determination idiom D23(a) locks for event pairs.

Parity boundary: making the count probe format-scoped would change behavior, so this drop carries the probes as data with today's global count/UDM behavior intact; *which formats/families run which probes* is a visibility/purpose question and is handed to #60 (see D25). Boundary with #60 recorded as guidance on that issue.

#### A12 — Failed elsif condition assignments clobber the per-line initializers; extraction defaults are a function of the winner's static position (found 2026-08-20, S2 implementation)

The per-line scalars are initialized to `""` (strings) / `undef` (metrics) / `0` (numerics), but a failed `elsif` *condition* of the form `( $a, $b ) = $_ =~ /.../` assigns the empty list on no-match, which **undefines its named targets**. By the time a later branch wins, every field captured by any statically-earlier branch's condition has been clobbered to `undef` — e.g. an mt10 line reaches downstream with `$instance`/`$user`/`$session`/`$platform` = `undef` (clobbered by the failed mt1 attempt), while an mt1 line carries `""` for its empty bracket captures. The value downstream sees for a field the winner does not capture is therefore *per-format deterministic under the static order* — and would silently change under MTF, which skips the earlier failed attempts. Consequence for D27: each entry's generated extraction closure bakes per-field defaults computed from the clobber union of the entries ahead of it in static order (`build_format_registry()` computes this from the field maps), making extraction byte-identical regardless of dynamic scan order. The P2 dispatch mini did not surface this because its inline oracle was a single-branch runner with all-`undef` declarations; the S2 sample oracle (verbatim full cascade) did.

#### Prototype coverage additions distilled from the audit

Beyond the F8 ranked list: (1) constrained-MTF variants (tiered / pinned partial order) with a misclassification test built from each format's samples cross-run against the full array (A2); (2) pattern-pair failure-cost measurement on shared-head siblings (A1); (3) record-shape comparison list-return vs hashref (A5); (4) transform-stage expression — closure-compiled vs declarative — over the A3 mutation inventory; (5) fixtures asserting `%timestamp_cache` semantics and the A6 guard behaviors; (6) CSV matcher-kind decision (A7); (7) `-V format-detection` output preserved byte-compatible for existing keys while adding scan telemetry (A8); (8) message-metric probe placement — fused-into-format-regex vs closure-compiled probes vs index()-guarded closure probes, measured on metric-bearing *and* metric-less lines (A11).

### Prototype charter (`prototype/`, no production code)

Compare the candidate implementations, measured at representative scale (staged 1k → 10k → 100k → millions of lines, per the NYTProf sample plan), against today's inline cascade as the baseline:

1. **Registry entry structure** — build-up cost at startup and memory footprint (`Devel::Size`), hash-of-hashes vs array-of-entries access cost per line.
2. **Hash/field access in the hot loop** — per-line cost of reading the matched entry's metadata (field map, units, flags) under each candidate structure.
3. **Extraction dispatch** — per-line cost of each candidate vs the inline baseline; this is the axis most likely to regress and the one the choice hinges on.
4. **MTF reorder cost** — splice-to-front cost at realistic reorder frequencies (rare in steady state; measure the change-point burst too).
5. **Detection window handling** — cost of holding/replaying the first ~N lines.

### Exit criteria

- A chosen approach with measured justification (memory + timing tables, medians with ranges, vs baseline).
- Matched-line extraction shows **no regression** vs the inline baseline within noise; detection-phase improvement consistent with the #369 expectation.
- Lessons learned and the resulting design refinements recorded back into this document as decisions (Dxx) **before** implementation begins.

### Prototype findings (2026-08-20 —) — measured on the fixture dataset

Prototype infrastructure: `prototype/58-generate-fixtures.sh` deterministically regenerates the 27-fixture dataset into `/tmp/ltl-58-fixtures/` (7 families × 1k/10k/100k/1m from the repo's known test logs; `pure-scriptlog-dense` capped at 100k; provenance in its manifest and header). `prototype/58-measure.pm` is the shared measurement scaffold: warmup + N runs, median with min–max range, ns/line, RSS delta, one TSV shape. `prototype/58-baseline-extractor.pl` is the faithful copy of the recognition region of `read_and_process_logs()` (all 13 branches, inert-guard fidelity, parity-accumulator surface all candidates must reproduce).

#### P1 — Full-cascade baseline: the removable cost class, quantified per fixture

Median at 1m fixture size, 5 runs, ranges ≤3% (1k/10k spot checks consistent in ordering); wall seconds are the absolute cost of one full recognition pass over the fixture:

| fixture (1m lines) | ns/line | wall |
|---|---|---|
| pure-access | 6,448 | 6.45 s |
| interleave-100 | 5,642 | 5.64 s |
| concat-pair | 5,626 | 5.63 s |
| pure-gc | 5,161 | 5.16 s |
| pure-scriptlog | 4,892 | 4.89 s |
| twx-blend | 3,535 | 3.54 s |
| pure-scriptlog-dense (100k cap) | 6,042 | 0.60 s/100k |

Composition caveat for cross-size comparisons: the blend and sparse-scriptlog families change mix with slice size (blend is 74.6% continuation lines at 1k but only 17% at 1m; sparse metric-bearing lines are 0% at 1k, ~13% at 1m), so per-size numbers for those families are workload-shift measurements, not noise.

Confirmations of A1/A2 mechanics: access lines are the *most* expensive matched class (each mt3 line first fails 7 earlier patterns incl. 4 same-head access siblings); no-match continuation lines are the *cheapest* (all 13 anchors reject near position 0) — the F3 discriminator's value is therefore bounded low on this population. The dense-vs-sparse scriptlog gap at equal 100k scale (6,042 vs 4,799) prices the A11 message-metric probes + masking at ~1,240 ns/line on metric-bearing lines — ~1.2 s per million such lines.

Fixture characterization recorded during scaffolding: GC fixtures match mt6 on only ~42% of lines — `Pause Remark`/`Pause Cleanup` carry no cause clause and fall through (#382 filed, backlog); metric-bearing lines (any of bytes/count/durationMs) in the sparse scriptlog family are 0% at 1k, ~0.5% at 100k, ~13% at 1m (they cluster late in the pool), while every dense-family line is metric-bearing — sparse measures the probes' miss path, dense their hit path.

#### P2 — Extraction dispatch (charter item 3, F8-4): closures are viable; interpreter is out; list-return beats hashref

`prototype/58-dispatch-mini.pl`: single-pattern match + extraction + identical common-mode post-steps (count probe, threadpool, guards), lines pre-loaded, I/O and scan order excluded — the steady-state MTF position-0 workload. All candidates byte-identical to the inline branch on every line of every fixture tested (parity gate built in, `--verify-only`); the closure candidates are *generated at load from declarative specs* (capture→field map + named transform primitives), i.e. the registry-entry shape itself.

Median ns/line at 1m fixture size (dense at its 100k cap), 5 runs; 10k/100k consistent. Absolute deltas are per million lines vs inline:

| candidate | pure-access (mt3) | pure-scriptlog (mt1) | dense-100k (mt1+probes) |
|---|---|---|---|
| inline (today's branch) | 3,527 | 4,316 | 5,522 |
| closure-list | 3,646 (+3.4%, +0.12 s/M) | 4,488 (+4.0%, +0.17 s/M) | 5,737 (+3.9%) |
| closure-hashref | 3,854 (+9.3%, +0.33 s/M) | 4,627 (+7.2%, +0.31 s/M) | 5,954 (+7.8%) |
| capture-map interpreter | 6,217 (+76%, +2.69 s/M) | 6,511 (+51%, +2.20 s/M) | 7,871 (+43%) |

- **Closure-list: +119–215 ns/line over inline (+0.12–0.17 s per million lines)** — matches F6's prediction (coderef call ~86–100 ns + list-return copy). A ~2–4% dispatch tax against the 4.9–6.4 µs/line full-cascade baseline.
- **The tax is dwarfed by the removable class**: pure-access full-cascade 6,448 vs dispatch-only inline 3,527 ns/line at 1m ⇒ ~2,920 ns/line (~45%, 2.92 s per million access lines) is failed same-head sibling attempts — #369's mechanism, now quantified. MTF steady state removes it; the closure costs back ~0.1–0.2 s/M.
- **Record shape (A5 named risk): settled toward list-return.** Hashref costs a consistent +200–330 ns/line over list-return (~0.2–0.3 s per million lines) — real but far below A5's ~10 µs worst case, which assumed per-field hash updates rather than one-shot anonymous-hash construction. List-return into the existing scalars is the lead unless a later axis contradicts.
- **Capture-map interpreter confirmed as the loser** (+2.0–2.7 µs/line): per-line declarative interpretation is off the hot path for good; declarative *definitions compiled to closures at load* is the shape (consistent with F6's codegen precedent and A3's transform inventory).

#### P3 — Constrained-MTF ordering (A2/F8-3, coverage item 1): pinned-closure MTF is correct and free; the remaining access cost is same-head rejects, not ordering

`prototype/58-mtf-mini.pl`: recognition-only over the 12 regex entries (CSV outside the array per A7; the two mt1 branches are separate entries). **Correctness criterion = R3 parity: a policy is correct iff it classifies every line identically to today's static cascade order**, tested per line. Constraints are *derived at load* from per-format sample lines via the F4/D24 cross-shadowing test — every A2-documented pair fell out automatically (mt12/mt4/mt9 ≺ mt3; mt10 ≺ mt2/mt8) plus four only the cross-test found (mt1std ≺ mt1gen; mt1std/mt1gen/mt10 ≺ mt2; mt1gen ≺ mt8). Derived closure/tiers: mt2 ← {mt1std, mt10, mt1gen}; mt3 ← {mt12, mt4, mt9}; mt8 ← {mt1std, mt10, mt1gen}.

Policies: `static` (today); `mtf-free` (unconstrained); `mtf-pinned` (winner promoted to front *together with its ancestor closure*, relative order preserved, no-op promotions skipped); `tier-mtf` (DAG-depth tiers, MTF within tier).

- **Correctness:** `mtf-free` **fails exactly as A2 predicted** — one stray mt3-shaped line flips every subsequent mt4/mt9/mt12 line to mt3 (100/201 lines wrong per adversarial stream; 392/900 on an all-formats round-robin). `mtf-pinned` and `tier-mtf` are line-identical to static on every adversarial stream and every fixture. D20's reorder rule is hereby refined to **pinned-closure MTF**.
- **Timing** (1m fixtures, classification only, median of 5, ranges ≤1%; 10k/100k consistent). Absolute seconds are per million lines:

  | fixture | static | mtf-pinned | Δ abs | mtf-free (invalid ceiling) | tier-mtf |
  |---|---|---|---|---|---|
  | pure-access | 4,322 ns/l = 4.32 s | 4,108 ns/l = 4.11 s | **−0.21 s (−4.9%)** | 1,028 ns/l = 1.03 s (−3.29 s) | 5,501 ns/l (worse) |
  | pure-gc | 4,297 ns/l = 4.30 s | 3,394 ns/l = 3.39 s | **−0.90 s (−21%)** | 3,398 ns/l (same) | 3,536 ns/l |
  | twx-blend | 1,807 ns/l = 1.81 s | 1,934 ns/l = 1.93 s | **+0.13 s (+7%)** | 1,890 ns/l | 2,092 ns/l |

  On the 1m access fixture, pinned saves ~0.21 s of the 4.32 s classification pass while the invalid ceiling shows ~3.29 s available; on the 1m GC fixture the pinned win is already large (0.90 s). **Blend regression is an implementation artifact, not an ordering cost**: with zero reorders and identical attempts/line (3.04), the mtf loop's per-attempt array-indexing/bookkeeping overhead (~40 ns/attempt vs static's direct entry iteration) shows through on low-attempt workloads — a production implementation must keep the steady-state scan loop as lean as the static one (hoisted front-entry fast path, index-free iteration), which P3's structure did not optimize. Change-point/interleave fixtures: mtf-pinned ≈ static or slightly better at 10k, reorders = 2 and 100 — reordering itself is essentially free at realistic change-point rates. `tier-mtf` is strictly worse everywhere (its tier-0 holds nine entries scanned before mt3's tier) — **rejected**.
- **The design finding:** on the #369 access workload, constrained ordering alone recovers only ~5% (4,108 vs 4,322 ns/line; ~0.21 s per million lines), because the pinned predecessors mt12/mt4/mt9 *must* be attempted before mt3 on every line, and those same-head siblings are precisely the expensive failures (A1) — the cheap first-char rejects that MTF skips cost almost nothing. The gap to the (correctness-invalid) mtf-free ceiling — 4,108 → 1,028 ns/line, ~3.08 s per million lines — is entirely same-head sibling rejects. **The #369 prize therefore requires making the pinned predecessors cheap to reject, not reordering them away**: per-entry cheap superset guards (F3 contract — e.g. mt12 only possible when the line contains `ms] [`; mt4 only when the line *ends* after the bytes field; mt9 only when a quoted user-agent tail is present) and/or A1 atomic/possessive same-head work. That is the next mini-proto axis (F8-5 + coverage item 2), measured against this P3 baseline.

#### P4 — Cheap superset guards (F8-5, A1, coverage item 2): selective per-entry guards recover the access prize; guards are opt-in data, never blanket

`prototype/58-guards-mini.pl`, on top of P3's pinned-closure MTF. A guard is registry-entry *data* compiled to a closure at load: a cheap test that may false-positive (one wasted attempt) but must never false-negative (misclassification). Soundness is verified empirically — pattern match ⇒ guard pass on every fixture line and sample (0 violations throughout), plus full classification parity vs the static cascade for every candidate. Ramped 1k → 10k → 100k → 1m; ordering stable at every step; blessed numbers from the single final 1m battery (median of 5, ranges ≤1%; ns/line = wall seconds per million lines):

| fixture (1m) | pinned (P3) | +guards (all entries) | +sel-guards (mt12/mt4/mt9 only) | +fam-guards (shared `] "` prefilter) | +atomic | mtf-free ceiling |
|---|---|---|---|---|---|---|
| pure-access | 4,235 (4.23 s) | 2,947 | **2,941 (2.94 s, −1.29 s)** | 3,278 | 3,895 | 1,083 |
| pure-scriptlog | **2,401** | 2,571 | 2,420 | 2,439 | 2,405 | 2,408 |
| pure-gc | 3,681 | 4,079 | 3,866 | **3,617** | 3,647 | 3,670 |
| twx-blend | 2,015 | 2,132 | 2,065 | **2,026** | 2,006 | 2,020 |
| interleave-100 | 3,438 | 2,875 | **2,794** | 2,962 | 3,247 | 1,806 |

- **Recommendation: `sel-guards` — guards only on the expensive-to-reject access siblings** (mt12: `index 'ms] ['`; mt9: `index '" "'`; mt4: `rindex '" '` + one-token tail). Recovers **−1.29 s per million access lines (−31%)** and −0.64 s/M on interleave; worst regression +0.19 s/M (GC), elsewhere ≤0.05 s/M. Guards on cheap-to-reject entries are a net *loss* (full-set `+guards` regresses GC by +0.40 s/M: an `index()` miss scans the whole line, costing more than the cheap regex reject it replaces) — **guard placement is a per-entry measured decision, part of the entry's data, never blanket policy**.
- **Atomic same-head heads: subsumed.** Alone they recover only −0.34 s/M on access; combined with guards they add nothing (the guarded sibling regexes never run). Dropped from the design.
- **Rejected variants** (10k iteration; kept in the mini-proto as negative results): *tail-window "O(1)" guards* — digit-ending non-access lines (stack-trace `…:123`) pass the last-char prechecks and pay full-line `rindex`/`tr` scans, regressing blend by ~+0.37 s/M; *fam2 winner-skip* — the extra per-entry branch costs what the skipped family check saves. The *family-shared prefilter* (`] "` memoized once per line across the four access entries) is the balanced alternative — best on GC/blend, but gives back 0.34 s/M of the access prize; not recommended while access logs are the driving workload, retained as a measured option.
- **Remaining headroom:** access sits 1.86 s/M above the (correctness-invalid) free-MTF ceiling — three guard-closure calls plus their scan costs per line. Inlining guard tests into generated scan code (no closure call) is the identified next increment if the gate probe demands more; not pursued in the mini-proto.

#### P5 — Registry entry structure & memory (charter items 1–2): build and footprint are negligible; array-of-arrays with constant indices wins the scan loop

`prototype/58-entry-struct-mini.pl`: the same fully-loaded 13-entry registry (R1 shape — identity, compiled pattern + source, field map, transforms, time contract, unit, statistics flag, samples, message-metric declarations, compiled extraction/guard closures, pinned ancestors) materialized in four container shapes, built from one declarative spec. Scan measurement runs the P4-winning configuration with identical logic per shape (direct field access — an early harness draft measured accessor-closure indirection instead of the containers and was rewritten); parity gate per shape before timing; ramped 1k → 10k → 100k → 1m, ordering stable at every step.

- **Build cost and memory are non-factors.** Full registry construction — 13 pattern compiles, guard/extractor closures, all metadata — costs **161–188 µs** (one-time startup) and **73–82 KB** total (`Devel::Size`, ~5.7–6.3 KB/entry, dominated by compiled patterns and sample strings). No shape is meaningfully cheaper to build; `aoa` is smallest.
- **Scan-loop container access, 1m fixtures (median ns/line; deltas vs the winner):**

  | shape | pure-access | pure-scriptlog | twx-blend |
  |---|---|---|---|
  | `aoa` array-of-arrayrefs, constant indices | **2,907** | 2,475 | 2,049 |
  | `soa` parallel arrays + scan-order index | 2,994 (+0.09 s/M) | **2,474** | **2,027** |
  | `aoh` array-of-hashrefs | 3,142 (+0.24 s/M) | 2,551 (+0.08) | 2,161 (+0.11) |
  | `hoh` hash-of-hashrefs + order array | 3,146 (+0.24 s/M) | 2,574 (+0.10) | 2,293 (+0.24) |

- **Recommendation: `aoa` — entries as arrayrefs with `use constant` field-name indices.** Hash-field lookups cost the aoh shape +0.08–0.24 s per million lines in the scan loop; hoh's extra name→entry lookup per scan step makes it strictly worst — rejected (its YAML-merge convenience belongs at *load* time: merge in a hash, then freeze into the aoa scan array). `soa` is statistically equivalent to aoa but splits one entry across parallel arrays, complicating reorder and readability for no measured gain — not recommended. Constant-named indices keep aoa as legible as a hashref while paying array-index cost.
- Only the hot fields (pattern, guard, name, and the few post-match metadata reads) are touched per line — cold metadata (samples, sources, field maps) rides along in the same arrayref without per-line cost, so no hot/cold split is warranted.

#### P6 — Message-metric probe placement (A11/D25, coverage item 8): fusion rejected empirically; index-guarded closure probes with an `=` outer gate win

`prototype/58-probe-mini.pl`: single-pattern mt1 recognition (P2 isolation protocol), probes for bytes/durationMs/count, masking identical in every candidate. The fused candidate was implemented as fairly as possible — optional *lookahead* captures anchored at message start (order-independent, lazy `.*?` for first-occurrence parity) — and still loses. Parity: every candidate byte-identical to inline (post-mask message, all three metrics) on every line at every size, including the full 1m sparse pass. Ramped 1k → 10k → 100k → 1m (dense capped at its 100k maximum, which is its final size).

| candidate | dense-100k (hit path, ns/line) | sparse-1m (miss path, ns/line = s/M) |
|---|---|---|
| inline (today) | **4,544** | 3,556 (3.56 s) |
| fused into recognition regex | 4,940 (+396) | 4,644 (**+1.09 s/M**) |
| index-guarded probes | 4,591 (+47) | 3,508 (−0.05 s/M) |
| `=` gate + guarded probes | 4,638 (+94) | **3,299 (−0.26 s/M)** |

- **D25 confirmed empirically: probes stay out of the recognition regex.** Fusion costs +1.09 s per million metric-less lines (the majority population in real streams) and +0.40 s/M even on the pure hit path — the A11 prediction, now measured, closing the loop the #306 lesson demanded (premise measured, not assumed).
- **Recommendation: closure-compiled probes with per-probe `index()` guards behind one `index($message,'=')` outer gate.** The outer gate is a superset of every probe literal (all probes require `=`), bounds the miss path to a single scan (−0.26 s/M on sparse), and costs +94 ns/line on fully-dense streams — a workload no real mixed log sustains. All three layers (gate, per-probe guard literals, probe regex + mask template) are declarative registry entry data compiled at load — the D25 shape holds unchanged.
- The count probe migrates with its current global scope (parity boundary, D25); scoping remains #60's question.

#### P7 — Detection-window replay cost (charter item 5, D17): free at realistic window sizes; two-phase-store is the shape

`prototype/58-window-mini.pl`: hold-the-first-N-lines designs priced against no-window, all running the P4 scan configuration with an identical extraction stand-in; accumulator parity gated before timing; ramped 1k (too noisy to read — sub-4 ms totals) → 10k → 100k → 1m, window = 1000.

- **At 1m the window mechanism is free in every variant**: deltas vs no-window are +8–54 ns/line across all three fixtures — at or inside run-to-run ranges. The overheads visible at small scale (reclassify's double classification of window lines, naive's per-line branch) are window-fraction artifacts that vanish as N/total → 0; a 1,000-line window is 0.1% of a 1m stream.
- **Buffer memory is linear and negligible**: ~310–575 bytes per held line for `[line, entry]` pairs (~185–450 raw lines only) — 0.3–0.6 MB for a 1,000-line window, 1.8–5.8 MB even at 10,000 lines.
- **Design choice therefore falls to structure, not speed: `two-phase-store`** — window loop classifies each held line once and stores `[line, entry]`, flush runs deferred extraction, then a *clean* steady loop with no window check (the P3 lean-loop lesson applied). `reclassify` (hold raw, classify twice) is acceptable if buffer simplicity is ever preferred; `naive-branch` (window test left in the hot loop) is measurable at small scale and structurally worse for zero benefit — avoided.
- Consequence for D17: the minimal detection window can be sized generously (hundreds to a few thousand lines) without measurable cost; the binding constraints are memory (trivial) and time-to-first-output, not throughput.

#### P8 — Timestamp-cache parity semantics (A6, F8-7): contract closures achieve exact parity; today's per-second cache grows unbounded on sparse-timestamp streams

`prototype/58-timestamp-mini.pl`: today's two parse families (ISO `substr`+`timegm`; Apache `dd/Mon/yyyy` via the month map) and the shared `%timestamp_cache` re-expressed as the R1 **time contract** — `layout` declared per entry, compiled at load into a parse closure with identical cache semantics — plus F6's last-seen-date cache as a measured alternative. Isolation protocol as P2/P6 (untimed prep yields the exact post-chop `timestamp_str` stream today's code sees). **Parity is exact**: per-line `(timestamp, fractional_ms, epoch)` triples identical across all candidates on every line of every fixture at every size, cache key-sets identical for the contract candidate, `ts_precision`-flip semantics identical. Ramped 1k → 10k → 100k → 1m.

1m results (median ns/line; cache after the full pass):

| fixture (1m) | inline (today) | contract closure | date-cache | inline cache | date-cache cache |
|---|---|---|---|---|---|
| pure-access | 703 | **696** | 822 | 46,682 keys / 5.8 MB | 1 key / 333 B |
| pure-scriptlog | 857 | **837** | 1,026 | 19,799 keys / 3.7 MB | 1 key / 332 B |
| pure-gc | 2,481 | 2,340 | **985 (−1.50 s/M)** | **694,101 keys / 100.7 MB** | 54 keys / 6 KB |

- **For the drop: the contract closure is the shape** — declarative layout compiled at load, byte-exact parity, and slightly *faster* than inline (−7 to −141 ns/line; the closure-call overhead disappears entirely once inlined into the per-format extraction closure). R1's time contract is validated end-to-end: offsets stay discarded (chops before the shared fractional strip), cache keys exclude offset and fraction, precision hint flips on `fractional_ms > 0`.
- **Cache efficacy is data-dependent, not format-dependent**: the driver is the unique-seconds-to-lines ratio. Dense bursts (scriptlog: 50 lines/s) hit the per-second cache constantly; sparse event streams (GC: ~0.7 unique seconds *per line*) miss 69%+ and pay `timegm` per miss.
- **Finding worth its own attention: today's cache grows unbounded on sparse-timestamp files — 100.7 MB after one million GC lines.** The date-cache variant (midnight epoch per date + HMS arithmetic, exact under `timegm`'s pure-UTC math) bounds it at keys = days (6 KB) *and* is 2.5× faster on that population, at a cost of +120–170 ns/line on dense streams. Candidate resolutions for the drop or a follow-up: per-layout choice is wrong (it's the data, not the format); a last-second scalar memo in front of the date-cache would likely recover the dense-stream loss — unmeasured, noted as the tuning option. This memory behavior exists in production `ltl` today, independent of the registry work — filed as #383 (unbounded timestamp-cache growth on sparse-timestamp files), backlog.

#### P9 — CSV matcher-kind (A7): CSV stays a per-file stage outside the scan array; the registry carries a non-scanned `csv` entry

Design analysis plus a correctness demonstration (`prototype/58-csv-mini.pl`).

**Why a matcher-kind inside the MTF array fails structurally.** CSV's lifecycle inverts the pinned-order model: while *unconfirmed* it must sit behind every regex entry (confirmation requires the full scan to have failed lines 1–2 — any log match disqualifies), but once *confirmed* it must short-circuit ahead of everything (today's `$csv_detected` branch at the top of the loop). Under P3's promotion rule the unconfirmed position makes all 12 regex entries CSV's ancestors, so promotion is a permanent no-op — the model cannot express "behind all, then in front of all." Additionally, CSV's matcher is per-file *state* (stashed header, column indices, separator, `$csv_detected`), while registry entries are global; a coderef matcher-kind would smuggle per-file state into a shared structure.

**Decision shape (recommended for locking at consolidation):** CSV remains a stateful per-file stage outside the ordered scan, exactly as today (#107 mechanics unchanged):
- unconfirmed: the stage consumes only the *no-match outcome* of the scan on lines 1–2;
- confirmed: a per-file extractor override bypasses the scan entirely;
- the registry still owns a **non-scanned `csv` entry** carrying the metadata surface (slug `csv` — harness-locked, time contract epoch/ISO with the #328 skip-and-warn, split-based extraction closure, statistics-eligible) — one resolution surface for everything downstream; only the matcher lives outside the array. `pipeline_parse()`'s per-file context owns the detection state.

**Demonstration** — five scenarios, each run under static and pinned+sel-guards order, all outcomes (per-line kind sequence, detection flag, UDM column mapping) identical: real CSVs with matching UDM configs confirm at line 2 with correct column mapping (`connection-server-custom-metrics.csv` → col 7; 10k of `results_data_idonly-timestampMs.csv` → col 2); a log fixture with UDM configs never confirms; an adversarial log-line-first CSV stream is disqualified; a CSV with no UDM configs leaves the stage inert. This closes the composition question: CSV confirmation consumes only match/no-match outcomes, which P3 proved order-invariant, so the registry's reordering cannot disturb #107's mechanics.

### Consolidation — decisions D26–D34 from the prototype phase (LOCKED 2026-08-20)

Each distills the referenced P-finding into the design the implementation follows. Numbering continues the umbrella sequence after D25. Locked as written by the architect, 2026-08-20.

- **D26 — Detection ordering: pinned-closure MTF with load-time derived constraints** (P3). The scan array reorders by move-to-front of the winner *together with its ancestor closure*, relative order preserved, no-op promotions skipped. Constraints are never hand-maintained: they derive from cross-testing every entry's samples against every pattern at load (the D24 mechanism), which reproduced all A2-documented pairs plus four undocumented ones. Unconstrained MTF is forbidden (misclassifies); tier-MTF rejected (strictly worse). Implementation obligation from the P3 blend artifact: the steady-state scan loop must be as lean as today's — no per-attempt bookkeeping, index-free iteration where possible.
- **D27 — Extraction dispatch: load-time codegen closures returning a fixed-order list into the existing scalars** (P2). Declarative entry definitions (capture→field map + named transform primitives per A3) compile to per-format closures at startup. The generic capture-map interpreter is off the hot path permanently (+2.2–2.7 s/M); hashref records rejected (+0.2–0.3 s/M over list-return; settles A5). Patterns may keep named groups for self-documentation; generated code reads positionally (F6).
- **D28 — Cheap superset guards are per-entry, opt-in, measured data — never blanket policy** (P4). This drop ships guards on the three expensive-to-reject access siblings (mt12 `index 'ms] ['`, mt9 `index '" "'`, mt4 `rindex`+one-token-tail), recovering −1.29 s/M access lines (−31%). Guards on cheap-to-reject entries are a measured net loss and are not placed. Atomic/possessive same-head variants are subsumed by guards and dropped. The family-shared `] "` prefilter stays a recorded, measured option (best on GC/blend) — not shipped while access logs drive #369. Soundness contract: a guard may false-positive, never false-negative; verified at load against samples (D24's executable-sample mechanism extends to guards).
- **D29 — Registry container: array-of-arrayrefs with `use constant` field indices** (P5). Hash-field access costs +0.08–0.24 s/M in the scan loop; hash-of-hashrefs rejected. User-YAML merge convenience lives at load time (merge in a hash, freeze into the scan array). Build cost (161–188 µs) and footprint (73–82 KB) are startup non-factors; no hot/cold field split warranted.
- **D30 — Detection window: two-phase-store** (P7, implements D17's minimal window). Window loop classifies each held line once and stores `[line, entry]`; flush runs deferred extraction; then a clean steady loop with no window check. Free at 1m scale in every variant (≤ +54 ns/line), buffer ~0.3–0.6 KB/held line — so the window is sized by detection needs (unit resolution, D17), not throughput.
- **D31 — Time contract compiled into per-layout parse closures** (P8, implements R1/D23's declarative time contract). Layout/precision/tz declared per entry; compiled closures reproduce today's path with exact per-line parity (epoch, fractional-ms, cache keys, precision flip) at slightly lower cost. **This drop keeps the per-second `%timestamp_cache` semantics unchanged** (parity boundary); the sparse-stream unbounded-growth fix (date-keyed cache, measured 2.5× faster and 6 KB vs 100.7 MB on GC-class streams) is #383's scope.
- **D32 — CSV stays a stateful per-file stage outside the scan array; the registry carries a non-scanned `csv` entry** (P9, settles A7). #107 mechanics unchanged (stash line 1, confirm on line-2 full-scan failure + header validation, per-file extractor override once confirmed); the entry owns slug, time contract, and split-extraction closure so downstream keeps one resolution surface. Composition with D26 proven order-invariant.
- **D33 — Message-metric probes: closure-compiled with per-probe `index()` guards behind one `index($message,'=')` superset gate** (P6; supplies the measured shape for D25's "index() literal pre-check"). Fusion into the recognition regex is rejected on measurement (+1.09 s/M miss path). Probe declarations (name, pattern, guard literal, unit, mask template) remain entry data; count-probe global scope unchanged (D25 parity boundary, scoping → #60).
- **D34 — No no-match pre-filter in this drop** (settles R2's open question; P1/P4 evidence). The no-match population is already the *cheapest* class (all anchors reject near position 0; 2.0–2.8 µs/line falling further under D28 guards), so the F3 first-char discriminator's payoff is bounded below its complexity. Revisit only if the merge-gate probe shows a no-match-dominated regression.

**Exit-criteria assessment (prototype phase):**
- *Measured justification with medians and ranges* — P1–P9 tables above, all blessed at the top of the 1k→10k→100k→1m ramp (dense capped at 100k). ✓
- *Matched-line extraction no-regression within noise* — dispatch tax is +0.12–0.17 s/M (P2), recovered several times over by D26+D28 on multi-attempt workloads; timestamp stage at parity or better (P8). ✓
- *Detection-phase improvement consistent with the #369 expectation* — composed classification on the access workload: 4.32 s/M (static) → 2.94 s/M (D26+D28), −32%, with the failed-attempt cost class (2.92 s/M, P1/P2) structurally removed rather than shaved; remaining headroom to the invalid ceiling identified as guard-call overhead with inlining named as the next increment if the gate probe demands it. ✓ (final proof remains the merge-gate `TIMING parse/read_files` probe on the real tool)
- *Lessons recorded before implementation* — this section. ✓

## In-drop design decisions still open (not covered by the prototype phase)

All resolved during implementation planning (2026-08-20): umbrella Q3 → D35; umbrella Q5 → D36; YAML module and R4 scope → D37. See the locked decisions below.

## Locked decisions (Dxx continues the umbrella sequence in `features/log-format-registry.md`)

### D24 — User-pattern anchoring and load-time validation (LOCKED 2026-08-20)

User-supplied format patterns (R4 YAML) are **automatically `^`-anchored**: the loader wraps the pattern as `^(?:...)`, stripping a user-supplied leading `^` first so it never doubles. Anchoring is implicit and documented — format recognition *means* matching from line start, and forgetting the anchor is the documented grok failure mode (F2, ~6× failed-match penalty). **`$` is never auto-appended**: four built-ins are deliberately prefix-matching (generic mt1, RAC mt2, JSON mt5, mt3's open tail) and user formats with free-text trailing messages need the same; the line end belongs to the author.

Because the anchor alone cannot protect performance (`^.*ERROR` re-imports the scan inside the anchor), validation is the stronger shield, all at load time with clear errors:

1. **Mandatory sample lines as executable tests** (F5, lnav precedent): a user format without at least one sample, or whose pattern fails any of its own samples, fails to load.
2. **Lint pass**: warn/error on `.*`/`.+` immediately following the anchor, on all-optional tails (the mt3 lesson, A2), and on nested quantifier constructs.
3. **Cross-shadowing test** (A2): the user pattern is run against every built-in format's samples and every built-in pattern against the user format's samples; overlap fails loudly unless the user declares an explicit priority for the entry.

Net effect: both silent failure modes the architect raised — broken recognition and invisible performance degradation — become load-time diagnostics.

### D25 — Message-metric probes become registry-declared, closure-compiled data; probe *scoping* is #60's (LOCKED 2026-08-20)

Per A11: the optional in-message metric probes (today ` bytes=`/` durationMs=` hardcoded in the mt1 branch; ` count=` and UDM patterns global across formats) are expressed in the registry as a declared optional `message_metrics` list per entry (name, pattern, unit, mask template), compiled at load into the per-format extraction closure with an `index()` literal pre-check before each probe regex (the D23(a) sub-determination idiom). They are **not** fused into the format-recognition regex (expected loss per A11's analysis; #306 precedent) — the prototype measures the three placements (coverage item 8) to confirm.

Parity boundary for this drop: probes migrate as data with byte-identical behavior, including the count probe's current global scope. Whether probes become format-/family-scoped configuration (which formats run which probes, whether count stays global) is a metric visibility/purpose question and is assigned to #60, recorded as guidance on that issue.

### D35 — No inheritance mechanism; user-format adjustment is sparse-override (LOCKED 2026-08-20, resolves umbrella Q3)

A user format entry naming an existing built-in is a **sparse override**: it starts from that built-in's spec, applies only the fields it states, then recompiles and revalidates through the full D24 gates (samples, lint, cross-shadowing). There is no separate `extends` mechanism: same-pattern variants cannot coexist in the scan array (cross-shadowing correctly rejects two patterns that match each other's samples, and MTF cannot order identical patterns meaningfully), so "like tomcat9 but microseconds" is inherently an override, and a *different* pattern is simply a new format. Formats carry **default** configuration only — runtime layers (`-du` override, index hints, future #17 detection) sit above per the R5 precedence chain.

### D36 — No strict mode in this drop (LOCKED 2026-08-20, resolves umbrella Q5)

Permissive unmatched-line behavior stays byte-identical. Unmatched-line visibility improves via the new `-V format-detection` scan telemetry; a strict/fail-on-unrecognized mode remains available as a small follow-on if ever wanted.

### D37 — R4 re-scoped out of Drop 1; YAML::PP as a hard dependency when the user-format feature lands (LOCKED 2026-08-20)

User-configurable YAML formats require a config folder/file mechanism that does not exist yet, and users do not need custom-format access immediately — Drop 1's purpose is getting the internal mechanisms working, active, and tested. Therefore:

- **In this drop:** the registry schema, data model, and full D24 validation machinery land in code, exercised by the built-in formats at every startup. No YAML file, no YAML module, no new CLI surface, no new dependency.
- **Follow-up issue (natively blocked by #58):** the YAML loader, the config folder/file convention, the CLI surface, and the YAML::PP dependency. When that feature lands, **YAML::PP is a hard dependency** (`use`, not a lazy `require`) — once the capability exists in the tool, the module must be present. Module choice per F7: YAML::PP (pure Perl, PAR-safe on all three platforms; YAML::Tiny's weaker validation and YAML::XS's packing risk both rejected). D35's sparse-override semantics and the already-implemented D24 gates transfer to that issue. *Filed 2026-08-21 as #387 (user-configurable YAML format definitions with config folder/file mechanism), `status: backlog`, native `blocked_by` #58.*
- Umbrella D12's "users get custom formats via YAML" intent is unchanged but re-sequenced; the umbrella doc carries the true-up.
- Coverage note per `tests/HARNESS-DESIGN.md` ("a gate only guards surfaces a scenario exercises"): with no external definition input in Drop 1, the D24 *failure* paths have no permanent scenario here — sabotage proofs are demonstrated at authoring time, and permanent malformed-definition scenarios are the follow-up issue's harness work.

### D38 — Detection window ships as structure now; N-sizing is a follow-up prototyping activity (LOCKED 2026-08-20)

The D30 two-phase-store structure lands in this drop with default window size 0 and a hidden `--detection-window=N` test flag; side-effect-ordering parity at N>0 (deferred extraction of held lines relative to read-side effects — a surface P7 did not exercise) is proven in this drop's parity testing at N=1000, so enabling the window later changes one constant against an already-proven surface. Sizing N appropriately is a **post-development prototyping activity** in its own follow-up GH issue (blocked by #58), enhancing the P7 battery; this closes the gap that the prototype phase measured the window *mechanism* (throughput/memory — free up to 10k lines) but never derived the value N should hold. *Filed 2026-08-21 as #388 (size the format-detection window N, post-development prototyping), `status: backlog`, native `blocked_by` #58.* *Superseded in part by umbrella D53 (`features/log-format-registry.md`, 2026-08-22): the window is the fallback for non-seekable input, not the primary evidence source; #388 (re-titled "Design and size the detection evidence sampling pass") sizes the sampling pass instead, and the fallback window's N ships with it.*

## S4 shadow-mode parity proof (2026-08-21)

Temporary hidden flag `--format-registry-shadow` (deleted with the S5 swap): after the live cascade binds its scalars, the registry scan (pinned-closure MTF + D28 guards) and the winner's extraction closure run against the same raw line into parallel state, and classification (`match_type`) plus the full 13-field extraction record are compared undef-aware. The comparison point is post-branch-extraction / pre count-probe/UDM/CSV — exactly the stage the closures replace. Confirmed-CSV lines are skipped (D32: CSV is outside the scan array). The end-of-run stderr report always prints when the flag is on, so a zero-divergence run is a positive assertion.

**Results (2026-08-21): 241 runs, 0 divergences, runtime-warning-clean.** Coverage: the regenerated 27-fixture prototype dataset's largest sizes (six 1m families incl. `concat-pair`/`interleave-100`, which exercise MTF change-point promotions, plus `pure-scriptlog-dense` at its 100k cap) and every committed log under `logs/` below 60 MB. One file excluded with cause: `IntegrationRuntimeLogs/IntegrationRuntime-46b44bb3-*.log` dies identically on pre-registry and registry builds with a pre-existing `Month '24' out of range` fatal in the Apache-family timestamp parse — filed as #385 (backlog), unrelated to recognition.

## S5 swap findings (2026-08-21) — gate-probe-driven refinements and decision amendments

The cascade→registry swap landed through three measured refinement rounds, each forced by the `TIMING parse/read_files` gate probe (median-of-N, alternating pre/post binaries on the 1m fixture families):

- **F9 — P2's dispatch-tax figure was an experimental-design artifact.** P2 measured closure-list at +0.12–0.17 s/M — but its "inline" baseline was itself a per-line *sub* (with its own lexical declarations and return-list copy), so the comparison hid exactly the machinery the closure adds over the real inline cascade. Against production code the per-entry-closure shape measured **+0.8–2.2 s/M** (scriptlog +23% initially). NYTProf attribution: ~1M/M-lines closure-call op overhead, a per-line regex op on the `=~ $qr` form, and an extra full copy of every record field through the return list. Lesson for future prototypes: the baseline must reproduce the production mechanism's call structure, not just its logic.
- **Round 1:** promotion was invoked on every matched line sitting behind its pinned ancestors and rebuilt an ancestor hash per call — fixed by a precomputed per-entry ancestor set (`FR_ANC_SET`) and an inline already-optimal gate (P3 lean-loop obligation).
- **Round 2:** extraction closures rewritten to write **file-scoped record lexicals directly** (no per-call declarations, no return-list copy); the per-line loop no longer declares the 13 record fields, and the CSV branches reset the fields they don't produce. Failed-attempt semantics preserved exactly (a failed match's empty capture assignment clobbers only that entry's own targets — A12).
- **D39 (amends D27's mechanism; implemented under the merge gate's no-regression criterion, architect confirmation pending) — the scan is ONE generated sub.** Per-entry closure calls still cost ~0.5–0.8 s/M after round 2, so the P4-anticipated "inlining" increment was implemented: `compile_format_scan_sub()` splices every entry's guard (literal `index`/`rindex` ops), recognition pattern (literal `m~…~`, compiled once at eval), and extraction/transform body into a single sub in scan order, generated from the same `format_entry_block_src()` fragments the validation closures use. Promotion code is emitted only into blocks whose generation-time position is not already optimal, so steady state executes zero promotion instructions. Per-entry `FR_EXTRACT` closures remain for load-time validation and detection-window replay (cold paths).
- **D40 — order-signature scan-sub cache with eager precompilation; promotion never recompiles (architect design, 2026-08-21; supersedes two rejected interim variants).** One scan-sub eval costs ~4 ms (13 pattern compiles), and regenerating on every promotion made the alternating-format fixture (`interleave-100`, ~10k change points/M) +79%. Two interim fixes were rejected by the architect: a regeneration throttle (leaves stale orders and still compiles inside the loop) and a per-front canonical order with a static-tail (silently weakened D26's recency semantics — a file alternating two or three formats must scan only those formats before the tail, which requires true MTF recency of the non-front entries). Final design: **the scan order stays exactly D26's pinned-closure MTF (winner + ancestor closure to front, rest keep relative recency), and generated subs are cached by order signature.** Recency alternation cycles through a tiny set of orders, so each order's sub is compiled at most once per run and selected by hash lookup thereafter; the static order and all 13 first-promotion-from-static orders are precompiled eagerly at startup (compile cost belongs before the read loop, not inside it — ~22 ms, reported by `TIMING detect/registry_build`, further warmed by gate 5's sample stream). Only genuinely novel recency permutations (multi-format interleaved streams) compile mid-run, once each.
- **New load-time gate (extends D24): the generated scan sub itself classifies every sample to its owning entry** under the static order at build; this gate immediately caught a real defect (the winner was read from `@format_scan_entries` *after* promotion had regenerated it mid-call — now captured pre-promotion). Build cost with the two startup compiles: ~5 ms, reported by `TIMING detect/registry_build`.

## S5b codegen refinements (2026-08-21) — profile-directed, architect-reviewed

NYTProf attribution on the swapped engine (100k fixtures) located the remaining reducible per-line costs; three declarative codegen refinements followed, each verified by D24 gates and probed per class (100k, median-of-3, local disk, vs the S5 commit):

- **Whitespace dispatch (new spec field `head_class`, verified by D24 gate 6).** Blend's 73.6% continuation lines are tab-led and were walking all 13 blocks plus three full-line guard scans. Space-led lines are provably unmatchable by every head; tab-led lines can only match the `[^ ]+`-headed entries (`head_class 'any'`: the access family, mt7, mt11). The generated sub opens with an `ord()` dispatch: space → immediate no-match; tab → the six tab-capable blocks only. Gate 6 fails the build if a space-prefixed sample matches any pattern or a tab-prefixed sample matches a non-tab-capable pattern. **twx-blend −13.4%.**
- **Frac contract (new time field `frac`: fixed3 | none | generic).** The generic capturing `s///` strip ran per line even where the pattern *guarantees* the shape. `fixed3` (pattern-enforced `.mmm`, checked structurally at build) emits two fixed-offset substr ops; `none` (apache_clf — CLF never carries a fraction) emits a constant; `generic` keeps the original strip (mt5's unguaranteed JSON capture, the flex layouts). **pure-scriptlog −4.0%** (with the memo), **pure-access −2.2%** (strip attempt eliminated). Note: the *value* is still always read — `$fractional_ms` feeds `$timestamp_epoch` and the index bounds unconditionally, so a demand-conditional presence-only variant is a behavior change deferred to #386 (analysis-precision data model).
- **Last-seen timestamp memo (P8's flagged tuning option).** A string `eq` against the previous line's timestamp string fronts the `%timestamp_cache` hash ops; dense streams hit it constantly. On sparse-timestamp streams the memo mostly misses and costs its test: **pure-gc +2.5% with heavily overlapping ranges** — noise-to-small-cost, consistent with P8's data-dependence finding; acceptable now, and #386's precision work is the natural place if it ever needs a data-driven gate.

Observability follow-through (architect, 2026-08-21): the no-match scan is the structural worst case, so S6's section contract gains a no-match scan counter (free — increments on the already-expensive path) and **sampled** no-match scan timing (time 1-in-N scans; per-line timer pairs were considered and rejected as an anti-pattern — the clock calls would cost more than many scans they measure).

## `-V format-detection` section-contract

Owned by the umbrella: `features/log-format-registry.md` § "`-V format-detection` section-contract" (consumer: `tests/validate-format-detection.sh`).

## S9 gate close-out (2026-08-21)

**Full-suite evidence:** the complete `tests/validate-*.sh` suite ran green on the final code (at the S7 close-out; the only commit since is docs-only, verified by `git diff --stat 7272def..HEAD -- ltl tests/` being empty): 19/21 harnesses pass outright; `validate-regression` reports only the 8 known file-legend mount-path scenarios with **zero** non-legend diff content lines; `validate-index-read-back` re-verified **58/58** from a local-disk clone with regenerated fixtures running this tree's `ltl`. `validate-format-detection`: 58 assertions, 0 failed. Runtime-warning-clean throughout.

**Blessing battery** (1m fixture families, median-of-3 with ranges, local disk under `caffeinate`; pre = the pre-swap cascade at commit b6495c2, final = this tree):

| Family (1m) | pre | final | Δ |
|---|---|---|---|
| pure-access | 14.24 s [14.09–14.29] | 12.38 s [11.96–12.38] | **−13.1%** |
| concat-pair | 11.82 s [11.78–11.87] | 10.52 s [10.51–10.58] | **−11.0%** |
| interleave-100 | 11.64 s [11.55–11.86] | 10.94 s [10.65–11.00] | **−6.0%** |
| pure-scriptlog | 10.21 s [10.13–10.26] | 10.06 s [9.90–10.21] | −1.5% |
| twx-blend | 7.02 s [7.01–7.06] | 6.94 s [6.94–6.98] | −1.1% |
| pure-gc | 10.53 s [10.49–10.57] | 10.50 s [10.46–10.61] | −0.3% |

Every family is net faster; no regression class remains anywhere in the battery.

**#369 probe** (`TIMING read_files`/`parse/read_files` median-of-3, v0.16.0 tag build vs final, 1m fixtures):

| Fixture (1m) | v0.16.0 | final | Δ |
|---|---|---|---|
| pure-access | 13.958 s | 12.060 s | **−13.6%** |
| twx-blend | 6.817 s | 6.659 s | −2.3% |
| pure-gc | 10.253 s | 10.000 s | −2.5% |

The v0.16.0 access-log read-phase regression (+5–10% read_files, per #369's measurements) is removed as a class — the read phase is now 13.6% *faster* than the regressed baseline, with the non-access controls also improving.

## Acceptance criteria / merge gate

- [x] **Research + prototype phase completed and its decisions recorded in this document before implementation began** (see the mandatory phase above; F1–F8, A1–A12, P1–P9, D24–D40).
- [x] All existing tests byte-identical: golden files + full `tests/validate-*.sh` suite exits 0; runtime-warning-clean stderr. *(S9 close-out evidence above; regression golden byte-identical modulo the documented file-legend mount-path quirk.)*
- [x] **#369 probe**: `TIMING parse/read_files` on an access-log selection improves vs. the v0.16.0 baseline — cost class removed, not shaved. *(−13.6% median-of-3 on pure-access-1m; table above.)*
- [x] Detection observability per the section-contract above. *(S6: per-file scan counters + `format-detection / scan` sub-section, harness-asserted and sabotage-proven.)*
- [x] Extraction parity per migrated format (sample-line fixtures). *(D24 gates 1–6 at every startup; S4 shadow mode 241 runs / 0 divergences; post-swap full-output parity diffs across all fixture families.)*
- [x] ~~At least one user-defined YAML format loads and parses a fixture; malformed definitions produce clear errors.~~ **Re-scoped to #387 (D37).** In its place: registry load-time self-validation (D24) demonstrably fails on sabotaged definitions (broken sample, broken guard, undeclared shadow) with clear diagnostics. *(Sabotage proofs demonstrated at S2 authoring time and recorded in its commit; permanent malformed-definition scenarios are #387's harness work.)*
- [x] Format-carried unit applied for a known format; `-du` wins; ambiguity warning fires on the Tomcat `%D` case. *(S7; note text locked in R5, harness scenario `unit-ambiguity-warning`.)*
- [x] Follow-up issues filed with native `blocked_by` #58: #387 (user-configurable YAML formats + config mechanism, D37); #388 (detection-window N sizing prototyping, D38); #386 (per-format analysis precision, filed during S5b).
- [ ] Gate passes → merge to `release/0.17.0`; #369 fix comment + close; #17's declarative half delivered (sampling follow-on stays open). *(Executed via the per-feature workflow; the PR and issue completion comments are the record.)*

## Related

- Parent umbrella: `features/log-format-registry.md` (#23) — D12/D13/D17/D18/D20
- Prerequisite: #180 (Drop 0 — named stages; native `blocked_by` recorded)
- `docs/regex-best-practices.md` — pattern-count scaling, ordering policies, alternation rejection, qr// handling
- #369 (fixed by this drop), #17 (declarative half delivered), #179 (detect-stage hints)
- `features/382-gc-log-g1-format-coverage.md` (#382) — widens the `mt6` entry to the cause-less G1 pause and event forms; carries D41–D43 and the HotSpot-sourced `[info][gc]` vocabulary. First worked example of editing a registry spec rather than hot-loop code.
- `features/395-wgm-client-log-format.md` (#395) — adds the `mt16` Windchill Workgroup Manager client entry: a new format declared entirely in the registry (pattern, field map, one transform, filename family, samples); carries D54–D56.
- `features/396-windchill-method-server-log4j-format.md` (#396) — adds the `mt17` Windchill Method Server log4j entry: the log4j `%d %-5p [%t] %c %x - %m` layout, local time, occurrences-only; filename family `<Service>-<yyMMddHHmm>-<pid>-log4j.log` with the daily-roll `date_n` index form. Carries D54–D57.
