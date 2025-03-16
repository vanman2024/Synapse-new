#!/bin/bash

# claude.sh - Claude AI integration functions for synergy.sh

# Import config
source "$(dirname "${BASH_SOURCE[0]}")/../core/config.sh"

# Start Claude with project context
start_claude() {
  # Check if claude CLI command exists
  if ! command_exists claude; then
    echo_color "$RED" "Claude CLI not found. Please install it first."
    return 1
  fi
  
  echo_color "$BLUE" "Starting Claude with project context..."
  
  # Create a context file with project information
  CONTEXT_FILE=$(mktemp)
  
  # Add basic project info
  echo "# Synapse Project Context" > "$CONTEXT_FILE"
  echo "- Current date: $(date '+%Y-%m-%d')" >> "$CONTEXT_FILE"
  echo "- Current branch: $(git branch --show-current)" >> "$CONTEXT_FILE"
  echo "" >> "$CONTEXT_FILE"
  
  # Add overview highlights
  echo "## Project Status" >> "$CONTEXT_FILE"
  grep -A 10 "(Current)" "$OVERVIEW_FILE" >> "$CONTEXT_FILE"
  echo "" >> "$CONTEXT_FILE"
  
  # Add recent git activity
  echo "## Recent Git Activity" >> "$CONTEXT_FILE"
  git log --oneline -n 5 >> "$CONTEXT_FILE"
  echo "" >> "$CONTEXT_FILE"
  
  # Add current session details if active
  if [ -f "/tmp/synergy/active_session" ]; then
    echo "## Current Session" >> "$CONTEXT_FILE"
    IFS=',' read -r BRANCH FOCUS_MODULE START_TIME <<< "$(cat "/tmp/synergy/active_session")"
    echo "Current Branch: $BRANCH" >> "$CONTEXT_FILE"
    echo "Current Focus: $FOCUS_MODULE" >> "$CONTEXT_FILE"
    echo "Started at: $START_TIME" >> "$CONTEXT_FILE"
  fi
  
  # Start Claude with the context
  claude < "$CONTEXT_FILE"
  
  # Clean up
  rm "$CONTEXT_FILE"
  
  return 0
}

# Save Claude compact summary
save_compact() {
  COMPACT_DATE=$(date '+%Y%m%d')
  COMPACT_DIR="/tmp/synergy/claude-compacts"
  COMPACT_FILE="$COMPACT_DIR/compact-$COMPACT_DATE.md"
  
  # Ensure directory exists
  mkdir -p "$COMPACT_DIR"
  
  # Create a temporary file for the input
  TEMP_FILE=$(mktemp)
  
  echo_color "$BLUE" "Paste the compact summary below (press Ctrl+D when done):"
  cat > "$TEMP_FILE"
  
  # Extract content between <summary> tags if present
  if grep -q "<summary>" "$TEMP_FILE" && grep -q "</summary>" "$TEMP_FILE"; then
    sed -n '/<summary>/,/<\/summary>/p' "$TEMP_FILE" | sed 's/<summary>//g' | sed 's/<\/summary>//g' > "$TEMP_FILE.extract"
    mv "$TEMP_FILE.extract" "$TEMP_FILE"
  fi
  
  # Save to compact file
  if [ ! -f "$COMPACT_FILE" ]; then
    # First summary of the day
    echo "# Claude Compact Summary - $(date '+%B %d, %Y')" > "$COMPACT_FILE"
    echo "" >> "$COMPACT_FILE"
  else
    # Append a separator
    echo "" >> "$COMPACT_FILE"
    echo "---" >> "$COMPACT_FILE"
    echo "" >> "$COMPACT_FILE"
  fi
  
  # Add timestamp
  echo "## Session at $(date '+%H:%M:%S')" >> "$COMPACT_FILE"
  echo "" >> "$COMPACT_FILE"
  
  # Append content
  cat "$TEMP_FILE" >> "$COMPACT_FILE"
  
  # Clean up
  rm "$TEMP_FILE"
  
  echo_color "$GREEN" "Compact summary saved to: $COMPACT_FILE"
  
  # Log activity if there's an active session
  if [ -f "/tmp/synergy/active_session" ]; then
    log_activity "Saved Claude compact summary"
  fi
  
  return 0
}

# Start compact watcher in background
start_compact_watch() {
  COMPACT_DIR="/tmp/synergy/claude-compacts"
  WATCH_DIR="$COMPACT_DIR/compact-watch"
  WATCH_PID_FILE="/tmp/synergy/compact-watch.pid"
  
  # Check if already running
  if [ -f "$WATCH_PID_FILE" ] && ps -p $(cat "$WATCH_PID_FILE") > /dev/null; then
    echo_color "$YELLOW" "Compact watcher is already running."
    return 0
  fi
  
  # Ensure directories exist
  mkdir -p "$WATCH_DIR"
  mkdir -p "$COMPACT_DIR/processed"
  
  # Start the watcher in background
  (
    while true; do
      # Check for new files
      for file in "$WATCH_DIR"/*; do
        if [ -f "$file" ] && [ ! -L "$file" ]; then
          # Process the file
          COMPACT_DATE=$(date '+%Y%m%d')
          COMPACT_FILE="$COMPACT_DIR/compact-$COMPACT_DATE.md"
          
          # Extract content between <summary> tags if present
          if grep -q "<summary>" "$file" && grep -q "</summary>" "$file"; then
            TEMP_FILE=$(mktemp)
            sed -n '/<summary>/,/<\/summary>/p' "$file" | sed 's/<summary>//g' | sed 's/<\/summary>//g' > "$TEMP_FILE"
            
            # Save to compact file
            if [ ! -f "$COMPACT_FILE" ]; then
              # First summary of the day
              echo "# Claude Compact Summary - $(date '+%B %d, %Y')" > "$COMPACT_FILE"
              echo "" >> "$COMPACT_FILE"
            else
              # Append a separator
              echo "" >> "$COMPACT_FILE"
              echo "---" >> "$COMPACT_FILE"
              echo "" >> "$COMPACT_FILE"
            fi
            
            # Add timestamp
            echo "## Session at $(date '+%H:%M:%S')" >> "$COMPACT_FILE"
            echo "" >> "$COMPACT_FILE"
            
            # Append content
            cat "$TEMP_FILE" >> "$COMPACT_FILE"
            
            # Clean up
            rm "$TEMP_FILE"
            
            # Move the processed file
            mv "$file" "$COMPACT_DIR/processed/$(basename "$file").$(date +"%H%M%S")"
          fi
        fi
      done
      
      # Wait before checking again
      sleep 5
    done
  ) &
  
  # Save PID
  echo $! > "$WATCH_PID_FILE"
  
  echo_color "$GREEN" "Compact watcher started in background."
  echo_color "$BLUE" "Save compact outputs to: $WATCH_DIR"
  
  return 0
}

# Stop compact watcher
stop_compact_watch() {
  WATCH_PID_FILE="/tmp/synergy/compact-watch.pid"
  
  if [ -f "$WATCH_PID_FILE" ]; then
    PID=$(cat "$WATCH_PID_FILE")
    if ps -p $PID > /dev/null; then
      kill $PID
      rm "$WATCH_PID_FILE"
      echo_color "$GREEN" "Compact watcher stopped."
      return 0
    fi
  fi
  
  echo_color "$YELLOW" "No compact watcher found."
  return 1
}