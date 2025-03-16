#!/bin/bash

# check-docs.sh - Script to verify development overview document and Airtable integration
# Run periodically to ensure documentation stays current

# Get repository directory
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../../ && pwd)"
OVERVIEW_FILE="$REPO_DIR/docs/project/DEVELOPMENT_OVERVIEW.md"
SESSION_FILE="$REPO_DIR/SESSION.md"
LOG_FILE="$REPO_DIR/logs/doc-check.log"
AIRTABLE_SCRIPT="$REPO_DIR/tools/dev-tracker/synergy-airtable.sh"

# Ensure log directory exists
mkdir -p "$REPO_DIR/logs"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "===============================================" >> "$LOG_FILE"
echo "Documentation check at $(date)" >> "$LOG_FILE"
echo "===============================================" >> "$LOG_FILE"

echo -e "${YELLOW}Verifying overview document structure...${NC}"

# Check if overview file exists
if [ ! -f "$OVERVIEW_FILE" ]; then
  echo -e "${RED}Error: Overview file not found at $OVERVIEW_FILE${NC}"
  echo "Error: Overview file not found at $OVERVIEW_FILE" >> "$LOG_FILE"
  exit 1
fi

# Check for basic structure elements
INCONSISTENCIES=0

# 1. Check that the file has at least one phase marked as current
if ! grep -q "(Current)" "$OVERVIEW_FILE"; then
  echo -e "${RED}Inconsistency: No phase marked as (Current) in overview${NC}"
  echo "Inconsistency: No phase marked as (Current) in overview" >> "$LOG_FILE"
  INCONSISTENCIES=$((INCONSISTENCIES+1))
fi

# 2. Check that there's an "Immediate Next Steps" section
if ! grep -q "## Immediate Next Steps" "$OVERVIEW_FILE"; then
  echo -e "${RED}Inconsistency: No 'Immediate Next Steps' section in overview${NC}"
  echo "Inconsistency: No 'Immediate Next Steps' section in overview" >> "$LOG_FILE"
  INCONSISTENCIES=$((INCONSISTENCIES+1))
fi

# 3. Verify that the current session focus is in the current phase
if [ -f "$SESSION_FILE" ] && grep -q "Status: Active" "$SESSION_FILE"; then
  FOCUS_MODULE=$(grep "Focus:" "$SESSION_FILE" | cut -d':' -f2- | awk '{$1=$1};1')
  
  if [ -n "$FOCUS_MODULE" ]; then
    # Get the current phase section
    CURRENT_PHASE_LINE=$(grep -n "(Current)" "$OVERVIEW_FILE" | cut -d':' -f1)
    
    if [ -n "$CURRENT_PHASE_LINE" ]; then
      # Find the next phase or end of file
      NEXT_PHASE_LINE=$(grep -n "## Phase" "$OVERVIEW_FILE" | awk -v start=$CURRENT_PHASE_LINE '$1 > start {print $1; exit}')
      
      if [ -z "$NEXT_PHASE_LINE" ]; then
        # If no next phase, read to the end of file
        CURRENT_PHASE_CONTENT=$(sed -n "$CURRENT_PHASE_LINE,\$p" "$OVERVIEW_FILE")
      else
        # Otherwise read to the next phase
        CURRENT_PHASE_CONTENT=$(sed -n "$CURRENT_PHASE_LINE,$((NEXT_PHASE_LINE-1))p" "$OVERVIEW_FILE")
      fi
      
      # Escape focus module for pattern matching
      FOCUS_PATTERN=$(echo "$FOCUS_MODULE" | sed 's/[\[\]\/&.*]/\\&/g')
      
      if ! echo "$CURRENT_PHASE_CONTENT" | grep -q "$FOCUS_PATTERN"; then
        echo -e "${YELLOW}Warning: Current focus ($FOCUS_MODULE) not found in current phase${NC}"
        echo "Warning: Current focus ($FOCUS_MODULE) not found in current phase" >> "$LOG_FILE"
      fi
    fi
  fi
fi

# 4. Check Airtable integration
echo -e "${BLUE}Checking Airtable integration...${NC}"

# Check if Airtable integration script exists
if [ ! -f "$AIRTABLE_SCRIPT" ]; then
  echo -e "${YELLOW}Warning: Airtable integration script not found at $AIRTABLE_SCRIPT${NC}"
  echo "Warning: Airtable integration script not found at $AIRTABLE_SCRIPT" >> "$LOG_FILE"
else
  # Check if .env file exists with Airtable credentials
  if [ ! -f "$REPO_DIR/.env" ] || ! grep -q "DEV_AIRTABLE" "$REPO_DIR/.env"; then
    echo -e "${YELLOW}Warning: Airtable credentials not found in .env file${NC}"
    echo "Warning: Airtable credentials not found in .env file" >> "$LOG_FILE"
    echo -e "${BLUE}Create a .env file with DEV_AIRTABLE_PAT and DEV_AIRTABLE_BASE_ID for Airtable integration${NC}"
  else
    echo -e "${GREEN}Airtable credentials found ✅${NC}"
    
    # Check if we can get the current phase from Airtable
    CURRENT_PHASE=$($AIRTABLE_SCRIPT get-phase 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$CURRENT_PHASE" ]; then
      echo -e "${GREEN}Airtable integration working correctly ✅${NC}"
      echo "Airtable integration verified successfully" >> "$LOG_FILE"
    else
      echo -e "${YELLOW}Warning: Could not verify Airtable integration${NC}"
      echo "Warning: Could not verify Airtable integration" >> "$LOG_FILE"
      echo -e "${BLUE}Run 'synergy.sh airtable-setup' to set up Airtable integration${NC}"
    fi
  fi
fi

# Check for Modules with missing links to phases
echo -e "${BLUE}Checking for missing module links...${NC}"
if [ -f "$AIRTABLE_SCRIPT" ]; then
  node -e "
  try {
    const airtable = require('$REPO_DIR/tools/dev-tracker/airtable-client');
    airtable.findRecords('Modules', '{Phase} = \"\"')
      .then(records => {
        if (records.length > 0) {
          console.log('Modules missing phase links:');
          records.forEach(record => {
            console.log(\" - \" + record.fields['Module Name']);
          });
          console.log('Run tools/dev-tracker/create-linked-records.js to fix these issues');
        } else {
          console.log('All modules have correct phase links ✅');
        }
      })
      .catch(err => {
        console.error('Error checking modules: ' + err.message);
      });
  } catch (error) {
    console.error('Could not check module links: ' + error.message);
  }" 2>/dev/null || echo -e "${YELLOW}Could not check module links${NC}"
fi

# Final report
if [ $INCONSISTENCIES -eq 0 ]; then
  echo -e "${GREEN}Overview document structure is valid! ✅${NC}"
  echo "Overview document structure is valid!" >> "$LOG_FILE"
else
  echo -e "${RED}Found $INCONSISTENCIES issues in overview document.${NC}"
  echo "Found $INCONSISTENCIES issues in overview document." >> "$LOG_FILE"
  echo -e "${YELLOW}Run 'synergy.sh update-module \"Current Focus Module\" in-progress' to update.${NC}"
fi

echo "Documentation check completed at $(date)" >> "$LOG_FILE"