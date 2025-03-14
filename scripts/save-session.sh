#!/bin/bash

# save-session.sh - Simple script to save Claude's compact summary
# Saves to a date-based file, appending if it already exists

# Create sessions directory if it doesn't exist
mkdir -p /mnt/c/Users/user/SynapseProject/Synapse-new/sessions

# Get today's date in YYYYMMDD format
DATE=$(date +"%Y%m%d")
TIME=$(date +"%H:%M:%S")
SESSION_FILE="/mnt/c/Users/user/SynapseProject/Synapse-new/sessions/session-$DATE.md"

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

# If the file doesn't exist, create it with a header
if [ ! -f "$SESSION_FILE" ]; then
  echo "# Session Summaries for $(date +"%B %d, %Y")" > "$SESSION_FILE"
  echo "" >> "$SESSION_FILE"
fi

# Add a timestamp and append content
echo "" >> "$SESSION_FILE"
echo "## Session at $TIME" >> "$SESSION_FILE"
echo "" >> "$SESSION_FILE"
cat "$TEMP_FILE" >> "$SESSION_FILE"
echo "" >> "$SESSION_FILE"
echo "---" >> "$SESSION_FILE"

# Clean up
rm "$TEMP_FILE"

echo "✅ Session summary appended to $SESSION_FILE"