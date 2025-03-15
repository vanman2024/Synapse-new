#!/bin/bash

# project-menu.sh - Interactive menu for project management commands
# Provides easy access to project functions without remembering commands

# Get script directory (repo root)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$REPO_DIR/scripts"
WORKFLOW_DIR="$REPO_DIR/scripts/workflow"
CLAUDE_SCRIPTS="$WORKFLOW_DIR/claude"

# Define colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Load claude commands to make them available
load_claude_commands() {
  source "$SCRIPTS_DIR/claude-commands.sh" &>/dev/null
  source "$SCRIPTS_DIR/claude-api.sh" &>/dev/null
}

# Function to display the main menu
show_menu() {
  clear
  echo -e "${BLUE}====================================================${NC}"
  echo -e "${BLUE}   SYNAPSE PROJECT MANAGEMENT MENU                ${NC}"
  echo -e "${BLUE}   $(date "+%B %d, %Y at %H:%M")                  ${NC}"
  echo -e "${BLUE}====================================================${NC}"
  echo ""
  echo -e "${CYAN}Claude Interaction:${NC}"
  echo -e "${GREEN}1)${NC} Start Claude with context"
  echo -e "${GREEN}2)${NC} Save Claude compact summary"
  echo -e "${GREEN}3)${NC} Start compact watcher"
  echo -e "${GREEN}4)${NC} Ask Claude a question"
  echo -e "${GREEN}5)${NC} Review code with Claude"
  echo ""
  echo -e "${CYAN}Sessions:${NC}"
  echo -e "${GREEN}6)${NC} Start development session"
  echo -e "${GREEN}7)${NC} End current session"
  echo -e "${GREEN}8)${NC} List all sessions"
  echo ""
  echo -e "${CYAN}Git Management:${NC}"
  echo -e "${GREEN}9)${NC} Create smart commit"
  echo -e "${GREEN}10)${NC} Create new feature branch"
  echo -e "${GREEN}11)${NC} Create pull request"
  echo ""
  echo -e "${CYAN}Project Documentation:${NC}"
  echo -e "${GREEN}d)${NC} View project documents"
  echo -e "${GREEN}s)${NC} View project status"
  echo ""
  echo -e "${GREEN}q)${NC} Quit"
  echo ""
}

# Handle Claude-related operations
handle_claude() {
  local choice="$1"
  case $choice in
    1) # Start Claude with context
      "$REPO_DIR/start-claude-session.sh"
      ;;
    2) # Save Claude compact summary
      "$SCRIPTS_DIR/save-session.sh"
      ;;
    3) # Start compact watcher
      "$REPO_DIR/start-compact-watch.sh"
      ;;
    4) # Ask Claude a question
      clear
      echo -e "${BLUE}Ask Claude a Question${NC}"
      echo -e "------------------------"
      echo -e "Type your question below and press Enter."
      echo -e "(Press Ctrl+D on a new line when done for multi-line questions)"
      echo ""
      read -p "Question: " question
      if [ -z "$question" ]; then
        # For multi-line input
        echo "Enter multi-line question (press Ctrl+D when done):"
        question=$(cat)
      fi
      load_claude_commands
      ask_claude "$question"
      ;;
    5) # Review code with Claude
      clear
      echo -e "${BLUE}Code Review with Claude${NC}"
      echo -e "------------------------"
      read -p "Enter file to review: " file_path
      load_claude_commands
      review_code "$file_path"
      ;;
  esac
}

# Handle session-related operations
handle_session() {
  local choice="$1"
  case $choice in
    6) # Start development session
      if [ -x "$WORKFLOW_DIR/development/start-session.sh" ]; then
        "$WORKFLOW_DIR/development/start-session.sh"
      else
        echo -e "${YELLOW}Session script not found. Creating a basic session.${NC}"
        echo "## Current Session: $(date)" > "$REPO_DIR/SESSION.md"
        echo "Session started at $(date)" >> "$REPO_DIR/SESSION.md"
      fi
      ;;
    7) # End current session
      if [ -x "$WORKFLOW_DIR/development/session-end.sh" ]; then
        "$WORKFLOW_DIR/development/session-end.sh"
      else
        echo -e "${YELLOW}Session end script not found.${NC}"
        echo "Session ended at $(date)" >> "$REPO_DIR/SESSION.md"
      fi
      ;;
    8) # List all sessions
      if [ -x "$WORKFLOW_DIR/development/session-manager.sh" ]; then
        "$WORKFLOW_DIR/development/session-manager.sh" list
      else
        echo -e "${YELLOW}No session manager found.${NC}"
        ls -lt "$REPO_DIR/sessions" 2>/dev/null || echo "No sessions directory found."
      fi
      ;;
  esac
}

# Handle Git-related operations
handle_git() {
  local choice="$1"
  case $choice in
    9) # Create smart commit
      load_claude_commands
      smart_commit
      ;;
    10) # Create new feature branch
      clear
      echo -e "${BLUE}Create New Feature Branch${NC}"
      echo -e "------------------------"
      read -p "Enter feature name: " feature_name
      load_claude_commands
      feature "$feature_name"
      ;;
    11) # Create pull request
      clear
      echo -e "${BLUE}Create Pull Request${NC}"
      echo -e "------------------------"
      read -p "Enter PR title: " pr_title
      load_claude_commands
      pr "$pr_title"
      ;;
  esac
}

# Main loop
while true; do
  show_menu
  read -p "Enter your choice: " choice
  
  case $choice in
    1|2|3|4|5)
      handle_claude "$choice"
      ;;
    6|7|8)
      handle_session "$choice"
      ;;
    9|10|11)
      handle_git "$choice"
      ;;
    d|D)
      # View project documents
      "$REPO_DIR/view-project-status.sh"
      ;;
    s|S)
      # View project status - show quick stats
      clear
      echo -e "${BLUE}Project Status${NC}"
      echo -e "--------------"
      echo "Current branch: $(git branch --show-current)"
      echo "Modified files: $(git status --short | wc -l)"
      echo "Recent commit: $(git log -1 --oneline)"
      if [ -f "$REPO_DIR/SESSION.md" ]; then
        echo ""
        echo "Current session:"
        grep -A 1 "## Current Session" "$REPO_DIR/SESSION.md"
      fi
      echo ""
      echo "Press Enter to return to the menu..."
      read
      ;;
    q|Q)
      clear
      echo "Exiting..."
      exit 0
      ;;
    *)
      echo -e "${RED}Invalid choice.${NC}"
      echo "Press Enter to continue..."
      read
      ;;
  esac
  
  # After each command, pause to let the user see the output
  if [[ "$choice" != "d" && "$choice" != "D" ]]; then
    echo ""
    echo -e "${GREEN}Command completed.${NC} Press Enter to return to the menu..."
    read
  fi
done