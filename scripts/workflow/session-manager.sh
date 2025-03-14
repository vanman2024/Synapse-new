#!/bin/bash

# session-manager.sh - Manages Claude sessions with unique IDs and storage

# Check if jq is installed
if ! command -v jq &> /dev/null; then
  echo "jq is required but not installed. Using fallback methods."
  JQ_AVAILABLE=false
else
  JQ_AVAILABLE=true
fi
# Usage: 
#   ./session-manager.sh start - Start a new session
#   ./session-manager.sh end - End the current session
#   ./session-manager.sh get SESSION_ID - Get data from a specific session
#   ./session-manager.sh list - List all sessions
#   ./session-manager.sh current - Get the current session info

# Get the workflow directory
WORKFLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get the repository root directory
REPO_DIR="$(cd "$WORKFLOW_DIR/../.." && pwd)"
SESSIONS_DIR="$REPO_DIR/sessions"
INDEX_FILE="$SESSIONS_DIR/sessions-index.json"
SESSION_FILE="$REPO_DIR/SESSION.md"

# Make sure the sessions directory exists
mkdir -p "$SESSIONS_DIR"

# Initialize the index file if it doesn't exist
if [ ! -f "$INDEX_FILE" ]; then
  echo '{"sessions": [], "current_session_id": null, "last_update": null}' > "$INDEX_FILE"
fi

# Fallback get_current_session_id for when jq is not available
get_current_session_id_fallback() {
  grep -o '"current_session_id": *"[^"]*"' "$INDEX_FILE" | grep -o '"[^"]*"$' | tr -d '"'
}$' | tr -d '"'
}

# Generate a unique session ID
generate_session_id() {
  echo "$(date +"%Y%m%d%H%M%S")-$(head /dev/urandom | tr -dc a-z0-9 | head -c 6)"
}

# Get the current session ID
get_current_session_id() {
  if [ "$JQ_AVAILABLE" = true ]; then
    CURRENT_ID=$(jq -r '.current_session_id' "$INDEX_FILE")
    if [ "$CURRENT_ID" = "null" ]; then
      echo ""
    else
      echo "$CURRENT_ID"
    fi
  else
    get_current_session_id_fallback
  fi
}

# Start a new session
start_session() {
  # Generate a new session ID
  NEW_SESSION_ID=$(generate_session_id)
  TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
  
  # Create the session file
  SESSION_DATA_FILE="$SESSIONS_DIR/$NEW_SESSION_ID.json"
  
  # Get the current branch
  BRANCH=$(git branch --show-current)
  
  # Create initial session data
  echo "{
    \"session_id\": \"$NEW_SESSION_ID\",
    \"started_at\": \"$TIMESTAMP\",
    \"branch\": \"$BRANCH\",
    \"status\": \"active\",
    \"focus\": [],
    \"activities\": [],
    \"files_modified\": [],
    \"notes\": []
  }" > "$SESSION_DATA_FILE"
  
  # Update the index file
  if [ "$JQ_AVAILABLE" = true ]; then
    CURRENT_INDEX=$(cat "$INDEX_FILE")
    UPDATED_INDEX=$(echo "$CURRENT_INDEX" | jq ".sessions += [{\"id\": \"$NEW_SESSION_ID\", \"started_at\": \"$TIMESTAMP\", \"branch\": \"$BRANCH\", \"status\": \"active\"}] | .current_session_id = \"$NEW_SESSION_ID\" | .last_update = \"$TIMESTAMP\"")
    echo "$UPDATED_INDEX" > "$INDEX_FILE"
  else
    # Simple fallback that updates the index file
    # This is less elegant but works without jq
    grep -v '"current_session_id"' "$INDEX_FILE" > "$INDEX_FILE.tmp"
    grep -v '"last_update"' "$INDEX_FILE.tmp" > "$INDEX_FILE"
    sed -i 's/"sessions": \[/"sessions": \[\n    {"id": "'"$NEW_SESSION_ID"'", "started_at": "'"$TIMESTAMP"'", "branch": "'"$BRANCH"'", "status": "active"},/' "$INDEX_FILE"
    echo "  \"current_session_id\": \"$NEW_SESSION_ID\"," >> "$INDEX_FILE"
    echo "  \"last_update\": \"$TIMESTAMP\"" >> "$INDEX_FILE"
    echo "}" >> "$INDEX_FILE"
  fi
  
  # Update SESSION.md with the session ID
  if [ -f "$SESSION_FILE" ]; then
    # Try to extract the current sprint information
    SPRINT_INFO=$(sed -n '/### Current Sprint/,/### Progress Tracker/p' "$SESSION_FILE" | head -n -1)
    
    # Extract current focus if it exists
    CURRENT_FOCUS=$(sed -n '/#### Current Focus/,/#### Last Activity/p' "$SESSION_FILE" | head -n -1 | tail -n +2)
    
    # Extract next tasks if they exist
    NEXT_TASKS=$(sed -n '/#### Next Tasks/,/### Code Context/p' "$SESSION_FILE" | head -n -1 | tail -n +2)
    
    # Update the session data with this information
    if [ -n "$CURRENT_FOCUS" ]; then
      UPDATED_SESSION=$(jq ".focus = [\"$(echo "$CURRENT_FOCUS" | tr '\n' ' ' | sed 's/"/\\"/g')\"]" "$SESSION_DATA_FILE")
      echo "$UPDATED_SESSION" > "$SESSION_DATA_FILE"
    fi
    
    # Update SESSION.md with the session ID by creating a temporary file
    CURRENT_DATE=$(date +"%B %d, %Y")
    SESSION_HEADER="## Current Session: $CURRENT_DATE - ID $NEW_SESSION_ID"
    
    # Replace the session header using a temporary file
    sed "s/## Current Session:.*$/$SESSION_HEADER/" "$SESSION_FILE" > "$SESSION_FILE.tmp"
    mv "$SESSION_FILE.tmp" "$SESSION_FILE"
    
    # Add previous session reference if there was a current session
    PREV_SESSION_ID=$(get_current_session_id)
    if [ -n "$PREV_SESSION_ID" ] && [ "$PREV_SESSION_ID" != "null" ]; then
      if ! grep -q "### Previous Sessions" "$SESSION_FILE"; then
        # Add the Previous Sessions section if it doesn't exist
        sed -i "/## Current Session/a \\
### Previous Sessions\\
- $PREV_SESSION_ID: $(date -d "$(jq -r ".sessions[] | select(.id == \"$PREV_SESSION_ID\") | .started_at" "$INDEX_FILE")" "+%B %d, %Y %H:%M")" "$SESSION_FILE"
      else
        # Update the Previous Sessions section
        sed -i "/### Previous Sessions/a \\
- $PREV_SESSION_ID: $(date -d "$(jq -r ".sessions[] | select(.id == \"$PREV_SESSION_ID\") | .started_at" "$INDEX_FILE")" "+%B %d, %Y %H:%M")" "$SESSION_FILE"
      fi
    fi
  fi
  
  echo "Started new session with ID: $NEW_SESSION_ID"
  echo "Session data stored in: $SESSION_DATA_FILE"
}

# End the current session
end_session() {
  CURRENT_ID=$(get_current_session_id)
  
  if [ -z "$CURRENT_ID" ] || [ "$CURRENT_ID" = "null" ]; then
    echo "No active session found"
    return 1
  fi
  
  TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
  SESSION_DATA_FILE="$SESSIONS_DIR/$CURRENT_ID.json"
  
  if [ ! -f "$SESSION_DATA_FILE" ]; then
    echo "Session data file not found: $SESSION_DATA_FILE"
    return 1
  fi
  
  # Update the session data
  UPDATED_SESSION=$(jq ".ended_at = \"$TIMESTAMP\" | .status = \"completed\"" "$SESSION_DATA_FILE")
  echo "$UPDATED_SESSION" > "$SESSION_DATA_FILE"
  
  # Get the last commit message and files
  LAST_COMMIT_MSG=$(git log -1 --pretty=%B)
  LAST_COMMIT_FILES=$(git log -1 --name-only --pretty=format:"")
  
  # Add final activity to the session data
  ACTIVITIES=$(jq ".activities" "$SESSION_DATA_FILE")
  UPDATED_ACTIVITIES=$(jq ".activities += [{\"timestamp\": \"$TIMESTAMP\", \"type\": \"session_end\", \"message\": \"Session ended\", \"files\": [\"$LAST_COMMIT_FILES\"]}]" "$SESSION_DATA_FILE")
  echo "$UPDATED_ACTIVITIES" > "$SESSION_DATA_FILE"
  
  # Update the index file
  UPDATED_INDEX=$(jq ".sessions[] |= if .id == \"$CURRENT_ID\" then .status = \"completed\" | .ended_at = \"$TIMESTAMP\" else . end | .current_session_id = null | .last_update = \"$TIMESTAMP\"" "$INDEX_FILE")
  echo "$UPDATED_INDEX" > "$INDEX_FILE"
  
  echo "Ended session with ID: $CURRENT_ID"
}

# Get data from a specific session
get_session() {
  SESSION_ID=$1
  
  if [ -z "$SESSION_ID" ]; then
    echo "Please provide a session ID"
    return 1
  fi
  
  SESSION_DATA_FILE="$SESSIONS_DIR/$SESSION_ID.json"
  
  if [ ! -f "$SESSION_DATA_FILE" ]; then
    echo "Session not found: $SESSION_ID"
    return 1
  fi
  
  cat "$SESSION_DATA_FILE"
}

# List all sessions
list_sessions() {
  if [ ! -f "$INDEX_FILE" ]; then
    echo "No sessions found"
    return 1
  fi
  
  jq -r '.sessions[] | "ID: \(.id) | Started: \(.started_at) | Status: \(.status) | Branch: \(.branch)"' "$INDEX_FILE"
}

# Get the current session info
current_session() {
  CURRENT_ID=$(get_current_session_id)
  
  if [ -z "$CURRENT_ID" ] || [ "$CURRENT_ID" = "null" ]; then
    echo "No active session found"
    return 1
  fi
  
  get_session "$CURRENT_ID"
}

# Log activity to the current session
log_activity() {
  ACTIVITY_TYPE=$1
  ACTIVITY_MESSAGE=$2
  FILES=$3
  
  CURRENT_ID=$(get_current_session_id)
  
  if [ -z "$CURRENT_ID" ] || [ "$CURRENT_ID" = "null" ]; then
    echo "No active session found"
    return 1
  fi
  
  SESSION_DATA_FILE="$SESSIONS_DIR/$CURRENT_ID.json"
  
  if [ ! -f "$SESSION_DATA_FILE" ]; then
    echo "Session data file not found: $SESSION_DATA_FILE"
    return 1
  fi
  
  TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
  
  # Add activity to the session data
  if [ "$JQ_AVAILABLE" = true ]; then
    UPDATED_SESSION=$(jq ".activities += [{\"timestamp\": \"$TIMESTAMP\", \"type\": \"$ACTIVITY_TYPE\", \"message\": \"$ACTIVITY_MESSAGE\", \"files\": [\"$FILES\"]}]" "$SESSION_DATA_FILE")
    echo "$UPDATED_SESSION" > "$SESSION_DATA_FILE"
  else
    # Simple fallback that appends to activities array
    # This is less robust but works without jq
    sed -i 's/"activities": \[/"activities": \[\n    {"timestamp": "'"$TIMESTAMP"'", "type": "'"$ACTIVITY_TYPE"'", "message": "'"$ACTIVITY_MESSAGE"'", "files": ["'"$FILES"'"]},/' "$SESSION_DATA_FILE"
  fi
  
  echo "Logged activity to session $CURRENT_ID"
}

# Main function to handle subcommands
main() {
  COMMAND=$1
  shift
  
  case "$COMMAND" in
    start)
      start_session
      ;;
    end)
      end_session
      ;;
    get)
      get_session "$1"
      ;;
    list)
      list_sessions
      ;;
    current)
      current_session
      ;;
    log)
      log_activity "$1" "$2" "$3"
      ;;
    *)
      echo "Usage: $0 {start|end|get|list|current|log}"
      exit 1
      ;;
  esac
}

# Call the main function with all arguments
main "$@"