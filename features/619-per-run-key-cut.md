# One per-run message-key cut, named cut lengths, and the grouping key carried with the entry (Issue #619)

## Status

Specification agreed with the architect 2026-09-28 on branch
`619-per-run-key-cut` off `release/0.19.0`. Implementation started 2026-10-01:
drop 1 (the per-run cut, named cut lengths, redundant cuts and the inert re-scan
partition removed) is pushed (§ 11).

**Amended 2026-10-01 (§ 4.4).** The scope widens to the final pass grouping
strictly by category and grouping key (D10, § 5.9) and to correcting the master
specification for message consolidation, `features/fuzzy-message-consolidation.md`,
where it is out of date or inconsistent (D11, § 5.10). D1 is restated: the
message key is one contiguous string, and the grouping key separates messages
in both passes. The design of § 5.9 and the criteria AC15 and AC16 were agreed
by the architect on 2026-10-01. The carried grouping key is the line's level as
it is, the value the streaming checkpoints already group by, so both passes
group by the same value (§ 5.4, § 11.2).

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
see move is the `-V benchmark-data` CONFIG line on `-o` and `-g` runs. The
removal of the inert re-scan partition (D8, the partition removed as dead code)
is held to the same standard: the equivalence matrix proves it changes no output.

---

## 2. Requirement

The architect's terms, from the issue body, the review's stage rows and the
decisions of 2026-09-28, 2026-09-29 and 2026-10-01 (§ 4), arranged by topic:

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
- **The grouping key is a data-consistency contract in both passes.** A key is
  compared and grouped only with keys of its own category and grouping key, in
  the streaming checkpoints and the final pass; the final pass, which breaks
  the contract today, is fixed (D1 restated, D10).
- **The master specification is the reference.** The code is held to
  `features/fuzzy-message-consolidation.md`; where it is out of date or
  inconsistent it is corrected here (D11, § 5.10).
- **The unread counter of the observed maximum key length goes.**
- **The inert re-scan partition is removed as dead code.** Within a group every
  key shares its level, so the level pre-filter the partition was meant to be
  divides nothing. Its code, its constants, its callers' use of the
  buckets and its uncalled third copy go, and the removal is proven
  behaviour-neutral (D8).
- **Done when:** the benchmark data reports the cut the run used; the re-scan
  partition's code is gone; no row groups keys of two grouping keys, and every
  final-pass batch holds one grouping key; the MESSAGES CSV keys and
  consolidation output are byte-identical to today's on the fixtures and the
  equivalence matrix except where a final-pass batch held two levels, each such
  difference attributed; the before/after benchmark shows the moved CONFIG line
  on `-o` and `-g` runs and, on the `-g` cases, only movement attributed to the
  final-pass fix; the master specification describes the code.

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
| 8 | The bucket-key cut takes the first word to 30 characters, else the message to 20, and its comment says 20 | **Holds; the cut changes no key, and the split it makes is by level.** `extract_consolidation_bucket_key` receives the capped whole key, or a canonical form, not the message body. The first word of every key is its bracketed level, which every key of one group shares. So within one group the re-scan split is a single bucket. The 20-character branch cannot run, because every key starts with `[`, which is not whitespace. The 30-character cut acts only on a level longer than 29 characters. A probe on a scratch copy of `ltl` printed each final-pass window's buckets on five committed fixtures (two application logs carrying thread and logger, one holding a line at each of six levels and one holding INFO and WARN lines that carry control characters; and three access logs whose level is the HTTP status, two answering only 200 and one answering 200 and 500): a window holding keys of one level held one bucket; a window holding keys of two levels (item 9) held two. The partition that `docs/staged-processing-pipeline.md` credits with a 21 % speed-up (`[LEVEL][class]` in the prototype) does not divide a group in `ltl`. How this relates to the plain and highlighted split is § 5.5. The partition is removed as dead code (D8), consolidation across levels being the design. |
| 9 | (not in the issue) `features/fuzzy-message-consolidation.md` § Grouping Key Design says an ERROR message is never compared with a WARN message | **Corrected 2026-10-01: the record states the contract and the final pass breaks it; the final pass is fixed in this issue (D10, the final pass grouped strictly by category and grouping key).** The text first written here read the code as the design; that reading is withdrawn (§ 4.4). The measurement below stands. In the final pass of `group_similar_messages`, a window with fewer than two keys is not processed and is carried on, so a lone key of one level joins the window of the next level. Two application-log lines with the same thread, logger and body, one at ERROR and one at WARN, print under `-g` as one row with the level shown as `[*]` and 2 occurrences. The probe of item 8 found windows holding two levels on three of the five fixtures: both application logs (the six-level log and the INFO and WARN log) and the access log answering 200 and 500. Nothing in the key text is exempt from consolidation, the level included; the record is trued up to say so. |
| 10 | IQ-01 names `--consolidate-full-key`, and treats session as a grouping field under `--include-session` | **Neither option exists in `ltl`.** |
| 11 | The cap's reason is DD-06 | **DD-06 gives the reason for grouping only.** The value 350 came first from the CSV option: the commit that added MESSAGES CSV output used `$write_messages_to_csv == 1 ? 350 : $max_log_message_length`. The grouping change adopted it "same as CSV output". No record gives a reason for the CSV's 350; its reason is now that it shares the grouping cap, so `-o` and `-o -g` produce the same keys (D5). |
| 12 | The thread cut is 20 and the object cut is 25, with no reason on record | **Holds.** Both came in one commit ("Truncate message object and thread names in message stats") with no stated reason. The thread keeps its first 20 characters and the object keeps its last 25. `my $max_object_length = 25;` is re-declared for every retained message. They are recorded as having no reason on record (D5). |
| 13 | `docs/architecture-patterns.md` § Hot-loop discipline says #620 refines the key length recomputed per line | **The owner is this issue.** #620's body says "the key cut is #619". This issue corrects the status line by adding its own token and changing nothing else in it. |
| 14 | #174 was closed as not planned on 2026-09-28 | **Closed 2026-09-27** (20:46 UTC). The closing comment is in the architect's terms and points the unread counter to this issue. |
| 15 | The completion gate's benchmark case would show the moved CONFIG line | **It would not.** `docs/process/workflow.md` § 3 (b) names `single-day-access-log-standard`, which runs neither `-o` nor `-g`. `compare-results.sh summary` does not print CONFIG rows. `detailed` does print them, and it labels a 200 to 350 step as `REGRESS +75.0%`. The gate is widened to four cases (D6). |
| 16 | (not in the issue) The bucket-key split has one caller per path | **A third, dead copy exists.** `partition_consolidation_keys` builds the same buckets as the loops in `run_consolidation_pass` and `process_final_pass_window`, and nothing calls it. It is removed with the partition (D8, the partition removed as dead code). |

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
   with its reason").* **Scope:** by D8 (the re-scan partition removed as dead
   code), this lock covers only the cuts that remain: the cap, the thread and
   object cuts, and the display cut owned by #564 (choose where a long message
   is truncated in the messages table). The bucket-key cuts are removed with the
   partition rather than named.
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
  **Restated by the architect on 2026-10-01 (§ 4.4):** what holds is that the
  message key is one contiguous string with no part exempt from similarity
  scoring and wildcarding. The rest of this entry (an ERROR and a WARN line
  with the same body consolidating into one row; the grouping key not being a
  barrier; no bug; byte-identical consolidation output; the record trued up to
  cross-level consolidation) is withdrawn.
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
  Superseded by D8 (the re-scan partition removed as dead code, locked
  2026-09-29) for the 30 and 20 constants, which are removed with the partition
  rather than named. The architect's reading was that the inert partition is the
  split between plain and highlighted messages, active when highlighted messages
  are many and inert when no highlight is active; § 5.5 records what the code
  does beside that reading.
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

### 4.3 Locked by the architect on 2026-09-29

In reply to being told that the split between plain and highlighted messages he
described exists and behaves as he said, but that the inert partition this
specification found is a different one: the re-scan bucket inside a group, split
by the key's first word (the bracketed level), inert whether or not a highlight
is active.

- **D7. The inert re-scan partition is dealt with in this issue, not skipped.**
  Locked by the architect 2026-09-29. His words: "This was meant as a pre-filter
  if I recall correctly, to quickly eliminate candidate messages which were not
  alike, using the log level to do so, reducing the potential number of keys
  that we needed to look at. Over time we tried SO many things to get that
  functionality working performantly that I don't know if that was something
  that ended up sticking or not. If you say that it is inert, this sounds like
  either a defect or a leftover which was not cleaned up which needs to be
  validated against the message consolidation specification. We shouldn't just
  see this here and skip it." The partition is neither left as it is nor filed
  away as a separate issue. **Resolution:** D8 (the partition removed as dead
  code), locked the same day. The tension a validation would have had to state
  was put to the architect first: a level pre-filter that works would stop an
  ERROR line and a WARN line with the same body from consolidating, which D1
  (consolidation across log levels is the design) locks as intended. He ruled on
  it directly, so no finding is brought to him and no validation stage runs.

In reply to being told that the validation of the inert re-scan partition would
have to state that tension:

- **D8. The inert re-scan partition is dead code and is removed from the
  application in this issue.** Locked by the architect 2026-09-29. His words:
  "yes, I'm aware of this. as this is a locked decision, then the dead code
  should be removed from the application." Consolidation across log levels is
  the design (D1), so the level pre-filter the partition was meant to be is
  superseded by that design. The re-scan bucket goes: the sub that cuts the
  key's first word (`extract_consolidation_bucket_key`), its 30 and 20
  constants, the bucket building and bucket lookup in its two callers
  (`run_consolidation_pass` for the streaming checkpoints and
  `process_final_pass_window` for the final pass), and the uncalled third copy
  of the split (`partition_consolidation_keys`, § 3 item 16). This resolves D7
  (the partition validated rather than skipped): no finding is brought to the
  architect and no validation stage runs. It supersedes D4 (the re-scan
  partition's constants named with what the code does) for the 30 and 20
  constants, which are removed rather than named. What remains of the stage is
  the proof that the removal is behaviour-neutral: consolidation output and the
  MESSAGES CSV byte-identical on the equivalence matrix (AC3, AC14), and the
  final-pass time measured before and after (§ 8). The consolidation record is
  trued up so that no entry claims a level pre-filter or a re-scan bucket
  speed-up, stating that cross-level consolidation is the design and that the
  pre-filter was removed as dead code under this issue (§ 10).
  *The words "stating that cross-level consolidation is the design" are
  withdrawn by the restatement of D1 (§ 4.4); the removal itself stands.*

### 4.4 Locked by the architect on 2026-10-01

Given after the drop 1 equivalence matrix (§ 11.3) found final-pass batches
holding two levels, and after the consolidation record
(`features/fuzzy-message-consolidation.md`, the master specification for
message consolidation) was set beside this specification.

- **D1 restated: the message key is one contiguous string, and category plus
  grouping key separate messages for every message in both passes.** The
  architect's words: "The message itself is to be treated as a contiguous
  string", and "The grouping key concept … is a data consistency contract
  which should hold for all messages being grouped." No part of the key text
  is exempt from similarity scoring or wildcarding (thread and object
  included). A message is compared and grouped only with messages of its own
  category (plain or highlighted) and grouping key (the log level, or the HTTP
  status on an access log), in the streaming checkpoints and in the final pass
  alike, as `features/fuzzy-message-consolidation.md` § Grouping Key Design
  states. An ERROR line and a WARN line never consolidate into one row.
- **D9 withdrawn (the counter movement on a final-pass batch spanning two
  levels).** Its case is the defect D10 fixes; once no batch holds two levels,
  the removal of the re-scan partition (D8) is expected to change nothing, and
  the equivalence matrix proves it on the fixed code.
- **D10. The final pass grouping across grouping keys is a defect, fixed in
  this issue.** The final pass sorts keys by body with the grouping key
  stripped, so keys of different levels interleave; a batch is cut at each
  change of grouping key, and a batch holding one key is carried into the next
  grouping key's batch and compared there (§ 11.7 measures how often). Every
  key the final pass handles is compared and grouped only within its own
  category and grouping key; a lone key is handled expressly so that it never
  groups across grouping keys. Consolidation output changes wherever a final
  pass batch held two levels.
- **D11. The master specification is the reference, and this issue corrects
  it where it is out of date or inconsistent.** The architect's words: "Your
  focus should be on that master specification and ensuring that 619 has as a
  goal to fix the code to fit the spec, or if there are issues within the spec
  … to raise them." Corrected in this issue (§ 5.10): § Process Flow (the final
  pass described as running through the streaming pipeline), § Grouping Key
  Design (the contract stated for both passes), PF-09 (similarity on the full
  message key, which credits the level prefix with what the grouping key
  does), IQ-01 (category model: metadata as an exact-match grouping key, the
  message body alone scored) and DD-08 (similarity on the message body), the
  final-pass redesign record's § Sort Order (sorting "regardless of status
  code"), and `docs/similarity-engine-best-practices.md` § Separate Similarity
  Scope from Storage Scope (the same body-only model). #616's record entries (one gated derivation of means)
  that state cross-level consolidation as the design (its D26 and finding 15)
  are marked superseded.
- **D12. The consolidation prototype is brought into line with the master
  specification in this issue.** The architect's words: "the prototype will
  need to be fixed so that this sort of poisoning doesn't occur again." Every
  departure of `prototype/96-fuzzy-consolidation.pl` from the master
  specification is removed (§ 5.10); its engine is rebuilt from `ltl`'s after
  the final-pass fix (drop 3), so the fix is not ported twice.

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
| `extract_consolidation_bucket_key` :: `return substr($1, 0, 30);` and `return substr($msg, 0, 20);` | the re-scan bucket: the key's first word cut to 30 characters, else its first 20; the comment says 20 | **removed**, with its 30 and 20 (D8, § 5.5) |
| `run_consolidation_pass`, `process_final_pass_window` :: `my $bk = extract_consolidation_bucket_key(...)` and `my $pattern_bk = extract_consolidation_bucket_key(...)` | build buckets by first word; a new pattern re-scans only the bucket of its canonical form's first word | **removed**: a new pattern re-scans every unconsumed key of its group, or of its final-pass window (D8). **Proposed** form: one list of surviving keys replaces the bucket map; within a group it is the single bucket the code builds today |
| `partition_consolidation_keys` | defined, never called (§ 3 item 16) | **removed** (D8) |
| `read_and_process_logs` :: `my $msg_len = length($log_key);` and `(GLOBALS)` :: `my $max_observed_message_length      = 0;` | written, never read | removed (lock 6) |
| `read_and_process_logs` :: `my $grouping_key = $log_level // "";` | the inline path's grouping key | also written onto the store entry under `-g` (lock 2) |
| `group_similar_messages` :: `my ($grouping_key) = $log_key =~ /^\[([^\]]+)\]/;` (three sites), `my ($gk) = $log_key =~ /^\[([^\]]+)\]/;` | parsed back | read from the entry (lock 2) |
| `group_similar_messages` :: `my ($msg_a) = $a =~ /^\[[^\]]+\]\s*(.*)/s;` | strip by regex, twice per comparison | **proposed**: the body is the key after `"[$gk]"` with leading whitespace stripped, computed once per key before the sort; the whole key is used when the grouping key is empty, as today. The order is identical to today's whenever the level holds no `]`. |
| `(GLOBALS)` :: `my %consolidation_key_message_cat_gk;` | written and deleted, never read (§ 3 item 7) | finding recorded beside the carried key; the implementation removes it if the carried key makes it redundant (D2) |
| `print_message_summary` :: `my $message = substr( $key, 0, $col_width{1} );` (and in `print_threadpool_summary`) | display cut | **untouched** (lock 3; #564 owns it) |

### 5.2 Named constants

The reasons are settled (lock 3, D5). The names and the form are **proposed**:
every fixed length becomes a `use constant` at file scope in the consolidation
configuration block, beside the cap. `ltl` already has twelve `use constant`
blocks. A constant folds at compile time, so the key sites pay nothing for the
name. The per-run cut stays a scalar, because it is a value resolved for the
run.

| Constant (proposed name) | Value | Reason written beside it |
|---|---|---|
| `MESSAGE_KEY_CAP` | 350 | Grouping: DD-06, so that a UUID or other variable tail near the end of a long message is never cut part-way. CSV: it shares the grouping cap, so that `-o` and `-o -g` produce the same keys. |
| `MESSAGE_KEY_THREAD_LENGTH` | 20 (first characters) | No reason on record. |
| `MESSAGE_KEY_OBJECT_LENGTH` | 25 (last characters) | No reason on record. |

`$consolidation_message_length_cap` is replaced by the cap constant, because the
CSV reads the same value (**proposed** name above).

The re-scan bucket's 30 and 20 are not named: they are removed with the
partition (D8, superseding D4 for them).

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

### 5.4 What the grouping key is: the contract for both passes (D1 restated, D10)

Consolidation works in groups. A group is a category (plain or highlighted, § 5.5)
plus a grouping key (the log level, or the HTTP status on an access log). Each
group has its own patterns, clusters, unmatched keys and stage counters. The
grouping key is a data-consistency contract: a key is compared and grouped only
with keys of its own group, in the streaming checkpoints and in the final pass
(`features/fuzzy-message-consolidation.md` § Grouping Key Design). Within a
group, similarity is scored on the whole key as one contiguous string, and no
part of the key text is exempt from wildcarding.

The streaming checkpoints keep the contract: every structure they read is held
per group. The final pass breaks it today (D10): it sorts each category's keys
by body with the grouping key stripped, so keys of different levels interleave;
it cuts a batch when the grouping key changes, and a batch of one key is carried
into the next grouping key's batch, where it is compared and can consolidate
with keys of another level, the row showing the level as a wildcard. § 5.9 fixes
it.

The carried grouping key (§ 5.3) is the level itself, the value the inline path
already uses. Today's parse returns the text between the leading `[` and the
first `]`, or the empty string when the brackets are empty; the two are equal
for every level that holds no `]`. Five format specs admit `]` in their level
capture and no corpus line carries one (§ 11.2).

### 5.5 The two splits on the consolidation path (D8)

The architect's reading was that the inert partition is the split between plain
and highlighted messages. The code has two splits on this path, and the one this
issue removes is not that one. The table states what each does in the code this
specification was written against.

| Split | What it divides | When it acts |
|---|---|---|
| **Category: plain or highlighted.** A line is highlighted when a highlight option selects it. The category is the outer part of every group, and the final pass walks each category separately. | Plain keys from highlighted keys: they are never compared. | Active whenever a highlight option selects lines, so that a long list of highlighted messages consolidates among itself. With no highlight active, every key is plain and the split has one side. This matches the architect's description. It uses no cut length and this issue does not touch it. |
| **Re-scan bucket (`extract_consolidation_bucket_key`).** Inside one group, after a new pattern is found, only the keys whose bucket matches the pattern's bucket are re-scanned against it. The bucket is the key's first word cut to 30 characters, else its first 20 characters. | Keys by their first word, which is the bracketed level. | Inert within a group whether or not highlighting is active, because every key of a group shares its level. It separates keys only in a final-pass window that holds keys of two levels (§ 5.4). The 20-character branch never runs. |

The category split stays as it is; this issue does not touch it. The re-scan
bucket is removed as dead code (D8): within a group every key shares its
level, so the level pre-filter it was meant to be divides nothing. The
bucket-key sub, its 30 and 20, the bucket building and bucket lookup in
`run_consolidation_pass` and `process_final_pass_window`, and the uncalled
`partition_consolidation_keys` go. A new pattern then re-scans every unconsumed
key of its group, or of its final-pass window.

**The proof that the removal is behaviour-neutral** runs in drop 1 (§ 9):

- **Output.** The MESSAGES CSV, the rendered messages table and
  `-V message-grouping` with `/ cluster-membership` are byte-identical between
  the base commit and the drop on the equivalence matrix (AC3).
- **Time.** The final-pass and streaming-checkpoint times on the `-g` cases of
  § 8 are measured before and after, medians of three with ranges (AC14).
- **Where the proof is hardest.** Within a group every key shares its level, so
  the bucket is the whole group and its removal drops only the per-key bucket
  computation. The bucket separates keys only in a final-pass window holding
  keys of two levels (§ 5.4). There, a pattern whose canonical form keeps the
  level re-scans only that level's keys today; after the removal its regex is
  also tried on the other level's keys, which its literal level cannot match. A
  pattern formed across the two levels has its level wildcarded (`[*]`), a first
  word that no bucket carries, so today it re-scans nothing; after the removal
  it re-scans the window. The matrix therefore holds, besides the same-body
  ERROR and WARN pair, a two-level window in which a pattern forms across the
  levels while further keys of both levels that its regex matches remain. If the
  proof finds output or a `-V message-grouping` counter moved there, or the
  final-pass time rising beyond 1 %, the measured difference is brought to the
  architect before the drop is pushed; this specification does not accept it.
  *Outcome (§ 11.3):* the output was identical and four counters moved in that
  window. The window itself is the defect D10 fixes; with the final pass
  grouped strictly by grouping key, no window holds two levels, and the
  removal's proof is re-run on the fixed code (AC14).

### 5.6 User surfaces

| Surface | Change |
|---|---|
| Options, `--help`, `docs/usage.md` | none. No option changes, and no row states a key length. |
| Notices | none |
| Rendered output (bar graph, messages table, summary) | none, except under `-g` where a final-pass batch held two levels: no row merges two levels (D10) |
| MESSAGES CSV, STATS CSV | none, except the MESSAGES rows under `-g` as above |
| `-V benchmark-data` | `CONFIG max_log_message_length` reads the per-run cut: the cap on `-o` or `-g` runs, the terminal width otherwise. The key name is unchanged. |
| `-V message-grouping` (and `/ cluster-membership`) | the final-pass counters and memberships move where a batch held two levels (D10); no cluster holds members of two grouping keys |

Every "none" above holds with the re-scan partition removed (D8); AC3 and AC14
prove it. The exceptions come only from the final-pass fix (D10); AC3 attributes
each one.

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
  is blocked by it (Status). #616's record states the final pass carrying a lone
  key across levels as the design (its D26 and finding 15); this issue marks
  both superseded (D1 restated, D10).
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

### 5.9 The final pass grouped strictly by grouping key (D10)

**Agreed by the architect on 2026-10-01**, with AC15 and AC16. Pass 1 of the final
pass in `group_similar_messages` sorts each category's keys by grouping key
first and body second, the grouping key read from the entry (§ 5.3) and the
body being the key after `"[$gk]"` with leading whitespace stripped. Each
grouping key's keys are then contiguous, in the same body order they have
today among themselves. A batch is cut when the grouping key changes, as
today, and is then cleared whatever its size: a batch of one key is not
carried into the next grouping key's batch. That key stays in the message
store as an unconsolidated row; it has already been tested against its own
group's patterns (S3) before it entered the batch, and Pass 2's sweep tests it
again against any pattern its group gains later. Pass 2 is unchanged: it
already tests each key against its own group's patterns only.

What changes in output, and only where a final-pass batch held two levels
(§ 11.7):

- no row consolidates keys of two grouping keys, and no row shows a wildcarded
  level;
- a group whose keys were split into several batches by keys of other levels
  interleaving in body order now meets them in one batch (up to the batch
  capacity of 1,000), so pairs that were never in one batch can now be found.

The streaming checkpoints do not change.

### 5.10 Master specification corrections (D11)

`features/fuzzy-message-consolidation.md` is the reference for message
consolidation. Where it is out of date or contradicts itself it is corrected
here, and the code is held to it.

| Where | Today it says | Corrected to |
|---|---|---|
| § Process Flow, the parsing-loop diagram, and Outstanding Decision 6 (final pass redesigned to reuse the streaming pipeline) | the final pass sends every remaining key "through the same `consolidation_process_key()` pipeline" | the final pass as built by the final-pass redesign (`features/150-final-pass-scalability.md`): Pass 1 over each group's keys in body order in batches of up to 1,000 with the S3 match and ceiling ahead of discovery, Pass 2 the S3 sweep; the same discovery, matching and merging functions as the streaming checkpoints |
| § Grouping Key Design | the group is category plus level and an ERROR message is never compared against a WARN message (holds), with the reason that short messages would wrongly merge across levels (holds) | unchanged in substance; states that the contract holds for every key in both passes and that a lone key never crosses into another group |
| PF-09 (similarity on the full message key) | "The `[level]` prefix naturally prevents cross-level merges" | the whole key is scored as one contiguous string; cross-level merges are prevented by the grouping key, not by the prefix, which on short messages does not prevent them (§ Grouping Key Design's reason) **Done 2026-10-01**, on `release/0.19.0` (`1e0694a`). |
| IQ-01 (category model, resolved) and its implementation note | metadata fields are an exact-match grouping key; only the message body is scored; the options `--consolidate-full-key` and session-as-grouping-field under `--include-session` | the grouping key is category plus level; level, thread and object are part of the scored string; neither option exists **Done 2026-10-01**, on `release/0.19.0` (`1e0694a`). |
| IQ-02 (key construction and message capping, resolved) | the engine receives the message body; the adaptive cap and `$max_observed_message_length` | the engine receives the whole key cut at the per-run cut; the adaptive cap was closed as not planned (its premise does not hold) and the counter is removed **Done 2026-10-01**, on `release/0.19.0` (`5c99cea`). |
| DD-08 (similarity on the message body) | the metadata prefix is not part of the comparison | superseded by PF-09 as corrected **Done 2026-10-01**, on `release/0.19.0` (`5c99cea`). |
| PF-07 (level partitioning deferred) | consolidation operates on the whole plain pool and the prefix keeps levels apart | historical: the grouping key partitions by level, and no re-scan bucket exists (D8) |
| PF-16 and PF-17 (the re-scan partition by level plus class) and the Process Flow's "in same partition bucket" | a re-scan bucket by level | removed as dead code under this issue (D8): within a group every key shares its level |
| `features/150-final-pass-scalability.md` § Sort Order | sort by body with the grouping key stripped, "regardless of status code" | sort by grouping key, then body (§ 5.9) |
| `docs/similarity-engine-best-practices.md` § Separate Similarity Scope from Storage Scope | score the message body only; metadata fields as exact-match grouping keys | score the whole key; the grouping key (level) separates groups, for the short-message reason **Done 2026-10-01**, on `release/0.19.0` (`5c99cea`). |
| `features/616-gated-mean-derivation.md` D26 and finding 15 | the final pass carrying a lone key into the next level's batch is the design | superseded by D1 as restated and D10 |
| `prototype/96-fuzzy-consolidation.pl` (the consolidation prototype) | groups an access log by status family (`2xx`) while its keys carry the exact status; re-scans within a bucket of level plus object class (PF-16); scores UUID-normalised trigrams; searches candidates with the 50 rarest trigrams and a 30 % pre-filter; caps patterns at 50 with no eviction; runs its final pass on ceiling-excluded keys only, at its own 80 % threshold (PF-12) | the engine of the master specification as `ltl` implements it after drop 3 (D12): exact-status grouping key; no re-scan bucket; scoring as written (the decision that consolidation does not replace UUIDs); the candidate search that finds every partner; adaptive eviction with no pattern cap; the final pass over every remaining key, grouped strictly by grouping key, scoring at the `-g` similarity |

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
      characters, one between the width and 350, `-g -m uuid`, the pair of
      same-body ERROR and WARN lines, and the two-level window of § 5.5, in
      which a pattern forms across the levels while further matching keys of
      both levels remain (D8). Between the base commit and drops 1 and 2, the
      MESSAGES CSV, the rendered messages table and `-V message-grouping` with
      `/ cluster-membership` are identical, except on the two-level window,
      where drop 1 moved four final-pass counters (§ 11.3). For the final-pass
      fix (D10) the matrix compares drop 2 against the fix, and every
      difference is attributed to a final-pass batch that held two levels
      (§ 5.9). *Assertable:* a
      one-off before/after diff over the matrix, the method the audit's hoist
      probe used to prove itself behaviour-neutral
      (`features/342-redundant-logic-surfaces-audit-report.md` § Item 8, Part 2:
      forty identical before/after comparisons before any timing run); the count
      of identical comparisons is recorded in this document.
- [ ] **AC4. No assertion or golden changes, except through the final-pass
      fix.** A saved output or expectation may change only where a final-pass
      batch held two levels (D10, § 5.9); each re-capture states which rows
      changed and why. `validate-regression.sh` (74
      terminal-width baselines), `validate-message-expose.sh`,
      `validate-message-mask.sh`, `validate-message-discard.sh`,
      `validate-message-control-characters.sh` and `validate-message-grouping.sh`
      pass with their existing expectations untouched. *Assertable:* the full suite at the completion gate, with `git diff`
      showing no expectation file changed.
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
- [ ] **AC8. Every remaining cut length is named, with its reason.** The cap,
      thread and object lengths are file-scope constants, each with the reason of
      § 5.2 beside it; the thread and object values say "no reason on record".
      The re-scan bucket lengths are gone with the partition (AC14). The display
      cuts in `print_message_summary` and `print_threadpool_summary` are
      unchanged. *Assertable:* a source check.
- [ ] **AC9. The unread counter is gone.** `$max_observed_message_length` and
      its per-key length measure no longer exist. *Assertable:* a source check.
- [ ] **AC10. The benchmark moves only where the locks say.** Before/after on
      the single-day access-log selection in the four cases of § 8, medians of
      three captures per side, each pair compared in `detailed` mode:
      `CONFIG max_log_message_length` steps from 200 to 350 on
      `top25-consolidate`,
      `heatmap-histogram-consolidate` and `heatmap-histogram-export`, and stays
      200 on `standard`. Every other metric, memory included, stays within 1 %,
      the regression threshold of `docs/process/workflow.md` § 3 (b). A memory
      movement on the `-g` cases beyond it is not pre-accepted: the findings
      report gives it with its attribution (the carried grouping key, the
      removed unread key-to-group map) for the architect's disposition (D2).
      *Assertable:* `compare-results.sh detailed` on each before/after pair of
      TSVs.
- [ ] **AC11. The master specification and the records it points to describe
      the code, and agree with each other.** Every row of § 5.10 reads as its
      "corrected to" column: the grouping key separates groups in both passes;
      the whole key is scored as one contiguous string; the final pass is
      described as built; no level pre-filter or re-scan bucket is claimed; no
      option `ltl` lacks is named; #616's record marks its cross-level entries
      superseded. *Unassertable* by a harness, because this is prose; checked by
      reading it at review.
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
- [ ] **AC14. The re-scan partition is gone and its removal changes nothing.**
      `extract_consolidation_bucket_key`, `partition_consolidation_keys`, the
      bucket lengths 30 and 20, and the bucket maps in `run_consolidation_pass`
      and `process_final_pass_window` no longer exist (D8). The equivalence
      matrix of AC3, the two-level window of § 5.5 included, is identical, and
      the final-pass time on the `-g` cases of § 8 does not rise beyond the 1 %
      threshold, medians of three with ranges. *Assertable:* a source check,
      AC3's diff, and `compare-results.sh detailed` on each before/after pair.
- [ ] **AC15. No row groups keys of two grouping keys (D10).** Under `-g`, the
      same-body ERROR and WARN pair prints two rows, one per level, and no row
      shows a wildcarded level; on the two-level window the ERROR key is its
      own row and the WARN keys group among themselves. *Assertable:* two
      scenarios in `validate-message-grouping.sh` on committed fixtures, reading
      `-V message-grouping / cluster-membership`: every cluster's members carry
      one grouping key.
- [ ] **AC16. Every final-pass batch holds one grouping key (D10).** On the
      AC3 matrix inputs and the corpus logs of § 11.7, an instrumented copy of
      the fixed code finds no batch holding two grouping keys, where the base
      found them on all five corpus logs. *Assertable* as a one-off probe,
      recorded here; the harness assertion is AC15.
- [ ] **AC17. The consolidation prototype follows the master specification
      (D12).** Every departure in § 5.10's prototype row is gone; on the AC15
      fixtures and the corpus logs of § 11.7 the prototype groups exactly the
      keys `ltl -g` groups. *Assertable* as a one-off comparison of cluster
      memberships, recorded here.

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
corpus format produces, for the same-body ERROR and WARN pair, and for the
two-level window of § 5.5, it uses a synthetic `.txt` in the scratchpad.

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

**The removal of the re-scan partition (D8):** measured on the same before/after
captures, with no separate probe. The removal drops one bucket computation per
key per pass and one per new pattern. In a final-pass window of two levels, a
pattern formed across the levels re-scans the window, where today it re-scans
nothing (§ 5.5), so the final-pass time is measured, not assumed: the findings
report gives `finalize/group_similar` on the `-g` cases with medians of three and
ranges, and a rise beyond 1 % is brought to the architect (AC14).

**Prototype: none.** The architect ruled the carrier question not relevant (D2);
the change to the entry's shape is measured by the before/after benchmark.

---

## 9. Delivery

Each drop is a commit and a push on the issue branch. There is one PR, at the end.

| Drop | Content | What it proves |
|---|---|---|
| 1 | Named constants with their reasons (lock 3, D5); the per-run cut resolved once and read by the key sites, the trigram guard and the CONFIG line (lock 1, lock 7); the dead branch and every redundant consolidation cut removed (D3); the unread counter removed (lock 6); the inert re-scan partition removed: the bucket-key sub, its 30 and 20, its two callers' bucket building and lookup, and the uncalled third copy (D8, § 5.5); the AC1 and AC2 scenarios and fixture; `docs/architecture-patterns.md` § Hot-loop discipline gains the key-site consumption and this issue's token on the status line (§ 5.7); the boundary note in `tests/baseline/README.md` (§ 8) | AC1, AC2, AC5, AC6, AC8, AC9, AC13, AC14; AC3 matrix identical, the two-level window of § 5.5 included; before/after on the four cases |
| 2 | The grouping key carried on the entry and read by the final pass and the sort (lock 2); the unread key-to-group map removed if the carried key makes it redundant (D2) | AC7; AC3 matrix identical to drop 1 |
| 3 | The final pass grouped strictly by grouping key (D10, § 5.9); the AC15 scenarios and fixtures; saved outputs re-captured where a final-pass batch held two levels, each with its attribution (AC4) | AC15, AC16; AC3 matrix against drop 2 with every difference attributed; AC14 re-proved (no batch holds two levels, so the removed partition could divide nothing); before/after on the four cases |
| 4 | Records: the master specification and the records it points to corrected (D11, § 5.10); `docs/staged-processing-pipeline.md` and `docs/fuzzy-consolidation-lessons-learned.md` (§ 10). PF-09, IQ-01, IQ-02, DD-08 and the best-practices section are already done on the release branch | AC11 |
| 5 | The consolidation prototype's engine rebuilt from `ltl`'s (D12) | AC17 |

Drops 1 and 2 prove byte-identity (AC3). Drop 1's proof included the two-level
window of § 5.5, where the removal of the re-scan partition was tested hardest
(D8); the difference found there (§ 11.3) led to D10. Drop 3 changes output by
design, only where a final-pass batch held two levels.

**Merge gate:** `$version_number` restored to `0.19.0`; the full harness suite
(`CI=1 validate-csv-output.sh`, then `CI=1 validate-statistics.sh`, then the
rest) on the head commit; the before/after of § 8 on the head commit;
`validate-help-content.sh` passing (help and usage are unchanged).

---

## 10. Records to update at delivery

| Record | Change |
|---|---|
| `features/fuzzy-message-consolidation.md` | Corrected per § 5.10 (D11): § Process Flow and Outstanding Decision 6 describe the final pass as built; § Grouping Key Design states the contract for both passes; PF-09, IQ-01, IQ-02, DD-08, PF-07, PF-16 and PF-17 as § 5.10 sets out; DD-06 and lesson 35 point at the closure of the adaptive cap (its premise does not hold). |
| `docs/staged-processing-pipeline.md` | § Partitioning Composes with Interleaving: the 21 % speed-up was measured on the prototype's level-plus-class key; in `ltl` every key of a group shares its level, so the partition never divided a group and was removed as dead code under this issue (D8) |
| `docs/fuzzy-consolidation-lessons-learned.md` | the "What replaced it" line names interleaved discovery and re-scan without key partitioning (D8) |
| `docs/architecture-patterns.md` | § 5.7 |
| `tests/baseline/README.md` | the boundary note of § 8, in the one boundary-notes section shared with #615's named CSV selection (whichever lands second merges) |
| `tests/HARNESS-DESIGN.md` | none; the CONFIG row's contract lives in § 7 here |
| `features/150-final-pass-scalability.md` | § Sort Order: keys sorted by grouping key, then body, the grouping key read from the entry, and a lone key never carried into another group's batch (D10, § 5.9); the growth list in the problem statement names no bucket partitioning (D8) |
| `docs/similarity-engine-best-practices.md` | § Separate Similarity Scope from Storage Scope: the whole key is scored as one contiguous string, and the grouping key (level) separates groups, for the short-message reason (D11) |
| `features/616-gated-mean-derivation.md` | D26 (the final pass carrying a lone key across levels is the design) and finding 15 marked superseded by D1 as restated and D10 of this issue |
| `features/342-redundant-logic-surfaces-audit-report.md` | § Review progress, stage 13 status set to *done* at close-out |
| `docs/usage.md`, `--help` | none |
| Release notes | a Bug Fixes bullet: grouping with `-g` no longer merges messages of different log levels in its final pass; the decision is taken at close-out (`docs/process/workflow.md` § 4) |
| Issue #619 | a comment pointing at this document as the agreed specification, naming D1 to D8 by what they decide |
| Issue #564 (choose where a long message is truncated) | a comment carrying the hand-forward of § 5.8: without `-o` or `-g` the stored key is already cut to the terminal width, so a left or middle display cut cannot show the message's tail; how a run that chooses a left or middle cut keeps the tail is #564's to decide, and after this issue the stored key's length is one per-run value resolved at one site |
| Issue #616 (one gated derivation of means) | a comment: its D26 and finding 15 (cross-level consolidation as the design) are superseded by this issue's D1 as restated and D10, and its record is marked so |
| Native edge: this issue blocked by #616 (the message-store entry gains its counts first) | exists |
| Native edge: #620 (hoisting per-line option handling) blocked by this issue | exists |

---

## 11. Implementation findings

### 11.1 Start of implementation (2026-10-01)

The issue branch was fast-forwarded to the release tip `af91a69` (#616 and the
v0.18.5 fixes merged). The `before` captures of § 8 were taken on `af91a69`,
labels `619-before-1` to `619-before-3`, each holding the four cases. Captures 1
and 2 were retaken whole, because a read-only scan of the corpus ran beside them
and could have disturbed their timings; capture 3 ran alone.

### 11.2 Level captures that admit `]` (§ 5.4, AC7)

§ 5.4 expected every format spec's level capture to exclude `]`. Five do not:
`connection_server_standard` and `integration_runtime_standard` (`([^ ]*)`),
`connection_server_json` (`([^"]*)`), `tw_analytics_v2` and `tw_edge_c_sdk`
(`([^ ]+)`). A level holding `]` would make today's parse (the text up to the
first `]`) differ from the carried level. A scan of every uncompressed file in
the corpus (19 GB) for a level token holding `]` in any of the five line shapes
found none. The inline streaming path already groups by the whole level
(`$cat_gk = "$category|$grouping_key"` with `$grouping_key = $log_level`), so
today such a key would be grouped under one value while streaming and another in
the final pass.

### 11.3 Drop 1 equivalence matrix (AC3, AC14)

The base `ltl` (`af91a69`) against drop 1, 165 comparisons: eleven inputs, five
option shapes (`-n 20`; `-o`; `-g`; `-o -g`; `-g -m uuid`) and terminal widths
80, 120 and 200. Inputs: one synthetic file per key variant (level only; level
and thread; level and object; level, thread and object), each holding messages
longer than 350 characters, between 200 and 350, and short, at two levels; the
same-body ERROR and WARN pair; the two-level window of § 5.5; and five corpus
logs (a ThingWorx application log, an Edge C SDK log, a Tomcat access log, an
Apache access log with long request paths, a Windchill method-server log). Each
comparison covers the exit code, the rendered output with `-V message-grouping`
(cluster membership included), the MESSAGES CSV and stderr. The run summary's
time and memory lines are excluded, and so is the bar glyph run (its counts are
kept): with two levels at equal counts, the split of a bar between them varies
from run to run on the base alone (six runs of the base, two renderings).

- **156 identical**, no runtime warning, every run exiting 0.
- **9 differ, all on the two-level window under `-g`** (every width, with `-o`
  and with `-m uuid`). The MESSAGES CSV, the rendered table and the cluster
  membership are identical (one cluster `[*] … Batch 100* …`, six members, one
  ERROR and five WARN). Four `-V message-grouping` counters of the WARN group's
  final pass move:

  | Counter | base | drop 1 |
  |---|---|---|
  | S4 Pairwise discovery | 6 | 2 |
  | S4 Re-scan absorbed | 0 | 4 |
  | New patterns created | 3 | 1 |
  | find_candidates calls | 4 | 2 |

  Mechanism, as § 5.5 predicted: the pattern formed across the two levels has its
  level wildcarded, a first word no re-scan bucket carries. Today it re-scans
  nothing, so the remaining WARN keys go through pairwise discovery, which
  creates two more patterns; every key still ends in the one cluster (the
  cross-cluster merge count is 0 on both sides). With the partition removed, the
  pattern re-scans the window and absorbs the four WARN keys at once. No corpus
  input moved a counter.

### 11.4 Locked by the architect on 2026-10-01

- **D9. The counter movement on a window spanning two levels is accepted.**
  *Withdrawn by the architect on 2026-10-01 (§ 4.4): the window is the defect
  D10 fixes.*
  Locked by the architect 2026-10-01. Removing the re-scan partition (D8) moves
  the final-pass counters S4 Pairwise discovery, S4 Re-scan absorbed, New
  patterns created and find_candidates calls of `-V message-grouping` on a
  final-pass window holding keys of two levels in which a pattern forms across
  the levels: the pattern re-scans the window instead of leaving the remaining
  keys to pairwise discovery. Output (the MESSAGES CSV, the rendered table and
  the cluster membership) is unchanged. No re-scan restriction is kept to
  reproduce the old counts. AC3 and AC14 read with this exception: the
  equivalence matrix is identical except these four counters on such a window.

### 11.5 Drop 1 source checks (AC5, AC6, AC8, AC9, AC14)

- **AC5:** the literal `350` appears once in `ltl`, at `MESSAGE_KEY_CAP`; no
  `? 350 :` remains; `$consolidation_message_length_cap` is gone. The four key
  sites, the trigram guard and the CONFIG line read `$max_log_message_length`,
  resolved once in `adapt_to_terminal_settings`.
- **AC6:** the one remaining cut of consolidation input is
  `get_consolidation_trigrams` :: `my $capped = substr($str, 0, $max_log_message_length);`.
- **AC8:** `MESSAGE_KEY_CAP`, `MESSAGE_KEY_THREAD_LENGTH` and
  `MESSAGE_KEY_OBJECT_LENGTH` are file-scope constants with their reasons; the
  display cuts `substr( $key, 0, $col_width{1} )` in `print_message_summary` and
  `print_threadpool_summary` are unchanged.
- **AC9:** `$max_observed_message_length` and its per-key length are gone.
- **AC14:** `extract_consolidation_bucket_key`, `partition_consolidation_keys`
  and the bucket maps are gone; a new pattern re-scans every unconsumed key of
  its group or window (`$rescan_keys`).

AC1 and AC2 are asserted by `key-cut-csv`, `key-cut-csv-grouping` and
`key-cut-csv-no-retention` in `tests/validate-csv-output.sh`, and `key-cut-grouping`,
`key-cut-no-retention` and `key-cut-terminal-width` in
`tests/validate-message-grouping.sh`. Each assertion was shown to fail: against
the release tip (which reports 120 under `-o` and `-g`), and against copies of
drop 1 that report the cap on every run or cut the keys at the terminal width.

One finding beside the carried key (§ 3 item 7, D2): with the inline re-cut gone,
`%consolidation_key_message` maps every key to the key itself, in both the
streaming and final-pass paths.

### 11.6 Drop 1 benchmark (§ 8, AC10, AC14)

The single-day access-log selection, the four cases of D6, three captures per
side: `619-before-1..3` on `af91a69` and `619-drop1-1..3` on drop 1. Medians with
ranges:

| Case | Metric | before | drop 1 | change |
|---|---|---|---|---|
| top25-consolidate | `CONFIG max_log_message_length` | 200 | 350 | expected (lock 7) |
| top25-consolidate | `finalize/group_similar` (s) | 2.400 [2.293..2.430] | 2.199 [2.176..2.270] | -8.4 % |
| top25-consolidate | `parse/read_files` (s) | 10.001 [9.829..10.085] | 9.311 [9.303..9.376] | -6.9 % |
| top25-consolidate | `rss_peak` (bytes) | 136,855,552 | 137,003,008 | +0.1 % |
| heatmap-histogram-consolidate | `CONFIG max_log_message_length` | 200 | 350 | expected (lock 7) |
| heatmap-histogram-consolidate | `finalize/group_similar` (s) | 1.787 [1.708..1.858] | 1.650 [1.631..1.666] | -7.7 % |
| heatmap-histogram-consolidate | `parse/read_files` (s) | 12.623 [12.520..12.772] | 11.821 [11.676..11.838] | -6.4 % |
| heatmap-histogram-export | `CONFIG max_log_message_length` | 200 | 350 | expected (lock 7) |
| heatmap-histogram-export | `parse/read_files` (s) | 10.341 [10.250..10.557] | 9.801 [9.759..9.817] | -5.2 % |
| standard | `CONFIG max_log_message_length` | 200 | 200 | unchanged |
| standard | `parse/read_files` (s) | 8.953 [8.775..9.012] | 8.567 [8.471..8.582] | -4.3 % |

The final-pass time does not rise (AC14). Memory moves by at most 0.1 %. The read
time falls 4 to 7 % on every case, `standard` included, where the only change on
the read path is the hoisted key-length expression, whose measured cost (§ 8,
about 53 ns per retained line) is under 0.5 % of this run. The two sides were
captured about an hour apart, not interleaved, so the read-time fall is not
attributed to drop 1; the completion gate's before/after decides it.

### 11.7 Final-pass batches holding two levels (D10)

Measured 2026-10-01 on drop 1 (`f1a62c3`), `-ni -bs 1440 -oe -n 20 -g`, with a
scratch copy of `ltl` that counts, at each final-pass batch processed (two keys
or more), the distinct levels among its keys:

| Log (family) | Batches processed | Batches holding two levels | Keys in those batches |
|---|---|---|---|
| Tomcat access log, 5,000 lines | 6 | 6 | 154 |
| Edge C SDK log | 86 | 39 | 145 |
| Apache access log with long request paths | 7 | 4 | 32 |
| Windchill method-server log | 10 | 3 | 11 |
| ThingWorx application log | 18 | 1 | 2 |

A batch holds at most one key of the previous level: the one carried when its
level's run, in body order, held a single key. On an access log, where the same
path is answered with several status codes, levels interleave in body order
throughout, and every batch on the Tomcat log held two levels.

### 11.8 Drop 2: the grouping key carried on the entry (lock 2, D2, AC7)

Under `-g`, a key new to the message store has `grouping_key` written on its
entry once, after the entry is born in either branch of the capture block in
`read_and_process_logs`, with the value the streaming checkpoints group it by
(`$log_level // ""`). The final pass reads it at all five places it used to parse
the key: the per-group key count of the skip decision, the key collection for the
similarity cliff edge, the sort, and the two group lookups of Pass 1 and Pass 2.
The sort computes each key's body once, before sorting (the key after
`"[$gk]"` and the whitespace that follows; the whole key when the grouping key is
empty), where it ran two regular expressions per comparison. The map
`%consolidation_key_message_cat_gk`, written and deleted but never read (§ 3
item 7), is removed.

- **AC7 source check:** no regular expression reads a bracketed prefix off a key
  anywhere in `ltl` (`grep` count 0).
- **AC3 matrix, drop 1 against drop 2:** the 165 comparisons of § 11.3, all
  identical, no runtime warning, every run exiting 0.
- `tests/validate-message-grouping.sh`: 30 passed, 0 failed.

**Drop 2 benchmark (§ 8, D2).** `619-drop2-1..3` on `4775344` against
`619-drop1-1..3`, medians with ranges. Memory: `MEMORY_FINAL log_messages` rises
0.2 % on the two `-g` cases (`top25-consolidate` 25,649,001 to 25,695,703 bytes;
`heatmap-histogram-consolidate` 25,639,801 to 25,695,207), the grouping key on
each entry; `rss_peak` moves between -0.4 % and +0.0 % on every case, within its
ranges. `finalize/group_similar`: -0.8 % and +1.4 %, ranges overlapping. Read time
rises 0.5 % to 1.4 % on every case, including `heatmap-histogram-export`, which
retains no message (`-n 0`) and so runs none of the changed code: the read-time
movement between these sessions is drift of about 1 %, not attributable to the
drop. It bounds what § 11.6's 4 to 7 % read-time fall can be read as.

### 11.9 Drop 3: why the final-pass fix changes grouping within a level

Drop 3 (keys sorted by grouping key, then body; a window cleared at each change
of grouping key) is in the working tree, measured against drop 2 (`4775344`).
AC15's two scenarios pass on it and fail on drop 2; AC16 holds: an instrumented
copy finds no final-pass window holding two grouping keys on the eleven AC3
inputs, where drop 2 had them on every input whose output changed. Three
statistics-drift MESSAGES baselines change: the consolidated Tomcat access log,
and the consolidated ThingWorx script log under both message data models. The
debugging below explains them.

**Two effects of the fix.** (1) The groups that held two grouping keys are gone:
13 of 206 on the Tomcat access log (`-g 90`). (2) A grouping key's keys are no
longer cut into small windows by keys of other levels interleaving in body
order. On the Tomcat log drop 2 ran 113 final-pass windows, 90 of them mixed;
the fix runs 9, none mixed. On the ThingWorx script log the window sizes go
from 26, 2, 17, 1,000, 1,000, 685, 4 to 26, 7, 1,000, 1,000, 712: the 1,000-key
window boundaries fall on different keys.

**A pre-existing limit the fix exposes: a final-pass window searches from at
most 500 of its keys.** `process_final_pass_window` sets
`my $max_search = min(500, $window_size);` while a window holds up to 1,000
keys (`$fp_window_capacity`). Keys at positions 500 to 999 of a full window
never start a candidate search; they are grouped only as the partner of an
earlier key or by a pattern's re-scan, and the final pass is their last chance.
Traced on the Tomcat log: in the fix, the 67 `[200] POST …/Things/G…/Services/
GetNamedProperties` keys sit at positions 841 to 947 of a full window, and none
is consumed; in drop 2 the same keys sat in windows of 57, 13 and 91 keys, each
searched in full, and 63 were grouped. Drop 2's broad
`[200] POST /Thingworx/Things/*0*/Services/GetNamedProperties` group (313
members) was built by merge-first from patterns found in those small windows
(`G*011`, `G*01*`, `GU*0*`, then `*0*`); in the fix the G-prefixed keys form no
pattern, and 15 narrower groups with 241 members between them remain. On the
ThingWorx script log no window reaches the cap: its changes come from the
window boundaries alone, keys meeting different partners in different
windows.

**Remedies measured** (median of three, `finalize/group_similar`, the drift
scenarios' own options):

| Log | Version | Groups | Rows after grouping | Candidate searches | Final-pass time |
|---|---|---|---|---|---|
| Tomcat access log | drop 2 | 206 | 1,137 | 1,849 | 1.600 s [1.541..1.698] |
| | fix | 200 | 1,296 | 1,582 | 0.875 s [0.862..0.882] |
| | fix, every key of a window searched | 206 | 1,093 | 1,813 | 0.978 s [0.977..1.136] |
| | fix, windows of 500 keys | 221 | 1,119 | 1,832 | 1.106 s [1.051..1.139] |
| ThingWorx script log | drop 2 | 29 | 53 | 112 | 0.332 s [0.321..0.411] |
| | fix | 27 | 49 | 111 | 0.320 s [0.318..0.334] |
| | fix, every key of a window searched | 27 | 49 | 111 | 0.320 s [0.310..0.324] |
| | fix, windows of 500 keys | 29 | 53 | 112 | 0.283 s [0.282..0.293] |

With every key of a window searched, the Tomcat log groups into fewer rows than
drop 2 (1,093 against 1,137) in 61 % of drop 2's final-pass time, and the
GetNamedProperties keys form one group of 313 members again; the ThingWorx
script log is unchanged from the fix. The master specification gives the final
pass as the last chance for every remaining key (Outstanding Decision 6: no
eviction in the final pass), and the final-pass redesign record runs pairwise
discovery on the window's contents with no cap; the 500 cap is the streaming
checkpoint's (§ Process Flow, S4 "max 500 keys"), where unsearched keys survive
to the next checkpoint.

**The recommendation to remove the final pass's 500-source cap is withdrawn
(2026-10-01).** It rested on the two logs above, where a candidate search is
cheap, and was made without tracing the cap. The cap entered the final pass with
the final-pass redesign (`8fea3d0`, carried over from the streaming
checkpoint's), with no reason recorded there; in the streaming checkpoints the
master specification shows it bounding a search cost that can be large (about
58 s per checkpoint of 500 sources on a batch of download requests at
similarity 80), and records the final pass on the PLM access log making about
37,400 candidate searches over about 75,500 keys in 42 to 44 s: half its keys,
the share a 500-of-1,000 cap allows. Removing the cap would roughly double that
work. No option for the cap is proposed until it is measured on that case.

**Locked by the architect on 2026-10-01: the batch sizes and search limits
are their own issue, and drop 3 lands with today's sizes.** Whether the final
pass's 1,000-key window, the streaming checkpoint's 5,000-key batch and the
500 keys that may start a search in either should change is filed as #648
(question and measure the batch sizes and search limits of message grouping's
streaming and final passes), blocked by this issue. Drop 3 is committed with
the sizes unchanged.

### 11.10 Drop 3 results (D10, AC3, AC4, AC15, AC16)

- **AC15:** `levels-same-body-pair` and `levels-lone-key-not-carried` in
  `tests/validate-message-grouping.sh`, on the committed fixtures
  `tests/fixtures/grouping-level-pair.txt` and
  `tests/fixtures/grouping-two-level-window.txt`: all four assertions pass on
  drop 3 and fail on drop 2, which groups an ERROR with a WARN key on each.
- **AC16:** an instrumented copy counted, at each final-pass window processed,
  the grouping keys among its keys, over the eleven AC3 inputs: no window held
  two on drop 3; on drop 2 every input whose output changed had such windows
  (the Edge C SDK log 39 of 86, the Tomcat access log 6 of 6). AC14 follows: no
  window holds two levels, so the removed re-scan partition could divide
  nothing.
- **AC3, drop 2 against drop 3:** 165 comparisons, no runtime warning, every run
  exiting 0. The 33 plain and 33 `-o` runs are identical. The 99 `-g` runs
  differ: 48 in the final-pass counters only (window counts and sizes), 51 in
  group membership. Every input whose membership changed had mixed windows on
  drop 2. The groups removed that held two grouping keys: 1 on the Apache access
  log, 1 on the same-body pair, 1 on the two-level window, 2 on the level-only
  synthetic input; drop 3 has none on any input. Within one level, groups
  re-form on the ThingWorx application log (2 gone, 2 new) and the Edge C SDK log
  (2 gone, 1 new), from the window composition (§ 11.9).
- **AC4, saved expectations changed:**
  - `tests/statistics-drift/baselines/{tomcat-consolidated,thingworx-consolidated,thingworx-bin-consolidated}/messages.csv`
    re-captured: on the Tomcat access log 13 of drop 2's 206 groups held two
    status codes and 90 of its 113 final-pass windows mixed them; on the
    ThingWorx script log one of 7 windows was mixed and the window boundaries
    moved (§ 11.9). The STATS baselines do not change.
  - `tests/statistics-drift/known-failures.tsv`: the
    `thingworx-bin-consolidated` p999 entry (registered against #469, hold
    consolidated message histograms on a shared bucket geometry) no longer
    reproduces, because the merged rows it was measured on changed composition;
    #469 is not fixed, and its other entries still reproduce.
  - `tests/validate-message-grouping-notices.sh`: its grouped scenarios ran on a
    fixture whose keys group only across status codes (`[200]` with `[302]`,
    `[304]` or `[404]` on the same path), so under the fix nothing groups there
    and the bin-model notice correctly does not print. The two grouped
    scenarios move to `tests/fixtures/grouping-signed-downloads.txt`
    (`-du us -xqs -g 75`), which groups within one status code on both drop 2
    and drop 3; the notice assertion was shown to fail on a copy of `ltl` with
    the notice disabled. The ungrouped scenario keeps its fixture.
- **Harnesses run on drop 3:** `validate-message-grouping.sh` 34 passed;
  `validate-message-grouping-notices.sh` 4 passed; the eight consolidated
  statistics-drift scenarios pass; `validate-message-control-characters.sh`,
  `validate-classification-states.sh`, `validate-statistics-demand.sh`,
  `validate-udm-counting.sh`, `validate-runtime-config.sh`,
  `validate-section-layout.sh`, `validate-format-detection.sh` and
  `validate-csv-output.sh` pass with no failure.

### 11.11 Drop 3 benchmark (§ 8, AC10, AC14)

`619-drop3-1..3` on `fe42422` against `619-drop2-1..3`, medians with ranges.
The single-day access-log selection is the Tomcat access log of the
`tomcat-consolidated` drift scenario, here run with the benchmark's own options
(`-g -m uuid`).

| Case | Metric | drop 2 | drop 3 | change |
|---|---|---|---|---|
| top25-consolidate | `finalize/group_similar` (s) | 2.229 [2.149..2.301] | 0.588 [0.576..0.663] | -73.6 % |
| top25-consolidate | message rows kept (`log_messages_entries`) | 656 | 747 | +91 rows |
| top25-consolidate | `rss_peak` | 137,035,776 | 139,198,464 | +1.6 % |
| top25-consolidate | `total` (s) | 11.850 [11.743..11.908] | 10.231 [10.200..10.310] | -13.7 % |
| heatmap-histogram-consolidate | `finalize/group_similar` (s) | 1.637 [1.631..1.683] | 0.513 [0.513..0.524] | -68.7 % |
| heatmap-histogram-consolidate | message rows kept | 656 | 747 | +91 rows |
| heatmap-histogram-consolidate | `rss_peak` | 118,145,024 | 111,853,568 | -5.3 % |
| standard, heatmap-histogram-export | every metric | | | within the session drift of § 11.8 (read time +0.9 % and +2.4 %; neither runs the final pass) |

The final pass is three to four times faster and keeps 91 more rows. Both come
from the same cause as § 11.9: on drop 2 the 200 keys reached the final pass in
many small windows, each searched in full; on drop 3 they arrive in windows of
1,000 of which at most 500 keys start a search, so fewer searches run and fewer
keys are grouped. The speed is the cost of the search limit, not a gain in the
search; whether the limits should change is #648. `MEMORY_FINAL log_messages`
rises 0.6 % with the extra rows.
