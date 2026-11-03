#!/usr/bin/env bash
# wt-e-view.sh <out>/<palette> <scheme>...
#
# Shows a candidate to the architect in Windows Terminal: one window, a tab
# per scheme (Ctrl+Tab between them), 190 by 51. Each tab shows the
# palette's swatch card (e-swatch.py) and then the eight runs of
# e-outputs.sh a page at a time, as the captures read them. A key flips the
# same page between today's colours (background unknown, basic.ans) and the
# set for the scheme's class (dark.ans or light.ans, the class from
# results/windows-terminal/schemes.txt).
#
# Keys: Space or Right the next page, b or Left the previous; n and p the
# next and previous run; t today or the set; q closes the tab.
#
# Run from Git Bash on the Windows host, after e-outputs.sh has written
# <out>/<palette>; it writes the swatch card into <out>/<palette>/palette/.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)

if [[ ${1:-} != --tab ]]; then
    dir=$(cd "$1" && pwd); shift
    (( $# )) || { echo "usage: wt-e-view.sh <out>/<palette> <scheme>..." >&2; exit 2; }
    PYTHONUTF8=1 PYTHONDONTWRITEBYTECODE=1 python3 "$here/e-swatch.py" \
        "$here/palettes/$(basename "$dir").tsv" "$dir/palette"
    bash=$(cygpath -w /usr/bin/bash.exe)
    args=(-w new --size 190,51 --pos 0,0)
    first=1
    for scheme in "$@"; do
        cls=$(awk -v s="$scheme" 'NR > 3 && substr($0, 1, 20) == sprintf("%-20s", s) { print $NF }' \
            "$here/results/windows-terminal/schemes.txt")
        [[ $cls == dark || $cls == light ]] || { echo "no class for scheme: $scheme" >&2; exit 2; }
        (( first )) || args+=(';' new-tab)
        args+=(--title "$scheme: $(basename "$dir")" --suppressApplicationTitle --colorScheme "$scheme"
               "$bash" "$(cygpath -w "$here/wt-e-view.sh")" --tab "$(cygpath -m "$dir")" "$cls" "$scheme")
        first=0
    done
    wt.exe "${args[@]}"
    exit
fi

PATH=/usr/bin:$PATH
dir=$2 cls=$3 scheme=$4
/c/Windows/System32/chcp.com 65001 > /dev/null
runs=(palette access-heatmap access-latency levels udm help explain error progress-pause)
rows=51
body=$(( rows - 1 ))
r=0 page=0 set=1

draw() {
    local which=$([[ $set == 1 ]] && echo "$cls" || echo basic)
    local file=$dir/${runs[r]}/$which.ans
    local n; n=$(wc -l < "$file")
    local pages=$(( (n + body - 1) / body ))
    (( page < pages )) || page=$(( pages - 1 ))
    (( page >= 0 )) || page=0
    local first=$(( page * body + 1 )) last=$(( (page + 1) * body ))
    printf '\033[0m\033[H\033[2J'
    sed -n "${first},${last}{s/\r\$//;p}" "$file" | head -c -1
    local what=$([[ $set == 1 ]] && echo "THE $cls SET" || echo "TODAY (basic colours)")
    printf '\033[%d;1H\033[0m\033[7m %s (%s)  |  %s  |  run %d/%d %s  |  page %d/%d  |  Space/b page   n/p run   t today/set   q quit \033[0m' \
        "$rows" "$scheme" "$cls" "${what^^}" $(( r + 1 )) ${#runs[@]} "${runs[r]}" $(( page + 1 )) "$pages"
}

printf '\033[?25l'
trap 'printf "\033[0m\033[?25h"' EXIT
while :; do
    draw
    IFS= read -rsn1 k || exit 0
    if [[ $k == $'\e' ]]; then IFS= read -rsn2 -t 0.05 k || true; fi
    case $k in
        ' '|'[C') page=$(( page + 1 )) ;;
        b|'[D') page=$(( page - 1 )) ;;
        n) r=$(( (r + 1) % ${#runs[@]} )) page=0 ;;
        p) r=$(( (r - 1 + ${#runs[@]}) % ${#runs[@]} )) page=0 ;;
        t) set=$(( 1 - set )) ;;
        q) exit 0 ;;
    esac
done
