# Choose where a long message is truncated in the messages table: left, middle or right (Issue #564)

## Status

Planning, on branch `564-message-truncation-position` off `release/0.20.0`.
The touched surfaces' contracts (§ 2) were confirmed by the architect on
2026-10-14; the architect's direction of the same day is § 3. No decision is
locked yet.

## 1. What this is for

An analyst reading the messages table of an access log sees messages that all
begin with the same path prefix, while what tells them apart sits at the end:
the API name and, with the query string kept (`-xqs`), the query string. The
right cut the table applies today always throws that end away. Choosing a left
or middle cut keeps the distinguishing part visible, with the attributes the
analyst uses as signposts (log level, thread, object) still shown.

## 2. Touched surfaces and their contracts (confirmed 2026-10-14)

| Surface | Contract | Record |
|---|---|---|
| Stored message-key length | One length per run, resolved at one site (`adapt_to_terminal_settings`): `MESSAGE_KEY_CAP` (350) under `-o` or `-g`, the terminal width otherwise | `features/619-per-run-key-cut.md` § 4.1 lock 1: "**One per-run cut**, resolved once at option settlement: the cap when grouping or CSV is on, the terminal width otherwise." |
| Display cut in the messages table | A rendering cut on a different value from the key cut, owned by this issue, kept distinct. Today a right cut with no marker: `print_message_summary` :: `my $message = substr( $key, 0, $col_width{1} );` | 619 § 4.1 lock 3: "The display cut in the messages table is a rendering cut on a different value, owned by #564, and stays distinct."; `features/342-redundant-logic-surfaces-audit-report.md` F7.9 (the field and message cuts): "the two must stay distinct when it lands" |
| Keeping the message's tail | Handed to this issue | 619 § 5.8: "Without `-o` or `-g`, the key is already cut to the terminal width when it is stored, so a left or middle display cut cannot show the message's tail: the key cut has already dropped it. How a run that chooses a left or middle cut keeps the tail is #564's to decide" |
| Exposed values | `-xt`, `-xs`, `-xu` and `-x object` append `key=value` at the end of the message; exposing a value does not move the key cut | `features/566-preserve-named-values-in-message.md` D4 (an exposed thread is appended to the end of the message as a key-value pair), D8 (the message key's length limit is unchanged): "Exposing a value does not change where the key is cut: the terminal width in the rendered output, 350 characters with `-o` or `-g`." |
| Key composition | Level, the thread's first 20 characters and the object's last 25 where the format supplies them, then the masked message | `features/fuzzy-message-consolidation.md` § IQ-01 (category model, resolved) |
| Key as identity and display | One string serves as hash key and display string; under `-g` similarity is scored on the whole key and any part, level, thread and object included, may be wildcarded | fuzzy-message-consolidation § DD-09 (the key is both hash key and display string), § PF-09 (similarity on the full message key): "Similarity is scored on the whole `$log_key` as one contiguous string, its level, thread and object included, and any part may be wildcarded." |
| CSV | Column 2 of the messages CSV is the stored key verbatim | `features/447-message-control-character-normalisation.md` surfaces table: "Messages CSV (column 2 is the key verbatim)" |
| Column budget | The message column is budgeted in characters and padded with `%-Ns` | 447 § Overview |
| Line width | No printed line exceeds the terminal width; 100 columns is the minimum supported | `features/column-layout-refactor.md` § Minimum supported terminal width |
| Existing shortener | `shorten_filename` (middle cut with `...`, used by the progress line and the processed-files list) is reused, not duplicated | `features/532-progress-line-file-path.md` § Requirements: "One resolution surface: the existing shortener is reused, not duplicated." |

Corrections to the issue's links: the issue describes DD-08 (similarity on the
message text, the metadata prefix held apart) as current; the record marks it
superseded by PF-09 (similarity on the full message key). #174 (adaptive
message length cap) is closed as not planned and no longer constrains this work.

## 3. The architect's direction (2026-10-14)

1. **The composed attributes are outside the truncation.** The attributes at
   the start of the composed message (level, thread, object) are never part of
   the question of where to cut. A left cut prints the attributes, then the
   ellipsis, then the message running to the end of the printable space.
2. **Two touch points, both position-aware.** The stored cut is no longer
   strictly a left-to-right flow: it may run right to left, or from the centre
   to the extremities. The cut at storage is the first touch point and applies
   the chosen position; the print to the terminal is the second, taking the
   already-shortened message and adapting it to the available print width with
   the same position.

## 4. Research (2026-10-14, read-only, on the worktree at `71f1116`)

Measured at terminal width 160 (`--terminal-width 160`), comparing the stored
key against `-o` keys capped at 350:

- The message column is sized by `print_message_summary`'s own percentage
  table, not `@column_layout`: 100 characters of a 160-character stored key in
  the statistics variant, 146 in the basic one.
- Keys longer than the column and also longer than the 160-character stored
  key, on the top messages: none on an Apache web-tier access log or a Tomcat
  access log carrying thread and session with `-xt`; all 100 on a Windchill
  method-server log with `-xt`; 32 of 61 on an HTTP/2 access log carrying
  OData queries; 22 of 83 on a Tomcat access log of an IoT REST API.
- The stored key's length changes which rows exist: on the method-server log
  with `-xt`, one row of 1,533 occurrences at 160 characters is 50 rows of
  about 30 at 350, one per thread, because the appended `thread=` survives.
- Where the varying part of a message sits depends on the log family: on the
  Tomcat thread-and-session, method-server and Apache web-tier logs a left cut
  removes only text shared by the top messages (20 of 20, 97 of 100, 18 of 18);
  on the IoT REST log the top 20 share a 77-character constant tail and a left
  cut removes only varying text (0 of 20).

Evidence: the session scratchpad's `733-research/` captures; to be re-run into
committed criteria when acceptance criteria are agreed.

## 5. Open items

- The stored cut's length when a left or middle position is chosen without
  `-o` or `-g` (terminal width or `MESSAGE_KEY_CAP`).
- CSV: the issue's done-when says CSV output is unchanged; a position-aware
  stored cut changes CSV column 2 for messages longer than the cap.
- Appended exposed values (`thread=`, `session=`, `user=`, `object=`) at the
  end of the key: message text to be cut, or attributes kept like the prefix.
- How each touch point knows where the composed attributes end, including under
  `-g`, where they may be wildcarded.
- The ellipsis character's width in the `%-Ns`-padded column.
- Automatic selection: prototype here, or a dependent issue.
