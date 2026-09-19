#!/usr/bin/env bash
# Claude Code SessionStart hook (startup, resume, clear, compact), wired in
# .claude/settings.json. Reconstructs outstanding state from the repository so a
# session whose context begins mid-stream starts from evidence, not memory.
# Everything printed is added to Claude's context.
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

echo "== Outstanding state (session-start hook, $(date '+%Y-%m-%d %H:%M')) =="
current=$(git branch --show-current 2>/dev/null)
echo "branch: $current"

# Everything below compares against local main and local release branches, so
# they are brought up to origin first: a stale local main reports releases as
# unmerged that were merged from another machine. A branch that is checked out,
# or that carries commits no origin branch holds, is reported rather than moved.
git fetch --quiet --prune --tags origin 2>/dev/null

sync_branch() {
    b=$1
    git rev-parse --verify --quiet "refs/remotes/origin/$b" >/dev/null || return 0
    git rev-parse --verify --quiet "refs/heads/$b" >/dev/null || return 0
    [ "$(git rev-parse "$b")" = "$(git rev-parse "origin/$b")" ] && return 0
    behind=$(git log --oneline "$b..origin/$b" | wc -l | tr -d ' ')
    ahead=$(git log --oneline "origin/$b..$b" | wc -l | tr -d ' ')
    if [ "$b" = "$current" ]; then
        # Unpushed work on the checked-out branch is already listed above.
        [ "$behind" != "0" ] && echo "FINDING: $b is checked out and $behind commit(s) behind origin/$b - pull before reading any file"
        return 0
    fi
    if [ "$ahead" != "0" ]; then
        # Commits on local main that an origin release branch already carries
        # are release work, not unpushed work: main is moved back to origin,
        # which loses nothing, instead of being reported as ahead.
        releases=$(git for-each-ref --format='^%(refname)' 'refs/remotes/origin/release/*')
        stray=$(git log --oneline "origin/$b..$b" $releases | wc -l | tr -d ' ')
        if [ "$b" = "main" ] && [ -n "$releases" ] && [ "$stray" = "0" ]; then
            git update-ref "refs/heads/$b" "refs/remotes/origin/$b" \
                && echo "reset main to origin/main: its $ahead local commit(s) are already on a release branch"
            return 0
        fi
        echo "FINDING: $b is $stray commit(s) ahead of origin/$b and of every release branch - unpushed work, not synced here"
        return 0
    fi
    git fetch --quiet origin "$b:$b" 2>/dev/null \
        && echo "synced $b from origin ($behind commit(s))" \
        || echo "FINDING: $b is $behind commit(s) behind origin/$b and would not fast-forward"
}
sync_branch main
for rb in $(git branch --list 'release/*' --format='%(refname:short)' 2>/dev/null); do
    sync_branch "$rb"
done

dirty=$(git status --short 2>/dev/null | head -15)
[ -n "$dirty" ] && { echo "uncommitted:"; echo "$dirty"; }

unpushed=$(git log --oneline '@{u}..' 2>/dev/null | head -10)
[ -n "$unpushed" ] && { echo "unpushed on this branch:"; echo "$unpushed"; }

# What git is hiding, beside what git is showing: an artifact left at depth one
# of this root or of the main checkout that .gitignore covers. Reports only; the
# exit code is discarded so a dirty root can never fail a session.
[ -x ./build/check-root-clean.sh ] && ./build/check-root-clean.sh || true

# A release branch ahead of main is normal while the release is open; it is a
# finding once the release tag exists (the release PR was never merged). The
# open release branch, not main, is the base for new work and the branch that
# merged work is measured against.
base=main
for rb in $(git branch --list 'release/*' --format='%(refname:short)' 2>/dev/null); do
    n=$(git log --oneline "main..$rb" 2>/dev/null | wc -l | tr -d ' ')
    [ "$n" = "0" ] && continue
    if [ -n "$(git tag -l "v${rb#release/}")" ]; then
        echo "FINDING: v${rb#release/} is tagged but main is $n commit(s) behind $rb - unmerged release, fix first"
    else
        echo "$rb in progress: $n commit(s) ahead of main"
    fi
done

unmerged=$(git branch -a --no-merged "$base" --format='%(refname:short)' 2>/dev/null \
    | sed 's|^origin/||' | grep -v -e 'release/' -e '^HEAD$' | sort -u | head -15)
[ -n "$unmerged" ] && { echo "branches not merged to $base:"; echo "$unmerged"; }

prs=$(gh pr list --state open --limit 20 2>/dev/null)
[ -n "$prs" ] && { echo "open PRs:"; echo "$prs"; }

if [ -x ./build/issue-status.sh ]; then
    status=$(./build/issue-status.sh list 2>/dev/null | head -40)
    [ -n "$status" ] && { echo "open issues by status:"; echo "$status"; }
fi

# An issue left on 'status: in review' whose PR already merged is a close-out
# that stopped at the merge: the issue is still open, its label still set and
# its completion comment unwritten, while its code has shipped. Reported here
# because it looks like work in flight and is the opposite.
reviewing=$(gh issue list --label "status: in review" --state open \
    --json number --jq '.[].number' 2>/dev/null | head -10)
for n in $reviewing; do
    merged=$(gh pr list --search "$n in:title" --state merged \
        --json number,title --jq ".[] | select(.title | test(\"#?$n\\\\b\")) | .number" 2>/dev/null | head -1)
    [ -n "$merged" ] && echo "FINDING: #$n is 'in review' but PR #$merged merged: finish workflow.md 4 (close, strip label, completion comment)"
done
echo "== Read CLAUDE.md § At session start before acting on any of this =="
exit 0
