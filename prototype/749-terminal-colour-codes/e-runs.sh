# e-runs.sh: the runs of features/749-terminal-colour-codes.md § 10, sourced
# by e-outputs.sh (which writes them to files) and wt-run.sh (which runs
# one at a prompt in a Windows terminal). `run <name> [flags]` writes that run's
# output. It needs the working directory at the repository's root and
# $synth naming the synthetic log synth-metrics.py writes; LTL names the ltl
# to run (default ./ltl) and PERL the perl to run it with (default perl).
cols=190
A=logs/Sets/windchill-jdk21-balancer-outage/node2/apachelogs/access.log_2026-08-21_00_00_00
D=logs/Sets/windchill-jdk21-balancer-outage/node2/logs
day=(-st 04:00 -et 13:00 -bs 30m -n 4 -hf --terminal-width $cols)
run() {  # run <name> <flags> : ltl's output for that run
    local name=$1 flags=${2:-}
    case $name in
        access-heatmap) "${PERL:-perl}" "${LTL:-./ltl}" --disable-progress $flags -du us "${day[@]}" -hm duration -hg $A ;;
        access-latency) "${PERL:-perl}" "${LTL:-./ltl}" --disable-progress $flags -du us "${day[@]}" -sm $A ;;
        levels) "${PERL:-perl}" "${LTL:-./ltl}" --disable-progress $flags -st 04:00 -et 12:30 -bs 30m -n 4 -hf --terminal-width $cols \
                    $D/MethodServer-2608090416-8780-log4j.log $D/MethodServer-2608211150-2679531-log4j.log.2026-08-21_1 \
                    $D/MethodServer-2608211150-2679531-log4j.log.2026-08-21_2 ;;
        udm) "${PERL:-perl}" "${LTL:-./ltl}" --disable-progress $flags -bs 10 -n 4 --terminal-width $cols \
                 -udm system_cpu_total::max -udm tcp_inuse::max -udm tcp_established::max -udm ctx_switches::max \
                 -udm tcp_timewait::max -udm system_mem_percent::max -udm java_mem_rss::max -udm no_such_column::max \
                 logs/UDM/connection-server-custom-metrics.csv ;;
        fills) "${PERL:-perl}" "${LTL:-./ltl}" --disable-progress $flags -bs 10 -n 0 --terminal-width $cols -h ' [0-9][0-9]:[0-5][13579]:[0-9][0-9],' \
                   -udm system_cpu_total::sum -udm tcp_inuse::sum -udm tcp_established::sum -udm java_num_connections::sum \
                   -udm tcp_timewait::sum -udm system_mem_percent::sum -udm java_mem_rss::sum -udm ephemeral_ports_used::sum \
                   -udm tcp_alloc::sum -udm java_fd_count::sum logs/UDM/connection-server-custom-metrics.csv ;;
        heat-*)
            local colour=${name#heat-} udm=() c
            for c in "${heat_order[@]}"; do udm+=(-udm "$c::sum"); done
            "${PERL:-perl}" "${LTL:-./ltl}" --disable-progress $flags -bs 30m -n 0 --terminal-width $cols -h HL "${udm[@]}" \
                -hm "$colour" --hide legend,occurrences "$synth" ;;
        help) FORCE_COLOR=1 "${PERL:-perl}" "${LTL:-./ltl}" --disable-progress $flags --terminal-width $cols --help ;;
        explain) FORCE_COLOR=1 "${PERL:-perl}" "${LTL:-./ltl}" --disable-progress $flags --terminal-width $cols --explain contribution-highlighting ;;
        error) FORCE_COLOR=1 "${PERL:-perl}" "${LTL:-./ltl}" --disable-progress $flags --terminal-width $cols --bogus-option $A 2>&1 || true ;;
        progress-pause)
            # ltl's own codes: $colors{'bright-green'} before each stage's
            # "... completed." line, and pause_for_keypress's "\033[0;44m$prompt\033[0m"
            local green prompt
            green=$(perl -ne "print \$1 if /'bright-green'\s*=>\s*\"([^\"]+)\"/" "${LTL:-./ltl}" | head -1)
            prompt=$(perl -ne 'print $1 if /\$prompt = "([^"]+)" unless defined \$prompt/' "${LTL:-./ltl}" | head -1)
            for stage in "Processing" "Calculating heatmap buckets" "Consolidating similar messages"; do
                printf '%b%s completed.\033[0m\n' "$green" "$stage"
            done
            [[ -n $prompt ]] || { echo "pause_for_keypress's prompt not found in ltl" >&2; exit 1; }
            printf '\n\033[0;44m%s\033[0m\n' "$prompt" ;;
    esac
}
# the order the ten metrics of the synthetic log take the column colours in (blue first: no users column)
heat_order=(blue magenta red orange pink teal purple yellow green cyan)
all_runs=(access-heatmap access-latency levels udm fills $(printf 'heat-%s ' "${heat_order[@]}") help explain error progress-pause)
