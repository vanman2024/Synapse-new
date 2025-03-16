#!/bin/bash

# synergy-airtable.sh - Bridge script to connect synergy.sh with Airtable
# This script should be called by synergy.sh when performing development tracking operations

COMMAND="$1"
shift

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_BIN=$(which node)

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

case "$COMMAND" in
  # Module status updates
  update-module)
    MODULE="$1"
    STATUS="$2"
    PHASE="$3"
    
    if [ -z "$MODULE" ] || [ -z "$STATUS" ]; then
      echo -e "${YELLOW}Usage: synergy-airtable.sh update-module \"Module Name\" [complete|in-progress|planned] [\"Phase Name\"]${NC}"
      exit 1
    fi
    
    # Call dedicated script to update module
    PHASE_ARG=""
    if [ -n "$PHASE" ]; then
      PHASE_ARG="\"$PHASE\""
    fi
    
    $NODE_BIN "$SCRIPT_DIR/update-module-status.js" "$MODULE" "$STATUS" $PHASE_ARG
    
    if [ $? -eq 0 ]; then
      echo -e "${GREEN}Module status updated in Airtable.${NC}"
    else
      echo -e "${RED}Failed to update module status in Airtable.${NC}"
      exit 1
    fi
    ;;
    
  # Log session
  log-session)
    SESSION_FILE="$1"
    MODULE="$2"
    
    if [ -z "$SESSION_FILE" ] || [ ! -f "$SESSION_FILE" ]; then
      echo -e "${YELLOW}Usage: synergy-airtable.sh log-session <session-file> [module-name]. No session file provided or not found.${NC}"
      exit 1
    fi
    
    # Extract session data
    DATE=$(date '+%Y-%m-%d')
    BRANCH=$(grep "Branch:" "$SESSION_FILE" | cut -d':' -f2- | xargs)
    FOCUS=$(grep "Focus:" "$SESSION_FILE" | cut -d':' -f2- | xargs)
    STATUS=$(grep "Status:" "$SESSION_FILE" | cut -d':' -f2- | xargs)
    START_TIME=$(grep "Started:" "$SESSION_FILE" | cut -d':' -f2- | xargs)
    END_TIME=$(grep "Ended:" "$SESSION_FILE" | cut -d':' -f2- | xargs || echo "")
    
    # Extract summary
    SUMMARY=$(sed -n '/^### Session Summary$/,/^####/p' "$SESSION_FILE" | grep -v "^###" | grep -v "^####" | tr '\n' ' ')
    
    # Extract commits
    COMMITS=$(git log --pretty=format:"%h %s" --since="5 hours ago" | head -5 | tr '\n' '|')
    
    # If no MODULE is passed but we have FOCUS, use that
    if [ -z "$MODULE" ] && [ -n "$FOCUS" ]; then
      MODULE="$FOCUS"
    fi
    
    # Extract feature name from branch for better summaries
    FEATURE_NAME=""
    if [[ "$BRANCH" == feature/* ]]; then
      FEATURE_NAME=$(echo "$BRANCH" | sed 's/feature\///')
      # Convert dashes to spaces and capitalize words for readability
      FEATURE_NAME=$(echo "$FEATURE_NAME" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')
    fi
    
    # Generate a better summary if one doesn't exist in the session file
    GENERATED_SUMMARY=""
    if [ -z "$SUMMARY" ]; then
      if [ -n "$FEATURE_NAME" ]; then
        GENERATED_SUMMARY="Implementation of $FEATURE_NAME functionality"
        
        # Add module context if available
        if [ -n "$MODULE" ]; then
          GENERATED_SUMMARY="$GENERATED_SUMMARY, working on $MODULE"
        fi
        
        # Add commit context if available
        if [ -n "$COMMITS" ]; then
          COMMIT_TYPES=$(echo "$COMMITS" | grep -o -E "feat:|fix:|refactor:|docs:|test:" | sort | uniq | tr '\n' ' ')
          if [ -n "$COMMIT_TYPES" ]; then
            GENERATED_SUMMARY="$GENERATED_SUMMARY. Includes $COMMIT_TYPES changes."
          fi
        fi
      elif [ -n "$MODULE" ]; then
        GENERATED_SUMMARY="Work on $MODULE implementation"
      fi
    fi
    
    # Use Module from parameter or Focus if available
    MODULE_JSON=""
    if [ -n "$MODULE" ]; then
      # We need to pass the module name and let the integration script find the ID
      MODULE_JSON="module: '$MODULE',"
      echo -e "${BLUE}Linking session to module: $MODULE${NC}"
    fi
    
    # Set summary if we generated one
    SUMMARY_JSON=""
    if [ -n "$GENERATED_SUMMARY" ]; then
      SUMMARY_JSON="summary: '$GENERATED_SUMMARY',"
      echo -e "${BLUE}Generated summary: $GENERATED_SUMMARY${NC}"
    fi
    
    # Call Node.js script to log session
    $NODE_BIN -e "
      const airtable = require('$SCRIPT_DIR/airtable-integration');
      const session = {
        date: '$DATE',
        branch: '$BRANCH',
        focus: '$FOCUS',
        status: '$STATUS',
        startTime: '$START_TIME',
        endTime: '$END_TIME',
        summary: '${GENERATED_SUMMARY:-$SUMMARY}',
        commits: '$COMMITS'.split('|').filter(c => c),
        $MODULE_JSON
      };
      airtable.logSession(session)
        .then(result => {
          process.exit(result ? 0 : 1);
        })
        .catch(error => {
          console.error(error);
          process.exit(1);
        });
    "
    
    if [ $? -eq 0 ]; then
      echo -e "${GREEN}Session logged in Airtable.${NC}"
    else
      echo -e "${RED}Failed to log session in Airtable.${NC}"
      exit 1
    fi
    ;;
    
  # Get current phase
  get-phase)
    # Call Node.js script to get current phase
    $NODE_BIN -e "
      const airtable = require('$SCRIPT_DIR/airtable-integration');
      airtable.getCurrentPhase()
        .then(phase => {
          if (phase) {
            console.log(JSON.stringify(phase));
            process.exit(0);
          } else {
            process.exit(1);
          }
        })
        .catch(error => {
          console.error(error);
          process.exit(1);
        });
    "
    ;;
    
  # Get module info
  get-module)
    MODULE="$1"
    
    if [ -z "$MODULE" ]; then
      echo -e "${YELLOW}Usage: synergy-airtable.sh get-module \"Module Name\"${NC}"
      exit 1
    fi
    
    # Call Node.js script to get module info
    $NODE_BIN -e "
      const airtable = require('$SCRIPT_DIR/airtable-integration');
      airtable.getModuleInfo('$MODULE')
        .then(module => {
          if (module) {
            console.log(JSON.stringify(module));
            process.exit(0);
          } else {
            process.exit(1);
          }
        })
        .catch(error => {
          console.error(error);
          process.exit(1);
        });
    "
    ;;
    
  # Get modules for phase
  get-phase-modules)
    PHASE_NUMBER="$1"
    
    if [ -z "$PHASE_NUMBER" ]; then
      echo -e "${YELLOW}Usage: synergy-airtable.sh get-phase-modules <phase-number>${NC}"
      exit 1
    fi
    
    # Call Node.js script to get phase modules
    $NODE_BIN -e "
      const airtable = require('$SCRIPT_DIR/airtable-integration');
      airtable.getPhaseModules($PHASE_NUMBER)
        .then(modules => {
          console.log(JSON.stringify(modules));
          process.exit(0);
        })
        .catch(error => {
          console.error(error);
          process.exit(1);
        });
    "
    ;;
    
  # Run setup script
  setup)
    # Call Node.js script to set up Airtable
    $NODE_BIN "$SCRIPT_DIR/setup-airtable.js"
    ;;
    
  # Maintain sessions
  maintain-sessions)
    # Call Node.js script to maintain sessions
    $NODE_BIN "$SCRIPT_DIR/maintain-sessions.js"
    
    if [ $? -eq 0 ]; then
      echo -e "${GREEN}Sessions maintained successfully.${NC}"
    else
      echo -e "${RED}Failed to maintain sessions.${NC}"
      exit 1
    fi
    ;;
    
  # Unknown command
  *)
    echo -e "${YELLOW}Unknown command: $COMMAND${NC}"
    echo "Available commands:"
    echo "  update-module <module-name> <status> - Update module status"
    echo "  log-session <session-file> - Log a session in Airtable"
    echo "  get-phase - Get current phase information"
    echo "  get-module <module-name> - Get module information" 
    echo "  get-phase-modules <phase-number> - Get modules for a phase"
    echo "  maintain-sessions - Improve session summaries and module links"
    echo "  setup - Set up Airtable tables"
    exit 1
    ;;
esac