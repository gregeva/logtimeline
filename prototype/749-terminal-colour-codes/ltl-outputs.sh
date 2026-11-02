#!/usr/bin/env bash
# ltl-outputs.sh <out-dir>
#
# Writes the ltl output the measurement draws, from committed fixtures so
# every host draws the same runs: a timeline of a web application access log
# (duration and bytes columns, the HTTP status families in the legend, one
# path highlighted), a timeline of a ThingWorx script log (duration, bytes,
# count and users columns, one message family highlighted), the top of
# --help and one --explain page, both with FORCE_COLOR so their bold and
# underline are written. Each is written as ltl writes it (<name>.ans) and
# rewritten to fixed 256-colour codes by to256.pl (<name>-256.ans).
#
# Runs ltl from the checkout this script sits in, with the fixture paths
# relative to it, so no host's own path is printed.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../.." && pwd)
out=$(mkdir -p "$1" && cd "$1" && pwd)
ltl=("perl" "./ltl" --disable-progress)
cd "$root"

"${ltl[@]}" -ni -bs 120 --terminal-width 118 -h SampleThing \
    tests/fixtures/tomcat-access-duration-spread.txt > "$out/access.ans"
"${ltl[@]}" -ni -bs 5s -tp s --terminal-width 118 -h BD-dur \
    tests/fixtures/numeric-highlight-boundary.txt > "$out/script.ans"
FORCE_COLOR=1 "${ltl[@]}" --help | head -52 > "$out/help-top.ans"
FORCE_COLOR=1 "${ltl[@]}" --explain contribution-highlighting > "$out/explain.ans"

for f in access script help-top explain; do
    perl "$here/to256.pl" < "$out/$f.ans" > "$out/$f-256.ans"
done
ls "$out"
