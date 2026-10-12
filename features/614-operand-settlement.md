# Operand checks settle once per option; pushback, rejection texts and help rows derive from the vocabulary checked (Issue #614)

## Status

Analysis redone 2026-10-12 on branch `614-operand-settlement` (at
`release/0.19.0` b4ec4ef), under CLAUDE.md § Before planning: the owning
records were found by search and each read or dismissed (§ 3), and § 4 states
each surface's contract with the record line behind it. The architect
confirmed § 4 and settled the four places a lock of this issue meets another
record (§ 6, recorded against D1, D2 and D6 in § 2), and confirmed D1's
two-place shape. Observations 1 and 3 to 9 in § 5 are settled, each decision
recorded against the observation and the lock it extends; observation 2 was
set aside by the architect as not a pushback question. Design, acceptance criteria
and the plan follow. No code has changed.

- **Parent:** #622 (the refactoring the redundant-logic audit dispatched), as a
  sub-issue.
- **Blocks:** #630 (remove deprecated options and functionality, the
  catch-all): the `std_dev` spelling on `-so` is removed only after its notice
  has carried a release, and this issue switches that notice on.
- **Record of the audit findings:** `features/342-redundant-logic-surfaces-audit-report.md`
  § Item 1 and § Review progress, stage 4.

---

## 1. Requirement (issue body)

An option's operand is checked once, in one place, and what the tool says about
it is derived from the vocabulary it was checked against.

**Done when (issue body):** each of the five optional-operand options reports
the same way when it takes a file argument; an argument that matched no file
stops the run with a message naming it; `-hg duration,foo` tells the user `foo`
is not a metric and names the metrics it knows; every `-so`, `--help` and `-pr`
message lists what the code accepts; the deprecated spellings print their
notice and still work for the release; `docs/usage.md` and `--help` agree with
the code, asserted by the help-content harness.

## 2. Locked decisions

Locked by the architect 2026-09-27, stage 4 of the #342 review, transcribed
from the issue body.

- **D1 — One pushback rule for the five optional-operand options** (`-hm`,
  `-hg`, `-g`, `-V`, `-mem`): the operand is checked against the option's own
  vocabulary first; otherwise it is a file argument, and the tool says so.
  After recursive expansion and globbing, an argument that resolved to no file
  is a usage error naming it. When it was the only argument, the existing
  no-files error already covers it.
  *Shape confirmed by the architect 2026-10-12.* D1 is decided in two places,
  the same way for every option with an optional operand, as the
  `docs/architecture-patterns.md` entry *Optional-operand options and the
  filename pushback* sets out:
  1. **Option settlement.** One helper serves `-hm`, `-hg`, `-V`, `-g`, `-mem`
     and any later option with an optional operand. A value in the option's
     own vocabulary is taken; anything else is pushed back onto `@ARGV` with
     one notice, the same for every option. Nothing is checked against the
     filesystem here, and no option has an error of its own for a value
     outside its vocabulary.
  2. **File resolution.** The loop over `@ARGV` in
     `adapt_to_command_line_options()` expands every argument, pushed back or
     typed, through `bsd_glob`, or `expand_recursive_pattern` under `-r`, into
     the files it selects. An argument whose expansion selects no file (a
     directory, a path that does not exist, a pattern that matches nothing)
     is the usage error naming it, a directory as a directory, in place of
     today's silent `grep { -f $_ } @in_files` drop. Directories inside a
     pattern that also selected files are still skipped without a word: that
     argument selected files.

  Settled with it where D1 met other records: #226's warn-and-continue for an
  unknown `-V` section is withdrawn (`-V foo file.log` prints the pushback
  notice and stops at file resolution, `foo` selecting no file); 420 D2's
  "unchanged from today" for a bare directory argument is withdrawn (the
  directory stops the run at file resolution).

  **Locked by the architect 2026-10-12** (phase 2 criteria): the pushback is
  silent for all five options. "The tool says so" is met at file resolution:
  a pushed-back value that selects no file is phase 1's usage error, which
  also names the option the value followed and says it is not in that
  option's vocabulary. A pushed-back value that is a file is the normal
  invocation (`ltl -hg access.log`, `ltl -mem access.log`) and prints
  nothing. #231's `-g` and `-hm` pushback warnings, and their rows in
  `docs/usage.md` § Stderr warnings, are withdrawn.
- **D2 — Every metric-taking option validates its operands at option
  settlement**, after user-defined metrics are parsed, through the one
  resolver, as `-hm` does; a handler only records the operand. `-hg`'s check
  moves there.
  *Stated by the architect 2026-10-12* where D1 met histogram-charts, #327 and
  user-defined-metrics criterion 19 (with `-udm` given, an unknown `-hm`/`-hg`
  name is an error listing the metrics): the metrics are one list, the
  built-in metrics then the user-defined ones (`available_metric_names()`;
  613 D5), and every consumer of the metric list reads it from there, with no
  rule of its own. Without `-udm` the user-defined part is empty, so whether
  `-udm` was given changes nothing about the rule: `-hm` and `-hg` follow D1
  either way, and every message that names the metrics lists both parts. Today's
  consumers with a rule of their own: `handle_histogram_option()`'s warning
  names the built-in list only, and the `-hm` handler's message without
  `-udm` names `duration|bytes|count`.
- **D3 — The `-so` vocabulary is generated** from the metric and statistic
  tables of #613 under 432 D1 (a bare metric word is its total) and D3
  (duration keeps its bare spellings). The allow-list, the resolution, the help
  row and the error all read the generated set. `total`, `count_total` and
  `std_dev` are deprecated with a stderr notice for a release and a
  release-notes line (`size` is deprecated by #613).
- **D4 — `--explain` resolves statistic names through the same statistic table
  as `-so`**, so a name `-so` accepts explains that statistic.
- **D5 — One `--help` topic table** (name, renderer) read by the dispatch, its
  error and the help row.
  *Extended by the architect 2026-10-12* (observation 7): the table is
  (name, description, renderer). The help row is generated from it, every
  topic with its one-line description, so `profile` gains one; the
  `docs/usage.md` row matches, asserted by `validate-help-content.sh`.
- **D6 — The `-pr` rejection lists the mode table's keys**, never a literal.
  *Changed by the architect 2026-10-12* where it met 451 D4 (`--help profile`
  is the mode reference; the invalid-mode error "points to `--help profile`
  rather than listing all fifteen names"): 451 D4 holds. The `-pr` rejection
  names the value it was given and points to `--help profile`, and lists no
  modes, so it carries no mode literal for the table to replace.
  *Extended by the architect 2026-10-12* (observation 8): the `-pr` help row
  generates its base-mode names and its `-alt` statement from
  `%profile_modes`, so a mode without an `-alt` key (`day`, per 256) is not
  claimed to have one. 451 D4's "state that each has an `-alt` variant" is
  replaced; the `docs/usage.md` row is corrected to match, asserted by
  `validate-help-content.sh`.

Inherited from `features/613-one-name-vocabulary.md`: **D14** (this issue
generates the family-prefixed `-so` names, writes the `-so` error and full help
row, and deprecates `total`, `count_total` and `std_dev` through #613's helper)
and **D17** (`stddev` is the typed statistic name; `std_dev` is the stored key
and a deprecated spelling whose notice this issue switches on). 613's own scope
line: it "does not move a check, change a rejection message's wording, or
change what an option does with an operand it does not recognise (the
file-name pushback)".

---

## 3. Records: found, read, dismissed

Found with `./process/find-records.sh` over the options (`-hm`, `--heatmap`,
`-hg`, `--histogram`, `--group-similar`, `-mem`, `--memory-usage`, `-so`,
`--sort-on`, `-pr`, `--profile`, `--explain`), the subs that implement them
(`handle_histogram_option`, `resolve_metric_operand`, `available_metric_names`,
`builtin_metric_name`, `dispatch_informational_options`, `_validate_profile`,
`resolve_explain_topic`, `explain_aliases`, `record_deprecation`,
`sort_key_metric_family`, `statistic_names`, `bsd_glob`) and the messages they
print (`treating as positional argument`, `Unknown -V section`, `invalid sort
type`, `unknown --help topic`, `not a valid profile mode`, `unable to open any
files`, `Unknown histogram metric`, `Unknown heatmap metric`): 115 records.
Issue bodies were read where a record pointed at one as the contract
(#226, #231, #261, #327); the finder's issue search is too coarse for option
names (GitHub tokenises `-so` to the word "so").

**Read, owning a contract this issue touches:**

| Record | What it fixes here |
|---|---|
| `features/histogram-charts.md` § Command Line Interface | the `-hg` operand forms, additivity, and the shared metric-operand surface for `-hm` and `-hg` |
| `features/user-defined-metrics.md` § Functions, the duplicate-name record and criterion 19 | the statistic table as the function slot's source; the unknown-metric `Available:` list |
| Issue #327 (closing comments) | the shared surface's verified behaviour, including the unknown-name error with user-defined metrics |
| `features/225-test-harness-coverage-gaps.md` § #231 | the silent-override warnings for `-g` and `-hm`; the `-so` and no-files error scenarios |
| Issue #226 (body) | the `-V` operand grammar and the unknown-section behaviour |
| `features/memory-tracking-improvements.md` S4 | the `-mem` operand and its file-argument shape |
| `features/680-statistics-duration-copies.md` (opening and § the release table) | `-mem release`, hidden |
| `features/fuzzy-message-consolidation.md` § Configuration | the `--group-similar` operand as designed |
| `features/605-input-units.md` § drop 4 and § `--help units` | `-g` stays a bare number; `units` added to the three topic lists, which "are #614's to derive" |
| `features/420-recursive-file-selection.md` § Goal, D1 to D8 | the file-argument filter and directory arguments |
| `features/445-unquoted-glob-consumed-by-shell-before-r.md` D1 to D5 | the no-files failure and its hint |
| `features/log-format-registry.md` F14 | a named pipe argument reaches the no-files error |
| `features/233-degenerate-input-coverage.md` § 2, § 3 | research only ("does not propose implementation"): the directory case's message |
| `features/432-metric-aggregate-naming-parity.md` D1 to D8, O2, O3 | the `-so` naming rules and the `duration_` strip |
| `features/418-unsatisfiable-sort-selection-cost.md` D2, D5 | the `-so` operands by family |
| `features/duration-statistics.md` § `-V statistics-demand` (`sort_gate`) | `operand` as typed; `family` from `sort_key_metric_family()` |
| `features/305-shape-moment-extended-percentile-demand.md` § Statistics-group demand | `-so` as a demand contributor through the statistic's group |
| `features/426-per-message-statistics-store.md` F8 | the `-so` vocabulary is not a subset of the stored columns |
| `features/520-inert-sort-bytes-aggregate-demand.md` D1 | a second copy of the bytes family's `-so` names, in the demand gate |
| `features/616-gated-mean-derivation.md` D21, D25 | impact in the duration family; the `impact` topic and the Ranking group of `--help statistics` |
| `features/613-one-name-vocabulary.md` § 1 to § 7 | the tables, the resolvers, the deprecation helper, the scope split |
| Issue #261 (body) | `--help <topic>` as terse reference, `--explain` as long form; the statistics aliases |
| `features/504-explain-technique-topics.md` F1, F2, D2 | statistic topics in snake case, technique topics in kebab case, never colliding |
| `features/256-time-axis-folding.md` § modes | there is no `day-alt` |
| `features/451-weekday-weekend-profile-modes.md` D1, D4 | the mode table's entries; the `-pr` row and the invalid-mode error |
| `docs/usage.md` § Files, the `-hm`, `-hg`, `-g`, `-V`, `-mem`, `-so`, `-pr`, `--help` rows, § Stderr warnings, § Alternate Names | the user-facing statement of each surface |
| `docs/explain/statistics.md` (header, standard deviation, percentiles) | the statistics reference and its examples |
| `docs/architecture-patterns.md` *Declarative table with one resolver*, *One resolution surface per vocabulary*, *Behavioural notices*, *Sort gates at three pipeline points*, *Optional-operand options and the filename pushback* | the patterns this issue refines |
| `features/342-redundant-logic-surfaces.md` § Item 1, `features/342-redundant-logic-surfaces-audit-report.md` § Item 1 | the audit's inventory (a pointer to the records above, not a contract) |

**Dismissed, with the reason:** every other hit uses one of these options as a
run input or an example, not as a contract on its operand: the release notes
(history, not contract); `503-yaml-aggregate-export`, `597-section-visibility`,
`303-calculated-statistic-sort-path` (ranking behaviour, not the operand),
`617-width-to-format-rule`, `472`, `heatmap.md` and its implementation plan
(their `-hm` forms agree with the histogram record), `269`, `273`, `189`, `187`,
`34`, `289`, `287`, `224`, `305`'s other sections, `458` (it reports `-so`
inert under `-n 0`; the operand still resolves, 520 D1), `561`, `528`, `516`,
`452`, `453`, `456`, `475`, `478`, `444`, `460`, `426-evaluation-framework`,
`293`, `219`, `213`, `638`, `629`, `637`, `640`, `639`, `619`, `598`, `546`,
`457`, `254`, `227`, `2`, `180`, `60`, `index-file`,
`bin-counter-accuracy-and-observability`, `memory-baseline-profiling`,
`hierarchical-message-grouping`, `heatmap-histogram-alignment`,
`column-layout-refactor`, `548`, `652`, `653`, `527`, `312`, `266`,
`histogram-charts-implementation-plan` (superseded by the record),
`docs/explain/techniques.md`, `heatmap.md`, `histogram.md`,
`classification.md`, `docs/test-logs.md`, `docs/purpose.md`,
`docs/process/*`, `docs/percentage-presentation.md`.

---

## 4. The contract of each surface, as the records state it (for confirmation)

Each surface: what the records say, quoted; then what the code does today,
measured on the committed Tomcat access-log fixture of twelve lines with
duration and bytes (`--disable-progress --terminal-width 220`). Where the
records are silent, it says so.

### 4.1 `-hm` (heatmap metric)

- `features/histogram-charts.md`: "built-in names `duration`/`bytes`/`count`
  match case-insensitively ... `time` is a deprecated spelling of `duration` on
  `-hm`, `-hg` and `-so` for one release ... `durationMs` and `durationMS` are
  key spellings, never metric names ... user-defined metric names are
  case-sensitive, matched by name then by base_name". The surface is
  `builtin_metric_name()` at parse time and `resolve_metric_operand()` after
  `parse_udm_configs()`, "with `available_metric_names()` supplying the
  vocabulary named in unknown-metric errors".
- `docs/usage.md` § Stderr warnings: "`-hm <unknown-metric>` without any
  `-udm` configured (e.g. `-hm bogus`): The value is treated as a positional
  argument and the default heatmap metric (`duration`) is applied" (added by
  #231 as a silent-override warning).
- With `-udm` given, an unknown name is an error naming the metrics
  (`Error: Unknown heatmap metric 'x'. Available: ...`; user-defined-metrics
  criterion 19; 613 criteria 1 and 15).
- Today: as stated.

### 4.2 `-hg` (histogram metrics)

- `features/histogram-charts.md`: "`-hg` ... (no argument = all available
  metrics)", "`-hg duration,bytes` | Show specific metrics (comma-separated)",
  "Multiple uses of command line options for -hg should be additive in case
  the overall environment states displaying -hg duration, and the user adds -hg
  bytes"; the shared surface as for `-hm`.
- Issue #327, verified: "`-hg ws_duration` errors listing available metrics
  (including `WS_duration`)".
- No record states what `-hg` does with an unrecognised word when no `-udm` is
  given.
- Today: an unrecognised single word with no `-udm` read yet is pushed back
  silently; `-hg duration,foo` runs duration with empty stderr (the warning is
  raised inside option parsing and swallowed); whether `-udm` has been read
  depends on its position before or after `-hg` (613 criterion 1's note).

### 4.3 `-g` (message grouping sensitivity)

- `docs/usage.md`: "`-g, --group-similar <N>` | ... N% Dice similarity
  threshold (50-99, default: 85)"; § Stderr warnings: "`-g <non-numeric>`
  (e.g. `-g logfile.log`): The non-numeric value is treated as a positional
  argument and the default similarity threshold (85) is applied" (#231).
- `features/605-input-units.md` drop 4: `-g` is one of "two numeric options
  typed as strings" that stay a bare number.
- `features/fuzzy-message-consolidation.md` § Configuration (the design table):
  "Accepts optional `%` suffix (e.g., `85%`). If a decimal like `0.85` is
  provided, it is detected and converted automatically."
- Today: digits only; `-g 85%` and `-g 0.85` are taken as file arguments with
  the #231 warning (measured).

### 4.4 `-V` (verbose sections)

- Issue #226, behaviour contract: `-V <section>`, repeated, comma list, bare
  `-V` (all), `-V all`, `-V list`; "A request for an unknown section emits a
  warning to stderr (`Unknown -V section: foo. Known sections: …`) and
  continues with the remaining valid sections. Exit code unchanged."
- The #226 commit also pushes back a value that looks like a path ("path
  separator, dot, or existing file on disk") silently, as bare `-V`.
- Today: as stated.

### 4.5 `-mem` (memory report)

- `features/memory-tracking-improvements.md` S4: "`-mem` takes an optional
  literal operand `debug`; bare `-mem` is unchanged. Only the literal `debug`
  is recognized — any other following token must remain a file argument
  (`ltl -mem access.log` keeps meaning `-mem` plus a file; the operand must not
  swallow it)."
- `features/680-statistics-duration-copies.md`: `release` is a second literal,
  "behind a hidden `-mem release`".
- Today: as stated; the pushback is silent.

### 4.6 File arguments

- `docs/usage.md` § Files: "Only regular files are accepted; directories and
  other non-file entries in a glob result are silently skipped."
- `features/420-recursive-file-selection.md` D2: "A bare directory argument
  matches nothing, with or without `-r` ... Unchanged from today"; D3:
  "Without `-r`, behavior is exactly what ships today."
- `features/445-unquoted-glob-consumed-by-shell-before-r.md` D1 to D3: when
  nothing is selected, `Error: unable to open any files` (byte-identical, exit
  2), with the quoting hint under `-r` only; "no check on a successful run".
- `features/log-format-registry.md` F14: a named pipe argument ends in the
  same no-files error.
- `features/233-degenerate-input-coverage.md` (research, undecided): a
  directory argument's message "should say 'is a directory'".
- No record states what happens to a path that does not exist when another
  argument selects files.
- Today: every argument that selects no file is dropped without a word; the
  no-files error when nothing is left.

### 4.7 `-so` (sort field)

- 432 D1: "`bytes` = sum of bytes, `duration` ... = total duration, `count` =
  sum of the count metric"; "`occurrences` ... is not a metric, it is how many
  messages matched". D3: "`duration_*` spellings are accepted as **aliases** on
  the CLI"; the CSV headers take the prefix. O3 (closed): "`duration_` is
  stripped once, ahead of both the whitelist and the ladder". D8: the bytes
  family (`bytes_occurrences`, `bytes_min`, `bytes_mean`, `bytes_max`) is a
  `-so` operand and a CSV column. O2 (closed): the whitelist matches
  case-insensitively.
- 418 D2: the operands by family: duration (`duration`, `min`, `mean`, `max`,
  `std_dev`, `cv`, `impact`, `p1`–`p99999`, `iqr`, `skewness`, `kurtosis`,
  `bimodality_coef`); bytes (`bytes`, the four `bytes_*`); count (`count`,
  `count_occurrences`, `count_sum`, `count_min`, `count_mean`, `count_max`);
  occurrences (`occurrences`/`total`).
- `features/duration-statistics.md`, `-V statistics-demand` `sort_gate`:
  "`operand` — the `-so` operand as the user typed it"; "`family` ... resolved
  by `sort_key_metric_family()`".
- 305: the `sort-on` consumer demands "the group containing `$sort_key`".
- 616 D21: impact is in the duration family.
- 613 D8, D14, D17: bare metric words and statistic names read the tables;
  `time`, `size` deprecated; `stddev` typed, `std_dev` deprecated (notice off).
- `docs/usage.md`: the `-so` value table (Totals with `occurrences`, `impact`;
  Bytes; Count without `count_sum`; latency stats; percentiles; shape) and
  § Alternate Names (`occurrences` alternate `total` on `-so`; `mean` alternate
  `avg` on `-so`, `--explain`, the function slot).
- #231 scenario: "error-unknown-so | Exit 1, stdout has `invalid sort type`".
- Today: as stated; `count_total`, `count_avg` and `count_sum` are accepted and
  not all documented.

### 4.8 `--explain` (topic)

- Issue #261: `%explain_aliases` "Mirrors -so value aliases (avg → mean,
  stddev → std_dev) plus every individual percentile slug routed to the shared
  'percentiles' topic".
- 504 D2: statistic topics keep snake case (`std_dev`, `bimodality_coef`),
  technique topics are kebab case; "the two styles never collide".
- 616 D25: the `impact` topic.
- 613 D8: the aliases read the statistic table.
- Today: bare statistic names and aliases resolve; prefixed names
  (`duration_mean`) do not.

### 4.9 `--help` (topic)

- Issue #261: "`--help <topic>` is for terse reference".
- 451 D4: "`--help profile` (a third topic on the existing `--help <topic>`
  surface, beside `statistics` and `formats`)".
- 605: `units` added to "the topic dispatch ..., to its error text ... and to
  the `-?, --help [<topic>]` row; those three lists are #614's to derive".
- `tests/validate-explain.sh` contract: "unknown --help topics are a hard
  error" naming the topic.
- Today: four topics in the dispatch and the error; the row and
  `docs/usage.md` name three (`profile` missing).

### 4.10 `-pr` (profile mode)

- `features/256-time-axis-folding.md`: "There is no `day-alt`: a pure
  time-of-day fold has no week-calendar or work-week concept to vary."
- 451 D1: every mode is its own entry in the table. D4: "The `-pr` row in
  `print_help()` and the matching `docs/usage.md` row name the base modes,
  state that each has an `-alt` variant, and point to `--help profile` to
  choose. The invalid-mode error message points to `--help profile` rather
  than listing all fifteen names."
- Today: the error names the eight base modes "each with an -alt variant" and
  points to `--help profile`; the row says the same of the singular modes,
  `day` included.

---

## 5. Observations (raised after § 4 is confirmed; none is a finding)

Each is a place where the code, a record and the user documentation do not say
the same thing, measured or read; none is called a defect until the architect
says which side is the contract.

1. `-hg` with an unrecognised word and no `-udm` pushes it back silently, and
   whether `-udm` counts depends on its position on the command line (§ 4.2).
   *Settled by the metric-list decision (D2 as stated, § 2).*
2. `-g 85%` and `-g 0.85`: the consolidation design table accepts them; the
   code and `docs/usage.md` do not (§ 4.3). Not a pushback question: under
   D1's shape (§ 2) a value outside `-g`'s vocabulary is pushed back like any
   other option's.
3. A path that does not exist, beside one that does, is dropped without a
   word; `docs/usage.md` documents the directory skip only (§ 4.6).
   *Settled by D1's shape: file resolution (§ 2).*
4. The `duration_` strip of 432 O3 accepts `duration_` before any accepted
   word: `-so duration_bytes` ranks by total bytes, `duration_occurrences` by
   message count, `duration_count_sum` by the count sum (measured).
   *The intention, stated by the architect 2026-10-12:* the naming is
   `<metric>_<statistic>`. Duration, bytes and count each carry statistics
   of the same kind; because `bytes_min` is defined, `duration_min` sorts by
   duration's minimum. The statistic follows the metric it is a statistic of.
   `duration_bytes`, `duration_count_sum` and `duration_occurrences` mix two
   metrics and make no sense; they are artefacts of the blanket strip, not of
   the requirement.
   *The rule, as the architect stated it back 2026-10-12:* each metric, with
   each statistic calculated for it, is `<metric>_<statistic>`. Duration
   carries many more statistics; bytes and count carry a more limited set
   under the same nomenclature. Some names have shorthand aliases: the bare
   statistic (`min`, `mean`, `max`, `p95`) for duration, and the bare metric,
   which is its sum statistic (`bytes` = `bytes_sum`). The blanket `duration_`
   strip of 432 O3 goes. Read against today's `-so` allow-list in
   `adapt_to_command_line_options()`: `count_sum` is accepted, `bytes_sum`
   and `duration_sum` are not.
5. `docs/usage.md`'s `-so` Count group omits `count_sum`; `count_avg` and
   `count_total` are accepted and undocumented; `bytes_avg` is rejected while
   `avg` works for `mean` and `count_mean` (measured).
   *Settled by the architect 2026-10-12.* The documented groups, `count_sum`,
   `bytes_sum` and `duration_sum` follow from the naming rule (observation 4)
   and D3's generated set; `count_total` is already deprecated by D3.
   **Locked:** `avg` is accepted after the metric prefix, `<metric>_avg`
   meaning `<metric>_mean` for every metric that has a mean (`bytes_avg`,
   `count_avg`, `duration_avg`) — for `avg` only. The intention is to move
   away from a list of aliases for statistics, not to generate prefixed forms
   from an alias column. Today `avg` on `mean` is the only alias in
   `@statistic_names` that `-so` reads; `distinct`'s `dcount` and `unique`
   belong to the `-udm` function.
6. `docs/explain/statistics.md` shows `ltl -so std_dev -n 20 access.log`;
   once D3 switches the `std_dev` notice on, that example prints it.
   *Settled by the architect 2026-10-12:* the example requires `stddev`
   (613 D17: `stddev` is the typed name).
7. The `--help` row and `docs/usage.md` row name three of the four topics
   (§ 4.9). *Settled by the architect 2026-10-12:* D5 as extended (§ 2).
8. The `-pr` row and error say the singular modes each have an `-alt`
   variant; 256 says `day` has none (§ 4.10). *Settled by the architect
   2026-10-12:* the error by D6 as changed, the row by D6 as extended (§ 2).
9. With `-udm` given, `-hm` followed by a file that exists
   (`-udm x::max -hm <file> <file>`, twelve-line access fixture) stops with
   `Error: Unknown heatmap metric '<file>'` and exit status 25: the error is a
   bare `die`, whose status comes from whatever the last system error was,
   not a set usage-error code (measured).
   Measured on the same fixture: `-so bogus`, `--help bogus` and
   `-pr day-alt` exit 1; `-udm x::max -hg foo` exits 25. Under D1's shape a
   single unknown word after `-hm`/`-hg` is pushed back; the metric rejection
   that remains is a comma list with an unknown member (`-hg duration,foo`).
   **Locked by the architect 2026-10-12:** that rejection exits with status 1,
   like the other rejections this issue touches. The other `die` sites in
   `ltl` are outside this issue.

## 6. Where a lock of this issue meets another record (raised after § 4 is confirmed)

| Lock | The other record | Where they meet |
|---|---|---|
| D6: the `-pr` rejection lists the mode table's keys | 451 D4: the invalid-mode error "points to `--help profile` rather than listing all fifteen names" | the `-pr` error text. **Settled 2026-10-12:** 451 D4 holds; the error names the value and points to `--help profile`, no mode list (D6 as changed, § 2) |
| D1: a value outside the option's vocabulary is a file argument | #226: an unknown `-V` section name warns and the run continues | `-V foo file.log`. **Settled 2026-10-12:** D1 holds; `foo` is pushed back with the common notice and stops the run at file resolution (D1's shape, § 2) |
| D1: as above | histogram-charts, #327, user-defined-metrics criterion 19: with `-udm` given, an unknown `-hm`/`-hg` name is an error listing the metrics | `-hm foo -udm x::max file.log`. **Settled 2026-10-12:** one metric list for every consumer, built-in then user-defined; the rule does not depend on `-udm` (D2 as stated, § 2) |
| D1: an argument that resolved to no file is a usage error | `docs/usage.md` § Files and 420 D2/D3: directories in a glob result are silently skipped | a directory argument beside files. **Settled 2026-10-12:** D1 holds; any argument whose expansion selects no file is a usage error naming it, raised at file resolution (D1's shape, § 2) |

## 7. Plan

The phase split, agreed by the architect 2026-10-12. Each phase's acceptance
criteria are agreed here before its tests and code.

1. **File resolution.** An argument whose expansion selects no file stops the
   run with a usage error naming it, a directory as a directory (D1's shape,
   place 2). First, because phase 2's pushback relies on it.
2. **One optional-operand helper** for `-hm`, `-hg`, `-V`, `-g`, `-mem`: a
   value in the option's vocabulary is taken, anything else is pushed back
   with one common notice (D1's shape, place 1), replacing the four `unshift`
   sites, `-V`'s path sniff and its warning.
3. **Metric operands at option settlement.** `-hm` and `-hg` are resolved
   after user-defined metrics are parsed, through the one resolver; every
   message listing metrics reads `available_metric_names()`; the comma-list
   rejection exits 1 (D2 as stated; observation 9).
4. **The `-so` vocabulary generated** from the tables: `<metric>_<statistic>`
   for each metric and the statistics it carries, duration's bare statistic
   names, the bare metric as its sum, `<metric>_avg`; the blanket strip and
   the literal allow-list go; the `total`, `count_total` and `std_dev` notices
   switch on; help row, `docs/usage.md` table and error read the set (D3;
   observations 4 and 5).
5. **`--explain`** resolves statistic names through the statistic table (D4).
6. **The `--help` topic table** of name, description and renderer (D5 as
   extended).
7. **`-pr`:** the error names the value and points to `--help profile`; the
   help row is generated from `%profile_modes` (D6 as changed and extended).
8. **Records and documentation:** `docs/usage.md` rows, the `stddev` example
   (observation 6), the *Optional-operand options and the filename pushback*
   entry's status in `docs/architecture-patterns.md`, the records this issue
   changes (432 O3, #226, 420 D2, 451 D4) annotated, release notes.

Nothing in the plan runs per log line; no prototype. The before/after
benchmark runs at the completion gate.

## Acceptance criteria

### Phase 1 — file resolution

Verification for every criterion: new scenarios in
`tests/validate-recursive-file-selection.sh` (the file-selection harness),
on its committed fixture tree `tests/fixtures/recursive-file-selection/`,
with its `-bs 1440 -oe -n 1 -V format-detection` shape: the exit status, the
stderr error block, and the `files:` / `file:` lines of `-V format-detection`
for what was selected. Each criterion is run without and with `-r`. All are
assertable; the fixture tree and the assertion surface already exist.

- [x] **A directory beside a file.** `ltl <fixture>/archive <fixture>/alpha.888`
      stops before reading any file, exit 2, and the error names
      `<fixture>/archive` and says it is a directory.
- [x] **A path that does not exist beside a file.** `ltl <fixture>/absent.888
      <fixture>/alpha.888` stops before reading any file, exit 2, and the
      error names `<fixture>/absent.888`.
- [x] **A pattern that matches nothing beside a file.** `ltl
      "<fixture>/*.none" <fixture>/alpha.888` (quoted, so `ltl` expands it)
      stops before reading any file, exit 2, and the error names the pattern
      as typed.
- [x] **Every such argument is named.** With two arguments that select no
      file beside one that does, the one error names both.
- [x] **Expansion comes first.** A quoted pattern that selects files
      (`"<fixture>/*.888"`) is never reported as selecting nothing; it runs
      and selects the files it matches.
- [x] **Directories inside a pattern that selected files stay silent.**
      `ltl "<fixture>/*"` without `-r` selects the root's four files
      (`alpha.888`, `beta.888`, `charlie.123`, `delta.000`) and skips
      `archive/`, `nested/` and `only-nonmatching/`; with `-r` it selects every
      file in the tree. Either way stderr carries no file-selection message.
- [x] **Nothing selected at all is the existing failure, unchanged.** When no
      argument selects any file, whether one argument or several, the run
      ends in `Error: unable to open any files`, byte-identical, exit 2, with
      the quoting hint under `-r` only (445 D1 to D3). The existing
      `bare-directory-matches-nothing` and `no-match-quoting-guidance`
      scenarios pass unchanged.
- [x] **The mechanism.** The check runs inside the existing expansion loop in
      `adapt_to_command_line_options()`, on each argument's `bsd_glob` or
      `expand_recursive_pattern` result, and reports through `print_usage()`,
      the mechanism the no-files error uses; the silent
      `grep { -f $_ } @in_files` drop no longer discards a whole argument.

### Phase 2 — one optional-operand helper

Verification for every criterion: scenarios in
`tests/validate-runtime-config.sh`, which owns today's pushback warnings
(`warning-g-non-numeric`, `warning-hm-non-builtin` and the `-hm` pushback runs
of `error-unknown-metric-lists` and `metric-key-spelling-unknown`, all
rewritten), on the twelve-line access fixture with `-bs 1440 -oe`: stderr, the
exit status, the `-V runtime-config` command-line values for what each option
took, and the `-V format-detection` `file:` lines for what was selected. The
mechanism criterion is a source check in the same harness, as
`quantity-units-declared` checks `ltl`'s source in the option-resolution
harness. All are assertable.

- [ ] **A value in the option's vocabulary is taken**, with no pushback and no
      notice: `-hm bytes`, `-hg duration,bytes`, `-V format-detection`,
      `-V format-detection,csv-output`, `-V all`, `-g 90`, `-mem debug`,
      `-mem release`. `-V list` still lists the sections and exits 0.
- [ ] **Anything else is pushed back as a file argument**, and the option
      takes its bare default: for each of the five, `ltl <option>
      <fixture>` selects the fixture, exits 0, and runs with `-hm` on
      `duration`, `-hg` on every available metric, `-V` on every section,
      `-g` at 85, `-mem` without its debug detail.
- [ ] **The pushback is silent, the same for all five.** In that case stderr
      carries nothing from the option: `ltl -hg <fixture>`,
      `ltl -mem <fixture>`, `ltl -g <fixture>` and the rest run clean.
- [ ] **A pushed-back value that is not a file stops at file resolution,
      naming the option.** `ltl -V foo <fixture>` and `ltl -g 85% <fixture>`
      end in phase 1's usage error, exit 2, which names the value, the option
      it followed, and that it is not in that option's vocabulary (the
      metrics from `available_metric_names()` for `-hm` and `-hg`, a pointer
      to `-V list` for `-V`, 50 to 99 for `-g`, `debug` for `-mem`).
- [ ] **User-defined names are in the vocabulary wherever `-udm` stands.**
      `-hm x -udm x::max` and `-udm x::max -hm x` both take `x`; likewise
      `-hg`. User-defined metrics are parsed before the helper runs.
- [ ] **A comma list with a member in the vocabulary belongs to the option.**
      `-V format-detection,foo` is a rejection naming `foo` and pointing to
      `-V list`, exit 1, never a file argument; the same rule gives
      `-hg duration,foo`'s rejection in phase 3.
- [ ] **The mechanism.** One sub makes the decision for all five options;
      `unshift @ARGV` occurs in `ltl` only in that sub and in the
      environment-argument merge in `adapt_to_command_line_options()`; `-V`'s
      path test (`$name =~ m{[/.]} || -e $name`) is gone.

### Phase 3 — metric operands at option settlement

`-hm` takes one value, so after phase 2 an unknown `-hm` word is always
pushed back and the `Unknown heatmap metric` error no longer exists; the
metric rejection left is `-hg`'s comma list. Verification: scenarios in
`tests/validate-runtime-config.sh` (`error-unknown-metric-lists`,
`deprecated-metric-spellings`, `metric-name-case`,
`metric-key-spelling-unknown`, `udm-key-not-a-name`, rewritten where they
assert the `Unknown heatmap metric` error) and the base-name panels of
`tests/validate-udm-specs.sh`, on their existing fixtures with `-bs 1440 -oe`:
exit status, stderr, and the rendered histogram panel titles. All are
assertable.

- [ ] **A comma list with an unknown member is a rejection.** `-hg
      duration,foo` exits 1 before any file is read, names `foo`, and lists
      `duration, bytes, count`; with `-udm x::max` it lists `duration, bytes,
      count, x`. Today it runs `duration` with an empty stderr.
- [ ] **One metric list for every run-time message.** Each message that
      lists metrics at run time (the `-hg` rejection, phase 1's error for a
      value pushed back from `-hm` or `-hg`) reads `available_metric_names()`:
      the built-in metrics, then the user-defined ones. No run-time message
      writes the built-in list alone. The help rows, written before any
      `-udm` is read, keep the table's built-in list and "or one of your own".
- [ ] **`-udm`'s position does not matter.** `-hg duration,x -udm x::max` and
      `-udm x::max -hg duration,x` render the same two panels; so do
      `-hg rows -udm rows -udm rows::delta` and the order reversed.
- [ ] **What resolution does today is kept.** Built-in names in any case
      (`-hg BYTES`); user-defined names case-sensitive, then by base name
      (#104); `time` still works with its deprecation notice; `durationMs` is
      a key spelling, never a metric name (inside a list it is the
      rejection); a counting user-defined metric still turns the heatmap off
      with its warning and is still skipped by `-hg` with its warning; `-hg`
      stays additive across the environment and the command line; bare `-hg`
      still shows every available metric but counting ones.
- [ ] **The rejection exits 1 through the usage path.** It is reported
      through `print_usage()` and `exit 1`, as the `-so` rejection is, never a
      bare `die` (observation 9).
- [ ] **The mechanism.** `handle_histogram_option()` records the operand and
      resolves nothing: no `builtin_metric_name()` call and no warning in it.
      Every `-hm` and `-hg` operand is resolved after `parse_udm_configs()`
      through `resolve_metric_operand()`.

### Phase 4 — the `-so` vocabulary generated from the tables

Verification: scenarios in `tests/validate-statistics-demand.sh` (the
`sort_gate` line of `-V statistics-demand`: operand as typed, family) and
`tests/validate-runtime-config.sh` (`error-unknown-so`, deprecation notices),
plus `tests/validate-help-content.sh` for the rows. Equivalence is asserted by
identical stdout of two runs on the same fixture. All are assertable.

- [ ] **Every generated name ranks.** For each metric and each statistic it
      carries, `-so <metric>_<statistic>` is accepted and its `sort_gate`
      family is that metric: duration carries sum, min, mean, max, stddev,
      the twelve percentiles, iqr, cv, skewness, kurtosis, bimodality_coef
      and impact; bytes and count carry sum, occurrences, min, mean and max.
- [ ] **Shorthands are the same sort.** These pairs give identical stdout:
      `bytes`/`bytes_sum`, `count`/`count_sum`, `duration`/`duration_sum`,
      `min`/`duration_min`, `p95`/`duration_p95`, `impact`/`duration_impact`,
      `avg`/`mean`/`duration_avg`/`duration_mean`, `bytes_avg`/`bytes_mean`,
      `count_avg`/`count_mean`.
- [ ] **Cross-metric names are rejected.** `duration_bytes`,
      `duration_count_sum`, `duration_occurrences`, `duration_total`,
      `bytes_p95` and `count_stddev` exit 1 with the `-so` error, which names
      the value and lists what `-so` accepts in the words of the help row.
- [ ] **Deprecated spellings work for the release, with their notice.**
      `total`, `count_total`, `std_dev`, `duration_std_dev`, `time` and
      `size` each print one `Warning: ... is deprecated` line naming
      `-so/--sort-on` and the replacement, and give the same stdout as the
      replacement. `stddev` prints none.
- [ ] **The rows read the set.** The `-so` help row and the error print the
      same vocabulary text; the `docs/usage.md` `-so` table agrees with it
      (`validate-help-content.sh`).
- [ ] **The mechanism.** One table of `-so` spellings is generated from
      `@builtin_metrics` and `@statistic_names`; the `s/^duration_//` strip,
      the literal allow-list and the `elsif` ladder are gone; the sort
      family is read from the table entry, not inferred from a key prefix.

### Phase 5 — `--explain` through the statistic table

Verification: `tests/validate-explain.sh`, comparing topic output. All are
assertable.

- [ ] **A `-so` name that names a statistic explains it.** `--explain
      duration_p95` shows the percentiles topic; `bytes_mean`, `count_avg`
      and `duration_avg` the mean topic; `duration_stddev` the std_dev topic;
      `duration_impact` the impact topic; `bytes_min` the min topic.
- [ ] **What is not a statistic topic stays unknown.** `--explain bytes_sum`
      and `--explain bytes_occurrences` keep the unknown-topic error, since
      neither sum nor a metric's occurrences has a topic.
- [ ] **The mechanism.** `resolve_explain_topic()` resolves a spelling
      through the `-so` table entry's statistic and that statistic's
      `explain` field; no second list of spellings.

### Phase 6 — the `--help` topic table

Verification: `tests/validate-help-content.sh` and `tests/validate-explain.sh`
(unknown topics are a hard error). All are assertable.

- [ ] **Each topic renders as before.** `--help statistics`, `formats`,
      `profile` and `units` give the same output as before the change.
- [ ] **The error and the row read the table.** `--help bogus` exits 1 with
      the error naming `bogus` and the four topics; the `--help` row names
      all four, each with its one-line description; the `docs/usage.md` row
      matches.
- [ ] **The mechanism.** One table of name, description and renderer; the
      dispatch iterates it, with no `elsif` per topic.

### Phase 7 — `-pr` error and row

Verification: `tests/validate-help-content.sh` for the rows,
`tests/validate-profile.sh` unchanged. All are assertable.

- [ ] **The error points, and lists nothing.** `-pr bogus` exits 1 with an
      error naming `bogus` and pointing to `ltl --help profile`, naming no
      mode.
- [ ] **The row is generated from the mode table.** The `-pr` help row names
      the singular modes (a one-day period) and the plural modes (a one-week
      period) in table order and says which have an `-alt` variant, so `day`
      is not claimed to have one; the `docs/usage.md` row matches.
- [ ] **Profiles fold as before.** `validate-profile.sh` and
      `validate-profile-render.sh` pass unchanged.

### Phase 8 — records and documentation

Verification: reading, and `tests/validate-help-content.sh`,
`tests/validate-doc-examples.sh` where they reach.

- [ ] `docs/usage.md`: the `-so` table, the `--help` and `-pr` rows, § Files
      (an argument that selects no file is an error), and § Stderr warnings
      without the `-g` and `-hm` pushback rows.
- [ ] `docs/explain/statistics.md` example uses `stddev`.
- [ ] `docs/architecture-patterns.md` *Optional-operand options and the
      filename pushback* names the helper as its one consumption site and is
      marked established.
- [ ] The records this issue changes carry a pointer to it: 432 O3, 420 D2,
      451 D4.
