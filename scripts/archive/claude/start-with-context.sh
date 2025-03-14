#!/bin/bash

# start-with-context.sh - Start a Claude session with comprehensive project context
# This script automatically explores the codebase, displays past session summaries,
# and provides context for Claude to understand the project state

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
WORKFLOW_DIR="$REPO_DIR/scripts/workflow"
SESSIONS_DIR="$REPO_DIR/sessions/claude"
GUIDES_FILE="$REPO_DIR/CLAUDE.md"
DATE=$(date +"%Y%m%d")
TIME=$(date +"%H%M%S")
OUTPUT_FILE="/tmp/claude-context-$DATE-$TIME.txt"
AUTO_COMPACT=true # Set to false to disable auto-compact functionality
PROJECT_NAME="Synapse"

# Check if we have the guide file
if [ ! -f "$GUIDES_FILE" ]; then
  echo "❌ CLAUDE.md not found at $GUIDES_FILE"
  echo "This file should contain project guides and commands for Claude."
  exit 1
fi

# Create output file for context
echo "# $PROJECT_NAME Project Context - $(date +"%B %d, %Y")" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Include the guide file
echo "## Project Guide" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
cat "$GUIDES_FILE" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Get the most recent compact summary
echo "## Recent Session Summary" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
LATEST_COMPACT=$(find "$SESSIONS_DIR" -name "compact-*.md" -type f -printf "%T@ %p\n" | sort -nr | head -1 | cut -d' ' -f2-)

if [ -n "$LATEST_COMPACT" ]; then
  echo "Latest session summary from: $(basename "$LATEST_COMPACT" | sed 's/compact-//' | sed 's/.md//')" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
  cat "$LATEST_COMPACT" >> "$OUTPUT_FILE"
else
  echo "No previous session summaries found." >> "$OUTPUT_FILE"
fi
echo "" >> "$OUTPUT_FILE"

# List available session archives
echo "## Available Session Archives" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
if [ -f "$WORKFLOW_DIR/session-archive.sh" ]; then
  bash "$WORKFLOW_DIR/session-archive.sh" --list >> "$OUTPUT_FILE"
else
  echo "Session archive script not found at $WORKFLOW_DIR/session-archive.sh" >> "$OUTPUT_FILE"
fi
echo "" >> "$OUTPUT_FILE"

# Development workflow documentation
echo "## Development Workflow" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "### Main Workflow Guide" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
WORKFLOW_DOCS="$REPO_DIR/docs/workflow/WORKFLOW.md"
if [ -f "$WORKFLOW_DOCS" ]; then
  cat "$WORKFLOW_DOCS" >> "$OUTPUT_FILE"
else
  echo "Workflow documentation not found at $WORKFLOW_DOCS" >> "$OUTPUT_FILE"
fi
echo "" >> "$OUTPUT_FILE"

# Testing workflow
echo "### Testing Workflow" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
TEST_DOCS="$REPO_DIR/docs/workflow/TEST_DEBUG_WORKFLOW.md"
if [ -f "$TEST_DOCS" ]; then
  cat "$TEST_DOCS" >> "$OUTPUT_FILE"
else
  echo "Test workflow documentation not found at $TEST_DOCS" >> "$OUTPUT_FILE"
fi
echo "" >> "$OUTPUT_FILE"

# CI/CD workflow
echo "### CI/CD Workflow" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
CICD_DOCS="$REPO_DIR/docs/workflow/CI_CD_WORKFLOW.md"
if [ -f "$CICD_DOCS" ]; then
  cat "$CICD_DOCS" >> "$OUTPUT_FILE"
else
  echo "CI/CD workflow documentation not found at $CICD_DOCS" >> "$OUTPUT_FILE"
fi
echo "" >> "$OUTPUT_FILE"

# Claude-specific documentation
echo "## Claude Documentation" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "### Claude Development Instructions" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
CLAUDE_DOCS="$REPO_DIR/docs/claude/CLAUDE_DEVELOPMENT_INSTRUCTIONS.md"
if [ -f "$CLAUDE_DOCS" ]; then
  cat "$CLAUDE_DOCS" >> "$OUTPUT_FILE"
else
  echo "Claude development instructions not found at $CLAUDE_DOCS" >> "$OUTPUT_FILE"
fi
echo "" >> "$OUTPUT_FILE"

echo "### Claude Sessions Documentation" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
CLAUDE_SESSIONS_DOCS="$REPO_DIR/docs/claude/sessions/SESSIONS.md"
if [ -f "$CLAUDE_SESSIONS_DOCS" ]; then
  cat "$CLAUDE_SESSIONS_DOCS" >> "$OUTPUT_FILE"
else
  echo "Claude sessions documentation not found at $CLAUDE_SESSIONS_DOCS" >> "$OUTPUT_FILE"
fi
echo "" >> "$OUTPUT_FILE"

# Project structure overview
echo "## Project Structure" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "### Source Code" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
find "$REPO_DIR/src" -type d -maxdepth 3 2>/dev/null | sort >> "$OUTPUT_FILE" || echo "Error accessing source directories" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "### Main Source Files" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
find "$REPO_DIR/src" -name "*.ts" -type f -maxdepth 2 2>/dev/null | sort >> "$OUTPUT_FILE" || echo "Error accessing source files" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "### Documentation" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
find "$REPO_DIR/docs" -name "*.md" -type f 2>/dev/null | sort >> "$OUTPUT_FILE" || echo "Error accessing documentation files" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Package info
echo "## Project Dependencies" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "### package.json" >> "$OUTPUT_FILE"
echo '```json' >> "$OUTPUT_FILE"
cat "$REPO_DIR/package.json" | grep -A 50 '"dependencies"' | grep -B 50 '"devDependencies"' >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# TypeScript settings
echo "## TypeScript Configuration" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo '```json' >> "$OUTPUT_FILE"
cat "$REPO_DIR/tsconfig.json" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Final instructions
echo "## Getting Started Instructions" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "1. Review the recent session summary to understand the current state of the project" >> "$OUTPUT_FILE"
echo "2. Check the project priorities in the guide" >> "$OUTPUT_FILE"
echo "3. Explore relevant source files based on current priorities" >> "$OUTPUT_FILE"
echo "4. When ready to end the session, use the \`/compact\` command" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Display progress
echo "Context preparation complete!"
echo "Starting Claude with comprehensive project context..."
echo ""

# Choose whether to use auto-compact or regular Claude
if [ "$AUTO_COMPACT" = true ] && [ -f "$SCRIPT_DIR/claude-with-autocompact.sh" ]; then
  echo "Starting Claude with auto-compact detection..."
  echo "---------------------------------------------"
  echo "Use /compact in your Claude session as normal"
  echo "The system will automatically save the compact summary"
  echo ""
  
  # Run Claude with auto-compact and pass the context file
  bash "$SCRIPT_DIR/claude-with-autocompact.sh" < "$OUTPUT_FILE"
else
  echo "Starting regular Claude..."
  echo "-------------------------"
  echo "When finished, run scripts/workflow/session-end.sh to save the session"
  echo ""
  
  # Run regular Claude and pass the context file
  claude < "$OUTPUT_FILE"
fi