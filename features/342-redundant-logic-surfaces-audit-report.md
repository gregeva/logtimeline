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

**State: audit complete (2026-09-26).** The four angles were run on the issue
branch. The two gaps the scoping pass found by reading are both confirmed by a
run, and the runs found two more: a day that is impossible for its month passes
the scanned arm's guard and aborts the whole run from inside the generated scan
sub, and the `-st`/`-et` bound parser drops the time of day from a `T`-separated
value with a Perl warning. Captures are under the session scratchpad
(`342/runs3/`), one file per run; every run passed `--disable-progress`, `-bs 1`,
`-ni` and `-V filter-summary` or bare `-V`.

### Fixtures used by the confirmation runs

Every fixture is two or three lines. CSV fixtures have the header `timestamp,value`
and are read with `-udm 'value::max'`, which is what turns CSV reading on.

- **csv-ok**: two ISO rows. **csv-month13**: an ISO row followed by
  `2025-13-01 10:01:00`. **csv-day32**: followed by `2025-06-32 10:01:00`.
  **csv-feb30**: followed by `2025-02-30 10:01:00`. **csv-shape**: followed by
  `not a date`. **csv-tz**: `2025-06-01T10:00:00+02:00` followed by
  `2025-06-01 10:00:00`. **csv-epoch-text**: `1748772000`, then `abc`, then
  `1748772060`.
- **apache-nonmonth** and **apache-feb30**: access-log lines (TEST-NET address)
  whose second line carries `[07/Xyz/2025:00:01:00 +0000]` or
  `[30/Feb/2025:00:01:00 +0000]`.
- **iso-month13**, **iso-day32**, **iso-feb30**: the first three lines of
  `tests/fixtures/numeric-highlight-boundary.txt` (an application-log format
  with a fixed three-digit fraction) with the second line's date rewritten to
  `2026-13-26`, `2026-01-32` or `2026-02-30`.
- The bound parser was run on the committed
  `tests/fixtures/tomcat-access-single-sample-keys.txt` with `-st '2025-13-01 00:00:00'`,
  `-st '2025-05-32'`, `-et '25:00'` and `-st '2025-05-07T00:02:00'`.

### Search angles run

1. **By layout.** `format_registry_specs()` declares 21 entries: eleven on
   `iso_ms` with the fixed three-digit fraction contract (one of them, the
   Integration Runtime encoder, on `iso_ms_ddmm`), one on `iso_flex` and one on
   `iso_flex_frac` with the generic fraction, seven on `apache_clf` with no
   fraction, and the `csv` entry whose layout falls to the ISO branch. The
   transform lists that touch the timestamp: `chop_tz_offset` on the seven
   access-log entries, `chop_tz_colon_offset` with `t_to_space` on one,
   `comma_to_dot` with `t_to_space` on two, `t_to_space` alone on one. For each
   layout the generated source in `format_entry_block_src` and the closure in
   `compile_format_time_parser` were read side by side: the date-key substring,
   the `timegm` argument order, the day/month offset swap and the time-of-day
   arithmetic are the same text in both; the memo, the fraction handling, the
   transforms and the impossible-date guard exist in the generated source only.
2. **By primitive.** Every `timegm` (five: the closure's two arms, the generated
   source's two arms, `parse_iso_date_to_epoch`, `format_sample_probes`), every
   `strptime` (five, all in `calculate_start_end_filter_timestamps`), every
   `gmtime` (fourteen, of which three are parse-side: `fold_epoch` twice and
   `profile_included_weekdays`), the one `%format_month_map` table and its two
   readers, and every regex or `substr` on `$timestamp_str` (44 lines; the
   capture is `i3-primitives.txt`).
3. **By variable.** Every read and write of `$fractional_ms`, `$timestamp_epoch`,
   `$bucket_epoch`, the memo pair, the date cache and the CSV epoch flag: 93
   lines, 32 of them in `read_and_process_logs`, 13 in `format_entry_block_src`,
   11 in `calculate_start_end_filter_timestamps`, the rest in the cache subs, the
   validation snapshot and the occupant swap. The single join point
   `my $timestamp_epoch = $timestamp + ($fractional_ms / 1000);` has four
   upstream writers of `$timestamp` (the generated block, the CSV ISO arm, the
   CSV epoch arm, the window replay) and three of `$fractional_ms`.
4. **By failure.** Eleven runs, listed under *Fixtures*; results in the findings.

### The seven parsers and what each does with a bad date

Run evidence, one row per parser. "Aborts" means the process exits non-zero with
a Perl message and no timeline; the message names a source line, which CLAUDE.md
treats as a defect in itself.

| Parser | Input class | Shape check | Month 13 / day 32 | Day impossible for its month | Non-numeric | Timezone suffix |
|---|---|---|---|---|---|---|
| Scanned ISO (generated) | every `iso_*` format | the format's pattern | note printed, line carried at the previous epoch, probe signalled (iso-month13, iso-day32: 3 lines included) | **aborts**: `Day '30' out of range 1..28 at (eval 88) line 216.` (iso-feb30, exit 1) | cannot occur | chopped by the declared transform |
| Scanned Apache (generated) | the seven access-log formats | `[^\]]+` inside brackets | **aborts** with a Perl warning first: `Use of uninitialized value $format_month_map{"Xyz"} in subtraction` then `Month '-1' out of range 0..11 at (eval 88) line 206.` (apache-nonmonth, exit 255) | **aborts** (apache-feb30, exit 1) | as month 13 | chopped |
| CSV ISO (closure) | CSV rows whose first data value is not numeric | `^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}` (#328): row skipped, counted, one warning per file (csv-shape: 1 excluded) | **aborts**: `Month '12' out of range 0..11 at ltl line 3510.`, `Day '32' out of range 1..30 at ltl line 3510.` (exit 255) | **aborts** (csv-feb30, exit 1) | as shape | **dropped without notice**: `2025-06-01T10:00:00+02:00` and `2025-06-01 10:00:00` land in one bucket (csv-tz: `DATA: 2`) |
| CSV epoch (inline) | CSV rows whose first data value is numeric | none after the first row | not applicable | not applicable | **runtime warning and epoch zero**: `Argument "abc" isn't numeric in int at ltl line 15462`, the row included in a `1970-01-01 00:00` bucket (csv-epoch-text: 3 included) | not applicable |
| `-st`/`-et` bounds (`strptime`) | option values | five regex shapes, space-separated only | **aborts** with the module's message: `Error parsing time at .../Time/Piece.pm line 637` (exit 1, no usage text) for `2025-13-01 00:00:00`, `2025-05-32` and `25:00` | as month 13 | `Warning: unhandled date/time format` deferred notice | not accepted; a `T` separator gives two Perl warnings (`Garbage at end of string in strptime: T00:02:00`) and the bound is taken as the date alone (st-T: 12 included, 0 excluded, where `00:02:00` would have excluded one) |
| Index read-back (`parse_iso_date_to_epoch`) | index file cells | `T` required | `undef`, silently (`eval`) | `undef` | `undef` | not accepted by the regex |
| Detection sample (`format_sample_probes`) | sample lines | regex, space only | counted out of range | counted out of range (`eval`) | not applicable | not applicable |

### Findings

| # | Decision | Site A | Site B (further copies in the note) | What each does | Observed divergence | Target | Contract and owner | Category | Related open issues |
|---|---|---|---|---|---|---|---|---|---|
| **F3.2** | The impossible-date guard | `format_entry_block_src` :: `if (substr(\$timestamp_str, $month_off, 2) > 12 \|\| substr(\$timestamp_str, $day_off, 2) > 31) {` | `compile_format_time_parser` :: `my $midnight = $timestamp_date_cache{substr($ts, 0, 10)} // timestamp_date_cache_add( substr($ts, 0, 10), timegm(` (no guard) and `compile_format_time_parser` :: `timestamp_date_cache_add( substr($ts, 0, $colon), timegm( 0, 0, 0, $day, $format_month_map{$month_str} - 1, $year ) );` (no guard, either copy) | A guards the two cheap ranges on the memo-miss branch and carries the line; B and the Apache arms guard nothing, so `timegm` croaks | The table above: month 13 on a scanned ISO line prints a note and carries the line; the same value on a CSV row aborts the run at `ltl line 3510`; a February 30 aborts the run on every arm including the scanned one, from inside the eval'd scan sub. One malformed line in a multi-million-line file ends the run on three of the four per-line arms | One guard policy for every arm that can receive the same input: the cheap range test where the inline arm has it, plus a `timegm` wrapped so that a croak becomes the same note-and-carry (or skip-and-count) the inline arm gives; on the hot path the wrap sits on the memo-miss branch only, as `features/log-format-registry.md` § #384 prototype findings F3 placed the existing guard | `features/log-format-registry.md` D31 and N3; `features/58-format-registry-staged-detection.md` A6 and P8 (exact semantics of the fast path); `features/user-defined-metrics.md` § CSV Columnar Input (skip and warn, one warning per file, for a CSV timestamp that is neither epoch nor ISO) | **diverged**, *hot path* | #387 (user-defined YAML formats) lets a user declare a layout whose lines the generated arm will parse; the guard policy is what a user-declared format inherits. #23 (parsing architecture umbrella, in progress) owns D31 and D32. #181 (buffered read pipeline, on hold) would restructure the per-line arms |
| **F3.3** | The CSV epoch arm's input | `read_and_process_logs` :: `$timestamp = int($epoch_val);` | `read_and_process_logs` :: `if (!defined $timestamp_str \|\| $timestamp_str !~ /^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}/) {` (the ISO arm's shape check) | A decides epoch mode on the first data row and never re-checks; B checks every row's shape | csv-epoch-text: `Argument "abc" isn't numeric in int at ltl line 15462`, and the row is included in a `1970-01-01 00:00` bucket, so the timeline gains a 1970 row and the observation range starts in 1970 | The epoch arm gets the ISO arm's skip-and-count with the same one-per-file warning, on a numeric-shape test | `features/user-defined-metrics.md` § CSV Columnar Input and § Epoch timestamps (#98) | **diverged** | #17 (input latency units) is the `-du` scaling this arm applies; informational |
| **F3.10** | The `-st`/`-et` bound parser | `calculate_start_end_filter_timestamps` :: `if ( $value =~ /^\d{4}-\d{1,2}-\d{1,2} \d{1,2}:\d{2}:\d{2}/ ) {` (five shapes, space only) and `calculate_start_end_filter_timestamps` :: `$epoch_value = Time::Piece->strptime( $value, "%Y-%m-%d %H:%M:%S" )->epoch;` | `read_and_process_logs` :: `if (!defined $timestamp_str \|\| $timestamp_str !~ /^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}/) {` (accepts `T`), `parse_iso_date_to_epoch` :: `return eval { timegm($6, $5, $4, $3, $2 - 1, $1) };` (requires `T`, fails silently), the `t_to_space` transform for scanned formats | Four acceptance rules for the ISO separator across four parsers, and a bound parser that reports a bad value through a Perl module's message | `-st '2025-05-07T00:02:00'`: two Perl warnings and the time of day silently dropped, so the bound is midnight and nothing is excluded; `-st '2025-13-01 00:00:00'`: `Error parsing time at .../Time/Piece.pm line 637`, exit 1, no usage message | One option-value timestamp parser (regex plus `timegm` under `eval`, accepting both separators, reporting through `print_usage`), which the index read-back can share | `docs/usage.md` § Filtering (the `-st`/`-et` forms) names the space form only; nothing documents the `T` behaviour | **diverged** | #154 (fixed timezone offset for rendering) names `-st`/`-et` display among the surfaces it shifts; #155 (normalise offsets to UTC) would give the bound values an offset to parse |
| **F3.9** | Timezone suffix on a CSV timestamp | `(file scope, %format_transform_code, after sub emit_index_readback_verbose)` :: `chop_tz_offset      => q{ $timestamp_str =~ s/ \+\d{4}$//; },` (and `chop_tz_colon_offset`), spliced into generated blocks by `format_entry_block_src` :: `my $code = $format_transform_code{$t}` | `read_and_process_logs` :: `$timestamp = $line_entry->[FR_TIME_PARSE]->($timestamp_str);` (the CSV ISO arm receives no transform) | Scanned formats declare which suffixes to chop and the block chops them; the CSV arm reads fixed offsets and ignores whatever follows the seconds | csv-tz: a row at `10:00:00+02:00` and a row at `10:00:00` fall into the same `10:00` bucket. The offset is neither applied nor reported | The CSV entry declares the normalisation primitives the scanned formats declare, or the CSV arm reports an offset it cannot honour once per file | `features/log-format-registry.md` (the time contract's `tz` field: the `csv` entry declares `utc`) | **diverged** | #155 (parse timezone offsets and normalise to UTC) is where an offset on any arm gains a meaning; this row is its CSV case |
| **F3.1** | The parse logic itself | `format_entry_block_src` :: `my ($day_off, $month_off) = $layout eq 'iso_ms_ddmm' ? (5, 8) : (8, 5);` (the source strings inlined into every scanned block) | `compile_format_time_parser` :: `my ($day_off, $month_off) = $layout eq 'iso_ms_ddmm' ? (5, 8) : (8, 5);` (the closures, built for every entry, called by the CSV ISO arm only) | The same substring offsets, `timegm` argument order and time-of-day arithmetic written twice; the Apache closure is built for seven entries and never called | Identical today (the February 30 runs abort with the same message from both copies); the doc comment in the generated source says "as compile_format_time_parser" and nothing checks it | The closure generated from the same source string the block uses (`eval` of the `$compute` text), so one text is the parse; or the CSV arm calls a closure compiled from the block source | `features/log-format-registry.md` D31 (the time contract compiles to per-layout closures) and D60; `features/58-format-registry-staged-detection.md` P8 (the closures achieve exact parity) | **latent**, *hot path* | #387 (user YAML formats): a user-declared layout has to reach both authorities today; #386 (analysis precision per format) adds a demand-driven variant of the fraction handling to the generated source, widening the gap unless the closure is derived |
| **F3.5** | The fractional-second strip | `format_entry_block_src` :: `push @body, q{if ($timestamp_str =~ s/(:\d{2}:\d{2})[.,](\d{1,6})/$1/)` | `read_and_process_logs` :: `if ($timestamp_str =~ s/(:\d{2}:\d{2})[.,](\d{1,6})/$1/) {` | The generic-fraction source and the CSV ISO arm restate one regex and one normalisation | Identical today | The CSV arm takes the `generic` fraction source through the same emitter, or the CSV entry declares `frac => 'generic'` and the arm is generated | `features/log-format-registry.md` (the `frac` contract) | **latent** | #386 (demand-driven sub-second handling) rewrites this strip in the generated source; a second copy in the loop would not follow |
| **F3.6** | CSV epoch detection | `read_and_process_logs` :: `if ($line_number == 2 && defined $timestamp_str && $timestamp_str =~ /^\d+(\.\d+)?$/) {` | `read_and_process_logs` :: `if (defined $timestamp_str && $timestamp_str =~ /^\d+(\.\d+)?$/) {` | The steady data-line arm and the lazy-detection confirm arm each decide epoch mode from the first data line (item 8's F8.3 lists the whole duplicated sequence) | Identical today | One CSV data-line handler called from both arms | `features/user-defined-metrics.md` § Epoch timestamps | **latent** | #181 (buffered read pipeline) would restructure both arms |
| **F3.11** | Epoch to bucket key | `read_and_process_logs` :: `$bucket = int($bucket_epoch / $bucket_size_seconds) * $bucket_size_seconds;` (with the millisecond branch `my $bucket_size_ms = int($bucket_size_seconds * 1000 + 0.5);` recomputed per included line) | `initialize_empty_time_windows` :: `my $start_bucket = int(int($output_timestamp_min * 1000 + 0.5) / $bucket_size_ms) * $bucket_size_ms;` (and its seconds branch) | The bucket arithmetic and the millisecond bucket size are written in the loop and again for the empty-window fill | Identical today (a change to one that the other did not follow would put empty rows between populated ones) | One `bucket_key_for($epoch)` resolved once for the run's precision, with the millisecond size computed before the loop (item 8 counts the per-line recomputation) | `features/524-bucket-size-unit.md` D4 (bucket width and precision are separate) | **latent**, *hot path* | #525 (a single timestamp-precision option with nanosecond) adds a precision every copy has to learn |
| **F3.7** | The last-seen memo | `format_entry_block_src` :: `push @body, qq{if (\$timestamp_str eq \$format_last_ts_str) { \$timestamp = \$format_last_ts_epoch; }` | `read_and_process_logs` :: `$timestamp = $line_entry->[FR_TIME_PARSE]->($timestamp_str);` (straight to the date cache, no memo) | Scanned arms reuse the previous epoch when the string repeats; the CSV ISO arm recomputes the time of day every row and the epoch arm uses neither memo nor cache | No behavioural difference; a cost asymmetry on CSV input only | none required; recorded so a generated CSV arm (F3.1's target) inherits the memo | `features/58-format-registry-staged-detection.md` P8 | **latent** | none |

Sites audited and closed as **deliberate**:

- The inline guard sits on the memo-miss branch behind the cache lookup, so it
  costs nothing on a cache hit: `features/log-format-registry.md` § #384
  prototype findings F3. Any widening of the guard (F3.2's target) keeps that
  placement.
- The #328 shape check on the CSV ISO arm skips and warns once per file:
  `features/user-defined-metrics.md` § CSV Columnar Input. F3.2 and F3.3 ask for
  the same policy on the other arms, not a change to this one.
- The date cache (`%timestamp_date_cache`, bounded at 100 entries) is shared by
  the generated arms and both closures: identical by construction, and the
  bound is the #58 P8 decision after the per-second cache grew unbounded.
- `t_to_space`, `comma_to_dot`, `chop_tz_offset` and `chop_tz_colon_offset` are
  declared per format and spliced at build time: the registry's declarative
  shape, not a copy.
- `format_sample_probes` reads every sample date under both month-first and
  day-first readings with `eval` around `timegm`: it is a scorer, and an
  out-of-range date is evidence, not an error. Its policy is its own by design.

### Open issues touching this item as a whole

- **#155** (parse timezone offsets and normalise to UTC, on hold): every arm
  gains an offset to honour; F3.9 is the CSV case it would meet first, and the
  chop transforms are the mechanism it would replace.
- **#154** (fixed timezone offset for rendering): names `-st`/`-et` among the
  surfaces it shifts (F3.10).
- **#525** (one timestamp-precision option, `next-up`): every copy of the bucket
  arithmetic (F3.11) and the join point learn a fourth precision.
- **#386** (default analysis precision per format, demand-driven sub-second
  handling): rewrites the fraction handling in the generated source (F3.5) and
  widens the inline-versus-closure gap (F3.1) unless the closure is derived.
- **#387** (user-defined YAML formats): a user-declared time layout inherits
  whichever guard policy the generated arm has (F3.2) and has to reach both
  parse authorities (F3.1).
- **#23** (core parsing architecture, in progress): the umbrella that owns D31
  (compiled time contract) and D32 (CSV outside the scan array).
- **#181** (buffered read pipeline, on hold): would restructure the CSV arms
  (F3.6) and the per-line join point.
- **#17** (input latency units): the `-du` scaling the CSV epoch arm applies;
  informational.

### Site inventory

Carried from the scoping pass (*(scoping)*; its six verifier additions included)
with the audit's additions:

- `format_entry_block_src` :: `my $compute = ($layout eq 'apache_clf')` :: the live parse for every scanned format, selected by layout. *(scoping)*
- `format_entry_block_src` :: `$timestamp_date_cache{substr($timestamp_str, 0, $colon)} // do { my ($day, $month_str, $year) = $timestamp_str =~ m/(\d{2})\/([A-Za-z]+)\/(\d{4})/;` :: inline Apache arm, no guard. *(scoping)*
- `format_entry_block_src` :: `my ($day_off, $month_off) = $layout eq 'iso_ms_ddmm' ? (5, 8) : (8, 5);` :: inline ISO arm offsets (the same line exists in `compile_format_time_parser`). *(scoping)*
- `format_entry_block_src` :: `my $miss_src = $layout =~ /^iso_/` :: the guard on the memo-miss branch, ISO layouts only. *(scoping)*
- `format_entry_block_src` :: `push @body, qq{if (\$timestamp_str eq \$format_last_ts_str) { \$timestamp = \$format_last_ts_epoch; }` :: the last-seen memo. *(scoping)*
- `format_entry_block_src` :: `my $frac = $spec->{time}{frac} // 'generic';` :: fraction handling by declared contract (`fixed3`, `none`, `generic`). *(scoping)*
- `format_entry_block_src` :: `my $code = $format_transform_code{$t}` :: where the declared transforms (including the timezone chops) are spliced ahead of the parse. *(audit)*
- `compile_format_time_parser` :: `sub compile_format_time_parser {` :: the closure copy of both arms; the Apache closure is never called. *(scoping)*
- `build_format_registry` :: `$entry->[FR_TIME_PARSE]      = compile_format_time_parser( $spec->{time}{layout} );` *(scoping)*
- `(file scope, between timestamp_date_cache_restore and compile_format_time_parser)` :: `my %format_month_map = (` :: the month table read by both Apache copies; a token not in it yields `undef`. *(audit)*
- `read_and_process_logs` :: `$timestamp = $line_entry->[FR_TIME_PARSE]->($timestamp_str);` :: the CSV ISO arm. *(scoping)*
- `read_and_process_logs` :: `if (!defined $timestamp_str || $timestamp_str !~ /^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}/) {` :: the #328 shape guard, CSV ISO only. *(scoping)*
- `read_and_process_logs` :: `if ($timestamp_str =~ s/(:\d{2}:\d{2})[.,](\d{1,6})/$1/) {` :: the CSV ISO arm's fraction strip. *(scoping)*
- `read_and_process_logs` :: `# Epoch timestamp: value is already epoch seconds (or other unit via -du)` and `$timestamp = int($epoch_val);` :: the CSV epoch arm, no guard, no cache. *(scoping, snippet added)*
- `read_and_process_logs` :: `if ($line_number == 2 && defined $timestamp_str && $timestamp_str =~ /^\d+(\.\d+)?$/) {` :: epoch detection, steady arm; the confirm arm's copy is `if (defined $timestamp_str && $timestamp_str =~ /^\d+(\.\d+)?$/) {`. *(scoping)*
- `read_and_process_logs` :: `my $timestamp_epoch = $timestamp + ($fractional_ms / 1000);` :: the join point. *(scoping)*
- `read_and_process_logs` :: `$bucket = int($bucket_epoch / $bucket_size_seconds) * $bucket_size_seconds;` :: the bucket arm, with the millisecond branch. *(scoping)*
- `read_and_process_logs` :: `my $folded = fold_epoch($timestamp_epoch, $profile_mode);` :: the `--profile` remap. *(scoping)*
- `read_and_process_logs` :: `my $tod = $timestamp_epoch - int($timestamp_epoch / 86400) * 86400;` :: time-of-day for date-less bounds. *(scoping)*
- `initialize_empty_time_windows` :: `my $start_bucket = int($output_timestamp_min / $bucket_size_seconds) * $bucket_size_seconds;` :: the second bucket copy. *(scoping)*
- `timestamp_date_cache_add` :: `sub timestamp_date_cache_add {` :: the date cache, bounded at 100. *(scoping)*
- `timestamp_date_cache_clear` :: `sub timestamp_date_cache_clear {` :: reset at registry build and occupant swap; no per-file clear. *(scoping)*
- `format_validate_scan_sub` :: `my $saved_cache = timestamp_date_cache_snapshot();` :: snapshot and restore around validation. *(scoping)*
- `calculate_start_end_filter_timestamps` :: `$epoch_value = Time::Piece->strptime( $value, "%Y-%m-%d %H:%M:%S" )->epoch;` :: the bound parser, five shapes, space only. *(scoping)*
- `calculate_start_end_filter_timestamps` :: `defer_notice("Warning: unhandled date/time format - option not taken into account\n");` :: its only notice, for a value matching no shape. *(audit)*
- `parse_iso_date_to_epoch` :: `return eval { timegm($6, $5, $4, $3, $2 - 1, $1) };` :: index read-back, `T` required, silent on failure. *(scoping)*
- `format_sample_probes` :: `my $epoch = eval { timegm($sec, $mi, $h, $dy, $mo - 1, $y) };` and `if ($mo > 12 || $dy > 31) { $r->{oor}++; next }` :: the detection scorer's own checks. *(scoping, snippet added)*
- `(file scope, %format_transform_code, after sub emit_index_readback_verbose)` :: `chop_tz_offset      => q{ $timestamp_str =~ s/ \+\d{4}$//; },` :: the four normalisation primitives. *(scoping)*
- `fold_epoch` :: `my @t = gmtime($epoch);` :: a second epoch-to-position transform in the loop, under `--profile` only. *(audit)*

### Verification notes

- Every snippet resolves to its enclosing sub. The generated-source sites are
  cited by the text of the source string inside `format_entry_block_src`, as the
  specification requires; the Perl messages quote `(eval 88)` because the
  failing code is the compiled scan sub.
- The scoping pass's F3.2 ("by reading, a CSV value such as 2025-13-01 passes
  the guard and reaches an unguarded timegm, which croaks") is confirmed
  exactly; the audit adds that the scanned arm's guard has the same gap for a
  day impossible for its month, which the reading did not anticipate.
- The scoping pass's F3.3 is confirmed exactly (warning text and epoch zero);
  the audit adds the visible consequence (a 1970 bucket on the timeline).
- The scoping pass's F3.8 (four validity policies) is superseded by the
  seven-parser table above, which adds the bound parser's two behaviours and the
  Apache arm's Perl warning.
- The `-st`/`-et` run on a `T` value was not in the scoping pass; it was run
  because three other parsers accept or require the `T` separator.

### Questions for the findings discussion, with the evidence bearing on each

- *Is the inline-versus-closure duplication in scope, given D31 and P8?* The
  runs show the two copies fail identically, so parity holds today; the cost of
  the duplication is that every change to the guard or the fraction handling
  (#386) has to be made twice. Generating the closure from the same source string
  keeps both and removes the second text.
- *Are the confirmed gaps findings of this audit or bugs of their own?* The
  audit's recommendation: F3.2 and F3.3 are bugs of their own, filed ahead of any
  convergence, because a single malformed line aborts a run (F3.2) or produces a
  1970 bucket and a Perl warning (F3.3), and the fix shape (a guard policy) is
  small; F3.10 is a bug of its own on the option surface.
- *Should the CSV ISO arm receive the normalisation primitives and the guard?*
  csv-tz shows the cost of not having the chops; the CSV entry already declares
  `tz => 'utc'`, so declaring the chops is consistent with its contract.
- *Do the off-loop parsers converge on one policy?* The bound parser's module
  croak and `T` handling (F3.10) argue yes for the option surface; the detection
  scorer stays separate by design.
- *Does the issue body's wording get trued up?* § 3 of the specification records
  the corrections; the audit adds none.


---

## Item 4: Aggregation and statistics gating

**State: audit complete (2026-09-26).** The four angles were run on the issue
branch; three candidates are confirmed as diverged by captured runs (the impact
divisor, the bytes-mean precision on the two CSVs, the formatted zero for a bucket
with no observation of a metric), one is refined by the runs (the formatted zero
appears only for a bucket that reached the store initialiser through some other
metric), and the rest are classified from the captures as latent rule violations
or restated formulas. Captures are under the session scratchpad (`342/runs4/`
and `342/runs4-dtb/`); every run passed `--disable-progress`, `-bs 1`, `-ni`,
`-o` and `-n 5`.

### Fixtures used by the confirmation runs

- **impact-mixed**: four application-log lines (the shape of
  `tests/fixtures/numeric-highlight-boundary.txt`, one minute) reading
  `Processing request <uuid> done`, the first two with `durationMS=100` and
  `durationMS=300`, the last two with no duration, each with a distinct UUID so
  that `-g 60` consolidates all four into one row.
- **bytes-half**: two access-log lines of one path with response sizes 512 and
  513 (mean 512.5) and durations 10 and 20 ms.
- **bytes-then-dash**: two access-log lines of one path, one minute apart, the
  second with `-` for its response size.
- **duration-then-none**: two application-log lines `Heartbeat ok`, one minute
  apart, the first with `durationMS=100`, the second carrying no metric at all.
- **duration-then-bytes-only**: the same, the second line carrying `bytes=60`
  and no duration.
- The message-store data models were compared on impact-mixed under `-mdm raw`
  and `-mdm bin`.

### Search angles run

1. **By operator.** Every `/` whose right operand is a count-shaped name
   (occurrences, a `_count` field, `$n`, a denominator, distinct, classified,
   included, lines, seen, samples, the bucket width) and every `* 100`: 66
   lines in 25 subs (`i4-angle1-divisions.txt`). Excluded as geometry: the
   histogram and heatmap boundary ratios, the bucket-key division, column
   scaling, the Dice coefficient. What remains is 41 derivation sites in 14
   subs; no shared mean or ratio helper exists (no sub in `ltl` is named for a
   mean, ratio, average or percentage).
2. **By field pair.** Every site of `total_bytes`, `total_duration`,
   `total_duration_num`, `bytes_occurrences`, `duration_count`, `count_sum`,
   `count_occurrences`, the per-file `*_sum` and `*_occurrences` pairs, the
   outcome counters, `_running_mean`, `sum_of_squares` and the user-defined
   `udm_<name>_sum` and `_occurrences` fields: 194 lines
   (`i4-angle2-fields.txt`). The increments are all in `read_and_process_logs`
   (per message, per bucket, per file) plus the roll-ups in
   `calculate_all_statistics`, `merge_consolidation_stats` and
   `merge_bin_state`; the initialisers are the two store constructors in
   `read_and_process_logs`, which zero `total_bytes`, `total_duration` and
   `sum_of_squares` in both data models and leave every count field except
   `duration_count` (bin model only) uninitialised.
3. **By gate.** Every `defined` over a total or a sum in a condition, every
   postfix `if defined` on a derived assignment, every `|| 1` or `// 1` divisor:
   22 lines (`i4-angle3-gates.txt`), listed under the findings.
4. **By surface pair.** The statistics that reach two surfaces were run and
   their cells compared: the per-message bytes mean (terminal table and
   MESSAGES CSV against STATS CSV), the per-bucket duration and bytes totals
   (timeline against STATS CSV), the impact (MESSAGES CSV against the duration
   mean on the same row), the unclassified percentage (item 2, F2.8).

### Findings

| # | Derived quantity | Site A | Site B (further copies in the note) | Gate, divisor, precision at each | Observed divergence | Target | Contract and owner | Category | Related open issues |
|---|---|---|---|---|---|---|---|---|---|
| **F4.5** | The impact mean's divisor | `read_and_process_logs` :: `my $mean = $log_messages{$category}{$log_key}{total_duration} / $log_messages{$category}{$log_key}{occurrences};` | `group_similar_messages` :: `my $mean = $entry->{total_duration} / $entry->{occurrences};` (the same divisor after consolidation) against `calculate_statistics` :: `my $mean = $bucket_data->{total_duration} / $duration_count;` and `calculate_statistics_bin` :: `my $mean = $sidecar_entry->{total_duration} / $n;` | Impact divides the duration total by every matched line; the duration mean divides by the lines that carried a duration. Impact is `log(mean ** 7 * occurrences)` | Fixture impact-mixed, `-g 60 -so impact`: the consolidated row's MESSAGES CSV cells read `occurrences=4`, `duration=400`, `duration_mean=200` and `impact=33.622`. The impact's own mean for that row is 400 / 4 = 100; the same formula over the duration mean the row reports (200) gives 38.475. The row is ranked as if its requests took half as long as its own mean column says | One derivation of a per-message mean with the observation count as divisor, shared by the impact and the statistics subs; impact recomputed from it | None on record defines impact's divisor. `features/432-metric-aggregate-naming-parity.md` F1 (as corrected in the specification § 3 item 10) fixed this divisor shape for the bytes mean and is the precedent | **diverged**, *hot path* | #426 (per-message store representation, on hold) rewrites every per-message accumulator read, including both impact sites. #469 (consolidated histograms on a shared grid) changes what `group_similar_messages` carries into the recompute |
| **F4.4** | The per-message bytes mean's precision | `print_message_summary` :: `? int( $total_bytes_num / $bytes_occurrences + 0.5 )` | `calculate_all_statistics` :: `bytes_mean    => $log_analysis{$bucket}{bytes_occurrences} ? ($log_analysis{$bucket}{total_bytes} / $log_analysis{$bucket}{bytes_occurrences}) : undef,` (per bucket, full precision, then `format_csv_value` at zero decimals), and `calculate_all_statistics` :: `$entry->{bytes_mean} = $entry->{bytes_occurrences}` (the sort pre-pass, full precision) | A rounds half up to an integer before the value reaches the CSV; B keeps the fraction and the CSV formatter rounds half to even | Fixture bytes-half: the MESSAGES CSV `bytes_mean` reads `513`, the STATS CSV `bytes_mean` for the one bucket holding the same two lines reads `512`. Two integers for one mean of 512.5, differing by the rounding rule of the copy | The per-message mean stored at full precision (as the sort pre-pass already does) and rounded only by `format_csv_value` on both CSVs | `features/432-metric-aggregate-naming-parity.md` D5 (bytes gains the full basic family on both CSV surfaces) says nothing about precision; `features/561-retained-durations-as-numbers.md` (storage stays precise) is the pattern | **diverged** | #273 (store precise, format at the rendering boundary) records the same shape for the duration total; this is its bytes twin |
| **F4.10** | A total projected from a zero-initialised field | `read_and_process_logs` :: `total_duration => 0,` (both store constructors; `total_bytes => 0,` beside it) and `calculate_all_statistics` :: `duration      => $log_analysis{$bucket}{total_duration},` (ungated, twice; `bytes         => $log_analysis{$bucket}{total_bytes},` likewise) | `print_bar_graph` :: `(defined $log_stats{$bucket}{$key} ? ltrim(format_duration_total($log_stats{$bucket}{$key}, 'medium', ' ')) : undef),` and its bytes twin `(defined $log_stats{$bucket}{$key} ? format_bytes($log_stats{$bucket}{$key}, 'B') : undef),` (the STATS `_nice` cells); the timeline's total column reads the same projection | The store zeroes the totals; the projection copies them without an observation gate; the cell tests `defined`, which a zero passes | Fixture duration-then-bytes-only: the bucket whose only line carries bytes and no duration writes `duration_nice=0 msec`, `duration=0`, `duration_mean=` (empty) and the timeline shows `0 milliseconds`. Fixture bytes-then-dash: the bucket whose only line carries `-` for bytes writes `bytes_nice=0 B`, `bytes=0`, `bytes_occurrences=` (empty) and the timeline shows `0 B`. A reader cannot tell a zero total from no observation, while the mean beside it says "none". Fixture duration-then-none, whose second line carries no metric at all, writes empty cells for both, because that line's bucket never reached the store constructor and the total was never zeroed | The totals gated on their observation counts at projection (`duration_count` or the retained array's length; `bytes_occurrences`), as the CLAUDE.md rule requires, so a bucket with no observation carries `undef` and the cell is empty | CLAUDE.md § Before writing or changing code (derived output gated on `count > 0`, never on `defined` over a zero-initialised field); `features/516-bytes-aggregate-demand-gate.md` D2 (absence-tolerant reads) | **diverged** | #514 (count metric explicit) adds or removes a total of this shape; #426 changes the store constructors |
| **F4.11** | Accumulators without an unconditional observation count | `read_and_process_logs` :: `if( $e->{bytes_occurrences}++ ) {` (incremented under `if( $bytes_aggregate_demand )`, per message and per bucket) | `read_and_process_logs` :: `$e->{total_bytes} += $bytes;` (unconditional, same block); the raw-model duration total `$log_messages{$category}{$log_key}{total_duration} += $duration;` with no count field in that model (`duration_count` exists in the bin model only; the raw model has `scalar @{ durations }`) | The total accumulates on every line carrying the metric; the count only when a consumer demanded the aggregate family | Observable as F4.10's `bytes_occurrences=` (empty) beside `bytes=0` in bytes-then-dash; and as the divisor question in F4.5, where the raw model has no count to divide by except the retained array's length | Every accumulator keeps its observation count unconditionally (one integer per store entry), and the demand gate governs the min, mean and max only | CLAUDE.md rule (every accumulator tracks an observation count); `features/516-bytes-aggregate-demand-gate.md` D1 (one store-level demand flag) and D2 | **latent** (the reads compensate today), *hot path* | #516 is closed; #426 rewrites the store; #514 touches the count family's counts |
| **F4.3** | The per-message count mean's gate | `calculate_all_statistics` :: `$entry->{count_mean} = ( defined $entry->{count_sum} && $entry->{count_occurrences} )` (sort pre-pass: truthiness) | `calculate_all_statistics` :: `: undef if defined $log_messages{$category}{$log_key}{count_occurrences};` (group calculation: the postfix leaves the field untouched when the count is absent) and `calculate_all_statistics` :: `count_mean    => ( defined $log_analysis{$bucket}{count_sum} && defined $log_analysis{$bucket}{count_occurrences}` (per bucket, twice, word for word) | Three gate shapes for one derivation, four copies | Identical in effect today (no path sets a stale value for the postfix to preserve); the neighbouring `calculate_all_statistics` :: `$log_messages{$category}{$log_key}{count_sum} = $log_messages{$category}{$log_key}{count_sum} if defined $log_messages{$category}{$log_key}{count_sum};` is a self-assignment that does nothing | One `mean_of($sum, $count)` helper with the gate inside, called at all four sites | CLAUDE.md rule | **latent** | #514 (count metric explicit) is the change that would otherwise touch all four |
| **F4.1 / F4.2** | The per-bucket user-defined mean | `calculate_all_statistics` :: `$log_stats{$bucket}{"udm_${name}_mean"} = (defined $occ && $occ > 0)` (no defined-sum guard; the same division four lines later in `elsif ($agg eq 'mean') { $display_value = (defined $occ && $occ > 0)`) | `calculate_all_statistics` :: `$log_messages{$category}{$log_key}{"udm_${name}_mean"} = (defined $sum && defined $occ && $occ > 0) ? $sum / $occ : undef;` (the #326 fix, per message) | The per-message copy gained a defined-sum guard from #326; the per-bucket copy relies on counting aggregations leaving the loop earlier, and computes the mean twice | Identical today | The same helper as F4.3, and the display value read from the stored mean | `features/user-defined-metrics.md` § Known Issues (#326) | **latent** | none |
| **F4.7** | Duration mean, variance, CV and moments | `calculate_statistics` :: `my $sum_sq_dev = $bucket_data->{sum_of_squares} - $duration_count * ($mean ** 2);` | `calculate_statistics_bin` :: `my $sum_sq_dev = $sidecar_entry->{sum_of_squares} - $n * ($mean ** 2);` (and `my $m2 = $sidecar_entry->{m2_sum} / $n;` against `my $m2 = $m2_sum / $n;`) | The raw and bin subs restate the same formulas over two store shapes; the gates differ in spelling (`occurrences > 0` then a non-empty array; `occurrences // 0 > 0` then `duration_count > 0`) | Identical on impact-mixed under `-mdm raw` and `-mdm bin` (means 100 and 300, no dispersion on single observations); the drift engine of `validate-statistics` holds them equal on the corpus | One statistics sub taking the count, sum, sum of squares and moment sums, with the raw and bin paths supplying them; percentiles stay per model | `features/duration-statistics.md` § Stores and primitives; `features/293-precision-lever-unification.md` | **latent** | #426 (store representation) and #354 (bin model memory, on hold) both change the store shapes these two subs read |
| **F4.6** | The impact gate | `read_and_process_logs` :: `if( $duration > 0 ) {` | `group_similar_messages` :: `if (defined $entry->{total_duration} && $entry->{occurrences} > 0 && $entry->{total_duration} > 0) {` | The read loop gates on the current line's duration; the recompute gates on `defined` over the zero-initialised total (always true), then two positive tests | Identical in effect; the `defined` is the rule-violating shape | Folded into F4.5's target | as F4.5 | **latent** | as F4.5 |
| **F4.12** | Welford's running mean | `read_and_process_logs` :: `my $delta_n  = $delta / $n;` (per message under the bin model, and again per bucket) | `merge_bin_state` :: `my $mean_ab = $mean_a + $delta * $n_b / $n_ab;` | Three copies of the update, two of them in the loop with the same text | Identical today | One `welford_update($entry, $value)` for the two loop copies (item 8 lists the pair as a loop-structure finding) | `features/189-histogram-bin-counter-primitives.md` | **latent**, *hot path* | #469 (shared bucket grid) changes what the merge copy combines |
| **F4.13** | Column-scaling maxima and the latency block | `normalize_data_for_output` :: `$max_total{duration} = $log_stats{$bucket}{duration} if ( defined $log_stats{$bucket}{duration}` (and `$log_stats{$bucket}{$scaled_key} = ( defined $log_stats{$bucket}{$key} && defined $max_total{$key} && $max_total{$key} != 0 )` with its `-HL` twin) | `print_bar_graph` :: `if( defined $log_stats{$bucket}{bytes} \|\| defined $log_stats{$bucket}{p50}` | Both test `defined` over the zero-initialised totals: harmless for a maximum, and an always-true first disjunct for the latency block | No observable consequence: a zero maximum scales nothing and the latency block's other disjuncts decide | Same gate as F4.10 | CLAUDE.md rule | **latent** | none |
| **F4.14** | A substitute divisor | `pipeline_finalize` :: `(1 - $final_remaining / ($keys_seen || 1)) * 100);` (twice) and `pipeline_finalize` :: `($s->{s3_calls} // 0) > 0 ? (($s->{s3_checkpoint} // 0) / ($s->{s3_calls} // 1)) * 100 : 0);` | `run_consolidation_checkpoint` :: `my $absorption_rate = $pre_count > 0 ? $absorbed / $pre_count : 0;` (gated) | The reduction percentage substitutes 1 for a zero count; its neighbours gate | `-V` consolidation diagnostics only: a run with no keys prints a reduction of 100 percent | Gate as the neighbours do | CLAUDE.md rule | **latent** (diagnostic only) | none |
| **F4.8** | The per-file index means | `write_index_file` :: `my $dur_avg   = $fd->{duration_occurrences} > 0 ? sprintf("%.2f", $fd->{duration_sum} / $fd->{duration_occurrences}) : '-';` | `calculate_all_statistics` :: `bytes_mean    => $log_analysis{$bucket}{bytes_occurrences} ? ($log_analysis{$bucket}{total_bytes} / $log_analysis{$bucket}{bytes_occurrences}) : undef,` | Six gated means (compliant) formatted inline with a `-` sentinel, apart from every other mean; the field names mix (`bytes_sum` over `file_bytes_occurrences`) | Item 2, F2.13 (`128.75` against `129`) | The same helper as F4.3, formatted by `format_csv_value` (F2.13's target) | none | **latent** (precision is F2.13) | none |

Sites audited and closed as **deliberate** or compliant:

- Every gate on a count field (`bytes_occurrences ?`, `count_occurrences > 0`,
  `$n > 0`, `$eligible && $classified`, `$denominator`, `$pre_count > 0`,
  `$seen > 0`, `$max_memory_usage > 0`) is compliant with the CLAUDE.md rule and
  is listed in the inventory without a finding.
- The per-bucket success and failure percentages
  (`normalize_data_for_output` :: `$log_stats{$bucket}{success_pct} = ($bucket_outcome->[1] // 0) / $bucket_classified * 100;`)
  and the run-level ones (`classification_reconciliation`) derive the same
  quantity from two populations by design
  (`features/452-success-failure-percentage-columns.md`).
- The error and message rates divide by the bucket width, a run constant, and
  need no gate (`normalize_data_for_output` :: `$log_occurrences{$bucket}{'err-rate'}{occurrences} = $error_occurrences / $bucket_size_seconds * $rate_multiplier{$rate_unit};`).
- The counting-aggregation ratio and rate derivations
  (`calculate_all_statistics` :: `elsif ($agg eq 'ratio')    { $display_value = $occ / $distinct; }`)
  are gated on `$occ > 0` with a stated invariant that `distinct >= 1` then.
- `merge_bin_state` is count-gated (`return` on `n_b == 0`, a branch for
  `n_a == 0`).

### Open issues touching this item as a whole

- **#426** (per-message statistics store as parallel arrays, on hold): every
  per-message derivation site in this item reads the store it would replace;
  a shared mean helper landing first gives it one site to retarget per quantity.
- **#469** (consolidated message histograms on a shared bucket grid): changes
  what `merge_bin_state` and the consolidation recompute (F4.5, F4.12) combine.
- **#273** (store precise, format at the rendering boundary): F4.4 is the same
  shape for the bytes mean.
- **#514** (count metric capture explicit, `next-up`): the count family's four
  mean copies (F4.3) and its totals (F4.10, F4.11).
- **#354** (bin model memory on singleton-dominated logs, on hold): changes the
  bin store shape `calculate_statistics_bin` reads (F4.7).
- **#535** (normalised rates diverge at fine bucket widths): a research issue
  on the rate derivation's meaning, not its copies; informational.

### Site inventory

Carried from the scoping pass (*(scoping)*; its eight verifier additions
included) with the audit's additions:

- `calculate_all_statistics` :: `count_mean    => ( defined $log_analysis{$bucket}{count_sum} && defined $log_analysis{$bucket}{count_occurrences}` :: per-bucket count mean, twice. *(scoping)*
- `calculate_all_statistics` :: `bytes_mean    => $log_analysis{$bucket}{bytes_occurrences} ? ($log_analysis{$bucket}{total_bytes} / $log_analysis{$bucket}{bytes_occurrences}) : undef,` :: per-bucket bytes mean, twice. *(scoping)*
- `calculate_all_statistics` :: `bytes         => $log_analysis{$bucket}{total_bytes},` :: ungated projections of the zeroed totals (with `duration      => $log_analysis{$bucket}{total_duration},` and the `-HL` twins). *(scoping)*
- `calculate_all_statistics` :: `elsif ($agg eq 'ratio')    { $display_value = $occ / $distinct; }` and `elsif ($agg eq 'ratio')    { $hl_value = $occ_hl / $distinct_hl; }` :: counting aggregations. *(scoping)*
- `calculate_all_statistics` :: `$log_stats{$bucket}{"udm_${name}_mean"} = (defined $occ && $occ > 0)` and `elsif ($agg eq 'mean') { $display_value = (defined $occ && $occ > 0)` :: per-bucket user-defined mean, twice. *(scoping)*
- `calculate_all_statistics` :: `$entry->{bytes_mean} = $entry->{bytes_occurrences}` and `$entry->{count_mean} = ( defined $entry->{count_sum} && $entry->{count_occurrences} )` :: the sort pre-pass. *(scoping)*
- `calculate_all_statistics` :: `: undef if defined $log_messages{$category}{$log_key}{count_occurrences};` :: the group-calculation count mean. *(scoping)*
- `calculate_all_statistics` :: `$log_messages{$category}{$log_key}{count_sum} = $log_messages{$category}{$log_key}{count_sum} if defined $log_messages{$category}{$log_key}{count_sum};` :: a self-assignment. *(audit)*
- `calculate_all_statistics` :: `$log_messages{$category}{$log_key}{"udm_${name}_mean"} = (defined $sum && defined $occ && $occ > 0) ? $sum / $occ : undef;` :: the #326 site. *(scoping)*
- `calculate_all_statistics` :: `$duration_observed ||= ( ($log_messages{$category}{$log_key}{total_duration} // 0) > 0 );` :: the #330 observed gate. *(scoping)*
- `calculate_all_statistics` :: `$aggregated_data->{total_bytes} += $log_messages{$category}{$log_key}{total_bytes} if defined $log_messages{$category}{$log_key}{total_bytes};` :: a roll-up gated on `defined` over a zeroed field. *(audit)*
- `calculate_statistics` :: `my $mean = $bucket_data->{total_duration} / $duration_count;` :: raw-model duration statistics. *(scoping)*
- `calculate_statistics_bin` :: `my $mean = $sidecar_entry->{total_duration} / $n;` :: bin-model twin. *(scoping)*
- `read_and_process_logs` :: `my $mean = $log_messages{$category}{$log_key}{total_duration} / $log_messages{$category}{$log_key}{occurrences};` :: impact in the loop; `$impact_time_exponent` is 7 at file scope. *(scoping)*
- `read_and_process_logs` :: `total_duration => 0,` :: the store constructors (message and bucket, both models). *(audit)*
- `read_and_process_logs` :: `if( $e->{bytes_occurrences}++ ) {` and `$e->{total_bytes} += $bytes;` :: the demand-gated count beside the unconditional total. *(audit)*
- `read_and_process_logs` :: `$fd->{duration_occurrences}++;` :: the per-file pairs (unconditional counts). *(audit)*
- `read_and_process_logs` :: `my $delta_n  = $delta / $n;` :: the Welford update, twice. *(scoping)*
- `group_similar_messages` :: `if (defined $entry->{total_duration} && $entry->{occurrences} > 0 && $entry->{total_duration} > 0) {` :: the impact recompute. *(scoping)*
- `merge_bin_state` :: `my $mean_ab = $mean_a + $delta * $n_b / $n_ab;` *(scoping)*
- `merge_consolidation_stats` :: `$target->{total_bytes} = ($target->{total_bytes} // 0) + $source->{total_bytes} if defined $source->{total_bytes};` :: the consolidation roll-up, `defined` over a zeroed field. *(audit)*
- `print_message_summary` :: `? int( $total_bytes_num / $bytes_occurrences + 0.5 )` *(scoping)*
- `normalize_data_for_output` :: `$log_stats{$bucket}{success_pct} = ($bucket_outcome->[1] // 0) / $bucket_classified * 100;` *(scoping)*
- `normalize_data_for_output` :: `$log_occurrences{$bucket}{'err-rate'}{occurrences} = $error_occurrences / $bucket_size_seconds * $rate_multiplier{$rate_unit};` *(scoping)*
- `normalize_data_for_output` :: `$max_total{duration} = $log_stats{$bucket}{duration} if ( defined $log_stats{$bucket}{duration}` and `$log_stats{$bucket}{$scaled_key} = ( defined $log_stats{$bucket}{$key} && defined $max_total{$key} && $max_total{$key} != 0 )` *(scoping)*
- `print_bar_graph` :: `if( defined $log_stats{$bucket}{bytes} || defined $log_stats{$bucket}{p50}` *(scoping)*
- `print_bar_graph` :: `(defined $log_stats{$bucket}{$key} ? ltrim(format_duration_total($log_stats{$bucket}{$key}, 'medium', ' ')) : undef),` :: the STATS nice cells. *(scoping)*
- `write_index_file` :: `my $dur_avg   = $fd->{duration_occurrences} > 0 ? sprintf("%.2f", $fd->{duration_sum} / $fd->{duration_occurrences}) : '-';` *(scoping)*
- `classification_reconciliation` :: `success_pct    => ($eligible && $classified) ? $total_successes / $classified * 100 : undef,` *(scoping)*
- `emit_classification_percentage_notices` :: `my $leak_pct = $r->{included} ?` and `emit_format_detection_verbose` :: `? sprintf('%.1f', $format_scan_nomatch_sample_us / $format_scan_nomatch_samples)` *(scoping)*
- `share_row_text` :: `my $share = format_percentage( $count / $denominator * 100,` *(scoping)*
- `sample_file_for_detection` :: `$obs->{avg_line} = $obs->{lines} ? int($line_bytes / $obs->{lines} + 0.5) : 0;` *(scoping)*
- `run_consolidation_checkpoint` :: `my $absorption_rate = $pre_count > 0 ? $absorbed / $pre_count : 0;` and `group_similar_messages` :: `next if ($absorbed / $seen) > $consolidation_skip_absorption;` *(scoping)*
- `pipeline_finalize` :: `(1 - $final_remaining / ($keys_seen || 1)) * 100);` *(scoping)*
- `print_summary_table` :: `my $pct = $max_memory_usage > 0 ? ($size / $max_memory_usage) * 100 : 0;` :: the memory share, gated. *(audit)*

### Verification notes

- Every snippet resolves to its enclosing sub. The scoping pass's line hints
  are dropped.
- The scoping pass's claim that a STATS bucket with lines but no duration
  observation writes a formatted zero is confirmed only for a bucket whose
  lines carried some other metric (F4.10); a line carrying no metric at all
  produces empty cells. The audit records both fixtures so the condition is
  not overstated.
- The scoping pass's F4.4 ("fractional against integer") is sharpened by the
  run: both CSVs write integers at the default precision, and they differ by
  their rounding rules.
- The `-mdm raw` against `-mdm bin` comparison on the four-line fixture cannot
  exercise the dispersion formulas (single observations); the restatement
  finding F4.7 rests on reading and on the drift engine's coverage, and is
  latent.

### Questions for the findings discussion, with the evidence bearing on each

- *Is the impact mean intentionally weighted by all matched lines?* The
  consolidated row shows the effect: a mean of 100 inside impact beside a
  reported mean of 200. If intentional, it is a different statistic from the
  mean and its doc should say so; if not, it is the #432 F1 divisor defect for
  duration, and the audit recommends it is filed as a bug.
- *Should a STATS bucket with no observation of a metric write an empty cell?*
  Two fixtures show `0 msec` and `0 B` beside empty means and counts.
- *Is the MESSAGES integer bytes mean against the STATS integer bytes mean a
  sanctioned difference?* `513` against `512` for one pair of lines is a
  rounding-rule difference, not a precision choice; the audit recommends one
  path through `format_csv_value`.
- *Does the CLAUDE.md rule require unconditional counts?* `bytes_occurrences`
  is absent while `total_bytes` is zero in the same row; the rule as written
  says the count is always tracked. The demand gate can keep governing the min,
  mean and max.
- *Should the raw and bin statistics converge on one sub?* The formulas are the
  same text over two shapes; the harness already proves them equal, so the
  convergence is a maintenance change with a behaviour-neutral proof available.


---

## Item 5: Filter and highlight range checks

**State: audit complete (2026-09-26).** The three angles were run on the issue
branch. The variable angle confirms the scoping pass's fourteen sites and adds
none; the runs confirm that the two codings of one closed interval agree, that
the exclusion count is reported three ways, that the missing-metric asymmetry is
the one #321 decided, and that negative bounds are accepted and applied. Captures
are under the session scratchpad (`342/runs5/`, `342/runs5-plain/`); every run
used `tests/fixtures/numeric-highlight-boundary.txt` (nineteen application-log
lines placing each metric below, at and above a bound, one line per metric with
no value for it) with `--disable-progress`, `-bs 1440`, `-ni` and
`-V filter-summary`.

### Search angles run

1. **By variable.** Every occurrence of the twelve bound variables, the
   activation flag, the missing-metric tally and the exclusion counter: 77 lines
   (`i5-angle1-vars.txt`), 21 of them in the loop and 23 in option settlement.
   No comparison site exists outside `read_and_process_logs`; the scoping
   pass's fourteen sites are the population.
2. **By table.** The inverted-range table's twelve rows against the seven other
   enumerations. Four hold all twelve (`GetOptions`, the provenance name list,
   the `-V runtime-config` registry, the inverted-range table); three hold the
   six filter bounds (`has_active_filters`, `serialize_filters`, the aggregate
   export's `grep`); one holds the six highlight bounds (the activation test).
   Every subset is complete for what it enumerates; the pairing of a metric's
   min, max and two option names exists in the inverted-range table only.
3. **By example text.** `docs/usage.md` names the twelve in twelve rows and in
   prose at three places and two examples; `--help` carries the twelve rows,
   the filter note and one example; `--explain` carries two examples of
   `-hdmin`. Every one of these would follow a change to the option surface;
   none carries logic.

### Findings

| # | Decision | Site A | Site B (further copies in the note) | What each does | Observed divergence | Target | Contract and owner | Category | Related open issues |
|---|---|---|---|---|---|---|---|---|---|
| **F5.3** | Whether the numeric exclusion count is reported | `write_aggregate_export` :: `$excluded->{numeric}     = $excluded_numeric if grep { defined } ($filter_duration_min, $filter_duration_max, $filter_bytes_min, $filter_bytes_max, $filter_count_min, $filter_count_max);` | `emit_filter_summary_verbose` :: `push @verbose_output, "excluded_numeric: $excluded_numeric";` and `lines_excluded_total` :: `return $excluded_time_window + $profile_dropped_samples + $excluded_filter + $excluded_numeric + $excluded_other;` | A emits the key only when a filter bound is defined; B and C use the count unconditionally | With no bound: the aggregate export's `excluded:` mapping holds `other: 0` and no `numeric` key, while the same run's verbose summary prints `excluded_numeric: 0`. With `-dmin 1`: the export holds `numeric: 1` and the summary `excluded_numeric: 1` | One rule, held with the count: either every consumer reports it whenever the run could have produced it (the filter surface exists), or every consumer reports it only when a bound was given | `features/503-yaml-aggregate-export.md` § `-V aggregate-export` section contract (locked as built) governs the export's shape; the `-V filter-summary` contract is in `tests/HARNESS-DESIGN.md` | **diverged** | #454 (notice that statistics describe a filtered subset) is a fourth consumer of "was a line-discarding filter active", and should read the one rule |
| **F5.6** | Negative bounds | `adapt_to_command_line_options` :: `'duration-min\|dmin=i' => \$filter_duration_min,` (twelve `=i` options) | `adapt_to_command_line_options` :: `if (defined $min && defined $max && $min > $max) {` (the only validation, inverted range) | The option type accepts any integer; nothing rejects a negative one, and the loop applies it | `-dmin -5 -hbmax -1`: accepted without a notice; the duration filter runs (one line without a duration is excluded and noted), and a highlight bound below zero is active with nothing to highlight | A value check at settlement beside the inverted-range check, from the same table | `features/312-numeric-criteria-highlight-selection.md` § Decisions (inverted range validated once, for all twelve) says nothing about sign | **diverged** (an accepted value no line can satisfy is not reported, where an inverted range is) | #605 (numeric, byte and duration inputs accept a value with a unit, `next-up`) rewrites the twelve options' value parsing and is where a sign check would be added |
| **F5.4** | The set of bound variables | `adapt_to_command_line_options` :: `[ $filter_duration_min,    $filter_duration_max,    '-dmin',  '-dmax',  'no log entries can match'         ],` (the only site pairing metric, bounds and option names) | `has_active_filters` :: `return 1 if defined $filter_duration_min \|\| defined $filter_duration_max;`, `serialize_filters` :: `push @parts, "-dmin=$filter_duration_min"     if defined $filter_duration_min;`, the aggregate export's `grep`, `adapt_to_command_line_options` :: `$numeric_highlight_active = ( grep { defined }`, `emit_runtime_config_verbose` :: `'highlight-duration-min'            => $highlight_duration_min,`, `_classify_argv_provenance` :: `'highlight-duration-min\|hdmin', 'highlight-duration-max\|hdmax',` | Eight hand-written enumerations of one set in three subsets; twelve independent scalars with no structure grouping them | Every enumeration complete today | One declaration of the six bound families (metric, filter min and max, highlight min and max, four option names) from which the eight enumerations derive, leaving the twelve scalars in place for the loop | `features/312-numeric-criteria-highlight-selection.md` § Option surface (highlight bounds stay out of the index signature): the declaration carries that as a flag | **latent** | #605 adds a unit parse to each of the twelve, one more place per option unless the declaration exists; #536 and #537 (thread name and remote host as attributes for filtering and highlighting) add families to the set |
| **F5.1** | One closed interval, two codings | `read_and_process_logs` :: `if( defined( $filter_duration_min ) && $duration < $filter_duration_min ) { $excluded_numeric++; next; }` (three filter blocks: a missing-metric guard and two complement tests each) | `read_and_process_logs` :: `( !defined( $highlight_duration_min ) \|\| ( defined( $duration ) && $duration >= $highlight_duration_min ) )` (six positive clauses in one predicate) | The filter drops on the complement with early exits; the highlight tests the positive form inside one boolean | `-dmin 100 -dmax 200` keeps four lines (`lines_included: 4`); `-hdmin 100 -hdmax 200` highlights four (`lines_highlighted: 4`) of nineteen. Equivalent today, by fifteen hand-kept comparisons | No shared per-line sub: the #312 hot-loop rule (one falsy scalar read when no numeric highlight is given) forbids a call where a scalar test is. The convergence is the declaration of F5.4, from which a generated or table-driven check could be built if item 8's measurement shows the twelve `defined` tests are worth removing | `features/312-numeric-criteria-highlight-selection.md` § Design, Core mechanism; `features/478-highlight-decision-read-back.md` D1 to D7 (one tag point) | **latent**, *hot path* | none |
| **F5.2** | Missing-metric accounting | `read_and_process_logs` :: `if( !defined( $duration ) ) { $numeric_filter_no_metric{duration}++; $excluded_numeric++; next; }` | `read_and_process_logs` :: `( !defined( $highlight_duration_min ) \|\| ( defined( $duration ) && $duration >= $highlight_duration_min ) )` (fails silently) | The filter counts the line and a notice reports it; the highlight clause fails without a counter | `-dmin 1`: `Note: 1 lines carried no duration value and were excluded by the duration filter ...` and `excluded_numeric: 1`; `-hdmin 1`: no notice, `lines_highlighted: 18` of nineteen | none: recorded so a shared predicate keeps the asymmetry | `features/312-numeric-criteria-highlight-selection.md` § Undefined metric (never satisfies) and the #321 resolution (visibility for the filter only) | **deliberate** | none |
| **F5.5** | Help wording | `print_help` :: `help_opt("-dmin, --duration-min <N>",     "Hide log entries with duration below this threshold (inclusive: entries exactly at N are kept)");` | `print_help` :: `help_opt("-bmin, --bytes-min <N>",        "Hide log entries with response size below this threshold (inclusive)");` (and the same split in `docs/usage.md` rows 82 to 87) | Two phrasings of one semantics across six rows | Semantics agree; `tests/validate-help-content.sh` holds `--help` and `docs/usage.md` together | One phrasing, or rows generated from F5.4's declaration | none | **latent** | none |

### Open issues touching this item as a whole

- **#605** (inputs accept a value with a unit, `next-up`): every one of the
  twelve options gains a unit parse; with F5.4's declaration that is one change,
  without it twelve.
- **#454** (notice for a filtered subset): reads "is a line-discarding filter
  active", which `has_active_filters` already answers for the index and F5.3's
  export test answers differently.
- **#536** and **#537** (thread name and remote host as attributes for grouping,
  filtering and highlighting, `next-up`): new criterion families on the same
  tag point.
- **#534** (highlight the lines of one input file): a new highlight criterion
  that composes at the tag point by AND (455 D6); informational.

### Site inventory

Carried from the scoping pass (*(scoping)*, its three verifier additions
included) with the audit's additions:

- `(GLOBALS)` :: `my ( $filter_duration_min, $filter_duration_max );` :: the twelve scalars, the tally and the activation flag. *(scoping)*
- `(GLOBALS)` :: `my ( $excluded_time_window, $excluded_filter, $excluded_numeric, $excluded_other ) = ( 0, 0, 0, 0 );` :: the exclusion counters. *(audit)*
- `adapt_to_command_line_options` :: `'duration-min|dmin=i' => \$filter_duration_min,` :: GetOptions, twelve `=i` options. *(scoping)*
- `adapt_to_command_line_options` :: `$numeric_highlight_active = ( grep { defined }` :: activation, six highlight bounds. *(scoping)*
- `adapt_to_command_line_options` :: `$highlight_active = ( defined($highlight_filter) || $numeric_highlight_active` *(scoping)*
- `adapt_to_command_line_options` :: `[ $filter_duration_min,    $filter_duration_max,    '-dmin',  '-dmax',  'no log entries can match'         ],` :: the inverted-range table. *(scoping)*
- `read_and_process_logs` :: `if( defined( $filter_duration_min ) && $duration < $filter_duration_min ) { $excluded_numeric++; next; }` :: the three filter blocks. *(scoping)*
- `read_and_process_logs` :: `&& ( !$numeric_highlight_active || (` :: the hot-loop gate on the predicate. *(scoping)*
- `read_and_process_logs` :: `( !defined( $highlight_duration_min ) || ( defined( $duration ) && $duration >= $highlight_duration_min ) )` :: the six-clause predicate. *(scoping)*
- `read_and_process_logs` :: `next unless $numeric_filter_no_metric{$metric};` :: the post-run notice. *(scoping)*
- `has_active_filters` :: `return 1 if defined $filter_duration_min || defined $filter_duration_max;` *(scoping)*
- `serialize_filters` :: `push @parts, "-bmax=$filter_bytes_max"       if defined $filter_bytes_max;` *(scoping)*
- `write_aggregate_export` :: `$excluded->{numeric}     = $excluded_numeric if grep { defined } ($filter_duration_min, $filter_duration_max, $filter_bytes_min, $filter_bytes_max, $filter_count_min, $filter_count_max);` *(scoping)*
- `emit_filter_summary_verbose` :: `push @verbose_output, "excluded_numeric: $excluded_numeric";` *(scoping)*
- `lines_excluded_total` :: `return $excluded_time_window + $profile_dropped_samples + $excluded_filter + $excluded_numeric + $excluded_other;` *(scoping)*
- `emit_runtime_config_verbose` :: `'duration-min'                      => $filter_duration_min,` *(scoping)*
- `_classify_argv_provenance` :: `'highlight-duration-min|hdmin', 'highlight-duration-max|hdmax',` *(scoping)*
- `print_help` :: `help_opt("-dmin, --duration-min <N>",     "Hide log entries with duration below this threshold (inclusive: entries exactly at N are kept)");` :: the twelve rows and the note (`my $note_text = "Note: filters affect all computed statistics.`). *(scoping)*
- `print_help` :: `$out .= $ex->("ltl -dmin 5000 access.log",                                     "Only requests slower than 5 seconds");` :: the help example; the explain examples are `ltl -hdmin 5000 access.log` and `ltl -hdmin 60000 node-*/access.2026-05-05.log`. *(audit)*

### Verification notes

- Every snippet resolves to its enclosing sub.
- The scoping pass's inventory is confirmed complete for the twelve variables:
  the audit's variable angle found the same sites and no other.
- The scoping pass's F5.3 named two consumers gated two ways; the verifier's
  third consumer (`lines_excluded_total`) is folded in, and the run shows the
  export key absent, not zero, without a bound.
- The negative-bound observation (F5.6) was raised as a question in the
  specification and is answered by the run: accepted, applied, unreported.

### Questions for the findings discussion, with the evidence bearing on each

- *Should the `-V` filter summary and the export share one gating rule?* The
  export omits the key and the summary prints zero for the same run; #454 will
  need the same answer. A key that is always present and zero when nothing was
  excluded is the cheaper contract for the export's readers.
- *Is negative-integer acceptance in scope?* It is now an observation: the
  bound is applied and no notice says the range cannot match, where an
  inverted range gets one. The fix belongs with #605's parse.
- *Does one declaration of the bound set count as convergence when the
  comparison sites stay inline?* The comparison sites are fifteen hand-kept
  tests proven equivalent by one run; the declaration removes the eight
  enumerations' drift, and the comparisons stay under the #312 hot-loop rule
  until item 8 says otherwise.


---

## Item 6: CSV emission column lists

**State: audit complete (2026-09-26).** The four angles were run on the issue
branch. The family-label disagreement the scoping pass found is confirmed by a
mechanical diff of the rules TSVs against the tool's table and shown to change no
emitted decimals; the header and row lists of both CSVs agree field for field on
captured output; the rest are latent copies. No run was added for this item: the
CSVs captured under item 2 (`342/runs2/cp0.stats.csv`, `cp0.messages.csv`, from
the committed access-log fixture with `-o -cp 0`) carry the headers and rows the
findings cite.

### Search angles run

1. **By emitter.** Every `$csv->print`, `push @output_columns`, `push @row` and
   `push @csv_data`, plus the `@index_columns` and `udm_csv_columns()` sites: 52
   lines (`i6-angle1-emitters.txt`). Four CSV files, two header sites and two row
   sites for the STATS and MESSAGES files, four emits for the run index, one walk
   for the aggregate export.
2. **By family.** Every `qw(...)` holding `occurrences`, `min`, `mean`, `max` or
   `sum`, every `"${key}_..."` and `"${prefix}_..."` construction, and every
   literal `bytes_*` or `count_*` name: 243 lines (`i6-angle2-families.txt`).
   The column-list copies are the eleven listed under the findings; the rest are
   store field names and statistic ladders.
3. **By rules TSV.** Each column of `messages-columns.tsv` (52 rows) and
   `stats-columns.tsv` (136 rows) against the tool's `%csv_column_family` table
   (30 entries, six families) three ways (`i6-angle3-tsv-diff.txt`): present in
   both, present in one, family disagreeing. Present in the TSVs only: the
   twelve percentile columns and every level, rate, session, thread-pool and
   user-defined column, all resolved in the tool by pattern in
   `resolve_csv_column_family` rather than by the table; present in the tool
   only: `timestamp`, and `category`, `message`, `impact` on the STATS side
   (columns of the other file). Family disagreeing: three columns, F6.1.
4. **By harness.** `tests/csv-output/validate-csv-output.pl` checks the header
   against the rules (every header name must have a rule, every required rule a
   column), the per-row field count against the header, each cell's type and
   decimals against its rule, and the family group consistency (if one
   conditional column of a family is populated, all are). It cannot catch a row
   padded to the header width (F6.2) or a value written under the wrong header
   of the same type.

### Findings

| # | Column or family | Site A (header or record) | Site B (row or second record; further copies in the note) | What each does | Observed divergence | Target | Contract and owner | Category | Related open issues |
|---|---|---|---|---|---|---|---|---|---|
| **F6.1** | The precision family of three columns | `(file scope in SUBS, before resolve_csv_column_family)` :: `'duration_std_dev'  => 'shape',` (and `'duration_cv'       => 'shape',`, `'impact'            => 'shape',`), under a comment that says the table mirrors the rules TSVs | `tests/csv-output/rules/stats-columns.tsv` and `messages-columns.tsv`: `duration_std_dev` and `duration_cv` in family `dispersion`, `impact` in family `duration` (messages only); no `dispersion` family exists in the tool | The tool's family decides the emitted decimals (shape: 3 at the default precision); the TSV's family decides the harness's group-consistency check and each row carries its own `max_decimals` | The two records of one contract disagree and the comment is false; the emitted decimals do not change (the tool writes three, the rules allow five for all three columns, so the harness passes). A reader of either record is misled about which family a column belongs to, and a future decimals change to `shape` or `dispersion` lands on different column sets | The table's comment corrected, and the two records reconciled on one label per column (the rules TSVs stay hand-maintained by design); `impact` decided as a duration or a shape statistic once | `tests/csv-output/README.md` § Rules TSV schema and § Updating rules when columns change (the tool and the rules TSV change in the same commit); `features/224-validate-statistics-test-harness.md` Decision 5 | **diverged** (record against record; no output consequence today) | #301 (per-release correctness manifest) would make the rules TSVs part of a versioned record; the disagreement would be frozen into it |
| **F6.2** | The STATS row against its header | `normalize_data_for_output` :: `push @output_columns, "${key}_nice" if $key =~ /^(duration\|bytes)$/;` (the header walk over `@populated_graph_columns`) | `print_bar_graph` :: `if( $key =~ /^(time\|duration)$/i ) {` (the row walk over the same list in a second if/elsif chain) and `print_bar_graph` :: `push @row, (undef) x ( $target_width - scalar @row ) if scalar @row < $target_width;` (the padding) | Two chains kept in step by comment; the row's `time` arm can never match (`@graph_columns` holds `duration`, `bytes`, `count`), and if it did the row would gain a field the header lacks; a short row is padded to the header width before it is written, so the harness's field-count check cannot see it | Identical today: the captured STATS file has 37 header fields and 37 in every row | One column declaration per STATS column (name, family, gate, value accessor) that the header push, the row push and the aggregate export's walk all read; the padding removed or replaced by a hard failure | `features/432-metric-aggregate-naming-parity.md` D8 (`@output_columns` drives the CSV); `features/column-layout-refactor.md` § Required Separation (the declaration is new, not the layout) | **latent** | #514 (count metric explicit) changes the count arm of both chains |
| **F6.5** | The MESSAGES row against its header | `pipeline_render` :: `$csv->print($csv_fh, [qw(category message occurrences successes failures conflicts bytes_occurrences bytes_min bytes_mean bytes_max bytes bytes_nice count_occurrences count_min count_mean` (41 names) | `print_message_summary` :: `format_csv_value($occurrences,       'occurrences'),` (a positional list of 41 values, 37 of them repeating the column name as the family tag; the per-column locals such as `my $bytes_occurrences = $log_messages{$grouping}{$key}{bytes_occurrences};` are a third spelling) | Two hand-written lists of 41 and a third of tags, none reading `@duration_family_stats` | Identical today: 41 header fields and 41 in every row of the captured MESSAGES file, and every tag matches its header name by position | The same per-column declaration as F6.2, shared by both files where the columns are the same statistic | `features/432-metric-aggregate-naming-parity.md` D3 (CSV headers take the `duration_` prefix) and D5 | **latent** | #273 (store precise, format at the boundary) touches the `duration_nice` slot of this list |
| **F6.3 / F6.4** | The bytes and count families | `normalize_data_for_output` :: `push @output_columns, qw( bytes_occurrences bytes_min bytes_mean bytes_max );` and `push @output_columns, "${key}_occurrences", "${key}_min", "${key}_mean", "${key}_max", "${key}_sum" if !$omit_count;` | `print_bar_graph` :: `foreach my $metric ( qw( occurrences min mean max ) ) {` and `foreach my $metric ( qw( occurrences min mean max sum ) ) {`; `write_aggregate_export` :: `$block->{$_} = aggregate_number($stats->{"bytes_$_"}) for grep { defined $stats->{"bytes_$_"} } qw(occurrences min mean` and its count twin; the user-defined fallback `qw(occurrences min mean max sum)` in the header, the row and the export beside `udm_csv_columns` :: `my @stats = qw(occurrences min mean max sum);` | The bytes family written four times, the count family four times, the user-defined fallback three times plus the one inside the sub that exists to prevent exactly this | Identical today | `@bytes_family_stats` and `@count_family_stats` at file scope beside `@duration_family_stats`, and the user-defined fallback read from `udm_csv_columns` | `features/432-metric-aggregate-naming-parity.md` D5 | **latent** | #514 |
| **F6.6** | The rate columns' spelling | `pipeline_render` :: `if    ($_ eq 'err-rate') { "err-rate$rate_csv_suffix{$rate_unit}" }` (header) | `print_bar_graph` :: `push @csv_data, format_csv_value($output_columns{$category_bucket}, $category_bucket);` (the row formats under the bare name) and `resolve_csv_column_family` :: `return 'level' if $column =~ /^(err\|msg)-rate(_(sec\|min\|hr\|day))?$/;` (both spellings resolve to one family) | The header renames, the row does not; the family resolver accepts both | Identical output: the captured header reads `err-rate_min` and `msg-rate_min` and the cells format the same either way | The renamed name held in `@output_columns` itself, so the header writes what the row formats | none | **identical by construction** | none |
| **F6.7** | The run index's columns | `write_index_file` :: `my @index_columns = qw(` | `read_index_file` :: `my @index_columns = qw(` (identical contents) and the four positional `$index_csv->print` emits | The writer and the reader each declare the list | Identical today (the read-back harness passes) | One file-scope `@index_columns` | `features/432-metric-aggregate-naming-parity.md` D7 | **latent** | none |

Sites audited and closed as **deliberate**:

- The rules TSVs are a copy of the column names by design: the harness checks
  the tool against a specification the tool did not generate
  (`tests/csv-output/README.md`). They are recorded as copies and excluded as a
  target.
- `udm_csv_columns` :: `return { shape => 'family', stats => \@stats, columns => [ map { "${prefix}_$_" } @stats ] };`
  is the one declaration serving five consumers, and the template the other
  columns should follow.
- `stats_csv_duration_columns_active` :: `return ($write_messages_to_csv && !$omit_durations && $durations_observed) ? 1 : 0;`
  and its bytes twin are shared gates, called by the header, the row and the
  export.
- The aggregate export's keys are YAML mapping keys in STATS order by the
  `features/503-yaml-aggregate-export.md` section contract, so its walk is a
  consumer of the same declaration, not a fifth spelling to be removed.

### Open issues touching this item as a whole

- **#514** (count metric capture and display explicit, `next-up`): the count
  family's four literal copies and both if/elsif chains change with it.
- **#273** (store precise, format at the rendering boundary): the MESSAGES
  `duration_nice` slot reads the stored string this issue removes.
- **#301** (per-release correctness manifest): the rules TSVs would enter a
  versioned record; F6.1's disagreement should be settled before it is frozen.

### Site inventory

Carried from the scoping pass (*(scoping)*, its four verifier additions
included) with the audit's additions:

- `(GLOBALS)` :: `my @duration_family_stats = qw( min mean max std_dev p1 p5 p10 p25 p50 p75 iqr p90 p95 p99 p999 p9999 p99999 cv skewness kurtosis bimodality_coef );` :: the one shared declaration; read by the STATS header, STATS row and export, not by the MESSAGES file. *(scoping)*
- `normalize_data_for_output` :: `push @output_columns, "timestamp";` :: STATS header start. *(scoping)*
- `normalize_data_for_output` :: `push @output_columns, "successes", "failures", "conflicts";` *(scoping)*
- `normalize_data_for_output` :: `# Build @populated_graph_columns and @output_columns (still needed for scaling and CSV)` :: the header walk. *(scoping)*
- `normalize_data_for_output` :: `push @output_columns, qw( bytes_occurrences bytes_min bytes_mean bytes_max );` *(scoping)*
- `normalize_data_for_output` :: `push @output_columns, map { "duration_$_" } @duration_family_stats;` *(audit)*
- `stats_csv_duration_columns_active` :: `return ($write_messages_to_csv && !$omit_durations && $durations_observed) ? 1 : 0;` *(scoping)*
- `pipeline_render` :: `if    ($_ eq 'err-rate') { "err-rate$rate_csv_suffix{$rate_unit}" }` :: STATS header write. *(scoping)*
- `print_bar_graph` :: `last if $category_bucket =~ /^occurrences$/;` :: the row reads the header list for the category segment. *(scoping)*
- `print_bar_graph` :: `# 'successes','failures' header pushes in normalize_data_for_output().` *(scoping)*
- `print_bar_graph` :: `# @populated_graph_columns in the SAME order as the @output_columns` :: the row walk. *(scoping)*
- `print_bar_graph` :: `foreach my $metric ( qw( occurrences min mean max ) ) {` *(scoping)*
- `print_bar_graph` :: `foreach my $stat ( @duration_family_stats ) {` *(audit)*
- `print_bar_graph` :: `push @row, (undef) x ( $target_width - scalar @row ) if scalar @row < $target_width;` *(scoping)*
- `pipeline_render` :: `$csv->print($csv_fh, [qw(category message occurrences successes failures conflicts bytes_occurrences bytes_min bytes_mean bytes_max bytes bytes_nice count_occurrences` :: MESSAGES header. *(scoping)*
- `print_message_summary` :: `format_csv_value($occurrences,       'occurrences'),` :: MESSAGES row. *(scoping)*
- `print_message_summary` :: `my $bytes_occurrences = $log_messages{$grouping}{$key}{bytes_occurrences};` :: the per-column locals. *(scoping)*
- `print_message_summary` :: `? format_csv_value($log_messages{$grouping}{$key}{"udm_${name}_occurrences"}, $csv->{columns}[0])` :: the user-defined tail. *(scoping)*
- `udm_csv_columns` :: `return { shape => 'family', stats => \@stats, columns => [ map { "${prefix}_$_" } @stats ] };` *(scoping)*
- `(file scope in SUBS, before resolve_csv_column_family)` :: `my %csv_column_family = (` :: the family table and its mirror comment. *(scoping)*
- `resolve_csv_column_family` :: `return 'count' if $column =~ /_(min|mean|max|sum|occurrences)$/;` :: dynamic families by pattern. *(scoping)*
- `adapt_to_command_line_options` :: `my %decimals_by_unit = ( ns => 9, us => 6, ms => 0, s => 0 );` and the three `%csv_family_decimals` tables that follow it (default, full, integer). *(audit)*
- `write_aggregate_export` :: `# The STATS CSV column families, in the order the row writes them.` :: the export walk. *(scoping)*
- `write_index_file` :: `my @index_columns = qw(` and `read_index_file` :: `next unless @$row >= scalar(@index_columns);` *(scoping)*
- `write_index_file` :: `$index_csv->print($ofh, \@index_columns);` :: the header emit; three positional row emits follow it. *(scoping, snippet corrected)*
- `build_column_layout` :: `my $show_latency = $durations_observed && !$omit_durations && !$hide_stats && !$heatmap_enabled;` and `add_dynamic_column` :: `my ($columns_ref, $id, $name, $color_index, %opts) = @_;` :: the display layout, which carries no CSV field. *(scoping)*
- `adapt_to_command_line_options` :: `do { print_usage( "invalid sort type used" ); exit 1; } unless grep { lc $_ eq lc $sort_type } qw(` and `print_help` :: `$out .= help_opt("-so,  --sort-on <field>",` :: the `-so` copies of the same names (item 1, F1.8). *(scoping)*

### Verification notes

- Every snippet resolves to its enclosing sub. The scoping pass's three refuted
  line hints are irrelevant to the snippet check.
- The scoping pass asked whether the family disagreement changes emitted
  decimals; the answer from the rules rows and the tool's table is no (three
  emitted, five allowed).
- The scoping pass's F6.2 ("if it ever matched, the row would carry one more
  field than the header") is confirmed by reading: the row arm pushes two
  values where the header pushes `_nice` plus the bare name only for
  `duration` and `bytes`; the `time` arm cannot match today.

### Questions for the findings discussion, with the evidence bearing on each

- *Does the family disagreement change emitted decimals?* No; it changes which
  record a maintainer trusts, and the comment that claims a mirror is wrong.
- *Does the STATS row padding stay?* It exists so a short row never breaks a
  reader; the captured file shows no short row today. A hard failure in its
  place would surface a drift the harness cannot otherwise see.
- *Is the `-so` vocabulary a further copy of these lists?* Yes for the
  `bytes_*` and `count_*` names (item 1, F1.8); one declaration per column
  would give `-so` its allow-list as well.


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

