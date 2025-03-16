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
    
  # Create a new session
  create-session)
    DATE="$1"
    BRANCH="$2"
    FOCUS="$3"
    STATUS="$4"
    START_TIME="$5"
    END_TIME="$6"
    SUMMARY="$7"
    
    if [ -z "$DATE" ] || [ -z "$BRANCH" ] || [ -z "$FOCUS" ] || [ -z "$STATUS" ] || [ -z "$START_TIME" ]; then
      echo -e "${YELLOW}Usage: synergy-airtable.sh create-session <date> <branch> <focus> <status> <start_time> [<end_time>] [<summary>]${NC}"
      exit 1
    fi
    
    # Extract feature name from branch for better summaries
    FEATURE_NAME=""
    if [[ "$BRANCH" == feature/* ]]; then
      FEATURE_NAME=$(echo "$BRANCH" | sed 's/feature\///')
      # Convert dashes to spaces and capitalize words for readability
      FEATURE_NAME=$(echo "$FEATURE_NAME" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')
    fi
    
    # Generate a better summary if one wasn't provided
    if [ -z "$SUMMARY" ]; then
      if [ -n "$FEATURE_NAME" ]; then
        SUMMARY="Started implementation of $FEATURE_NAME functionality"
        
        # Add module context if available
        if [ -n "$FOCUS" ]; then
          SUMMARY="$SUMMARY, working on $FOCUS"
        fi
      elif [ -n "$FOCUS" ]; then
        SUMMARY="Started work on $FOCUS implementation"
      fi
    fi
    
    # Extract commits
    COMMITS=$(git log --pretty=format:"%h %s" --since="1 hour ago" | head -5 | tr '\n' '|')
    
    # Call Node.js script to create session
    $NODE_BIN -e "
      const airtable = require('$SCRIPT_DIR/airtable-integration');
      const session = {
        date: '$DATE',
        branch: '$BRANCH',
        module: '$FOCUS',
        status: '$STATUS',
        startTime: '$START_TIME',
        endTime: '$END_TIME',
        summary: '$SUMMARY',
        commits: '$COMMITS'.split('|').filter(c => c)
      };
      airtable.logSession(session)
        .then(result => {
          // Store the record ID for later updates
          if (result && result.id) {
            require('fs').writeFileSync('/tmp/synergy/session_id', result.id);
          }
          process.exit(result ? 0 : 1);
        })
        .catch(error => {
          console.error(error);
          process.exit(1);
        });
    "
    
    if [ $? -eq 0 ]; then
      echo -e "${GREEN}Session created in Airtable.${NC}"
    else
      echo -e "${RED}Failed to create session in Airtable.${NC}"
      exit 1
    fi
    ;;
    
  # Update an existing session
  update-session)
    STATUS="$1"
    END_TIME="$2"
    SUMMARY="$3"
    FOCUS="$4"
    
    if [ -z "$STATUS" ]; then
      echo -e "${YELLOW}Usage: synergy-airtable.sh update-session <status> [<end_time>] [<summary>] [<focus>]${NC}"
      exit 1
    fi
    
    # Get the session ID if available
    SESSION_ID=""
    if [ -f "/tmp/synergy/session_id" ]; then
      SESSION_ID=$(cat "/tmp/synergy/session_id")
    fi
    
    if [ -z "$SESSION_ID" ]; then
      echo -e "${YELLOW}No active session ID found. Cannot update session.${NC}"
      exit 1
    fi
    
    # Extract commits
    COMMITS=$(git log --pretty=format:"%h %s" --since="5 hours ago" | head -5 | tr '\n' '|')
    
    # Call Node.js script to update session
    $NODE_BIN -e "
      const airtable = require('$SCRIPT_DIR/airtable-integration');
      const updateData = {
        status: '$STATUS'
      };
      
      if ('$END_TIME') updateData.endTime = '$END_TIME';
      if ('$SUMMARY') updateData.summary = '$SUMMARY';
      if ('$FOCUS') updateData.module = '$FOCUS';
      if ('$COMMITS') updateData.commits = '$COMMITS'.split('|').filter(c => c);
      
      airtable.updateSession('$SESSION_ID', updateData)
        .then(result => {
          process.exit(result ? 0 : 1);
        })
        .catch(error => {
          console.error(error);
          process.exit(1);
        });
    "
    
    if [ $? -eq 0 ]; then
      echo -e "${GREEN}Session updated in Airtable.${NC}"
      # Remove the session ID file if the status is Completed
      if [ "$STATUS" = "Completed" ]; then
        rm -f "/tmp/synergy/session_id"
      fi
    else
      echo -e "${RED}Failed to update session in Airtable.${NC}"
      exit 1
    fi
    ;;
  
  # Get active session
  get-active-session)
    # Check if we have a session ID stored
    if [ ! -f "/tmp/synergy/session_id" ]; then
      echo -e "${YELLOW}No active session ID found.${NC}"
      exit 1
    fi
    
    SESSION_ID=$(cat "/tmp/synergy/session_id")
    
    # Call Node.js script to get session
    $NODE_BIN -e "
      const airtable = require('$SCRIPT_DIR/airtable-integration');
      airtable.getSession('$SESSION_ID')
        .then(session => {
          if (session) {
            console.log(JSON.stringify(session));
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
    
  # Get recent sessions
  get-recent-sessions)
    # Call Node.js script to get recent sessions
    $NODE_BIN -e "
      const airtable = require('$SCRIPT_DIR/airtable-integration');
      airtable.getRecentSessions()
        .then(sessions => {
          if (sessions && sessions.length > 0) {
            // Display summary of the last 3 sessions
            sessions.slice(0, 3).forEach(session => {
              const fields = session.fields;
              console.log(\`\${fields.Date || 'Unknown date'}: \${fields.Summary || 'No summary'} (\${fields.Status || 'Unknown status'})\`);
            });
            process.exit(0);
          } else {
            console.log('No recent sessions found');
            process.exit(1);
          }
        })
        .catch(error => {
          console.error(error);
          process.exit(1);
        });
    "
    ;;
    
  # Legacy log-session command (completely removed, but keeping command for backward compatibility)
  log-session)
    echo -e "${RED}Error: The log-session command has been removed.${NC}"
    echo -e "${YELLOW}Use create-session and update-session instead.${NC}"
    echo -e "${YELLOW}Example: synergy-airtable.sh create-session \"$(date '+%Y-%m-%d')\" \"$(git branch --show-current)\" \"Your Focus\" \"Active\" \"$(date '+%H:%M')\"${NC}"
    exit 1
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
    echo "  create-session <date> <branch> <focus> <status> <start_time> - Create a new session"
    echo "  update-session <status> [<end_time>] [<summary>] [<focus>] - Update an existing session"
    echo "  get-active-session - Get information about the active session"
    echo "  log-session <session-file> - (Legacy) Log a session from a file"
    echo "  get-phase - Get current phase information"
    echo "  get-module <module-name> - Get module information" 
    echo "  get-phase-modules <phase-number> - Get modules for a phase"
    echo "  maintain-sessions - Improve session summaries and module links"
    echo "  setup - Set up Airtable tables"
    exit 1
    ;;
esac