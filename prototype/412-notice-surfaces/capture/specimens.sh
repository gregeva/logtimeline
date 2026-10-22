#!/usr/bin/env bash
# The capture method demonstrated against known-good and known-bad input
# (prototype/README.md § (d)): each assertion of assert-surface.pl is run on a
# capture of the current build, which must pass, and on a capture of a build
# that carried the defect the assertion is for, which must fail. The known-bad
# builds are this stage's own escaped defects, checked out from their commits:
#   round 6 (e6230dd): the options list's pane lacked its empty row below
#   round 3 (4bef110): the dimmed run under the modal moved to the bottom
# A redirected run stands for the harness and screenshot path; the raw byte
# stream a terminal receives (tmux pipe-pane) is the known-bad for it.
#
#   capture/specimens.sh OUTDIR ROUND6_TREE ROUND3_TREE
set -u
HERE=$(cd "$(dirname "$0")/.." && pwd)
export PATH="$(brew --prefix)/bin:$(brew --prefix)/opt/perl/bin:$PATH"
OUT=${1:?OUTDIR}; R6=${2:?ROUND6_TREE}; R3=${3:?ROUND3_TREE}
mkdir -p "$OUT"
W=160; H=50
A="$HERE/capture/assert-surface.pl"

# pane DIR NAME CMD STEPS: run CMD in a tmux pane in DIR, send keys, capture
pane() {
  local dir=$1 name=$2 cmd=$3 steps=$4 sess="ltl412c-$$-$RANDOM"
  tmux new-session -d -s "$sess" -x $W -y $H -c "$dir" "exec bash --noprofile --norc"
  tmux send-keys -t "$sess" "clear; $cmd" Enter
  for step in $steps; do
    case $step in
      sleep:*) sleep "${step#sleep:}" ;;
      cap:*)   tmux capture-pane -e -p -t "$sess" > "$OUT/$name.${step#cap:}.ansi" ;;
      *)       tmux send-keys -t "$sess" "$step" ;;
    esac
  done
  tmux kill-session -t "$sess" 2>/dev/null
}
check() {  # LABEL EXPECT(PASS|FAIL) assertion args...
  local label=$1 expect=$2; shift 2
  local out; out=$(perl "$A" "$@" 2>&1); local rc=$?
  local got=PASS; [ $rc -ne 0 ] && got=FAIL
  local verdict=ok; [ "$got" != "$expect" ] && verdict=WRONG
  printf '%-42s expected %-4s got %-4s %s\n' "$label" "$expect" "$got" "$verdict"
  echo "$out" | grep -E '^MISS|^compared|^box|^escapes' | sed 's/^/    /' | head -8
}

echo "== panes: each pane padded 2 cells at the sides, an empty row above and below"
pane "$HERE" good-list "perl show.pl ask --input pattern" "sleep:7 l sleep:0.6 cap:list"
pane "$R6/prototype/412-notice-surfaces" bad-list "perl show.pl ask --input pattern" "sleep:7 l sleep:0.6 cap:list"
check "current build, options list"  PASS panes "$OUT/good-list.list.ansi" --side 2 --rows 1
check "round 6 build, options list"  FAIL panes "$OUT/bad-list.list.ansi"  --side 2 --rows 1

echo "== unmoved: the run's rows stay where they were under the modal"
pane "$HERE" good-modal "perl show.pl ask --input memory" "sleep:1.2 cap:before sleep:1.6 cap:modal Escape sleep:2.5 cap:after"
pane "$R3/prototype/412-notice-surfaces" bad-modal "perl surfaces/ask.pl --moment read" "sleep:1.2 cap:before sleep:1.6 cap:modal Escape sleep:2.5 cap:after"
check "current build, modal over the run" PASS unmoved "$OUT/good-modal.before.ansi" "$OUT/good-modal.modal.ansi"
check "round 3 build, modal over the run" FAIL unmoved "$OUT/bad-modal.before.ansi"  "$OUT/bad-modal.modal.ansi"

echo "== no-trace: nothing left once the modal closed"
pane "$HERE" good-trace "perl show.pl ask --input memory --record" "sleep:1.2 cap:before sleep:1.6 Escape sleep:2.5 cap:after"
check "current build, Esc"                PASS no-trace "$OUT/good-modal.before.ansi" "$OUT/good-modal.after.ansi"
check "current build with --record (left on purpose)" FAIL no-trace "$OUT/good-trace.before.ansi" "$OUT/good-trace.after.ansi"

echo "== plain: a redirected run prints the surface once as plain rows and goes on"
( cd "$HERE" && perl show.pl ask --input memory --width $W --height $H > "$OUT/redirected.txt" 2>"$OUT/redirected.err" )
# the raw bytes a terminal receives, taken off a tmux pane with pipe-pane
raw() {
  local name=$1 cmd=$2 secs=$3 sess="ltl412r-$$-$RANDOM"
  tmux new-session -d -s "$sess" -x $W -y $H -c "$HERE" "exec bash --noprofile --norc"
  tmux pipe-pane -o -t "$sess" "cat > '$OUT/$name'"
  tmux send-keys -t "$sess" "clear; $cmd" Enter
  sleep "$secs"
  tmux kill-session -t "$sess" 2>/dev/null
}
raw pty-stream.txt "perl show.pl ask --input memory --seconds 1" 6
check "redirected stdout"                PASS plain "$OUT/redirected.txt"
check "raw pty stream (script)"          FAIL plain "$OUT/pty-stream.txt"
