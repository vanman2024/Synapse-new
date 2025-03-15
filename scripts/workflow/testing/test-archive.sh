#!/bin/bash

# test-archive.sh - Test the session archiving functionality
# This script creates multiple dummy sessions and tests the archiving system

# Get the workflow directory
WORKFLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get the repository root directory 
REPO_DIR="$(cd "$WORKFLOW_DIR/../.." && pwd)"
SESSION_FILE="$REPO_DIR/SESSION.md"
ARCHIVE_DIR="$REPO_DIR/docs/workflow/session-archives"
ORIGINAL_SESSION=$(mktemp)

# Backup original SESSION.md
if [ -f "$SESSION_FILE" ]; then
  cp "$SESSION_FILE" "$ORIGINAL_SESSION"
  echo "✅ Backed up original SESSION.md"
fi

# Create a test SESSION.md with 5 sessions to trigger archiving
echo "# Synapse Development Session Log" > "$SESSION_FILE"
echo "" >> "$SESSION_FILE"

# Create 5 sessions to test archiving (default keeps 3)
for i in {1..5}; do
  DATE=$(date -d "2025-03-$((10 + $i))" +"%B %d, %Y")
  echo "## Current Session: $DATE" >> "$SESSION_FILE"
  echo "" >> "$SESSION_FILE"
  echo "### Session Goals" >> "$SESSION_FILE"
  echo "- Test session $i" >> "$SESSION_FILE"
  echo "- Testing archiving functionality" >> "$SESSION_FILE"
  echo "" >> "$SESSION_FILE"
  echo "#### Project Status" >> "$SESSION_FILE"
  echo "- Test status $i" >> "$SESSION_FILE"
  echo "" >> "$SESSION_FILE"
  echo "#### Current Focus" >> "$SESSION_FILE"
  echo "- Test focus $i" >> "$SESSION_FILE"
  echo "" >> "$SESSION_FILE"
  echo "#### Last Activity" >> "$SESSION_FILE"
  echo "🧪 **$(date +"%H:%M")** - Test activity $i" >> "$SESSION_FILE"
  echo "" >> "$SESSION_FILE"
  echo "#### Next Tasks" >> "$SESSION_FILE"
  echo "- Task for test $i" >> "$SESSION_FILE"
  echo "" >> "$SESSION_FILE"
done

echo "✅ Created test SESSION.md with 5 sessions"

# Run the archive script
echo "Running archive script..."
"$WORKFLOW_DIR/session-archive.sh"

# Check results
echo ""
echo "Testing archive list functionality..."
"$WORKFLOW_DIR/session-archive.sh" --list

# Test retrieving an archive
echo ""
echo "Testing archive retrieval..."
ARCHIVE_DATE=$(ls -1 "$ARCHIVE_DIR"/session-*.md | head -n 1 | xargs basename | sed 's/session-//' | sed 's/.md//')
"$WORKFLOW_DIR/session-archive.sh" --retrieve="$ARCHIVE_DATE" | head -n 5

# Test the auto-session-tracker integration
echo ""
echo "Testing auto-session-tracker integration..."
"$WORKFLOW_DIR/auto-session-tracker.sh"

# Restore original SESSION.md
if [ -f "$ORIGINAL_SESSION" ]; then
  mv "$ORIGINAL_SESSION" "$SESSION_FILE"
  echo "✅ Restored original SESSION.md"
fi

echo ""
echo "Test completed. If any archives were created during testing, they are still in"
echo "$ARCHIVE_DIR and should be removed manually if unwanted."