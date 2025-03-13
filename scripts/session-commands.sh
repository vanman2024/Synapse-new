#!/bin/bash

# session-commands.sh - Process commands from SESSION.md
# Usage: ./scripts/session-commands.sh [command]

REPO_DIR="$(pwd)"
SESSION_FILE="$REPO_DIR/SESSION.md"
COMMAND=$1

# Available commands
function show_help {
  echo "Available commands:"
  echo "  @focus:component - Set current focus to a specific component"
  echo "  @sprint:name,start-date,end-date - Set current sprint information"
  echo "  @todo:task - Add a task to Next Tasks"
  echo "  @summary - Generate session summary"
  echo "  @help - Show this help"
}

function set_focus {
  COMPONENT=$1
  if [ -z "$COMPONENT" ]; then
    echo "Error: Component name required"
    return 1
  fi
  
  # Update Current Focus section in SESSION.md
  FOCUS_CONTENT="- Working on component: $COMPONENT"
  
  # Find and update the Current Focus section
  if grep -q "#### Current Focus" "$SESSION_FILE"; then
    # Replace content after Current Focus header until next section
    sed -i "/#### Current Focus/,/#### Last Activity/c\\#### Current Focus\\n$FOCUS_CONTENT\\n\\n#### Last Activity" "$SESSION_FILE"
    echo "Focus set to: $COMPONENT"
  else
    echo "Error: Could not find Current Focus section in SESSION.md"
    return 1
  fi
}

function set_sprint {
  IFS=',' read -r NAME START_DATE END_DATE <<< "$1"
  
  if [ -z "$NAME" ] || [ -z "$START_DATE" ] || [ -z "$END_DATE" ]; then
    echo "Error: Sprint format should be name,start-date,end-date"
    return 1
  fi
  
  # Calculate days remaining
  DAYS_REMAINING=$(( ($(date -d "$END_DATE" +%s) - $(date +%s)) / 86400 ))
  
  # Create sprint section
  SPRINT_SECTION="### Current Sprint\n- Name: $NAME\n- Start: $START_DATE\n- End: $END_DATE\n- Days remaining: $DAYS_REMAINING days\n- Progress: 0%"
  
  # Check if sprint section exists
  if grep -q "### Current Sprint" "$SESSION_FILE"; then
    # Replace existing sprint section
    sed -i "/### Current Sprint/,/### Progress Tracker/c\\$SPRINT_SECTION\\n\\n### Progress Tracker" "$SESSION_FILE"
  else
    # Insert new sprint section after ## Current Session
    sed -i "/## Current Session/a \\n$SPRINT_SECTION" "$SESSION_FILE"
  fi
  
  echo "Sprint set to: $NAME ($START_DATE to $END_DATE, $DAYS_REMAINING days remaining)"
}

function add_todo {
  TASK=$1
  if [ -z "$TASK" ]; then
    echo "Error: Task description required"
    return 1
  fi
  
  # Add task to Next Tasks section
  if grep -q "#### Next Tasks" "$SESSION_FILE"; then
    # Add task
    sed -i "/#### Next Tasks/a - [ ] $TASK" "$SESSION_FILE"
    echo "Task added: $TASK"
  else
    echo "Error: Could not find Next Tasks section in SESSION.md"
    return 1
  fi
}

function generate_summary {
  # Run session-summary.sh
  if [ -f "$REPO_DIR/scripts/session-summary.sh" ]; then
    $REPO_DIR/scripts/session-summary.sh
  else
    echo "Error: session-summary.sh not found"
    return 1
  fi
}

# Process command
if [ -z "$COMMAND" ]; then
  echo "Error: Command required"
  show_help
  exit 1
fi

# Parse command
if [[ "$COMMAND" == @help ]]; then
  show_help
elif [[ "$COMMAND" == @focus:* ]]; then
  COMPONENT=${COMMAND#@focus:}
  set_focus "$COMPONENT"
elif [[ "$COMMAND" == @sprint:* ]]; then
  SPRINT_INFO=${COMMAND#@sprint:}
  set_sprint "$SPRINT_INFO"
elif [[ "$COMMAND" == @todo:* ]]; then
  TASK=${COMMAND#@todo:}
  add_todo "$TASK"
elif [[ "$COMMAND" == @summary ]]; then
  generate_summary
else
  echo "Unknown command: $COMMAND"
  show_help
  exit 1
fi

# Commit changes to SESSION.md if needed
if git status --porcelain | grep -q "SESSION.md"; then
  git add "$SESSION_FILE"
  git commit -m "Command: $COMMAND"
  echo "Changes to SESSION.md committed"
fi

exit 0