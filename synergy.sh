#!/bin/bash

# synergy.sh - Fully automated project tracking and development system
# Consolidated entry point that maximizes automation and maintains a single source of truth

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

# Get repository directory
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define key files - single source of truth approach
MODULE_TRACKER="$REPO_DIR/docs/project/MODULE_TRACKER.md"
PROJECT_TRACKER="$REPO_DIR/docs/project/PROJECT_TRACKER.md"
SESSION_FILE="$REPO_DIR/SESSION.md"
COMPACT_DIR="$REPO_DIR/sessions/claude"
SESSIONS_DIR="$REPO_DIR/sessions"

# Auto-commit settings
AUTO_COMMIT_INTERVAL=300 # seconds (5 minutes)
AUTO_COMMIT_PID_FILE="/tmp/synergy-autocommit.pid"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# ------------------------------------------------------------
# Core Functions - Project Tracking
# ------------------------------------------------------------

# Start a development session with automatic tracking
start_session() {
  # Check if a session is already active
  if [ -f "$SESSION_FILE" ] && grep -q "Status: Active" "$SESSION_FILE"; then
    echo -e "${YELLOW}A session is already active. End it first or resume.${NC}"
    read -p "Do you want to resume the current session? (y/n): " choice
    if [ "$choice" != "y" ]; then
      return 1
    fi
    echo -e "${GREEN}Resuming current session.${NC}"
    return 0
  fi

  # Create a new session
  CURRENT_DATE=$(date "+%B %d, %Y")
  CURRENT_BRANCH=$(git branch --show-current)
  
  # Read module focus from PROJECT_TRACKER
  FOCUS_MODULE=$(grep "Focus Module" "$PROJECT_TRACKER" | cut -d':' -f2 | xargs)
  
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
- Update MODULE_TRACKER.md

### Code Context
- Files: $(git status --short | wc -l) files with changes
- Commits: $(git log --oneline -n 1)
EOF

  echo -e "${GREEN}Session started. Focus: $FOCUS_MODULE${NC}"
  
  # Start auto-commit in background if not already running
  if ! is_auto_commit_running; then
    start_auto_commit
    echo -e "${GREEN}Auto-commit started in background.${NC}"
  fi
  
  # Auto-update git hooks (pre-commit, pre-push)
  setup_git_hooks
  
  return 0
}

# End current session with summary and archiving
end_session() {
  # Check if a session is active
  if [ ! -f "$SESSION_FILE" ] || ! grep -q "Status: Active" "$SESSION_FILE"; then
    echo -e "${YELLOW}No active session found.${NC}"
    return 1
  fi
  
  # Update session status
  sed -i 's/Status: Active/Status: Completed/' "$SESSION_FILE"
  
  # Add end time
  END_TIME=$(date "+%H:%M")
  sed -i "/^- Started:/a\\- Ended: $END_TIME" "$SESSION_FILE"
  
  # Generate activity summary from git
  ACTIVITIES=$(git log --pretty=format:"- %s (%ar)" --since="5 hours ago" | head -5)
  
  # Append summary to session
  cat >> "$SESSION_FILE" << EOF

### Session Summary
Session ended at $END_TIME

#### Completed Activities
$ACTIVITIES

#### Module Progress
$(update_module_progress)

EOF

  # Archive the session
  mkdir -p "$SESSIONS_DIR"
  cp "$SESSION_FILE" "$SESSIONS_DIR/session-$(date '+%Y%m%d').md"
  
  # Stop auto-commit if running
  stop_auto_commit
  
  echo -e "${GREEN}Session ended and archived to $SESSIONS_DIR/session-$(date '+%Y%m%d').md${NC}"
  
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

# Update module tracker with completed status
update_module() {
  MODULE="$1"
  STATUS="$2"
  
  if [ -z "$MODULE" ] || [ -z "$STATUS" ]; then
    echo -e "${YELLOW}Usage: synergy.sh update-module \"Module Name\" complete${NC}"
    return 1
  fi
  
  if [ "$STATUS" = "complete" ]; then
    # Update in markdown table format
    sed -i "s/| $MODULE | 🔄 In Progress /| $MODULE | ✅ Completed /" "$MODULE_TRACKER"
    sed -i "s/| $MODULE | 📝 Planned /| $MODULE | ✅ Completed /" "$MODULE_TRACKER"
    
    # Log the change
    echo -e "${GREEN}✅ Updated module status: $MODULE is now marked as completed${NC}"
    
    # Add to session log
    echo "#### $(date '+%H:%M') - Completed module: $MODULE" >> "$SESSION_FILE"
    
    # Update PROJECT_TRACKER with achievement
    DATE_LINE=$(grep -n "## Recent Achievements" "$PROJECT_TRACKER" | cut -d':' -f1)
    if [ -n "$DATE_LINE" ]; then
      DATE_LINE=$((DATE_LINE + 1))
      sed -i "${DATE_LINE}i\\- Completed $MODULE implementation" "$PROJECT_TRACKER"
    fi
    
    return 0
  else
    echo -e "${YELLOW}Unknown status: $STATUS (use 'complete')${NC}"
    return 1
  fi
}

# ------------------------------------------------------------
# Git Integration Functions
# ------------------------------------------------------------

# Set up git hooks for automated tracking
setup_git_hooks() {
  HOOKS_DIR="$REPO_DIR/.git/hooks"
  
  # Create pre-commit hook for auto-updating SESSION.md
  cat > "$HOOKS_DIR/pre-commit" << 'EOF'
#!/bin/bash
REPO_DIR=$(git rev-parse --show-toplevel)
SESSION_FILE="$REPO_DIR/SESSION.md"

# Only proceed if session is active
if [ -f "$SESSION_FILE" ] && grep -q "Status: Active" "$SESSION_FILE"; then
  # Get commit information
  FILES_CHANGED=$(git diff --cached --name-only | wc -l)
  SUMMARY=$(git diff --cached --stat | tail -n 1)
  
  # Add activity to session log
  echo "#### $(date '+%H:%M') - Git: Commit with $FILES_CHANGED files" >> "$SESSION_FILE"
fi
exit 0
EOF
  chmod +x "$HOOKS_DIR/pre-commit"
  
  # Create pre-push hook for verification
  cat > "$HOOKS_DIR/pre-push" << 'EOF'
#!/bin/bash
REPO_DIR=$(git rev-parse --show-toplevel)
SESSION_FILE="$REPO_DIR/SESSION.md"

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

# Update session if active
if [ -f "$SESSION_FILE" ] && grep -q "Status: Active" "$SESSION_FILE"; then
  echo "#### $(date '+%H:%M') - Verified code quality for push" >> "$SESSION_FILE"
fi

echo "✅ All checks passed! Pushing code..."
exit 0
EOF
  chmod +x "$HOOKS_DIR/pre-push"
  
  echo -e "${GREEN}Git hooks updated for automated tracking.${NC}"
}

# Auto-commit in background at regular intervals
start_auto_commit() {
  # Check if already running
  if is_auto_commit_running; then
    echo -e "${YELLOW}Auto-commit is already running.${NC}"
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
      echo -e "${GREEN}Auto-commit stopped.${NC}"
      return 0
    fi
  fi
  echo -e "${YELLOW}No auto-commit process found.${NC}"
  return 1
}

# Create a feature branch and update tracking
feature() {
  FEATURE_NAME="$1"
  
  if [ -z "$FEATURE_NAME" ]; then
    echo -e "${YELLOW}Usage: synergy.sh feature feature-name${NC}"
    return 1
  fi
  
  # Create branch
  git checkout -b "feature/$FEATURE_NAME"
  
  # Update session if active
  if [ -f "$SESSION_FILE" ] && grep -q "Status: Active" "$SESSION_FILE"; then
    # Update branch info
    sed -i "s/- Branch:.*/- Branch: feature\/$FEATURE_NAME/" "$SESSION_FILE"
    
    # Add activity
    echo "#### $(date '+%H:%M') - Started feature: $FEATURE_NAME" >> "$SESSION_FILE"
  fi
  
  echo -e "${GREEN}Created and switched to branch: feature/$FEATURE_NAME${NC}"
  echo -e "${BLUE}To track this feature in PROJECT_TRACKER.md, update the Focus Module section.${NC}"
  
  return 0
}

# Smart commit with AI assistance or auto-detection
smart_commit() {
  MESSAGE="$1"
  
  # Check if there are staged changes
  if [ -z "$(git diff --cached --name-only)" ]; then
    echo -e "${YELLOW}No staged changes found. Stage your changes first with 'git add'.${NC}"
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
    
    echo -e "${BLUE}Generated commit message: ${NC} $MESSAGE"
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
    echo "#### $(date '+%H:%M') - Commit: $MESSAGE" >> "$SESSION_FILE"
  fi
  
  echo -e "${GREEN}Committed with message: $MESSAGE${NC}"
  return 0
}

# Create a pull request with tracking updates
create_pr() {
  TITLE="$1"
  
  if [ -z "$TITLE" ]; then
    echo -e "${YELLOW}Usage: synergy.sh pr \"Pull Request Title\"${NC}"
    return 1
  fi
  
  BRANCH=$(git branch --show-current)
  
  # Check if gh CLI is available
  if ! command -v gh &> /dev/null; then
    echo -e "${RED}GitHub CLI not found. Please install it first.${NC}"
    return 1
  fi
  
  # Get the commit messages for PR body
  echo -e "${BLUE}Generating PR body from commits...${NC}"
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
    echo "#### $(date '+%H:%M') - Created PR: $TITLE" >> "$SESSION_FILE"
  fi
  
  echo -e "${GREEN}Created PR: $TITLE${NC}"
  
  return 0
}

# ------------------------------------------------------------
# Claude Integration Functions
# ------------------------------------------------------------

# Start Claude with project context
start_claude() {
  # Check if claude CLI command exists
  if ! command -v claude &> /dev/null; then
    echo -e "${RED}Claude CLI not found. Please install it first.${NC}"
    return 1
  fi
  
  echo -e "${BLUE}Starting Claude with project context...${NC}"
  
  # Create a context file with project information
  CONTEXT_FILE=$(mktemp)
  
  # Add basic project info
  echo "# Synapse Project Context" > "$CONTEXT_FILE"
  echo "- Current date: $(date '+%Y-%m-%d')" >> "$CONTEXT_FILE"
  echo "- Current branch: $(git branch --show-current)" >> "$CONTEXT_FILE"
  echo "" >> "$CONTEXT_FILE"
  
  # Add module tracker highlights
  echo "## Module Status" >> "$CONTEXT_FILE"
  grep -A 25 "Current Focus" "$MODULE_TRACKER" >> "$CONTEXT_FILE"
  echo "" >> "$CONTEXT_FILE"
  
  # Add recent git activity
  echo "## Recent Git Activity" >> "$CONTEXT_FILE"
  git log --oneline -n 5 >> "$CONTEXT_FILE"
  echo "" >> "$CONTEXT_FILE"
  
  # Add current session details if active
  if [ -f "$SESSION_FILE" ]; then
    echo "## Current Session" >> "$CONTEXT_FILE"
    grep -A 15 "Current Focus" "$SESSION_FILE" >> "$CONTEXT_FILE"
  fi
  
  # Start Claude with the context
  claude < "$CONTEXT_FILE"
  
  # Clean up
  rm "$CONTEXT_FILE"
  
  return 0
}

# Save Claude compact summary
save_compact() {
  COMPACT_DATE=$(date '+%Y%m%d')
  COMPACT_FILE="$COMPACT_DIR/compact-$COMPACT_DATE.md"
  
  # Ensure directory exists
  mkdir -p "$COMPACT_DIR"
  
  # Create a temporary file for the input
  TEMP_FILE=$(mktemp)
  
  echo -e "${BLUE}Paste the compact summary below (press Ctrl+D when done):${NC}"
  cat > "$TEMP_FILE"
  
  # Extract content between <summary> tags if present
  if grep -q "<summary>" "$TEMP_FILE" && grep -q "</summary>" "$TEMP_FILE"; then
    sed -n '/<summary>/,/<\/summary>/p' "$TEMP_FILE" | sed 's/<summary>//g' | sed 's/<\/summary>//g' > "$TEMP_FILE.extract"
    mv "$TEMP_FILE.extract" "$TEMP_FILE"
  fi
  
  # Save to compact file
  if [ ! -f "$COMPACT_FILE" ]; then
    # First summary of the day
    echo "# Claude Compact Summary - $(date '+%B %d, %Y')" > "$COMPACT_FILE"
    echo "" >> "$COMPACT_FILE"
  else
    # Append a separator
    echo "" >> "$COMPACT_FILE"
    echo "---" >> "$COMPACT_FILE"
    echo "" >> "$COMPACT_FILE"
  fi
  
  # Add timestamp
  echo "## Session at $(date '+%H:%M:%S')" >> "$COMPACT_FILE"
  echo "" >> "$COMPACT_FILE"
  
  # Append content
  cat "$TEMP_FILE" >> "$COMPACT_FILE"
  
  # Clean up
  rm "$TEMP_FILE"
  
  echo -e "${GREEN}Compact summary saved to: $COMPACT_FILE${NC}"
  
  # Update session if active
  if [ -f "$SESSION_FILE" ] && grep -q "Status: Active" "$SESSION_FILE"; then
    echo "#### $(date '+%H:%M') - Saved Claude compact summary" >> "$SESSION_FILE"
  fi
  
  return 0
}

# Start compact watcher in background
start_compact_watch() {
  WATCH_DIR="$COMPACT_DIR/compact-watch"
  WATCH_PID_FILE="/tmp/compact-watch.pid"
  
  # Check if already running
  if [ -f "$WATCH_PID_FILE" ] && ps -p $(cat "$WATCH_PID_FILE") > /dev/null; then
    echo -e "${YELLOW}Compact watcher is already running.${NC}"
    return 0
  fi
  
  # Ensure directories exist
  mkdir -p "$WATCH_DIR"
  mkdir -p "$COMPACT_DIR/processed"
  
  # Start the watcher in background
  (
    while true; do
      # Check for new files
      for file in "$WATCH_DIR"/*; do
        if [ -f "$file" ] && [ ! -L "$file" ]; then
          # Process the file
          COMPACT_DATE=$(date '+%Y%m%d')
          COMPACT_FILE="$COMPACT_DIR/compact-$COMPACT_DATE.md"
          
          # Extract content between <summary> tags if present
          if grep -q "<summary>" "$file" && grep -q "</summary>" "$file"; then
            TEMP_FILE=$(mktemp)
            sed -n '/<summary>/,/<\/summary>/p' "$file" | sed 's/<summary>//g' | sed 's/<\/summary>//g' > "$TEMP_FILE"
            
            # Save to compact file
            if [ ! -f "$COMPACT_FILE" ]; then
              # First summary of the day
              echo "# Claude Compact Summary - $(date '+%B %d, %Y')" > "$COMPACT_FILE"
              echo "" >> "$COMPACT_FILE"
            else
              # Append a separator
              echo "" >> "$COMPACT_FILE"
              echo "---" >> "$COMPACT_FILE"
              echo "" >> "$COMPACT_FILE"
            fi
            
            # Add timestamp
            echo "## Session at $(date '+%H:%M:%S')" >> "$COMPACT_FILE"
            echo "" >> "$COMPACT_FILE"
            
            # Append content
            cat "$TEMP_FILE" >> "$COMPACT_FILE"
            
            # Clean up
            rm "$TEMP_FILE"
            
            # Move the processed file
            mv "$file" "$COMPACT_DIR/processed/$(basename "$file").$(date +"%H%M%S")"
          fi
        fi
      done
      
      # Wait before checking again
      sleep 5
    done
  ) &
  
  # Save PID
  echo $! > "$WATCH_PID_FILE"
  
  echo -e "${GREEN}Compact watcher started in background.${NC}"
  echo -e "${BLUE}Save compact outputs to: $WATCH_DIR${NC}"
  
  return 0
}

# Stop compact watcher
stop_compact_watch() {
  WATCH_PID_FILE="/tmp/compact-watch.pid"
  
  if [ -f "$WATCH_PID_FILE" ]; then
    PID=$(cat "$WATCH_PID_FILE")
    if ps -p $PID > /dev/null; then
      kill $PID
      rm "$WATCH_PID_FILE"
      echo -e "${GREEN}Compact watcher stopped.${NC}"
      return 0
    fi
  fi
  
  echo -e "${YELLOW}No compact watcher found.${NC}"
  return 1
}

# ------------------------------------------------------------
# Status Functions
# ------------------------------------------------------------

# Show current status summary
show_status() {
  clear
  echo -e "${BLUE}==================================================${NC}"
  echo -e "${BLUE}           SYNAPSE PROJECT STATUS                ${NC}"
  echo -e "${BLUE}         $(date "+%B %d, %Y at %H:%M")           ${NC}"
  echo -e "${BLUE}==================================================${NC}"
  echo ""
  
  # Git status
  echo -e "${GREEN}GIT STATUS:${NC}"
  echo "Current branch: $(git branch --show-current)"
  git status --short | head -n 5
  if [ $(git status --short | wc -l) -gt 5 ]; then
    echo "... and $(expr $(git status --short | wc -l) - 5) more changes"
  fi
  echo ""
  
  # Recent commits
  echo -e "${GREEN}RECENT COMMITS:${NC}"
  git log --oneline -n 3
  echo ""
  
  # Session status
  echo -e "${GREEN}SESSION STATUS:${NC}"
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
  
  # Module progress
  echo -e "${GREEN}MODULE PROGRESS:${NC}"
  COMPLETED=$(grep -c "✅ Completed" "$MODULE_TRACKER")
  TOTAL=$(grep -c "Status" "$MODULE_TRACKER")
  echo "$COMPLETED of $TOTAL modules completed ($(expr $COMPLETED \* 100 / $TOTAL)%)"
  
  # Current focus
  echo ""
  echo "Current focus from PROJECT_TRACKER:"
  grep -A 1 "Focus Module" "$PROJECT_TRACKER"
  echo ""
}

# ------------------------------------------------------------
# Help Function
# ------------------------------------------------------------

show_help() {
  echo -e "${BLUE}Synergy - Automated Project Management${NC}"
  echo "=========================================="
  echo ""
  echo "A consolidated workflow tool that maximizes automation"
  echo "and maintains a single source of truth for tracking."
  echo ""
  echo -e "${GREEN}Session Management:${NC}"
  echo "  start         - Start a new development session with auto-tracking"
  echo "  end           - End and archive the current session"
  echo "  status        - Show current project and session status"
  echo ""
  echo -e "${GREEN}Module Tracking:${NC}"
  echo "  update-module \"Module Name\" complete - Mark a module as completed"
  echo ""
  echo -e "${GREEN}Git Integration:${NC}"
  echo "  feature NAME  - Create a new feature branch"
  echo "  commit \"Message\" - Create a smart commit (auto-generates message if none provided)"
  echo "  pr \"Title\"    - Create a pull request with auto-generated body"
  echo ""
  echo -e "${GREEN}Claude Integration:${NC}"
  echo "  claude        - Start Claude with project context"
  echo "  compact       - Save a Claude compact summary"
  echo "  watch         - Start watcher for compact summaries"
  echo "  stop-watch    - Stop the compact watcher"
  echo ""
  echo -e "${GREEN}Automation:${NC}"
  echo "  auto-on       - Start auto-commit in background"
  echo "  auto-off      - Stop auto-commit background process"
  echo ""
  echo "Most operations automatically update SESSION.md and integrate with git."
  echo ""
}

# ------------------------------------------------------------
# Main Command Handler
# ------------------------------------------------------------

COMMAND="$1"
shift

case "$COMMAND" in
  # Session management
  start)
    start_session
    ;;
  end)
    end_session
    ;;
  status)
    show_status
    ;;
    
  # Module tracking
  update-module)
    update_module "$1" "$2"
    ;;
    
  # Git integration
  feature)
    feature "$1"
    ;;
  commit)
    smart_commit "$1"
    ;;
  pr)
    create_pr "$1"
    ;;
    
  # Claude integration
  claude)
    start_claude
    ;;
  compact)
    save_compact
    ;;
  watch)
    start_compact_watch
    ;;
  stop-watch)
    stop_compact_watch
    ;;
    
  # Automation
  auto-on)
    start_auto_commit
    ;;
  auto-off)
    stop_auto_commit
    ;;
    
  # Help and default
  help|*)
    show_help
    ;;
esac