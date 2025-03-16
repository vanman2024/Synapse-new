#!/bin/bash

# config.sh - Central configuration for synergy.sh
# All modules import this file to ensure consistent configuration

# Get repository directory (adjusts for being in scripts/core/ subdirectory)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../../ && pwd)"

# Define key files - single source of truth approach
OVERVIEW_FILE="$REPO_DIR/docs/project/DEVELOPMENT_OVERVIEW.md"
SESSION_FILE="$REPO_DIR/SESSION.md"
COMPACT_DIR="$REPO_DIR/sessions/claude"
SESSIONS_DIR="$REPO_DIR/sessions"

# Auto-commit settings
AUTO_COMMIT_INTERVAL=300 # seconds (5 minutes)
AUTO_COMMIT_PID_FILE="/tmp/synergy-autocommit.pid"

# Airtable integration
AIRTABLE_SCRIPT="$REPO_DIR/tools/dev-tracker/synergy-airtable.sh"

# GitHub Projects configuration (legacy, maintained for backward compatibility)
GITHUB_ORG="vanman2024"          # Organization or username
GITHUB_REPO="Synapse-new"        # Repository name
GITHUB_PROJECT_NUMBER="1"        # Project number from URL (e.g., 4 from /projects/4)
GITHUB_STATUS_FIELD_ID="PVTF_lADOAHg8xMDTjMgzs0OU"  # Status field ID from GitHub API (placeholder)

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Ensure critical directories exist
mkdir -p "$SESSIONS_DIR"
mkdir -p "$COMPACT_DIR"
mkdir -p "$COMPACT_DIR/processed"
mkdir -p "$COMPACT_DIR/compact-watch"
mkdir -p "$COMPACT_DIR/debug"
mkdir -p "$COMPACT_DIR/archives"

# Helper functions for common operations

# Extract a field from a file (e.g., extract_field "Focus" "$SESSION_FILE")
extract_field() {
  grep "$1:" "$2" | cut -d':' -f2- | xargs
}

# Update a field in the session file (e.g., update_session_field "Status" "Completed")
update_session_field() {
  sed -i "s/- $1:.*$/- $1: $2/" "$SESSION_FILE"
}

# Check if a command exists and is executable
command_exists() {
  command -v "$1" &> /dev/null
}

# Echo with color (e.g., echo_color "$GREEN" "Success message")
echo_color() {
  echo -e "${1}${2}${NC}"
}

# Log output to session file with timestamp
log_to_session() {
  echo "#### $(date '+%H:%M') - $1" >> "$SESSION_FILE"
}