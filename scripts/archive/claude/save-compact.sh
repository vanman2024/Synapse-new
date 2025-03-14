#!/bin/bash

# save-compact.sh - Simple script to save Claude's compact summary
# This is completely separate from the development workflow

# Usage:
# 1. Run /compact in Claude
# 2. Copy the summary text (with or without <summary> tags)
# 3. Save it to a file
# 4. Run this script with the file path: ./scripts/save-compact.sh summary-file.txt

if [ $# -ne 1 ]; then
  echo "Usage: ./scripts/save-compact.sh <summary-file>"
  echo "Saves the Claude compact summary to a dated file"
  exit 1
fi

SUMMARY_FILE="$1"
DATE=$(date +"%Y%m%d")
OUTPUT_FILE="sessions/claude/compact-${DATE}.md"

if [ ! -f "$SUMMARY_FILE" ]; then
  echo "Error: File not found: $SUMMARY_FILE"
  exit 1
fi

# Create sessions directory if it doesn't exist
mkdir -p sessions

# Extract summary content
CONTENT=$(cat "$SUMMARY_FILE")

# Handle <summary> tags if present
if [[ "$CONTENT" == *"<summary>"* && "$CONTENT" == *"</summary>"* ]]; then
  CONTENT=$(echo "$CONTENT" | sed -n '/<summary>/,/<\/summary>/p' | sed 's/<summary>//g' | sed 's/<\/summary>//g')
fi

# Create a nicely formatted output
echo "# Claude Compact Summary - $(date +"%B %d, %Y")" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "$CONTENT" >> "$OUTPUT_FILE"

echo "✅ Saved compact summary to $OUTPUT_FILE"