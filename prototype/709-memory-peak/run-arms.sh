#!/usr/bin/env bash
# #709 P1: the timed runs. Rounds, then inputs, then arms, the arm order
# rotated each round so no arm always runs first or last on an input. Every
# run under /usr/bin/time -l, from an empty directory, with
# --disable-progress -V benchmark-data,memory-usage; -mem on every arm but a
# floor (ltl-tracked, or an arm named *-floor). summarise.py reads the output tree.
#
#   usage: run-arms.sh <arms dir> <output dir> <candidates file> <rounds> <input ...>
#   ARMS overrides the arm list (default: tracked every boundaries grouponly cond-either-0)
set -u
here="$(cd "$(dirname "$0")" && pwd)"
arms="$1"; out="$2"; candidates="$3"; rounds="$4"; shift 4
inputs=("$@")
LOGS="${LOGS:-$here/../../logs}"
read -r -a arm_list <<< "${ARMS:-tracked every boundaries grouponly cond-either-0}"
mkdir -p "$out/cwd"

declare -A files opts
while IFS='|' read -r name globs o; do
    [[ -z "$name" || "$name" == \#* ]] && continue
    f=""
    for g in $globs; do for p in $LOGS/$g; do [[ -f "$p" ]] && f="$f $p"; done; done
    files[$name]="$f"; opts[$name]="$o"
done < "$candidates"
for input in "${inputs[@]}"; do
    [[ -n "${files[$input]:-}" ]] || { echo "unknown or empty input: $input" >&2; exit 2; }
done

echo "start $(date '+%F %T'); arms: ${arm_list[*]}; inputs: ${inputs[*]}"
n=${#arm_list[@]}
for (( r = 1; r <= rounds; r++ )); do
    for input in "${inputs[@]}"; do
        mkdir -p "$out/r$r/$input"
        for (( i = 0; i < n; i++ )); do
            arm="${arm_list[$(( (i + r - 1) % n ))]}"
            mem="-mem"; [[ "$arm" == tracked || "$arm" == *-floor ]] && mem=""
            # word lists, unquoted on purpose
            ( cd "$out/cwd" && /usr/bin/time -l "$arms/ltl-$arm" --disable-progress \
                -V benchmark-data,memory-usage $mem ${opts[$input]} ${files[$input]} \
                > "$out/r$r/$input/$arm.out" 2> "$out/r$r/$input/$arm.err" )
            rc=$?
            total=$(awk -F'\t' '$1=="TIMING" && $2=="total" {print $3}' "$out/r$r/$input/$arm.out")
            echo "r$r $input $arm: exit $rc, total ${total:-?} s"
        done
    done
done
echo "end $(date '+%F %T')"
