# Start Development Session Prompt

When the user indicates they want to start development with messages like:
- "Let's start developing"
- "Let's begin coding"
- "Ready to start development"
- "Start working on the feature"

Follow these automated steps:

1. Run the start session command to initialize tracking:
```bash
./synergy.sh start
```

2. Check if we need to create a feature branch:
```bash
# Check if we're on master or main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" = "master" ] || [ "$CURRENT_BRANCH" = "main" ]; then
  # Ask what feature we're working on and create branch
  echo "We should create a feature branch for this work."
  echo "What feature are we implementing? (e.g., content-service, user-auth)"
  # After user responds, create the branch
  ./synergy.sh feature feature-name-from-user
fi
```

3. Check current module focus from status:
```bash
./synergy.sh status
```

4. Provide summary of what we'll be working on, based on the PROJECT_TRACKER.md and MODULE_TRACKER.md content

5. Start Claude with context if needed:
```bash
./synergy.sh claude
```

This ensures all tracking is setup, we're on a feature branch, and we have full context.