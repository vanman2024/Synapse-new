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

# Function to update commit-log.txt file instead of modifying the human-readable RECOVERY.md
update_recovery_file() {
  COMMIT_LOG="$REPO_DIR/commit-log.txt"
  TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
  
  # Create the commit log file if it doesn't exist
  if [ ! -f "$COMMIT_LOG" ]; then
    echo "# Synapse Project - Commit Log" > "$COMMIT_LOG"
    echo "" >> "$COMMIT_LOG"
    echo "This file automatically tracks all commits to the repository." >> "$COMMIT_LOG"
    echo "" >> "$COMMIT_LOG"
  fi
  
  # Get last commit information
  LAST_COMMIT=$(git log -1 --pretty=format:"%h - %s")
  MODIFIED_FILES=$(git log -1 --name-only --pretty=format:"" | grep -v "RECOVERY.md" | sort | head -n 10)
  
  # Append the new commit information to the log file
  echo "## Commit at $TIMESTAMP" >> "$COMMIT_LOG"
  echo "- **Commit:** $LAST_COMMIT" >> "$COMMIT_LOG"
  echo "- **Files:**" >> "$COMMIT_LOG"
  echo '```' >> "$COMMIT_LOG"
  if [ -z "$MODIFIED_FILES" ]; then
    echo "No files changed (other than RECOVERY.md)" >> "$COMMIT_LOG"
  else
    echo "$MODIFIED_FILES" >> "$COMMIT_LOG"
  fi
  echo '```' >> "$COMMIT_LOG"
  echo "" >> "$COMMIT_LOG"
  
  # Update the Last Updated date in RECOVERY.md using sed
  RECOVERY_FILE="$REPO_DIR/RECOVERY.md"
  if [ -f "$RECOVERY_FILE" ]; then
    # Update only the date in the Last Updated line
    sed -i "s/> Last Updated:.*/>\ Last Updated: $(date +"%B %d, %Y")/" "$RECOVERY_FILE"
  fi
  
  echo "Updated commit log at $TIMESTAMP"
}

# Function to commit and push changes
commit_and_push() {
  cd "$REPO_DIR"
  
  # Always update the commit log and recovery file
  update_recovery_file
  
  # Run the session tracker to update SESSION.md
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