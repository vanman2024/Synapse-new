#!/bin/bash

# branch-manager.sh - A script to manage feature branches and session tracking
# Usage: ./scripts/branch-manager.sh [command] [branch-name]
#   Commands:
#     start    - Create and checkout a new feature branch
#     update   - Update SESSION.md with current progress
#     finish   - Merge feature branch to develop and update SESSION.md
#     status   - Show current branch and SESSION.md status

# Defaults
REPO_DIR="$(pwd)"
SESSION_FILE="$REPO_DIR/SESSION.md"
COMMAND=${1:-"status"}
BRANCH_NAME=${2:-""}
DATE=$(date +"%B %d, %Y")

# Check if we're in the repo root
if [ ! -d "$REPO_DIR/.git" ]; then
  echo "Error: Not in git repository root. Please run from the project root."
  exit 1
fi

# Function to update SESSION.md with current date and progress
update_session_file() {
  # Update the current session date
  sed -i "s/## Current Session:.*$/## Current Session: $DATE/" "$SESSION_FILE"
  
  # Get current branch
  CURRENT_BRANCH=$(git branch --show-current)
  
  # Update branch status
  sed -i "s/- Currently on:.*$/- Currently on: $CURRENT_BRANCH branch/" "$SESSION_FILE"
  
  echo "SESSION.md updated with today's date and current branch."
  
  # Stage the file for commit
  git add "$SESSION_FILE"
  git status --short
}

# Function to create a new feature branch
start_feature() {
  if [ -z "$BRANCH_NAME" ]; then
    echo "Error: Branch name required."
    echo "Usage: ./scripts/branch-manager.sh start feature-name"
    exit 1
  fi
  
  # Create branch name with feature/ prefix if not already specified
  if [[ ! "$BRANCH_NAME" == feature/* ]]; then
    BRANCH_NAME="feature/$BRANCH_NAME"
  fi
  
  # Create and checkout the branch
  git checkout -b "$BRANCH_NAME"
  
  # Update SESSION.md
  update_session_file
  
  echo "Feature branch $BRANCH_NAME created. SESSION.md updated."
  echo "Remember to update the 'Current Focus' and 'Next Tasks' sections!"
}

# Function to finish a feature branch
finish_feature() {
  CURRENT_BRANCH=$(git branch --show-current)
  
  # Check if we're on a feature branch
  if [[ ! "$CURRENT_BRANCH" == feature/* ]]; then
    echo "Error: Not on a feature branch. Current branch: $CURRENT_BRANCH"
    exit 1
  fi
  
  # Confirm with user
  read -p "Ready to merge $CURRENT_BRANCH to develop? [y/N] " response
  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 0
  fi
  
  # Make sure develop branch exists and is up to date
  if ! git show-ref --verify --quiet refs/heads/develop; then
    echo "Develop branch does not exist. Creating from main/master..."
    
    # Check if main or master exists
    if git show-ref --verify --quiet refs/heads/main; then
      git checkout main
      git checkout -b develop
    elif git show-ref --verify --quiet refs/heads/master; then
      git checkout master
      git checkout -b develop
    else
      echo "Error: Neither main nor master branch exists."
      exit 1
    fi
  else
    git checkout develop
    git pull origin develop
  fi
  
  # Merge the feature branch
  git merge --no-ff "$CURRENT_BRANCH" -m "Merge $CURRENT_BRANCH into develop"
  
  # Update SESSION.md
  update_session_file
  
  echo "Feature branch $CURRENT_BRANCH merged to develop."
  echo "Remember to update SESSION.md with completed tasks!"
}

# Function to show status
show_status() {
  CURRENT_BRANCH=$(git branch --show-current)
  echo "Current branch: $CURRENT_BRANCH"
  echo ""
  echo "SESSION.md preview:"
  echo "-----------------"
  head -n 20 "$SESSION_FILE"
  echo "-----------------"
  echo ""
  echo "Git status:"
  git status --short
}

# Main execution
case "$COMMAND" in
  start)
    start_feature
    ;;
  update)
    update_session_file
    ;;
  finish)
    finish_feature
    ;;
  status|*)
    show_status
    ;;
esac

exit 0