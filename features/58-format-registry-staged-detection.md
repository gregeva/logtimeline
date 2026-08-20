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

### R4 — User-defined formats via YAML (D12)

Loaded at startup; validated with clear, actionable errors; able to extend or override built-ins. In-drop decision: YAML::PP vs YAML::Tiny, weighed against the PAR-packaged builds.

### R5 — Format-carried units (D18 boundary)

Duration unit is registry metadata. Precedence: explicit `-du` override → format-carried unit (this drop) → index read-back (#179) → sample-based auto-detection (#17 — NOT in this drop; no unit auto-detection or speculative unit tracking inside the rewrite). Ambiguous variants get a warning; *resolving* the ambiguity statistically stays #17's follow-on (its ~100-line sampling window is the D17 detection window — see the design-tie comments on #181/#17).

### R6 — Detect-stage integration

The registry slots into #180's named `detect` role — concretely (post-Drop 0, 2026-08-20): the pre-read detect surface is `pipeline_detect()` (today `read_index_file()` + the startup memory checkpoint), and the per-line match-type cascade this drop replaces lives inside `read_and_process_logs()` under `pipeline_parse()`. Each `pipeline_*()` sub carries a contract header comment (receives/emits + resolved demand and capture modes as standing inputs); the headers on `pipeline_detect()`/`pipeline_parse()` are updated **in the same change** that moves detection into the registry, as is `docs/staged-processing-pipeline.md` § "Named Pipeline Stages". `read_index_file()` hints (#179 — timestamp range, `ts_precision`) are available detect-stage inputs. The D17 minimal detection window (hold first ~N lines; per-line re-scan on cache-miss) is the only line-holding built — no full reader/processor decoupling (#181 is architecture guidance only).

**Detection timing nomenclature (contract from #180's 2026-08-20 decision):** timing surfaces follow `stage/step` form. When this drop adds detection cost, the machine row is `TIMING	detect/<step>` and the summary-table row is `DETECT: <NAME>` with the display string **≤30 characters** (the summary table's category column is fixed at width 30; longer strings overflow). New labels need no `compare-results.sh` compat mapping — only renames of pre-existing labels do (the #180 rename map already exists there).

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

#### Prototype coverage additions distilled from the audit

Beyond the F8 ranked list: (1) constrained-MTF variants (tiered / pinned partial order) with a misclassification test built from each format's samples cross-run against the full array (A2); (2) pattern-pair failure-cost measurement on shared-head siblings (A1); (3) record-shape comparison list-return vs hashref (A5); (4) transform-stage expression — closure-compiled vs declarative — over the A3 mutation inventory; (5) fixtures asserting `%timestamp_cache` semantics and the A6 guard behaviors; (6) CSV matcher-kind decision (A7); (7) `-V format-detection` output preserved byte-compatible for existing keys while adding scan telemetry (A8).

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

## In-drop design decisions to settle

- Pattern priority when multiple registry entries could match the same line (umbrella Q2)
- Format definition inheritance — "like tomcat9 but microseconds" (umbrella Q3)
- Strict mode vs. current permissive behavior for unrecognized formats (umbrella Q5)
- YAML module choice (R4)
- Whether a no-match pre-filter is warranted (R2)

## `-V format-detection` section-contract (stub — to be locked in-drop)

The existing `format-detection` section (`emit_format_detection_verbose()`) gains ordering/scan-depth telemetry sufficient to prove MTF behavior: per-format match counts, scan-depth distribution (or total failed-attempt count), final array order. Per `tests/HARNESS-DESIGN.md`: line shapes and counter semantics are locked here when implemented, and the consuming harness is updated in the same change. This document becomes the owning feature doc for that section-contract.

## Acceptance criteria / merge gate

- [ ] **Research + prototype phase completed and its decisions recorded in this document before implementation began** (see the mandatory phase above).
- [ ] All existing tests byte-identical: golden files + full `tests/validate-*.sh` suite exits 0; runtime-warning-clean stderr.
- [ ] **#369 probe**: `TIMING parse/read_files` on an access-log selection improves vs. the v0.16.0 baseline — cost class removed, not shaved. Targeted single-file probe, median-of-3; no XL suites during development.
- [ ] Detection observability per the section-contract above.
- [ ] Extraction parity per migrated format (sample-line fixtures).
- [ ] At least one user-defined YAML format loads and parses a fixture; malformed definitions produce clear errors.
- [ ] Format-carried unit applied for a known format; `-du` wins; ambiguity warning fires on the Tomcat `%D` case.
- [ ] Gate passes → merge to `release/0.17.0`; #369 fix comment + close; #17's declarative half delivered (sampling follow-on stays open).

## Related

- Parent umbrella: `features/log-format-registry.md` (#23) — D12/D13/D17/D18/D20
- Prerequisite: #180 (Drop 0 — named stages; native `blocked_by` recorded)
- `docs/regex-best-practices.md` — pattern-count scaling, ordering policies, alternation rejection, qr// handling
- #369 (fixed by this drop), #17 (declarative half delivered), #179 (detect-stage hints)
