#!/bin/bash

# session.sh - Session management functions for synergy.sh

# Import config
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

# Start a development session with automatic tracking
start_session() {
  CURRENT_DATE=$(date "+%Y-%m-%d")
  CURRENT_TIME=$(date "+%H:%M")
  CURRENT_BRANCH=$(git branch --show-current)
  
  # Check if there's already an active session in Airtable for today
  # This is a placeholder - we'd need to query Airtable directly in the future
  if [ -f "/tmp/synergy/active_session" ]; then
    echo_color "$YELLOW" "A session appears to be active already."
    read -p "Do you want to start a new session anyway? (y/n): " choice
    if [ "$choice" != "y" ]; then
      echo_color "$GREEN" "Resuming existing session."
      return 0
    else
      # End the existing session silently before starting a new one
      "$REPO_DIR/tools/dev-tracker/synergy-airtable.sh" get-active-session > /dev/null 2>&1
      if [ $? -eq 0 ]; then
        end_session --silent
      fi
    fi
  fi
  
  # Get current module focus from the overview document
  # Look for the phase marked (Current) then extract modules from that phase
  CURRENT_PHASE_LINE=$(grep -n "(Current)" "$OVERVIEW_FILE" | cut -d':' -f1)
  
  if [ -n "$CURRENT_PHASE_LINE" ]; then
    # Look for incomplete modules (with "[ ]" rather than "[x]") in the current phase
    NEXT_PHASE_LINE=$(grep -n "## Phase" "$OVERVIEW_FILE" | awk -v start=$CURRENT_PHASE_LINE '$1 > start {print $1; exit}')
    
    if [ -z "$NEXT_PHASE_LINE" ]; then
      # If no next phase, read to the end of file
      FOCUS_MODULE=$(sed -n "$CURRENT_PHASE_LINE,\$p" "$OVERVIEW_FILE" | grep -m 1 "\[ \]" | sed -E 's/.*\[ \] (.*)/\1/')
    else
      # Otherwise read to the next phase
      FOCUS_MODULE=$(sed -n "$CURRENT_PHASE_LINE,$((NEXT_PHASE_LINE-1))p" "$OVERVIEW_FILE" | grep -m 1 "\[ \]" | sed -E 's/.*\[ \] (.*)/\1/')
    fi
  fi
  
  # If no focus module found, use a generic name
  if [ -z "$FOCUS_MODULE" ]; then
    FOCUS_MODULE="Development Tasks"
  fi
  
  # Create a temporary file to mark active session
  mkdir -p "/tmp/synergy"
  echo "$CURRENT_BRANCH,$FOCUS_MODULE,$CURRENT_TIME" > "/tmp/synergy/active_session"
  
  # Clear previous activity log
  rm -f "/tmp/synergy/activities.log"
  
  # Record first activity
  log_activity "Session started with focus on $FOCUS_MODULE"
  
  # Create the session record in Airtable
  source "$REPO_DIR/scripts/integrations/airtable.sh"
  "$REPO_DIR/tools/dev-tracker/synergy-airtable.sh" create-session "$CURRENT_DATE" "$CURRENT_BRANCH" "$FOCUS_MODULE" "Active" "$CURRENT_TIME" "" "Started development session focusing on $FOCUS_MODULE"

  echo_color "$GREEN" "Session started. Focus: $FOCUS_MODULE"
  
  # Update development overview based on current focus
  source "$REPO_DIR/scripts/core/module.sh"
  update_roadmap "$FOCUS_MODULE"
  
  # Start auto-commit in background if not already running
  source "$REPO_DIR/scripts/core/git-hooks.sh"
  if ! is_auto_commit_running; then
    start_auto_commit
    echo_color "$GREEN" "Auto-commit started in background."
  fi
  
  # Auto-update git hooks
  setup_git_hooks
  
  return 0
}

# Archive the current session file
archive_session() {
  if [ ! -f "$SESSION_FILE" ]; then
    return 0
  fi
  
  # Create archive directory if it doesn't exist
  mkdir -p "$SESSIONS_DIR"
  
  # Create daily archive file name
  ARCHIVE_DATE=$(date '+%Y%m%d')
  ARCHIVE_FILE="$SESSIONS_DIR/session-$ARCHIVE_DATE.md"
  CURRENT_TIME=$(date '+%H:%M:%S')
  
  # Check if the session is active
  if grep -q "Status: Active" "$SESSION_FILE"; then
    # Add a note that this session wasn't properly closed
    echo -e "\n### Note: This session was not properly closed before archiving\n" >> "$SESSION_FILE"
  fi
  
  # If daily file exists, append with separator
  if [ -f "$ARCHIVE_FILE" ]; then
    echo -e "\n\n---\n\n## Session at $CURRENT_TIME\n" >> "$ARCHIVE_FILE"
    cat "$SESSION_FILE" >> "$ARCHIVE_FILE"
  else
    # Create new daily file with header
    echo "# Synapse Development Sessions - $(date '+%B %d, %Y')" > "$ARCHIVE_FILE"
    echo -e "\n## Session at $CURRENT_TIME\n" >> "$ARCHIVE_FILE"
    cat "$SESSION_FILE" >> "$ARCHIVE_FILE"
  fi
  
  echo_color "$YELLOW" "Session archived to $ARCHIVE_FILE"
  return 0
}

# Update module progress based on git commits
update_module_progress() {
  # Extract module names from recent commits
  MODULE_PATTERN="feat|fix|update|refactor|test|docs"
  MODULES=$(git log --pretty=format:"%s" --since="5 hours ago" | grep -E "$MODULE_PATTERN" | grep -o -E "Content Service|Content Repository|Content Controller|Brand Style System|Asset Repository|[A-Z][a-z]+ [A-Z][a-z]+" | sort | uniq)
  
  # Default empty status
  if [ -z "$MODULES" ]; then
    echo "No specific modules updated in this session."
    return 0
  fi
  
  # Return formatted status
  echo "$MODULES" | while read -r module; do
    if [ -n "$module" ]; then
      echo "- Updated $module"
    fi
  done
  
  return 0
}

# End current session with summary and archiving
end_session() {
  # Check if silent mode is enabled
  SILENT=0
  if [ "$1" = "--silent" ]; then
    SILENT=1
  fi
  
  # Check if a session is active by looking for the temp file
  if [ ! -f "/tmp/synergy/active_session" ]; then
    if [ $SILENT -eq 0 ]; then
      echo_color "$YELLOW" "No active session found."
    fi
    return 1
  fi
  
  # Get session information from the active session file
  IFS=',' read -r BRANCH FOCUS_MODULE START_TIME <<< "$(cat "/tmp/synergy/active_session")"
  
  # Set end time
  END_TIME=$(date "+%H:%M")
  
  # Generate activity summary from git
  ACTIVITIES=$(git log --pretty=format:"- %s (%ar)" --since="5 hours ago" | head -5)
  
  # Extract module from commits to get focus area
  MODULE_PATTERN="feat|fix|update|refactor|test|docs"
  COMMIT_MODULE=$(git log --pretty=format:"%s" --since="5 hours ago" | grep -E "$MODULE_PATTERN" | grep -o -E "Content Service|Content Repository|Content Controller|Brand Style System|Asset Repository|[A-Z][a-z]+ [A-Z][a-z]+" | sort | uniq | head -1)
  
  # If we found a module in commits, use that instead of the original focus
  if [ -n "$COMMIT_MODULE" ]; then
    FOCUS_MODULE="$COMMIT_MODULE"
  fi
  
  # Generate summary
  SUMMARY="Development session on branch $BRANCH focusing on $FOCUS_MODULE."
  
  # Get activities from temp log if it exists
  if [ -f "/tmp/synergy/activities.log" ]; then
    ACTIVITIES_LOG=$(cat "/tmp/synergy/activities.log")
    SUMMARY="$SUMMARY Activities: $ACTIVITIES_LOG"
  fi
  
  # Add module progress
  MODULE_PROGRESS=$(update_module_progress)
  if [ -n "$MODULE_PROGRESS" ]; then
    SUMMARY="$SUMMARY Module progress: $MODULE_PROGRESS"
  fi
  
  # Update the session in Airtable
  "$REPO_DIR/tools/dev-tracker/synergy-airtable.sh" update-session "Completed" "$END_TIME" "$SUMMARY" "$FOCUS_MODULE"
  
  # Stop auto-commit if running
  source "$REPO_DIR/scripts/core/git-hooks.sh"
  stop_auto_commit
  
  # Remove active session marker
  rm -f "/tmp/synergy/active_session"
  
  # Automatically run maintenance to ensure proper linking
  "$REPO_DIR/tools/dev-tracker/synergy-airtable.sh" maintain-sessions > /dev/null 2>&1
  
  if [ $SILENT -eq 0 ]; then
    echo_color "$GREEN" "Session ended and updated in Airtable"
  fi
  
  return 0
}

# Clean up temporary session files
cleanup_sessions() {
  echo_color "$BLUE" "Cleaning up temporary session files..."
  
  # Clean up temporary files
  rm -f "/tmp/synergy/active_session"
  rm -f "/tmp/synergy/session_id"
  rm -f "/tmp/synergy/activities.log"
  
  echo_color "$GREEN" "Temporary session files cleaned up"
  
  # Ask if user wants to run Airtable maintenance
  read -p "Do you want to run Airtable session maintenance? (y/n): " choice
  if [ "$choice" = "y" ]; then
    "$REPO_DIR/tools/dev-tracker/synergy-airtable.sh" maintain-sessions
  fi
  
  return 0
}

# Show current status summary
show_status() {
  clear
  echo_color "$BLUE" "=================================================="
  echo_color "$BLUE" "           SYNAPSE PROJECT STATUS                "
  echo_color "$BLUE" "         $(date "+%B %d, %Y at %H:%M")           "
  echo_color "$BLUE" "=================================================="
  echo ""
  
  # Git status
  echo_color "$GREEN" "GIT STATUS:"
  echo "Current branch: $(git branch --show-current)"
  git status --short | head -n 5
  if [ $(git status --short | wc -l) -gt 5 ]; then
    echo "... and $(expr $(git status --short | wc -l) - 5) more changes"
  fi
  echo ""
  
  # Recent commits
  echo_color "$GREEN" "RECENT COMMITS:"
  git log --oneline -n 3
  echo ""
  
  # Session status
  echo_color "$GREEN" "SESSION STATUS:"
  
  # Check for active session in temp file
  if [ -f "/tmp/synergy/active_session" ]; then
    echo "Active session in progress"
    IFS=',' read -r BRANCH FOCUS_MODULE START_TIME <<< "$(cat "/tmp/synergy/active_session")"
    echo "- Branch: $BRANCH"
    echo "- Focus: $FOCUS_MODULE"
    echo "- Started: $START_TIME"
    
    # Show recent activities if available
    if [ -f "/tmp/synergy/activities.log" ]; then
      echo ""
      echo "Recent activities:"
      tail -n 4 "/tmp/synergy/activities.log"
    fi
  else
    echo "No active session."
    
    # Check Airtable for recent sessions
    if [ -f "$AIRTABLE_SCRIPT" ]; then
      echo ""
      echo "Recent sessions in Airtable:"
      "$REPO_DIR/tools/dev-tracker/synergy-airtable.sh" get-recent-sessions 2>/dev/null || echo "  (Unable to fetch recent sessions)"
    fi
  fi
  echo ""
  
  # Check for Airtable integration
  source "$REPO_DIR/scripts/integrations/airtable.sh"
  if [ -f "$AIRTABLE_SCRIPT" ]; then
    echo_color "$GREEN" "AIRTABLE INTEGRATION:"
    
    # Get current phase from Airtable
    CURRENT_PHASE=$($AIRTABLE_SCRIPT get-phase 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$CURRENT_PHASE" ]; then
      echo "Airtable integration active"
      echo "Current phase tracked in Airtable"
    else
      echo "Airtable integration available but not configured"
      echo "Run 'synergy.sh airtable-setup' to configure"
    fi
  else
    echo_color "$GREEN" "MODULE PROGRESS:"
    
    # Fallback to overview file
    if [ -f "$OVERVIEW_FILE" ]; then
      CURRENT_PHASE=$(grep "(Current)" "$OVERVIEW_FILE" | sed -E 's/.*## Phase [0-9]+: (.*) \(Current\).*/\1/')
      if [ -n "$CURRENT_PHASE" ]; then
        echo "Current phase (from overview): $CURRENT_PHASE"
      fi
    fi
  fi
  echo ""
}