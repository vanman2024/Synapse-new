#!/bin/bash

# save-compact-simple.sh - A simple script to save Claude's compact summary
# This version works directly in any terminal without special requirements

# Get script directory and repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CLAUDE_DIR="$REPO_DIR/sessions/claude"
DATE=$(date +"%Y%m%d")
TIME=$(date +"%H:%M:%S")
FORMATTED_DATE=$(date +"%B %d, %Y")
COMPACT_FILE="$CLAUDE_DIR/compact-$DATE.md"

# Make sure the directory exists
mkdir -p "$CLAUDE_DIR"

# Create a temporary file for the input
TEMP_FILE=$(mktemp)

# Display instructions
echo "========================================================"
echo "    CLAUDE COMPACT SUMMARY SAVER"
echo "    $FORMATTED_DATE"
echo "========================================================"
echo ""
echo "This script will save a compact summary from Claude."
echo ""
echo "Instructions:"
echo "1. Run the /compact command in your Claude session"
echo "2. Copy the ENTIRE output (including <summary> tags)"
echo "3. Paste below and press Ctrl+D when done"
echo ""
echo "Paste the compact summary below (press Ctrl+D when done):"
echo ""

# Read from stdin
cat > "$TEMP_FILE"

# Check if we got any input
if [ ! -s "$TEMP_FILE" ]; then
  echo "❌ Error: No input provided. Exiting."
  rm "$TEMP_FILE"
  exit 1
fi

# Extract content between <summary> tags if present
if grep -q "<summary>" "$TEMP_FILE" && grep -q "</summary>" "$TEMP_FILE"; then
  echo "Found <summary> tags in input, extracting..."
  sed -n '/<summary>/,/<\/summary>/p' "$TEMP_FILE" | sed 's/<summary>//g' | sed 's/<\/summary>//g' > "$TEMP_FILE.extract"
  mv "$TEMP_FILE.extract" "$TEMP_FILE"
else
  echo "⚠️ Warning: Input doesn't contain <summary> tags."
  echo "It may not be a proper Claude compact summary."
  
  # Ask user if they want to continue
  read -p "Continue anyway? (y/n): " CONTINUE
  if [ "$CONTINUE" != "y" ]; then
    echo "Aborted. Please try again with a proper compact summary."
    rm "$TEMP_FILE"
    exit 1
  fi
fi

# Save to compact-YYYYMMDD.md (appending if it exists)
if [ ! -f "$COMPACT_FILE" ]; then
  # First summary of the day - create the file with header
  echo "# Claude Compact Summary - $FORMATTED_DATE" > "$COMPACT_FILE"
  echo "" >> "$COMPACT_FILE"
else
  # Append a separator for additional summaries
  echo "" >> "$COMPACT_FILE"
  echo "---" >> "$COMPACT_FILE"
  echo "" >> "$COMPACT_FILE"
fi

# Add a timestamp for this summary
echo "## Session at $TIME" >> "$COMPACT_FILE"
echo "" >> "$COMPACT_FILE"

# Append the summary content
cat "$TEMP_FILE" >> "$COMPACT_FILE"

# Update the sessions index file
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

echo ""
echo "✅ Summary saved successfully to: $COMPACT_FILE"
echo ""
echo "To view the file, run:"
echo "cat $COMPACT_FILE"