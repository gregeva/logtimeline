#!/usr/bin/env bash
# wt-run.sh <run> <synth-log>
#
# Runs one of e-runs.sh's runs, or the notice panel (`notices`: the
# panel-categories fixture), in the terminal it is typed in, with no
# background option, so ltl settles the background from the terminal's
# answer. ltl runs under the host's native perl with the terminal's own
# PATH, so a pager it starts is the one an analyst's would be. For
# wt-show-runs.ps1; Windows, run by Git Bash's bash.exe from cmd.
perl_exe=$(command -v perl)
window_path=$PATH
PATH=/usr/bin:$PATH
here=$(cd "$(dirname "$0")" && pwd)
"$perl_exe" -e 'exit($^O eq "MSWin32" ? 0 : 1)' || { echo "not a native Windows perl: $perl_exe" >&2; exit 1; }
export PERL=$perl_exe
synth=$2
cd "$here/../.."
source "$here/e-runs.sh"
case $1 in
    notices) PATH=$window_path "$PERL" ./ltl --disable-progress -bs 1440 -oe -n 1 --notice-fixture panel-categories \
                 tests/fixtures/format-detection/access-combined-duration.txt ;;
    *) PATH=$window_path run "$1" ;;
esac
