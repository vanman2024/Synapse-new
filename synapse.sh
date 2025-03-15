#!/bin/bash

# synapse.sh - Main command dispatcher for all Synapse operations
# This script serves as the single entry point for all project workflows

# Get script directory (repo root)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$REPO_DIR/scripts"
WORKFLOW_DIR="$REPO_DIR/scripts/workflow"

# Set up command categories
CLAUDE_SCRIPTS="$WORKFLOW_DIR/claude"
DEV_SCRIPTS="$WORKFLOW_DIR/development"
GIT_SCRIPTS="$WORKFLOW_DIR/git"
TEST_SCRIPTS="$WORKFLOW_DIR/testing"

# Print usage information
usage() {
  echo "Synapse Project Command System"
  echo "=============================="
  echo ""
  echo "Usage: ./synapse.sh [category] [command] [options]"
  echo ""
  echo "Categories:"
  echo "  claude     - Claude AI session management"
  echo "  session    - Development session tracking"
  echo "  git        - Git and version control workflows"
  echo "  test       - Testing and verification"
  echo "  project    - Project documentation and status"
  echo ""
  echo "Common Commands:"
  echo "  ./synapse.sh claude start     - Start a Claude session with context"
  echo "  ./synapse.sh claude compact   - Save a Claude compact summary"
  echo "  ./synapse.sh claude watch     - Watch for compact summaries"
  echo "  ./synapse.sh claude ask \"...\" - Ask Claude a question"
  echo "  ./synapse.sh session start    - Start development session"
  echo "  ./synapse.sh session end      - End development session"
  echo "  ./synapse.sh git commit       - Smart commit with AI assistance"
  echo "  ./synapse.sh project status   - View project status"
  echo ""
  echo "Run './synapse.sh help [category]' for category-specific help"
}

# Load the original Claude commands to make them available
load_claude_commands() {
  source "$SCRIPTS_DIR/claude-commands.sh" &>/dev/null
  source "$SCRIPTS_DIR/claude-api.sh" &>/dev/null
}

# Command handlers
handle_claude() {
  command="$1"
  shift
  
  case "$command" in
    start)
      "$REPO_DIR/start-claude-session.sh" "$@"
      ;;
    compact)
      "$SCRIPTS_DIR/save-session.sh" "$@"
      ;;
    watch)
      "$REPO_DIR/start-compact-watch.sh" "$@"
      ;;
    ask)
      load_claude_commands
      ask_claude "$@"
      ;;
    review)
      load_claude_commands
      review_code "$@"
      ;;
    changes)
      load_claude_commands
      review_changes "$@"
      ;;
    help|*)
      echo "Claude AI Commands:"
      echo "  start           - Start a Claude session with project context"
      echo "  compact         - Save a Claude compact summary manually"
      echo "  watch           - Start the automated compact watcher"
      echo "  ask \"question\"  - Ask Claude a question about the codebase"
      echo "  review FILE     - Have Claude review a specific file"
      echo "  changes         - Review current branch changes with Claude"
      ;;
  esac
}

handle_session() {
  command="$1"
  shift
  
  case "$command" in
    start)
      "$DEV_SCRIPTS/start-session.sh" "$@"
      ;;
    end)
      "$DEV_SCRIPTS/session-end.sh" "$@"
      ;;
    log)
      "$DEV_SCRIPTS/session-manager.sh" log "$@"
      ;;
    list)
      "$DEV_SCRIPTS/session-manager.sh" list
      ;;
    current)
      "$DEV_SCRIPTS/session-manager.sh" current
      ;;
    summary)
      "$DEV_SCRIPTS/session-summary.sh" "$@"
      ;;
    help|*)
      echo "Development Session Commands:"
      echo "  start   - Start a new development session"
      echo "  end     - End the current development session"
      echo "  log     - Log activity to the current session"
      echo "  list    - List all development sessions"
      echo "  current - Show current session info"
      echo "  summary - Generate summary for current session"
      ;;
  esac
}

handle_git() {
  command="$1"
  shift
  
  case "$command" in
    feature)
      load_claude_commands
      feature "$@"
      ;;
    commit)
      load_claude_commands
      smart_commit "$@"
      ;;
    check)
      load_claude_commands
      check "$@"
      ;;
    pr)
      load_claude_commands
      pr "$@"
      ;;
    push)
      load_claude_commands
      push "$@"
      ;;
    help|*)
      echo "Git Workflow Commands:"
      echo "  feature NAME - Create a new feature branch"
      echo "  commit       - Create a smart commit with AI assistance"
      echo "  check        - Run type checking and linting"
      echo "  pr TITLE     - Create a pull request"
      echo "  push         - Push with verification"
      ;;
  esac
}

handle_test() {
  command="$1"
  shift
  
  case "$command" in
    run)
      "$TEST_SCRIPTS/test-cycle.sh" "$@"
      ;;
    check)
      "$TEST_SCRIPTS/ts-check.sh" "$@"
      ;;
    help|*)
      echo "Testing Commands:"
      echo "  run     - Run the test suite"
      echo "  check   - Run TypeScript type checking"
      ;;
  esac
}

handle_project() {
  command="$1"
  shift
  
  case "$command" in
    status)
      "$REPO_DIR/view-project-status.sh" "$@"
      ;;
    update)
      echo "Updating project documentation..."
      # Future functionality
      ;;
    help|*)
      echo "Project Management Commands:"
      echo "  status  - View current project status"
      echo "  update  - Update project documentation (future)"
      ;;
  esac
}

# Main command dispatcher
if [ $# -eq 0 ]; then
  usage
  exit 0
fi

category="$1"
shift

case "$category" in
  claude)
    handle_claude "$@"
    ;;
  session)
    handle_session "$@"
    ;;
  git)
    handle_git "$@"
    ;;
  test)
    handle_test "$@"
    ;;
  project)
    handle_project "$@"
    ;;
  help)
    if [ $# -eq 0 ]; then
      usage
    else
      handle_"$1" help
    fi
    ;;
  *)
    echo "Unknown category: $category"
    usage
    exit 1
    ;;
esac