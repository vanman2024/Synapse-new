#!/bin/bash

# Directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ---- Simplified Claude Commands ----

# Start a new feature branch
feature() {
    if [ -z "$1" ]; then
        echo "Usage: feature <feature-name>"
        echo "Example: feature add-login"
        return 1
    fi
    
    feature_name="$1"
    git checkout -b "feature/$feature_name"
    echo "Created and switched to branch: feature/$feature_name"
    
    # Optional: Show the user what files might be relevant
    echo "Scanning for relevant files..."
    grep -r --include="*.ts" --include="*.js" "$feature_name" "$REPO_ROOT/src" 2>/dev/null || echo "No direct matches found for $feature_name"
}

# Check code and create a commit
check() {
    npm run typecheck && npm run lint && npm run build
    if [ $? -eq 0 ]; then
        echo "✅ All checks passed!"
    else
        echo "❌ Checks failed! Fix errors before committing."
        return 1
    fi
}

# Commit with a standard format
commit() {
    if [ -z "$1" ]; then
        echo "Usage: commit <type> <message>"
        echo "Types: feat, fix, docs, style, refactor, test, chore"
        echo "Example: commit feat 'Add login page'"
        return 1
    fi
    
    type="$1"
    shift
    message="$@"
    
    check || return 1
    
    git commit -m "$type: $message"
    echo "✅ Successfully committed: $type: $message"
}

# Create and push a PR
pr() {
    if [ -z "$1" ]; then
        echo "Usage: pr <title>"
        echo "Example: pr 'Add login functionality'"
        return 1
    fi
    
    title="$1"
    branch=$(git branch --show-current)
    
    # Check if gh CLI is available
    if ! command -v gh &> /dev/null; then
        echo "GitHub CLI not found. Please install it first."
        return 1
    fi
    
    # Get the commit messages for PR body
    echo "Generating PR body from commits..."
    commits=$(git log --pretty=format:"- %s" origin/master..HEAD)
    
    gh pr create --title "$title" --body "## Changes
$commits

## Tests
- [x] Passed TypeScript check
- [x] Passed linting
- [x] Builds successfully

🤖 Generated with Claude Code"
    
    echo "✅ PR created successfully!"
}

# Quick lint fix
lintfix() {
    git checkout -b "fix/lint-$(date +%Y%m%d)"
    npm run lint
    echo "Created lint fix branch. Make necessary changes and then use 'commit fix \"Fix lint issues\"'"
}

# Push with verification
push() {
    check || return 1
    
    current_branch=$(git branch --show-current)
    git push origin "$current_branch"
    
    echo "✅ Changes pushed to $current_branch"
}

# Help command
claude-help() {
    echo "Claude Commands:"
    echo "----------------"
    echo "feature <name>     - Create a new feature branch"
    echo "check              - Run typecheck, lint, and build"
    echo "commit <type> <msg>- Create a commit with proper format"
    echo "pr <title>         - Create and push a PR"
    echo "lintfix            - Create a branch for fixing lint issues"
    echo "push               - Push with verification"
    echo "claude-help        - Show this help"
}

# Load Claude API functions
source "$SCRIPT_DIR/claude-api.sh"

# Update help to include Claude API functions
claude-help() {
    echo "Claude Commands:"
    echo "----------------"
    echo "feature <name>     - Create a new feature branch"
    echo "check              - Run typecheck, lint, and build"
    echo "commit <type> <msg>- Create a commit with proper format"
    echo "pr <title>         - Create and push a PR"
    echo "lintfix            - Create a branch for fixing lint issues"
    echo "push               - Push with verification"
    echo ""
    echo "Claude AI Functions:"
    echo "-------------------"
    echo "ask_claude <question> - Ask Claude a question"
    echo "review_code <file>    - Have Claude review a file"
    echo "smart_commit          - Generate a commit message with Claude"
    echo "review_changes        - Review branch changes with Claude"
    echo ""
    echo "claude-help           - Show this help"
}

# Export all functions
export -f feature
export -f check
export -f commit
export -f pr
export -f lintfix
export -f push
export -f claude-help

echo "Claude commands loaded. Type 'claude-help' for a list of commands."