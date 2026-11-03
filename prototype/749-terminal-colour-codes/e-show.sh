#!/usr/bin/env bash
# e-show.sh <file.ans> <window-rows> <signal-prefix> <title>
#
# Runs inside the Terminal.app window e-measure.sh opens and has already
# given its profile and size. Prints <file.ans> as a terminal shows ltl's
# output, a page of <window-rows> lines at a time so every line is captured:
# after page k it writes <signal-prefix>.page-<k> and waits for
# <signal-prefix>.page-<k>.taken; the next page scrolls the window on as a
# live run does. After the last page it writes <signal-prefix>.end, and
# e-measure.sh closes the window.
file=$1 rows=$2 sig=$3 title=$4
printf '\033]2;%s\007' "$title"
printf '\033[?25l'
clear
total=$(( $(wc -l < "$file") + 1 ))
k=0 first=1
while (( first <= total )); do
    last=$(( first + rows - 1 ))
    (( k > 0 )) && printf '\n'
    sed -n "${first},${last}p" "$file" | perl -pe 'chomp if eof'
    touch "$sig.page-$k"
    while [[ ! -e $sig.page-$k.taken ]]; do sleep 0.05; done
    k=$(( k + 1 )) first=$(( last + 1 ))
done
touch "$sig.end"
