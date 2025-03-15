#!/bin/bash

# start-compact-watch.sh - Start the auto-compact watcher for Claude summaries
# Automatically saves Claude's compact summaries without requiring copy-paste

# Get script directory (repo root)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_SCRIPTS_DIR="$REPO_DIR/scripts/workflow/claude"

# Check if the auto-compact-watch script exists
if [ ! -f "$CLAUDE_SCRIPTS_DIR/auto-compact-watch.sh" ]; then
  echo "❌ Auto-compact watch script not found at $CLAUDE_SCRIPTS_DIR/auto-compact-watch.sh"
  echo "Make sure all scripts are properly installed."
  exit 1
fi

# Display helpful information
echo "==================================================="
echo "  STARTING CLAUDE COMPACT SUMMARY WATCHER"
echo "  $(date "+%B %d, %Y at %H:%M")"
echo "==================================================="
echo ""
echo "This script will monitor for compact summaries from Claude."
echo ""
echo "To use this system:"
echo "1. Run your Claude session normally"
echo "2. When you use the /compact command in Claude:"
echo "   - Save the output to a file in sessions/claude/compact-watch/"
echo "   - This watcher will automatically process it"
echo "   - The summary will be saved to the daily compact file"
echo ""
echo "To see saved summaries:"
echo "  cat ./sessions/claude/compact-$(date +"%Y%m%d").md"
echo ""
echo "Press Ctrl+C to stop the watcher."
echo ""

# Start the auto-compact watch script
$CLAUDE_SCRIPTS_DIR/auto-compact-watch.sh