#!/bin/bash

# Auto-commit script to regularly push changes to GitHub
# Usage: ./scripts/auto-commit.sh [interval_minutes]

# Default interval is 5 minutes if not specified
INTERVAL=${1:-5}
REPO_DIR="$(pwd)"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

echo "Auto-commit script started at $TIMESTAMP"
echo "Working in: $REPO_DIR"
echo "Commit interval: $INTERVAL minutes"

# Make sure we're in a git repository
if [ ! -d "$REPO_DIR/.git" ]; then
  echo "Error: Not a git repository"
  exit 1
fi

# Function to update RECOVERY.md file
update_recovery_file() {
  RECOVERY_FILE="$REPO_DIR/RECOVERY.md"
  TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
  
  # Create the file if it doesn't exist
  if [ ! -f "$RECOVERY_FILE" ]; then
    echo "# Synapse Project - Progress Tracker" > "$RECOVERY_FILE"
    echo "" >> "$RECOVERY_FILE"
    echo "This file tracks our progress so we can quickly resume after interruptions." >> "$RECOVERY_FILE"
    echo "" >> "$RECOVERY_FILE"
    echo "## Project Information" >> "$RECOVERY_FILE"
    echo "- **Project Path:** \`$REPO_DIR\`" >> "$RECOVERY_FILE"
    echo "- **GitHub Repo:** https://github.com/vanman2024/Synapse-new" >> "$RECOVERY_FILE"
    echo "" >> "$RECOVERY_FILE"
    echo "## Last Auto-Update" >> "$RECOVERY_FILE"
    echo "- **Timestamp:** Initial setup" >> "$RECOVERY_FILE"
    echo "- **Last Commit:** None" >> "$RECOVERY_FILE"
    echo "- **Recently Modified Files:**" >> "$RECOVERY_FILE"
    echo "\`\`\`" >> "$RECOVERY_FILE"
    echo "None" >> "$RECOVERY_FILE"
    echo "\`\`\`" >> "$RECOVERY_FILE"
    echo "" >> "$RECOVERY_FILE"
    echo "## Current Progress" >> "$RECOVERY_FILE"
    echo "" >> "$RECOVERY_FILE"
    echo "### Components Implemented" >> "$RECOVERY_FILE"
    echo "- ✅ Project Structure & Configuration" >> "$RECOVERY_FILE"
    echo "- ✅ Airtable Data Access Layer" >> "$RECOVERY_FILE"
    echo "- ✅ CloudinaryService for image processing" >> "$RECOVERY_FILE"
    echo "- ✅ OpenAIService for AI generation" >> "$RECOVERY_FILE"
    echo "- ✅ Brand Repository implementation" >> "$RECOVERY_FILE"
    echo "- ✅ Brand Controller and API routes" >> "$RECOVERY_FILE"
    echo "- ✅ Express Server Setup" >> "$RECOVERY_FILE"
    echo "- ✅ Job Repository implementation" >> "$RECOVERY_FILE"
    echo "- ✅ Job Controller and API routes" >> "$RECOVERY_FILE"
    echo "- ✅ Comprehensive Folder Structure" >> "$RECOVERY_FILE"
    echo "" >> "$RECOVERY_FILE"
    echo "### In Progress" >> "$RECOVERY_FILE"
    echo "- 🔄 Content Generation System" >> "$RECOVERY_FILE"
    echo "- 🔄 Content Repository" >> "$RECOVERY_FILE"
    echo "" >> "$RECOVERY_FILE"
    echo "### Next Steps" >> "$RECOVERY_FILE"
    echo "1. Implement Content Repository" >> "$RECOVERY_FILE"
    echo "2. Implement Text Overlay System" >> "$RECOVERY_FILE"
    echo "3. Implement Approval Workflow with Slack" >> "$RECOVERY_FILE"
    echo "4. Implement Distribution System" >> "$RECOVERY_FILE"
    echo "" >> "$RECOVERY_FILE"
    echo "## Recovery Instructions" >> "$RECOVERY_FILE"
    echo "" >> "$RECOVERY_FILE"
    echo "1. **Check GitHub Repository:**" >> "$RECOVERY_FILE"
    echo "   \`\`\`bash" >> "$RECOVERY_FILE"
    echo "   cd $REPO_DIR && git status" >> "$RECOVERY_FILE"
    echo "   \`\`\`" >> "$RECOVERY_FILE"
    echo "" >> "$RECOVERY_FILE"
    echo "2. **Verify Project Structure:**" >> "$RECOVERY_FILE"
    echo "   \`\`\`bash" >> "$RECOVERY_FILE"
    echo "   cd $REPO_DIR && find src -type d | sort" >> "$RECOVERY_FILE"
    echo "   \`\`\`" >> "$RECOVERY_FILE"
    echo "" >> "$RECOVERY_FILE"
    echo "3. **Restart Auto-Commit:**" >> "$RECOVERY_FILE"
    echo "   \`\`\`bash" >> "$RECOVERY_FILE"
    echo "   cd $REPO_DIR && npm run auto-commit &" >> "$RECOVERY_FILE"
    echo "   \`\`\`" >> "$RECOVERY_FILE"
    echo "" >> "$RECOVERY_FILE"
    echo "4. **Check Current Dependencies:**" >> "$RECOVERY_FILE"
    echo "   \`\`\`bash" >> "$RECOVERY_FILE"
    echo "   cd $REPO_DIR && npm list --depth=0" >> "$RECOVERY_FILE"
    echo "   \`\`\`" >> "$RECOVERY_FILE"
  fi
  
  # Add last commit information
  LAST_COMMIT=$(git log -1 --pretty=format:"%h - %s")
  MODIFIED_FILES=$(git log -1 --name-only --pretty=format:"" | grep -v "RECOVERY.md" | sort | head -n 10)
  
  # Update the "Last Updated" section of the file
  sed -i '/## Last Auto-Update/,/## Current Progress/c\
## Last Auto-Update\
- **Timestamp:** '"$TIMESTAMP"'\
- **Last Commit:** '"$LAST_COMMIT"'\
- **Recently Modified Files:**\
```\
'"$MODIFIED_FILES"'\
```\
\
## Current Progress' "$RECOVERY_FILE"
  
  echo "Updated RECOVERY.md at $TIMESTAMP"
}

# Function to commit and push changes
commit_and_push() {
  cd "$REPO_DIR"
  
  # Always update the recovery file
  update_recovery_file
  
  # Check if there are changes to commit (including the updated RECOVERY.md)
  if git status --porcelain | grep -q .; then
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    
    git add "$REPO_DIR/RECOVERY.md"
    git commit -m "Auto-commit: Update RECOVERY.md at $TIMESTAMP"
    git push origin master
    echo "RECOVERY.md updated and pushed at $TIMESTAMP"
    
    # Check if there are other changes to commit
    if git status --porcelain | grep -q -v "RECOVERY.md"; then
      git add .
      git commit -m "Auto-commit: Other changes at $TIMESTAMP"
      git push origin master
      echo "Other changes committed and pushed at $TIMESTAMP"
    fi
  else
    echo "No changes to commit at $(date +"%Y-%m-%d %H:%M:%S")"
  fi
}

# Initial commit
commit_and_push

# Set up repeated commits
echo "Press Ctrl+C to stop auto-committing"
while true; do
  echo "Waiting $INTERVAL minutes before next commit..."
  sleep $(($INTERVAL * 60))
  commit_and_push
done