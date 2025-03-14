#!/bin/bash

# auto-compact.sh - Automatically detect and capture Claude's compact output
# This script monitors the Claude process and captures the output when /compact
# is used, then appends the summary to a daily consolidated file

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSIONS_DIR="$SCRIPT_DIR/../../sessions/claude"
DATE=$(date +"%Y%m%d")
TIME=$(date +"%H%M%S")
DAILY_SESSION_FILE="$SESSIONS_DIR/claude-session-$DATE.md"
TEMP_FILE="$SESSIONS_DIR/auto-compact-$DATE-$TIME.txt"
FIFO_FILE="/tmp/claude-fifo-$$"

# Make sure sessions directory exists
mkdir -p "$SESSIONS_DIR"

# Create a FIFO (named pipe) for capturing the output
mkfifo "$FIFO_FILE"

# Trap to clean up the FIFO on exit
trap 'rm -f "$FIFO_FILE"; echo "Exiting..."; exit' INT TERM EXIT

echo "Starting Claude with auto-compact detection..."
echo "Use /compact in your Claude session as normal"
echo "This script will automatically detect and append the compact summary to the daily session file"
echo "Press Ctrl+C to exit"
echo ""

# Start background process to monitor the output for compact command
cat "$FIFO_FILE" | tee "$TEMP_FILE" | grep --line-buffered -A 100 "<summary>" > /dev/null &
GREP_PID=$!

# Run Claude and redirect its output to our FIFO
claude > "$FIFO_FILE" 2>&1

# After Claude exits, check if we found a compact summary
if grep -q "<summary>" "$TEMP_FILE"; then
  # Extract content between <summary> tags
  sed -n '/<summary>/,/<\/summary>/p' "$TEMP_FILE" | sed 's/<summary>//g' | sed 's/<\/summary>//g' > "$TEMP_FILE.extract"
  
  # Create header for new session entry
  SESSION_HEADER="## Claude Session - $(date +"%B %d, %Y %H:%M")"
  
  # Create the daily session file if it doesn't exist
  if [ ! -f "$DAILY_SESSION_FILE" ]; then
    echo "# Claude Sessions for $(date +"%B %d, %Y")" > "$DAILY_SESSION_FILE"
    echo "" >> "$DAILY_SESSION_FILE"
  fi
  
  # Append the new session to the daily file
  echo "$SESSION_HEADER" >> "$DAILY_SESSION_FILE"
  echo "" >> "$DAILY_SESSION_FILE"
  cat "$TEMP_FILE.extract" >> "$DAILY_SESSION_FILE"
  echo "" >> "$DAILY_SESSION_FILE"
  echo "---" >> "$DAILY_SESSION_FILE"
  echo "" >> "$DAILY_SESSION_FILE"
  
  echo ""
  echo "✅ Compact summary detected and appended to: $DAILY_SESSION_FILE"
  
  # Also create a monthly index file to track all sessions
  MONTH=$(date +"%Y%m")
  MONTHLY_INDEX="$SESSIONS_DIR/sessions-$MONTH.md"
  
  if [ ! -f "$MONTHLY_INDEX" ]; then
    echo "# Claude Sessions for $(date +"%B %Y")" > "$MONTHLY_INDEX"
    echo "" >> "$MONTHLY_INDEX"
    echo "| Date | Time | Session File |" >> "$MONTHLY_INDEX"
    echo "|------|------|-------------|" >> "$MONTHLY_INDEX"
  fi
  
  # Add this session to the monthly index
  echo "| $(date +"%Y-%m-%d") | $(date +"%H:%M") | [Session](./claude-session-$DATE.md) |" >> "$MONTHLY_INDEX"
  
  # Update the main index json file
  SESSIONS_INDEX="$SESSIONS_DIR/sessions-index.json"
  
  # Create index file if it doesn't exist or is empty
  if [ ! -s "$SESSIONS_INDEX" ]; then
    echo '{"sessions":[]}' > "$SESSIONS_INDEX"
  fi
  
  # Add the session to the index using jq if available, otherwise append to a log file
  if command -v jq >/dev/null 2>&1; then
    TEMP_JSON=$(mktemp)
    jq --arg date "$(date +"%Y-%m-%d")" \
       --arg time "$(date +"%H:%M")" \
       --arg file "claude-session-$DATE.md" \
       '.sessions += [{"date": $date, "time": $time, "file": $file}]' \
       "$SESSIONS_INDEX" > "$TEMP_JSON" && mv "$TEMP_JSON" "$SESSIONS_INDEX"
  else
    echo "$(date +"%Y-%m-%d %H:%M") - claude-session-$DATE.md" >> "$SESSIONS_DIR/sessions-log.txt"
  fi
  
  # Clean up temporary files
  rm -f "$TEMP_FILE.extract"
else
  echo ""
  echo "No compact summary was detected in this session."
  # Don't remove the temp file as it might be useful for debugging
fi

# Kill any remaining background processes
kill $GREP_PID 2>/dev/null

# Clean up the FIFO
rm -f "$FIFO_FILE"

echo "Full session log saved to: $TEMP_FILE"