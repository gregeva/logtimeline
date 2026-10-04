# One vocabulary for metric, field, identifier and statistic names across every option (Issue #613)

## Status

Specification agreed with the architect 2026-09-28 and merged into
`release/0.19.0` (PR #623). Implementation started 2026-10-04 on branch
`613-one-name-vocabulary` off `release/0.19.0` (12712ae): `$version_number`
stamped `0.19.0-613`, `613-before` benchmark captured on the base commit. The
working sequence is § 9, *Implementation plan*.

- **Parent:** #622 (the refactoring the redundant-logic audit dispatched), as a
  sub-issue.
- **Blocks:** #581 (deprecate the omit options `--discard` duplicates), #601
  (deprecate the options `--hide` and `--show` duplicate), #582 (name what to
  expose, discard or mask by a regular expression), #614 (operand checks and
  their texts derive from the vocabulary checked), #617 (one width-to-format
  rule, whose metric-kind resolver reads this issue's built-in metric table) and
  #618 (one declaration per CSV column, derived from this issue's tables).
- **Record of the findings:** `features/342-redundant-logic-surfaces-audit-report.md`
  § Item 1 and § Review progress, stages 3, 4 and 16. This document cites each
  finding by what it measured.
- **Governing records, each trued up by this issue:**
  `features/566-preserve-named-values-in-message.md` (D6: a built-in name
  resolves before a key found in the line; D7: a line key is appended only when
  the formed message no longer yields its value),
  `features/567-discard-named-values-from-message.md` (D9: the parsed fields
  `-d` names; D12: nothing of a discarded part survives into a count or
  capture, and a `-udm` metric whose key is discarded is switched off; D14: the
  `-d` name table; D15: `-x` and `-d` accept the same names; D16: a discarded
  key-value pair takes the separator that follows it, or at the end the one
  before it, so no `?&` or doubled separator remains (567 criterion 1)),
  `features/580-mask-uuid-and-ip-address.md` (D5: the `-m` surface follows
  the `-x`/`-d` shape), `features/597-section-visibility.md`
  (D24: a user-defined metric's column is named by its heading),
  `features/histogram-charts.md` § Command Line Interface (the metric-operand
  contract), and `features/432-metric-aggregate-naming-parity.md` (D1: a bare
  metric word on `-so` is its total, and its line "`duration` / `time` = total
  duration", which D1 below takes `time` out of; D3: duration keeps its bare
  spellings on the command line; D8: the consumers of the bytes family are
  `-so` and the CSVs).
- **Shared surfaces owned elsewhere:** the `-V runtime-config` section's
  contract is owned by `features/225-test-harness-coverage-gaps.md`; #525
  (timestamp precision option) adds a `timestamp-precision:` key to the same
  section, and this issue changes only the values of its `expose` and `discard`
  keys (§ 7). The help-content parity scenario is built by #608 (the byte-unit
  ladder); this issue adds its rows to it (§ 6, criterion 19).

---

## 1. The motivating consumer

Two consumers, one now and one next.

**The analyst typing a name.** Today the same word means different things on
different options. `time` is the duration metric on `-hm`, `-hg` and `-so`, a
key read from the line on `-x` and `-d`, and an error on `--hide`. `Bytes` is
the bytes metric on `-hm` and `--hide`, and a line key on `-x` and `-d`. A
user-defined metric read from the `elapsed=` key is named `elapsed` on `-x` and
`-d` and is unknown on `-hm` and `--hide`. The analyst who learns a name on one
option and uses it on another gets a different result with no word of warning,
visible only by comparing two runs.

**The next issue that touches a vocabulary.** #581 makes `-d` the only way to
switch a metric off, #601 makes `--hide` the only column surface, #582 rewrites
the parse of `-x`, `-d` and `-m`, #514 (count metric explicit and off by
default) edits the count entry of the metric set, #617 (one width-to-format
rule) resolves a metric's kind from its family, and #536 and #537 (thread name
and remote host as attributes) each add a parsed field. Each of them today has
to find every copy of the set it changes: the built-in metric set is written as
a literal at more than twenty sites. After this issue each set is one table,
each option resolves through one resolver over it, and each of those issues
edits one entry or one resolver.

What changes for a user: a name means one thing on every option that accepts
it, in any case; two spellings (`time` on `-hm`, `-hg` and `-so`; `size` on
`-so`) print a deprecation notice for one release; naming a metric's key on
`-x` keeps its value in place and on `-d` removes it whole and switches the
metric off with a notice; `-x object` appends the full object; a handful of
`-x`, `-d` and `-m` spellings change meaning (§ 5.7 lists each).

---

## 2. Requirement

In the architect's terms, transcribed from the issue body, the stage 3, 4 and
16 rows of the audit's review, and the architect's replies of 2026-09-28,
organised but not reinterpreted.

### Mandate

Every option that names a metric, a parsed field, an identifier or a statistic
resolves the name through one vocabulary, so a name means the same thing on
every option and a change to the set is made once.

### What was measured as wrong (audit § Item 1, on the Tomcat access-log fixture and three-line scratch fixtures of the same shape)

- `-hm time`, `-hg time` and `-so time` mean the duration metric; `-d time`
  removes nothing and `-x time` appends a `time=` line key; `--hide time` is a
  usage error.
- `-hm Bytes` and `--hide Bytes` resolve to the bytes metric; `-d Bytes` keeps
  the column `-d bytes` removes; `-x Bytes` appends a `Bytes=` line key.
- `-x durationMs` and `-d durationMs` mean the duration metric; `-hm durationMs`
  warns, pushes the word back as a file name and uses duration anyway; `-hg
  durationMs` does so silently.
- With `-udm 'lat::max:elapsed'`, `-x elapsed` and `-d elapsed` find the metric
  `lat`; `-hm elapsed` and `--hide elapsed` are errors.
- Three unknown-metric messages name the vocabulary three ways, one naming
  `time`, one never printing.
- `-d object` clears the parsed object field; `-x object` appends an `object=`
  line key.
- `-d uuid|ipv4|ipv6` matches by literal beside the mask table `-m` resolves
  through; the `-m` error is a literal.
- `avg` is an alias of `mean` in three tables; `-so size` is accepted for bytes
  and `size` is accepted nowhere else.

### Locks

Nine from stage 3 and stage 16 of the review (D1 to D9), a tenth from the stage
16 placement (D10), and seven from the architect's replies to this
specification's draft on 2026-09-28 (D11 to D17). § 4 restates each.

### Scope boundary set by the architect

"Where each option's rejection message lives and what it says is stage 4 of the
review, not this issue" (issue body). Stage 4 is #614 (operand checks settle
once per option; their texts derive from the vocabulary). The issue body's
scope line and D14 draw the line: this issue changes the source of every list
a message names and prints the notices its own locks name (the `time` and `size` deprecations, the metric
switch-off); it does not move a check, change a rejection message's wording, or
change what an option does with an operand it does not recognise (the file-name
pushback).

### Done when (issue body, with the defect D12 adds)

Every name above means one thing on every option that accepts it; the
deprecated spellings print their notice and still work for the release;
`docs/usage.md`, `--help` and the governing records (566 D6, 567 D9 and D15, the
histogram record's command-line section) say the same thing; the built-in
metric, field, identifier and statistic sets each exist once in the code; and a
key removed by `-d` leaves no residue whether or not its value was masked.

---

## 3. Corrections to the issue body and the audit record

Verified on 2026-09-28 against `ltl` at the base of this branch
(`release/0.19.0`, 58f8d94), by `grep -F` of every cited snippet and by captured
runs (`--disable-progress --terminal-width 220 -ni -bs 1440 -oe`). Every snippet
the issue and the audit cite for the stage 3 findings (the `time` alias, case
folding, key spellings, the token-key fallback, the unknown-metric texts, the
literal copies of the metric set, the mask identifiers, `object` on `-d` only,
the aggregate aliases) and for the stage 16 flag finding (the expose and mask
flags set twice) is found once inside the sub named: the token-key fallback
twice, in the expose and discard resolvers, and the mask flag twice, as cited.
The code has not moved since the audit.

1. **No notice exists when `-d` switches a user-defined metric off.** D4 (a
   user-defined metric is named by its name) says "567 D12 then switches that
   metric off with its notice". `apply_discard_precedence` drops the metric
   (`@udm_configs = grep { !$_->{discarded} } @udm_configs;`) and prints
   nothing; 567 D12 names no notice. Measured: `-udm 'lat::max:elapsed' -xqs -d
   lat` and `-d elapsed` on a three-line access-log fixture whose query string
   carries `elapsed=` and `v=`: stderr empty, exit 0. The design adds the notice
   the lock names (§ 5.3), and D12 extends it to the built-in metric whose key
   is discarded.
2. **`-d` applies identifiers in command-line order, not the mask order.**
   Measured on a ThingWorx standard line whose message carries `peer
   ::ffff:192.0.2.7 closed`: `-d ipv4,ipv6` leaves `peer ::ffff: closed`, `-d
   ipv6,ipv4` leaves `peer closed`. `-m` always applies uuid, ipv6, ipv4 in that
   order. D7 (identifiers through the mask table and order) and D13 (fixed
   order, order-independent) settle it.
3. **The built-in metric set is written at more sites than twelve.** Beyond the
   twelve the audit counts: the `-x` and `-d` help rows also list `duration,
   bytes, count` (the audit counted a `-udm` row, which lists none); six
   internal loops carry `qw(duration bytes count)` (`write_aggregate_export`,
   the no-metric notice in `read_and_process_logs`,
   `calculate_histogram_buckets_exact`, `finalize_histogram_unified`,
   `calculate_histogram_layout`, `normalize_data_for_output`); and the heatmap
   value formatter carries its own built-in name chain (`format_heatmap_value`
   :: `if ($metric eq 'duration') {`). None of these is in the per-line loop.
   The issue's "each exist once in the code" includes them.
4. **The `-udm` function slot keeps two tables, not one.** `parse_udm_configs`
   holds `%function_names` (every accepted name) and `%udm_agg_aliases` (`avg`
   to `mean`, `dcount` and `unique` to `distinct`), and its invalid-function
   warning lists the names as a literal.
5. **`docs/usage.md` § Alternate Names overstates the aliases.** It says `time`,
   `size`, `total`, `avg`, `dcount`/`unique` and `std_dev` "work anywhere a
   metric or function name is used — sorting (`-so`), heatmap (`-hm`), histogram
   (`-hg`), and user-defined metric aggregations". Measured: `-hm size` on the
   Tomcat access fixture prints `-hm value 'size' is not a built-in metric
   (duration|bytes|count) and no -udm configs are defined; treating as positional
   argument` and runs duration. `size`, `total` and `std_dev` are `-so` spellings
   only. The same table names `stddev` canonical and `std_dev` its alternate,
   where the code's stored key is `std_dev`; D17 settles which is which.
6. **A governing record the issue does not list names `time`.**
   `features/432-metric-aggregate-naming-parity.md` D1 reads "`duration` / `time`
   = total duration". D1 below (`time` is not a metric name) amends it; § 10
   lists it.
7. **The object is in the message key cut to its last 25 characters.** The key's
   bracketed object segment is the object's last 25 characters
   (`read_and_process_logs` :: `my $truncated_object = defined($object) ?
   substr($object, length($object) > $max_object_length ? ...`). Measured on the
   committed ThingWorx application-log fixture: an object written
   `c.t.s.s.p.PlatformSubsystem` (27 characters) appears in the key as
   `[t.s.s.p.PlatformSubsystem]`. D16 (`-x object` appends the full object)
   answers it.
8. **566's own requirement names the key spelling as a way to keep a metric's
   number in place.** 566 § Requirements, *Metric values* and *Naming*
   (2026-09-16): "Naming it (for example `-expose durationMs`) keeps the `123` in
   place"; "the analyst can name either the internal metric name or the key as
   written". D11 keeps that outcome by a different reading: `durationMS` is the
   key, and naming the key lifts its mask. 566 criterion 8 and 567 criterion 8
   (the three duration spellings give identical output) are amended in § 10:
   under D11 and D12, `-x durationMS` and `-x duration` still give the same
   messages on lines written `durationMS=`, while `-d durationMS` now also
   removes the pair.
9. **A masked key pair leaves residue when discarded.** `discard_key_sub` reads
   a value up to `&`, `?` or a space, so a pair whose value a mask has already
   replaced with `?` loses its `?` as the separator instead. Measured with a
   pattern-form `-udm` that masks `elapsed=`, `-xqs -d elapsed`: `GET
   /app/items?&v=3`, where 567 D16 (a discarded pair takes the separator that
   follows it) requires `GET /app/items?v=3`. Measured with a pattern-form `-udm` that masks a space-separated `tookMs=` on
   ThingWorx lines, `-d tookMs`: `executed··bytes=?` (two spaces). D12 and D13
   fix it in this issue.

---

## 4. Locked decisions

Each is the architect's, restated from its source. Nothing else in this
document is numbered Dxx. D11, D12 and D16 refine D3 and D6 where noted.

### Locked 2026-09-27, stage 3 and stage 16 of the redundant-logic audit's review (#342), transcribed on the issue body

- **D1 — LOCKED 2026-09-27 (architect), stage 3, finding F1.1 (the `time`
  alias) — `time` is not a metric name.** `duration` is the one name on every
  surface; `time` on `-x` or `-d` is a line key. `-hm time`, `-hg time` and
  `-so time` print a deprecation notice on stderr for a release, with a
  release-notes line.
- **D2 — LOCKED 2026-09-27 (architect), stage 3, finding F1.2 (case folding) —
  Built-in names match case-insensitively on every option**, and a built-in
  name resolves before a key found in the line (566 D6). A key that collides
  with a built-in name by case is named through the regular-expression form
  (#582). D15 states its reach.
- **D3 — LOCKED 2026-09-27 (architect), stage 3, finding F1.3 (key spellings) —
  `durationMs` and `durationMS` are key spellings, not metric names**, on any
  option: a line key on `-x`/`-d`, an unknown name elsewhere. 566 D6's "and
  their keys as written" is amended by this issue. D11 and D12 state what the
  line key does on `-x` and `-d`.
- **D4 — LOCKED 2026-09-27 (architect), stage 3, finding F1.4 (the token-key
  fallback) — A user-defined metric is named by its name**, which defaults to
  its key, on every option. On `-x` and `-d` the key from the log is the primary
  reading, and defining a metric from a key does not take the key away: `-d
  elapsed` discards the `elapsed=` key whether or not a renamed metric reads it
  (567 D12 then switches that metric off with its notice). The token-key
  fallback in the expose and discard resolvers goes.
- **D5 — LOCKED 2026-09-27 (architect), stage 3, findings F1.5 and F1.7 (the
  unknown-metric texts and the literal copies of the metric set) — One table of
  built-in metrics** (name, column, family, help text) from which every site
  derives: the resolver, the available-names function, the graph and
  visibility column lists, the heatmap metric map, the sort allow-list and the
  help rows. Every unknown-metric message derives its list from it.
- **D6 — LOCKED 2026-09-27 (architect), stage 3, finding F1.11 (`object` on
  `-d` only) — One table of parsed fields for `-x` and `-d`**, `object` in it,
  resolved before a line key on both (567 D15: the two accept the same names).
  `-x object` appends nothing, the field being already in the message (566 D7).
  D16 replaces the last sentence: `-x object` appends the full object.
- **D7 — LOCKED 2026-09-27 (architect), stage 3, finding F1.10 (the mask
  identifiers) — `-d` resolves identifiers through the mask table and order
  `-m` uses**, `ip` included; the `-m` error lists the table.
- **D8 — LOCKED 2026-09-27 (architect), stage 3, finding F1.20 (the aggregate
  aliases) — One table of statistic names and aliases** (`avg` for `mean`,
  `stddev`, the percentile names) read by the `-udm` function slot, `-so` and
  `--explain`. `size` is deprecated on `-so` in favour of `bytes`, with a stderr
  notice for a release and a release-notes line.
- **D9 — LOCKED 2026-09-27 (architect), stage 16, finding FP.3 (flags set
  twice) — Each run-scoped activation flag is derived once**: the expose and
  mask flags are set in their resolvers and again after the discard-precedence
  pass; the resolvers this issue rewrites derive each flag once, after every
  pass that can change its list.
- **D10 — LOCKED 2026-09-27 (architect), stage 16, findings FP.4 (every error
  and help row that names a vocabulary derives it from the table it validates
  against) and FP.5 (one helper for the optional-operand pushback) — placed
  "in #613/#614", that is in this issue and in #614 (operand texts).** § 5.8
  applies the placement: FP.4 to this issue's four vocabularies (D5, D7); FP.5
  with #614 (stage 4, F1.6).

### Locked 2026-09-28, in reply to this specification's draft

- **D11 — LOCKED 2026-09-28 (architect) — `durationMS` is a token key of the
  duration metric, and naming a token key on `--expose` lifts its mask.**
  `durationMS` is not, and never was, a metric name: the metric is `duration`,
  and `durationMS` (and `durationMs`) is a token key that maps to the duration
  metric. `--omit-duration` (`-od`) does not remove the key; it nulls the
  duration metric. Under `--expose`, naming the token key (`-x durationMS`)
  means the masking of that key's value, which the format applies after
  reading it so that lines group together, is simply not done: the value stays
  in place in the message, exposed where it would otherwise be flattened to
  `?`. Nothing is appended twice. The same holds for the key a user-defined
  metric reads (`-x elapsed` with a metric defined from `elapsed`).
- **D12 — LOCKED 2026-09-28 (architect) — `--discard` throws away what it
  names, the metric or the key, whole.** A key that the format has already
  masked is still discarded as a whole pair (key, separator and value):
  discard is not conditional on a particular value. `-d durationMS` removes the
  pair from the message and switches off the duration metric with the notice a
  discarded key's metric gets (the rule 567 D12 already gives for a
  user-defined metric whose key is discarded); `-d duration` nulls the metric.
  The residue a discarded masked pair leaves (`?&`, or a doubled space) is a
  defect found during this work and is fixed in this issue, not filed
  separately.
- **D13 — LOCKED 2026-09-28 (architect) — Mask and discard are
  order-independent.** Applying a mask before a discard, or a discard before a
  mask, gives the same message; and the identifiers named on `-d` are applied
  in the fixed order `-m` uses (uuid, ipv6, ipv4), never in the order typed.
  The current shape is a design error, corrected here.
- **D14 — LOCKED 2026-09-28 (architect) — The scope split with #614 (operand
  checks and rejection texts) is as recommended.** This issue makes `-so`'s
  bare metric words, the bare statistic names and `--explain`'s aliases read
  the tables, and prints the `time` and `size` deprecation notices; #614
  generates the family-prefixed `-so` names under the aggregate-naming
  record's rules (432 D1, a bare metric word is its total; 432 D3, duration
  keeps its bare spellings), writes the `-so` error and full help row, and
  deprecates `total`, `count_total` and `std_dev`. Recorded on #614 by comment.
- **D15 — LOCKED 2026-09-28 (architect) — Every built-in name matches
  case-insensitively on every option**: metrics, parsed fields (thread,
  session, user, object, query-string) and identifiers (uuid, ip, ipv4, ipv6)
  alike. `-x User` is the user field, `-d UUID` removes UUIDs, `-m IP` equals
  `-m ip`. A key written in the line whose spelling collides with a built-in
  name by case is named through #582 (naming by regular expression).
- **D16 — LOCKED 2026-09-28 (architect) — `-x object` appends the full object
  onto the end of the message, as the thread is appended**, because the message
  key carries only the object's last 25 characters and this is the same kind of
  loss. It is always appended, not only when the key's segment was cut;
  optimising that is future work the architect will look at.
- **D17 — LOCKED 2026-09-28 (architect) — `stddev` is the typed statistic
  name, and one deprecation-notice helper serves every deprecated spelling.**
  The statistic-name table makes `stddev` the typed canonical name, with
  `std_dev` the stored key and a deprecated spelling, and carries a
  deprecated-spelling column as the metric table does, so #614 edits one entry
  to deprecate it. This issue owns one deprecation-notice helper (one stderr
  line per deprecated spelling, for one release, with a release-notes line)
  that #614 and, if `-s`/`-ms` are later deprecated, #525 (timestamp precision
  option) call; it is recorded under the behavioural-notices entry of
  `docs/architecture-patterns.md`.

---

## 5. Design

Everything in this section restates or applies D1 to D17 unless it is marked
**proposed**; a proposed element is implementation detail the architect did not
decide. Code is cited by sub plus an in-body snippet; table, helper and
resolver names not already in `ltl` are proposed.

### 5.1 The four tables

Each follows the time-unit ladder's shape (`features/524-bucket-size-unit.md`
D1): one file-scope table in the `## GLOBALS ##` section, its views derived
beside it, one resolver, no sub keeping a copy.

**Built-in metrics** (D5), in display order:

| name | layout column | family | help text | deprecated spelling, and the options it still works on for one release |
|---|---|---|---|---|
| `duration` | the duration column | duration | how long an entry took | `time` on `-hm`, `-hg`, `-so` (D1) |
| `bytes` | the bytes column | bytes | response or payload size | `size` on `-so` (D8) |
| `count` | the count column | count | work completed, per entry | none |

Derived views: the case-folded lookup (D15), the ordered name list, the list
texts the messages and help rows interpolate (`duration, bytes, count` and
`duration|bytes|count`), `@graph_columns`, the metric entries of
`@visibility_columns`, the keys of `%heatmap_metric_map`, the metric loops of
the six internal consumers (§ 3 item 3), and the built-in arm of the heatmap
value formatter, which reads the family column instead of its own name chain.
The family column is what #617 (one width-to-format rule) reads for a built-in
metric's kind, so this issue is the only one that rewrites that chain; #617
routes the family through its dispatch afterwards. The layout column is the id
`%heatmap_metric_map` holds today; the colour stays resolved from
`@column_layout`. **Proposed:** `%column_aliases` keeps `dur`, `byt` and `cnt`
as column shorthands on `--hide` and `--show` only; they are column
abbreviations, not metric names, and do not become names on `-hm`, `-hg`, `-x`
or `-d`.

A token key a format reads a built-in metric from is not a name in this table
(D3, D11). The keys come from the format registry's probe declarations
(`format_registry_specs` :: `mask_key => 'durationM[sS]'`), which is where the
metric's mask is built; **proposed:** a view derived beside the registry maps
each probe key spelling as written (`durationMS`, `durationMs`, `bytes`) to its
metric, read by the `-x` and `-d` resolvers (§ 5.2). The view is derived from
the static specs, so it is available when the options settle, before the
registry is built.

**Parsed fields and message parts** (D6, D15, D16):

| name | `-x` does | `-d` does | `--hide` column |
|---|---|---|---|
| `thread` | appends ` thread=<value>` (566 D4) | clears the captured value (567 D9) | none |
| `session` | appends ` session=<value>` (566 D5) | clears the captured value | `session` |
| `user` | appends ` user=<value>` (566 D5) | clears the captured value | `user` |
| `object` | appends ` object=<full value>` (D16) | clears the captured value | none |
| `query-string` | keeps the query string (566 D6) | removes the query string (567 D15) | none |

Names match in any case (D15). The object append follows the thread's rule: a
value that is undefined, empty or `-` appends nothing.

**Identifiers** (D7, D15): `%mask_patterns` and `@mask_order` (they exist) gain
the group name `ip` (IPv6 then IPv4, in mask order) as a table entry, so the
name list `uuid, ip, ipv4, ipv6` is derived, not written. Names match in any
case.

**Statistic and aggregation names** (D8, D17): one table whose rows are the
names a user types for a statistic or an aggregation, each with its stored key,
its aliases, its deprecated spelling and the surfaces that accept it:

| typed name | stored key | aliases | deprecated spelling | `-udm` function slot | `-so` | `--explain` topic |
|---|---|---|---|---|---|---|
| `mean` | `mean` | `avg` | none | yes | yes | `mean` |
| `min`, `max` | same | none | none | yes | yes | its own |
| `stddev` | `std_dev` | none | `std_dev` (its notice switched on by #614, D14) | no | yes | `std_dev` |
| `p1` ... `p99999` | same | none | none | no | yes | `percentiles` |
| `iqr`, `cv`, `skewness`, `kurtosis`, `bimodality_coef` | same | none | none | no | yes | its own |
| `sum`, `delta`, `idelta` | same | none | none | yes | no | none |
| `count`, `distinct`, `ratio`, `rate`, `drate` | same | `dcount`, `unique` for `distinct` | none | yes (counting) | no | none |

The rows keep the order of `@duration_family_stats` so #618 (one declaration per
CSV column) can derive the CSV column order from them; this issue does not
touch CSV emission, and the stored key is what every CSV header, `-V` key and
YAML key keeps writing. The `-udm` function slot, `%explain_aliases` and the
bare statistic words of `-so` read this table (D14). **Proposed:** the
per-surface columns are how "one table read by the `-udm` function slot, `-so`
and `--explain`" is met, since the aggregation functions and the reported
statistics are different sets that share `mean`, `min`, `max` and the `avg`
alias.

### 5.2 Resolvers

| Resolver | Over | Called by | Rule |
|---|---|---|---|
| `builtin_metric_name` (exists) | built-in metric table | `-hm`, `-hg`, `-so`, `--hide`/`--show`, `-x`, `-d` | case-insensitive (D15); `durationMs`/`durationMS` are not in it (D3); a deprecated spelling resolves only on the options listed for it, and records its notice with the deprecation helper (D1, D8, D17) |
| `resolve_metric_operand` (exists) | built-in, then user-defined by name then base name | `-hm`, `-hg` | unchanged; user-defined names stay case-sensitive |
| `udm_config_by_name` (exists) | user-defined metrics | every option naming a metric | name, then base name; no token-key arm (D4) |
| `available_metric_names` (exists) | built-in table plus user-defined names | every unknown-metric message | its `qw(duration bytes count)` goes (D5) |
| one message-option resolver shared by `resolve_expose_names` and `resolve_discard_names` (proposed name) | field table, identifier table (`-d` only), built-in metric table, user-defined names, else a line key | `-x`, `-d` | built-in names first, in any case (D2, D15); a user-defined name as written, which on `-d` also discards a line key of the same name (D4); anything else a key as written, matched case-sensitively in the line. A line key that a format probe or a user-defined metric reads is marked with the metric it feeds (§ 5.3, D11, D12) |
| one identifier resolver (proposed name) | identifier table | `-m`, `-d` | a name, in any case, expands to its entries; the run applies them in `@mask_order` (D7, D13) |
| one statistic-name resolver (proposed name) | statistic table | `-udm` function slot, `-so` bare statistic words, `--explain` aliases | case as each surface does today |

On `-d`, a metric is switched off in three cases: its name is given (D4 for a
user-defined metric, `-d duration` for a built-in), a user-defined metric's own
key is given (567 D12, which D4 keeps), or a key a format probe reads a
built-in metric from is given (D12). The second and third are not a naming
fallback: the key is discarded as a key, and the metric reading it is switched
off because its value is gone. The second and third print the switch-off notice
(§ 5.3). When a user-defined metric's name is its key (`-udm 'elapsed::max'`),
`-d elapsed` is the key reading and prints the notice. By D4 ("the key from
the log is the primary reading") and D12, `-d <user-defined name>` also discards a key of the same name written in the
line; on `-x` a user-defined name keeps its number in place and appends
nothing, as 566 D6 and D7 say.

### 5.3 The target shape per lock

| Lock | Before (measured or read) | After |
|---|---|---|
| D1 (`time` is not a metric name) | `builtin_metric_name` :: `return 'duration' if $lc eq 'duration' \|\| $lc eq 'time';`; `-so` ladder `if( $sort_type =~ /^(?:duration\|time)$/i ) {` | `time` leaves the table's names; it is a deprecated spelling on `-hm`, `-hg`, `-so` only; `-x time` and `-d time` are line keys, as today |
| D1 and D8 notices (deprecated `time`, `size`) | none | recorded by the deprecation helper (§ 5.6) during option parsing and printed once per spelling at settlement, outside the warning collector around option parsing that swallows a `warn` inside `handle_histogram_option` (audit, stage 4, measured: `-hg duration,foo` exits 0 with empty stderr). Text (proposed): `Warning: time is deprecated as a metric name (given to -hm/--heatmap, -so/--sort-on): use duration` |
| D2 and D15 (built-in names in any case) | `resolve_expose_names` :: `elsif ( $name eq 'bytes' )        { $expose_metric{bytes} = 1 }` (exact case); `resolve_mask_names` :: `if    ( $name eq 'ip' )` (exact case) | the shared message-option resolver and the identifier resolver fold case for every built-in name: `-x Bytes` is `-x bytes`, `-x User` is `-x user`, `-d UUID` is `-d uuid`, `-m IP` is `-m ip`. A `Bytes=`, `User=` or `UUID=` key is nameable only through #582 (naming by regular expression) |
| D3 (key spellings) | three copies of `$name eq 'duration' \|\| $name eq 'durationMs' \|\| $name eq 'durationMS'` | the spellings are nowhere in the metric table; on `-x`/`-d` they are line keys (D11, D12); on `-hm`/`-hg` they take the unknown-name path of today (`-hm durationMs` with no `-udm`: the pushback warning; with `-udm`: `Unknown heatmap metric ... Available: duration, bytes, count, <udm names>`) |
| D11 (a named key's mask is lifted) | `-x durationMS` resolves to the duration metric and drops its probe key from the compiled mask (`compile_format_extractor` :: `grep { defined $_->{mask_key} && !$exposed->{ $_->{name} } }`); `-x elapsed` finds `lat` through the token-key fallback and sets its `expose` flag | `-x durationMS` is a line key the ThingWorx probe reads for duration: the compiled mask leaves that key spelling out of its alternation, so `durationMS=150` stays in place. `-x elapsed` is a line key a token-key metric reads: every such metric skips its mask (`$message =~ s/\Q$matched_value\E/?/ unless ... $config->{expose}`). The line-key append then finds the value in the message and appends nothing, by the test 566 D7 already has (`next if defined $message_value && $message_value eq $line_value;`). The key matches as written: `-x durationMs` lifts nothing on a line written `durationMS=`. **Proposed:** the probe's `durationM[sS]` alternation is split into its written spellings at compile time so one spelling can be left out |
| D12 (discard a key whole, and its metric) | `-d durationMS` is `-od`: duration columns gone, message still reads `durationMS=?` (measured on ThingWorx standard lines carrying `durationMS=`, `bytes=`, `count=`); `discard_key_sub` :: `my $value = q{[^\s,;"'\])&?]*};` stops at a masked `?` | `-d durationMS` removes the pair whole and switches the duration metric off, as `-od` does, with the switch-off notice; `-d duration` nulls the metric and leaves the key in the message, as today. **Proposed:** the key discard's value pattern accepts the mask placeholder `?` as a whole value, so the pair, its value and one separator go whether or not the value was masked |
| D12 notice (a metric switched off through its key) | none (§ 3 item 1) | one stderr line per metric switched off, a behavioural notice printed with `--disable-progress`. Text (proposed): `Note: -d/--discard removes the key elapsed, which the -udm metric lat reads: the metric is switched off`; for a built-in, `Note: -d/--discard removes the key durationMS, which the duration metric reads: the metric is switched off` |
| D13 (mask and discard order-independent) | a key discard on a masked value leaves `?&` or a doubled space (§ 3 item 9); `-d ipv4,ipv6` and `-d ipv6,ipv4` differ (§ 3 item 2) | every discard pattern matches its target whether or not a mask has already replaced its value: the metric mask's `?`, a `-udm` mask's `?`, and the `-m` placeholders (whose `#`, `.` and `:` the key value pattern already accepts). The pipeline order 580 D4 fixes (form, expose, discard, mask) stays; the result no longer depends on it. `-d` identifiers are collected, expanded through the identifier resolver, and applied in `@mask_order` whatever order they were typed |
| D4 (a user-defined metric named by its name) | `resolve_expose_names` :: `// ( grep { defined $_->{token_key} && $_->{token_key} eq $name } @udm_configs )[0];` (and in `resolve_discard_names`) | the fallback goes from both. `-x elapsed` is a line key whose mask is lifted (D11); `-x lat` keeps its number in place; `-d elapsed` removes the pair and switches `lat` off with the notice; `-d lat` switches `lat` off without the notice, as `-d duration` nulls duration without one; `-hm elapsed` and `--hide elapsed` stay errors |
| D5 (one built-in metric table) | twenty-plus literal copies (§ 3 item 3) | every copy reads the table's views; the three unknown-metric texts keep their wording (#614 owns rejection wording) and interpolate the table's list, so the `-hm` pushback warning renders the same `(duration\|bytes\|count)` it renders today and the never-printing `-hg` warning stops naming `time` |
| D6 and D16 (`object` a parsed field; `-x object` appends it whole) | `-x object` appends ` object=9` from a query string (measured on a three-line access-log fixture whose request query string carries `object=9`, without `-xqs`) | `object` is a parsed field on `-x`: its `-x` arm appends ` object=<full object>` after the formed message, in the order the names were given, as the thread is; a literal `object=` key is nameable only through #582 |
| D7 (identifiers through the mask table) | `resolve_discard_names` :: `elsif ( $name eq 'uuid' \|\| $name eq 'ipv4' \|\| $name eq 'ipv6' ) { push @discard_subs, discard_identifier_sub($name) }`; `resolve_mask_names` :: `print_usage("Unknown mask name '$name' for -m. Valid values: uuid, ip, ipv4, ipv6");` | `-d` resolves identifiers through the identifier resolver (order per D13); `-m`'s error interpolates the table's name list (same text) |
| D8 and D17 (one statistic table; `stddev` typed) | `%function_names`, `%udm_agg_aliases`, `%explain_aliases`, the `-so` allow-list and ladder each hold `avg`; the `-so` ladder accepts `std_dev` and `stddev` | each reads the statistic table; `-so size` ranks by bytes and prints its deprecation line; `-so stddev` and `-so std_dev` both rank by the stored `std_dev`, the second without a notice until #614 switches it on |
| D9 (flags derived once) | `$expose_active` and `$mask_active` set in their resolvers and again in `apply_discard_precedence` | one settlement step after `apply_discard_precedence` derives `$expose_active`, `$mask_active`, `$mask_uuid`, `$discard_active` and `$discard_any_field` from their final lists; the resolvers and the precedence pass only build lists |

**Proposed: the switch-off is resolved from the probe declarations.** Options
settle before any file is read, so the switch-off is taken from the keys the
format probes declare, not from the keys a file's lines carry. The ThingWorx
probe reads the duration metric from both `durationMS=` and `durationMs=`, so
`-d durationMs` switches the duration metric off for the run even on a log
whose lines are all written `durationMS=`, and removes nothing from those
lines; the notice says which key switched it off.

**A boundary D11 does not reach.** A user-defined metric defined by a pattern
rather than a key names no key, so naming a key its pattern happens to read
does not lift its mask: `-x elapsed` with a pattern-form metric masking
`elapsed=` appends ` elapsed=<value>` by 566 D7 (measured today: `GET
/app/items?elapsed=?&v=3 elapsed=9`). That metric's number stays in place when
the metric is named (`-x <its name>`). This follows from D11's wording ("the
key a user-defined metric reads", "a metric defined from `elapsed`"); it is
unchanged behaviour and is stated so the criteria do not assert otherwise.

### 5.4 `-x object`

D16 settles it. The field table's `-x` arm for `object` appends
` object=<value>` with the object as the format captured it, after the formed
message and in command-line order among the other exposed values; `-V
runtime-config` lists `object` under `expose`. On the ThingWorx family, whose
key carries the object's last 25 characters (§ 3 item 7), two objects that
share their last 25 characters become two messages. The append is
unconditional; appending only when the key's segment was cut is future work.
The key's own bracketed segment is unchanged (the cut belongs to #619, one
per-run key cut and cap).

### 5.5 Case folding

D15 settles it for every built-in name: the metric, field and identifier
tables each fold case in their lookup, and `-V runtime-config` lists a name
given in another case in its canonical spelling. The keys that become
nameable only through #582 are those whose spelling folds onto a built-in name:
`Duration=`, `Bytes=`, `Count=`, `Thread=`, `Session=`, `User=`, `Object=`,
`Query-String=`, `UUID=`, `IP=`, `IPv4=`, `IPv6=`, in any case. A token key
(`durationMS`, a user-defined metric's key) is not a built-in name and matches
as written.

### 5.6 The deprecation-notice helper (D17)

One helper records a deprecated spelling (or option) as it is met during
option parsing, with the options it was given on and its replacement, and
prints one stderr line per deprecated spelling at option settlement. It is a
behavioural notice: it always prints, `--disable-progress` included. Callers in
this issue: `time` on `-hm`, `-hg`, `-so` (D1) and `size` on `-so` (D8).
Callers after it: #614 (`std_dev` by switching on its entry in the statistic
table's deprecated-spelling column; `total` and `count_total` in the
family-prefixed `-so` set it generates, neither being a row of this issue's
tables) and #525 (timestamp precision option) if `-s`/`-ms` are deprecated.
**Proposed:** the two existing option deprecation notices (`-os/--omit-stats`
and `-uuid/--mask-uuid`) route through the helper with their text unchanged, so the codebase has one
place that prints a deprecation.

### 5.7 User surfaces that change

| Surface | Change | Drop |
|---|---|---|
| `-hm time`, `-hg time`, `-so time` | still duration; one deprecation line for `time` (D1, D17) | 2 |
| `-so size` | still bytes; one deprecation line (D8, D17) | 2 |
| `-x Bytes`, `-x Duration`, `-x COUNT` and every case variant on `-d` | the built-in metric, not a line key (D15) | 2 |
| `-x durationMS` on lines written `durationMS=` | same messages as today, now by the key reading: the value stays in place, nothing appended (D11) | 2 |
| `-x durationMs` on lines written `durationMS=` | no longer lifts the mask; the key is not in those lines, so nothing changes in the message (D3, D11) | 2 |
| `-d durationMs`, `-d durationMS` | removes the pair whole and switches duration off with a notice (D12) | 2 |
| `-hm durationMs`, `-hg durationMs` | unknown name, as `-hm foo` today (D3); wording unchanged | 2 |
| `-x <key of a -udm metric>` | a line key whose mask is lifted; same message as today (D4, D11) | 2 |
| `-d <key of a -udm metric>` | unchanged effect on the metric, now with a notice; a masked pair leaves no residue (D4, D12) | 2 |
| `-d <name of a -udm metric>` | unchanged (D4) | 2 |
| `-d <any key>` whose value a mask replaced | the pair goes whole: no `?&`, no doubled space (D12, D13) | 2 |
| `-x Thread`, `-x USER`, `-d Object`, `-d Query-String` | the parsed field, not a line key (D15) | 3 |
| `-m IP`, `-m UUID`, `-d IPv4` | the identifier, not a usage error or a line key (D15) | 3 |
| `-x object` | appends ` object=<full object>` (D16) | 3 |
| `-d ip` | removes IPv6 then IPv4 addresses, as `-m ip` masks them (D7, D13) | 3 |
| `-d ipv4,ipv6` (any order) | removals applied in mask order (D7, D13) | 3 |
| `-m` error, `-hm`/`-hg` unknown-metric errors, `-hm` pushback warning | same text, list derived (D5, D7) | 1 |
| `--help statistics` and the `--explain` index | the summary lines' alias notes read the statistic table: `mean` shows `avg`; the standard-deviation line names `stddev` as the typed name and `std_dev` as its deprecated spelling (D8, D17) | 1 |
| `--help` rows for `-hm`, `-hg`, `-so`, `-x`, `-d`, `-m`, `--hide`, and the function-name part of the `-udm` function row | lists interpolated from the tables; the `-so` row shows `time` and `size` as deprecated spellings of `duration` and `bytes`, as `docs/usage.md` does; the `-x` row gains `object`. #608 edits the unit-list part of the `-udm` row; this issue edits its function names only | 1 to 3 |
| `docs/usage.md` rows for the same options, the `-so` value table, § Alternate Names | agree with `--help`; `time` and `size` shown as deprecated; `stddev` shown as the name, and `std_dev` as the spelling CSV headers and YAML keys carry; § Alternate Names corrected to where each alias works (§ 3 item 5) | 1 to 3 |
| `-V runtime-config` `expose`, `discard`, `mask` | list resolved names; a built-in name given in another case is listed in its canonical spelling (567 D18 "lists the resolved names"); a key is listed as written | 2, 3 |
| STATS and MESSAGES CSV, YAML export | unchanged byte for byte on every run that uses no changed spelling | all |

### 5.8 Boundary with #614

D14 settles it. #614 (operand checks settle once per option; pushback,
rejection texts and help rows derive from the vocabulary checked) is blocked by
this issue and reads its tables. This issue: the bare metric words and bare
statistic names of `-so` and the aliases of `--explain` read the tables; the
`time` and `size` notices; the deprecated-spelling column with `std_dev` in it.
#614: the family-prefixed `-so` names generated under 432 D1 and D3, the `-so`
error and full help row, the `total`, `count_total` and `std_dev` deprecations
through this issue's helper.

Three further lines follow from other locks, not from D14. FP.4 (every list a
message or help row names derives from the table it validates against) applies
here to this issue's four vocabularies, by D5 and D7. FP.5 (one helper for the
optional-operand pushback) is #614's, by stage 4's lock of F1.6 (one pushback
rule for the five optional-operand options). `--explain` accepting the
family-prefixed names `-so` accepts, such as `duration_mean`, is #614's
requirement that `--explain` resolve through the statistic table `-so` reads
(stage 4, F1.19).

### 5.9 Pattern entries in `docs/architecture-patterns.md`

Each edit changes only this issue's token in a shared status line.

- **Declarative table with one resolver:** four consumption sites added (the
  metric, field, identifier and statistic tables with their resolvers); this
  issue's part of the status line (the metric-name resolver called by two of
  six options that take metric names, the `-m` error listing its vocabulary as
  a literal) is rewritten to what remains, and the entry stays *needs
  refinement* until #614 (operand texts derive from the vocabulary) and #608
  (the byte ladder) land.
- **One resolution surface per vocabulary:** the metric-operand consumption
  sites become the message-option resolver and the identifier resolver; #613
  leaves the status line's list of refining issues.
- **Run-scoped activation flags resolved once:** the settlement step of D9 is
  added as a consumption site, and both "the expose and mask flags are set in
  their resolve subs and again in `apply_discard_precedence` (audit, FP.3)" and
  "The expose and mask flags are #613;" leave the status line.
- **Behavioural notices, deferred while progress owns the terminal:** the
  deprecation-notice helper (D17) and the switch-off notice (D12) are added as
  consumption sites; the helper is named as the one way a deprecation prints.

---

## 6. Acceptance criteria

Agreed with the architect 2026-09-28, derived from D1 to D17. Every `ltl` run
in a harness is shaped to its assertion (`--disable-progress -ni -bs 1440 -oe`,
`-o` in a scratch directory where a CSV is read, `-n` small where only the
messages table is read) and checked for ` at <file> line <N>` on stderr
(`tests/lib/runtime-warnings.sh`). Each assertion is proven to fail against the
base build, except those marked *holds today*, which guard behaviour the change
must keep.

| # | Condition | Observable outcome | Triage and method |
|---|---|---|---|
| 1 | `-udm x::max -hm foo`, `-udm x::max -hg foo`, `-hm foo` (D5) | errors read `Available: duration, bytes, count, x`; the pushback warning reads `(duration\|bytes\|count)`; no message names `time` | assertable: `tests/validate-runtime-config.sh` stderr scenarios, on the Tomcat access fixture (*holds today*: the texts keep their wording and read their list from the table; -udm comes first because -hg pushes an unrecognised operand back as a file name when no -udm has yet been read) |
| 2 | `-hm time`, `-hm TIME`, `-hg time`, `-so time` each alone, and `-hm time -hg time -so time` together (D1, D15, D17) | each runs as duration (`-V runtime-config` `heatmap: duration`; the histogram and the ranking identical to the `duration` run); each run prints exactly one deprecation line naming `time` and `duration`, including the `-hg` run, and the combined run prints one line, not three | assertable: `tests/validate-runtime-config.sh`, Tomcat access fixture |
| 3 | `-so size` (D8, D17) | messages ranked as `-so bytes` (messages CSV identical) plus exactly one deprecation line | assertable: `tests/validate-runtime-config.sh`, access fixture with `-o` |
| 4 | `-x time`, `-xqs -d time` on access lines whose query string carries `Bytes=`, `time=`, `object=`, `elapsed=` (D1) | `-x time` appends ` time=<value>`; `-d time` removes the `time=` pair; the latency columns are present in both | assertable: `tests/validate-message-expose.sh`, `tests/validate-message-discard.sh`, new committed fixture (below) (*holds today*) |
| 5 | `-x Bytes`, `-x BYTES` against `-x bytes`; `-d Bytes`, `-d DURATION` against `-d bytes`, `-d duration` (D15) | messages and statistics CSVs identical pairwise; no ` Bytes=` appended; `-V runtime-config` lists `bytes`, `duration` | assertable: the same two harnesses, new fixture and `tests/fixtures/numeric-highlight-boundary.txt` (ThingWorx standard lines carrying `durationMS=`, `bytes=`, `count=`) |
| 6 | `-x Thread`, `-x USER` against `-x thread`, `-x user`; `-d Object` against `-d object`; `-d UUID`, `-d IP` against `-d uuid`, `-d ip`; `-m IP`, `-m UUID` against `-m ip`, `-m uuid`; `-x Object`, `-x Session`, `-x Query-String`, `-d Session`, `-d Query-String` against their lower-case spellings (D15) | messages CSVs identical pairwise, exit 0; nothing appended under a folded name; `-V runtime-config` lists the canonical spelling | assertable: `tests/validate-message-expose.sh`, `tests/validate-message-discard.sh`, `tests/validate-message-mask.sh`, on the ThingWorx application-log fixture and the mask harness's existing identifier lines |
| 7 | `-x durationMS`, and separately `-x duration`, on the ThingWorx fixture whose lines are written `durationMS=` (D11) | the two messages CSVs are identical; the line carrying 150 reads `durationMS=150` in place with `bytes=?` and `count=?`; no message carries `durationMS` twice; the statistics CSV is identical to the run without `-x`; `-V runtime-config` `expose: durationMS` | assertable: `tests/validate-message-expose.sh` `metric-names` scenario, `tests/fixtures/numeric-highlight-boundary.txt` (the in-place assertions *hold today*; the resolution path changes) |
| 8 | `-x durationMs` on the same fixture (D3, D11) | messages CSV identical to the run without `-x`: every message still reads `durationMS=?`, nothing appended | assertable: same scenario; replaces the assertion that `-x durationMs` is `-x durationMS` |
| 9 | `-udm 'lat::max:elapsed' -xqs` with `-x elapsed`, and separately with `-x lat` (D4, D11) | both messages CSVs read `elapsed=<value>` in place and append nothing; identical to each other; `lat` still measured (`-V udm-specs`) | assertable: `tests/validate-message-expose.sh`, new fixture |
| 10 | `-d durationMS` on the ThingWorx fixture (D12) | no message carries `durationMS`, a doubled space or `?&`; the statistics CSV carries no duration columns, as with `-od`; exactly one switch-off notice naming `durationMS` and the duration metric | assertable: `tests/validate-message-discard.sh` `metrics` scenario (its `dur-durationMs`/`dur-durationMS` loop) |
| 11 | `-d duration` on the same fixture (D12) | identical output to `-od`; messages still read `durationMS=?`; no switch-off notice | assertable: the same `metrics` scenario (*holds today*) |
| 12 | `-udm 'lat::max:elapsed' -xqs -d elapsed`, and `-udm 'lat::max:elapsed' -xqs -d lat` (D4, D12) | no `lat` metric (`-V udm-specs`) in either run; exactly one switch-off notice with `-d elapsed`, none with `-d lat`; with `-d elapsed` the message reads `GET /app/items?v=<value>` with no `?&` | assertable: `tests/validate-message-discard.sh`, new fixture |
| 13 | order independence: `-xqs -d elapsed` with a pattern-form `-udm` that masks `elapsed=`, against `-xqs -d elapsed` with no `-udm`; `-d tookMs` with a pattern-form `-udm` masking a space-separated `tookMs=` on ThingWorx lines, against `-d tookMs` with no `-udm`; `-m ipv4 -d peer` against `-d peer` on a line carrying `peer=192.0.2.7` (D12, D13) | the message column of each pair is identical; none carries `?&` or a doubled space | assertable: `tests/validate-message-discard.sh`, new fixture and lines staged in the harness (as it already stages its separator cases); the `-m ipv4 -d peer` pair *holds today* (discard runs before mask) |
| 14 | `-d ip`, `-d ipv4,ipv6`, `-d ipv6,ipv4` on a ThingWorx line carrying `peer ::ffff:192.0.2.7 closed`; `-m foo` (D7, D13) | the three messages CSVs identical, reading `peer closed`; the `-m` error text unchanged and its list read from the table | assertable: `tests/validate-message-discard.sh` (line staged in the harness), `tests/validate-message-mask.sh`; the `-m foo` text *holds today* |
| 15 | `-hm durationMs` with no `-udm`; `-hm durationMs -udm x::max` (D3) | the first prints the pushback warning of criterion 1; the second the unknown-metric error of criterion 1 | assertable: `tests/validate-runtime-config.sh` (*holds today*) |
| 16 | `-hm elapsed`, `--hide elapsed` with `-udm 'lat::max:elapsed'` (D4) | both exit non-zero naming the vocabulary | assertable: `tests/validate-runtime-config.sh`, `tests/validate-section-layout.sh` (*holds today*) |
| 17 | `-x object` on the ThingWorx application-log fixture; `-x object -xqs` on the new access fixture carrying `object=` (D16) | ThingWorx: every message whose object is defined, not empty and not `-` ends ` object=<full object>`, and no other message carries ` object=`; the message for `c.t.s.s.p.PlatformSubsystem` carries all 27 characters; the bracketed key segment is as without `-x`; access: nothing appended (the format has no object field); `expose: object` | assertable: `tests/validate-message-expose.sh`, committed ThingWorx application-log fixture and the new fixture |
| 18 | `-udm 'b::avg'`, `--explain avg`, `--explain stddev`, `--explain std_dev`, `--explain p95`, `-so avg` against `-so mean`, `-so stddev` against `-so std_dev` (D8, D17) | `-V udm-specs` `aggregation=mean`; the four topics render; each ranking pair identical; no deprecation line for `std_dev` in this issue | assertable: `tests/validate-udm-specs.sh`, `tests/validate-explain.sh`, `tests/validate-statistics-demand.sh` (*holds today*) |
| 19 | `--help` and `docs/usage.md` (D5, D10, D14) | every row that lists metric, field, identifier or statistic names (`-hm`, `-hg`, `-so`'s bare metric and statistic words, `-x`, `-d`, `-m`, `--hide`, the function-name part of the `-udm` function row) lists exactly the table's names, in table order; `time` and `size` appear only as deprecated spellings; the `-hm`, `-hg`, `-m`, `--hide` and `-udm` function rows each list what their matching error or warning prints (`-x` and `-d` print none, and the `-so` error is #614's); `--help` and `docs/usage.md` agree | assertable: `tests/validate-help-content.sh`, the rows added to the parity scenario #608 builds (a help row's interpolated list against the list the matching error prints), not a second mechanism |
| 20 | `-x thread -d thread`, `-m uuid -d uuid`, `-xqs -d query-string` (D9) | the 567 notices for a name given both to expose and discard, or to mask and discard (567 D13, D17), print, nothing is appended or masked, output identical to `-d` alone | assertable: the existing discard-harness scenarios for those three cases (*holds today*) |
| 21 | the source (Done when) | each of the four sets is written once: no `qw(duration bytes count)`, no `qw( thread session user object )`, no `uuid, ip, ipv4, ipv6`, no `avg` alias, no `(alias: avg)` or `(alias: stddev)` literal, and no built-in name chain in the heatmap value formatter outside its table; every deprecation line (`time`, `size`) is printed by one helper (`grep -F 'is deprecated'` finds one print site) | unassertable by a behavioural harness (a property of the source, not of a run); checked at review by `grep -F` counts, recorded in the completion comment |
| 22 | no changed spelling used | every other harness passes without re-blessing; STATS and MESSAGES CSVs byte-identical | assertable: the full suite at the completion gate |
| 23 | `-hm Bytes`, `-hg BYTES`, `-so Bytes`, `--hide Bytes` against `bytes` on each (D15) | identical output pairwise (`-V runtime-config` `heatmap: bytes`; histogram, ranking and hidden column identical) | assertable: `tests/validate-runtime-config.sh`, `tests/validate-section-layout.sh`, Tomcat access fixture (*holds today*) |

**New fixture:** `tests/fixtures/message-vocabulary-access-keys.txt`,
synthetic, a handful of Tomcat access-log lines with TEST-NET addresses whose
request query strings carry `Bytes=`, `time=`, `object=` and `elapsed=` keys
followed by a `v=` key, with distinct values per line, so a name read as a line
key finds a value, a name read as a metric does not change the message, and a
removed `elapsed=` pair has a key after it.

---

## 7. Verification surface

**`-V` sections read:** `runtime-config` (`heatmap`, `sort-on`, `expose`,
`discard`, `mask`), `udm-specs`, `udm-counting`, `section-layout`. **Changed:**
none in shape. The values of `expose`, `discard` and `mask` change only for a
built-in name given in a case other than its own, which is listed in its
canonical spelling (567 D18: the key lists the resolved names); a key is listed
as written. No key is added or renamed and no section is proposed. The
`runtime-config` section's contract is owned by
`features/225-test-harness-coverage-gaps.md`; #525 (timestamp precision
option) adds a `timestamp-precision:` key to it, independently of this issue.

**Harnesses that read this surface** (the audit's list of fourteen), and what
moves:

| Harness | Scenarios whose spelling or expectation moves | Why the documented contract supports the new value |
|---|---|---|
| `validate-message-expose` | `metric-names`: the `x-durationms` in-place assertions stay (D11 keeps the outcome); `x-durationms-lower` (contract: 566 *Naming*, "either spelling of the key") becomes criterion 8; `-x duration is -x durationMS` stays; new scenarios for criteria 4 to 7, 9, 17 | D3 and D11 amend 566 D6; 566's criterion 8 is amended in the same commit |
| `validate-message-discard` | the metric scenario's `dur-durationMs` and `dur-durationMS` loop (contract: 567 D14 "the three spellings are one name") becomes criterion 10; new scenarios for criteria 4 to 6, 12 to 14 | D12 makes the spellings keys that remove the pair and switch the metric off; 567 D14's table and criterion 8 are amended in the same commit |
| `validate-message-mask` | the `-m` error scenario keeps its text; case scenarios added (criterion 6) | D7 (identifiers through the mask table), D15 (built-in names in any case) |
| `validate-runtime-config` | `warning-hm-non-builtin` keeps its pattern (same text, derived list); new deprecation-notice and unknown-metric scenarios | D1 and D8 (`time` and `size` deprecated with a notice), D5 (unknown-metric lists from the table), D17 (one deprecation helper) |
| `validate-help-content` | `G-udm-function-list-parity`, `H-mask-option-rows`, `I-discard-option-rows` keep their patterns; this issue's rows join #608's parity scenario | D5 and D10 (every list derived from its table), D14 (this issue's rows, #614's `-so` row) |
| `validate-udm-specs`, `validate-explain`, `validate-statistics-demand` | none move; criterion 18 added where absent | D8 and D17 keep every accepted spelling |
| `validate-section-layout` | none move; `--hide elapsed` added | D4 (a user-defined metric is named by its name, so `--hide elapsed` stays an error) |
| `validate-bucket-size-units`, `validate-format-registry`, `validate-format-detection`, `validate-histogram-bin-counters`, `validate-profile` | none; run for regression | no spelling they use changes |

No harness in `tests/` runs `-hm`, `-hg` or `-so` with `time`, `size` or a case
variant, or `-x`/`-d`/`-m` with a case variant of a built-in name (searched).

**Fixtures:** the new access fixture above (`.txt`, synthetic); the existing
`tests/fixtures/numeric-highlight-boundary.txt` (ThingWorx standard lines
carrying all three metrics, every duration key written `durationMS=`),
`tests/fixtures/format-detection/thingworx-application-log.txt` and
`tests/fixtures/tomcat-access-single-sample-keys.txt`, each confirmed tracked;
the IPv4-ending IPv6 line, the `peer=` line and the space-separated `tookMs=`
line staged inside the discard harness rather than added to a shared fixture.

---

## 8. Measurement obligations

**Before/after benchmark: yes.** The diff touches executable lines of `ltl`
(workflow § 3 scope table). Every table read and every resolver runs at option
settlement. The per-message paths the change reaches: the value pattern of the
key discard (accepts `?`, D12), the order of `-d`'s identifier removals (a list
built once, D13), the key spellings baked into the generated scan sub's metric
mask at compile time (D11), and the object append, which runs only when `-x
object` is given (D16). No per-line test is added to a run that names none of
them. `single-day-access-log-standard`, `613-before` captured on the base commit
before the first line of code, `613-after` at the gate.

**Prototype: none.** No new or changed data model, no new hot-path capability,
and every criterion's verification method is known (`prototype/README.md`).

---

## 9. Delivery

Each drop is a commit and a push on the issue branch; one PR at the end.

**Ordering, recorded at the start of delivery:** a native `blocked_by` edge
making #617 (one width-to-format rule) blocked by this issue, because its
metric-kind resolver reads the built-in metric table's family column and this
issue rewrites the heatmap value formatter's built-in name chain. The existing
edges (this issue blocks #581, #601, #582, #614, #618) are re-checked in the same
step.

| Drop | Content | What it proves |
|---|---|---|
| 1 | The four tables and their views; every copy of the built-in metric set (the heatmap value formatter's chain included), the identifier list and the statistic aliases reads them; messages and help rows interpolate; the deprecation-notice helper, with the two existing option deprecations routed through it unchanged (proposed, § 5.6); no behaviour changes | criteria 1, 18, 21, 22, and 19 for the rows whose list does not change: the full suite passes unchanged, CSVs byte-identical |
| 2 | Metric names on every option: case folding on `-x`/`-d` (D15), `time` and `size` deprecations (D1, D8, D17), key spellings (D3) with the mask lifted on `-x` (D11) and the pair removed whole with the metric switched off on `-d` (D12), the discard residue fixed (D12, D13), token-key fallback removed with the switch-off notice (D4); 566, 567, 432 and histogram records and `docs/usage.md` trued in the same commit | criteria 2 to 5, 7 to 13, 15, 16, 23, and 19 for the `-hm`, `-hg` and `-so` rows |
| 3 | Fields and identifiers: case folding (D15), `-x object` appended in full (D16), `-d` through the identifier table and order (D7, D13), the flags derived once (D9), pattern entries updated | criteria 6, 14, 17, 20, and 19 for the `-x`, `-d` and `-m` rows |

### Implementation plan (2026-10-04)

The sequence inside each drop. It applies § 5 and decides nothing; anything
marked *proposed* there stays proposed.

**Re-audit at the start of implementation (2026-10-04, base 12712ae).** Every
snippet § 3 and § 5.3 cite is still found in the sub named. One change since
the specification: #525 (single timestamp-precision option) added two option
deprecation notices, `-s/--seconds` and `-ms/--milliseconds`, beside the
`-os/--omit-stats` and `-uuid/--mask-uuid` notices § 5.6 names. All four route
through the deprecation-notice helper with their text unchanged, so criterion
21's single print site holds. Further literal copies found beyond § 3 item 3:
the `--explain` index footer and the standard-deviation topic's *See also* line
name the `stddev` alias, and the `-udm` function parser's aggregation and
transform alternations name the function set; each reads the statistic table.

**Drop 1, the tables, no behaviour change.**
1. The built-in metric table in `## GLOBALS ##`, before `@graph_columns`: name,
   layout column, family, help text, deprecated spellings with the options each
   works on, and the stored key a bare `-so` metric word ranks by (proposed:
   the `-so` ladder's metric arms then read the table instead of a name chain).
   Derived views: ordered names, case-folded lookup, the comma and bar list
   texts.
2. `@graph_columns`, the metric entries of `@visibility_columns`,
   `%heatmap_metric_map`, `available_metric_names`, the six internal loops and
   the export's histogram order read the views; `format_heatmap_value`'s
   built-in arm dispatches on the family column.
3. The parsed-field table (name, `-x` action, `-d` action), read by the
   field-flag derivation; the identifier table (`uuid`, `ip`, `ipv4`, `ipv6`,
   each expanding to `%mask_patterns` entries in `@mask_order`), read by `-m`,
   its error and its help row.
4. The statistic table (typed name, stored key, aliases, deprecated spelling,
   per-surface columns): the `-udm` function slot's name set, alias map,
   alternations and invalid-function list; `%explain_aliases`; the bare
   statistic words of the `-so` allow-list and ladder; the alias notes of
   `--help statistics`, the `--explain` index footer and the standard-deviation
   topic.
5. The deprecation-notice helper: records a deprecated spelling or option
   with the options it was given on and its replacement, prints one line each
   at settlement; the four existing option notices route through it.
6. Help rows and error texts interpolate the lists: `-hm`, `-hg`, `-x`, `-d`,
   `-m`, `--hide`, the bare words of `-so`, the `-udm` function row. Rendered
   text identical where the list does not change.
7. Harness: criterion 1 stderr scenarios, criterion 18, criterion 19 rows added
   to the help-content parity scenario; full suite unchanged.

*Delivered 2026-10-04.* Measured against the base build on 45 invocations
(every `-so` bare word and alias, `-hm` and `-hg` with built-in and unknown
operands, the three unknown-metric texts, the `-m` and `--hide` errors, the
`-udm` invalid-function warning, the four option deprecations together, `-m`
with `-d` on identifiers, `-x` and `-d` on probe keys, `--help`, `--help
statistics`, `--explain` and its alias topics, heatmap and histogram renders):
every output is identical apart from the memory and timing lines, except two
help texts. The `--help statistics` and `--explain` index line for the
standard deviation reads `(name: stddev; std_dev is a deprecated spelling)`
where it read `(alias: stddev)` (§ 5.7, D17). The `--hide` column row takes its
list from the same helper as the `--hide` error, so the column names read
`values (val), rate (rt)` followed by `values are the numbers on the bars and
rate the rates in the legend`, where the row carried the two qualifiers inline;
`docs/usage.md` is trued with it. Harness additions: `K-name-list-parity`
(help-content), `error-unknown-metric-lists` (runtime-config),
`function-aliases` (udm-specs), `scenario-16-sort-on-statistic-aliases`
(statistics-demand), each proven to fail against a sabotaged table or row.
The statistics-demand harness printed its summary inside its last scenario's
block, so a `--scenario` run of any other scenario printed no result and
exited 0 whatever failed; the summary now follows every scenario.

**Drop 2, metric names on every option.** `builtin_metric_name` takes the
option it is resolving for and records `time` and `size` through the helper
(D1, D8); the `-x`/`-d` resolver folds case (D15); the probe key view from the
registry specs (`durationMS`, `durationMs`, `bytes`), with the probe's mask key
split into its written spellings so one can be left out (D11); `-d` on a probe
key or a user-defined metric's key removes the pair, switches the metric off
and prints the switch-off notice (D4, D12); the key-discard value pattern
accepts a masked `?` (D12, D13); the token-key fallback goes (D4); records 566,
567, 432, histogram and `docs/usage.md` trued in the same commit; harness
criteria 2 to 5, 7 to 13, 15, 16, 23.

**Drop 3, fields and identifiers.** Field and identifier names in any case on
`-x`, `-d`, `-m` (D15); `-x object` appends the full object (D16); `-d`
identifiers through the identifier table, applied in `@mask_order` (D7, D13);
one settlement step derives the expose, mask and discard flags after the
precedence pass (D9); 580, 597, 225 records and the pattern entries (§ 5.9);
harness criteria 6, 14, 17, 20.

**Merge gate:** the full harness suite and the before/after benchmark on the
final commit, `$version_number` restored to `0.19.0`,
`tests/validate-help-content.sh` passing, the criterion 21 grep counts
recorded.

---

## 10. Records to update at delivery

| Record | Change |
|---|---|
| `features/566-preserve-named-values-in-message.md` | D6's list: `durationMs`/`durationMS` leave it as metric names and are stated as keys whose mask a named key lifts (D11); `object` joins it, appended in full (D16); case folding stated (D15); § Requirements *Naming* annotated: the key keeps its value in place by the key reading; criterion 8 amended to the spelling written in the line |
| `features/567-discard-named-values-from-message.md` | D14's table (the duration row: `-d duration` nulls the metric, `-d durationMS` removes the pair and switches duration off with the notice; the identifier row naming the table and its fixed order; the `-udm` rows naming the notice; case folding); D12 names the switch-off notice; D16's rule stated for masked values (the pair goes whole); D9 and D15 point at the field table; criterion 8 amended |
| `features/580-mask-uuid-and-ip-address.md` | D5: `-d` resolves through the same table and order; names in any case; D4's pipeline order stated as not changing the result |
| `features/597-section-visibility.md` | D24's note that `--expose` and `--discard` carry an inline copy of the lookup is resolved |
| `features/histogram-charts.md` § Command Line Interface | `time` removed from the built-in names, deprecated for a release; the case contract stated for every option; the contract names the table |
| `features/432-metric-aggregate-naming-parity.md` | D1's "`duration` / `time` = total duration": `time` deprecated by this issue |
| `features/user-defined-metrics.md` § Functions | the function slot reads the statistic table |
| `features/225-test-harness-coverage-gaps.md` | the `runtime-config` contract: `expose`, `discard`, `mask` list canonical spellings for built-in names and keys as written |
| `docs/usage.md` | rows for `-hm`, `-hg`, `-so` (and its value table), `-x`, `-d`, `-m`, `--hide`, the function-name part of the `-udm` function row; § Alternate Names rewritten |
| `--help` (`print_help`) | the same rows, lists interpolated |
| `docs/architecture-patterns.md` | § 5.9 |
| Issue #613 | a comment transcribing D11 to D17 and pointing at § 4 of this document |
| Issue #614 (operand checks and texts) | a comment recording the D14 split and the `std_dev` entry in the deprecated-spelling column it switches on through the helper (D17) |
| Issue #617 (one width-to-format rule) | the native `blocked_by` edge on this issue, and a comment naming the family column its kind resolver reads and that this issue rewrites the heatmap value formatter's chain |
| Issue #608 (the byte-unit ladder) | a comment: this issue's rows join its help-content parity scenario, and this issue edits only the function-name part of the `-udm` function row |
| Issue #525 (timestamp precision option) | a comment: the deprecation-notice helper it calls if `-s`/`-ms` are deprecated, and the shared `-V runtime-config` section whose contract `features/225-test-harness-coverage-gaps.md` owns |
| Release notes (`releases/v0.19.0.md`, created at the release if absent) | yes. Drafts: "Deprecate `time` as a metric name on `-hm`, `-hg` and `-so`; use `duration`. A notice prints for this release." "Deprecate `size` on `-so`; use `bytes`. A notice prints for this release." "Match built-in metric, field and identifier names in any case on every option." "Match a metric key named on `-x` as written: `-x durationMs` no longer exposes a value written `durationMS=`." "Remove a metric key such as `durationMS` from messages with `-d`, and print a notice when removing a key switches its metric off." "Accept `ip` on `-d` to remove IPv6 and IPv4 addresses, as `-m ip` masks them." "Append the full object with `-x object`, as `-x thread` appends the thread." "Stop `-d` leaving `?&` or a doubled space where it removes a masked key." "Apply `-d` identifier removals in `-m`'s order, whatever order they are typed." |
