#!/bin/bash

# claude-start.sh - Run this at the beginning of each Claude session
# Automatically starts the auto-commit script and displays session status

# Get the workflow directory
WORKFLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get the repository root directory (two levels up from the workflow dir)
REPO_DIR="$(cd "$WORKFLOW_DIR/../.." && pwd)"
SESSION_FILE="$REPO_DIR/SESSION.md"
DATE=$(date +"%B %d, %Y")
LOCK_FILE="$REPO_DIR/.claude-autocommit.lock"

# Change to repo directory
cd "$REPO_DIR"

# Start a new session using the session manager
"$WORKFLOW_DIR/session-manager.sh" start

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
  # Make sure logs directory exists
  mkdir -p "$REPO_DIR/logs/system"
  
  # Start auto-commit script in background
  cd "$REPO_DIR"
  nohup "$REPO_DIR/scripts/auto-commit.sh" > "$REPO_DIR/logs/system/auto-commit.log" 2>&1 &
  
  # Script now writes its own PID to lock file
  sleep 1
  if [ -f "$LOCK_FILE" ]; then
    echo "✅ Started auto-commit script with PID $(cat "$LOCK_FILE")"
    echo "   Output is being logged to logs/system/auto-commit.log"
  else
    echo "❌ Failed to start auto-commit script"
  fi
fi

# Install git hooks if they're not already set up
if [ ! -x "$REPO_DIR/.git/hooks/pre-commit" ]; then
  echo "Setting up git hooks..."
  bash "$WORKFLOW_DIR/setup-hooks.sh"
fi

# Create a new session at the top of SESSION.md
# This preserves previous sessions and adds a new current session
TMP_FILE=$(mktemp)

# Add new session to the top
echo "# Synapse Development Session Log" > "$TMP_FILE"
echo "" >> "$TMP_FILE"
echo "## Current Session: $DATE" >> "$TMP_FILE"
echo "" >> "$TMP_FILE"
echo "### Session Goals" >> "$TMP_FILE"
echo "- Continue development on current modules" >> "$TMP_FILE"
echo "- Fix any outstanding issues" >> "$TMP_FILE"
echo "- Improve project structure and organization" >> "$TMP_FILE"
echo "" >> "$TMP_FILE"

# If SESSION.md exists, append everything after the first session header
if [ -f "$SESSION_FILE" ]; then
  # Find the line number of the first "## Current Session" line
  FIRST_SESSION=$(grep -n "^## Current Session:" "$SESSION_FILE" | head -n 1 | cut -d: -f1)
  
  if [ -n "$FIRST_SESSION" ]; then
    # Extract the existing content without the header
    tail -n +$FIRST_SESSION "$SESSION_FILE" >> "$TMP_FILE"
  else
    # If no session header found, just append the entire file
    cat "$SESSION_FILE" >> "$TMP_FILE"
  fi
fi

# Replace SESSION.md with our new version
mv "$TMP_FILE" "$SESSION_FILE"

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
FOCUS_KEYWORDS=$(sed -n '/#### Current Focus/,/#### Last Activity/p' "$SESSION_FILE" | head -n -1 | tail -n +2 | grep -o -E '\w+' | tr '\n' '|' | sed 's/|$//')

if [ -n "$FOCUS_KEYWORDS" ]; then
  # Find recently modified files related to focus keywords
  echo "Files related to current focus:"
  git ls-files | grep -E "$FOCUS_KEYWORDS" | head -n 5
  
  # Show recently modified files
  echo ""
  echo "Recently modified files:"
  git log --name-only --pretty=format: -n 5 | grep -v '^$' | sort | uniq | head -n 5
fi

# Check for recent archive sessions to provide context continuity
echo ""
echo "RECENT ARCHIVED SESSIONS:"
echo "------------------------------------------------"
if [ -f "$WORKFLOW_DIR/session-archive.sh" ]; then
  # List only the last 2 archives
  "$WORKFLOW_DIR/session-archive.sh" --list | grep -v "Available" | grep -v "-----" | head -n 2
  echo "Run './scripts/workflow/session-archive.sh --list' to see all archives"
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
echo "  - Testing Guide:   docs/workflow/TEST_DEBUG_WORKFLOW.md"
echo "  - Dev Instructions: docs/claude/CLAUDE_DEVELOPMENT_INSTRUCTIONS.md"
echo "  - Module Tracker:  docs/claude/MODULE_TRACKER.md"
echo ""
echo "SESSION ARCHIVES:"
echo "  - List archives:     ./scripts/workflow/session-archive.sh --list"
echo "  - View archive:      ./scripts/workflow/session-archive.sh --retrieve=YYYYMMDD"
echo ""
echo "COMMANDS: (process with ./scripts/workflow/session-commands.sh)"
echo "  @focus:component   - Set current focus to component"
echo "  @sprint:name,start,end - Set sprint information"
echo "  @todo:task         - Add a task to Next Tasks"
echo "  @summary           - Generate session summary"
echo "  @help              - Show all available commands"
echo ""
echo "TESTING & DEPLOYMENT:"
echo "  ./scripts/workflow/test-cycle.sh component cycle-number  # Run tests"
echo "  ./scripts/workflow/verify-and-push.sh component         # Push to GitHub"
echo ""
echo "SUGGESTED FIRST MESSAGE:"
echo "  \"Please review SESSION.md and project documentation to understand where we left off.\""
echo "--------------------------------------------------"