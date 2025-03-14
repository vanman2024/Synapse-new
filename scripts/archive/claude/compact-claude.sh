#!/bin/bash

# compact-claude.sh - Automatically invoke Claude's compact command and save the result
# This script wraps the 'claude' CLI command, captures its output when using /compact,
# and automatically appends the summary to a daily consolidated file

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSIONS_DIR="$SCRIPT_DIR/../../sessions/claude"
DATE=$(date +"%Y%m%d")
TIME=$(date +"%H%M%S")
DAILY_SESSION_FILE="$SESSIONS_DIR/claude-session-$DATE.md"
TEMP_FILE="$SESSIONS_DIR/temp-compact-$DATE-$TIME.txt"

# Make sure sessions directory exists
mkdir -p "$SESSIONS_DIR"

# Create a temporary file to store the Claude output
echo "Invoking Claude's compact command and saving results..."
echo "Once Claude generates the summary, press Ctrl+C to exit Claude"
echo ""
echo "Processing..."

# Run the claude command with /compact
claude | tee "$TEMP_FILE"

# Extract the summary part (anything between <summary> and </summary>)
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
  rm "$TEMP_FILE.extract"
else
  echo ""
  echo "❌ No compact summary found in the output."
  echo "Did you run the /compact command in Claude?"
fi

# Keep the temp file for reference
echo "Full session log saved to: $TEMP_FILE"