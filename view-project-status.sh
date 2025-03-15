#!/bin/bash

# view-project-status.sh - Quick script to view project status
# This script provides a consolidated view of the project status

# Get the script directory (repo root)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to view a file with less
view_file() {
  local file_path="$1"
  
  if [ -f "$file_path" ]; then
    # Use less with quit-if-one-screen and RAW control chars
    less -FRX "$file_path"
  else
    clear
    echo -e "${YELLOW}File not found: $file_path${NC}"
    echo "Press Enter to return to the menu..."
    read
  fi
}

# Function to display the menu
show_menu() {
  clear
  echo -e "${BLUE}====================================================${NC}"
  echo -e "${BLUE}   SYNAPSE PROJECT STATUS VIEWER${NC}"
  echo -e "${BLUE}====================================================${NC}"
  echo ""
  echo -e "Choose a document to view (press 'q' to exit any document):"
  echo ""
  echo -e "${CYAN}Project Management:${NC}"
  echo -e "${GREEN}1)${NC} PROJECT_TRACKER     - Current status and overview"
  echo -e "${GREEN}2)${NC} MODULE_TRACKER      - Detailed module status"
  echo -e "${GREEN}3)${NC} DEVELOPMENT_ROADMAP - Development phases and roadmap"
  echo -e "${GREEN}4)${NC} PROJECT_ORGANIZATION - Project structure"
  echo ""
  echo -e "${CYAN}Workflows:${NC}"
  echo -e "${GREEN}5)${NC} WORKFLOWS           - Consolidated workflows reference"
  echo -e "${GREEN}d)${NC} DEVELOPMENT_WORKFLOW - Development workflow details"
  echo -e "${GREEN}s)${NC} WORKFLOW_SCRIPTS    - Workflow scripts documentation"
  echo -e "${GREEN}6)${NC} CI_CD_WORKFLOW      - CI/CD workflow documentation"
  echo ""
  echo -e "${CYAN}Claude Integration:${NC}"
  echo -e "${GREEN}c)${NC} View today's Claude compact summaries"
  echo -e "${GREEN}w)${NC} Start compact watcher in a new terminal"
  echo -e "${GREEN}a)${NC} Show all project statistics"
  echo ""
  echo -e "${GREEN}q)${NC} Quit"
  echo ""
}

# Function to show a project summary with key statistics
show_project_stats() {
  # Create a temporary file for the stats
  TEMP_FILE=$(mktemp)
  
  # Write stats to the temporary file
  {
    echo -e "SYNAPSE PROJECT STATS - $(date "+%B %d, %Y at %H:%M")"
    echo "===================================================="
    echo ""

    # Current git branch and status
    echo "GIT STATUS:"
    echo "Current branch: $(git branch --show-current)"
    git status --short | head -n 5
    if [ $(git status --short | wc -l) -gt 5 ]; then
      echo "... and $(expr $(git status --short | wc -l) - 5) more changes"
    fi
    echo ""

    # Show recent commits
    echo "RECENT COMMITS:"
    git log --oneline -n 3
    echo ""

    # Current development session
    echo "CURRENT SESSION:"
    if [ -f "$REPO_DIR/SESSION.md" ]; then
      grep -A 1 "## Current Session:" "$REPO_DIR/SESSION.md"
    else
      echo "No active session found"
    fi
    echo ""

    # Claude summaries
    echo "CLAUDE SUMMARIES:"
    COMPACT_COUNT=$(find "$REPO_DIR/sessions/claude" -name "compact-*.md" -type f | wc -l)
    LATEST_FILE=$(find "$REPO_DIR/sessions/claude" -name "compact-*.md" -type f -printf "%T@ %p\n" 2>/dev/null | sort -nr | head -n 1 | cut -d' ' -f2-)
    
    if [ -n "$LATEST_FILE" ]; then
      LATEST_DATE=$(basename "$LATEST_FILE" | sed 's/compact-\(.*\)\.md/\1/')
      echo "Total compact summaries: $COMPACT_COUNT"
      echo "Latest summary: $LATEST_DATE"
    else
      echo "No compact summaries found"
    fi
  } > "$TEMP_FILE"
  
  # Display the stats with less
  less -FRX "$TEMP_FILE"
  
  # Clean up
  rm -f "$TEMP_FILE"
}

# Main loop
while true; do
  show_menu
  read -p "Enter your choice: " choice
  
  case $choice in
    1)
      view_file "$REPO_DIR/docs/project/PROJECT_TRACKER.md"
      ;;
    2)
      view_file "$REPO_DIR/docs/project/MODULE_TRACKER.md"
      ;;
    3)
      view_file "$REPO_DIR/docs/project/DEVELOPMENT_ROADMAP.md"
      ;;
    4)
      view_file "$REPO_DIR/docs/project/PROJECT_ORGANIZATION.md"
      ;;
    5)
      view_file "$REPO_DIR/docs/project/developmentworkflows/WORKFLOWS.md"
      ;;
    d|D)
      view_file "$REPO_DIR/docs/project/developmentworkflows/DEVELOPMENT_WORKFLOW.md"
      ;;
    s|S)
      view_file "$REPO_DIR/docs/project/developmentworkflows/WORKFLOW_SCRIPTS.md"
      ;;
    6)
      view_file "$REPO_DIR/docs/project/developmentworkflows/CI_CD_WORKFLOW.md"
      ;;
    c|C)
      COMPACT_FILE="$REPO_DIR/sessions/claude/compact-$(date +"%Y%m%d").md"
      view_file "$COMPACT_FILE"
      ;;
    w|W)
      if command -v gnome-terminal &> /dev/null; then
        gnome-terminal -- "$REPO_DIR/start-compact-watch.sh"
        echo -e "${GREEN}Started compact watcher in a new terminal.${NC}"
      elif command -v xterm &> /dev/null; then
        xterm -e "$REPO_DIR/start-compact-watch.sh" &
        echo -e "${GREEN}Started compact watcher in a new terminal.${NC}"
      else
        echo -e "${YELLOW}Cannot start in new terminal. Run manually:${NC}"
        echo "./start-compact-watch.sh"
      fi
      echo "Press Enter to return to the menu..."
      read
      ;;
    a|A)
      show_project_stats
      ;;
    q|Q)
      clear
      echo "Exiting..."
      exit 0
      ;;
    *)
      echo -e "${YELLOW}Invalid choice.${NC}"
      echo "Press Enter to return to the menu..."
      read
      ;;
  esac
done