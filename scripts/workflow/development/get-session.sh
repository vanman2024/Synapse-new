#!/bin/bash

# get-session.sh - Get information about a session
# Usage: ./get-session.sh [session_id]
# If no session_id is provided, it will return the current session

WORKFLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$WORKFLOW_DIR/../.." && pwd)"

# Change to repo directory
cd "$REPO_DIR"

if [ -z "$1" ]; then
  # No session ID provided, get the current session
  "$WORKFLOW_DIR/session-manager.sh" current
else
  # Get specific session by ID
  "$WORKFLOW_DIR/session-manager.sh" get "$1"
fi