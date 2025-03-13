#!/bin/bash

# auto-session-tracker.sh - Automatically tracks session progress
# Set up as a git hook or run periodically with auto-commit

# Get the workflow directory
WORKFLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get the repository root directory (two levels up from the workflow dir)
REPO_DIR="$(cd "$WORKFLOW_DIR/../.." && pwd)"
SESSION_FILE="$REPO_DIR/SESSION.md"
ARCHIVE_DIR="$REPO_DIR/docs/workflow/session-archives"
DATE=$(date +"%B %d, %Y")
TIME=$(date +"%H:%M:%S")
BRANCH=$(git branch --show-current)
LAST_COMMIT_MSG=$(git log -1 --pretty=%B)
LAST_COMMIT_FILES=$(git log -1 --name-only --pretty=format:"")
CHANGE_TYPE=$(echo "$LAST_COMMIT_MSG" | grep -o "Auto-commit (\w*)" | sed 's/Auto-commit (//' | sed 's/)//')

# Create archive directory if it doesn't exist
mkdir -p "$ARCHIVE_DIR"

# Archive older activity if SESSION.md is getting too large (> 300 lines)
SESSION_LINES=$(wc -l < "$SESSION_FILE")
if [ "$SESSION_LINES" -gt 300 ]; then
  # Extract date to use in archive filename
  ARCHIVE_DATE=$(date +"%Y%m%d")
  # Create archive filename
  ARCHIVE_FILE="$ARCHIVE_DIR/session_${ARCHIVE_DATE}.md"
  
  # Extract older activity sections to archive
  grep -n "#### Last Activity" "$SESSION_FILE" | head -n -3 | cut -d ":" -f 1 > /tmp/activity_lines.txt
  if [ -s /tmp/activity_lines.txt ]; then
    START_LINE=$(head -n 1 /tmp/activity_lines.txt)
    END_LINE=$(tail -n 1 /tmp/activity_lines.txt)
    
    # Add header to archive file if it doesn't exist
    if [ ! -f "$ARCHIVE_FILE" ]; then
      echo "# Archived Session Activities - $DATE" > "$ARCHIVE_FILE"
      echo "" >> "$ARCHIVE_FILE"
    fi
    
    # Append activities to archive
    echo "## Activities from $(date +"%Y-%m-%d")" >> "$ARCHIVE_FILE"
    sed -n "${START_LINE},${END_LINE}p" "$SESSION_FILE" >> "$ARCHIVE_FILE"
    echo "" >> "$ARCHIVE_FILE"
    
    # Remove old activities from SESSION.md (keep only last 3)
    sed -i "/${START_LINE},${END_LINE}d" "$SESSION_FILE"
    
    echo "Archived older activities to $ARCHIVE_FILE"
  fi
fi

# Update session date
sed -i "s/## Current Session:.*$/## Current Session: $DATE ($TIME)/" "$SESSION_FILE"

# Update branch status
sed -i "s/- Currently on:.*$/- Currently on: $BRANCH branch/" "$SESSION_FILE"

# Check for sprint information and update if present
if grep -q "### Current Sprint" "$SESSION_FILE"; then
  # Get current sprint info
  SPRINT_INFO=$(grep -A 3 "### Current Sprint" "$SESSION_FILE")
  
  # Calculate days remaining if end date is present
  if echo "$SPRINT_INFO" | grep -q "- End:"; then
    SPRINT_END=$(echo "$SPRINT_INFO" | grep "- End:" | cut -d ":" -f 2 | xargs)
    DAYS_REMAINING=$(( ($(date -d "$SPRINT_END" +%s) - $(date +%s)) / 86400 ))
    
    # Update days remaining
    sed -i "/- Days remaining:/c\\- Days remaining: $DAYS_REMAINING days" "$SESSION_FILE"
  fi
else
  # If no sprint info exists, add placeholder section
  if ! grep -q "### Current Sprint" "$SESSION_FILE"; then
    # Find the right place to insert sprint info (after Project Status section)
    PROJECT_LINE=$(grep -n "#### Project Status" "$SESSION_FILE" | cut -d ":" -f 1)
    if [ -n "$PROJECT_LINE" ]; then
      PROJECT_END=$(grep -n "#### Current Focus" "$SESSION_FILE" | cut -d ":" -f 1)
      PROJECT_END=$((PROJECT_END - 1))
      
      # Create sprint section
      SPRINT_SECTION="\n### Current Sprint\n- Name: (Not set)\n- Start: $(date +"%Y-%m-%d")\n- End: (Not set)\n- Days remaining: (Not set)\n- Progress: 0%\n\n"
      
      # Insert after project status section
      sed -i "${PROJECT_END}a ${SPRINT_SECTION}" "$SESSION_FILE"
    fi
  fi
fi

# Count lines added/removed in recent changes
LINES_CHANGED=""
if [ -n "$LAST_COMMIT_FILES" ]; then
  LINES_ADDED=0
  LINES_REMOVED=0
  
  # Use git diff to count lines changed
  DIFF_STATS=$(git diff HEAD~1 --stat | tail -n 1)
  if [ -n "$DIFF_STATS" ]; then
    LINES_ADDED=$(echo "$DIFF_STATS" | grep -o "[0-9]* insertion" | grep -o "[0-9]*" || echo "0")
    LINES_REMOVED=$(echo "$DIFF_STATS" | grep -o "[0-9]* deletion" | grep -o "[0-9]*" || echo "0")
    LINES_CHANGED=" (+$LINES_ADDED, -$LINES_REMOVED)"
  fi
fi

# Set icon based on change type
ICON="🔧"
if [ "$CHANGE_TYPE" = "fix" ]; then
  ICON="🐛"
elif [ "$CHANGE_TYPE" = "feature" ]; then
  ICON="✨"
elif [ "$CHANGE_TYPE" = "docs" ]; then
  ICON="📝"
elif [ "$CHANGE_TYPE" = "test" ]; then
  ICON="🧪"
elif [ "$CHANGE_TYPE" = "refactor" ]; then
  ICON="♻️"
fi

# Create improved activity section
ACTIVITY_SECTION=$(cat <<EOF
#### Last Activity
$ICON **$(date +"%H:%M")** - ${LAST_COMMIT_MSG}${LINES_CHANGED}
- Modified files:
\`\`\`
$LAST_COMMIT_FILES
\`\`\`
EOF
)

# Replace the Last Activity section
sed -i "/#### Last Activity/,/#### Next Tasks/c\\#### Last Activity\\n$ICON **$(date +"%H:%M")** - ${LAST_COMMIT_MSG}${LINES_CHANGED}\\n- Modified files:\\n\`\`\`\\n$LAST_COMMIT_FILES\\n\`\`\`\\n\\n#### Next Tasks" "$SESSION_FILE"

# Add SESSION.md to git (will be committed by auto-commit script)
git add "$SESSION_FILE"

# If we archived anything, add that too
if [ -f "$ARCHIVE_FILE" ]; then
  git add "$ARCHIVE_FILE"
fi

# Clean up temporary files
rm -f /tmp/activity_lines.txt