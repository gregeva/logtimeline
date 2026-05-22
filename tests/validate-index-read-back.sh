#!/usr/bin/env bash
# validate-index-read-back.sh — Validate ltl-index.csv read-back behavior (Issue #179).
# Usage: ./tests/validate-index-read-back.sh
#
# Each scenario sets up an isolated cwd, orchestrates ltl-index.csv state
# directly (seeding via ltl runs, then selectively deleting/editing rows
# via Text::CSV), invokes ltl with -V index-read-back, and asserts specific
# labeled lines in the `=== index-read-back ===` section. Format contract
# is in features/179-index-read-back.md.
#
# Departs from validate-regression.sh in assertion style: greps the -V
# section for expected key/value lines rather than diffing full output
# against a reference fixture. The two suites are complementary:
# validate-regression.sh ensures rendered output is byte-identical;
# this suite ensures index read-back lookup, freshness, drift, and
# multi-file aggregation behave per spec.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"

# 5k-line samples of real production logs, sliced from the middle of the
# corresponding logs/<source>/ files. See docs/test-logs.md and
# tests/fixtures/regenerate-index-readback-fixtures.sh for derivation.
ACCESS_LOG="$REPO_DIR/logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05-5k.txt"
SCRIPT_LOG="$REPO_DIR/logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean-5k.log"

# Prebuilt ltl-index.csv covering both ACCESS_LOG and SCRIPT_LOG with file
# rows + unfiltered selection rows + filtered (-dmin=50) selection rows.
# Scenarios copy this into their cwd and manipulate it (delete rows, edit
# bounds, age entries, corrupt the file) to drive specific code paths
# without paying for a full ltl seed run per scenario.
INDEX_FIXTURE="$SCRIPT_DIR/fixtures/ltl-index-readback.csv"

# Common options: suppress progress and limit top messages.
COMMON="--disable-progress -osum -n 1"

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"
    exit 1
fi

# The sample logs and prebuilt index are gitignored derived artifacts. If
# any are missing, run the regenerate script to produce them, then check
# again. If they are still missing the script itself failed (typically
# because the source logs in logs/ are not present locally) — hard-fail
# with a clear diagnostic.
REGENERATE_SCRIPT="$SCRIPT_DIR/fixtures/regenerate-index-readback-fixtures.sh"
if [[ ! -f "$ACCESS_LOG" || ! -f "$SCRIPT_LOG" || ! -f "$INDEX_FIXTURE" ]]; then
    echo "Fixtures missing; running $REGENERATE_SCRIPT to generate them..."
    if ! "$REGENERATE_SCRIPT"; then
        echo "ERROR: $REGENERATE_SCRIPT failed; cannot run this harness" >&2
        exit 1
    fi
fi
if [[ ! -f "$ACCESS_LOG" ]]; then
    echo "ERROR: ACCESS_LOG still not found after regenerate: $ACCESS_LOG" >&2
    exit 1
fi
if [[ ! -f "$SCRIPT_LOG" ]]; then
    echo "ERROR: SCRIPT_LOG still not found after regenerate: $SCRIPT_LOG" >&2
    exit 1
fi
if [[ ! -f "$INDEX_FIXTURE" ]]; then
    echo "ERROR: INDEX_FIXTURE still not found after regenerate: $INDEX_FIXTURE" >&2
    exit 1
fi

pass=0
fail=0
failures=()
current_scenario=""

# ---------------------------------------------------------------------------
# Orchestration helpers (6a)
# ---------------------------------------------------------------------------

# Run ltl in the current cwd, capture combined output to a temp file, echo path.
# Usage: out=$(run_ltl <ltl args...>)
run_ltl() {
    local outfile
    outfile=$(mktemp)
    "$LTL" "$@" > "$outfile" 2>&1 || true
    echo "$outfile"
}

# Convenience: run ltl with -V index-read-back and the COMMON flags,
# return capture path. Issue #226: narrow capture to the section this
# harness actually asserts against.
# Usage: out=$(run_ltl_v <extra args...> "$LOG")
run_ltl_v() {
    run_ltl $COMMON -V index-read-back "$@"
}

# Drop the prebuilt ltl-index.csv fixture into the current cwd. Scenarios
# that need an already-seeded index call this once at the start, then
# manipulate the local copy (delete rows, edit bounds, age entries,
# corrupt) to drive whatever code path they assert against.
seed_from_fixture() {
    cp "$INDEX_FIXTURE" ./ltl-index.csv
}

# Read a column from a row in ltl-index.csv (current cwd) where one or
# more other columns match given values. Used to read calibrated bounds
# from the fixture rather than re-deriving them via a full ltl run.
# Predicate syntax: column=value [AND column=value]...
# Usage: v=$(read_index_column duration_max 'entry_type=selection AND filters=-dmin=50')
read_index_column() {
    local column="$1" predicate="$2"
    [[ -f ltl-index.csv ]] || { echo "ERROR: no ltl-index.csv in cwd" >&2; return 1; }
    perl -MText::CSV -e '
        my ($column, $predicate) = @ARGV;
        my @clauses = split /\s+AND\s+/, $predicate;
        my %want; for my $c (@clauses) { my ($k, $v) = split /=/, $c, 2; $want{$k} = $v; }
        my $csv = Text::CSV->new({binary=>1, eol=>$/});
        open my $fh, "<", "ltl-index.csv" or die;
        my %ci; my $header;
        while (my $r = $csv->getline($fh)) {
            if (!$header) { $header = $r; for my $i (0..$#$r) { $ci{$r->[$i]} = $i } next; }
            my $matches = 1;
            for my $k (keys %want) {
                my $idx = $ci{$k};
                if (!defined $idx || ($r->[$idx] // "") ne $want{$k}) { $matches = 0; last; }
            }
            if ($matches) {
                my $idx = $ci{$column};
                print $r->[$idx] // "" if defined $idx;
                exit 0;
            }
        }
        # No match — print empty; caller checks with [[ -z ]]
    ' "$column" "$predicate"
}

# Extract a key's value from a -V capture file.
# Recognizes both `key: value` (top-level) and `  key: value` (indented).
# Usage: v=$(extract_v_value "$out" 'preseed_duration_max')
extract_v_value() {
    local file="$1" key="$2"
    perl -ne 'if (/^\s*\Q'"$key"'\E:\s*(.*?)\s*$/) { print $1; exit }' "$file"
}

# Selectively delete rows from ltl-index.csv whose CSV columns match the
# predicate. Predicate syntax: column=value [AND column=value]...
# Values are matched as exact strings against the CSV column.
# Usage: delete_index_rows 'entry_type=selection AND filters=-dmin=50;'
delete_index_rows() {
    local predicate="$1"
    [[ -f ltl-index.csv ]] || return 0
    perl -MText::CSV -e '
        my $pred = $ARGV[0];
        my @clauses = split /\s+AND\s+/, $pred;
        my %want;
        for my $c (@clauses) {
            my ($k, $v) = split /=/, $c, 2;
            $want{$k} = $v;
        }
        my $csv = Text::CSV->new({binary=>1, eol=>$/});
        open my $in, "<", "ltl-index.csv" or die;
        my @rows; my @cols; my %ci;
        while (my $r = $csv->getline($in)) {
            if (!@cols) { @cols = @$r; for my $i (0..$#cols) { $ci{$cols[$i]} = $i } push @rows, $r; next; }
            my $matches = 1;
            for my $k (keys %want) {
                my $idx = $ci{$k};
                if (!defined $idx || ($r->[$idx] // "") ne $want{$k}) { $matches = 0; last; }
            }
            push @rows, $r unless $matches;
        }
        close $in;
        open my $out, ">", "ltl-index.csv" or die;
        $csv->print($out, $_) for @rows;
        close $out;
    ' "$predicate"
}

# Edit columns in the first row matching the predicate.
# Usage: edit_index_row 'entry_type=file' 'duration_max=100,duration_min=0'
edit_index_row() {
    local predicate="$1" assigns="$2"
    [[ -f ltl-index.csv ]] || return 1
    perl -MText::CSV -e '
        my ($pred, $assigns) = @ARGV;
        my @clauses = split /\s+AND\s+/, $pred;
        my %want; for my $c (@clauses) { my ($k,$v) = split /=/, $c, 2; $want{$k} = $v; }
        my %set;  for my $a (split /,/, $assigns) { my ($k,$v) = split /=/, $a, 2; $set{$k} = $v; }
        my $csv = Text::CSV->new({binary=>1, eol=>$/});
        open my $in, "<", "ltl-index.csv" or die;
        my @rows; my @cols; my %ci;
        my $applied = 0;
        while (my $r = $csv->getline($in)) {
            if (!@cols) { @cols = @$r; for my $i (0..$#cols) { $ci{$cols[$i]} = $i } push @rows, $r; next; }
            if (!$applied) {
                my $matches = 1;
                for my $k (keys %want) {
                    my $idx = $ci{$k};
                    if (!defined $idx || ($r->[$idx] // "") ne $want{$k}) { $matches = 0; last; }
                }
                if ($matches) {
                    for my $k (keys %set) { my $idx = $ci{$k}; $r->[$idx] = $set{$k} if defined $idx; }
                    $applied = 1;
                }
            }
            push @rows, $r;
        }
        close $in;
        open my $out, ">", "ltl-index.csv" or die;
        $csv->print($out, $_) for @rows;
        close $out;
        exit($applied ? 0 : 1);
    ' "$predicate" "$assigns"
}

# Set entry_date in matching rows to N days ago.
# Usage: set_entry_date 'entry_type=selection AND filters=-dmin=50;' 91
set_entry_date() {
    local predicate="$1" age_days="$2"
    [[ -f ltl-index.csv ]] || return 1
    local past_iso
    past_iso=$(perl -e 'use POSIX qw(strftime); print strftime("%Y-%m-%dT%H:%M:%S", gmtime(time() - $ARGV[0] * 86400))' "$age_days")
    edit_index_row "$predicate" "entry_date=$past_iso"
}

# Damage the index file. mode = truncate | malform.
corrupt_index_file() {
    local mode="$1"
    [[ -f ltl-index.csv ]] || return 1
    case "$mode" in
        truncate)
            # Cut the file in half (mid-row).
            local sz half
            sz=$(wc -c < ltl-index.csv | tr -d ' ')
            half=$((sz / 2))
            head -c "$half" ltl-index.csv > ltl-index.csv.tmp
            mv ltl-index.csv.tmp ltl-index.csv
            ;;
        malform)
            # Append a row with mismatched quoting.
            printf 'this is not,valid,"csv,unterminated\n' >> ltl-index.csv
            ;;
        *)
            echo "corrupt_index_file: unknown mode $mode" >&2
            return 1
            ;;
    esac
}

# Self-documenting assertion: a line matching `pattern` must be present.
# Required named fields: pattern, asserts, produced_by, contract.
# On failure, all four are surfaced alongside the captured output path.
# See tests/HARNESS-DESIGN.md § Self-documenting assertions.
# Reads $current_scenario for the scenario label.
assert_line() {
    local outfile="$1"
    shift
    local pattern asserts produced_by contract
    while [[ $# -gt 0 ]]; do
        case "$1" in
            pattern)     pattern="$2";     shift 2 ;;
            asserts)     asserts="$2";     shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2";    shift 2 ;;
            *) echo "assert_line: unknown field '$1'"; exit 2 ;;
        esac
    done
    : "${pattern:?assert_line requires pattern}"
    : "${asserts:?assert_line requires asserts}"
    : "${produced_by:?assert_line requires produced_by}"
    : "${contract:?assert_line requires contract}"

    if grep -qE "$pattern" "$outfile"; then
        echo "  PASS  $current_scenario :: $pattern"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario"
        echo "        pattern:     $pattern"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        echo "        (not found in $outfile)"
        fail=$((fail + 1))
        failures+=("$current_scenario :: $pattern")
    fi
}

# Self-documenting assertion: no line matching `pattern` may be present.
# Same field requirements as assert_line.
assert_no_line() {
    local outfile="$1"
    shift
    local pattern asserts produced_by contract
    while [[ $# -gt 0 ]]; do
        case "$1" in
            pattern)     pattern="$2";     shift 2 ;;
            asserts)     asserts="$2";     shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2";    shift 2 ;;
            *) echo "assert_no_line: unknown field '$1'"; exit 2 ;;
        esac
    done
    : "${pattern:?assert_no_line requires pattern}"
    : "${asserts:?assert_no_line requires asserts}"
    : "${produced_by:?assert_no_line requires produced_by}"
    : "${contract:?assert_no_line requires contract}"

    if grep -qE "$pattern" "$outfile"; then
        echo "  FAIL  $current_scenario"
        echo "        pattern:     !$pattern (unexpectedly present)"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        fail=$((fail + 1))
        failures+=("$current_scenario :: !$pattern (unexpectedly present)")
    else
        echo "  PASS  $current_scenario :: !$pattern"
        pass=$((pass + 1))
    fi
}

# Self-documenting command-based assertion: run `command` (eval'd) and
# PASS if it exits 0. Used when the assertion is not a simple grep
# against a single file (e.g., compound greps, Perl validation, count
# comparisons). Required named fields: command, label, asserts,
# produced_by, contract. `label` is a short human-readable summary of
# what the command is checking (used in PASS lines, where the command
# itself would be too verbose).
# Reads $current_scenario for the scenario label.
assert_command() {
    local command label asserts produced_by contract
    while [[ $# -gt 0 ]]; do
        case "$1" in
            command)     command="$2";     shift 2 ;;
            label)       label="$2";       shift 2 ;;
            asserts)     asserts="$2";     shift 2 ;;
            produced_by) produced_by="$2"; shift 2 ;;
            contract)    contract="$2";    shift 2 ;;
            *) echo "assert_command: unknown field '$1'"; exit 2 ;;
        esac
    done
    : "${command:?assert_command requires command}"
    : "${label:?assert_command requires label}"
    : "${asserts:?assert_command requires asserts}"
    : "${produced_by:?assert_command requires produced_by}"
    : "${contract:?assert_command requires contract}"

    if eval "$command"; then
        echo "  PASS  $current_scenario :: $label"
        pass=$((pass + 1))
    else
        echo "  FAIL  $current_scenario"
        echo "        label:       $label"
        echo "        command:     $command"
        echo "        asserts:     $asserts"
        echo "        produced_by: $produced_by"
        echo "        contract:    $contract"
        fail=$((fail + 1))
        failures+=("$current_scenario :: $label")
    fi
}

# Run a scenario in an isolated cwd. Does NOT subshell — pass/fail counters
# are global and must be visible to the runner. We cd into the dir, run
# the scenario, cd back, and clean up.
# Usage: in_scenario_dir <scenario-fn>
in_scenario_dir() {
    local fn="$1"
    local prev_dir
    prev_dir="$PWD"
    local dir
    dir=$(mktemp -d)
    cd "$dir"
    "$fn"
    cd "$prev_dir"
    rm -rf "$dir"
}

# ---------------------------------------------------------------------------
# Self-tests for the orchestration helpers themselves
# ---------------------------------------------------------------------------

helper_self_test() {
    current_scenario="helpers"
    echo "[$current_scenario]"

    seed_from_fixture
    assert_command \
        command     '[[ -f ltl-index.csv ]]' \
        label       'seed_from_fixture produces ltl-index.csv' \
        asserts     'The seed_from_fixture helper drops the prebuilt fixture into the scenario cwd so subsequent assertions have a known starting state' \
        produced_by 'seed_from_fixture() in tests/validate-index-read-back.sh (copies $INDEX_FIXTURE to ./ltl-index.csv)' \
        contract    'features/179-index-read-back.md § Validation — Index orchestration; tests/HARNESS-DESIGN.md § Orchestration helpers'

    assert_command \
        command     '[[ "$(grep -c "^file," ltl-index.csv || true)" -ge 1 && "$(grep -c "^selection," ltl-index.csv || true)" -ge 1 ]]' \
        label       'fixture seeds at least one file row and one selection row' \
        asserts     'The prebuilt fixture must carry both row kinds (file rows and selection rows) so scenarios exercising either tier have something to match against' \
        produced_by 'tests/fixtures/regenerate-index-readback-fixtures.sh (produces tests/fixtures/ltl-index-readback.csv)' \
        contract    'features/179-index-read-back.md § Validation — Test scenarios; fixture invariant'

    # Test delete_index_rows: remove all selection rows.
    delete_index_rows "entry_type=selection"
    assert_command \
        command     '[[ "$(grep -c "^selection," ltl-index.csv || true)" -eq 0 ]]' \
        label       'delete_index_rows removes matching rows' \
        asserts     'The delete_index_rows orchestration helper removes every row whose predicate columns match, so scenarios can force Tier 2 fallback by deleting the relevant selection rows' \
        produced_by 'delete_index_rows() in tests/validate-index-read-back.sh (Text::CSV-based row filter)' \
        contract    'features/179-index-read-back.md § Validation — Index orchestration supported operations'

    # Test edit_index_row: change duration_max in the file row.
    edit_index_row "entry_type=file" "duration_max=999999"
    assert_command \
        command     'grep -q ",999999," ltl-index.csv' \
        label       'edit_index_row applies new value' \
        asserts     'The edit_index_row orchestration helper writes the new column value to the first matching row, so scenarios can corrupt bounds (narrow duration_max, blank a column) without touching unrelated rows' \
        produced_by 'edit_index_row() in tests/validate-index-read-back.sh (Text::CSV-based first-match rewrite)' \
        contract    'features/179-index-read-back.md § Validation — Index orchestration supported operations'

    # Test corrupt_index_file: truncate to half-size.
    local size_before size_after
    size_before=$(wc -c < ltl-index.csv | tr -d ' ')
    corrupt_index_file truncate
    size_after=$(wc -c < ltl-index.csv | tr -d ' ')
    assert_command \
        command     "[[ $size_after -lt $size_before ]]" \
        label       "corrupt_index_file truncate shrinks file ($size_before -> $size_after bytes)" \
        asserts     'The corrupt_index_file helper (mode=truncate) cuts the index file mid-row so scenarios can drive the malformed-index code path' \
        produced_by 'corrupt_index_file() in tests/validate-index-read-back.sh (head -c $((sz/2)))' \
        contract    'features/179-index-read-back.md § Validation — Index orchestration supported operations'
}

# ---------------------------------------------------------------------------
# Scenarios (6b)
# ---------------------------------------------------------------------------

scenario_cold_no_index() {
    current_scenario="cold-no-index"
    echo "[$current_scenario]"

    local out
    out=$(run_ltl_v "$ACCESS_LOG")

    assert_line "$out" \
        pattern     '^index_used: no$' \
        asserts     'With no ltl-index.csv in cwd at run start, the run-level header reports index_used=no — the read-back path has nothing to consult on a cold run' \
        produced_by 'emit_index_readback_verbose() in ltl (run-level header block)' \
        contract    'features/179-index-read-back.md § "-V verbose output" Layer 1 — Run-level summary; locked index_used field'

    assert_command \
        command     '[[ -f ltl-index.csv ]] && grep -q "^file," ltl-index.csv && grep -q "^selection," ltl-index.csv' \
        label       'cold run writes index with file and selection rows' \
        asserts     'A cold run must still write a fresh ltl-index.csv at end-of-run carrying at least one file row and one selection row so the next run has a warm index to read back' \
        produced_by 'write_index_file() in ltl (end-of-run #46 write side)' \
        contract    'features/179-index-read-back.md § Interactions with existing features § "With write side (#46)"'
}

scenario_warm_unfiltered() {
    current_scenario="warm-unfiltered"
    echo "[$current_scenario]"

    seed_from_fixture
    local out
    out=$(run_ltl_v "$ACCESS_LOG")

    assert_line "$out" \
        pattern     '^index_used: yes$' \
        asserts     'When the index file exists and has a usable row, the run-level header reports index_used=yes' \
        produced_by 'emit_index_readback_verbose() in ltl (run-level header block)' \
        contract    'features/179-index-read-back.md § "-V verbose output" Layer 1 — Run-level summary'

    # The unfiltered run matches a selection entry with filters=- (Tier 1)
    # — see spec §6.4: that selection entry and the file entry describe
    # the same population and would always agree.
    assert_line "$out" \
        pattern     '^  lookup: tier_1_selection$' \
        asserts     'An unfiltered run matches the seeded unfiltered selection row (filters=-) and the per-file lookup reports tier_1_selection — the read-back path consults the selection row directly without falling back to the file row' \
        produced_by 'emit_index_readback_verbose() in ltl (per-file lookup block)' \
        contract    'features/179-index-read-back.md § "-V verbose output" Layer 2 — Per-file lookup result; § Behavior — Pre-seeded values (Tier 1 selection row)'

    assert_line "$out" \
        pattern     '^  freshness: fresh$' \
        asserts     'When the live file mtime and size match the values stored in the matched index row, the per-file freshness check reports fresh' \
        produced_by 'emit_index_readback_verbose() in ltl (per-file lookup block, freshness sub-field)' \
        contract    'features/179-index-read-back.md § Behavior — Freshness check; § "-V verbose output" Layer 2'

    assert_line "$out" \
        pattern     '^drift_detected: no$' \
        asserts     'When the live calibrated bounds match the pre-seeded bounds, the run-level drift_detected field reports no' \
        produced_by 'detect_index_drift() in ltl + emit_index_readback_verbose() (run-level drift field)' \
        contract    'features/179-index-read-back.md § Behavior — Drift detection; § "-V verbose output" Layer 4 — Drift detection result'
}

scenario_cold_filtered_tier2_fallback() {
    current_scenario="cold-filtered-tier2-fallback"
    echo "[$current_scenario]"

    # Filtered run with -dmin=50 should fall back to Tier 2 (file row)
    # when no matching selection row exists. Remove the prebuilt
    # -dmin=50 row so the scenario actually exercises the fallback.
    seed_from_fixture
    delete_index_rows "entry_type=selection AND filters=-dmin=50"
    local out
    out=$(run_ltl_v -dmin 50 "$ACCESS_LOG")

    assert_line "$out" \
        pattern     '^index_used: yes$' \
        asserts     'A filtered run with a missing selection row still reports index_used=yes because the file row is usable for pre-seeding even when no exact-filter selection row matches' \
        produced_by 'emit_index_readback_verbose() in ltl (run-level header block)' \
        contract    'features/179-index-read-back.md § "-V verbose output" Layer 1; § Behavior — Pre-seeded values (Tier 2 fallback)'

    assert_line "$out" \
        pattern     '^  lookup: tier_2_file$' \
        asserts     'When no selection row matches the requested filter signature, the per-file lookup falls back to the file row and reports tier_2_file' \
        produced_by 'emit_index_readback_verbose() in ltl (per-file lookup block)' \
        contract    'features/179-index-read-back.md § Behavior — Pre-seeded values § Tier 2 file-row fallback; § "-V verbose output" Layer 2'

    assert_line "$out" \
        pattern     '^index_filter_signature: -dmin=50$' \
        asserts     'The run-level index_filter_signature echoes the active CLI filters in canonical form so the reader can confirm which signature was used to probe the index' \
        produced_by 'emit_index_readback_verbose() in ltl (run-level header block)' \
        contract    'features/179-index-read-back.md § "-V verbose output" Layer 1 — Run-level summary; locked field'

    assert_command \
        command     'grep -q "^selection,.*,-dmin=50$" ltl-index.csv' \
        label       'selection row written for -dmin=50' \
        asserts     'After a Tier 2 fallback run, the end-of-run write appends a fresh selection row for the requested filter signature so the next run with the same filters hits Tier 1' \
        produced_by 'write_index_file() in ltl (end-of-run #46 write side; appends new selection row)' \
        contract    'features/179-index-read-back.md § Interactions with existing features § "With write side (#46)"'
}

scenario_warm_tier1_filtered() {
    current_scenario="warm-tier1-filtered"
    echo "[$current_scenario]"

    # Fixture already has a selection row for -dmin=50, so this run
    # hits Tier 1 directly.
    seed_from_fixture
    local out
    out=$(run_ltl_v -dmin 50 "$ACCESS_LOG")

    assert_line "$out" \
        pattern     '^index_used: yes$' \
        asserts     'A warm filtered run with a matching selection row reports index_used=yes' \
        produced_by 'emit_index_readback_verbose() in ltl (run-level header block)' \
        contract    'features/179-index-read-back.md § "-V verbose output" Layer 1'

    assert_line "$out" \
        pattern     '^  lookup: tier_1_selection$' \
        asserts     'When the index has a fresh selection row matching the active filter signature, the per-file lookup hits Tier 1 directly without consulting the file row' \
        produced_by 'emit_index_readback_verbose() in ltl (per-file lookup block)' \
        contract    'features/179-index-read-back.md § Behavior — Pre-seeded values § Tier 1 selection row; § "-V verbose output" Layer 2'

    assert_line "$out" \
        pattern     '^index_filter_signature: -dmin=50$' \
        asserts     'The run-level index_filter_signature echoes the active CLI filters in canonical form even when Tier 1 matches' \
        produced_by 'emit_index_readback_verbose() in ltl (run-level header block)' \
        contract    'features/179-index-read-back.md § "-V verbose output" Layer 1 — Run-level summary'

    assert_line "$out" \
        pattern     '^drift_detected: no$' \
        asserts     'When the live calibrated bounds match the Tier 1 selection row bounds, drift_detected reports no' \
        produced_by 'detect_index_drift() in ltl + emit_index_readback_verbose() (run-level drift field)' \
        contract    'features/179-index-read-back.md § Behavior — Drift detection; § "-V verbose output" Layer 4'
}

scenario_warm_tier2_different_filters() {
    current_scenario="warm-tier2-different-filters"
    echo "[$current_scenario]"

    # Fixture has -dmin=50; this run uses -dmin=100 (different filter set).
    # Tier 1 miss → Tier 2 fallback → new selection row appended on write.
    seed_from_fixture
    local out
    out=$(run_ltl_v -dmin 100 "$ACCESS_LOG")

    assert_line "$out" \
        pattern     '^  lookup: tier_2_file$' \
        asserts     'When the active filter signature does not match any seeded selection row (fixture has -dmin=50 but run uses -dmin=100), the per-file lookup falls back to Tier 2 (file row)' \
        produced_by 'emit_index_readback_verbose() in ltl (per-file lookup block)' \
        contract    'features/179-index-read-back.md § Behavior — Pre-seeded values § Tier 2 fallback'

    assert_line "$out" \
        pattern     '^index_filter_signature: -dmin=100$' \
        asserts     'The run-level index_filter_signature reflects the active CLI filters (-dmin=100) regardless of which seeded rows the index already carries' \
        produced_by 'emit_index_readback_verbose() in ltl (run-level header block)' \
        contract    'features/179-index-read-back.md § "-V verbose output" Layer 1'

    assert_command \
        command     'grep -q "^selection,.*,-dmin=50$" ltl-index.csv && grep -q "^selection,.*,-dmin=100$" ltl-index.csv' \
        label       'both -dmin=50 and -dmin=100 selection rows preserved after write' \
        asserts     'After the run, the end-of-run write must preserve the pre-existing -dmin=50 selection row AND append a new -dmin=100 selection row — the write side never discards selection rows for filter signatures it did not see this run' \
        produced_by 'write_index_file() in ltl (end-of-run #46 write side; merge-with-existing semantics)' \
        contract    'features/179-index-read-back.md § Interactions with existing features § "With write side (#46)" — selection rows accumulate per filter signature'
}

scenario_stale_mtime() {
    current_scenario="stale-mtime"
    echo "[$current_scenario]"

    # Need a local copy of the log we can touch without mutating the shared
    # logs/ file. Seed against that local copy so the index records its
    # specific path/mtime/size — then advance mtime to provoke staleness.
    # (Fixture cannot be reused here because it references a different path.)
    local local_log="./access.log"
    cp "$ACCESS_LOG" "$local_log"
    run_ltl $COMMON -V index-read-back "$local_log" > /dev/null
    sleep 1
    touch "$local_log"   # advance mtime past stored value
    local out
    out=$(run_ltl_v "$local_log")

    assert_line "$out" \
        pattern     '^index_used: no$' \
        asserts     'When the live file mtime no longer matches the value stored in the index row, the freshness check fails and the run-level header reports index_used=no — stale rows must not pre-seed' \
        produced_by 'emit_index_readback_verbose() in ltl (run-level header block; gated on freshness check)' \
        contract    'features/179-index-read-back.md § Behavior — Freshness check; § "-V verbose output" Layer 1'

    assert_line "$out" \
        pattern     '^  freshness: stale_mtime$' \
        asserts     'Per-file freshness reports the specific reason stale_mtime (not just "stale") so the reader can distinguish mtime drift from size drift' \
        produced_by 'emit_index_readback_verbose() in ltl (per-file lookup block, freshness sub-field; staleness reason)' \
        contract    'features/179-index-read-back.md § Behavior — Freshness check; § "-V verbose output" Layer 2 — locked staleness reason codes'
}

scenario_stale_size() {
    current_scenario="stale-size"
    echo "[$current_scenario]"

    # Same setup as stale_mtime — need a local copy referenced by the
    # index — but instead of touching the file, we corrupt the index's
    # stored file_size to a wrong value to provoke staleness.
    local local_log="./access.log"
    cp "$ACCESS_LOG" "$local_log"
    run_ltl $COMMON -V index-read-back "$local_log" > /dev/null
    edit_index_row "entry_type=file" "file_size=42"
    local out
    out=$(run_ltl_v "$local_log")

    assert_line "$out" \
        pattern     '^index_used: no$' \
        asserts     'When the live file size no longer matches the value stored in the index row, the freshness check fails and the run-level header reports index_used=no' \
        produced_by 'emit_index_readback_verbose() in ltl (run-level header block; gated on freshness check)' \
        contract    'features/179-index-read-back.md § Behavior — Freshness check'

    assert_line "$out" \
        pattern     '^  freshness: stale_size$' \
        asserts     'Per-file freshness reports the specific reason stale_size when size drift is the cause (distinct from stale_mtime) so the reader can identify whether truncation/append vs touch caused the staleness' \
        produced_by 'emit_index_readback_verbose() in ltl (per-file lookup block, freshness sub-field; staleness reason)' \
        contract    'features/179-index-read-back.md § Behavior — Freshness check; § "-V verbose output" Layer 2 — locked staleness reason codes'
}

scenario_drift_refresh_tier1() {
    current_scenario="drift-refresh-tier1"
    echo "[$current_scenario]"

    # Fixture has selection rows for -dmin=50 with real calibrated bounds.
    # Read the calibrated duration_max, narrow it deliberately, run, assert
    # drift detection — then re-run and assert drift cleared by the write.
    seed_from_fixture
    local cal_max
    cal_max=$(read_index_column duration_max \
        "entry_type=selection AND file_path=$ACCESS_LOG AND filters=-dmin=50")
    if [[ -z "$cal_max" || "$cal_max" == "-" ]]; then
        echo "  FAIL  $current_scenario :: fixture missing calibrated duration_max for $ACCESS_LOG -dmin=50"
        fail=$((fail + 1))
        return
    fi
    local narrowed=$((cal_max / 2))
    edit_index_row "entry_type=selection AND filters=-dmin=50" "duration_max=$narrowed"
    local out
    out=$(run_ltl_v -dmin 50 "$ACCESS_LOG")

    assert_line "$out" \
        pattern     '^index_used: yes$' \
        asserts     'A Tier 1 run with a matching selection row still reports index_used=yes even when the seeded bounds have drifted from live — drift detection does not invalidate the pre-seed' \
        produced_by 'emit_index_readback_verbose() in ltl (run-level header block)' \
        contract    'features/179-index-read-back.md § "-V verbose output" Layer 1; § Behavior — Drift detection does not gate index_used'

    assert_line "$out" \
        pattern     '^  lookup: tier_1_selection$' \
        asserts     'When the index has a fresh selection row matching the active filter signature, the per-file lookup reports tier_1_selection regardless of whether the seeded bounds have drifted' \
        produced_by 'emit_index_readback_verbose() in ltl (per-file lookup block)' \
        contract    'features/179-index-read-back.md § Behavior — Pre-seeded values § Tier 1 selection row'

    assert_line "$out" \
        pattern     '^drift_detected: yes$' \
        asserts     'When live calibrated bounds differ from the pre-seeded bounds in the matched index row, the run-level drift_detected field reports yes' \
        produced_by 'detect_index_drift() in ltl + emit_index_readback_verbose() (run-level drift field)' \
        contract    'features/179-index-read-back.md § Behavior — Drift detection; § "-V verbose output" Layer 4 — Drift detection result'

    assert_line "$out" \
        pattern     "^  duration_max: live=$cal_max preseed=$narrowed drifted=yes$" \
        asserts     'The per-bound drift detail reports the live calibrated value, the preseeded value from the index row, and a drifted=yes flag — the reader can see exactly which bound moved and by how much' \
        produced_by 'emit_index_readback_verbose() in ltl (drift detail block, per-bound line)' \
        contract    'features/179-index-read-back.md § "-V verbose output" Layer 4 — Drift detection result; locked per-bound line format'

    # Re-run: the previous write refreshed the selection row, drift should be gone.
    current_scenario="drift-refresh-tier1-recovery"
    local out2
    out2=$(run_ltl_v -dmin 50 "$ACCESS_LOG")

    assert_line "$out2" \
        pattern     '^drift_detected: no$' \
        asserts     'After a drift-detecting run, the end-of-run write refreshes the selection row with the live calibrated bounds, so the very next run sees matching values and reports drift_detected=no — drift is self-healing' \
        produced_by 'write_index_file() in ltl (end-of-run #46 write refreshes selection row bounds) + detect_index_drift() (next run)' \
        contract    'features/179-index-read-back.md § Behavior — Drift detection § "Drift is self-healing"; § Interactions with existing features § "With write side (#46)"'
}

scenario_drift_refresh_tier2() {
    current_scenario="drift-refresh-tier2"
    echo "[$current_scenario]"

    # Read calibrated duration_max from the fixture's file row, then force
    # an unfiltered Tier 2 path by deleting the unfiltered selection rows,
    # and narrow the file row's bound to provoke drift detection.
    seed_from_fixture
    local cal_max
    cal_max=$(read_index_column duration_max \
        "entry_type=file AND file_path=$ACCESS_LOG")
    if [[ -z "$cal_max" || "$cal_max" == "-" ]]; then
        echo "  FAIL  $current_scenario :: fixture missing calibrated duration_max for $ACCESS_LOG"
        fail=$((fail + 1))
        return
    fi
    delete_index_rows "entry_type=selection AND filters=-"
    local narrowed=$((cal_max / 2))
    edit_index_row "entry_type=file" "duration_max=$narrowed"
    local out
    out=$(run_ltl_v "$ACCESS_LOG")

    assert_line "$out" \
        pattern     '^  lookup: tier_2_file$' \
        asserts     'When no selection row matches the active (unfiltered) filter signature, the per-file lookup falls back to the file row and reports tier_2_file — drift detection applies to whichever tier was matched' \
        produced_by 'emit_index_readback_verbose() in ltl (per-file lookup block)' \
        contract    'features/179-index-read-back.md § Behavior — Pre-seeded values § Tier 2 fallback'

    assert_line "$out" \
        pattern     '^drift_detected: yes$' \
        asserts     'Drift detection applies to Tier 2 (file row) lookups as well as Tier 1 — when live calibrated bounds differ from the file rows preseeded bounds, drift_detected reports yes' \
        produced_by 'detect_index_drift() in ltl + emit_index_readback_verbose() (run-level drift field)' \
        contract    'features/179-index-read-back.md § Behavior — Drift detection (tier-agnostic)'

    assert_line "$out" \
        pattern     "^  duration_max: live=$cal_max preseed=$narrowed drifted=yes$" \
        asserts     'The per-bound drift detail format (live=X preseed=Y drifted=yes) is identical for Tier 1 and Tier 2 — the reader sees the same diagnostic regardless of which row was matched' \
        produced_by 'emit_index_readback_verbose() in ltl (drift detail block, per-bound line; tier-agnostic format)' \
        contract    'features/179-index-read-back.md § "-V verbose output" Layer 4 — locked per-bound line format'
}

scenario_multi_file_all_fresh_tier2_unfiltered() {
    current_scenario="multi-file-all-fresh-tier2-unfiltered"
    echo "[$current_scenario]"

    # Force Tier 2 for both files by removing all selection rows from the
    # fixture. Both files remain fresh (file rows untouched).
    seed_from_fixture
    delete_index_rows "entry_type=selection"
    local out
    out=$(run_ltl_v "$ACCESS_LOG" "$SCRIPT_LOG")

    assert_line "$out" \
        pattern     '^index_used: yes$' \
        asserts     'A multi-file run where every file matches some index row (Tier 2 fallback for all) reports index_used=yes at the run level' \
        produced_by 'emit_index_readback_verbose() in ltl (run-level header block)' \
        contract    'features/179-index-read-back.md § "-V verbose output" Layer 1; § Behavior — Multi-file aggregation'

    assert_command \
        command     "[[ \"\$(grep -c '^  lookup: tier_2_file\$' \"$out\" || true)\" -eq 2 ]]" \
        label       'both files report tier_2_file' \
        asserts     'In a multi-file run, each file produces its own per-file lookup block — when all files fall back to Tier 2, the output contains exactly one tier_2_file line per file' \
        produced_by 'emit_index_readback_verbose() in ltl (per-file lookup block emitted once per input file)' \
        contract    'features/179-index-read-back.md § "-V verbose output" Layer 2 — Per-file lookup result; § Behavior — Multi-file aggregation'

    assert_line "$out" \
        pattern     '^aggregated_preseed:$' \
        asserts     'When all files are usable for pre-seeding, the run emits an aggregated_preseed block summarizing the merged bounds used for the run — this header is the locked anchor for the aggregation section' \
        produced_by 'emit_index_readback_verbose() in ltl (aggregated_preseed block, multi-file path)' \
        contract    'features/179-index-read-back.md § "-V verbose output" Layer 3 — Aggregated pre-seed values'

    assert_line "$out" \
        pattern     '^  duration_max: .* \(from .*\)$' \
        asserts     'Each aggregated bound line carries (from <path>) provenance so the reader can see which input file contributed the winning value to the merged pre-seed' \
        produced_by 'emit_index_readback_verbose() in ltl (aggregated_preseed block, per-bound line with provenance suffix)' \
        contract    'features/179-index-read-back.md § "-V verbose output" Layer 3 — Aggregated pre-seed values; locked (from <path>) provenance suffix'
}

scenario_multi_file_all_fresh_tier1() {
    current_scenario="multi-file-all-fresh-tier1"
    echo "[$current_scenario]"

    # Fixture already has -dmin=50 selection rows for both files.
    seed_from_fixture
    local out
    out=$(run_ltl_v -dmin 50 "$ACCESS_LOG" "$SCRIPT_LOG")

    assert_line "$out" \
        pattern     '^index_used: yes$' \
        asserts     'A multi-file run where every file has a matching selection row (Tier 1 for all) reports index_used=yes at the run level' \
        produced_by 'emit_index_readback_verbose() in ltl (run-level header block)' \
        contract    'features/179-index-read-back.md § "-V verbose output" Layer 1'

    assert_command \
        command     "[[ \"\$(grep -c '^  lookup: tier_1_selection\$' \"$out\" || true)\" -eq 2 ]]" \
        label       'both files report tier_1_selection' \
        asserts     'In a multi-file run with matching selection rows for both files, each per-file lookup block independently reports tier_1_selection — multi-file aggregation does not collapse or share per-file lookup results' \
        produced_by 'emit_index_readback_verbose() in ltl (per-file lookup block emitted once per input file)' \
        contract    'features/179-index-read-back.md § "-V verbose output" Layer 2 — Per-file lookup result; § Behavior — Multi-file aggregation'
}

scenario_multi_file_mixed_tiers() {
    current_scenario="multi-file-mixed-tiers"
    echo "[$current_scenario]"

    # Fixture has -dmin=50 for both files. Delete SCRIPT_LOG's row so it
    # falls back to Tier 2 while ACCESS_LOG stays at Tier 1.
    seed_from_fixture
    delete_index_rows "entry_type=selection AND file_path=$SCRIPT_LOG AND filters=-dmin=50"
    local out
    out=$(run_ltl_v -dmin 50 "$ACCESS_LOG" "$SCRIPT_LOG")

    assert_line "$out" \
        pattern     '^index_used: no$' \
        asserts     'When the input files match at different tiers, the run reports index_used=no — multi-file aggregation requires uniform tier matches across all files to be usable for pre-seeding' \
        produced_by 'emit_index_readback_verbose() in ltl (run-level header block; multi-file mixed-tier branch)' \
        contract    'features/179-index-read-back.md § Behavior — Multi-file aggregation § "Mixed-tier runs disable pre-seeding"'

    assert_line "$out" \
        pattern     '^  lookup: tier_1_selection$' \
        asserts     'Even when the run as a whole rejects pre-seeding due to mixed tiers, each per-file lookup block still reports its individual would-have-been tier so the reader can diagnose the mismatch — here ACCESS_LOG retains its Tier 1 selection match' \
        produced_by 'emit_index_readback_verbose() in ltl (per-file lookup block; reports individual tier independent of aggregate decision)' \
        contract    'features/179-index-read-back.md § "-V verbose output" Layer 2 — per-file lookup reports individual tier'

    assert_line "$out" \
        pattern     '^  lookup: tier_2_file$' \
        asserts     'In the mixed-tier multi-file scenario, the file whose selection row was deleted (SCRIPT_LOG) reports tier_2_file in its per-file lookup block — the diagnostic surfaces exactly which file dragged the run into mixed-tier territory' \
        produced_by 'emit_index_readback_verbose() in ltl (per-file lookup block)' \
        contract    'features/179-index-read-back.md § "-V verbose output" Layer 2 — per-file lookup reports individual tier'

    assert_no_line "$out" \
        pattern     '^aggregated_preseed:$' \
        asserts     'When the run is mixed-tier (index_used=no), the aggregated_preseed block is suppressed — there is no merged pre-seed to report so the section is omitted entirely rather than emitted with empty values' \
        produced_by 'emit_index_readback_verbose() in ltl (aggregated_preseed block gated on index_used=yes)' \
        contract    'features/179-index-read-back.md § "-V verbose output" Layer 3 — Aggregated pre-seed values § "Suppressed when index_used=no"'
}

scenario_multi_file_one_stale() {
    current_scenario="multi-file-one-stale"
    echo "[$current_scenario]"

    # As with stale_mtime: local copies needed so we can touch without
    # mutating shared logs. The index records the local paths.
    local f1="./access.log"
    local f2="./script.log"
    cp "$ACCESS_LOG" "$f1"
    cp "$SCRIPT_LOG" "$f2"
    run_ltl $COMMON -V index-read-back "$f1" "$f2" > /dev/null
    sleep 1
    touch "$f1"   # advance only $f1's mtime
    local out
    out=$(run_ltl_v "$f1" "$f2")

    assert_line "$out" \
        pattern     '^index_used: no$' \
        asserts     'When any file in a multi-file run is stale, the entire run reports index_used=no — multi-file aggregation requires every file to be fresh; one stale file disables pre-seeding for the run' \
        produced_by 'emit_index_readback_verbose() in ltl (run-level header block; multi-file freshness aggregation)' \
        contract    'features/179-index-read-back.md § Behavior — Multi-file aggregation § "Any stale file disables pre-seeding"'

    assert_line "$out" \
        pattern     '^  freshness: stale_mtime$' \
        asserts     'In a multi-file run with one stale file, the per-file lookup block for the stale file reports its specific freshness reason (stale_mtime) so the reader can identify which file caused the run to reject pre-seeding' \
        produced_by 'emit_index_readback_verbose() in ltl (per-file lookup block, freshness sub-field)' \
        contract    'features/179-index-read-back.md § "-V verbose output" Layer 2 — locked staleness reason codes'

    assert_line "$out" \
        pattern     '^  freshness: fresh$' \
        asserts     'The non-stale file in a mixed-freshness multi-file run still reports freshness=fresh in its per-file lookup block — per-file freshness is reported independently regardless of the aggregate decision' \
        produced_by 'emit_index_readback_verbose() in ltl (per-file lookup block, freshness sub-field)' \
        contract    'features/179-index-read-back.md § "-V verbose output" Layer 2 — per-file freshness reported independently'
}

scenario_malformed_index() {
    current_scenario="malformed-index"
    echo "[$current_scenario]"

    seed_from_fixture
    # Use 'malform' (mismatched quotes appended) rather than 'truncate'.
    # Truncate leaves a row with a partial path that the existing #46
    # write side preserves verbatim on rewrite, yielding 2 file rows
    # instead of self-healing. Mismatched quotes trip CSV parse cleanly,
    # exercising the spec's malformed-index acceptance criterion.
    corrupt_index_file malform
    local out
    out=$(run_ltl_v "$ACCESS_LOG")

    assert_line "$out" \
        pattern     '^index_used: no$' \
        asserts     'When the index file cannot be parsed as valid CSV (mismatched quotes), the read-back path treats it as unusable and the run reports index_used=no — a malformed index must not silently pre-seed with garbage values' \
        produced_by 'emit_index_readback_verbose() in ltl (run-level header block; CSV-parse-failure branch)' \
        contract    'features/179-index-read-back.md § Behavior — Malformed index handling; § Acceptance criteria'

    assert_command \
        command     'perl -MText::CSV -e '"'"'
            my $csv = Text::CSV->new({binary=>1, eol=>$/});
            open my $f, "<", "ltl-index.csv" or exit 1;
            while (my $r = $csv->getline($f)) {}
            my $err = $csv->error_diag;
            exit (($err && (split / /, $err)[0] ne "EOF") ? 1 : 0);
        '"'" \
        label       'end-of-run write rewrites malformed index as valid CSV' \
        asserts     'After a run started against a malformed index, the end-of-run write side overwrites the file with valid CSV — the index file is self-healing on the next run rather than requiring manual cleanup' \
        produced_by 'write_index_file() in ltl (end-of-run #46 write side; full rewrite from in-memory state)' \
        contract    'features/179-index-read-back.md § Behavior — Malformed index handling § "Self-healing on write"; § Interactions with existing features § "With write side (#46)"'
}

scenario_missing_bound_column() {
    current_scenario="missing-bound-column"
    echo "[$current_scenario]"

    seed_from_fixture
    edit_index_row "entry_type=file" "duration_max=-"
    delete_index_rows "entry_type=selection"   # force Tier 2
    local out
    out=$(run_ltl_v "$ACCESS_LOG")

    assert_line "$out" \
        pattern     '^index_used: yes$' \
        asserts     'An index row with one bound column blanked out (set to literal "-") is still usable for pre-seeding — index_used reports yes because the rest of the row carries valid data' \
        produced_by 'emit_index_readback_verbose() in ltl (run-level header block; partial-bounds branch)' \
        contract    'features/179-index-read-back.md § Behavior — Pre-seeded values § "Missing bound columns are tolerated"'

    assert_line "$out" \
        pattern     '^  preseed_duration_max: -$' \
        asserts     'When a specific bound column is "-" in the matched index row, the per-file preseed line for that bound echoes the literal "-" — the reader sees that the bound is unavailable rather than seeing a default that silently masks the gap' \
        produced_by 'emit_index_readback_verbose() in ltl (per-file preseed block, per-bound line)' \
        contract    'features/179-index-read-back.md § "-V verbose output" Layer 2 — Per-file preseed values; locked "-" rendering for missing bounds'

    assert_no_line "$out" \
        pattern     '^  preseed_duration_min: -$' \
        asserts     'Blanking one bound (duration_max) must not cascade — the other bound columns (duration_min, etc.) still report their seeded values; this confirms per-bound granularity of the missing-bound handling' \
        produced_by 'emit_index_readback_verbose() in ltl (per-file preseed block, per-bound line emitted per-column)' \
        contract    'features/179-index-read-back.md § Behavior — Pre-seeded values § "Missing bound columns are tolerated" (per-bound, not row-wide)'
}

scenario_expired_selection_entry() {
    current_scenario="expired-selection-entry"
    echo "[$current_scenario]"

    seed_from_fixture
    set_entry_date "entry_type=selection AND filters=-dmin=50" 91
    local out
    out=$(run_ltl_v -dmin 50 "$ACCESS_LOG")
    # The expired selection row is purged at end-of-run write per #46 logic;
    # at read-back time it may still match Tier 1 (read-back doesn't expire).
    # The acceptance criterion is that after the run, the prior expired row
    # is replaced by a fresh selection row (entry_date is now current).
    local current_year
    current_year=$(date +%Y)

    assert_command \
        command     "grep -q '^selection,${current_year}' ltl-index.csv" \
        label       "selection row refreshed with current entry_date (${current_year})" \
        asserts     'A selection row with entry_date older than the retention horizon (91 days here) is replaced by a fresh selection row at end-of-run write — read-back itself does not expire rows, but the write side does, so expiration is self-healing on the next run' \
        produced_by 'write_index_file() in ltl (end-of-run #46 write side; purges expired rows then writes fresh ones with current entry_date)' \
        contract    'features/179-index-read-back.md § Interactions with existing features § "With write side (#46)" — expiration semantics delegated to #46; § Behavior — read-back does not expire'
}

# ---------------------------------------------------------------------------
# Runner
# ---------------------------------------------------------------------------

echo "Validating index read-back against ltl at $LTL"
echo ""

echo "--- Helper self-tests ---"
in_scenario_dir helper_self_test

echo ""
echo "--- Scenarios ---"

for s in \
    scenario_cold_no_index \
    scenario_warm_unfiltered \
    scenario_cold_filtered_tier2_fallback \
    scenario_warm_tier1_filtered \
    scenario_warm_tier2_different_filters \
    scenario_stale_mtime \
    scenario_stale_size \
    scenario_drift_refresh_tier1 \
    scenario_drift_refresh_tier2 \
    scenario_multi_file_all_fresh_tier2_unfiltered \
    scenario_multi_file_all_fresh_tier1 \
    scenario_multi_file_mixed_tiers \
    scenario_multi_file_one_stale \
    scenario_malformed_index \
    scenario_missing_bound_column \
    scenario_expired_selection_entry \
    ; do
    echo ""
    in_scenario_dir "$s"
done

echo ""
echo "Results: $pass passed, $fail failed"

if [[ $fail -gt 0 ]]; then
    echo ""
    if [[ ${#failures[@]} -gt 0 ]]; then
        echo "Failures:"
        printf '  - %s\n' "${failures[@]}"
        echo ""
    fi
    echo "INDEX READ-BACK TESTS FAILED"
    exit 1
else
    echo "ALL INDEX READ-BACK TESTS PASSED"
    exit 0
fi
