#!/bin/bash

# auto-compact.sh - Automatically detect and capture Claude's compact output
# This script monitors the Claude process and captures the output when /compact
# is used, then saves the summary without requiring manual intervention

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSIONS_DIR="$SCRIPT_DIR/../sessions"
DATE=$(date +"%Y%m%d")
TIME=$(date +"%H%M%S")
TEMP_FILE="$SESSIONS_DIR/auto-compact-$DATE-$TIME.txt"
OUTPUT_FILE="$SESSIONS_DIR/compact-$DATE-$TIME.md"
FIFO_FILE="/tmp/claude-fifo-$$"

# Make sure sessions directory exists
mkdir -p "$SESSIONS_DIR"

# Create a FIFO (named pipe) for capturing the output
mkfifo "$FIFO_FILE"

# Trap to clean up the FIFO on exit
trap 'rm -f "$FIFO_FILE"; echo "Exiting..."; exit' INT TERM EXIT

echo "Starting Claude with auto-compact detection..."
echo "Use /compact in your Claude session as normal"
echo "This script will automatically detect and save the compact summary"
echo "Press Ctrl+C to exit"
echo ""

# Start background process to monitor the output for compact command
cat "$FIFO_FILE" | tee "$TEMP_FILE" | grep --line-buffered -A 100 "<summary>" > /dev/null &
GREP_PID=$!

# Run Claude and redirect its output to our FIFO
claude > "$FIFO_FILE" 2>&1

# After Claude exits, check if we found a compact summary
if grep -q "<summary>" "$TEMP_FILE"; then
  # Extract content between <summary> tags
  sed -n '/<summary>/,/<\/summary>/p' "$TEMP_FILE" | sed 's/<summary>//g' | sed 's/<\/summary>//g' > "$TEMP_FILE.extract"
  
  # Format the output
  echo "# Claude Compact Summary - $(date +"%B %d, %Y %H:%M")" > "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
  cat "$TEMP_FILE.extract" >> "$OUTPUT_FILE"
  
  echo ""
  echo "✅ Compact summary detected and saved to: $OUTPUT_FILE"
  
  # Clean up temporary files
  rm -f "$TEMP_FILE.extract"
else
  echo ""
  echo "No compact summary was detected in this session."
  # Don't remove the temp file as it might be useful for debugging
  rm -f "$OUTPUT_FILE" 2>/dev/null
fi

# Kill any remaining background processes
kill $GREP_PID 2>/dev/null

# Clean up the FIFO
rm -f "$FIFO_FILE"

echo "Full session log saved to: $TEMP_FILE"