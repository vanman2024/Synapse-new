#!/bin/bash

# auto-branch-checker.sh - Automatically checks if we're on the right branch
# Run this when development starts to ensure we're not on master/main

# Get the repository root directory
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYNERGY_SCRIPT="$REPO_DIR/synergy.sh"
# Check for active session
TMP_SESSION_FILE="/tmp/synergy/active_session"

# Check current branch
CURRENT_BRANCH=$(git branch --show-current)

# Check if we're on master or main
if [ "$CURRENT_BRANCH" = "master" ] || [ "$CURRENT_BRANCH" = "main" ]; then
  echo "⚠️  IMPORTANT: You're currently on the $CURRENT_BRANCH branch."
  echo "    Development should happen on feature branches, not directly on $CURRENT_BRANCH."
  echo ""
  
  # Get current module focus
  FOCUS_MODULE=$(grep "Focus Module" "$REPO_DIR/docs/project/PROJECT_TRACKER.md" | cut -d':' -f2 | xargs)
  FEATURE_NAME=$(echo "$FOCUS_MODULE" | tr '[:upper:] ' '[:lower:]-')
  
  # Suggest creating a feature branch
  echo "Creating feature branch for: $FOCUS_MODULE"
  "$SYNERGY_SCRIPT" feature "$FEATURE_NAME"
  
  # Start the session if not already started
  if [ ! -f "$TMP_SESSION_FILE" ]; then
    echo "Starting development session..."
    "$SYNERGY_SCRIPT" start
  fi
else
  echo "✅ Currently on feature branch: $CURRENT_BRANCH"
  
  # Make sure we have an active session
  if [ ! -f "$TMP_SESSION_FILE" ]; then
    echo "Starting development session..."
    "$SYNERGY_SCRIPT" start
  else
    echo "✅ Session is active"
  fi
fi

# Show current status
"$SYNERGY_SCRIPT" status

# Print success message
echo ""
echo "🚀 Ready for development! The system will:"
echo "   - Automatically verify code with tests before commits"
echo "   - Automatically track development in Airtable"
echo "   - Automatically suggest module completion and PR creation"
echo ""
echo "Just code - the hooks will handle verification and tracking!"