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
  bash "$REPO_DIR/scripts/workflow/setup-hooks.sh"
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

# Show sprint info if available
if grep -q "### Current Sprint" "$SESSION_FILE"; then
  echo ""
  echo "SPRINT INFO:"
  echo "------------------------------------------------"
  sed -n '/### Current Sprint/,/### Progress Tracker/p' "$SESSION_FILE" | head -n -1 | tail -n +2
fi

# Show current focus
echo ""
echo "CURRENT FOCUS:"
echo "------------------------------------------------"
sed -n '/#### Current Focus/,/#### Last Activity/p' "$SESSION_FILE" | head -n -1 | tail -n +2

# Find relevant files based on current focus
echo ""
echo "CONTEXT PRIORITY FILES:"
echo "------------------------------------------------"
FOCUS_KEYWORDS=$(sed -n '/#### Current Focus/,/#### Last Activity/p' "$SESSION_FILE" | head -n -1 | tail -n +2 | \
  grep -o -E '\w+' | tr '\n' '|' | sed 's/|$//')

if [ -n "$FOCUS_KEYWORDS" ]; then
  # Find recently modified files related to focus keywords
  echo "Files related to current focus:"
  git ls-files | grep -E "$FOCUS_KEYWORDS" | head -n 5
  
  # Show recently modified files
  echo ""
  echo "Recently modified files:"
  git log --name-only --pretty=format: -n 5 | grep -v '^$' | sort | uniq | head -n 5
fi$' | sort | uniq | head -n 5
fi

echo ""
echo "Claude session is ready to begin!"
echo "You can now start working with Claude on the Synapse project."
echo "Auto-commit will run automatically every 5 minutes."
echo "All your changes will be tracked in SESSION.md automatically."
echo ""
echo "DOCUMENTATION:"
echo "  - Quick Reference: docs/workflow/CLAUDE_README.md"
echo "  - Detailed Guide:  docs/workflow/CLAUDE_WORKFLOW.md"
echo ""
echo "COMMANDS: (process with ./scripts/workflow/session-commands.sh)"
echo "  @focus:component   - Set current focus to component"
echo "  @sprint:name,start,end - Set sprint information"
echo "  @todo:task         - Add a task to Next Tasks"
echo "  @summary           - Generate session summary"
echo "  @help              - Show all available commands"
echo ""
echo "SUGGESTED FIRST MESSAGE:"
echo "  \"Please review SESSION.md and project documentation to understand where we left off.\""
echo "--------------------------------------------------"