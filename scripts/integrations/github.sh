#!/bin/bash

# github.sh - GitHub integration functions for synergy.sh
# (Legacy support, main tracking is now in Airtable)

# Import config
source "$(dirname "${BASH_SOURCE[0]}")/../core/config.sh"

# Get GitHub Projects configuration details
get_github_projects_config() {
  # Check if gh CLI is available
  if ! command_exists gh; then
    echo_color "$RED" "GitHub CLI not found. Install it first to configure GitHub Projects."
    echo "See: https://github.com/cli/cli#installation"
    return 1
  fi
  
  # Check if jq is available (required for JSON parsing)
  if ! command_exists jq; then
    echo_color "$RED" "jq command not found. Install it first to configure GitHub Projects."
    echo "See: https://stedolan.github.io/jq/download/"
    echo "Install with: sudo apt-get install jq (Debian/Ubuntu)"
    echo "or: brew install jq (macOS with Homebrew)"
    return 1
  fi
  
  echo_color "$BLUE" "Fetching GitHub Projects configuration information..."
  
  # Ensure user is authenticated with GitHub
  if ! gh auth status &> /dev/null; then
    echo_color "$YELLOW" "You need to authenticate with GitHub first."
    echo "Run: gh auth login"
    return 1
  fi
  
  # Get repository information
  REPO_INFO=$(gh repo view --json owner,name)
  OWNER=$(echo "$REPO_INFO" | jq -r '.owner.login')
  REPO_NAME=$(echo "$REPO_INFO" | jq -r '.name')
  
  echo "GitHub Organization/User: $OWNER"
  echo "Repository Name: $REPO_NAME"
  
  # List available projects
  echo -e "\n${BLUE}Available Projects:${NC}"
  gh api graphql -f query='query { organization(login: "'$OWNER'") { projectsV2(first: 10) { nodes { id number title } } } }' | \
    jq -r '.data.organization.projectsV2.nodes[] | "Project #\(.number): \(.title) (ID: \(.id))"'
  
  # Prompt user for project number
  read -p "Enter the project number you want to use: " PROJECT_NUMBER
  
  # Get project field information
  echo -e "\n${BLUE}Fetching fields for Project #$PROJECT_NUMBER...${NC}"
  gh api graphql -f query='query { organization(login: "'$OWNER'") { projectV2(number: '$PROJECT_NUMBER') { fields(first: 20) { nodes { ... on ProjectV2FieldCommon { id name } ... on ProjectV2SingleSelectField { id name options { id name } } } } } } }' | \
    jq -r '.data.organization.projectV2.fields.nodes[] | "Field: \(.name) (ID: \(.id))"'
  
  # For single select fields, show options
  echo -e "\n${BLUE}For Status fields, here are the available options:${NC}"
  gh api graphql -f query='query { organization(login: "'$OWNER'") { projectV2(number: '$PROJECT_NUMBER') { fields(first: 20) { nodes { ... on ProjectV2SingleSelectField { id name options { id name } } } } } } }' | \
    jq -r '.data.organization.projectV2.fields.nodes[] | select(.options != null) | "Field: \(.name) (ID: \(.id))\n  Options: \(.options[] | "    \(.name) (ID: \(.id))")"'
  
  echo -e "\n${GREEN}Use this information to update the GitHub Projects configuration in synergy.sh${NC}"
  echo "Example:"
  echo "GITHUB_ORG=\"$OWNER\""
  echo "GITHUB_REPO=\"$REPO_NAME\""
  echo "GITHUB_PROJECT_NUMBER=$PROJECT_NUMBER"
  echo "GITHUB_STATUS_FIELD_ID=\"[Field ID from above]\"  # Replace with actual ID"
  
  return 0
}

# Update module in GitHub Projects (LEGACY - NOT USED WITH AIRTABLE INTEGRATION)
update_module_github() {
  MODULE="$1"
  STATUS="$2"
  
  # Check if GitHub CLI is installed
  if command_exists gh; then
    echo_color "$BLUE" "GitHub CLI is installed. Would use it for GitHub Projects integration if configured."
    
    # For now, we'll just simulate the update with an explanatory message
    if [ "$STATUS" = "complete" ]; then
      echo_color "$GREEN" "Simulating: Would move '$MODULE' to 'Done' column in GitHub Projects"
    elif [ "$STATUS" = "in-progress" ]; then
      echo_color "$GREEN" "Simulating: Would move '$MODULE' to 'In Progress' column in GitHub Projects"
    elif [ "$STATUS" = "planned" ]; then
      echo_color "$GREEN" "Simulating: Would move '$MODULE' to 'To Do' column in GitHub Projects"
    fi
    
    # Log the change for local tracking only
    echo_color "$GREEN" "✅ Local tracking updated: $MODULE is now marked as $STATUS"
    echo_color "$YELLOW" "GitHub Projects integration is disabled for now."
  else
    echo_color "$YELLOW" "GitHub CLI not installed. Update only applied locally."
    echo "See: https://github.com/cli/cli#installation"
  fi
  
  return 0
}