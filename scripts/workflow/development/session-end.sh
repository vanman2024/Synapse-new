#!/bin/bash

# session-end.sh - End a development session with Claude
# This script coordinates between the workflow session archive and Claude's compact summaries

# Get the workflow directory
WORKFLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get the repository root directory 
REPO_DIR="$(cd "$WORKFLOW_DIR/../.." && pwd)"
SESSION_FILE="$REPO_DIR/SESSION.md"
WORKFLOW_ARCHIVE_DIR="$REPO_DIR/docs/workflow/session-archives"
CLAUDE_ARCHIVE_DIR="$REPO_DIR/sessions/claude"
DATE=$(date +"%Y%m%d")
FORMATTED_DATE=$(date +"%B %d, %Y")

# Make sure both archive directories exist
mkdir -p "$WORKFLOW_ARCHIVE_DIR"
mkdir -p "$CLAUDE_ARCHIVE_DIR"

echo "=========================================="
echo "   SYNAPSE PROJECT - END SESSION WORKFLOW"
echo "   $FORMATTED_DATE"
echo "=========================================="
echo ""
echo "This script will help you properly end your Claude session and archive the results."
echo ""

# Check if auto-commit is running and kill it if needed
LOCK_FILE="$REPO_DIR/.claude-autocommit.lock"
if [ -f "$LOCK_FILE" ] && ps -p $(cat "$LOCK_FILE") > /dev/null; then
  echo "Stopping auto-commit process (PID: $(cat "$LOCK_FILE"))..."
  kill $(cat "$LOCK_FILE")
  rm "$LOCK_FILE"
  echo "✅ Auto-commit stopped"
else
  echo "Auto-commit is not running"
fi

# Run one final auto-commit to capture any changes
echo "Performing final auto-commit..."
bash "$WORKFLOW_DIR/auto-commit.sh" --message "End of session commit" --no-daemon

# Instructions for compact command
echo ""
echo "=========================================="
echo "IMPORTANT: SAVE SESSION SUMMARY"
echo "=========================================="
echo "1. In your Claude session, run the /compact command"
echo "2. Wait for Claude to generate the summary (this may take a moment)"
echo "3. Copy the ENTIRE output from Claude (including <summary> tags)"
echo "4. Paste the summary below and press Ctrl+D when finished"
echo ""
echo "Paste compact summary below (press Ctrl+D when done):"

# Create a temporary file for the summary
TEMP_SUMMARY=$(mktemp)

# Capture user input to file (until Ctrl+D)
cat > "$TEMP_SUMMARY"

# Check if the file has content
if [ ! -s "$TEMP_SUMMARY" ]; then
  echo "❌ No summary provided. Session will not be properly archived."
  exit 1
fi

# Check if the summary contains <summary> tags
if ! grep -q "<summary>" "$TEMP_SUMMARY"; then
  echo "⚠️ Warning: The pasted text doesn't contain <summary> tags."
  echo "It may not be a proper Claude compact summary."
  
  # Ask user if they want to continue
  read -p "Continue anyway? (y/n): " CONTINUE
  if [ "$CONTINUE" != "y" ]; then
    echo "Aborted. Please try again with a proper compact summary."
    exit 1
  fi
fi

# Extract content between <summary> tags if present
if grep -q "<summary>" "$TEMP_SUMMARY" && grep -q "</summary>" "$TEMP_SUMMARY"; then
  sed -n '/<summary>/,/<\/summary>/p' "$TEMP_SUMMARY" | sed 's/<summary>//g' | sed 's/<\/summary>//g' > "$TEMP_SUMMARY.extract"
  mv "$TEMP_SUMMARY.extract" "$TEMP_SUMMARY"
fi

# Save the summary to Claude archives
CLAUDE_COMPACT_FILE="$CLAUDE_ARCHIVE_DIR/compact-$DATE.md"
echo "# Claude Compact Summary - $FORMATTED_DATE" > "$CLAUDE_COMPACT_FILE"
echo "" >> "$CLAUDE_COMPACT_FILE"
cat "$TEMP_SUMMARY" >> "$CLAUDE_COMPACT_FILE"

echo "✅ Saved Claude compact summary to $CLAUDE_COMPACT_FILE"

# Save the full session to Claude archives
CLAUDE_SESSION_FILE="$CLAUDE_ARCHIVE_DIR/$DATE-session.json"
echo "Attempting to locate and archive the full Claude session..."

# Look for today's session JSON file
LATEST_SESSION=$(find "$CLAUDE_ARCHIVE_DIR" -name "*.json" -type f -printf "%T@ %p\n" | sort -nr | head -1 | cut -d' ' -f2-)

if [ -n "$LATEST_SESSION" ]; then
  # Copy the latest session to a date-stamped file
  cp "$LATEST_SESSION" "$CLAUDE_ARCHIVE_DIR/$DATE-session.json"
  echo "✅ Saved full Claude session to $CLAUDE_ARCHIVE_DIR/$DATE-session.json"
  
  # Also save a text version
  if [ -f "$CLAUDE_ARCHIVE_DIR/archives/${DATE}sessionClaudetxt.txt" ]; then
    echo "✅ Text version of session already exists at $CLAUDE_ARCHIVE_DIR/archives/${DATE}sessionClaudetxt.txt"
  else
    mkdir -p "$CLAUDE_ARCHIVE_DIR/archives"
    # Create a plain text version from the JSON (simplified)
    echo "Session from $FORMATTED_DATE" > "$CLAUDE_ARCHIVE_DIR/archives/${DATE}sessionClaudetxt.txt"
    cat "$TEMP_SUMMARY" >> "$CLAUDE_ARCHIVE_DIR/archives/${DATE}sessionClaudetxt.txt"
    echo "✅ Created text version of session at $CLAUDE_ARCHIVE_DIR/archives/${DATE}sessionClaudetxt.txt"
  fi
else
  echo "⚠️ Could not find today's Claude session JSON file"
fi

# Update the sessions index file
SESSIONS_INDEX="$CLAUDE_ARCHIVE_DIR/sessions-index.json"

# Create index file if it doesn't exist or is empty
if [ ! -s "$SESSIONS_INDEX" ]; then
  echo '{"sessions":[]}' > "$SESSIONS_INDEX"
fi

# Add the session to the index using jq if available, otherwise append to a log file
if command -v jq >/dev/null 2>&1; then
  TEMP_JSON=$(mktemp)
  jq --arg date "$(date +"%Y-%m-%d")" \
     --arg time "$(date +"%H:%M")" \
     --arg file "compact-$DATE.md" \
     --arg session "$DATE-session.json" \
     '.sessions += [{"date": $date, "time": $time, "compact": $file, "session": $session}]' \
     "$SESSIONS_INDEX" > "$TEMP_JSON" && mv "$TEMP_JSON" "$SESSIONS_INDEX"
  echo "✅ Updated sessions index JSON"
else
  echo "$(date +"%Y-%m-%d %H:%M") - compact-$DATE.md - $DATE-session.json" >> "$CLAUDE_ARCHIVE_DIR/sessions-log.txt"
  echo "✅ Updated sessions log (jq not available)"
fi

# Now, also run the session-archive.sh to update the workflow archives
if [ -f "$WORKFLOW_DIR/session-archive.sh" ]; then
  echo "Archiving workflow sessions..."
  bash "$WORKFLOW_DIR/session-archive.sh"
  
  # Also create a workflow archive with today's date containing the compact summary
  WORKFLOW_ARCHIVE_FILE="$WORKFLOW_ARCHIVE_DIR/session-$DATE.md"
  
  # Only create if it doesn't exist
  if [ ! -f "$WORKFLOW_ARCHIVE_FILE" ]; then
    echo "# Archived Session: $FORMATTED_DATE" > "$WORKFLOW_ARCHIVE_FILE"
    echo "" >> "$WORKFLOW_ARCHIVE_FILE"
    echo "## Session Summary" >> "$WORKFLOW_ARCHIVE_FILE"
    echo "" >> "$WORKFLOW_ARCHIVE_FILE"
    cat "$TEMP_SUMMARY" >> "$WORKFLOW_ARCHIVE_FILE"
    echo "✅ Created workflow archive at $WORKFLOW_ARCHIVE_FILE"
  else
    echo "ℹ️ Workflow archive for today already exists at $WORKFLOW_ARCHIVE_FILE"
  fi
else
  echo "⚠️ session-archive.sh not found, skipping workflow archive update"
fi

# Clean up temp file
rm "$TEMP_SUMMARY"

echo ""
echo "SESSION END COMPLETE"
echo "=========================================="
echo "✅ Session summary saved to:"
echo "   - Claude archive: $CLAUDE_COMPACT_FILE"
echo "   - Workflow archive: $WORKFLOW_ARCHIVE_FILE (if it didn't exist already)"
echo ""
echo "✅ Session archives updated"
echo ""
echo "Next steps:"
echo "1. Review the session archives if needed"
echo "2. You can view archived sessions with:"
echo "   ./scripts/workflow/session-archive.sh --list"
echo "   ./scripts/workflow/session-archive.sh --retrieve=YYYYMMDD"
echo ""
echo "Goodbye! 👋"