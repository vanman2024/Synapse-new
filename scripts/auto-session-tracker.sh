#!/bin/bash

# auto-session-tracker.sh - Automatically tracks session progress
# Set up as a git hook or run periodically with auto-commit

REPO_DIR="$(pwd)"
SESSION_FILE="$REPO_DIR/SESSION.md"
DATE=$(date +"%B %d, %Y")
BRANCH=$(git branch --show-current)
LAST_COMMIT_MSG=$(git log -1 --pretty=%B)
LAST_COMMIT_FILES=$(git log -1 --name-only --pretty=format:"")

# Update session date
sed -i "s/## Current Session:.*$/## Current Session: $DATE/" "$SESSION_FILE"

# Update branch status
sed -i "s/- Currently on:.*$/- Currently on: $BRANCH branch/" "$SESSION_FILE"

# Update last activity section with recent commits
ACTIVITY_SECTION=$(cat <<EOF
#### Last Activity
- Latest commit: "$LAST_COMMIT_MSG"
- Modified files:
\`\`\`
$LAST_COMMIT_FILES
\`\`\`
EOF
)

# Replace the Last Activity section
sed -i "/#### Last Activity/,/#### Next Tasks/c\\#### Last Activity\\n- Latest commit: \"$LAST_COMMIT_MSG\"\\n- Modified files:\\n\`\`\`\\n$LAST_COMMIT_FILES\\n\`\`\`\\n\\n#### Next Tasks" "$SESSION_FILE"

# Add SESSION.md to git (will be committed by auto-commit script)
git add "$SESSION_FILE"