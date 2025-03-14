#!/bin/bash

# compact-claude.sh - Automatically invoke Claude's compact command and save the result
# This script wraps the 'claude' CLI command, captures its output when using /compact,
# and automatically saves the summary

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSIONS_DIR="$SCRIPT_DIR/../sessions"
DATE=$(date +"%Y%m%d")
TEMP_FILE="$SESSIONS_DIR/temp-compact-$DATE.txt"
OUTPUT_FILE="$SESSIONS_DIR/compact-$DATE.md"

# Make sure sessions directory exists
mkdir -p "$SESSIONS_DIR"

# Create a temporary file to store the Claude output
echo "Invoking Claude's compact command and saving results..."
echo "Once Claude generates the summary, press Ctrl+C to exit Claude"
echo ""
echo "Processing..."

# Run the claude command with /compact
claude | tee "$TEMP_FILE"

# Extract the summary part (anything between <summary> and </summary>)
if grep -q "<summary>" "$TEMP_FILE"; then
  # Extract content between <summary> tags
  sed -n '/<summary>/,/<\/summary>/p' "$TEMP_FILE" | sed 's/<summary>//g' | sed 's/<\/summary>//g' > "$TEMP_FILE.extract"
  
  # Format the output
  echo "# Claude Compact Summary - $(date +"%B %d, %Y")" > "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
  cat "$TEMP_FILE.extract" >> "$OUTPUT_FILE"
  
  echo ""
  echo "✅ Compact summary saved to: $OUTPUT_FILE"
  
  # Clean up temporary files
  rm "$TEMP_FILE.extract"
else
  echo ""
  echo "❌ No compact summary found in the output."
  echo "Did you run the /compact command in Claude?"
fi

# Keep the temp file for reference
echo "Full session log saved to: $TEMP_FILE"