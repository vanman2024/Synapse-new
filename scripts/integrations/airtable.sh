#\!/bin/bash

# airtable.sh - Airtable integration functions for synergy.sh
# Enhanced with component registry and session maintenance capabilities

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
  if [ \! -f "$AIRTABLE_SCRIPT" ]; then
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

# Legacy function - replaced by direct API calls in session.sh
# This function is deprecated and will be removed
log_session_to_airtable() {
  echo_color "$YELLOW" "Warning: log_session_to_airtable is deprecated."
  echo_color "$BLUE" "Sessions are now automatically tracked directly in Airtable."
  echo_color "$BLUE" "Use 'synergy.sh start' and 'synergy.sh end' to manage sessions."
  
  return 0
}

# Set up Airtable for development tracking
setup_airtable() {
  # Check if Airtable integration is available
  if [ \! -f "$AIRTABLE_SCRIPT" ]; then
    echo_color "$RED" "Airtable integration script not found at $AIRTABLE_SCRIPT"
    return 1
  fi
  
  echo_color "$BLUE" "Setting up Airtable tables and importing data..."
  # Call the Airtable setup script
  "$AIRTABLE_SCRIPT" setup
  
  if [ $? -ne 0 ]; then
    echo_color "$RED" "Failed to set up Airtable tables."
    return 1
  fi
  
  echo_color "$BLUE" "Creating component registry..."
  # Run the component registry script
  node "$REPO_DIR/tools/dev-tracker/create-component-registry.js"
  
  if [ $? -ne 0 ]; then
    echo_color "$YELLOW" "Warning: Component registry setup had issues."
  fi
  
  echo_color "$BLUE" "Enhancing session tracking with Git context fields..."
  # Run the session enhancement script
  node "$REPO_DIR/tools/dev-tracker/enhance-sessions.js"
  
  if [ $? -ne 0 ]; then
    echo_color "$YELLOW" "Warning: Session enhancement had issues."
  fi
  
  # Run initial maintenance to clean up existing sessions
  echo_color "$BLUE" "Running initial maintenance on existing sessions..."
  "$AIRTABLE_SCRIPT" maintain-sessions
  
  echo_color "$GREEN" "Airtable setup completed successfully."
  return 0
}

# Register a component in Airtable
register_component() {
  NAME="$1"
  FILE_PATH="$2"
  COMPONENT_TYPE="$3"
  PURPOSE="$4"
  MODULE="$5"
  
  if [ -z "$NAME" ] || [ -z "$FILE_PATH" ] || [ -z "$COMPONENT_TYPE" ]; then
    echo_color "$YELLOW" "Usage: register_component <name> <file-path> <type> [<purpose>] [<module>]"
    echo_color "$YELLOW" "Component types: Controller, Service, Repository, Model, Middleware, Utility, Script, Configuration, Other"
    return 1
  fi
  
  # Check if Airtable integration is available
  if [ \! -f "$AIRTABLE_SCRIPT" ]; then
    echo_color "$YELLOW" "Airtable integration not available. Skipping component registration."
    return 1
  fi
  
  # Call the Airtable script to register the component
  "$AIRTABLE_SCRIPT" component-register "$NAME" "$FILE_PATH" "$COMPONENT_TYPE" "$PURPOSE" "$MODULE"
  
  if [ $? -eq 0 ]; then
    echo_color "$GREEN" "Component registered in Airtable."
  else
    echo_color "$RED" "Failed to register component in Airtable."
    return 1
  fi
  
  return 0
}

# List components in the registry
list_components() {
  MODULE="$1"
  
  # Check if Airtable integration is available
  if [ \! -f "$AIRTABLE_SCRIPT" ]; then
    echo_color "$YELLOW" "Airtable integration not available. Cannot list components."
    return 1
  fi
  
  # Call the Airtable script to list components
  if [ -n "$MODULE" ]; then
    "$AIRTABLE_SCRIPT" component-list "$MODULE"
  else
    "$AIRTABLE_SCRIPT" component-list
  fi
  
  return $?
}

# Maintain sessions in Airtable (improve descriptions and links)
maintain_sessions() {
  # Check if Airtable integration is available
  if [ \! -f "$AIRTABLE_SCRIPT" ]; then
    echo_color "$YELLOW" "Airtable integration not available. Cannot maintain sessions."
    return 1
  fi
  
  echo_color "$BLUE" "Running maintenance on Airtable sessions..."
  # Call the Airtable script to maintain sessions
  "$AIRTABLE_SCRIPT" maintain-sessions
  
  if [ $? -eq 0 ]; then
    echo_color "$GREEN" "Session maintenance completed successfully."
  else
    echo_color "$RED" "Failed to maintain sessions."
    return 1
  fi
  
  return 0
}
