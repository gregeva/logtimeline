#!/usr/bin/env bash
# wt-show.sh <ansi-file> <done-file>
#
# Runs inside the new Windows Terminal window wt-capture.ps1 opens: sets the
# UTF-8 code page, hides the cursor, prints the file with cat and nothing
# after it, then waits until <done-file> exists and exits 0, which closes the
# window. Commands are named by path because the window's PATH is the
# Windows one, not Git Bash's.
/c/Windows/System32/chcp.com 65001 > /dev/null
printf '\033[?25l'
/usr/bin/cat "$1"
while [[ ! -e "$2" ]]; do /usr/bin/sleep 0.2; done
