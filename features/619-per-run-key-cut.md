# One per-run message-key cut, named cut lengths, and the grouping key carried with the entry (Issue #619)

## Status

Specification agreed with the architect 2026-09-28 on branch
`619-per-run-key-cut` off `release/0.19.0`; implementation not started. Nothing
in `ltl` has changed on the branch, and `$version_number` has not been stamped.

The issue comes from stage 13 (the key cut and the cap) of the #342 review of
duplicated logic, decided by the architect on 2026-09-27. It is a sub-issue of
#622 (the parent issue for the refactoring the review dispatched).

**Landing order:** #273 (store precise duration totals), then #616 (one gated
derivation of means over accumulators that always carry an observation count),
then this issue, then #620 (move per-line option handling out of the read loop,
in measured steps). This issue is blocked by #616, because the message-store
entry gains its observation counts in #616 before this issue adds the grouping
key to the same entry. It blocks #620, whose step for run constants computed
before the loop leaves the key cut to this issue. The `before` benchmark and
every memory baseline in this document are re-taken on the tree this issue lands
on, after #616 has merged, never on the commit this specification was written
against.

---

## 1. The motivating consumer

The consumers are three readers who today get a wrong or unstated answer.

1. **Whoever reads a benchmark.** `-V benchmark-data` reports
   `CONFIG max_log_message_length`, and the benchmark TSVs under
   `tests/baseline/results/` keep it as the key length each run used. On every run
   with `-o` or `-g`, the reported value is the terminal width, but the run cut its
   keys at 350 characters. Someone who compares two captures, or who explains a
   memory figure by key length (the #426 per-message store analysis did exactly
   that), is reading a number the run did not use.
2. **Whoever changes a cut length next.** The 350-character cap has two
   spellings: a named variable that consolidation reads, and a literal inside five
   copies of a ternary that cuts the key. Nothing ties the two together. The thread,
   object and consolidation-bucket cuts are literals with no stated reason. A
   change to one spelling silently leaves the other behind. The consolidation
   record's DD-06 (the cap must not cut a UUID part-way, or consolidation fails
   without any message) says that drift costs correctness, not only tidiness.
3. **Whoever works on the consolidation path next.** In the final pass, the
   grouping key (the log level, or the HTTP status on an access log) is recovered by
   parsing it back out of the key's first bracket. That works only because every key
   variant happens to put the level first, and no contract says so. Two upcoming
   changes reach the same path: #465 (stack-trace continuation lines that must never
   become keys) and #564 (choosing where a long message is truncated in the messages
   table). Each needs the grouping key and the key's shape to be stated facts.

The work changes no rendered output and no CSV cell. The only value a user can
see move is the `-V benchmark-data` CONFIG line on `-o` and `-g` runs.

---

## 2. Requirement

The architect's terms, from the issue body, the review's stage rows and the
decisions of 2026-09-28 (§ 4), arranged by topic:

- **One per-run cut.** The length at which a message key is cut is resolved
  once per run into one named value. Everything that cuts, compares or reports
  keys reads that value: the four key sites, consolidation and the `-V` benchmark
  data. The value is the cap when grouping or CSV output is on, and the terminal
  width otherwise. The dead terminal-width branch goes, and so does every
  consolidation cut that provably changes nothing; one guard stays where text
  enters the trigram index.
- **The grouping key travels with the entry.** It is never parsed back out of
  the key.
- **Every cut length is a named constant with its reason.** Where no reason is
  on record, the constant says so.
- **The consolidation record is trued up to the code**, including the fact that
  consolidation across log levels is the design.
- **The unread counter of the observed maximum key length goes.**
- **Done when:** the benchmark data reports the cut the run used; the MESSAGES
  CSV keys and consolidation output are byte-identical to today's on the fixtures;
  the before/after benchmark shows the moved CONFIG line on `-o` and `-g` runs and
  nothing else; the record describes the code.

---

## 3. Findings and corrections to the issue body and the audit record

Each item was checked against the worktree's `ltl` at `58f8d94` with `grep -F`
and by reading the enclosing sub; the runs quoted below state their input and
options.

| # | What was cited | What was found |
|---|---|---|
| 1 | The literal `350` sits in five ternaries beside the named cap, which nine sites read | **Holds.** Four ternaries are in `read_and_process_logs` (one per key variant) and one is in `group_similar_messages`. The cap `$consolidation_message_length_cap` is read by `read_and_process_logs` (1), `group_similar_messages` (2), `get_consolidation_trigrams` (1), `run_consolidation_pass` (2), `process_final_pass_window` (2) and `consolidation_cliff_edge` (1). |
| 2 | The benchmark data reports the terminal width on runs that cut at 350 | **Holds, reproduced.** A two-line access-log fixture has one request line of 434 characters. Run with `-ni -bs 1440 -oe -n 3 --terminal-width 120 -o -V`, it prints `CONFIG max_log_message_length 120`, while the long key in the MESSAGES CSV is 350 characters. `-g` also prints 120. |
| 3 | Every `-o` or `-g` benchmark TSV carries the wrong value | **Holds, with the scope made exact.** `run-benchmark.sh` always passes `--terminal-width 200`, so all 35 committed TSVs that carry the row report `200` (1,122 rows). Three of the eleven scenarios are affected: `top25-consolidate` (`-g`), `heatmap-histogram-consolidate` (`-g`) and `heatmap-histogram-export` (`-hm -hg -n 0 -o`). The export scenario keeps no message and cuts no key; under the one-cut rule (the cap when CSV is on) it will report 350. |
| 4 | One ternary's terminal-width branch can never run | **Holds.** `pipeline_finalize` calls `group_similar_messages()` only under `unless( $group_similar_sensitivity eq "none" )`. |
| 5 | The consolidation input re-cuts every retained key at 350 after the key sites did | **Holds, and applies to every consolidation cut.** Under `-g` every key is at most 350 characters. The other eight readers of the cap each cut a string that is already at most 350: a key, the capped message stored for a key, or a canonical form built from those. `derive_canonical` emits at most one character per input character, so it never lengthens its input. All nine cap cuts, and the canonical form's cut in the fifth ternary, are no-ops under `-g`. |
| 6 | The batch path parses the level four times and strips it with a fifth regex | **Holds.** `group_similar_messages` has `my ($grouping_key) = $log_key =~ /^\[([^\]]+)\]/;` at three sites and `my ($gk) = $log_key =~ /^\[([^\]]+)\]/;` at one. The sort comparator strips the prefix with `/^\[[^\]]+\]\s*(.*)/s`, and when that fails it falls back to the whole key. |
| 7 | The audit's target for the grouping key says the consolidation store "already keeps" it in `%consolidation_key_message_cat_gk` | **Does not hold as a carrier; the map is written and never read.** `consolidation_process_key` writes it, `run_consolidation_checkpoint` deletes from it on eviction and consumption, and `group_similar_messages` empties it when the final pass starts. No site reads it. It costs memory for every key in the streaming working set and has no reader. |
| 8 | The bucket-key cut takes the first word to 30 characters, else the message to 20, and its comment says 20 | **Holds; the cut changes no key, and the split it makes is by level.** `extract_consolidation_bucket_key` receives the capped whole key, or a canonical form, not the message body. The first word of every key is its bracketed level, which every key of one group shares. So within one group the re-scan split is a single bucket. The 20-character branch cannot run, because every key starts with `[`, which is not whitespace. The 30-character cut acts only on a level longer than 29 characters. A probe on a scratch copy of `ltl` printed each final-pass window's buckets on five committed fixtures (two application logs carrying thread and logger, one holding a line at each of six levels and one holding INFO and WARN lines that carry control characters; and three access logs whose level is the HTTP status, two answering only 200 and one answering 200 and 500): a window holding keys of one level held one bucket; a window holding keys of two levels (item 9) held two. The partition that `docs/staged-processing-pipeline.md` credits with a 21 % speed-up (`[LEVEL][class]` in the prototype) does not divide a group in `ltl`. How this relates to the plain and highlighted split is § 5.5. |
| 9 | (not in the issue) `features/fuzzy-message-consolidation.md` § Grouping Key Design says an ERROR message is never compared with a WARN message | **The record does not describe the code; the code is the design (D1 below).** In the final pass of `group_similar_messages`, a window with fewer than two keys is not processed and is carried on, so a lone key of one level joins the window of the next level. Two application-log lines with the same thread, logger and body, one at ERROR and one at WARN, print under `-g` as one row with the level shown as `[*]` and 2 occurrences. The probe of item 8 found windows holding two levels on three of the five fixtures: both application logs (the six-level log and the INFO and WARN log) and the access log answering 200 and 500. Nothing in the key text is exempt from consolidation, the level included; the record is trued up to say so. |
| 10 | IQ-01 names `--consolidate-full-key`, and treats session as a grouping field under `--include-session` | **Neither option exists in `ltl`.** |
| 11 | The cap's reason is DD-06 | **DD-06 gives the reason for grouping only.** The value 350 came first from the CSV option: the commit that added MESSAGES CSV output used `$write_messages_to_csv == 1 ? 350 : $max_log_message_length`. The grouping change adopted it "same as CSV output". No record gives a reason for the CSV's 350; its reason is now that it shares the grouping cap, so `-o` and `-o -g` produce the same keys (D5). |
| 12 | The thread cut is 20 and the object cut is 25, with no reason on record | **Holds.** Both came in one commit ("Truncate message object and thread names in message stats") with no stated reason. The thread keeps its first 20 characters and the object keeps its last 25. `my $max_object_length = 25;` is re-declared for every retained message. They are recorded as having no reason on record (D5). |
| 13 | `docs/architecture-patterns.md` § Hot-loop discipline says #620 refines the key length recomputed per line | **The owner is this issue.** #620's body says "the key cut is #619". This issue corrects the status line by adding its own token and changing nothing else in it. |
| 14 | #174 was closed as not planned on 2026-09-28 | **Closed 2026-09-27** (20:46 UTC). The closing comment is in the architect's terms and points the unread counter to this issue. |
| 15 | The completion gate's benchmark case would show the moved CONFIG line | **It would not.** `docs/process/workflow.md` § 3 (b) names `single-day-access-log-standard`, which runs neither `-o` nor `-g`. `compare-results.sh summary` does not print CONFIG rows. `detailed` does print them, and it labels a 200 to 350 step as `REGRESS +75.0%`. The gate is widened to four cases (D6). |
| 16 | (not in the issue) The bucket-key split has one caller per path | **A third, dead copy exists.** `partition_consolidation_keys` builds the same buckets as the loops in `run_consolidation_pass` and `process_final_pass_window`, and nothing calls it. |

---

## 4. Locked decisions

### 4.1 Locked by the architect on 2026-09-27

Transcribed verbatim from the issue body and the review's stage rows in
`features/342-redundant-logic-surfaces-audit-report.md` § Review progress. Locks
1 to 5 carry the issue body's numbering; 6 and 7 are the two locks recorded only
in the stage rows, numbered here for reference.

1. **One per-run cut**, resolved once at option settlement: the cap when
   grouping or CSV is on, the terminal width otherwise. The four key sites,
   consolidation and the `-V` benchmark data read it. The dead branch and the
   no-op re-cut go. *Source: issue body lock 1; stage 13 row ("one per-run cut
   read by the key sites, consolidation and the benchmark data"); stage 15 row
   (F8.2, the per-line key-length expression, "in #619").*
2. **The grouping key travels with the entry** and is never parsed back out of
   the key. *Source: issue body lock 2; stage 13 row ("the grouping key
   carried").*
3. **Every cut length is a named constant with its reason** (the cap's reason is
   `features/fuzzy-message-consolidation.md` DD-06; the thread, object and
   bucket-key cuts get theirs recorded or are questioned). The display cut in the
   messages table is a rendering cut on a different value, owned by #564, and
   stays distinct. *Source: issue body lock 3; stage 13 row ("every cut named
   with its reason").*
4. **The consolidation record is trued up** to the code (IQ-01, IQ-02).
   *Source: issue body lock 4; stage 13 row ("the record trued up"); stage 16 row
   ("F7.7 in #619", the record's observed-length description).*
5. **#174 (adaptive cap) is not the vehicle**: every use of the cap is a
   first-N-characters cut and nothing is sized by the cap, so the smaller of the
   observed maximum and 350 changes no key and no trigram; the finding is on that
   issue for the architect's disposition. *Source: issue body lock 5. #174 was
   closed as not planned on 2026-09-27.*
6. **The unread observed-maximum counter goes with #619.** *Source: stage 13
   row, and the architect's closing comment on #174.*
7. **The benchmark data reports the cut the run used**, which moves a CONFIG
   line in every benchmark TSV and is accounted for in this issue's
   before/after. *Source: stage 1 row (F7.4 "folded into stage 13 (the cut
   length resolved once per run and reported is the fix)") and stage 13 row.*

### 4.2 Locked by the architect on 2026-09-28

In reply to six questions put to him on this specification. Where he answered
"yes", the recommendation is the decision; where he changed one, his words
govern.

- **D1. Consolidation across log levels is the design, not a defect.** Locked by
  the architect 2026-09-28. Text contained in the message key does not have
  parts that are allowed or not allowed to consolidate. An ERROR line and a WARN
  line with the same body consolidating into one row under `-g` is intended. The
  grouping key the entry carries (2026-09-27 lock 2) is the batching key the code
  uses to order its work, not a barrier to consolidation. No bug is filed,
  nothing changes in the final-pass window, and consolidation output stays
  byte-identical. The consolidation record is trued up in this issue so that the
  condition is never raised as a defect again (§ 10).
- **D2. No carrier prototype and no amendment to the done-when for the grouping
  key.** Locked by the architect 2026-09-28, who ruled the question not
  relevant. The grouping key travels with the entry as locked on 2026-09-27. The
  before/after benchmark reports the `-g` runs' memory as it does on every run;
  any movement is reported and attributed in the findings report at the gate,
  not written into the done-when in advance. The key-to-group map that is written
  and never read (§ 3 item 7) is recorded as a finding beside the carried key,
  for the implementation to remove if the carried key makes it redundant.
- **D3. Every provably redundant consolidation cut is removed; one guard stays
  at the trigram boundary.** Locked by the architect 2026-09-28. The guard reads
  the per-run cut, so a future source of keys that bypasses the key sites still
  enters the trigram index cut. The change is behaviour-identical, proven by the
  equivalence matrix (AC3).
- **D4. The re-scan partition's constants are named with what the code does
  today; no separate issue is filed.** Locked by the architect 2026-09-28.
  Behaviour does not change. The architect's reading was that the inert
  partition is the split between plain and highlighted messages, active when
  highlighted messages are many and inert when no highlight is active; § 5.5
  records what the code does beside that reading.
- **D5. A cut length with no reason on record is recorded as such.** Locked by
  the architect 2026-09-28. The thread's first 20 characters and the object's
  last 25: "no reason on record". The CSV's 350: it shares the grouping cap, so that
  `-o` and `-o -g` produce the same keys. The architect is asked for a reason
  only when a relevant or valid purpose needs one; none does here.
- **D6. The gate is four single-day access-log cases.** Locked by the architect
  2026-09-28. `standard`, `top25-consolidate`, `heatmap-histogram-consolidate`
  and `heatmap-histogram-export`, medians of three, compared in `detailed` mode,
  with a boundary note in `tests/baseline/README.md` in the shape of the existing
  note on the consolidating scenarios gaining `-m uuid`. The comparison tool's
  labelling of CONFIG rows stays as it is.

---

## 5. Design

Elements marked **proposed** are implementation detail the architect did not
decide. Everything else follows from a lock of § 4.

### 5.1 Sites this work reaches

| Site (sub :: snippet) | Today | Target |
|---|---|---|
| `(GLOBALS)` :: `my $max_log_message_length = 0;` | declared 0, set to the terminal width | holds the per-run cut (lock 1) |
| `adapt_to_terminal_settings` :: `$max_log_message_length = $terminal_width;` | terminal width | the cap when `-o` or `-g` is in effect after settlement, the terminal width otherwise (lock 1). **Proposed** placement: computed here once, as `($write_messages_to_csv \|\| $group_similar_sensitivity ne "none") ? <cap> : $terminal_width`. This sub runs after `adapt_to_command_line_options`, which has already switched `-g` off under `-n 0`, so both inputs are settled. |
| `read_and_process_logs` :: `$log_key = substr("[$log_level] $message", 0,` (and the three sibling variants) | ternary per retained message | `substr(..., 0, $max_log_message_length)` (lock 1) |
| `read_and_process_logs` :: `my $capped_msg = substr($log_key, 0, $consolidation_message_length_cap);` | no-op re-cut | removed; `$capped_msg` is `$log_key` (lock 1, D3) |
| `group_similar_messages` :: `my $capped_msg = substr($log_key, 0, $consolidation_message_length_cap);` (two sites) | no-op re-cuts | removed (D3) |
| `group_similar_messages` :: `my $canonical_log_key = substr($canonical, 0, ((... ) ? 350 : $max_log_message_length));` | dead branch around a no-op cut | the whole cut removed: the dead branch by lock 1, the remaining cut by D3, since the canonical form is built from keys already at most the cap |
| `run_consolidation_pass`, `process_final_pass_window` :: `my $msg_a = substr($consolidation_key_message{...} // '', 0, $consolidation_message_length_cap);` and `$msg_b` | four no-op cuts | removed (D3) |
| `consolidation_cliff_edge` :: `map { get_consolidation_trigrams(substr($_, 0, $consolidation_message_length_cap)) } @keys` | no-op cut before the guard | removed; the strings pass through the guard (D3) |
| `get_consolidation_trigrams` :: `my $capped = substr($str, 0, $consolidation_message_length_cap);` | the trigram entry cut | **the one guard**, reading the per-run cut (D3) |
| `print_verbose_output` :: `printf "CONFIG\tmax_log_message_length\t%d\n", $max_log_message_length;` | reports the terminal width | unchanged text; it now reports the per-run cut (lock 7). The key name stays, so benchmark rows keep pairing across the change. |
| `read_and_process_logs` :: `my $truncated_thread = defined($threadname) ? substr($threadname, 0, 20) : undef;` | literal 20 | named constant, "no reason on record" (lock 3, D5) |
| `read_and_process_logs` :: `my $max_object_length = 25;` | local re-declared per retained message | named constant at file scope, "no reason on record" (lock 3, D5) |
| `extract_consolidation_bucket_key` :: `return substr($1, 0, 30);` and `return substr($msg, 0, 20);` | literals; the comment says 20 | named constants stating what they do today, and a comment stating what the sub receives (D4, § 5.5) |
| `partition_consolidation_keys` | defined, never called (§ 3 item 16) | removed, under the standing rule that near-duplicates found on the way are converged in the same change (CLAUDE.md § Before writing or changing code) |
| `read_and_process_logs` :: `my $msg_len = length($log_key);` and `(GLOBALS)` :: `my $max_observed_message_length      = 0;` | written, never read | removed (lock 6) |
| `read_and_process_logs` :: `my $grouping_key = $log_level // "";` | the inline path's grouping key | also written onto the store entry under `-g` (lock 2) |
| `group_similar_messages` :: `my ($grouping_key) = $log_key =~ /^\[([^\]]+)\]/;` (three sites), `my ($gk) = $log_key =~ /^\[([^\]]+)\]/;` | parsed back | read from the entry (lock 2) |
| `group_similar_messages` :: `my ($msg_a) = $a =~ /^\[[^\]]+\]\s*(.*)/s;` | strip by regex, twice per comparison | **proposed**: the body is the key after `"[$gk]"` with leading whitespace stripped, computed once per key before the sort; the whole key is used when the grouping key is empty, as today. The order is identical to today's whenever the level holds no `]`. |
| `(GLOBALS)` :: `my %consolidation_key_message_cat_gk;` | written and deleted, never read (§ 3 item 7) | finding recorded beside the carried key; the implementation removes it if the carried key makes it redundant (D2) |
| `print_message_summary` :: `my $message = substr( $key, 0, $col_width{1} );` (and in `print_threadpool_summary`) | display cut | **untouched** (lock 3; #564 owns it) |

### 5.2 Named constants

The reasons are settled (lock 3, D4, D5). The names and the form are
**proposed**: every fixed length becomes a `use constant` at file scope in the
consolidation configuration block, beside the cap. `ltl` already has twelve `use
constant` blocks. A constant folds at compile time, so the key sites pay nothing
for the name. The per-run cut stays a scalar, because it is a value resolved for
the run.

| Constant (proposed name) | Value | Reason written beside it |
|---|---|---|
| `MESSAGE_KEY_CAP` | 350 | Grouping: DD-06, so that a UUID or other variable tail near the end of a long message is never cut part-way. CSV: it shares the grouping cap, so that `-o` and `-o -g` produce the same keys. |
| `MESSAGE_KEY_THREAD_LENGTH` | 20 (first characters) | No reason on record. |
| `MESSAGE_KEY_OBJECT_LENGTH` | 25 (last characters) | No reason on record. |
| `CONSOLIDATION_RESCAN_BUCKET_WORD_LENGTH` | 30 | The re-scan bucket is the key's first word, which is its bracketed level, shared by every key of one group; the cut acts only on a level longer than 29 characters. No reason on record for the value. |
| `CONSOLIDATION_RESCAN_BUCKET_PREFIX_LENGTH` | 20 | Used only for a key that begins with whitespace; no key does, because every key begins with its bracketed level. No reason on record for the value. |

`$consolidation_message_length_cap` is replaced by the cap constant, because the
CSV reads the same value (**proposed** name above).

### 5.3 The grouping key on the entry (lock 2, D2)

The grouping key is a field of the message-store entry
`%log_messages{$category}{$log_key}`, written under `-g` where a store entry is
born in `read_and_process_logs`, and read by the final pass and the sort in
`group_similar_messages`. **Proposed** detail: the field is named `grouping_key`
and is written at the two places an entry is born, the `//=` initialiser in the
`$metrics_observed` branch and the auto-vivifying `{occurrences}++` in the other
branch. The entries that `group_similar_messages` injects from clusters take the
grouping key from `split(/\|/, $cat_gk, 2)`, which the injection loop already
does; nothing after the final pass reads the field, so injected entries do not
carry it.

By D2 there is no carrier prototype and the done-when is not amended. The
before/after benchmark's `-g` cases report the actual memory on the landing tree,
and any movement is attributed in the findings report at the gate.

Beside the carried key sits the finding of § 3 item 7: the key-to-group map
`%consolidation_key_message_cat_gk` is written and deleted but never read. The
implementation removes it if the carried key makes it redundant (D2).

The field is added after #616 has given the same entry its observation counts,
so the entry's shape is read on that tree, not on this document's base commit.

### 5.4 What the grouping key is, and consolidation across levels (D1)

Consolidation works in groups. A group is a category (plain or highlighted, § 5.5)
plus a grouping key (the log level, or the HTTP status on an access log). Each
group has its own patterns, clusters, unmatched keys and stage counters, and the
streaming checkpoints process one group at a time. The grouping key therefore
orders the work. It is not a barrier to consolidation.

Similarity is scored on the whole key, level included, and no part of the key
text is exempt from being wildcarded. The final pass sorts each category's keys
by body and flushes a window when the grouping key changes; a window of fewer
than two keys is carried into the next, so a lone key of one level is compared
with keys of the next level and can consolidate with them. The resulting row
shows the level as a wildcard. This is the design (D1).

This issue keeps the window exactly as it is. The carried grouping key is the
level itself, the value the inline path already uses. Today's parse returns the
text between the leading `[` and the first `]`, or the empty string when the
brackets are empty. The two are equal for every level that holds no `]`. The
implementation checks every format spec's level capture and records here that
none can hold `]`, so every window forms as today.

### 5.5 The two splits on the consolidation path (D4)

The architect's reading was that the inert partition is the split between plain
and highlighted messages. The code has two splits on this path, and the one
whose cut lengths this issue names is not that one.

| Split | What it divides | When it acts |
|---|---|---|
| **Category: plain or highlighted.** A line is highlighted when a highlight option selects it. The category is the outer part of every group, and the final pass walks each category separately. | Plain keys from highlighted keys: they are never compared. | Active whenever a highlight option selects lines, so that a long list of highlighted messages consolidates among itself. With no highlight active, every key is plain and the split has one side. This matches the architect's description. It uses no cut length and this issue does not touch it. |
| **Re-scan bucket (`extract_consolidation_bucket_key`).** Inside one group, after a new pattern is found, only the keys whose bucket matches the pattern's bucket are re-scanned against it. The bucket is the key's first word cut to 30 characters, else its first 20 characters. | Keys by their first word, which is the bracketed level. | Inert within a group whether or not highlighting is active, because every key of a group shares its level. It separates keys only in a final-pass window that holds keys of two levels (§ 5.4). The 20-character branch never runs. |

The constants of § 5.2 are named for the second split, with what it does
today. No behaviour changes and no issue is filed.

### 5.6 User surfaces

| Surface | Change |
|---|---|
| Options, `--help`, `docs/usage.md` | none. No option changes, and no row states a key length. |
| Notices | none |
| Rendered output (bar graph, messages table, summary) | none (byte-identical) |
| MESSAGES CSV, STATS CSV | none (byte-identical) |
| `-V benchmark-data` | `CONFIG max_log_message_length` reads the per-run cut: the cap on `-o` or `-g` runs, the terminal width otherwise. The key name is unchanged. |
| `-V message-grouping` (and `/ cluster-membership`) | none (byte-identical) |

### 5.7 Patterns file

Edits to `docs/architecture-patterns.md`:

- **§ Hot-loop discipline:** add the consumption site
  `read_and_process_logs` :: `$log_key = substr("[$log_level] $message", 0, $max_log_message_length);`
  (a value constant for the run, computed before the loop). The status line's
  owner of the key length is corrected to this issue (§ 3 item 13) by adding this
  issue's token for the key length; the rest of the line, including the tokens
  of #620 (hoisting per-line option handling in measured steps) and #621 (the
  switchable generated loop body), is left as it is.
- **§ One resolution surface per vocabulary:** the status line already names
  this issue among the refiners, and the token stays until the issue closes.
- **§ Run-scoped activation flags resolved once:** unchanged. The per-run cut
  is a value, not a flag.

### 5.8 Relationship to other open issues

- **#616 (one gated derivation of means and totals):** lands first; this issue
  is blocked by it (Status). #616's record, item 15 of its findings, had noted the
  cross-level consolidation as a known condition; #616's delivery rewrites that
  note as the design, per D1, and cross-references § 5.4 here.
- **#615 (CSV as a header-instantiated registry entry):** two seams.
  `tests/baseline/README.md`: #615 adds a named CSV selection and this issue adds
  the boundary note; both go in one boundary-notes section, and whichever lands
  second merges into it. `-V benchmark-data`: this issue moves
  `CONFIG max_log_message_length` from 200 to 350 on the `-o` and `-g` scenarios
  and #615 adds compile-count rows; each completion comment attributes only its
  own movement.
- **#620 (move per-line option handling out of the read loop, blocked by this
  issue):** this issue delivers the key cut that #620's step for run constants
  computed before the loop leaves to it. The string compare on the grouping
  sensitivity in the read loop's consolidation block stays for #620's first step,
  which turns the string-compare gates into booleans resolved once.
- **#564 (choose where a long message is truncated in the messages table):** a
  hand-forward. Without `-o` or `-g`, the key is already cut to the terminal width
  when it is stored, so a left or middle display cut cannot show the message's
  tail: the key cut has already dropped it. How a run that chooses a left or
  middle cut keeps the tail is #564's to decide; after this issue the stored
  key's length is one per-run value resolved at one site.
- **#465 (stack-trace continuation lines):** adds a class of line that never
  becomes a key. There is no interaction beyond the shared path.

---

## 6. Acceptance criteria

- [ ] **AC1. A run with `-o` reports the cut it used.** On the long-request
      fixture at `--terminal-width 120` with `-o -V benchmark-data`,
      `CONFIG max_log_message_length` is `350` and the longest key in the MESSAGES
      CSV is 350 characters. *Assertable:* a new scenario in
      `validate-csv-output.sh` (the harness that owns the MESSAGES CSV), on the
      fixture of § 7.
- [ ] **AC2. The cut follows the one-cut rule on every option shape.** At
      `--terminal-width 120` on the same fixture, the CONFIG value is `350` with
      `-g`, `350` with `-o -g`, `350` with `-n 0 -o`, `120` with `-n 0 -g`
      (grouping is switched off at settlement) and `120` with none of them.
      *Assertable:* one scenario per shape; the `-o` shapes in
      `validate-csv-output.sh`, the others in `validate-message-grouping.sh`.
- [ ] **AC3. Keys and consolidation output are byte-identical to the base
      commit.** Every key variant (level only; level and thread; level and
      object; level, thread and object) runs under plain, `-o`, `-g` and `-o -g`,
      at terminal widths 80, 120 and 200, on inputs with a message longer than 350
      characters, one between the width and 350, `-g -m uuid`, and the pair of
      same-body ERROR and WARN lines that consolidates into one row (D1). Between
      the base commit and the branch head, the MESSAGES CSV, the rendered messages
      table and `-V message-grouping` with `/ cluster-membership` are identical;
      the ERROR and WARN pair prints one row on both sides. *Assertable:* a
      one-off before/after diff over the matrix, the method the audit's hoist
      probe used to prove itself behaviour-neutral
      (`features/342-redundant-logic-surfaces-audit-report.md` § Item 8, Part 2:
      forty identical before/after comparisons before any timing run); the count
      of identical comparisons is recorded in this document.
- [ ] **AC4. No assertion or golden changes.** `validate-regression.sh` (74
      terminal-width baselines), `validate-message-expose.sh`,
      `validate-message-mask.sh`, `validate-message-discard.sh`,
      `validate-message-control-characters.sh` and `validate-message-grouping.sh`
      pass with their existing expectations untouched. *Assertable:* the full
      suite at the completion gate, with `git diff` showing no expectation file
      changed.
- [ ] **AC5. One cap, one per-run cut, read everywhere.** The literal `350`
      appears once in `ltl`, at the cap constant, and no `? 350 :` remains. The
      four key sites, the trigram guard and the CONFIG line read the one per-run
      value. *Assertable:* a source check (`grep -c`) recorded in the completion
      comment.
- [ ] **AC6. One consolidation cut remains, at the trigram boundary.** Exactly
      one cut of consolidation input remains, in `get_consolidation_trigrams`,
      reading the per-run cut; the inline re-cut, the two final-pass re-cuts, the
      canonical form's cut, the four pairwise cuts and the cliff-edge cut are
      gone. *Assertable:* a source check, with AC3 proving the removal changes
      nothing.
- [ ] **AC7. The grouping key is read from the entry.** No regex reads a
      bracketed prefix off a key anywhere in `ltl`, and the final pass takes each
      key's grouping key from its store entry. *Assertable:* a source check, plus
      AC3's identical per-group counters in `-V message-grouping` (a grouping key
      that differed would move a key to another group's counters). A source check
      over the format specs' level captures shows that none admits `]`, so the
      carried value equals today's parse on every format.
- [ ] **AC8. Every cut length is named, with its reason.** The cap, thread,
      object and both re-scan bucket lengths are file-scope constants, each with
      the reason of § 5.2 beside it; the thread, object and bucket values say "no
      reason on record". The display cuts in `print_message_summary` and
      `print_threadpool_summary` are unchanged. *Assertable:* a source check.
- [ ] **AC9. The unread counter is gone.** `$max_observed_message_length` and
      its per-key length measure no longer exist. *Assertable:* a source check.
- [ ] **AC10. The benchmark moves only where the locks say.** Before/after on
      the single-day access-log selection in the four cases of § 8, medians of
      three captures per side, each pair compared in `detailed` mode:
      `CONFIG max_log_message_length` steps from 200 to 350 on
      `top25-consolidate`, `heatmap-histogram-consolidate` and
      `heatmap-histogram-export`, and stays 200 on `standard`. Every other
      metric, memory included, stays within 1 %, the regression threshold of
      `docs/process/workflow.md` § 3 (b). A memory movement on the `-g` cases
      beyond it is not pre-accepted: the findings report gives it with its
      attribution (the carried grouping key, the removed unread key-to-group map)
      for the architect's disposition (D2). *Assertable:*
      `compare-results.sh detailed` on each before/after pair of TSVs.
- [ ] **AC11. The consolidation record describes the code.** The sections of
      § 10 state that a group is category plus grouping key (the level, or the
      status code on an access log), and that the grouping key is the batching
      key the code uses to order its work, not a barrier to consolidation; that
      similarity is scored on the whole key cut at the cap, level
      included, and that no part of the key is exempt from consolidation, so keys
      of different levels can consolidate (D1); that no observed-length counter
      exists; and they name no option `ltl` lacks. *Unassertable* by a harness,
      because this is prose; checked by reading it at review.
- [ ] **AC12. No runtime warnings.** Every run in the AC3 matrix and the new
      scenarios leaves no ` at <file> line <N>` on stderr. *Assertable:*
      `tests/lib/runtime-warnings.sh` in the new scenarios, and a grep over the
      matrix captures.
- [ ] **AC13. The CONFIG step is explained where benchmarks are compared.**
      `tests/baseline/README.md` carries a boundary note, in the shape of the
      note on the consolidating scenarios gaining `-m uuid`, saying that from
      this release `CONFIG max_log_message_length` reads 350 on
      `top25-consolidate`, `heatmap-histogram-consolidate` and
      `heatmap-histogram-export`, and that a 200 to 350 step labelled as a
      regression across that boundary is expected. It sits in the one
      boundary-notes section shared with #615's named CSV selection.
      *Unassertable* by a harness; checked by reading it at review.

---

## 7. Verification surface

**`-V` sections read:** `benchmark-data` (the value of one row changes),
`message-grouping` and `message-grouping / cluster-membership` (read, unchanged).

**Section contract (this document owns the row):** `benchmark-data` →
`CONFIG max_log_message_length <n>`. `<n>` is the length the run's message keys
are cut to, resolved once at option settlement: the message-key cap when `-o` or
`-g` is in effect after settlement, the terminal width otherwise. It is reported
whether or not the run retains messages; a `-n 0 -o` run reports the cap. The key
name is kept for benchmark-row continuity. Under `tests/HARNESS-DESIGN.md` §
Naming rules, the row is asserted by the harnesses that own the message key (AC1,
AC2), not by a harness named for `benchmark-data`.

**Harnesses whose assertions or goldens move:** none (AC4). Two harnesses gain
scenarios (AC1, AC2).

**Fixtures:** one new committed fixture, `tests/fixtures/message-key-long-request.txt`
(**proposed** name). It holds two access-log lines from documentation addresses:
one request line longer than 350 characters (a path of numbered segments) and one
short. The scenarios run with `-ni -bs 1440 -oe -n 3 --terminal-width 120`,
because the assertion reads only the CONFIG row and the MESSAGES CSV keys. The AC3
matrix uses corpus logs chosen from `docs/test-logs.md`: an application log
carrying thread and logger, an access log whose level is the HTTP status, and a
log whose lines carry a source-file object but no thread. For any key variant no
corpus format produces, and for the same-body ERROR and WARN pair, it uses a
synthetic `.txt` in the scratchpad.

**Run hygiene:** every capture goes to the scratchpad. Any file `ltl` writes into
the worktree during a check (the CSV outputs of `-o` runs) is deleted by the
agent that made it before it returns.

---

## 8. Measurement obligations

**Before/after benchmark: required.** The diff touches executable lines of `ltl`
inside the read loop and on a per-key path (`docs/process/workflow.md` § 3, scope
table, row 1). The `before` capture is taken on the tree this issue lands on,
after #616 has merged.

**Cases (D6):** the single-day access-log selection in four scenarios:
`standard` (the workflow's gate case: a retaining run without `-o` or `-g`,
where the key site cuts at the terminal width and the CONFIG line stays 200),
`top25-consolidate` and `heatmap-histogram-consolidate` (`-g`, where the grouping
key and the consolidation cuts run), and `heatmap-histogram-export` (the one `-o`
scenario). Each side is captured three times, every capture holding the four
cases: labels `619-before-1` to `619-before-3` on the landing tree, and
`619-after-1` to `619-after-3` on the head commit. `compare-results.sh detailed`
runs on each before/after pair. The findings report gives each metric's median
of the three with its range. All six TSVs are deleted at close-out.

**How the moved CONFIG line is accounted for:** `detailed` prints it as
`200 → 350, REGRESS +75.0%` on the three `-g` and `-o` cases. That is the expected
result of lock 7 and is stated in the findings report and the completion comment;
the tool's labelling stays as it is (D6). `summary` does not print CONFIG rows.
Committed TSVs are deliverables and are not edited. Every comparison that spans
the change (the 0.19.0 release comparison, and any development reference captured
before it) shows the same step. A boundary note in `tests/baseline/README.md`, in
the shape of the existing note on the consolidating scenarios gaining `-m uuid`,
says so, so that the step is not read as a regression.

**Expected effect:** hoisting the ternary saves the audit's measured cost of the
key-length expression (one numeric and one string compare, about 53 ns per
retained line) on every retaining run, well under 1 % of an access-log line. The
`-g` cases may also show `finalize/group_similar` falling, because the sort stops
running two regular expressions per comparison. Memory on the `-g` cases may move
with the carried grouping key and the removal of the unread map; the findings
report gives the measured figure and its attribution (D2).

**Prototype: none.** The architect ruled the carrier question not relevant (D2);
the change to the entry's shape is measured by the before/after benchmark.

---

## 9. Delivery

Each drop is a commit and a push on the issue branch. There is one PR, at the end.

| Drop | Content | What it proves |
|---|---|---|
| 1 | Named constants with their reasons (lock 3, D4, D5); the per-run cut resolved once and read by the key sites, the trigram guard and the CONFIG line (lock 1, lock 7); the dead branch and every redundant consolidation cut removed (D3); the unread counter removed (lock 6); the uncalled third copy of the bucket split removed (§ 3 item 16); the AC1 and AC2 scenarios and fixture; `docs/architecture-patterns.md` § Hot-loop discipline gains the key-site consumption and this issue's token on the status line (§ 5.7); the boundary note in `tests/baseline/README.md` (§ 8) | AC1, AC2, AC5, AC6, AC8, AC9, AC13; AC3 matrix identical; before/after on the four cases |
| 2 | The grouping key carried on the entry and read by the final pass and the sort (lock 2); the unread key-to-group map removed if the carried key makes it redundant (D2) | AC7; AC3 matrix identical again; before/after with the memory figure |
| 3 | Records: the consolidation record trued up (lock 4, D1); `features/150-final-pass-scalability.md` § Sort Order (§ 10) | AC11 |

**Merge gate:** `$version_number` restored to `0.19.0`; the full harness suite
(`CI=1 validate-csv-output.sh`, then `CI=1 validate-statistics.sh`, then the
rest) on the head commit; the before/after of § 8 on the head commit;
`validate-help-content.sh` passing (help and usage are unchanged).

---

## 10. Records to update at delivery

| Record | Change |
|---|---|
| `features/fuzzy-message-consolidation.md` | Trued up to the code (lock 4, D1). § Grouping Key Design: the group is category plus grouping key, the grouping key is the batching key the code uses to order its work and is not a barrier to consolidation, and keys of different levels can consolidate, as the final pass does when a lone key joins the next level's window; the sentence saying an ERROR message is never compared with a WARN message, and the "why not coarser grouping" paragraph's claim that level grouping prevents cross-level merges, are replaced. Also replaced: PF-09's 'The `[level]` prefix naturally prevents cross-level merges (see PF-07)'; PF-07's 'cross-level candidates that will never match'; IQ-01's implementation note 'ensures keys are only compared within the same level, so the prefix doesn't cause cross-level false matches', and the '(incorrect merge)' labels on the same-body WARN/ERROR examples under 'Reasoning — prefix domination'; IQ-02's resolved sub-question 'Per IQ-01, thread is an exact-match grouping field' (thread takes part in similarity and wildcarding). IQ-01 and IQ-02: the similarity input is the whole key cut at the cap, level included; no part of the key is exempt from consolidation; no observed-length counter exists; the options `--consolidate-full-key` and session-as-grouping-field under `--include-session` do not exist. DD-08 (similarity on the message body) points at PF-09 (similarity on the full key), which governs. PF-07 and lesson 7 (level prefixes separate levels naturally) state that they do not prevent consolidation across levels. DD-06 and lesson 35: the references to an adaptive cap "not yet implemented" point at #174's closure (its premise does not hold). |
| `docs/architecture-patterns.md` | § 5.7 |
| `tests/baseline/README.md` | the boundary note of § 8, in the one boundary-notes section shared with #615's named CSV selection (whichever lands second merges) |
| `tests/HARNESS-DESIGN.md` | none; the CONFIG row's contract lives in § 7 here |
| `features/150-final-pass-scalability.md` | § Sort Order states that the body follows the grouping key the entry carries (**proposed** wording, following the sort of § 5.1) |
| `features/342-redundant-logic-surfaces-audit-report.md` | § Review progress, stage 13 status set to *done* at close-out |
| `docs/usage.md`, `--help` | none |
| Release notes | **proposed: no bullet**, because the only moved value is a diagnostic row of `-V benchmark-data`; the decision is taken at close-out (`docs/process/workflow.md` § 4) |
| Issue #619 | a comment pointing at this document as the agreed specification, naming D1 to D6 by what they decide |
| Issue #564 (choose where a long message is truncated) | a comment carrying the hand-forward of § 5.8: without `-o` or `-g` the stored key is already cut to the terminal width, so a left or middle display cut cannot show the message's tail; how a run that chooses a left or middle cut keeps the tail is #564's to decide, and after this issue the stored key's length is one per-run value resolved at one site |
| Issue #616 (one gated derivation of means) | none from this issue; #616's delivery rewrites its note on cross-level consolidation as the design and cross-references § 5.4 |
| Native edge: this issue blocked by #616 (the message-store entry gains its counts first) | exists |
| Native edge: #620 (hoisting per-line option handling) blocked by this issue | exists |
