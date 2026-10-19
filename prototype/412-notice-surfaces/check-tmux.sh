#!/usr/bin/env bash
# Claude's check before a round is reviewed: each view driven in a tmux pane
# the size of a terminal, keys sent as the analyst would, and the pane
# captured as it is seen, alternate screen included (what a replay through an
# emulator without one could not show). Captures land in the directory given;
# nothing here runs ltl.
#
#   ./check-tmux.sh OUTDIR [scenario ...]      (default: every scenario)
#   ./check-tmux.sh --list
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
export PATH="$(brew --prefix)/bin:$(brew --prefix)/opt/perl/bin:$PATH"
W=120; H=40

# name | command | key steps: "sleep:S" waits, "cap:NAME" captures, anything else is sent as keys
scenarios() {
cat <<'S'
modal-read     | perl show.pl ask --input memory             | sleep:2.5 cap:up sleep:0.3 BTab cap:shift-tab sleep:0.2 Tab cap:tab-back Escape sleep:2 cap:after
modal-stopcd   | perl show.pl ask --input memory             | sleep:2.5 Space sleep:1.5 cap:stopped Escape sleep:2 cap:after
modal-quit     | perl show.pl ask --input memory             | sleep:2.5 x sleep:1 cap:after
modal-pattern  | perl show.pl ask --input pattern            | sleep:7 cap:stage1 l sleep:0.5 cap:list Down sleep:0.3 cap:list2 Escape sleep:1 cap:after
modal-fixed    | perl show.pl ask --input pattern --fixed-height | sleep:7 cap:stage1 l sleep:0.5 cap:list Escape sleep:1 cap:after
modal-preread  | perl show.pl ask --input preread            | sleep:2.5 cap:up S sleep:1 cap:after
modal-inline   | perl show.pl ask --input memory --placement inline | sleep:2.5 cap:up BTab sleep:0.3 cap:shift-tab Enter sleep:2.5 cap:after
box-read       | perl show.pl ask --input memory --form box  | sleep:2.5 cap:up q sleep:0.5 cap:q-ignored Escape sleep:2.5 cap:after
box-pattern    | perl show.pl ask --input pattern --form box | sleep:7 cap:up L sleep:0.5 cap:list 2 sleep:0.3 cap:list2 Enter sleep:1 cap:after
browser        | perl show.pl browser                        | sleep:7 cap:up Space 7 sleep:0.3 cap:tab7 sleep:0.3 cap:guidance Enter sleep:0.5 cap:layered Down sleep:0.3 Enter sleep:0.5 cap:chosen Escape sleep:1 cap:after
browser-cd     | perl show.pl browser --seconds 3            | sleep:7 cap:up sleep:3.5 cap:closed
browser-inline | perl show.pl browser --placement inline     | sleep:7 cap:up 7 sleep:0.3 cap:guidance Enter sleep:0.5 cap:layered Escape sleep:0.5 cap:back Escape sleep:1 cap:after
S
}

if [ "${1:-}" = "--list" ]; then scenarios | cut -d'|' -f1; exit 0; fi
OUT=${1:?OUTDIR}; shift; mkdir -p "$OUT"
want=("$@")

run() {
  local name=$1 cmd=$2 steps=$3 sess="ltl412-$$-$RANDOM"
  tmux new-session -d -s "$sess" -x $W -y $H -c "$HERE" "exec bash --noprofile --norc"
  tmux send-keys -t "$sess" "clear; $cmd; echo EXIT=\$?" Enter
  for step in $steps; do
    case $step in
      sleep:*) sleep "${step#sleep:}" ;;
      cap:*)   tmux capture-pane -e -p -t "$sess" > "$OUT/$name.${step#cap:}.ansi"
               tmux capture-pane -p -t "$sess"    > "$OUT/$name.${step#cap:}.txt" ;;
      *)       tmux send-keys -t "$sess" "$step" ;;
    esac
  done
  sleep 0.5
  tmux capture-pane -p -t "$sess" > "$OUT/$name.final.txt"
  tmux kill-session -t "$sess" 2>/dev/null
  echo "$name: $(grep -o 'EXIT=[0-9]*' "$OUT/$name.final.txt" | tail -1)"
}

scenarios | while IFS='|' read -r name cmd steps; do
  name=$(echo "$name" | xargs); cmd=$(echo "$cmd" | xargs); steps=$(echo "$steps" | xargs)
  if [ ${#want[@]} -gt 0 ]; then
    hit=0; for w in "${want[@]}"; do [ "$w" = "$name" ] && hit=1; done; [ $hit = 1 ] || continue
  fi
  run "$name" "$cmd" "$steps"
done
