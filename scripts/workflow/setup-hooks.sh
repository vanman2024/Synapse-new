#!/bin/bash

# setup-hooks.sh - Sets up git hooks for automated session tracking
# Run this script once to install git hooks

# Get the workflow directory
WORKFLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get the repository root directory (two levels up from the workflow dir)
REPO_DIR="$(cd "$WORKFLOW_DIR/../.." && pwd)"
HOOKS_DIR="$REPO_DIR/.git/hooks"

# Check if .git directory exists
if [ ! -d "$REPO_DIR/.git" ]; then
  echo "Error: Could not find .git directory. Script path issue."
  exit 1
fi

# Create pre-commit hook
cat > "$HOOKS_DIR/pre-commit" << 'EOF'
#!/bin/bash

# Run the session tracker to update SESSION.md
if [ -f "./scripts/workflow/auto-session-tracker.sh" ]; then
  ./scripts/workflow/auto-session-tracker.sh
  # Re-add SESSION.md after it's been updated
  git add SESSION.md
fi
EOF

# Create post-commit hook
cat > "$HOOKS_DIR/post-commit" << 'EOF'
#!/bin/bash

echo "✅ Session tracker has updated SESSION.md with your latest changes"
EOF

# Create pre-push hook
cat > "$HOOKS_DIR/pre-push" << 'EOF'
#!/bin/bash

# Make sure SESSION.md is up to date before pushing
if [ -f "./scripts/workflow/auto-session-tracker.sh" ]; then
  ./scripts/workflow/auto-session-tracker.sh
  git add SESSION.md
  if git status --porcelain | grep -q "SESSION.md"; then
    git commit -m "Update SESSION.md before push"
  fi
fi
EOF

# Make the hooks executable
chmod +x "$HOOKS_DIR/pre-commit"
chmod +x "$HOOKS_DIR/post-commit"
chmod +x "$HOOKS_DIR/pre-push"

echo "Git hooks installed successfully!"
echo "Now the SESSION.md file will be automatically updated on every commit and push"