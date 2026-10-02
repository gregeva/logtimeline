#!/usr/bin/env bash
# validate-timestamp-precision.sh — Validate the one timestamp formatter and
# the precision every rendered or written timestamp is shown at (issue #525).
#
# Contract: features/525-timestamp-precision-option.md (D1 one formatter, D7
# rounded once with carry, D8 the file-name stamp in scope) and its § 7
# Acceptance criteria. The harness owns no -V section: it compares what the
# run summary heading, the timeline, the run index and the aggregate export
# print for the same line, so its file name tracks the feature.
#
# Usage: ./tests/validate-timestamp-precision.sh [--list] [--scenario NAME]
#
# Implements the self-documenting-assertion design from
# tests/HARNESS-DESIGN.md. Reference: tests/validate-bucket-size-units.sh.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LTL="$REPO_DIR/ltl"

# shellcheck source=lib/runtime-warnings.sh
source "$SCRIPT_DIR/lib/runtime-warnings.sh"
# shellcheck source=lib/colour-env.sh
source "$SCRIPT_DIR/lib/colour-env.sh"
# shellcheck source=lib/scenario-select.sh
source "$SCRIPT_DIR/lib/scenario-select.sh"

scenario_register \
    one-formatter/structure \
    one-rounding/three-digit-ms \
    carry/next-second \
    carry/next-day \
    truncate/second-precision \
    index/older-row-fresh
SCENARIO_USAGE_NOTE='Contract: features/525-timestamp-precision-option.md § 7 (Acceptance criteria)'
scenario_parse_args "$@"

# Ambient FORCE_COLOR/NO_COLOR must not decide what this harness asserts
# against (tests/HARNESS-DESIGN.md section Colour rendering is controlled,
# never inherited).
neutralize_colour_env

if [[ ! -e "$LTL" ]]; then
    echo "ERROR: required file missing: $LTL" >&2
    exit 1
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# Fixtures: a few lines each of an application log whose timestamp fraction is
# variable-length (a log4j-style layout with a comma before the fraction).
# THREE carries fractions that are not exact binary fractions; CARRY ends on a
# line at .9996, which rounds into the next second at the millisecond; DAYEND
# does the same at 23:59:59.9996, into the next day.
THREE="$TMP_DIR/three.log"
CARRY="$TMP_DIR/carry.log"
DAYEND="$TMP_DIR/dayend.log"
printf '%s\n' \
    '2026-01-26 10:00:01,123 [main] INFO  com.example.Service - first line' \
    '2026-01-26 10:00:02,456 [main] INFO  com.example.Service - second line' \
    '2026-01-26 10:00:03,789 [main] ERROR com.example.Service - third line' > "$THREE"
printf '%s\n' \
    '2025-02-20 10:06:10,100 [main] INFO  com.example.Service - first line' \
    '2025-02-20 10:06:11,200 [main] INFO  com.example.Service - second line' \
    '2025-02-20 10:06:12,300 [main] INFO  com.example.Service - third line' \
    '2025-02-20 10:06:13,9996 [main] INFO  com.example.Service - fourth line' > "$CARRY"
printf '%s\n' \
    '2025-02-20 23:59:59,500 [main] INFO  com.example.Service - first line' \
    '2025-02-20 23:59:59,9996 [main] INFO  com.example.Service - last line' > "$DAYEND"

# Invocation shape (tests/HARNESS-DESIGN.md section Invocation coherence):
# the assertions read the timeline labels, the summary heading's bounds, the
# run index and the aggregate export. No messages table (-n 0), no empty
# buckets (-oe); width 200 keeps the heading's two bounds on one line. The
# index is a subject here, so -ni is passed only where it is not read; every
# run that writes an index or an export runs in a directory of its own.
COMMON=(--disable-progress -n 0 -oe --terminal-width 200)

CONTRACT_D1='features/525-timestamp-precision-option.md D1 (one timestamp formatter: epoch, precision, optional Z, rounded once) and D8 (the file-name stamp calls it)'
CONTRACT_D7='features/525-timestamp-precision-option.md D7 (rounded half-up once at the last displayed sub-second digit, carrying into seconds, minutes and the date; minute and second truncate)'
CONTRACT_INDEX='features/525-timestamp-precision-option.md § 7 drop 1 (older index rows stay fresh) and features/179-index-read-back.md § freshness (file_mtime compared by string equality)'

pass=0
fail=0
failures=()
current_scenario=""

fail_with() {
    # fail_with LABEL ASSERTS PRODUCED_BY CONTRACT [DETAIL...]
    local label="$1" asserts="$2" produced_by="$3" contract="$4"
    shift 4
    echo "  FAIL  $current_scenario :: $label"
    echo "        asserts:     $asserts"
    echo "        produced_by: $produced_by"
    echo "        contract:    $contract"
    local d
    for d in "$@"; do echo "        $d"; done
    fail=$((fail + 1))
    failures+=("$current_scenario :: $label")
}

pass_with() {
    echo "  PASS  $current_scenario :: $1"
    pass=$((pass + 1))
}

# run_in TAG ARGS... — runs ltl in its own directory $TMP_DIR/TAG, stdout to
# out.txt (ANSI stripped into plain.txt), stderr to err.txt, the exit code to
# rc.txt; applies the runtime-warning check. A non-zero exit is a failure.
run_in() {
    local tag="$1"; shift
    local dir="$TMP_DIR/$tag" rc
    mkdir -p "$dir"
    set +e
    ( cd "$dir" && "$LTL" "$@" > out.txt 2> err.txt )
    rc=$?
    set -e
    echo "$rc" > "$dir/rc.txt"
    sed -E 's/\x1b\[[0-9;]*m//g' "$dir/out.txt" > "$dir/plain.txt"
    if ! assert_no_runtime_warnings "$dir/err.txt" "$current_scenario/$tag"; then
        fail=$((fail + 1))
        failures+=("$current_scenario :: runtime warnings ($tag)")
    fi
    if [[ "$rc" != 0 ]]; then
        fail_with "ltl exits 0 ($tag)" "the run completes" 'ltl' "$CONTRACT_D1" \
            "exit: $rc" "stderr: $(head -3 "$dir/err.txt")"
    fi
}

# heading_bounds DIR — the summary heading's two bounds, "FIRST|LAST"; a
# missing anchor prints MISSING-ANCHOR (tests/HARNESS-DESIGN.md Trap 3/4).
heading_bounds() {
    local b
    b=$(perl -ne 'if (/results between (.+?) and (.+?)\s*$/) { print "$1|$2"; exit }' "$1/plain.txt")
    echo "${b:-MISSING-ANCHOR:heading}"
}

# index_cell DIR ENTRY_TYPE COLUMN — one cell of the run index's row for the
# entry type, by header name; MISSING-ANCHOR when the file, row or column is
# absent.
index_cell() {
    local v
    v=$(perl -e '
        my ($f, $type, $col) = @ARGV;
        open my $fh, "<", $f or exit;
        chomp(my $h = <$fh>); my @h = split /,/, $h;
        my ($i) = grep { $h[$_] eq $col } 0..$#h; defined $i or exit;
        while (<$fh>) { chomp; my @r = split /,/; if ($r[0] eq $type) { print $r[$i]; exit } }
    ' "$1/ltl-index.csv" "$2" "$3" 2>/dev/null || true)
    echo "${v:-MISSING-ANCHOR:index-$2-$3}"
}

# export_observation DIR KEY — observation.start or .end from the aggregate
# export the run published (named by the -V aggregate-export file: row).
export_observation() {
    local dir="$1" key="$2" file v
    file=$(awk '/^=== aggregate-export ===/ {s=1; next} s && /^file: / {print $2; exit}' "$dir/out.txt")
    if [[ -z "$file" || ! -f "$dir/$file" ]]; then
        echo "MISSING-ANCHOR:export-file"; return
    fi
    v=$(awk -v k="$key" '/^ *observation:/ {s=1; next} s && $1 == k":" { $1=""; sub(/^ /, ""); print; exit }' "$dir/$file")
    echo "${v:-MISSING-ANCHOR:observation-$key}"
}

# ---------------------------------------------------------------------------
# One formatter (D1, D8): structural
# ---------------------------------------------------------------------------
if scenario_wanted one-formatter/structure; then
current_scenario="one-formatter/structure"
# Outside format_timestamp no strftime, no millisecond sprintf and no
# gmtime/localtime call remain. The field readers that render nothing are
# exempt by name: fold_epoch, profile_included_weekdays and
# format_sample_probes, and the weekday field slice in print_bar_graph.
stray=$(perl -ne '
    $sub = $1 if /^sub (\w+)/;
    next if /^\s*#/;
    next if $sub eq "format_timestamp";
    next if $sub =~ /^(fold_epoch|profile_included_weekdays|format_sample_probes)$/;
    next if $sub eq "print_bar_graph" && /\(gmtime\([^;]*\)\)\[\d\]/;
    print "$sub:$.: $_" if /\b(strftime|gmtime|localtime)\s*\(|\.%03d/;
' "$LTL")
old_subs=$(grep -cE '^sub (format_epoch_iso|format_observation_timestamp|format_bucket_timestamp)\b' "$LTL" || true)
stamp_calls=$(perl -ne '$s = $1 if /^sub (\w+)/; print if $s eq "run_file_stamp" && /format_timestamp\(/' "$LTL")
if [[ -z "$stray" && "$old_subs" == 0 && -n "$stamp_calls" ]]; then
    pass_with "every timestamp is rendered by format_timestamp; the three former subs are gone; run_file_stamp calls it"
else
    fail_with "every timestamp is rendered by format_timestamp; the three former subs are gone; run_file_stamp calls it" \
        "outside format_timestamp no strftime, .%03d or gmtime/localtime call renders a timestamp (the field readers that render nothing excepted); format_epoch_iso, format_observation_timestamp and format_bucket_timestamp do not exist; the output file-name stamp is formatted by format_timestamp" \
        'format_timestamp() and run_file_stamp() in ltl' "$CONTRACT_D1" \
        "stray: ${stray:-none}" "former subs defined: $old_subs" "run_file_stamp calls: ${stamp_calls:-none}"
fi
fi

# ---------------------------------------------------------------------------
# One rounding (D7): heading, export and index agree on .123
# ---------------------------------------------------------------------------
if scenario_wanted one-rounding/three-digit-ms; then
current_scenario="one-rounding/three-digit-ms"
run_in round "${COMMON[@]}" -o -V aggregate-export -ms -bs 1000 "$THREE"
d="$TMP_DIR/round"
first=$(heading_bounds "$d"); first=${first%%|*}
obs=$(export_observation "$d" start)
idx=$(index_cell "$d" file first_timestamp)
if [[ "$first" == "2026-01-26 10:00:01.123" && "$obs" == "2026-01-26 10:00:01.123" && "$idx" == "2026-01-26T10:00:01.123" ]]; then
    pass_with "heading, export observation.start and index first_timestamp all read 10:00:01.123"
else
    fail_with "heading, export observation.start and index first_timestamp all read 10:00:01.123" \
        "a line written at 10:00:01.123 is shown at .123 by every surface under -ms: the heading's first bound, the export's observation.start and the index's first_timestamp" \
        'format_timestamp() in ltl, called by print_summary_table() (heading), write_aggregate_export() and write_index_file()' "$CONTRACT_D7" \
        "heading: $first" "export: $obs" "index: $idx"
fi
fi

# ---------------------------------------------------------------------------
# Carry (D7): .9996 at the millisecond is the next second's .000
# ---------------------------------------------------------------------------
if scenario_wanted carry/next-second; then
current_scenario="carry/next-second"
run_in carry "${COMMON[@]}" -o -V aggregate-export -ms -bs 100 "$CARRY"
d="$TMP_DIR/carry"
last=$(heading_bounds "$d"); last=${last##*|}
obs=$(export_observation "$d" end)
idx=$(index_cell "$d" file last_timestamp)
label=$(grep -cE '^ 2025-02-20 10:06:14\.000 INFO: 1 ' "$d/plain.txt" || true)
if [[ "$last" == "2025-02-20 10:06:14.000" && "$obs" == "2025-02-20 10:06:14.000" && "$idx" == "2025-02-20T10:06:14.000" && "$label" == 1 ]]; then
    pass_with "heading, export, index and the line's bucket label name 10:06:14.000"
else
    fail_with "heading, export, index and the line's bucket label name 10:06:14.000" \
        "a line at 10:06:13.9996 rounds at the millisecond into the next second: the heading's last bound, observation.end, the index's last_timestamp and the bucket the line counts in all name 10:06:14.000" \
        'format_timestamp() in ltl (the one rounding, with carry); the bucket key in read_and_process_logs()' "$CONTRACT_D7" \
        "heading: $last" "export: $obs" "index: $idx" "bucket rows labelled 10:06:14.000 holding the line: $label"
fi
four=$(cat "$d/plain.txt" "$d/ltl-index.csv" "$d"/*-LTL-AGGREGATE.yaml | grep -oE '[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{4,}' || true)
if [[ -z "$four" ]]; then
    pass_with "no timestamp carries a four-digit fraction"
else
    fail_with "no timestamp carries a four-digit fraction" \
        "a rounded millisecond never overflows into a fourth digit (.1000): the carry goes into the second" \
        'format_timestamp() in ltl' "$CONTRACT_D7" "found: $(echo "$four" | sort -u | tr '\n' ' ')"
fi
fi

if scenario_wanted carry/next-day; then
current_scenario="carry/next-day"
run_in dayend "${COMMON[@]}" -o -V aggregate-export -ms -bs 100 "$DAYEND"
d="$TMP_DIR/dayend"
last=$(heading_bounds "$d"); last=${last##*|}
idx=$(index_cell "$d" file last_timestamp)
label=$(grep -cE '^ 2025-02-21 00:00:00\.000 INFO: 1 ' "$d/plain.txt" || true)
if [[ "$last" == "2025-02-21 00:00:00.000" && "$idx" == "2025-02-21T00:00:00.000" && "$label" == 1 ]]; then
    pass_with "a line at 23:59:59.9996 is shown at the next day's 00:00:00.000"
else
    fail_with "a line at 23:59:59.9996 is shown at the next day's 00:00:00.000" \
        "the carry from the millisecond reaches the date: the heading's last bound, the index's last_timestamp and the line's bucket label name 2025-02-21 00:00:00.000" \
        'format_timestamp() in ltl' "$CONTRACT_D7" \
        "heading: $last" "index: $idx" "bucket rows labelled 2025-02-21 00:00:00.000 holding the line: $label"
fi
fi

# ---------------------------------------------------------------------------
# Second precision truncates (D7)
# ---------------------------------------------------------------------------
if scenario_wanted truncate/second-precision; then
current_scenario="truncate/second-precision"
run_in trunc "${COMMON[@]}" -ni -s -bs 1 "$CARRY"
d="$TMP_DIR/trunc"
last=$(heading_bounds "$d"); last=${last##*|}
label=$(grep -cE '^ 2025-02-20 10:06:13 INFO: 1 ' "$d/plain.txt" || true)
if [[ "$last" == "2025-02-20 10:06:13" && "$label" == 1 ]]; then
    pass_with "at second precision the 10:06:13.9996 line reads 10:06:13"
else
    fail_with "at second precision the 10:06:13.9996 line reads 10:06:13" \
        "minute and second precision truncate as clocks and bucket labels do: under -s the line's bucket label and the heading's last bound read 10:06:13" \
        'format_timestamp() in ltl' "$CONTRACT_D7" "heading: $last" "bucket rows labelled 10:06:13 holding the line: $label"
fi
fi

# ---------------------------------------------------------------------------
# An index row whose file_mtime was written in the established form is fresh
# ---------------------------------------------------------------------------
if scenario_wanted index/older-row-fresh; then
current_scenario="index/older-row-fresh"
d="$TMP_DIR/fresh"
mkdir -p "$d"
cp "$THREE" "$d/three.log"
run_in fresh "${COMMON[@]}" -V index-read-back -ms -bs 1000 three.log
# Rewrite the file row's file_mtime with the expression the index writer used
# before the one formatter, so the read-back compares the new formatter's
# on-disk time against a value written the established way.
old_form=$(perl -MPOSIX=strftime -e 'print strftime("%Y-%m-%dT%H:%M:%S", gmtime((stat $ARGV[0])[9]))' "$d/three.log")
perl -i -pe 'BEGIN { $v = shift } s/^(file,[^,]*,[^,]*,[^,]*,)[^,]*,/$1$v,/' "$old_form" "$d/ltl-index.csv"
written=$(index_cell "$d" file file_mtime)
run_in fresh "${COMMON[@]}" -V index-read-back -ms -bs 1000 three.log
fresh=$(awk '/^=== index-read-back ===/ {s=1; next} s && /^  freshness: / {print $2; exit}' "$d/out.txt")
if [[ "$written" == "$old_form" && "$fresh" == "fresh" ]]; then
    pass_with "a row whose file_mtime was written in the established form reads fresh"
else
    fail_with "a row whose file_mtime was written in the established form reads fresh" \
        "the index's file_mtime keeps its whole-second ISO form, so a row an earlier build wrote is still matched by string equality with the on-disk time" \
        'format_timestamp() in ltl, called by read_index_file() (freshness)' "$CONTRACT_INDEX" \
        "file_mtime written: $written (wanted $old_form)" "freshness: ${fresh:-MISSING-ANCHOR:freshness}"
fi
fi

# ---------------------------------------------------------------------------
echo
echo "Results: $pass passed, $fail failed"
if [[ "$pass" -eq 0 && "$fail" -eq 0 ]]; then
    echo "ERROR: no assertion ran" >&2
    exit 1
fi
if [[ "$fail" -gt 0 ]]; then
    echo "Failures:"
    printf '  %s\n' "${failures[@]}"
    exit 1
fi
exit 0
