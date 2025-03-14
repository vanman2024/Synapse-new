#!/bin/bash

# start-claude-session.sh - Master script for starting Claude sessions
# This script launches Claude with the optimal context and configuration

# Get script directory (repo root)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$REPO_DIR/scripts/claude"
WORKFLOW_DIR="$REPO_DIR/scripts/workflow"

# Check if context loader exists
if [ ! -f "$CLAUDE_DIR/claude-context-loader.sh" ]; then
  echo "❌ Context loader script not found at $CLAUDE_DIR/claude-context-loader.sh"
  echo "Make sure you're running this script from the project root."
  exit 1
fi

# Check if autocompact script exists
if [ ! -f "$CLAUDE_DIR/claude-with-autocompact.sh" ]; then
  echo "❌ Claude autocompact script not found at $CLAUDE_DIR/claude-with-autocompact.sh"
  echo "Make sure you've installed all the required scripts."
  exit 1
fi

# Run the context loader script
echo "==================================================="
echo "  STARTING SYNAPSE PROJECT CLAUDE SESSION"
echo "  $(date "+%B %d, %Y at %H:%M")"
echo "==================================================="
echo ""
echo "Loading context and starting Claude..."
echo ""

# Run the context loader to create the context file
CONTEXT_FILE=$($CLAUDE_DIR/claude-context-loader.sh | grep -o "/tmp/claude-context-[0-9]\+-[0-9]\+.txt")

# Check if context file was created
if [ -f "$CONTEXT_FILE" ]; then
  echo "Starting Claude with automatic compact detection..."
  echo ""
  # Start Claude with autocompact and the context file
  $CLAUDE_DIR/claude-with-autocompact.sh < "$CONTEXT_FILE"
else
  echo "❌ Context file not found. Starting Claude without context..."
  echo ""
  # Fallback to just starting Claude with autocompact
  $CLAUDE_DIR/claude-with-autocompact.sh
fi