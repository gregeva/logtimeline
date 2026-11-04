#!/usr/bin/env bash
# notice-sets.sh <outdir>
#
# The notice surfaces in the conditions of D1 amended (feature doc § 12.7),
# drawn by the notice prototype (../412-notice-surfaces, show.pl) with the
# notice roles of palettes/n1.tsv (notice-design.py). The browser runs live
# in a tmux pane of 120 by 50 and is captured as it is seen, so the layered
# ask over the dimmed browser is drawn as a terminal draws it:
#   1  the browser, All tab, the first notice's detail
#   2  the guidance tab, the detail with its duration histogram
#   3  Enter on it: the options as an ask layered over the dimmed browser
#   4  the panel of seven notices, headed, and an ask with its countdown
#      (drawn piped, the surfaces only)
# Variants, for each background:
#   dark   today   today's dark style (also what an unknown background draws)
#          set     the dark set
#   light  today   today's light style
#          tone    the light set, category colours by tone (today's, moved
#                  in lightness)
#          gradient the light set, category colours from t4's light gradients
#          unknown today's dark style, as drawn when the background is not known
# Writes <outdir>/<bg>/<page>-<variant>.ans and <outdir>/<bg>/index.tsv.
set -euo pipefail
out=${1:?usage: notice-sets.sh <outdir>}
here=$(cd "$(dirname "$0")" && pwd)
proto=$(cd "$here/../412-notice-surfaces" && pwd)
pal=$here/palettes/n1.tsv
W=120 H=50

args() {  # variant -> show.pl options
    case $1 in
        dark-today)     echo "--bg dark" ;;
        dark-set)       echo "--bg dark --set $pal" ;;
        light-today)    echo "--bg light" ;;
        light-tone)     echo "--bg light --set $pal --categories tone" ;;
        light-gradient) echo "--bg light --set $pal --categories gradient" ;;
        light-unknown)  echo "--bg dark" ;;
    esac
}

live() {  # variant file keys...: the browser in a tmux pane, the keys sent, the pane captured
    local v=$1 f=$2; shift 2
    local s=ns$$ i
    tmux new-session -d -s $s -x $W -y $H -c "$proto" "perl show.pl browser --input heavy --seconds 300 $(args "$v"); sleep 60"
    for i in $(seq 1 60); do tmux capture-pane -p -t $s | grep -q '╭─ notices' && break; sleep 0.25; done
    for k in "$@"; do tmux send-keys -t $s "$k"; sleep 0.8; done
    sleep 0.5
    tmux capture-pane -e -p -t $s > "$f"
    tmux kill-session -t $s 2>/dev/null || true
}

surface() { awk '/╭/ { on = 1 } on { print } /╰/ { on = 0 }'; }

piped() {  # variant file: the panel and an ask, the surfaces only
    local v=$1 f=$2
    {
        echo
        perl "$proto/show.pl" panel --input typical --headed --width $W --height $H $(args "$v") | surface
        echo
        perl "$proto/show.pl" ask --input pattern --form modal --placement inline --width $W --height $H $(args "$v") | surface
    } > "$f"
}

for bg in dark light; do
    mkdir -p "$out/$bg"
    if [[ $bg == dark ]]; then variants="today set"; else variants="today tone gradient unknown"; fi
    for v in $variants; do
        live "$bg-$v" "$out/$bg/1-$v.ans"
        live "$bg-$v" "$out/$bg/2-$v.ans" 7
        live "$bg-$v" "$out/$bg/3-$v.ans" 7 Enter
        piped "$bg-$v" "$out/$bg/4-$v.ans"
    done
    printf '%s\n' "1	the browser, All tab" "2	the guidance tab: a detail with its histogram" \
        "3	its options: an ask layered over the dimmed browser" "4	the panel, headed, and an ask with its countdown" > "$out/$bg/index.tsv"
done
ls "$out"/*/
