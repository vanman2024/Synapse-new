#!/bin/bash

# module.sh - Module tracking and management functions for synergy.sh

# Import config
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

# Update phase focus in overview and tracking systems
update_roadmap() {
  FOCUS_MODULE="$1"
  STATUS="$2"
  
  if [ -z "$FOCUS_MODULE" ]; then
    return 1
  fi
  
  # If overview file exists, update it for reference
  if [ ! -f "$OVERVIEW_FILE" ]; then
    echo_color "$YELLOW" "Warning: Overview file not found. Creating reference phases only in tracking system."
    return 1
  fi
  
  # Set up status - if none provided, assume we're just updating the focus
  if [ -z "$STATUS" ]; then
    # Find the phase containing our focus module
    FOCUS_PATTERN=$(echo "$FOCUS_MODULE" | sed 's/[\/&]/\\&/g')
    PHASE_CONTENT=$(grep -A20 "## Phase" "$OVERVIEW_FILE" | grep -B20 "$FOCUS_PATTERN" | grep "## Phase")
    
    if [ -n "$PHASE_CONTENT" ]; then
      # Found the phase, update it to current
      sed -i 's/(Current)/(Previous)/g' "$OVERVIEW_FILE"
      
      # Extract the phase number and name
      PHASE_NUM=$(echo "$PHASE_CONTENT" | sed -E 's/## Phase ([0-9]+):.*/\1/')
      PHASE_NAME=$(echo "$PHASE_CONTENT" | sed -E 's/## Phase [0-9]+: (.*) \(.*/\1/')
      
      # Update the phase to current
      sed -i "s/## Phase $PHASE_NUM: $PHASE_NAME (Previous)/## Phase $PHASE_NUM: $PHASE_NAME (Current)/g" "$OVERVIEW_FILE"
    fi
  elif [ "$STATUS" = "complete" ]; then
    # Mark the module as completed in the overview using a pattern match approach
    # Escape module name for pattern matching
    MODULE_PATTERN=$(echo "$FOCUS_MODULE" | sed 's/[\/&]/\\&/g' | sed 's/ /[[:space:]]\+/g')
    
    # Find any instances of the module in the overview and mark as completed
    if grep -qi "$MODULE_PATTERN" "$OVERVIEW_FILE"; then
      sed -i "s/- \[ \]\(.*$MODULE_PATTERN\)/- [x]\1/gi" "$OVERVIEW_FILE"
      echo_color "$GREEN" "Updated local overview: Marked $FOCUS_MODULE as completed"
    fi
  fi
  
  # If we have an overview file, update the immediate next steps
  if [ -f "$OVERVIEW_FILE" ]; then
    NEXT_STEPS_LINE=$(grep -n "## Immediate Next Steps" "$OVERVIEW_FILE" | cut -d':' -f1)
    if [ -n "$NEXT_STEPS_LINE" ]; then
      # Clear existing next steps (remove 5 lines after the header)
      sed -i "$((NEXT_STEPS_LINE+1)),+5d" "$OVERVIEW_FILE"
      
      # Add new next steps based on the focus module
      if [[ "$FOCUS_MODULE" == *"Content"* ]]; then
        cat >> "$OVERVIEW_FILE" << EOF
1. Implement $FOCUS_MODULE with AI integration
2. Create templates for content generation
3. Complete unit tests for $FOCUS_MODULE
4. Update API endpoints for content management
5. Start work on Brand Style System integration
EOF
      elif [[ "$FOCUS_MODULE" == *"Brand"* ]]; then
        cat >> "$OVERVIEW_FILE" << EOF
1. Implement $FOCUS_MODULE for styling management
2. Create theme extraction capabilities
3. Integrate with Cloudinary for asset storage
4. Complete unit tests for $FOCUS_MODULE
5. Update API endpoints for brand management
EOF
      else
        cat >> "$OVERVIEW_FILE" << EOF
1. Implement $FOCUS_MODULE functionality
2. Create supporting components
3. Complete unit tests for $FOCUS_MODULE
4. Update related documentation
5. Integrate with existing modules
EOF
      fi
    fi
  fi
  
  echo_color "$GREEN" "Updated focus to: $FOCUS_MODULE"
  
  return 0
}

# Update module status in tracking systems
update_module() {
  MODULE="$1"
  STATUS="$2"
  
  if [ -z "$MODULE" ] || [ -z "$STATUS" ]; then
    echo_color "$YELLOW" "Usage: synergy.sh update-module \"Module Name\" [complete|in-progress|planned]"
    return 1
  fi
  
  # First, update the session file to reflect current focus
  if [ "$STATUS" = "in-progress" ] && [ -f "$SESSION_FILE" ]; then
    # Update focus in session file
    update_session_field "Focus" "$MODULE"
    sed -i "s/Current focus is on.*/Current focus is on $MODULE implementation./" "$SESSION_FILE"
    
    # Add to session log
    log_to_session "Started work on module: $MODULE"
  elif [ "$STATUS" = "complete" ] && [ -f "$SESSION_FILE" ]; then
    # Add to session log
    log_to_session "Completed module: $MODULE"
  fi
  
  # Update Airtable if integration is available
  source "$REPO_DIR/scripts/integrations/airtable.sh"
  update_module_in_airtable "$MODULE" "$STATUS"
  
  # Fallback to updating the overview document
  if [ -f "$OVERVIEW_FILE" ]; then
    # Escape module name for pattern matching
    MODULE_PATTERN=$(echo "$MODULE" | sed 's/[\/&.]/\\&/g')
    
    if [ "$STATUS" = "complete" ]; then
      # Update the overview document as fallback
      sed -i "s/\- \[ \]\s*$MODULE_PATTERN/\- [x] $MODULE_PATTERN/" "$OVERVIEW_FILE"
      echo_color "$GREEN" "✅ Updated local overview: $MODULE is now marked as completed"
    fi
  fi
  
  # Check for invalid status
  if [ "$STATUS" != "complete" ] && [ "$STATUS" != "in-progress" ] && [ "$STATUS" != "planned" ]; then
    echo_color "$YELLOW" "Unknown status: $STATUS (use 'complete', 'in-progress', or 'planned')"
    return 1
  fi
  
  # Update roadmap focus
  update_roadmap "$MODULE" "$STATUS"
  
  return 0
}

# Create a feature branch and update tracking
feature() {
  FEATURE_NAME="$1"
  
  if [ -z "$FEATURE_NAME" ]; then
    echo_color "$YELLOW" "Usage: synergy.sh feature feature-name"
    return 1
  fi
  
  # Create branch
  git checkout -b "feature/$FEATURE_NAME"
  
  # Update session if active
  if [ -f "$SESSION_FILE" ] && grep -q "Status: Active" "$SESSION_FILE"; then
    # Update branch info
    update_session_field "Branch" "feature/$FEATURE_NAME"
    
    # Add activity
    log_to_session "Started feature: $FEATURE_NAME"
  fi
  
  echo_color "$GREEN" "Created and switched to branch: feature/$FEATURE_NAME"
  echo_color "$BLUE" "To track this feature, update the focus in the Development Overview document."
  
  return 0
}

# Smart commit with AI assistance or auto-detection
smart_commit() {
  MESSAGE="$1"
  
  # Check if there are staged changes
  if [ -z "$(git diff --cached --name-only)" ]; then
    echo_color "$YELLOW" "No staged changes found. Stage your changes first with 'git add'."
    return 1
  fi
  
  # If no message is provided, try to auto-generate one
  if [ -z "$MESSAGE" ]; then
    # Get the diff of staged changes
    DIFF_FILES=$(git diff --cached --name-only)
    
    # Try to infer the commit type
    if echo "$DIFF_FILES" | grep -q "test"; then
      TYPE="test"
    elif echo "$DIFF_FILES" | grep -q "\.md$"; then
      TYPE="docs"
    elif echo "$DIFF_FILES" | grep -q "fix\|bug"; then
      TYPE="fix"
    else
      TYPE="feat"
    fi
    
    # Determine the module being changed
    if echo "$DIFF_FILES" | grep -q -i "content"; then
      MODULE="Content"
    elif echo "$DIFF_FILES" | grep -q -i "brand"; then
      MODULE="Brand"
    elif echo "$DIFF_FILES" | grep -q -i "job"; then
      MODULE="Job"
    else
      MODULE=$(echo "$DIFF_FILES" | head -1 | xargs dirname | xargs basename)
    fi
    
    # Build the message
    MESSAGE="$TYPE: Update $MODULE implementation"
    
    echo_color "$BLUE" "Generated commit message: $NC $MESSAGE"
    read -p "Use this message? (y/edit): " choice
    
    if [ "$choice" = "edit" ]; then
      read -p "Enter your commit message: " MESSAGE
    elif [ "$choice" != "y" ]; then
      echo "Commit canceled."
      return 1
    fi
  fi
  
  # Perform the commit
  git commit -m "$MESSAGE"
  
  # Update session if active
  if [ -f "$SESSION_FILE" ] && grep -q "Status: Active" "$SESSION_FILE"; then
    log_to_session "Commit: $MESSAGE"
  fi
  
  echo_color "$GREEN" "Committed with message: $MESSAGE"
  return 0
}