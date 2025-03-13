#!/bin/bash

# start-session.sh - Quickly prepare for a new development session
# Usage: ./scripts/start-session.sh

REPO_DIR="$(pwd)"
SESSION_FILE="$REPO_DIR/SESSION.md"
DATE=$(date +"%B %d, %Y")

# Check if we're in the repo root
if [ ! -d "$REPO_DIR/.git" ]; then
  echo "Error: Not in git repository root. Please run from the project root."
  exit 1
fi

# Update session file date
sed -i "s/## Current Session:.*$/## Current Session: $DATE/" "$SESSION_FILE"

# Display session info
echo "=================================="
echo "  SYNAPSE DEVELOPMENT SESSION"
echo "  $DATE"
echo "=================================="

# Show branch and status
CURRENT_BRANCH=$(git branch --show-current)
echo "Current branch: $CURRENT_BRANCH"

# Show most recent commits
echo ""
echo "Recent commits:"
git log --oneline -n 3

# Show current focus and next tasks from SESSION.md
echo ""
echo "CURRENT FOCUS:"
sed -n '/#### Current Focus/,/#### Last Completed Tasks/p' "$SESSION_FILE" | head -n -1 | tail -n +2

echo ""
echo "NEXT TASKS:"
sed -n '/#### Next Tasks/,/### Code Context/p' "$SESSION_FILE" | head -n -1 | tail -n +2

# Check auto-commit script status
echo ""
echo "Auto-commit status:"
if pgrep -f "auto-commit.sh" > /dev/null; then
  echo "✅ Auto-commit is running"
else
  echo "❌ Auto-commit is NOT running"
  echo "Run './scripts/auto-commit.sh &' to start it"
fi

echo ""
echo "Ready to continue development!"
echo "Remember to update SESSION.md before ending your session."
echo ""