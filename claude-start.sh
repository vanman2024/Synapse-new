#!/bin/bash

# claude-start.sh - Run this at the beginning of each Claude session
# Automatically starts the auto-commit script and displays session status

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION_FILE="$REPO_DIR/SESSION.md"
DATE=$(date +"%B %d, %Y")
LOCK_FILE="$REPO_DIR/.claude-autocommit.lock"

# Change to repo directory
cd "$REPO_DIR"

echo "=================================="
echo "  SYNAPSE PROJECT - CLAUDE SESSION"
echo "  $DATE"
echo "=================================="

# Make sure logs directory exists
LOG_DIR="$REPO_DIR/logs/system"
mkdir -p "$LOG_DIR"

# Check if auto-commit is already running
if [ -f "$LOCK_FILE" ] && ps -p $(cat "$LOCK_FILE") > /dev/null; then
  echo "✅ Auto-commit is already running with PID $(cat "$LOCK_FILE")"
else
  # Start auto-commit script in background and save PID
  nohup "$REPO_DIR/scripts/auto-commit.sh" > "$LOG_DIR/auto-commit.log" 2>&1 &
  echo $! > "$LOCK_FILE"
  echo "✅ Started auto-commit script with PID $(cat "$LOCK_FILE")"
  echo "   Output is being logged to logs/system/auto-commit.log"
fi

# Install git hooks if they're not already set up
if [ ! -x "$REPO_DIR/.git/hooks/pre-commit" ]; then
  echo "Setting up git hooks..."
  bash "$REPO_DIR/scripts/setup-hooks.sh"
fi

# Update SESSION.md with current date
sed -i "s/## Current Session:.*$/## Current Session: $DATE/" "$SESSION_FILE"

# Show current branch
CURRENT_BRANCH=$(git branch --show-current)
echo ""
echo "Current branch: $CURRENT_BRANCH"

# Show recent commits
echo ""
echo "Recent commits:"
git log --oneline -n 3

# Display critical project info from SESSION.md
echo ""
echo "PROJECT STATUS:"
echo "------------------------------------------------"
sed -n '/#### Project Status/,/#### Current Focus/p' "$SESSION_FILE" | head -n -1 | tail -n +2

# Show current focus
echo ""
echo "CURRENT FOCUS:"
echo "------------------------------------------------"
sed -n '/#### Current Focus/,/#### Last Activity/p' "$SESSION_FILE" | head -n -1 | tail -n +2

echo ""
echo "Claude session is ready to begin!"
echo "You can now start working with Claude on the Synapse project."
echo "Auto-commit will run automatically every 5 minutes."
echo "All your changes will be tracked in SESSION.md automatically."
echo ""
echo "DOCUMENTATION:"
echo "  - Quick Reference: docs/workflow/CLAUDE_README.md"
echo "  - Detailed Guide:  docs/workflow/CLAUDE_WORKFLOW.md"
echo "--------------------------------------------------"