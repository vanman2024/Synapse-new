#!/bin/bash

# save-compact-from-file.sh - Saves Claude's compact summary from a file
# Useful for automated workflows that export Claude chat content

# Get the script directory and repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SAVE_SCRIPT="$REPO_DIR/scripts/save-session.sh"

# Check if save-session.sh exists
if [ ! -f "$SAVE_SCRIPT" ]; then
  echo "❌ Error: save-session.sh not found at $SAVE_SCRIPT"
  exit 1
fi

# Check for input file argument
if [ $# -ne 1 ]; then
  echo "Usage: $0 <path-to-session-file>"
  echo "Example: $0 ~/Downloads/claude-session.txt"
  exit 1
fi

if [ ! -f "$1" ]; then
  echo "❌ Error: File not found: $1"
  exit 1
fi

# Create a temporary file for the extracted summary
TEMP_FILE=$(mktemp)

# Extract content between <summary> tags if present
if grep -q "<summary>" "$1" && grep -q "</summary>" "$1"; then
  echo "Found <summary> tags in $1, extracting..."
  sed -n '/<summary>/,/<\/summary>/p' "$1" > "$TEMP_FILE"
  
  # Call the save-session.sh script with our temp file
  bash "$SAVE_SCRIPT" "$TEMP_FILE"
  echo "✅ Compact summary extracted and saved successfully!"
else
  echo "❌ No <summary> tags found in $1"
  echo "The file must contain a Claude compact summary with <summary></summary> tags."
  exit 1
fi

# Clean up
rm "$TEMP_FILE"