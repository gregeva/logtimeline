#!/bin/bash
# Three identical real-ltl runs: is counter_memory_bytes stable across processes?
F=logs/AccessLogs/localhost_access_log.2025-03-21.txt
for i in 1 2 3; do
  ./ltl --disable-progress -ni -mdm bin -V histogram-bin-counters --terminal-width 200 -bs 1440 -oe $F 2>&1 | grep -a 'counter_memory_bytes\|partition_count'
done
