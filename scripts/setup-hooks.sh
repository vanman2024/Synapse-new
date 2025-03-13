#!/bin/bash

# setup-hooks.sh - Sets up git hooks for automated session tracking
# Run this script once to install git hooks

REPO_DIR="$(pwd)"
HOOKS_DIR="$REPO_DIR/.git/hooks"

# Check if we're in the repo root
if [ ! -d "$REPO_DIR/.git" ]; then
  echo "Error: Not in git repository root. Please run from the project root."
  exit 1
fi

# Create pre-commit hook
cat > "$HOOKS_DIR/pre-commit" << 'EOF'
#!/bin/bash

# Run the session tracker to update SESSION.md
if [ -f "./scripts/auto-session-tracker.sh" ]; then
  ./scripts/auto-session-tracker.sh
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
if [ -f "./scripts/auto-session-tracker.sh" ]; then
  ./scripts/auto-session-tracker.sh
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