#!/usr/bin/env bash
# Lists every record that mentions the surfaces a piece of work touches, so the
# owning records are found by search rather than taken from an issue's links
# (CLAUDE.md, Before planning). Each record listed is read, or dismissed in the
# feature doc with its reason.
#
# Usage: find-records.sh [--issues] <term> [<term> ...]
#   A term starting with '-' is an option and is matched as written inside a
#   code span (`-g`, `-g 85`, `--group-similar`); any other term (a sub name, a
#   section name, a table name) is matched as a fixed string.
#   --issues also searches open and closed issue bodies through gh.
set -euo pipefail

root=$(git rev-parse --show-toplevel)
search_issues=0
if [[ "${1:-}" == "--issues" ]]; then search_issues=1; shift; fi
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 [--issues] <term> [<term> ...]" >&2
    exit 1
fi

records=()
while IFS= read -r f; do records+=("$f"); done < <(
    cd "$root" && find features docs releases -name '*.md' -type f | sort
)

declare -A hits terms_of
for term in "$@"; do
    if [[ "$term" == -* ]]; then
        patterns=(-e "\`$term\`" -e "\`$term " -e "\`$term," -e "\`$term/" -e "/$term\`" -e "/$term ")
    else
        patterns=(-e "$term")
    fi
    while IFS=: read -r f n; do
        [[ "$n" -gt 0 ]] || continue
        hits[$f]=$(( ${hits[$f]:-0} + n ))
        terms_of[$f]="${terms_of[$f]:-}${terms_of[$f]:+, }$term"
    done < <(cd "$root" && grep -a -c -F "${patterns[@]}" "${records[@]}" 2>/dev/null || true)
done

if [[ ${#hits[@]} -eq 0 ]]; then
    echo "No record mentions: $*"
else
    for f in "${!hits[@]}"; do
        printf '%6d  %s  [%s]\n' "${hits[$f]}" "$f" "${terms_of[$f]}"
    done | sort -rn
fi

if [[ $search_issues -eq 1 ]]; then
    echo
    echo "Issues whose body mentions a term:"
    for term in "$@"; do
        gh search issues --repo "$(gh repo view --json nameWithOwner -q .nameWithOwner)" \
            --match body --limit 50 --json number,title,state \
            -q '.[] | "  #\(.number) \(.state) \(.title)"' -- "$term" 2>/dev/null \
            | sed "s/\$/  [$term]/"
    done | sort -u
fi
