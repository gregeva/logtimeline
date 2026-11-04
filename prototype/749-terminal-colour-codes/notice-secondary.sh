#!/usr/bin/env bash
# notice-secondary.sh <outdir>
#
# The notice surfaces' secondary text, two greys side by side (feature doc
# § 12.7): option 1 held at 4.5:1, option 2 at today's look. For each
# background, two pages of the notice prototype (../412-notice-surfaces,
# show.pl --secondary), option 1 on the left, option 2 on the right:
#   page 1  the browser, 25 notices in every category
#   page 2  the panel of seven notices, headed, and an ask with its countdown
# Writes <outdir>/secondary-{dark,light}-{1,2}.ans.
#
# Dark:  option 1 #93969b, Clear Dark's faint default text (#797c81) moved in
#        OKLCH lightness only to 4.5:1 on its background;
#        option 2 #797c81, Clear Dark's faint default text as drawn.
# Light: option 1 #747474, the light set's grey (t4, f244);
#        option 2 244, today's grey.
set -euo pipefail
out=${1:?usage: notice-secondary.sh <outdir>}
here=$(cd "$(dirname "$0")" && pwd)
proto=$here/../412-notice-surfaces
mkdir -p "$out"
W=120 H=50

render() {  # bg secondary page -> stdout, the surfaces only (the backdrop above them left out)
    local bg=$1 sec=$2 page=$3
    if [[ $page == 1 ]]; then
        perl "$proto/show.pl" browser --input heavy --bg "$bg" --width $W --height $H --secondary "$sec" | surface
    else
        perl "$proto/show.pl" panel --input typical --headed --bg "$bg" --width $W --height $H --secondary "$sec" | surface
        echo
        perl "$proto/show.pl" ask --input pattern --form modal --placement inline --bg "$bg" --width $W --height $H --secondary "$sec" | surface
    fi
}
surface() { awk '/╭/ { on = 1 } on { print } /╰/ { on = 0 }'; }

for bg in dark light; do
    if [[ $bg == dark ]]; then
        one='#93969b'; two='#797c81'
        l1='Option 1: grey held at 4.5:1   #93969b, 4.52:1 on Clear Dark'
        l2="Option 2: grey at today's faint   #797c81, 3.21:1 on Clear Dark"
    else
        one='#747474'; two='244'
        l1='Option 1: grey held at 4.5:1   #747474, 4.52:1 on Clear Light'
        l2="Option 2: today's grey 244   #808080, 3.82:1 on Clear Light"
    fi
    for page in 1 2; do
        render $bg "$one" $page > "$out/.a"
        render $bg "$two" $page > "$out/.b"
        python3 - "$out/.a" "$out/.b" "$l1" "$l2" $W > "$out/secondary-$bg-$page.ans" <<'EOF'
import re, sys
a, b, l1, l2, w = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], int(sys.argv[5])
A, B = (open(f, encoding="utf-8").read().split("\n") for f in (a, b))
if A[-1] == "": A.pop()
if B[-1] == "": B.pop()
cells = lambda s: len(re.sub(r"\x1b\[[0-9;]*m", "", s))
pad = lambda s: s + "\x1b[0m" + " " * max(0, w - cells(s))
print()
print(pad("  " + l1) + "   " + "  " + l2)
print()
for i in range(max(len(A), len(B))):
    x = A[i] if i < len(A) else ""
    y = B[i] if i < len(B) else ""
    print(pad(x) + "   " + y + "\x1b[0m")
EOF
    done
done
rm -f "$out/.a" "$out/.b"
ls "$out"/secondary-*.ans
