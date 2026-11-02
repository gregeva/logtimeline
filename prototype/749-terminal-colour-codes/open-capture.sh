#!/usr/bin/env bash
# open-capture.sh <profile> <ansi-file> <out.png> [cols] [rows]
# Opens a Terminal.app window in <profile>, cats the file, captures the window, closes it.
set -euo pipefail
profile="$1"; file="$2"; out="$3"; cols="${4:-110}"; rows="${5:-40}"
wid=$(osascript <<OSA
tell application "Terminal"
  set t to do script "clear; printf '\\\\033[?25l'; cat '$file'; tail -f /dev/null"
  set current settings of t to settings set "$profile"
  set number of columns of t to $cols
  set number of rows of t to $rows
  delay 1.5
  set w to first window whose tabs contains t
  return id of w
end tell
OSA
)
screencapture -x -o -l "$wid" "$out"
osascript -e "tell application \"Terminal\" to close (every window whose id is $wid)" >/dev/null 2>&1 || true
echo "$wid $out"
