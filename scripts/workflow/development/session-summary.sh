#!/bin/bash

# session-summary.sh - Generates a summary of the current session
# Usage: ./scripts/session-summary.sh [since_hours_ago]

# Get the workflow directory
WORKFLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get the repository root directory (two levels up from the workflow dir)
REPO_DIR="$(cd "$WORKFLOW_DIR/../.." && pwd)"
SESSION_FILE="$REPO_DIR/SESSION.md"
HOURS_AGO=${1:-24}  # Default to last 24 hours if not specified
SESSION_START=$(date -d "$HOURS_AGO hours ago" +"%Y-%m-%d %H:%M:%S")
CURRENT_DATE=$(date +"%B %d, %Y")
CURRENT_TIME=$(date +"%H:%M:%S")

echo "Generating session summary since $SESSION_START..."

# Get current branch
BRANCH=$(git branch --show-current)

# Get commit count and list
COMMITS=$(git log --since="$HOURS_AGO hours ago" --oneline)
COMMIT_COUNT=$(echo "$COMMITS" | grep -v "^$" | wc -l)

# Get files changed
FILES_CHANGED=$(git diff --name-only --diff-filter=ACDMRT @{$HOURS_AGO.hours.ago} | sort | uniq)
FILE_COUNT=$(echo "$FILES_CHANGED" | grep -v "^$" | wc -l)

# Get lines changed
LINES_ADDED=0
LINES_DELETED=0
if [ $COMMIT_COUNT -gt 0 ]; then
  LINES_STATS=$(git diff --stat @{$HOURS_AGO.hours.ago} | tail -n 1)
  LINES_ADDED=$(echo "$LINES_STATS" | grep -o "[0-9]* insertion" | grep -o "[0-9]*" || echo "0")
  LINES_DELETED=$(echo "$LINES_STATS" | grep -o "[0-9]* deletion" | grep -o "[0-9]*" || echo "0")
fi

# Get current focus from SESSION.md
CURRENT_FOCUS=$(grep -A 10 "#### Current Focus" "$SESSION_FILE" | tail -n +2 | sed '/####/,$d')

# Determine primary change types
FEATURE_COMMITS=$(git log --since="$HOURS_AGO hours ago" --oneline | grep -i "feature" | wc -l)
FIX_COMMITS=$(git log --since="$HOURS_AGO hours ago" --oneline | grep -i "fix\|bug" | wc -l)
DOCS_COMMITS=$(git log --since="$HOURS_AGO hours ago" --oneline | grep -i "doc" | wc -l)
TEST_COMMITS=$(git log --since="$HOURS_AGO hours ago" --oneline | grep -i "test" | wc -l)
REFACTOR_COMMITS=$(git log --since="$HOURS_AGO hours ago" --oneline | grep -i "refactor" | wc -l)

# Calculate time spent (approximate)
TIME_SPENT_MINUTES=$((HOURS_AGO * 60))
if [ $COMMIT_COUNT -gt 0 ]; then
  AVG_TIME_PER_COMMIT=$((TIME_SPENT_MINUTES / COMMIT_COUNT))
else
  AVG_TIME_PER_COMMIT=0
fi

# Generate the summary
cat <<EOF > "/tmp/session_summary_$CURRENT_DATE.md"
# Session Summary - $CURRENT_DATE

## Overview
- **Time Period**: Last $HOURS_AGO hours
- **Branch**: $BRANCH
- **Commits**: $COMMIT_COUNT
- **Files Changed**: $FILE_COUNT
- **Lines**: +$LINES_ADDED, -$LINES_DELETED
- **Estimated Time Spent**: ~$TIME_SPENT_MINUTES minutes
- **Generated**: $CURRENT_TIME

## Activity Breakdown
- Feature work: $FEATURE_COMMITS commits
- Bug fixes: $FIX_COMMITS commits
- Documentation: $DOCS_COMMITS commits
- Tests: $TEST_COMMITS commits
- Refactoring: $REFACTOR_COMMITS commits

## Current Focus
$CURRENT_FOCUS

## Changed Files
\`\`\`
$FILES_CHANGED
\`\`\`

## Recent Commits
\`\`\`
$COMMITS
\`\`\`

## Next Steps
[Add next steps for the project]

EOF

echo "Summary generated at /tmp/session_summary_$CURRENT_DATE.md"
cat "/tmp/session_summary_$CURRENT_DATE.md"