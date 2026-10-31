# #709 P1: the staged inputs, sourced by trace.sh and run-arms.sh.
# One server's month of web application access logs carrying execution time in
# the duration field, from its first day: 1, 3, 7 and 15 days (34.4, 66.6,
# 327.2 and 801.9 MB); and the application log of 286K unique messages (97 MB),
# the benchmark's most checkpoint-heavy file. Options are the benchmark's
# top25-consolidate scenario (tests/baseline/run-benchmark.sh SCENARIOS), with
# its file selections' bucket size: -bs 1440 on the access logs, and the
# benchmark's default -bs 60 elsewhere. Then the same server's 1, 3 and 7 days
# grouped without the UUID mask, with the options of
# features/memory-tracking-improvements.md § Issue #146 › Drop 2, whose walks
# are the cost handed forward to #709.
#
# Requires LOGS (the corpus directory). Defines INPUTS (names, in order),
# input_files <name> and input_options <name>.

INPUTS=(d1 d3 d7 d15 uniq g1 g3 g7)
SCENARIO_OPTIONS="-n 25 -g -m uuid --terminal-width 200"

input_files() {
    local month="$LOGS/AccessLogs/really-big/localhost_access_log-twx01-twx-thingworx-1.2026-01"
    case "$1" in
        d1|g1) echo "$month-02.txt" ;;
        d3|g3) echo "$month-0"[2-4].txt ;;
        d7|g7) echo "$month-0"[2-8].txt ;;
        d15)  echo "$month-0"[2-9].txt "$month-1"[0-6].txt ;;
        uniq) echo "$LOGS/ThingworxLogs/HundredsOfThousandsOfUniqueErrors.log" ;;
        *)    echo "unknown input: $1" >&2; return 1 ;;
    esac
}

input_options() {
    case "$1" in
        d1|d3|d7|d15) echo "-bs 1440 $SCENARIO_OPTIONS" ;;
        uniq)         echo "-bs 60 $SCENARIO_OPTIONS" ;;
        g1|g3|g7)     echo "-ni -g" ;;
    esac
}
