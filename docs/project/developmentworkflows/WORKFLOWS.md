# Synapse Workflows Reference

This document provides a consolidated reference to all workflows used in the Synapse project.

## Development Workflows

### Project Session Workflow

The Synapse project uses a structured development session approach:

1. **Starting a Session**
   ```bash
   ./scripts/workflow/development/start-session.sh
   ```
   This updates the project status and prepares the development environment.

2. **During Development**
   - Auto-commit runs in the background saving changes
   - Code is organized according to the architecture guidelines
   - Tests are written alongside implementation

3. **Ending a Session**
   ```bash
   ./scripts/workflow/development/session-end.sh
   ```
   This finalizes the session and updates project tracking.

### Git Workflow

The project uses a feature branch workflow:

1. **Creating a Feature Branch**
   ```bash
   ./scripts/workflow/git/new-feature.sh feature-name "Feature description"
   ```

2. **Committing Changes**
   ```bash
   # Automatic commits happen every 5 minutes, or
   ./scripts/workflow/git/auto-commit.sh
   ```

3. **Verifying & Pushing Changes**
   ```bash
   ./scripts/workflow/git/verify-and-push.sh
   ```

### Testing Workflow

Test-driven development is central to the project:

1. **Running Tests**
   ```bash
   ./scripts/workflow/testing/test-cycle.sh component-name cycle-number
   ```

2. **TypeScript Checks**
   ```bash
   ./scripts/workflow/testing/ts-check.sh
   ```

## Claude AI Workflow

The project uses Claude AI for development assistance:

1. **Tracking Claude Conversations**
   ```bash
   # Start the auto-compact watcher (recommended)
   ./start-compact-watch.sh
   ```

2. **Saving Compact Summaries**
   - Use `/compact` in Claude
   - Save output files to `sessions/claude/compact-watch/`
   - Summaries are automatically processed and stored

## CI/CD Workflow

Continuous integration and deployment workflow:

1. **Local Verification**
   - All tests must pass
   - TypeScript checks must succeed
   - Linting rules must be satisfied

2. **GitHub Actions**
   - Automated testing on push
   - Deployment to staging on merge to develop
   - Deployment to production on merge to main

## Documentation Workflow

Documentation maintenance follows these processes:

1. **Project Documentation**
   - Store in `/docs/project/`
   - Update PROJECT_TRACKER.md with current status
   - Update MODULE_TRACKER.md with module progress

2. **Technical Documentation**
   - API documentation in `/docs/api/`
   - Architecture documentation in `/docs/architecture/`
   - Deployment guides in `/docs/deployment/`

## Reference Table of Workflow Scripts

| Category | Script | Purpose |
|----------|--------|---------|
| **Development** | start-session.sh | Start a development session |
| | session-end.sh | End a development session |
| | session-archive.sh | Archive older sessions |
| **Git** | auto-commit.sh | Automatic Git commits |
| | branch-manager.sh | Manage Git branches |
| | new-feature.sh | Create a new feature branch |
| | verify-and-push.sh | Verify and push changes |
| **Testing** | test-cycle.sh | Run test cycles |
| | ts-check.sh | TypeScript verification |
| **Claude** | auto-compact-watch.sh | Watch for compact summaries |
| | save-compact-simple.sh | Manual method to save summaries |

## Integration Points

These workflows are designed to work together:

1. **Development & Git**
   - Development sessions use Git for version control
   - Auto-commit keeps track of changes during sessions

2. **Testing & CI/CD**
   - Local testing feeds into CI/CD pipeline
   - Test results inform development decisions

3. **Claude AI & Documentation**
   - Claude compact summaries provide context for decisions
   - Documentation references Claude discussions where relevant

This consolidated approach ensures consistent development practices
and clear documentation across the entire project.
## References to Detailed Workflow Documentation

For more detailed information on specific workflows, see:

- [DEVELOPMENT_WORKFLOW.md](./DEVELOPMENT_WORKFLOW.md) - Development workflow details
- [WORKFLOW_SCRIPTS.md](./WORKFLOW_SCRIPTS.md) - Details on workflow scripts
- [CI_CD_WORKFLOW.md](./CI_CD_WORKFLOW.md) - CI/CD workflow details
