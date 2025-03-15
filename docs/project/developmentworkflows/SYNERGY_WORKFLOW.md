# Synergy Automated Development Workflow

This document explains the fully automated development workflow using the `synergy.sh` script.

## Overview

The Synergy workflow automates all aspects of development:
- Session management
- Git branch creation and management
- Code verification and testing
- Module tracking
- Documentation updates
- Claude integration
- CI/CD integration

## Getting Started

To begin development:

```bash
./synergy.sh start
```

This single command:
- Ensures you're on a feature branch
- Creates a new development session
- Updates MODULE_TRACKER.md and PROJECT_TRACKER.md
- Starts auto-commit in the background
- Sets up git hooks for verification

## Core Commands

### Session Management

```bash
# Start a development session
./synergy.sh start

# Show current status
./synergy.sh status

# End a development session
./synergy.sh end
```

### Git Operations

```bash
# Create a feature branch
./synergy.sh feature branch-name

# Smart commit (auto-generates message)
./synergy.sh commit
# Or with a specific message
./synergy.sh commit "feat: Add new feature"

# Create a pull request
./synergy.sh pr "Feature title"
```

### Module Tracking

```bash
# Mark a module as completed
./synergy.sh update-module "Module Name" complete
```

### Claude Integration

```bash
# Start Claude with context
./synergy.sh claude

# Save a Claude compact summary
./synergy.sh compact

# Start the compact watcher
./synergy.sh watch

# Stop the compact watcher
./synergy.sh stop-watch
```

### Automation Controls

```bash
# Start auto-commit in background
./synergy.sh auto-on

# Stop auto-commit
./synergy.sh auto-off
```

## Test & Debug Workflow

The system follows a test-driven development approach with automated verification:

### Automated Testing

Before every commit, the system automatically:
1. **Runs TypeScript Checks** - Verifies all type definitions
2. **Performs Linting** - Ensures code quality standards
3. **Executes Tests** - Runs unit and integration tests

If any verification step fails, the commit is blocked until fixed.

### Debugging Process

When tests fail:
1. Fix the identified issues
2. Stage your changes with `git add .`
3. Try committing again - tests will run automatically
4. Repeat until all tests pass

### Test-Verify-Push Cycle

Our workflow distinguishes between local commits and pushes:
- **Auto-Commit**: Makes frequent local commits
- **No Auto-Push**: Never pushes to GitHub automatically
- **Verification**: Ensures all tests pass before pushing

When ready to push to GitHub:
```bash
git push origin <branch-name>
```
This will trigger the pre-push hook, which runs a final verification.

## Comprehensive CI/CD Integration

The Synergy workflow is part of a comprehensive CI/CD system:

### Local Automation (Your Machine)

The local system includes:
1. **Auto-Commit**: Changes committed every 5 minutes
2. **Git Hooks**: Automated verification before commits and pushes
3. **Session Tracking**: Automated updates to SESSION.md
4. **Module Updates**: Automatic tracking of module completion

### Cloud CI/CD (GitHub Actions)

After pushing to GitHub, the cloud CI/CD takes over:
1. **Build and Test Job**:
   - Sets up Node.js environment in GitHub cloud
   - Runs TypeScript checks, linting, tests
   - Verifies the build in a clean environment
   - Updates SESSION.md with CI results

2. **Deployment Job** (only for main branch):
   - Builds for production
   - Deploys to development environment
   - Updates SESSION.md with deployment info

### Quality Assurance Layers

This multi-layered approach provides:
1. **Local Verification**: Catch issues on your machine first
2. **Cloud Verification**: Double-check in a clean environment
3. **Automated Deployment**: Auto-deploy verified code
4. **Complete History**: Track the entire process in SESSION.md

## Automated Git Hooks

The system includes automated git hooks:

1. **Pre-Commit Hook**: 
   - Automatically runs tests before allowing commits
   - Updates SESSION.md with activity
   - Ensures code quality

2. **Post-Commit Hook**:
   - Checks for module completion
   - Suggests when to create PRs

3. **Pre-Push Hook**:
   - Verifies code quality
   - Confirms all tests pass
   - Prevents pushing broken code

## Single Source of Truth

The system maintains these core tracking files:

- **SESSION.md** - Current development session
- **docs/project/MODULE_TRACKER.md** - Module completion status
- **docs/project/PROJECT_TRACKER.md** - Overall project status

These files are automatically updated to remain in sync.

## Benefits

This streamlined workflow:
- Eliminates manual documentation updates
- Ensures code quality with automated verification
- Maintains consistent branch structure
- Creates a complete development history
- Integrates with Claude AI seamlessly
- Provides multi-layer quality assurance
- Automates deployment to staging environments

Start using it today with `./synergy.sh start`!