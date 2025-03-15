#!/bin/bash

# check-docs.sh - Script to check for outdated documentation
# Run periodically to ensure documentation stays current

# Get repository directory
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../../ && pwd)"
MODULE_TRACKER="$REPO_DIR/docs/project/MODULE_TRACKER.md"
ROADMAP_FILE="$REPO_DIR/docs/project/DEVELOPMENT_ROADMAP.md"
PROJECT_TRACKER="$REPO_DIR/docs/project/PROJECT_TRACKER.md"
LOG_FILE="$REPO_DIR/logs/doc-check.log"

# Ensure log directory exists
mkdir -p "$REPO_DIR/logs"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "===============================================" >> "$LOG_FILE"
echo "Documentation check at $(date)" >> "$LOG_FILE"
echo "===============================================" >> "$LOG_FILE"

# Check for inconsistencies between MODULE_TRACKER and DEVELOPMENT_ROADMAP
echo -e "${YELLOW}Checking for module status inconsistencies...${NC}"

# Get completed modules from MODULE_TRACKER
COMPLETED_MODULES=$(grep -F "✅ Completed" "$MODULE_TRACKER" | sed -E 's/.*\| ([^|]+) \| .*/\1/g' | awk '{$1=$1};1')

# Check each completed module in the roadmap
INCONSISTENCIES=0
for module in $COMPLETED_MODULES; do
  module_pattern=$(echo $module | sed 's/ /\\s/g')
  if grep -q "\[ \].*$module_pattern" "$ROADMAP_FILE"; then
    echo -e "${RED}Inconsistency: $module is completed in MODULE_TRACKER but not in ROADMAP${NC}"
    echo "Inconsistency: $module is completed in MODULE_TRACKER but not in ROADMAP" >> "$LOG_FILE"
    INCONSISTENCIES=$((INCONSISTENCIES+1))
  fi
done

# Check for current focus consistency
FOCUS_MODULE=$(grep "Focus Module" "$PROJECT_TRACKER" 2>/dev/null | cut -d':' -f2 | awk '{$1=$1};1')
if [ -n "$FOCUS_MODULE" ]; then
  if ! grep -q "(Current)" "$ROADMAP_FILE" || ! grep -q "$FOCUS_MODULE" "$ROADMAP_FILE"; then
    echo -e "${RED}Inconsistency: Current focus module ($FOCUS_MODULE) not properly marked in ROADMAP${NC}"
    echo "Inconsistency: Current focus module ($FOCUS_MODULE) not properly marked in ROADMAP" >> "$LOG_FILE"
    INCONSISTENCIES=$((INCONSISTENCIES+1))
  fi

  # Check for current focus consistency in MODULE_TRACKER
  FOCUS_PATTERN=$(echo "$FOCUS_MODULE" | sed 's/ /\\s*/g')
  MODULE_ENTRY=$(grep -A 2 "$FOCUS_PATTERN" "$MODULE_TRACKER" 2>/dev/null)
  if ! echo "$MODULE_ENTRY" | grep -q "In Progress"; then
    echo -e "${RED}Inconsistency: Current focus module ($FOCUS_MODULE) should be marked as In Progress${NC}"
    echo "Inconsistency: Current focus module ($FOCUS_MODULE) should be marked as In Progress" >> "$LOG_FILE"
    INCONSISTENCIES=$((INCONSISTENCIES+1))
  fi
else
  echo -e "${YELLOW}Warning: No focus module found in PROJECT_TRACKER${NC}"
  echo "Warning: No focus module found in PROJECT_TRACKER" >> "$LOG_FILE"
fi

# Final report
if [ $INCONSISTENCIES -eq 0 ]; then
  echo -e "${GREEN}All documentation is consistent! ✅${NC}"
  echo "All documentation is consistent!" >> "$LOG_FILE"
else
  echo -e "${RED}Found $INCONSISTENCIES inconsistencies in documentation.${NC}"
  echo "Found $INCONSISTENCIES inconsistencies in documentation." >> "$LOG_FILE"
  echo -e "${YELLOW}Run 'synergy.sh update-module \"$FOCUS_MODULE\" in-progress' to update.${NC}"
fi

echo "Documentation check completed at $(date)" >> "$LOG_FILE"