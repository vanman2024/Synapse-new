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

# Function to get list of files to be tracked, considering .autocommitignore
get_tracked_files() {
  # First get all modified and untracked files
  ALL_CHANGES=$(git status --porcelain | grep -v "^D " | awk '{print $2}')
  
  # If .autocommitignore exists, filter files using grep -v
  IGNORE_FILE="$REPO_DIR/.autocommitignore"
  if [ -f "$IGNORE_FILE" ]; then
    # Create a temporary filtered ignore file without comments and blank lines
    TEMP_IGNORE_FILE="/tmp/temp_ignore_patterns.txt"
    grep -v "^#" "$IGNORE_FILE" | grep -v "^$" > "$TEMP_IGNORE_FILE"
    
    if [ -s "$TEMP_IGNORE_FILE" ]; then
      # Filter out ignored files
      TRACKED_FILES=""
      for FILE in $ALL_CHANGES; do
        IGNORE_THIS=false
        while IFS= read -r PATTERN; do
          if [[ "$FILE" == $PATTERN ]]; then
            IGNORE_THIS=true
            break
          fi
        done < "$TEMP_IGNORE_FILE"
        
        if [ "$IGNORE_THIS" = false ]; then
          TRACKED_FILES="$TRACKED_FILES $FILE"
        fi
      done
      rm -f "$TEMP_IGNORE_FILE"
      echo "$TRACKED_FILES"
    else
      rm -f "$TEMP_IGNORE_FILE"
      echo "$ALL_CHANGES"
    fi
  else
    echo "$ALL_CHANGES"
  fi
}

# Function to detect change type from files changed
detect_change_type() {
  # Get the list of changed files
  CHANGED_FILES="$1"
  
  # Initialize flags for different change types
  HAS_DOCS=false
  HAS_TESTS=false
  HAS_FEATURE=false
  HAS_FIX=false
  HAS_REFACTOR=false
  
  # Check each file to determine change type
  for FILE in $CHANGED_FILES; do
    if [[ "$FILE" == *"test"* || "$FILE" == *"spec"* ]]; then
      HAS_TESTS=true
    elif [[ "$FILE" == *"doc"* || "$FILE" == *"README"* || "$FILE" == *".md" ]]; then
      HAS_DOCS=true
    elif [[ "$FILE" == *"fix"* || "$FILE" == *"bug"* ]]; then
      HAS_FIX=true
    elif [[ "$FILE" == *"refactor"* ]]; then
      HAS_REFACTOR=true
    else
      HAS_FEATURE=true
    fi
  done
  
  # Determine primary change type based on file patterns
  if $HAS_FIX; then
    echo "fix"
  elif $HAS_REFACTOR; then
    echo "refactor"
  elif $HAS_TESTS && ! $HAS_FEATURE; then
    echo "test"
  elif $HAS_DOCS && ! $HAS_FEATURE; then
    echo "docs"
  else
    echo "feature"
  fi
}

# Function to commit and push changes
commit_and_push() {
  cd "$REPO_DIR"
  
  # Update the session file
  update_session_file
  
  # Run the session tracker to update SESSION.md with details
  if [ -f "$REPO_DIR/scripts/workflow/auto-session-tracker.sh" ]; then
    bash "$REPO_DIR/scripts/workflow/auto-session-tracker.sh"
    echo "Updated SESSION.md with latest activity"
  else
    echo "Error: Could not find auto-session-tracker.sh script"
  fi
  
  # Check if there are changes to commit
  if git status --porcelain | grep -q .; then
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    
    # Get tracked files (respecting .autocommitignore)
    TRACKED_FILES=$(get_tracked_files)
    
    if [ -n "$TRACKED_FILES" ]; then
      # Detect change type
      CHANGE_TYPE=$(detect_change_type "$TRACKED_FILES")
      
      # Add tracked files individually to respect .autocommitignore
      for FILE in $TRACKED_FILES; do
        git add "$FILE"
      done
      
      # Create an appropriate commit message based on change type
      COMMIT_MESSAGE="Auto-commit (${CHANGE_TYPE}): $TIMESTAMP"
      
      # Commit locally but don't push automatically
      git commit -m "$COMMIT_MESSAGE"
      
      # Log the commit but don't push to GitHub
      echo "Changes committed locally at $TIMESTAMP (not pushed to GitHub)"
      echo "Change type detected: $CHANGE_TYPE"
    else
      echo "No tracked changes to commit (all changes in .autocommitignore)"
    fi
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