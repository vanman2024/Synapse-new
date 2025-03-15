#\!/bin/bash

# compact-save-example.sh - Example script showing how to save compact summaries
# This script simulates a complete workflow of generating and automatically processing a compact summary

# Get script directory and repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
WATCH_DIR="$REPO_DIR/sessions/claude/compact-watch"
DATE=$(date +"%Y%m%d")
TIME=$(date +"%H%M%S")

# Create a sample compact summary
echo "Creating example compact summary file..."
cat > "$WATCH_DIR/example-summary-$DATE-$TIME.txt" << 'SUMMARY'
<summary>
This is an example compact summary from the demonstration script.

1. The auto-compact-watch.sh script watches the compact-watch directory
2. When you save a file containing <summary> tags to this directory, 
   it automatically processes and saves it to the daily compact file
3. Multiple summaries on the same day are appended to the same file
4. Each summary gets a timestamp and separator for better organization
5. No manual copy/paste required\!

This provides a fully automated system for saving Claude's compact summaries.
</summary>
SUMMARY

echo "✅ Saved example summary to $WATCH_DIR/example-summary-$DATE-$TIME.txt"
echo ""
echo "If auto-compact-watch.sh is running, it should detect and process this file automatically."
echo "Otherwise, run: ./scripts/workflow/auto-compact-watch.sh"
echo ""
echo "To view the results, check: $REPO_DIR/sessions/claude/compact-$DATE.md"
