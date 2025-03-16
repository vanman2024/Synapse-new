# Synergy Automated Development Workflow

This document explains the fully automated development workflow using the `synergy.sh` script.

## Overview

The Synergy workflow automates all aspects of development:
- Session management
- Git branch creation and management
- Code verification and testing
- Module tracking and progress
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
- Updates the Development Overview document
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

### GitHub Projects Integration

```bash
# Mark a module as completed in GitHub Projects
./synergy.sh update-module "Module Name" complete

# Mark a module as in-progress (current focus) in GitHub Projects
./synergy.sh update-module "Module Name" in-progress

# Reset a module to planned status in GitHub Projects
./synergy.sh update-module "Module Name" planned

# NOTE: Requires GitHub CLI to be installed
# If GitHub CLI is not available, falls back to local overview updates
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

## Integration with Airtable for Development Tracking

The system now uses Airtable as the primary tracking system for project progress:

- **SESSION.md** - Tracks the current development session (local file)
- **Airtable Base** - Primary source of truth for module status and progress
- **docs/project/DEVELOPMENT_OVERVIEW.md** - Reference document for project structure and phases

### Airtable Integration Overview

The Airtable integration provides:
1. **Phases Table** - Tracks development phases with number, name, and status
2. **Modules Table** - Tracks modules with links to phases and status (Planned, In Progress, Completed)
3. **Sessions Table** - Logs development sessions with links to modules and summaries

All session logs and module status updates are automatically synchronized with Airtable using the following workflow:
- When a module status is updated, Airtable is updated automatically
- When a session ends, it's logged in Airtable with links to relevant modules
- Module focus is determined from git commit messages and session focus

### Setting Up Airtable Integration

The integration requires an Airtable base with the appropriate tables. To set it up:

```bash
# Set up Airtable for development tracking
./synergy.sh airtable-setup
```

This command:
1. Creates the required tables in Airtable
2. Imports phase and module data from DEVELOPMENT_OVERVIEW.md
3. Establishes relationships between tables
4. Configures fields for proper display

To use the integration, you need to create a `.env` file with your Airtable credentials:

```
DEV_AIRTABLE_PAT=pat_your_personal_access_token
DEV_AIRTABLE_BASE_ID=app_your_base_id
```

### Using Airtable Integration

Once set up, the integration works automatically with the existing synergy.sh commands:

```bash
# Update module status - now updates Airtable
./synergy.sh update-module "Module Name" complete

# End session - now logs to Airtable
./synergy.sh end

# Other commands work the same way with Airtable integration
```

### Airtable Data Structure

The Airtable base contains three main tables with the following structure:

1. **Phases Table**
   - Phase Number: Number for ordering
   - Phase Name: Primary field for display in links
   - Description: Full description from DEVELOPMENT_OVERVIEW.md
   - Status: Current, Previous, or Upcoming

2. **Modules Table**
   - Module Name: Primary field for display
   - Phase: Linked record to Phases table
   - Status: Completed, In Progress, or Planned

3. **Sessions Table**
   - Branch: Git branch for the session
   - Status: Active or Completed
   - Focus: Linked record to Modules table
   - Summary: Automatic summary of session activities
   - Commits: List of recent commits
   - Notes: Extracted from SESSION.md

All these tables are kept in sync automatically by the synergy.sh script.

### GitHub Projects (Legacy)

While GitHub Projects integration is included in the script, the current workflow uses Airtable as the primary tracking system. GitHub Projects may be used in the future or alongside Airtable, but configuration is not required for the main workflow.

## Modular Architecture

The Synergy system has been refactored into a modular architecture for better maintainability:

```
/scripts/
  /core/
    config.sh      # Central configuration and helper functions
    session.sh     # Session management functions
    module.sh      # Module tracking functions
    git-hooks.sh   # Git hook setup and automation
  /integrations/
    airtable.sh    # Airtable integration (primary tracking)
    github.sh      # GitHub Projects integration (legacy)
    claude.sh      # Claude AI integration
```

This modular approach provides the following advantages:
- Modules are loaded on-demand to improve performance
- Each module focuses on a specific functionality area
- Easier to maintain and extend with new features
- Clear separation between core functionality and integrations

## Benefits

This streamlined workflow:
- Uses a single source of truth for project tracking
- Eliminates manual documentation updates and synchronization
- Ensures code quality with automated verification
- Maintains consistent branch structure
- Creates a complete development history
- Integrates with Claude AI seamlessly
- Provides multi-layer quality assurance
- Automates deployment to staging environments

## Development Overview Structure

The Development Overview document follows this structure:

```markdown
# Synapse Development Roadmap

## Current State
[Description of the current application state]

## Phase 1: Foundation & Verification (Previous)
- [x] Task 1 (completed)
- [x] Task 2 (completed)

## Phase 2: Content Generation Enhancement (Current)
- [x] Task 1 (completed)
- [ ] Task 2 (in progress)
- [ ] Task 3 (planned)

## Phase 3: User Management & Security
- [ ] Task 1 (planned)
- [ ] Task 2 (planned)

## Immediate Next Steps
1. First priority task
2. Second priority task
```

Start using it today with `./synergy.sh start`!