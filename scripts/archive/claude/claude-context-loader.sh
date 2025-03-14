#!/bin/bash

# claude-context-loader.sh - Prepare comprehensive context for Claude sessions
# Load documentation, recent sessions, code insights, and project status

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
WORKFLOW_DIR="$REPO_DIR/scripts/workflow"
SESSIONS_DIR="$REPO_DIR/sessions/claude"
DATE=$(date +"%Y%m%d")
TIME=$(date +"%H%M%S")
CONTEXT_FILE="/tmp/claude-context-$DATE-$TIME.txt"

echo "Preparing Synapse project context for Claude..."

# Create context file
echo "# Synapse Project Context - $(date +"%B %d, %Y")" > "$CONTEXT_FILE"
echo "" >> "$CONTEXT_FILE"

# Include project guide
echo "## Project Guide" >> "$CONTEXT_FILE"
echo "" >> "$CONTEXT_FILE"
cat "$REPO_DIR/docs/workflow/GUIDE.md" >> "$CONTEXT_FILE"
echo "" >> "$CONTEXT_FILE"

# Include Claude workflow documentation
echo "## Claude Workflow" >> "$CONTEXT_FILE"
echo "" >> "$CONTEXT_FILE"
cat "$REPO_DIR/docs/claude/CLAUDE_WORKFLOW.md" >> "$CONTEXT_FILE"
echo "" >> "$CONTEXT_FILE"

# Include session management documentation
echo "## Session Management" >> "$CONTEXT_FILE"
echo "" >> "$CONTEXT_FILE"
cat "$REPO_DIR/docs/claude/development/SESSION_MANAGEMENT.md" >> "$CONTEXT_FILE"
echo "" >> "$CONTEXT_FILE"

# Get most recent compact summary
echo "## Recent Session" >> "$CONTEXT_FILE"
echo "" >> "$CONTEXT_FILE"
LATEST_COMPACT=$(find "$SESSIONS_DIR" -name "compact-*.md" -type f -printf "%T@ %p\n" 2>/dev/null | sort -nr | head -1 | cut -d' ' -f2-)

if [ -n "$LATEST_COMPACT" ]; then
  echo "Latest session summary from: $(basename "$LATEST_COMPACT" | sed 's/compact-//' | sed 's/.md//')" >> "$CONTEXT_FILE"
  echo "" >> "$CONTEXT_FILE"
  cat "$LATEST_COMPACT" >> "$CONTEXT_FILE"
else
  echo "No previous session summaries found." >> "$CONTEXT_FILE"
fi
echo "" >> "$CONTEXT_FILE"

# Include session archives info
echo "## Session Archives" >> "$CONTEXT_FILE"
echo "" >> "$CONTEXT_FILE"
if [ -f "$WORKFLOW_DIR/session-archive.sh" ]; then
  bash "$WORKFLOW_DIR/session-archive.sh" --list | head -5 >> "$CONTEXT_FILE"
  echo "..." >> "$CONTEXT_FILE"
else
  echo "Session archive script not found." >> "$CONTEXT_FILE"
fi
echo "" >> "$CONTEXT_FILE"

# Include MODULE_TRACKER info
echo "## Module Status" >> "$CONTEXT_FILE"
echo "" >> "$CONTEXT_FILE"
if [ -f "$REPO_DIR/docs/claude/MODULE_TRACKER.md" ]; then
  cat "$REPO_DIR/docs/claude/MODULE_TRACKER.md" >> "$CONTEXT_FILE"
else
  echo "Module tracker not found." >> "$CONTEXT_FILE"
fi
echo "" >> "$CONTEXT_FILE"

# Include current session status
echo "## Current Session" >> "$CONTEXT_FILE"
echo "" >> "$CONTEXT_FILE"
if [ -f "$REPO_DIR/SESSION.md" ]; then
  # Extract the current session part only
  FIRST_SESSION=$(grep -n "^## Current Session:" "$REPO_DIR/SESSION.md" | head -n 1 | cut -d: -f1)
  NEXT_SESSION=$(grep -n "^## Current Session:" "$REPO_DIR/SESSION.md" | sed -n '2p' | cut -d: -f1)
  
  if [ -n "$FIRST_SESSION" ]; then
    if [ -n "$NEXT_SESSION" ]; then
      sed -n "${FIRST_SESSION},${NEXT_SESSION}p" "$REPO_DIR/SESSION.md" | head -n -1 >> "$CONTEXT_FILE"
    else
      sed -n "${FIRST_SESSION},\$p" "$REPO_DIR/SESSION.md" >> "$CONTEXT_FILE"
    fi
  else
    echo "No current session found in SESSION.md" >> "$CONTEXT_FILE"
  fi
else
  echo "SESSION.md not found." >> "$CONTEXT_FILE"
fi
echo "" >> "$CONTEXT_FILE"

# Include key project source files overview
echo "## Project Sources" >> "$CONTEXT_FILE"
echo "" >> "$CONTEXT_FILE"
echo "### Models" >> "$CONTEXT_FILE"
echo '```' >> "$CONTEXT_FILE"
find "$REPO_DIR/src/models" -name "*.ts" -type f 2>/dev/null | sort >> "$CONTEXT_FILE"
echo '```' >> "$CONTEXT_FILE"
echo "" >> "$CONTEXT_FILE"

echo "### Repositories" >> "$CONTEXT_FILE"
echo '```' >> "$CONTEXT_FILE"
find "$REPO_DIR/src/repositories" -name "*.ts" -type f 2>/dev/null | sort >> "$CONTEXT_FILE"
echo '```' >> "$CONTEXT_FILE"
echo "" >> "$CONTEXT_FILE"

echo "### Services" >> "$CONTEXT_FILE"
echo '```' >> "$CONTEXT_FILE"
find "$REPO_DIR/src/services" -name "*.ts" -type f 2>/dev/null | sort >> "$CONTEXT_FILE"
echo '```' >> "$CONTEXT_FILE"
echo "" >> "$CONTEXT_FILE"

# Include info about session archiving scripts
echo "## Session Archiving Scripts" >> "$CONTEXT_FILE"
echo "" >> "$CONTEXT_FILE"
echo "### session-end.sh" >> "$CONTEXT_FILE"
echo '```bash' >> "$CONTEXT_FILE"
if [ -f "$WORKFLOW_DIR/session-end.sh" ]; then
  grep -A 10 "session-end.sh -" "$WORKFLOW_DIR/session-end.sh" >> "$CONTEXT_FILE"
else
  echo "# Script not found" >> "$CONTEXT_FILE"
fi
echo '```' >> "$CONTEXT_FILE"
echo "" >> "$CONTEXT_FILE"

echo "### claude-with-autocompact.sh" >> "$CONTEXT_FILE"
echo '```bash' >> "$CONTEXT_FILE"
if [ -f "$SCRIPT_DIR/claude-with-autocompact.sh" ]; then
  grep -A 10 "claude-with-autocompact.sh -" "$SCRIPT_DIR/claude-with-autocompact.sh" >> "$CONTEXT_FILE"
else
  echo "# Script not found" >> "$CONTEXT_FILE"
fi
echo '```' >> "$CONTEXT_FILE"
echo "" >> "$CONTEXT_FILE"

echo "### session-archive.sh" >> "$CONTEXT_FILE"
echo '```bash' >> "$CONTEXT_FILE"
if [ -f "$WORKFLOW_DIR/session-archive.sh" ]; then
  grep -A 10 "session-archive.sh -" "$WORKFLOW_DIR/session-archive.sh" >> "$CONTEXT_FILE"
else
  echo "# Script not found" >> "$CONTEXT_FILE"
fi
echo '```' >> "$CONTEXT_FILE"
echo "" >> "$CONTEXT_FILE"

# Final guidance
echo "## Starting Instructions" >> "$CONTEXT_FILE"
echo "" >> "$CONTEXT_FILE"
echo "1. Review the recent session summary to understand what we've been working on" >> "$CONTEXT_FILE"
echo "2. Check the module tracker to see what needs to be completed next" >> "$CONTEXT_FILE"
echo "3. Focus on completing the ContentRepository implementation, which is a high priority" >> "$CONTEXT_FILE"
echo "4. When ending the session, use the /compact command and one of these options:" >> "$CONTEXT_FILE"
echo "   a. If using claude-with-autocompact.sh, the summary will be saved automatically" >> "$CONTEXT_FILE"
echo "   b. Otherwise, use ./scripts/workflow/session-end.sh to manually save it" >> "$CONTEXT_FILE"
echo "" >> "$CONTEXT_FILE"

# Display progress
echo "Context file created at $CONTEXT_FILE"
echo ""

# Provide two options for using the context
echo "You can now use this context in two ways:"
echo ""
echo "1. Start Claude with automatic compact detection:"
echo "   ./scripts/claude/claude-with-autocompact.sh < $CONTEXT_FILE"
echo ""
echo "2. Start regular Claude with the context:"
echo "   claude < $CONTEXT_FILE"
echo ""
echo "Option 1 is recommended as it will automatically save your /compact output."