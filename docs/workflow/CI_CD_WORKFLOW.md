# CI/CD Workflow for Synapse Project

This document explains the complete CI/CD workflow for the Synapse project, including both local Git hooks and GitHub Actions.

## Overview

The Synapse project uses a comprehensive workflow that combines:

1. **Local automation**: Scripts and Git hooks that run on your development machine
2. **Cloud CI/CD**: GitHub Actions that run on GitHub's infrastructure after pushes

This approach ensures code quality at multiple stages and automates deployment.

## Local Development Workflow

### Auto-Commit

The `auto-commit.sh` script automatically commits your changes at regular intervals (default: 5 minutes).

```bash
# Start auto-commit in the background
./scripts/workflow/auto-commit.sh
```

This script:
- Monitors for changes
- Updates SESSION.md with your activities
- Creates local commits
- Does NOT automatically push to GitHub

### Git Hooks

Two important Git hooks are active:

1. **pre-commit**: Runs before each commit
   - Updates SESSION.md
   - Ensures code formatting

2. **pre-push**: Runs before each push
   - Runs TypeScript checks
   - Runs linting
   - Builds the project
   - Runs tests
   - Updates SESSION.md with verification info
   - Only allows push if all checks pass

These hooks ensure that code quality is verified BEFORE changes leave your machine.

## Cloud CI/CD with GitHub Actions

After code is pushed to GitHub, GitHub Actions workflows are triggered:

### CI Workflow

The `ci.yml` workflow runs on every push to main branches and for pull requests:

1. **Build and Test Job**:
   - Sets up Node.js environment
   - Installs dependencies
   - Runs TypeScript checks
   - Runs linting
   - Builds the project
   - Runs tests
   - Updates SESSION.md with CI results

2. **Deployment Job** (for main and clean-rebuild branches):
   - Builds for production
   - Deploys to development environment
   - Updates SESSION.md with deployment info

## How They Work Together

The combined workflow creates multiple layers of quality assurance:

1. **Local Development**:
   - Auto-commit captures work in progress
   - SESSION.md tracks development activity
   - Git hooks validate before pushing

2. **Cloud Verification and Deployment**:
   - GitHub Actions runs tests in a clean environment
   - Builds and deploys code automatically
   - Updates SESSION.md with CI/CD information

## Benefits

This integrated workflow provides several benefits:

1. **Catch issues early**: Problems are detected on your machine before pushing
2. **Consistent verification**: Code is tested in multiple environments
3. **Automated deployment**: Successful builds are automatically deployed
4. **Complete history**: SESSION.md maintains a record of all activities
5. **Team coordination**: Everyone sees the same workflow and history

## Configuration

To modify the workflow:

1. **Local hooks**: Edit files in `.git/hooks/`
2. **GitHub Actions**: Edit files in `.github/workflows/`

Both components are designed to work together and complement each other.