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
# Using awk instead of grep to avoid character issues
if awk '/### Current Sprint/ {found=1} END {exit !found}' "$SESSION_FILE"; then
  # Use awk to safely extract sprint information
  SPRINT_END_DATE=$(awk '/- End:/ {print $3}' "$SESSION_FILE" | head -1)
  
  # Calculate days remaining if end date is present and valid
  if [ -n "$SPRINT_END_DATE" ] && [[ ! "$SPRINT_END_DATE" =~ ^\(.*$ ]]; then
    # Try to calculate days remaining
    if date -d "$SPRINT_END_DATE" >/dev/null 2>&1; then
      DAYS_REMAINING=$(( ($(date -d "$SPRINT_END_DATE" +%s) - $(date +%s)) / 86400 ))
      
      # Update days remaining - using awk for safer in-place editing
      awk -v remaining="$DAYS_REMAINING" '{
        if ($0 ~ /- Days remaining:/) {
          print "- Days remaining: " remaining " days"
        } else {
          print $0
        }
      }' "$SESSION_FILE" > "${SESSION_FILE}.tmp" && mv "${SESSION_FILE}.tmp" "$SESSION_FILE"
    fi
  fi
else
  # If no sprint info exists, add placeholder section using awk
  # This creates a temporary file with sprint info added and replaces the original
  awk -v today="$(date +"%Y-%m-%d")" '
    /#### Project Status/ {in_status=1}
    /#### Current Focus/ {
      if (in_status) {
        print "\n### Current Sprint";
        print "- Name: (Not set)";
        print "- Start: " today;
        print "- End: (Not set)";
        print "- Days remaining: (Not set)";
        print "- Progress: 0%\n";
      }
      in_status=0;
    }
    {print}
  ' "$SESSION_FILE" > "${SESSION_FILE}.tmp" && mv "${SESSION_FILE}.tmp" "$SESSION_FILE"
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

# Create safe variables for awk
TIME_NOW=$(date +"%H:%M")
COMMIT_MSG_SAFE=$(echo "$LAST_COMMIT_MSG" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed "s/'/\\\\'/g")
COMMIT_FILES_SAFE=$(echo "$LAST_COMMIT_FILES" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed "s/'/\\\\'/g")
LINES_CHANGED_SAFE=$(echo "$LINES_CHANGED" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed "s/'/\\\\'/g")

# Create a temporary file for safer file operations
TMP_FILE=$(mktemp)

# Update the Last Activity section with awk
awk -v icon="$ICON" -v time="$TIME_NOW" -v msg="$COMMIT_MSG_SAFE" -v files="$COMMIT_FILES_SAFE" -v lines="$LINES_CHANGED_SAFE" '
  /#### Last Activity/ {
    print "#### Last Activity";
    print icon " **" time "** - " msg lines;
    print "- Modified files:";
    print "```";
    print files;
    print "```";
    print "";
    looking_for_next_tasks = 1;
    next;
  }
  
  /#### Next Tasks/ {
    looking_for_next_tasks = 0;
  }
  
  {
    if (!looking_for_next_tasks) print;
  }
' "$SESSION_FILE" > "$TMP_FILE"

# If Last Activity section wasn't found, add it before Next Tasks
if ! grep -q "#### Last Activity" "$TMP_FILE"; then
  awk -v icon="$ICON" -v time="$TIME_NOW" -v msg="$COMMIT_MSG_SAFE" -v files="$COMMIT_FILES_SAFE" -v lines="$LINES_CHANGED_SAFE" '
    /#### Next Tasks/ {
      print "#### Last Activity";
      print icon " **" time "** - " msg lines;
      print "- Modified files:";
      print "```";
      print files;
      print "```";
      print "";
      print $0;
      next;
    }
    { print }
  ' "$SESSION_FILE" > "$TMP_FILE"
fi

# Replace the original file with our updated version
cat "$TMP_FILE" > "$SESSION_FILE"
rm "$TMP_FILE"

# Add SESSION.md to git (will be committed by auto-commit script)
git add "$SESSION_FILE"

# If we archived anything, add that too
if [ -f "$ARCHIVE_FILE" ]; then
  git add "$ARCHIVE_FILE"
fi

# Clean up temporary files
rm -f /tmp/activity_lines.txt