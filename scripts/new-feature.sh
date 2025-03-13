#!/bin/bash

# new-feature.sh - Automatically creates a new feature branch and updates tracking
# Usage: ./scripts/new-feature.sh feature-name "Feature Description"

FEATURE_NAME=$1
FEATURE_DESC=$2
REPO_DIR="$(pwd)"
SESSION_FILE="$REPO_DIR/SESSION.md"
DATE=$(date +"%B %d, %Y")

if [ -z "$FEATURE_NAME" ]; then
  echo "Error: Feature name required."
  echo "Usage: ./scripts/new-feature.sh feature-name \"Feature Description\""
  exit 1
fi

if [ -z "$FEATURE_DESC" ]; then
  echo "Error: Feature description required."
  echo "Usage: ./scripts/new-feature.sh feature-name \"Feature Description\""
  exit 1
fi

# Create branch name with feature/ prefix if not already specified
if [[ ! "$FEATURE_NAME" == feature/* ]]; then
  BRANCH_NAME="feature/$FEATURE_NAME"
else
  BRANCH_NAME="$FEATURE_NAME"
fi

# Create and switch to new branch
git checkout -b "$BRANCH_NAME"
echo "Created and switched to branch: $BRANCH_NAME"

# Create features directory if it doesn't exist
mkdir -p "$REPO_DIR/features"

# Create the feature plan file
FEATURE_FILE="$REPO_DIR/features/${FEATURE_NAME}.md"
cat > "$FEATURE_FILE" << EOL
# Feature: ${FEATURE_NAME}
> Created: ${DATE}

## Description
${FEATURE_DESC}

## Implementation Plan

### Files to Create/Modify
- [ ] 
- [ ] 
- [ ] 

### Dependencies
- 

### Testing Strategy
- [ ] Unit tests:
- [ ] Integration tests:
- [ ] Manual tests:

### Tasks
1. [ ] 
2. [ ] 
3. [ ] 

## Notes
- 

## Review Checklist
- [ ] Code follows project style and conventions
- [ ] All tests are passing
- [ ] Documentation has been updated
- [ ] SESSION.md has been updated
EOL

# Update SESSION.md automatically
# Update Current Focus section
sed -i "/#### Current Focus/,/#### Last Activity/c\\#### Current Focus\\n- Working on feature: $FEATURE_NAME\\n- $FEATURE_DESC\\n\\n#### Last Activity" "$SESSION_FILE"

# Update branch status
sed -i "s/- Currently on:.*$/- Currently on: $BRANCH_NAME branch/" "$SESSION_FILE"

# Add both files to git
git add "$FEATURE_FILE" "$SESSION_FILE"
git commit -m "Start feature: $FEATURE_NAME"

echo "Feature '$FEATURE_NAME' set up successfully!"
echo "Feature plan created at: $FEATURE_FILE"
echo "SESSION.md has been updated with your new focus"
echo ""
echo "You're now ready to start implementing this feature."
echo "The auto-commit script will keep track of your progress automatically."