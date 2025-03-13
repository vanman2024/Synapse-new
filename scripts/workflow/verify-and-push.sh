#!/bin/bash

# verify-and-push.sh - Verify code and push to GitHub only when all tests pass
# Usage: ./scripts/workflow/verify-and-push.sh [component]

# Get the workflow directory
WORKFLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get the repository root directory
REPO_DIR="$(cd "$WORKFLOW_DIR/../.." && pwd)"
SESSION_FILE="$REPO_DIR/SESSION.md"
COMPONENT=${1:-"all"}  # Default to "all" if not specified

# Function to run tests
run_verification() {
  local component=$1
  local success=true
  
  echo "=========================================="
  echo "    VERIFICATION: $component"
  echo "=========================================="
  
  # Run tests
  echo "Running tests..."
  if [ "$component" == "all" ]; then
    npm test
  else
    npm test -- --testPathPattern=$component
  fi
  
  if [ $? -ne 0 ]; then
    echo "❌ Tests failed!"
    success=false
  else
    echo "✅ Tests passed!"
  fi
  
  # Run linting
  echo "Running linting..."
  npm run lint
  
  if [ $? -ne 0 ]; then
    echo "❌ Linting failed!"
    success=false
  else
    echo "✅ Linting passed!"
  fi
  
  # Run type checking
  echo "Running type checking..."
  npm run typecheck
  
  if [ $? -ne 0 ]; then
    echo "❌ Type checking failed!"
    success=false
  else
    echo "✅ Type checking passed!"
  fi
  
  # Return overall success
  if [ "$success" = true ]; then
    return 0
  else
    return 1
  fi
}

# Function to push to GitHub
push_to_github() {
  echo "Pushing changes to GitHub..."
  git push origin $(git branch --show-current)
  
  if [ $? -eq 0 ]; then
    echo "✅ Successfully pushed to GitHub!"
    
    # Update SESSION.md with push info
    local timestamp=$(date +"%H:%M")
    local branch=$(git branch --show-current)
    local push_info="🚀 **$timestamp** - Verified code pushed to GitHub on branch $branch"
    
    # Insert after Last Activity section
    sed -i "/#### Last Activity/a $push_info" "$SESSION_FILE"
    git add "$SESSION_FILE"
    git commit -m "Update SESSION.md with push information"
    
    # Push this commit too
    git push origin $(git branch --show-current)
    
    return 0
  else
    echo "❌ Failed to push to GitHub. Please check your git configuration."
    return 1
  fi
}

# Main function
main() {
  # Check if there are any commits to push
  local unpushed_commits=$(git log --branches --not --remotes --oneline | wc -l)
  
  if [ "$unpushed_commits" -eq 0 ]; then
    echo "No unpushed commits. Everything is already up-to-date with GitHub."
    return 0
  fi
  
  echo "Found $unpushed_commits local commits that haven't been pushed to GitHub."
  
  # Ask for confirmation
  read -p "Run verification before pushing? (Y/n) " response
  if [[ "$response" =~ ^[Nn]$ ]]; then
    echo "Skipping verification..."
  else
    # Run verification
    run_verification "$COMPONENT"
    
    if [ $? -ne 0 ]; then
      echo "❌ Verification failed! Please fix the issues before pushing to GitHub."
      echo "Hint: Run ./scripts/workflow/test-cycle.sh to start the testing cycle."
      return 1
    fi
  fi
  
  # Final confirmation
  echo "Ready to push $unpushed_commits commits to GitHub."
  read -p "Proceed with push? (Y/n) " response
  if [[ "$response" =~ ^[Nn]$ ]]; then
    echo "Push cancelled."
    return 0
  fi
  
  # Push to GitHub
  push_to_github
  return $?
}

# Execute main function
main "$@"