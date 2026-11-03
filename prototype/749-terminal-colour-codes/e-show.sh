#!/usr/bin/env bash
# e-show.sh <file.ans> <window-rows> <signal-prefix> <title>
#
# Runs inside the Terminal.app window e-measure.sh opens and has already
# given its profile and size. Prints <file.ans> as a terminal shows ltl's
# output, in two steps so both ends are captured: the first <window-rows>
# lines, then <signal-prefix>.top and a wait for <signal-prefix>.top.taken;
# then the rest, which scrolls the window to the end as a live run does,
# then <signal-prefix>.bottom and a wait for <signal-prefix>.bottom.taken,
# after which e-measure.sh closes the window.
file=$1 rows=$2 sig=$3 title=$4
printf '\033]2;%s\007' "$title"
printf '\033[?25l'
clear
head -n "$rows" "$file" | perl -pe 'chomp if eof'
touch "$sig.top"
while [[ ! -e $sig.top.taken ]]; do sleep 0.1; done
printf '\n'
tail -n +"$((rows + 1))" "$file"
touch "$sig.bottom"
while [[ ! -e $sig.bottom.taken ]]; do sleep 0.1; done
