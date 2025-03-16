#!/bin/bash

# airtable.sh - Airtable integration functions for synergy.sh

# Import config
source "$(dirname "${BASH_SOURCE[0]}")/../core/config.sh"

# Update module status in Airtable
update_module_in_airtable() {
  MODULE="$1"
  STATUS="$2"
  PHASE="$3"
  
  if [ -z "$MODULE" ] || [ -z "$STATUS" ]; then
    echo_color "$YELLOW" "Usage: update_module_in_airtable \"Module Name\" [complete|in-progress|planned] [\"Phase Name\"]"
    return 1
  fi
  
  # Check if Airtable integration is available
  if [ ! -f "$AIRTABLE_SCRIPT" ]; then
    echo_color "$YELLOW" "Airtable integration not available. Skipping Airtable update."
    return 1
  fi
  
  # Call the Airtable script to update the module
  PHASE_ARG=""
  if [ -n "$PHASE" ]; then
    PHASE_ARG="\"$PHASE\""
  fi
  
  # Execute the command
  if [ -n "$PHASE_ARG" ]; then
    "$AIRTABLE_SCRIPT" update-module "$MODULE" "$STATUS" "$PHASE_ARG"
  else
    "$AIRTABLE_SCRIPT" update-module "$MODULE" "$STATUS"
  fi
  
  if [ $? -eq 0 ]; then
    echo_color "$GREEN" "Module status updated in Airtable."
  else
    echo_color "$RED" "Failed to update module status in Airtable."
    return 1
  fi
  
  return 0
}

# Log session to Airtable
log_session_to_airtable() {
  SESSION_FILE="$1"
  MODULE="$2"
  
  if [ -z "$SESSION_FILE" ] || [ ! -f "$SESSION_FILE" ]; then
    echo_color "$YELLOW" "Usage: log_session_to_airtable <session-file> [module-name]. No session file provided or not found."
    return 1
  fi
  
  # Check if Airtable integration is available
  if [ ! -f "$AIRTABLE_SCRIPT" ]; then
    echo_color "$YELLOW" "Airtable integration not available. Skipping Airtable session log."
    return 1
  fi
  
  # Call the Airtable script to log the session
  if [ -n "$MODULE" ]; then
    "$AIRTABLE_SCRIPT" log-session "$SESSION_FILE" "$MODULE"
  else
    "$AIRTABLE_SCRIPT" log-session "$SESSION_FILE"
  fi
  
  if [ $? -eq 0 ]; then
    echo_color "$GREEN" "Session logged in Airtable."
  else
    echo_color "$RED" "Failed to log session in Airtable."
    return 1
  fi
  
  return 0
}

# Set up Airtable for development tracking
setup_airtable() {
  # Check if Airtable integration is available
  if [ ! -f "$AIRTABLE_SCRIPT" ]; then
    echo_color "$RED" "Airtable integration script not found at $AIRTABLE_SCRIPT"
    return 1
  fi
  
  # Call the Airtable setup script
  "$AIRTABLE_SCRIPT" setup
  
  if [ $? -eq 0 ]; then
    echo_color "$GREEN" "Airtable setup completed successfully."
  else
    echo_color "$RED" "Failed to set up Airtable."
    return 1
  fi
  
  return 0
}