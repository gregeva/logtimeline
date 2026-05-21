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

ACCESS_LOG="$REPO_DIR/logs/AccessLogs/localhost_access_log-twx01-twx-thingworx-0.2025-05-05.txt"
SCRIPT_LOG="$REPO_DIR/logs/ThingworxLogs/CustomThingworxLogs/ScriptLog-DPMExtended-clean.log"

# Common options: suppress progress and limit top messages.
COMMON="--disable-progress -osum -n 1"

if [[ ! -x "$LTL" ]]; then
    echo "ERROR: ltl not found or not executable at $LTL"
    exit 1
fi
if [[ ! -f "$ACCESS_LOG" ]]; then
    echo "ERROR: ACCESS_LOG not found: $ACCESS_LOG"
    exit 1
fi
if [[ ! -f "$SCRIPT_LOG" ]]; then
    echo "ERROR: SCRIPT_LOG not found: $SCRIPT_LOG"
    exit 1
fi

pass=0
fail=0
failures=()

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

# Seed the index by running ltl normally. The run produces real file and
# selection rows for the given log + filter args. Returns the -V capture
# path so callers can extract calibrated bounds for downstream assertions.
# Usage: out=$(seed_via_ltl <ltl args...>)
seed_via_ltl() {
    run_ltl $COMMON -V index-read-back "$@"
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

# Assert a specific line appears in the -V capture file.
# Usage: assert_line "scenario-name" "$out" '^index_used: yes$'
assert_line() {
    local name="$1" file="$2" pattern="$3"
    if grep -qE "$pattern" "$file"; then
        echo "  PASS  $name :: $pattern"
        pass=$((pass + 1))
    else
        echo "  FAIL  $name :: $pattern"
        echo "        (not found in $file)"
        fail=$((fail + 1))
        failures+=("$name :: $pattern")
    fi
}

# Assert a line does NOT appear.
assert_no_line() {
    local name="$1" file="$2" pattern="$3"
    if grep -qE "$pattern" "$file"; then
        echo "  FAIL  $name :: $pattern (unexpectedly found)"
        fail=$((fail + 1))
        failures+=("$name :: $pattern (unexpectedly found)")
    else
        echo "  PASS  $name :: !$pattern"
        pass=$((pass + 1))
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
    local name="helpers"
    # Seed an index from a real run.
    seed_via_ltl "$ACCESS_LOG" > /dev/null
    if [[ ! -f ltl-index.csv ]]; then
        echo "  FAIL  $name :: seed_via_ltl did not produce ltl-index.csv"
        fail=$((fail + 1))
        return
    fi
    local file_rows_before sel_rows_before
    file_rows_before=$(grep -c '^file,' ltl-index.csv || true)
    sel_rows_before=$(grep -c '^selection,' ltl-index.csv || true)
    if [[ "$file_rows_before" -lt 1 || "$sel_rows_before" -lt 1 ]]; then
        echo "  FAIL  $name :: expected at least one file row and one selection row after seed"
        fail=$((fail + 1))
        return
    fi

    # Test delete_index_rows: remove the selection row.
    delete_index_rows "entry_type=selection"
    local sel_rows_after
    sel_rows_after=$(grep -c '^selection,' ltl-index.csv || true)
    if [[ "$sel_rows_after" -ne 0 ]]; then
        echo "  FAIL  $name :: delete_index_rows did not remove selection row"
        fail=$((fail + 1))
        return
    fi
    pass=$((pass + 1))
    echo "  PASS  $name :: delete_index_rows removes matching rows"

    # Test edit_index_row: change duration_max in the file row.
    edit_index_row "entry_type=file" "duration_max=999999"
    if grep -q ',999999,' ltl-index.csv; then
        pass=$((pass + 1))
        echo "  PASS  $name :: edit_index_row applies new value"
    else
        echo "  FAIL  $name :: edit_index_row did not apply"
        fail=$((fail + 1))
    fi

    # Test corrupt_index_file: truncate.
    corrupt_index_file truncate
    if [[ "$(wc -c < ltl-index.csv)" -lt 2000 ]]; then
        pass=$((pass + 1))
        echo "  PASS  $name :: corrupt_index_file truncate"
    else
        echo "  FAIL  $name :: truncate did not shrink file"
        fail=$((fail + 1))
    fi
}

# ---------------------------------------------------------------------------
# Scenarios (6b)
# ---------------------------------------------------------------------------

scenario_cold_no_index() {
    local out
    out=$(run_ltl_v "$ACCESS_LOG")
    assert_line "cold-no-index" "$out" '^index_used: no$'
    if [[ ! -f ltl-index.csv ]]; then
        echo "  FAIL  cold-no-index :: index was not written"
        fail=$((fail + 1))
        return
    fi
    grep -q '^file,' ltl-index.csv && grep -q '^selection,' ltl-index.csv \
        && { pass=$((pass+1)); echo "  PASS  cold-no-index :: index has file and selection rows"; } \
        || { fail=$((fail+1)); echo "  FAIL  cold-no-index :: index missing rows"; }
}

scenario_warm_unfiltered() {
    seed_via_ltl "$ACCESS_LOG" > /dev/null
    local out
    out=$(run_ltl_v "$ACCESS_LOG")
    assert_line "warm-unfiltered" "$out" '^index_used: yes$'
    # The unfiltered run matches a selection entry with filters=- (Tier 1)
    # — see spec §6.4: that selection entry and the file entry describe
    # the same population and would always agree.
    assert_line "warm-unfiltered" "$out" '^  lookup: tier_1_selection$'
    assert_line "warm-unfiltered" "$out" '^  freshness: fresh$'
    assert_line "warm-unfiltered" "$out" '^drift_detected: no$'
}

scenario_cold_filtered_tier2_fallback() {
    # Seed produces a selection row with filters=- only. Filtered run should
    # fall back to Tier 2 (file row) since no matching selection row exists.
    seed_via_ltl "$ACCESS_LOG" > /dev/null
    local out
    out=$(run_ltl_v -dmin 50 "$ACCESS_LOG")
    assert_line "cold-filtered-tier2-fallback" "$out" '^index_used: yes$'
    assert_line "cold-filtered-tier2-fallback" "$out" '^  lookup: tier_2_file$'
    assert_line "cold-filtered-tier2-fallback" "$out" '^index_filter_signature: -dmin=50$'
    # End-of-run write should add a selection row for -dmin=50.
    grep -q '^selection,.*,-dmin=50$' ltl-index.csv \
        && { pass=$((pass+1)); echo "  PASS  cold-filtered-tier2-fallback :: selection row written for -dmin=50"; } \
        || { fail=$((fail+1)); echo "  FAIL  cold-filtered-tier2-fallback :: no -dmin=50 selection row written"; }
}

scenario_warm_tier1_filtered() {
    # First filtered run creates the selection row.
    seed_via_ltl -dmin 50 "$ACCESS_LOG" > /dev/null
    # Second filtered run hits Tier 1.
    local out
    out=$(run_ltl_v -dmin 50 "$ACCESS_LOG")
    assert_line "warm-tier1-filtered" "$out" '^index_used: yes$'
    assert_line "warm-tier1-filtered" "$out" '^  lookup: tier_1_selection$'
    assert_line "warm-tier1-filtered" "$out" '^index_filter_signature: -dmin=50$'
    assert_line "warm-tier1-filtered" "$out" '^drift_detected: no$'
}

scenario_warm_tier2_different_filters() {
    # Seed with one filter set; run with a different filter set.
    seed_via_ltl -dmin 50 "$ACCESS_LOG" > /dev/null
    local out
    out=$(run_ltl_v -dmin 100 "$ACCESS_LOG")
    assert_line "warm-tier2-different-filters" "$out" '^  lookup: tier_2_file$'
    assert_line "warm-tier2-different-filters" "$out" '^index_filter_signature: -dmin=100$'
    # After the run, both selection rows (-dmin=50 and -dmin=100) should exist.
    grep -q '^selection,.*,-dmin=50$'  ltl-index.csv \
        && grep -q '^selection,.*,-dmin=100$' ltl-index.csv \
        && { pass=$((pass+1)); echo "  PASS  warm-tier2-different-filters :: both selection rows preserved"; } \
        || { fail=$((fail+1)); echo "  FAIL  warm-tier2-different-filters :: selection rows missing"; }
}

scenario_stale_mtime() {
    # Seed, then advance the on-disk file's mtime. The stored entry is now stale.
    # Use a local copy so we can touch it without modifying the shared logs/ file.
    local local_log="./access.log"
    cp "$ACCESS_LOG" "$local_log"
    seed_via_ltl "$local_log" > /dev/null
    # Wait briefly + touch to ensure mtime advances (file system mtime resolution).
    sleep 1
    touch "$local_log"
    local out
    out=$(run_ltl_v "$local_log")
    assert_line "stale-mtime" "$out" '^index_used: no$'
    assert_line "stale-mtime" "$out" '^  freshness: stale_mtime$'
}

scenario_stale_size() {
    # Seed, then manually edit the index's stored file_size to a different value.
    local local_log="./access.log"
    cp "$ACCESS_LOG" "$local_log"
    seed_via_ltl "$local_log" > /dev/null
    edit_index_row "entry_type=file" "file_size=42"
    local out
    out=$(run_ltl_v "$local_log")
    assert_line "stale-size" "$out" '^index_used: no$'
    assert_line "stale-size" "$out" '^  freshness: stale_size$'
}

scenario_drift_refresh_tier1() {
    # Seed with filtered run -> selection row is written with real bounds.
    local cal_out
    cal_out=$(seed_via_ltl -dmin 50 "$ACCESS_LOG")
    local cal_max
    cal_max=$(extract_v_value "$cal_out" 'preseed_duration_max')
    if [[ -z "$cal_max" || "$cal_max" == "-" ]]; then
        # First run had no preseed (cold). Seed once more so subsequent run can show calibration.
        cal_out=$(seed_via_ltl -dmin 50 "$ACCESS_LOG")
        cal_max=$(extract_v_value "$cal_out" 'preseed_duration_max')
    fi
    if [[ -z "$cal_max" || "$cal_max" == "-" ]]; then
        echo "  FAIL  drift-refresh-tier1 :: could not calibrate cal_max"
        fail=$((fail + 1))
        return
    fi
    # Narrow the selection row's duration_max to half the calibrated max.
    local narrowed=$((cal_max / 2))
    edit_index_row "entry_type=selection AND filters=-dmin=50" "duration_max=$narrowed"
    local out
    out=$(run_ltl_v -dmin 50 "$ACCESS_LOG")
    assert_line "drift-refresh-tier1" "$out" '^index_used: yes$'
    assert_line "drift-refresh-tier1" "$out" '^  lookup: tier_1_selection$'
    assert_line "drift-refresh-tier1" "$out" '^drift_detected: yes$'
    assert_line "drift-refresh-tier1" "$out" "^  duration_max: live=$cal_max preseed=$narrowed drifted=yes$"

    # Re-run: the previous write refreshed the selection row, drift should be gone.
    local out2
    out2=$(run_ltl_v -dmin 50 "$ACCESS_LOG")
    assert_line "drift-refresh-tier1-recovery" "$out2" '^drift_detected: no$'
}

scenario_drift_refresh_tier2() {
    local cal_out
    cal_out=$(seed_via_ltl "$ACCESS_LOG")
    local cal_max
    cal_max=$(extract_v_value "$cal_out" 'preseed_duration_max')
    if [[ -z "$cal_max" || "$cal_max" == "-" ]]; then
        cal_out=$(seed_via_ltl "$ACCESS_LOG")
        cal_max=$(extract_v_value "$cal_out" 'preseed_duration_max')
    fi
    if [[ -z "$cal_max" || "$cal_max" == "-" ]]; then
        echo "  FAIL  drift-refresh-tier2 :: could not calibrate cal_max"
        fail=$((fail + 1))
        return
    fi
    # Force an unfiltered Tier 2 path by deleting the unfiltered selection row.
    delete_index_rows "entry_type=selection AND filters=-"
    local narrowed=$((cal_max / 2))
    edit_index_row "entry_type=file" "duration_max=$narrowed"
    local out
    out=$(run_ltl_v "$ACCESS_LOG")
    assert_line "drift-refresh-tier2" "$out" '^  lookup: tier_2_file$'
    assert_line "drift-refresh-tier2" "$out" '^drift_detected: yes$'
    assert_line "drift-refresh-tier2" "$out" "^  duration_max: live=$cal_max preseed=$narrowed drifted=yes$"
}

scenario_multi_file_all_fresh_tier2_unfiltered() {
    # Seed both files, force Tier 2 by deleting selection rows, then run again.
    seed_via_ltl "$ACCESS_LOG" "$SCRIPT_LOG" > /dev/null
    delete_index_rows "entry_type=selection"
    local out
    out=$(run_ltl_v "$ACCESS_LOG" "$SCRIPT_LOG")
    assert_line "multi-file-all-fresh-tier2-unfiltered" "$out" '^index_used: yes$'
    # Both per-file blocks should report tier_2_file fresh.
    local tier2_count
    tier2_count=$(grep -c '^  lookup: tier_2_file$' "$out" || true)
    if [[ "$tier2_count" -eq 2 ]]; then
        pass=$((pass+1)); echo "  PASS  multi-file-all-fresh-tier2-unfiltered :: both files at tier_2_file"
    else
        fail=$((fail+1)); echo "  FAIL  multi-file-all-fresh-tier2-unfiltered :: expected 2 tier_2_file lookups, got $tier2_count"
    fi
    # Aggregated block must include (from <path>) provenance.
    assert_line "multi-file-all-fresh-tier2-unfiltered" "$out" '^aggregated_preseed:$'
    assert_line "multi-file-all-fresh-tier2-unfiltered" "$out" '^  duration_max: .* \(from .*\)$'
}

scenario_multi_file_all_fresh_tier1() {
    seed_via_ltl -dmin 50 "$ACCESS_LOG" "$SCRIPT_LOG" > /dev/null
    local out
    out=$(run_ltl_v -dmin 50 "$ACCESS_LOG" "$SCRIPT_LOG")
    assert_line "multi-file-all-fresh-tier1" "$out" '^index_used: yes$'
    local tier1_count
    tier1_count=$(grep -c '^  lookup: tier_1_selection$' "$out" || true)
    if [[ "$tier1_count" -eq 2 ]]; then
        pass=$((pass+1)); echo "  PASS  multi-file-all-fresh-tier1 :: both files at tier_1_selection"
    else
        fail=$((fail+1)); echo "  FAIL  multi-file-all-fresh-tier1 :: expected 2 tier_1_selection lookups, got $tier1_count"
    fi
}

scenario_multi_file_mixed_tiers() {
    # Seed both files for -dmin=50 (so both have tier 1 candidates).
    seed_via_ltl -dmin 50 "$ACCESS_LOG" "$SCRIPT_LOG" > /dev/null
    # Delete the SCRIPT_LOG selection row so SCRIPT_LOG falls back to Tier 2.
    delete_index_rows "entry_type=selection AND file_path=$SCRIPT_LOG AND filters=-dmin=50"
    local out
    out=$(run_ltl_v -dmin 50 "$ACCESS_LOG" "$SCRIPT_LOG")
    assert_line "multi-file-mixed-tiers" "$out" '^index_used: no$'
    # Per-file blocks still report what each file would have matched at.
    assert_line "multi-file-mixed-tiers" "$out" '^  lookup: tier_1_selection$'
    assert_line "multi-file-mixed-tiers" "$out" '^  lookup: tier_2_file$'
    # No aggregated_preseed block when mixed.
    assert_no_line "multi-file-mixed-tiers" "$out" '^aggregated_preseed:$'
}

scenario_multi_file_one_stale() {
    local f1="./access.log"
    local f2="./script.log"
    cp "$ACCESS_LOG" "$f1"
    cp "$SCRIPT_LOG" "$f2"
    seed_via_ltl "$f1" "$f2" > /dev/null
    sleep 1
    touch "$f1"   # advance only $f1's mtime
    local out
    out=$(run_ltl_v "$f1" "$f2")
    assert_line "multi-file-one-stale" "$out" '^index_used: no$'
    assert_line "multi-file-one-stale" "$out" '^  freshness: stale_mtime$'
    assert_line "multi-file-one-stale" "$out" '^  freshness: fresh$'
}

scenario_malformed_index() {
    seed_via_ltl "$ACCESS_LOG" > /dev/null
    # Use 'malform' (mismatched quotes appended) rather than 'truncate'.
    # Truncate leaves a row with a partial path that the existing #46
    # write side preserves verbatim on rewrite, yielding 2 file rows
    # instead of self-healing. Mismatched quotes trip CSV parse cleanly,
    # exercising the spec's malformed-index acceptance criterion.
    corrupt_index_file malform
    local out
    out=$(run_ltl_v "$ACCESS_LOG")
    assert_line "malformed-index" "$out" '^index_used: no$'
    # End-of-run write should overwrite the corrupt file with valid CSV.
    if perl -MText::CSV -e '
        my $csv = Text::CSV->new({binary=>1, eol=>$/});
        open my $f, "<", "ltl-index.csv" or exit 1;
        while (my $r = $csv->getline($f)) {}
        my $err = $csv->error_diag;
        exit (($err && (split / /, $err)[0] ne "EOF") ? 1 : 0);
    '; then
        pass=$((pass+1)); echo "  PASS  malformed-index :: index rewritten as valid CSV"
    else
        fail=$((fail+1)); echo "  FAIL  malformed-index :: index still malformed after run"
    fi
}

scenario_missing_bound_column() {
    seed_via_ltl "$ACCESS_LOG" > /dev/null
    edit_index_row "entry_type=file" "duration_max=-"
    delete_index_rows "entry_type=selection"   # force Tier 2
    local out
    out=$(run_ltl_v "$ACCESS_LOG")
    assert_line "missing-bound-column" "$out" '^index_used: yes$'
    # When duration_max column is '-' in the matched file row, preseed reflects '-'.
    assert_line "missing-bound-column" "$out" '^  preseed_duration_max: -$'
    # Other bounds still populated.
    assert_no_line "missing-bound-column" "$out" '^  preseed_duration_min: -$'
}

scenario_expired_selection_entry() {
    seed_via_ltl -dmin 50 "$ACCESS_LOG" > /dev/null
    set_entry_date "entry_type=selection AND filters=-dmin=50" 91
    local out
    out=$(run_ltl_v -dmin 50 "$ACCESS_LOG")
    # The expired selection row is purged at end-of-run write per #46 logic;
    # at read-back time it may still match Tier 1 (read-back doesn't expire).
    # The acceptance criterion is that after the run, the prior expired row
    # is replaced by a fresh selection row (entry_date is now current).
    local current_year
    current_year=$(date +%Y)
    if grep -q "^selection,${current_year}" ltl-index.csv; then
        pass=$((pass+1)); echo "  PASS  expired-selection-entry :: selection row refreshed with current entry_date"
    else
        fail=$((fail+1)); echo "  FAIL  expired-selection-entry :: selection row not refreshed"
    fi
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
    echo "[$s]"
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
