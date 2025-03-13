#!/bin/bash

# Auto-commit script to regularly push changes to GitHub
# Usage: ./scripts/auto-commit.sh [interval_minutes]

# Default interval is 5 minutes if not specified
INTERVAL=${1:-5}
REPO_DIR="$(pwd)"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

echo "Auto-commit script started at $TIMESTAMP"
echo "Working in: $REPO_DIR"
echo "Commit interval: $INTERVAL minutes"

# Make sure we're in a git repository
if [ ! -d "$REPO_DIR/.git" ]; then
  echo "Error: Not a git repository"
  exit 1
fi

# Function to update the SESSION.md file with commit information
update_session_file() {
  SESSION_FILE="$REPO_DIR/SESSION.md"
  TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
  
  # Make sure SESSION.md exists
  if [ ! -f "$SESSION_FILE" ]; then
    echo "Error: SESSION.md not found. Unable to update session tracking."
    return 1
  fi
  
  # Update the current session date
  sed -i "s/## Current Session:.*$/## Current Session: $(date +"%B %d, %Y")/" "$SESSION_FILE"
  
  echo "Updated session file at $TIMESTAMP"
}

# Function to commit and push changes
commit_and_push() {
  cd "$REPO_DIR"
  
  # Update the session file
  update_session_file
  
  # Run the session tracker to update SESSION.md with details
  if [ -f "$REPO_DIR/scripts/auto-session-tracker.sh" ]; then
    $REPO_DIR/scripts/auto-session-tracker.sh
    echo "Updated SESSION.md with latest activity"
  fi
  
  # Check if there are changes to commit
  if git status --porcelain | grep -q .; then
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    
    # Add all changes
    git add .
    
    # Commit and push
    git commit -m "Auto-commit: $TIMESTAMP"
    git push origin master
    echo "Changes committed and pushed at $TIMESTAMP"
  else
    echo "No changes to commit at $(date +"%Y-%m-%d %H:%M:%S")"
  fi
}

# Initial commit
commit_and_push

# Set up repeated commits
echo "Press Ctrl+C to stop auto-committing"
while true; do
  echo "Waiting $INTERVAL minutes before next commit..."
  sleep $(($INTERVAL * 60))
  commit_and_push
done