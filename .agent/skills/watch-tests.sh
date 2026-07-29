#!/usr/bin/env bash
#
# Skill: watch-tests.sh
# Description: Actively watches a background test process, printing updates and showing final results once complete.
# Usage: .agent/skills/watch-tests.sh -p <PID> [-f <LogFile>] [-i <Interval>]

set -euo pipefail

PID=""
LOG_FILE="test_run.log"
INTERVAL=30

while getopts "p:f:i:" opt; do
  case $opt in
    p) PID="$OPTARG" ;;
    f) LOG_FILE="$OPTARG" ;;
    i) INTERVAL="$OPTARG" ;;
    *) echo "Usage: $0 -p <PID> [-f <LogFile>] [-i <Interval>]" && exit 1 ;;
  esac
done

if [ -z "$PID" ]; then
  echo "Error: Must provide a PID to watch."
  exit 1
fi

echo "Actively watching background process $PID..."
echo "Tailing updates from: $LOG_FILE"
echo "Polling interval: $INTERVAL seconds"
echo "--------------------------------------------------"

LAST_LINE_COUNT=0
while kill -0 "$PID" 2>/dev/null; do
  # Print any new lines added to the log file since our last check
  if [ -f "$LOG_FILE" ]; then
    TOTAL_LINES=$(wc -l < "$LOG_FILE")
    if [ "$TOTAL_LINES" -gt "$LAST_LINE_COUNT" ]; then
      NEW_LINES=$((TOTAL_LINES - LAST_LINE_COUNT))
      tail -n "$NEW_LINES" "$LOG_FILE"
      LAST_LINE_COUNT="$TOTAL_LINES"
    fi
  fi
  sleep "$INTERVAL"
done

echo "--------------------------------------------------"
echo "Process $PID has completed."
echo "Showing the last 100 lines of $LOG_FILE:"
echo "--------------------------------------------------"
if [ -f "$LOG_FILE" ]; then
  tail -n 100 "$LOG_FILE"
else
  echo "Log file $LOG_FILE not found."
fi
