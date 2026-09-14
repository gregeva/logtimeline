#!/usr/bin/env bash
# Wiki sync: publishes the docs/ sources to the GitHub wiki, and verifies that
# what is published matches them.
#
# The wiki is not a second copy that could drift. Each page is a byte-for-byte
# copy of its docs/ source; docs/ is the source of truth and the wiki is
# overwritten from it at every release. The page map below is the single place
# that pairing is written down — the release procedure runs this script rather
# than restating the map, and tests/validate-explain.sh reads the map from here.
#
# Usage:
#   ./build/sync-wiki.sh verify [--version X.Y.Z]   compare published against docs/ (read-only)
#   ./build/sync-wiki.sh publish --version X.Y.Z    overwrite the wiki from docs/ and push
#   ./build/sync-wiki.sh map                        print the source-to-page map
#
# "verify" exits non-zero naming every page that is behind its source, and is
# what makes a skipped publish visible: the release is not finished while it
# fails. It needs read access to the wiki repository and nothing else.

set -euo pipefail

WIKI_URL="https://github.com/gregeva/logtimeline.wiki.git"

# The clone directory, set by clone_wiki and removed by the EXIT trap. It is
# file-scope so the trap can see it whatever function is running when the
# script exits.
CLONE_DIR=""

# The map: one "<source> <page>" pair per line. Adding a docs/ file that the
# wiki should carry means adding its line here and nowhere else.
WIKI_PAGE_MAP="\
docs/usage.md Home.md
docs/purpose.md Purpose-and-Design-Philosophy.md
docs/explain/statistics.md Statistics-Reference.md
docs/explain/heatmap.md Heatmap-Reference.md
docs/explain/histogram.md Histogram-Reference.md
docs/explain/classification.md Classification-Reference.md
docs/explain/techniques.md Analysis-Techniques-Reference.md"

die() { echo "[error] $*" >&2; exit 1; }

usage() {
    cat >&2 <<USAGE
Usage: ./build/sync-wiki.sh <command> [options]

  verify [--version X.Y.Z]   Clone the wiki and compare every page against its
                             docs/ source. Read-only. Exits non-zero, naming each
                             page whose content differs, each page that is absent,
                             and (with --version) a wiki whose last sync commit
                             does not name that version.
  publish --version X.Y.Z    Overwrite every page from its docs/ source, commit
                             as "Sync wiki docs from vX.Y.Z" and push. Pushes
                             nothing when no page changed.
  map                        Print the source-to-page map, one "<source> <page>"
                             pair per line.
USAGE
    exit 1
}

require_repo_root() {
    [ -f ltl ] && [ -d build ] || die "run from the repository root"
    command -v git >/dev/null 2>&1 || die "git not found on PATH"
}

# Every source the map names exists. A missing source is a broken map, and it
# is reported before any clone so the failure does not look like a network one.
require_sources() {
    local src page missing=0
    while read -r src page; do
        [ -n "$src" ] || continue
        if [ ! -f "$src" ]; then
            echo "[error] the map names '$src' ($page), which does not exist" >&2
            missing=$((missing + 1))
        fi
    done <<< "$WIKI_PAGE_MAP"
    [ "$missing" -eq 0 ] || die "$missing mapped source(s) missing — fix the map in build/sync-wiki.sh"
}

# Clones into a fresh temporary directory and echoes nothing: the path is
# CLONE_DIR, removed on exit however the script ends.
clone_wiki() {
    CLONE_DIR="$(mktemp -d)"
    trap 'rm -rf "$CLONE_DIR"' EXIT
    git clone --quiet "$WIKI_URL" "$CLONE_DIR" \
        || die "could not clone the wiki from $WIKI_URL — check network access and that the wiki exists"
}

cmd_map() {
    [ $# -eq 0 ] || usage
    printf '%s\n' "$WIKI_PAGE_MAP"
}

cmd_verify() {
    local version="" clone src page behind=0 checked=0
    while [ $# -gt 0 ]; do
        case "$1" in
            --version) [ $# -ge 2 ] || usage; version="${2#v}"; shift 2 ;;
            *) usage ;;
        esac
    done

    require_sources
    clone_wiki
    clone="$CLONE_DIR"

    while read -r src page; do
        [ -n "$src" ] || continue
        checked=$((checked + 1))
        if [ ! -f "$clone/$page" ]; then
            echo "[behind] $page is absent from the wiki (source: $src)"
            behind=$((behind + 1))
        elif ! diff -q "$src" "$clone/$page" >/dev/null; then
            echo "[behind] $page differs from $src ($(diff "$src" "$clone/$page" | grep -c '^[<>]') changed line(s))"
            behind=$((behind + 1))
        else
            echo "[ok] $page matches $src"
        fi
    done <<< "$WIKI_PAGE_MAP"

    # The content check above passes whenever docs/ has not moved since the last
    # publish, which is exactly the state a skipped release leaves when that
    # release changed no docs. Naming the version asserts the stronger thing:
    # that a publish ran FOR this release.
    if [ -n "$version" ]; then
        local subject
        subject="$(git -C "$clone" log -1 --format=%s)"
        if [ "$subject" = "Sync wiki docs from v$version" ]; then
            echo "[ok] the wiki's last commit is the v$version sync"
        else
            echo "[behind] the wiki's last commit is '$subject', not 'Sync wiki docs from v$version'"
            behind=$((behind + 1))
        fi
    fi

    [ "$checked" -gt 0 ] || die "the page map is empty — nothing was verified"

    if [ "$behind" -gt 0 ]; then
        echo ""
        die "$behind of $checked check(s) behind — run ./build/sync-wiki.sh publish --version X.Y.Z"
    fi
    echo ""
    echo "[ok] all $checked check(s) current"
}

cmd_publish() {
    local version="" clone src page staged=0
    while [ $# -gt 0 ]; do
        case "$1" in
            --version) [ $# -ge 2 ] || usage; version="${2#v}"; shift 2 ;;
            *) usage ;;
        esac
    done
    [ -n "$version" ] || die "publish needs --version X.Y.Z (it names the sync commit)"

    require_sources
    clone_wiki
    clone="$CLONE_DIR"

    while read -r src page; do
        [ -n "$src" ] || continue
        cp "$src" "$clone/$page"
        git -C "$clone" add "$page"
        staged=$((staged + 1))
    done <<< "$WIKI_PAGE_MAP"

    if git -C "$clone" diff --cached --quiet; then
        echo "[ok] every one of the $staged page(s) already matches its source — nothing to push"
        return 0
    fi

    echo "[info] pages changed by this sync:"
    git -C "$clone" diff --cached --name-only | sed 's/^/  /'

    git -C "$clone" commit --quiet -m "Sync wiki docs from v$version"
    git -C "$clone" push --quiet \
        || die "the commit was made but the push failed — check write access to the wiki"
    echo "[ok] published $staged page(s) as 'Sync wiki docs from v$version'"
}

main() {
    [ $# -ge 1 ] || usage
    require_repo_root
    local command="$1"; shift
    case "$command" in
        verify)  cmd_verify "$@" ;;
        publish) cmd_publish "$@" ;;
        map)     cmd_map "$@" ;;
        *)       usage ;;
    esac
}

main "$@"
