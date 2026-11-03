#!/usr/bin/env bash
# wt-e-show.sh <file.ans> <window-rows> <signal-prefix>
#
# The Windows counterpart of e-show.sh. Runs inside the Windows Terminal
# window wt-e-capture.ps1 opens, already in its scheme and size: sets the
# UTF-8 code page, hides the cursor, clears, and prints <file.ans> as a
# terminal shows ltl's output, a page of <window-rows> lines at a time so
# every line is captured: after page k it writes <signal-prefix>.page-<k>
# and waits for <signal-prefix>.page-<k>.taken; the next page scrolls the
# window on as a live run does. After the last page it writes
# <signal-prefix>.end and exits, which closes the window. The window's PATH
# is the Windows one, not Git Bash's, so Git Bash's own tools come first.
PATH=/usr/bin:$PATH
file=$1 rows=$2 sig=$3
/c/Windows/System32/chcp.com 65001 > /dev/null
printf '\033[?25l\033[H\033[2J'
total=$(( $(wc -l < "$file") + 1 ))
k=0 first=1
while (( first <= total )); do
    last=$(( first + rows - 1 ))
    (( k > 0 )) && printf '\n'
    sed -n "${first},${last}{s/\r\$//;p}" "$file" | head -c -1
    touch "$sig.page-$k"
    while [[ ! -e $sig.page-$k.taken ]]; do sleep 0.05; done
    k=$(( k + 1 )) first=$(( last + 1 ))
done
touch "$sig.end"
