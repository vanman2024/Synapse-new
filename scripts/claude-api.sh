#!/bin/bash

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLAUDE_LOG_DIR="$REPO_ROOT/logs/claude"
mkdir -p "$CLAUDE_LOG_DIR"

# ---- Claude API Integration ----

# Ask Claude about code
ask_claude() {
    if [ -z "$1" ]; then
        echo "Usage: ask_claude <question>"
        echo "Example: ask_claude \"How should I structure the authentication system?\""
        return 1
    fi
    
    question="$@"
    timestamp=$(date +"%Y%m%d_%H%M%S")
    log_file="$CLAUDE_LOG_DIR/question_$timestamp.md"
    
    echo "Asking Claude: $question"
    echo "# Question: $question" > "$log_file"
    echo "" >> "$log_file"
    echo "## Context" >> "$log_file"
    echo "\`\`\`" >> "$log_file"
    git branch --show-current >> "$log_file"
    git status --short >> "$log_file"
    echo "\`\`\`" >> "$log_file"
    echo "" >> "$log_file"
    
    # Use Claude CLI to get an answer
    echo "## Claude's Answer" >> "$log_file"
    claude --print "$question" >> "$log_file"
    
    echo "Response saved to: $log_file"
    echo "Opening response..."
    # Try to open with VSCode or default editor
    if command -v code &> /dev/null; then
        code "$log_file"
    else
        # Try to use the default system editor
        ${EDITOR:-vi} "$log_file"
    fi
}

# Review code with Claude
review_code() {
    if [ -z "$1" ]; then
        echo "Usage: review_code <file_path>"
        echo "Example: review_code src/auth/login.ts"
        return 1
    fi
    
    file_path="$1"
    
    if [ ! -f "$file_path" ]; then
        echo "File not found: $file_path"
        return 1
    fi
    
    timestamp=$(date +"%Y%m%d_%H%M%S")
    log_file="$CLAUDE_LOG_DIR/review_$timestamp.md"
    
    echo "Asking Claude to review: $file_path"
    echo "# Code Review: $file_path" > "$log_file"
    echo "" >> "$log_file"
    echo "## File Content" >> "$log_file"
    echo "\`\`\`" >> "$log_file"
    cat "$file_path" >> "$log_file"
    echo "\`\`\`" >> "$log_file"
    echo "" >> "$log_file"
    
    # Use Claude CLI to get a review
    echo "## Claude's Review" >> "$log_file"
    claude --print "Please review this code for any issues, improvements, or best practices: $(cat "$file_path")" >> "$log_file"
    
    echo "Review saved to: $log_file"
    echo "Opening review..."
    if command -v code &> /dev/null; then
        code "$log_file"
    else
        ${EDITOR:-vi} "$log_file"
    fi
}

# Generate a commit message with Claude
smart_commit() {
    # Check if there are staged changes
    if [ -z "$(git diff --cached --name-only)" ]; then
        echo "No staged changes found. Stage your changes first with 'git add'."
        return 1
    fi
    
    echo "Generating commit message with Claude..."
    
    # Get the diff of staged changes
    diff_output=$(git diff --cached)
    
    # Ask Claude for a commit message
    commit_msg=$(claude --print "Generate a concise and descriptive commit message for these changes. Use the conventional commit format (type: description). Here's the diff: $diff_output")
    
    # Propose the commit message to the user
    echo "Claude suggests this commit message:"
    echo "-----------------------------------"
    echo "$commit_msg"
    echo "-----------------------------------"
    
    # Ask for confirmation
    read -p "Use this message? (y/n/e to edit): " choice
    
    case "$choice" in
        y|Y )
            git commit -m "$commit_msg"
            echo "✅ Committed with Claude's message"
            ;;
        e|E )
            # Create a temporary file with the message
            temp_file=$(mktemp)
            echo "$commit_msg" > "$temp_file"
            
            # Open in editor
            ${EDITOR:-vi} "$temp_file"
            
            # Read the edited message
            edited_msg=$(cat "$temp_file")
            rm "$temp_file"
            
            git commit -m "$edited_msg"
            echo "✅ Committed with edited message"
            ;;
        * )
            echo "Commit canceled. You can create your own commit message."
            ;;
    esac
}

# Review changes before creating a PR
review_changes() {
    branch=$(git branch --show-current)
    base="master"
    
    echo "Reviewing changes in $branch compared to $base..."
    
    # Get the diff
    diff_output=$(git diff "$base..$branch")
    
    # If there's no diff, try to find commits
    if [ -z "$diff_output" ]; then
        echo "No code differences found. Looking at commits..."
        diff_output=$(git log --pretty=format:"%h %s" "$base..$branch")
        
        if [ -z "$diff_output" ]; then
            echo "No changes or commits found to review."
            return 1
        fi
    fi
    
    timestamp=$(date +"%Y%m%d_%H%M%S")
    log_file="$CLAUDE_LOG_DIR/pr_review_$timestamp.md"
    
    echo "# PR Review: $branch" > "$log_file"
    echo "" >> "$log_file"
    echo "## Changes" >> "$log_file"
    echo "\`\`\`" >> "$log_file"
    echo "$diff_output" >> "$log_file"
    echo "\`\`\`" >> "$log_file"
    echo "" >> "$log_file"
    
    # Use Claude CLI to get a review
    echo "## Claude's Analysis" >> "$log_file"
    claude --print "Please review these changes and provide a summary of what was changed, any potential issues, and suggest a good PR title and description: $diff_output" >> "$log_file"
    
    echo "PR review saved to: $log_file"
    echo "Opening review..."
    if command -v code &> /dev/null; then
        code "$log_file"
    else
        ${EDITOR:-vi} "$log_file"
    fi
}

# Export functions
export -f ask_claude
export -f review_code
export -f smart_commit
export -f review_changes