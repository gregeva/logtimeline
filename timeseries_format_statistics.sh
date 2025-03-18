#!/bin/bash

# Check for the --keep-seconds option
keep_seconds=false
if [ "$1" == "--keep-seconds" ]; then
  keep_seconds=true
fi

# Loop through all files matching the pattern
for file in Entity*Statistics-*.csv; do
  # Extract the datetime part from the filename
  datetime=$(echo "$file" | sed -n 's/.*-\([0-9]\{14\}\)-.*/\1/p')
  
  # Extract the host system part from the filename
  host_system=$(echo "$file" | sed -n 's/.*-\([0-9]\{14\}\)-\([a-zA-Z0-9]*\)\.csv/\2/p')
  
  # Convert the datetime to a standard format using awk and printf
  if $keep_seconds; then
    formatted_datetime=$(echo "$datetime" | awk '{printf "%s-%s-%s %s:%s:%s\n", substr($0, 1, 4), substr($0, 5, 2), substr($0, 7, 2), substr($0, 9, 2), substr($0, 11, 2), substr($0, 13, 2)}')
  else
    formatted_datetime=$(echo "$datetime" | awk '{printf "%s-%s-%s %s:%s\n", substr($0, 1, 4), substr($0, 5, 2), substr($0, 7, 2), substr($0, 9, 2), substr($0, 11, 2)}')
  fi
  
  # Read the file and prepend the formatted datetime and host system to each line
  while IFS= read -r line; do
    echo "$formatted_datetime,$host_system,$line"
  done < "$file"
done
