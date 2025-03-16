#!/bin/bash

# session.sh - Session management functions for synergy.sh

# Import config
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

# Start a development session with automatic tracking
start_session() {
  # Check if a session is already active
  if [ -f "$SESSION_FILE" ] && grep -q "Status: Active" "$SESSION_FILE"; then
    echo_color "$YELLOW" "A session is already active. End it first or resume."
    read -p "Do you want to resume the current session? (y/n): " choice
    if [ "$choice" != "y" ]; then
      # Archive the existing session before overwriting
      archive_session
      echo_color "$YELLOW" "Previous session archived before starting new session."
    else
      echo_color "$GREEN" "Resuming current session."
      return 0
    fi
  elif [ -f "$SESSION_FILE" ]; then
    # Archive any existing session file even if not active
    archive_session
    echo_color "$YELLOW" "Previous session archived before starting new session."
  fi

  # Create a new session
  CURRENT_DATE=$(date "+%B %d, %Y")
  CURRENT_BRANCH=$(git branch --show-current)
  
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
  
  # Start with template
  cat > "$SESSION_FILE" << EOF
# Synapse Development Session
## Current Session: $CURRENT_DATE

### Status: Active
- Branch: $CURRENT_BRANCH
- Started: $(date "+%H:%M")
- Focus: $FOCUS_MODULE

### Current Sprint
Current focus is on $FOCUS_MODULE implementation.

#### Current Focus
- Implement $FOCUS_MODULE
- Write tests for new functionality
- Update documentation

#### Last Activity
- Session started at $(date "+%H:%M")

#### Next Tasks
- Complete current implementation
- Run tests and verify functionality
- Update Development Overview

### Code Context
- Files: $(git status --short | wc -l) files with changes
- Commits: $(git log --oneline -n 1)
EOF

  echo_color "$GREEN" "Session started. Focus: $FOCUS_MODULE"
  
  # Update development overview based on current focus
  # This imports and runs update_roadmap from module.sh
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
  # Check if a session is active
  if [ ! -f "$SESSION_FILE" ] || ! grep -q "Status: Active" "$SESSION_FILE"; then
    echo_color "$YELLOW" "No active session found."
    return 1
  fi
  
  # Update session status
  sed -i 's/Status: Active/Status: Completed/' "$SESSION_FILE"
  
  # Add end time
  END_TIME=$(date "+%H:%M")
  sed -i "/^- Started:/a\\- Ended: $END_TIME" "$SESSION_FILE"
  
  # Generate activity summary from git
  ACTIVITIES=$(git log --pretty=format:"- %s (%ar)" --since="5 hours ago" | head -5)
  
  # Extract module from commits to get focus area
  MODULE_PATTERN="feat|fix|update|refactor|test|docs"
  FOCUS_MODULE=$(git log --pretty=format:"%s" --since="5 hours ago" | grep -E "$MODULE_PATTERN" | grep -o -E "Content Service|Content Repository|Content Controller|Brand Style System|Asset Repository|[A-Z][a-z]+ [A-Z][a-z]+" | sort | uniq | head -1)
  
  # Append summary to session
  cat >> "$SESSION_FILE" << EOF

### Session Summary
Session ended at $END_TIME

#### Completed Activities
$ACTIVITIES

#### Module Progress
$(update_module_progress)

EOF

  # Archive the session with proper closing
  archive_session
  
  # Stop auto-commit if running
  source "$REPO_DIR/scripts/core/git-hooks.sh"
  stop_auto_commit
  
  # Get current focus from session file
  CURRENT_FOCUS=$(extract_field "Focus" "$SESSION_FILE")
  
  # If no focus extracted from commits, use the session focus
  if [ -z "$FOCUS_MODULE" ]; then
    FOCUS_MODULE="$CURRENT_FOCUS"
  fi
  
  # Log session in Airtable with module information
  source "$REPO_DIR/scripts/integrations/airtable.sh"
  if [ -n "$FOCUS_MODULE" ]; then
    log_session_to_airtable "$SESSION_FILE" "$FOCUS_MODULE"
  else
    log_session_to_airtable "$SESSION_FILE"
  fi
  
  # Automatically run maintenance to ensure proper linking
  "$REPO_DIR/tools/dev-tracker/synergy-airtable.sh" maintain-sessions > /dev/null 2>&1
  
  echo_color "$GREEN" "Session ended and properly archived"
  
  return 0
}

# Clean up old session files
cleanup_sessions() {
  echo_color "$BLUE" "Cleaning up old session files..."
  
  # Get today's date for the consolidated file
  TODAY=$(date '+%Y%m%d')
  CONSOLIDATED_FILE="$SESSIONS_DIR/session-$TODAY.md"
  BACKUP_DIR="$SESSIONS_DIR/old-sessions"
  
  # Create backup directory if it doesn't exist
  mkdir -p "$BACKUP_DIR"
  
  # Find all timestamped session files for today
  SESSION_COUNT=0
  for file in "$SESSIONS_DIR"/session-$TODAY-*.md; do
    if [ -f "$file" ]; then
      # Extract the time from the filename
      FILE_TIME=$(basename "$file" | sed -E 's/session-[0-9]+-([0-9]+)\.md/\1/')
      
      # Add a separator and the session to the consolidated file
      echo -e "\n\n---\n\n## Session at $FILE_TIME\n" >> "$CONSOLIDATED_FILE"
      cat "$file" >> "$CONSOLIDATED_FILE"
      
      # Move the file to backup
      mv "$file" "$BACKUP_DIR/"
      SESSION_COUNT=$((SESSION_COUNT+1))
    fi
  done
  
  echo_color "$GREEN" "Consolidated $SESSION_COUNT sessions into $CONSOLIDATED_FILE"
  echo_color "$YELLOW" "Old files moved to $BACKUP_DIR"
  
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
  if [ -f "$SESSION_FILE" ]; then
    if grep -q "Status: Active" "$SESSION_FILE"; then
      echo "Active session in progress"
      grep -A 2 "Started:" "$SESSION_FILE"
      
      # Show recent activities
      echo ""
      echo "Recent activities:"
      grep -A 3 "#### " "$SESSION_FILE" | tail -n 4
    else
      echo "No active session. Last session ended at $(grep "Ended:" "$SESSION_FILE" | cut -d':' -f2- | xargs)"
    fi
  else
    echo "No session file found."
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