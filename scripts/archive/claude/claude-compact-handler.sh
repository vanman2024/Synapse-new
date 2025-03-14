#!/bin/bash

# claude-compact-handler.sh - Handle the output from Claude's /compact command
# This script bridges between Claude's compact output and the session archiving system

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
WORKFLOW_DIR="$REPO_DIR/scripts/workflow"
SESSIONS_DIR="$REPO_DIR/sessions/claude"
DATE=$(date +"%Y%m%d")
TIME=$(date +"%H%M%S")
FORMATTED_DATE=$(date +"%B %d, %Y")

# Make sure sessions directory exists
mkdir -p "$SESSIONS_DIR"
mkdir -p "$SESSIONS_DIR/archives"

# Check if a file was provided
if [ $# -eq 1 ]; then
  # Use the provided file
  SUMMARY_FILE="$1"
  echo "Using provided summary file: $SUMMARY_FILE"
  
  if [ ! -f "$SUMMARY_FILE" ]; then
    echo "Error: File not found: $SUMMARY_FILE"
    exit 1
  fi
else
  # Create a temporary file for manual input
  SUMMARY_FILE=$(mktemp)
  
  echo "No file provided. Please paste Claude's compact output below (press Ctrl+D when done):"
  cat > "$SUMMARY_FILE"
  
  if [ ! -s "$SUMMARY_FILE" ]; then
    echo "Error: No input provided. Exiting."
    rm "$SUMMARY_FILE"
    exit 1
  fi
fi

# Extract content between <summary> tags if present
TEMP_EXTRACT=$(mktemp)
if grep -q "<summary>" "$SUMMARY_FILE" && grep -q "</summary>" "$SUMMARY_FILE"; then
  sed -n '/<summary>/,/<\/summary>/p' "$SUMMARY_FILE" | sed 's/<summary>//g' | sed 's/<\/summary>//g' > "$TEMP_EXTRACT"
  CONTENT_FILE="$TEMP_EXTRACT"
  echo "Found and extracted <summary> tags"
else
  CONTENT_FILE="$SUMMARY_FILE"
  echo "No <summary> tags found, using entire content"
fi

# Create the compact summary file
CLAUDE_COMPACT_FILE="$SESSIONS_DIR/compact-$DATE.md"
echo "# Claude Compact Summary - $FORMATTED_DATE" > "$CLAUDE_COMPACT_FILE"
echo "" >> "$CLAUDE_COMPACT_FILE"
cat "$CONTENT_FILE" >> "$CLAUDE_COMPACT_FILE"

echo "✅ Saved Claude compact summary to $CLAUDE_COMPACT_FILE"

# Create a text version for the archives
ARCHIVE_FILE="$SESSIONS_DIR/archives/${DATE}sessionClaudetxt.txt"
echo "Session from $FORMATTED_DATE" > "$ARCHIVE_FILE"
echo "" >> "$ARCHIVE_FILE"
cat "$CONTENT_FILE" >> "$ARCHIVE_FILE"

echo "✅ Created text archive at $ARCHIVE_FILE"

# Update the sessions index file
SESSIONS_INDEX="$SESSIONS_DIR/sessions-index.json"

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
     --arg archive "${DATE}sessionClaudetxt.txt" \
     '.sessions += [{"date": $date, "time": $time, "compact": $file, "archive": $archive}]' \
     "$SESSIONS_INDEX" > "$TEMP_JSON" && mv "$TEMP_JSON" "$SESSIONS_INDEX"
  echo "✅ Updated sessions index JSON"
else
  echo "$(date +"%Y-%m-%d %H:%M") - compact-$DATE.md - ${DATE}sessionClaudetxt.txt" >> "$SESSIONS_DIR/sessions-log.txt"
  echo "✅ Updated sessions log (jq not available)"
fi

# Check if session-end.sh exists and offer to run it
if [ -f "$WORKFLOW_DIR/session-end.sh" ]; then
  echo ""
  echo "Would you like to run the full session-end.sh workflow?"
  echo "This will also update the workflow archives and perform end-of-session tasks."
  read -p "Run session-end.sh? (y/n): " RUN_END
  
  if [ "$RUN_END" = "y" ]; then
    # Pass our extracted content to session-end.sh
    echo "Running session-end.sh with the compact summary..."
    
    # Create a temporary file with the summary
    END_SUMMARY=$(mktemp)
    cat "$CONTENT_FILE" > "$END_SUMMARY"
    
    # Call session-end.sh and pass it the summary
    (cd "$REPO_DIR" && cat "$END_SUMMARY" | bash "$WORKFLOW_DIR/session-end.sh")
    
    # Clean up
    rm "$END_SUMMARY"
  else
    echo "Skipping session-end.sh workflow"
  fi
fi

# Clean up temp files
rm -f "$TEMP_EXTRACT"
if [ $# -ne 1 ]; then
  rm -f "$SUMMARY_FILE"
fi

echo ""
echo "COMPACT HANDLING COMPLETE"
echo "=========================================="
echo "The compact summary has been saved and indexed."
echo ""
echo "To end your session completely, run:"
echo "  ./scripts/workflow/session-end.sh"
echo ""
echo "To view archived sessions:"
echo "  ./scripts/workflow/session-archive.sh --list"
echo "  ./scripts/workflow/session-archive.sh --retrieve=YYYYMMDD"