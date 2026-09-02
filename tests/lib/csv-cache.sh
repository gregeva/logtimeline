#!/usr/bin/env bash
# csv-cache.sh — shared producer + cache helper for CSV-emitting test harnesses.
#
# Sourced by validate-csv-output.sh (#223) and validate-statistics.sh (#224).
# Eliminates duplicate `ltl … -o` invocations across harnesses by caching
# produced CSVs under deterministic, scenario-derived filenames.
#
# Public functions:
#   csv_cache_produce SCENARIO LOGFILE OPTIONS LOG_SHORTHAND
#       Ensures cached MESSAGES + STATS CSVs exist for the given inputs.
#       Cache hit → returns immediately.
#       Cache miss → runs `ltl … -o` in a tempdir, renames the produced
#       CSVs to the deterministic cache names, then returns.
#       On success, exports:
#           CSV_CACHE_MESSAGES — absolute path to cached MESSAGES CSV
#           CSV_CACHE_STATS    — absolute path to cached STATS CSV
#       Returns non-zero on ltl failure or missing produced files.
#
#   csv_cache_options_shorthand OPTIONS
#       Pure function: prints the kebab-case shorthand for an options string.
#       Strips `-o` (it's always present), collapses whitespace, joins on `-`.
#       Example: `-bs 240 -n 25 -mdm raw -bdm raw` → `bs240-n25-mdm-raw-bdm-raw`
#
#   csv_cache_filename SCENARIO OPTIONS LOG_SHORTHAND KIND
#       Pure function: prints the deterministic cache filename for one CSV.
#       KIND is `messages` or `stats`.
#
#   csv_cache_logfile_shorthand LOGFILE_PATH
#       Pure function: prints the kebab-case shorthand for a logfile path.
#       Takes the basename, strips extension, lowercases, replaces `_` and
#       `.` with `-`. Example:
#       `logs/AccessLogs/ApacheHTTP2Server-access_log-Windchill_Navigate.2026-01-25.log`
#       → `apachehttp2server-access-log-windchill-navigate-2026-01-25`
#
#   csv_cache_maybe_cleanup
#       Calls cleanup-test-artifacts.sh iff $CI is unset (standalone mode).
#       Harnesses call this at end of run. Under CI=1 the orchestrator is
#       responsible for cleanup.
#
# Orchestration signal:
#   CI=1 (or any non-empty value)  → orchestrated mode, leave cache in place
#   CI unset / empty               → standalone mode, clean up at end of run
#
# The `CI` env var is the industry-standard signal (set by GitHub Actions,
# GitLab CI, CircleCI, Jenkins, Travis, etc.) — harnesses running under any
# CI get the right behavior automatically, and developers running the local
# orchestrator script set the same well-known variable.

# This file is meant to be sourced, not executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "ERROR: csv-cache.sh is a library; source it, do not execute it." >&2
    exit 2
fi

# Resolve once at source-time so callers can change directory freely.
_CSV_CACHE_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Runtime-warning cleanliness check (HARNESS-DESIGN.md section Runtime-warning
# cleanliness): performed once here at the point of capture so the harnesses
# that consume cached CSVs don't re-implement it.
# shellcheck source=tests/lib/runtime-warnings.sh
source "$_CSV_CACHE_LIB_DIR/runtime-warnings.sh"
_CSV_CACHE_TESTS_DIR="$(cd "$_CSV_CACHE_LIB_DIR/.." && pwd)"
_CSV_CACHE_REPO_DIR="$(cd "$_CSV_CACHE_TESTS_DIR/.." && pwd)"

# shellcheck source=logs-dir.sh
source "$_CSV_CACHE_LIB_DIR/logs-dir.sh"
_CSV_CACHE_DIR="$_CSV_CACHE_TESTS_DIR/.artifacts/csv"
_CSV_CACHE_RULES_DIR="$_CSV_CACHE_TESTS_DIR/csv-output/rules"

# How long a cached artifact may be read back. A CI=1 chain runs its harnesses
# minutes apart, which is the sharing this cache exists for; an hour keeps that
# and still refuses anything left over from an earlier working session. A CI=1
# run deliberately skips the cleanup so the next harness can reuse its capture,
# so without an expiry a session that never ran cleanup-test-artifacts.sh
# leaves its artifacts to be read back indefinitely — which is what happened:
# forty artifacts three days old validated 21 of 23 scenarios against an ltl
# that predated two of the columns the contract had since gained, and both
# harnesses failed against output no version of the tool would produce today
# (#448). Overridable so the harness can put the rule itself under test.
_CSV_CACHE_MAX_AGE_MINUTES="${CSV_CACHE_MAX_AGE_MINUTES:-60}"
_CSV_CACHE_CLEANUP="$_CSV_CACHE_TESTS_DIR/cleanup-test-artifacts.sh"
_CSV_CACHE_LTL="$_CSV_CACHE_REPO_DIR/ltl"

# Pure: produce the kebab-case shorthand for an options string.
csv_cache_options_shorthand() {
    local opts="$*"
    # Strip the trailing `-o` (always present; never starts the string).
    opts="${opts% -o}"
    opts="${opts%-o}"
    # Collapse runs of whitespace into single spaces, trim ends.
    opts="$(echo "$opts" | tr -s '[:space:]' ' ')"
    opts="${opts# }"; opts="${opts% }"
    # Join tokens with `-`, drop the leading `-` on flag tokens so we get
    # `bs240-n25` not `-bs-240--n-25`.
    local out=""
    local first=1
    local token
    for token in $opts; do
        # Drop a single leading `-` from flag tokens (`-bs` → `bs`).
        # Leave numeric/value tokens untouched.
        if [[ "$token" =~ ^- ]]; then
            token="${token#-}"
            token="${token#-}"  # also handle `--long-flag`
        fi
        if [[ $first -eq 1 ]]; then
            out="$token"
            first=0
        else
            out="$out-$token"
        fi
    done
    printf '%s' "$out"
}

# Pure: kebab-case shorthand for a logfile path.
csv_cache_logfile_shorthand() {
    local path="$1"
    local base
    base="$(basename "$path")"
    # Strip last extension.
    base="${base%.*}"
    # Lowercase.
    base="$(echo "$base" | tr '[:upper:]' '[:lower:]')"
    # Replace `_` and `.` with `-`.
    base="$(echo "$base" | tr '_.' '--')"
    # Collapse runs of `-`.
    base="$(echo "$base" | tr -s '-')"
    printf '%s' "$base"
}

# The sidecar recording which CSV-emitting code produced an artifact.
csv_cache_signature_path() {
    local msg_path="$1"
    printf '%s__csv-signature.txt' "${msg_path%__messages.csv}"
}

# A digest of everything that decides what the CSV files contain: the subs of
# ltl dedicated to CSV, the CSV-writing lines of the subs that write one, and
# the column-rule spec the validators read (a column added to the tool lands in
# both in the same commit, so the spec is a second, independent witness).
#
# Deliberately NOT the whole of ltl: an edit anywhere in the tool would then
# throw the cache away, and the regeneration cost would fall on every session
# that touches the timeline or the summary table. What this does not see — a
# value computed further upstream and then written into a column — is covered
# by the validity period above rather than by this digest.
_CSV_CACHE_SIGNATURE=""
csv_cache_ltl_signature() {
    if [[ -z "$_CSV_CACHE_SIGNATURE" ]]; then
        local computed
        computed="$( "${PERL:-perl}" -e '
            use Digest::MD5 qw(md5_hex);
            my ($ltl, $rules_dir) = @ARGV;
            open my $fh, "<", $ltl or die "csv-cache: cannot read $ltl: $!\n";
            my $src = do { local $/; <$fh> };
            close $fh;
            my @parts;
            while ($src =~ /^(sub (\w+) \{.*?^\})$/msg) {
                my ($body, $name) = ($1, $2);
                if ($name =~ /csv|aggregate/i) { push @parts, $body; next }
                my @lines = grep { /\$csv\b|\$csv_fh\b|\$csv->|csv_columns|csv_headers|csv_prefix/ }
                            split /\n/, $body;
                push @parts, join( "\n", @lines ) if @lines;
            }
            die "csv-cache: no CSV-emitting code found in $ltl\n" unless @parts;
            my @rules = sort ( glob( "$rules_dir/*.tsv" ), glob( "$rules_dir/../../aggregate-export/rules/*.tsv" ) );
            die "csv-cache: no column rules found under $rules_dir\n" unless @rules;
            for my $rule (@rules) {
                open my $rh, "<", $rule or die "csv-cache: cannot read $rule: $!\n";
                push @parts, do { local $/; <$rh> };
                close $rh;
            }
            print md5_hex( join( "\n\n", @parts ) );
        ' "$_CSV_CACHE_LTL" "$_CSV_CACHE_RULES_DIR" )" || return 1
        [[ -n "$computed" ]] || return 1
        _CSV_CACHE_SIGNATURE="$computed"
    fi
    printf '%s' "$_CSV_CACHE_SIGNATURE"
}

# Age of a file in whole seconds.
_csv_cache_file_age_seconds() {
    "${PERL:-perl}" -e 'my @s = stat($ARGV[0]) or die "csv-cache: cannot stat $ARGV[0]\n";
                        printf "%d", time - $s[9];' "$1"
}

# Why a cached artifact may not be read back, on stdout. Exit 0 with a reason
# when it is stale, 1 when it may be reused, 2 when the question could not be
# answered — which is treated as stale by the caller, never as fresh.
csv_cache_staleness_reason() {
    local msg_path="$1"
    local age_seconds max_seconds sig_path stored current

    age_seconds="$(_csv_cache_file_age_seconds "$msg_path")" || return 2
    max_seconds=$(( _CSV_CACHE_MAX_AGE_MINUTES * 60 ))
    if (( age_seconds > max_seconds )); then
        printf 'captured %d minutes ago, past the %d-minute validity period' \
            $(( age_seconds / 60 )) "$_CSV_CACHE_MAX_AGE_MINUTES"
        return 0
    fi

    sig_path="$(csv_cache_signature_path "$msg_path")"
    if [[ ! -s "$sig_path" ]]; then
        printf 'captured without a record of the CSV-emitting code that produced it'
        return 0
    fi
    stored="$(cat "$sig_path")"
    current="$(csv_cache_ltl_signature)" || return 2
    if [[ "$stored" != "$current" ]]; then
        printf 'the CSV-emitting code in ltl or the column rules changed after it was captured'
        return 0
    fi
    return 1
}

# Pure: deterministic cache filename for one CSV.
csv_cache_filename() {
    local scenario="$1" options="$2" log_shorthand="$3" kind="$4"
    local options_short
    options_short="$(csv_cache_options_shorthand "$options")"
    printf '%s_%s_%s__%s.csv' "$scenario" "$options_short" "$log_shorthand" "$kind"
}

# Internal: locate the produced MESSAGES/STATS CSV in a directory.
_csv_cache_find_produced() {
    local dir="$1" kind_marker="$2"
    ls "$dir"/*-LTL-"$kind_marker"-*.csv 2>/dev/null | head -1
}

# Ensure cached CSVs exist; run `ltl` only on cache miss. Exports
# CSV_CACHE_MESSAGES and CSV_CACHE_STATS on success, plus CSV_CACHE_STDOUT:
# the producing run requests -V csv-output, so the run's own precision
# contract is captured alongside its CSVs and no consumer needs a second
# identical ltl run to read it (the section is stdout-only; the CSVs are
# byte-identical with and without it).
csv_cache_produce() {
    local scenario="$1" logfile="$2" options="$3" log_shorthand="$4"

    # Refuse stray -o in the options string. The helper owns -o emission;
    # callers must supply options that exclude it. A stray -o here causes
    # the resulting ltl command to receive `-o -o <logfile>`, which is
    # subtly wrong in ways that affect output stability (see commit log
    # for scenarios.tsv hygiene fix).
    case " $options " in
        *" -o "*|*" -o")
            echo "csv-cache: refuse to invoke ltl with stray -o in options for scenario=$scenario" >&2
            echo "           options: $options" >&2
            echo "           scenarios.tsv must omit -o; the helper appends it itself" >&2
            return 2
            ;;
    esac

    local msg_name stats_name
    msg_name="$(csv_cache_filename "$scenario" "$options" "$log_shorthand" messages)"
    stats_name="$(csv_cache_filename "$scenario" "$options" "$log_shorthand" stats)"

    local msg_path="$_CSV_CACHE_DIR/$msg_name"
    local stats_path="$_CSV_CACHE_DIR/$stats_name"
    local stdout_path="${msg_path%__messages.csv}__stdout.txt"
    local aggregate_path="${msg_path%__messages.csv}__aggregate.yaml"
    local sig_path
    sig_path="$(csv_cache_signature_path "$msg_path")"

    if [[ -s "$msg_path" && -s "$stats_path" && -s "$stdout_path" && -s "$aggregate_path" ]]; then
        local stale_reason stale_rc
        stale_reason="$(csv_cache_staleness_reason "$msg_path")"
        stale_rc=$?
        if [[ $stale_rc -eq 1 ]]; then
            export CSV_CACHE_MESSAGES="$msg_path"
            export CSV_CACHE_STATS="$stats_path"
            export CSV_CACHE_STDOUT="$stdout_path"
            export CSV_CACHE_AGGREGATE="$aggregate_path"
            return 0
        fi
        # Anything but a clean "fresh" means the artifact is produced again.
        # The warning is the point: a cache that silently serves the wrong
        # thing is how three-day-old output validated a tool it never ran.
        if [[ $stale_rc -eq 2 ]]; then
            stale_reason="its validity could not be determined"
        fi
        echo "csv-cache: WARNING stale cache for scenario=$scenario — $stale_reason; refreshing" >&2
    fi

    mkdir -p "$_CSV_CACHE_DIR"

    local abs_log
    abs_log="$(resolve_log_path "$logfile")"

    if [[ ! -f "$abs_log" ]]; then
        echo "csv-cache: logfile missing: $abs_log" >&2
        return 1
    fi

    local tmp_dir
    tmp_dir="$(mktemp -d)"
    local rc=0
    (
        cd "$tmp_dir"
        # shellcheck disable=SC2086  # word-splitting on $options is intentional
        "$_CSV_CACHE_LTL" --disable-progress -ni -V csv-output $options -o "$abs_log" >"$tmp_dir/ltl.stdout" 2>"$tmp_dir/ltl.stderr"
    )
    rc=$?

    if [[ $rc -ne 0 ]]; then
        echo "csv-cache: ltl exit=$rc scenario=$scenario" >&2
        sed 's/^/        /' "$tmp_dir/ltl.stderr" >&2
        rm -rf "$tmp_dir"
        return $rc
    fi

    if ! assert_no_runtime_warnings "$tmp_dir/ltl.stderr" "csv-cache scenario=$scenario"; then
        rm -rf "$tmp_dir"
        return 1
    fi

    local produced_msg produced_stats produced_aggregate
    produced_msg="$(_csv_cache_find_produced "$tmp_dir" MESSAGES)"
    produced_stats="$(_csv_cache_find_produced "$tmp_dir" STATS)"
    produced_aggregate="$(ls "$tmp_dir"/*-LTL-AGGREGATE.yaml 2>/dev/null | head -1)"

    if [[ -z "$produced_msg" || -z "$produced_stats" || -z "$produced_aggregate" ]]; then
        echo "csv-cache: ltl ran but produced files missing scenario=$scenario messages=${produced_msg:-MISSING} stats=${produced_stats:-MISSING} aggregate=${produced_aggregate:-MISSING}" >&2
        rm -rf "$tmp_dir"
        return 1
    fi

    mv "$produced_msg" "$msg_path"
    mv "$produced_stats" "$stats_path"
    mv "$produced_aggregate" "$aggregate_path"
    mv "$tmp_dir/ltl.stdout" "$stdout_path"
    rm -rf "$tmp_dir"

    # Recorded with the artifact, so a later run can tell whether the code that
    # produced it is still the code in the tree.
    if ! csv_cache_ltl_signature > "$sig_path"; then
        echo "csv-cache: could not record the CSV signature for scenario=$scenario" >&2
        rm -f "$sig_path"
        return 1
    fi

    export CSV_CACHE_MESSAGES="$msg_path"
    export CSV_CACHE_STATS="$stats_path"
    export CSV_CACHE_STDOUT="$stdout_path"
    export CSV_CACHE_AGGREGATE="$aggregate_path"
    return 0
}

# Call at end of harness run. Cleans the artifact tree iff running standalone.
csv_cache_maybe_cleanup() {
    if [[ -n "${CI:-}" ]]; then
        return 0
    fi
    if [[ -x "$_CSV_CACHE_CLEANUP" ]]; then
        "$_CSV_CACHE_CLEANUP"
    fi
}
