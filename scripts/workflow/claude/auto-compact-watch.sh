#!/bin/bash

# auto-compact-watch.sh - Watches Claude session files for compact summaries
# This script runs in the background and automatically saves compact summaries
# without requiring any copy/paste action from the user

# Get script directory and repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CLAUDE_DIR="$REPO_DIR/sessions/claude"
DATE=$(date +"%Y%m%d")
TIME=$(date +"%H:%M:%S")
FORMATTED_DATE=$(date +"%B %d, %Y")
COMPACT_FILE="$CLAUDE_DIR/compact-$DATE.md"
WATCH_DIR="$REPO_DIR/sessions/claude"
LOCK_FILE="/tmp/auto-compact-watch.lock"

# Make sure the directories exist
mkdir -p "$CLAUDE_DIR"

# Check if another instance is running
if [ -f "$LOCK_FILE" ] && ps -p $(cat "$LOCK_FILE") > /dev/null; then
  echo "❌ Another auto-compact-watch process is already running (PID: $(cat "$LOCK_FILE"))"
  echo "If this is incorrect, delete the lock file: $LOCK_FILE"
  exit 1
fi

# Create lock file
echo $$ > "$LOCK_FILE"

# Cleanup on exit
trap 'rm -f "$LOCK_FILE"; echo "Stopping compact summary watcher ($(date))"; exit' INT TERM EXIT

# Log function - only print to console, no file logging
log() {
  echo "[$(date "+%Y-%m-%d %H:%M:%S")] $1"
}

# Save compact summary function
save_compact() {
  local summary_file=$1
  local temp_file=$(mktemp)
  
  log "Processing file: $summary_file"
  
  # Extract content between <summary> tags
  if grep -q "<summary>" "$summary_file" && grep -q "</summary>" "$summary_file"; then
    log "Found <summary> tags, extracting content..."
    sed -n '/<summary>/,/<\/summary>/p' "$summary_file" | sed 's/<summary>//g' | sed 's/<\/summary>//g' > "$temp_file"
    
    # Save to compact-YYYYMMDD.md (appending if it exists)
    if [ ! -f "$COMPACT_FILE" ]; then
      # First summary of the day - create the file with header
      echo "# Claude Compact Summary - $FORMATTED_DATE" > "$COMPACT_FILE"
      echo "" >> "$COMPACT_FILE"
      log "Created new compact file for today: $COMPACT_FILE"
    else
      # Append a separator for additional summaries
      echo "" >> "$COMPACT_FILE"
      echo "---" >> "$COMPACT_FILE"
      echo "" >> "$COMPACT_FILE"
      log "Appending to existing compact file: $COMPACT_FILE"
    fi
    
    # Add a timestamp for this summary
    echo "## Session at $(date +"%H:%M:%S")" >> "$COMPACT_FILE"
    echo "" >> "$COMPACT_FILE"
    
    # Append the summary content
    cat "$temp_file" >> "$COMPACT_FILE"
    
    # Update the sessions index file
    SESSIONS_INDEX="$CLAUDE_DIR/sessions-index.json"
    
    # Create index file if it doesn't exist or is empty
    if [ ! -s "$SESSIONS_INDEX" ]; then
      echo '{"sessions":[]}' > "$SESSIONS_INDEX"
    fi
    
    # Add the session to the index using jq if available, otherwise append to a log file
    if command -v jq >/dev/null 2>&1; then
      TEMP_JSON=$(mktemp)
      jq --arg date "$(date +"%Y-%m-%d")" \
         --arg time "$(date +"%H:%M")" \
         --arg file "compact-$DATE.md" \
         '.sessions += [{"date": $date, "time": $time, "compact": $file}]' \
         "$SESSIONS_INDEX" > "$TEMP_JSON" && mv "$TEMP_JSON" "$SESSIONS_INDEX"
      log "Updated sessions index JSON"
    else
      echo "$(date +"%Y-%m-%d %H:%M") - compact-$DATE.md" >> "$CLAUDE_DIR/sessions-log.txt"
      log "Updated sessions log (jq not available)"
    fi
    
    log "✅ Summary saved successfully to: $COMPACT_FILE"
    
    # Move the processed file to avoid processing it again
    mkdir -p "$CLAUDE_DIR/processed"
    mv "$summary_file" "$CLAUDE_DIR/processed/$(basename "$summary_file").$(date +"%H%M%S")"
    log "Moved processed file to: $CLAUDE_DIR/processed/$(basename "$summary_file").$(date +"%H%M%S")"
  else
    log "⚠️ No <summary> tags found in $summary_file"
  fi
  
  # Clean up
  rm -f "$temp_file"
}

# Start the watcher
log "Starting compact summary auto-watcher..."
log "Watching directory: $WATCH_DIR"
log "Compact summaries will be saved to: $COMPACT_FILE"
log "To stop, press Ctrl+C"
echo ""

# Create a watch folder for summaries if it doesn't exist
COMPACT_WATCH_DIR="$WATCH_DIR/compact-watch"
mkdir -p "$COMPACT_WATCH_DIR"
log "Created watch directory: $COMPACT_WATCH_DIR"
log "To automatically save a summary:"
log "1. Run /compact in Claude"
log "2. Save the summary as a file in: $COMPACT_WATCH_DIR"
log "3. This script will detect and process it automatically"
echo ""

# Main loop
while true; do
  # Check for new files in the watch directory
  for file in "$COMPACT_WATCH_DIR"/*; do
    if [ -f "$file" ] && [ ! -L "$file" ]; then
      save_compact "$file"
    fi
  done
  
  # Wait a bit before checking again
  sleep 5
done