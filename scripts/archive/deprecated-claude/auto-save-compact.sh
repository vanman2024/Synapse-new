#!/bin/bash

# auto-save-compact.sh - Automatically saves Claude's compact summary
# This should be integrated with your Claude session workflow
# Place this on your PATH to directly use it from the terminal

# Get the script directory and repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SAVE_SCRIPT="$REPO_DIR/scripts/save-session.sh"

# Check if save-session.sh exists
if [ ! -f "$SAVE_SCRIPT" ]; then
  echo "❌ Error: save-session.sh not found at $SAVE_SCRIPT"
  exit 1
fi

# Create a temporary file for the input
TEMP_FILE=$(mktemp)

# Usage instructions
echo "=========================================="
echo "   AUTO-SAVE CLAUDE COMPACT SUMMARY"
echo "=========================================="
echo ""
echo "This script will automatically save Claude's compact summary."
echo ""
echo "Instructions:"
echo "1. Run /compact in your Claude session"
echo "2. Select and copy the ENTIRE compact output (including <summary> tags)"
echo "3. Paste below (press Ctrl+D when done)"
echo ""
echo "Paste compact summary below (press Ctrl+D when done):"

# Read input from stdin
cat > "$TEMP_FILE"

# Check if we got any input
if [ ! -s "$TEMP_FILE" ]; then
  echo "❌ No input provided. Exiting."
  rm "$TEMP_FILE"
  exit 1
fi

# Check if it contains a summary
if ! grep -q "<summary>" "$TEMP_FILE"; then
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

# Call the save-session.sh script with our temp file
bash "$SAVE_SCRIPT" "$TEMP_FILE"

# Clean up
rm "$TEMP_FILE"

echo ""
echo "✅ Compact summary saved successfully!"
echo "=========================================="