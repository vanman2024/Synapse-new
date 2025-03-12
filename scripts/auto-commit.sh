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

# Function to update RECOVERY.md file
update_recovery_file() {
  RECOVERY_FILE="$REPO_DIR/RECOVERY.md"
  TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
  
  # Only update if the file exists
  if [ -f "$RECOVERY_FILE" ]; then
    # Add last commit information
    LAST_COMMIT=$(git log -1 --pretty=format:"%h - %s")
    MODIFIED_FILES=$(git log -1 --name-only --pretty=format:"" | grep -v "RECOVERY.md" | sort | head -n 10)
    
    # Update the "Last Updated" section of the file
    sed -i '/## Last Auto-Update/,/## Current Progress/c\
## Last Auto-Update\
- **Timestamp:** '"$TIMESTAMP"'\
- **Last Commit:** '"$LAST_COMMIT"'\
- **Recently Modified Files:**\
```\
'"$MODIFIED_FILES"'\
```\
\
## Current Progress' "$RECOVERY_FILE"
    
    echo "Updated RECOVERY.md at $TIMESTAMP"
  fi
}

# Function to commit and push changes
commit_and_push() {
  cd "$REPO_DIR"
  
  # Check if there are changes to commit
  if git status --porcelain | grep -q .; then
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    
    # Update recovery file before committing
    update_recovery_file
    
    git add .
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