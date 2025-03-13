#!/bin/bash

# feature-template.sh - Creates a templated plan for a new feature
# Usage: ./scripts/feature-template.sh feature-name "Feature Description"

FEATURE_NAME=$1
FEATURE_DESC=$2
REPO_DIR="$(pwd)"
DATE=$(date +"%B %d, %Y")

if [ -z "$FEATURE_NAME" ]; then
  echo "Error: Feature name required."
  echo "Usage: ./scripts/feature-template.sh feature-name \"Feature Description\""
  exit 1
fi

if [ -z "$FEATURE_DESC" ]; then
  echo "Error: Feature description required."
  echo "Usage: ./scripts/feature-template.sh feature-name \"Feature Description\""
  exit 1
fi

# Create feature directory and plan file
mkdir -p "$REPO_DIR/features"
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

echo "Feature template created at: $FEATURE_FILE"
echo "Branch creation command: ./scripts/branch-manager.sh start $FEATURE_NAME"
echo ""
echo "Remember to fill in the implementation details before starting development!"