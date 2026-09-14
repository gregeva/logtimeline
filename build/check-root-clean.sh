#!/usr/bin/env bash
# Reports artifacts sitting at depth one of a repository root that .gitignore
# hides, so that a product left behind by an earlier run is visible without
# anyone having to look for it.
#
# Ignoring the run products is right - they must never be committed - but
# "ignored" was also reading as "not worth mentioning", and no other surface in
# the repository tells the two apart. Every surface that reports repository
# state reads git's default non-ignored view, so a file left in the root is
# reported by nothing. This is that surface.
#
# It reports and never removes, moves or truncates anything.
# ./tests/cleanup-test-artifacts.sh is the only sanctioned cleanup.
#
# Usage:
#   ./build/check-root-clean.sh              probe this session's root and the main checkout
#   ./build/check-root-clean.sh <directory>  probe that root only
#   ./build/check-root-clean.sh --quiet      exit code only, no output
#
# Exit: 0 every probed root clean, 1 findings printed, 2 usage error or a root
# that cannot be probed. The session-start sweep discards the exit code; a
# dirty root must never be able to fail a session.

set -uo pipefail

QUIET=0
ROOT_ARG=""

usage() {
    cat >&2 <<'USAGE'
Usage: ./build/check-root-clean.sh [<directory>] [--quiet]

  <directory>   Probe this root only, instead of this session's root and the
                main checkout.
  --quiet       Suppress output; yield the exit code only.

Exit codes: 0 clean, 1 findings reported, 2 usage error or unprobeable root.
USAGE
}

while [ $# -gt 0 ]; do
    case "$1" in
        --quiet)
            QUIET=1
            ;;
        -*)
            echo "[error] unknown option: $1" >&2
            usage
            exit 2
            ;;
        *)
            if [ -n "$ROOT_ARG" ]; then
                echo "[error] only one directory may be given" >&2
                usage
                exit 2
            fi
            ROOT_ARG="$1"
            ;;
    esac
    shift
done

# Entries never reported, by exact basename. Deliberately short and fixed: the
# corpus symlink each worktree carries, and finder state. Anything else a
# developer wants silenced goes in the per-checkout acknowledgement file, where
# it is their decision and visible to them.
EXCLUSIONS=("logs" ".DS_Store")

ACK_FILE=".claude/root-clean-ack.txt"

# The product-shape vocabulary lives here and only here in this script, as the
# labelling table that turns a bare filename into a named class. It is
# presentation: it never decides whether an entry is reported.
label_for() {
    case "$1" in
        *-LTL-AGGREGATE.yaml) echo "aggregate export" ;;
        *-LTL-STATS-*.csv)    echo "STATS CSV" ;;
        *-LTL-MESSAGES-*.csv) echo "MESSAGES CSV" ;;
        ltl-index.csv)        echo "run index" ;;
        nytprof.out)          echo "profile output" ;;
        *)                    echo "untracked, ignored" ;;
    esac
}

# Whole KB or MB, rounded down; bytes below a kilobyte are reported as bytes so
# that a small leftover is not rendered as "0 KB".
human_size() {
    size=$1
    if [ "$size" -ge 1048576 ]; then
        echo "$((size / 1048576)) MB"
    elif [ "$size" -ge 1024 ]; then
        echo "$((size / 1024)) KB"
    else
        echo "$size bytes"
    fi
}

# Whole days, rounded down; under a day reads "today".
human_age() {
    age_seconds=$1
    [ "$age_seconds" -lt 0 ] && age_seconds=0
    days=$((age_seconds / 86400))
    if [ "$days" -lt 1 ]; then
        echo "today"
    elif [ "$days" -eq 1 ]; then
        echo "1 day old"
    else
        echo "$days days old"
    fi
}

# stat differs between BSD and GNU; both are in use against this repository.
file_mtime() {
    stat -f '%m' "$1" 2>/dev/null || stat -c '%Y' "$1" 2>/dev/null
}

file_size() {
    stat -f '%z' "$1" 2>/dev/null || stat -c '%s' "$1" 2>/dev/null
}

# The newest modification time among the root's tracked files, which is what the
# run index is judged stale against. The whole tracked set goes to stat in one
# batch: a checkout carries hundreds of tracked files, and one process per file
# costs seconds at every session start.
newest_tracked_mtime() {
    root=$1
    (
        cd "$root" 2>/dev/null || exit 0
        git ls-files -z 2>/dev/null \
            | xargs -0 stat -f '%m' 2>/dev/null \
            || git ls-files -z 2>/dev/null | xargs -0 stat -c '%Y' 2>/dev/null
    ) | sort -rn | head -1
}

acknowledged() {
    root=$1
    name=$2
    ack="$root/$ACK_FILE"
    [ -f "$ack" ] || return 1
    while IFS= read -r line || [ -n "$line" ]; do
        entry="${line#"${line%%[![:space:]]*}"}"
        entry="${entry%"${entry##*[![:space:]]}"}"
        [ -n "$entry" ] || continue
        case "$entry" in \#*) continue ;; esac
        [ "$entry" = "$name" ] && return 0
    done < "$ack"
    return 1
}

excluded() {
    name=$1
    for ex in "${EXCLUSIONS[@]}"; do
        [ "$name" = "$ex" ] && return 0
    done
    return 1
}

findings=0
index_current=0
report=""

emit() {
    report="${report}$1
"
}

probe_root() {
    root=$1
    root_label=$2
    now=$(date '+%s')
    newest_tracked=""

    # git status quotes a path containing unusual characters; core.quotePath=false
    # keeps a non-ASCII name readable, and the depth-one filter below rejects any
    # entry carrying a separator regardless.
    entries=$(git -C "$root" -c core.quotePath=false status --short --ignored=traditional 2>/dev/null) || return 2

    while IFS= read -r line; do
        [ -n "$line" ] || continue
        [ "${line:0:2}" = "!!" ] || continue
        name="${line:3}"
        # Depth one, exactly: anything with a separator in it is below the root,
        # and a trailing separator is an ignored directory rather than a file.
        case "$name" in */*) continue ;; esac
        excluded "$name" && continue
        acknowledged "$root" "$name" && continue
        [ -f "$root/$name" ] || continue

        size=$(file_size "$root/$name")
        mtime=$(file_mtime "$root/$name")
        [ -n "$size" ] && [ -n "$mtime" ] || continue

        # The run index is rewritten by every run without -ni, so reporting it
        # unconditionally would put the same line in every session start forever.
        # It is listed only when it is older than the newest tracked file in this
        # root, which says the root has been sitting untouched with an index in
        # it; otherwise it is counted in the closing line.
        if [ "$name" = "ltl-index.csv" ]; then
            [ -n "$newest_tracked" ] || newest_tracked=$(newest_tracked_mtime "$root")
            if [ -n "$newest_tracked" ] && [ "$mtime" -ge "$newest_tracked" ]; then
                index_current=$((index_current + 1))
                continue
            fi
        fi

        emit "FINDING: dirty root $root_label: $name ($(label_for "$name"), $(human_size "$size"), $(human_age $((now - mtime))))"
        findings=$((findings + 1))
    done <<EOF
$entries
EOF
    return 0
}

session_root=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -n "$ROOT_ARG" ]; then
    if [ ! -d "$ROOT_ARG" ]; then
        echo "[error] not a directory: $ROOT_ARG" >&2
        exit 2
    fi
    resolved=$(git -C "$ROOT_ARG" rev-parse --show-toplevel 2>/dev/null)
    if [ -z "$resolved" ]; then
        echo "[error] not a git repository: $ROOT_ARG" >&2
        exit 2
    fi
    probe_root "$resolved" "session" || exit 2
else
    if [ -z "$session_root" ]; then
        echo "[error] not a git repository" >&2
        exit 2
    fi
    probe_root "$session_root" "session" || exit 2

    # The main checkout, so that a worktree session sees the backlog sitting one
    # directory away rather than reporting its own root clean. --git-common-dir
    # returns the shared git directory by definition, in a worktree and in the
    # main checkout alike; its parent is the main checkout root.
    common_dir=$(git -C "$session_root" rev-parse --git-common-dir 2>/dev/null)
    if [ -n "$common_dir" ]; then
        case "$common_dir" in
            /*) ;;
            *) common_dir="$session_root/$common_dir" ;;
        esac
        main_root=$(cd "$common_dir/.." 2>/dev/null && pwd -P)
        session_real=$(cd "$session_root" 2>/dev/null && pwd -P)
        if [ -n "$main_root" ] && [ "$main_root" != "$session_real" ]; then
            probe_root "$main_root" "main checkout" || exit 2
        fi
    fi
fi

# The closing line names the sanctioned cleanup, so that the report never leaves
# the reader to invent one. It is printed when there is anything to say: a
# finding, or a current run index folded into its trailing clause. A root with
# neither prints nothing at all, not even a heading.
if [ "$QUIET" -eq 0 ] && { [ "$findings" -gt 0 ] || [ "$index_current" -gt 0 ]; }; then
    printf '%s' "$report"
    closing="nothing is deleted automatically; ./tests/cleanup-test-artifacts.sh is the only sanctioned cleanup"
    if [ "$index_current" -gt 0 ]; then
        closing="$closing ($index_current run index not listed, current)"
    fi
    echo "$closing"
fi

[ "$findings" -gt 0 ] && exit 1
exit 0
