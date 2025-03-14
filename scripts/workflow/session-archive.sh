#!/bin/bash

# session-archive.sh - Archives older sessions from SESSION.md
# This script maintains a manageable size for SESSION.md while preserving history
#
# Usage:
#   ./session-archive.sh                  # Archive all but the last 3 sessions
#   ./session-archive.sh --keep=N         # Keep N most recent sessions in SESSION.md
#   ./session-archive.sh --retrieve=DATE  # View a specific archived session by date (YYYYMMDD)
#   ./session-archive.sh --list           # List all archived sessions

# Get the workflow directory
WORKFLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get the repository root directory 
REPO_DIR="$(cd "$WORKFLOW_DIR/../.." && pwd)"
SESSION_FILE="$REPO_DIR/SESSION.md"
ARCHIVE_DIR="$REPO_DIR/docs/workflow/session-archives"

# Make sure the archive directory exists
mkdir -p "$ARCHIVE_DIR"

# Default number of sessions to keep in SESSION.md
SESSIONS_TO_KEEP=3

# Function to list all archived sessions
list_archives() {
  echo "Available archived sessions:"
  echo "-----------------------------"
  
  if [ ! "$(ls -A "$ARCHIVE_DIR" 2>/dev/null)" ]; then
    echo "No archived sessions found."
    return
  fi
  
  for file in "$ARCHIVE_DIR"/session-*.md; do
    if [ -f "$file" ]; then
      base_name=$(basename "$file")
      date_part=${base_name#session-}
      date_part=${date_part%.md}
      
      # Format the date for display (YYYY-MM-DD)
      formatted_date="${date_part:0:4}-${date_part:4:2}-${date_part:6:2}"
      
      # Extract the first session header for context
      session_title=$(grep -m 1 "^## " "$file" | sed 's/^## //')
      
      echo "$formatted_date: $session_title"
    fi
  done
}

# Function to retrieve a specific archived session
retrieve_archive() {
  DATE=$1
  ARCHIVE_FILE="$ARCHIVE_DIR/session-$DATE.md"
  
  if [ ! -f "$ARCHIVE_FILE" ]; then
    echo "No archive found for date: $DATE"
    echo "Use --list to see available archives."
    return 1
  fi
  
  echo "Session archive from $DATE:"
  echo "===================================="
  echo ""
  cat "$ARCHIVE_FILE"
}

# Function to extract a session from SESSION.md
extract_session() {
  local session_start=$1
  local session_end=$2
  local temp_file=$3
  
  sed -n "${session_start},${session_end}p" "$SESSION_FILE" > "$temp_file"
}

# Function to archive sessions
archive_sessions() {
  # Find session boundaries (lines with "## Current Session:")
  SESSION_BOUNDARIES=($(grep -n "^## Current Session:" "$SESSION_FILE" | cut -d: -f1))
  
  # Count number of sessions
  NUM_SESSIONS=${#SESSION_BOUNDARIES[@]}
  
  # If we have more sessions than we want to keep
  if [ "$NUM_SESSIONS" -gt "$SESSIONS_TO_KEEP" ]; then
    echo "Found $NUM_SESSIONS sessions, keeping $SESSIONS_TO_KEEP recent ones"
    
    # Archive older sessions
    for ((i=$SESSIONS_TO_KEEP; i<$NUM_SESSIONS; i++)); do
      # Calculate the starting and ending line for this session
      current_idx=$i
      session_start=${SESSION_BOUNDARIES[$current_idx]}
      
      # If this is the last session, end at EOF
      if [ "$current_idx" -eq $(($NUM_SESSIONS - 1)) ]; then
        session_end='$'
      else
        next_idx=$(($current_idx + 1))
        session_end=$((${SESSION_BOUNDARIES[$next_idx]} - 1))
      fi
      
      # Extract session date from header
      SESSION_DATE=$(sed -n "${session_start}p" "$SESSION_FILE" | grep -o "[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}" || \
                    sed -n "${session_start}p" "$SESSION_FILE" | grep -o "[A-Z][a-z]* [0-9]\{1,2\}, [0-9]\{4\}")
      
      # Format date for the filename (YYYYMMDD)
      if [[ "$SESSION_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        # Already in YYYY-MM-DD format
        ARCHIVE_DATE=$(echo "$SESSION_DATE" | tr -d '-')
      else
        # Convert from Month DD, YYYY format
        ARCHIVE_DATE=$(date -d "$SESSION_DATE" +"%Y%m%d" 2>/dev/null)
        
        # If conversion fails, use a timestamp
        if [ $? -ne 0 ]; then
          ARCHIVE_DATE=$(date +"%Y%m%d")
        fi
      fi
      
      # Create archive file
      ARCHIVE_FILE="$ARCHIVE_DIR/session-$ARCHIVE_DATE.md"
      
      # Extract session content to temp file
      TEMP_FILE=$(mktemp)
      extract_session "$session_start" "$session_end" "$TEMP_FILE"
      
      # Add header to archive file if it doesn't exist yet
      if [ ! -f "$ARCHIVE_FILE" ]; then
        echo "# Archived Session: $SESSION_DATE" > "$ARCHIVE_FILE"
        echo "" >> "$ARCHIVE_FILE"
      fi
      
      # Append session content to archive file
      cat "$TEMP_FILE" >> "$ARCHIVE_FILE"
      
      # Clean up temp file
      rm "$TEMP_FILE"
      
      echo "Archived session from $SESSION_DATE to $ARCHIVE_FILE"
    done
    
    # Keep only the most recent sessions in SESSION.md
    TEMP_FILE=$(mktemp)
    
    # Start with a fresh file
    echo "# Synapse Development Session Log" > "$TEMP_FILE"
    echo "" >> "$TEMP_FILE"
    
    # Add the sessions to keep
    for ((i=0; i<$SESSIONS_TO_KEEP; i++)); do
      session_start=${SESSION_BOUNDARIES[$i]}
      
      if [ "$i" -eq $(($SESSIONS_TO_KEEP - 1)) ]; then
        session_end='$'
      else
        next_idx=$(($i + 1))
        session_end=$((${SESSION_BOUNDARIES[$next_idx]} - 1))
      fi
      
      # Extract this session
      extract_session "$session_start" "$session_end" "$TEMP_FILE.session"
      
      # Append it to the new SESSION.md
      cat "$TEMP_FILE.session" >> "$TEMP_FILE"
      rm "$TEMP_FILE.session"
    done
    
    # Replace SESSION.md with our new version
    mv "$TEMP_FILE" "$SESSION_FILE"
    
    echo "Updated SESSION.md, keeping the $SESSIONS_TO_KEEP most recent sessions"
    
    # Add a note about archived sessions if not already present
    if ! grep -q "## Archived Sessions" "$SESSION_FILE"; then
      echo "" >> "$SESSION_FILE"
      echo "## Archived Sessions" >> "$SESSION_FILE"
      echo "Older sessions are archived in docs/workflow/session-archives/. Use \`./scripts/workflow/session-archive.sh --list\` to view them." >> "$SESSION_FILE"
    fi
  else
    echo "SESSION.md has $NUM_SESSIONS sessions, no archiving needed (keeping $SESSIONS_TO_KEEP)"
  fi
}

# Process command line arguments
if [ "$#" -eq 0 ]; then
  # No arguments, run default archiving
  archive_sessions
elif [ "$1" = "--list" ]; then
  # List all archived sessions
  list_archives
elif [[ "$1" =~ ^--retrieve=([0-9]{8})$ ]]; then
  # Retrieve a specific archive by date
  retrieve_archive "${BASH_REMATCH[1]}"
elif [[ "$1" =~ ^--keep=([0-9]+)$ ]]; then
  # Set custom number of sessions to keep
  SESSIONS_TO_KEEP="${BASH_REMATCH[1]}"
  archive_sessions
else
  echo "Usage:"
  echo "  $0                  # Archive all but the last $SESSIONS_TO_KEEP sessions"
  echo "  $0 --keep=N         # Keep N most recent sessions in SESSION.md"
  echo "  $0 --retrieve=DATE  # View a specific archived session by date (YYYYMMDD)"
  echo "  $0 --list           # List all archived sessions"
  exit 1
fi