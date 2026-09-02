#!/usr/bin/env bash
# Claude Code SessionStart hook (startup, resume, clear, compact), wired in
# .claude/settings.json. Reconstructs outstanding state from the repository so a
# session whose context begins mid-stream starts from evidence, not memory.
# Everything printed is added to Claude's context.
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

echo "== Outstanding state (session-start hook, $(date '+%Y-%m-%d %H:%M')) =="
echo "branch: $(git branch --show-current 2>/dev/null)"

dirty=$(git status --short 2>/dev/null | head -15)
[ -n "$dirty" ] && { echo "uncommitted:"; echo "$dirty"; }

unpushed=$(git log --oneline '@{u}..' 2>/dev/null | head -10)
[ -n "$unpushed" ] && { echo "unpushed on this branch:"; echo "$unpushed"; }

# A release branch ahead of main is normal while the release is open; it is a
# finding once the release tag exists (the release PR was never merged).
for rb in $(git branch --list 'release/*' --format='%(refname:short)' 2>/dev/null); do
    n=$(git log --oneline "main..$rb" 2>/dev/null | wc -l | tr -d ' ')
    [ "$n" = "0" ] && continue
    if [ -n "$(git tag -l "v${rb#release/}")" ]; then
        echo "FINDING: v${rb#release/} is tagged but main is $n commit(s) behind $rb - unmerged release, fix first"
    else
        echo "$rb in progress: $n commit(s) ahead of main"
    fi
done

unmerged=$(git branch -a --no-merged main 2>/dev/null | grep -v 'release/' | head -15)
[ -n "$unmerged" ] && { echo "branches not merged to main:"; echo "$unmerged"; }

prs=$(gh pr list --state open --limit 20 2>/dev/null)
[ -n "$prs" ] && { echo "open PRs:"; echo "$prs"; }

if [ -x ./build/issue-status.sh ]; then
    status=$(./build/issue-status.sh list 2>/dev/null | head -40)
    [ -n "$status" ] && { echo "open issues by status:"; echo "$status"; }
fi
echo "== Read CLAUDE.md § At session start before acting on any of this =="
exit 0
