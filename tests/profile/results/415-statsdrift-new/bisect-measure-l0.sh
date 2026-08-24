#!/bin/bash
# usage: measure-l0.sh <sha>  -> prints best L0 lookup seconds over 2 runs
set -euo pipefail
OUT=/private/tmp/claude-501/-Users-gregeva-Documents-GitHub-logtimeline/12cf9682-1693-4c41-ac11-f2b6f8dd43ea/scratchpad/415
SAMPLE=/Users/gregeva/Documents/GitHub/logtimeline/tests/profile/samples/HundredsOfThousandsOfUniqueErrors-100000.log
sha=$1; f=$OUT/bisect-$(git -C /Users/gregeva/Documents/GitHub/logtimeline rev-parse --short "$sha").pl
git -C /Users/gregeva/Documents/GitHub/logtimeline show "$sha:ltl" > "$f"
perl -pi -e 'BEGIN{open my $h, "<", shift; local $/; $inj=<$h>} if (!$done && /^\s*calculate_all_statistics\(\);/) { print $inj; $done=1 }' $OUT/inj-l0.pl "$f"
grep -q '### L0' "$f" || { echo "INJECT-FAIL"; exit 2; }
best=
for r in 1 2; do
  v=$(/opt/homebrew/bin/perl "$f" --disable-progress --terminal-width 200 -bs 60 -so p99 -dm raw "$SAMPLE" 2>&1 >/dev/null | grep -a '### L0' | awk '{print $3}')
  [[ -z "$v" ]] && { echo "RUN-FAIL"; exit 2; }
  if [[ -z "$best" ]] || (( $(echo "$v < $best" | bc -l) )); then best=$v; fi
done
rm -f "$f"; echo "$best"
