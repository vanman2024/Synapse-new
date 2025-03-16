#!/bin/bash

# synergy.sh - Fully automated project tracking and development system
# Consolidated entry point that maximizes automation and maintains a single source of truth

# This is the refactored version that uses a modular architecture for better maintainability
# Primary tracking is now done via Airtable integration
# GitHub Projects integration code is retained but not actively used

# ------------------------------------------------------------
# Import Modules
# ------------------------------------------------------------

# Import config first (this sets up environment variables and helper functions)
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")/scripts"
source "$SCRIPT_DIR/core/config.sh"

# Other modules are imported as needed during execution to reduce startup time

# ------------------------------------------------------------
# Help Function
# ------------------------------------------------------------

show_help() {
  echo -e "${BLUE}Synapse - Automated Project Management${NC}"
  echo "=========================================="
  echo ""
  echo "A consolidated workflow tool that maximizes automation"
  echo "and maintains a single source of truth for tracking."
  echo ""
  echo -e "${GREEN}Session Management:${NC}"
  echo "  start         - Start a new development session with auto-tracking"
  echo "  end           - End and archive the current session"
  echo "  status        - Show current project and session status"
  echo "  cleanup       - Consolidate today's session files into a single daily file"
  echo ""
  echo -e "${GREEN}Module Tracking:${NC}"
  echo "  update-module \"Module Name\" complete    - Mark a module as completed"
  echo "  update-module \"Module Name\" in-progress - Mark a module as in progress"
  echo "  update-module \"Module Name\" planned     - Reset a module to planned status"
  echo ""
  echo -e "${GREEN}Documentation Management:${NC}"
  echo "  * Documentation is automatically updated when using update-module"
  echo "  * Development Overview document is the single source of truth"
  echo "  * Modules are properly marked as completed with [x] in the overview"
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
  echo -e "${GREEN}Project Tracking:${NC}"
  echo "  github-config - Configure GitHub Projects integration (legacy)"
  echo "  airtable-setup - Set up Airtable for development tracking"
  echo "                  (Creates tables and populates with data from DEVELOPMENT_OVERVIEW.md)"
  echo "  airtable-maintain - Improve session descriptions and module links in Airtable"
  echo "                  (Runs maintenance on recent sessions to ensure proper linking)"
  echo ""
  echo "Most operations automatically update SESSION.md and integrate with git."
  echo "Documentation is kept in sync with development progress automatically."
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
    source "$SCRIPT_DIR/core/session.sh"
    start_session
    ;;
  end)
    source "$SCRIPT_DIR/core/session.sh"
    end_session
    ;;
  status)
    source "$SCRIPT_DIR/core/session.sh"
    show_status
    ;;
  cleanup)
    source "$SCRIPT_DIR/core/session.sh"
    cleanup_sessions
    ;;
    
  # Module tracking
  update-module)
    source "$SCRIPT_DIR/core/module.sh"
    update_module "$1" "$2"
    ;;
    
  # Git integration
  feature)
    source "$SCRIPT_DIR/core/module.sh"
    feature "$1"
    ;;
  commit)
    source "$SCRIPT_DIR/core/module.sh"
    smart_commit "$1"
    ;;
  pr)
    source "$SCRIPT_DIR/core/git-hooks.sh"
    create_pr "$1"
    ;;
    
  # Claude integration
  claude)
    source "$SCRIPT_DIR/integrations/claude.sh"
    start_claude
    ;;
  compact)
    source "$SCRIPT_DIR/integrations/claude.sh"
    save_compact
    ;;
  watch)
    source "$SCRIPT_DIR/integrations/claude.sh"
    start_compact_watch
    ;;
  stop-watch)
    source "$SCRIPT_DIR/integrations/claude.sh"
    stop_compact_watch
    ;;
    
  # Automation
  auto-on)
    source "$SCRIPT_DIR/core/git-hooks.sh"
    start_auto_commit
    ;;
  auto-off)
    source "$SCRIPT_DIR/core/git-hooks.sh"
    stop_auto_commit
    ;;
    
  # GitHub Projects configuration (legacy)
  github-config)
    source "$SCRIPT_DIR/integrations/github.sh"
    get_github_projects_config
    ;;
    
  # Airtable setup and maintenance
  airtable-setup)
    source "$SCRIPT_DIR/integrations/airtable.sh"
    setup_airtable
    ;;
  
  airtable-maintain)
    # Run maintenance script to link sessions to modules
    "$REPO_DIR/tools/dev-tracker/synergy-airtable.sh" maintain-sessions
    ;;
    
  # Help and default
  help|*)
    show_help
    ;;
esac