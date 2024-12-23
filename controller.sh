#!/bin/bash

# Check if at least one argument is passed (the command/script to run)
if [ $# -lt 1 ]; then
  echo "Usage: $0 <command> [args...]"
  exit 1
fi

# Capture the command and its arguments
COMMAND="$@"

set -m

# Run the command in the background and capture the PID
$COMMAND &
COMMAND_PID=$!

function ctrl_c {

  state=$(awk '{print $3}' /proc/$COMMAND_PID/stat)

  if [ "$state" == "R" ] || [ "$state" == "S" ]; then
    echo "Pausing..." && kill -TSTP $COMMAND_PID
    state=$(awk '{print $3}' /proc/$COMMAND_PID/stat)
  elif [ "$state" == "T" ]; then
    echo "Resuming..." && kill -CONT $COMMAND_PID
  fi
}

# Background process to monitor the process state
monitor_process_state() {
  while true; do
    sleep 1
  done
}

# Start monitoring the process state in the background
monitor_process_state &
MONITOR_PID=$!

while [ -e "/proc/$COMMAND_PID/stat" ]; do
  trap ctrl_c SIGINT
done

kill $MONITOR_PID