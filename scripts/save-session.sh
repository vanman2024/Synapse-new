#!/bin/bash

# save-session.sh - Simple script to save Claude's compact summary
# Saves to a date-based file, appending if it already exists

# Get the script directory and repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Define consistent directories
CLAUDE_DIR="$REPO_DIR/sessions/claude"
ARCHIVES_DIR="$CLAUDE_DIR/archives"

# Create directories if they don't exist
mkdir -p "$CLAUDE_DIR"
mkdir -p "$ARCHIVES_DIR"

# Get today's date in YYYYMMDD format
DATE=$(date +"%Y%m%d")
TIME=$(date +"%H:%M:%S")
FORMATTED_DATE=$(date +"%B %d, %Y")

# Consistent file location - one MD file per day
CLAUDE_COMPACT_FILE="$CLAUDE_DIR/compact-$DATE.md"

# Create a temporary file for the input
TEMP_FILE=$(mktemp)

# Check if input is provided as a file argument
if [ $# -eq 1 ] && [ -f "$1" ]; then
  cat "$1" > "$TEMP_FILE"
  echo "Reading from file: $1"
else
  # No file provided, read from stdin
  echo "Paste the compact summary below (press Ctrl+D when done):"
  cat > "$TEMP_FILE"
fi

# Extract content between <summary> tags if present
if grep -q "<summary>" "$TEMP_FILE" && grep -q "</summary>" "$TEMP_FILE"; then
  sed -n '/<summary>/,/<\/summary>/p' "$TEMP_FILE" | sed 's/<summary>//g' | sed 's/<\/summary>//g' > "$TEMP_FILE.extract"
  mv "$TEMP_FILE.extract" "$TEMP_FILE"
  echo "Found and extracted <summary> tags"
fi

# --- PRIMARY LOCATION (Claude format) ---
# Save to claude/compact-YYYYMMDD.md (appending if it exists)
if [ ! -f "$CLAUDE_COMPACT_FILE" ]; then
  # First summary of the day - create the file with header
  echo "# Claude Compact Summary - $FORMATTED_DATE" > "$CLAUDE_COMPACT_FILE"
  echo "" >> "$CLAUDE_COMPACT_FILE"
else
  # Append a separator for additional summaries
  echo "" >> "$CLAUDE_COMPACT_FILE"
  echo "---" >> "$CLAUDE_COMPACT_FILE"
  echo "" >> "$CLAUDE_COMPACT_FILE"
fi

# Add a timestamp for this summary
echo "## Session at $TIME" >> "$CLAUDE_COMPACT_FILE"
echo "" >> "$CLAUDE_COMPACT_FILE"

# Append the summary content
cat "$TEMP_FILE" >> "$CLAUDE_COMPACT_FILE"

# --- UPDATE SESSION INDEX ---
SESSIONS_INDEX="$CLAUDE_DIR/sessions-index.json"

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
     '.sessions += [{"date": $date, "time": $time, "compact": $file}]' \
     "$SESSIONS_INDEX" > "$TEMP_JSON" && mv "$TEMP_JSON" "$SESSIONS_INDEX"
  echo "✅ Updated sessions index JSON"
else
  echo "$(date +"%Y-%m-%d %H:%M") - compact-$DATE.md" >> "$CLAUDE_DIR/sessions-log.txt"
  echo "✅ Updated sessions log (jq not available)"
fi

# Clean up
rm "$TEMP_FILE"

echo "✅ Session summary saved to: $CLAUDE_COMPACT_FILE"