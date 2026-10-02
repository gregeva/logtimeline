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
    index/older-row-fresh \
    option/values \
    option/equivalence \
    option/width-separate \
    option/read-at-precision \
    deprecation/notice \
    deprecation/switch-jobs \
    rejection/values \
    rejection/switch-conflict
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
CONTRACT_D3='features/525-timestamp-precision-option.md D3 (-tp covers minute, second, millisecond, microsecond; the ladder tokens and long spellings) and D9 (-tp, --timestamp-precision)'
CONTRACT_D5='features/525-timestamp-precision-option.md D5 (-s and -ms deprecated with a notice for one release, keeping their jobs) and D12 (-s or -ms beside a -tp of another precision is a usage error)'
CONTRACT_D11='features/525-timestamp-precision-option.md D11 (timestamp precision and bucket width are separate: -tp sets no width; a bare -bs number is minutes)'
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

# timeline_text DIR — the rendered run without the lines that legitimately
# differ between two equivalent invocations: the echoed options and the
# summary's elapsed time and peak memory.
timeline_text() {
    grep -vE '^(command-line|environment) options: |^  (TOTAL TIME|MAXIMUM MEMORY USED) ' "$1/plain.txt"
}

# benchmark_row DIR KEY — one CONFIG row of -V benchmark-data.
benchmark_row() {
    local v
    v=$(awk -F'\t' -v k="$2" '$1 == "CONFIG" && $2 == k { print $3 }' "$1/out.txt")
    echo "${v:-MISSING-ANCHOR:$2}"
}

# same_run LABEL DIR_A DIR_B ASSERTS PRODUCED_BY CONTRACT — both runs exited
# 0 and rendered timeline rows, and their rendered text is byte-identical.
same_run() {
    local d
    for d in "$2" "$3"; do
        if [[ "$(cat "$d/rc.txt")" != 0 ]] || ! grep -qE '^ [0-9]{4}-[0-9]{2}-[0-9]{2} ' "$d/plain.txt"; then
            fail_with "$1" "$4" "$5" "$6" "run $(basename "$d") exited $(cat "$d/rc.txt") or rendered no timeline row"
            return
        fi
    done
    if diff -q <(timeline_text "$2") <(timeline_text "$3") > /dev/null; then
        pass_with "$1"
    else
        fail_with "$1" "$4" "$5" "$6" "$(diff <(timeline_text "$2") <(timeline_text "$3") | head -6 | tr '\n' '~')"
    fi
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
# The option (D3, D9): every spelling of a step is the same run
# ---------------------------------------------------------------------------
if scenario_wanted option/values; then
current_scenario="option/values"
for group in "m minute Minutes" "s second SECONDS sec" "ms millisecond msec MilliSeconds" "us microsecond usec Microseconds"; do
    read -r token rest <<< "$group"
    run_in "val-$token" "${COMMON[@]}" -ni -bs 1 -tp "$token" "$THREE"
    for spelling in $rest; do
        run_in "val-$token-$spelling" "${COMMON[@]}" -ni -bs 1 -tp "$spelling" "$THREE"
        same_run "-tp $spelling renders as -tp $token" "$TMP_DIR/val-$token" "$TMP_DIR/val-$token-$spelling" \
            "every spelling of a precision step, in any case, gives the same run as the step's token" \
            'adapt_to_command_line_options() in ltl (-tp resolved through time_unit_canonical())' "$CONTRACT_D3"
    done
done
fi

# ---------------------------------------------------------------------------
# Equivalence with the switches (D5, D11)
# ---------------------------------------------------------------------------
if scenario_wanted option/equivalence; then
current_scenario="option/equivalence"
run_in eq-none "${COMMON[@]}" -ni "$THREE"
run_in eq-tpm  "${COMMON[@]}" -ni -tp m "$THREE"
same_run "-tp m renders as the run without any switch" "$TMP_DIR/eq-none" "$TMP_DIR/eq-tpm" \
    "minute precision is the default: naming it changes nothing" 'adapt_to_command_line_options() in ltl' "$CONTRACT_D3"
run_in eq-s    "${COMMON[@]}" -ni -s -bs 30 "$CARRY"
run_in eq-tps  "${COMMON[@]}" -ni -tp s -bs 30s "$CARRY"
same_run "-tp s -bs 30s renders as -s -bs 30" "$TMP_DIR/eq-s" "$TMP_DIR/eq-tps" \
    "the deprecated switch's two jobs are -tp for the precision and a unit on -bs for the width" \
    'adapt_to_command_line_options() in ltl' "$CONTRACT_D5; $CONTRACT_D11"
fi

# ---------------------------------------------------------------------------
# Width and precision separate (D11)
# ---------------------------------------------------------------------------
if scenario_wanted option/width-separate; then
current_scenario="option/width-separate"
run_in ws-none "${COMMON[@]}" -ni -V benchmark-data "$THREE"
run_in ws-tpms "${COMMON[@]}" -ni -V benchmark-data -tp ms "$THREE"
none=$(benchmark_row "$TMP_DIR/ws-none" bucket_size_seconds)
tpms=$(benchmark_row "$TMP_DIR/ws-tpms" bucket_size_seconds)
labels=$(grep -cE '^ 2026-01-26 10:[0-9]{2}:[0-9]{2}\.[0-9]{3} ' "$TMP_DIR/ws-tpms/plain.txt" || true)
if [[ "$none" == "$tpms" && "$none" != MISSING-ANCHOR:* && "$labels" -gt 0 ]]; then
    pass_with "-tp ms alone keeps the default width ($none s) and labels to the millisecond"
else
    fail_with "-tp ms alone keeps the default width and labels to the millisecond" \
        "-tp sets no width: with -bs absent the width is the run without any switch's; only the labels gain milliseconds" \
        'adapt_to_command_line_options() and adapt_to_terminal_settings() in ltl' "$CONTRACT_D11" \
        "without: $none" "with -tp ms: $tpms" "millisecond labels: $labels"
fi
run_in ws-60 "${COMMON[@]}" -ni -V benchmark-data -tp ms -bs 60 "$THREE"
w60=$(benchmark_row "$TMP_DIR/ws-60" bucket_size_seconds)
if [[ "$w60" == "3600.00" ]]; then
    pass_with "-tp ms -bs 60 is a 60-minute width"
else
    fail_with "-tp ms -bs 60 is a 60-minute width" "a bare -bs number is minutes whatever -tp says" \
        'adapt_to_command_line_options() in ltl (bucket-size resolution)' "$CONTRACT_D11" "bucket_size_seconds: $w60"
fi
run_in ws-s90   "${COMMON[@]}" -ni -s -bs 90s "$CARRY"
run_in ws-tps90 "${COMMON[@]}" -ni -tp s -bs 90s "$CARRY"
same_run "-tp s -bs 90s renders as -s -bs 90s" "$TMP_DIR/ws-s90" "$TMP_DIR/ws-tps90" \
    "a unit on -bs sets the width and -tp the precision, so the pair reproduces the deprecated switch with the same unit-form width" \
    'adapt_to_command_line_options() in ltl' "$CONTRACT_D11"
fi

# ---------------------------------------------------------------------------
# Rendered at the precision (D11)
# ---------------------------------------------------------------------------
if scenario_wanted option/read-at-precision; then
current_scenario="option/read-at-precision"
run_in rp "${COMMON[@]}" -ni -bs 1 -tp ms "$THREE"
b=$(heading_bounds "$TMP_DIR/rp")
if [[ "$b" == "2026-01-26 10:00:01.123|2026-01-26 10:00:03.789" ]]; then
    pass_with "-tp ms renders the heading's bounds as 01.123 and 03.789"
else
    fail_with "-tp ms renders the heading's bounds as 01.123 and 03.789" \
        "at millisecond precision the heading shows the lines' timestamps to the millisecond, as written" \
        'format_timestamp() in ltl, called by print_summary_table()' "$CONTRACT_D3" "heading: $b"
fi
fi

# ---------------------------------------------------------------------------
# Deprecation (D5, D12)
# ---------------------------------------------------------------------------
if scenario_wanted deprecation/notice; then
current_scenario="deprecation/notice"
for sw in "-s|-tp s|-bs 30s" "-ms|-tp ms|-bs 100ms"; do
    IFS='|' read -r flag tp bs <<< "$sw"
    for progress in on off; do
        tag="dep${flag}-$progress"
        if [[ "$progress" == on ]]; then
            run_in "$tag" -n 0 -oe -ni --terminal-width 200 "$flag" -bs 1 "$THREE"
        else
            run_in "$tag" "${COMMON[@]}" -ni "$flag" -bs 1 "$THREE"
        fi
        n=$(grep -cE "^Warning: ${flag}/--[a-z]+ is deprecated: use ${tp} for the timestamp precision, and give -bs a unit \(${bs}\) for the bucket width\$" "$TMP_DIR/$tag/err.txt" || true)
        if [[ "$n" == 1 ]]; then
            pass_with "$flag prints one deprecation line naming '$tp' and '$bs' (progress $progress)"
        else
            fail_with "$flag prints one deprecation line naming '$tp' and '$bs' (progress $progress)" \
                "a deprecated switch prints exactly one stderr line pointing at -tp and a unit on -bs; it is a behavioural notice, so --disable-progress does not suppress it" \
                'adapt_to_command_line_options() in ltl (deprecation notices)' "$CONTRACT_D5" \
                "matching lines: $n" "stderr: $(head -3 "$TMP_DIR/$tag/err.txt" | tr '\n' '~')"
        fi
    done
    run_in "dep${flag}-same" "${COMMON[@]}" -ni "$flag" ${tp} -bs 1 "$THREE"
    n=$(grep -cE "^Warning: ${flag}/--[a-z]+ is deprecated" "$TMP_DIR/dep${flag}-same/err.txt" || true)
    if [[ "$(cat "$TMP_DIR/dep${flag}-same/rc.txt")" == 0 && "$n" == 1 ]]; then
        pass_with "$flag ${tp} runs, with the notice"
    else
        fail_with "$flag ${tp} runs, with the notice" \
            "a deprecated switch beside a -tp of the same precision runs, and still prints its notice" \
            'adapt_to_command_line_options() in ltl' "$CONTRACT_D5" "exit: $(cat "$TMP_DIR/dep${flag}-same/rc.txt")" "notice lines: $n"
    fi
done
fi

if scenario_wanted deprecation/switch-jobs; then
current_scenario="deprecation/switch-jobs"
for row in "-ms||0.12" "-ms|-bs 100|0.10" "-s|-bs 30|30.00"; do
    IFS='|' read -r flag bs want <<< "$row"
    # shellcheck disable=SC2086
    run_in "job$flag${bs// /}" "${COMMON[@]}" -ni -V benchmark-data "$flag" $bs "$THREE"
    got=$(benchmark_row "$TMP_DIR/job$flag${bs// /}" bucket_size_seconds)
    if [[ "$got" == "$want" ]]; then
        pass_with "$flag ${bs:-(no -bs)} keeps its width: $want s"
    else
        fail_with "$flag ${bs:-(no -bs)} keeps its width: $want s" \
            "while deprecated, -s and -ms keep their jobs: a bare -bs number and the default width are read in their unit" \
            'adapt_to_command_line_options() and adapt_to_terminal_settings() in ltl' "$CONTRACT_D5" "bucket_size_seconds: $got"
    fi
done
fi

# ---------------------------------------------------------------------------
# Rejections (D3, D12): each exits non-zero having run nothing
# ---------------------------------------------------------------------------
# run_rejected TAG PATTERN LABEL ASSERTS CONTRACT ARGS... — runs ltl expecting
# a non-zero exit, the PATTERN on stderr and no timeline row on stdout.
run_rejected() {
    local tag="$1" pattern="$2" label="$3" asserts="$4" contract="$5"
    shift 5
    local dir="$TMP_DIR/$tag" rc
    mkdir -p "$dir"
    set +e
    ( cd "$dir" && "$LTL" "$@" > out.txt 2> err.txt )
    rc=$?
    set -e
    if ! assert_no_runtime_warnings "$dir/err.txt" "$current_scenario/$tag"; then
        fail=$((fail + 1))
        failures+=("$current_scenario :: runtime warnings ($tag)")
    fi
    if [[ "$rc" != 0 ]] && grep -qE -- "$pattern" "$dir/err.txt" && ! grep -qE '^ ?[0-9]{4}-[0-9]{2}-[0-9]{2} ' "$dir/out.txt"; then
        pass_with "$label"
    else
        fail_with "$label" "$asserts" 'adapt_to_command_line_options() in ltl (-tp resolution)' "$contract" \
            "exit: $rc" "stderr: $(head -3 "$dir/err.txt" | tr '\n' '~')"
    fi
}

if scenario_wanted rejection/values; then
current_scenario="rejection/values"
for v in bogus h ns; do
    run_rejected "rej-$v" "Invalid timestamp precision '$v'\. Valid values: m, s, ms, us\$" \
        "-tp $v exits non-zero listing the accepted values" \
        "a value that is not one of the four precision steps is a usage error naming the accepted values, and the run does nothing" \
        "$CONTRACT_D3" "${COMMON[@]}" -ni -tp "$v" "$THREE"
done
fi

if scenario_wanted rejection/switch-conflict; then
current_scenario="rejection/switch-conflict"
for pair in "-s|ms|-s/--seconds" "-ms|s|-ms/--milliseconds"; do
    IFS='|' read -r flag tp name <<< "$pair"
    run_rejected "conf$flag" "${name} and -tp ${tp} ask for different timestamp precisions" \
        "$flag -tp $tp exits non-zero naming both" \
        "a deprecated switch beside a -tp of another precision is a usage error naming both, and the run does nothing" \
        "$CONTRACT_D5" "${COMMON[@]}" -ni "$flag" -tp "$tp" "$THREE"
done
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
