# Audit report: redundant logic surfaces and architectural patterns across `ltl` (Issue #342)

## Status

Opened 2026-09-26 with the scoping pass's verified inventory as its first entries.
The specification, method, locked decisions and acceptance criteria are in
`features/342-redundant-logic-surfaces.md`; this document holds the findings.

Every entry below marked *scoping pass* was found by a read-only inventory of `ltl`
at 7aa2bd5 (the base of `release/0.19.0`) and re-grepped by an independent verifier.
The audit completes each item by running the search angles the specification names,
confirms every *diverged* candidate by a captured run, assigns category and priority,
and fills the site inventory. Until an item's section says *audit complete*, its
findings are candidates, numbered so they can be discussed, not conclusions.

## How to read a finding

`F<item>.<n>` identifies a finding of scope item `<item>` (P for the patterns sweep).
Every reference to one elsewhere carries its meaning in the same sentence. A site is
cited by enclosing sub plus an in-body snippet that `grep -F` finds inside that sub;
file-scope sites name the section or the two subs they sit between. Category is one
of *diverged*, *latent*, *identical by construction* or *deliberate*; *hot path*
marks a benchmark obligation for whichever issue fixes the finding. Priority ranks
by divergence risk, then user-visible consequence, then number of copies.


---

## Item 1: Option-operand vocabularies

**State: audit complete (2026-09-26).** The four search angles of the
specification were run on `ltl` at 4e2d006 (the issue branch, which differs from
7aa2bd5 only by the version stamp); every candidate the scoping pass raised was
re-read against the captures, every *diverged* finding was confirmed by a run, and
three findings the scoping pass did not have were added (a warning that can never
print, a nondeterministic unit resolution, and a help text that names a mode that
does not exist). Captures live under the session scratchpad (`342/runs/`), one
file per run, named by option; the report cites each by fixture and options so it
can be reproduced from the fixture description below.

### Fixtures used by the confirmation runs

- **A**: the committed `tests/fixtures/tomcat-access-single-sample-keys.txt`
  (twelve Tomcat access-log lines, one request each, with duration and bytes).
- **B**: a three-line scratch fixture in the Tomcat access-log shape (TEST-NET
  addresses, one path each, status 200, bytes 512/640/128, durations 10/20/30 ms)
  whose request line carries the query string `?Bytes=7&time=3&object=9` (values
  7 to 9 on the first key, 3 to 5 on the second, 9 on the third), so that a name
  read as a line key finds a value and a name read as a metric does not change
  the message.
- **C**: a two-line scratch fixture of the same shape whose query string is
  `?Bytes=7&Foo=3&bytes=5` (8, 4, 6 on the second line), so that `Bytes`,
  `bytes` and a name of no vocabulary are all present as keys.
- **D**: a three-line scratch fixture of the same shape whose query string is
  `?elapsed=5&v=1` (7/2, 9/3), the input for a user-defined metric read by its
  token key (`elapsed`) and for the byte-unit cases (`v`).

Every run passed `--disable-progress`, `--terminal-width 220` and, where the
verbose sections were read, bare `-V`. The scratchpad sits on a case-insensitive
filesystem, so captures whose names differ only by case (`-x Bytes` and
`-x bytes`) were re-taken under distinct names before being read; the byte-unit
sample counts below come from fresh runs piped to `grep`, not from files.

### Search angles run

1. **By option.** The GetOptions block (128 lines) lists 27 options taking a
   string value. Of those, 20 compare the value against a token vocabulary and
   are in scope: `-bs`, `-du`, `-ru` (time units); `-lf` (format names); `--hide`
   and `--show` with their eleven per-column and per-section shorthands (section
   and column names); `-x` with `-xt`, `-xqs`, `-xs`, `-xu`, and `-d` (metric,
   field, identifier and line-key names); `-m` and `-uuid` (identifiers); `-so`
   (sort fields); `-udm` (unit and function slots); `-dm`, `-hgdm`, `-hmdm`,
   `-mdm`, `-bdm` (`raw|bin`); `-pr` (profile modes); `-V` (section names);
   `-cp` (precision modes); `-hm`, `-hg` (metric names); `-g`, `-mem`, `--help`
   and `--explain` (an optional operand or a topic). The other seven take free
   text (regular expressions, timestamps, file names, a separator) and were not
   followed. Every variable was followed to each `eq`, `=~`, `exists`, `grep` and
   hash lookup on it; the sites are in the inventory.
2. **By token.** Every literal occurrence of `duration`, `time`, `bytes`, `size`,
   `count`, `durationMs`, `durationMS` (122 lines), `raw` and `bin` (81 lines),
   `uuid`, `ipv4`, `ipv6`, `ip` (6 lines), and `thread`, `session`, `user`,
   `object`, `query-string` (34 lines), classified as resolution, error text,
   help text, or internal consumer of resolved state. The internal consumers
   (format specs' field maps, the column layout ids, the CSV family table, the
   per-metric loops in the histogram and export code) are listed once in the
   inventory as out of scope for this item and not counted as copies of an
   option vocabulary.
3. **By error and help text.** 62 `die`, `warn` and `print_usage` lines naming a
   vocabulary and 65 `help_opt` rows naming a metric, unit, model, identifier,
   field, topic or sort field were read. Each enumeration is classified below as
   derived from the table the resolver reads, or as a literal.
4. **By table.** Every reader of `@time_unit_ladder` and its five views,
   `%mask_patterns` and `@mask_order`, `%verbose_section_registry` and
   `@verbose_section_order`, `%profile_modes`, `@visibility_columns` and
   `%column_aliases`, `@output_sections` and `%section_aliases`,
   `@duration_family_stats`, `@graph_columns`, `%heatmap_metric_map`,
   `%explain_aliases`, `%function_names`, `%byte_units`, `%si_units`,
   `%byte_unit_canonical`, `%format_registry_spec` and `%format_registry_entry`,
   `@log_levels` and `%log_level_set`, and the four metric-name subs. The
   readers are in the inventory; the places that should read a table and do not
   are the findings.

### Findings

Ranked by divergence risk, then user-visible consequence, then number of copies.
Every site is `sub` plus an in-body snippet. "Confirmed" names the fixture and
options of the run that produced the two observations.

| # | Vocabulary | Site A | Site B (further copies in the note) | What each does | Observed divergence | Target | Contract and owner | Category | Related open issues |
|---|---|---|---|---|---|---|---|---|---|
| **F1.12** | Byte units on the `-udm` unit slot | `parse_udm_configs` :: `my %byte_unit_canonical = map { lc($_) => $_ } keys %byte_units;` | `convert_bytes` :: `'K'   => 1024,` (and the help row `print_help` :: `Bytes: B, kB, KB, MB, GB, TB, KiB, MiB, GiB, TiB. SI: k/K, M, G, T.`) | A folds the unit to lowercase and looks it up in a map built from a table that holds both `kB` and `KB` (and `B` and `b`), so the two spellings collapse onto one lowercase key and the survivor is whichever `keys %byte_units` yielded last; B multiplies `kB` by 1000 and `KB` by 1024 | **Nondeterministic across processes.** Fixture D, `-udm 'v:KB:max' -V udm-specs`, sixteen fresh runs: ten reported `unit=KB(bytes)` (1024), six reported `unit=kB(bytes)` (1000). `-udm 'v:kB:max'` reported `unit=KB(bytes)` in its captured run. The same input gives a value that differs by 2.4 percent between two runs of the same command. Separately, `K` on the unit slot resolves through `parse_udm_configs` :: `if (exists $si_units{$unit}) {` to a plain number times 1000 (`unit=K(number)`), while `K` inside a heap value read by the GC transform reaches `convert_bytes` and means 1024: the `'K' => 1024` entry of `convert_bytes` is unreachable from the option | One byte-unit ladder at file scope in the shape of `@time_unit_ladder` (token, spellings, multiplier), read by `parse_udm_configs`, `convert_bytes`, `format_bytes` and the `-udm` help row; case-folding only where two spellings are not both tokens | `features/524-bucket-size-unit.md` D1 (one ladder per unit vocabulary, no private tables) is the shape; `features/user-defined-metrics.md` says every byte unit is base 1024, which the code contradicts (§ 3 item 10 of the specification) | **diverged**, nondeterministic | #605 (byte, duration and number inputs accept a value with a unit) would add every threshold option as a reader of this vocabulary and asks for the standard input-unit pattern; it must land on the one ladder or it multiplies the copies. #17 (auto-detect input latency units) is time units only, no relationship |
| **F1.17** | `-hg` unknown-metric warning | `handle_histogram_option` :: `warn "Unknown histogram metric: $metric (valid: duration, time, bytes, count)\n";` | `adapt_to_command_line_options` :: `local $SIG{__WARN__} = sub { push @getopt_warnings, $_[0]; };` | A warns from inside the GetOptions handler; B installs a warning handler around GetOptions that collects every warning and prints the collection only when GetOptions fails | **The warning can never reach the user.** Fixture A, `-hg duration,foo`: exit 0, empty stderr, histogram rendered for duration; `foo` is dropped without a word. The `-hm` counterpart (`adapt_to_command_line_options` :: `warn "-hm value '$heatmap_metric' is not a built-in metric (duration|bytes|count)`) runs after GetOptions and prints | Validate `-hg` operands where `-hm`'s are validated, at option settlement after `parse_udm_configs()`, through `resolve_metric_operand()`; the handler only records the operand | `features/histogram-charts.md` § Command Line Interface (any option taking metric-name operands resolves through the three named subs; an unknown name is an error the user sees) | **diverged** | none on the `-hg` surface. #412 (notices surface) is where a settlement-time notice would render, informational |
| **F1.1** | The `time` alias for duration | `builtin_metric_name` :: `return 'duration' if $lc eq 'duration' \|\| $lc eq 'time';` (read by `-hm`, `-hg`; `-so` re-encodes it in `adapt_to_command_line_options` :: `if( $sort_type =~ /^(?:duration\|time)$/i ) {`) | `resolve_discard_names` :: `elsif ( $name eq 'duration' \|\| $name eq 'durationMs' \|\| $name eq 'durationMS' ) { $omit_durations = 1 }` (same literal in `resolve_expose_names` and `apply_discard_precedence`; `resolve_visibility_name` has `dur` but no `time` in `%column_aliases`) | A and `-so` accept `time` as duration; B does not, so `time` falls through to the line-key path; `--hide time` is a usage error | Fixture B: `-d time` keeps the latency columns (the messages table row still shows `10ms 20ms 20ms`) and removes nothing visible; `-d duration` removes them. `-x time` appends ` time=3` to the message and splits the two `/app/orders` lines into rows of one occurrence each. Fixture A: `-hm time` reports `heatmap: duration`; `-so time` is accepted; `--hide time` exits 1 with `Unknown section or column 'time'` | `resolve_expose_names`, `resolve_discard_names`, `apply_discard_precedence` and `resolve_visibility_name` call `builtin_metric_name()` before their own arms; `-so` calls it for its bare metric words | `features/histogram-charts.md` § Command Line Interface (`time` aliases `duration`; any new option taking metric names resolves through the named subs) against `features/566-preserve-named-values-in-message.md` D6 and `features/567-discard-named-values-from-message.md` D14 as written (a list without `time`). Which reading is the contract is a findings-discussion question | **diverged** | #581 (deprecate `-od`, `-ob`, `-oc` in favour of `--discard`) makes `-d` the only surface for switching a metric off, so its vocabulary has to equal the shared one before the omit options go. #582 (name what to expose, discard or mask by a regular expression) rewrites the three resolvers' parse and is where a converged resolver would be built or bypassed |
| **F1.2** | Case folding of built-in metric names | `builtin_metric_name` :: `my $lc = lc trim($token);` and `resolve_visibility_name` :: `my $name  = lc $given;` | `resolve_expose_names` :: `elsif ( $name eq 'bytes' )        { $expose_metric{bytes} = 1 }` (same exact compare in `resolve_discard_names` and `apply_discard_precedence`) | A folds case; B compares exactly, so a capitalised built-in name becomes a line key | Fixture C: `-x Bytes` appends ` Bytes=7` to the message as a line key; `-x bytes` appends nothing (the metric is exposed in place); `-d bytes` removes the bytes column, `-d Bytes` keeps it. Fixture A: `-hm Bytes` reports `heatmap: bytes`; `--hide Bytes` reports `hide: progress,bytes`; `-so BYTES` is accepted | as F1.1 | `features/histogram-charts.md` § Command Line Interface (built-in names match case-insensitively) | **diverged** | #581 and #582 as F1.1 |
| **F1.3** | `durationMs` and `durationMS` as duration | `resolve_expose_names` :: `elsif ( $name eq 'duration' \|\| $name eq 'durationMs' \|\| $name eq 'durationMS' ) { $expose_metric{duration} = 1 }` (same literal twice more) | `builtin_metric_name` :: `return $lc        if $lc eq 'bytes' \|\| $lc eq 'count';` (no arm for the key spellings) | A accepts the two key spellings as the duration metric; B rejects them, so `-hm` and `-hg` treat the word as a filename | Fixture A: `-x durationMs` is accepted with no notice; `-hm durationMs` warns `is not a built-in metric (duration|bytes|count)`, pushes the word back as a positional argument and uses duration; `-hg durationMs` does the same silently. In both the pushed-back word is then dropped without notice (see F1.6) | One list of accepted spellings held with `builtin_metric_name()`; whether the key spellings belong to the shared vocabulary or to the key-reading options only is a findings-discussion question | `features/566-preserve-named-values-in-message.md` D6 (the accepted spellings on `-x`) | **diverged** | #581 as F1.1 |
| **F1.4** | A user-defined metric named by its token key | `resolve_expose_names` :: `// ( grep { defined $_->{token_key} && $_->{token_key} eq $name } @udm_configs )[0];` (same fallback in `resolve_discard_names`) | `resolve_metric_operand` :: `return { kind => 'udm', config => $match } if $match;` and `resolve_visibility_name` :: `my $config = udm_config_by_name($given);` (both call `udm_config_by_name` alone) | A resolves the metric by name, base name, then token key; B by name and base name only | Fixture D with `-udm 'lat::max:elapsed' -xqs`: `-x elapsed` and `-x lat` both leave `elapsed=5` in place in the message where the bare run shows `elapsed=?`; `-x nosuch` leaves `elapsed=?`. `-hm elapsed` and `-hg elapsed` exit 25 with `Unknown ... metric 'elapsed'. Available: duration, bytes, count, lat`; `--hide elapsed` exits 1 as an unknown column while `--hide lat` succeeds | The token-key fallback moves into `udm_config_by_name()` if it is part of the shared vocabulary, or is removed from `-x` and `-d` if it is not: a findings-discussion question | `features/597-section-visibility.md` D24 (a user-defined metric's column is hidden by the name its column shows); `features/user-defined-metrics.md` (name, base name) | **diverged** | #601 (deprecate the per-column options `--hide` duplicates) makes `--hide` the only column surface, so the name set it accepts is the one users keep |
| **F1.11** | Parsed-field names on `-x` and `-d` | `resolve_expose_names` :: `elsif ( $name eq 'thread'  )      { push @expose_appends, [ EXPOSE_THREAD,  'thread'  ] }` (thread, session, user, query-string) | `resolve_discard_names` :: `if    ( $name eq 'thread' \|\| $name eq 'session' \|\| $name eq 'user' \|\| $name eq 'object' ) {` (and the second copy `$discard_any_field = ( grep { $discard_field{$_} } qw( thread session user object ) ) ? 1 : 0;`) | A's field set has no `object`; B's has it, so the same word is a parsed field on `-d` and a line key on `-x` | Fixture B: `-x object` appends ` object=9` to the message (a line key read from the query string); `-d object` clears the parsed object field, which access logs do not carry, and the message and columns are unchanged | One field-name table read by both resolvers, with `object` in or out of it by decision | `features/567-discard-named-values-from-message.md` D9 (the fields `-d` names) and D15 (`-x` and `-d` accept the same names) disagree with each other on `object`; a findings-discussion question | **diverged** | #536 (expose the thread name as an attribute) and #537 (expose the remote host as an attribute) each add a name to this vocabulary on the grouping, filter and highlight surfaces; #582 rewrites the parse of all three options |
| **F1.6** | An operand that names nothing, pushed back as a filename | `adapt_to_command_line_options` :: `warn "-hm value '$heatmap_metric' is not a built-in metric (duration|bytes|count) and no -udm configs are defined; treating as positional argument` (and `-g`: `warn "-g value '$group_similar_sensitivity' is not numeric; treating as positional argument`) | `handle_histogram_option` :: `unshift @ARGV, $opt_value;` (silent); `adapt_to_command_line_options` :: `unshift @ARGV, $name;` under `-V` (silent) and `unshift @ARGV, $memory_usage_operand;` under `-mem` (silent) | Five options with an optional operand treat a value they do not recognise as a filename; two say so, three do not. Every one then reaches `adapt_to_command_line_options` :: `@in_files = grep { -f $_ } @in_files;`, which drops a name that is not a file without a notice | Fixture A: `-hm foo`, `-g foo` warn and continue; `-hg foo`, `-V foo` (its own warning names the section vocabulary, not the pushback), `-mem foo` continue silently; in all five the word `foo` appears nowhere afterwards, and the verbose file list holds only the fixture | One pushback helper that decides "operand or filename" the same way for the five options and always says what it did; and a notice from the file-list filter when a positional argument is not a file | `features/histogram-charts.md` (issue #231 in the source comment surfaced the `-hm` pushback); nothing records the silent drop of a non-file positional | **diverged** | none |
| **F1.5** | The vocabulary named by an unknown-metric message | `adapt_to_command_line_options` :: `die "Error: Unknown heatmap metric '$heatmap_metric'. Available: " . join(', ', available_metric_names()) . "\n";` (and the `-hg` twin) | `adapt_to_command_line_options` :: `is not a built-in metric (duration|bytes|count) and no -udm configs are defined` and `handle_histogram_option` :: `(valid: duration, time, bytes, count)` | A derives its list from `available_metric_names()` (built-ins plus user-defined names, no `time`); B and C are literals, one naming `time`, one not; C never prints (F1.17) | Fixture A: `-hm foo` prints the `(duration|bytes|count)` literal; `-hm foo -udm x::max` prints `Available: duration, bytes, count, x` | Every unknown-metric message names `available_metric_names()`, which itself reads the built-in list from `builtin_metric_name()`'s table rather than its own `qw(duration bytes count)` | `features/histogram-charts.md` § Command Line Interface | **diverged** | none |
| **F1.8 / F1.9** | The `-so` sort-field vocabulary | `adapt_to_command_line_options` :: `do { print_usage( "invalid sort type used" ); exit 1; } unless grep { lc $_ eq lc $sort_type } qw(` (the allow-list) | `adapt_to_command_line_options` :: `if( $sort_type =~ /^(?:duration\|time)$/i ) {` (the ladder, every name again) and `print_help` :: `A bare metric name means its total: bytes, duration (alias time), count. Aggregates:` (the row) | Three copies of one vocabulary; the row omits `size`, `total`, `count_sum`, `count_total`, `count_avg`, `avg`, `std_dev` and the `duration_` prefix; the error names no vocabulary; the alias set is uneven (`avg` for `mean` and `count_mean`, none for `bytes_mean`) | Fixture A: `-so size`, `-so total`, `-so count_avg`, `-so stddev`, `-so duration_stddev` (reported as `stddev`) and `-so duration_p50` (reported as `p50`) are accepted; `-so bytes_avg` and `-so foo` exit 1 with `invalid sort type used` | One sort-field table (operand, aliases, sort key) that the allow-list, the ladder, the help row and the error all read; the bare metric words through `builtin_metric_name()` | `features/432-metric-aggregate-naming-parity.md` D1 (a bare metric word aliases its total) and D3 (duration keeps its bare spellings); D8 names `-so` a consumer of the CSV column names, which are item 6's copies | **diverged** (help against behaviour) | #514 (count metric capture becomes explicit) changes what the `count_*` operands can rank and retires the dead `-ic`; it touches the count arm of this vocabulary |
| **F1.18** | `-pr` profile modes | `_validate_profile` :: `the modes are day, week, workday, workweek, weekday,` | `(file scope, GLOBALS)` :: `my %profile_modes = (` | A validates against the table but writes its error as a literal that ends "each with an -alt variant"; the table has no `day-alt` (fifteen keys: `day` and seven modes with an `-alt` twin) | Fixture A: `-pr day-alt` exits 1 with a message stating that `day` has an `-alt` variant; `-pr day` runs | The error lists `sort keys %profile_modes` | `features/`: the profile feature doc (not read for this item; the mode table is the contract) | **diverged** | none |
| **F1.15** | `--help` topics | `dispatch_informational_options` :: `print_usage("unknown --help topic '$help_topic' (try: statistics, formats, profile)");` | `print_help` :: `Naming a topic shows that topic's index: 'statistics'` (the row names statistics and formats) | The dispatch is an if/elsif chain with a literal list in its error; the help row lists one topic fewer | `--help foo` exits 1 naming three topics; `--help` names two | One topic table (name, renderer) read by the dispatch, the error and the row | none recorded | **diverged** (two texts disagree) | none |
| **F1.19** | Statistic-name aliases shared by `--explain` and `-so` | `(file scope, --explain section)` :: `my %explain_aliases = (` (comment: mirrors `-so` value aliases) | `adapt_to_command_line_options` :: `$sort_type =~ s/^duration_//i unless $sort_type =~ /^duration$/i;` | A maps `avg`, `stddev` and the percentile names; B strips the `duration_` prefix and accepts the metric-family names | `--explain stddev` and `--explain avg` render; `--explain duration_mean` and `--explain bytes_mean` exit 1 as unknown topics while `-so duration_mean` and `-so bytes_mean` are accepted | Either the comment is corrected to say the two vocabularies are different, or `resolve_explain_topic()` applies the same prefix strip; a findings-discussion question | `features/504-explain-technique-topics.md` (topic registry) | **diverged** (comment against behaviour) | none |
| **F1.7** | The built-in metric set `duration`, `bytes`, `count` | `builtin_metric_name` :: `return $lc        if $lc eq 'bytes' \|\| $lc eq 'count';` | `available_metric_names` :: `return (qw(duration bytes count), map { $_->{name} } @udm_configs);` and nine more: `(file scope, GLOBALS)` :: `my @graph_columns = qw( duration bytes count );`, `(file scope, GLOBALS)` :: `my @visibility_columns = qw( legend occurrences duration bytes count session user classification stats values rate );`, `(file scope, GLOBALS)` :: `my %heatmap_metric_map = (`, the three resolver literals (F1.2), the `-so` allow-list and ladder, and the four help rows for `-hm`, `-hg`, `-so` and `-udm` | Twelve literal copies of one three-word set | Identical today | One table of built-in metrics (name, aliases, column, family) from which `builtin_metric_name()`, `available_metric_names()`, `@graph_columns`, `@visibility_columns`, `%heatmap_metric_map` and the help rows derive | CLAUDE.md checkpoint (one resolution surface per vocabulary) | **latent** | #514 would remove or demote `count` from the set and has to touch every copy; #60 (configurable metric visibility, on hold) would make the set data |
| **F1.10** | Mask identifiers | `resolve_mask_names` :: `elsif ( exists $mask_patterns{$name} )       { $wanted{$name} = 1 }` | `resolve_discard_names` :: `elsif ( $name eq 'uuid' \|\| $name eq 'ipv4' \|\| $name eq 'ipv6' ) { push @discard_subs, discard_identifier_sub($name) }` and `resolve_mask_names` :: `print_usage("Unknown mask name '$name' for -m. Valid values: uuid, ip, ipv4, ipv6");` | A resolves through the table; B matches the same names by literal (and reads only the pattern from the table through `discard_identifier_sub`); the `-m` error is a literal | Identical today (the table holds exactly uuid, ipv6, ipv4; `ip` is the alias both spell out) | `-d` resolves identifiers through `%mask_patterns` and `@mask_order` as `-m` does; the `-m` error lists the table | `features/580-mask-uuid-and-ip-address.md` D5 (the `-m` surface follows the `-x`/`-d` shape); the `%mask_patterns` comment ("every option that names one of these identifiers resolves it through this table") is not true of `-d` | **latent** | #582 adds a replacement field and a pattern form to `-m` and `-d`, and would rewrite both resolvers |
| **F1.13** | Time-unit spellings in help rows | `(file scope, GLOBALS)` :: `my $time_unit_list        = join(', ', map { $_->{token} } @time_unit_ladder);` (read by the three errors) | `print_help` :: `(ns, us, ms, s, m, h, d, w, month, year)` (the `-du` row; the `-ru`, `-bs` and `-udm` rows carry the same literal) | The errors derive the list; four help rows write it by hand | Identical today (both read `ns, us, ms, s, m, h, d, w, month, year`); `tests/validate-help-content.sh` has scenarios for the `-udm` function list, the `-m` rows and the `-d` rows, and none for a unit list | The rows interpolate `$time_unit_list` | `features/524-bucket-size-unit.md` D1 and D2 | **latent** | #605 adds the unit ladder to every threshold option's help row |
| **F1.14** | `raw\|bin` per-surface defaults | `resolve_data_model` :: `return $data_model_omnibus if defined $data_model_omnibus;` | `read_and_process_logs` :: `$heatmap_capture_mode       = choose_data_model('heatmap')       // 'bin';` and thirteen more call sites with an inline default | The resolver returns undef when no selector was given and every caller applies the surface's default itself | Identical today (fourteen sites, each surface's default consistent across its sites) | The default held with the surface inside `resolve_data_model()` | `features/266-data-model-selectors.md` § Resolution at each call site (as built) | **latent** | none |
| **F1.20** | Aggregate-function aliases | `parse_udm_configs` :: `my %function_names = map { $_ => 1 } qw( sum min max mean avg count distinct dcount unique ratio rate drate delta idelta );` | the `-so` allow-list (F1.8) and `%explain_aliases` (F1.19) | Three tables each carry `avg` as an alias of `mean` | Identical today | Where a shared statistic-name table exists (F1.8's target), `avg`, `stddev` and the percentile names are read from it by all three | `features/user-defined-metrics.md` (function slot) | **latent** | none |
| **F1.16** | Format names | `apply_format_pin` :: `$listed{ $e->[FR_SLUG] } = 1 unless $format_registry_spec{ $e->[FR_NAME] }{verification};` | `print_help_formats` :: `next if $spec->{verification};   # a verification-only producer is not a format a user reads` | Both derive from the registry; the verification filter is written twice, and the family-member loop above B does not apply it | Identical today: the `-lf foo` error lists 19 names and `--help formats` lists the same 19 | One predicate (`format_user_visible($spec)`) read by both | `features/log-format-registry.md` D49 (a run-level pin tops the precedence chain) | **identical by construction** | #387 (user-defined YAML formats) adds entries to the registry both lists read; informational |

Sites audited and closed as **deliberate**, so the next reader does not re-open
them:

- `-hm LAT` is rejected while `-hm lat` resolves (fixture D): user-defined metric
  names are case-sensitive by the `features/histogram-charts.md` contract, and
  the help rows for `-hm` and `-hg` say so.
- `-d nosuch` and `-x nosuch` are accepted without a notice (fixture C): by the
  `features/567-discard-named-values-from-message.md` rule that an unknown name is
  a key no line carries, not an error.
- `-V` section names: one registry (`%verbose_section_registry`,
  `@verbose_section_order`) serves validation, the `-V list` output and the
  unknown-name warning (`adapt_to_command_line_options` :: `warn "Unknown -V section: $name. Known sections: "`). Converged.
- `-du`, `-ru`, `-bs`: one resolver (`time_unit_canonical`) and one derived list
  in the three errors. Converged in code (#524 D1); the help rows are F1.13.
- `-dm` and its four siblings: one validator (`_validate_dm`) and one error form.
  Converged (#266); the defaults are F1.14.
- `-cp`: a single option whose allow-list and error are literals in one place
  (`adapt_to_command_line_options` :: `print_usage("Invalid --csv-precision value '$csv_precision'. Valid values: default, full, or a non-negative integer.")`). No second copy.
- `--hide`/`--show` section and column names: one resolver
  (`resolve_visibility_name`) over two alias tables, and an error that derives
  its three lists from the tables. Converged for sections and columns; the
  metric-name arm is F1.1, F1.2 and F1.4.

### Open issues touching this item as a whole

Read from the issue bodies captured on 2026-09-26.

- **#605** (numeric, byte and duration inputs accept a value with a unit,
  `next-up`): asks for one input-unit pattern across every threshold option and
  for that pattern to be documented for future work. It adds readers to the time
  ladder and to the byte vocabulary; F1.12 is the state of the byte vocabulary it
  would build on, and F1.13 the help-row copies it would multiply. Its "standard
  architecture pattern" deliverable overlaps this audit's patterns file.
- **#581** (deprecate the omit options `--discard` duplicates): after it, `-d` is
  the only way to switch a metric off, so the metric-name arm of
  `resolve_discard_names` (F1.1, F1.2, F1.3) becomes the surface every user
  meets.
- **#601** (deprecate the options `--hide` and `--show` duplicate): after it,
  `--hide` is the only column surface, so F1.4's name set is the one that
  remains.
- **#582** (name what to expose, discard or mask by a regular expression,
  `next-up`): rewrites the spec grammar of `-x`, `-d` and `-m`; F1.1, F1.2, F1.3,
  F1.4, F1.10 and F1.11 all sit in the three resolvers it would change. Its
  record already fixes one shared grammar across the three verbs, which is the
  direction the convergence would take; a convergence landing first gives it one
  resolver to extend, landing second it reads this item.
- **#514** (count metric capture and display become explicit, `next-up`): touches
  every copy of the built-in set (F1.7) and the `count_*` arm of `-so` (F1.8).
- **#536**, **#537** (thread name and remote host as attributes, `next-up`): each
  adds a field name to the vocabulary F1.11 audits.
- **#60** (configurable metric visibility, on hold) and **#387** (user-defined
  YAML formats): would make the metric set and the format list data; informational.
- **#17** (auto-detect input latency units): time units only, already served by
  the ladder; no finding depends on it.

### Site inventory

Every site the four angles reached, including those that produced no finding.
Sites the scoping pass recorded are kept as recorded and marked *(scoping)*;
sites the audit added are marked *(audit)*.

- `builtin_metric_name` :: `return 'duration' if $lc eq 'duration' || $lc eq 'time';` :: METRIC: the reference parse-time canonicaliser for built-in metric names; case-insensitive; `time` aliases duration. *(scoping)*
- `resolve_metric_operand` :: `return { kind => 'udm', config => $match } if $match;` :: METRIC: full resolution, built-in then user-defined through `udm_config_by_name`. Called by the `-hm` and `-hg` settlement only. *(scoping)*
- `udm_config_by_name` :: `($match) = grep { $_->{base_name} eq $token } @udm_configs if !$match;` :: METRIC: name then base name; no token-key arm. *(scoping)*
- `available_metric_names` :: `return (qw(duration bytes count), map { $_->{name} } @udm_configs);` :: METRIC: the error vocabulary; its own copy of the built-in list; no `time`. *(scoping)*
- `handle_histogram_option` :: `my $has_valid_metric = grep { defined builtin_metric_name($_) } @parts;` :: METRIC: `-hg` parse time; silent pushback when no part is a built-in and no `-udm` was given. *(scoping)*
- `handle_histogram_option` :: `(valid: duration, time, bytes, count)` :: METRIC: the `-hg` unknown-token warning, never printed (F1.17). *(scoping)*
- `adapt_to_command_line_options` :: `local $SIG{__WARN__} = sub { push @getopt_warnings, $_[0]; };` :: the warning capture around GetOptions that swallows F1.17's warning on a successful parse. *(audit)*
- `adapt_to_command_line_options` :: `@in_files = grep { -f $_ } @in_files;` :: the file-list filter that silently drops a pushed-back operand that is not a file (F1.6). *(audit)*
- `adapt_to_command_line_options` :: `is not a built-in metric (duration|bytes|count) and no -udm configs are defined` :: METRIC: `-hm` parse time; pushback with a warning. *(scoping)*
- `adapt_to_command_line_options` :: `warn "-g value '$group_similar_sensitivity' is not numeric; treating as positional argument` :: `-g` pushback with a warning. *(audit)*
- `adapt_to_command_line_options` :: `if ($memory_usage_operand eq 'debug') {` :: `-mem` operand: `debug` or a silent pushback. *(audit)*
- `adapt_to_command_line_options` :: `die "Error: Unknown heatmap metric '$heatmap_metric'. Available: " . join(', ', available_metric_names()) . "\n";` :: METRIC: `-hm` settlement through `resolve_metric_operand`, gated on `!exists $heatmap_metric_map{...}`. *(scoping)*
- `adapt_to_command_line_options` :: `die "Error: Unknown histogram metric '$metric'. Available: " . join(', ', available_metric_names()) . "\n";` :: METRIC: `-hg` settlement. *(scoping)*
- `(file scope, GLOBALS)` :: `my %heatmap_metric_map = (` :: METRIC: literal built-in keys; also the "already a built-in" test before `-hm` is resolved as user-defined. *(scoping)*
- `(file scope, GLOBALS)` :: `my @graph_columns = qw( duration bytes count );` :: METRIC: another literal copy, extended by `parse_udm_configs`. *(scoping)*
- `(file scope, GLOBALS)` :: `my @visibility_columns = qw( legend occurrences duration bytes count session user classification stats values rate );` :: COLUMN and METRIC: the `--hide`/`--show` column list, a literal copy of the metric set. *(scoping)*
- `(file scope, GLOBALS)` :: `my %column_aliases = ( leg => 'legend', occ => 'occurrences', dur => 'duration', byt => 'bytes', cnt => 'count',` :: COLUMN: the fixed aliases; `dur`, no `time`. *(audit)*
- `(file scope, GLOBALS)` :: `my %section_aliases = ( tl => 'timeline', hg => 'histogram', opt => 'options', msg => 'messages',` :: SECTION: the fixed section aliases. *(audit)*
- `resolve_visibility_name` :: `my $column = $column_aliases{$name} // $name;` :: METRIC and COLUMN: lowercased section, then column, then `udm_config_by_name`; does not call `builtin_metric_name`. *(scoping)*
- `apply_output_visibility` :: `Unknown section or column '" . trim($given) . "' for --$verb. Sections: $sections; columns: $columns$metrics` :: the `--hide`/`--show` error, three lists derived from the tables. *(scoping)*
- `resolve_expose_names` :: `elsif ( $name eq 'duration' || $name eq 'durationMs' || $name eq 'durationMS' ) { $expose_metric{duration} = 1 }` :: METRIC and FIELD: `-x` exact-case literals; fields thread, session, user, query-string. *(scoping)*
- `resolve_expose_names` :: `// ( grep { defined $_->{token_key} && $_->{token_key} eq $name } @udm_configs )[0];` :: METRIC: the token-key fallback (`grep -F` also finds the copy in `resolve_discard_names`). *(scoping)*
- `resolve_discard_names` :: `elsif ( $name eq 'duration' || $name eq 'durationMs' || $name eq 'durationMS' ) { $omit_durations = 1 }` :: METRIC, FIELD and IDENTIFIER: `-d` repeats the `-x` literals, adds `object`, and matches the identifiers by literal. *(scoping)*
- `resolve_discard_names` :: `$discard_any_field = ( grep { $discard_field{$_} } qw( thread session user object ) ) ? 1 : 0;` :: FIELD: the second copy of the `-d` field set in the same sub. *(scoping)*
- `apply_discard_precedence` :: `delete $expose_metric{duration} if $name eq 'duration' || $name eq 'durationMs' || $name eq 'durationMS';` :: METRIC: the third copy of the duration spellings. *(scoping)*
- `discard_key_sub` :: `return [ qr/\b${escaped_key}\s*[=:]\s*${value}[&?\s]|[&?\s]?\b${escaped_key}\s*[=:]\s*${value}$/, '' ];` :: LINE KEY: the fallback every unrecognised `-d` name takes, case-sensitive on the key. *(audit)*
- `resolve_mask_names` :: `elsif ( exists $mask_patterns{$name} )       { $wanted{$name} = 1 }` :: IDENTIFIER: `-m` resolves through the table plus the `ip` case. *(audit)*
- `resolve_mask_names` :: `print_usage("Unknown mask name '$name' for -m. Valid values: uuid, ip, ipv4, ipv6");` :: IDENTIFIER: the `-m` error, a literal. *(scoping)*
- `(file scope, before resolve_mask_names)` :: `my @mask_order = qw(uuid ipv6 ipv4);` :: IDENTIFIER: the table order; the `%mask_patterns` comment above `my %mask_patterns;` claims every option resolves through it. *(scoping)*
- `discard_identifier_sub` :: `my $pattern = $mask_patterns{$name}[0];` :: IDENTIFIER: `-d` reads the pattern from the table; only the name match is literal. *(scoping)*
- `_validate_dm` :: `return if defined $value && ($value eq 'raw' || $value eq 'bin');` :: DATA MODEL: the one validator and error form. *(scoping)*
- `resolve_data_model` :: `return $data_model_omnibus if defined $data_model_omnibus;` :: DATA MODEL: per-surface flag, then omnibus, then undef; fourteen callers apply the default. *(scoping)*
- `read_and_process_logs` :: `$heatmap_capture_mode       = choose_data_model('heatmap')       // 'bin';` :: DATA MODEL: one of the fourteen call sites with an inline default (the others in `emit_percentile_algorithm_verbose`, `emit_statistics_demand_verbose`, `calculate_heatmap_buckets`, `calculate_histogram_buckets`, `calculate_all_statistics` three times). *(scoping)*
- `(file scope, GLOBALS)` :: `my %time_unit_by_spelling = map { my $step = $_; map { $_ => $step->{token} } @{ $step->{spellings} } } @time_unit_ladder;` :: TIME UNIT: the ladder and its views (`%time_unit_step`, `$time_unit_list`, `%rate_multiplier`, `%rate_suffix`, `%rate_csv_suffix`). *(scoping)*
- `time_unit_canonical` :: `return $time_unit_by_spelling{ lc $spelling };` :: TIME UNIT: the one resolver; callers `-du`, `-ru`, `-bs`, the `-udm` unit slot. *(scoping)*
- `adapt_to_command_line_options` :: `print_usage("Invalid rate unit '$rate_unit'. Valid values: $time_unit_list")` :: TIME UNIT: the `-ru` error; `-du` (`Invalid duration unit`) and `-bs` (`with a unit of $time_unit_list`) share the derived list. *(scoping)*
- `parse_udm_configs` :: `my %byte_units = map { $_ => 1 } qw( B b kB KB MB GB TB KiB MiB GiB TiB );` :: BYTE UNITS: the unit-slot table; `%si_units`, `%byte_unit_canonical` local to the sub; an unknown unit warns without a list. *(scoping)*
- `parse_udm_configs` :: `my %byte_unit_canonical = map { lc($_) => $_ } keys %byte_units;` :: BYTE UNITS: the case-fold map that collapses `kB`/`KB` and `B`/`b` (F1.12). *(audit)*
- `parse_udm_configs` :: `if (exists $si_units{$unit}) {` :: SI UNITS: checked case-sensitively before the fold, so `K` is a number times 1000 here and never reaches `convert_bytes`. *(audit)*
- `parse_udm_configs` :: `my %si_units = ( 'k' => 1000, 'K' => 1000, 'M' => 1000**2, 'G' => 1000**3, 'T' => 1000**4 );` :: SI UNITS: the parse-side multiplier map. *(scoping)*
- `convert_bytes` :: `'KiB' => 1024,` :: BYTE UNITS: the second table (`kB` 1000, `KB` and `K` 1024); `grep -F` also finds the line in `format_bytes`. Callers: `parse_udm_configs`, `emit_index_readback_verbose`, the `gc_heap_delta` transform in `%format_transform_code`. *(scoping)*
- `print_help` :: `Time: ns, us, ms, s, m, h, d, w, month, year. Bytes: B, kB, KB, MB, GB, TB, KiB, MiB, GiB, TiB. SI: k/K, M, G, T.` :: UNITS (help): the `-udm` unit row, all three vocabularies as literals. *(scoping)*
- `print_help` :: `(ns, us, ms, s, m, h, d, w, month, year)` :: TIME UNIT (help): the `-du` row literal; `-ru` and `-bs` carry the same. *(audit)*
- `parse_udm_configs` :: `my %function_names = map { $_ => 1 } qw( sum min max mean avg count distinct dcount unique ratio rate drate delta idelta );` :: AGGREGATE NAME: the `-udm` function slot, with its own `avg` alias. *(scoping)*
- `adapt_to_command_line_options` :: `do { print_usage( "invalid sort type used" ); exit 1; } unless grep { lc $_ eq lc $sort_type } qw(` :: SORT FIELD: the allow-list; error names nothing. *(scoping)*
- `adapt_to_command_line_options` :: `if( $sort_type =~ /^(?:duration|time)$/i ) {` :: SORT FIELD: the ladder, every name again, with its own `duration|time` and `bytes|size` aliases. *(scoping)*
- `adapt_to_command_line_options` :: `$sort_type =~ s/^duration_//i unless $sort_type =~ /^duration$/i;` :: SORT FIELD: the `duration_` prefix strip, `-so` only. *(scoping)*
- `sort_key_metric_family` :: `return 'bytes'       if $key eq 'total_bytes' || $key =~ /^bytes_/;` :: SORT FIELD and METRIC: resolved key to family by prefix; `apply_parse_time_sort_gate` keys `%killer` by the same families. *(scoping)*
- `(file scope, --explain section)` :: `my %explain_aliases = (` :: STATISTIC NAME: `--explain` aliases, maintained apart from `-so` (F1.19). *(scoping)*
- `resolve_explain_topic` :: `$key = $explain_aliases{$key} if exists $explain_aliases{$key};` :: STATISTIC NAME: the one reader of the alias table. *(audit)*
- `(file scope, GLOBALS)` :: `my @duration_family_stats = qw( min mean max std_dev p1 p5 p10 p25 p50 p75 iqr p90 p95 p99 p999 p9999 p99999 cv skewness kurtosis bimodality_coef );` :: STATISTIC NAME: the CSV column order; the `-so` allow-list does not read it. *(scoping)*
- `print_help` :: `A bare metric name means its total: bytes, duration (alias time), count. Aggregates:` :: SORT FIELD (help): the third copy, incomplete. *(scoping)*
- `apply_format_pin` :: `print_usage("Unknown log format '$log_format_pin' for -lf. Known formats: " . join(', ', sort keys %listed));` :: FORMAT NAME: registry-derived list. *(scoping)*
- `print_help_formats` :: `next if $spec->{verification};   # a verification-only producer is not a format a user reads` :: FORMAT NAME: the same filter written again, in the "Other formats" loop only. *(scoping)*
- `_validate_profile` :: `the modes are day, week, workday, workweek, weekday,` :: PROFILE MODE: validates against `%profile_modes`; error a literal that overstates the table (F1.18). *(scoping)*
- `(file scope, GLOBALS)` :: `my %profile_modes = (` :: PROFILE MODE: fifteen keys; `day` has no `-alt` twin. *(audit)*
- `dispatch_informational_options` :: `print_usage("unknown --help topic '$help_topic' (try: statistics, formats, profile)");` :: HELP TOPIC: if/elsif chain with a literal list. *(scoping)*
- `print_help` :: `Naming a topic shows that topic's index: 'statistics'` :: HELP TOPIC (help): the row names two of the three topics. *(audit)*
- `dispatch_informational_options` :: `print_usage("unknown --explain topic '$explain_topic' (try: 'ltl --explain' for the list)");` :: EXPLAIN TOPIC: the error points at the registry rather than listing it. *(audit)*
- `adapt_to_command_line_options` :: `if (exists $verbose_section_registry{$name}) {` :: VERBOSE SECTION: one registry for validation and `-V list`. *(scoping)*
- `adapt_to_command_line_options` :: `warn "Unknown -V section: $name. Known sections: "` :: VERBOSE SECTION: the error derives its list from `@verbose_section_order`. *(scoping)*
- `adapt_to_command_line_options` :: `print_usage("Invalid --csv-precision value '$csv_precision'. Valid values: default, full, or a non-negative integer.")` :: CSV PRECISION MODE: single option, literal allow-list and error in one place. *(scoping)*
- `write_aggregate_export` :: `(qw(duration bytes count), sort grep { !/^(?:duration|bytes|count)$/ } keys %histogram_stats);` :: METRIC (internal): consumers of resolved state that carry the literal set (`read_and_process_logs`, `calculate_histogram_buckets_exact`, `finalize_histogram_unified`, `calculate_histogram_layout`, `normalize_data_for_output`, `format_entry_block_src` :: `if    ($f eq 'bytes' || $f eq 'duration') { push @dflt_undef, "\$$f"; }`). Not option parsing; out of scope for this item, in scope for F1.7's target table. *(scoping)*

### Verification notes

Carried from the scoping pass (sites reported 39, confirmed 40, refuted 0, added
by the verifier 8), plus the audit's own:

- Every snippet cited in the findings table and the inventory was located inside
  the named sub by resolving each line to its preceding `sub` header on
  2026-09-26; the new citations (`local $SIG{__WARN__}`, the file-list filter, the
  `-g` and `-mem` pushbacks, `resolve_explain_topic`, the two `parse_udm_configs`
  lines, `_validate_profile`, the `--help` row) all resolve to the sub named.
- The scoping pass's line hints are not carried into this section; the
  acceptance check is `grep -F` of the snippet within the sub's range.
- The scoping pass's F1.5 said the `-hg` warning "includes time and never names
  user-defined metrics"; the audit found it never prints at all (F1.17), which
  supersedes that reading.
- The scoping pass's F1.12 said `K` is 1000 in one table and 1024 in another; the
  audit found the 1024 reading unreachable from the option (the SI table is
  consulted first) and found the `kB`/`KB` collapse, which is the user-visible
  defect.

### Questions for the findings discussion, with the evidence bearing on each

- *Should `-x time` and `-d time` mean the duration metric or a `time=` key?*
  Fixture B shows the key reading is live: `-x time` appends ` time=3` from a
  query string. A log family that writes `time=` as a key exists in the corpus
  (the ThingWorx application logs write `durationMS=`; whether any writes bare
  `time=` was not checked). The #327 contract and the 566/567 lists disagree.
- *Are `durationMs`/`durationMS` part of the shared vocabulary?* They are key
  spellings a format writes; `-x` and `-d` accept them because those options read
  keys. Extending them to `-hm`/`-hg` costs nothing; leaving them out means
  F1.3's warning on `-hm durationMs` stands.
- *Does the token-key fallback extend to `-hm`, `-hg` and `--hide`?* Fixture D
  shows `-x elapsed` and `-x lat` are equivalent today; `--hide elapsed` is an
  error. 597 D24 names the column heading as the `--hide` name, which is the
  metric name, not the key.
- *Is `object` on `-d` but not `-x` deliberate?* 567 D9 lists it for `-d`; 566 D6
  does not list it for `-x`; D15 says the two accept the same names. Fixture B
  shows the two readings of the word.
- *Should `-so` resolve bare metric words through `builtin_metric_name()`?* It
  re-encodes `duration|time` and `bytes|size`; `size` is accepted nowhere else.
  Converging removes `size` unless `builtin_metric_name()` gains it.
- *Is F1.12 a bug of its own?* It is nondeterministic and user-visible (a
  threshold or a displayed value off by 2.4 percent between runs of one
  command); the audit's recommendation is that it is filed and fixed ahead of
  any convergence, on the one-ladder shape, and that #605 is sequenced after it.
- *Are help-row literals in scope?* `tests/validate-help-content.sh` checks the
  `-udm` function list against the code (scenario G) and nothing for unit lists
  or the `-so` vocabulary; F1.8 shows the `-so` row already disagrees with the
  code, so a harness scenario would fail today.
- *New: is F1.17 a bug of its own?* A validation message that cannot print is a
  defect independent of any convergence; the fix is to move the check to
  settlement, where its `-hm` twin already runs.


---

## Item 2: Unit and value formatting

**State: audit complete (2026-09-26).** The four angles were run on the issue
branch; every *diverged* candidate carries two strings produced by a run, not by
reading; two candidates the scoping pass raised were reclassified on the evidence
(the rate-suffix divergence is unreachable, the per-unit decimals tables produce
no observable difference on integer source values); three findings were added (a
formatted string stored in the message store, which an open issue already records;
the index file's own timestamp pattern; the double trailing-zero strip inside one
formatter). Captures are under the session scratchpad (`342/runs2/`), one file
per run.

### Fixtures used by the confirmation runs

- **A**: `tests/fixtures/tomcat-access-single-sample-keys.txt` (twelve access-log
  lines; two carry a duration of zero).
- **N**: `tests/fixtures/numeric-highlight-boundary.txt` (nineteen application-log
  lines carrying `durationMS=`, `bytes=` and `count=` keys, millisecond
  timestamps).
- **G**: `tests/fixtures/grouping-signed-downloads.txt` read with `-du us`;
  **B**: `tests/fixtures/bucket-size-units.txt` read with `-du ns`.
- Scratch fixtures, each in the Tomcat access-log shape unless said otherwise,
  TEST-NET addresses: **bytes-edge** (four lines, one per minute, with response
  sizes 999, 1000, 1023 and 1024); **cv-half** (three lines of one path with
  durations 10, 20 and 30 ms, whose sample coefficient of variation is exactly
  0.5); **zeros** (two lines with duration 0); **count-single-1500** (the first
  line of N with `count=1500`); **ms-frac** (the first three lines of N with
  fractional timestamps `.123`, `.456`, `.789`); **unclassified-1200** (1,200
  lines in the classification-verification shape, one per second, each carrying
  a duration that neither the success nor the failure rule of that format
  matches, read with `-lf classification_verification`).

### Search angles run

1. **By formatter.** Every call of the thirteen value and timestamp formatters
   and the five helpers, with its enclosing sub and arguments: 212 call lines,
   condensed to 78 distinct (sub, call shape) pairs. The pairs for the same value
   class with different arguments are the findings; the full list is in the
   captures (`i2-angle1-callers.txt`).
2. **By idiom.** 293 `sprintf` and `printf` lines, classified by enclosing sub:
   46 in `pipeline_finalize`, 41 in `print_verbose_output`, 20 in the
   `emit_*_verbose` subs and 4 in `memory_debug_*` are machine-read diagnostics
   (deliberate raw); 13 in the `explain_*` subs are prose layout; 21 in the
   formatters themselves; 8 in `write_index_file`; the remainder are column
   padding (`%-*s`, `%6s`) in the four table renderers, which carry no numeric
   formatting, plus the seven presentation restatements listed in the findings.
   Trailing-zero strips: six idioms in five formatters plus the dead
   `normalize`. Roundings by `int(... + 0.5)`: 15, all geometry (bucket keys,
   padding, glyph indices, tick counts) except the bytes mean in
   `print_message_summary` (item 4) and the detection sample's mean line length.
   `strftime`: eight sites, two inside the timestamp formatters, six outside
   (findings F2.11 and F2.16).
3. **By surface.** Each rendered surface walked for every number it prints and
   the path it took: the table in *Surfaces walked* below.
4. **By unit table.** Every hash keyed by a unit spelling or a resolved unit:
   `%duration_display_decimals` (file scope beside `format_duration`),
   `%decimals_by_unit` (inside `adapt_to_command_line_options`), the two byte
   maps (`convert_bytes`, `format_bytes`), the number ladder in `format_number`,
   `%byte_units` and `%si_units` (item 1), and the time-unit ladder's views.
   Against `features/524-bucket-size-unit.md` D1, the two decimals tables and
   the two byte maps are private tables; the number ladder is a private table
   for a vocabulary no option takes.

### Surfaces walked

| Surface | Numbers printed | Path |
|---|---|---|
| Timeline row | duration total, bytes total, count total, user-defined value, occurrences per category, rates, success and failure percentages, P50/P95/P99/P999, CV | `format_duration_total` (tier by width), `format_bytes`, `format_number` (medium, space, 2 decimals), `format_number` (medium, space, per-metric decimals; rate suffix appended), `format_number` medium, `format_percentage` significant 3, `format_duration` (rounded, width 6), `format_cv_display` |
| Timeline legend | category totals, rate totals | `format_number` medium; `legend_category_total` (short unless precise values) |
| Heatmap header and footer | scale minimum and maximum | `format_heatmap_value` (duration through `format_time` directly; bytes `format_bytes`; count `format_number` medium, 1 decimal, no space) |
| Histogram | y-axis count ticks, y-axis percent ticks, x-axis value labels, percentile markers, legend values, dimensions line | `format_number` (medium, 0 decimals); inline `sprintf(" %3d%%")` twice; `format_heatmap_value` for the rest |
| Messages table | occurrences, min, P50, P999, CV, total duration | raw `sprintf("%Ns")`; `format_duration` with the column width; `format_cv_display`; the string stored in the message store by `calculate_all_statistics` |
| Thread-pool table | occurrences | raw `sprintf("%Ns")` |
| Summary table | lines read, highlighted, included; observation start and end; category totals and shares; stage timings; total time; peak memory; memory breakdown sizes and percentages; per-file rows | raw `sprintf($table_format, ...)`; `format_observation_timestamp`; raw count plus `format_percentage` in `share_row_text`; `format_time(..., 's', 'medium', ' ')`; `format_bytes($x, 'B')` and `format_bytes($x, 'B', 0)`; `format_percentage` integer width 5 |
| Notices | counts and one percentage | `format_number` medium in three read-loop notices and `bin_consolidation_notice`; raw counts in the unclassified warning and the CSV skipped-rows warning; inline `sprintf('%.1f')` for the unclassified percentage |
| Progress line | line counts, rate, percentages | `format_number` medium; `format_percentage` integer width 3 floor |
| STATS and MESSAGES CSVs | every numeric cell; `duration_nice`, `bytes_nice` | `format_csv_value` by column family; `format_duration_total` medium space and `format_bytes` for the nice twins |
| Run index | means, read rate, elapsed, peak memory, timestamps | inline `sprintf("%.2f")` six times, `"%.0f"`, `"%.3f"`, raw; `format_epoch_iso`; inline `strftime` for now and file mtime |
| Aggregate export | every measurement; total time; peak memory; observation span and bounds | `aggregate_number` (raw by decision); `format_time` and `format_bytes` with the summary table's exact arguments; `format_time($span, 's', 'long', ' ', 3)`; `format_observation_timestamp` |
| `--explain` | worked figures in prose | inline `sprintf` in the `explain_*` subs (prose, not a value surface) |

### Findings

| # | Value class | Site A | Site B (further copies in the note) | What each does | Observed divergence | Target | Contract and owner | Category | Related open issues |
|---|---|---|---|---|---|---|---|---|---|
| **F2.1** | A duration of zero | `format_duration_total` :: `return format_time($value, 'ms', $format, $space) if $value != 0;` | `format_heatmap_value` :: `format_time($value, 'ms')` | A renders zero in the resolved source unit; B calls the ladder scaler directly, and the ladder's lowest step is the nanosecond | Fixture zeros, `-hm duration -bs 1`: the heatmap header reads `0ns heatmap [duration] 0ns`. Fixture A, `-bs 1`: the timeline's zero bucket reads `0 milliseconds` and its latency cells `0ms`. One value, two units | `format_heatmap_value` routes durations through `format_duration_total` (or `format_time` gains the zero rule) | `features/444-access-log-format-family-and-user-surface.md` R17 / D16 (a zero total renders in the source unit); `features/524-bucket-size-unit.md` records the `0ns` as a consequence, not a decision | **diverged** | none |
| **F2.2** | A count | `print_bar_graph` :: `format_number( $log_stats{$bucket}{$key}, 'medium', ' ', 2)` | `format_heatmap_value` :: `format_number($value, 'medium')` and `render_histogram_row` :: `my $count_str = format_number($count_val, 'medium', undef, 0);` | The same formatter called with three argument sets: space and two decimals, no space and one decimal, no space and no decimals | Fixture count-single-1500: the timeline count column reads `1.50 k`; the heatmap header reads `1.5k heatmap [count] 1.5k`; the histogram x-axis reads `1.5k` and its y-axis ticks are whole numbers. Three spellings of 1500 | One count-rendering call shape held with the value class (a `format_count` wrapper, or `format_number` given a surface tier rather than raw arguments) | `features/501-legend-category-total-shortening.md` D1 and D2 (three tiers by surface) name the tier, not the decimals or the space | **diverged** | #514 (count metric capture and display become explicit): every count surface changes hands there; it should land on one call shape |
| **F2.7** | Trailing zeros | `format_cv_display` :: `return sprintf('%.2f', $cv);` and `format_number` :: `$formatted_value =~ s/\.0+$//;` | `format_csv_value` :: `$formatted =~ s/\.0+$//;`, `format_percentage` :: `$t =~ s/0+$//;`, `format_time` :: `$formatted_value =~ s/0+$//;` and, four lines later in the same sub, `$formatted_value =~ s/\.0+(?=\s\|$)//;`, `format_bytes` :: `$formatted_value =~ s/\.0+(?=\s\|$)//;`, and the dead `normalize` :: `sub normalize { $_[0] =~ s/\.0+$//r }` | The CV cell never strips; `format_number` strips only an all-zero fraction, so a two-decimal call keeps `1.50`; the CSV, percentage and duration formatters strip partial zeros; `format_time` strips twice with two idioms | Fixture cv-half: the messages table CV cell reads `0.50`, the MESSAGES CSV `duration_cv` cell reads `0.5`. Fixture count-single-1500: the timeline count reads `1.50 k` where the heatmap reads `1.5k` for the same value | One strip helper (the existing `normalize`, made to strip partial zeros) called by every formatter; `format_cv_display` and the two-decimal count call route through it | `docs/percentage-presentation.md` and `features/503-yaml-aggregate-export.md` D13 (trailing zeros stripped as every formatter does); `features/448-category-summary-share-and-bar.md` N1 | **diverged** | none |
| **F2.6** | Bytes near a unit boundary | `format_bytes` :: `if( length( $bytes_int ) >= length( $units{$u} ) ) {` | `format_number` :: `if ($value >= $units{$u}) {` (the value-based climb the other ladders use) and `convert_bytes` :: `'kB' => 1000,` (the parse-side map, with `KB` 1024) | A promotes by the digit count of the integer part, so 1000 to 1023 bytes promote to the kibibyte; B promotes by value | Fixture bytes-edge, `-o -bs 1`: the STATS `bytes_nice` cells read `999 B`, `1 KiB`, `1 KiB`, `1 KiB` for 999, 1000, 1023 and 1024 bytes. Three different byte counts render as one string, and 1000 bytes reads as a kibibyte | One byte ladder (item 1, F1.12's target) with a value-based climb shared with `format_number`; the `TO DO` comment in `format_bytes` says as much | `features/user-defined-metrics.md` (bytes display through `format_bytes`); `features/heatmap.md` § `format_bytes()` Float Handling Bug records the integer-length workaround | **diverged** | #605 (inputs accept a unit) adds parse-side readers of the byte vocabulary; it and this finding share the one-ladder target |
| **F2.11** | Milliseconds of a timestamp | `format_observation_timestamp` :: `$str .= sprintf ".%03d", ($epoch - int($epoch)) * 1000 if $print_milliseconds;` | `format_epoch_iso` :: `my $ms = int(($epoch - $int_part) * 1000 + 0.5);` | A truncates the product of a binary fraction, so `.123` can become `122.999...` and print as `.122`; B rounds | Fixture ms-frac, `-ms -bs 1000`: the summary reads `between 2026-01-26 10:00:01.122 and ...`; the run index's `first_timestamp` reads `2026-01-26T10:00:01.123` for the same line | One millisecond derivation (rounded) in a helper both formatters call, or `format_bucket_timestamp`'s integer-millisecond key path used for both | none recorded; `features/524-bucket-size-unit.md` D4 (bucket width and timestamp precision are separate) is adjacent | **diverged** | #525 (a single timestamp-precision option, nanosecond included) would add a fourth precision to every timestamp formatter; #154 (fixed timezone offset for rendering) would touch every rendered timestamp and should land on one formatter; #155 (normalise offsets to UTC) is the parse side |
| **F2.13** | A mean in the run index | `write_index_file` :: `my $dur_avg   = $fd->{duration_occurrences} > 0 ? sprintf("%.2f", $fd->{duration_sum} / $fd->{duration_occurrences}) : '-';` (five more `"%.2f"` means, one `"%.0f"` rate, one `"%.3f"` elapsed) | `format_csv_value` :: `my $formatted = sprintf("%.${decimals}f", $value);` | A fixes two decimals and writes `-` for no data; B applies the `-cp` family decimals and leaves an empty cell | Fixture A, `-o -cp 0`: the run index's `duration_mean` reads `128.75`; the STATS CSV's `duration_mean` for the same file's single bucket reads `129` | The index means through `format_csv_value` with the same families, or a recorded decision that the index is outside the `-cp` contract | `features/432-metric-aggregate-naming-parity.md` D7 (the run index follows the same naming convention) says nothing about precision; `features/561-retained-durations-as-numbers.md` covers the two CSVs only | **diverged** | none |
| **F2.8 / F2.9** | A count and a percentage in a notice | `emit_classification_percentage_notices` :: `my $leak_pct = $r->{included} ? sprintf('%.1f', $r->{unclassified} / $r->{included} * 100) : '0.0';` and the raw `$r->{unclassified}` on the same line; `read_and_process_logs` :: `print STDERR "Warning: $in_file: skipped $csv_skipped_timestamp_rows CSV rows with unparseable timestamps\n";` | `read_and_process_logs` :: `print STDERR "Note: " . format_number($count, 'medium')` (and two sibling notices, and `bin_consolidation_notice`); `share_row_text` :: `my $share = format_percentage( $count / $denominator * 100,` | A prints a raw count and an inline one-decimal percentage on a user-facing warning; B renders counts through the medium tier and percentages through the one formatter | Fixture unclassified-1200: the warning reads `Warning: 1200 included line(s) (100.0%) matched neither ...` while the same run's legend renders the same 1,200 lines as `INFO: 1.2k` and `share_row_text` would render the share as `100%` | Counts in notices through `format_number(..., 'medium')` as the sibling notices do; the percentage through `format_percentage` | `docs/percentage-presentation.md` (every presented percentage through the formatter; the `-V` copy is exempt, the warning is not named); no rule for counts in notices | **diverged** | #412 (notices surface) inventories every ad-hoc notice for migration and is where one rendering rule for notice numbers would be set; #454 (notice that statistics describe a filtered subset) adds a notice carrying counts |
| **F2.10** | Occurrences | `print_message_summary` :: `sprintf( "%$col_width{2}s", $occurrences )` (twice; `print_threadpool_summary` once; `print_summary_table` :: `push @summary_table, sprintf( $table_format, "LINES READ", $total_lines_read );` and its two siblings) | `print_bar_graph` :: `format_number( $occurrences, 'medium' )` and `legend_category_total` :: `return $precise_values ? $occurrences : format_number($occurrences, 'short');` | The tables print the integer; the legend shortens it | Fixture unclassified-1200: the messages table row reads `same message 1200 ...` and the summary `LINES READ 1200`, the legend `INFO: 1.2k`, in one run | Either a recorded decision that tables and the summary print exact integers (the `-ov` precise-values switch already exists for the legend) or the tables take the tier | undocumented either way | **diverged** | none |
| **F2.15** | The message total duration | `calculate_all_statistics` :: `$log_messages{$category}{$log_key}{total_duration} = format_duration_total( $aggregated_data->{total_duration}, 'medium', 'space' ) if defined $aggregated_data->{total_duration};` | `print_message_summary` :: `sprintf( "%$col_width{7}s", defined $total_duration ? $total_duration : "" )` and the MESSAGES CSV `duration_nice` cell, both reading the stored string | The statistics phase formats a value and stores the string where every other statistic is stored as a number; the renderers print it verbatim | Not a divergence between two strings (one path); a divergence from the storage-stays-precise pattern every other statistic follows, so a future renderer that wants a different tier cannot have one | Store the number; format at the two emit sites (the open issue's own acceptance criteria) | `features/561-retained-durations-as-numbers.md` (storage stays precise) | **latent** | #273 (collapse `total_duration` / `total_duration_num`: store precise, format at the rendering boundary) records this exact site and its fix; this finding adds nothing to it beyond the pointer |
| **F2.3** | A rate-type user-defined metric's unit suffix | `print_bar_graph` :: `$trend_value .= $rate_suffix{$rate_unit}` | `format_heatmap_value` :: `format_number($value, 'medium')` (the user-defined branch appends nothing) | The scoping pass read this as a divergence; the heatmap and histogram refuse counting aggregations before the branch is reached | Fixture N, `-udm 'x::rate:count' -hm x`: `Warning: Heatmap metric 'x' uses counting aggregation 'rate' - heatmap disabled`. The B branch cannot see a rate metric | none needed today; recorded so the branch is not read as live | `features/user-defined-metrics.md` (counting aggregations carry no per-line distribution) | **latent** (unreachable) | none |
| **F2.4** | Metric-kind dispatch | `format_heatmap_value` :: `return $ut eq 'time'  ? format_time($value, 'ms') :` (three times inside the sub) | `print_bar_graph` :: `my $time_format = $col_w >= 15 ? 'long' : ($col_w >= 10 ? 'medium' : 'short');` (the display branch; the width-to-tier rule is written again as `my $fmt = $col_w >= 15 ? 'long' : ($col_w >= 10 ? 'medium' : 'short');`) and the STATS CSV builder in the same sub | Five copies of "which formatter for this metric kind", two of "which tier for this width" | Identical today | One `format_metric_value($kind, $value, $tier)` that every surface calls, holding the tier rule | none | **latent** | #514 changes the count arm of every copy |
| **F2.5** | Per-source-unit decimals | `(file scope, between format_time and format_duration_total)` :: `my %duration_display_decimals = ( ns => 6, us => 3, ms => 0, s => 0 );` | `adapt_to_command_line_options` :: `my %decimals_by_unit = ( ns => 9, us => 6, ms => 0, s => 0 );` | Two private tables keyed by the resolved duration unit, covering four of the ladder's ten tokens and defaulting to zero; the display table rounds to source resolution, the CSV table allows three more decimals | No observable difference on integer source values: fixture G under `-du us` shows `13.6ms` in the table (the width shed of `format_duration`) and `13.633` in the CSV, both the exact value; fixture B under `-du ns` shows `500ns` and `0.0005`. A source unit outside the four tokens (`-du m`) gets zero decimals in both | Both derived from the ladder (a `decimals` field per step), per #524 D1 | `features/524-bucket-size-unit.md` D1 (no sub keeps a unit table of its own) | **latent** | #605 (units on inputs) is the next reader of the ladder |
| **F2.12** | Fitting a value to a width | `format_duration` :: `if (defined $max_chars && length($out) > $max_chars && $out =~ /\.\d/)` | `format_percentage` :: `while ( length($figure) > $inner_width && $decimals > 0 )` and `format_cv_display` :: `return sprintf('%.1f', $cv) if $cv >= 10;` | Shed one digit once; loop decimals down; fix decimals by magnitude | Identical in effect on today's widths; three mechanisms to reach for | One fit-to-width rule in a helper the three formatters call | none | **latent** | #497 (rows overflow the terminal width) and #498 (messages-table headings degrade) are open on the same table these three formatters fill; a width rule set there should be the one rule |
| **F2.16** | ISO timestamps outside the formatters | `write_index_file` :: `my $now_iso = strftime("%Y-%m-%dT%H:%M:%S", gmtime());` (and `my $mtime_iso = strftime("%Y-%m-%dT%H:%M:%S", gmtime($fd->{file_mtime}));`, `my $current_mtime = strftime("%Y-%m-%dT%H:%M:%S", gmtime($fd->{file_mtime}));`; `read_index_file` :: `my $on_disk_mtime = strftime("%Y-%m-%dT%H:%M:%S", gmtime($stat[9]));`; `write_aggregate_export` :: `$determining->{generated_at} = strftime("%Y-%m-%dT%H:%M:%SZ", gmtime());`) | `format_epoch_iso` :: `return sprintf("%s.%03d", strftime("%Y-%m-%dT%H:%M:%S", gmtime($int_part)), $ms);` | Five inline restatements of the ISO pattern, one with a `Z` suffix, beside the formatter that owns it | Identical today (the index reads back what it wrote through the same inline pattern) | `format_epoch_iso` with a no-milliseconds mode, or a sibling, called by all five | none | **latent** | #154 (rendering offset) touches every timestamp site |

Sites audited and closed as **deliberate**:

- The `-V` sections, the TIMING, MEMORY, COUNTS and CONFIG lines and the
  MEMDIAG diagnostics: raw `sprintf` by `docs/percentage-presentation.md`'s
  exemption and `tests/HARNESS-DESIGN.md` (machine-read output is never
  presentation-formatted). 111 of the 293 `sprintf` lines.
- `aggregate_number` :: `return defined $v ? $v + 0 : undef;`: the export's exact
  values, `features/503-yaml-aggregate-export.md` R12.
- The STATS and MESSAGES numeric cells beside their `_nice` twins: the numeric
  cell must stay numeric (`features/561-retained-durations-as-numbers.md`).
- The histogram's percent ticks, `render_histogram_row` :: `$y_pct = sprintf(" %3d%%", $pct_val);`
  and `render_histogram_x_axis` :: `$result .= $box->{corner_br} . sprintf(" %3d%%", 0);`:
  listed as pending migration in `docs/percentage-presentation.md`, so
  deliberate until that migration; recorded here so the migration is not lost.
- The summary table's stage timings and peak memory, and the aggregate export's
  restatement of the same calls: `features/503-yaml-aggregate-export.md` D19
  locks them as the same calls.
- `format_duration`'s rounding to the source resolution before scaling:
  `features/444-access-log-format-family-and-user-surface.md` (latency cells).

### Open issues touching this item as a whole

- **#273** (store the precise total duration, format at the rendering boundary):
  records F2.15's site and its fix; the audit adds only the cross-reference.
- **#605** (numeric, byte and duration inputs accept a value with a unit,
  `next-up`): the parse side of the byte and time vocabularies whose display
  side F2.6 and F2.5 audit; the one-ladder target serves both.
- **#514** (count metric capture and display become explicit, `next-up`): every
  count rendering site (F2.2, F2.4) is on its path.
- **#525** (one timestamp-precision option, nanosecond included, `next-up`) and
  **#154** / **#155** (render-side timezone offset; UTC normalisation): every
  timestamp formatter (F2.11, F2.16) gains a mode or an offset; landing on one
  formatter first is cheaper than on three.
- **#412** (notices surface, `next-up`) and **#454** (a notice for filtered
  statistics): the rendering rule for numbers in notices (F2.8, F2.9) belongs to
  the surface #412 builds.
- **#497** and **#498** (rows overflow the width; headings degrade): the
  messages table whose cells F2.12's three fit-to-width mechanisms fill.

### Site inventory

Carried from the scoping pass (each marked *(scoping)*; the refuted attribution
of `%duration_display_decimals` is corrected to file scope) with the audit's
additions:

- `format_time` :: `my $milliseconds = convert_duration_to_ms($value, $unit);` :: OWNER: duration scaler over the ladder; zero renders in the lowest step. 16 references. *(scoping)*
- `format_time` :: `$formatted_value =~ s/0+$//;` :: the first of two trailing-zero strips in the sub; the second is `$formatted_value =~ s/\.0+(?=\s|$)//;`. *(audit)*
- `format_duration` :: `my $rounded  = sprintf( "%.${decimals}f", $value );` :: OWNER: latency cells, rounds to source resolution through the private decimals table, sheds a digit to fit. *(scoping)*
- `format_duration_total` :: `return format_time($value, 'ms', $format, $space) if $value != 0;` :: OWNER: totals; zero in the source unit. *(scoping)*
- `format_bytes` :: `if( length( $bytes_int ) >= length( $units{$u} ) ) {` :: OWNER: bytes; private map, digit-count climb, `TO DO` about 1000kB. *(scoping)*
- `format_bytes` :: `$formatted_value =~ s/\.0+(?=\s|$)//;` :: its strip. *(audit)*
- `convert_bytes` :: `'KB'  => 1024,` :: the parse-side map (item 1). *(scoping)*
- `format_number` :: `$formatted_value =~ s/\.0+$//;` :: OWNER: counts and unitless; private 1/k/Mil/Bil/Tril ladder climbed by value (`if ($value >= $units{$u}) {`); three tiers. *(scoping)*
- `significant_decimals` :: `my $magnitude = $value >= 100 ? 3 : $value >= 10 ? 2 : $value >= 1 ? 1 : 0;` :: shared helper for `format_time` and `format_percentage`. *(scoping)*
- `format_percentage` :: `$decimals = significant_decimals($value, $p{digits} // 3);` :: OWNER: every presented percentage; five call sites (`progress_line_text` twice, `print_bar_graph`, `share_row_text`, `print_summary_table`). *(scoping)*
- `format_percentage` :: `$t =~ s/0+$//;` :: its strip. *(audit)*
- `format_cv_display` :: `return sprintf('%.1f', $cv) if $cv >= 10;` :: OWNER: the CV cell; magnitude-fixed decimals, no strip. *(scoping)*
- `format_csv_value` :: `my $formatted = sprintf("%.${decimals}f", $value);` :: OWNER: numeric CSV cells by family; 56 calls in `print_bar_graph` and `print_message_summary`. *(scoping)*
- `format_csv_value` :: `$formatted =~ s/\.0+$//;` :: its strip. *(audit)*
- `adapt_to_command_line_options` :: `my %decimals_by_unit = ( ns => 9, us => 6, ms => 0, s => 0 );` :: the CSV decimals table. *(scoping)*
- `(file scope, between format_time and format_duration_total)` :: `my %duration_display_decimals = ( ns => 6, us => 3, ms => 0, s => 0 );` :: the display decimals table. *(scoping, attribution corrected)*
- `format_heatmap_value` :: `return $ut eq 'time'  ? format_time($value, 'ms') :` :: the partial metric-kind dispatcher; seven callers (`format_histogram_dimensions_line` twice, `get_heatmap_column_header`, `print_heatmap_footer_scale`, `calculate_histogram_x_labels`, `select_histogram_percentiles`, `render_histogram_legend`). *(scoping)*
- `print_bar_graph` :: `my $time_format = $col_w >= 15 ? 'long' : ($col_w >= 10 ? 'medium' : 'short');` :: the display-branch dispatch and width-to-tier rule. *(scoping)*
- `print_bar_graph` :: `(defined $log_stats{$bucket}{$key} ? ltrim(format_duration_total($log_stats{$bucket}{$key}, 'medium', ' ')) : undef),` :: the STATS CSV nice-cell builder. *(scoping)*
- `print_bar_graph` :: `? format_percentage( $cell_value, mode => 'significant', digits => 3, width => $col_w )` :: the success and failure percentage columns. *(scoping)*
- `print_bar_graph` :: `$trend_value = defined $log_stats{$bucket}{$key} ? " " . format_number( $log_stats{$bucket}{$key}, 'medium', ' ', $decimals) : "";` :: the user-defined number column, variable decimals. *(scoping)*
- `print_bar_graph` :: `$rate_metrics .= "${color}" . format_number( $occurrences, 'medium' ) . "$colors{'NC'}";` :: legend counts. *(scoping)*
- `normalize_data_for_output` :: `$title_length = length( format_number( $occurrences, 'medium' ) . "$rate_suffix{$rate_unit} ");` :: the legend width measured by re-rendering. *(scoping)*
- `calculate_all_statistics` :: `$log_messages{$category}{$log_key}{total_duration} = format_duration_total( $aggregated_data->{total_duration}, 'medium', 'space' ) if defined $aggregated_data->{total_duration};` :: the formatted string stored in the message store (F2.15). *(scoping)*
- `print_message_summary` :: `$row .= " " x $table_padding_inner . sprintf( "%$col_width{2}s", $occurrences ) . " " x $table_padding_inner;` :: raw occurrences (twice). *(scoping)*
- `print_threadpool_summary` :: `my $occurrences = scalar keys %{$threadpool_activity{$grouping}{$key}};` :: raw occurrences, third copy. *(scoping)*
- `print_message_summary` :: `my $total_bytes = defined $total_bytes_num ? format_bytes( $total_bytes_num,'B' ) : undef;` :: MESSAGES `bytes_nice`. *(scoping)*
- `print_summary_table` :: `push @summary_table, sprintf( $table_format, "LINES READ", $total_lines_read );` :: raw counts in the summary (three rows). *(audit)*
- `legend_category_total` :: `return $precise_values ? $occurrences : format_number($occurrences, 'short');` *(scoping)*
- `share_row_text` :: `my $share = format_percentage( $count / $denominator * 100,` :: share through the formatter, count raw. *(scoping)*
- `print_summary_table` :: `my $pct_str = format_percentage( $pct, mode => 'integer', width => 5, parens => 1,` :: memory breakdown. *(scoping)*
- `write_aggregate_export` :: `$measurements->{total_time}      = format_time($elapsed_total, 's', 'medium', " ");` :: the D19 restatement. *(scoping)*
- `write_aggregate_export` :: `$determining->{generated_at} = strftime("%Y-%m-%dT%H:%M:%SZ", gmtime());` :: inline ISO with `Z`. *(audit)*
- `aggregate_number` :: `return defined $v ? $v + 0 : undef;` *(scoping)*
- `emit_classification_percentage_notices` :: `my $leak_pct = $r->{included} ? sprintf('%.1f', $r->{unclassified} / $r->{included} * 100) : '0.0';` *(scoping)*
- `emit_format_detection_verbose` :: `push @verbose_output, "unclassified_pct: " . ($total_lines_included ? sprintf('%.1f', $unclassified / $total_lines_included * 100) : '0.0');` :: the exempt `-V` twin. *(scoping)*
- `render_histogram_row` :: `$y_pct = sprintf(" %3d%%", $pct_val);` and `render_histogram_x_axis` :: `$result .= $box->{corner_br} . sprintf(" %3d%%", 0);` :: pending migration. *(scoping)*
- `render_histogram_row` :: `my $count_str = format_number($count_val, 'medium', undef, 0);  # No space, 0 decimals` *(scoping)*
- `write_index_file` :: `my $dur_avg   = $fd->{duration_occurrences} > 0 ? sprintf("%.2f", $fd->{duration_sum} / $fd->{duration_occurrences}) : '-';` :: six means, a rate, an elapsed. *(scoping)*
- `write_index_file` :: `'-', $max_memory_usage, sprintf("%.3f", $elapsed_total), $current_filters` *(scoping)*
- `write_index_file` :: `my $now_iso = strftime("%Y-%m-%dT%H:%M:%S", gmtime());` *(scoping)*
- `read_index_file` :: `my $on_disk_mtime = strftime("%Y-%m-%dT%H:%M:%S", gmtime($stat[9]));` *(audit)*
- `read_and_process_logs` :: `print STDERR "Warning: $in_file: skipped $csv_skipped_timestamp_rows CSV rows with unparseable timestamps\n";` *(scoping)*
- `read_and_process_logs` :: `print STDERR "Note: " . format_number($count, 'medium')` *(scoping)*
- `bin_consolidation_notice` :: `format_number(` *(scoping)*
- `progress_line_text` :: `$file_pct = format_percentage( $pct, mode => 'integer', width => 3, floor => 1 );` *(scoping)*
- `normalize` :: `sub normalize { $_[0] =~ s/\.0+$//r }` :: dead. *(scoping)*
- `format_epoch_iso` :: `my $ms = int(($epoch - $int_part) * 1000 + 0.5);` *(scoping)*
- `format_observation_timestamp` :: `$str .= sprintf ".%03d", ($epoch - int($epoch)) * 1000 if $print_milliseconds;` *(scoping)*
- `format_bucket_timestamp` :: `return strftime($output_timestamp_format, gmtime($bucket / 1000)) . sprintf(".%03d", $bucket % 1000)` :: the integer-millisecond path that neither of the two above uses. *(scoping)*
- `format_histogram_dimensions_line` :: `"  %-10s samples=%-6d min=%-10s max=%-10s decades=%.2f buckets_per_decade=%d total_buckets=%d",` *(scoping)*
- `pipeline_finalize` :: `push @verbose_output, sprintf("    Reduction: %d -> %d (%.1f%%)",` and `print_verbose_output` :: `printf "TIMING\ttotal\t%.3f\n", $elapsed_total;` :: deliberate raw diagnostics. *(scoping)*
- `parse_udm_configs` :: `my %si_units = ( 'k' => 1000, 'K' => 1000, 'M' => 1000**2, 'G' => 1000**3, 'T' => 1000**4 );` and `emit_index_readback_verbose` :: `convert_bytes(` :: the parse-side unit maps and their second caller (item 1). *(scoping)*
- `sample_file_for_detection` :: `$obs->{avg_line} = $obs->{lines} ? int($line_bytes / $obs->{lines} + 0.5) : 0;` :: a rounding outside the formatters, diagnostic. *(audit)*

### Verification notes

- Every snippet in the table and the inventory was resolved to its enclosing sub
  on 2026-09-26. The scoping pass's one refuted attribution (the display
  decimals table inside `format_duration`) is corrected to file scope.
- The scoping pass's F2.1 cited `features/524-bucket-size-unit.md`'s note that a
  zero renders `0ns`; the run confirms it on the heatmap header. The histogram
  did not render at all for an all-zero fixture, so the histogram half of the
  claim is unconfirmed and stands on the shared dispatcher only.
- The scoping pass's F2.3 (rate suffix) is refuted as a live divergence: the
  heatmap and histogram refuse counting aggregations before the branch runs.
- The scoping pass's F2.5 is kept as a table-duplication finding but its
  "different values" are not observable on integer source values; the run
  evidence is recorded so the next reader does not expect a visible difference.
- The `-lf classification_verification` fixture had to carry a four-digit
  duration beginning with a digit below five: a three-digit value matches that
  format's success rule and a five-or-above leading digit its failure rule.

### Questions for the findings discussion, with the evidence bearing on each

- *Is the zero-duration `0ns` on the heatmap header intended?* The zeros fixture
  shows `0ns` beside a timeline that says `0ms` for the same lines. #444 R17
  chose the source unit for totals; nothing chose the nanosecond for labels.
- *Are the two decimals tables meant to differ?* On integer source values they
  cannot be told apart; both cover four tokens of ten. Converging them on the
  ladder is a #524 D1 obligation more than a behaviour question.
- *Should bytes get one ladder and a value-based climb?* 1000, 1023 and 1024
  bytes render identically today; the `TO DO` in `format_bytes` has asked for
  the change since before the ladder existed. Sequencing: after item 1's F1.12
  fix, with #605.
- *Does the trailing-zero rule extend to the CV cell and to two-decimal counts?*
  `0.50` against `0.5` and `1.50 k` against `1.5k` are the two observations. The
  CV cell's four-character budget is the constraint a strip would have to keep.
- *Are raw occurrences in the tables and the summary deliberate?* `1200` against
  `1.2k` in one run. The legend has `-ov` for precise values; the tables have no
  switch the other way. A decision either way is a one-line record.
- *Does the run index honour `-cp`?* `128.75` against `129`. The index is read
  back by `read_index_file` and compared by `detect_index_drift`, which is the
  cost of changing its precision.
- *Milliseconds: rounding or truncation?* `.122` against `.123` for a `.123`
  timestamp is a defect in the truncating copy, independent of which policy is
  chosen; the integer-millisecond key path of `format_bucket_timestamp` has
  neither problem.
- *Is the unclassified warning inside the percentage convention?* The doc's
  exemption names `-V` and machine-read output; the warning is neither.


---

## Item 3: Timestamp parsing

**State: scoping pass recorded; audit not yet run.**

### Summary of the scoping pass

Four live per-line parse arms. (1) Inline ISO fixed-offset substr/timegm arm in the generated scan blocks: iso_ms routes mt1std, mt10, mt16, mt1gen, mt2, mt5, mt6, mt7, mt17 and mtvfy (pin-only verification entry); iso_flex routes mt8; iso_flex_frac routes mt11; iso_ms_ddmm routes mt10ir with the day/month offsets swapped. (2) Inline Apache month-map arm, layout apache_clf: mt3ts, mt12, mt9, mt19, mt20, mt3, mt4. (3) CSV ISO arm via the csv entry's FR_TIME_PARSE closure (layout 'csv', which takes the iso branch). (4) CSV epoch arm, inline in read_and_process_logs, for the csv entry when the first data line is numeric. There is also a second copy of arms 1 and 2 as closures in compile_format_time_parser; the apache closure is never called. Off the per-line path: calculate_start_end_filter_timestamps (Time::Piece strptime for -st/-et), parse_iso_date_to_epoch, and format_sample_probes. One shared date cache (%timestamp_date_cache) and one last-seen memo ($format_last_ts_str/$format_last_ts_epoch, scanned arms only).

**Shared surface today.** Partial. The date cache is shared: timestamp_date_cache_add / timestamp_date_cache_clear / timestamp_date_cache_snapshot / timestamp_date_cache_restore over %timestamp_date_cache. Every ISO and Apache arm (inline and closure) reads it. The parse logic has two authorities for the same arms: compile_format_time_parser (closures, used only by the CSV ISO arm) and the source strings in format_entry_block_src (inlined into generated scan blocks, used by every scanned format). The CSV epoch arm and the CSV fractional strip sit inline in read_and_process_logs.

### Candidate findings (scoping pass; category and priority assigned by the audit)

- **F3.1** Two copies of the ISO and Apache parse: the closures in compile_format_time_parser and the $compute source strings in format_entry_block_src restate the same timegm/substr/month-map logic. The doc comment `as compile_format_time_parser` asserts they are the same, but nothing checks it. The apache_clf closure is built into FR_TIME_PARSE for seven entries and never called.
- **F3.2** Impossible-date guard: the inline iso arm (format_entry_block_src, `if (substr(\$timestamp_str, $month_off, 2) > 12 || substr(\$timestamp_str, $day_off, 2) > 31) {`) guards month>12/day>31 before timegm. The CSV ISO arm (read_and_process_logs, via compile_format_time_parser's iso closure) checks only shape (`/^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}/`). By reading, a CSV value such as 2025-13-01 00:00:00 passes the guard and reaches an unguarded timegm, which croaks on month out of range. Not run.
- **F3.3** The issue 328 shape guard exists only on the CSV ISO arm. The CSV epoch arm (`my $epoch_val = $timestamp_str;` ... `$timestamp = int($epoch_val);`) has none: epoch mode is decided from the first data line alone, so by reading, a later non-numeric value hits int() under `use warnings`, which would give a ' at ltl line N' warning and epoch 0. Not run.
- **F3.4** The Apache arm has no guard in either copy: the timestamp capture is `[\[]([^\]]+)[\]]` (no shape guarantee), and `$format_month_map{$month_str} - 1` is undefined for a token that is not a month name.
- **F3.5** The fractional strip is written twice: the 'generic' frac source in format_entry_block_src (`if ($timestamp_str =~ s/(:\d{2}:\d{2})[.,](\d{1,6})/$1/) { $fractional_ms = $2 * (10 ** (3 - length($2))); }`) and the CSV ISO arm in read_and_process_logs (the same regex and normalisation on separate lines).
- **F3.6** CSV epoch detection is written twice in read_and_process_logs: once on the confirmed-CSV data-line path (`$line_number == 2 && defined $timestamp_str && $timestamp_str =~ /^\d+(\.\d+)?$/`) and once on the header-validation path (`defined $timestamp_str && $timestamp_str =~ /^\d+(\.\d+)?$/`).
- **F3.7** The last-seen memo ($format_last_ts_str / $format_last_ts_epoch) sits in front of the scanned arms only. The CSV ISO arm goes straight to the date cache, and the CSV epoch arm uses neither.
- **F3.8** Four separate ISO-date parsers apply different validity checks: the inline iso arm (month/day range checks, no eval), the closure (no check), parse_iso_date_to_epoch (regex plus eval), and format_sample_probes (regex, range checks and eval).

### Site inventory (scoping pass)

- `format_entry_block_src` :: `my $compute = ($layout eq 'apache_clf')` :: Emits the inline per-format parse into each generated scan block. Picks one of two source strings by the entry's declared time layout: apache_clf (month-map arm) or everything else (fixed-offset substr/timegm ISO arm). This is the live parse for every scanned format.
- `format_entry_block_src` :: `$timestamp_date_cache{substr($timestamp_str, 0, $colon)} // do { my ($day, $month_str, $year) = $timestamp_str =~ m/(\d{2})\/([A-Za-z]+)\/(\d{4})/;` :: Inline Apache arm (layout apache_clf): the date key is the text before the first colon, the month comes from %format_month_map, timegm runs once per new date, and the time of day is added as arithmetic. There is no guard on the date parts.
- `format_entry_block_src` :: `my ($day_off, $month_off) = $layout eq 'iso_ms_ddmm' ? (5, 8) : (8, 5);` :: Inline ISO arm (every iso_* layout): reads the date parts at fixed substr offsets from $timestamp_str (key substr 0,10). Day and month offsets swap for iso_ms_ddmm.
- `format_entry_block_src` :: `my $miss_src = $layout =~ /^iso_/` :: Guard on the memo-miss branch, iso_* layouts only: an impossible month (>12) or day (>31) carries the line at the previous epoch and signals format_probe_signal('impossible_date'). Variant-group members also get the monotonicity probe. apache_clf gets no guard.
- `format_entry_block_src` :: `push @body, qq{if (\$timestamp_str eq \$format_last_ts_str) { \$timestamp = \$format_last_ts_epoch; }` :: Last-seen memo in front of every scanned parse: if the timestamp string is unchanged from the previous line, it reuses the previous epoch.
- `format_entry_block_src` :: `my $frac = $spec->{time}{frac} // 'generic';` :: Fractional-second handling chosen by the declared frac contract: fixed3 (substr at offset 20), none (constant 0), or generic (an s/// strip with a regex).
- `compile_format_time_parser` :: `sub compile_format_time_parser {` :: Closure copy of the same two arms (an apache_clf closure plus an iso closure with the ddmm swap), built into FR_TIME_PARSE for every entry by build_format_registry. Its only runtime caller is the CSV ISO arm, so the apache_clf closure is built but never called.
- `build_format_registry` :: `$entry->[FR_TIME_PARSE]      = compile_format_time_parser( $spec->{time}{layout} );` :: How the per-format declared layout reaches the closure parser. The inline arms read $spec->{time}{layout} directly inside format_entry_block_src.
- `read_and_process_logs` :: `$timestamp = $line_entry->[FR_TIME_PARSE]->($timestamp_str);` :: CSV ISO arm (match_type 13 when the file is not epoch): calls the csv entry's closure. Layout 'csv' falls to the iso branch with mm-dd offsets.
- `read_and_process_logs` :: `if (!defined $timestamp_str || $timestamp_str !~ /^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}/) {` :: The shape guard added under the issue for CSV timestamps that are neither epoch nor ISO (issue 328 in the source comment). It skips the row, counts it in $csv_skipped_timestamp_rows and $excluded_other, and warns once per file. Only the CSV ISO arm has it.
- `read_and_process_logs` :: `if ($timestamp_str =~ s/(:\d{2}:\d{2})[.,](\d{1,6})/$1/) {` :: CSV ISO arm's fractional strip. It is a verbatim copy of the 'generic' frac source emitted by format_entry_block_src.
- `read_and_process_logs` :: `# Epoch timestamp: value is already epoch seconds (or other unit via -du)` :: CSV epoch arm (when $csv_epoch_timestamp is set): scales the value by -du through %time_unit_step, takes int() for the whole seconds and puts the remainder in $fractional_ms. It has no guard and does not use the date cache.
- `read_and_process_logs` :: `if ($line_number == 2 && defined $timestamp_str && $timestamp_str =~ /^\d+(\.\d+)?$/) {` :: Epoch detection on the confirmed-CSV data-line path, first data line only. A second copy sits on the header-validation path: `if (defined $timestamp_str && $timestamp_str =~ /^\d+(\.\d+)?$/) {` (about line 15241). $csv_epoch_timestamp is reset per file (about line 14988).
- `timestamp_date_cache_add` :: `sub timestamp_date_cache_add {` :: The actual timestamp cache: date string maps to midnight epoch, capped at TIMESTAMP_DATE_CACHE_MAX (100) with oldest-insertion eviction. Used by the inline ISO and Apache arms and by both closures, so the CSV ISO arm uses it too. The CSV epoch arm does not.
- `timestamp_date_cache_clear` :: `sub timestamp_date_cache_clear {` :: Cache reset. Called from format_record_reset (at the end of build_format_registry, before line 1) and from format_registry_set_occupant, but only when the occupant actually changed (reached from format_probe_signal and apply_format_variant_selection). There is no per-file clear. The last-seen memo is reset at both of those sites too.
- `format_validate_scan_sub` :: `my $saved_cache = timestamp_date_cache_snapshot();` :: Saves and restores the date cache and the last-seen memo around sample validation of a newly compiled scan sub.
- `calculate_start_end_filter_timestamps` :: `$epoch_value = Time::Piece->strptime( $value, "%Y-%m-%d %H:%M:%S" )->epoch;` :: A separate parse surface (Time::Piece strptime) for -st/-et bounds. read_and_process_logs calls it once, until $filter_range_filter_initialized is set; it is not run per line.
- `parse_iso_date_to_epoch` :: `return eval { timegm($6, $5, $4, $3, $2 - 1, $1) };` :: Another ISO-to-epoch parser outside the hot loop, used for index-file and ISO 'T' strings. Its timegm is wrapped in eval.
- `format_sample_probes` :: `my $epoch = eval { timegm($sec, $mi, $h, $dy, $mo - 1, $y) };` :: Detection-sample parser that reads each ISO date under both mm-dd and dd-mm. It has its own regex plus month>12/day>31 checks and an eval around timegm, overlapping the inline iso guard. Runs on the detection sample, not per line.
- `read_and_process_logs` :: `$bucket = int($bucket_epoch / $bucket_size_seconds) * $bucket_size_seconds;` :: The per-line epoch-to-bucket arm the original task asked for ('into an epoch or bucket'). It has two branches: integer-millisecond keys under $print_milliseconds (`$bucket = int($epoch_ms / $bucket_size_ms) * $bucket_size_ms;`) and whole-second keys otherwise. The inventory does not list it. *(added by the verifier)*
- `read_and_process_logs` :: `my $folded = fold_epoch($timestamp_epoch, $profile_mode);` :: Per-line remap of the epoch under --profile, before bucketing. fold_epoch uses gmtime plus anchor arithmetic, which makes it a second epoch-to-position transform in the hot loop. *(added by the verifier)*
- `read_and_process_logs` :: `my $tod = $timestamp_epoch - int($timestamp_epoch / 86400) * 86400;` :: Per-line time-of-day derivation for -st/-et bounds given without a date. The same seconds-since-midnight idea exists again as strptime '%H:%M:%S' in calculate_start_end_filter_timestamps. *(added by the verifier)*
- `(file scope, %format_transform_code, after sub emit_index_readback_verbose)` :: `chop_tz_offset      => q{ $timestamp_str =~ s/ \+\d{4}$//; },` :: Timestamp normalisation primitives spliced into the generated blocks ahead of the fractional strip and parse: t_to_space, comma_to_dot, chop_tz_offset, chop_tz_colon_offset. The date-cache key is 'post-chop', so these are part of the parse path. The CSV ISO arm gets none of them: its guard accepts a 'T', and any timezone suffix is dropped without comment by the fixed offsets. *(added by the verifier)*
- `read_and_process_logs` :: `my $timestamp_epoch = $timestamp + ($fractional_ms / 1000);` :: The single point where every arm's whole-second epoch and $fractional_ms join into the fractional epoch that the filters and buckets read. *(added by the verifier)*
- `initialize_empty_time_windows` :: `my $start_bucket = int($output_timestamp_min / $bucket_size_seconds) * $bucket_size_seconds;` :: A second copy of the bucket arithmetic, ms and seconds branches included (`my $bucket_size_ms = int($bucket_size_seconds * 1000 + 0.5);`). It is off the per-line path but duplicates the read_and_process_logs bucket arm. *(added by the verifier)*

### Verification notes

Sites reported 19, confirmed 20, refuted 0 (corrected above), added by the verifier 6, owning docs refuted 0.

- The line hint for the frac site `my $frac = $spec->{time}{frac} // 'generic';` is wrong: the snippet is at about line 4380, not 4388. It is in the right sub (format_entry_block_src).
- The snippet `my ($day_off, $month_off) = $layout eq 'iso_ms_ddmm' ? (5, 8) : (8, 5);` is not unique. It also sits in compile_format_time_parser (about line 3507). The format_entry_block_src attribution holds (about line 4393).
- The snippet `if ($timestamp_str =~ s/(:\d{2}:\d{2})[.,](\d{1,6})/$1/) {` also matches inside format_entry_block_src (about line 4389). The read_and_process_logs attribution holds (about line 15482), and the duplication is already listed under divergences.
- All six owning-doc headings exist verbatim: log-format-registry.md at about lines 623, 1068 and 581; 58-format-registry-staged-detection.md at about 186 and 358; user-defined-metrics.md at about 265, with the skip-and-warn line at about 280. All three harnesses exist.
- Verified as stated: timestamp_cache has 0 hits in ltl. There are 7 apache_clf entries (mt3ts, mt12, mt9, mt19, mt20, mt3, mt4), and every layout route in count_summary matches format_registry_specs. FR_TIME_PARSE is called at runtime only in the CSV ISO arm, so the apache closure is never called. The last-seen memo is reset in format_registry_set_occupant and format_record_reset, and saved and restored in format_validate_scan_sub. $csv_skipped_timestamp_rows is a `my` declared per file (about line 14993), so 'warns once per file' holds.
- The inventory's scope is incomplete against the original task. The task asked for arms that turn a timestamp 'into an epoch or bucket', but the inventory stops at the epoch. It leaves out the bucket arm, the --profile fold_epoch remap and the pre-parse timestamp transforms in %format_transform_code (see sites_missed).

### Questions for the findings discussion

Carried in the specification, § 4, under this item; the audit adds the evidence bearing on each here.


---

## Item 4: Aggregation and statistics gating

**State: scoping pass recorded; audit not yet run.**

### Summary of the scoping pass

26 ratio or derivation sites across 12 subs. Duplicates: count mean has 4 inline copies (per-bucket x2, per-message x2); bytes mean has 4 (per-bucket x2, sort pre-pass, print_message_summary); UDM numeric mean has 3 (per-bucket x2, per-message); duration mean/variance/cv/moments have 2 full copies (calculate_statistics, calculate_statistics_bin); impact mean has 2; the per-file index mean has 6 (3 plus 3 sel_ twins); unclassified percentage has 2. No shared mean or ratio helper exists. Rule violations: 5 defined-over-zero-init or wrong-divisor sites (the impact mean x2, the STATS CSV duration_nice/bytes_nice, the print_bar_graph latency-block OR, and normalize max_total, which is harmless), plus 2 accumulators with no unconditional observation count (raw-mode total_duration, and total_bytes when bytes demand is off).

**Shared surface today.** None for mean or ratio derivation: no sub named *mean*, *ratio*, *avg*, *pct* or *div* exists in ltl. The only shared derivation surfaces are calculate_statistics() (raw) and calculate_statistics_bin() (bin) for the duration family, and they are two parallel copies of the same formulas. Every bytes, count and UDM mean is an inline ternary at its site.

### Candidate findings (scoping pass; category and priority assigned by the audit)

- **F4.1** Per-bucket vs per-message UDM mean gate: calculate_all_statistics `$log_stats{$bucket}{"udm_${name}_mean"} = (defined $occ && $occ > 0)` has no defined-sum guard. The per-message copy `(defined $sum && defined $occ && $occ > 0) ? $sum / $occ : undef;` got it from the #326 fix (commit 6c6b172). The per-bucket copy is safe only because counting configs exit earlier through `next`.
- **F4.2** Per-bucket UDM mean computed twice in one block: `$log_stats{$bucket}{"udm_${name}_mean"} = (defined $occ && $occ > 0)` (17514) and `elsif ($agg eq 'mean') { $display_value = (defined $occ && $occ > 0)` (17522) repeat the same division.
- **F4.3** Per-message count mean, three differently shaped gates: sort pre-pass `( defined $entry->{count_sum} && $entry->{count_occurrences} )` (truthiness), group-calc `defined ... count_sum && defined ... count_occurrences && ... > 0 ... : undef if defined ...{count_occurrences};` (postfix-if leaves the field untouched when the count is absent), per-bucket `count_mean    => ( defined $log_analysis{$bucket}{count_sum} && defined $log_analysis{$bucket}{count_occurrences}` (no postfix, written in two identical copies at 17434/17456).
- **F4.4** Per-message bytes mean, precision: sort pre-pass `$entry->{bytes_mean} = $entry->{bytes_occurrences}` keeps full precision (a comment says rounding at rank time would manufacture ties), while print_message_summary `? int( $total_bytes_num / $bytes_occurrences + 0.5 )` rounds to an integer for both the display and the MESSAGES CSV. The per-bucket `bytes_mean    => ... : undef,` keeps full precision. So the STATS CSV bytes_mean is fractional and the MESSAGES CSV bytes_mean is an integer.
- **F4.5** Duration-mean divisor: calculate_statistics `my $mean = $bucket_data->{total_duration} / $duration_count;` and calculate_statistics_bin `/ $n` divide by the duration observation count, while the impact means in read_and_process_logs (`.../ $log_messages{$category}{$log_key}{occurrences};`) and group_similar_messages (`my $mean = $entry->{total_duration} / $entry->{occurrences};`) divide by all matched lines. This is the defect shape #432 (bytes aggregate parity) F1 found and fixed for mean_bytes, still present for the impact mean.
- **F4.6** Impact gate: the read-loop copy gates on the current line's `if( $duration > 0 )`; the consolidation copy gates on `defined $entry->{total_duration} && $entry->{occurrences} > 0 && $entry->{total_duration} > 0`. Same quantity, different guards.
- **F4.7** Raw vs bin duration statistics: calculate_statistics gates `return unless $occurrences > 0;` then a non-empty durations[]; calculate_statistics_bin gates `($sidecar_entry->{occurrences} // 0) > 0` then `$n > 0`. The mean, variance (sum_of_squares - n*mean^2)/(n-1), cv and moment formulas are restated in both.
- **F4.8** Per-file index vs everything else: write_index_file formats means inline as `sprintf("%.2f", ...)` with '-' for no data; every other surface yields undef and formats through format_csv_value. Its bytes pair also mixes names: `$fd->{bytes_sum}    / $fd->{file_bytes_occurrences}`.
- **F4.9** Unclassified percentage derived twice: emit_format_detection_verbose `unclassified_pct: " . ($total_lines_included ? sprintf('%.1f', $unclassified / $total_lines_included * 100) : '0.0')` and emit_classification_percentage_notices `my $leak_pct = $r->{included} ? sprintf('%.1f', $r->{unclassified} / $r->{included} * 100) : '0.0';`, from different inputs (globals vs the reconciliation record).

### Site inventory (scoping pass)

- `calculate_all_statistics` :: `count_mean    => ( defined $log_analysis{$bucket}{count_sum} && defined $log_analysis{$bucket}{count_occurrences}` :: Per-bucket count mean (count_sum / count_occurrences) projected into %log_stats. Gate: defined sum AND defined occ AND occ > 0. The expression appears twice, word for word, at 17434 and 17456 (the duration-stats branch and the no-duration else-branch of the same $log_stats{$bucket} = {...} build). count_sum/count_occurrences are not zero-initialised in %log_analysis, so the gate is compliant. No helper.
- `calculate_all_statistics` :: `bytes_mean    => $log_analysis{$bucket}{bytes_occurrences} ? ($log_analysis{$bucket}{total_bytes} / $log_analysis{$bucket}{bytes_occurrences}) : undef,` :: Per-bucket bytes mean (total_bytes / bytes_occurrences), full precision. Gate: truthiness of bytes_occurrences, which equals count > 0 for a non-negative integer. A second copy sits at 17461 in the else-branch (the same text without the trailing comma). bytes_occurrences is only incremented under $bytes_aggregate_demand (#516, bytes aggregate family captured only on demand), so with demand off the count is absent while total_bytes still accumulates. No helper.
- `calculate_all_statistics` :: `bytes         => $log_analysis{$bucket}{total_bytes},` :: Per-bucket bytes total projected with no gate from a field zero-initialised when the bucket is created in read_and_process_logs (total_bytes => 0). This also happens at 17447, and for duration at 17427/17449 (duration      => $log_analysis{$bucket}{total_duration}, which is also zero-initialised). The -HL twins ('bytes-HL', 'duration-HL', 'count-HL') are projected without a gate from fields that exist only when a highlighted line carried the metric.
- `calculate_all_statistics` :: `elsif ($agg eq 'ratio')    { $display_value = $occ / $distinct; }` :: Per-bucket UDM counting aggregations: ratio = occ/distinct, rate = occ/bucket_seconds*multiplier, drate = distinct/bucket_seconds*multiplier. Gate: defined $occ && $occ > 0 (compliant; a comment states the invariant that distinct >= 1 whenever occ > 0).
- `calculate_all_statistics` :: `elsif ($agg eq 'ratio')    { $hl_value = $occ_hl / $distinct_hl; }` :: -HL twin of the counting ratio/rate/drate. Gate: defined $occ_hl && $occ_hl > 0 (compliant).
- `calculate_all_statistics` :: `$log_stats{$bucket}{"udm_${name}_mean"} = (defined $occ && $occ > 0)` :: Per-bucket UDM numeric mean (udm_<name>_sum / udm_<name>_occurrences) stored as udm_<name>_mean. Gate: defined occ && occ > 0, with no defined-sum guard; it relies on counting configs having left the loop earlier through `next`. This is the per-bucket sibling of the #326 (uninitialised-value warning in a UDM full-pattern run) fix.
- `calculate_all_statistics` :: `elsif ($agg eq 'mean') { $display_value = (defined $occ && $occ > 0)` :: Per-bucket UDM display value for -udm ...:mean. Recomputes the same division as 17514, four lines above, instead of reading the stored udm_<name>_mean. Same gate. The -HL twin for mean is hard-coded to undef.
- `calculate_all_statistics` :: `$entry->{bytes_mean} = $entry->{bytes_occurrences}` :: Per-message bytes mean in the sort pre-pass (only when -so bytes_mean), full precision. Gate: truthiness of bytes_occurrences. This is a second derivation of the per-message bytes mean; the display derivation is in print_message_summary.
- `calculate_all_statistics` :: `$entry->{count_mean} = ( defined $entry->{count_sum} && $entry->{count_occurrences} )` :: Per-message count mean in the sort pre-pass (only when -so count_mean). Gate: defined sum && truthy occ. The gate is shaped differently from the group-calc copy at 17901.
- `calculate_all_statistics` :: `: undef if defined $log_messages{$category}{$log_key}{count_occurrences};` :: Per-message count mean in the group-calc loop, top keys only. Gate: defined sum && defined occ && occ > 0, wrapped in a postfix `if defined count_occurrences`, so a key with no count observations keeps whatever was there (possibly a sort-pre-pass value) rather than being set to undef. Neighbouring lines hold self-assignments that do nothing (count_occurrences = count_occurrences if defined ...).
- `calculate_all_statistics` :: `$log_messages{$category}{$log_key}{"udm_${name}_mean"} = (defined $sum && defined $occ && $occ > 0) ? $sum / $occ : undef;` :: Per-message UDM mean. This is the #326 fix (commit 6c6b172, merged via PR #336): `next if agg_kind eq 'counting'` plus the added defined-sum guard. The gate differs from the per-bucket sibling at 17514.
- `calculate_all_statistics` :: `$duration_observed ||= ( ($log_messages{$category}{$log_key}{total_duration} // 0) > 0 );` :: Per-message duration-observed gate (the #330 fix, which stops a 0-initialised total_duration reading as observed). Primary gate: duration_count > 0 (bin mode) or a non-empty durations[] (raw mode), with a fallback on a positive total. It decides whether total_duration/total_duration_num and the statistics are written to the message.
- `calculate_statistics` :: `my $mean = $bucket_data->{total_duration} / $duration_count;` :: Duration mean, std_dev and cv for raw-mode buckets and messages. Gate: occurrences > 0, then a non-empty durations[]; the divisor is duration_count = scalar @sorted (compliant). Variance divides by duration_count - 1 under a >= 2 guard; cv is gated on mean != 0; the moment ratios (m2/m3/m4 over n) have their own n guards.
- `calculate_statistics_bin` :: `my $mean = $sidecar_entry->{total_duration} / $n;` :: Bin-mode twin of calculate_statistics: the same mean/variance/cv/moment derivations, restated. Gate: occurrences // 0 > 0, then n = duration_count // 0 > 0 (compliant). The formulas are duplicated rather than shared with the raw path.
- `read_and_process_logs` :: `my $mean = $log_messages{$category}{$log_key}{total_duration} / $log_messages{$category}{$log_key}{occurrences};` :: Per-message running 'impact' mean, computed in the hot loop. Gate: the current line's $duration > 0. The divisor is occurrences (all matched lines), not the duration observation count.
- `group_similar_messages` :: `if (defined $entry->{total_duration} && $entry->{occurrences} > 0 && $entry->{total_duration} > 0) {` :: Recomputes impact after consolidation (my $mean = $entry->{total_duration} / $entry->{occurrences}; at 11090). Gate: defined total_duration (always true, because the field is 0-initialised) && occurrences > 0 && total > 0. Same occurrences divisor as the read-loop copy.
- `merge_bin_state` :: `my $mean_ab = $mean_a + $delta * $n_b / $n_ab;` :: Combines Welford running means and moments during consolidation. Gate: return if n_b == 0, and a separate branch when n_a == 0 (count-gated, compliant).
- `print_message_summary` :: `? int( $total_bytes_num / $bytes_occurrences + 0.5 )` :: Per-message bytes mean for the terminal table and the MESSAGES CSV, rounded to an integer. Gate: bytes_occurrences truthy. total_bytes_num is also gated on bytes_occurrences (the #432 fix to the zero-initialised total_bytes).
- `normalize_data_for_output` :: `$log_stats{$bucket}{success_pct} = ($bucket_outcome->[1] // 0) / $bucket_classified * 100;` :: Per-bucket success/failure percentages. Gate: bucket_classified > 0 (or a conflict present) and no disqualified lines; otherwise it falls back to counts (success_pct_count). Compliant.
- `normalize_data_for_output` :: `$log_occurrences{$bucket}{'err-rate'}{occurrences} = $error_occurrences / $bucket_size_seconds` :: Per-bucket error and message rates. The denominator is the bucket width constant; the numerators default to 0 (// 0). No count gate needed or present; gated only by !$omit_rate.
- `normalize_data_for_output` :: `$max_total{duration} = $log_stats{$bucket}{duration} if ( defined $log_stats{$bucket}{duration}` :: Column scaling maxima for bytes, duration and count. Gate: defined, over zero-initialised bytes/duration totals. Harmless for a max, but it is the defined-over-zero-init shape.
- `print_bar_graph` :: `if( defined $log_stats{$bucket}{bytes} || defined $log_stats{$bucket}{p50}` :: Terminal latency-cell block. The first disjunct is defined over bytes = total_bytes, which is zero-initialised for every bucket that has lines, so this OR is always true for such buckets.
- `print_bar_graph` :: `(defined $log_stats{$bucket}{$key} ? ltrim(format_duration_total($log_stats{$bucket}{$key}` :: STATS CSV duration_nice cell. Gate: defined over zero-initialised total_duration, so a bucket whose lines carried no duration writes a formatted zero rather than an empty cell. The bytes_nice twin at 19951 (defined ... ? format_bytes(...)) has the same shape over zero-initialised total_bytes.
- `write_index_file` :: `my $dur_avg   = $fd->{duration_occurrences} > 0` :: Per-file index means: duration, file_bytes and count at 6844-6846 and the sel_ twins at 6863-6865. Gate: occurrences > 0 over fields zero-initialised at 14975/14982 (compliant). Formatted inline with sprintf('%.2f') and '-' for no data, separately from every other mean. Naming mismatch: bytes_sum / file_bytes_occurrences.
- `classification_reconciliation` :: `success_pct    => ($eligible && $classified) ? $total_successes / $classified * 100 : undef,` :: Run-level success/failure percentages. Gate: eligible && classified (truthiness of a count, compliant).
- `emit_classification_percentage_notices` :: `my $leak_pct = $r->{included} ?` :: Unclassified-leak percentage for the notice. Gate: truthiness of included. emit_format_detection_verbose computes unclassified_pct at 5350 as a parallel derivation with the same shape (gate $total_lines_included ?).
- `read_and_process_logs` :: `my $delta_n  = $delta / $n;` :: The Welford running mean (_running_mean = mean + delta/n, n = duration_count + 1) is updated in the hot loop in two copies: the per-message copy under -mdm bin (hint 16059) and the per-bucket copy under -bdm bin (hint 16196). Both are gated on $n_old == 0 (count-gated, compliant). merge_bin_state holds a third copy of this derivation (its $mean_ab line). The inventory lists only the merge copy. *(added by the verifier)*
- `share_row_text` :: `my $share = format_percentage( $count / $denominator * 100,` :: Category and row share percentage in the summary table. Called from print_summary_table (share_row_text( $category_label, ... and share_row_text( $label, $n, $denominator )). Gated on the truthiness of $denominator. The inventory does not list it. *(added by the verifier)*
- `emit_format_detection_verbose` :: `? sprintf('%.1f', $format_scan_nomatch_sample_us / $format_scan_nomatch_samples)` :: Mean scan time per unmatched line in -V (nomatch_scan_avg_us), from a sum/count pair. Gated on the truthiness of the sample count; '-' when there is no data. *(added by the verifier)*
- `sample_file_for_detection` :: `$obs->{avg_line} = $obs->{lines} ? int($line_bytes / $obs->{lines} + 0.5) : 0;` :: Mean line length per detection sample part, rounded to an integer. Gated on the truthiness of lines; yields 0 rather than undef when there is no data. *(added by the verifier)*
- `run_consolidation_checkpoint` :: `my $absorption_rate = $pre_count > 0 ? $absorbed / $pre_count : 0;` :: Consolidation absorption rate that feeds the eviction moving average. Gated on count > 0; yields 0 when there is no data. *(added by the verifier)*
- `group_similar_messages` :: `next if ($absorbed / $seen) > $consolidation_skip_absorption;` :: Per-category streaming absorption ratio used in the decision to skip the final pass. Guarded by `next unless $seen > 0;` on the line above (count-gated). *(added by the verifier)*
- `pipeline_finalize` :: `(1 - $final_remaining / ($keys_seen || 1)) * 100);` :: -V consolidation diagnostics: a reduction percentage (two copies, hints 21925 and 21930) and the s3 checkpoint share `(($s->{s3_checkpoint} // 0) / ($s->{s3_calls} // 1)) * 100` gated on s3_calls > 0. The reduction copies divide by `|| 1`, which substitutes a fake divisor instead of gating. *(added by the verifier)*
- `normalize_data_for_output` :: `$log_stats{$bucket}{$scaled_key} = ( defined $log_stats{$bucket}{$key} && defined $max_total{$key} && $max_total{$key} != 0 )` :: Scales a column value against its maximum, with an -HL twin on the next line. Gated on defined over the zero-initialised bytes and duration totals (the defined-over-zero-init shape) plus max != 0. The occurrences twin gates on `$max_total{occurrences} != 0`. *(added by the verifier)*

### Verification notes

Sites reported 26, confirmed 26, refuted 0 (corrected above), added by the verifier 8, owning docs refuted 0.

- All 26 snippets were found inside the named subs. The line hints match exactly: count_mean at 17434/17456, bytes_mean at 17439/17461, the bytes/duration projections at 17425/17447, and the rest.
- Every owning doc path and cited heading exists: user-defined-metrics.md (Data Model, Per-Message Storage, Statistics, Highlight Behavior by Aggregation, Known Issues > Resolved), 432 (F1, Locked decisions, D5 at heading line 140, Status > Found and fixed while implementing), 516 (Decisions > D1, D2), 426 (Findings from the investigation (2026-08-24), which does mention the #330 observed-vs-defined gate at line 214), duration-statistics.md (Stores and primitives, Demand model). custom-metrics-record-count-stats.md and docs/explain/statistics.md exist; the inventory made no heading claims for them. All 8 harness files exist.
- Commit 6c6b172 exists: 'Issue #326: skip counting-aggregation UDMs in per-message mean derivation'.
- The claim that the #432 F1 doc is stale holds: features/432-metric-aggregate-naming-parity.md line 81 still quotes '# BUG/ WRONG!!! below assumes all lines have bytes', and that comment is no longer in ltl.
- The claim that raw mode has no duration count holds. duration_count is assigned only inside the `$message_stats_capture_mode eq 'bin'` and `$bucket_stats_capture_mode eq 'bin'` branches of read_and_process_logs, and in merge_bin_state.
- The bytes-demand claim holds. The per-message ($e = $log_messages{...}) and per-bucket ($e = $log_analysis{$bucket}) increments of bytes_occurrences both sit under `if( $bytes_aggregate_demand )`, while total_bytes accumulates outside that gate. The per-file index counter file_bytes_occurrences is unconditional.
- Count summary: the Welford running-mean derivation has 3 copies (two in read_and_process_logs, one in merge_bin_state), not 1. Adding the missed sites above brings the ratio-site total to 34 or more. There are also 2 more defined-over-zero-init sites: the normalize_data_for_output scaled_key and its -HL twin.
- The rule-violation list should add the pipeline_finalize `($keys_seen || 1)` divisor, which substitutes 1 for a zero count instead of gating on it (a -V diagnostic only).

### Questions for the findings discussion

Carried in the specification, § 4, under this item; the audit adds the evidence bearing on each here.


---

## Item 5: Filter and highlight range checks

**State: scoping pass recorded; audit not yet run.**

### Summary of the scoping pass

12 bound options (6 filter, 6 highlight; no count-of-lines or UDM bound options exist). 14 sites across 9 subs: value-vs-bound comparisons live only in read_and_process_logs (filter: 3 per-metric blocks = 3 undefined guards + 6 comparisons; highlight: 1 six-clause predicate); 1 min-vs-max check (inverted-range table in adapt_to_command_line_options); 8 hand-enumerations of the bound variable set. All comparison sites are inclusive at both ends. Zero shared comparison subs.

**Shared surface today.** None.

### Candidate findings (scoping pass; category and priority assigned by the audit)

- **F5.1** Two comparison codings of one closed interval, no shared sub: the filter in read_and_process_logs drops on the complement ('$duration < $filter_duration_min' / '$duration > $filter_duration_max', early next), while the highlight predicate in the same sub tests the positive form ('$duration >= $highlight_duration_min' / '$duration <= $highlight_duration_max'). Semantically equivalent today (both inclusive, both reject an undefined metric); the equivalence is maintained by hand across 6 filter comparisons plus 3 undefined-metric guards and 6 highlight clauses.
- **F5.2** Missing-metric accounting differs by family: the filter increments '$numeric_filter_no_metric{duration}++' and '$excluded_numeric++' when the metric is undefined; the highlight clause '( defined( $duration ) && ... )' just fails silently with no counter. By design per 312's 'Undefined metric' decision and 321's resolution (visibility only for the filter), so not a defect, but it is a behavioural asymmetry a shared predicate would have to keep.
- **F5.3** Exclusion reporting gated two different ways: write_aggregate_export emits 'excluded->{numeric}' only 'if grep { defined } ($filter_duration_min, ...)', while emit_filter_summary_verbose prints 'excluded_numeric: $excluded_numeric' unconditionally.
- **F5.4** The set of bound variables is hand-enumerated at eight places with different subsets: GetOptions (12), _classify_argv_provenance (12), emit_runtime_config_verbose (12), inverted-range table (12), has_active_filters (6 filter), serialize_filters (6 filter), write_aggregate_export grep (6 filter), $numeric_highlight_active grep (6 highlight). Only the inverted-range table pairs min/max/option-name per metric.
- **F5.5** Help wording differs across the filter rows only in phrasing: -dmin/-dmax say '(inclusive: entries exactly at N are kept)', -bmin/-bmax/-cmin/-cmax say '(inclusive)'; same in docs/usage.md rows 82-87. Semantics agree.

### Site inventory (scoping pass)

- `(GLOBALS)` :: `my ( $filter_duration_min, $filter_duration_max );` :: Declares the six filter bound globals (lines 303-305); the six highlight bound globals follow at 307-309 (my ( $highlight_duration_min, $highlight_duration_max );), plus $numeric_highlight_active (310) and %numeric_filter_no_metric (306). Twelve independent scalars, no structure grouping them by metric or by filter/highlight.
- `adapt_to_command_line_options` :: `'duration-min|dmin=i' => \$filter_duration_min,` :: GetOptions parsing of all twelve bounds, each =i (integer; negative integers accepted, no further value validation). Highlight twins at 14128-14133 ('highlight-duration-min|hdmin=i').
- `adapt_to_command_line_options` :: `$numeric_highlight_active = ( grep { defined }` :: Activation: numeric highlight is active iff any of the six highlight bounds is defined; feeds $highlight_active. Hand-enumerated list of six highlight vars.
- `adapt_to_command_line_options` :: `[ $filter_duration_min,    $filter_duration_max,    '-dmin',  '-dmax',  'no log entries can match'         ],` :: Inverted-range notice (issue 322): a 12-option table of [min, max, min_opt, max_opt, consequence]; warns on STDERR when both defined and $min > $max (strict, so equal bounds are silent, consistent with inclusive bounds). Only site that treats all twelve as one table. Warning text: 'Warning: $min_opt $min is greater than $max_opt $max - the range is unsatisfiable, $consequence'.
- `read_and_process_logs` :: `if( defined( $filter_duration_min ) && $duration < $filter_duration_min ) { $excluded_numeric++; next; }` :: Per-line hard filter, three copies (duration/bytes/count, 15600-15613). Order per metric: if any bound for the metric defined, undefined metric -> $numeric_filter_no_metric{metric}++ and $excluded_numeric++ then next; value < min -> drop; value > max -> drop. Kept set is the closed interval min <= v <= max (INCLUSIVE both ends), expressed as the complement with early exits.
- `read_and_process_logs` :: `( !defined( $highlight_duration_min ) || ( defined( $duration ) && $duration >= $highlight_duration_min ) )` :: Highlight tag-point numeric predicate, one inline boolean expression of six clauses (15657-15662) gated by $numeric_highlight_active, AND-composed with match_filter() and the outcome criteria. Positive form v >= min and v <= max (INCLUSIVE both ends); an undefined metric fails any given criterion on it. No counter for metric-less lines.
- `read_and_process_logs` :: `next unless $numeric_filter_no_metric{$metric};` :: Post-processing notice (issue 321): per metric, prints 'Note: N lines carried no <metric> value and were excluded by the <metric> filter ...' to STDERR. Filter side only; reports the count, not the bound values.
- `has_active_filters` :: `return 1 if defined $filter_duration_min || defined $filter_duration_max;` :: Active-filter detection for the index cache; enumerates the six filter bounds (highlight bounds deliberately absent per the 312 decision 'highlight options are not filters').
- `serialize_filters` :: `push @parts, "-bmax=$filter_bytes_max"       if defined $filter_bytes_max;` :: Index-cache filter signature; emits the six filter bounds as '-bmax=N' ... '-dmin=N' in fixed alphabetical order. Surfaces as -V 'index_filter_signature:'. Highlight bounds absent by design.
- `write_aggregate_export` :: `$excluded->{numeric}     = $excluded_numeric if grep { defined } ($filter_duration_min, $filter_duration_max, $filter_bytes_min, $filter_bytes_max, $filter_count_min, $filter_count_max);` :: YAML aggregate export (-o): emits population.lines.excluded.numeric only when any of the six filter bounds is defined. Fourth hand-enumeration of the six filter vars.
- `emit_filter_summary_verbose` :: `push @verbose_output, "excluded_numeric: $excluded_numeric";` :: -V filter-summary section: reports the numeric-filter exclusion count unconditionally (not gated on any bound being defined, unlike the aggregate export). Bound values themselves not reported here.
- `emit_runtime_config_verbose` :: `'duration-min'                      => $filter_duration_min,` :: -V runtime-config resolved-values registry: all twelve bounds listed as long-name => variable (2566-2579), printed as e.g. 'highlight-duration-min: 100'.
- `_classify_argv_provenance` :: `'highlight-duration-min|hdmin', 'highlight-duration-max|hdmax',` :: Static long|short name map for runtime-config provenance; lists all twelve bound options (2426-2432).
- `print_help` :: `help_opt("-dmin, --duration-min <N>",     "Hide log entries with duration below this threshold (inclusive: entries exactly at N are kept)");` :: User-facing help rows for all twelve (9880-9891) plus the note at 9893 stating inclusive semantics, missing-metric exclusion and the inverted-range warning. Mirrored in docs/usage.md rows 82-93 and prose at lines 64, 66, 107.
- `lines_excluded_total` :: `return $excluded_time_window + $profile_dropped_samples + $excluded_filter + $excluded_numeric + $excluded_other;` :: Adds the numeric-filter exclusion count into the total of excluded lines, unconditionally (no check that any filter bound is defined). This is a third consumer of $excluded_numeric besides the -V filter summary and the aggregate export. *(added by the verifier)*
- `adapt_to_command_line_options` :: `$highlight_active = ( defined($highlight_filter) || $numeric_highlight_active` :: Combines numeric-highlight activation with the regex highlight and the outcome highlights into $highlight_active. The inventory mentions this in the activation site's role text but has no site entry for it. *(added by the verifier)*
- `read_and_process_logs` :: `&& ( !$numeric_highlight_active || (` :: Hot-loop gate that wraps the six-clause highlight predicate (line 15656). It is the mechanism behind the 312 hot-loop rule that the predicate runs only when a numeric highlight is given. The inventory describes it but does not list it as a site. *(added by the verifier)*

### Verification notes

Sites reported 14, confirmed 14, refuted 0 (corrected above), added by the verifier 3, owning docs refuted 0.

- The per-line filter snippet ('if( defined( $filter_duration_min ) && $duration < $filter_duration_min )') is at line 15602, not 15600. Line 15600 is the per-metric guard 'if( defined( $filter_duration_min ) || defined( $filter_duration_max ) ) {', and the undefined-metric drop is at 15601. The sub attribution is correct.
- The _classify_argv_provenance snippet ('highlight-duration-min|hdmin') is at line 2430, not 2426. The twelve names run from 2426 ('duration-min|dmin') to 2432 and share one static list with unrelated options, so they are not a separate block. The sub attribution is correct.
- Every snippet exists and sits in the named sub. The GLOBALS site at line 303 comes before '## SUBS ##' at line 1360, as expected.
- Grepping every use of (filter|highlight)_(duration|bytes|count)_(min|max) turns up no bound-variable site beyond those listed. So the inventory's coverage of the twelve bound variables is complete.
- There are 3 consumers of $excluded_numeric, not 2: lines_excluded_total, emit_filter_summary_verbose and write_aggregate_export. Only write_aggregate_export checks that a filter bound is defined, so the observed divergence in how exclusions are reported covers all three.
- Checked and present: all headings cited in features/312-numeric-criteria-highlight-selection.md (Decisions table rows, Design / Core mechanism, Index cache, -V runtime-config, Related findings), plus 455 D6 and D7, features/478-highlight-decision-read-back.md, and docs/usage.md '### Filtering & Highlighting' at line 60 with option rows 82-93.
- The listed harnesses are not the only ones that pass these options. tests/validate-format-detection.sh, validate-histogram-bin-counters.sh, validate-udm-counting.sh and validate-statistics-demand.sh also mention dmin, hdmin or excluded_numeric. Whether they read this surface or only pass the options as invocation settings was not checked.
- User-facing examples that use these options without doing any logic: the explain text ('ltl -hdmin 5000 access.log', 'ltl -hdmin 60000 ...') and the help examples ('ltl -dmin 5000 access.log'). They are not comparison sites, but a change to an option surface would have to update them too.

### Questions for the findings discussion

Carried in the specification, § 4, under this item; the audit adds the evidence bearing on each here.


---

## Item 6: CSV emission column lists

**State: scoping pass recorded; audit not yet run.**

### Summary of the scoping pass

Two CSV files with 2 header sites and 2 row sites: MESSAGES header in pipeline_render and row in print_message_summary; STATS header built in normalize_data_for_output, written in pipeline_render, row in print_bar_graph. Around them sit 1 parallel family-name table (%csv_column_family) plus its pattern resolver, 1 parallel walk in the YAML aggregate export (write_aggregate_export), and 1 index CSV declared twice (write_index_file, read_index_file). Shared parts: @duration_family_stats (3 of 4 duration sites; MESSAGES is the exception), udm_csv_columns() (5 consumers), 2 gate predicates. Literal copies: bytes family 4x, count family 4x, user-defined-metric fallback list 3x plus the one inside udm_csv_columns(), duration names 1 extra hand copy (MESSAGES header) plus 21 row tags. Outside ltl, the column names are kept a third time in tests/csv-output/rules/messages-columns.tsv (52 lines) and stats-columns.tsv (136 lines). One family-label divergence exists today (std_dev and cv as shape vs dispersion, impact as shape vs duration), and the stated mirror comment is wrong about it.

**Shared surface today.** No one declaration covers either CSV. The only shared parts are partial. @duration_family_stats covers the duration family on the STATS header, STATS row and aggregate export, but not on the MESSAGES CSV. udm_csv_columns() covers user-defined-metric columns on all four CSV sites and the aggregate export. stats_csv_duration_columns_active() and stats_csv_bytes_columns_active() are shared gates, not name lists. On the STATS side, @output_columns is the header list, and the row reads it only for the category segment (up to 'occurrences'); everything after that is rebuilt by a parallel walk of @populated_graph_columns.

### Candidate findings (scoping pass; category and priority assigned by the audit)

- **F6.1** The precision-family labels disagree today between ltl and the rules TSVs. The %csv_column_family comment says 'Mirrors the family annotations in tests/csv-output/rules/{messages,stats}-columns.tsv', but ltl has `'duration_std_dev'  => 'shape'` and `'duration_cv'       => 'shape'` where both TSVs have `duration_std_dev ... dispersion` and `duration_cv ... dispersion`. ltl also has `'impact'            => 'shape'` where messages-columns.tsv has `impact\t41\tfloat\tconditional:duration\t5\tduration`. ltl has no 'dispersion' family at all; the harness uses the TSV family for its group-consistency check and the drift engine uses it for its per-family rollup. I did not run anything to see whether the emitted decimals differ.
- **F6.2** The STATS header and row walk @populated_graph_columns in two separate if/elsif chains that must stay in step. The header loop in normalize_data_for_output adds `"${key}_nice" if $key =~ /^(duration|bytes)$/`. The row loop in print_bar_graph matches `$key =~ /^(time|duration)$/i` and pushes two values (nice and raw). No 'time' key exists in @graph_columns (`qw( duration bytes count )`), so that alternation is dead today. If it ever matched, the row would emit one more field than the header.
- **F6.3** The bytes family (occurrences min mean max) is written as a literal list four times: `push @output_columns, qw( bytes_occurrences bytes_min bytes_mean bytes_max );` (STATS header), `foreach my $metric ( qw( occurrences min mean max ) )` (STATS row), `for grep { defined $stats->{"bytes_$_"} } qw(occurrences min mean max)` (aggregate export), and the MESSAGES qw. The four copies agree today.
- **F6.4** The count family (occurrences min mean max sum) is written as `"${key}_occurrences", "${key}_min", ...` in the STATS header, `qw( occurrences min mean max sum )` in the STATS row, a qw in the aggregate export and the MESSAGES qw. The user-defined-metric fallback `qw(occurrences min mean max sum)` appears again in the header, the row and the aggregate export, separate from the `my @stats = qw(occurrences min mean max sum);` inside udm_csv_columns(). They agree today.
- **F6.5** MESSAGES: the header qw has 41 names and the row list has 41 values. Pairing them by position, every tagged value's format_csv_value column name matches its header name, and the four untagged slots are category, message, bytes_nice and duration_nice. They agree today, but only because the two lists were written by hand to match; the duplicated duration names do not come from @duration_family_stats.
- **F6.6** STATS err-rate/msg-rate: the header written in pipeline_render uses `"err-rate$rate_csv_suffix{$rate_unit}"`, while the row formats the value under the bare name (`format_csv_value($output_columns{$category_bucket}, $category_bucket)`). Both resolve to the 'level' family with the rate override, so the output is the same, but header and row spell the column differently.
- **F6.7** ltl-index.csv: `my @index_columns = qw(` is declared twice with identical contents, once in write_index_file and once in read_index_file. The write-side rows are positional lists that parallel it.

### Site inventory (scoping pass)

- `(GLOBALS)` :: `my @duration_family_stats = qw( min mean max std_dev p1 p5 p10 p25 p50 p75 iqr p90 p95 p99 p999 p9999 p99999 cv skewness kurtosis bimodality_coef );` :: The one shared declaration in this area: the duration statistics in column order. The STATS header, the STATS row and the aggregate export read it. The MESSAGES CSV does not; it spells the same 21 names out by hand.
- `normalize_data_for_output` :: `push @output_columns, "timestamp";` :: Starts the STATS CSV header list (@output_columns, a global declared as `my ( @in_files, @output_columns );`), then pushes the category columns in @log_levels order.
- `normalize_data_for_output` :: `push @output_columns, "successes", "failures", "conflicts";` :: STATS header: the occurrences column plus the three outcome-count columns.
- `normalize_data_for_output` :: `# Build @populated_graph_columns and @output_columns (still needed for scaling and CSV)` :: STATS header: walks @graph_columns, building @populated_graph_columns and the metric headers in the same loop. It adds the _nice columns, the count family written as literal strings, the user-defined-metric columns via udm_csv_columns() with a literal fallback list, and the sessions/users -HL twins.
- `normalize_data_for_output` :: `push @output_columns, qw( bytes_occurrences bytes_min bytes_mean bytes_max );` :: STATS header: the CSV-only bytes family and duration family, each gated on its shared predicate (stats_csv_bytes_columns_active / stats_csv_duration_columns_active).
- `stats_csv_duration_columns_active` :: `return ($write_messages_to_csv && !$omit_durations && $durations_observed) ? 1 : 0;` :: Shared gate that the STATS header push and row push both call (its comment says 'MUST both call this'). stats_csv_bytes_columns_active is the same pattern for bytes. The aggregate export also calls both.
- `pipeline_render` :: `if    ($_ eq 'err-rate') { "err-rate$rate_csv_suffix{$rate_unit}" }` :: Writes the STATS header. It maps @output_columns, renaming err-rate and msg-rate to their unit-suffixed spellings, then calls $csv->print. The rename happens only here: the row side formats those values under the bare names.
- `print_bar_graph` :: `last if $category_bucket =~ /^occurrences$/;` :: STATS row: re-walks the @output_columns header list to emit category counts, stopping at 'occurrences'. This is the one place where the row reads the header list directly.
- `print_bar_graph` :: `# 'successes','failures' header pushes in normalize_data_for_output().` :: STATS row: occurrences plus the outcome counts, kept in step with the header by a comment only.
- `print_bar_graph` :: `# @populated_graph_columns in the SAME order as the @output_columns` :: STATS row: a second if/elsif over @populated_graph_columns that mirrors the header loop's branches. It has its own literal count stat list and its own user-defined-metric fallback list.
- `print_bar_graph` :: `foreach my $metric ( qw( occurrences min mean max ) ) {` :: STATS row: the bytes family written out as a second literal list, parallel to the header's qw list. The duration family follows and reads @duration_family_stats.
- `print_bar_graph` :: `push @row, (undef) x ( $target_width - scalar @row ) if scalar @row < $target_width;` :: STATS row: pads a short row with empty fields up to the header width. This hides a row that comes out shorter than the header.
- `pipeline_render` :: `$csv->print($csv_fh, [qw(category message occurrences successes failures conflicts bytes_occurrences bytes_min bytes_mean bytes_max bytes bytes_nice count_occurrences` :: MESSAGES header: 41 fixed names in one literal qw list, then the user-defined-metric headers from udm_csv_columns().
- `print_message_summary` :: `format_csv_value($occurrences,       'occurrences'),` :: MESSAGES row: a positional list of 41 values that parallels the header's qw. 37 of them repeat the column name as the format_csv_value family tag, which makes the names a second copy. The four untagged slots are category, message, bytes_nice and duration_nice.
- `print_message_summary` :: `? format_csv_value($log_messages{$grouping}{$key}{"udm_${name}_occurrences"}, $csv->{columns}[0])` :: MESSAGES row, user-defined-metric tail: reads udm_csv_columns() like the header does, so these columns share one declaration.
- `udm_csv_columns` :: `return { shape => 'family', stats => \@stats, columns => [ map { "${prefix}_$_" } @stats ] };` :: Declares the user-defined-metric CSV columns. Its comment says it exists so that header and row 'can never disagree about shape or spelling'. It returns the column names and the accumulator for each column, and the STATS header, STATS row, MESSAGES header, MESSAGES row and aggregate export all call it. It is the template the rest of the CSV columns could follow.
- `file scope in SUBS, before resolve_csv_column_family` :: `my %csv_column_family = (` :: %csv_column_family: a third hand-kept list of the fixed column names, mapping each name to a precision family. Its comment says it mirrors the rules TSV family annotations.
- `resolve_csv_column_family` :: `return 'count' if $column =~ /_(min|mean|max|sum|occurrences)$/;` :: Resolves families for dynamic columns (levels, rates, user-defined metrics) by pattern, outside the static table.
- `write_aggregate_export` :: `# The STATS CSV column families, in the order the row writes them.` :: YAML aggregate export, bucket series: a third walk over @populated_graph_columns in STATS order. It has its own literal bytes list (occurrences min mean max) and count list (occurrences min mean max sum), and reads @duration_family_stats and udm_csv_columns(). Its keys are YAML mapping keys, not CSV headers.
- `write_index_file` :: `my @index_columns = qw(` :: ltl-index.csv header on the write side. Each row (@file_row, @sel_row) is a positional list that parallels it.
- `read_index_file` :: `next unless @$row >= scalar(@index_columns);` :: ltl-index.csv read side. It declares a second, identical copy of @index_columns and maps values to columns by position.
- `build_column_layout` :: `my $show_latency = $durations_observed && !$omit_durations && !$hide_stats && !$heatmap_enabled;` :: Display column declaration: the timestamp, legend, success_pct/failure_pct, separator, occurrences/duration/bytes/count, latency or heatmap columns, as hashes with id, type, name, width, spacing, visible, color and hide_order. There is no CSV field.
- `add_dynamic_column` :: `my ($columns_ref, $id, $name, $color_index, %opts) = @_;` :: Adds the sessions, users, thread-pool and user-defined-metric columns to @column_layout as single proportional columns (one id per metric). It carries no CSV sub-columns, statistic list or -HL twin.
- `adapt_to_command_line_options` :: `do { print_usage( "invalid sort type used" ); exit 1; } unless grep { lc $_ eq lc $sort_type } qw(` :: The -so sort-operand allow-list. It spells out bytes_occurrences bytes_min bytes_mean bytes_max, count_occurrences..count_max and the full duration stat/percentile/shape names (unprefixed) as a separate literal list. An elsif ladder follows that maps each operand to a sort key (e.g. '} elsif( $sort_type =~ /^bytes_occurrences$/i ) {'). features/432 D8 names this as a consumer of the same bytes_* vocabulary. The inventory raised it only as an open question and did not list it. *(added by the verifier)*
- `print_help` :: `$out .= help_opt("-so,  --sort-on <field>",` :: A hand-written copy of the same aggregate, stat and percentile name list in the -so help row (bytes_occurrences, bytes_min, ... count_max, impact, p1..p99999, iqr, skewness, kurtosis, bimodality_coef). *(added by the verifier)*
- `print_message_summary` :: `my $bytes_occurrences = $log_messages{$grouping}{$key}{bytes_occurrences};` :: MESSAGES row: per-column local variables are pulled from %log_messages before the positional format_csv_value list. This is a third per-column spelling on the MESSAGES side that must match the header qw and the tags. *(added by the verifier)*
- `write_index_file` :: `$csv->print(` :: ltl-index.csv has four separate $csv->print row/header emits (lines 6827, 6830, 6857, 6875) with positional rows. The inventory named @file_row/@sel_row but not the count of emit sites. *(added by the verifier)*

### Verification notes

Sites reported 23, confirmed 20, refuted 3 (corrected above), added by the verifier 4, owning docs refuted 0.

- The line hints are off by 1-5 lines for several sites. Actual lines: stats_csv_duration_columns_active return 18792; the err-rate rename in pipeline_render 22059; 'last if $category_bucket =~ /^occurrences$/;' 19738; the successes/failures comment 19755; the row padding 20006; the MESSAGES row format_csv_value($occurrences...) 21517; the udm_csv_columns return 10290; resolve_csv_column_family's count regex 13257.
- 'my @index_columns = qw(' occurs at line 1915 (read_index_file, which starts at 1903) and line 6755 (write_index_file, which starts at 6752). Both attributions hold. The read_index_file site's snippet 'next unless @$row >= scalar(@index_columns);' is at line 1934.
- @duration_family_stats (line 323) is confirmed in GLOBALS (lines 64 to 1360). Its consumers are exactly write_aggregate_export (6650), normalize_data_for_output (19093) and print_bar_graph (19994). print_message_summary does not use it.
- udm_csv_columns() has exactly 5 callers, as claimed: write_aggregate_export 6678, normalize_data_for_output 19069, print_bar_graph 19961, print_message_summary 21496 and pipeline_render 22084.
- Family divergence confirmed. In ltl, 'duration_std_dev', 'duration_cv' and 'impact' map to 'shape' (lines 13234, 13235, 13238). Both rules TSVs give dispersion for duration_std_dev and duration_cv, and messages-columns.tsv gives impact as the duration family. 'dispersion' does not occur anywhere in ltl.
- @graph_columns is confirmed as 'qw( duration bytes count )' (line 247), so a 'time' match in the STATS row loop cannot happen.
- Rules TSV line counts are confirmed: messages-columns.tsv has 52 lines and stats-columns.tsv has 136. The per-row field-count check 'if (scalar(@$row) != scalar(@$header_row))' is confirmed at line 136 of tests/csv-output/validate-csv-output.pl, and the 'unknown column' rule at line 285.
- Every owning doc heading exists: column-layout-refactor.md Goals (37), Architectural Principle (301), Required Separation (313), Automatic Visibility (323), Identified Problem Areas (333), 5. Column Selection Scatter (377); 432 D3 (116), D5 (140), D8 (163), D7 (188); 224 Decision 5 (162), Decision 10 (271); 503 '-V aggregate-export section contract (locked as built, 2026-09-03; ...)' (390); tests/csv-output/README.md Rules TSV schema (56), Updating rules when columns change (97). features/452-success-failure-percentage-columns.md exists. The three harnesses exist.

### Questions for the findings discussion

Carried in the specification, § 4, under this item; the audit adds the evidence bearing on each here.


---

## Item 7: Message-key construction

**State: scoping pass recorded; audit not yet run.**

### Summary of the scoping pass

5 copies of the ternary cut: 4 in read_and_process_logs (key variants level+thread+object, level+object, level+thread, level only) and 1 in group_similar_messages (canonical re-cut, where the ternary always picks 350). The cut length has 2 spellings: a literal 350 at those 5 sites and $consolidation_message_length_cap = 350 at 10 consolidation re-cut sites. $max_log_message_length has 1 declaration, 1 assignment (terminal width, in adapt_to_terminal_settings) and 6 readers (the 5 key sites plus one -V benchmark-data line). The key shape is parsed back from its first bracket at 5 sites in group_similar_messages. On the harness side: 3 assert exact bracketed keys from the MESSAGES CSV (expose with 31 literal-prefix lines, mask with 20, discard with 1 prefix constant); 3 freeze the key indirectly (control-characters through the render and column 2, grouping through the cluster-membership records, regression through 74 terminal-width references); csv-output only substring-matches the message column; histogram-bin-counters only asserts the '(category, log_key)' keying label. The 350 cut appears in no user doc.

**Shared surface today.** None.

### Candidate findings (scoping pass; category and priority assigned by the audit)

- **F7.1** The 350 cut has two spellings: a literal 350 inside the ternary at all five key sites (read_and_process_logs: substr("[$log_level] ... $message", 0, (... ? 350 : $max_log_message_length)); group_similar_messages: substr($canonical, 0, (... ? 350 : $max_log_message_length))), and the named global $consolidation_message_length_cap = 350 used by every consolidation re-cut (substr($log_key, 0, $consolidation_message_length_cap) in read_and_process_logs and group_similar_messages, get_consolidation_trigrams, run_consolidation_pass, try_consolidation_merge_into_existing, consolidation_cliff_edge). Same value today, nothing ties them.
- **F7.2** The ternary at group_similar_messages 'my $canonical_log_key = substr($canonical, 0, (($write_messages_to_csv == 1 || $group_similar_sensitivity ne "none") ? 350 : $max_log_message_length));' can only ever pick 350: pipeline_finalize calls group_similar_messages() only inside 'unless( $group_similar_sensitivity eq "none" )'. The $max_log_message_length branch is dead there.
- **F7.3** S1 inline in read_and_process_logs does 'my $capped_msg = substr($log_key, 0, $consolidation_message_length_cap);' right after $log_key was already cut to 350 under the same -g condition, so the second cut does nothing.
- **F7.4** -V benchmark-data prints 'CONFIG\tmax_log_message_length' as $max_log_message_length (terminal width, set in adapt_to_terminal_settings), but under -o or -g the key is actually cut at 350, so the reported value is not the length keys were built with in those runs.
- **F7.5** Grouping key has two derivations: S1 inline uses 'my $grouping_key = $log_level // "";' directly, while group_similar_messages recovers it by parsing the key, 'my ($grouping_key) = $log_key =~ /^\[([^\]]+)\]/;' (four sites). They agree only because every key variant puts [$log_level] first.
- **F7.6** features/fuzzy-message-consolidation.md IQ-01 says the grouping key is "$log_level|$truncated_thread|$truncated_object|$session" and that similarity is scored on $message alone. In code the grouping key is the level only ("$category|$grouping_key"), and thread and object stay inside the scored text ($capped_msg is cut from $log_key). The doc's own implementation notes admit this for v0.14.4.
- **F7.7** features/fuzzy-message-consolidation.md IQ-02 says $max_observed_message_length is tracked 'on $message body, not full $log_key'. read_and_process_logs does 'my $msg_len = length($log_key);'.
- **F7.8** features/fuzzy-message-consolidation.md IQ-01 describes session being prepended to $message under --include-session. In current code session reaches the message as an appended ' session=<value>' through the -x expose loop (EXPOSE_SESSION in @expose_appends), not as a key field.
- **F7.9** Field cuts are written three ways inside read_and_process_logs: thread 'substr($threadname, 0, 20)' (a literal 20, first characters), object through the local 'my $max_object_length = 25;' (last characters), and the key cut through the ternary. None of them is a named global.

### Site inventory (scoping pass)

- `read_and_process_logs` :: `$log_key = substr("[$log_level] [$truncated_thread] [$truncated_object] $message", 0,` :: Key variant 1: level + thread + object + message, cut at 350 when -o or -g is active, else at $max_log_message_length (terminal width)
- `read_and_process_logs` :: `$log_key = substr("[$log_level] [$truncated_object] $message", 0,` :: Key variant 2: level + object + message, same ternary cut
- `read_and_process_logs` :: `$log_key = substr("[$log_level] [$truncated_thread] $message", 0,` :: Key variant 3: level + thread + message, same ternary cut
- `read_and_process_logs` :: `$log_key = substr("[$log_level] $message", 0,` :: Key variant 4: level + message only, same ternary cut
- `read_and_process_logs` :: `my $truncated_thread = defined($threadname) ? substr($threadname, 0, 20) : undef;` :: Field preparation: thread cut to its first 20 characters, object to its last 25 ($max_object_length = 25, a local) before the key is assembled; $log_level is $status_code when > 0 else $category_bucket with -HL stripped
- `read_and_process_logs` :: `my $capped_msg = substr($log_key, 0, $consolidation_message_length_cap);` :: S1 inline consolidation input: re-cuts the already-cut key at the named 350 global (a no-op under -g, since the key is already at most 350); also tracks $max_observed_message_length on length($log_key)
- `group_similar_messages` :: `my $canonical_log_key = substr($canonical, 0, (($write_messages_to_csv == 1 || $group_similar_sensitivity ne "none") ? 350 : $max_log_message_length));` :: Fifth copy of the ternary cut: re-cuts a cluster's canonical form (from derive_canonical) before injecting it into %log_messages; the ternary is always 350 here because pipeline_finalize only calls group_similar_messages under unless( $group_similar_sensitivity eq "none" )
- `group_similar_messages` :: `my ($grouping_key) = $log_key =~ /^\[([^\]]+)\]/;` :: Parses the key shape back: recovers the grouping key (level) from the first bracket; appears at four sites (hints 10855, 10873 as $gk, 10915, 10966)
- `group_similar_messages` :: `my ($msg_a) = $a =~ /^\[[^\]]+\]\s*(.*)/s;` :: Parses the key shape back: strips the first bracket to sort on the remaining text
- `group_similar_messages` :: `"  cluster: $category\x1f$canonical_log_key";` :: -V message-grouping / cluster-membership record carries the canonical key verbatim
- `merge_log_message_entry_into_cluster` :: `my $key = "$category\x1f$log_key";` :: Composite counter-store key over the message key (also at read_and_process_logs hint 16028, group_similar_messages hint 11050, and two sites near 17717/17883)
- `(GLOBALS)` :: `my $max_log_message_length = 0;` :: Declaration of the terminal-mode cut
- `adapt_to_terminal_settings` :: `$max_log_message_length = $terminal_width;` :: Only assignment of the terminal-mode cut: equal to terminal width
- `(GLOBALS)` :: `my $consolidation_message_length_cap = 350;` :: Named 350 constant used by consolidation (get_consolidation_trigrams, run_consolidation_pass, try_consolidation_merge_into_existing, consolidation_cliff_edge, S1 inline); never reassigned, not an option; the key-construction sites use a literal 350 instead
- `print_verbose_output` :: `printf "CONFIG\tmax_log_message_length\t%d\n", $max_log_message_length;` :: -V benchmark-data reports the terminal-mode cut; read by benchmark TSVs under tests/baseline/results/
- `print_message_summary` :: `my $message = substr( $key, 0, $col_width{1} );` :: Second, display-only cut of the key to the message column width
- `read_and_process_logs` :: `$message =~ tr/\x00-\x08\x0a-\x1f\x7f//d;` :: Control-character normalisation of $message upstream of key construction (447 D2), gated on $is_line_match
- `consolidation_process_key` :: `$consolidation_key_message{$log_key} = $capped_msg;` :: Second key-to-text map: stores the 350-capped copy of the key for keys S1 did not absorb, alongside $consolidation_key_message_cat_gk{$log_key} = $cat_gk. The consolidation re-cut sites in run_consolidation_pass and process_final_pass_window read it. *(added by the verifier)*
- `process_final_pass_window` :: `$consolidation_key_message{$log_key} = $capped_msg;` :: Refills the same key-to-capped-text map for window keys; the same sub re-cuts it again at 'my $msg_a = substr($consolidation_key_message{$log_key} // '', 0, $consolidation_message_length_cap);' *(added by the verifier)*
- `read_and_process_logs` :: `$log_level =~ s/-HL$//;` :: Prepares the key's level field: follows 'my $log_level = $status_code > 0 ? $status_code : $category_bucket;'. The inventory mentions it only inside the role of another site; it has no site entry of its own. *(added by the verifier)*
- `read_and_process_logs` :: `$message =~ s/$m->[0]/$m->[1]/g;` :: -m mask applied to $message just before the key is assembled (upstream of the 350 cut; this is the ordering the 580 feature doc's truncated-key note is about) *(added by the verifier)*
- `calculate_all_statistics` :: `$log_messages_counters{"$category\x1f$log_key"},` :: Composite counter key over the message key, two sites; the inventory gives these only as line hints (17717/17883) with no sub named *(added by the verifier)*
- `print_threadpool_summary` :: `my $message = substr( $key, 0, $col_width{1} );` :: The same display cut snippet also appears here, cutting a threadpool key rather than a message key. A grep -F for the print_message_summary snippet returns both lines. *(added by the verifier)*

### Verification notes

Sites reported 17, confirmed 17, refuted 0 (corrected above), added by the verifier 6, owning docs refuted 0.

- Wrong count: the inventory says $consolidation_message_length_cap is used at 10 consolidation re-cut sites. There are 9 readers besides the declaration: group_similar_messages x2 (hints 10914, 10965), get_consolidation_trigrams x1 (11106), run_consolidation_pass x2 (12019, 12020), process_final_pass_window x2 (12163, 12164), consolidation_cliff_edge x1 (12377), read_and_process_logs S1 inline x1 (15811).
- Wrong sub named: the inventory lists try_consolidation_merge_into_existing among the users of $consolidation_message_length_cap. It does not use it. The missing user is process_final_pass_window.
- The capped_msg snippet 'my $capped_msg = substr($log_key, 0, $consolidation_message_length_cap);' is not unique. It matches three lines: read_and_process_logs at 15811, and group_similar_messages at 10914 and 10965. The site as attributed holds, but the two group_similar_messages re-cuts should be listed as sites of their own.
- The grouping-key parse snippet matches three lines verbatim (10855, 10915, 10966). The fourth site (10873) is spelled 'my ($gk) = $log_key =~ /^\[([^\]]+)\]/;', which the inventory already notes. Confirmed.
- The (GLOBALS) sites: 'my $max_log_message_length = 0;' (line 235) and 'my $consolidation_message_length_cap = 350;' (line 749) both sit between '## GLOBALS ##' (line 64) and '## SUBS ##' (line 1360). Confirmed.
- Divergence confirmed: the fifth ternary copy, in group_similar_messages, is dead on its $max_log_message_length branch. Its only call, 'group_similar_messages();', sits inside 'unless( $group_similar_sensitivity eq "none" )' in pipeline_finalize.
- Divergences confirmed from the code: S1 takes the grouping key directly with 'my $grouping_key = $log_level // "";', and observed length is measured on the whole key with 'my $msg_len = length($log_key);'.
- The literal 350 appears at exactly 6 lines (the 5 ternary sites plus the cap declaration), and $max_log_message_length at 1 declaration, 1 assignment and 6 readers. Both counts confirmed.
- Every owning doc path and heading exists: fuzzy-message-consolidation.md DD-06, IQ-01 and IQ-02 (headings struck through and marked RESOLVED); 447 D2, D5 and Affected surfaces; the 580 truncated-key note; the 350 context in 150; 528. All 8 harness paths exist.

### Questions for the findings discussion

Carried in the specification, § 4, under this item; the audit adds the evidence bearing on each here.


---

## Item 8: The structure of the per-line loop

**State: scoping pass recorded; audit not yet run. This item is drop 2 of the
issue: its measurement runs in the background while items 1 to 7 and the patterns
sweep are triaged, and its record lands here when the analysis is written.**

### Summary of the scoping pass

The loop body (15085-16427, after the scan sub has returned) holds about 107 test sites of run-constant values, not counting the per-config tests inside the UDM loop that only run when UDM is set. By group:
- progress/diagnostics 2
- UDM 2 gates plus 3 unguarded foreach loops over @udm_configs
- discard/expose/mask 5 gates plus 5 inner lookups
- metric omission 12 ($omit_count 3, $omit_bytes 4, $omit_durations 5)
- -du 2
- time window and profile 3, plus the absolute range compare, which always runs
- filters 6 outer plus 10 inner
- highlight 1 compound gate with 12 inner terms
- bucket precision 1
- message capture and consolidation 16 (the key-length expression written 4 times but run once per line; $message_stats_capture_mode eq 'bin' 5 times)
- bucket statistics 8
- heatmap 1 outer plus 5 inner
- histogram 1 plus 1 plus 8 metric-selection tests plus 2 UDM loops
- threadpool 1 compound (3 terms)
- sessions/users 0
- index-file tracking 0 (runs under -ni)

Also in the body: about 20 $line_is_highlighted read-back sites (constant false when highlight is off), 2 per-entry reads of FR_PCT_QUALIFYING, and file-scoped tests ($csv_detected, $csv_epoch_timestamp, $from_window, the classification-signature compare). Only 2 run options are compiled into the generated scan sub: include_query_string and expose_metric. $show_classification is folded into an entry attribute at build. The measured per-line statement count on the access-log path is 114 (NYTProf, 100k lines). These counts come from reading the source, not from a profile.

**Shared surface today.** Loop body: none. No sub owns the run-constant gates; each one is an inline scalar or hash test in read_and_process_logs(). A few options are folded ahead of time: capture modes are set once before the loop ($heatmap_capture_mode, $histogram_capture_mode, $message_stats_capture_mode, $bucket_stats_capture_mode from choose_data_model()), and the statistics-demand flags are settled during option processing. The loop still tests all of them per line, some as string eq compares. Scan sub: format_scan_sub_resolve() (signature cache) with compile_format_scan_sub() (code generation), fed by build_format_registry(), which stores $format_registry_opts and clears %format_scan_sub_cache. build_format_registry() itself compiles nothing: under D60 (elevation by election), sub generation happens at election, promotion, occupant swap or pin. format_registry_set_occupant() does its own cache lookup-or-compile inline.

### Candidate findings (scoping pass; category and priority assigned by the audit)

- **F8.1** Two cache paths disagree with the resolve sub's own comment. format_scan_sub_resolve()'s header says 'Every point that changes the order and needs the sub live again routes through here — occupant swaps, promotion, election, the pre-line-1 fallback'. Yet format_registry_set_occupant() recomputes 'my $sig = join ',', map { $_->[FR_NAME] } @format_scan_order;' and runs '$format_scan_sub = $format_scan_sub_cache{$sig} //= compile_format_scan_sub($format_registry_opts);' inline. It skips '$format_scan_sub_cache_hits++ if exists $format_scan_sub_cache{$sig};', so the scan_sub_cache_hits telemetry does not count cache hits from occupant swaps.
- **F8.2** The key-length expression '($write_messages_to_csv == 1 || $group_similar_sensitivity ne "none") ? 350 : $max_log_message_length' is written out four times in read_and_process_logs() (the four key branches at 15798/15800/15802/15804) and once more in group_similar_messages() ('my $canonical_log_key = substr($canonical, 0, (($write_messages_to_csv == 1 || ...'). The copies are identical today, and each is recomputed per retained message even though its value is fixed for the run.
- **F8.3** The CSV data-line arm ('if ($csv_detected) {' ... '$line_entry->[FR_CLASSIFY]->($_);') and the lazy-detection confirm arm ('# Confirmed CSV — process line 2 as data' ... '$line_entry->[FR_CLASSIFY]->($_);') restate the same sequence: timestamp trim, epoch test, message from -ucm, DATA category, record reset, classify. The only difference is that the steady arm guards its epoch test with '$line_number == 2' and the confirm arm tests unconditionally; both apply only on line 2 in practice. Duplicated, but not diverging today.
- **F8.4** The same '$format_detection{$in_file} //= { match_type => undef, slug => undef, ... first_match_line => undef, }' initialiser appears inside the loop (per matched line) and again after it (the per-file telemetry block). The two key lists are identical today.
- **F8.5** The Welford-Pebay update is restated for per-message statistics ('if ($message_stats_capture_mode eq 'bin') { my $entry = $log_messages{$category}{$log_key};' ... '$entry->{duration_count} = $n;') and for per-bucket statistics ('if ($bucket_stats_capture_mode eq 'bin') { my $entry = $log_analysis{$bucket};' ... '$entry->{duration_count} = $n;'). The only difference is the counter call: the bucket one passes $bucket_stats_buckets_per_decade and the message one does not.

### Site inventory (scoping pass)

- `read_and_process_logs` :: `while (1) {` :: Start of the per-line loop. It runs from line 15085 to the closing brace at 16427, just before 'close $fh;' (1,343 physical lines, 830 not blank or comment). The sub itself runs 14931-16549 (1,619 physical lines, 1,008 code lines). Outside the loop: per-file setup (index record, CSV state reset, detection sample, format_scan_sub_resolve(), window pre-read), and after it the per-file telemetry.
- `read_and_process_logs` :: `if ( $line_entry = $format_scan_sub->($_) ) {` :: Where the loop hands off to the generated scan sub. It sits in the else-arm of 'if ($csv_detected)'. The sub writes the 13 record lexicals, $timestamp/$fractional_ms and $line_outcome/$line_cls_sig directly and returns the winning entry. Everything after this point is loop-body code.
- `read_and_process_logs` :: `if ($window_entry && $window_entry->[FR_EXTRACT]->($_)) {` :: Replay of held detection-window lines. The classification was already made, so only the entry's FR_EXTRACT closure runs. The '$from_window' test runs on every line (file-scoped state, not a run option).
- `read_and_process_logs` :: `memory_debug_sample("read_lines") if $show_memory_debug` :: Progress/diagnostics gate. Run-constant $show_memory_debug is tested on every line read.
- `read_and_process_logs` :: `if ($total_lines_read % PROGRESS_LINE_STRIDE == 0 && !$disable_progress) {` :: Progress repaint gate. The modulo is tested first, then run-constant $disable_progress, on every line.
- `read_and_process_logs` :: `if (@udm_configs && !$csv_detected) {` :: Lazy CSV detection, gated on run-constant @udm_configs plus file-scoped $csv_detected, on every line.
- `read_and_process_logs` :: `if (@udm_configs && defined $message) {` :: UDM capture gate, on every line. When on, the inner loop tests per-config run constants on each line: agg_kind, transform, converter, expose, and match_type == 13.
- `read_and_process_logs` :: `foreach my $config (@udm_configs) {` :: Three foreach loops over @udm_configs with no outer gate: new consolidation key (15832), per-message store (15969), per-bucket store (16258). With no UDM configured each still enters a loop over an empty list.
- `read_and_process_logs` :: `if( $discard_any_field ) {` :: Discard of parsed fields (-d thread|session|user|object), on every line. When on, four $discard_field{...} hash lookups follow.
- `read_and_process_logs` :: `if( !$omit_count && defined $message ) {` :: Count-metric capture, gated on run-constant $omit_count, on every line. It is 1 of 12 omission sites in the loop: $omit_count 3, $omit_bytes 4, $omit_durations 5.
- `read_and_process_logs` :: `$message =~ s/ count\s*=\s*\d+/ count=?/g unless $expose_count;` :: Expose gate for count masking. Runs only on lines that carry count=.
- `read_and_process_logs` :: `if (defined $duration_unit_override) {` :: -du duration-unit gate, on every matched line with a duration (15438), plus the CSV epoch path (15454). The fallback tests the per-entry constant FR_DURATION_UNIT.
- `read_and_process_logs` :: `if (%filter_range_tod) {` :: Time-of-day window gate (a hash tested for truth), on every matched line. The else-arm always compares against %filter_range_epoch, whose defaults are 0 and 2521843200, so a run with no -st/-et still does two compares.
- `read_and_process_logs` :: `if ($profile_mode) {` :: --profile folding gate, on every in-range line. A second $profile_mode test comes later for $profile_included_samples.
- `read_and_process_logs` :: `if( defined( $exclude_filter )         && match_filter($_, $exclude_filter) )` :: Pattern filter gates. The -exclude test is at 15581 and the -include test on the next line (15582). Both run on every in-range line.
- `read_and_process_logs` :: `if( $outcome_filter_active ) {` :: Outcome filter gate. When on, four inner tests follow: include/exclude success/failure.
- `read_and_process_logs` :: `if( defined( $filter_duration_min ) || defined( $filter_duration_max ) ) {` :: The first of three numeric-filter gates (duration, bytes, count; 15600/15605/15610). Each is two defined() tests on every in-range line, with 6 inner threshold tests.
- `read_and_process_logs` :: `if( $highlight_active` :: Highlight tag point: one compound gate. Inside it are 12 run-constant terms: $highlight_filter, $outcome_highlight_active, $highlight_failure, $highlight_success, $numeric_highlight_active, and six thresholds. It sets $line_is_highlighted, which about 20 later sites read (heatmap, histogram, bucket, UDM, threadpool, session, user). With highlight off, those reads are all constant false.
- `read_and_process_logs` :: `if ($print_milliseconds) {` :: Bucket-key precision gate, on every included line.
- `read_and_process_logs` :: `if ($line_entry->[FR_PCT_QUALIFYING]) {` :: Classification bookkeeping. FR_PCT_QUALIFYING is a per-entry constant baked at build from $show_classification and read at 15702 and 15710. The outcome itself ($line_outcome) is computed inside the scan sub.
- `read_and_process_logs` :: `if( $capture_messages && defined( $message ) ) {` :: Message-capture gate, on every included line. It encloses the expose, discard, mask, key-building, consolidation and per-message statistics blocks.
- `read_and_process_logs` :: `$log_level =~ s/-HL$//;` :: Unconditional regex substitution on each retained message, stripping the highlight suffix from the category. No gate.
- `read_and_process_logs` :: `if( $expose_active ) {` :: Expose (-x) gate, once per retained message.
- `read_and_process_logs` :: `if( $discard_active ) {` :: Message discard (-d) gate, once per retained message, plus a $discard_field{'query-string'} lookup inside.
- `read_and_process_logs` :: `if( $mask_active ) {` :: Mask (-m) gate, once per retained message.
- `read_and_process_logs` :: `($write_messages_to_csv == 1 || $group_similar_sensitivity ne "none") ? 350 : $max_log_message_length` :: Key-length expression, run-constant, recomputed per retained message. It is written out in 4 branches of the key build (one runs per line) and a fifth time in group_similar_messages (line 10998). Overlaps scope item 7 of the issue (message-key construction).
- `read_and_process_logs` :: `if ($group_similar_sensitivity ne "none") {` :: Consolidation gate, a string compare per retained message.
- `read_and_process_logs` :: `if( $message_duration_stats_demand ) {` :: Per-message statistics-demand gate. Nearby run constants: $message_outcomes_demand (3 sites), $message_stats_capture_mode eq 'bin' (5 string compares), $message_stats_demand_shape (2), $bytes_aggregate_demand (1).
- `read_and_process_logs` :: `$log_analysis{$bucket} //= ($bucket_stats_capture_mode eq 'bin' ? {` :: Per-bucket statistics. Run constants: $bucket_stats_capture_mode eq 'bin' (3 string compares), $bucket_stats_demand_shape (2), $bucket_duration_stats_demand (1), $bytes_aggregate_demand (1). The Welford-Pebay block here near-duplicates the per-message one.
- `read_and_process_logs` :: `$durations_observed = 1 if $durations_observed != 1 && $duration_observed;` :: Run-level latch flag, read and compared on each line with metrics.
- `read_and_process_logs` :: `if ($heatmap_enabled) {` :: Heatmap gate, on each line with metrics. Inside: three $heatmap_metric eq compares, defined $heatmap_udm_config, and $heatmap_capture_mode eq 'raw'.
- `read_and_process_logs` :: `if ($histogram_enabled) {` :: Histogram gate, on each line with metrics. Inside: $histogram_capture_mode eq 'raw', 8 metric-selection tests (!%histogram_metrics || $histogram_metrics{X}), two loops over @histogram_udm_configs, and 6 omit tests.
- `read_and_process_logs` :: `( !defined $threadpool_activity_regex && $include_threadpool_summary )` :: Threadpool capture gate: one compound condition with three run-constant terms, reached only when a threadpool was parsed.
- `read_and_process_logs` :: `if( defined $session && $session ne "" && $session ne "-" ) {` :: Session capture, gated on data only. No run option is consulted ($hide_session is not read here).
- `read_and_process_logs` :: `if( defined $user && $user ne "" && $user ne "-" ) {` :: User capture, gated on data only. No run option is consulted ($hide_user is not read here).
- `read_and_process_logs` :: `$fd->{sel_match_count}++;` :: Per-file index tracking, before and after the filters (blocks at 15513 and 15620). No gate: it runs even under -ni, and $no_index is never referenced in read_and_process_logs.
- `read_and_process_logs` :: `format_elect_scan_front( $sample->{formats} ) unless defined $log_format_pin;` :: Per-file election before line 1: the format the sample found most often is moved to the front of the scan order.
- `format_scan_sub_resolve` :: `$format_scan_sub_cache_hits++ if exists $format_scan_sub_cache{$sig};` :: The one resolve point: order signature (joined FR_NAME of @format_scan_order), then %format_scan_sub_cache //= compile_format_scan_sub($format_registry_opts). Called by election and fallback (per file, before line 1), format_registry_promote() and apply_format_pin().
- `format_registry_set_occupant` :: `$format_scan_sub = $format_scan_sub_cache{$sig} //= compile_format_scan_sub($format_registry_opts);` :: A second, inline cache-lookup-or-compile for variant occupant swaps. It computes the same signature but does not go through format_scan_sub_resolve().
- `compile_format_scan_sub` :: `my $sub = eval $src;` :: Code generation. For each entry in the current order it assembles a guard, a pattern-match condition and a body (from format_entry_block_src), adds a whitespace dispatch (space-led lines go to no-match; tab-led lines try only head_class 'any' blocks), evals the whole thing as one sub, and validates it (format_validate_scan_sub, which saves and restores run state). It records telemetry: compile count, elapsed time, RSS delta.
- `compile_format_scan_sub` :: `: "my \$winner = \$entries[$si];\nformat_registry_promote($si);\nreturn \$winner;\n";` :: Promotion code is emitted only into blocks that are not already in their best position. Steady state runs no promotion code.
- `build_format_registry` :: `my $opts = { include_query_string => $include_query_string, expose_metric => \%expose_metric };` :: The only run options baked into generated code: include_query_string (whether the strip_query_string transform is emitted) and expose_metric (which in-message metric keys are masked). Everything else run-scoped is tested in the loop body.
- `build_format_registry` :: `$entry->[FR_PCT_QUALIFYING]  = ($spec->{_cls_both} && ($spec->{event_ledger} || $show_classification)) ? 1 : 0;` :: A run option ($show_classification) folded into a per-entry constant at build time, which the loop body then reads per line.
- `format_entry_block_src` :: `if ($t eq 'strip_query_string') { next if $opts->{include_query_string}; }` :: Build-time use of an option inside a generated block: the transform is left out entirely rather than tested per line.
- `format_entry_block_src` :: `my $exposed = $opts->{expose_metric} || {};` :: Build-time use of an option: metrics named on -x are dropped from the generated mask alternation.
- `read_and_process_logs` :: `unless (exists $log_level_set{$category_bucket}) {` :: Category acceptance gate at about line 15467. It does a hash lookup on every matched line against %log_level_set, which is fixed for the run (built at GLOBALS from @log_levels and extended in the registry build around line 3862). The inventory has no group for it. *(added by the verifier)*
- `read_and_process_logs` :: `my $bucket_size_ms = int($bucket_size_seconds * 1000 + 0.5);` :: Inside the 'if ($print_milliseconds) {' arm at about line 15682. A value fixed for the run is recomputed on every included line. The inventory lists the gate but not this per-line recomputation. *(added by the verifier)*
- `read_and_process_logs` :: `$output_timestamp_min = $bucket_epoch if $output_timestamp_min == 0 || $output_timestamp_min > $bucket_epoch;` :: Run-level min/max accumulators at about lines 15675-15676, with 4 compares per included line (the max line is the same shape). They are the same kind of thing as the $durations_observed latch the inventory lists, but are left out. *(added by the verifier)*
- `read_and_process_logs` :: `my $max_object_length = 25;` :: A literal constant re-declared once per retained message inside the message-capture block (about line 15735) and used in the $truncated_object substr. Missed next to the key-length expression item. *(added by the verifier)*
- `read_and_process_logs` :: `if ($match_type == 13) {` :: Inside the UDM inner loop at about line 15328. The inventory lists it as match_type == 13 in the role of the UDM-capture site. It is also tested again at about line 15480 ('} elsif (!$csv_epoch_timestamp && $match_type == 13) {') on the timestamp path, and that second site is not counted. *(added by the verifier)*

### Verification notes

Sites reported 45, confirmed 45, refuted 0 (corrected above), added by the verifier 5, owning docs refuted 0.

- All 45 snippets were found, and every attributed occurrence sits inside the named sub. The line hints match exactly.
- The snippet 'while (1) {' also occurs in auto_hide_narrow_columns (line 18725). The attribution is right, but the snippet is not unique in the file.
- 'foreach my $config (@udm_configs) {' occurs 9 times in ltl. Only 15832, 15969 and 16258 are in read_and_process_logs, which matches the inventory.
- The snippets 'if (defined $duration_unit_override) {', 'if ($profile_mode) {', 'if ($group_similar_sensitivity ne "none") {', 'if ($heatmap_enabled) {', 'if ($histogram_enabled) {' and 'if ($print_milliseconds) {' also appear in other subs. The copies in read_and_process_logs are at the stated lines. Note that 'if ($group_similar_sensitivity ne "none") {' also occurs at 16484, in the sub but after the loop.
- The loop's end was confirmed: the closing brace is just before 'close $fh;' at about line 16429 (16427 is the loop's closing brace per the inventory, and the note_unmatched_line else-arm closes just before it).
- Every owning doc path exists, and so do both harnesses. These headings were confirmed: 567 § Completion gate (line 137) and § Post-release finding (line 155); log-format-registry.md § '#413 — lazy scan-sub compilation (elevation by election)' (line 796) and § '2026-08-21: Drop 1 (#58) implementation — D39–D40 ...' (line 1052); 478 § '4. The mechanism today' (line 177) and § 'The thirteen read-back sites' (line 198); staged-processing-pipeline.md § 'Named Pipeline Stages (#180)' (line 149). In features/58-format-registry-staged-detection.md, D26 (line 391) and the lean-loop obligation are present.
- Minor count nuance: the loop tallies show $message_duration_stats_demand at 2 references. One is the gate; the other is the closing comment at about line 16076, so the gate count of 1 holds. The same applies to $expose_active, $discard_active and $mask_active, which each show 2 references (the gate plus a comment).

### Questions for the findings discussion

Carried in the specification, § 4, under this item; the audit adds the evidence bearing on each here.


---

## Item P: Architectural patterns

**State: scoping pass recorded; audit not yet run.**

### Summary of the scoping pass

15 candidate patterns scouted, each with 1-4 consumption sites in ltl (44 site rows in total). 12 already have an owning doc: format registry, column layout, bin counters, precision tiers, data-model selectors, demand gates, statistics-group consumer registry, -V sections, metric-operand resolution, named stages, S1-S5 pipeline, section visibility, plus sort gates (spread over 3 docs). 3 have no single owning doc: run-scoped activation flags, behavioural notices / deferred notice queue, and the one-resolution-surface rule, which exists only as a CLAUDE.md checkpoint plus scattered instances. The new file would index these docs, not duplicate them. docs/staged-processing-pipeline.md is the only existing docs/*.md written as a pattern description.

**Shared surface today.** Existing single-surface subs per candidate: build_format_registry() + format_scan_sub_resolve() (format recognition); @column_layout + add_dynamic_column() (columns); partition_new/bin_assign/counter_update/percentile/partition_rebin (bin counters); bpd_for_surface() over %TIER_BPD (precision); choose_data_model()/resolve_data_model() (raw|bin); demand block in adapt_to_command_line_options() + resolve_statistics_group_demand() over @STAT_CONSUMERS (demand); section_requested() over %verbose_section_registry (-V); builtin_metric_name()/resolve_metric_operand()/available_metric_names() (metric operands); format_csv_value()/resolve_csv_column_family() (CSV values); pipeline_* (stages); defer_notice()/flush_deferred_notices() (notices); resolve_visibility_name()/section_hidden() (visibility); apply_parse_time_sort_gate/apply_pre_walk_sort_gate/apply_post_walk_sort_gate (sort).

### Candidate findings (scoping pass; category and priority assigned by the audit)

- **FP.1** Timeline latency-column visibility is restated in three places rather than resolved once (identical today, a latent drift point): @STAT_CONSUMERS entry `active => sub { !$hide_stats && !$heatmap_enabled },` (line ~1005); adapt_to_command_line_options() demand block `(!$hide_stats && !$heatmap_enabled)   # timeline latency-statistics column` (line ~14747); and a third copy `my $show_latency = $durations_observed && !$omit_durations && !$hide_stats && !$heatmap_enabled;` (line ~18370, in the column-layout build area). Similarly the stats-csv/messages-csv consumer predicates restate `$write_messages_to_csv` / `$capture_messages` terms that the store-level demand booleans also compute.
- **FP.2** Naming mismatch against the HARNESS-DESIGN naming rule: sub emit_bin_counter_mode_verbose() emits section 'histogram-bin-counters' (`return unless section_requested('histogram-bin-counters');`), whose harness is tests/validate-histogram-bin-counters.sh; the emitter name tracks an older name, not the section.
- **FP.3** Run-scoped activation flags: no doc owns the pattern; it is resolved in several places (adapt_to_command_line_options() for highlight/outcome flags, resolve_expose_names()/resolve_mask_names()/resolve_discard_names() for `$expose_active`/`$mask_active`/`$discard_active`, each also re-set a second time later in the same subs: `$expose_active  = @expose_appends ? 1 : 0;` at ~13741 and `$mask_active = @mask_subs ? 1 : 0;` at ~13760).

### Site inventory (scoping pass)

- `Declarative format registry compiled into a generated, cached scan sub` :: `return $format_scan_sub = $format_scan_sub_cache{$sig}` :: Per-format behaviour is declared as data in format_registry_specs(); build_format_registry() compiles it into live entries plus per-entry closures (time parser, classifier, extractor, guard), and one hot-loop scan sub is generated per most-recently-used order and cached by order signature. Defined: features/log-format-registry.md (# Feature Requirements: Log Format Registry, ## Architectural Template: Staged Pipeline) and features/58-format-registry-staged-detection.md; CLAUDE.md Architecture 'Format recognition' paragraph also describes it.
- `Declarative format registry compiled into a generated, cached scan sub` :: `build_format_registry();` :: Consumption site: pipeline_detect() builds the registry once after option parsing, because extraction closures bake CLI-gated behaviour.
- `Declarative format registry compiled into a generated, cached scan sub` :: `$entry->[FR_TIME_PARSE]      = compile_format_time_parser( $spec->{time}{layout} );` :: Consumption site: build_format_registry() compiles per-entry closures from the spec (compile_format_time_parser, compile_format_classifier, compile_format_extractor).
- `Declarative format registry compiled into a generated, cached scan sub` :: `if ( $line_entry = $format_scan_sub->($_) ) {` :: Consumption site: read_and_process_logs() dispatches each line through the one generated scan sub.
- `Single column-layout source of truth` :: `add_dynamic_column(\@column_layout, 'sessions', 'sessions', 3,` :: @column_layout holds every column's width, spacing, visibility and colour; dynamic columns are appended through add_dynamic_column(); rendering, CSV headers and colour resolution all read it. Defined: features/column-layout-refactor.md (## Goals, ## Layout Engine Requirements, ## Color Scheme Requirements).
- `Single column-layout source of truth` :: `# Resolve ALL metric colors from @column_layout (single source of truth)` :: Consumption site: normalize_data_for_output() resolves all metric colours from @column_layout.
- `Single column-layout source of truth` :: `## RENDER ROW BY ITERATING @column_layout` :: Consumption site: print_bar_graph() renders each row by iterating the visible layout entries.
- `Bin-counter primitives (partition / assign / counter / percentile)` :: `counter_update(\%bucket_stats_counters, $bucket, $duration, $bucket_stats_buckets_per_decade) if $duration > 0;` :: One shared substrate for every histogram-shaped consumer: partition_new(), bin_assign(), counter_update(), percentile(), partition_rebin() (finalize re-bin for display-geometry-bound consumers), with over/underflow counters and -V telemetry. Defined: features/189-histogram-bin-counter-primitives.md (## Requirements R1-R12), locked by features/187-histogram-bin-counter-percentiles.md; also features/bin-counter-accuracy-and-observability.md.
- `Bin-counter primitives (partition / assign / counter / percentile)` :: `counter_update(\%histogram_counters_hl, 'duration', $duration, $histogram_stream_bpd) if $is_highlighted;` :: Consumption site: histogram streaming counters in read_and_process_logs(), with a parallel highlight store.
- `Bin-counter primitives (partition / assign / counter / percentile)` :: `my ($final_p, $final_bins) = partition_rebin(` :: Consumption site: histogram/heatmap finalize re-bin then percentile() for markers.
- `Precision tiers (one lever, per-surface bins-per-decade table)` :: `return $TIER_BPD{$surface}[$data_model_precision_level - 1];` :: A single --data-model-precision tier (1..9) indexes %TIER_BPD; each surface's bins-per-decade is resolved once through bpd_for_surface(). Defined: features/293-precision-lever-unification.md (## Precision-tier -> bins-per-decade (source of truth)); table matches %TIER_BPD in ltl today.
- `Precision tiers (one lever, per-surface bins-per-decade table)` :: `$percentile_buckets_per_decade   = bpd_for_surface('message-stats');` :: Consumption site: adapt_to_command_line_options() resolves the four surfaces' bpd once at startup.
- `Data-model selectors (raw|bin per surface)` :: `data_model      => choose_data_model('histogram')   // 'bin',` :: Each statistical surface resolves raw vs bin through one resolver, called once before the parse loop. Defined: features/266-data-model-selectors.md (### Resolution at each call site, ### `resolve_data_model($surface)` shape).
- `Demand gates (store-level run-start booleans)` :: `$bytes_aggregate_demand = ( !$omit_bytes && (` :: A per-line capture runs only when some consumer of its output is active; the boolean is resolved once in the demand-resolution block of adapt_to_command_line_options() and downstream reads are absence-tolerant. Defined: features/516-bytes-aggregate-demand-gate.md (### D1 - Store-level demand flag...), features/517-message-outcomes-demand-gate.md (### D1 - One store-level demand flag...), features/305-shape-moment-extended-percentile-demand.md (### Store-level demand (#349, pre-existing)).
- `Demand gates (store-level run-start booleans)` :: `if( $bytes_aggregate_demand ) {` :: Consumption site: per-line bytes capture in read_and_process_logs() tests the flag.
- `Demand gates (store-level run-start booleans)` :: `$log_messages{$category}{$log_key}{outcomes}[$line_outcome]++ if $message_outcomes_demand && $line_outcome;` :: Consumption site: per-message outcome counters gated in read_and_process_logs().
- `Declarative consumer registry for statistics-group demand` :: `{ name => 'timeline-latency-column', store => 'bucket',` :: @STAT_CONSUMERS declares each output surface (store, active predicate, statistic groups); resolve_statistics_group_demand() derives per-store per-group demand from it, layered on the store-level gates. Defined: features/305-shape-moment-extended-percentile-demand.md (# Statistics-group demand registry (#305), ## The three gate classes).
- `Declarative consumer registry for statistics-group demand` :: `resolve_statistics_group_demand();` :: Consumption site: resolved once at the end of the demand block.
- `Declarative consumer registry for statistics-group demand` :: `$stats = calculate_statistics($aggregated_data, $bucket_demand);` :: Consumption site: calculate_all_statistics() passes a per-store demand hash to calculate_statistics().
- `Run-scoped activation flags resolved once at option settlement` :: `$highlight_active = ( defined($highlight_filter) || $numeric_highlight_active` :: Option-shaped behaviour is reduced to scalar *_active flags in adapt_to_command_line_options() (or the resolve_*_names subs it calls) so the per-line loop tests one scalar. No dedicated doc; described piecemeal in features/567-discard-named-values-from-message.md (Post-release finding, measured loop cost of non-executing gates) and the issue 342 comment on read_and_process_logs() structure.
- `Run-scoped activation flags resolved once at option settlement` :: `$discard_active = ( @discard_subs || $discard_field{'query-string'} ) ? 1 : 0;` :: Consumption site: resolve_discard_names() sets the discard gate.
- `Run-scoped activation flags resolved once at option settlement` :: `$outcome_filter_active = ( $include_failure || $exclude_failure` :: Consumption site: outcome filter gate resolved in adapt_to_command_line_options().
- `-V telemetry sections as the test surface (verbose section registry)` :: `my %verbose_section_registry = (` :: Every machine-readable diagnostic is a named kebab-case section registered in %verbose_section_registry / @verbose_section_order, emitted by an emit_*_verbose sub gated on section_requested(); harnesses assert on sections, never on rendered output. Defined: tests/HARNESS-DESIGN.md (## Application-observability contract, ## Reserved section names, ## Stability contract, ### Counters serving benchmark attribution: one source, two surfaces).
- `-V telemetry sections as the test surface (verbose section registry)` :: `return unless section_requested('statistics-demand');` :: Consumption site: emit_statistics_demand_verbose().
- `-V telemetry sections as the test surface (verbose section registry)` :: `push @verbose_output, "scan_sub_cache_hits: $format_scan_sub_cache_hits";` :: Consumption site: emit_format_registry_verbose() reports scan-sub compile/cache counters.
- `One resolution surface per vocabulary` :: `my $resolved = resolve_metric_operand($heatmap_metric);` :: Parsing, matching, validation and formatting of a value class go through one named sub; options sharing an operand set call it. Defined as a rule in CLAUDE.md (### Before writing or changing code, first bullet); worked contract in features/histogram-charts.md (metric-name operands paragraph, line 32); further instances in features/463-friendly-log-level-category-names.md (category_display_name()), features/478-highlight-decision-read-back.md, features/447-message-control-character-normalisation.md.
- `One resolution surface per vocabulary` :: `my $has_valid_metric = grep { defined builtin_metric_name($_) } @parts;` :: Consumption site: builtin_metric_name() used at option-parse time for -hg.
- `One resolution surface per vocabulary` :: `die "Error: Unknown heatmap metric '$heatmap_metric'. Available: " . join(', ', available_metric_names()) . "\n";` :: Consumption site: unknown-metric errors name the vocabulary from available_metric_names().
- `One resolution surface per vocabulary` :: `push @csv_data, format_csv_value($total_occurrences, 'occurrences');` :: Consumption site: CSV value formatting routes every column through format_csv_value() / resolve_csv_column_family() (56 call sites).
- `MAIN` :: `pipeline_accumulate();` :: ## MAIN ## is a thin dispatcher over pipeline_detect/parse/accumulate/finalize/render; stages are roles, not strictly sequential passes, and take resolved demand as explicit input. Defined: features/180-named-pipeline-stages.md (### R2 - Stage semantics: roles, not sequential temporal phases; ### R4 - Audited stage inventory); summarised in docs/staged-processing-pipeline.md (## Named Pipeline Stages (#180)).
- `Named pipeline stages (roles with contracts)` :: `$elapsed_detect_registry_build = tv_interval($registry_build_start);` :: Consumption site: pipeline_detect() times the registry build as its own sub-stage.
- `Staged processing pipeline S1-S5 (cheap inline match, periodic expensive discovery)` :: `run_consolidation_checkpoint($cat, $gk);` :: Separate expensive discovery from cheap continuous matching: inline match per line, checkpoint-triggered ceiling filter / match / pairwise discovery, interleaved re-scan, bounded transient memory. Defined: docs/staged-processing-pipeline.md (## Core Principle..., ## The S1-S5 Pipeline, ## Applicability Beyond Fuzzy Consolidation); features/fuzzy-message-consolidation.md.
- `Staged processing pipeline S1-S5 (cheap inline match, periodic expensive discovery)` :: `my $entry = match_consolidation_patterns($category, $grouping_key, $capped_msg);` :: Consumption site: S1/S3 matching through match_consolidation_patterns().
- `Behavioural notices (always print; deferred while progress owns the terminal)` :: `push @deferred_notices, $text;` :: Auto-disable, fallback and limit-hit notices always print regardless of --disable-progress; notices raised during the read are queued with defer_notice() and emitted by flush_deferred_notices() after the progress line. Rule defined in CLAUDE.md (### Before writing or changing code) and .claude/rules/ltl-source.md; progress-side rationale in docs/progress-indication-best-practices.md. No single feature doc owns the mechanism.
- `Behavioural notices (always print; deferred while progress owns the terminal)` :: `defer_notice( "Note: $file: the detected log format (" . $entry->[FR_SLUG] . ") is written by more than one producer and " . $consequence` :: Consumption site: format-variant ambiguity note raised during detection.
- `Behavioural notices (always print; deferred while progress owns the terminal)` :: `emit_udm_zero_match_notices();` :: Consumption site: end-of-run notice emitters.
- `Section visibility and section boundaries` :: `my $resolved = resolve_visibility_name($given);` :: Output sections and columns are named, aliased and hidden through one resolver (resolve_visibility_name()) and one predicate (section_hidden()); open_section() separates rendered sections. Defined: features/597-section-visibility.md (## Decisions, ## Finding: where each section starts and ends today).
- `Section visibility and section boundaries` :: `open_section('timeline');` :: Consumption site: print_bar_graph() opens the timeline section.
- `Sort gates at three pipeline points` :: `apply_post_walk_sort_gate($sort_defined_keys);` :: Sort-operand satisfiability is resolved at parse time, before the population walk and after it, each through a named gate sub with a fallback to occurrences. Defined: features/418-unsatisfiable-sort-selection-cost.md, features/303-calculated-statistic-sort-path.md, features/520-inert-sort-bytes-aggregate-demand.md.
- `Generated code compiled from source strings (eval of built source)` :: `my $closure = eval $src;` :: compile_format_classifier() and compile_format_extractor() build Perl source text and eval it into closures, as compile_format_scan_sub() does ('my $sub = eval $src;'). There are three eval-generated sites today, not just the scan sub. This bears on the open question 'generated per-run code: one pattern or part of the registry entry'. *(added by the verifier)*
- `Declarative explain-topic registry` :: `%explain_topics = (` :: --explain topics are declared as data blocks (heading/paragraph types) in %explain_topics. populate_explain_topics() fills it, it is called once at file scope ('populate_explain_topics();' just before sub print_help), and print_explain_registry() renders it. Owning doc: features/504-explain-technique-topics.md (exists). *(added by the verifier)*
- `Declarative memory-structure registry` :: `log_occurrences        => Devel::Size::total_size(\%log_occurrences),` :: named_structure_sizes() lists every major data structure by name for memory telemetry. It is a registry-shaped single source that the inventory's open questions name but that has no site row. *(added by the verifier)*
- `Declarative consumer registry for statistics-group demand` :: `my %STAT_GROUP_FIELDS = (` :: A global table that maps each statistic group to its ladder fields. @STAT_CONSUMERS references these groups, so the registry is two tables, not one. *(added by the verifier)*
- `Behavioural notices (always print; deferred while progress owns the terminal)` :: `flush_deferred_notices();` :: This is the flush point of the deferred-notice queue in read_and_process_logs(). The inventory names flush_deferred_notices() but gives no site for it. *(added by the verifier)*
- `User-defined metric specs (declarative UDM configs)` :: `sub parse_udm_configs {` :: A second declarative-spec surface: parse_udm_configs(), derive_udm_production(), udm_config_by_name() and resolve_udm_metric_names(), with its own -V sections (emit_udm_specs_verbose, emit_udm_counting_verbose). Owning doc: features/user-defined-metrics.md (exists). Not scouted. *(added by the verifier)*

### Verification notes

Sites reported 39, confirmed 44, refuted 0 (corrected above), added by the verifier 6, owning docs refuted 0.

- Every snippet was found with grep -F, inside the named sub or at the stated scope. Every doc path and every cited heading exists. docs/architecture-patterns.md is absent, and ltl has 327 subs.
- 'pipeline_accumulate();' (line 22293) is at ## MAIN ## file scope (the marker is at line 22271), after the last sub, expand_recursive_pattern(). A naive sub-range awk attributes it to expand_recursive_pattern, so it should be recorded as MAIN scope.
- 'push @deferred_notices, $text;' is at line 12907 in defer_notice(), not 12903 (sub defer_notice starts at 12905).
- 'my ($final_p, $final_bins) = partition_rebin(' has two sites: finalize_heatmap_unified() at line 16743 and finalize_histogram_unified() at line 17102. The row should name the sub.
- 'if( $bytes_aggregate_demand ) {' occurs twice in read_and_process_logs() (lines 15951 and 16236). The per-message outcomes increment line also occurs twice (15923 and 16086).
- 'my $entry = match_consolidation_patterns(...)' also occurs twice in group_similar_messages() (lines 10930 and 10971), besides consolidation_process_key() at 11815.
- The data-model selectors snippet 'data_model => choose_data_model('histogram') // 'bin',' sits in emit_percentile_algorithm_verbose(), a -V emitter. It is not a resolution call site, so it is a weak consumption example for 'resolved once before the parse loop'.
- The global snippets at line 131 (%verbose_section_registry) and line 1004 (@STAT_CONSUMERS entry) are at GLOBALS scope with no enclosing sub, as expected.
- Wrong in observed_divergences: the second re-sets '$expose_active  = @expose_appends ? 1 : 0;' (13741) and '$mask_active = @mask_subs ? 1 : 0;' (13760) are NOT in the same subs. Both are in apply_discard_precedence(). The first sets are in resolve_expose_names() (13581) and resolve_mask_names() (13644).
- Divergence addendum: section 'histogram-bin-counters' has two emitters, emit_bin_counter_mode_verbose() (6196) and finalize_histogram_unified() ('if (section_requested('histogram-bin-counters') && @metrics_with_data) {' at 17197). The section is not owned by one emit_* sub.
- The third latency-visibility copy 'my $show_latency = ...' (18370) is in build_column_layout(). The inventory says only 'the column-layout build area'.

### Questions for the findings discussion

Carried in the specification, § 4, under this item; the audit adds the evidence bearing on each here.


---

## Grouping by target sub

Filled when every item is audit complete: findings across items that converge on
the same target sub, as the starting point for the discussion of which findings
become issues and how they group. The decision is the architect's and is recorded
on the issue when made.

## What was not searched

Filled at the end of the audit: angles not run, surfaces not walked, and why.

