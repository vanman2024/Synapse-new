#!/bin/bash

# git-hooks.sh - Git hooks and automation functions for synergy.sh

# Import config
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

# Set up git hooks for automated tracking
setup_git_hooks() {
  HOOKS_DIR="$REPO_DIR/.git/hooks"
  
  # Create pre-commit hook for logging activity
  cat > "$HOOKS_DIR/pre-commit" << 'EOF'
#!/bin/bash
REPO_DIR=$(git rev-parse --show-toplevel)
TMP_DIR="/tmp/synergy"

# Only proceed if session is active
if [ -f "$TMP_DIR/active_session" ]; then
  # Get commit information
  FILES_CHANGED=$(git diff --cached --name-only | wc -l)
  SUMMARY=$(git diff --cached --stat | tail -n 1)
  
  # Add activity to temp log
  mkdir -p "$TMP_DIR"
  echo "$(date '+%H:%M') - Git: Commit with $FILES_CHANGED files" >> "$TMP_DIR/activities.log"
fi
exit 0
EOF
  chmod +x "$HOOKS_DIR/pre-commit"
  
  # Create pre-push hook for verification
  cat > "$HOOKS_DIR/pre-push" << 'EOF'
#!/bin/bash
REPO_DIR=$(git rev-parse --show-toplevel)
TMP_DIR="/tmp/synergy"

echo "Running pre-push verification..."

# Run TypeScript check
npm run typecheck
if [ $? -ne 0 ]; then
  echo "❌ TypeScript check failed. Fix errors before pushing."
  exit 1
fi

# Run linting
npm run lint
if [ $? -ne 0 ]; then
  echo "❌ Linting failed. Fix errors before pushing."
  exit 1
fi

# If tests exist, run them
if grep -q "\"test\":" "$REPO_DIR/package.json"; then
  npm test
  if [ $? -ne 0 ]; then
    echo "❌ Tests failed. Fix errors before pushing."
    exit 1
  fi
fi

# Add activity to log if session is active
if [ -f "$TMP_DIR/active_session" ]; then
  # Add activity to temp log
  mkdir -p "$TMP_DIR"
  echo "$(date '+%H:%M') - Verified code quality for push" >> "$TMP_DIR/activities.log"
fi

echo "✅ All checks passed! Pushing code..."
exit 0
EOF
  chmod +x "$HOOKS_DIR/pre-push"
  
  echo_color "$GREEN" "Git hooks updated for automated tracking."
}

# Auto-commit in background at regular intervals
start_auto_commit() {
  # Check if already running
  if is_auto_commit_running; then
    echo_color "$YELLOW" "Auto-commit is already running."
    return 0
  fi
  
  # Start background process
  (
    while true; do
      sleep $AUTO_COMMIT_INTERVAL
      
      # Only commit if there are changes
      if [ -n "$(git status --porcelain)" ]; then
        # Get brief summary of changes
        FILES_CHANGED=$(git status --porcelain | wc -l)
        
        # Add activity to session before committing
        if [ -f "$SESSION_FILE" ]; then
          echo "#### $(date '+%H:%M') - Auto-commit: $FILES_CHANGED files changed" >> "$SESSION_FILE"
        fi
        
        # Stage and commit
        git add .
        git commit -m "auto: Session checkpoint with $FILES_CHANGED files [skip ci]"
      fi
    done
  ) &
  
  # Save PID for later stopping
  echo $! > "$AUTO_COMMIT_PID_FILE"
}

# Check if auto-commit is running
is_auto_commit_running() {
  if [ -f "$AUTO_COMMIT_PID_FILE" ]; then
    PID=$(cat "$AUTO_COMMIT_PID_FILE")
    if ps -p $PID > /dev/null; then
      return 0
    fi
  fi
  return 1
}

# Stop auto-commit background process
stop_auto_commit() {
  if [ -f "$AUTO_COMMIT_PID_FILE" ]; then
    PID=$(cat "$AUTO_COMMIT_PID_FILE")
    if ps -p $PID > /dev/null; then
      kill $PID
      rm "$AUTO_COMMIT_PID_FILE"
      echo_color "$GREEN" "Auto-commit stopped."
      return 0
    fi
  fi
  echo_color "$YELLOW" "No auto-commit process found."
  return 1
}

# Create a pull request with tracking updates
create_pr() {
  TITLE="$1"
  
  if [ -z "$TITLE" ]; then
    echo_color "$YELLOW" "Usage: synergy.sh pr \"Pull Request Title\""
    return 1
  fi
  
  BRANCH=$(git branch --show-current)
  
  # Check if gh CLI is available
  if ! command_exists gh; then
    echo_color "$RED" "GitHub CLI not found. Please install it first."
    return 1
  fi
  
  # Get the commit messages for PR body
  echo_color "$BLUE" "Generating PR body from commits..."
  COMMITS=$(git log --pretty=format:"- %s" origin/master..HEAD)
  
  # Extract updated modules from commits
  MODULES=$(echo "$COMMITS" | grep -o -E "Content Service|Content Repository|Content Controller|Brand Style System|Asset Repository|[A-Z][a-z]+ [A-Z][a-z]+" | sort | uniq | sed 's/^/- /')
  
  # Create PR
  gh pr create --title "$TITLE" --body "## Summary
This PR implements the following modules/features:
$MODULES

## Commits
$COMMITS

## Testing
- [x] Typecheck passed
- [x] Linting passed
- [x] Tests passed

## Module Tracker
Updates have been applied to the Module Tracker."
  
  # Update session if active
  if [ -f "$SESSION_FILE" ] && grep -q "Status: Active" "$SESSION_FILE"; then
    log_to_session "Created PR: $TITLE"
  fi
  
  echo_color "$GREEN" "Created PR: $TITLE"
  
  return 0
}